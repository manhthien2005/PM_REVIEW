# Intent Drift Review — `health_system / DEVICE` (v2)

**Status:** ✅ Confirmed Phase 0.5 v2 (2026-05-13) — deep verification rewrite, 7 drift thêm + 3 claim sửa
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE)
**Module:** DEVICE (IoT device pairing, configuration, status monitoring)
**Related UCs:** UC040 v2 Connect Device, UC041 v2 Configure Device, UC042 v2 View Device Status
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13

---

## 🎯 Mục tiêu v2

Rewrite doc v1 (2026-05-12) sau khi deep-dive phát hiện:
- 3 claim sai (1 blocking schema drift, 1 scope claim "no overlap" functional-false, 1 Q4 rationale "implicit poll" không có thực tế).
- 7 drift MISS trong v1 (1 critical: UC040 Main Flow không implementable; 3 high: `calibration_data` dead, `is_active` overload, UNIQUE MAC bypass; 3 medium: `last_sync_at` dead, soft-delete ghost, DeviceCreateRequest MAC validator inconsistent).

v2 = source-of-truth cho Phase 4 backlog DEVICE module. UC v2 đã commit, 3 ADR đã commit (ADR-010/011/012), 3 bug đã commit (HS-001/002/003).

---

## 📚 UC cũ summary (memory aid, deprecated post-v2)

### UC040 — Kết nối thiết bị IoT (v1 cũ, DEPRECATED)
- Main flow pair-claim: nhập device code / quét QR, validate tồn tại, gán user_id.
- Alt 4.a device không tồn tại / Alt 4.b chuyển quyền.
- BR-040-01 1 device to 1 user, BR-040-02 calibration theo device, BR-040-03 audit log.

### UC041 — Cấu hình thiết bị IoT (v1 cũ, DEPRECATED)
- Main flow config save + push xuống device.
- Alt 4.a config không hợp lệ, Alt 6.a device offline thì "pending sync".
- BR-041-01 server/device split config, BR-041-02 audit log.

### UC042 — Xem trạng thái thiết bị (v1 cũ, DEPRECATED)
- Main flow list + detail. Alt 3.a no device, Alt 5.a offline too long.
- BR-042-01 online/offline threshold 2 phút, BR-042-02 battery < 20 alert.

---

## 🔧 Code state — verified deep

### Routes (`device.py`) — 7 endpoints

```
tags=["mobile-devices"]  (prefix /mobile injected ở api/router.py)

GET    /mobile/devices                           List paginated (user-scoped, filter type/active/status)
GET    /mobile/devices/{id}                      Detail (ownership check)
POST   /mobile/devices                           Create manual (full identifiers optional)
PATCH  /mobile/devices/{id}                      Update name/firmware/is_active
DELETE /mobile/devices/{id}                      Soft delete (deleted_at + is_active=FALSE)
POST   /mobile/devices/scan/pair                 BLE pair (MAC mandatory, INSERT row)
PUT    /mobile/devices/{id}/settings             Update calibration_data JSONB
```

### Admin routes (`admin.py`) — 9 endpoints (prefix `/mobile/admin/`, dependency `require_internal_service`)

```
GET    /mobile/admin/devices
POST   /mobile/admin/devices                     INSERT với is_active=FALSE (vs mobile TRUE)
PATCH  /mobile/admin/devices/{id}
DELETE /mobile/admin/devices/{id}
POST   /mobile/admin/devices/{id}/assign         By email
POST   /mobile/admin/devices/{id}/activate       TRUE this + FALSE all siblings of user
POST   /mobile/admin/devices/{id}/deactivate
POST   /mobile/admin/devices/{id}/heartbeat      IoT sim uses (update battery + signal + last_seen_at=NOW)
GET    /mobile/admin/users/search
```

### DB schema `devices` — 2 bản drift (xem HS-001)

| Source                                                       | user_id constraint                                    |
| ------------------------------------------------------------ | ----------------------------------------------------- |
| `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` (canonical)      | Nullable, `REFERENCES users(id) ON DELETE SET NULL`   |
| `PM_REVIEW/SQL SCRIPTS/03_create_tables_devices.sql`         | Giống canonical                                       |
| `health_system/SQL SCRIPTS/03_create_tables_devices.sql`     | `NOT NULL REFERENCES users(id) ON DELETE CASCADE`     |
| `health_system/backend/app/models/device_model.py`           | `ForeignKey(..., ondelete="CASCADE")` + implicit NOT NULL |

Decision ADR-010: PM_REVIEW canonical, Phase 4 sync 2 bản còn lại.

### Service (`device_service.py`) — verified

- `get_user_devices()` — user-scoped, pagination, status filter (online/offline/all).
- `get_device_by_id()` — ownership filter.
- `create_device()` — duplicate check (app layer, filter by user_id, bug HS-002).
- `update_device()` — COALESCE partial update.
- `delete_device()` — soft delete.
- `pair_new_device()` — duplicate MAC check (same bug HS-002), is_active=TRUE, battery=100.
- `update_device_settings()` — ownership verify, build calibration_data JSONB (7 keys hiện tại, Phase 4 giảm xuống 4 per ADR-012).

Online threshold: hardcode 5 phút (`timedelta(minutes=5)`), 4 chỗ trong service.

### Admin service (`admin_device_service.py`)

- `list_all_devices()` — cross-user, admin view, pagination.
- `create_device()` — is_active=FALSE (provisioning flow), duplicate check cross-user ✓.
- `assign_device(device_id, user_id)` — user email lookup + SET user_id.
- `activate_device()` — implicit "primary per user" (deactivate siblings).
- `deactivate_device()`, `update_device()`, `delete_device()`.
- `update_heartbeat()` — IoT sim consume endpoint `/mobile/admin/devices/:id/heartbeat`.

### Pydantic schemas (`schemas/device.py`) — verified

| Schema                  | Fields hiện tại                                                                                                                                         | Phase 4 changes per ADR-012                                      |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `DeviceCreateRequest`   | device_name, device_type, model, firmware_version, mac_address (optional regex), serial_number, mqtt_client_id                                         | No change                                                        |
| `DeviceUpdateRequest`   | device_name, firmware_version, is_active                                                                                                                | No change                                                        |
| `DeviceScanPairRequest` | mac_address (required, exact 17), device_name, device_type, model                                                                                       | No change                                                        |
| `DeviceSettingsRequest` | 7 fields: heart_rate_offset, spo2_calibration, temperature_offset, notify_high_hr, notify_low_spo2, notify_high_bp, wear_side                           | **Drop 3 offset fields**, keep 3 toggle + wear_side (ADR-012)    |
| `DeviceItemResponse`    | Full + `is_online` computed + `calibration_data` dict                                                                                                    | No change                                                        |
| `DeviceListResponse`    | devices, total, limit, offset                                                                                                                            | No change                                                        |

### Mobile FE (`health_system/lib/features/device/`) — ACTIVE

- `device_screen.dart` — list with attention zone, filter toolbar.
- `device_connect_screen.dart` — state machine (intro, scan/manual, verify, confirm, pair, success/error).
- `device_configure_screen.dart` — name edit + 3 notify toggles + wear_side + danger zone.
- `device_status_detail_screen.dart` — hero card + insight banner + info sections.
- 4 providers active (`device_provider`, `device_connect_provider`, `device_configure_provider`, `device_status_detail_provider`).
- 1 repository (`device_repository`) consume 7 BE endpoints.

FE KHÔNG gửi 3 offset field (heart_rate_offset, spo2_calibration, temperature_offset) trong `saveChanges()` — chỉ gửi 3 toggle. Nghĩa là Phase 4 drop schema không breaking FE hiện tại.

---

## 🚨 Drift findings v2 (verified)

### A. Claim đúng từ v1 (confirm)

1. ✅ 7 endpoints tồn tại với `tags=["mobile-devices"]`, prefix `/mobile/` injected qua `api/router.py`.
2. ✅ Online threshold hardcode 5 phút.
3. ✅ BR-040-01 app-level duplicate check tồn tại (nhưng bypass-able, xem HS-002).
4. ✅ BR-040-02 calibration_data trên device row.
5. ✅ UC040 Alt 4.a trả 404 (cho endpoint GET detail).
6. ✅ UC042 Main Flow list + detail implement đầy đủ.
7. ✅ BR-042-02 battery <= 20 FE attention.
8. ✅ Soft delete pattern `deleted_at + is_active=FALSE`.

### B. Claim SAI từ v1 (đã sửa trong v2)

#### B.1 🚨 CRITICAL: "devices.user_id nullable (unassigned device in stock)" — sai context

v1 nói schema đã nullable. Thực tế drift giữa 2 bản PM_REVIEW (nullable) vs `health_system/SQL SCRIPTS/` (NOT NULL CASCADE) vs ORM model (CASCADE + NOT NULL implicit).

Hệ quả: `AdminDeviceService.create_device(user_id=None)` và IoT sim auto-provision crash NOT NULL violation nếu DB init từ health_system schema. User hard-delete thì CASCADE mất vitals/fall_events history.

Fix: ADR-010 chốt PM_REVIEW canonical, Phase 4 sync. Bug HS-001 track.

#### B.2 Q5 "Admin service scope khác, không overlap thực sự" — functional-false

v1 nói không overlap vì auth scope khác. Thực tế: cả 2 admin flow (mobile BE + HealthGuard) đều CRUD toàn bộ devices table. HealthGuard `PATCH /api/v1/devices/:id` cho phép update `calibration_data` thì vi phạm BR-040-02 (calibration theo device không theo admin). `unassign` + `lock/unlock` chỉ bên HealthGuard, `heartbeat` + `activate/deactivate` chỉ bên mobile BE.

Fix v2: Document scope overlap, flag Phase 4 cần split rõ. Không hard-fix trong Phase 0.5 (YAGNI).

#### B.3 Q4 "IoT sim poll DB trực tiếp (implicit sync)" — sai thực tế

v1 nói IoT sim đọc calibration_data implicit. Thực tế: grep `Iot_Simulator_clean/**` cho `calibration` trả 0 match. Không có poll. Calibration là dead write-only.

Fix: ADR-012 chốt drop 3 offset field (keep 3 toggle + wear_side), HS-003 track 3 sub-task (drop schema, notification consume toggle, last_sync_at dead column).

### C. Drift MISS hoàn toàn trong v1 (v2 add)

#### C.1 🚨 CRITICAL: UC040 Main Flow không implementable với code hiện tại

v1 claim "code implement functional 100%". Thực tế: UC040 cũ mô tả pair-claim (nhập code, BE verify tồn tại, update user_id), nhưng code chỉ có pair-create (INSERT row mới). Alt 4.a/4.b không thể trigger.

Fix: ADR-011 chốt UC040 v2 = pair-create only. UC040 file đã rewrite.

#### C.2 🟠 HIGH: `calibration_data` write-only

Covered ở B.3, HS-003, ADR-012.

#### C.3 🟠 HIGH: `is_active` overload 3 semantic

3 meaning trộn: (1) admin-locked, (2) primary device per user (implicit qua activate_device), (3) BLE paired.

UC041/042 cũ không document state machine nào là source-of-truth cho `is_active`.

Fix: UC040 v2 + UC042 v2 bổ sung bảng state machine, document current overload. Phase 4 KHÔNG split field (YAGNI đồ án 2), chỉ document.

#### C.4 🟠 HIGH: Thiếu UNIQUE constraint + cross-user bypass

- DB schema không có UNIQUE trên mac/serial/mqtt.
- App `_check_duplicate_identity` filter `user_id = :user_id` thì cross-user bypass BR-040-01.
- Race condition same-user (2 parallel INSERT).
- Soft-delete ghost (row#1 deleted, re-pair, row#2, 2 row cùng MAC historical).

Fix: Bug HS-002 track. Phase 4 add partial UNIQUE (WHERE deleted_at IS NULL) + remove user_id filter khỏi app check.

#### C.5 🟢 LOW (self-corrected 2026-05-13): FE `_deviceNeedsAttention` heuristic bug với device mới pair

**Self-correction note:** Claim ban đầu "`last_sync_at` dead column" là SAI. Grep verify lại trong session INGESTION (workspace-wide scope):
- `health_system/backend/app/api/routes/telemetry.py:287-291` CÓ UPDATE `devices.last_sync_at = NOW()` sau vitals ingest batch.
- `Iot_Simulator_clean/api_server/dependencies.py:1046-1050` CÓ UPDATE trong IoT sim direct-DB path (ADR-013).

`last_sync_at` KHÔNG phải dead column. Initial grep trong session DEVICE dùng includePattern quá hẹp (`**/health_system/backend/**/*.py`) nên miss match.

**Drift thực tế:** FE `_deviceNeedsAttention` heuristic có edge case bug — device vừa pair xong (chưa có vitals telemetry) sẽ có `last_sync_at = NULL`, khiến FE trigger attention zone cho device mới hoàn toàn. Không phải schema issue, là FE heuristic issue.

Fix: HS-003 sub-task 3 (severity xuống Low). Phase 4 FE update `_deviceNeedsAttention` — device mới pair (no telemetry yet) không nên trigger attention. Grace period 1h sau `registered_at` trước khi enforce sync heuristic, hoặc chỉ dựa `last_seen_at` cho attention detection (heartbeat đã populate).

#### C.6 🟡 MEDIUM: Soft-delete không rollback identifier fields

Sau soft-delete, `mac_address/serial_number/mqtt_client_id` giữ nguyên. Bundle fix với HS-002 partial UNIQUE (WHERE deleted_at IS NULL) — cho phép re-pair sau unpair mà vẫn prevent duplicate cross active rows.

#### C.7 🟡 MEDIUM: `DeviceCreateRequest.mac_address` field length inconsistent

- `DeviceCreateRequest.mac_address`: `max_length=17` (optional).
- `DeviceScanPairRequest.mac_address`: `min_length=17, max_length=17` (required).

Validation logic duplicate. Phase 4 extract shared validator. Cosmetic, không block.

---

## 🎯 Anh's decisions Phase 0.5 v2

Tất cả anh chọn theo em recommend (confirm 2026-05-13):

| ID     | Item                                           | Decision                                                                          | Phase 4 effort   |
| ------ | ---------------------------------------------- | --------------------------------------------------------------------------------- | ---------------- |
| **D1** | Devices schema canonical (HS-001, ADR-010)    | PM_REVIEW `SET NULL` nullable, sync health_system SQL + ORM                      | ~1h              |
| **D2** | UC040 pair-create only (ADR-011)               | Rewrite UC040 theo code hiện tại, drop Alt 4.a/4.b, no claim endpoint             | 0h (doc only)    |
| **D3** | Drop calibration offsets (ADR-012, HS-003 st1) | Remove heart_rate_offset/spo2_calibration/temperature_offset khỏi schema         | ~30min           |
| **D4** | `is_active` state machine document only        | UC040/042 v2 add state machine table, không split field                          | 0h (doc only)    |

**Extra Phase 4 tasks phát sinh từ v2:**

| Task                                                          | Bug/ADR    | Effort    |
| ------------------------------------------------------------- | ---------- | --------- |
| UNIQUE constraints cross-user + remove user_id filter         | HS-002     | ~1h       |
| Notification service check 3 toggle flag                      | HS-003 st2 | ~2h       |
| Handle `last_sync_at` dead column (Option A drop)             | HS-003 st3 | ~30min    |
| Audit log 4 actions (device.bound/unbound/config.updated/updated) | DEVICE.md v1 | ~1h     |
| Online threshold UC update (5 min) — cosmetic                 | v1         | 0h (done)  |
| QR mock note in UC — cosmetic                                 | v1         | 0h (done)  |
| Pending sync drop — cosmetic                                  | v1         | 0h (done)  |

**Estimated Phase 4 total DEVICE module: ~6h** (vs v1 claim ~1h — v1 off by 6x).

---

## 📊 UC delta v2

| UC cũ                    | Status v2    | v2 changes                                                                                                                                                                                                                                                                                                                                                    |
| ------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UC040 Connect Device     | **Overwrite** | Main Flow = pair-create only. Drop Alt 4.a/4.b (pair-claim). Add BR-040-05 (admin orthogonal flow). Add state machine `is_active`. BR-040-01 enforce qua DB UNIQUE (Phase 4). BR-040-04 QR simulated note. BR-040-03 audit log Phase 4.                                                                                                                         |
| UC041 Configure Device   | **Overwrite** | Main Flow pass tên + 3 toggle + wear_side (drop 3 offset). Drop Alt 6.a pending sync. Add Alt 3.a/4.a/5.a/6.a chi tiết match code (empty name, PATCH fail, partial success, ownership). BR-041-01 toggle server-only. BR-041-04 dropped offsets. BR-041-05 dropped pending sync.                                                                               |
| UC042 View Device Status | **Overwrite** | BR-042-01 threshold 5 phút (match code). BR-042-03 FE attention zone heuristic document (battery <= 20 OR active+no sync OR > 24h sync). BR-042-04 caregiver scope clarified (out of UC042). Add 3.b defensive missing table edge case. Add state rendering table.                                                                                            |

---

## 🆕 Industry standard add-ons — anh's selection v2

Tất cả DROP (giữ nguyên từ v1):

- ❌ Device firmware OTA update — Phase 5+
- ❌ Device health score (aggregate) — Phase 5+ UX
- ❌ Multi-device active switching — document implicit current behavior trong UC040 v2, không implement thêm
- ❌ Device sharing (caregiver xem status) — Phase 5+ cross-feature

---

## 📝 Decisions log consolidated

### Active decisions v2

| ID     | Item                               | Decision                                          | Output artifact                                 |
| ------ | ---------------------------------- | ------------------------------------------------- | ----------------------------------------------- |
| D-DEV-A (v1 carry) | Online threshold 5 min            | Keep 5 min, UC042 v2 BR-042-01 explicit          | UC042 v2                                        |
| D-DEV-B (v1 carry) | Audit log missing                  | Add 4 actions Phase 4                             | UC040/041 v2 BR-040-03 / BR-041-02 (Phase 4)    |
| D-DEV-C (v1 carry) | QR mock                            | Keep mock, UC note simulated                      | UC040 v2 BR-040-04                              |
| D-DEV-D (v1 carry) | Pending sync                       | DROP, no push mechanism                           | UC041 v2 BR-041-05                              |
| **D1**             | Devices schema canonical           | PM_REVIEW `SET NULL` nullable                     | **ADR-010**, **HS-001**                         |
| **D2**             | UC040 pair-create only             | Drop pair-claim flow                              | **ADR-011**, UC040 v2                           |
| **D3**             | Drop calibration offsets           | Remove 3 offset fields Phase 4                    | **ADR-012**, **HS-003**, UC041 v2               |
| **D4**             | `is_active` overload document only | Not split field Phase 4                           | UC040/042 v2 state machine table                |
| **NEW-A**          | UNIQUE MAC cross-user              | Partial UNIQUE index + remove user_id filter     | **HS-002** (Phase 4)                            |
| **NEW-B**          | Notification consume 3 toggle      | Phase 4 sub-task                                  | **HS-003 sub-task 2**                           |
| **NEW-C**          | `last_sync_at` handling            | Option A drop column (em recommend)               | **HS-003 sub-task 3** (Phase 4 anh quyết final) |

### Add-ons dropped (v1 carry)

| Add-on                         | Decision |
| ------------------------------ | -------- |
| Firmware OTA update            | ❌ Drop |
| Device health score            | ❌ Drop |
| Multi-device active switching  | ❌ Drop (document only) |
| Device sharing (caregiver)     | ❌ Drop |

---

## Cross-references

### UC v2 (committed Phase 0.5)

- `PM_REVIEW/Resources/UC/Device/UC040_Connect_Device.md` — v2 overwrite
- `PM_REVIEW/Resources/UC/Device/UC041_Configure_Device.md` — v2 overwrite
- `PM_REVIEW/Resources/UC/Device/UC042_View_Device_Status.md` — v2 overwrite

### ADR mới (committed Phase 0.5)

- `PM_REVIEW/ADR/010-devices-schema-canonical.md` — D1
- `PM_REVIEW/ADR/011-uc040-pair-create-only.md` — D2
- `PM_REVIEW/ADR/012-drop-calibration-offset-fields.md` — D3

### Bug mới (committed Phase 0.5)

- `PM_REVIEW/BUGS/HS-001-devices-schema-drift-canonical.md` — Critical
- `PM_REVIEW/BUGS/HS-002-device-unique-mac-cross-user-bypass.md` — High
- `PM_REVIEW/BUGS/HS-003-calibration-offsets-never-consumed.md` — Medium

### Code paths (Phase 4 backlog)

**health_system BE:**
- `health_system/backend/app/models/device_model.py` — ORM FK update (HS-001)
- `health_system/SQL SCRIPTS/03_create_tables_devices.sql` — sync canonical or delete (HS-001)
- `health_system/backend/app/schemas/device.py` — drop 3 offset (ADR-012)
- `health_system/backend/app/services/device_service.py` — calibration_data dict build (ADR-012) + `_check_duplicate_identity` remove user_id filter (HS-002) + audit log 4 actions (D-DEV-B)
- `health_system/backend/app/services/notification_service.py` — consume 3 toggle flag (HS-003 st2)

**DB migration scripts mới (Phase 4):**
- `PM_REVIEW/SQL SCRIPTS/20260513_devices_user_id_nullable.sql` (HS-001 / ADR-010)
- `PM_REVIEW/SQL SCRIPTS/20260513_devices_unique_identity.sql` (HS-002)
- `PM_REVIEW/SQL SCRIPTS/20260513_devices_drop_last_sync_at.sql` (HS-003 st3 Option A)
- `PM_REVIEW/SQL SCRIPTS/20260513_devices_cleanup_calibration_offsets.sql` (ADR-012 optional cleanup)

**Mobile FE:** no code change (FE đã không gửi 3 offset, đã seed 3 toggle từ calibration_data).

**Cross-repo:**
- IoT sim (`Iot_Simulator_clean/api_server/sim_admin_service.py`): no change per ADR-010 (vẫn dùng `update_heartbeat()` via internal auth).
- HealthGuard admin (`HealthGuard/backend/src/routes/device.routes.js`): no change Phase 4, cân nhắc Phase 5+ revisit scope overlap (B.2).

### DB schema canonical

- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` — section 03 devices table, `user_id` nullable `SET NULL`.
- `audit_logs` table — already exists (07_create_tables_system.sql), Phase 4 chỉ insert rows.

---

## Changelog

| Version | Date       | Note                                                                                                                      |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------- |
| v1      | 2026-05-12 | Initial 5 Q drift review                                                                                                  |
| v2      | 2026-05-13 | Deep verification rewrite: 7 drift add + 3 claim fix, 3 ADR mới, 3 bug mới, UC overwrite 3 file                            |
