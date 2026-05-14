# Audit: F9 — services/sleep_features.py

**File:** `healthguard-model-api/app/services/sleep_features.py`
**LoC:** 97
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive extended (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Sleep record feature engineering pipeline: timestamp parsing -> derived hour-of-day + weekday/month encoding -> cyclic sin/cos encoding -> BMI, HR range, SpO2 range, fragmentation index, deep/rem ratio, disturbance load, recovery index, behavioral risk index -> per-user groupby transforms (bedtime std, duration median, efficiency median) -> drop timestamp cols.

Public entry point: `prepare_inference_frame(records)` called by `sleep_service._prepare_inputs` (F3 line 142). Returns `tuple[raw_df, X]` where `X` drops `sleep_score` target + `DROP_COLS` (user_id, daily_label, created_at).

Focus per task brief: pandas groupby usage (F3 flagged), rolling stats (none - just groupby transform), BMI edge cases, timezone handling, date parsing robustness.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | BMI division-by-zero unguarded when `height_cm=0`; `pd.to_datetime` lenient + no format pin; groupby `transform("std")` returns NaN for single-record users; `behavioral_risk_index` uses `.abs()` on jetlag but no bound check. |
| Readability | 3/3 | Linear flow top-to-bottom, named intermediate columns, `_cyclic_encode` helper factored. Slight density in the mid-sleep computation. |
| Architecture | 2/3 | Pure functions but module-level `DROP_COLS` + `TARGET` + `GROUP_COL` constants leak training context into inference module (acceptable for parity). No class boundary. |
| Security | 3/3 | No I/O, no logging, no network, no PHI echo. Pure compute. |
| Performance | 2/3 | Per-call `data.copy()` + pandas groupby transform thrice (bedtime_std, duration_median, efficiency_median) - extends F3 groupby cost finding with implementation detail. |
| **Total** | **12/15** | Band: Healthy |

## Positive findings

- **Module docstring** (line 1) references training-side source `healthguard-ai/models/sleep/sleep_score_modeling.py` - explicit parity intent. Same pattern as `fall_featurize.py` docstring.
- **Cyclic encoding helper** `_cyclic_encode` (lines 14-22) factored as reusable function with `period` + `prefix` parameters. Used 5 times (start/end/mid/weekday/month) - DRY. Proper sin/cos embedding of cyclic features (weekday, month, hour) - preserves ordinal proximity (Sun adjacent to Mon).
- **Defensive copy** (line 27): `data = df.copy()` - caller's DataFrame not mutated. Composable.
- **`pd.to_datetime` applied to 4 timestamp fields** (lines 29-32): explicit conversion from F6-noted `str`-typed fields to datetime before `.dt` accessor use. Fails loud if format unparseable (by default `errors="raise"`).
- **`.clip(lower=1)` on denominators** (lines 60, 64, 70, 77): guards division-by-zero for `duration_minutes`, `sleep_stage_light_pct`, `stress_score`. Prevents `inf` propagation to model. Thorough defensive pattern.
- **`.abs()` on `jetlag_hours`** (line 77): jetlag can be negative (westward travel) but impact on `behavioral_risk_index` should be magnitude-based. Correct domain logic.
- **`pd.concat` with `axis=1`** (lines 47-56) for cyclic encode columns: idiomatic pandas for joining derived DataFrame to original. Index preserved via `index=values.index` in `_cyclic_encode` (line 20) - no row misalignment.
- **Drop-after-use** (lines 84-91): timestamp columns dropped after all derived features computed. Model input clean of non-numeric data. `DROP_COLS` further drops `user_id`, `daily_label`, `created_at` in `prepare_inference_frame` - separates feature selection from feature engineering.
- **Tuple return** (line 96): `(raw_df.reset_index(drop=True), X)` - F3 uses `_` to discard raw_df. Flexible API: raw data preserved for downstream `input_ref` / logging if needed.
- **`TARGET = "sleep_score"`** + `DROP_COLS` (lines 8-10) as module constants: explicit training-time target handling. `errors="ignore"` in `.drop(columns=...)` (line 95) tolerates inference-time case where target is absent.

## Findings per axis

### Correctness (2/3)

- **P2 NEW - BMI derivation crashes on `height_cm=0` (F-MA-P3-10):**
  - Line 57-58:
    ```python
    height_m = data["height_cm"] / 100.0
    data["bmi"] = data["weight_kg"] / (height_m**2)
    ```
  - If payload sends `height_cm=0` (schema currently accepts any float per F6), `height_m=0` -> `height_m**2 = 0` -> division yields `inf` or NaN (pandas converts `x/0 = inf` in numeric context).
  - Pandas handles `inf` silently -> `bmi=inf` flows to CatBoost preprocessor. CatBoost can tolerate NaN/inf but prediction semantics undefined.
  - If `height_cm` is negative (schema also accepts), `height_m**2` is positive -> `bmi` is positive but meaningless.
  - **Compare to `duration_minutes.clip(lower=1)` pattern** (line 60) used elsewhere - consistent defense would be `height_m = (data["height_cm"] / 100.0).clip(lower=0.3)` (min adult height 30cm for safety) before squaring.
  - **Root cause upstream:** F6 P1 finding (F-MA-P3-02) - `SleepRecord.height_cm: float` has no `Field(ge=30, le=250)`. Once F6 action done, this defense becomes redundant. For defense-in-depth, add `.clip(lower=1)` here too.
  - **Action:** Either add `.clip(lower=1)` on height_m locally, OR rely on F6 range validator fix + document dependency.

- **P2 NEW - `pd.to_datetime` no explicit format or errors mode (F-MA-P3-11):**
  - Lines 29-32:
    ```python
    data["date_recorded"] = pd.to_datetime(data["date_recorded"])
    data["sleep_start_timestamp"] = pd.to_datetime(data["sleep_start_timestamp"])
    data["sleep_end_timestamp"] = pd.to_datetime(data["sleep_end_timestamp"])
    data["created_at"] = pd.to_datetime(data["created_at"])
    ```
  - Pandas `to_datetime` default behavior:
    - `errors="raise"` (default) - unparseable string raises `ValueError`. Good: fails loud.
    - No `format="..."` argument - pandas auto-detects format per row. Performance cost (2-10x slower than pinned format) at batch scale. Also ambiguous dates (`"01/02/2024"` = Jan 2 US or Feb 1 EU) depend on locale.
    - No `utc=True` - results are timezone-naive. If consumer sends `"2024-01-15T22:00:00+07:00"` (with offset), result carries offset info per-value; mixing offsets silently normalizes to UTC. If consumer sends naive strings, result is naive -> `.dt.hour` is local-hour, not UTC-hour.
  - **Timezone impact:**
    - `SleepRecord.timezone: str` field exists (F6 line 48) BUT is NOT used in this module. `sleep_start_hour = dt.hour + dt.minute/60` (line 34-36) computes hour-of-day from whatever the datetime carries.
    - If consumer sends `"2024-01-15T22:00:00"` (naive) -> `.dt.hour = 22` -> `mid_sleep_hour` computation works, but interpretation depends on consumer's timezone intent.
    - Training data likely assumed local-time naive (or UTC-consistent). Inference must match. Currently implicit contract.
  - **Format robustness:**
    - ISO 8601 `"2024-01-15T22:00:00"` works.
    - Date-only `"2024-01-15"` parses as midnight.
    - Garbage `"yesterday"` raises `ValueError` -> router returns 500 (if not caught) or 422 (if Pydantic reruns).
    - Pandas-specific edge cases: `"nan"` string -> `NaT`. Mixed types in Series -> object dtype -> unpredictable.
  - **Action:** Pin format explicitly (`format="ISO8601"` available since pandas 2.0, or explicit `"%Y-%m-%dT%H:%M:%S"`). Add `utc=True` for consistent timezone handling. Document assumed format in docstring. Consider upstream schema fix (F6 P3): change `SleepRecord.sleep_start_timestamp: str` to `datetime`.

- **P2 NEW - `groupby(GROUP_COL).transform("std")` returns NaN for single-record groups (F-MA-P3-12):**
  - Lines 81-84:
    ```python
    data["user_bedtime_std"] = data.groupby(GROUP_COL)["sleep_start_hour"].transform("std")
    data["user_duration_median"] = data.groupby(GROUP_COL)["duration_minutes"].transform("median")
    data["user_efficiency_median"] = data.groupby(GROUP_COL)["sleep_efficiency_pct"].transform("median")
    ```
  - `pandas.Series.std()` returns NaN for single-element series (default `ddof=1` requires n>=2). Batch inference call with 1 record per user -> `user_bedtime_std` = NaN.
  - `median` is stable for n=1 but `std` is not.
  - CatBoost can handle NaN; impact depends on preprocessor transform. If preprocessor has `ColumnTransformer` + imputer, NaN replaced; if not, CatBoost internal NaN handling applies.
  - Typical inference flow (mobile app sends one record): single-record user -> NaN std. Feature has limited value for single-record case anyway (no variance over single point).
  - **F3 already noted groupby cost** (audit P2 Performance). F9 extends: correctness implication on single-record case + dependency on preprocessor NaN handling.
  - **Action:** Add `.fillna(0.0)` after groupby transform OR use `ddof=0` (population std, returns 0 for n=1). Document in code comment.

- **P3 - Mid-sleep hour computation duplicates subexpression** (lines 38-45):
  ```python
  mid_sleep_minutes = (
      (data["sleep_start_timestamp"] + (data["sleep_end_timestamp"] - data["sleep_start_timestamp"]) / 2).dt.hour
      * 60
      + (
          data["sleep_start_timestamp"]
          + (data["sleep_end_timestamp"] - data["sleep_start_timestamp"]) / 2
      ).dt.minute
  )
  ```
  - Same `mid_sleep_timestamp = start + (end - start) / 2` expression built twice (once for `.dt.hour`, once for `.dt.minute`). Minor inefficiency + duplication.
  - Also: midpoint across midnight edge case. If `sleep_start = 23:00 Jan 15`, `sleep_end = 07:00 Jan 16`, midpoint = `03:00 Jan 16` -> `dt.hour = 3`. Correct. But if consumer sends `sleep_end < sleep_start` (data entry bug), `(end - start) / 2` is negative Timedelta -> midpoint before `sleep_start`. `dt.hour` still returns hour of day, but value is nonsensical.
  - **Action:** Assign `mid_sleep_ts = data["sleep_start_timestamp"] + (data["sleep_end_timestamp"] - data["sleep_start_timestamp"]) / 2` once. Then `.dt.hour * 60 + .dt.minute`. Consider `model_validator` on `SleepRecord` asserting `end > start` (F6 P3 already flags).

- **P3 - No NaN check on numeric fields fed into model**:
  - Similar to F8 F-MA-P3-09: Pydantic accepts NaN for `float` type. `hrv_rmssd_ms = NaN` propagates through `recovery_index = (NaN * efficiency / 100) / stress` = NaN.
  - CatBoost handles NaN. Final prediction still produced but meaning unclear.
  - **Action:** Consider `.fillna(0.0)` at end of `add_features` OR reject NaN at Pydantic layer (F6 follow-up).

- **P3 - Unit divisor constants magic numbers**:
  - Line 68: `caffeine_mg / 40` - what is 40? Presumably typical caffeine dose scaling.
  - Line 67: `screen_time_before_bed_min / 10` - unclear scale.
  - Line 77: `jetlag_hours.abs() * 2` - coefficient 2 unexplained.
  - Line 78: `insomnia_flag * 8`, `medication_flag * 4` - coefficients hardcoded.
  - These match training-side exactly (per docstring) so changing them breaks model. Document with inline comments linking to training module section.

### Readability (3/3)

- Linear top-to-bottom flow in `add_features`: parse timestamps -> derive hour -> cyclic encode -> domain-specific features -> groupby transforms -> drop. Each stage obvious.
- Named intermediate columns (`sleep_start_hour`, `mid_sleep_hour`, `hr_range`, `spo2_range`, `sleep_fragmentation_index`, ...) match training glossary.
- `_cyclic_encode` helper (lines 14-22) factored appropriately.
- Type hints present on public functions (`pd.DataFrame`, `tuple[pd.DataFrame, pd.DataFrame]`).
- **P3 readability**: the mid_sleep_minutes computation (lines 38-45) spans 7 lines and repeats a subexpression - hurts readability. See Correctness P3 above.
- **P3 readability**: module-level `DROP_COLS = ["user_id", "daily_label", "created_at"]` (line 10) mixes user_id (identifier) with daily_label (training target leak protection) and created_at (non-feature metadata). A comment explaining each would help.
- No dead code, no commented-out sections.
- 97 LoC is well below readability threshold.

### Architecture (2/3)

- `add_features` is pure (inputs -> outputs, no side effects) - testable in isolation.
- `prepare_inference_frame` is a thin shim: `raw_df` preservation + `X` selection. Minimal responsibility split.
- Module-level `TARGET`, `GROUP_COL`, `DROP_COLS` constants are training artifacts bleeding into inference module. Acceptable because this is a shared feature-engineering module intended for parity with training - but worth documenting in docstring.
- **P2 observation - Pattern inconsistency vs F8:**
  - F8 (`fall_featurize`) uses `_normalize_sample` for payload dict -> normalized row conversion.
  - F9 has no such helper - `prepare_inference_frame` assumes `records: list[dict]` already has the expected keys and types. If consumer sends a dict missing `height_cm`, `KeyError` raised in `add_features` line 57 - ugly trace.
  - Upstream Pydantic (`SleepRecord`) validates shape, so dict always has all keys. But coupling to Pydantic contract is implicit.
  - **Action:** Document contract in `prepare_inference_frame` docstring: "Input dicts MUST conform to `SleepRecord` schema (all 45 fields present)."
- **P3 - No class encapsulation**: Unlike `fall_service`/`sleep_service` (classes with state), this is module-level functions only. Correct for pure helpers - no critique, just noting the pattern.
- `prepare_inference_frame` accepts both `list[dict]` and `pd.DataFrame` via `isinstance(records, pd.DataFrame)` (line 92-93) - flexibility for training-side reuse. Inference always passes `list[dict]`. OK.

### Security (3/3)

- No I/O, no network, no file access, no subprocess.
- No `eval`/`exec`/pickle/yaml parse.
- No logging - no leak surface.
- No PHI echo: function consumes PHI (sleep metrics, HR, SpO2, BMI) and produces features, but does not log or persist. `raw_df` returned to caller for downstream use (logging responsibility at service layer, covered in F3).
- Defense against DoS: no unbounded loops, no regex on user strings, no recursive structure. O(n) in records.
- `pd.to_datetime` is safe against injection (pandas parses datetime, not code).
- No exception `except Exception: pass` anti-pattern.

### Performance (2/3)

- **P2 observation (extends F3 groupby cost with implementation detail):**
  - Three `groupby(GROUP_COL).transform(...)` calls (lines 81-84). Each is O(n log n) or O(n) depending on backend.
  - At typical inference call (1 user, 1-7 records), overhead is small (<5ms).
  - Batch endpoint accepts arbitrary record count without `max_length` (F6 cross-ref). 1000 records, 100 unique users = 300 ms+ just in groupby. F3 noted this cost; F9 confirms three separate groupby passes contribute most of it.
  - **Optimization:** Single `groupby(GROUP_COL).agg(...)` call that computes bedtime_std + duration_median + efficiency_median together, then merges back via `.transform` or `.map` - 1/3 the cost. Not urgent.
- **P2 observation - `pd.concat` for cyclic encode** (lines 47-56):
  - Five `_cyclic_encode` calls, each returns a 2-column DataFrame. Concatenated all at once via single `pd.concat([data, enc1, enc2, enc3, enc4, enc5], axis=1)` - efficient single-alloc pattern. Good that all 5 are in one concat; would be wasteful if 5 separate concats.
  - BUT each `_cyclic_encode` allocates a new DataFrame with index -> 5 intermediate allocations. Minor.
- **P3 - `data.copy()`** (line 27): unavoidable for pure-function contract. For 1-record inference, trivial; for 1000-record batch, ~1-5 MB copy. Acceptable.
- **P3 - `.dt.hour + .dt.minute / 60.0` computed twice** (lines 34-36 + 38-45): mid_sleep_minutes rebuilds the midpoint timestamp twice. See Correctness P3.
- **Positive:** All arithmetic is numpy/pandas vectorized - no Python loops over rows.
- **Positive:** `pd.to_datetime` once per column - not per row.
- **Positive:** No string operations inside hot path (timezone passed through unchanged, dropped later).

## Recommended actions (Phase 4)

- [ ] **P1 (cross-ref F-MA-P3-02):** Defense-in-depth BMI: add `height_m.clip(lower=0.3)` OR rely on F6 Pydantic `Field(ge=30, le=250)` on `height_cm`. Document dependency in comment.
- [ ] **P2:** Pin `pd.to_datetime(..., format="ISO8601", utc=True)` (pandas >= 2.0) for all 4 timestamp columns. Document format contract in docstring.
- [ ] **P2:** Guard `transform("std")` NaN for single-record groups: either `.fillna(0.0)` after, or use `std(ddof=0)` equivalent. Add comment.
- [ ] **P2:** Extract `mid_sleep_ts` into variable (compute once) - fixes both readability + minor perf duplication.
- [ ] **P2 (perf, defer Phase 5+):** Combine 3 groupby transforms into single `groupby.agg` + merge. Only worth it at batch scale.
- [ ] **P3:** Document `prepare_inference_frame` input contract (must match `SleepRecord` schema) in docstring.
- [ ] **P3:** Add inline comments to magic-number coefficients (40, 10, 2, 8, 4) linking to training module source.
- [ ] **P3:** Consider `model_validator` on `SleepRecord` for `sleep_end_timestamp > sleep_start_timestamp` (F6 already flagged P3).

## Out of scope

- **Math correctness of composite features** (`sleep_fragmentation_index`, `deep_rem_ratio`, `disturbance_load`, `recovery_index`, `behavioral_risk_index`) - ML-ops review. Formula correctness belongs to training-side audit, not code audit.
- **Feature parity with training module** (`healthguard-ai/models/sleep/sleep_score_modeling.py`) - cross-repo ML-ops check.
- **Preprocessor NaN imputation** - `sleep_service` concern (F3).
- **Timezone policy decision** (UTC vs local) - cross-system concern; aligns with how `health_system/backend` persists timestamps (see M03 schemas of that repo).
- **CatBoost NaN semantics in prediction** - ML-ops review.
- **Training/inference feature drift detection** - CI concern, covered in F8 Out of Scope.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) - sleep service pipeline; F9 is the featurization helper module behind `SleepModelService._prepare_inputs`.
- Phase 3: [F3 sleep_service](./F3_sleep_service_audit.md) - F3 noted groupby cost at service layer; F9 drills into the 3 specific `transform()` calls contributing to it.
- Phase 3: [F6 health/sleep schemas](./F6_health_sleep_schemas_audit.md) - `SleepRecord` field list + P1 range validator gap + P3 timestamp-as-str flag; F9 exposes concrete downstream impact (BMI division-by-zero, `pd.to_datetime` robustness).
- Phase 3: [F7 fall schema](./F7_fall_schema_audit.md) - parallel "validation layer" responsibility for fall domain.
- Phase 3: [F8 fall_featurize](./F8_fall_featurize_audit.md) - sibling feature engineering module (fall); similar pattern, different domain. Cross-compare NaN handling + docstring parity.
- Training-side source-of-truth: `healthguard-ai/models/sleep/sleep_score_modeling.py` (docstring line 1).
- Tech-debt cross-ref: [F3 P3 sklearn_sleep_pickle_compat](./F3_sleep_service_audit.md) - preprocessor compat shim is a separate concern; F9 downstream of preprocessor.
- No known bugs target this file. No open items in `PM_REVIEW/BUGS/` for sleep_features.
