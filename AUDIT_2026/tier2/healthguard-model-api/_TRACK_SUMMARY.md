# Track 4 Summary — healthguard-model-api

**Phase:** Phase 1 macro audit
**Date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory:** [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)

---

## TL;DR

**Repo verdict:** **🟡 Healthy với 🔴 Critical security debts (D-013)**

Module quality cao (architecture, readability, correctness >= 2/3 across all modules). NHƯNG **security score = 0** ở 2 modules (M01 routers + M04 bootstrap) do D-013 (no internal secret check) + CORS misconfig → auto-Critical band.

Phase 4 fix D-013 + CORS = unlock band promotion từ 🔴 → 🟡 cho 2 modules. Sau fix, repo overall = 🟢 Mature.

---

## Module scores

| Module | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|
| [M01 Routers](./M01_routers_audit.md) | 3 | 3 | 2 | **0** | 2 | 10/15 | 🔴 Critical |
| [M02 Services](./M02_services_audit.md) | 3 | 2 | 2 | 2 | 2 | 11/15 | 🟡 Healthy |
| [M03 Schemas](./M03_schemas_audit.md) | 2 | 3 | 3 | 2 | 3 | 13/15 | 🟢 Mature |
| [M04 Bootstrap](./M04_bootstrap_audit.md) | 2 | 3 | 3 | **0** | 2 | 10/15 | 🔴 Critical |
| [M05 Scripts](./M05_scripts_audit.md) (skim) | 2 | 2 | 2 | 3 | 3 | 12/15 | 🟡 Healthy |
| **Repo average** | 2.4 | 2.6 | 2.4 | 1.4 | 2.4 | **11.2/15** | 🟡 Healthy* |

*Repo average masks 2 modules at 🔴 Critical from Security=0. Post-fix average: ~12.6/15.

---

## Critical findings (P0 — block Phase 4)

| ID | Module | Issue | Fix file |
|---|---|---|---|
| D-013 | M01, M04 | No `verify_internal_secret` dependency on predict endpoints; no `internal_secret` field in Settings | `config.py`, `main.py`, new `dependencies.py`, all 3 router predict endpoints |
| CORS | M04 | `allow_origins=["*"]` + `allow_credentials=True` (anti-pattern + spec violation) | `main.py:60-66` |
| D-014 | M04 | `/health` semantic collision with `/api/v1/health/*` | Rename to `/healthz` (small, P2) |

**P0 fix sequence:**
1. Add `internal_secret` field to Settings (M04)
2. Create `app/dependencies.py` với `verify_internal_secret` function
3. Add `Depends(verify_internal_secret)` to all 3 `/predict` + 2 `/predict/batch` endpoints (M01)
4. Coordinate cross-repo:
   - `health_system/backend/app/services/model_api_client.py` already sends `X-Internal-Service: health-system-backend` ✓
   - `Iot_Simulator_clean/simulator_core/fall_ai_client.py` MUST add header (D-020)
   - `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` MUST add header (D-020) + fix path (IS-001)
5. Fix CORS allowlist via env var
6. Smoke test mobile flow + IoT sim flow before deploy

**Estimated Phase 4 effort:** 4-6h (small surface, well-isolated)

---

## P1 backlog (Phase 4 secondary)

- [ ] Wrap sync ML inference với `asyncio.to_thread` (M01 + M02)
- [ ] Move sample-cases JSON loader from router to service layer (M01 architecture cleanup)
- [ ] Expose Gemini config via Settings (M02)
- [ ] Add range validators to `SleepRecord` + `HealthRecord` fields (M03 — physiological bounds)

## P2 backlog (defer or Phase 5+)

- [ ] Add rate limiting middleware (M04)
- [ ] Add `TrustedHostMiddleware` (M04)
- [ ] Add `max_length` to string schemas (M03)
- [ ] Convert string fields to Literal enum where bounded (M03)
- [ ] Add structured JSON logging option for prod (M04)
- [ ] Add unit tests for threshold boundary values (M02)
- [ ] Verify ValueError messages don't leak schema internals (M01)

---

## Phase 3 deep-dive candidates (promoted from inventory)

Based on macro findings, these modules warrant per-file deep audit:

- [ ] `services/fall_service.py` — 279 LoC borderline god class; SHAP integration; threshold logic
- [ ] `services/health_service.py` — verify mirror Fall pattern + range bounds
- [ ] `services/sleep_service.py` — verify mirror + IS-001 related (consumer-side)
- [ ] `services/gemini_explainer.py` lines 80-215 — prompt template PHI check
- [ ] `services/prediction_contract.py` lines 80-300 — SHAP base value handling
- [ ] `schemas/health.py` + `schemas/sleep.py` — range constraint addition

---

## Cross-repo coordination (Phase 4)

D-013 fix affects 3 repos:

```
healthguard-model-api (Phase 4 fix)
       ↓ enforce X-Internal-Service header
health_system BE (model_api_client.py — already sends ✓)
       ↓ no change needed
Iot_Simulator_clean (Phase 4 fix simultaneous)
   - fall_ai_client.py: add header
   - sleep_ai_client.py: add header + fix path (IS-001)
```

→ **Phase 4 cần single PR** chứa 3-repo coordinated change (or 3 PRs merged simultaneously) để no downtime.

---

## Out of scope (Phase 1 macro complete)

Phase 1 không cover:
- Per-file deep code review (Phase 3 deep-dive)
- ML model accuracy/fairness (separate ML-ops concern)
- Test coverage matrix (separate report)
- Deployment configs (Docker, uvicorn args)
- Performance benchmarks (load testing)

---

## Phase 1 Track 4 Definition of Done

- [x] All 5 modules (M01-M05) audited với 5-axis rubric
- [x] Each module has output file `Mxx_*_audit.md`
- [x] Critical findings prioritized P0/P1/P2
- [x] Phase 3 deep-dive candidates promoted from macro findings
- [x] Cross-repo coordination noted (D-013 → 3 repos)
- [x] Track summary aggregated (this file)
- [ ] ThienPDM review
- [ ] Commit + PR
- [ ] Merge → Phase 1 Track 5 (IoT sim) start

**Next:** Phase 1 Track 5A (IoT simulator security focus, paired with IS-001 + D-020 fix planning)


---

## Phase 3 deep-dive results (2026-05-13)

Session 1 (F1-F6) completed 2026-05-13 AM. Session 2 (F7-F9) extended scope closed 2026-05-13 PM - fall schema + 2 feature-engineering helper modules.

| File | Total | Band | Audit doc |
|---|---|---|---|
| F1 fall_service.py | 11/15 | 🟡 Healthy | [link](../../tier3/healthguard-model-api/F1_fall_service_audit.md) |
| F2 health_service.py | 12/15 | 🟡 Healthy | [link](../../tier3/healthguard-model-api/F2_health_service_audit.md) |
| F3 sleep_service.py | 12/15 | 🟡 Healthy | [link](../../tier3/healthguard-model-api/F3_sleep_service_audit.md) |
| F4 gemini_explainer.py | 9/15 | 🟠 Needs attention | [link](../../tier3/healthguard-model-api/F4_gemini_explainer_audit.md) |
| F5 prediction_contract.py | 13/15 | 🟢 Mature | [link](../../tier3/healthguard-model-api/F5_prediction_contract_audit.md) |
| F6 health/sleep schemas | 13/15 | 🟢 Mature | [link](../../tier3/healthguard-model-api/F6_health_sleep_schemas_audit.md) |
| F7 fall schema | 13/15 | 🟢 Mature | [link](../../tier3/healthguard-model-api/F7_fall_schema_audit.md) |
| F8 fall_featurize.py | 13/15 | 🟢 Mature | [link](../../tier3/healthguard-model-api/F8_fall_featurize_audit.md) |
| F9 sleep_features.py | 12/15 | 🟡 Healthy | [link](../../tier3/healthguard-model-api/F9_sleep_features_audit.md) |
| **Average** | **12.0/15** | 🟡 Healthy | - |

**Band distribution:** 4 Mature (F5, F6, F7, F8), 4 Healthy (F1, F2, F3, F9), 1 Needs attention (F4). No Critical. Average moved from 11.7 (6 files) to 12.0 (9 files) because the 3 extended-scope files (F7 schema + F8/F9 pure featurizers) scored well - no new Critical/Needs-attention items.

### Phase 3 top findings (new, distinct from Phase 1/0.5)

Listed in priority order. Cross-ref only when finding was already flagged.

1. **F-MA-P3-01 (P1 Security) - PHI values sent to external LLM API** (F4, cross-ref F2 + F3)
   - gemini_explainer _format_features embeds raw feature values (SpO2, HR, BP, body_temperature, sleep_efficiency, stress_score) in prompt body.
   - Values are HIPAA-class PHI per 40-security-guardrails.md. Consumer-grade API path retains prompts for model improvement absent BAA.
   - **Acceptable đồ án 2** (synthetic data, internal localhost). **Not acceptable production.**
   - **Action:** replace values with band labels (low/normal/high) OR strip values entirely OR gate via env flag default off.

2. **F-MA-P3-04 (P1 Performance) - gemini_explainer 12s blocks event loop + orphaned threads** (F4)
   - thread join with 12s timeout runs synchronously from awaited FastAPI route -> blocks single uvicorn worker event loop up to 12s per prediction. Fall detection (life-safety) most impacted.
   - On timeout, daemon thread keeps running -> unbounded thread growth under burst load.
   - **Action:** move explainer to FastAPI BackgroundTasks OR separate explain endpoint. Replace Python-thread timeout with httpx socket timeout.

3. **F-MA-P3-02 (P1 Correctness) - schemas missing physiological range validators** (F6)
   - VitalSignsRecord + SleepRecord accept negative HR, 105 percent SpO2, -5C body_temperature, 1000kg weight, etc. Router-level Pydantic validates only presence/type, not physiological plausibility.
   - Garbage-in propagates through feature engineering -> model inference -> plausible-looking but nonsensical prediction.
   - Phase 1 M03 flagged P1; Phase 3 provides per-field bound tables.
   - **Action:** add Field ge/le per table in F6 audit + unit tests for boundaries.

4. **F-MA-P3-05 (P3 Doc drift, RESOLVED 2026-05-13) - intent drift MODEL_API.md + fall_service docstring mis-label backends** (F1, F3)
   - MODEL_API.md services table listed sleep model as LightGBM joblib; code uses CatBoost (sleep_service line 12 catboost Pool import).
   - Fall listed as ONNX/LightGBM joblib but fall metadata confirms selected_model_family xgboost. Also fall_service docstring line 1 incorrectly said LightGBM.
   - **Action taken (2026-05-13):** Updated MODEL_API.md services table (Fall=XGBoost, Sleep=CatBoost). Updated fall_service.py line 1 docstring to XGBoost. Health confirmed LightGBM (no change). Evidence noted inline in MODEL_API.md.

5. **F-MA-P3-03 (P3 Correctness, DOWNGRADED from P1) - fall_service SHAP backend drift** (F1)
   - Initial audit flagged SHAP backend mismatch as P1 Correctness (potential HTTP 500 on every fall predict). Same-day re-verification via fall metadata confirms bundle IS XGBoost - SHAP path runtime-correct.
   - Remaining concern is defense-in-depth: load auto-detects 3 backends but _shap_contributions only supports XGB. Future bundle swap to LGBM/sklearn would break.
   - **Action:** Add runtime assertion OR branch SHAP path per backend. Low urgency (current production OK).

6. **F-MA-P3-06 (P1 Correctness) - fall schema missing IMU sensor range validators** (F7)
   - `AccelData`, `GyroData`, `OrientationData`, `EnvironmentData`, `SensorSample.timestamp` accept unbounded floats/ints. Garbage sensor input (accel=99999 m/s^2) propagates through `fall_featurize` -> inflated features -> XGBoost out-of-distribution prediction -> potential false-positive fall alert (life-safety path via SOS flow).
   - Extends F-MA-P3-02 (F6) pattern to fall domain. F7 provides per-field bound table (accel +/-16g, gyro +/-2000dps, orientation -180..360, environment 0..1 or 0..100, timestamp ge=0).
   - **Action:** Add `Field(ge=..., le=...)` on all nested sensor models + unit tests for boundary values.

7. **F-MA-P3-07 (P2 Security) - fall schema string + list fields lack max_length** (F7)
   - `device_id: str = "unknown"` has no `max_length` -> 10MB device_id flows into `input_ref` + logs.
   - `FallPredictionRequest.data` has `min_length` from config but no `max_length` -> 10M-sample window = memory bomb.
   - `FallPredictPayload` list arm has `min_length=1` but no `max_length` -> 10M-window batch.
   - Extends F6 + Phase 0.5 finding to fall domain explicitly.
   - **Action:** Add `max_length=64` on device_id, `max_length=500` on data list, `max_length=100` on batch list arm. Acceptable for đồ án 2 per Phase 0.5; mandatory Phase 5+.

8. **F-MA-P3-08 (P2 Correctness) - fall_featurize post_impact fallback relies on upstream guard** (F8)
   - `extract_sequence_features` uses ternary `if accel_mag.size else np.array([0.0])` to avoid empty-slice crash. Safe but only reachable when upstream `fall_service._prepare_inputs` guard is intact (`len(data) >= fall_min_sequence_samples`). No local assert; direct call with `sequence_length=0` produces silent zero-feature output.
   - **Action:** Add `assert len(group) > 0` at top of `extract_sequence_features` for defense-in-depth.

9. **F-MA-P3-09 (P2 Correctness) - NaN silently propagates through featurization layers** (F8, F9)
   - Pydantic v2 `float` accepts NaN. `fall_featurize.summarize_series` + `sleep_features.add_features` let NaN flow to XGBoost/CatBoost which handle NaN silently - predictions still returned but meaning undefined.
   - No `.fillna()` or NaN detection at module boundary.
   - **Action:** Pick one contract: (a) reject NaN at Pydantic layer via `model_validator`, or (b) `frame_df.fillna(0.0)` inside featurizers. Document in docstring.

10. **F-MA-P3-10 (P2 Correctness) - sleep_features BMI division-by-zero unguarded** (F9)
    - Line 57-58: `data["bmi"] = data["weight_kg"] / (height_m**2)`. Schema accepts `height_cm=0` (per F6 F-MA-P3-02) -> `bmi=inf` flows to CatBoost. Inconsistent with `duration_minutes.clip(lower=1)` pattern used elsewhere in same module.
    - **Action:** `.clip(lower=0.3)` on height_m defense-in-depth, OR rely on F6 Pydantic range fix.

11. **F-MA-P3-11 (P2 Correctness) - sleep_features pd.to_datetime lenient parsing + timezone-ambiguous** (F9)
    - `pd.to_datetime(...)` called without `format=` or `utc=` on 4 timestamp columns. Slow (auto-detect per row), ambiguous dates per locale, mixed-offset silent normalization, `.dt.hour` meaning depends on consumer's timezone intent.
    - `SleepRecord.timezone: str` field exists but unused in featurization.
    - **Action:** Pin `format="ISO8601"` + `utc=True`, document contract, consider upstream F6 P3 (convert `str` -> `datetime` at Pydantic layer).

12. **F-MA-P3-12 (P2 Correctness) - groupby transform("std") returns NaN for single-record users** (F9, extends F3)
    - Lines 81-84: 3 `groupby(GROUP_COL).transform(...)` calls. `std()` default `ddof=1` -> NaN for single-record group. Typical inference path (mobile sends 1 record) always hits this case -> `user_bedtime_std` = NaN fed to CatBoost.
    - F3 audit noted groupby cost; F9 extends with correctness impact for single-record case.
    - **Action:** `.fillna(0.0)` after groupby transform OR use `ddof=0` equivalent. Document.

### Other noteworthy Phase 3 observations (not escalated — noted for context)

- F4 daemon-thread timeout pattern orphans threads — memory creep risk (covered under F-MA-P3-04).
- F1/F3 use `zip(..., strict=False)` — silent truncation risk (low probability).
- F5 `_reason_value(0.0)` edge case returns empty string.
- F6 SleepRecord string fields lack max_length — DoS vector (cross-ref Phase 0.5 which already acknowledged fall data list size; extend to all domains).
- F2 `prepare_inference_frame` as module-level free function inconsistent with fall (featurize module) + sleep (features module) pattern.
- F3 sleep uses `sklearn_sleep_pickle_compat` runtime monkey-patch — tech-debt flag (sklearn version lock).
- F7 `FallPredictPayload` Union type produces verbose Pydantic error messages on both arms — DX tradeoff for single-or-batch endpoint.
- F8 `SENSOR_ONLY_EXCLUDE_*` constants declared but unused — dead code (grep-confirmed).
- F8 `np.percentile` uses default interpolation method — may drift from training if training pinned `method="median_unbiased"`.
- F8 + F9 docstrings reference training-side source module but no CI check for feature drift.
- F9 5-way `pd.concat` for cyclic encode is efficient (single alloc) but 3 separate `groupby.transform` calls could merge into 1 `groupby.agg` (defer Phase 5+).
- F9 `prepare_inference_frame` accepts both `list[dict]` and `pd.DataFrame` - flexibility for training reuse, inference always passes `list[dict]`.

### Phase 3 Definition of Done

- [x] 6 target files audited (F1-F6) — session 1
- [x] 3 extended-scope files audited (F7-F9) — session 2
- [x] Tier3 folder structure created
- [x] Each file scored against 5-axis rubric with positive findings + issues
- [x] Cross-references to Phase 1 + Phase 0.5 (no duplication of known findings)
- [x] Track summary updated with Phase 3 section (this block) + session 2 results
- [x] F-MA-P3-03 backend mismatch verified against fall metadata (XGBoost confirmed, downgraded P1 to P3)
- [x] F-MA-P3-06 through F-MA-P3-12 escalated from session 2 (7 new findings: 1 P1 + 6 P2)
- [ ] ThienPDM review
- [ ] Follow-up decisions on F-MA-P3-01 through F-MA-P3-12
