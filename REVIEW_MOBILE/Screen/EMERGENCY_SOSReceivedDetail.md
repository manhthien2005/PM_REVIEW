# 📱 EMERGENCY — Chi tiết SOS + Bản đồ (War Room)

> **UC Ref**: UC011, UC015
> **Module**: EMERGENCY
> **Status**: ✅ Built (health_system)

## Purpose

Chi tiết sự kiện SOS. Map (nếu `can_view_location`), vitals, nút "Đã xác nhận an toàn". Cần `can_view_location` để hiển thị map. Cần `can_receive_alerts` để vào màn này. Màu đỏ, nút to.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [EMERGENCY_SOSReceivedList](./EMERGENCY_SOSReceivedList.md) | Bấm item | → This screen |
| [EMERGENCY_IncomingSOSAlarm](./EMERGENCY_IncomingSOSAlarm.md) | Bấm "Xem chi tiết" | → This screen |
| [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) | Bấm SOS Badge | → This screen |
| This screen | Bấm "Đã xác nhận an toàn" | → Home (Resolved) |

---

## User Flow

1. Nhận `sosId` từ route.
2. Fetch detail, subscribe updates (WebSocket/polling).
3. Hiển thị: Tên người gửi, vitals, map (nếu có quyền), trạng thái.
4. Nút "Đã xác nhận an toàn" (≥56dp) → API resolve → Home.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch detail | Skeleton |
| Success | Có data | Map, vitals, nút "Đã xác nhận an toàn" |
| No Location | Không có `can_view_location` | Ẩn map, hiển thị "Vị trí không khả dụng" |
| Resolving | User bấm xác nhận | Loading → Home |
| Error | API fail, network loss | SnackBar + "Thử lại" |
| App Background | App minimize | On resume: refetch nếu SOS active |

---

## Edge Cases

- [ ] **Network loss** khi fetch/resolve → Cache; retry khi có mạng
- [ ] **App background** → On resume: refetch nếu SOS vẫn active; nếu đã resolve → Home
- [ ] Không có `can_view_location` → Ẩn map, không crash
- [ ] SOS đã resolve bởi người khác → Cập nhật UI real-time (subscribe)
- [ ] Nút "Đã xác nhận an toàn" → hold-to-confirm 2s tránh bấm nhầm (optional)

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sos/:sosId`; `POST /api/mobile/sos/:sosId/resolve`; WebSocket/polling updates
- **Input**: Route arg `sosId`
- **Output**: `{ sender_name, profile_id, status, vitals, location?, created_at, ... }`

---

## Sync Notes

- Khi EMERGENCY_SOSReceivedList thay đổi → tap item truyền `sosId`
- Khi EMERGENCY_IncomingSOSAlarm thay đổi → "Xem chi tiết" truyền `sosId` từ FCM
- Khi HOME_FamilyDashboard thay đổi → SOS Badge truyền `sosId` từ `active_sos_id`
- Resolve → update List; FCM có thể notify người gửi SOS đã được xác nhận

---

## Design Context

- **Target audience**: Người theo dõi (caregiver/family) — xem chi tiết SOS người thân.
- **Usage context**: Emergency — War Room.
- **Key UX priority**: Clarity (map, vitals rõ), Speed (load nhanh), Calm (nút xác nhận to).
- **Specific constraints**: Màu đỏ cho SOS active; Map cần zoom; nút ≥56dp; hold-to-confirm cho "Đã xác nhận an toàn".

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
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (network loss, app background), UX (56dp, hold-to-confirm) |

---

## Implementation Reference (health_system)

- `lib/features/emergency/screens/emergency_sos_detail_screen.dart`
- Nhận `sosId`. Fetch detail, subscribe updates. Map, vitals, status.
