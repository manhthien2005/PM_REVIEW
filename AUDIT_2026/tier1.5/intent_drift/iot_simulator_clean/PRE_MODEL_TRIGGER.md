# Intent Drift Review - Iot_Simulator_clean / PRE_MODEL_TRIGGER

**Status:** Confirmed v2 (2026-05-13) - Q1 + Q2 + Q4 REVISED per verify pass + ADR-015; module list + mode matrix expanded
**Repo:** `Iot_Simulator_clean`
**Module:** PRE_MODEL_TRIGGER
**Related UCs (old):** N/A (internal tooling - no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass + ADR-015 + decisions F-PT-03/04)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/PRE_MODEL_TRIGGER_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** Q1-Q5 chot, status Confirmed.
- **v2 (2026-05-13 afternoon):** Verify pass phat hien:
  - C1 Q4 severity taxonomy SAI (prob mapping khong ton tai, enum khac ADR D1) -> **Resolved by ADR-015 (2 taxonomies + mapping layer).**
  - H1 Q1 "flip env var 30min" underscoped - 2 flags + shadow/active mode. **Decision: default SHADOW mode (safer), active = separate Phase 4 decision.**
  - H2 Q2 DB threshold source claim SAI (update_overrides 0 call sites). **Decision: document intent-only, fix detection logic, wire DB post-capstone.**
  - H3 P3 + P6 wording sai (sleep_dispatch standalone, ResponseHandler post-process only).
  - M1 Config JSON files chua list; M2 Second flag PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS missing.
- Doc rewritten theo verify findings + ADR-015 + anh decisions.

---

## Muc tieu doc nay

Capture intent cho Pre-Model Trigger - decision layer giua raw vitals va AI model calls. Internal tooling, khong co UC cu.

---

## Code state - what currently exists (v2 corrected)

**Core pipeline (`pre_model_trigger/*`):**
- `orchestrator.py`: `TriggerOrchestrator.evaluate_tick()` - central coordinator. Pipeline: normalize -> data quality gate -> vitals buffer -> rule engine -> fall pre-trigger -> optional model escalation -> response handler.
- `rule_engine.py`: `RuleEngine` class. Evaluates instant + profile + time-series rules tu `rules_config.json`.
- `fall_pre_trigger.py`: `FallPreTrigger.evaluate()` - Stage 1 fall detection. Loads `fall/fall_pipeline_wrist_config.json`. Emits `URGENT` (hard trigger) / `SEND_TO_RISK_MODEL` (soft trigger) actions.
- `vitals_buffer.py`: `VitalsHistoryBuffer(max_size=60)` ring buffer per device. 60 samples = ~5 min tai 5s tick (tick interval configurable per SIMULATOR_CORE Q5).
- `settings_provider.py`: `SystemSettingsProvider` - wraps hardcoded fallback thresholds tu `api_server/services/vitals_service.py`. `update_overrides()` method ton tai **nhung chua duoc wire (0 call sites)**. DB fetch = Phase 4 intent per F-PT-04 (b).
- `response_handler.py`: `ResponseHandler` static class. **Post-process only** (dedup + filter NORMAL + enrich metadata + sort by severity). Push-to-BE o runtime layer tren, khong thuoc ResponseHandler.
- `normalization.py`: `normalize_vitals_for_rules()` + `validate_data_quality()`. Called truoc rule eval trong `evaluate_tick`.
- `healthguard_client.py`: `HealthGuardAPIClient` HTTP client -> HealthGuard admin BE. Reserved; dependencies.py comment indicates actual risk inference uses `_trigger_risk_inference()` (correct endpoint + header).
- `mobile_telemetry_client.py`: `MobileTelemetryClient` HTTP client -> health_system BE. `X-Internal-Service: iot-simulator` header present. Used by `SleepRiskDispatcher`.

**Sleep dispatch (standalone, NOT wired in orchestrator):**
- `sleep_dispatch.py`: `SleepRiskDispatcher` - submits 43-field SleepRecord qua `MobileTelemetryClient`. Standalone utility (not called from `TriggerOrchestrator.evaluate_tick()`). Used externally by slice 3a sleep risk submission flow.

**Runtime config data files (load at startup/init):**
- `rules_config.json`: Declarative rule definitions (threshold ranges, severity per rule, profile adjustments). Loaded by `RuleEngine.__init__`.
- `fall/fall_pipeline_wrist_config.json`: Fall stage-1 thresholds (hard/soft trigger conditions, gyro/accel limits). Loaded by `FallPreTrigger.__init__`.

**Gating flags (2 env vars, BOTH default OFF):**

| Env var | Default | Controls |
|---|---|---|
| `PRE_MODEL_TRIGGER_ENABLED` | `0` | Activates `evaluate_tick` invocation trong tick loop |
| `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS` | `0` | When True, actions voi severity `SEND_TO_RISK_MODEL` / `URGENT` trigger HTTP model-api call |
| `USE_DB_THRESHOLDS` | `0` | Intended for Phase 4 DB fetch (NOT wired, placeholder only) |

**Mode matrix** (per `api_server/dependencies.py:1919-1938` logic):

| `PRE_MODEL_TRIGGER_ENABLED` | `ENABLE_MODEL_CALLS` | Orchestrator wired? | Mode |
|---|---|---|---|
| 0 | * | * | `off` |
| 1 | * | False | `off` + degraded `pre_trigger_misconfigured` |
| 1 | 0 | True | `shadow` (rules run, actions log only, NO modify `effects.pending_alerts`) |
| 1 | 1 | True | `active` (escalated actions trigger `_trigger_risk_inference` HTTP call) |

---

## Anh's decisions (Q1-Q5 revised v2)

### Q1: Pre-model trigger default mode? (**REVISED v2 per F-PT-03**)

**Decision v1:** Enable by default (flip env var, 30min).
**Decision v2 (F-PT-03 shadow chose):** **Default = shadow mode** (flip `PRE_MODEL_TRIGGER_ENABLED=1`, keep `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS=0`). Active mode = deferred Phase 4 separate decision.

**Rationale:**
1. Shadow mode = safe unblock. Rules + fall pre-trigger run va log, operator quan sat behavior truoc khi activate.
2. Active mode (2 flags ON) can dedup analysis voi existing `_push_alert_to_backend()` flow - risk duplicate alerts. Out of scope "enable by default" scope v1.
3. Phase 4 observability: FE display mode indicator (off / shadow / active) cho operator biet trigger state.

**Phase 4 tasks:**
1. Flip `.env.example` default `PRE_MODEL_TRIGGER_ENABLED=1` - 15min.
2. Smoke test: verify orchestrator shadow log trong dev runtime - 30min.
3. FE: show pre-model trigger mode badge (active/shadow/off/misconfigured) + last triggered + reason - 3-4h.
4. **Active mode decision:** post-shadow observation period + dedup analysis + active flip - separate future task.

### Q2: Threshold source? (**REVISED v2 per F-PT-04**)

**Decision v1:** Keep dual source (DB primary, hardcode fallback).
**Decision v2 (F-PT-04 intent-only chose):** **Hardcode = active source. DB fetch = intent for post-capstone.**

**Rationale:**
- Code reality: `update_overrides()` co nhung 0 call sites. `USE_DB_THRESHOLDS` env var co nhung khong co code path fetch DB.
- Capstone scope: hardcode fallbacks la enough. Admin UI threshold tuning = future enhancement when there's actual operator demand.
- `dependencies.py:1937` detection logic `threshold_source = "db" if day else "fallback"` false positive (dict always non-empty). **Must fix** to report accurate source hien tai.

**Phase 4 tasks:**
1. Fix `threshold_source` detection: track actual override state (e.g., `settings_provider.has_db_overrides: bool`) - 30min.
2. FE: threshold source indicator display "Hardcode defaults" (only value hien tai - no confusing "db" label) - 1h.
3. Document ADR D2 (future) cho DB fetch flow khi thuc su implement.

### Q3: Rule engine scope?

**Decision (unchanged):** Keep tach biet (vitals rules + motion rules = 2 domain rieng).

**Rationale:** Vitals anomaly != fall. Tach = clear separation of concerns.

### Q4: Severity taxonomy? (**REVISED v2 per ADR-015**)

**Decision v1:** Probability mapping (prob < 0.3 = normal, 0.3-0.7 = warning, > 0.7 = critical) per ADR D1 low/medium/high/critical.
**Decision v2 (per ADR-015 `alert-severity-taxonomy-mapping`):** **4-layer taxonomy + explicit mapping at each boundary.**

- **Layer 1 — Orchestrator internal (action vocab):** `NORMAL` / `WATCH` / `SEND_TO_RISK_MODEL` / `URGENT`. Semantic: "what to do with this event". Stays internal.
- **Layer 2 — IoT sim outbound alert (contract):** `normal` / `warning` / `critical`. Semantic: push-to-BE contract.
- **Layer 3 — BE ingest translation:** `_map_alert_severity()` maps Layer 2 -> Layer 4 values.
- **Layer 4 — BE DB canonical:** `low` / `medium` / `high` / `critical` (per canonical SQL CHECK constraint).

**Mapping (Layer 2 -> Layer 4 via Layer 3):**
- `normal` -> `low`
- `warning` -> `high`
- `critical` -> `critical`

**Rationale:** 4 layers = 4 purposes. Each boundary has explicit mapping. ADR-015 also identifies BE SQLAlchemy CheckConstraint drift (XR-002 bug) that must fix before full pipeline active.

**Phase 4 tasks:**
1. Fix BE SQLAlchemy CheckConstraint (XR-002) - 15min.
2. Fix `_map_alert_severity()` "normal" -> "low" output - 15min.
3. IoT sim `_decide_alert_severity()` already maps orchestrator actions -> Layer 2 outbound - verify correct per ADR-015.
4. Contract test: orchestrator URGENT -> outbound "critical" -> BE persist "critical" - 30min.

### Q5: Buffer size?

**Decision (unchanged):** Keep 60 samples.

**Rationale:** Tai default 5s tick = 5 min trend window. Neu operator raise tick interval qua `runtime settings` (per SIMULATOR_CORE Q5), buffer covers proportionally longer window. Phase 4 khong can change.

---

## Features moi

Khong co feature moi. Chi enable + surface existing functionality + add severity mapping layer + fix threshold source detection.

---

## Features DROP

Khong drop. Giu nguyen module structure. ADR-015 + F-PT-04 decisions clarify scope, khong delete code.

---

## Confirmed Intent Statement (v2)

> Pre-Model Trigger la decision layer tu dong detect vitals anomaly va co the trigger AI model calls.
>
> **Phase 4 default = SHADOW mode** (per F-PT-03): rules + fall pre-trigger evaluate tick-by-tick, actions log only, khong modify existing alert flow. Active mode (HTTP escalation to model-api) = separate future decision after dedup analysis.
>
> **Threshold source = hardcode** (per F-PT-04): `SystemSettingsProvider` wraps hardcoded fallbacks tu `vitals_service.py`. DB fetch = intent only, not wired. FE must report "Hardcode defaults" clearly (fix existing false-positive "db" label).
>
> **Severity taxonomy = 2 distinct vocabularies + mapping** (per ADR-015): internal action vocab (`NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT`) + canonical clinical vocab (`low/medium/high/critical` per ADR D1). Mapping applied at push layer.
>
> FE PHAI hien thi mode badge + threshold source + last trigger + reason de operator biet he thong dang lam gi.

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status | Evidence |
|---|---|---|---|
| P1 | Rule evaluation: vitals vuot threshold -> emit action voi internal severity | Confirmed | `rule_engine.py:RuleEngine.evaluate()` + `rules_config.json` |
| P2 | Fall pre-trigger: motion window suspicious -> emit action severity `URGENT` (hard) / `SEND_TO_RISK_MODEL` (soft) | Confirmed | `fall_pre_trigger.py:FallPreTrigger.evaluate()` + `fall/fall_pipeline_wrist_config.json` |
| P3 | Sleep dispatch = standalone utility (NOT wired in orchestrator) | Revised v2 | `sleep_dispatch.py:SleepRiskDispatcher`. Grep: 0 call sites from orchestrator. Feature scope "sleep AI record submission" (slice 3a). |
| P4 | Vitals buffering: 60 samples per device ring buffer | Confirmed | `vitals_buffer.py:VitalsHistoryBuffer(max_size=60)` |
| P5 | Threshold from hardcode (capstone); DB override = intent-only per F-PT-04 | Revised v2 | `settings_provider.py` + grep 0 `update_overrides` callers |
| P6 | Response handler = post-process only (dedup + filter + enrich + sort) | Revised v2 | `response_handler.py:ResponseHandler` static methods; Push-to-BE at runtime layer tren |
| P7 | Gating flag: `PRE_MODEL_TRIGGER_ENABLED` + `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS` (2 flags, 4-mode matrix) | Confirmed v2 | `dependencies.py:166-169, 698-715` |
| P8 | Default = shadow (Phase 4: flip `PRE_MODEL_TRIGGER_ENABLED=1`, keep `ENABLE_MODEL_CALLS=0`) | Phase 4 per F-PT-03 | Task pending |
| P9 | FE status display: mode badge + threshold source + last trigger + reason | Phase 4 | Tasks in Q1 + Q2 |
| P10 | Severity mapping layer: internal `NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT` -> canonical `low/medium/high/critical` per ADR-015 | Phase 4 per ADR-015 | Task pending |

---

## Impact on Phase 4 fix plan (v2)

Per F-PT-03 shadow + F-PT-04 intent-only + ADR-015 severity mapping:

| Phase 4 task | Status | Priority | Effort |
|---|---|---|---|
| Flip `.env.example` default `PRE_MODEL_TRIGGER_ENABLED=1` + smoke test | Per F-PT-03 | P1 | 45min |
| Fix `threshold_source` detection logic (track actual override state) | Per F-PT-04 | P1 | 30min |
| Create `map_orchestrator_to_canonical()` helper + test | Per ADR-015 | P1 | 1h |
| Apply severity mapping at `alert_service._push_alert_to_backend()` call site | Per ADR-015 | P1 | 30min |
| Contract test: orchestrator severity -> BE severity via mapper | Per ADR-015 | P1 | 30min |
| FE: mode badge display (off / shadow / active / misconfigured) | Per F-PT-03 | P2 | 3-4h |
| FE: threshold source indicator ("Hardcode defaults" only) | Per F-PT-04 | P2 | 1h |
| FE: last trigger + reason display | Phase 4 new | P2 | 1-2h |
| Review + simplify orchestrator (don dead paths) | Phase 4 new | P3 | 2-3h |
| Active mode activation (2 flags + dedup analysis + smoke test) | Deferred | P3 | 4h |
| DB threshold fetch flow (post-capstone) | Deferred | P4 | 3-4h |

---

## Cross-references

- **SIMULATOR_CORE:** Tick loop calls orchestrator per device per tick.
- **ETL_TRANSPORT:** Post-ADR-013 direct DB write for vitals; alert push still via HTTP (orchestrator output flows here when active mode).
- **Settings router:** `/api/sim/settings` exposes threshold config + trigger mode.
- **ADR D1:** Canonical severity vocabulary (`low/medium/high/critical`). Source: `phase_minus_1_summary.md`. IoT sim internal taxonomy maps TO this per ADR-015.
- **ADR-015:** Severity mapping decision - 2 taxonomies + mapping layer.
- **ADR-013:** IoT sim direct-DB vitals tick write (separate path, does not interact with orchestrator).
- **ADR-014:** HealthProfile taxonomy (unrelated, different area of IoT sim).
- **HealthGuard admin BE:** Future DB threshold endpoint (post-capstone per F-PT-04 deferred).
- **Bugs:** No bugs logged for this module specifically.

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 Q1-Q5 confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 3 HIGH + 3 MEDIUM + 2 LOW findings | Em |
| 2026-05-13 afternoon | ADR-015 accepted (severity taxonomy + mapping) | Anh |
| 2026-05-13 afternoon | F-PT-03 decision: default SHADOW mode | Anh |
| 2026-05-13 afternoon | F-PT-04 decision: threshold intent-only, hardcode as active | Anh |
| 2026-05-13 afternoon | v2 rewrite confirmed | Em (doc) |
