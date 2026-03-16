# 📱 NOTIFICATION — Trung tâm thông báo (Inbox)

> **UC Ref**: UC030, UC031
> **Module**: NOTIFICATION
> **Status**: ⬜ Spec only

## Purpose

**Inbox** tập trung tất cả thông báo của User. Icon theo loại (SOS, Sleep, Risk, System). Tap → NOTIFICATION_Detail hoặc deep-link màn tương ứng. Phân biệt với NOTIFICATION_Settings (tuỳ chỉnh) và NOTIFICATION_EmergencyContacts (SĐT khẩn cấp).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm icon "Thông báo" | → This screen |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm icon thông báo (nếu có) | → This screen |
| This screen | Bấm item thông báo | → [NOTIFICATION_Detail](./NOTIFICATION_Detail.md) / deep-link |
| This screen | Bấm "Cài đặt" | → [NOTIFICATION_Settings](./NOTIFICATION_Settings.md) |
| This screen | Back | → [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Mở màn → fetch danh sách thông báo (paginated).
2. Hiển thị list: icon loại, title, preview, timestamp, read/unread.
3. Tap item → mark read → NOTIFICATION_Detail hoặc deep-link (SOS → SOSReceivedDetail, Sleep → SLEEP_Report, v.v.).
4. Pull-to-refresh, load more.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch | Skeleton |
| Empty | Không có thông báo | Illustration + "Chưa có thông báo" |
| Success | Có data | List với icon loại, read/unread |
| Error | API fail | SnackBar + "Thử lại" |

---

## Edge Cases

- [ ] FCM push mới khi đang xem → refresh list hoặc insert top
- [ ] Deep-link: SOS → EMERGENCY_SOSReceivedDetail; Sleep → SLEEP_Report; Risk → ANALYSIS_RiskReport
- [ ] Mark all read → API batch update
- [ ] Pagination: load more khi scroll cuối

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/notifications` với query `?page=&limit=`
- **Input**: Auth token, pagination
- **Output**: `[{ id, type, title, body, data, read_at, created_at }]`

---

## Sync Notes

- Khi NOTIFICATION_Settings thay đổi → không ảnh hưởng inbox (chỉ ảnh hưởng nhận push)
- Khi FCM nhận push → có thể insert vào list local hoặc refetch
- Shared: NotificationCard, NotificationTypeIcon

---

## Design Context

- **Target audience**: Tất cả User.
- **Usage context**: Routine — xem lịch sử thông báo.
- **Key UX priority**: Clarity (icon loại rõ), Speed (load nhanh).
- **Specific constraints**: Unread badge rõ; tap target min 48dp.

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
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, phân biệt Inbox vs Settings vs EmergencyContacts |
