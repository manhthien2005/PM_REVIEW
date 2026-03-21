# 📱 DEVICE — Chi tiết trạng thái thiết bị

> **UC Ref**: UC041, UC042
> **Module**: DEVICE
> **Status**: ✅ Built (health_system, cần polish theo spec)

## Purpose

Hiển thị chi tiết tình trạng của một thiết bị self đã kết nối: pin, online/offline, tín hiệu, lần đồng bộ gần nhất, firmware, serial và các cảnh báo cần xử lý. Đây là màn hình giúp user trả lời thật nhanh câu hỏi: **"Đồng hồ của tôi đang hoạt động ổn không?"**

> **Quan trọng**: theo kiến trúc Hybrid hiện tại, đây vẫn là màn hình **self-only**. Người thân cần thông tin thiết bị của bệnh nhân sẽ nhận phiên bản **read-only summary** ở `HOME_FamilyDashboard` hoặc card monitoring, không đi sâu vào màn quản trị này.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_List](./DEVICE_List.md) | Bấm vào card thiết bị | → This screen |
| This screen | Bấm "Cấu hình thiết bị" | → [DEVICE_Configure](./DEVICE_Configure.md) |
| This screen | Pull-to-refresh / Retry | → This screen |
| This screen | Back | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow

1. Nhận `deviceId` qua route args.
2. Fetch full device detail.
3. Hero section hiển thị:
   - tên thiết bị,
   - loại,
   - trạng thái kết nối,
   - pin %,
   - lần cập nhật gần nhất.
4. Nếu pin yếu hoặc offline lâu → hiện banner cảnh báo dễ hiểu.
5. User xem tiếp các mục:
   - Thông tin chung,
   - Tình trạng kết nối,
   - Thông tin kỹ thuật,
   - Trạng thái đồng bộ/pending sync.
6. User bấm **"Cấu hình thiết bị"** để sang `DEVICE_Configure`.
7. Nếu gặp lỗi / not found → quay lại danh sách hoặc retry.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải lần đầu | Skeleton hero + 2 section giả |
| Success | Có dữ liệu hợp lệ | Hero summary + banner trạng thái + section detail |
| LowBattery | Pin < 20% | Banner vàng/cam "Pin yếu - nên sạc sớm" |
| OfflineShort | Mới mất kết nối | Badge Offline + last seen rõ |
| OfflineLong | Mất kết nối quá lâu | Banner cảnh báo mạnh hơn + gợi ý kiểm tra sạc/kết nối |
| PendingSync | Có cấu hình chờ đẩy xuống thiết bị | Banner info "Thiết bị sẽ nhận cấu hình khi online" |
| NotFound | Thiết bị đã bị xoá / unpair | Empty state + nút quay lại danh sách |
| Error | Lỗi mạng / 403 / lỗi server | Error state + Retry / Back |

---

## Edge Cases

- [x] Thiết bị đã bị xoá → `404` → message rõ "Thiết bị không còn tồn tại".
- [x] Thiết bị offline quá lâu → hiển thị theo ngưỡng đời thường: "Mất kết nối hơn 2 giờ" thay vì chỉ timestamp.
- [x] `batteryPercent = null` hoặc `0` không đáng tin → hiển thị "Không xác định", tránh báo sai là hết pin.
- [x] `signalStrength = null` → hiển thị "Không xác định", không làm layout vỡ.
- [x] `lastSyncAt` cũ nhưng `isOnline = true` → hiển thị cảnh báo đồng bộ chậm.
- [x] Pull-to-refresh → luôn có thể tự làm mới.
- [x] `403` hoặc mở sai context linked → chặn và quay về `DEVICE_List`.
- [x] Người lớn tuổi xem màn hình ở text scale 150% → section phải wrap tốt, không ép 1 hàng.

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/devices/:deviceId`
- **Input**: route arg `deviceId`
- **Output**:
  - `{ id, name, type, isOnline, batteryPercent, signalStrength, lastSeenAt, lastSyncAt, firmwareVersion, serialNumber, macAddress, mqttClientId, pendingSync, ... }`
- **Derived UI rules**:
  - `batteryPercent < 20` → `LowBattery`
  - `isOnline = false` + `lastSeenAt` quá ngưỡng → `OfflineLong`
  - `pendingSync = true` → hiện `PendingSync`

---

## Sync Notes

- `DEVICE_List` chỉ hiển thị subset; màn này lấy full detail.
- Sau khi từ `DEVICE_Configure` quay về:
  - nếu update nhẹ → refetch detail,
  - nếu unpair/delete → pop về `DEVICE_List` và refresh list.
- Shared widgets nên có: `DeviceHeroSummaryCard`, `ConditionalStatusBanner`, `DeviceStatusSection`, `InfoRow`, `BatteryPill`, `SignalPill`.
- `health_system` hiện đã có màn detail khá gần spec; cần bổ sung wording theo đời thường, pending sync, stale sync và guard self-only rõ hơn.

---

## Design Context

- **Target audience**: Người dùng lớn tuổi muốn kiểm tra xem đồng hồ còn hoạt động ổn không.
- **Usage context**: Routine checking, troubleshooting nhanh.
- **Key UX priority**: Clarity + Calm.
- **Specific constraints**:
  - số pin phải đủ to,
  - banner cảnh báo rõ nhưng không "báo động giả",
  - nút cấu hình phải nằm thấp, dễ bấm,
  - thông tin kỹ thuật được tách riêng, không đưa lên đầu màn.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `./build-plan/DEVICE_StatusDetail_plan.md` |
| BUILD | ✅ Partial | `health_system` |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
| v2.1 | 2026-03-18 | AI | Bổ sung stale-offline, pending sync, self-only guard và layout tối ưu cho người lớn tuổi |
| v2.2 | 2026-03-18 | AI | Liên kết PLAN đã tạo: `build-plan/DEVICE_StatusDetail_plan.md` |

---

## Implementation Reference (health_system)

- `lib/features/device/screens/device_status_detail_screen.dart`
- Đã có:
  - detail screen riêng,
  - retry / not-found states,
  - configure navigation,
  - low battery / offline banner theo widget riêng.
- Gap chính:
  - chưa làm rõ `pending sync`,
  - chưa ưu tiên wording thân thiện người lớn tuổi,
  - chưa mô tả rõ self-only / linked guard ở level spec.
