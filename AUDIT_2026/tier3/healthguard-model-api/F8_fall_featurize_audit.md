# Audit: F8 — services/fall_featurize.py

**File:** `healthguard-model-api/app/services/fall_featurize.py`
**LoC:** 146
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive extended (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

IMU window featurization pipeline: dict-payload normalization -> long-form `frame_df` (per-timestep) -> frame-level magnitudes + deltas -> sequence-level aggregation (mean/std/min/max/median/quartiles/range/energy/slope per signal) -> specialty fall features (peak impact, post-impact stats, environment contact score, orientation dispersion, motion stability).

Public entry point: `featurize_payloads(payloads: list[dict], feature_names: list[str] | None)` called by `fall_service._prepare_inputs` (F1 line 142).

Focus per task brief: edge cases (empty windows, NaN), code-level correctness (not math validation), vectorization, side effects, zip usage.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Empty-payload guard present but empty-sample handling fragile; NaN not explicit; division-by-zero guarded with 1e-6 epsilons; `post_impact_accel_*` safe via ternary but relies on upstream guard. |
| Readability | 3/3 | Small focused functions, typed signatures, constants grouped at top, docstring pointers to training-side module. |
| Architecture | 3/3 | Pure functions (no side effects, no globals mutated), single-responsibility separation (frame features / sequence features / payload normalization), module-level constants for training parity. |
| Security | 3/3 | No PHI, no I/O, no network, no user input parsed as code. Consumes dict data, produces DataFrame. Safe. |
| Performance | 2/3 | Pandas groupby inside `add_frame_features` runs twice (accel + gyro diff); `extract_sequence_features` calls `to_numpy()` 16 times per group (one per signal) - slightly wasteful. No vectorized batch path for multi-window case. |
| **Total** | **13/15** | Band: Mature |

## Positive findings

- **Module docstring** (line 1) references training-side module `healthguard-ai/models/fall/fall_modeling.py` - ML-ops parity intent documented. Anyone updating features must update both.
- **Pure functions throughout**: `add_frame_features`, `summarize_series`, `extract_sequence_features`, `build_sequence_dataset`, `_normalize_sample`, `featurize_payloads` all take inputs + return outputs, no mutation of module state. Easy to test in isolation.
- **Defensive copy** in `add_frame_features` (line 37): `data = df.copy()` - caller's `frame_df` not mutated. Composable.
- **Explicit dtype** (`dtype=float`, `dtype=np.float32` downstream via fall_service): numeric stability + memory control.
- **Division-by-zero guarded with epsilon** (lines 89-91, 98-100): `max(accel_mag.mean(), 1e-6)` + `(accel_delta_mag.mean() + 1e-6) / (accel_mag.mean() + 1e-6)`. Prevents inf/nan propagation from all-zero sensor windows.
- **Empty-frame guard** (lines 154-155): `if frame_df.empty: return pd.DataFrame(columns=feature_names or []), raw_df` - explicitly handles the "all payloads had empty `data` list" case. Returns empty DataFrame with correct columns for downstream reindex.
- **`feature_names` reindex** (lines 158-159): `features_df.reindex(columns=feature_names, fill_value=0.0)` - guarantees bundle feature order + fills missing with 0. Robust against schema drift (new feature added to training but old bundle loaded, or vice versa).
- **Polyfit guarded by `np.ptp(t) > 0`** (line 61): `slope = ... if arr.size > 1 and np.ptp(t) > 0 else 0.0` - prevents `LinAlgError` when all timesteps are identical (degenerate window).
- **`ddof=0`** explicit on `np.std` (lines 66, 92): matches NumPy population-std convention; consistency with training preprocessing (assumed).
- **Constants exported at module top** (lines 10-32): `SAMPLING_RATE`, `FALL_LABELS`, `SEQUENCE_SIGNAL_COLUMNS`, `STAT_NAMES`, `SENSOR_ONLY_EXCLUDE_*` - no magic numbers in function bodies.
- **`sort=False`** in `groupby("sequence_id", sort=False)` (line 106): preserves caller order; correct for batch inference where payload index maps to response index.
- **`summarize_series` returns dict** (line 65): downstream `extract_sequence_features` iterates via `.items()` - stable key ordering (Python 3.7+ dict insertion order).

## Findings per axis

### Correctness (2/3)

- **P2 NEW - `post_impact_accel_mean/std` fallback via ternary only (F-MA-P3-08):**
  - Lines 89-92:
    ```python
    peak_index = int(np.argmax(accel_mag)) if accel_mag.size else 0
    impact_slice = accel_mag[peak_index:] if accel_mag.size else np.array([0.0])
    ...
    features["post_impact_accel_mean"] = float(impact_slice[:10].mean())
    features["post_impact_accel_std"] = float(impact_slice[:10].std(ddof=0))
    ```
  - Ternary `if accel_mag.size else np.array([0.0])` ensures `impact_slice` is never empty. Safe.
  - BUT upstream `_prepare_inputs` in F1 raises `ValueError` when `len(data) < settings.fall_min_sequence_samples` (default 50). Actual reach of the `else` branch is dead code under normal call path.
  - If a future caller bypasses the service guard (unit test calling `extract_sequence_features` directly with `sequence_length=0`), `accel_mag = group["accel_mag"].to_numpy(...)` at line 85 returns empty array, hits fallback - `mean([0.0]) = 0.0` - no crash but silent zero-feature output. Document or assert explicitly.
  - **Action:** Add `assert len(group) > 0, "sequence must have at least one timestep"` at top of `extract_sequence_features`, OR handle length-0 explicitly.

- **P2 NEW - NaN silently propagates from input (F-MA-P3-09):**
  - `_normalize_sample` (lines 108-126) uses `float(accel.get("x", 0.0))` - if payload explicitly sends `"x": null` (JSON null), `.get("x", 0.0)` returns `None` -> `float(None)` raises `TypeError`. Reachable via Pydantic: `SensorSample.accel.x: float` rejects `None` at boundary with 422, so this path is protected.
  - BUT if payload sends `"x": NaN` (invalid JSON, but some parsers accept), Pydantic v2 float coerces NaN -> NaN. Then `accel_mag = sqrt(x**2 + ...)` = NaN -> all dependent features NaN -> XGBoost handles NaN silently (XGB native NaN support) -> model output may be surprising but not crash.
  - The `_prepare_inputs` service path does NOT run `.fillna()` or NaN detection before feeding to preprocessor. Preprocessor may or may not handle NaN (depends on sklearn transformer config).
  - **Action:** At boundary of `featurize_payloads`, optionally call `frame_df = frame_df.fillna(0.0)` or raise on NaN detection. Or document that upstream (Pydantic) is expected to reject NaN - then add `model_validator` on `SensorSample` in F7.

- **P3 - Statistical `np.percentile` uses default linear interpolation** (line 59):
  - `q25, q75 = np.percentile(arr, [25, 75])` - NumPy default method `"linear"`. If training used different method (e.g., `method="median_unbiased"`), feature values drift slightly vs training distribution. Verify parity with `healthguard-ai/models/fall/fall_modeling.py`.
  - Low impact (small numeric drift, not a crash), but explicit `method=...` argument would pin it.

- **P3 - `pd.to_numeric` not used; dtype coercion implicit**:
  - `group[column].to_numpy(dtype=float)` (line 83) assumes column is already numeric. If `_normalize_sample` ever returns a non-numeric `None`/`str` value due to mutation elsewhere, `to_numpy(dtype=float)` raises `ValueError` with unclear trace.
  - Current code path is safe because `_normalize_sample` wraps all values in `float(...)`. Document contract.

- **P3 - `extract_sequence_features` returns `pd.Series` with mixed types** (lines 72-104):
  - Dict has `int` (`sequence_id`, `sequence_length`, `is_fall`), `str` (`label` - only if present), `float` (all stat features). When wrapped as `pd.Series`, dtype coerces to `object` -> `build_sequence_dataset` creates mixed-dtype DataFrame.
  - Downstream `features_df.drop(columns=["sequence_id", "label", "is_fall"], errors="ignore")` drops the object-dtype columns, leaving only float columns - OK.
  - If someone adds a new string-typed feature to `features` dict by mistake, it would leak into `features_df` with object dtype, breaking preprocessor. Not a current bug, just fragile.

- **P3 - Training/inference divergence risk**:
  - Docstring (line 1) says "aligned with `healthguard-ai/models/fall/fall_modeling.py`" - no CI check for drift. If training script adds a feature or changes a formula (e.g., changes epsilon from 1e-6 to 1e-9), inference silently diverges.
  - **Action:** Add comment noting source-of-truth + git SHA, OR a smoke test that reproduces training feature values on a known sample.

- **P3 - Unused constants (dead code):**
  - `SENSOR_ONLY_EXCLUDE_PREFIXES` (line 31) + `SENSOR_ONLY_EXCLUDE_EXACT` (line 32) are declared but grep confirms zero uses in this file or any other file in the repo. Likely leftover from training-side code copied over. Remove or document intent.

### Readability (3/3)

- Small focused functions: `_normalize_sample` 20 lines, `summarize_series` 17 lines, `extract_sequence_features` 33 lines, `featurize_payloads` 28 lines. All well below 50-line readability threshold.
- Constants grouped at module top with clear names. Column list (`SEQUENCE_SIGNAL_COLUMNS`) + stat list (`STAT_NAMES`) are sources of truth for feature enumeration - readers can count `16 * 10 = 160` stat features without scrolling.
- Typed signatures: `dict[str, float]`, `pd.DataFrame`, `tuple[pd.DataFrame, pd.DataFrame]`. PEP 604 `|` union syntax used consistently (matches M01-M05 audit findings).
- Private helper prefixed `_normalize_sample` - convention followed.
- **Minor readability**: nested `dict.get()` chain in `_normalize_sample` (lines 109-112) is deep but flat-readable. OK.
- **Minor readability**: line 109 `accel = sample.get("accel", {})` - uses empty dict as fallback, then `.get("x", 0.0)` inside. Double fallback means missing-field tolerance is high (intentional for backward-compat with sparse payloads). Document this in docstring.

### Architecture (3/3)

- All functions are pure: inputs -> outputs, no module-level state mutation, no global side effects. Testable in isolation.
- Clean pipeline: payload dict -> normalized row -> frame_df -> augmented frame_df (magnitudes + deltas) -> sequence-level rows -> aggregated DataFrame. Each stage has one responsibility.
- `featurize_payloads` is the single public entry point - `_normalize_sample` is intentionally private. API surface minimal.
- No coupling to FastAPI, Pydantic, or the model bundle. Pure featurization logic - trivially portable to training pipeline.
- `add_frame_features` mutates its local copy only. Returns new DataFrame - pandas idiomatic.
- `build_sequence_dataset` uses list comprehension over groupby then wraps in `pd.DataFrame(rows)` - O(n_sequences) linear build, no quadratic patterns.
- **P3 observation:** `FALL_LABELS` constant (line 12) is **training-only** (labels not present in inference payloads). The `if "label" in data.columns` branches (lines 46-47, 76-77) are dead in the inference path. Acceptable code-sharing: keeps training + inference feature extraction in lockstep. Document intent.

### Security (3/3)

- No I/O, no network calls, no file access. Pure compute on in-memory data.
- No use of `eval`, `exec`, `pickle.loads`, `yaml.load`, `subprocess`, `open`.
- Input shape is already validated upstream (Pydantic `SensorSample` in F7) before dict is passed here - this module is a second consumer of already-validated data.
- No PHI present: IMU + environment sensor values only. `device_id` is passed through but not logged here.
- No logging at all in this file - cannot leak sensitive values. Good for a pure-compute helper.
- No exception `except Exception: pass` anti-pattern.

### Performance (2/3)

- **P2 observation - Pandas groupby called twice per payload** (lines 41-42):
  ```python
  accel_diff = data.groupby("sequence_id")[["accel_x", "accel_y", "accel_z"]].diff().fillna(0.0)
  gyro_diff = data.groupby("sequence_id")[["gyro_x", "gyro_y", "gyro_z"]].diff().fillna(0.0)
  ```
  - Two groupby passes over same frame. Combined into single `data.groupby("sequence_id")[["accel_x", ..., "gyro_z"]].diff()` would halve groupby overhead. Micro-optimization.
  - Real cost at 50 samples/sequence, 1 sequence per request = trivial (~1ms). At 500-sequence batch, adds up.

- **P2 observation - `extract_sequence_features` converts to NumPy 16+ times per group** (lines 81-83):
  ```python
  for column in SEQUENCE_SIGNAL_COLUMNS:
      stats = summarize_series(group[column].to_numpy(dtype=float), timesteps)
  ```
  - `group[column].to_numpy(...)` called 16 times. Batch conversion `arr = group[SEQUENCE_SIGNAL_COLUMNS].to_numpy(dtype=float)` then slice `arr[:, i]` would be ~2-3x faster at 50 samples.
  - BUT current code is more readable. Keep as-is unless profiling shows bottleneck.

- **P3 - `pd.DataFrame(rows)` in `build_sequence_dataset`** (line 108):
  - Each `extract_sequence_features` returns `pd.Series` with mixed dtypes. `pd.DataFrame(rows)` from list of Series is slower than `pd.DataFrame.from_records()` with explicit dtypes for large batches.
  - At current scale (single window), imperceptible. Flag for Phase 5+ if batch size grows.

- **P3 - No early-exit on single-sequence case**:
  - For single-window predict (most common Flutter mobile path), groupby over 1 group is overhead. A fast path `if frame_df["sequence_id"].nunique() == 1` could skip groupby. Not worth complicating API.

- **Positive:** No Python-level for-loop over samples (except enumeration in `featurize_payloads` to build rows list, which is O(n) and necessary). Compute is numpy-vectorized per signal.
- **Positive:** `np.asarray` + `dtype=float` consistent - avoids hidden copies.
- **Positive:** DataFrame reindex with `fill_value=0.0` is O(n_columns), not O(n_rows * n_columns).

## Recommended actions (Phase 4)

- [ ] **P2:** Remove or use `SENSOR_ONLY_EXCLUDE_PREFIXES` + `SENSOR_ONLY_EXCLUDE_EXACT` (lines 31-32) - dead code currently.
- [ ] **P2:** Add explicit NaN handling contract: either `frame_df = frame_df.fillna(0.0)` before `add_frame_features`, or add `model_validator` on `SensorSample` (F7) rejecting NaN. Document choice.
- [ ] **P3:** Combine the two `groupby(...).diff()` calls into one (accel + gyro columns together) - micro-optim.
- [ ] **P3:** Pin `np.percentile(..., method="linear")` explicitly to match training; verify against training module.
- [ ] **P3:** Add smoke test: feed a known sample window, assert feature values match expected (training-side reference). Catches divergence.
- [ ] **P3:** Add `assert len(group) > 0` at start of `extract_sequence_features` - defense against misuse.
- [ ] **P3:** Document in docstring that `_normalize_sample` uses double-fallback (empty-dict outer, 0.0 inner) to tolerate sparse payloads - explicit contract.

## Out of scope

- **Math correctness of features** (mean/std/energy/slope/quartiles/magnitudes/deltas/peak ratios) - ML-ops review, not a code audit. Per framework "Out of scope" for code-level audit.
- **Feature parity with training module** (`healthguard-ai/models/fall/fall_modeling.py`) - requires reading training repo. Out of scope per framework.
- **Preprocessor transform compatibility** - `fall_service` responsibility, covered in F1.
- **Model accuracy / SHAP attribution correctness** - ML-ops concern.
- **Cython/Numba acceleration** - premature optimization for current scale.
- **Training-time `label` / `is_fall` columns** - dead in inference path but intentionally preserved for code-sharing with training.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) - flagged fall service pipeline; F8 drills into the featurization helper.
- Phase 3: [F1 fall_service](./F1_fall_service_audit.md) - calls `featurize_payloads` at line 142; upstream guards ensure `data` is non-empty + `len >= fall_min_sequence_samples`.
- Phase 3: [F7 fall schema](./F7_fall_schema_audit.md) - input validation layer; fall_featurize inherits Pydantic-validated input contract.
- Peer pattern: [F9 sleep_features](./F9_sleep_features_audit.md) - same "feature engineering helper module" pattern; compare structure.
- Training-side source-of-truth: `healthguard-ai/models/fall/fall_modeling.py` (referenced in docstring line 1). Not in this repo - cross-repo ML-ops coordination.
- No known bugs target this file. No open items in `PM_REVIEW/BUGS/` for fall_featurize.
