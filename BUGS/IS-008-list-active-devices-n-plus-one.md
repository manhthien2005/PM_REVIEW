# Bug IS-008: SimAdminService.list_active_devices N+1 query pattern

**Status:** Open
**Repo(s):** Iot_Simulator_clean (api_server)
**Module:** api_server/sim_admin_service
**Severity:** Medium
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M04)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`SimAdminService.list_active_devices` (sim_admin_service.py line 302-316) runs 1 query to get device ID list, then iterates to fetch full detail per ID via `_fetch_device`. Classic N+1 pattern.

## Repro steps

1. Have N active devices trong `devices` table (`is_active=TRUE AND deleted_at IS NULL`)
2. Call `SimAdminService.list_active_devices(db)`
3. Count DB queries executed

**Expected:** 1 query total (single JOIN of devices + users).

**Actual:** 1 + N queries (1 for ID list + N for detail per device).

**Repro rate:** 100% deterministic, scales linearly with device count.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/api_server/sim_admin_service.py` line 302-316
- DB: shared Postgres (connection pool size 3 + overflow 5)

## Root cause

### File: `sim_admin_service.py:302-316`

```python
@staticmethod
def list_active_devices(db: Session) -> list[dict[str, Any]]:
    """Return full device info for every active (non-deleted) device."""
    rows = db.execute(
        text(
            "SELECT id FROM devices "
            "WHERE is_active = TRUE AND deleted_at IS NULL"
        )
    ).mappings().all()
    results: list[dict[str, Any]] = []
    for row in rows:
        info = SimAdminService._fetch_device(int(row["id"]), db)   # N+1
        if info is not None:
            results.append(info)
    return results
```

`_fetch_device` delegates to `DeviceRepository.fetch_device` which runs full JOIN query per ID. For N devices, total queries = 1 + N.

## Impact

**Dev env (small scale):** negligible. 5 active devices = 6 queries, ~30ms total.

**Scale (50 active devices):** 51 queries, ~250ms if each query 5ms. Noticeable for admin UI.

**Scale + connection pool pressure:** 51 serialized queries hold pool connections. Pool size 3 = sequential. Admin UI + heartbeat thread + 2 admin tabs = pool saturation -> timeout errors.

**Production risk:** Admin panel polling `/api/sim/admin/devices/active` every N seconds. If panel open 10 minutes, 10 * 60 / 5 = 120 polls. Each poll = 51 queries. Total = 6120 queries in 10 min. Unsustainable at scale.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Inherited from pre-extraction code, copy-pasted pattern | Likely — sim_admin_service evolved iteratively, fetch_device delegation added later than list_active_devices |
| H2 | Intentional design for cache warm-up? | Rejected — no cache populated during loop |
| H3 | DeviceRepository.list_admin_devices already returns is_active filter? | Rejected — `list_admin_devices` returns ALL non-deleted, no `is_active` filter param |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 4 target)_

**Fix approach (planned):**

### Option A (recommended): Add `active_only` filter to DeviceRepository.list_admin_devices

Extend `DeviceRepository.list_admin_devices` with optional `active_only: bool = False` param. Define 2 explicit SQL constants (NO f-string SQL concat):

```python
# device_repository.py
_ADMIN_LIST_ACTIVE_SQL = """
    SELECT d.id, d.uuid, d.user_id, ... (same columns as _ADMIN_LIST_SQL)
    FROM devices d LEFT JOIN users u ON u.id = d.user_id
    WHERE d.deleted_at IS NULL
      AND d.is_active = TRUE
    ORDER BY d.registered_at DESC
    LIMIT 200
"""

@staticmethod
def list_admin_devices(db: Session, *, active_only: bool = False) -> list[AdminDeviceResponse]:
    sql = _ADMIN_LIST_ACTIVE_SQL if active_only else _ADMIN_LIST_SQL
    rows = db.execute(text(sql)).mappings().all()
    return [AdminDeviceResponse.model_validate(dict(r)) for r in rows]
```

Update caller:

```python
# sim_admin_service.py — REPLACE list_active_devices body
@staticmethod
def list_active_devices(db: Session) -> list[dict[str, Any]]:
    typed = DeviceRepository.list_admin_devices(db, active_only=True)
    return [d.model_dump() for d in typed]
```

### Option B: Inline single-query SQL in SimAdminService

Copy `_ADMIN_LIST_SQL` from DeviceRepository, modify WHERE. Duplicates long column list. Option A cleaner.

**Em khuyen Option A** — extends existing repo method, no code duplication, clear contract.

**Fix scope summary:**
- device_repository.py: +25 LoC (new SQL const + param)
- sim_admin_service.py: -10 LoC (replace loop with delegation)
- Net: +15 LoC but 1 less maintenance point (N+1 eliminated)

Est: 20 min + unit test.

**Test added (planned):**
- `test_device_repository.py::test_list_admin_devices_active_only_filter`
- Insert 5 devices (3 active, 2 inactive), assert filter returns 3
- `test_sim_admin_service.py::test_list_active_devices_single_query`
- Mock `db.execute`, assert called once (not 1+N times)

**Verification:**
1. Unit tests green
2. `EXPLAIN ANALYZE` in Postgres: query plan shows single Index Scan or Seq Scan, no nested loop over device ID list
3. Query counter: log query count per request (via SQLAlchemy event listener) shows 1 query per `list_active_devices` call regardless of device count

## Related

- **Parent audit:** [M04 repositories + db audit](../AUDIT_2026/tier2/iot-simulator/M04_repositories_db_audit.md)
- **Reference pattern:** `DeviceRepository.list_admin_devices` (line 166-169) already returns typed full rows via single query — just needs filter param
- **Consumer surface:** Em chua grep callers of `list_active_devices` — potentially used by admin UI polling or background runtime. Verify before refactor.
- **Related index work:** Phase 4 should verify `CREATE INDEX idx_devices_active_registered ON devices (is_active, registered_at DESC) WHERE deleted_at IS NULL` for optimal query plan

## Notes

- Surgical fix, 20 min
- Can batch with IS-009 (activate_device rollback) + repository migration work for single Phase 4 M04 cleanup PR
- If admin panel doesn't poll frequently, defer P2 — but 50-device threshold reached easily in demo scenarios
- Connection pool bump to `pool_size=10` (per M04 recommendation) gives headroom regardless
