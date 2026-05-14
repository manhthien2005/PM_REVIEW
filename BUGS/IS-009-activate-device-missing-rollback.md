# Bug IS-009: SimAdminService.activate_device raises ValueError before rollback

**Status:** Open
**Repo(s):** Iot_Simulator_clean (api_server)
**Module:** api_server/sim_admin_service
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M04)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`SimAdminService.activate_device` (sim_admin_service.py line 180-235) checks target device `user_id IS NULL` via SELECT, then raises `ValueError(f"Device {device_id} is not assigned to a user")`. No `db.rollback()` called before raise. If caller has prior uncommitted mutations trong same session, they stay pending until session explicitly closed.

## Repro steps

1. Call `activate_device(device_id=X, db=session)` where target device has `user_id = NULL`
2. Observe: `ValueError` raised
3. Check session state: if caller previously executed non-committed statements, they remain pending

**Expected:** Session rolled back before raise, OR caller contract documented "you must rollback on exception".

**Actual:** Raise, session dirty, caller must know to handle.

**Repro rate:** 100% for orphaned device scenario.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/api_server/sim_admin_service.py` line 180-235

## Root cause

### File: `sim_admin_service.py:180-226`

```python
@staticmethod
def activate_device(device_id: int, db: Session) -> dict[str, Any] | None:
    target = db.execute(text("""
        SELECT user_id FROM devices WHERE id = :device_id
          AND deleted_at IS NULL LIMIT 1
    """), {"device_id": device_id}).mappings().first()

    if target is None:
        return None

    user_id = target["user_id"]
    if user_id is None:
        raise ValueError(f"Device {device_id} is not assigned to a user")   # NO ROLLBACK

    db.execute(text("..."))   # deactivate other user devices
    row = db.execute(text("..."))   # activate target
    ...
```

Line 219: `raise ValueError(...)` with no rollback. SELECT-only prior, so not immediately destructive. BUT if caller wraps activate in broader transaction with prior INSERTs/UPDATEs, those stay pending.

## Impact

**Isolated call (current usage):**

FastAPI request lifecycle + `get_db()` generator with `finally: db.close()` ensures cleanup. SQLAlchemy Session.close() without commit = implicit rollback. Current impact = 0 in production.

**Higher risk scenario (future):**

Caller wraps `activate_device` trong manual session_scope + adds other mutations before/after. If ValueError fires mid-way, prior mutations unclear. Defensive fix advisable.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | FastAPI middleware handles session cleanup via `get_db()` generator | Confirmed — standard pattern, session.close() triggers rollback of uncommitted |
| H2 | Bug actually harmless in current usage | Likely — but contract fragile, future refactor can break |
| H3 | Should raise HTTP exception instead of ValueError | Consider — router layer converts ValueError to 400/422, current pattern works |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 4 or defer)_

**Fix approach (planned):**

### Option A (minimal, recommended): Add rollback before raise

```python
user_id = target["user_id"]
if user_id is None:
    db.rollback()   # <-- ADD
    raise ValueError(f"Device {device_id} is not assigned to a user")
```

Pro: Surgical, 1 LoC change. Matches existing rollback pattern in same file (line 232).
Con: Redundant if caller always uses FastAPI `get_db()` pattern.

### Option B (contract clarity): Document caller responsibility via docstring

Pro: No behaviour change, cheap.
Con: Relies on caller reading docstring.

### Option C (defensive): Wrap entire method in try/except

Pro: Bulletproof regardless of caller.
Con: Catches too broad, may hide bugs.

**Em khuyen Option A** — smallest diff, matches existing pattern in same file.

**Fix scope summary:** 1 LoC. Est 5 min.

**Test added (planned):**
- `test_sim_admin_service.py::test_activate_device_rolls_back_on_no_user`
- Create device with `user_id=NULL`
- Call activate_device, catch ValueError
- Assert session state: `db.in_transaction() is False` OR no pending mutations

**Verification:**
1. Test green
2. Code diff shows `db.rollback()` line added before `raise ValueError`
3. Existing tests still pass (no behaviour change in success path)

## Related

- **Parent audit:** [M04 repositories + db audit](../AUDIT_2026/tier2/iot-simulator/M04_repositories_db_audit.md)
- **Pattern reference:** Same file line 232 `if row is None: db.rollback(); return None` — this is the correct pattern to mirror
- **Caller check needed:** Grep where `SimAdminService.activate_device` is called. Should be a router handler via FastAPI `Depends(get_db)`. Verify pattern before Phase 4.

## Notes

- Cosmetic but correct fix
- Batch with IS-008 (N+1 fix) in same Phase 4 M04 cleanup PR
- Defer P2 if Phase 4 backlog tight — current usage pattern safe via FastAPI lifecycle
