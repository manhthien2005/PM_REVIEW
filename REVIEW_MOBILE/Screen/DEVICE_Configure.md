# 📱 DEVICE — Cấu hình thiết bị

> **UC Ref**: UC041
> **Module**: DEVICE
> **Status**: ✅ Partial (health_system đã có rename/toggle/delete, chưa đủ config chuẩn)

## Purpose

Cho phép user chỉnh các cài đặt của thiết bị theo cách **đủ dùng nhưng không rối**: đổi tên, cấu hình các tuỳ chọn cơ bản, lưu thay đổi an toàn khi thiết bị đang offline, và thực hiện thao tác nguy hiểm như unpair trong khu vực tách biệt.

> **Quan trọng**:
> - Màn này là **self-only**.
> - Không dùng cho linked/family context.
> - Phải chia rõ **Cơ bản / Nâng cao / Vùng nguy hiểm** để người lớn tuổi không bị quá tải.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) | Bấm "Cấu hình thiết bị" | → This screen |
| This screen | Lưu thành công / Back | → [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) |
| This screen | Ngắt kết nối (unpair) thành công | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow

1. Nhận `deviceId` hoặc `device` từ route args.
2. Fetch cấu hình hiện tại của thiết bị.
3. Hiển thị 3 nhóm:
   - **Cơ bản**: tên thiết bị.
   - **Theo dõi & cảnh báo**: cảnh báo pin yếu, rung khi cảnh báo, bật/tắt theo dõi giấc ngủ nếu phần cứng hỗ trợ.
   - **Đồng bộ**: khoảng thời gian sync / trạng thái pending sync.
4. User chỉnh 1 hoặc nhiều trường.
5. Nếu có thay đổi → nút **"Lưu thay đổi"** active.
6. Nếu thiết bị đang offline:
   - vẫn cho lưu các cấu hình hỗ trợ server-side,
   - hiển thị rõ phần nào đang **"Chờ đồng bộ khi thiết bị online"**.
7. User bấm **"Ngắt kết nối thiết bị"** ở vùng nguy hiểm → confirm 2 bước → gọi unpair.
8. Sau save thành công → quay về `DEVICE_StatusDetail` và refetch.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang tải config | Skeleton form + footer bar disabled |
| Idle | Form sẵn sàng chỉnh | Section form + sticky footer "Lưu thay đổi" |
| Dirty | Có thay đổi chưa lưu | Footer bar nổi bật + badge "Chưa lưu" |
| Saving | Đang lưu | Loading trên CTA, disable field |
| PendingSync | Lưu được nhưng thiết bị offline | Banner info "Thiết bị sẽ nhận cấu hình khi online" |
| Success | Lưu thành công | SnackBar xanh / toast ngắn + back |
| Error | Save fail | Inline error hoặc snackBar đỏ, giữ nguyên dữ liệu user vừa nhập |
| UnpairConfirm | User chuẩn bị unpair | Bottom sheet / dialog xác nhận rõ hậu quả |
| Unpairing | Đang ngắt kết nối | Disable toàn màn |

---

## Edge Cases

- [x] Thiết bị offline khi save → vẫn cho lưu các cấu hình hợp lệ, đánh dấu `pending sync`.
- [x] Validation tên thiết bị: không rỗng, không chỉ có khoảng trắng, giới hạn độ dài thân thiện.
- [x] Sync interval ngoài range → báo lỗi tại field, không chờ submit.
- [x] User Back khi đang có thay đổi chưa lưu → confirm "Bạn có muốn bỏ thay đổi không?"
- [x] Unpair confirm phải ghi rõ: dữ liệu đã đồng bộ vẫn được giữ, nhưng thiết bị sẽ không tiếp tục gửi dữ liệu.
- [x] Unpair fail → message dễ hiểu, không hiện raw server error.
- [x] Nếu field nào chỉ áp dụng khi thiết bị online → chú thích nhỏ "Sẽ áp dụng khi đồng hồ online lại".
- [x] Nếu app vào sai linked context → chặn truy cập ngay.

---

## Data Requirements

- **API endpoints**:
  - `GET /api/mobile/devices/:deviceId/config`
  - `PATCH /api/mobile/devices/:deviceId`
  - `DELETE /api/mobile/devices/:deviceId` hoặc unpair endpoint tương đương
- **Input (update)**:
  - `name`
  - `syncInterval`
  - `lowBatteryAlertThreshold`
  - `enableVibrationAlert`
  - `enableSleepTracking`
- **Output**:
  - `device` hoặc `config` mới
  - `pendingSync: true|false`
  - lỗi validate / 404 / 409 nếu có conflict

---

## Sync Notes

- Sau save thành công → `DEVICE_StatusDetail` phải refetch để cập nhật tên/trạng thái/pending sync.
- Sau unpair thành công → pop toàn bộ về `DEVICE_List` và refresh list.
- Shared components nên có:
  - `ConfigSectionCard`
  - `DirtyFooterBar`
  - `PendingSyncBanner`
  - `DangerZoneCard`
  - `DiscardChangesDialog`
- `health_system` hiện mới cover:
  - đổi tên,
  - bật/tắt active,
  - delete/unpair.
- Cần mở rộng dần theo backend capability, nhưng UI phải vẫn chia section đúng từ đầu.

---

## Design Context

- **Target audience**: Người dùng tự quản lý đồng hồ của mình; nhiều khả năng không rành thuật ngữ kỹ thuật.
- **Usage context**: Configuration không thường xuyên nhưng rủi ro thao tác nhầm cao.
- **Key UX priority**: Trust + Clarity.
- **Specific constraints**:
  - Chỉ 1 CTA chính ở footer.
  - Vùng nguy hiểm cách xa CTA lưu.
  - Min touch target 48dp.
  - Default copy phải đời thường, không dùng jargon kỹ thuật nếu không cần.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `./build-plan/DEVICE_Configure_plan.md` |
| BUILD | ✅ Partial | `health_system` |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation (STUB) |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
| v2.1 | 2026-03-18 | AI | Chuẩn hoá config theo 3 nhóm Cơ bản/Nâng cao/Vùng nguy hiểm, thêm dirty state, pending sync và self-only guard |
| v2.2 | 2026-03-18 | AI | Liên kết PLAN đã tạo: `build-plan/DEVICE_Configure_plan.md` |
