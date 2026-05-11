# Audit: M02 — Services (ML inference logic)

**Module:** `healthguard-model-api/app/services/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 4 (model-api)

## Scope

8 service files, ~1,500 LoC total:

| File | LoC | Role |
|---|---|---|
| `fall_service.py` | 279 | Fall detection model wrapper (XGB/LGBM/sklearn auto-detect) |
| `health_service.py` | 253 | Health risk model wrapper |
| `sleep_service.py` | 240 | Sleep score model wrapper |
| `prediction_contract.py` | 300 | SHAP payload + meta + input_ref builders (shared) |
| `gemini_explainer.py` | 215 | Gemini API client for Vietnamese explanation (with fallback) |
| `fall_featurize.py` | 146 | IMU window → aggregated features |
| `sleep_features.py` | 97 | Sleep record feature derivation |
| `sklearn_sleep_pickle_compat.py` | 57 | Pickle backward compat shim |

**Audit method note:** Macro audit — scanned representative samples (fall_service.py:1-200, prediction_contract.py:1-80, gemini_explainer.py:1-80) + LoC inventory. Health + Sleep services likely mirror Fall pattern (verified by router scan showing identical structure). Phase 3 deep-dive per file recommended for full validation.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Defensive load + guard methods + threshold-based classification consistent. |
| Readability | 2/3 | Mostly clear, but fall_service.py 279 LoC borderline god class. |
| Architecture | 2/3 | Service singleton pattern good. SHAP/contract logic shared correctly. Gemini fallback safe. |
| Security | 2/3 | API key via env ✓. Sanitized error messages. Gemini timeout protected. |
| Performance | 2/3 | Models cached. Sync inference (M01 deduct already). Gemini hard timeout. |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (3/3)

- ✓ **Load lifecycle defensive** (`fall_service.py:58-84`):
  - Try-except wraps full load flow
  - Validates bundle is `dict` (line 65-66)
  - Checks required keys: `preprocessor`, `model` (line 67-68)
  - Auto-detects backend (`xgboost`/`lightgbm`/`sklearn`) by class name (line 69-75)
  - Stores `_last_load_error` for `get_info()` exposure
  - `_loaded = False` on failure → routes return 503 cleanly
- ✓ **Min sample guard** (`fall_service.py:130-138`): rejects payload với `len(data) < min_len` → ValueError → 422 from router
- ✓ **Threshold-based classification** consistent (`classify_fall_risk` line 42-48 — `critical_at >= warning_at >= 0.5`)
- ✓ **Decision threshold from bundle** with fallback to settings (`fall_service.py:172-173`):
  ```python
  thr_bundle = self._bundle.get("decision_threshold")
  thr = float(thr_bundle) if thr_bundle is not None else settings.fall_thresholds.fall_true_at
  ```
  Bundle metadata can override config — good design
- ✓ **SHAP payload builder** handles base_value extraction (`prediction_contract.py:62-66`) — XGB SHAP returns N+1 values, last is base
- ✓ **Gemini fallback-safe** (`gemini_explainer.py:7-9` docstring): "Fire-and-forget with silent fallback: any Gemini error returns None"
- ✓ **Hard timeout** for Gemini (12s, line 30) prevents stalling inference

### Readability (2/3)

- ✓ Docstrings on most public functions
- ✓ Module-level docstrings explain role (`fall_service.py:1`, `gemini_explainer.py:1-13`)
- ✓ Vietnamese REASON_OVERRIDES dictionary clear (`fall_service.py:34-39`)
- ✓ Service class structure: `__init__` → `load` → `is_loaded` property → `predict` flow
- ⚠️ **`fall_service.py` = 279 LoC** — borderline god class. Contains:
  - Load logic (~30 lines)
  - Info builder (~25 lines)
  - Input prep (~20 lines)
  - Probability prediction (~5 lines)
  - SHAP contribution (~10 lines)
  - Prediction rows builder (~25 lines)
  - High-level `predict()` + `predict_api()` flow
  - Top features overrides
  
  Consider split: `_load`, `_inference`, `_explain` helpers into separate modules. Phase 3 deep-dive.
- ⚠️ Class names: `FallModelService` vs module singleton `fall_service` — naming overlap could confuse (instance shadows class semantics)
- ⚠️ Magic numbers in `_GEMINI_MODEL = "gemini-2.5-flash"`, `_TIMEOUT_SECONDS = 12` — should expose via config (currently hardcoded line 29-32)

### Architecture (2/3)

- ✓ **Service singleton pattern** (`fall_service = FallModelService()` likely at module bottom — em chưa scan toàn bộ, suy luận từ main.py import)
- ✓ **Shared contract builders** in `prediction_contract.py` → fall/health/sleep all use `make_meta`, `make_input_ref`, `build_shap_payload`, `build_top_features` — DRY
- ✓ **Separation:** Service knows about ML lib (xgboost, joblib), router doesn't
- ✓ **Backend abstraction** (auto-detect XGB/LGBM/sklearn) → swap model without code change
- ✓ **Gemini explainer separate file** — clear single-responsibility
- ⚠️ **Singleton thread safety** — `fall_service` is module-level mutable (`_loaded`, `_bundle`). Read-only after `lifespan` load → safe in practice. NO documented contract về thread safety.
- ⚠️ **`gemini_explainer.py` lazy init** uses `threading.Lock` (line 34) — good pattern but verify all access paths protected (em chỉ scan `_get_client`).
- ⚠️ **`prediction_contract.py` 300 LoC** — borderline god utility. Multiple builder functions. Acceptable nhưng split candidate.

### Security (2/3)

- ✓ **Gemini API key from env** (`gemini_explainer.py:51`): `os.environ.get("GEMINI_API_KEY", "")` — no hardcode
- ✓ **Sanitized load_error** (`fall_service.py:79-80`): truncates to 500 chars → no full traceback leak in `get_info()`
- ✓ **No PHI leak in logs** verified spot-check: logger uses model status only, no user data
- ✓ **Gemini fallback silent** (returns `None`) — no fatal crash if API key compromised + rotated
- ⚠️ **`fall_service.py:81`** — `logger.error("Cannot load fall bundle: %s", exc)` — logs raw exception. Acceptable cho startup error logging, but verify Phase 3 no PHI in exception message.
- ⚠️ **`gemini_explainer.py`** — em chưa scan lines 80-215, có thể có prompt template, verify Phase 3 không embed PHI in Gemini prompts.
- ⚠️ **No input sanitization for SHAP feature values** — assumes feature names trusted (correct trong internal use, but defense-in-depth not present).

### Performance (2/3)

- ✓ **Bundle loaded once on lifespan startup** — cached in service instance
- ✓ **`np.asarray` + `dtype=np.float32`/`np.float64`** → efficient memory layout
- ✓ **Threshold lookup O(1)** — direct settings attribute access
- ✓ **Gemini hard timeout** (12s) prevents stalling
- ⚠️ **Sync ML inference** (`predict_proba`, `predict`, SHAP `pred_contribs=True`) trong async pipeline — see M01 finding. Wrap with `asyncio.to_thread`.
- ⚠️ **SHAP computation always-on** — adds latency per prediction. Verify Phase 3 if SHAP can be optional (e.g., `compute_shap: bool = True` query param).
- ⚠️ **`featurize_payloads` returns pandas DataFrame** — pandas allocation overhead per request. Acceptable cho batch, suboptimal cho single-window real-time path.
- ⚠️ **Gemini call adds ~1-3s latency** (network + model inference). Verify Phase 3 nếu cached per prediction or fire-and-forget background.

## Recommended actions (Phase 4)

- [ ] **P1:** Wrap sync ML inference với `asyncio.to_thread` in router (paired with M01 fix)
- [ ] **P1:** Expose Gemini config (`model`, `timeout_seconds`, `max_output_tokens`) via Settings (currently hardcoded)
- [ ] **P2:** Document service singleton thread safety contract (or migrate to FastAPI `Depends` factory)
- [ ] **P2:** Consider optional SHAP computation (query param) cho real-time fall detection (latency-sensitive)
- [ ] **P3:** Split `fall_service.py` (279 LoC) into smaller modules nếu tiếp tục grow (Phase 4 only if expand)
- [ ] **P3:** Add unit tests for `classify_fall_risk` boundary values (51, 60, 85)

## Out of scope (defer Phase 3 deep-dive)

- Per-file detailed scan of health_service.py + sleep_service.py (em assumed mirror pattern from fall_service)
- `gemini_explainer.py` lines 80-215 prompt template review (PHI check)
- `prediction_contract.py` lines 80-300 detail
- `fall_featurize.py` feature engineering correctness (math validation)
- `sleep_features.py` feature derivation
- `sklearn_sleep_pickle_compat.py` backward compat strategy
- ML model accuracy / fairness audit (separate ML-ops concern)

## Cross-references

- Phase -1.B: [D-013](../../tier1/api_contract_v1.md) — auth gap (M01 fix)
- Phase -1.C: [D-018](../../tier1/topology_v2.md) — IS-001 sleep AI consumer bug (affects which service endpoint is called)
- Phase 0: Module M02 in [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)
- Consumer file: `health_system/backend/app/services/model_api_client.py` — calls these services through M01 routers
