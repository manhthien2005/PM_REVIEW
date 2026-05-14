# Verification Report - `Iot_Simulator_clean / PRE_MODEL_TRIGGER`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/PRE_MODEL_TRIGGER.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** WARN - 3 HIGH + 3 MEDIUM + 2 LOW drift findings.
**Verdict (resolved 2026-05-13):** PASS v2 - ADR-015 accepted + F-PT-03 + F-PT-04 decisions + drift doc v2 rewritten. All HIGH findings resolved via ADR/decisions. MEDIUM all absorbed into v2 doc. Phase 4 backlog unblocked with clear scope.

---

## TL;DR

- **Module list:** Mostly correct. 11 files listed. 1 missing piece: `fall/fall_pipeline_wrist_config.json` (threshold config data, critical).
- **Q1 "enable by default" = misleading scope:** Env var `PRE_MODEL_TRIGGER_ENABLED=1` MOI LA bat evaluate_tick vao runtime. Nhung o shadow mode (actions log only, KHONG modify `effects.pending_alerts`). De thuc su "active" need 2 flags: `PRE_MODEL_TRIGGER_ENABLED=1` + `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS=1`. Doc chi nhac 1 flag -> Phase 4 task "30 min flip default" = UNDERSCOPED.
- **Q4 severity mapping SAI:** Doc claim "prob < 0.3 normal, 0.3-0.7 warning, > 0.7 critical" per ADR D1 (low/medium/high/critical). Code thuc te dung `NORMAL / WATCH / SEND_TO_RISK_MODEL / URGENT` - 4 values khac hoan toan. Khong co mapping tu probability sang severity trong module nay.
- **Q2 DB primary claim misleading:** `SystemSettingsProvider` co `update_overrides()` method nhung grep 0 call sites - DB override mechanism chua wire. Fallback hardcode la ACTIVE source hien tai, khong phai fallback.
- **Sleep dispatch scope ambiguous:** `sleep_dispatch.py` co `SleepRiskDispatcher` class nhung KHONG duoc wire vao TriggerOrchestrator - module rieng re. Doc claim "Detect sleep end -> trigger scoring" la intent nhung runtime behavior chua match.

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 Module file claims

| Claim | Code location | Verdict |
|---|---|---|
| `orchestrator.py`: TriggerOrchestrator - evaluate vitals -> decide action | `orchestrator.py:44-93` + `evaluate_tick()` line 91 | OK Dung |
| `rule_engine.py`: Threshold-based rules (HR, SpO2, BP ranges) | `rule_engine.py:178` RuleEngine class; loads `rules_config.json` | OK Dung |
| `fall_pre_trigger.py`: Motion window analysis -> decide if fall AI call needed | `fall_pre_trigger.py:FallPreTrigger.evaluate()` - hard/soft triggers per `fall_pipeline_wrist_config.json` | OK Dung |
| `sleep_dispatch.py`: Detect sleep session end -> trigger scoring | `sleep_dispatch.py:SleepRiskDispatcher` ton tai nhung khong wire vao orchestrator. Standalone class. Grep: 0 call sites trong `evaluate_tick()`, 0 in `_execute_pending_tick_publish`. | WARN Incomplete - scope disconnect |
| `vitals_buffer.py`: Rolling buffer 60 recent samples for trend analysis | `vitals_buffer.py:VitalsHistoryBuffer(max_size=60)` | OK Dung |
| `healthguard_client.py`: HTTP client -> HealthGuard admin BE | Grep verified (client ton tai) | OK Dung |
| `mobile_telemetry_client.py`: HTTP client -> health_system BE | Grep verified (client ton tai) + `X-Internal-Service` header present | OK Dung |
| `settings_provider.py`: Load thresholds from DB/env (dual source) | `settings_provider.py:SystemSettingsProvider`. Class co `update_overrides()` nhung KHONG co DB fetch logic trong file. DB load chua wire. | WARN Misleading - code chua load tu DB |
| `response_handler.py`: AI verdict -> alert severity mapping | `response_handler.py:ResponseHandler` static methods (dedup/filter/enrich/sort). KHONG co "AI verdict -> severity" mapping - chi post-process severity EXISTING. | WARN Misleading - mapping mo ta sai |
| `normalization.py`: Normalize vitals before rule evaluation | `orchestrator.py:105` calls `normalize_vitals_for_rules()` + `validate_data_quality()` | OK Dung |
| Gating flag: `PRE_MODEL_TRIGGER_ENABLED` env var (default: OFF) | `dependencies.py:166-169` + `.env.example:25` `PRE_MODEL_TRIGGER_ENABLED=0` | OK Default OFF confirmed |
| (NOT mentioned) Second gating flag `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS` | `dependencies.py` wires `enable_model_calls=False` hardcoded; env var `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS` kiem soat runtime `_orch_enable_model_calls` | FAIL Doc miss - critical flag cho "active" mode |
| (NOT mentioned) Fall config JSON | `fall_pre_trigger.py:29` loads `pre_model_trigger/fall/fall_pipeline_wrist_config.json` | WARN Doc miss config data file |
| (NOT mentioned) Rules config JSON | `rule_engine.py:35` loads `rules_config.json` | WARN Doc miss config data file |

**Module list verdict: 8/11 OK, 3/11 WARN misleading, 1 critical flag missing.**

### 1.2 Severity taxonomy drift (Q4 SAI)

**Doc Q4 claim:**
> Keep (prob < 0.3 = normal, 0.3-0.7 = warning, > 0.7 = critical). Match severity vocabulary da chot (ADR D1: low/medium/high/critical).

**Actual code `response_handler.py:21-26`:**
```
_SEVERITY_RANK: dict[str, int] = {
    "NORMAL": 0,
    "WATCH": 1,
    "SEND_TO_RISK_MODEL": 2,
    "URGENT": 3,
}
```

**Actual `TriggerActionItem.severity` values** tu `fall_pre_trigger.py` code + `_MODEL_ESCALATION_SEVERITIES` = `{"SEND_TO_RISK_MODEL", "URGENT"}` (`orchestrator.py:41-44`):

| Severity | Context | Use case |
|---|---|---|
| `normal` | Low severity data-quality log | Pass-through |
| `NORMAL` | Rule engine normal evaluation | Informational |
| `WATCH` | Rule engine watch-level alert | Monitor, no action |
| `SEND_TO_RISK_MODEL` | Fall soft-trigger, profile rule escalation | Forward to AI model |
| `URGENT` | Fall hard-trigger, critical vitals | Immediate alert |

**Compared to ADR D1 severity vocab** (per doc claim): `low / medium / high / critical` - 4 DIFFERENT values.

**Verdict:** FAIL Q4 claim sai tu 3 goc do:
1. Probability mapping (`prob < 0.3 normal, 0.3-0.7 warning, > 0.7 critical`) KHONG o trong module nay. Severity duoc assign declaratively trong rule config + fall_pre_trigger, khong map tu probability.
2. Code dung 4 enum (`NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT`) khac ADR D1 taxonomy (`low/medium/high/critical`).
3. Neu co mapping ADR D1 -> module enum thi o layer ngoai (alert push to BE), doc nham chuc nang.

**Cross-repo check:** Neu ADR D1 la authoritative cho alert severity o BE, cross-repo drift giua IoT sim internal severity va BE severity schema. Can kiem tra.

### 1.3 Runtime mode architecture (Q1 underscoped)

**Doc claim Q1:**
> Enable by default + FE display. Phase 4 task: `Flip env var default -> true (30 min)`

**Code architecture** (from `dependencies.py:1919-1938` + `schemas.py:501-525` comment):

```
Mode state = function of 2 flags + orchestrator wiring:

PRE_MODEL_TRIGGER_ENABLED    ENABLE_MODEL_CALLS    Orchestrator    Mode
          0                          *                 *           "off"
          1                          *               False         "off" + degraded "pre_trigger_misconfigured"
          1                          0               True          "shadow"
          1                          1               True          "active"
```

- **Shadow mode** (`schemas.py:501-521` comment): "rules + fall pre-trigger run but no HTTP escalation. Logged only. Does NOT modify `effects.pending_alerts`."
- **Active mode**: Actions with `severity >= SEND_TO_RISK_MODEL` trigger `_trigger_risk_inference()` HTTP POST.

**Verdict:** FAIL Q1 Phase 4 task "flip env var default -> true" chi chuyen mode OFF -> SHADOW. KHONG phai "active" - rules se run nhung actions chi log, khong effect alert flow. Operator expect "simulator TU phat hien vitals anomaly -> tu goi AI" (per Q1 rationale) nhung shadow mode khong do.

**Fix scope:** Phase 4 task phai specify:
- Option (a): Enable to shadow mode (flip `PRE_MODEL_TRIGGER_ENABLED=1`) - low risk, observe logs.
- Option (b): Enable to active mode (flip both `PRE_MODEL_TRIGGER_ENABLED=1` + `PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS=1`) - actions trigger real HTTP calls to BE + model-api.

Doc chua pick. 30min la enough cho (a), nhung (b) can them: smoke test + verify no duplicate alerts voi existing `_push_alert_to_backend()` flow + decide deduplication strategy.

### 1.4 DB threshold source claim (Q2 misleading)

**Doc claim Q2 P5:**
> Keep dual source (DB primary, hardcode fallback). Threshold from DB: dual source (DB primary, hardcode fallback).

**Actual code `settings_provider.py`:**
- `_FALLBACK_DAYTIME`, `_FALLBACK_SLEEP` from `api_server/services/vitals_service.py` (hardcode imports).
- `SystemSettingsProvider.__init__` copies fallback dicts.
- `update_overrides()` method exists but grep 0 call sites - no one calls this method.
- `USE_DB_THRESHOLDS` env var exists (`schemas.py:523`) but no corresponding code path fetches DB thresholds and calls `update_overrides()`.

**`dependencies.py:1937` logic:**
```
threshold_source = "db" if day else "fallback"
```
-> Labels "db" neu dict khong empty. Vi dict always non-empty tu `_FALLBACK_DAYTIME`, "db" label la FALSE POSITIVE.

**Verdict:** FAIL Q2 claim "DB primary, hardcode fallback" SAI. Reality: hardcode la active source hien tai, DB override never called. Phase 4 task "FE threshold source indicator" will display "db" incorrectly (vi logic kiem empty dict khong dung).

**Critical fix** needed truoc khi Q2 FE display meaningful:
1. Implement DB threshold fetch flow (Admin BE endpoint + IoT sim client + call `update_overrides()` on startup/refresh).
2. Fix `threshold_source` detection logic (track actual override source, not empty-check).

### 1.5 Sleep dispatch disconnected (P3 misleading)

**Doc claim P3:**
> Sleep dispatch: detect sleep end -> trigger scoring

**Code reality:**
- `sleep_dispatch.py:167` `SleepRiskDispatcher` class exists.
- `filter_to_sleep_record()` + `dispatch()` methods present.
- Orchestrator KHONG instantiate SleepRiskDispatcher. Grep `SleepRiskDispatcher(` = 0 hits trong `api_server/`.
- Sleep detection + dispatch logic la trong `api_server/services/sleep_service.py` (different module, different concern).

**Verdict:** WARN P3 incomplete - `sleep_dispatch.py` la helper module cho feature scope "sleep AI record submission" (slice 3a per risk-contract baseline doc), khong phai orchestrator concern. Phase 4 nen:
- (a) Document ro sleep_dispatch la standalone utility, khong thuoc orchestrator pipeline; HOAC
- (b) Wire `SleepRiskDispatcher` vao orchestrator neu intent la "trigger scoring".

### 1.6 Response handler scope drift (P6)

**Doc claim P6:**
> Response mapping: AI verdict -> alert severity -> push to BE

**Actual `response_handler.py`:**
- Static methods: `deduplicate`, `filter_actionable`, `sort_by_severity`, `enrich_metadata`, `process`.
- KHONG co "AI verdict -> severity mapping". ResponseHandler takes list of `TriggerActionItem` (which ALREADY have severity assigned by rule_engine/fall_pre_trigger) and post-processes.
- KHONG push to BE. Push to BE happens in `_execute_pending_tick_publish()` / `_push_alert_to_backend()` layer above.

**Verdict:** WARN P6 wording sai. Correct description:
> Response handler: post-process actions (dedup + filter NORMAL + enrich metadata + sort by severity). Final push to BE handled by runtime layer.

### 1.7 Config JSON files missing trong doc

Code load 2 JSON configs:
- `pre_model_trigger/rules_config.json` (rule_engine)
- `pre_model_trigger/fall/fall_pipeline_wrist_config.json` (fall_pre_trigger)

Doc "Code state" khong list. Modifying these JSONs = changing runtime behavior. Config data la critical code dependency.

---

## 2. Issues enumerated (prioritized)

### CRITICAL - Block Phase 4 implementation

**C1. Q4 severity taxonomy claim SAI - probability mapping khong ton tai + enum khac ADR D1**
- **Evidence:** `response_handler.py:_SEVERITY_RANK` = `NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT`. ADR D1 vocab (per doc claim) = `low/medium/high/critical`.
- **Impact:** If BE alert severity schema follow ADR D1, IoT sim push alerts with wrong vocab -> BE validation reject hoac silent miscategorize. Cross-repo contract break.
- **Fix direction:**
  1. Cross-check actual ADR D1 (neu co) content - verify vocabulary decision.
  2. Identify mapping point IoT sim severity -> BE severity (likely o `_push_alert_to_backend()` layer).
  3. Revise Q4 claim specificity: "Internal orchestrator severity (NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT) mapped to BE alert severity (low/medium/high/critical) at push layer".
- **Effort:** 30min verify + 30min doc update; 1-2h code if mapping layer missing.

### HIGH - Phase 4 scope underestimation

**H1. Q1 "flip env var 30min" scope underestimated - 2 flags needed + shadow/active mode decision**
- **Evidence:** Section 1.3 mode state table. 30min chi enough cho shadow mode.
- **Impact:** Operator expect "simulator auto-detect + call AI" per Q1 rationale. Shadow mode = logs only, no HTTP escalation. Active mode = real calls but conflict with existing `_push_alert_to_backend()` flow (dedup concern).
- **Fix direction:** Anh decide:
  - Shadow default only (low risk, 30min flip)?
  - Active default (2 flags flip + dedup analysis + smoke test, ~4h)?
- **Effort:** Decision 20min + doc update 15min. Implementation shadow 30min / active 4h.

**H2. Q2 DB threshold source NOT wired - "db primary" claim misleading**
- **Evidence:** Section 1.4. `update_overrides()` 0 call sites. `threshold_source = "db" if day else "fallback"` = false positive.
- **Impact:** Phase 4 task "FE threshold source indicator" display wrong info. Operator see "db" but actually hardcode values.
- **Fix direction:** Choose:
  - (a) Wire DB fetch flow (Admin BE endpoint + periodic refresh) - effort M 3-4h.
  - (b) Document as "intent for future, hardcode-only today" - effort S 20min doc + revise FE spec.
- **Effort:** Decision + scope Phase 4 per choice.

**H3. P6 ResponseHandler "AI verdict -> severity" description SAI + P3 sleep_dispatch disconnected**
- **Evidence:** Section 1.6 + 1.5.
- **Impact:** Doc reader expect ResponseHandler = severity mapping layer; actually post-processing only. Sleep_dispatch documented as trigger component but la standalone utility.
- **Fix direction:** Doc rewrite P3, P6 descriptions:
  - P6: "ResponseHandler post-process actions: dedup + filter NORMAL + enrich + sort. Push-to-BE at runtime layer."
  - P3: "sleep_dispatch.py: Standalone utility for `SleepRiskDispatcher` - submit 43-field SleepRecord. NOT wired in TriggerOrchestrator pipeline."
- **Effort:** Doc 20min.

### MEDIUM - Scope / doc gaps

**M1. Config JSON files chua list**
- **Evidence:** `rules_config.json`, `fall/fall_pipeline_wrist_config.json` loaded runtime, not in doc module list.
- **Impact:** Contributor tuong engine logic o code only. Actual behavior = code + JSON config.
- **Fix direction:** Add config files vao "Code state" section as "runtime dependencies".
- **Effort:** Doc 10min.

**M2. Second gating flag (`PRE_MODEL_TRIGGER_ENABLE_MODEL_CALLS`) not documented**
- **Evidence:** Section 1.1 table + `.env.example:29`.
- **Impact:** Operator chi biet 1 flag, se confuse tai sao orchestrator khong call AI du da bat.
- **Fix direction:** Doc both flags + mode state table per Section 1.3.
- **Effort:** Doc 15min.

**M3. Cross-repo severity mapping layer missing doc**
- **Evidence:** C1 + potential BE severity schema drift.
- **Fix direction:** Paired with C1 - add cross-ref section documenting mapping layer.
- **Effort:** Included in C1.

### LOW - Wording / minor

**L1. Healthguard_client + mobile_telemetry_client brief descriptions**
- Only module name + generic "HTTP client" description. Could benefit from endpoint/auth header details.
- Effort 10min.

**L2. Q5 buffer 60 samples "5-minute trend at 5s tick" - tick interval configurable**
- `session.py` tick interval configurable (per Q5 of this doc). If operator raises tick to 10s, buffer = 10min, not 5. Minor wording tweak.
- Effort 5min.

---

## 3. Fix backlog (prioritized) - status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-PT-01 | Verify ADR D1 severity vocab + fix Q4 taxonomy claim (C1) | P0 | 30min verify + 30min doc | **DONE** - ADR D1 verified in `phase_minus_1_summary.md`; ADR-015 accepted |
| F-PT-02 | Document severity mapping layer (orchestrator -> push layer -> BE) (C1/M3) | P0 | 30min doc | **DONE** - ADR-015 Decision section + drift doc v2 P10/Q4 |
| F-PT-03 | Decide Q1 default: shadow or active? (H1) | P1 | 20min decision + 15min doc | **DONE** - SHADOW chose; Phase 4 task rescoped |
| F-PT-04 | Decide Q2 DB wire implement or intent-only (H2) | P1 | 20min decision + code scope | **DONE** - Intent-only chose; fix detection logic Phase 4 |
| F-PT-05 | Revise P3 + P6 wording (H3) | P1 | 20min doc | **DONE** - v2 Code state + Behaviors table revised |
| F-PT-06 | Add second flag (ENABLE_MODEL_CALLS) + mode state table (M2) | P2 | 15min doc | **DONE** - v2 Gating flags table + Mode matrix |
| F-PT-07 | Add config JSON files to module list (M1) | P2 | 10min doc | **DONE** - v2 "Runtime config data files" section |
| F-PT-08 | Minor wording L1-L2 | P3 | 15min doc | **DONE** - v2 buffer size wording + client descriptions expanded |

**Status summary:** 8/8 DONE.

**Total effort spent today:** ~3h (verify report + ADR-015 + decisions + drift doc v2 rewrite + INDEX).
**Remaining (Phase 4 code branch):** Per drift doc v2 backlog (~12-15h total: shadow flip + mapper + FE displays + threshold fix).

---

## 4. Cross-repo impact

### Affected docs/specs
- **ADR D1 (severity vocab)** - needs location verified. If exists, cross-check taxonomy alignment.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/ETL_TRANSPORT.md` - alert push layer interacts with orchestrator output.
- `PM_REVIEW/AUDIT_2026/tier1/api_contract_v1.md` - BE alert endpoint severity schema.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` - tick loop feeds orchestrator.

### Affected code repos
- `Iot_Simulator_clean/api_server/dependencies.py` - mode state logic + orchestrator wiring.
- `Iot_Simulator_clean/api_server/routers/settings.py` - trigger_mode derivation.
- `health_system/backend/app/models/` - BE alert severity enum (cross-check).
- `HealthGuard/backend` - Admin BE threshold endpoint (if Q2 DB wire chosen).

### ADRs potentially needed
- **ADR-015 (pending):** Severity taxonomy mapping IoT sim orchestrator <-> BE alert (if ADR D1 location confirmed + mismatch real).

---

## 5. Next steps - em de xuat

1. **Immediate verify (10min):** Em grep ADR folder to find ADR D1 actual content. Neu khong co ADR D1 -> Q4 claim reference invalid.
2. **Decisions needed from anh:**
   - F-PT-03: Q1 default = shadow hay active mode?
   - F-PT-04: Q2 Phase 4 = wire DB implement, hay document intent-only?
3. **After decisions:** Em apply all doc fixes (F-PT-01 through F-PT-08) -> drift doc v2.
4. **Phase 4 backlog adjust:** Per Q1/Q2 decisions.

**Em khong edit drift doc trong phase verify. Output verify nay la input cho anh decide.**

---

## Appendix - evidence index

- Orchestrator: `pre_model_trigger/orchestrator.py:44-243`
- Severity enum: `pre_model_trigger/response_handler.py:21-26`
- Mode state logic: `api_server/dependencies.py:1919-1938`
- Orchestrator runtime wiring: `api_server/dependencies.py:684-721`
- Orchestrator invocation: `api_server/dependencies.py:2808-2830`
- Shadow mode comment: `api_server/schemas.py:501-525`
- Env flags: `.env.example:25-32`
- Settings DB claim vs reality: `pre_model_trigger/settings_provider.py` vs grep 0 `update_overrides` callers
- Sleep dispatch: `pre_model_trigger/sleep_dispatch.py:SleepRiskDispatcher` (standalone, not wired)
- Config JSON: `pre_model_trigger/fall/fall_pipeline_wrist_config.json`, `pre_model_trigger/rules_config.json`
