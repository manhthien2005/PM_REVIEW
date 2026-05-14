# Bug IS-003: _sleep_session_exists swallow DB error -> double-write sleep_sessions risk

**Status:** Open
**Repo(s):** Iot_Simulator_clean (api_server)
**Module:** api_server/services/sleep_service
**Severity:** Medium
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass B audit (M02)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`SleepService._sleep_session_exists` dung `except Exception: return False` khi DB query fail. Caller (`push_sleep_session_for_date`) dung return value de quyet dinh `was_overwritten` flag. Neu DB co transient error khi probing exist, ham return `False` thay vi raise, caller cho rang "chua co session" va INSERT tiep -> duplicate row trong `sleep_sessions`.

## Repro steps

1. Chay `push_sleep_session_for_date(device_id=X, target_date=Y, scenario_id=Z)` 2 lan lien tiep voi cung input
2. Lan 1: DB insert thanh cong, `sleep_sessions` co 1 row
3. Lan 2: Neu DB transient fail o `_sleep_session_exists` (connection reset, timeout), ham return `False` thay vi raise
4. Caller thay `was_overwritten=False` nhung van INSERT tiep -> 2 row cho cung `(user_id, device_id, sleep_date)`

**Expected:** DB error phai propagate, caller abort or retry.

**Actual:** DB error silenced, caller insert duplicate.

**Repro rate:** Phu thuoc DB transient fail freq. Manual repro: kill Postgres lien tuc giua 2 call.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/api_server/services/sleep_service.py` line 625-660 (`_sleep_session_exists`)
- DB: shared Postgres

## Root cause

### File: `sleep_service.py:625-660`

```python
def _sleep_session_exists(
    self,
    *,
    db_device_id: int,
    user_id: int,
    target_date: date,
) -> bool:
    try:
        with session_scope() as db:
            result = db.execute(
                text("""
                    SELECT EXISTS (...)
                """),
                {...},
            ).scalar()
    except Exception:
        logger.warning("DB check for existing sleep session failed ...", exc_info=True)
        return False   # <-- SILENT SWALLOW + AMBIGUOUS SENTINEL
    return bool(result)
```

**Anti-pattern:** `return False` on error conflates "truly does not exist" with "could not determine". Caller (line 920-1050 `push_sleep_session_for_date`) uses the value solely for `was_overwritten` message flag, thinking `False` is safe default.

### DB schema constraint

`PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` — em chua verify table `sleep_sessions` co UNIQUE constraint tren `(user_id, device_id, sleep_date)` hay khong. Neu CO unique, insert thu 2 se bi DB reject -> bug manifest voi HTTP 500. Neu KHONG unique, duplicate row len DB actual -> data corruption.

## Impact

**Khi DB stable:** 0 impact (exist check luon thanh cong).

**Khi DB transient fail:**

- **Co unique constraint:** `_post_sleep_payload` bi DB reject -> caller catch `Exception` -> return `{"success": False, "message": "Failed: IntegrityError..."}` -> user thay API fail nhung khong biet ly do la race condition. UX confusing nhung data intact.
- **Khong unique constraint:** Duplicate `sleep_sessions` row. Downstream:
  - `sleep_db_history` query returns nhieu row cung date -> confuse UI
  - Sleep score aggregation sai
  - PHI nhan doi

Severity Medium vi (a) transient DB error hiem trong dev, (b) impact phu thuoc constraint existence em chua verify.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | `sleep_sessions` CO unique constraint -> DB bat duplicate, impact = UX confusion only | Testing — need verify schema |
| H2 | `sleep_sessions` KHONG unique -> actual duplicate row, impact = data corruption | Testing — need verify schema |
| H3 | Caller dung `_sleep_session_exists` result cho decision khac ngoai `was_overwritten`? | Reviewed — khong, chi dung cho message string |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass B audit 2026-05-13, defer Phase 4)_

## Resolution

_(Fill in when resolved — Phase 4 target)_

**Fix approach (planned, 2 options):**

### Option A: Propagate exception

```python
def _sleep_session_exists(self, ...) -> bool:
    with session_scope() as db:
        result = db.execute(text("..."), {...}).scalar()
    return bool(result)
```

Caller (`push_sleep_session_for_date`) handle DB exception explicitly:

```python
try:
    was_overwritten = self._sleep_session_exists(...)
except SQLAlchemyError as exc:
    return {
        "success": False,
        "message": f"DB probe failed: {exc}. Push aborted to avoid duplicate.",
        ...
    }
```

**Pro:** Caller co the abort insert if probe fails. No duplicate risk.
**Con:** User sees failed push when probe fails. Mitigated by retry logic upstream.

### Option B: Three-state return

```python
def _sleep_session_exists(self, ...) -> bool | None:
    try:
        ...
        return bool(result)
    except Exception:
        logger.warning(...)
        return None   # <-- sentinel for "unknown"
```

Caller interprets `None` as "unknown, abort":

```python
exists = self._sleep_session_exists(...)
if exists is None:
    return {"success": False, "message": "Could not verify existence, aborted."}
was_overwritten = exists
```

**Pro:** Backward compatible callers that check falsy still abort.
**Con:** Ambiguous type signature (`bool | None`).

**Em khuyen Option A** — nhanh hon, clearer contract, caller responsible for error handling (good separation).

### Prerequisite: Verify unique constraint

Before fix, check `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`:

```sql
-- Search for:
UNIQUE (user_id, device_id, sleep_date)
-- OR
CREATE UNIQUE INDEX ... ON sleep_sessions (...)
```

Neu chua co -> add via migration + update Prisma schema (cross-repo).

**Fix scope summary:** ~10 LoC change + 1 migration (neu unique constraint chua co). Est 30 min.

**Test added (planned):**
- `test_sleep_service.py::test_push_sleep_aborts_when_db_probe_fails`
- Mock `session_scope` to raise `OperationalError`, assert caller returns `success=False`.

**Verification:**
1. Unit test green
2. Manual: Kill Postgres giua 2 call -> observe `{"success": False, "message": "DB probe failed..."}`
3. Query `sleep_sessions` -> no duplicate

## Related

- **Parent audit:** [M02 services audit](../AUDIT_2026/tier2/iot-simulator/M02_services_audit.md)
- **Linked pattern:** `_resolve_bound_device_user_id` (line 687) — cung swallow `Exception` -> `None`. Should migrate to same approach.
- **DB schema:** `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` — verify `sleep_sessions` unique constraint
- **Prisma schema (admin repo):** `HealthGuard/backend/prisma/schema.prisma` — mirror constraint

## Notes

- Surgical fix, low risk
- Phase 4 batch cung IS-002 (same file)
- Neu schema chua co unique constraint, add migration voi ON CONFLICT DO NOTHING behaviour fallback
- Consider audit other `except Exception: return <fallback>` sites trong cung file:
  - `_resolve_bound_device_user_id` (line 687)
  - `_phase_minutes_from_segments` (line 197) — ok (best-effort parse)
  - `_select_session_for_scenario` filter_fn (line 950) — ok (defensive)
  - `_push_sleep_to_backend` outer try (line 651) — lose stack context
  - `sleep_db_history` (line 732) — silent DB read fail, returns []
