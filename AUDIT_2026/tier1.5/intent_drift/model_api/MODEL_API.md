# Intent Drift Review — `healthguard-model-api`

**Status:** ✅ Confirmed Phase 0.5 (2026-05-13) — Q1-Q2 finalized
**Repo:** `healthguard-model-api` (ML model serving)
**Module:** MODEL_API (3 domains: Health Risk, Fall Detection, Sleep Score)
**Related UCs (old):** No dedicated UC — internal service referenced by UC016 (Risk), UC020 (Sleep)
**Phase 1 audit ref:** N/A
**Date prepared:** 2026-05-13
**Question count:** 2 (Q1 UC documentation, Q2 auth)

---

## 🎯 Mục tiêu

Capture intent cho model-api — internal ML serving service. 3 prediction domains (health/fall/sleep), each with predict + batch + model-info + sample-cases endpoints. Repo clean, well-structured. Phase 0.5 confirms no UC needed (internal service) + no auth acceptable for do an 2.

---

## 🔧 Code state — verified

### Endpoints (3 domains x 5 + system)

**Health Risk** (`/api/v1/health/`): predict, predict/batch, model-info, sample-cases, sample-input
**Fall Detection** (`/api/v1/fall/`): predict, predict/batch, model-info, sample-cases, sample-input
**Sleep Score** (`/api/v1/sleep/`): predict, predict/batch, model-info, sample-cases, sample-input
**System**: /health (per-model status), /api/v1/models, / (redirect docs)

### Services

| Service | Model | SHAP |
|---|---|---|
| health_service | LightGBM joblib | Yes |
| fall_service | XGBoost joblib (sklearn preprocessor) | Yes |
| sleep_service | CatBoost joblib (sklearn preprocessor) | Yes |

<!-- Updated 2026-05-13 (F-MA-P3-05): Fall was mis-labeled as ONNX/LightGBM, Sleep as LightGBM. Verified via fall_metadata.json (selected_model_family=xgboost) + sleep_service.py line 12 (from catboost import Pool). Health confirmed via healthguard_lightgbm.pkl artifact + health_service.py docstring. -->

### Thresholds (configurable via env)

- Fall: true_at=0.5, warning=0.6, critical=0.85
- Health: high_risk=0.5, warning=0.35, critical=0.65
- Sleep: critical<50, poor<60, fair<75, good<85

### Consumers

- health_system BE via ModelApiClient (circuit breaker + fallback)
- IoT Simulator indirect (via health_system) + direct sleep_ai_client (IS-001 bug)

---

## 💬 Decisions

### Q1: No UC
✅ **B1** — Internal service, contract doc sufficient.

### Q2: No auth
✅ **B2** — Localhost only. Production add X-Internal-Secret Phase 5+.

---

## 🎯 Decisions table

| ID | Item | Decision | Effort |
|---|---|---|---|
| **D-MA-01** | UC documentation | No UC, contract doc | ~5min |
| **D-MA-02** | Auth middleware | Keep no-auth, note production | ~5min |

**Phase 4 effort: ~10min (doc only)**

---

## 🔍 Deep-dive findings (2026-05-13)

### Verified OK

- Model load at startup (lifespan) — blocking, 3 services, degraded mode if 1 fails ✓
- Gemini explainer — optional, graceful fallback (env key not set → template) ✓
- SHAP contributions computed per prediction ✓
- Configurable thresholds via env (pydantic-settings) ✓
- Consistent response structure across 3 domains (StandardPrediction + TopFeature + ShapDetails) ✓
- Sample cases for testing/demo per domain ✓
- Health check per-model status (healthy/degraded/unhealthy) ✓

### Noted (acceptable do an 2, flag production)

| Finding | Risk | Acceptable? | Production action |
|---|---|---|---|
| CORS allow_origins wildcard (main.py) | Any origin can call | Yes - internal localhost | Restrict to health_system BE origin |
| No global exception handler | Stack trace in 500 | Yes - consumer is internal BE | Add exception handler sanitize |
| No request size limit (fall data array) | Memory spike large payload | Yes - internal + localhost | Add max_length on data field |
| No rate limiting | Unbounded requests | Yes - single consumer | Add rate limit if expose |

**None require Phase 4 action** — all acceptable for do an 2 internal service. Document for Phase 5+ production hardening.

---

## Cross-references

- `healthguard-model-api/app/routers/` — 3 domain routers + system
- `healthguard-model-api/app/services/` — 3 model services
- `healthguard-model-api/app/config.py` — thresholds + paths
- `health_system/backend/app/services/model_api_client.py` — consumer
- IS-001 bug — tracked in SLEEP D-SLP-04
