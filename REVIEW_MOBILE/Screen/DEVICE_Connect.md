# 📱 DEVICE — Kết nối thiết bị mới (Connect)

> **UC Ref**: UC040
> **Module**: DEVICE
> **Status**: ⬜ Spec only (health_system dùng Dialog thay vì màn riêng)

## Purpose

Ghép cặp đồng hồ lần đầu với **profile của chính người dùng**. **Spec**: BLE scan → Chọn thiết bị → Pair → Success/Timeout. **health_system**: Dialog "Đăng ký thiết bị" với form thủ công (tên, loại, model, MAC, serial, MQTT). MAC address liên kết theo `target_profile_id` (self).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_List](./DEVICE_List.md) | Bấm FAB "Thêm thiết bị" | → This screen |
| [HOME_Dashboard](./HOME_Dashboard.md) | No_Device state → CTA "Kết nối thiết bị" | → This screen |
| This screen | Pair thành công | → [DEVICE_List](./DEVICE_List.md) |
| This screen | Timeout / Cancel | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow (Spec — BLE)

1. Bật Bluetooth, đeo đồng hồ.
2. Bấm "Tìm kiếm" → BLE scan.
3. Chọn thiết bị từ list → Pair.
4. Success → về List. Timeout 30s → thông báo "Thử lại?".

---

## User Flow (health_system — Dialog/Form)

1. Mở Dialog form: name, type, model, firmware, MAC, serial, MQTT Client ID.
2. Nhập thông tin → API addDevice.
3. Success → đóng Dialog, refresh List.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Scanning | BLE đang quét | Loading + "Đang tìm thiết bị..." + list thiết bị tìm thấy |
| Idle (Form) | Form thủ công | Các field nhập liệu, "Đăng ký" |
| Pairing | Đang ghép cặp | Progress + "Đang kết nối..." |
| Success | Kết nối thành công | Checkmark → Navigate List |
| Timeout | Không tìm thấy / Pair fail | "Không tìm thấy. Thử lại?" + nút Retry |
| Error | Bluetooth off, API fail | Message + Retry / "Bật Bluetooth" |

---

## Edge Cases

- [ ] Bluetooth tắt → prompt "Bật Bluetooth để tìm thiết bị"
- [ ] Không tìm thấy thiết bị sau 30s → Timeout state, cho phép Retry
- [ ] Thiết bị đã được pair với user khác → message "Thiết bị đã được đăng ký"
- [ ] MAC trùng (form mode) → API 409 → message "Thiết bị này đã tồn tại"
- [ ] User cancel giữa scan → về List không thêm gì
- [ ] App background khi đang scan → pause/resume scan (tuỳ implementation)

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/devices` — đăng ký thiết bị mới, gắn với `target_profile_id` = self
- **Input (BLE)**: `{ macAddress, name?, type }` — từ BLE scan
- **Input (Form)**: `{ name, type, model, firmware?, macAddress, serialNumber?, mqttClientId? }`
- **Output**: `{ device: { id, ... } }` → navigate List; error: 409 (duplicate), 400 (validation)

---

## Sync Notes

- Khi DEVICE_List thay đổi → sau khi Connect success, pop về List với refetch hoặc insert
- Binding theo UC040: MAC liên kết với `target_profile_id` đang select (luôn self ở màn này)
- Shared: BLE scan logic (nếu dùng package flutter_blue, permission handling)

---

## Design Context

- **Target audience**: User tự kết nối đồng hồ của mình.
- **Usage context**: Setup — one-time hoặc khi thêm thiết bị mới.
- **Key UX priority**: Clarity (hướng dẫn rõ), Speed (scan nhanh).
- **Specific constraints**: Nút "Thử lại" min 48dp; Bluetooth permission cần request trước scan.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Spec only (health_system: Dialog) | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |

---

## Implementation Reference (health_system)

- **Chưa có màn riêng**. `DeviceScreen._showAddDeviceDialog()` — Dialog form: name, type, model, firmware, MAC, serial, MQTT Client ID. API `addDevice` đăng ký thiết bị thủ công.
