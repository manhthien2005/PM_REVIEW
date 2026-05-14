# UC040 - KẾT NỐI THIẾT BỊ IOT (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Main Flow rewrite theo `pair-create` semantics thực tế trong code (POST `/mobile/devices/scan/pair`). Flow cũ `pair-claim` (nhập device code / quét QR để claim device đã tồn tại) chưa bao giờ được implement và không nằm trong scope đồ án 2. Xem **ADR-011**.

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC040                                                                                                                                                                                                                      |
| **Tên UC**         | Kết nối thiết bị IoT qua BLE scan & pair                                                                                                                                                                                   |
| **Tác nhân chính** | Bệnh nhân                                                                                                                                                                                                                  |
| **Mô tả**          | Bệnh nhân ghép nối (pair) một thiết bị IoT (smartwatch / fitness band) với tài khoản HealthGuard thông qua BLE scan. Endpoint backend sẽ tạo device record mới với `user_id = current_user.id` và `is_active = TRUE`.      |
| **Trigger**        | Người dùng chọn "Kết nối thiết bị mới" trong màn Device.                                                                                                                                                                   |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Thiết bị vật lý đang bật BLE và ở gần mobile device.                                                                                                                                       |
| **Hậu điều kiện**  | Device record mới được tạo trong `devices` với `user_id = current_user.id`, `is_active = TRUE`, `battery_level = 100` (default). Hệ thống bắt đầu chấp nhận telemetry data (vitals, motion) đi kèm `device_id` tương ứng.  |

---

## Luồng chính (Main Flow) — BLE Scan and Pair

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                       |
| ---- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Người dùng      | Mở màn "Thiết bị" → nhấn CTA "Kết nối thiết bị mới".                                                                                                                                                            |
| 2    | Hệ thống        | Mở màn `DeviceConnectScreen`, hiển thị chọn phương thức: (a) Quét QR (simulated — xem **BR-040-04**), (b) Nhập mã thủ công, (c) BLE scan nearby.                                                                |
| 3    | Người dùng      | Chọn phương thức. Client triggers BLE discovery (hoặc QR simulated sẽ preset MAC).                                                                                                                              |
| 4    | Hệ thống        | Hiển thị card xác nhận identity (tên thiết bị, MAC, loại). Người dùng confirm.                                                                                                                                 |
| 5    | Client          | Gọi `POST /mobile/devices/scan/pair` với `{ mac_address, device_name, device_type, model? }`.                                                                                                                   |
| 6    | Hệ thống (BE)   | Validate Pydantic (`DeviceScanPairRequest`): MAC regex `^[0-9A-F]{2}(:[0-9A-F]{2}){5}$`, device_type in {smartwatch, fitness_band, medical_device}.                                                             |
| 7    | Hệ thống (BE)   | Duplicate check cross-user (**BR-040-01** enforce Phase 4 via partial UNIQUE index). Nếu MAC đã tồn tại trên active row (bất kỳ user nào, `deleted_at IS NULL`) → 400 "Thiết bị đã tồn tại".                    |
| 8    | Hệ thống (BE)   | INSERT devices với `user_id = current_user.id`, `is_active = TRUE`, `battery_level = 100`, `registered_at = NOW()`.                                                                                             |
| 9    | Hệ thống (BE)   | Ghi `audit_logs` với `action = 'device.bound'` (**BR-040-03**, Phase 4 implement).                                                                                                                              |
| 10   | Hệ thống        | Response 200 `{ success: true, device: {...} }`. Client chuyển `DeviceConnectState.success`, pop màn về list.                                                                                                   |

---

## Luồng thay thế (Alternative Flows)

### 6.a - MAC address sai format

| Bước  | Người thực hiện | Hành động                                                                                      |
| ----- | --------------- | ---------------------------------------------------------------------------------------------- |
| 6.a.1 | Hệ thống        | Pydantic validator raise `ValueError("MAC address không đúng định dạng AA:BB:CC:DD:EE:FF")`.   |
| 6.a.2 | Hệ thống        | Trả 422 với Vietnamese error. Client ở `DeviceConnectState.error`, show lỗi cụ thể.            |

### 7.a - Thiết bị đã ghép nối (duplicate MAC)

| Bước  | Người thực hiện | Hành động                                                                                                                                             |
| ----- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 7.a.1 | Hệ thống (BE)   | `_check_duplicate_identity` cross-user (Phase 4): found active row với cùng MAC.                                                                      |
| 7.a.2 | Hệ thống (BE)   | Raise `ValueError("Thiết bị đã tồn tại (trùng serial/mac/mqtt)")` → 400.                                                                             |
| 7.a.3 | Hệ thống        | Client ở `DeviceConnectState.error`, show "Thiết bị này đã được ghép nối với tài khoản khác. Vui lòng liên hệ hỗ trợ để chuyển quyền (out of scope)". |

### 3.a - BLE scan không tìm thấy thiết bị / QR scan fail

| Bước  | Người thực hiện | Hành động                                                                                                        |
| ----- | --------------- | ---------------------------------------------------------------------------------------------------------------- |
| 3.a.1 | Client          | BLE discovery timeout (30s) hoặc user huỷ quét.                                                                  |
| 3.a.2 | Client          | Hiển thị "Không tìm thấy thiết bị. Hãy kiểm tra BLE + khoảng cách." + option retry / manual input.                |

---

## Business Rules

- **BR-040-01** (enforce Phase 4): Một device (định danh bằng `mac_address` hoặc `serial_number` hoặc `mqtt_client_id`) tại mỗi thời điểm chỉ liên kết với đúng 1 user đang active. Enforce qua partial UNIQUE index trong DB (`WHERE deleted_at IS NULL`). Application-layer check không đủ vì race condition + hiện tại filter theo `user_id` nên cross-user duplicate bypass (xem **HS-002**).
- **BR-040-02**: Các thông số notification preferences (`calibration_data.notify_high_hr / notify_low_spo2 / notify_high_bp / wear_side`) đi theo device record, không theo user. Khi chuyển quyền device (ngoài scope đồ án 2), preferences giữ nguyên.
- **BR-040-03** (implement Phase 4): Mọi thao tác pair/unpair phải ghi `audit_logs` với:
  - `action = 'device.bound'` khi pair thành công (pair_new_device, create_device)
  - `action = 'device.unbound'` khi unpair (delete_device)
  - Field: `user_id`, `device_id`, `ip_address`, `user_agent`, `details.mac_address`.
- **BR-040-04**: QR scan flow hiện đang simulated (hard-coded preset MAC) cho demo đồ án 2. Real QR decode (cần package + camera permission + physical QR sticker trên device) là Phase 5+. UC không đòi hỏi real QR để coi Main Flow pass.
- **BR-040-05**: Admin provisioning (tạo device `is_active=FALSE` chờ user claim) là flow orthogonal qua HealthGuard admin web (`PATCH /api/v1/devices/:id/assign`). UC040 không cover flow này — user Main Flow là self-service BLE pair. Xem **ADR-011**.

---

## State machine `is_active`

Field `is_active` có 3 semantic khác nhau tuỳ caller (đang overload, Phase 0.5 document, Phase 4 xem xét split — xem **HS-002 Related**):

| Caller path                                        | Set `is_active`                          | Ý nghĩa                                                     |
| -------------------------------------------------- | ---------------------------------------- | ----------------------------------------------------------- |
| `POST /mobile/devices/scan/pair`                   | `TRUE`                                   | Device được user pair & active primary                      |
| `POST /mobile/devices` (manual)                    | `TRUE`                                   | Cùng semantic                                                |
| `POST /mobile/admin/devices` (X-Internal-Secret)   | `FALSE`                                  | Device provisioning, chờ `assign` + `activate`              |
| `POST /mobile/admin/devices/:id/activate`          | `TRUE` + `FALSE` cho mọi sibling của user | "Primary device" per user (implicit flag — chỉ 1 active)    |
| `POST /mobile/admin/devices/:id/deactivate`        | `FALSE`                                  | Admin lock hoặc user chuyển primary sang device khác        |
| `PATCH /mobile/devices/:id`                        | Optional user toggle                     | User self-serve deactivate                                   |
| `DELETE /mobile/devices/:id`                       | `FALSE` + `deleted_at = NOW()`           | Unpair (soft delete)                                         |

Đồ án 2 constraint: Document trạng thái overload này trong UC, KHÔNG split field (YAGNI). Phase 4 chỉ cần thêm UNIQUE constraint + audit log.

---

## Yêu cầu phi chức năng

- **Usability**:
  - CTA "Kết nối thiết bị mới" visible ở empty state (**UC042 Alt 3.a**).
  - Progress indicator rõ ràng suốt state machine `DeviceConnectState` (intro → scanning → verifying → confirmIdentity → pairing → success/error).
- **Security**:
  - MAC address validator reject format sai ngay boundary (Pydantic `field_validator`).
  - Duplicate check Phase 4 enforce cross-user via DB UNIQUE (không tin application layer).
  - JWT required (`Depends(get_current_user)`), không cho anonymous pair.
- **Reliability**:
  - Nếu `pair_new_device` INSERT fail → `db.rollback()` + raise `ValueError` (đã implement).
  - Client retry an toàn: Pydantic reject duplicate MAC → không tạo nhiều record rác.

---

## Implementation references

- Route: `health_system/backend/app/api/routes/device.py` (`scan_and_pair_device`)
- Service: `health_system/backend/app/services/device_service.py` (`pair_new_device`)
- Schema: `health_system/backend/app/schemas/device.py` (`DeviceScanPairRequest`)
- FE provider: `health_system/lib/features/device/providers/device_connect_provider.dart` (state machine)
- FE mock: `health_system/lib/features/device/mock/device_mock_data.dart` (`MockBleDiscovery`)
- Related ADRs: **ADR-011** (pair-create decision), **ADR-010** (devices schema canonical)
- Related bugs: **HS-001** (schema drift), **HS-002** (UNIQUE MAC cross-user bypass)
