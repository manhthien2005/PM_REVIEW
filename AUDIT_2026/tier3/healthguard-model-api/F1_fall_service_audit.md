# Audit: F1 — services/fall_service.py

**File:** `healthguard-model-api/app/services/fall_service.py`
**LoC:** 249 (Phase 1 estimate 279 was slightly high)
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Fall detection service wrapper: joblib bundle load, feature preparation via `fall_featurize`, probability inference, SHAP contribution computation, top-feature selection, response contract assembly (meta + input_ref + prediction + top_features + shap + explanation). Module-level singleton `fall_service = FallModelService()` (line 249).

Covers load lifecycle, classification thresholds, XGBoost SHAP path, batch inference, Vietnamese reason overrides.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Load/guard/threshold strong. SHAP path backend-matches actual bundle (XGBoost - verified via metadata 2026-05-13). Docstring stale but runtime OK. |
| Readability | 2/3 | Class 249 LoC still borderline god-like; module docstring says LightGBM but code + bundle are XGBoost (doc drift, not bug). |
| Architecture | 2/3 | Singleton mutable state, no async boundary, service pattern consistent. |
| Security | 2/3 | No PHI in inputs (IMU sensors + environment). D-013 cross-ref. |
| Performance | 2/3 | Sync inference + always-on SHAP + synchronous Gemini call chain. |
| **Total** | **11/15** | Band: 🟡 Healthy |

## Positive findings

- Defensive load (`load()` lines 57-84): file exists -> dict type -> required keys -> backend auto-detect -> success/failure state captured in `_last_load_error`, truncated 500 chars.
- `unavailable_detail()` (line 95) exposes load error in HTTP 503 response.
- Min-length guard in `_prepare_inputs` (line 134) raises `ValueError` early -> router returns 422 cleanly.
- `decision_threshold` from bundle overrides settings default (line 173) -> model version can tune threshold without redeploy.
- `classify_fall_risk` (line 42) uses `>=` with explicit critical/warning bands -> no off-by-one.
- Payload `event_timestamp` pulled from first sample (line 237) -> input traceability without requiring separate field.
- `TOP_FEATURE_PRIORITY` (line 24) + `REASON_OVERRIDES` (line 33) separated from logic -> easy tuning.

## Findings per axis

### Correctness (3/3)

- **P3 DOWNGRADED from P1 - Docstring vs backend drift (was P1 Correctness in initial audit 2026-05-13):**
  - _shap_contributions (lines 166-173) hardcodes XGBoost DMatrix + get_booster predict(pred_contribs=True).
  - Module docstring line 1 claims LightGBM + sklearn preprocessor.
  - **Verification (2026-05-13 same-day re-check):** Read models/fall/fall_metadata.json. Fields confirm model_name fall_xgboost_small_binary, selected_model_family xgboost, export_family xgboost.
  - **Conclusion:** Bundle IS XGBoost. SHAP path runtime-correct. Docstring is stale (likely copy-paste from an earlier LGBM experiment). No production incident risk.
  - **Remaining concern:** If someone swaps to LGBM/sklearn bundle in future (which load auto-detect suggests is intended), SHAP path breaks. Add runtime assertion OR branch on self._backend.
- P2 - _build_prediction_rows (line 174-198) accesses raw_df device_id iloc i - if featurize_payloads returns empty DataFrame (all payloads had no samples), would raise. Upstream guard in _prepare_inputs prevents this, but coupling is implicit.
- P3 - predict_api zip with strict=False (line 209-216): silently truncates to shortest list. If shap_values row count mismatches inputs due to featurizer edge case, rows get dropped without warning.

### Readability (2/3)

- Module docstring (line 1) states intent clearly BUT is stale: says LightGBM + sklearn preprocessor while bundle is XGBoost (verified via metadata). Fix: update docstring to match actual bundle.
- Class length: 249 LoC borderline. Methods are well-named. predict_api (line 200-246) = 46 lines, approaching readability limit.
- Private helpers prefixed _ consistently.
- TOP_FEATURE_PRIORITY as module constant while FEATURE_ORDER in health_service is also module constant - consistent. But PATIENT_FACING_EXCLUDED_FEATURES absent here (fall_service doesn't exclude any feature) - implicit assumption IMU/environment is never PHI.

### Architecture (2/3)

- Service singleton at module bottom — consistent with health + sleep service pattern.
- Delegates featurization to `fall_featurize.featurize_payloads` (line 142) — single responsibility.
- Delegates contract building to `prediction_contract` module — DRY with health/sleep.
- Mutable instance attributes (`_bundle`, `_loaded`, `_backend`, `_last_load_error`) written only in `load()` at lifespan startup -> de-facto immutable after startup, but no documented thread-safety contract. Uvicorn worker model is async single-threaded per worker so practically safe.
- Hard dependency on `xgboost` package in import block (line 12) -> even if bundle is LGBM, xgboost must still be installed. Increases image size.
- `_shap_contributions` does `get_booster()` which implies booster-level API coupling. If bundle stores an sklearn Pipeline wrapping xgb, `get_booster()` may not exist on pipeline object.

### Security (2/3)

- Inputs are accelerometer/gyro/orientation/environment sensors — not PHI per HIPAA definition. IMU data alone doesn't identify health condition.
- `device_id` in input_ref is opaque ID, not user-identifying.
- Load error truncated 500 chars prevents stack-trace leak in `get_info()`.
- `logger.error("Cannot load fall bundle: %s", exc)` (line 81) logs raw exception message. OK at startup (no PHI in a joblib load error).
- **Cross-ref (not re-flagged):** D-013 predict endpoint has no `X-Internal-Service` check — already tracked in M01 routers audit + _TRACK_SUMMARY.md. Phase 3 confirms fall service does not enforce auth internally (defense-in-depth gap OK since auth belongs at router).
- Exception on SHAP backend mismatch (P1 Correctness finding) would propagate as HTTP 500 "Prediction error" (per M01 sanitization) — no raw leak, so Security impact limited. But Correctness impact is real.

### Performance (2/3)

- Bundle loaded once at lifespan.
- `np.asarray(..., dtype=np.float32)` explicit -> memory-efficient input to model.
- Sync `predict_proba` + `get_booster().predict` runs on event loop thread (already deducted at M01). Adds up to ~50-200ms per batch depending on sample_count x feature_dim.
- **Always-on SHAP** (line 217): every `predict_api` call runs `pred_contribs=True`. For latency-sensitive fall detection (IoT sim path, human life-safety), SHAP may add 10-50ms. No opt-out query param.
- **Sync Gemini chain:** `build_explanation` (line 242) -> `gemini_explainer.generate_explanation` -> thread join up to 12s. For fall detection flow this is a P1 latency risk (see F4 audit for detail).
- `featurize_payloads` returns pandas DataFrame -> pandas allocation per request. Acceptable for batch, suboptimal for single-window real-time.

## Recommended actions (Phase 4)

- [ ] **P3:** Update module docstring fall_service.py line 1 to match actual XGBoost backend (verified via metadata).
- [ ] **P3:** Harden SHAP path for future backend swap - either assert _backend matches expected in _shap_contributions with clear error, or branch SHAP impl per backend. Current production OK because bundle is XGB.
- [ ] **P2:** Make SHAP computation opt-in via payload flag for latency-sensitive consumers.
- [ ] **P2:** Decouple Gemini explanation from critical-path prediction - run in background task (see F4 Performance).
- [ ] **P3:** Document thread-safety contract on FallModelService (read-only after load).
- [ ] **P3:** Add regression test for zip strict=False truncation case in predict_api.

## Out of scope

- Featurization correctness (`fall_featurize.featurize_payloads`) — math validation belongs to ML-ops review, not code audit.
- Model accuracy / fairness — separate ML-ops concern per framework Out-of-scope.
- `DMatrix` feature name handling vs preprocessor feature names alignment — deferred to ML-ops test.
- Load-time impact on uvicorn worker startup — infra concern.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) - flagged 279 LoC borderline god class, SHAP always-on, Gemini hardcoded.
- Phase 1: [M01 Routers](../../tier2/healthguard-model-api/M01_routers_audit.md) - sync predict_api called from async route (perf deduct already applied upstream).
- Known findings: D-013 (no internal secret on fall predict), D-020 (IoT sim fall_ai_client missing header) - tracked Phase 1, NOT re-flagged.
- Intent drift: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) - Fall service table lists ONNX/LightGBM joblib which is INCORRECT; actual backend is XGBoost per fall metadata. Flagged for doc correction (P3, F-MA-P3-05).
- Evidence: fall metadata verified 2026-05-13 - model_name and selected_model_family both indicate xgboost backend.
- Consumer code: Iot_Simulator_clean fall_ai_client.py calls the fall predict endpoint.
- Peer file: F2 [health_service.py audit](./F2_health_service_audit.md) - uses LGBM SHAP pattern; template if backend swap ever happens.
