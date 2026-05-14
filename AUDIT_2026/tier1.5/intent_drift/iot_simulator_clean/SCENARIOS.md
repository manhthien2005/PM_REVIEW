# Intent Drift Review — Iot_Simulator_clean / SCENARIOS

**Status:** Confirmed v2 (2026-05-13) — S7 scope refined + cross-reference wording fixed + Q5 linked to ADR-014 + push-date 365 cap documented + PRE_MODEL_TRIGGER shadow note
**Repo:** `Iot_Simulator_clean`
**Module:** SCENARIOS
**Related UCs (old):** N/A (internal tooling — no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/SCENARIOS_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** Q1-Q5 confirmed, 13 scenarios + 6 fall variants verified.
- **v2 (2026-05-13 afternoon):** Verify pass phat hien:
  - M1 S7 "side-effect routing" scope narrower than claim (3 scenarios actual vs generic wording).
  - M2 Cross-reference sai 3 goc: "HealthGuard BE" -> health_system BE; "transport layer" -> unused per ADR-013; "scenarios push alerts" -> scenarios only trigger side-effects.
  - M3 Q5 "named profiles" superseded by ADR-014 HealthProfile - cross-ref should point to ADR-014.
  - L1 Push-date 365 days cap not documented (distinct from backfill 90 days).
  - L2 PRE_MODEL_TRIGGER cross-ref needs shadow-mode note per F-PT-03.

---

## Muc tieu doc nay

Capture intent cho Scenarios module — bo kich ban y te pre-defined cho operator inject.
Internal tooling, khong co UC cu.

---

## Code state — what currently exists

- `api_server/routers/scenarios.py`: BUILT_IN_SCENARIOS manifest (13 scenarios, 4 categories)
  - Vitals (5): normal_rest, tachycardia_warning, hypoxia_critical, hypertension_moderate, normal_walking
  - Fall (3): fall_high_confidence, fall_false_alarm, fall_no_response
  - Sleep (3): good_sleep_night, fragmented_sleep, elderly_normal
  - Risk (2): high_risk_cardiac, medium_risk_general
- Schema: `ScenarioOption` pydantic — id, name, category, description, expectedOutcome, severity, keySignals, followUp
- `api_server/dependencies.py:218-287` `_FALL_VARIANT_POLICIES`: 6 variants (false_fall, slip_recovery, fall_brief, fall_from_bed, confirmed, fall_no_response) + default fallback = confirmed (for legacy fall_1/fall_generic)
- `api_server/routers/scenarios.py:305-315` `_SCENARIO_RISK_INJECTS`: 3 auto risk inject mappings (hypoxia_critical, high_risk_cardiac, medium_risk_general only)
- Sleep backfill: `/scenarios/sleep/backfill` bulk N days (1-90), BackgroundTask pattern (CRITICAL #3 fix)
- Sleep push-date: `/scenarios/sleep/push-date` single day, synchronous, 365-day cap
- Risk inject: `/events/risk-inject` force risk score
- Apply scenario: `/scenarios/apply` atomic BE-driven (FE khong fire follow-on calls per Module B.2 comment)

---

## Anh's decisions

### Q1: Scenario coverage?

**Decision (unchanged):** Keep 13 scenarios. Du cho capstone.

**Rationale:** Cover main flows: normal/warning/critical per category. Edge cases quan trong da co (false_fall, fall_no_response, fragmented_sleep, hypoxia_critical). Them = them maintenance.

### Q2: Fall variant policy — 6 variants?

**Decision (unchanged):** Keep 6. Du cover spectrum false positive -> true critical.

**Rationale:** 6 variants test 6 branches khac nhau trong BE (below/above confidence threshold, countdown/no-countdown, cancel/no-cancel). Them = diminishing returns.

### Q3: Sleep backfill + push-date limits? (**EXPANDED v2 per L1**)

**Decision (unchanged):** Keep 90 days max cho backfill, 365 days cap cho push-date.

**Rationale:** 
- `/scenarios/sleep/backfill`: bulk backfill 1-90 days via BackgroundTask. AI risk scoring can ~30 days minimum, 90 = buffer.
- `/scenarios/sleep/push-date`: single day synchronous, 365 days cap = demo/test older data without overloading backend.
- 2 endpoints khac purpose: bulk historical population vs surgical single-day insertion.

### Q4: Scenario manifest — static hay dynamic?

**Decision (unchanged):** Keep static (hardcoded list).

**Rationale:** Dynamic = can CRUD UI + persistence + validation. Over-engineering cho testing tool. Static du cover demo needs.

### Q5: FE scenario display? (**LINKED TO ADR-014 v2 per M3**)

**Decision:** Them "expected outcome preview" per scenario x active HealthProfile.

**Rationale:** Operator muon biet "apply scenario X len HealthProfile Y = thay gi?" truoc khi apply. 

**Data source:** Per ADR-014, `HealthProfile.scenario_response` dict provides magnitude multiplier for each scenario_id. FE preview consume:
- `HealthProfile.scenario_response[scenario_id]` -> response magnitude.
- `ScenarioOption.keySignals` + `ScenarioOption.expectedOutcome` -> display text.
- Compute preview: "Apply `tachycardia_warning` to `elderly_hypertension` = HR spike x1.5 from baseline 75-85 -> ~160 bpm (critical)".

**Implementation dependency:** ADR-014 HealthProfile catalog must be implemented first (Phase 4 task from SIMULATOR_CORE v2 backlog).

---

## Features moi

Khong co feature moi. FE enhancement (Q5) link voi ADR-014 HealthProfile.

---

## Features DROP

Khong co.

---

## Confirmed Intent Statement (v2)

> Scenarios la bo kich ban y te pre-defined (13 scenarios, 4 categories) ma operator inject vao device de test downstream behavior. Static manifest, BE-driven apply (atomic). 
>
> Fall variants (6) test full SOS pipeline spectrum. Sleep backfill bulk (90 days max) + push-date single (365-day cap) cho history generation. 
>
> Side-effect routing narrow: chi 3 scenarios co auto risk inject (hypoxia_critical + 2 risk scenarios). Fall + sleep side-effects di qua separate mechanisms (`runtime.set_device_scenario()` + fall variant policy table).
>
> FE can show expected outcome preview per scenario x HealthProfile combination (per ADR-014). Scenarios themselves khong push alerts - trigger BE side-effects, alerts emit downstream qua `alert_service.py` direct httpx to health_system BE `/mobile/telemetry/alert` (per ADR-013 transport layer unused).

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status |
|---|---|---|
| S1 | Scenario manifest: 13 static scenarios, FE render metadata | Confirmed |
| S2 | Apply scenario: atomic, BE-driven side-effects (fall + sleep + risk inject in single route call) | Confirmed |
| S3 | Fall variant policy: 6 variants, countdown/cancel/alert behavior per table | Confirmed |
| S4 | Sleep backfill: bulk N days (1-90), BackgroundTask pattern | Confirmed |
| S5 | Sleep push single-date: 1 day, synchronous, 365-day cap | Confirmed v2 |
| S6 | Risk inject: force risk score per device (manual trigger) | Confirmed |
| S7 | Side-effect routing: **3 scenarios** (hypoxia_critical, high_risk_cardiac, medium_risk_general) auto risk inject via `_SCENARIO_RISK_INJECTS` table. **Fall/sleep side-effects go through separate mechanisms** (`runtime.set_device_scenario()` + fall variant policy + followUp metadata) | Confirmed v2 (scope refined) |
| S8 | FE: expected outcome preview per scenario x HealthProfile (per ADR-014 HealthProfile.scenario_response) | Phase 4 (link ADR-014 HealthProfile) |

---

## Impact on Phase 4 fix plan

| Phase 4 task | Status | Priority | Effort | Dependency |
|---|---|---|---|---|
| FE: expected outcome preview (scenario x HealthProfile matrix) | New | P2 | 3-4h | ADR-014 HealthProfile catalog implemented first |
| No other SCENARIOS tasks identified | — | — | — | — |

---

## Cross-references (v2 corrected)

- **SIMULATOR_CORE + ADR-014:** `HealthProfile.scenario_response` is data source for Q5 FE preview. HealthProfile catalog must be implemented first.
- **PRE_MODEL_TRIGGER:** Per F-PT-03 decision, default mode = shadow (actions log only, no HTTP escalation). Manual scenario apply remains primary trigger path. Active mode deferred.
- **SLEEP_AI_CLIENT:** Sleep AI scoring consumed by sleep service, indirectly tied to scenario apply via `runtime.set_device_scenario()` sleep path.
- **Fall variant policy:** `dependencies.py:218-287` `_FALL_VARIANT_POLICIES` table - 6 entries + default fallback.
- **Sleep service:** `api_server/services/sleep_service.py` handles backfill logic + scoring.
- **Boundary contract (corrected v2):** Scenario apply triggers BE side-effects (fall event / risk inject / sleep phase). Downstream alerts (if any) emit via `alert_service.py` direct `httpx` to health_system BE `/mobile/telemetry/alert`. Transport layer per ADR-013 is NOT involved. HealthGuard admin BE (port 5000) not directly touched by scenario apply.
- **ADRs:**
  - ADR-013 (transport layer unused at runtime) - scenarios alert path unaffected.
  - ADR-014 (HealthProfile catalog) - Q5 FE preview dependency.
  - ADR-015 (severity mapping) - not directly applicable; scenario apply path uses direct severity strings in `alert_service.py`.

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 Q1-Q5 confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 3 MEDIUM + 2 LOW findings | Em |
| 2026-05-13 afternoon | Anh approved F-SC-01 through F-SC-05 doc fixes | Anh |
| 2026-05-13 afternoon | v2 rewrite | Em (doc) |
