# Audit: M01 — Routers (HTTP layer)

**Module:** `healthguard-model-api/app/routers/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 4 (model-api)

## Scope

- `routers/system.py` (54 LoC) — root redirect, `/health` probe, `/api/v1/models` list
- `routers/fall.py` (104 LoC) — fall predict + model-info + sample-cases + sample-input
- `routers/health.py` (91 LoC) — health predict + batch + model-info + samples
- `routers/sleep.py` (91 LoC) — sleep predict + batch + model-info + samples

**Total:** ~340 LoC across 4 files. **17 endpoints** total.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Consistent pattern, `is_loaded` guard, HTTPException 422/500 split. |
| Readability | 3/3 | Mirror structure 3 domains, helper functions extracted, prefix+tag clean. |
| Architecture | 2/3 | Routers thin ✓ but contain JSON file IO (sample loaders should be in service). |
| **Security** | **0/3** | 🚨 D-013: NO `verify_internal_secret` dependency on predict endpoints. |
| Performance | 2/3 | Async signature OK. Sync `predict_api()` call inside `async` blocks event loop. |
| **Total** | **10/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Correctness (3/3)

- ✓ All 3 domain routers follow identical 4-endpoint pattern: `/predict`, `/model-info`, `/sample-cases`, `/sample-input`
- ✓ `is_loaded` guard returns HTTP 503 với detail message (`fall.py:48-49`, `health.py:34-35`, `sleep.py:34-35`)
- ✓ Error hierarchy: `ValueError` → 422 (client error, malformed input), `Exception` → 500 (server error, internal)
- ✓ `logger.exception()` logs traceback at 500 path → debuggable
- ✓ Generic `Exception` catch followed by sanitized message "Prediction error" → does NOT leak `str(exc)` per security guardrail ✓
- ✓ `sample-input` query param `case` validated against `sample-cases` document, 404 if missing
- ✓ `/predict/batch` cho health/sleep re-calls `/predict` — same logic, no duplication (`health.py:51-52`, `sleep.py:51-52`)
- ✓ `fall.py` accepts `Union[FallPredictionRequest, list[FallPredictionRequest]]` via `FallPredictPayload` type alias — flexible API

### Readability (3/3)

- ✓ Module docstring 1-line per router file
- ✓ `_load_*_sample_cases_document()` helper function per router (consistent name pattern)
- ✓ Router declaration includes `prefix` + `tags` (`fall.py:20`, `health.py:19`, `sleep.py:19`)
- ✓ Endpoint summaries clear: "Predict Fall Risk", "Fall Model Info", "Fall sample cases (evaluate fall vs not_fall)"
- ✓ Query parameter descriptions present (`fall.py:84-86`)
- ✓ HTTP error detail strings actionable: "Run: python scripts/build_fall_sample_cases.py" (`fall.py:28`)
- ✓ No dead code, no commented-out blocks
- ⚠️ Repetition trong sample-input + sample-cases pattern across 3 routers (fall/health/sleep) — could extract to generic helper but acceptable trade-off (clarity > DRY in 4-file scope)

### Architecture (2/3)

- ✓ Router → service delegation correct: `fall_service.predict_api(...)`, `health_service.predict_api(...)`, `sleep_service.predict_api(...)`
- ✓ Routers do NOT touch model directly — go through service singletons
- ✓ Response model declared (`response_model=FallPredictionResponse`) → OpenAPI accurate + validate output shape
- ⚠️ **Sample loaders read JSON file from disk INSIDE router** (`fall.py:30`, `health.py:29`, `sleep.py:29`) — should be in service layer (e.g., `fall_service.get_sample_cases()`). Currently router has file IO logic.
- ⚠️ `_request_to_payload()` (`fall.py:33-39`) converts Pydantic → dict — bridging logic in router. Acceptable nhưng could move to service or schema method.
- ⚠️ `predict_health_batch()` = trivial wrapper around `predict_health()` — could expose same fn for both routes (FastAPI supports multiple decorators) instead of wrapping function. Minor.

### Security (0/3) — 🚨 Auto-Critical (D-013)

**🚨 P0 — D-013 (already logged Phase -1.B):** NO `Depends(verify_internal_secret)` on ANY predict endpoint:

```python
# fall.py:42-47, health.py:32-33, sleep.py:32-33
@router.post("/predict", ...)
async def predict_fall(body: FallPredictPayload):   # ← no auth dependency
    ...
```

**Compare** với pattern in FastAPI rules file (`22-fastapi.md`):
```python
@router.post("/predict")
async def predict_fall(
    payload: FallPredictRequest,
    service: FallService = Depends(get_fall_service),
    _auth: None = Depends(verify_internal_secret),   # ← required pattern
):
```

**Impact:**
- Anyone on network can call ML inference → cost leak (model CPU usage)
- DDoS risk
- IoT sim `fall_ai_client.py` calls these endpoints — but IoT sim itself missing header (D-020). After fix, IoT sim cần thêm header simultaneously.

**🚨 P1:** `/health` (system probe) is intentionally public — OK. But ML probes (`/model-info`, `/sample-cases`, `/sample-input`) leak model metadata (feature names, thresholds, model version) — likely OK cho internal but not for production public.

**⚠️ P2:** Error response shape inconsistent:
- HTTP 422: `detail = str(exc)` exposes ValueError message → could leak internal validation info
- HTTP 500: `detail = "Prediction error"` sanitized ✓

Verify Phase 3 deep-dive: ValueError messages don't leak schema internals.

**Anti-pattern HIT:** Missing auth on internal-only endpoints (D-013) → Security score = 0.

### Performance (2/3)

- ✓ `async def` signature on all endpoints — uvicorn worker doesn't block
- ⚠️ **BUT** `fall_service.predict_api(...)` is **sync CPU-bound** (xgboost.predict + sklearn preprocessing) — blocks event loop for duration of inference window. Should be:
  ```python
  results = await asyncio.to_thread(fall_service.predict_api, payloads)
  ```
- ⚠️ `json.loads(path.read_text(...))` sync file IO trong async function (`fall.py:30`, repeated) — blocks event loop for sample-cases endpoint. Sample data nhỏ nên impact minimal, but anti-pattern.
- ✓ No N+1: sample data loaded once per call, no pagination needed
- ✓ Response model serialization auto-cached by Pydantic v2 (Rust core)

## Recommended actions (Phase 4)

- [ ] **P0 (D-013):** Add `Depends(verify_internal_secret)` dependency to all `/predict` + `/predict/batch` endpoints — requires `internal_secret` field added to Settings (M04 dependency) + new `dependencies.py` file
- [ ] **P0:** Coordinate fix with IoT sim — add `X-Internal-Service: iot-simulator` header to fall_ai_client + sleep_ai_client (cross-ref D-020)
- [ ] **P1:** Wrap sync ML inference với `asyncio.to_thread` cho non-blocking
- [ ] **P1:** Move sample loaders from router to service layer (architectural cleanup)
- [ ] **P2:** Consider rate limit middleware (per-IP) on `/predict` endpoints
- [ ] **P2:** Verify ValueError detail strings don't leak schema internals (defer Phase 3)

## Out of scope (defer Phase 3 deep-dive)

- Per-endpoint request/response contract test with consumer
- Detailed Sample case JSON format validation
- OpenAPI spec accuracy
- Rate limit threshold values

## Cross-references

- Phase -1.B: [D-013](../../tier1/api_contract_v1.md) — predict endpoints no internal secret (THIS module)
- Phase -1.B: [D-014](../../tier1/api_contract_v1.md) — `/health` semantic collision (M04 also flagged)
- Phase -1.C: [D-020](../../tier1/topology_v2.md) — IoT fall AI client missing X-Internal-Service header (cross-repo)
- Phase 0: Module M01 in [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)
- Bug: [IS-001](../../../BUGS/IS-001-sleep-ai-client-wrong-path.md) — consumer-side path bug, fix simultaneously
