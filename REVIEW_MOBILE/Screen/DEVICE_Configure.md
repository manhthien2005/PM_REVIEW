# 📱 DEVICE — Cấu hình thiết bị

> **UC Ref**: UC041
> **Module**: DEVICE
> **Status**: ⬜ Spec only

## Purpose

Cài đặt nâng cao của đồng hồ: đổi tên, bật/tắt sync, cấu hình cảnh báo, ngắt kết nối (unpair). Link từ DEVICE_StatusDetail.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) | Bấm "Cấu hình" | → This screen |
| This screen | Lưu thành công / Back | → [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) |
| This screen | Ngắt kết nối (unpair) | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow

1. Nhận `deviceId` từ route args.
2. Hiển thị form: Tên thiết bị (editable), Sync interval, Cảnh báo pin, v.v.
3. Bấm "Lưu" → API update device config.
4. Bấm "Ngắt kết nối" → confirm dialog → API unpair → về List.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch config | Skeleton / form disabled |
| Idle | Form sẵn sàng chỉnh | Các field, "Lưu", "Ngắt kết nối" |
| Saving | Đang gọi API update | Loading trên nút "Lưu", disable form |
| Success | Lưu thành công | SnackBar xanh → Back |
| Error | API fail | SnackBar đỏ, form giữ giá trị |
| Unpairing | Đang ngắt kết nối | Loading, disable buttons |

---

## Edge Cases

- [ ] Thiết bị offline khi đang config → vẫn cho phép đổi tên (sync khi online)
- [ ] Unpair confirm → "Bạn có chắc muốn ngắt kết nối? Dữ liệu đã đồng bộ sẽ được giữ."
- [ ] Unpair fail (thiết bị đang sync?) → message "Không thể ngắt. Thử lại sau."
- [ ] Validation: tên không rỗng, sync interval trong range
- [ ] User Back không lưu → discard changes (có thể confirm nếu đã chỉnh)

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/devices/:deviceId/config`; `PATCH /api/mobile/devices/:deviceId`; `DELETE /api/mobile/devices/:deviceId` (unpair)
- **Input (update)**: `{ name?, syncInterval?, lowBatteryAlertThreshold? }`
- **Output**: `{ success: true }` hoặc device object; error: 404, 400

---

## Sync Notes

- Khi DEVICE_StatusDetail thay đổi → Back về StatusDetail cần refetch nếu đã đổi tên
- Khi unpair → navigate về List, List cần refetch (device đã bị xoá)
- Shared: Form validation, confirm dialog component

---

## Design Context

- **Target audience**: User cấu hình thiết bị của mình.
- **Usage context**: Configuration — không thường xuyên.
- **Key UX priority**: Clarity (options rõ), Trust (unpair cần confirm).
- **Specific constraints**: Nút "Ngắt kết nối" cần confirm; nút "Lưu" min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation (STUB) |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
