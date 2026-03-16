# 📱 DEVICE — Chi tiết trạng thái thiết bị

> **UC Ref**: UC041, UC042
> **Module**: DEVICE
> **Status**: ⬜ Spec only (health_system: thông tin trên card, chưa có màn drill-down)

## Purpose

Xem chi tiết thiết bị: pin %, trạng thái kết nối, last sync, firmware. Link đến DEVICE_Configure (cài đặt nâng cao). Cảnh báo pin yếu (< 20%).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_List](./DEVICE_List.md) | Bấm vào Card thiết bị | → This screen |
| This screen | Bấm "Cấu hình" | → [DEVICE_Configure](./DEVICE_Configure.md) |
| This screen | Bấm Back | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow

1. Nhận `deviceId` từ route args.
2. Hiển thị: Tên, loại, pin %, online/offline, last sync, firmware version.
3. Pin < 20% → Cảnh báo rõ (banner/vùng màu).
4. Nút "Cấu hình" → DEVICE_Configure.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch device detail | Skeleton / CircularProgressIndicator |
| Success | Có data thiết bị | Card chi tiết: tên, type, pin, status, lastSync |
| Low Battery | Pin < 20% | Banner cảnh báo "Pin yếu - Sạc sớm" |
| Offline | Thiết bị mất kết nối | Badge "Offline", lastSync timestamp |
| Error | API fail, device not found | SnackBar + "Thử lại" / Back |

---

## Edge Cases

- [ ] Thiết bị đã bị xoá → 404 → message "Thiết bị không còn" → Back về List
- [ ] Thiết bị offline lâu → lastSync cũ, hiển thị "Cập nhật lần cuối: X phút trước"
- [ ] Pin 0% / unknown → hiển thị "Không xác định" hoặc ẩn
- [ ] Pull-to-refresh → refetch device status
- [ ] User không có quyền xem thiết bị này → 403 → Back

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/devices/:deviceId` (hoặc tương đương)
- **Input**: Route arg `deviceId` (string)
- **Output**: `{ id, name, type, status, batteryPercent, lastSyncAt, firmwareVersion, ... }`

---

## Sync Notes

- Khi DEVICE_List thay đổi → card trong List có thể hiển thị subset info; drill-down vào đây lấy full detail
- Khi DEVICE_Configure thay đổi → Back về đây có thể cần refetch (ví dụ đổi tên)
- Shared: Device status badge (Online/Offline), battery indicator

---

## Design Context

- **Target audience**: User xem trạng thái thiết bị của mình.
- **Usage context**: Routine — kiểm tra pin, kết nối.
- **Key UX priority**: Clarity (số liệu rõ), Calm (cảnh báo pin không gây hoảng).
- **Specific constraints**: Pin % font lớn; cảnh báo pin yếu màu cam/đỏ rõ ràng; nút "Cấu hình" min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Spec only (health_system: info trên card) | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |

---

## Implementation Reference (health_system)

- `DeviceScreen._buildDeviceCard()` — Thông tin hiển thị trên card trong List (tên, loại, trạng thái). Chưa có màn StatusDetail riêng khi tap card.
