# Bug IS-012: ETL normalize.py silent skip mask data loss cross subjects

**Status:** Open
**Repo(s):** Iot_Simulator_clean (etl_pipeline)
**Module:** etl_pipeline/normalize
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M09)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`NormalizedArtifactPipeline.run` iterate qua all adapters + subjects. Moi subject failure -> `try: except Exception: logger.warning(...); continue`. Neu ALL subjects fail voi cung bug, loop exit voi empty list, pipeline writes 0-row parquet. `summary.json` shows `session_count: 0` nhung khong error raise len caller.

## Repro steps

1. Chay `python -m etl_pipeline.normalize --output-dir=./test_out`
2. Gia su adapter cau hinh dataset path sai (dataset files missing)
3. Tat ca subject in a given adapter raise `FileNotFoundError` / `KeyError`
4. Each failure caught, logged at WARNING, continue
5. Loop exits with `rows=[]`
6. `ArtifactWriter` writes empty parquet
7. `summary.json` reports `"vitals_rows": 0, "motion_rows": 0, ...`
8. Exit code 0 — pipeline considers itself successful

**Expected:** Pipeline detect `failure_rate >= threshold (50%)`, raise `RuntimeError` with summary.

**Actual:** Silent pass, artifact created but empty.

**Repro rate:** 100% if dataset path config broken.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/etl_pipeline/normalize.py` line 65-67, 235-240, 300-305, 330-335 (multiple `except` sites)

## Root cause

Pattern repeated across `_load_sleep_rows` (via `normalize_sleep`), `_load_motion_rows`, `_load_respiration_rows`, `_load_stress_rows`:

```python
for subject_id in subjects:
    try:
        record = adapter.load_subject(subject_id)
        ...
    except Exception as exc:
        logger.warning("Skip subject %s: %s", subject_id, exc)
```

No aggregation of success/failure counts. No threshold check. No aggregate assertion at end.

## Impact

**Dev workflow:** Dev runs ETL, sees "Normalize complete, 7 artifacts written" message, but artifacts empty -> runtime loads empty registry -> simulator behaves degenerate (no vitals to replay) -> dev debugs runtime instead of ETL -> wasted time.

**CI impact:** If ETL job is part of CI pipeline (em chua verify), empty artifact not caught -> deploy to env with broken data.

**Severity Low:** Dev-time only, production sim not using live ETL.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Silent skip is intentional for "partial dataset" scenarios (some subjects missing is OK) | Partially — but 100% failure != "partial" |
| H2 | Summary JSON already captures this — caller inspects counts | Technically yes; but caller = human dev, easy to miss |
| H3 | Should fail loud when zero rows produced | Yes — minimum-data assertion |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 5 hygiene)_

**Fix approach (planned):**

### Option A: Track success/failure ratio, raise on threshold

```python
class NormalizedArtifactPipeline:
    _FAILURE_THRESHOLD = 0.5
    _MIN_ROWS_THRESHOLD = 10

    def run(self, config: dict[str, Any] | None = None) -> dict[str, str]:
        config = config or self.default_config()
        failure_stats: dict[str, tuple[int, int]] = {}

        pif_rows, pif_stats = self._load_pif_rows_tracked(config)
        failure_stats["pif"] = pif_stats

        total_success = sum(s for s, t in failure_stats.values())
        total_attempted = sum(t for s, t in failure_stats.values())
        if total_attempted > 0 and (total_attempted - total_success) / total_attempted > self._FAILURE_THRESHOLD:
            raise RuntimeError(
                f"ETL failure rate exceeded threshold: "
                f"{total_attempted - total_success}/{total_attempted} failed. "
                f"Details: {failure_stats}"
            )

        if len(vitals_rows) < self._MIN_ROWS_THRESHOLD:
            raise RuntimeError(f"ETL vitals stream has only {len(vitals_rows)} rows (< {self._MIN_ROWS_THRESHOLD})")
```

### Option B: Lightweight — minimum-row assertion only

```python
if len(vitals_rows) == 0 and len(motion_rows) == 0:
    raise RuntimeError("ETL produced zero rows across all streams — check adapter config")
```

Simpler but coarser.

**Em khuyen Option A** — complete visibility + tunable threshold. Option B as minimum fallback.

**Fix scope summary:** 50-80 LoC add across normalize.py. Est 45 min.

**Test added (planned):**
- `test_normalize.py::test_raises_when_all_subjects_fail`
- `test_normalize.py::test_passes_when_majority_succeed`
- `test_normalize.py::test_threshold_configurable`
- `test_normalize.py::test_zero_rows_raises_regardless_of_failure_ratio`

**Verification:**
1. Unit tests green
2. Manual: break PIF dataset path, run ETL, expect RuntimeError
3. Manual: break 1 of 5 subjects, expect warning + pass (below threshold)

## Related

- **Parent audit:** [M09 dataset + ETL audit](../AUDIT_2026/tier2/iot-simulator/M09_dataset_etl_audit.md)
- **Related pattern:** `_sleep_session_exists` (IS-003) also swallows DB error -> silent pass. Same anti-pattern family.

## Notes

- Low priority (dev-time only)
- Threshold constants `_FAILURE_THRESHOLD`, `_MIN_ROWS_THRESHOLD` should be configurable
- Ship ETL with `--strict` CLI flag option (default ON for CI, OFF for quick dev)
