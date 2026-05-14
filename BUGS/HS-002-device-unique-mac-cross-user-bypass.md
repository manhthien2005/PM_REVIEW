# Bug HS-002: Cross-user MAC duplicate bypass — BR-040-01 violation

**Status:** 🔴 Open
**Repo(s):** health_system (mobile BE)
**Module:** device
**Severity:** High
**Reporter:** ThienPDM (self) via Phase 0.5 DEVICE deep-dive
**Created:** 2026-05-13
**Resolved:** —

## Symptom

`_check_duplicate_identity()` trong `device_service.py` filter `user_id = :user_id` khi check MAC trùng. Nghĩa là:

- User A pair device MAC `AA:BB:CC:11:22:33` thì device tạo row với `user_id=A, mac=AA:BB:...`.
- User B pair cùng MAC đó thì app check `WHERE user_id=B AND mac=...` trả 0 match, pass duplicate check, INSERT thành công.

Kết quả: 1 physical MAC nhưng 2 device row, cho 2 user khác nhau, cùng active. Vi phạm **BR-040-01** "Một thiết bị tại 1 thời điểm chỉ gán cho 1 user".

Ngoài ra, DB schema không có UNIQUE constraint trên `mac_address`, `serial_number`, hay `mqtt_client_id`, nên race condition: 2 request parallel cùng user cùng MAC, cả 2 pass app check, DB accept, 2 row duplicate.

Soft-delete collision: User A unpair (soft delete, `deleted_at` set) thì pair lại cùng MAC. App check filter `deleted_at IS NULL` pass, INSERT. DB giờ có 2 row cùng MAC (1 soft-deleted, 1 active). Nếu sau này query debug, 2 row cùng MAC trong historical gây confusion.

## Repro steps

### Repro A: Cross-user duplicate MAC

1. User A đăng nhập mobile app, pair device với MAC `AA:BB:CC:11:22:33` qua endpoint `POST /mobile/devices/scan/pair` với body `{"mac_address":"AA:BB:CC:11:22:33","device_name":"Watch A","device_type":"smartwatch"}`. Response 200.
2. Logout A. User B đăng nhập. Gọi cùng endpoint với cùng MAC nhưng `device_name = "Watch B"`.
3. Response 200, device thứ 2 tạo thành công.
4. Query DB:
   ```sql
   SELECT id, user_id, mac_address, device_name FROM devices
   WHERE mac_address = 'AA:BB:CC:11:22:33' AND deleted_at IS NULL;
   ```
   Trả 2 row cho 2 user khác nhau.

**Expected:** User B gọi phải fail 400 "Thiết bị đã tồn tại (trùng MAC)".
**Actual:** 2 row cùng MAC, active, cho 2 user.

### Repro B: Race condition same-user

1. User A chạy 2 request song song cùng MAC cùng lúc.
2. Cả 2 request query `_check_duplicate_identity` cùng lúc, cả 2 thấy 0 match (chưa INSERT).
3. Cả 2 INSERT thành công, 2 row duplicate cùng user.

**Expected:** 1 request pass, 1 fail.
**Actual:** 2 row.

### Repro C: Soft-delete ghost

1. User A pair MAC, row#1 created.
2. User A unpair, row#1 soft-deleted.
3. User A pair lại cùng MAC, row#2 created (app check pass vì row#1 `deleted_at IS NOT NULL`).
4. DB có 2 row cùng MAC.

**Expected:** Có thể chấp nhận behavior này, nhưng nếu Phase 4 add UNIQUE constraint thì phải dùng partial index (`WHERE deleted_at IS NULL`) để không block re-pair sau unpair.

**Repro rate:** 100% cho Repro A và C; Repro B cần load test (race window nhỏ).

## Environment

- DB state: bất kỳ (bug không depend schema drift HS-001)
- Affected file: `health_system/backend/app/services/device_service.py` (`_check_duplicate_identity`, line 68-96)

## Logs / Stack trace

Không có error log — bug là "silent pass", 2 row duplicate được chấp nhận.

## Investigation

### Hypothesis log

| #  | Hypothesis                                                                           | Status      |
| -- | ------------------------------------------------------------------------------------ | ----------- |
| H1 | Filter `user_id = :user_id` là intentional cho mobile (user tự quản device của mình) | ✅ Confirmed, nhưng design flaw |
| H2 | Cần partial UNIQUE index cross-user + exclude soft-deleted                           | ✅ Đây là fix |
| H3 | Admin flow `AdminDeviceService._check_duplicate_identity` đã cross-user (không filter user_id) | ✅ Confirmed — logic đúng bên admin, sai bên mobile |

### Attempts

Chưa có — bug mới phát hiện Phase 0.5.

---

## Resolution

_(Fill in when resolved Phase 4)_

**Fix approach:**

### Step 1: Add partial UNIQUE constraints (DB layer)

Migration script `PM_REVIEW/SQL SCRIPTS/20260513_devices_unique_identity.sql`:
```sql
-- MAC uniqueness (exclude soft-deleted and NULL)
CREATE UNIQUE INDEX IF NOT EXISTS devices_mac_active_uniq
  ON devices(mac_address)
  WHERE deleted_at IS NULL AND mac_address IS NOT NULL;

-- Serial uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS devices_serial_active_uniq
  ON devices(serial_number)
  WHERE deleted_at IS NULL AND serial_number IS NOT NULL;

-- MQTT client uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS devices_mqtt_active_uniq
  ON devices(mqtt_client_id)
  WHERE deleted_at IS NULL AND mqtt_client_id IS NOT NULL;
```

### Step 2: Remove `user_id` filter trong `_check_duplicate_identity`

`device_service.py` — đổi điều kiện SQL:
- BEFORE: `WHERE user_id = :user_id AND deleted_at IS NULL AND (...mac/serial/mqtt match...)`
- AFTER: `WHERE deleted_at IS NULL AND (...mac/serial/mqtt match...)`

### Step 3: Handle error cross-user rõ hơn

Raise `ValueError` với message user-facing: "Thiết bị này đã được ghép nối với tài khoản khác. Vui lòng liên hệ hỗ trợ để chuyển quyền sở hữu."

**Regression test:**
- `tests/test_device_service.py::test_cross_user_duplicate_mac_blocked`
- `tests/test_device_service.py::test_soft_deleted_mac_can_be_reused`
- `tests/test_device_service.py::test_unique_index_prevents_race_condition` (concurrent INSERT)

## Related

- UC: UC040 v2 (BR-040-01 duplicate check cross-user enforce)
- JIRA: _(chưa có)_
- Linked bug: **HS-001** (schema drift — khác bug nhưng cùng affect devices table)
- ADR: —
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md` (section B.4)

## Notes

Lưu ý khi migrate DB đang có duplicate MAC: cần cleanup trước khi add UNIQUE index. Script phát hiện:
```sql
SELECT mac_address, COUNT(*) FROM devices
WHERE deleted_at IS NULL AND mac_address IS NOT NULL
GROUP BY mac_address HAVING COUNT(*) > 1;
```
