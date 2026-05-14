# UC041 - CẤU HÌNH THIẾT BỊ IOT (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** UC cũ mention "sensor calibration offsets" (heart_rate_offset, spo2_calibration, temperature_offset) nhưng phía consumer (IoT sim, notification service) KHÔNG đọc các field này. Phase 0.5 drop offset fields khỏi spec & schema, chỉ giữ 3 notification toggles + wear_side. Đồng thời drop Alt 6.a "pending sync" vì no push mechanism tồn tại. Xem **ADR-012**, **HS-003**.

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC041                                                                                                                                   |
| **Tên UC**         | Cấu hình tên + notification preferences cho thiết bị IoT                                                                                |
| **Tác nhân chính** | Bệnh nhân                                                                                                                               |
| **Mô tả**          | Người dùng đặt tên thiết bị và bật/tắt các loại cảnh báo (nhịp tim cao, SpO2 thấp, huyết áp cao), chọn tay đeo (left / right).          |
| **Trigger**        | Người dùng mở `DeviceConfigureScreen` từ detail hoặc list.                                                                              |
| **Tiền điều kiện** | - Thiết bị đã pair với user (UC040).<br>- Người dùng là owner (device.user_id == current_user.id).                                      |
| **Hậu điều kiện**  | Tên mới lưu ở `devices.device_name`. Notification prefs + wear_side lưu ở `devices.calibration_data` (JSONB).                           |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                          |
| ---- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1    | Người dùng      | Chọn thiết bị trong list hoặc detail → nhấn "Cài đặt".                                                                                                             |
| 2    | Hệ thống        | Seed form từ `device.calibration_data`: `notify_high_hr`, `notify_low_spo2`, `notify_high_bp` (default TRUE nếu key missing), `wear_side` (default "left").        |
| 3    | Người dùng      | Sửa tên, bật/tắt 3 toggle, chọn tay đeo, nhấn "Lưu".                                                                                                               |
| 4    | Client          | Nếu `_nameDirty = true` thì gọi `PATCH /mobile/devices/:id` với `{ device_name }`. Phản hồi 200 thì clear flag.                                                    |
| 5    | Client          | `PUT /mobile/devices/:id/settings` với `{ notify_high_hr, notify_low_spo2, notify_high_bp, wear_side }`.                                                            |
| 6    | Hệ thống (BE)   | `update_device_settings` verify ownership (device.user_id == current_user.id). Nếu fail, raise `PermissionError` thì trả 403.                                       |
| 7    | Hệ thống (BE)   | Build `calibration_data` JSONB (chỉ 4 field: 3 toggle + wear_side + `updated_at` timestamp). UPDATE `devices.calibration_data`.                                     |
| 8    | Hệ thống (BE)   | Ghi `audit_logs` với `action = 'device.config.updated'` (**BR-041-02**, Phase 4 implement).                                                                         |
| 9    | Hệ thống        | Response 200 `{ success: true, calibration_data: {...} }`. Client snackbar "Cập nhật cấu hình thành công", clear dirty flags.                                       |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Tên rỗng sau trim

| Bước  | Người thực hiện | Hành động                                                                                   |
| ----- | --------------- | ------------------------------------------------------------------------------------------- |
| 3.a.1 | Client          | `DeviceConfigureProvider.saveChanges()` detect `deviceName.trim().isEmpty && _nameDirty`. |
| 3.a.2 | Client          | Set `_errorMessage = 'Tên thiết bị không được để trống.'`, skip PATCH call.                 |

### 4.a - PATCH name fail

| Bước  | Người thực hiện | Hành động                                                                         |
| ----- | --------------- | --------------------------------------------------------------------------------- |
| 4.a.1 | Hệ thống (BE)   | PATCH fail (validator / 404 / network).                                            |
| 4.a.2 | Client          | `nameJustCommitted = false`, catch block set `_errorMessage`. PUT bước 5 skip.    |
| 4.a.3 | Client          | Snackbar đỏ "Lỗi: <message>". Form giữ dirty.                                      |

### 5.a - PUT settings fail sau khi PATCH name đã thành công

| Bước  | Người thực hiện | Hành động                                                                                                                                                                                                    |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 5.a.1 | Hệ thống (BE)   | PUT fail (5xx / ownership error / DB).                                                                                                                                                                      |
| 5.a.2 | Client          | `nameJustCommitted = true` branch set `_hasPartialSuccess = true`, `_errorMessage = 'Đã đổi tên thiết bị, nhưng chưa lưu được cài đặt thông báo: ...'`. Screen hiển thị warning snackbar (vàng, không đỏ). |

### 6.a - Ownership mismatch (device.user_id != current_user.id)

| Bước  | Người thực hiện | Hành động                                                                                         |
| ----- | --------------- | ------------------------------------------------------------------------------------------------- |
| 6.a.1 | Hệ thống (BE)   | SELECT device trả NULL (filter `WHERE id = :id AND user_id = :user_id`).                          |
| 6.a.2 | Hệ thống (BE)   | Raise `PermissionError("Không có quyền truy cập thiết bị này")` thì trả 403.                       |
| 6.a.3 | Client          | Snackbar đỏ. User không thể config device người khác — expected behavior per data isolation.       |

---

## Business Rules

- **BR-041-01**: Các notification toggles (`notify_high_hr`, `notify_low_spo2`, `notify_high_bp`) lưu server-only trong `calibration_data` JSONB. Notification service (Phase 4+) phải check các toggle này trước khi push alert — xem **HS-003 Follow-up**.
- **BR-041-02** (implement Phase 4): Mọi update `calibration_data` phải ghi `audit_logs` với:
  - `action = 'device.config.updated'`
  - Field: `user_id`, `device_id`, `ip_address`, `user_agent`, `details.fields_updated` (list key trong payload).
- **BR-041-03**: Field `wear_side` thuần UI preference (left / right). Server chỉ persist + trả về, KHÔNG dùng nó để offset sensor data. Đồ án 2 scope không cần correction theo tay đeo.
- **BR-041-04** (dropped từ UC cũ): Sensor calibration offsets (`heart_rate_offset`, `spo2_calibration`, `temperature_offset`) KHÔNG có consumer — không IoT sim nào đọc, không monitoring service nào áp dụng. Phase 0.5 drop khỏi spec + schema Phase 4. Xem **ADR-012**.
- **BR-041-05** (dropped từ UC cũ): "Pending sync when device offline" KHÔNG được implement — không có push mechanism từ BE xuống thiết bị thật hoặc IoT sim. Config lưu DB là kết thúc chain. Phase 5+ xem xét implement nếu có firmware channel thật.

---

## Payload schema

### Request — PUT `/mobile/devices/:id/settings`

```json
{
  "notify_high_hr": true,
  "notify_low_spo2": true,
  "notify_high_bp": true,
  "wear_side": "left"
}
```

Validator: `wear_side` pattern `^(left|right)$`. 3 toggle nullable (optional) — nếu null thì default TRUE.

### Response

```json
{
  "success": true,
  "message": "Cập nhật cấu hình thành công",
  "calibration_data": {
    "notify_high_hr": true,
    "notify_low_spo2": true,
    "notify_high_bp": true,
    "wear_side": "left",
    "updated_at": "2026-05-13T10:30:00Z"
  }
}
```

---

## Yêu cầu phi chức năng

- **Usability**: 3 toggle nhóm dưới tiêu đề "Thông báo vital". `wear_side` nhóm dưới tiêu đề "Tay đeo". Tên thiết bị riêng một ô text ở top.
- **Reliability**:
  - Partial success handling (5.a) phải clear, không misleading user rằng mọi thứ đã fail.
  - `_nameDirty` tracked riêng với `_isDirty` để tránh PATCH tên khi user không sửa.
- **Security**: Ownership check mandatory bước 6 — user khác không được cấu hình device của user này.

---

## Implementation references

- Route: `health_system/backend/app/api/routes/device.py` (`update_device_settings`)
- Service: `health_system/backend/app/services/device_service.py` (`update_device_settings`)
- Schema: `health_system/backend/app/schemas/device.py` (`DeviceSettingsRequest`, `DeviceSettingsResponse`)
- FE provider: `health_system/lib/features/device/providers/device_configure_provider.dart`
- FE screen: `health_system/lib/features/device/screens/device_configure_screen.dart`
- Related ADRs: **ADR-012** (drop calibration offsets)
- Related bugs: **HS-003** (calibration offsets never consumed)
