# Audit: M09 — dataset_adapters/ + etl_pipeline/

**Module:** `Iot_Simulator_clean/{dataset_adapters/, etl_pipeline/}`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 1 Track 5 Pass C — IoT sim data ingestion / normalization

## Scope

Dataset adapters translate external research datasets (BIDMC, PAMAP2, PPG-DaLiA, PIF v3, Sleep-EDF, UP-Fall, VitalDB, WESAD) into canonical simulator row format. ETL pipeline normalizes + builds windows + writes parquet/jsonl artifacts for runtime consumption.

| File | LoC | Role |
|---|---|---|
| `dataset_adapters/__init__.py` | 26 | Public exports |
| `dataset_adapters/base_adapter.py` | 41 | ABC `DatasetAdapter` + `SimpleDataFrame` fallback |
| `dataset_adapters/types.py` | 27 | `SleepPhase` + `SleepSessionRecord` dataclasses |
| `dataset_adapters/bidmc_adapter.py` | est 200 | BIDMC respiration ingestion |
| `dataset_adapters/pamap2_adapter.py` | est 150 | PAMAP2 activity ingestion |
| `dataset_adapters/pif_v3_adapter.py` | est 200 | PIF v3 synthetic subject ingestion |
| `dataset_adapters/ppg_dalia_adapter.py` | est 150 | PPG-DaLiA HR ingestion |
| `dataset_adapters/sleep_edf_adapter.py` | est 200 | Sleep-EDF hypnogram ingestion |
| `dataset_adapters/up_fall_adapter.py` | est 200 | UP-Fall motion ingestion |
| `dataset_adapters/vitaldb_adapter.py` | est 250 | VitalDB BP/SpO2 ingestion (largest) |
| `dataset_adapters/wesad_adapter.py` | est 150 | WESAD stress ingestion |
| `etl_pipeline/__init__.py` | 5 | Public exports |
| `etl_pipeline/normalize.py` | 452 | Orchestrator: adapter -> row -> artifact |
| `etl_pipeline/window_builder.py` | 99 | Fixed-length motion window slicer |
| `etl_pipeline/artifact_writer.py` | 42 | Parquet/JSONL writer with pandas/pyarrow optional dep |
| **Total** | **~2,200** | |

**Note:** Em read 7 files fully (base_adapter, types, normalize, window_builder, artifact_writer, 2 `__init__.py`). Remaining 8 adapter files sized by file length. Pattern uniform across them per inventory + spot-check of adapter contract via `_rows_from_frame` consumer in normalize.py.

**Excluded:** Raw dataset files (parquet/csv/mat). Test files. Adapter implementations beyond base contract (Phase 3 candidate).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | ABC contract enforced; defensive ETL guards (try/except per subject); sleep Adapter gracefully skips if dataset missing; window-builder handles edge cases. Concerns: silent skip patterns mask real errors. |
| Readability | 2/3 | base_adapter clean; normalize.py 452 LoC = approaching split threshold; nested helpers; adapter contract uniform. |
| Architecture | 3/3 | ABC + concrete per dataset; pipeline orchestrates; artifact writer pluggable (parquet OR jsonl fallback); SimpleDataFrame fallback when pandas absent. |
| Security | 3/3 | No network calls (reads local datasets); no SQL; no user input; parquet/json write to fs only. Minor: no path traversal check on output_dir (low risk — CLI arg). |
| Performance | 2/3 | In-memory row accumulation (could OOM on large datasets); `_rows_from_frame` calls `.to_dict(orient="records")` = full-copy; `_extract_events` O(N*M) linear scan per segment. |
| **Total** | **12/15** | Band: **Healthy** |

## Findings

### Correctness (2/3)

**Base adapter (strong):**
- `DatasetAdapter` ABC with 3 abstract methods (load_subject, list_subjects, validate) — clear contract
- `SimpleDataFrame` fallback when pandas unavailable — supports dev without heavy deps
- `SimpleDataFrame.to_dict(orient="records")` raises ValueError on unsupported orient — explicit failure

**ETL pipeline (mostly solid):**
- Multiple `try: except Exception: # pragma: no cover - defensive ETL guard` patterns (normalize.py line 65-67, 235-240, 300-305, 330-335) — skip failed subject, log warning, continue
- `normalize_sleep` gracefully handles `FileNotFoundError` -> returns `{"skipped": True, ...}` — no crash when dataset missing
- `SleepEdfAdapter` init checks + `adapter.list_subjects()[:max_subjects]` slice — bounded work
- `_extract_events` sorts + groups by fall_variant correctly
- `build_motion_windows` has `if len(group_rows) < target_length: continue` — drops under-sized groups safely
- `_resample_indices` handles `length <= 1` edge case

**Concerns:**

1. **Silent "skip" patterns mask bugs:**
   ```python
   for subject_id in subjects:
       try:
           record = adapter.load_subject(subject_id)
           ...
       except Exception as exc:
           logger.warning("Skip sleep subject %s: %s", subject_id, exc)
   ```
   If ALL subjects fail with same bug, loop exits with empty list, pipeline writes 0-row parquet. `summary.json` shows `session_count: 0` — but no error signal to caller. Silent data loss.
   
   **Recommendation:** Track `error_rate` ratio; if > threshold (50%), raise at end.

2. **`_rows_from_frame` duck-typing fallback:**
   ```python
   if hasattr(frame, "to_dict"):
       try:
           return list(frame.to_dict(orient="records"))
       except TypeError:
           pass
   if isinstance(frame, list):
       return frame
   return frame.to_dict()
   ```
   Final `return frame.to_dict()` (no args) — will fail if frame is NOT SimpleDataFrame/pandas. Silent TypeError -> crash upstream.

3. **`_segment_to_event` linear scan:**
   ```python
   start_index = subject_rows.index(first) if first in subject_rows else 0
   ```
   `subject_rows.index(first)` is O(N). Called per fall segment. For datasets with many falls + large subject row count = quadratic behaviour.

4. **`normalize.py` imports `from dataset_adapters import ...`** (line 11-20) — uses top-level package import. Works when cwd = repo root, fails when cwd elsewhere. No `sys.path` manipulation visible. Fragile to CLI invocation context.

5. **VitalDB `_default_vitaldb_cases`** uses private adapter method `vitaldb._resolve_track(...)` (line 203). Accessing private API = coupling pain when VitalDBAdapter refactors. Public method needed.

### Readability (2/3)

**Strengths:**
- `base_adapter.SimpleDataFrame` has `__len__`, `head`, `to_dict`, `iter_rows` — familiar pandas-like surface
- Dataclasses `SleepPhase` + `SleepSessionRecord` with `to_dict()` method — explicit serialization
- `NormalizedArtifactPipeline.run` clearly orchestrates 7 row-load steps + builds + writes — linear top-to-bottom readable
- Config dict schema implicit via `_default_config` — self-documenting

**Concerns:**
- `normalize.py` = 452 LoC. Pipeline class 300+ LoC. Approaching split threshold. Candidate split: `pipeline/pif_loader.py`, `pipeline/event_extractor.py`, `pipeline/vitaldb_loader.py`.
- `_load_motion_rows`, `_load_vitals_rows`, `_load_respiration_rows`, `_load_stress_rows`, `_load_event_rows` all similar shape but different adapter + filter. Abstraction via `_load_from_adapter(adapter, subjects, filter_fn)` possible.
- `_build_cli_parser` + `main` at bottom of file — split CLI into `cli.py` if module grows.
- Lambda assignments: `group_key = lambda row: (...)` (window_builder line 87) — PEP8 prefers `def group_key(row): return (...)`.
- `_event_sort_key` nested function inside `_extract_events` — could be private module-level helper.

### Architecture (3/3)

**Strengths:**
- ABC + concrete impls: 8 dataset adapters all implement `DatasetAdapter` — uniform contract
- `ArtifactWriter` abstracts parquet vs jsonl — caller doesn't care about backend
- `SimpleDataFrame` fallback means code runs with or without pandas (dev can skip heavy install)
- `NormalizedArtifactPipeline.run(config)` + `default_config()` — 1 entry point, injectable config
- ETL is offline/batch — decoupled from runtime. Runtime reads parquet artifacts.
- Optional dep pattern for pandas + pyarrow (artifact_writer lines 8-15)

**Minor concerns:**
- `normalize.py._default_vitaldb_cases` accesses VitalDB adapter private `_resolve_track` — violates encapsulation
- `NormalizedArtifactPipeline` has 8 adapter dependencies. High fan-in. Consider plugin registry pattern if dataset count grows beyond 10.

### Security (3/3)

**Positives:**
- **No network calls** — all adapters read local parquet/csv/mat. ETL can run air-gapped.
- **No SQL** — parquet/jsonl only.
- **No eval/exec** — pure data transformation.
- **No user input** — CLI arg `--output-dir` only, used as Path.
- Parquet write via pandas — Pandas handles serialization. JSON via stdlib `json.dumps`.

**Concerns:**
- `output_dir.mkdir(parents=True, exist_ok=True)` in ArtifactWriter — accepts arbitrary path. If attacker controls CLI arg, can overwrite existing parquet files anywhere fs-writable. Low risk (CLI = dev-only).
- `json_dumps` fallback `str(value)` (json_utils.py) — if data row contains object with `__str__` that leaks info, included in parquet. Bound by upstream adapter's output shape. Low risk.
- No integrity check on generated artifacts. Downstream runtime loads parquet without verifying shape/schema. If adapter bug produces wrong columns, runtime crashes at first query. Phase 4 consider pydantic schema validation at read-time.

### Performance (2/3)

**Strengths:**
- ETL is offline batch — latency not critical, throughput is
- `build_motion_windows` uses `groupby` + slicing — O(N) per group
- Optional dep pattern avoids forcing pyarrow install

**Concerns:**

1. **In-memory accumulation:** `NormalizedArtifactPipeline.run` loads ALL subject rows from ALL adapters into `motion_rows`, `vitals_rows`, `event_rows`, `respiration_rows`, `stress_rows` lists. For VitalDB with 5 cases * ~100k rows/case = 500k vitals rows in memory. PAMAP2 adds ~1M rows. Could OOM on low-RAM machine.

2. **`_rows_from_frame` full-copy:** `list(frame.to_dict(orient="records"))` copies entire DataFrame to list of dicts. Memory peaks at 2x DataFrame size.

3. **`_segment_to_event` O(N*M):** `subject_rows.index(first)` per segment. If 100 segments x 10k subject rows = 1M comparisons. Better: pre-compute dict `{row_id: index}` once.

4. **`build_motion_windows` stride-based sampling:** `_resample_indices(length, target_length)` recomputed per window. Could cache if target_length fixed.

5. **Parquet vs JSONL choice:** Parquet compressed + typed (fast read). JSONL fallback (~10x larger, slower read). If runtime on low-resource env defaults to JSONL, perf hit downstream.

## New findings / bugs

### IS-012 (NEW, Low) — ETL silent skip masks data loss

**Severity:** Low (dev-time only, not production)
**Status:** Proposed (Phase 5 hygiene)

**Summary:** Multiple `try: except Exception: logger.warning(...); continue` in normalize.py. If all subjects fail, pipeline produces empty artifact silently. Summary JSON shows 0 count but caller doesn't detect.

**Fix:** Track success/failure count; raise at end if `failure_rate > 0.5`. Or add validation post-ETL that artifact has expected min rows.

**Est:** 30 min.

### IS-013 (NEW, Low) — ETL uses VitalDBAdapter private method `_resolve_track`

**Severity:** Low
**Status:** Proposed (Phase 5 refactor)

**Summary:** `NormalizedArtifactPipeline._default_vitaldb_cases` accesses `vitaldb._resolve_track(caseid, ...)` — private API. Couples pipeline to VitalDB internals.

**Fix:** Add public `VitalDBAdapter.has_required_tracks(caseid) -> bool` method; pipeline calls that.

**Est:** 15 min.

## Positive findings

- **ABC + SimpleDataFrame fallback** — codebase degrades gracefully when pandas absent. Useful for CI that avoids heavy deps.
- **Optional pyarrow + pandas** (artifact_writer) — pattern reused from transport/mqtt_publisher.
- **Dataclass + `to_dict()` explicit serialization** (sleep types) — clear Pydantic-free data contract.
- **Defensive ETL `try/except Exception: # pragma: no cover - defensive ETL guard`** — comments explain intent (even if swallow pattern flagged).
- **Config dict schema via `default_config()` classmethod** — self-documenting, overridable.
- **Bounded subject limits** (`max_subjects=10` sleep, `limit=5` VitalDB) — prevents runaway ETL.

## Recommended actions (Phase 4)

### P1
- [ ] Verify no recent regression in adapter list — grep for `DatasetAdapter` implementations, ensure all 8 implement full ABC contract.

### P2
- [ ] **IS-012 fix**: Track success/failure ratio, raise on high failure rate.
- [ ] **IS-013 fix**: Expose public `has_required_tracks` in VitalDBAdapter.
- [ ] Chunked write pattern for large datasets (OOM prevention).
- [ ] Replace `_segment_to_event` linear scan with pre-computed index dict.
- [ ] Split `normalize.py` (452 LoC) if grows further.
- [ ] Add schema validation at runtime parquet-load boundary.
- [ ] Lambda -> named def for `group_key` in window_builder.

## Out of scope (defer Phase 3 deep-dive)

- **Individual adapter audits** (BIDMC, PAMAP2, PPG-DaLiA, PIF, Sleep-EDF, UP-Fall, VitalDB, WESAD) — 8 x ~200 LoC each = ~1600 LoC deep dive. Separate Phase 3 task.
- Dataset-specific signal quality validation (clinical review).
- Parquet schema versioning.
- Test coverage matrix for adapters.
- Benchmark ETL wall-clock vs runtime startup wall-clock.

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Inventory: [M09 entry](../../module_inventory/05_iot_simulator.md#m09-dataset_adapters--etl_pipeline)
- Related modules: [M06 simulator_core](./M06_simulator_core_audit.md) (consumer of normalized artifacts)
- Phase 3 deep-dive candidate: per-adapter audit (8 files)
