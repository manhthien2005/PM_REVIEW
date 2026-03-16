# 📱 DEVICE — Danh sách thiết bị

> **UC Ref**: UC040, UC041, UC042
> **Module**: DEVICE
> **Status**: ✅ Built (health_system)

## Purpose

Hiển thị danh sách thiết bị đã đăng ký (đồng hồ, vòng đeo) của **chính bản thân** người dùng. Overview: Tổng / Online / Ngoại tuyến. Filter theo trạng thái và loại. CTA "Thêm thiết bị" khi empty.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm tab Thiết bị / CTA "Kết nối thiết bị" | → This screen |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Thiết bị" | → This screen |
| This screen | Bấm FAB "Thêm thiết bị" | → [DEVICE_Connect](./DEVICE_Connect.md) |
| This screen | Bấm vào Card thiết bị | → [DEVICE_StatusDetail](./DEVICE_StatusDetail.md) |

---

## User Flow

1. Mở màn → fetch devices.
2. Overview: Tổng, Online, Ngoại tuyến. Filter: Tất cả / Online / Offline. Lọc theo loại (smartwatch, fitness_band, medical_device).
3. Empty state → "Chưa có thiết bị" + CTA.
4. Bấm FAB → Add device flow (Connect hoặc Dialog đăng ký).
5. Bấm card → StatusDetail.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch danh sách thiết bị | Skeleton / CircularProgressIndicator |
| Empty | Chưa có thiết bị nào | Illustration + "Chưa có thiết bị" + CTA "Thêm thiết bị" |
| Success | Có 1+ thiết bị | Overview stats + List cards + FAB |
| Error | API fail, network loss | SnackBar đỏ + "Thử lại" |
| Filtered | Đã chọn filter | List đã lọc theo Online/Offline/Type |

---

## Edge Cases

- [ ] Tất cả thiết bị offline → Overview hiển thị "0 Online", list vẫn hiển thị với badge Offline
- [ ] Network mất khi đang xem → hiển thị cache nếu có; SnackBar "Mất kết nối"
- [ ] Thiết bị bị xoá từ backend → refresh list, có thể 404 trên card → remove khỏi list
- [ ] User chưa có quyền xem thiết bị (edge) → 403 → message phù hợp
- [ ] Pull-to-refresh → refetch list

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/devices` (hoặc tương đương) — devices của `target_profile_id` = self
- **Input**: Query: `?status=all|online|offline`, `?type=smartwatch|fitness_band|medical_device` (optional)
- **Output**: `{ devices: [{ id, name, type, status, batteryPercent, lastSyncAt, ... }], total, onlineCount, offlineCount }`

---

## Sync Notes

- Khi DEVICE_Connect thêm thiết bị thành công → pop về List → refetch hoặc insert vào list
- Khi DEVICE_StatusDetail thay đổi trạng thái (pin, online) → List có thể cần refresh khi back
- Shared: Device card widget (có thể reuse trong List và StatusDetail preview)
- **Lưu ý**: health_system dùng Dialog "Đăng ký thiết bị" thay vì màn Connect riêng — spec vẫn giữ Connect cho BLE flow tương lai

---

## Design Context

- **Target audience**: User quản lý thiết bị của chính mình (không phải người thân).
- **Usage context**: Routine — xem/quản lý thiết bị đã kết nối.
- **Key UX priority**: Clarity (overview rõ), Speed (load nhanh).
- **Specific constraints**: FAB min 48dp; filter dễ bấm; empty state thân thiện.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |

---

## Implementation Reference (health_system)

- `lib/features/device/screens/device_screen.dart`
- Route: `/device` (từ MainScreen hoặc Profile)
- **Khác spec**: App dùng Dialog "Đăng ký thiết bị" (form thủ công: tên, loại, model, MAC, serial, MQTT) thay vì BLE scan. Không có màn Connect riêng.
