# 📱 EMERGENCY — Danh sách SOS nhận được

> **UC Ref**: UC015
> **Module**: EMERGENCY
> **Status**: ✅ Built (health_system)

## Purpose

Danh sách SOS đã nhận từ người thân. Filter theo trạng thái (all/active/resolved). Search. Tap → SOSReceivedDetail. Màu đỏ cho SOS active.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| MainScreen (Tab Khẩn cấp) | Tab "Khẩn cấp" | → This screen |
| [EMERGENCY_IncomingSOSAlarm](./EMERGENCY_IncomingSOSAlarm.md) | Bấm "Xem chi tiết" | → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md) |
| [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) | Bấm SOS Badge | → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md) |
| This screen | Bấm vào item | → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md) |

---

## User Flow

1. Mở tab Khẩn cấp → fetch list SOS.
2. Filter: Tất cả / Đang active / Đã xử lý.
3. Search theo tên người gửi.
4. Tap item → SOSReceivedDetail với `sosId`.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch list | Skeleton |
| Success | Có data | List cards, filter chips, search |
| Empty | Không có SOS | "Chưa có SOS nào" + illustration |
| Error | API fail, network loss | SnackBar + "Thử lại" |
| Filtered | Đã chọn filter | List đã lọc |

---

## Edge Cases

- [ ] **Network loss** khi load → Cache list cũ nếu có; SnackBar "Mất kết nối"
- [ ] **App background** khi có SOS mới → FCM → IncomingSOSAlarm; List refresh khi tab active
- [ ] SOS active → Card màu đỏ nổi bật; resolved → xám
- [ ] Pull-to-refresh → refetch list
- [ ] Nhiều SOS cùng người → Group hoặc hiển thị từng item

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sos/received` với query `?status=all|active|resolved&search=`
- **Input**: Filter, search params
- **Output**: `[{ sos_id, sender_name, profile_id, status, created_at, ... }]`

---

## Sync Notes

- Khi EMERGENCY_SOSReceivedDetail thay đổi → Back về List có thể refresh (status resolved)
- Khi EMERGENCY_IncomingSOSAlarm thay đổi → "Xem chi tiết" → Detail (có thể qua List hoặc thẳng)
- Khi HOME_FamilyDashboard thay đổi → SOS Badge → Detail (không qua List)
- Shared: SOSCard widget, filter chips

---

## Design Context

- **Target audience**: Người theo dõi (caregiver/family).
- **Usage context**: Routine — xem danh sách SOS đã nhận.
- **Key UX priority**: Clarity (SOS active đỏ rõ), Speed (load nhanh).
- **Specific constraints**: Card SOS active màu đỏ; nút/filter ≥48dp.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (network loss, app background), Design Context |

---

## Implementation Reference (health_system)

- `lib/features/emergency/screens/emergency_sos_received_list_screen.dart`
- Tab trong MainScreen. Filter: all/active/resolved. Search theo tên.
