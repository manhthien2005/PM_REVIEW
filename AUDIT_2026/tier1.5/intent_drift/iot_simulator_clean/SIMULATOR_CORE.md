# Intent Drift Review - Iot_Simulator_clean / SIMULATOR_CORE

**Status:** Confirmed v2 (2026-05-13) - Q1 + Features moi REVISED per ADR-014; C6 state machine + module list fixed per verify pass
**Repo:** `Iot_Simulator_clean`
**Module:** SIMULATOR_CORE
**Related UCs (old):** N/A (internal tooling - no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass + ADR-014)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/SIMULATOR_CORE_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** Q1-Q6 chot, status Confirmed.
- **v2 (2026-05-13 afternoon):** Verify pass phat hien:
  - H1 C6 state machine claim SAI (5 states linear) vs reality (7 activity_state + 3 orthogonal fields).
  - H2 `sleep_ai_client.py` miss trong doc + thieu IS-001 reference.
  - H3 `vitals_generator.py` + `motion_generator.py` la shim 3 dong (re-export).
  - M1 Phase 4 "named health profiles" scope clash voi 3 existing concepts (MOCK_PERSONAS + PersonaConfig + SLEEP_VITALS_PROFILES) -> **Resolved by ADR-014 (unified HealthProfile Option X).**
  - M3 C3 scope boundary fuzzy.
  - M4 D-020 cross-repo: fall_ai_client + sleep_ai_client thieu `X-Internal-Service` header.
- Doc rewritten theo verify findings + ADR-014.

---

## Muc tieu doc nay

Capture intent cho Simulator Core engine - bo sinh du lieu y te gia lap. Internal tooling, khong co UC cu.

---

## Code state - what currently exists (v2 corrected)

**Core engine files:**
- `session.py`: `SimulatorSession` class - tick loop + device orchestration. Tick goi `PersonaEngine.tick()` + `VitalsGenerator.generate_tick()` + `MotionGenerator.generate()` per device.
- `persona_engine.py`: `Persona` dataclass (age/weight/height/gender/seed) + `PersonaEngine` (state transitions + 9 inject_event types + battery drain factors).
- `generators.py`: Contains **2 classes** - `VitalsGenerator` (line 45) + `MotionGenerator` (line 196). Generate HR/SpO2/BP/temp (vitals) + 3-axis accel/gyro (motion).
- `vitals_generator.py` / `motion_generator.py`: **Re-export shims** (3-line modules) forwarding to `generators.py`. No logic in these files.
- `dataset_registry.py`: `DatasetRegistry` class - load parquet/jsonl artifacts + 30+ query methods (vitals baseline / motion windows / fall events / sleep sessions / demographics).
- `sleep_vitals_enricher.py`: `enrich_sleep_record()` + `SLEEP_VITALS_PROFILES` (4 presets: good_sleep_night / fragmented_sleep / sleep_apnea_mild / sleep_apnea_severe). **Per ADR-014 se fold vao HealthProfile.sleep_profile.**

**AI clients (cross-repo):**
- `fall_ai_client.py`: HTTP client -> model-api `POST /api/v1/fall/predict`. Availability probe `GET /api/v1/fall/model-info`. **Header: `Content-Type: application/json` only - THIEU `X-Internal-Service` header (D-020).**
- `sleep_ai_client.py`: HTTP client -> model-api. **Bug IS-001: POST `/predict` (wrong path) thay vi `/api/v1/sleep/predict`.** Health probe `GET /health`. Also missing `X-Internal-Service` header.

**Presets (deprecated per ADR-014):**
- `mock_personas.py`: `MOCK_PERSONAS` list - 5 demographic presets (young_healthy / middle_aged / elderly / obese / underweight). **Comment: "Not currently auto-imported. Available for manual use / future API integration". Status: DEAD CODE, scheduled DELETE per ADR-014.**

**Persona state schema (`persona_engine.py:20-26`):**
```
@dataclass
class DeviceState:
    activity_state: str = "resting"
    fall_variant: str | None = None
    stress_state: str | None = None
    sleep_phase: str | None = None
    battery_level: int = 100
    is_online: bool = True
```

**`activity_state` (7 values)** tu `transition_to` transitions + battery drain factors:
`resting`, `walking`, `running`, `standing`, `fall`, `recovery`, `sleeping`.

**Event types qua `inject_event` (9 types):** `fall_detected`, `sleep_start`, `sleep_end`, `sleep_phase_change`, `low_battery`, `device_offline`, `device_online`, `stress`, `neutral`.

**Orthogonal state axes:** `fall_variant` (7+ variants), `stress_state` (stress/neutral/None), `sleep_phase` (light/deep/rem/etc.).

---

## Anh's decisions (Q1-Q6 - revised v2)

### Q1: Data source priority - synthetic hay dataset-driven? (**REVISED v2 per ADR-014**)

**Decision:** Keep 2 modes (synthetic + dataset-bound). Phase 4 enhancement: **unified `HealthProfile` catalog** (per ADR-014 Option X) replace MOCK_PERSONAS, fold SLEEP_VITALS_PROFILES vao sub-catalog.

**Rationale:** Synthetic boot nhanh (khong can artifacts). Dataset-bound cho realistic AI testing. HealthProfile unified approach unblock Phase 4 "named health profiles" scope + giai quyet 3-concept fragmentation.

**Scope Phase 4 (per ADR-014):**
- 5 HealthProfile presets: `young_healthy`, `elderly_healthy`, `elderly_hypertension`, `elderly_cardiac_risk`, `elderly_diabetic`.
- FE simulator-web: profile selector + description card + scenario preview.
- BE API: `GET /api/v1/sim/health-profiles`.
- Migration: MOCK_PERSONAS delete; SLEEP_VITALS_PROFILES reference by HealthProfile.sleep_profile.
- PersonaConfig schema add field `health_profile: str | None`.

### Q2: Persona model - do phuc tap nao?

**Decision (unchanged):** Keep simple (age / weight / height / gender / seed -> baseline ranges).

**Rationale:** Capstone khong can complex comorbidity model. 5 params + HealthProfile wrapper (Q1) du de demo personalized vitals. PersonaConfig schema add 1 optional field (`health_profile`) - backward compat.

### Q3: Device state machine - du states chua? (**REVISED v2 per H1**)

**Decision v1 (2026-05-13 morning):** 5 states linear (provisioned / streaming / sleeping / fall_countdown / sos_active).

**Decision v2 (2026-05-13 afternoon, per verify H1):** **State machine KHONG phai 5 states linear.** La:

- **`activity_state` enum (7 values):** `resting / walking / running / standing / fall / recovery / sleeping`. Co transitions co structure:
  - `fall` -> `recovery` (auto after `FALL_DURATION_TICKS=10`)
  - `recovery` -> `standing` (auto after `RECOVERY_DURATION_TICKS=20`)
  - Other transitions qua `inject_event()` (9 event types).
- **Orthogonal state fields:** `fall_variant` (7+ variants for fall type classification), `stress_state` (stress/neutral/None), `sleep_phase` (light/deep/rem).
- **Additional properties:** `battery_level` (0-100, drain rate per activity), `is_online` (bool).

**KHONG co** `provisioned` / `streaming` / `fall_countdown` / `sos_active` states trong persona engine - do la **mobile app UI lifecycle states** (thuoc `health_system/lib/features/device/`), khac domain khac repo.

**Rationale:** Cleanup confusion giua 2 state concepts khac nhau. IoT sim engineer doc spec se hieu dung persona engine state model.

### Q4: Fall AI client - keep trong simulator_core?

**Decision (unchanged):** Keep. Integral part of fall simulation flow.

**Rationale:** Fall inject -> call AI -> get verdict -> update state. Move ra ngoai = break encapsulation.

**Note v2:** Current `fall_ai_client.py` + `sleep_ai_client.py` deu **thieu `X-Internal-Service: iot-simulator` header** (D-020 + D-022). Phase 4 task paired voi D-013 fix (model-api enforce internal secret).

### Q5: Tick interval - configurable?

**Decision (unchanged):** Keep configurable (runtime settings, default ~5s).

**Rationale:** Demo flexibility - show 1h data trong 5 phut bang cach tang speed.

### Q6: Noise model?

**Decision (unchanged):** Keep simple (Gaussian noise + scenario modulation).

**Rationale:** Physiological noise model = research-level complexity. Gaussian + dataset binding da du realistic cho AI testing.

---

## Features moi (Phase 4 enhancement) (**REVISED v2 per ADR-014**)

### Unified HealthProfile catalog (replace MOCK_PERSONAS, fold SLEEP_VITALS_PROFILES)

**Intent:** Operator chon `HealthProfile` truoc khi simulate. Profile = combination of demographics + conditions + response magnitudes.

**Profile schema (per ADR-014):**
```
class HealthProfile:
    label: str               # "elderly_hypertension"
    display_name: str        # "Elderly Hypertensive (72y)"
    description: str         # FE display blurb
    demographics: dict       # age range, weight, height, gender hint
    baseline_shifts: dict    # {"hr": (+5, +10), "bp_sys": (+20, +30)}
    scenario_response: dict  # {"tachycardia": 1.5, "bradycardia": 1.3}
    sleep_profile: dict | None  # ref to SLEEP_VITALS_PROFILES entry
    conditions: list[str]    # tags
```

**5 starter presets** (per ADR-014 Notes): young_healthy / elderly_healthy / elderly_hypertension / elderly_cardiac_risk / elderly_diabetic.

**Example:**
- `elderly_hypertension` (72y, hypertension): HR baseline 75-85, BP 140/90. Apply tachycardia -> HR x1.5 = spike 160.
- `young_healthy` (25y, no conditions): HR baseline 65-75, BP 120/80. Apply tachycardia -> HR x0.8 = spike 100 (milder).

**FE simulator-web:**
- Profile selector dropdown.
- Description card: demographics + baseline ranges.
- Scenario preview: show `scenario_response[scenario_id]` magnitude truoc khi apply.

**Migration steps (per ADR-014 follow-up):**
1. NEW `simulator_core/health_profiles.py`.
2. MODIFY `schemas.py` `PersonaConfig` add optional `health_profile: str | None`.
3. MODIFY `sleep_service._select_session_for_scenario()` lookup by HealthProfile.sleep_profile.
4. MODIFY `_build_db_device_persona()` auto-match HealthProfile by age.
5. BE API `GET /api/v1/sim/health-profiles`.
6. FE selector components.
7. DELETE `mock_personas.py` (verify 0 import grep).
8. Test: API contract + scenario_response matrix.

---

## Features DROP

- **MOCK_PERSONAS** (`mock_personas.py`): Per ADR-014 decision. Dead code 6+ thang, demographics merge vao HealthProfile. Safe delete (comment confirmed "manual use / future" + 0 auto-imports).

---

## Confirmed Intent Statement (v2)

> Simulator Core la engine sinh du lieu y te gia lap realistic. Combine **persona engine** (7 activity states + 3 orthogonal state fields) + **medical datasets** (qua DatasetRegistry load parquet artifacts) + **noise models** (Gaussian) de output vitals/motion streams giong smartwatch that.
>
> Support 2 modes: **synthetic** (quick demo) va **dataset-bound** (realistic AI testing).
>
> Fall + Sleep AI inference qua HTTP clients -> healthguard-model-api (`/api/v1/fall/predict` OK, `/api/v1/sleep/predict` **bug IS-001 chua fix**).
>
> Phase 4 enhancement (per ADR-014): **unified `HealthProfile` catalog** (5 presets) replace dead MOCK_PERSONAS, fold SLEEP_VITALS_PROFILES vao sub-catalog. FE simulator-web display expected outcome per scenario x profile.
>
> **Scope boundary:** Scenario orchestration (apply/compose/persist) o layer **tren** simulator_core (`api_server/services/session_service.py`, `api_server/routers/scenarios.py`) - xem SCENARIOS module.

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status | Evidence |
|---|---|---|---|
| C1 | Persona-based generation: age/weight/gender -> baseline ranges | Confirmed | `persona_engine.py:10-16` Persona dataclass; `generators.py:45-131` VitalsGenerator |
| C2 | Dataset-driven mode: bind real medical data tu artifacts | Confirmed | `dataset_registry.py:50-247` query methods; `session.py:28-35` DataBinding with `source_mode="replay"` |
| C3 | Event-level state transitions qua `PersonaEngine.inject_event()` (9 event types) | Confirmed v2 | `persona_engine.py:85-102`. Scope **event-level only** - full scenario orchestration o `session_service.py` (out of simulator_core scope) |
| C4 | Motion generation: 3-axis accel/gyro arrays; **can return None** if activity khong match dataset | Confirmed v2 | `generators.py:201-215` MotionGenerator.generate() |
| C5 | Tick-based streaming: configurable interval (runtime settings) | Confirmed | `session.py:52-90` SimulatorSession.tick() |
| C6a | Persona engine state model: `activity_state` (7 values) + 3 orthogonal fields (fall_variant / stress_state / sleep_phase) + battery_level + is_online | Confirmed v2 | `persona_engine.py:20-26` DeviceState |
| C6b | Mobile app device UI lifecycle states (provisioned/streaming/sos_active/etc.) - **OUT OF scope simulator_core**, thuoc `health_system/lib/features/device/` | Confirmed v2 | Cross-reference mobile DEVICE module (different domain) |
| C7 | Fall AI integration: POST `/api/v1/fall/predict` + probe `/api/v1/fall/model-info`. **THIEU X-Internal-Service header (D-020)** | Partial v2 | `fall_ai_client.py:predict()` + `check_availability()` |
| C8 | Sleep AI integration: POST `/api/v1/sleep/predict` **SAI path - POST /predict (404) per IS-001**. Also thieu X-Internal-Service header (D-022) | BROKEN | `sleep_ai_client.py:predict()` - IS-001 scheduled Phase 4 fix |
| C9 | Unified HealthProfile catalog (per ADR-014) replace MOCK_PERSONAS | Phase 4 enhancement | ADR-014 accepted; implementation pending |

---

## FE display requirement (v2)

Per ADR-014 FE simulator-web:
- Profile selector dropdown (`HealthProfile.label` + `display_name`).
- Profile description card: demographics + baseline_shifts ranges.
- Scenario preview: `scenario_response[scenario_id]` magnitude display truoc khi apply.
- Link voi SCENARIOS Q5 "expected outcome preview" - HealthProfile.scenario_response la data source.

---

## Impact on Phase 4 fix plan (v2)

Per ADR-014 follow-up actions:

| Phase 4 task | Status | Priority | Effort |
|---|---|---|---|
| Create `simulator_core/health_profiles.py` catalog + 5 starter presets | Unblocked | P1 | 2-3h |
| Add `health_profile` field to `PersonaConfig` schema | Unblocked | P1 | 30min |
| BE API `GET /api/v1/sim/health-profiles` + test | Unblocked | P1 | 1h |
| Refactor `sleep_service._select_session_for_scenario()` sang HealthProfile.sleep_profile | Unblocked | P1 | 1-2h |
| `_build_db_device_persona()` auto-match HealthProfile by demographics | Unblocked | P2 | 1h |
| FE simulator-web profile selector + description card + scenario preview | Unblocked | P1 | 4-6h |
| DELETE `mock_personas.py` (verify 0 imports) | Unblocked | P2 | 5min |
| Add `X-Internal-Service: iot-simulator` header to fall_ai_client + sleep_ai_client (F-SC-06) | Paired with D-013 | P2 | 30min + test |
| Fix IS-001 (sleep_ai_client path `/api/v1/sleep/predict`) | Scheduled | P0 | 30min (existing bug, known fix) |

---

## Cross-references

- **ETL_TRANSPORT intent:** Artifacts la data source cho dataset-bound mode. `transport/*` layer khong active runtime (per ADR-013).
- **Fall AI client:** Correct path `/api/v1/fall/predict` (verified). Missing header D-020.
- **Sleep AI client:** IS-001 critical bug (POST `/predict` = 404). Scheduled Phase 4 fix.
- **Persona engine:** Wraps into HealthProfile catalog (per ADR-014).
- **SCENARIOS module:** Q5 "expected outcome preview" depend on HealthProfile.scenario_response.
- **Mobile DEVICE module:** Handles device UI lifecycle states (provisioning/streaming/sos_active) - different domain, different repo.
- **ADRs:**
  - **ADR-014** (HealthProfile taxonomy) - primary decision for this module's Phase 4 scope.
  - **ADR-004** (API prefix standardization) - `/api/v1/sim/health-profiles` follows target pattern.
  - **ADR-005** (Internal service secret) - fall/sleep AI clients need header addition.
- **Bugs:**
  - **IS-001** (sleep AI client wrong path) - known critical, Phase 4 scheduled.
- **Topology findings:**
  - **D-020** (fall AI client missing X-Internal-Service header) - medium, Phase 4 paired with D-013.
  - **D-022** (sleep AI client `/health` probe) - low priority.

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 Q1-Q6 confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 3 HIGH + 4 MEDIUM + 3 LOW findings | Em |
| 2026-05-13 afternoon | ADR-014 accepted (Option X unified HealthProfile) | Anh |
| 2026-05-13 afternoon | v2 rewrite confirmed | Em (doc) |
