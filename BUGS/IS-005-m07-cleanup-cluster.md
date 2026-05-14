# Bug IS-005: M07 pre_model_trigger cleanup cluster (dead code + dup constants)

**Status:** Open
**Repo(s):** Iot_Simulator_clean (pre_model_trigger + api_server)
**Module:** pre_model_trigger/{orchestrator, rule_engine, response_handler} + health_rules/rules_config.json
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass B audit (M07)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

3 cleanup concerns grouped into 1 bug to avoid INDEX noise. All Low severity, same module cluster, same cleanup PR.

### IS-005a — orchestrator `_extract_vitals_snapshot` dead code

`TriggerOrchestrator._extract_vitals_snapshot` (orchestrator.py line 178-196) defined as private static method. Grep scan shows zero callsites. `_VITALS_SNAPSHOT_KEYS` constant (line 28-37) only consumed by this dead method.

### IS-005b — `rules_config.json.pending_baseline_drift` dead config

`time_series_rules.pending_baseline_drift` section (12 rules) marked `"_notes": "These rules require baseline tracking (not yet implemented)"`. Rule engine code doesn't load this section — flagged dead at `rule_engine.py._evaluate_time_series_rules` which only reads `persistent_drift`.

### IS-005c — duplicated severity rank constants

`rule_engine.py._SEVERITY_ORDER` (4-key dict) and `response_handler.py._SEVERITY_RANK` (identical dict) are separate consts. Risk: drift if one updated, other not.

## Repro steps

### IS-005a
1. Grep `orchestrator.py` cho `_extract_vitals_snapshot` — 1 match (the def)
2. Grep entire repo cho `_extract_vitals_snapshot` — same 1 match

### IS-005b
1. Grep `rule_engine.py` cho `pending_baseline_drift` — 0 matches
2. Read `_evaluate_time_series_rules` — reads `persistent_drift` only

### IS-005c
1. Diff `rule_engine.py._SEVERITY_ORDER` vs `response_handler.py._SEVERITY_RANK` — identical 4-entry dict {NORMAL:0, WATCH:1, SEND_TO_RISK_MODEL:2, URGENT:3}

## Environment

- Repo: `Iot_Simulator_clean@develop`
- Files affected:
  - `Iot_Simulator_clean/pre_model_trigger/orchestrator.py` line 28-37 + 178-196
  - `Iot_Simulator_clean/pre_model_trigger/rule_engine.py` line 26-32 (`_SEVERITY_ORDER`)
  - `Iot_Simulator_clean/pre_model_trigger/response_handler.py` line 22-28 (`_SEVERITY_RANK`)
  - `Iot_Simulator_clean/pre_model_trigger/health_rules/rules_config.json` approx line 250-330 (`time_series_rules.pending_baseline_drift`)

## Root cause

### IS-005a
Added forward-compat cho future model-call payload path, then abandoned when `_request_model_prediction` chose to not extract (sends full vitals or device_id instead).

### IS-005b
Config drafted with full baseline drift vision, implementation deferred. Kept in config as aspirational doc. Dead until baseline impl work lands.

### IS-005c
2 files written independently, each defining its own severity rank lookup. No centralized types module for this constant.

## Impact

**Production:** 0 impact. All 3 are latent cleanup items.

**Code health:**
- IS-005a: -20 LoC if removed
- IS-005b: -80 LoC JSON config noise, improves reader confusion ("which rules are active?")
- IS-005c: Drift risk if severity levels change (add CRITICAL, adjust ordering)

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | `_extract_vitals_snapshot` is used indirectly via getattr/setattr magic | Rejected — grep covers all access patterns |
| H2 | `pending_baseline_drift` loaded conditionally via feature flag elsewhere | Rejected — read config loader, only `persistent_drift` + `rapid_change` + `recurrence` keys loaded |
| H3 | `_SEVERITY_ORDER` and `_SEVERITY_RANK` have intentional difference (e.g. profile-specific) | Rejected — identical dict content |

### Attempts

_(Chua attempt fix — defer Phase 4 cleanup sprint)_

## Resolution

_(Fill in when resolved)_

**Fix approach (planned):**

### IS-005a
```python
# orchestrator.py — DELETE lines 28-37 + 178-196
# _VITALS_SNAPSHOT_KEYS: tuple[str, ...] = (...)    REMOVED
# @staticmethod
# def _extract_vitals_snapshot(...) -> dict[str, Any]:    REMOVED
```

### IS-005b
Option A (simple, recommended): Delete `pending_baseline_drift` subsection from `rules_config.json`. Document in commit "removed aspirational baseline drift rules — re-add when baseline tracking lands".

Option B (preserve): Add `"enabled": false, "_deprecated": true, "_planned_for": "baseline tracking implementation"` flags. Rule engine skips load if `enabled=false`.

### IS-005c
Move to `types.py`:

```python
# pre_model_trigger/types.py
SEVERITY_RANK: dict[str, int] = {
    "NORMAL": 0,
    "WATCH": 1,
    "SEND_TO_RISK_MODEL": 2,
    "URGENT": 3,
}
```

Import from both consumers:
```python
# rule_engine.py
from pre_model_trigger.types import SEVERITY_RANK
_SEVERITY_ORDER = SEVERITY_RANK   # or replace usage with direct reference

# response_handler.py
from pre_model_trigger.types import SEVERITY_RANK
_SEVERITY_RANK = SEVERITY_RANK
```

Remove the aliasing lines entirely if no other rename needed.

**Fix scope summary:**
- IS-005a: -20 LoC, 1 file
- IS-005b: -80 LoC JSON, 1 file
- IS-005c: -10 LoC + 1 central def, 3 files

Est total: 25 min + test verify.

**Test added (planned):**
- No new tests (cleanup only, no behaviour change)
- Verify existing tests pass: `pytest tests/pre_model_trigger/ -v`
- Grep verify: `_extract_vitals_snapshot` and `pending_baseline_drift` return 0 matches

**Verification:**
1. Unit tests green
2. Grep zero-match as above
3. `SEVERITY_RANK` defined once, imported twice

## Related

- **Parent audit:** [M07 pre_model_trigger audit](../AUDIT_2026/tier2/iot-simulator/M07_pre_model_trigger_audit.md)
- **Blocks:** None (cleanup only)
- **Blocked by:** None
- Original labels: IS-005 (orchestrator dead code), IS-006 (config dead section), IS-007 (dup consts) — merged into this single IS-005 cluster per solo-dev ergonomics

## Notes

- 3 concerns batched into 1 PR to reduce review overhead
- Phase 4 cleanup sprint timing — can defer further to Phase 5 hygiene if backlog heavy
- If IS-005b option B chosen, future dev adding baseline impl has clear TODO hook in config
- No behaviour change expected from any of 3 fixes — pure code health
