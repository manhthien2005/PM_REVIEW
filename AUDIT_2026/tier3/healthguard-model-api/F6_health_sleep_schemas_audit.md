# Audit: F6 — schemas/health.py + schemas/sleep.py

**Files:**
- `healthguard-model-api/app/schemas/health.py` (68 LoC)
- `healthguard-model-api/app/schemas/sleep.py` (75 LoC)

**Total LoC:** 143 (combined)
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M03 Schemas](../../tier2/healthguard-model-api/M03_schemas_audit.md)

## Scope

Pydantic v2 request + response schemas for two domains:
- `health.py`: `VitalSignsRecord` (14 fields: vitals + derived), `HealthPredictionRequest`, `HealthPredictionResult`, `HealthPredictionResponse`.
- `sleep.py`: `SleepRecord` (45 fields: sleep metrics + context + demographics), `SleepPredictionRequest`, `SleepPredictionResult`, `SleepPredictionResponse`.

Both files delegate common response building blocks (`InputReference`, `PredictionMeta`, `StandardPrediction`, `TopFeature`, `ShapDetails`, `PredictionExplanation`) to `schemas/common.py`.

Phase 1 M03 flagged **range constraint addition** as P1 backlog for `VitalSignsRecord` + `SleepRecord`. This audit owns the per-field detailed assessment.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Bare float types on physiological fields, no ge/le range validators. Negative HR, out-of-range SpO2 accepted. |
| Readability | 3/3 | Clean field names, explicit json_schema_extra example for health, consistent common-schema reuse. |
| Architecture | 3/3 | Proper separation (common reusable blocks, per-domain files), min_length=1 on request list. |
| Security | 2/3 | Missing max_length on string fields (user_id, gender, timezone, device_model). DoS via large list partially guarded. |
| Performance | 3/3 | Pydantic v2 Rust core. No heavy validators. Small payloads. |
| **Total** | **13/15** | Band: 🟢 Mature |

## Positive findings

- Pydantic v2 import style correct (`from pydantic import BaseModel, Field`) — no legacy v1 patterns.
- `records: list[X] = Field(..., min_length=1)` (health line 55, sleep line 55) — guarantees non-empty batch. Matches Pydantic v2 syntax (not legacy `min_items`).
- Common schema reuse (both files import from `app.schemas.common`): PredictionMeta, InputReference, StandardPrediction, TopFeature, ShapDetails, PredictionExplanation. DRY across 3 domains.
- `json_schema_extra` example block in `VitalSignsRecord.model_config` (health lines 29-50) — OpenAPI UI shows realistic example input. Verified values align with reason overrides (high HR, high temp, low SpO2 -> high risk).
- `status: str = "ok"` default in response result (health line 64, sleep line 63) — explicit success flag, overridable on failure modes.
- TopFeature, ShapDetails, PredictionExplanation made Optional on result (health lines 66-68, sleep lines 66-68 via `| None = None`) — graceful degradation if Gemini fails or SHAP unavailable.
- `Field(default_factory=list)` on `top_features` — correct mutable-default handling (not `= []`).
- SleepRecord preserves order consistent with `sleep_features.add_features` expected input (timestamps first, then metrics, then context) — implicit aligned with feature engineering pipeline.
- No from-attributes or orm_mode — these are pure DTOs, not ORM models. Appropriate.

## Findings per axis

### Correctness (2/3)

- **P1 NEW — No range validators on physiological fields (F-MA-P3-02):**

  VitalSignsRecord (health.py line 16-27):
  | Field | Current type | Physiological bound (suggested) | Failure mode |
  |---|---|---|---|
  | heart_rate | float | ge=0, le=300 (resting 30-200, peak 220) | -10 HR accepted |
  | respiratory_rate | float | ge=0, le=60 (adult 8-40) | negative RR accepted |
  | body_temperature | float | ge=30, le=45 (hypothermia-hyperthermia) | 0C or 100C accepted |
  | spo2 | float | ge=0, le=100 (percent) | 105% or -5% accepted |
  | systolic_blood_pressure | float | ge=40, le=300 | negative accepted |
  | diastolic_blood_pressure | float | ge=20, le=200 | negative accepted |
  | age | int | ge=0, le=130 | -5 age accepted |
  | gender | int | ge=0, le=1 (assuming binary encoding) | 99 accepted |
  | weight_kg | float | ge=1, le=500 | 0 or 1000 accepted |
  | height_m | float | ge=0.3, le=2.5 | 10m accepted |
  | derived_hrv | float | ge=0, le=500 (ms) | - |
  | derived_pulse_pressure | float | ge=0, le=200 | - |
  | derived_bmi | float | ge=5, le=100 | - |
  | derived_map | float | ge=30, le=250 | - |

  SleepRecord (sleep.py line 18-56):
  | Field | Current type | Suggested bound | Notes |
  |---|---|---|---|
  | duration_minutes | float | ge=0, le=1440 | full day max |
  | sleep_latency_minutes | float | ge=0, le=600 | - |
  | wake_after_sleep_onset_minutes | float | ge=0, le=1440 | - |
  | sleep_efficiency_pct | float | ge=0, le=100 | percent |
  | sleep_stage_*_pct (4 fields) | float | ge=0, le=100 | percent; sum should equal 100 (model-level check) |
  | heart_rate_*_bpm (3 fields) | float | ge=0, le=300 | - |
  | hrv_rmssd_ms | float | ge=0, le=500 | - |
  | respiration_rate_bpm | float | ge=0, le=60 | - |
  | spo2_*_pct (2 fields) | float | ge=0, le=100 | - |
  | movement_count | float | ge=0 | integer-like, counts non-negative |
  | ambient_noise_db | float | ge=0, le=150 | - |
  | room_temperature_c | float | ge=-10, le=50 | - |
  | room_humidity_pct | float | ge=0, le=100 | - |
  | step_count_day | float | ge=0, le=100000 | - |
  | caffeine_mg | float | ge=0, le=2000 | - |
  | alcohol_units | float | ge=0, le=100 | - |
  | medication_flag | float | ge=0, le=1 | binary-like |
  | age | float | ge=0, le=130 | - |
  | weight_kg | float | ge=1, le=500 | - |
  | height_cm | float | ge=30, le=250 | - |
  | stress_score | float | ge=0, le=100 | - |
  | insomnia_flag | float | ge=0, le=1 | binary |
  | apnea_risk_score | float | ge=0, le=1 or ge=0, le=100 (depends on definition) | - |

  **Impact:**
  1. Garbage-in: negative SpO2 = -5 flows through `prepare_inference_frame` -> model inference -> nonsense probability. Model-dependent: LGBM may extrapolate wildly. Returns plausible-looking risk probability but based on impossible input.
  2. Feature-derivation bug amplification: `sleep_efficiency_pct = 150` makes `deep_rem_ratio = (10+20)/light` valid but `sleep_stage_sum != 100` undetected.
  3. Consumer trust: mobile app + IoT sim rely on service rejecting malformed sensor data; currently only router-level ValueError from missing keys is raised.
  4. Defensive depth: Phase 1 M01 audit noted router-boundary validation trusted but not fully audited. This file is the validation boundary.

  **Spec alignment:** SRS (if exists) likely expects range constraints; this is boundary validation.

- P2 — `gender` field type inconsistency:
  - `VitalSignsRecord.gender: int` (health line 23)
  - `SleepRecord.gender: str` (sleep line 50)
  - Divergence suggests different training datasets. Sleep model probably encodes via ColumnTransformer ohe; health uses direct int. Not a bug but cross-domain inconsistency.

- P3 — Timestamp fields as `str`:
  - `date_recorded: str`, `sleep_start_timestamp: str`, `sleep_end_timestamp: str`, `created_at: str` (sleep lines 19-22)
  - No format validator. `sleep_features.add_features` does `pd.to_datetime(...)` which is lenient (accepts many formats). If consumer sends malformed timestamp string, `to_datetime` raises or coerces.
  - Suggest `datetime | str` union or Pydantic `datetime` type + ISO 8601 validation.

### Readability (3/3)

- Both files open with short docstring describing role. Clear.
- Field declarations one-per-line, consistent. No clutter.
- Response model names follow convention (`XPredictionRequest`, `XPredictionResult`, `XPredictionResponse`).
- `VitalSignsRecord.model_config` uses `json_schema_extra` with realistic example — aids OpenAPI consumers.
- `SleepRecord` lacks example block (asymmetric with health) — P3 consistency.
- No dead code, no commented-out fields.

### Architecture (3/3)

- Proper DTO-vs-domain separation (schemas here, service logic in `app/services/`).
- Common response blocks in `common.py` — zero duplication across domains.
- `min_length=1` on request list — router gets empty-batch rejection for free.
- No cross-schema imports between `health.py` and `sleep.py` — each domain independent.
- No `from_attributes` — correct, these are not ORM-backed.

### Security (2/3)

- **P2 NEW — No `max_length` on string fields:**
  - SleepRecord: `user_id: str`, `timezone: str`, `gender: str`, `device_model: str`, `date_recorded: str`, `sleep_start_timestamp: str`, `sleep_end_timestamp: str`, `created_at: str` — 8 fields unbounded.
  - VitalSignsRecord: all numeric/int, no string fields. Safer.
  - Attack vector: malicious consumer sends `user_id` of 10MB -> request body size limit kicks in (default Starlette 16MB per request, no explicit limit configured per M04 audit noted).
  - `user_id` flows into `input_ref` (F3 confirmed) and logs; 10MB string in logs = log flood.
  - **Acceptable đồ án 2** (internal localhost), **production must add**:
    - `Field(max_length=64)` on `user_id`, `gender`, `timezone`, `device_model`
    - `Field(max_length=32)` on timestamp strings (or switch to `datetime`)
- **P2 NEW — No batch-list `max_length`:**
  - `records: list[X] = Field(..., min_length=1)` — no upper bound.
  - Attack vector: consumer sends 1M records. Each record ~200 bytes -> 200MB payload. `predict_api` loops, accumulates pandas DataFrame, calls model, runs SHAP per record -> memory + CPU bomb.
  - **Phase 0.5 intent drift already acknowledged** this risk: "No request size limit (fall data array)" marked acceptable for đồ án 2 internal. Re-ref, not new finding. But sleep + health batch endpoints ALSO lack `max_length` — extend Phase 0.5 flag to all 3 domains.
  - Suggested Phase 5+: `Field(..., min_length=1, max_length=500)` — aligns with typical batch sizes.
- `user_id` field stored verbatim in response `input_ref` — acceptable echo pattern, no sanitization needed (consumer owns their ID namespace).
- No SQL in schemas (it is a stateless inference service) — no injection surface.
- Pydantic v2 strictness: default float rejects strings like "abc", accepts "123.45" coerce — Pydantic v2 is stricter than v1 but still coerces. Acceptable.

### Performance (3/3)

- Pydantic v2 uses Rust core (`pydantic_core`) -> field validation in microseconds.
- Small payloads (14 fields for health, 45 fields for sleep) — negligible validation cost.
- No computed_fields, no validators (yet — range validators P1 above would add trivial cost).
- `json_schema_extra` is a dict; no recomputation at runtime.

## Recommended actions (Phase 4)

- [ ] **P1 (cross-ref M03):** Add physiological range validators via `Field(ge=..., le=...)` on all numeric fields in `VitalSignsRecord` + `SleepRecord`. Use tables above as reference. Add unit tests for boundary values.
- [ ] **P2:** Add `max_length` to all string fields in `SleepRecord` (user_id, gender, timezone, device_model, 4 timestamp fields). Suggested: 64 chars for IDs, 32 for timestamps.
- [ ] **P2:** Add `max_length=500` to `records: list[...]` in all 3 request schemas (health, sleep, fall). Prevents memory-bomb DoS.
- [ ] **P2:** Add `field_validator` on `sleep_stage_*_pct` fields to assert sum is approximately 100 (with tolerance). Model-level check via `model_validator`.
- [ ] **P3:** Standardize `gender` field type across domains — either both int or both str.
- [ ] **P3:** Convert timestamp string fields in `SleepRecord` to `datetime` + add ISO-8601 format validator.
- [ ] **P3:** Add `json_schema_extra` example block to `SleepRecord` (parity with `VitalSignsRecord`).

## Out of scope

- Fall schema (`schemas/fall.py`) — not in F6 target list, deferred. Intuition: IMU sensor fields also lack range validators (acceleration can legitimately be -16g to +16g; gyro -2000 to +2000 dps; orientation 0-360). Add to Phase 3+ follow-up.
- Common schema (`common.py`) review — M03 covers.
- Batch endpoint rate-limiting (M04 concern).
- Cross-field validation (e.g., `sleep_end_timestamp > sleep_start_timestamp`) — belongs to `model_validator`, flagged for Phase 5+.

## Cross-references

- Phase 1: [M03 Schemas](../../tier2/healthguard-model-api/M03_schemas_audit.md) — range constraint + max_length addition candidates promoted to Phase 3 (now covered).
- Phase 1: [M01 Routers](../../tier2/healthguard-model-api/M01_routers_audit.md) — router validates via Pydantic before service; range constraints at this layer would return 422 with clear Pydantic error messages.
- Phase 0.5: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — "No request size limit (fall data array)" acceptable đồ án 2; extend same treatment to health+sleep here.
- Consumer alignment:
  - `health_system/backend/app/services/model_api_client.py` — sends vital records; payload shape must match `VitalSignsRecord`.
  - `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` — sends SleepRecord-shaped payload (IS-001 tracks path bug, not shape).
- Upstream usage: F2 [health_service](./F2_health_service_audit.md) consumes VitalSignsRecord, F3 [sleep_service](./F3_sleep_service_audit.md) consumes SleepRecord.
- Spec source-of-truth: `PM_REVIEW/Resources/UC/` — if UC specifies acceptable vital ranges, align bounds there.
