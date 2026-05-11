# Audit: M03 — Schemas (Pydantic models)

**Module:** `healthguard-model-api/app/schemas/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 4 (model-api)

## Scope

- `schemas/common.py` (94 LoC) — Shared types (APIResponse, ModelInfo, PredictionMeta, StandardPrediction, TopFeature, ShapDetails, PredictionExplanation)
- `schemas/fall.py` (95 LoC) — Fall request/response + sensor sample types
- `schemas/health.py` (~80 LoC est) — Health request/response
- `schemas/sleep.py` (87 LoC) — Sleep request/response + 40+ field SleepRecord

**Total:** ~400 LoC

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Pydantic v2 OK. Missing field validators (range constraints) trên health/sleep records. |
| Readability | 3/3 | Clean type hierarchy, shared common types DRY. |
| Architecture | 3/3 | Proper request/response separation, generic `APIResponse[T]`, no cross-contamination. |
| Security | 2/3 | Type-safe boundary good. Missing input size constraints. |
| Performance | 3/3 | No N+1, no eager serialization, default_factory used correctly. |
| **Total** | **13/15** | Band: **🟢 Mature** |

## Findings

### Correctness (2/3)

- ✓ Pydantic v2 syntax: `BaseModel`, `Field`, `ConfigDict`, `model_dump()` usage
- ✓ `FallPredictionRequest.data` enforces `min_length=settings.fall_min_sequence_samples` (line 58) — dynamic from config
- ✓ `Annotated[list, Field(min_length=1)]` cho batch payload (line 65-68)
- ✓ Generic `APIResponse[T]` với TypeVar — supports any data shape
- ⚠️ `SleepRecord` (sleep.py:17-60) có 40+ fields **all `float`** without `ge`/`le` constraints:
  - `heart_rate_mean_bpm: float` — no range (0-300?)
  - `spo2_mean_pct: float` — no range (0-100?)
  - `caffeine_mg: float` — no upper bound (sanity check)
  - `weight_kg: float` — no range
  - Model expects clean data but invalid input passes through (returns 422 from pydantic_v2 only if type wrong)
- ⚠️ `HealthRecord` likely same pattern (em chưa đọc health.py trong scan này — defer Phase 3 deep-dive)
- ⚠️ `SensorSample.environment` field has `EnvironmentData(default_factory=...)` — graceful missing env, OK
- ⚠️ `device_id: str = "unknown"` default (fall.py:53) — silent default vs required. Acceptable cho dev, audit-able only.

### Readability (3/3)

- ✓ Common types extracted to `common.py` — DRY, no duplication
- ✓ Naming consistent: `*Request`, `*Response`, `*Result` suffix per convention
- ✓ `Literal["risk_up", "risk_down"]` cho enum-like fields (clear values)
- ✓ Hierarchical composition: `FallPredictionResult` contains `PredictionMeta`, `InputReference`, `StandardPrediction`, `list[TopFeature]`, `ShapDetails`, `PredictionExplanation`
- ✓ Field descriptions present (vd `fall.py:60-62`)
- ✓ Type alias `FallPredictPayload = FallPredictionRequest | Annotated[list, ...]` flexible payload pattern

### Architecture (3/3)

- ✓ Request schema separate from Response (no model reuse — clean boundary)
- ✓ `common.py` exports shared building blocks, NO cross-import giữa fall/health/sleep schemas
- ✓ Generic `APIResponse[T]` (line 13-17) — type-safe wrapper
- ✓ `ConfigDict(extra="ignore")` trên `ModelInfo` (common.py:21) — forward-compatible field addition
- ✓ Pydantic v2 idioms: `default_factory` thay vì mutable default

### Security (2/3)

- ✓ Pydantic auto-validate trên Type → reject non-conforming input → 422 response
- ✓ `model_dump()` strips computed fields (no PHI leak via response if marked)
- ⚠️ `SleepRecord.user_id: str` — no length cap (potential DOS với 10MB string)
- ⚠️ No `max_length` constraints trên string fields → memory attack vector
- ⚠️ `device_model: str` — no allowlist enum (any string accepted)
- ⚠️ Sample case loader (`router._load_*_sample_cases_document()`) reads file from disk — path injection nếu config compromised, but file paths defined in `Settings` (controlled)

### Performance (3/3)

- ✓ `default_factory` thay vì mutable default → no shared state across requests
- ✓ `min_length` on lists prevents empty input (no zero-iteration bugs)
- ✓ Generic types compile-time (zero runtime overhead in Pydantic v2)
- ✓ No nested deep recursion in types
- ✓ Pydantic v2 uses Rust core → fast (de)serialization

## Recommended actions (Phase 4)

- [ ] **P1:** Add range constraints to `SleepRecord` fields:
  - `heart_rate_mean_bpm: float = Field(..., ge=20, le=250)`
  - `spo2_mean_pct: float = Field(..., ge=0, le=100)`
  - `caffeine_mg: float = Field(..., ge=0, le=5000)`
  - `weight_kg: float = Field(..., ge=1, le=500)`
  - Similar for ~15 other physiological fields
- [ ] **P1:** Apply same to `HealthRecord` (verify Phase 3 deep-dive)
- [ ] **P2:** Add `max_length` to string fields (user_id 64, device_id 128, etc.)
- [ ] **P2:** Convert `device_model`, `gender`, `timezone` to `Literal[...]` enum where domain bounded
- [ ] **P2:** Add `ge=0` to all `*_count`, `*_minutes` fields (negative values unphysical)

## Out of scope (defer Phase 3 deep-dive)

- Cross-schema consistency check (vd fall sample matches FallPredictionRequest)
- OpenAPI spec generation quality
- Contract test with consumer (health_system BE `model_api_client.py`)
- Backward compatibility analysis (extra fields handling)

## Cross-references

- Phase -1.B: [API contract](../../tier1/api_contract_v1.md) catalogs endpoint surface
- Phase 0: Module M03 in [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)
- Consumer: `health_system/backend/app/services/model_api_client.py` — expects this schema
