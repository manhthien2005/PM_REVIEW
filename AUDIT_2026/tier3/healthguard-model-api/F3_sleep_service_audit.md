# Audit: F3 — services/sleep_service.py

**File:** `healthguard-model-api/app/services/sleep_service.py`
**LoC:** 240
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Sleep score service: CatBoost bundle + optional standalone preprocessor file load, legacy sklearn ColumnTransformer unpickle shim, feature engineering via `sleep_features.prepare_inference_frame`, regression prediction (clipped 0-100), CatBoost SHAP via `get_feature_importance(type="ShapValues")`, classification bands (critical/poor/fair/good/excellent), contract assembly.

Module-level singleton `sleep_service = SleepModelService()` (line 240). Related to IS-001 (consumer-side IoT sim path bug — NOT this file).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | CatBoost SHAP correct, clip(0, 100), pickle compat shim, threshold bands explicit. |
| Readability | 3/3 | TOP_FEATURE_PRIORITY + REASON_OVERRIDES + PATIENT_FACING_EXCLUDED separated cleanly. |
| Architecture | 2/3 | Uses `sleep_features` module (symmetry with fall, not health). Singleton mutable. |
| Security | 2/3 | PHI pass-through to Gemini (user_id, sleep_efficiency, stress_score) — cross-ref F4. |
| Performance | 2/3 | Sync inference + CatBoost Pool allocation + always-on SHAP + blocking Gemini chain. |
| **Total** | **12/15** | Band: 🟡 Healthy |

## Positive findings

- **Dual preprocessor load strategy** (line 81-88): tries bundle-embedded first, falls back to standalone `sleep_score_preprocessor.joblib` if bundle missing it. Backward-compat with legacy model artifacts.
- `patch_sklearn_column_transformer_for_legacy_sleep_pickle` shim applied **twice** (lines 79, 84) — defensive: covers both bundle-load path and standalone load path where monkey-patch may be needed.
- `_predict_scores` (line 161-164) clips output to `[0, 100]` -> safety net against regression extrapolation producing absurd scores.
- `classify_sleep_score` (line 56-65) uses 5 bands with explicit `<` comparison in descending order — no off-by-one.
- CatBoost SHAP via `Pool(prepared) -> get_feature_importance(type="ShapValues")` (line 166-173) — correct CatBoost API. Contrast with fall service XGBoost mismatch (F1 P1).
- Metadata loaded optional (`sleep_metadata_path.exists()` guard, line 90-91) — service degrades gracefully if metadata missing.
- `PATIENT_FACING_EXCLUDED_FEATURES` (line 40) excludes demographics + `device_model` + `timezone` from top_features -> cleaner explanations.
- `get_info` returns both `attention_below` + `alert_below` thresholds (lines 121-123) -> consumers can reason about why a record is flagged.

## Findings per axis

### Correctness (3/3)

- Load validates dict + `"model"` key (lines 74-78). Looser than fall (fall also checks `preprocessor`) — but valid because preprocessor may come from standalone file.
- Prediction uses `requires_attention = score < attention_below` (line 187) and `high_priority_alert = score < alert_below` (line 188) — **inverse polarity** vs fall/health (those use `>=`). Correct: lower sleep score = more concerning. Intent-aligned.
- P3 — `prediction_band` in `predict_api` (line 210-218) computed via nested ternary directly from thresholds, duplicating logic of `classify_sleep_score`. If thresholds change, two places must stay in sync. Consider single function.
- P3 — `predicted_sleep_score` rounded to 2 decimals (line 179), but `confidence = round(score / 100.0, 6)` at 6 decimals (line 221). Asymmetric rounding is intentional (confidence is a ratio) but worth a code comment.
- P3 — `zip(..., strict=False)` (line 197-203) same truncation risk as fall/health if shap_values row count mismatches inputs. Low probability.

### Readability (3/3)

- Module docstring clear (line 1).
- Constants grouped at top. Vietnamese reason overrides properly diacritic.
- Methods well-sized; `predict_api` (line 190-238) is 48 lines — at borderline but acceptable.
- Tuple destructuring in `_prepare_inputs` (line 142): `_, X = prepare_inference_frame(records)` — ignores raw_df intentionally (discard first tuple element).

### Architecture (2/3)

- Uses `sleep_features.prepare_inference_frame` (separate module) — matches `fall_featurize` pattern.
- Shared contract builders from `prediction_contract`.
- P3 — `patch_sklearn_column_transformer_for_legacy_sleep_pickle` is a **runtime monkey-patch** invoked twice per load. This is a known tech-debt indicator (coupling to a specific sklearn version). Document the sklearn version lock.
- `Pool(prepared)` allocation per prediction (line 168) — CatBoost requires it for SHAP. Acceptable.
- Singleton mutable state not documented.

### Security (2/3)

- **P1 cross-ref (owned by F4) — PHI -> Gemini:** `predict_api` (line 191) passes `row = X.to_dict()` and `raw_record` into `build_top_features` / `build_explanation`. Sleep features include `sleep_efficiency_pct`, `stress_score`, `spo2_mean_pct`, `heart_rate_mean_bpm` — these ARE sensitive health indicators. `user_id` also flows into `input_ref` (line 227) and potentially to Gemini if the contract builder leaks it (checked: `_format_features` only reads top_features, not input_ref, so user_id stays in meta). Risk comparable to F2 health but slightly lower (sleep metrics less acute).
- P3 NEW — `raw_record.get("user_id")` (line 227) — user_id passed into `input_ref` verbatim. Response contract echoes user_id to consumer. Acceptable pattern (consumer sent it), but if logged raw elsewhere could trace patient. No raw PHI in logs here.
- `logger.error("Failed to load sleep bundle: %s", exc)` (line 100) — same as fall/health: startup-only exception log, OK.
- **Cross-ref (not re-flagged):** D-013 (no auth on `/sleep/predict`). IS-001 (IoT sim `sleep_ai_client.py` wrong path) — consumer bug, tracked separately.

### Performance (2/3)

- Bundle + optional preprocessor loaded once.
- CatBoost `Pool` allocation per `predict_api` call (line 168) — unavoidable for `ShapValues` type; adds ~small ms.
- Sync in async, always-on SHAP, blocking Gemini — same deducts as F1/F2.
- `_predict_scores` calls `np.clip` after `predict` -> O(N) over scores, negligible.
- `prepare_inference_frame` (from `sleep_features`) does groupby rolling stats per user_id — if `records` batch contains many users, pandas groupby cost scales. Batch endpoint not rate-limited (M04 finding).

## Recommended actions (Phase 4)

- [ ] **P1 (cross-ref F4):** PHI redaction in Gemini prompt — shared action with F2.
- [ ] **P2:** Extract `prediction_band` logic (line 211-218) into `classify_sleep_band` helper to avoid duplication with `classify_sleep_score`.
- [ ] **P2:** Document sklearn version requirement for `sklearn_sleep_pickle_compat` shim in a top-of-file comment or `pyproject.toml` constraint.
- [ ] **P3:** Add unit tests for threshold boundary values (score = 49.99, 50.0, 50.01, 59.99, 60.0).
- [ ] **P3:** Consider making `include_shap` opt-in via payload to reduce CatBoost Pool allocation on low-latency batch calls.

## Out of scope

- `sleep_features.prepare_inference_frame` feature engineering math correctness — ML-ops review (cyclic encoding, BMI, behavioral_risk_index, etc.).
- `sklearn_sleep_pickle_compat` backward-compat strategy full audit — tech-debt review.
- IS-001 fix (IoT sim sleep_ai_client path) — consumer-side, separate bug.
- Sleep score model accuracy / calibration — ML-ops.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) — mirror pattern verified + consumer relation to IS-001.
- Phase 1: [M01 Routers](../../tier2/healthguard-model-api/M01_routers_audit.md) — D-013 auth gap at router.
- Intent drift: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — Sleep service = LightGBM per drift doc BUT code uses CatBoost (`from catboost import Pool`). **Potential doc drift:** intent drift table mis-labels sleep backend. Flag for doc correction (P3).
- Consumer code: `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` — IS-001 path bug tracked separately; also missing X-Internal-Service header per D-020.
- Peer files: F1 [fall_service.py](./F1_fall_service_audit.md), F2 [health_service.py](./F2_health_service_audit.md), F4 [gemini_explainer.py](./F4_gemini_explainer_audit.md).
- Bug: [IS-001](../../../BUGS/IS-001-sleep-ai-client-wrong-path.md) — consumer-side, unaffected by this file.
