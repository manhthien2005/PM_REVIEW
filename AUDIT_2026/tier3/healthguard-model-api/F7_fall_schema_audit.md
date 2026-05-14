# Audit: F7 — schemas/fall.py

**File:** `healthguard-model-api/app/schemas/fall.py`
**LoC:** 72
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive extended (model-api)
**Tier2 ref:** [M03 Schemas](../../tier2/healthguard-model-api/M03_schemas_audit.md)

## Scope

Pydantic v2 request + response schemas for fall detection:
- Nested sensor models: `AccelData`, `GyroData`, `OrientationData`, `EnvironmentData`, `SensorSample`.
- Request types: `FallPredictionRequest`, `FallPredictPayload` (Union of single + list).
- Response types: `FallPredictionResult`, `FallPredictionResponse`.

Delegates common response blocks (`InputReference`, `PredictionMeta`, `StandardPrediction`, `TopFeature`, `ShapDetails`, `PredictionExplanation`) to `schemas/common.py` — same pattern as health + sleep (F6).

F6 flagged the physiological range validator gap for `VitalSignsRecord` + `SleepRecord` (F-MA-P3-02). F7 extends that pattern to IMU sensor fields here.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | IMU sensor bounds missing (accel, gyro, orientation); `timestamp: int` no format/range; `sampling_rate`/`window_size` no `ge/le`. |
| Readability | 3/3 | Nested model decomposition clean, union-type request is idiomatic, docstring concise. |
| Architecture | 3/3 | Proper separation (nested sub-models, common reuse), `min_length` wired from config (`settings.fall_min_sequence_samples`). |
| Security | 2/3 | `device_id: str` no `max_length`; batch list (single side of union) no `max_length`; inner list of `FallPredictionRequest` in Union side has `min_length=1` but no upper bound. |
| Performance | 3/3 | Pydantic v2 Rust core; nested models compile to optimal validators; payload cost scales linearly with sample count (expected). |
| **Total** | **13/15** | Band: Mature |

## Positive findings

- **Nested sensor decomposition** (`AccelData`, `GyroData`, `OrientationData`, `EnvironmentData`): each axis-group modeled as separate BaseModel (lines 20-41). Clean structural mapping vs flat 12-float dict. Makes OpenAPI schema readable for consumers (Flutter / IoT sim).
- **`data` length bound from config** (line 58): `Field(..., min_length=settings.fall_min_sequence_samples, ...)` — `min_length` is **dynamic** (reads from pydantic-settings). When ops change `HEALTHGUARD_FALL_MIN_SEQUENCE_SAMPLES` env, schema + service guard stay in sync. Rare good pattern — health + sleep use hardcoded `min_length=1` only.
- **Description includes threshold value** (line 58-62): `f"IMU window: ... length >= {settings.fall_min_sequence_samples}."` — OpenAPI docs show actual threshold, not abstract "non-empty".
- **Union type for single-or-batch payload** (lines 65-69): `FallPredictPayload = FallPredictionRequest | Annotated[list[FallPredictionRequest], Field(min_length=1, ...)]`. One endpoint accepts either shape — eliminates duplicate `/predict` + `/predict/batch` surface on fall. Consumer convenience with no safety loss.
- **`EnvironmentData` defaults all zero** (lines 37-40): consumer can omit environment block entirely. Backward-compat with devices that don't have pressure mat / room occupancy sensors. Pragmatic default.
- **`FallPredictionResult.status: str = "ok"`** (line 85) + Optional `top_features`, `shap`, `explanation` — graceful degradation when downstream components (SHAP, Gemini) fail. Mirrors F6 pattern.
- **Default `device_id = "unknown"`** (line 54) — dev/test payloads do not break; production consumers should always send real ID.
- **`Annotated[list[...], Field(...)]` syntax** in union arm (lines 66-68) — correct Pydantic v2 way to attach `Field(min_length=...)` to `list[...]` inside `Union`. Uses `Annotated` rather than `conlist` — modern idiom.
- **Exported via `schemas/__init__.py`** (`FallPredictPayload` in `__all__`) — consumers import from one place, no `app.schemas.fall` drilling.

## Findings per axis

### Correctness (2/3)

- **P1 NEW — No IMU sensor range validators (F-MA-P3-06):**

  Extends F-MA-P3-02 (F6) pattern to fall domain. IMU sensors have physical bounds that standard consumer IMUs (MPU6050, LSM6DS3, Apple Watch accelerometer) respect:

  | Field | Current | Physical bound (suggested) | Notes |
  |---|---|---|---|
  | `AccelData.x/y/z` (lines 21-23) | `float` | `ge=-160, le=160` (m/s^2) OR `ge=-16, le=16` (g) | Typical consumer IMU range +/-16g = +/-157 m/s^2. Unit depends on bundle training. |
  | `GyroData.x/y/z` (lines 27-29) | `float` | `ge=-2000, le=2000` (dps) OR `ge=-35, le=35` (rad/s) | Typical range +/-2000 dps. |
  | `OrientationData.pitch/roll` (lines 33-34) | `float` | `ge=-180, le=180` | Euler angles signed half-turn. |
  | `OrientationData.yaw` (line 35) | `float` | `ge=0, le=360` OR `ge=-180, le=180` | Depends on convention - check `fall_featurize` assumption. |
  | `EnvironmentData.floor_vibration` (line 38) | `float` | `ge=0, le=100` | Assume normalized 0-100 scale per `environment_contact_score` weight (0.3 coefficient, featurize line 95). |
  | `EnvironmentData.room_occupancy` (line 39) | `float` | `ge=0, le=1` OR `ge=0, le=10` | Binary (occupied or not) or count. Feature weight (0.2) suggests normalized. |
  | `EnvironmentData.pressure_mat` (line 40) | `float` | `ge=0, le=1` | Likely binary (0 or 1) per mat-sensor convention. Currently accepts 999. |
  | `SensorSample.timestamp: int` (line 44) | `int` | `ge=0` at minimum | Unix epoch ms/s. Currently accepts negative. |

  **Impact:**
  1. Garbage input propagation: `accel_x=99999` flows through `fall_featurize.summarize_series` -> `accel_x_mean/std/max/range/energy` all inflated -> XGBoost sees extreme values -> predicts `fall_probability=1.0` (false positive) or returns a value model never saw during training (out-of-distribution).
  2. Feature derivation math: `accel_mag = sqrt(x^2 + y^2 + z^2)` (featurize line 41) with `x=1e30` yields `inf` -> `peak_to_mean` = inf -> downstream SHAP computation corrupts.
  3. Life-safety critical path: fall detection feeds into SOS / emergency alert flow in mobile app (UC010 / UC011 domain). False positive due to invalid sensor input = unnecessary emergency contact call.
  4. Defensive depth: consumers are Flutter app + IoT sim. Flutter `sensors_plus` emits physically-bounded values but IoT sim is synthetic (can emit arbitrary). Boundary validation at schema layer protects both.

  **Action:** Add `Field(ge=..., le=...)` per table above. Add unit tests for sensor-bound values (-16g, +16g, 0g) + out-of-bound (-20g, +20g).

- **P2 NEW — `sampling_rate` + `window_size` no bounds** (lines 55-56):
  - `sampling_rate: int = 50` — accepts 0, negative, or 100_000_000.
  - `window_size: int = 50` — no validator; mismatch with actual `len(data)` not checked.
  - Flow: `fall_featurize.featurize_payloads` reads `int(payload.get("sampling_rate", SAMPLING_RATE))` (featurize line 144) — coerces to int but does not validate. Large value goes into `raw_df`, stored as metadata, never used by model — ignored benignly. Small/negative value also ignored. Impact: metadata pollution in `raw_df` propagated to response `input_ref`/`meta`.
  - Suggest: `Field(ge=1, le=200)` on `sampling_rate` (typical watch sensors 20-200 Hz) + `Field(ge=1, le=10_000)` on `window_size`.
  - **Consistency check:** `settings.fall_min_sequence_samples` has `ge=1, le=10_000` (config.py line 53). `window_size` payload field should match.

- **P3 — `SensorSample.timestamp: int` no format hint** (line 44):
  - Accepts any int: epoch milliseconds, epoch seconds, monotonic nanoseconds — consumer chooses. `fall_service._build_prediction_rows` uses `data[0]["timestamp"]` verbatim in `event_timestamp` field (F1 line 237) — response contract echoes raw unit back.
  - Acceptable if cross-consumer contract is "epoch seconds" (typical). Add `description="Unix epoch seconds"` to clarify.

- P3 — **Union request type error messages** (line 65):
  - When Pydantic rejects `FallPredictPayload`, validation error tries both arms and reports both failure reasons. Consumer sees verbose error. Acceptable DX cost for API surface convenience.

### Readability (3/3)

- Nested sub-models each < 5 lines — minimal, focused.
- `SensorSample` uses `Field(default_factory=EnvironmentData)` (line 50) — correct Pydantic v2 mutable-default handling.
- Type hints correct throughout. `Annotated[list[...], Field(...)]` in Union arm is the documented modern approach.
- No dead code, no commented-out fields.
- Single-line docstring (line 1) acceptable for schema file.
- **P3 asymmetry** (cross-ref F6): VitalSignsRecord has `json_schema_extra` example, FallPredictionRequest does not. Add IMU window example for OpenAPI UI.

### Architecture (3/3)

- Nested models (`AccelData`, `GyroData`, ...) follow "typed composition" pattern — matches raw IoT payload shape 1:1. Consumer mental model = schema.
- `FallPredictPayload` Union as module-level alias (not inside a BaseModel) — correct use of type alias; router imports directly.
- Uses `settings.fall_min_sequence_samples` from pydantic-settings — config-driven validation without coupling config to the schema module (only imports `settings`, not the `Settings` class).
- No cross-schema imports from health/sleep — each domain independent.
- `schemas/__init__.py` re-exports public names (verified via grep) — consumers do not drill into `app.schemas.fall`.

### Security (2/3)

- **P2 NEW — String fields no `max_length` (F-MA-P3-07):**
  - `device_id: str = "unknown"` (line 54) — no upper bound. Malicious consumer could send 10MB `device_id` -> flows to `input_ref.device_id` (F1 line 237), logged, echoed in response.
  - Suggest `Field(default="unknown", max_length=64)` — matches Phase 0.5 + F6 guidance.

- **P2 cross-ref (not re-flagged, extend):** F6 + Phase 0.5 both flagged batch list `max_length` gap for health/sleep/fall. Fall-specific detail:
  - `FallPredictionRequest.data: list[SensorSample]` — `min_length=N` (from config) but **no** `max_length`. Single window could theoretically have 10M samples.
  - `FallPredictPayload` list arm: `Field(min_length=1, ...)` — no `max_length`. Batch could have 10M windows.
  - **Acceptable đồ án 2** (localhost only, Phase 0.5 explicit decision). **Phase 5+ production must add**: `Field(max_length=500)` on inner list, `Field(max_length=100)` on batch arm.

- **P3 — `EnvironmentData` defaults enable sensor spoofing:**
  - A consumer that omits `environment` field entirely gets default `EnvironmentData()` = all zeros. Then feature `environment_contact_score = 0` (featurize line 93) — predictions degrade silently instead of failing loud.
  - Trade-off: backward-compat (devices without env sensors) vs silent degradation. Current choice is pragmatic — defense via `fall_service` using `environment_contact_score` as one of many features means single-feature drop does not tank accuracy. Document the trade-off in schema comment.

- **Cross-ref (not re-flagged):**
  - D-013 (router-level auth gap on `/fall/predict`) — M01 routers audit.
  - D-020 (IoT sim `fall_ai_client.py` missing internal-service header) — IoT sim side, tracked separately.
  - No PHI in fall schema: IMU + environment sensors are not HIPAA-class by themselves. `device_id` is opaque ID, not patient-identifying (per Phase 0.5 data flow assumption).

### Performance (3/3)

- Pydantic v2 Rust core — nested model validation ~5-10us per sample at the 50-sample window size = <1ms full request parse.
- No `json_schema_extra` computation at runtime.
- No validators or computed fields defined (adding range validators P1 above would add ~1us per field — negligible).
- `min_length` check is O(1).

## Recommended actions (Phase 4)

- [ ] **P1 (extends F-MA-P3-02):** Add IMU sensor range validators per table above on `AccelData`, `GyroData`, `OrientationData`, `EnvironmentData`, `SensorSample`. Use same unit (m/s^2 vs g) as training data — verify against `fall_metadata.json`. Add unit tests for boundary values.
- [ ] **P2:** Add `Field(ge=1, le=200)` on `sampling_rate` and `Field(ge=1, le=10_000)` on `window_size` (match `settings.fall_min_sequence_samples` upper bound).
- [ ] **P2:** Add `Field(max_length=64)` on `device_id`.
- [ ] **P2 (cross-ref Phase 0.5):** Add `max_length=500` on `FallPredictionRequest.data` + `max_length=100` on `FallPredictPayload` list arm — defer to Phase 5+ per Phase 0.5 decision, but document intent in schema comment now.
- [ ] **P3:** Add `json_schema_extra` example block with a realistic 50-sample fall window for OpenAPI UI (parity with `VitalSignsRecord`).
- [ ] **P3:** Add `description="Unix epoch seconds"` (or ms, verify consumer contract) to `SensorSample.timestamp`.
- [ ] **P3:** Consider `model_validator` enforcing `len(data) >= window_size` cross-field consistency.

## Out of scope

- `fall_featurize` math correctness (covered in F8).
- Sensor unit conversion (m/s^2 vs g) — ML-ops concern, verify against training preprocessing.
- Config-level `fall_min_sequence_samples` value tuning — ops concern.
- Pydantic v2 Union discriminator optimization — micro-perf, not needed at current scale.

## Cross-references

- Phase 1: [M03 Schemas](../../tier2/healthguard-model-api/M03_schemas_audit.md) — range constraint gap noted general; F7 provides fall-specific bound table.
- Phase 3: [F6 health/sleep schemas](./F6_health_sleep_schemas_audit.md) — F-MA-P3-02 extends pattern to fall here; F6 "Out of scope" note predicted this gap (verified).
- Phase 3: [F1 fall_service](./F1_fall_service_audit.md) — service consumes `FallPredictionRequest`, `device_id` flows to `input_ref`.
- Phase 3: [F8 fall_featurize](./F8_fall_featurize_audit.md) — peer file, consumes dict-shaped payloads (not Pydantic models directly).
- Phase 0.5: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — "No request size limit (fall data array)" acceptable for đồ án 2, deferred to Phase 5+.
- Consumer code: `Iot_Simulator_clean/simulator_core/fall_ai_client.py` — sends fall payloads; must conform to schema range bounds once added.
- Bug: D-020 (IoT sim fall_ai_client missing auth header) — tracked Phase 1, unrelated to schema.
- Spec source-of-truth: `PM_REVIEW/Resources/UC/` + `fall_metadata.json` — if UC specifies acceptable IMU ranges or training preprocessing clipping, align bounds with that.
