# 📱 NOTIFICATION — Chi tiết thông báo

> **UC Ref**: UC031
> **Module**: NOTIFICATION
> **Status**: ⬜ Spec only

## Purpose

Chi tiết 1 thông báo. Hiển thị full content. **Deep-link** theo loại (SOS, Sleep, Risk, System) → navigate màn tương ứng. Có thể là màn trung gian (preview) hoặc redirect thẳng.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [NOTIFICATION_Center](./NOTIFICATION_Center.md) | Bấm item | → This screen |
| *FCM tap* | User tap push | → This screen (hoặc deep-link thẳng) |
| This screen | Bấm "Xem chi tiết" / content | → Màn tương ứng (SOS/Sleep/Risk) |
| This screen | Back | → [NOTIFICATION_Center](./NOTIFICATION_Center.md) |

---

## User Flow

1. Nhận `notificationId` từ route (từ Center) hoặc FCM payload.
2. Fetch detail, mark read.
3. Hiển thị: title, body, timestamp.
4. Nút "Xem chi tiết" → deep-link theo `type`:
   - SOS → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md)
   - Sleep → [SLEEP_Report](./SLEEP_Report.md)
   - Risk → [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md)
   - System → có thể không có deep-link
5. Nếu notification thuộc linked profile → payload phải truyền đúng `profileId` để mở đúng ngữ cảnh người được theo dõi.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch | Skeleton |
| Success | Có data | Title, body, timestamp, "Xem chi tiết" |
| Error | Not found, API fail | SnackBar, Back |
| Redirect | Deep-link thẳng | Có thể skip màn này, navigate trực tiếp |

---

## Edge Cases

- [ ] Notification đã bị xoá → 404 → Back
- [ ] FCM data payload có `screen`, `id` → deep-link thẳng không cần fetch
- [ ] Loại không hỗ trợ deep-link → ẩn nút "Xem chi tiết"
- [ ] Notification của linked profile nhưng thiếu `profileId` → fallback vào màn preview, không deep-link sai sang self

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/notifications/:id`; `PATCH /api/mobile/notifications/:id/read`
- **Input**: Route arg `notificationId`; FCM payload `notification_id`, `type`, `screen`, `id`, `profile_id?`, `report_id?`, `date?`
- **Output**: `{ id, type, title, body, data, created_at }`

---

## Sync Notes

- Khi NOTIFICATION_Center thay đổi → tap item truyền `notificationId`
- FCM tap → có thể vào đây hoặc deep-link thẳng tùy payload
- Deep-link tới `SLEEP_Report` / `ANALYSIS_RiskReport` phải truyền tiếp `profileId` nếu notification thuộc linked profile
- Shared: NotificationDetailCard

---

## Design Context

- **Target audience**: Tất cả User.
- **Usage context**: Routine — xem chi tiết thông báo.
- **Key UX priority**: Clarity (content rõ), Speed (deep-link nhanh).
- **Specific constraints**: Nút "Xem chi tiết" min 48dp.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, deep-link logic |
| v2.1 | 2026-03-17 | AI | Cross-check sync: bổ sung deep-link context `profileId` cho sleep/risk notification của linked profile |
