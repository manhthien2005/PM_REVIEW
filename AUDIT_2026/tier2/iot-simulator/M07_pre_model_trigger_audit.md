# Audit: M07 — pre_model_trigger/

**Module:** `Iot_Simulator_clean/pre_model_trigger/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 1 Track 5 Pass B — IoT sim rule engine + fast-path trigger

## Scope

Stage-1 "pre-model" trigger evaluates vitals + motion BEFORE invoking downstream ML risk model. Config-driven rule engine + fall fast-path + backend dispatch clients.

| File | LoC | Role |
|---|---|---|
| `__init__.py` | 32 | Public exports |
| `types.py` | 72 | `PersonaProfile` + `TriggerActionItem` dataclasses |
| `settings_provider.py` | 86 | Threshold dict provider (wraps vitals_service constants) |
| `normalization.py` | 140 | Vitals field name normalization + data quality validation |
| `rule_engine.py` | 345 | Rule evaluation (instant + profile + time-series + combination) |
| `fall_pre_trigger.py` | 242 | Fall Stage-1 threshold check (accel + gyro + posture) |
| `orchestrator.py` | 217 | Pipeline coordinator: buffer -> rules -> fall -> model call -> post-process |
| `response_handler.py` | 130 | Dedup + filter + enrich + sort action list (static class) |
| `healthguard_client.py` | 158 | HTTP client -> `/mobile/risk/calculate` (status-only sender) |
| `mobile_telemetry_client.py` | 274 | HTTP client -> `/api/v1/mobile/telemetry/imu-window` + `/sleep-risk` (body+status sender) |
| `sleep_dispatch.py` | 224 | 43-field `SleepRecord` validator + dispatcher (wraps mobile_telemetry_client) |
| `vitals_buffer.py` | 100 | Per-device vitals ring buffer (for time-series rules) |
| `motion_window_buffer.py` | 280 | Per-device motion 50-sample FIFO -> IMU window payload |
| Config: `health_rules/rules_config.json` | 447 | JSON rule declarations |
| **Total** | **~2,747** | (Python ~2,300 + JSON ~447) |

**Excluded:** `fall/fall_pipeline_wrist_config.json` (pipeline config data, not code), `tests/` (separate report).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Data quality gate chan rule eval khi invalid; time-series + combination + profile escalation chuan; fall pre-trigger has hard/soft trigger cascade. |
| Readability | 3/3 | Module docstrings chi tiet; function names precise; JSON config co version/scope/principles; dataclasses thuan. |
| Architecture | 3/3 | Clean layering: types -> providers -> engines -> orchestrator; DI khap noi; `MobileTelemetryClient` vs `HealthGuardAPIClient` tach ro concern; `ResponseHandler` static class pattern. |
| Security | 3/3 | Ca 3 HTTP client gui `X-Internal-Service` + optional `X-Internal-Secret`; data quality gate suppress PHI rule eval when signal poor; no SQL/eval/exec. |
| Performance | 2/3 | `rules_config.json` reload moi lan init (acceptable); `_eval_multi_metric_condition` parse regex moi tick (cache-able); ring buffers tot. |
| **Total** | **14/15** | Band: **Mature** |

## Findings

### Correctness (3/3)

**Data quality gate (strong):**
- `normalization.validate_data_quality` kiem tra 6 required fields + signal_quality + sensor_error_flag. Tra ve `(is_valid, errors)` tuple — ro rang.
- Orchestrator line 143-160: neu `_dq_ok=False` -> SUPPRESS all vitals rules (URGENT included). Comment neu ro tradeoff "URGENT rules also skipped — review if this device may have a real clinical event". Well-documented intentional decision.
- Fall trigger van chay khi vitals fail — dung vi fall detection dung motion data, khong phu thuoc vitals quality.

**Rule engine (strong):**
- `_eval_single_cmp` + `_eval_multi_metric_condition` split ro: 1 variable vs multi-variable.
- `_check_condition` ho tro ca 2 format (string expression + structured `lt`/`gt`/`lte`/`gte`) — backward compat.
- Severity ordering explicit (`_SEVERITY_ORDER`), consumed 2 places (sort + profile map).
- `_PROFILE_ESCALATION_SOURCE_MAP` comment "Fix #6" giai thich bug cu: profile escalation truoc day match sai `reason_code` (output vs source). Fix clean.
- Time-series drift ho tro 4 direction `above/above_eq/below/below_eq` — Fix #4 note explains addition.
- Combination rules escalation-only (never downgrade) — principle enforced.

**Fall pre-trigger (strong):**
- Hard trigger (accel >= 3g) -> URGENT immediate return — khong check soft.
- Soft trigger chain: accel >= 2.5g + (posture >= 45 deg OR low motion >= 1s) OR gyro >= 250dps + posture >= 45 deg.
- Compute `accel_mag` + `gyro_mag` defensive from x/y/z, fallback to pre-computed peak values trong motion dict — 2-source robust.
- Config fallback defaults neu JSON parse fail (line 23-27).

**Sleep dispatcher (strong):**
- `filter_to_sleep_record` validates 41 required fields + explicit None check (line 124-127: "Treat explicit None as missing too — the model-api's float fields can't deserialise null and would 422"). Catches upstream bugs at simulator boundary.
- Custom `SleepRecordValidationError` carries `missing` set — clean error surface.
- Try/except chain in `dispatch()`: validation -> transport -> unexpected -> all return `None` voi WARNING log. Never crash tick loop.

**Minor concerns:**
- `_evaluate_time_series_rules` line 282: `if len(recent) < max(2, window // 2): continue` — 2-arg `max` semantics OK, but documented nowhere. Reader must infer "minimum 2 readings OR half the window, whichever larger".
- `_eval_multi_metric_condition` parses via `_CMP_RE.match(part)` — regex matches from start but doesn't anchor end. Input "heart_rate > 100 and extra" would match "heart_rate > 100" + ignore "and extra" silently. Not exploitable (config-driven input only) but fragile.

### Readability (3/3)

**Strengths:**
- Every module has headline docstring + "Architecture reference" line pointing to plan doc.
- Fix comments numbered (`Fix #1`, `Fix #4`, `Fix #6`, `CRITICAL #1`, `MEDIUM #9`, `HIGH #6`) — traceable to commit history.
- `rules_config.json` structure uses `scope`, `principles`, `inputs`, `derived_metrics`, `data_quality`, `context_policy`, `baseline`, `profile`, `instant_rules`, `profile_adjusted_rules`, `time_series_rules`, `combination_rules`, `special_policies`, `decision_engine`, `implementation_notes` — declarative schema that reads like a spec.
- `TriggerActionItem` dataclass is minimal (6 fields), serialisation-friendly. Type hints throughout.

**Function sizes:**
- All files under 350 LoC. Largest: `rule_engine.py` 345 LoC — acceptable (single responsibility: evaluate rules).
- Longest function `RuleEngine._evaluate_instant_rules` ~45 LoC — within 50 LoC goal.

**Naming:**
- `PersonaProfile` vs `TriggerActionItem` — clear domain terms.
- `high_sensitivity`, `escalation_rules`, `pre_trigger` — domain language consistent.
- `_build_source_to_profile_map` — explicit about direction.
- Helper funcs `_safe_float`, `_accel_xyz`, `_gyro_xyz`, `_derive_orientation` — primitive + reusable.

**Minor readability concerns:**
- `rule_engine._evaluate_instant_rules` line 219-223 uses `for ... else: continue; break` Python idiom — tricky to read. A named helper `_match_severity_for_metric()` would be clearer.
- JSON config has `time_series_rules.pending_baseline_drift` section marked "not yet implemented" with 12 rules defined — dead code-adjacent. Either remove or feature-flag.
- `_SEVERITY_RANK` (response_handler) duplicates `_SEVERITY_ORDER` (rule_engine) — same data, 2 consts, different files. Should centralize.

### Architecture (3/3)

**Strengths:**

1. **Clean layering:**
   ```
   types (PersonaProfile, TriggerActionItem)
     |
   settings_provider (SystemSettingsProvider)
   normalization (pure functions)
     |
   rule_engine (RuleEngine)
   fall_pre_trigger (FallPreTrigger)
     |
   orchestrator (TriggerOrchestrator) -- pipeline
     |
   response_handler (ResponseHandler — static post-process)
   ```
   Plus 3 HTTP clients + 2 buffers as orthogonal infrastructure.

2. **DI everywhere**: `TriggerOrchestrator.__init__` accepts 8 explicit deps (settings, rules, fall, client, handler, buffer, flag). No hidden globals. Test injection trivial.

3. **`ResponseHandler` as static class**: comment line 29-32 explains "passed as class (not instance) to orchestrator constructor". Avoids stateful handler — good defensive design for pure post-processing.

4. **Dual HTTP client split**:
   - `HealthGuardAPIClient` uses status-only `HttpSenderFn` — fire-and-forget dispatch, old `/mobile/risk/calculate` route.
   - `MobileTelemetryClient` uses body+status `HttpSenderWithBodyFn` — reads response for `fall_event_id` / `risk_score_id`. Both co-exist with distinct contracts — documented explicitly in mobile_telemetry_client.py line 16-23.

5. **Buffer separation**: `VitalsHistoryBuffer` (dicts) vs `MotionWindowBuffer` (dataclass samples) — different eviction/shape needs split into 2 classes rather than 1 generic. Correct YAGNI.

6. **Config as JSON**: `rules_config.json` is declarative spec. Rule engine code doesn't encode thresholds. Ship-config-only updates possible without touching Python.

7. **Protocol-like pattern in healthguard_client**: `HttpSenderFn` + `HttpSenderWithBodyFn` type aliases document sender contracts. Test doubles satisfy type checker.

**Minor concerns:**

1. **`settings_provider` imports from `api_server/services/vitals_service.py`** (line 17-20). Creates upward dependency: `pre_model_trigger` depends on `api_server`. Breaks layering if `api_server` ever needs to depend on `pre_model_trigger`. Currently acceptable (vitals thresholds are only authoritative source) but document why.

2. **`_VITALS_SNAPSHOT_KEYS` in orchestrator.py line 28-37** — uses snapshot for model calls but grep shows `_extract_vitals_snapshot` is DEFINED but NEVER CALLED (private static method). Dead code OR dead-for-now forward-compat. Remove or wire up.

3. **`HealthGuardAPIClient` + `MobileTelemetryClient` + `SleepRiskDispatcher`** all do similar POST-JSON-parse-response work, but 3 different implementations. `_post_json` in mobile_telemetry_client is cleaner (returns dict | None) than healthguard_client's `request_prediction` (returns list of TriggerActionItem). Consider unified transport base class with per-client payload/response transformer.

### Security (3/3)

**All 3 HTTP clients send internal auth headers (chuan):**

1. **`HealthGuardAPIClient.request_prediction`** (line 94-99):
   ```python
   headers: dict[str, str] = {
       "Content-Type": "application/json",
       "X-Internal-Service": "iot-simulator",
   }
   if self._internal_secret:
       headers["X-Internal-Secret"] = self._internal_secret
   ```

2. **`MobileTelemetryClient._post_json`** (line 180-186): same pattern.

3. **`SleepRiskDispatcher`** delegates to `MobileTelemetryClient` -> inherited headers.

**Contrast with M02 finding IS-002**: `SleepService._push_sleep_to_backend` in `api_server/services/` DOES NOT use these headers. Drift: M07 correct, M02 incorrect. IS-002 fix should adopt M07 pattern verbatim.

**Data quality gate = PHI protection:**
- Line 143-160 orchestrator: when `validate_data_quality` fails, logs raw error codes (`missing_required_field:heart_rate` etc.) but NOT the raw vitals values. No PHI leak in log.
- `WARNING` log level for DQ failure — appropriate visibility without ERROR escalation.

**Secret handling:**
- `internal_secret: str | None = None` default -> 3 clients all optional (env-driven). No hardcoded secret.

**Other positives:**
- `_summarise(body)` in mobile_telemetry_client line 260-267: truncates response body to 200 chars before logging. Backend error body with PHI gets capped. Good defense-in-depth.
- No `eval()`, `exec()`, no SQL in any M07 file.
- No `verify=False` or SSL disable patterns.

**Minor concerns:**
- `rule_engine` line 41-47: reads `_CONFIG_PATH` from disk. If `rules_config.json` is tampered (file permission misconfig), attacker could inject rules that evade detection. Not an immediate risk (same process can be compromised easier), but config integrity verification (checksum at startup) would be defense-in-depth. Defer P2.
- `rule_engine.reload_config()` (line 332-338) is public — anyone calling the engine can hot-reload from disk. No auth check. Acceptable for dev sim but flag if used cross-service.

### Performance (2/3)

**Strengths:**
- Ring buffers O(1) push + O(k) read (k = history size, bounded <= 60 or 50).
- `_SEVERITY_ORDER` dict lookup O(1) for sort keys.
- `ResponseHandler.process` pipeline is in-memory list operations — no I/O.
- `MobileTelemetryClient` timeout=8s default — reasonable for fall model call.

**Concerns:**

1. **`_load_rules_config()` called once per `RuleEngine.__init__`**. File I/O on startup — fine. But `reload_config()` re-parses full JSON — acceptable for dev hot-reload, not ideal for production if called frequently.

2. **`_eval_multi_metric_condition` regex parse per tick:**
   ```python
   for part in parts:
       match = _CMP_RE.match(part)
   ```
   For combination rules (up to ~10 per tick), regex matches happen every tick. Parse once at rule-load time -> cache `(left_raw, op, right_raw)` tuples. Minor perf gain, bigger code simplicity gain.

3. **Rule evaluation doesn't short-circuit**:
   - `RuleEngine.evaluate` runs all 4 phases (instant + profile + time-series + combination) regardless of whether already URGENT triggered. Not critical (fast in-memory) but semantically: if URGENT fires in instant phase, no need to eval profile/TS rules. Skip possible via early-exit flag.

4. **`_extract_vitals_snapshot` orchestrator.py line 178** — defined but never called (dead code). Remove.

5. **`rules_config.json.time_series_rules.pending_baseline_drift`** — 12 rules marked "not yet implemented". Not loaded by code. Dead config. Either remove or mark explicitly `"enabled": false` + `"_deprecated": true`.

6. **HTTP clients use `http_sender` callback pattern — sync**. All push paths serial. Parallelism possible via async variants. Acceptable for dev sim's single-device common case. Document for Phase 4 scaling consideration.

7. **`_eval_single_cmp` uses `float.__lt__` etc. from `_OPS` dict**. Works but `operator.lt` from stdlib `operator` module is idiomatic + faster (C-optimized). Trivial perf diff.

## New findings / bugs (not in BUGS INDEX)

### IS-005 (NEW, Low) — orchestrator `_extract_vitals_snapshot` dead code

**Severity:** Low
**Status:** Proposed (defer or simple cleanup)

**Summary:** `TriggerOrchestrator._extract_vitals_snapshot` (orchestrator.py line 178-196) defined as private static method but grep shows zero callsites. Comment line 176 says "Returns a flat dict with only the keys needed for model calls". If model calls skip this method, `_VITALS_SNAPSHOT_KEYS` constant (line 28-37) is also unused.

**Impact:** 0 runtime, -20 LoC if removed.

**Fix:** Delete method + constant, or wire into `_request_model_prediction` if originally intended.

### IS-006 (NEW, Low) — `rules_config.json.pending_baseline_drift` dead config

**Severity:** Low
**Status:** Proposed (cleanup)

**Summary:** 12 rules in `time_series_rules.pending_baseline_drift` marked "_notes": "These rules require baseline tracking (not yet implemented)". No code path loads them. Adds ~80 LoC to config file, confuses readers about which rules are active.

**Fix:** Move to separate `rules_config_future.json` OR add `"enabled": false` flag + document which scope covers baseline impl work. Phase 4 decision.

### IS-007 (NEW, Low) — duplicated severity rank consts

**Severity:** Low
**Status:** Proposed (Phase 4 refactor)

**Summary:** `rule_engine.py._SEVERITY_ORDER` (4-key dict) and `response_handler.py._SEVERITY_RANK` (same 4-key dict) are identical. Risk: drift if one updated.

**Fix:** Move to `types.py`:
```python
SEVERITY_RANK: dict[str, int] = {
    "NORMAL": 0, "WATCH": 1, "SEND_TO_RISK_MODEL": 2, "URGENT": 3,
}
```
Import from both consumers.

## Positive findings (transfer to other modules)

- **Data quality gate pattern** (orchestrator + normalization) — suppress rule eval when data unreliable, still run motion-based fall trigger. Clear separation of "input trusted" vs "input suspect". Apply to other sensor ingestion paths.
- **Dual HTTP sender contract** (`HttpSenderFn` vs `HttpSenderWithBodyFn`) — explicit documented contracts for "fire and forget" vs "read response". Better than one-size-fits-all.
- **`SleepRecordValidationError.missing` attribute** — custom exception carries structured data. Pattern for other validators.
- **`ResponseHandler` static class** — correct pattern when behavior has no state. Reuse for future post-processors.
- **Config-driven rules** (`rules_config.json` 447 LoC) — declarative spec. Non-code devs (clinicians) can review thresholds. Ship-with-config-update workflow possible.
- **Fix-numbered comments** (`Fix #1`, `Fix #4`, etc.) — audit trail within code. Useful for future archaeology.
- **Severity escalation principles** (rules_config.json line 22-30) — explicitly listed as 7 invariants. Machine-readable contract for reviewers.
- **M07 correctly sends X-Internal-Service headers** — reference impl for IS-002 SleepService fix.

## Recommended actions (Phase 4)

### P1 — Phase 4 recommended
- [ ] **IS-002 fix uses M07 pattern**: Apply M07's header-injection approach to SleepService in M02. Est 15 min.
- [ ] **Dead code cleanup**: Remove `_extract_vitals_snapshot` + `_VITALS_SNAPSHOT_KEYS` if not used (IS-005).
- [ ] **Centralize severity rank** (IS-007): Move to `types.py`, single source of truth.
- [ ] Cache `_CMP_RE.match()` results at config-load time — parse once, eval fast.
- [ ] Add early-exit in `RuleEngine.evaluate()`: if URGENT fires in instant phase, skip profile/TS/combination (still eval fall trigger in orchestrator).

### P2 — Phase 5+ or defer
- [ ] **IS-006 cleanup**: Decide `pending_baseline_drift` fate (delete / enable / move to future config).
- [ ] Unified HTTP base class for 3 clients (`HealthGuardAPIClient`, `MobileTelemetryClient`, `SleepRiskDispatcher`). Extract `_post_json` + `_summarise` to base.
- [ ] Config integrity check at `rules_config.json` load (checksum or signature).
- [ ] Async variants of HTTP clients (if scaling scenario demands).
- [ ] `operator.lt` stdlib instead of `float.__lt__` (micro-perf).

## Out of scope (defer Phase 3 deep-dive)

- **`rules_config.json` threshold accuracy validation** — needs clinical domain input (is HR >= 131 really urgent threshold for all ages? BMI >= 25 really high-sensitivity trigger?). Separate from code audit.
- Test coverage matrix for rule evaluation (separate report).
- `fall_pipeline_wrist_config.json` hard/soft trigger calibration (empirical tuning, not code).
- Benchmark rule-engine perf at 1000 devices/sec (stress test, not macro audit).

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Inventory: [M07 entry](../../module_inventory/05_iot_simulator.md#m07-pre_model_trigger--rule-engine)
- Related modules: [M01 routers](./M01_routers_audit.md), [M02 services](./M02_services_audit.md), [M03 middleware+deps](./M03_middleware_dependencies_audit.md)
- Reference pattern for IS-002 fix: `pre_model_trigger/healthguard_client.py` line 94-99 (header injection done correctly)
- Config: `Iot_Simulator_clean/pre_model_trigger/health_rules/rules_config.json` (447 LoC declarative rules)
- Related ADR: [ADR-015 alert severity taxonomy](../../../ADR/015-alert-severity-taxonomy-mapping.md)
- Architecture plan ref: `Iot_Simulator_clean/plans/alert-threshold-architecture-plan.md`
