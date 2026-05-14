# Bug HS-001: Devices schema drift — user_id NOT NULL/CASCADE vs nullable/SET NULL

**Status:** 🔴 Open
**Repo(s):** health_system (mobile BE), PM_REVIEW (canonical), cross-repo impact Iot_Simulator_clean
**Module:** device
**Severity:** Critical
**Reporter:** ThienPDM (self) via Phase 0.5 DEVICE deep-dive
**Created:** 2026-05-13
**Resolved:** —

## Symptom

DB schema cho bảng `devices` đang tồn tại 3 bản khác nhau về `user_id` column:

| File                                                            | user_id                                                  |
| --------------------------------------------------------------- | -------------------------------------------------------- |
| `health_system/SQL SCRIPTS/03_create_tables_devices.sql:18`     | `NOT NULL REFERENCES users(id) ON DELETE CASCADE`        |
| `PM_REVIEW/SQL SCRIPTS/03_create_tables_devices.sql:199`        | Nullable, `REFERENCES users(id) ON DELETE SET NULL`      |
| `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:197` (canonical)     | Nullable, `REFERENCES users(id) ON DELETE SET NULL`      |
| `health_system/backend/app/models/device_model.py:31`           | `ForeignKey("users.id", ondelete="CASCADE")` + implicit NOT NULL (SQLAlchemy `Mapped[int]`) |

Nếu dev clone health_system repo và chạy `SQL SCRIPTS/03_create_tables_devices.sql` để init DB thì admin provisioning + IoT sim auto-provision sẽ crash NOT NULL violation khi pass `user_id=None`.

Nếu dev deploy từ `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` thì chạy OK, nhưng ORM model vẫn lệch, gây race condition / runtime error khi ORM attempt assign `None`.

## Repro steps

### Repro A: Crash trên `health_system` schema

1. Clone DB từ `health_system/SQL SCRIPTS/03_create_tables_devices.sql`.
2. Chạy mobile BE, gọi internal endpoint:
   ```
   POST /mobile/admin/devices
   Body: { "device_name": "Test", "device_type": "smartwatch" }
   Header: X-Internal-Secret: <secret>
   ```
   (không truyền `user_email`, nên `user_id = None`)
3. BE thực thi `INSERT INTO devices (user_id, ...) VALUES (NULL, ...)`.

**Expected:** Device được tạo với `user_id = NULL` (waiting for admin assign).
**Actual:** PostgreSQL raise `null value in column "user_id" violates not-null constraint`. Request fail 500.

### Repro B: Crash IoT sim auto-provision

1. Clone DB từ `health_system/SQL SCRIPTS/`.
2. Run IoT sim (`Iot_Simulator_clean/api_server`), auto-provision device cho scenario:
   ```python
   SimAdminService.create_device(db, device_name="IoT-001", device_type="smartwatch", user_id=None)
   ```
3. Cùng lỗi NOT NULL violation.

### Repro C: Data loss khi user hard-delete (schema `health_system`)

1. User X có device pair thì devices row với `user_id = X.id`.
2. Device có vitals telemetry (FK `vitals.device_id`).
3. Admin hard-delete user X (`DELETE FROM users WHERE id = X.id`): CASCADE xuống devices, devices row xoá, CASCADE tiếp xuống `vitals` (`ON DELETE CASCADE`), mất toàn bộ telemetry history.

Trên PM_REVIEW canonical: device set `user_id=NULL` (orphan preserved), vitals giữ nguyên.

**Repro rate:** 100% theo schema bị chọn.

## Environment

- DB state: khác nhau tùy deploy source
- Affected repos:
  - `health_system/backend/app/services/admin_device_service.py:325` (pass `user_id=None`)
  - `Iot_Simulator_clean/api_server/sim_admin_service.py` (pass `user_id=None`)
  - `health_system/backend/app/models/device_model.py:31` (ORM overload)

## Logs / Stack trace

Stack trace expected (Repro A):
```
psycopg2.errors.NotNullViolation: null value in column "user_id" of relation "devices" violates not-null constraint
DETAIL:  Failing row contains (..., null, Test, smartwatch, ...)
```

## Investigation

### Hypothesis log

| #  | Hypothesis                                                                               | Status      |
| -- | ---------------------------------------------------------------------------------------- | ----------- |
| H1 | PM_REVIEW là canonical source-of-truth theo steering rule, health_system SQL đã stale   | ✅ Confirmed |
| H2 | ORM model sync với health_system/SQL SCRIPTS/ (cùng CASCADE + NOT NULL)                  | ✅ Confirmed |
| H3 | 2 code path (AdminDeviceService, SimAdminService) đang active pass user_id=None          | ✅ Confirmed |

### Attempts

Chưa có — bug mới phát hiện Phase 0.5, fix deferred sang Phase 4.

---

## Resolution

_(Fill in when resolved Phase 4)_

**Fix approach:** Theo ADR-010 — PM_REVIEW canonical, update health_system files + ORM về match.

**Regression test (phải có Phase 4):**
- `tests/test_device_schema.py::test_admin_create_device_with_null_user_id_succeeds`
- `tests/test_device_schema.py::test_user_soft_delete_preserves_device_orphan`

## Related

- UC: UC040 v2 (BR-040-05 admin provisioning flow cần user_id nullable)
- JIRA: _(chưa có)_
- Linked bug: **HS-002** (độc lập nhưng cùng affect devices table schema)
- ADR: **ADR-010** (devices schema canonical decision)
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md` (section A2.1)

## Notes

Phase 4 sequence cần cẩn thận:
1. Viết migration script trên clone DB, test trên dataset thật.
2. Update `health_system/SQL SCRIPTS/03_create_tables_devices.sql` (hoặc delete file để PM_REVIEW là nguồn duy nhất).
3. Update ORM `device_model.py` LAST vì depend DB state.
4. Smoke test: `AdminDeviceService.create_device(user_id=None)` pass, admin subsequent assign pass.
