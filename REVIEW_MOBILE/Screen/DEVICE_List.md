# 📱 DEVICE — Danh sách thiết bị

> **UC Ref**: UC040, UC041, UC042
> **Module**: DEVICE
> **Status**: ✅ Built (health_system, cần refactor theo spec chuẩn)

## Purpose

Hiển thị danh sách thiết bị đã đăng ký của **chính bản thân người dùng** theo kiến trúc Hybrid hiện tại. Đây là màn hình hub của module DEVICE: xem nhanh trạng thái, phát hiện thiết bị sắp hết pin/mất kết nối, vào chi tiết, và bắt đầu luồng kết nối thiết bị mới.

> **Quan trọng**: Màn này là **self-only**. Người thân/người chăm sóc **không** vào đây để quản lý thiết bị của bệnh nhân; nhu cầu theo dõi từ xa phải được đáp ứng bằng badge/trạng thái thiết bị ở `HOME_FamilyDashboard` hoặc trong các màn monitoring liên quan.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm tab "Thiết bị" / CTA "Kết nối thiết bị" ở empty state | → This screen |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Thiết bị" | → This screen |
| This screen | Bấm CTA / FAB "Thêm thiết bị" | → [DEVICE_Connect](./DEVICE_Connect.md) |
| This screen | Bấm vào Card thiết bị | → [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) |

---

## User Flow

1. User mở tab **Thiết bị**.
2. Hệ thống fetch danh sách thiết bị self đang gắn với tài khoản.
3. Top section hiển thị 3 số liệu rõ ràng: **Tổng thiết bị / Đang kết nối / Cần kiểm tra**.
4. Danh sách card ưu tiên thiết bị có vấn đề lên trên: pin yếu, offline lâu, pending sync.
5. User có thể lọc theo trạng thái hoặc loại thiết bị nếu có nhiều hơn 2 thiết bị.
6. Empty state hiển thị CTA lớn **"Kết nối thiết bị mới"** và mô tả ngắn, dễ hiểu.
7. User bấm một card để xem `DEVICE_StatusDetail`.
8. User bấm CTA/FAB để vào `DEVICE_Connect`.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang tải lần đầu | Skeleton cho summary + 2 card mẫu |
| Empty | Chưa có thiết bị | Illustration + text ngắn + CTA lớn "Kết nối thiết bị mới" |
| Success | Có ít nhất 1 thiết bị | Summary, filter nhẹ, danh sách card |
| NeedsAttention | Có thiết bị pin yếu / offline lâu / pending sync | Banner nhẹ màu vàng/cam + card lỗi được đẩy lên đầu |
| Error | Fetch lỗi và không có cache | Empty error state + nút "Thử lại" |
| OfflineCache | Mất mạng nhưng có dữ liệu cũ | Banner "Đang xem dữ liệu đã lưu" + timestamp cache |
| Filtered | User đã chọn filter | Chỉ hiện list đã lọc, vẫn giữ CTA thêm thiết bị |

---

## Edge Cases

- [x] Tất cả thiết bị offline → summary vẫn rõ "0 đang kết nối", list không bị trống giả.
- [x] Thiết bị pin yếu `< 20%` → card có badge cảnh báo rõ nhưng không làm user hoảng.
- [x] Thiết bị offline quá lâu → hiển thị "Mất kết nối X giờ/ngày" thay vì chỉ badge Offline.
- [x] Network mất khi đang xem → giữ cache nếu có, tránh trắng màn hình.
- [x] Card bị xóa từ backend sau khi refresh → tự remove khỏi list, không crash.
- [x] Chữ phóng to 150-200% → card vẫn xuống dòng đẹp, không cắt nội dung.
- [x] Chỉ số pin / RSSI không có → hiển thị "Không xác định", không để `--` trơ trọi trên summary.
- [x] User chạm nhầm filter nhiều lần → request trước đó phải được bỏ qua hoặc state cuối cùng thắng.
- [x] Nếu app bị mở ở ngữ cảnh linked/family do deep link sai → redirect về self device module hoặc chặn bằng thông báo "Bạn chỉ quản lý thiết bị của chính mình tại đây".

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/devices` (self-only; không truyền `profileId` cho linked context ở kiến trúc Hybrid hiện tại)
- **Input**:
  - Query `status=all|online|offline|needs_attention` (optional)
  - Query `type=smartwatch|fitness_band|medical_device` (optional)
- **Output**:
  - `devices: [{ id, name, type, isOnline, batteryPercent, signalStrength, lastSeenAt, lastSyncAt, pendingSync, ... }]`
  - `summary: { total, onlineCount, needsAttentionCount }`

---

## Sync Notes

- Khi `DEVICE_Connect` thành công → quay về List và refresh/inject item mới lên đầu danh sách.
- Khi `DEVICE_StatusDetail` / `DEVICE_Configure` thay đổi tên, trạng thái, pending sync → List phải refetch khi back.
- Shared widgets nên có: `DeviceSummaryCard`, `DeviceStatusBadge`, `NeedsAttentionBanner`, `EmptyDeviceState`.
- `HOME_FamilyDashboard` nên hiển thị read-only device health summary cho linked profile, **không** reuse full navigation vào màn DEVICE self-only này.
- `health_system` hiện đã có `device_screen.dart`, nhưng cần tinh gọn copy, tăng accessibility và đồng bộ wording theo spec này.

---

## Design Context

- **Target audience**: Người dùng lớn tuổi tự quản lý đồng hồ của mình; đôi khi có người thân am hiểu công nghệ đứng cạnh hỗ trợ thao tác.
- **Usage context**: Routine check, troubleshooting nhẹ, bắt đầu kết nối thiết bị mới.
- **Key UX priority**: Clarity trước tiên, sau đó mới đến đủ thông tin.
- **Specific constraints**:
  - Card phải đọc nhanh trong 3-5 giây.
  - Chỉ 1 CTA chính nổi bật.
  - Touch target >= 48dp.
  - Không đẩy chi tiết kỹ thuật như MAC/MQTT ra danh sách chính.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `./build-plan/DEVICE_List_plan.md` |
| BUILD | ✅ Partial | `health_system` |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
| v2.1 | 2026-03-18 | AI | Chuẩn hoá self-only theo Hybrid Architecture, thêm needs-attention state, accessibility và handoff cho nhu cầu theo dõi người thân |
| v2.2 | 2026-03-18 | AI | Liên kết PLAN đã tạo: `build-plan/DEVICE_List_plan.md` |

---

## Implementation Reference (health_system)

- `lib/features/device/screens/device_screen.dart`
- Route: `/device`
- App đã có list, refresh, filter, add dialog, detail navigation.
- Gap chính so với spec:
  - wording còn thiên kỹ thuật,
  - chưa có `needs_attention` summary rõ,
  - chưa có empty state/elderly copy tối ưu,
  - chưa chặn/giải thích rõ self-only context.
