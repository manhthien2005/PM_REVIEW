# Bug IS-013: ETL pipeline truy cập private method `_resolve_track` của VitalDBAdapter

**Status:** Open
**Repo(s):** Iot_Simulator_clean (etl_pipeline)
**Module:** etl_pipeline/normalize + dataset_adapters/vitaldb_adapter
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M09)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`NormalizedArtifactPipeline._default_vitaldb_cases` call `vitaldb._resolve_track(caseid, SPO2_TRACK)` + `_resolve_track(caseid, BP_SYS_TRACK)` + `_resolve_track(caseid, BP_DIA_TRACK)`. `_resolve_track` la private method cua `VitalDBAdapter` (prefix underscore). External caller truy cap private API = coupling pain.

## Repro steps

1. Grep `normalize.py` cho `vitaldb._`
2. See 3 matches tai line 203-205: `vitaldb._resolve_track(caseid, SPO2_TRACK)`, `vitaldb._resolve_track(caseid, BP_SYS_TRACK)`, `vitaldb._resolve_track(caseid, BP_DIA_TRACK)`

**Expected:** Pipeline calls public method `VitalDBAdapter.has_required_tracks(caseid)` or similar.

**Actual:** Pipeline reaches into private internals.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- Files:
  - `Iot_Simulator_clean/etl_pipeline/normalize.py` line 194-213 (`_default_vitaldb_cases`)
  - `Iot_Simulator_clean/dataset_adapters/vitaldb_adapter.py` (`_resolve_track` private method)

## Root cause

### File: `normalize.py:194-213`

```python
@staticmethod
def _default_vitaldb_cases(
    limit: int = DEFAULT_VITALDB_CASE_LIMIT,
    session_start: str = DEFAULT_VITALDB_SESSION_START,
) -> list[dict[str, str]]:
    try:
        vitaldb = VitalDBAdapter()
    except (FileNotFoundError, ValueError):
        return []

    selected_cases: list[dict[str, str]] = []
    for caseid in vitaldb.list_subjects():
        has_required_tracks = (
            vitaldb._resolve_track(caseid, SPO2_TRACK) is not None      # PRIVATE
            and vitaldb._resolve_track(caseid, BP_SYS_TRACK) is not None  # PRIVATE
            and vitaldb._resolve_track(caseid, BP_DIA_TRACK) is not None  # PRIVATE
        )
        if not has_required_tracks:
            continue
        selected_cases.append({"caseid": str(caseid), "session_start": session_start})
        if len(selected_cases) >= limit:
            break
    return selected_cases
```

**Encapsulation violation:** Pipeline is `VitalDBAdapter` consumer. Public API should expose "does this case have required tracks?" as method. Currently pipeline duplicates adapter's internal knowledge (3 track constants + `_resolve_track` signature).

## Impact

**Refactor risk:**
- If `VitalDBAdapter._resolve_track` changes signature / renames / removes, pipeline breaks silently (Python private = convention only, no enforcement)
- If `SPO2_TRACK`, `BP_SYS_TRACK`, `BP_DIA_TRACK` constants renamed in adapter, pipeline fails at import

**Code clarity:**
- Reader of pipeline sees `._resolve_track` — must jump to adapter internals to understand intent
- Pipeline knows too much about adapter internals

**Severity Low:** Works currently. Risk on refactor only.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Private method was introduced for pipeline use but never promoted to public | Likely — pipeline was initial consumer |
| H2 | Public method would be slower? | Rejected — implementation same |
| H3 | Intentional to discourage multiple callers? | Unlikely — better solve via docstring warning |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 5 hygiene)_

**Fix approach (planned):**

### Step 1: Add public method to VitalDBAdapter

```python
# dataset_adapters/vitaldb_adapter.py

REQUIRED_TRACKS_FOR_VITALS: tuple[str, ...] = (SPO2_TRACK, BP_SYS_TRACK, BP_DIA_TRACK)

class VitalDBAdapter(DatasetAdapter):
    def has_required_tracks(self, caseid: str | int) -> bool:
        """Check whether case has all tracks needed for vitals ingestion.
        
        Returns True if SpO2, systolic BP, and diastolic BP tracks are
        available for the given case ID.
        """
        return all(
            self._resolve_track(caseid, track) is not None
            for track in REQUIRED_TRACKS_FOR_VITALS
        )
```

### Step 2: Update pipeline caller

```python
# etl_pipeline/normalize.py

for caseid in vitaldb.list_subjects():
    if not vitaldb.has_required_tracks(caseid):
        continue
    selected_cases.append({"caseid": str(caseid), "session_start": session_start})
    if len(selected_cases) >= limit:
        break
```

Remove unused imports:
```python
# normalize.py line 21
# REMOVE: from dataset_adapters.vitaldb_adapter import BP_DIA_TRACK, BP_SYS_TRACK, SPO2_TRACK
```

**Fix scope summary:** +10 LoC adapter public method, -5 LoC pipeline, -1 import line. Net -3 LoC. Est 15 min.

**Test added (planned):**
- `test_vitaldb_adapter.py::test_has_required_tracks_returns_true_for_complete_case`
- `test_vitaldb_adapter.py::test_has_required_tracks_returns_false_when_spo2_missing`
- `test_normalize.py::test_default_vitaldb_cases_filters_cases_without_required_tracks`

**Verification:**
1. Unit tests green
2. Grep `vitaldb._` in pipeline -> 0 matches
3. Grep `_resolve_track` cross codebase -> reduced external access

## Related

- **Parent audit:** [M09 dataset + ETL audit](../AUDIT_2026/tier2/iot-simulator/M09_dataset_etl_audit.md)
- **Related module:** `dataset_adapters/vitaldb_adapter.py`

## Notes

- Low priority, Phase 5 hygiene
- Consider auditing other adapter private method external access: grep `adapter._` pattern across codebase
- Public method naming convention: `has_*` (boolean check), `get_*` (returns data), `can_*` (permission check)
- If multiple adapters need similar "has_required_tracks" check, consider promoting to ABC method in `DatasetAdapter`
