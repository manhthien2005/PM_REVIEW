# Bug IS-004: SleepService SLEEP_SCENARIO_PHASES/PROFILES la module-level globals (not instance state)

**Status:** Open
**Repo(s):** Iot_Simulator_clean (api_server)
**Module:** api_server/services/sleep_service
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass B audit (M02)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`sleep_service.py` khai bao 2 module-level `dict` (`SLEEP_SCENARIO_PHASES`, `SLEEP_SCENARIO_PROFILES`) va populate chung tu `SleepService.__init__()` dung `global` keyword. Khi 2 instance init voi scenario khac nhau (pattern test voi mock data), instance thu 2 overwrite instance 1. Methods downstream doc scenario via module global -> read state cua instance khac -> bug tiem tang.

## Repro steps

1. Instantiate `SleepService(sleep_scenario_phases={"scenario_A": [...], ...}, ...)`
2. Verify `SLEEP_SCENARIO_PHASES` module-level dict co scenario_A
3. Instantiate `SleepService(sleep_scenario_phases={"scenario_B": [...], ...}, ...)` — parallel test, different fixture
4. Module-level dict bay gio co ca scenario_A + scenario_B (merged via `.update()`)
5. Call `_advance_sleep_phase_if_due(device_id)` tu instance A, ham doc `SLEEP_SCENARIO_PHASES` (module global) — tra ve data merge tu all instances

**Expected:** Moi SleepService instance hold scenario data rieng.

**Actual:** State shared via module-level globals.

**Repro rate:** 100% code-path deterministic. User-visible impact: 0 (chi 1 runtime today).

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/api_server/services/sleep_service.py`
  - Line 66-67: module-level decl
  - Line 85-92: `__init__` populate via `global` + `.update()`
  - Line 1200-1260: `_advance_sleep_phase_if_due` reads module-level
  - Line 920: `_select_session_for_scenario` reads module-level

## Root cause

### File: `sleep_service.py:60-92`

```python
# MEDIUM #9: Module-level references — populated once from dependencies.py
# via SleepService.__init__ to avoid calling load_sleep_scenarios() twice.
SLEEP_SCENARIO_PHASES: dict[str, Any] = {}
SLEEP_SCENARIO_PROFILES: dict[str, Any] = {}


class SleepService:
    def __init__(
        self,
        ...
        sleep_scenario_phases: dict[str, Any] | None = None,
        sleep_scenario_profiles: dict[str, Any] | None = None,
    ) -> None:
        global SLEEP_SCENARIO_PHASES, SLEEP_SCENARIO_PROFILES
        ...
        if sleep_scenario_phases is not None:
            SLEEP_SCENARIO_PHASES.update(sleep_scenario_phases)   # <-- mutates module global
        if sleep_scenario_profiles is not None:
            SLEEP_SCENARIO_PROFILES.update(sleep_scenario_profiles)
```

### Why bug exists

Comment "MEDIUM #9: avoid calling load_sleep_scenarios() twice" goi y dev previously loaded scenarios trong `dependencies.py` va muon share state. Chose shortcut: module global. Se correct neu:

1. Only 1 SleepService instance exists per process (currently true)
2. Scenario data is immutable after startup (currently true)

Both assumption hold -> bug invisible nhung pattern fragile.

## Impact

**Production (current state):** 0 impact. 1 SleepService, 1 scenario set, immutable.

**Testing (potential):**

- Parallel unit tests that instantiate SleepService with different scenario fixtures will leak state across test cases unless each test clears `SLEEP_SCENARIO_PHASES.clear()` + `SLEEP_SCENARIO_PROFILES.clear()`.
- No existing fixture does this clearing -> Phase 4 refactor risk when adding test.
- Module-level mutation = flake potential if pytest parallel runner (`pytest -n auto`) is adopted.

**Future (if scope expands):**

- Multi-tenant runtime (per-user scenario sets): impossible without refactor.
- Hot-reload config: impossible without process restart.

Severity **Low** vi production impact = 0.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Global pattern necessary do circular import constraint? | Rejected — instance attr hoan toan khong lien quan import |
| H2 | Perf reason? Shared data across calls? | Rejected — `__init__` chay 1 lan, attr vs global same perf |
| H3 | Historical extraction artifact tu SimulatorRuntime | Confirmed — "MEDIUM #9" comment references dependencies.py load_sleep_scenarios |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass B audit 2026-05-13, defer Phase 4 or Phase 5)_

## Resolution

_(Fill in when resolved — Phase 4/5 target)_

**Fix approach (planned):**

```python
# Remove module-level decl (lines 66-67)
# SLEEP_SCENARIO_PHASES: dict[str, Any] = {}    DELETE
# SLEEP_SCENARIO_PROFILES: dict[str, Any] = {}  DELETE


class SleepService:
    def __init__(
        self,
        ...
        sleep_scenario_phases: dict[str, Any] | None = None,
        sleep_scenario_profiles: dict[str, Any] | None = None,
    ) -> None:
        # Remove `global` statement
        ...
        self._scenario_phases: dict[str, Any] = dict(sleep_scenario_phases or {})
        self._scenario_profiles: dict[str, Any] = dict(sleep_scenario_profiles or {})

    def _advance_sleep_phase_if_due(self, device_id: str) -> None:
        scenario_id = self.device_scenarios.get(device_id)
        if scenario_id not in self._scenario_phases:   # <-- self. instead of global
            ...
        schedule = self._scenario_phases[scenario_id]
        ...

    def _select_session_for_scenario(self, scenario_id: str) -> tuple[...]:
        profile = self._scenario_profiles.get(
            scenario_id,
            self._scenario_profiles["good_sleep_night"]
        )
        ...
```

**Fix scope summary:** ~10 LoC change (2 decls + 2 method reads + 1 init block). Est 15 min.

**Test added (planned):**
- `test_sleep_service.py::test_scenario_data_isolated_per_instance`
- Create 2 SleepService instances with disjoint scenario dicts, assert each instance only knows its own scenarios.

**Verification:**
1. Unit test green
2. Grep `SLEEP_SCENARIO_PHASES` / `SLEEP_SCENARIO_PROFILES` — 0 matches after fix
3. Existing tests still pass (no behaviour change cho production single-instance case)

## Related

- **Parent audit:** [M02 services audit](../AUDIT_2026/tier2/iot-simulator/M02_services_audit.md)
- **Anti-pattern ref:** steering `22-fastapi.md` — "Global mutable state khong thread-safe"

## Notes

- Nhe nhat trong 3 bug tu M02 audit
- Phase 4 co the defer sang Phase 5 (hygiene) neu P0/P1 backlog nang
- Pattern same applied (module globals) co the xuat hien trong dependencies.py (M03 3266 LoC) — cross-check khi Phase 3 split dependencies.py
- `MEDIUM #9` comment hint developer nay aware "avoid load twice" optimization — nen thuc hien bang cache / lru_cache thay vi module global
