# ADR-010: Devices schema canonical = PM_REVIEW (user_id nullable, ON DELETE SET NULL)

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [database, schema, cross-repo, health_system, iot-sim, canonical]

## Context

Phase 0.5 deep-dive DEVICE module phát hiện 2 file DB schema cho bảng `devices` đang lệch nhau:

| File                                                            | `user_id` definition                                    |
| --------------------------------------------------------------- | ------------------------------------------------------- |
| `health_system/SQL SCRIPTS/03_create_tables_devices.sql`        | `INT NOT NULL REFERENCES users(id) ON DELETE CASCADE`   |
| `PM_REVIEW/SQL SCRIPTS/03_create_tables_devices.sql`            | `INT REFERENCES users(id) ON DELETE SET NULL` (nullable) |
| `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`                     | `INT REFERENCES users(id) ON DELETE SET NULL` (nullable) |
| `health_system/backend/app/models/device_model.py`              | `ForeignKey("users.id", ondelete="CASCADE")` + implicit NOT NULL |

Hệ quả:
- `AdminDeviceService.create_device()` truyền `user_id=None` (admin provisioning flow) chạy được trên PM_REVIEW canonical nhưng SẼ CRASH NOT NULL violation nếu DB được initialize từ `health_system/SQL SCRIPTS/`.
- `Iot_Simulator_clean/api_server/sim_admin_service.py` auto-provision device với `user_id=None` — cùng lỗi.
- Khi user soft-delete: PM_REVIEW SET NULL giữ device orphan (preserve vitals + fall_events), CASCADE của `health_system` xóa device và CASCADE tiếp sang `vitals` / `fall_events` / `sos_events` (mất data lịch sử).

Constraints:
- PM_REVIEW là source of truth theo steering rule `25-docs-sql.md` và `20-stack-conventions.md`.
- ORM model phải sync với DB canonical, không ngược lại.
- Đồ án 2 scope: có flow admin provisioning device trước khi user claim (xem UC040 v2 BR-040-05).

## Decision

**Chose:** PM_REVIEW canonical — `user_id INT REFERENCES users(id) ON DELETE SET NULL` (nullable).

**Why:**

1. Admin provisioning flow cần user_id nullable: `AdminDeviceService.create_device()` và IoT sim auto-provision đang pass `user_id=None`. Nếu NOT NULL, 2 code path này break.
2. Data preservation khi soft-delete user: Hệ thống y tế bắt buộc giữ lịch sử vitals / fall events. SET NULL giữ device row + telemetry; CASCADE xoá sạch, không thể audit lại.
3. PM_REVIEW đã là source-of-truth đã được chốt từ rule steering + Phase -1 spec rebuild. Không có lý do ngược đãi.

## Options considered

### Option A (chosen): Sync toàn bộ về PM_REVIEW canonical — `user_id` nullable, `SET NULL`

**Description:** Keep PM_REVIEW làm canonical, update `health_system/SQL SCRIPTS/03_create_tables_devices.sql` + `device_model.py` về match. Viết migration script cho DB đã deploy.

**Pros:**
- Match 2 production use case hiện hữu (admin provisioning + IoT sim auto-provision).
- Preserve vitals/fall_events khi user soft-delete.
- Tôn trọng PM_REVIEW source-of-truth.

**Cons:**
- Cần migration script cho DB đã tồn tại (nếu tạo từ `health_system/SQL SCRIPTS/`).
- Cần cập nhật 2 file khác nhau (SQL + ORM).

**Effort:** S (~1h — migration + ORM update + smoke test).

### Option B (rejected): Sync về `health_system/SQL SCRIPTS/` — NOT NULL + CASCADE

**Description:** Keep strict FK, update PM_REVIEW + ORM + disable admin provisioning với `user_id=None`.

**Pros:**
- FK stricter, không có orphan device.

**Cons:**
- Phải rework `AdminDeviceService.create_device()` và IoT sim `sim_admin_service.create_device()` để không nhận `user_id=None` — breaking change cho admin workflow.
- Mất data khi user xoá (CASCADE xuống vitals/fall_events).
- Đi ngược PM_REVIEW source-of-truth.

**Why rejected:** Breaking change cho 2 active code path + mất audit trail sức khoẻ — không chấp nhận cho medical app.

### Option C (rejected): Giữ drift, document "deploy từ PM_REVIEW"

**Description:** Không sync, chỉ viết doc cảnh báo devs không dùng `health_system/SQL SCRIPTS/`.

**Pros:**
- Không phải code change.

**Cons:**
- Landmine — dev nào không đọc doc, clone repo, chạy file local thì production crash.
- Không fix được ORM drift (model.py đã lệch canonical rồi).

**Why rejected:** Anti-pattern. Solo dev workflow phải tự-defending chứ không dựa doc.

---

## Consequences

### Positive

- Admin provisioning + IoT sim auto-provision chạy ổn định cross-repo.
- Soft-delete user không mất device/vitals/fall_events lịch sử — audit compliance.
- Single source-of-truth: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`.

### Negative / Trade-offs accepted

- Device orphan sau user delete không tự cleanup — cần manual cleanup job (out of scope đồ án 2).
- Em accept rằng phải viết 1 migration script + sync 2 file. Trade-off tốt vì tránh landmine production.

### Follow-up actions required

- [ ] Viết migration script `PM_REVIEW/SQL SCRIPTS/20260513_devices_user_id_nullable.sql` (ALTER TABLE devices DROP NOT NULL + DROP/RECREATE FK với SET NULL).
- [ ] Update `health_system/SQL SCRIPTS/03_create_tables_devices.sql` — đổi FK sang `ON DELETE SET NULL`, drop NOT NULL.
- [ ] Update `health_system/backend/app/models/device_model.py` — `ondelete="SET NULL"`, `nullable=True`.
- [ ] Deprecate hoặc delete file `health_system/SQL SCRIPTS/03_create_tables_devices.sql` nếu không còn use case (PM_REVIEW đã cover).
- [ ] Smoke test: admin provision device `user_id=None` -> assign sau -> user soft-delete -> device vẫn tồn tại với `user_id=NULL`.

## Reverse decision triggers

- Nếu scope đồ án 2 thay đổi và admin provisioning flow bị drop, cân nhắc revert về NOT NULL cho stricter integrity.
- Nếu orphan device growth > 10% total rows, xem xét cleanup job hoặc quay lại CASCADE.

## Related

- UC: UC040 v2 (BR-040-05 admin provisioning flow)
- ADR: —
- Bug: triggered by **HS-001** (devices schema drift canonical)
- Code: enforces in `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`, to-be-updated `health_system/backend/app/models/device_model.py`
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md`

## Notes

Phase 4 migration script thứ tự: (1) ALTER drop NOT NULL constraint, (2) ALTER TABLE drop FK, (3) ALTER TABLE add FK với ON DELETE SET NULL. Test trên clone DB trước.
