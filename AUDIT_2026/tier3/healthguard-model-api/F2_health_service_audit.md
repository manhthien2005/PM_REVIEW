# Audit: F2 — services/health_service.py

**File:** `healthguard-model-api/app/services/health_service.py`
**LoC:** 253
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Health risk service: LightGBM bundle load, `prepare_inference_frame` helper (module-level, unique to this file), probability inference, LightGBM SHAP via `booster_.predict(pred_contrib=True)`, classification bands, contract assembly. Module-level singleton `health_service = HealthModelService()` (line 253).

Key difference vs fall service: inputs are **raw vital signs** (heart rate, SpO2, BP, body temperature, BMI derived) — directly PHI.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Proper LGBM SHAP path, explicit FEATURE_ORDER, missing-key validation, robust `_prepared_frame` column recovery. |
| Readability | 3/3 | Clear FEATURE_ORDER constant, reason overrides with diacritics, methods well-named. |
| Architecture | 2/3 | `prepare_inference_frame` as module-level function (inconsistent with sleep/fall split); otherwise clean. |
| Security | 2/3 | PHI pass-through to Gemini prompt (NEW P3 finding). D-013 cross-ref. |
| Performance | 2/3 | Sync inference + always-on SHAP + blocking Gemini chain. |
| **Total** | **12/15** | Band: 🟡 Healthy |

## Positive findings

- `FEATURE_ORDER` (line 26) as explicit list -> single source of truth for input schema alignment with model.
- `prepare_inference_frame` (line 64) checks `missing = sorted(required - set(df.columns))` and raises `ValueError` with list of missing keys — actionable 422 error.
- Load validates bundle shape (dict, has `preprocessor` + `model`) and validates `feature_names` match `FEATURE_ORDER` set (line 96-99) — catches stale model artifacts at startup.
- `_prepared_frame` (line 165-171) gracefully handles preprocessor output as either DataFrame or numpy array — defends against sklearn ColumnTransformer behavior drift.
- `_predict_probabilities` (line 186-191) handles 1-column proba output (`proba.shape[1] > 1`) — correct for LGBM `predict_proba` variants.
- LightGBM SHAP done correctly via `booster_.predict(pred_contrib=True)` (line 207-212) — contrast with fall_service which hardcodes XGBoost.
- `PATIENT_FACING_EXCLUDED_FEATURES` (line 45) excludes immutable demographics from top_features presented to clinicians/users — reduces noise in explanations.
- Reason overrides use proper Vietnamese diacritics + specific phrasing (line 52-58).

## Findings per axis

### Correctness (3/3)

- Load lifecycle equivalent to fall_service pattern (line 90-113) — defensive, captures failure cleanly.
- Feature-name alignment check: `set(fn) == set(FEATURE_ORDER)` (line 98) — detects if training features drift from expected.
- Threshold classification uses `>=` on explicit bands (`classify_health_risk` line 78).
- No zip-strict=False truncation risk: `_predict_probabilities` returns shape (N,) matching input N.
- P3 — `_build_prediction_rows` (line 213-230) returns `predicted_health_risk_label` = "high_risk" if `prob_f >= t.high_risk_true_at` (default 0.5), but `risk_level` uses `classify_health_risk` which only returns "critical"/"warning"/"normal". So if `prob_f` = 0.5 -> label=high_risk + risk_level=warning (0.35 <= 0.5 < 0.65). Semantic overlap (label != risk_level) is intentional but could confuse consumers. Not a bug.

### Readability (3/3)

- Module docstring line 1 clear.
- Constants grouped at top: `FEATURE_ORDER`, `TOP_FEATURE_PRIORITY`, `PATIENT_FACING_EXCLUDED_FEATURES`, `REASON_OVERRIDES`.
- `prepare_inference_frame` accepts both list[dict] and DataFrame — flexible helper.
- P3 — `prepare_inference_frame` (line 63-73) is **module-level free function** (not method), which differs from:
  - `fall_service`: no free function (featurization lives in `fall_featurize`)
  - `sleep_service`: uses `from app.services.sleep_features import prepare_inference_frame` (separate module)
  Inconsistency: health pattern is "free function in service file", sleep is "separate module". Not critical but confusing when reading the 3 services side-by-side.
- Method lengths reasonable: longest is `predict_api` (line 232-251, 20 lines).

### Architecture (2/3)

- Service singleton pattern consistent.
- Uses shared contract builders from `prediction_contract`.
- **`prepare_inference_frame` module-level function** inside service file — mixes concerns (schema validation + DataFrame assembly). Could extract to `health_features.py` for symmetry with `sleep_features.py` + `fall_featurize.py`.
- `_model_input_columns` (line 173-180) probes `feature_names_in_` / `n_features_in_` — leaky abstraction across sklearn / LGBM attribute names. Acceptable pragmatism.
- Hard dependency on `pandas` (line 10). Acceptable (featurization demands it).

### Security (2/3)

- **P1 NEW — PHI -> Gemini external API (F-MA-P3-01):** `predict_api` (line 232) passes `row = X.to_dict(orient="records")` into `build_shap_payload` -> `build_top_features` -> `build_explanation` -> `gemini_explainer.generate_explanation`. Feature values (SpO2, HR, BP, body_temperature, derived_map) are **raw PHI** and get formatted into the Gemini prompt via `gemini_explainer._format_features` (see F4 audit, line 79-87). Google Gemini receives individual patient vital snapshots over HTTPS.
  - **Intent drift Phase 0.5 acceptance:** Gemini explainer noted as "optional, graceful fallback" in MODEL_API.md but PHI-to-third-party was not explicitly discussed.
  - **Security rule (`40-security-guardrails.md`):** HIPAA-class data; PHI must encrypt at rest + HTTPS in transit. Gemini uses HTTPS (ok) but third-party processing still creates a Google data-processor relationship not covered in spec.
  - **Acceptable for đồ án 2:** flag only (internal localhost + no real patients), production must either (a) redact values to bands ("spo2: low/normal/high"), (b) disable Gemini, or (c) sign BAA with Google.
  - **Scope note:** root cause is in `gemini_explainer.py` (F4) — this audit cross-refs; F4 owns the P1.
- P3 NEW — `PATIENT_FACING_EXCLUDED_FEATURES` excludes `age`, `gender`, `weight_kg`, `height_m`, `derived_bmi` from top_features presented to user/clinician — but these still flow to Gemini prompt via full `row` dict. Wait — rechecking: `gemini_explainer._format_features(top_features[:5])` uses top_features only, not raw row. So excluded demographics are NOT sent to Gemini. Good defense-in-depth via top_features filter. Upgrade Gemini PHI severity slightly — only top-5 vitals go to Gemini, not full payload.
- **Cross-ref (not re-flagged):** D-013 (no internal secret on `/health/predict`) — Phase 1 M01 + _TRACK_SUMMARY.md. Defense-in-depth: health service itself doesn't check auth (belongs at router boundary).
- `logger.error("Failed to load health bundle: %s", exc)` (line 113) — raw exception logged at startup, no PHI (joblib load), OK.

### Performance (2/3)

- Bundle loaded once.
- `booster_.predict` with LGBM native is fast (microseconds-ms per record).
- Sync inference in async pipeline — M01 deduct already applied.
- Always-on SHAP per record.
- Blocking Gemini chain up to 12s (F4 Performance).
- `prepare_inference_frame` creates DataFrame copy per call (line 71) -> small payload overhead. Acceptable.

## Recommended actions (Phase 4)

- [ ] **P1 (cross-ref F4):** Redact PHI values from Gemini prompt — either send feature names + direction only (no raw numeric), or bucket values into bands (low/normal/high) before formatting. Track under shared action with F4.
- [ ] **P2:** Extract `prepare_inference_frame` (line 63-73) to `health_features.py` for consistency with sleep+fall feature module pattern.
- [ ] **P2:** Add unit test asserting `FEATURE_ORDER` matches Phase 0 schema + model training bundle feature_names.
- [ ] **P3:** Clarify semantic overlap between `predicted_health_risk_label` (binary) and `risk_level` (ternary) in response schema docstring.

## Out of scope

- Gemini explainer PHI handling root cause -> covered in F4.
- Model accuracy / fairness / calibration — ML-ops concern.
- Database-layer encryption of stored predictions — not this service's responsibility (Model API is stateless).

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) — mirror pattern confirmed + PHI check flagged for Phase 3 (now resolved here + F4).
- Phase 1: [M01 Routers](../../tier2/healthguard-model-api/M01_routers_audit.md) — D-013 auth gap at router (not re-flagged).
- Intent drift: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — Health service = LightGBM joblib with SHAP, matches code.
- Consumer code: `health_system/backend/app/services/model_api_client.py` — sends vital records via `/api/v1/health/predict`.
- Peer files: F1 [fall_service.py](./F1_fall_service_audit.md) (XGB SHAP mismatch), F3 [sleep_service.py](./F3_sleep_service_audit.md), F4 [gemini_explainer.py](./F4_gemini_explainer_audit.md).
- Security rule: `40-security-guardrails.md` PHI section — encryption at rest + audit log mandatory production.
