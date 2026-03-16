# 📱 NOTIFICATION — Cài đặt thông báo

> **UC Ref**: UC031
> **Module**: NOTIFICATION
> **Status**: ⬜ Spec only

## Purpose

**Tuỳ chỉnh cảnh báo** — tắt/bật từng loại thông báo (SOS, Sleep, Risk, System). **QUAN TRỌNG**: Mỗi toggle phải sync FCM subscribe/unsubscribe. Không chỉ lưu DB. Phân biệt với NOTIFICATION_Center (inbox) và NOTIFICATION_EmergencyContacts (SĐT khẩn cấp).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [NOTIFICATION_Center](./NOTIFICATION_Center.md) | Bấm "Cài đặt" | → This screen |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Cài đặt thông báo" | → This screen |
| This screen | Back | → [NOTIFICATION_Center](./NOTIFICATION_Center.md) hoặc [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Hiển thị các toggle: SOS alerts, Sleep summary, Risk report, System updates.
2. User gạt toggle → gọi API update + FCM subscribe/unsubscribe ngay.
3. SOS alerts: **luôn khuyến nghị ON** — có thể disable nhưng cảnh báo.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch settings | Skeleton |
| Idle | Các toggle sẵn sàng | Toggle + label mô tả |
| Saving | Đang gọi API + FCM | Loading trên toggle đang đổi |
| Error | API fail, FCM fail | SnackBar, restore toggle |
| Success | Lưu thành công | Toast "Đã lưu" |

---

## Edge Cases

- [ ] FCM subscribe/unsubscribe fail → Toast "Không thể cập nhật. Thử lại." — restore toggle
- [ ] User tắt SOS alerts → confirm "Bạn có chắc? Bạn có thể bỏ lỡ cảnh báo khẩn cấp."
- [ ] Network loss khi save → retry khi có mạng
- [ ] Toggle spam → disable trong 500ms sau mỗi lần gạt

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/notification-settings`; `PATCH /api/mobile/notification-settings`
- **Input**: `{ sos_alerts?, sleep_summary?, risk_report?, system_updates? }` (boolean)
- **Output**: `{ success: true }`; client phải gọi FCM `subscribeToTopic`/`unsubscribeFromTopic` tương ứng

---

## Sync Notes

- Khi toggle thay đổi → FCM topic sync: `user_{userId}_sos`, `user_{userId}_sleep`, v.v.
- NOTIFICATION_Center (inbox) không phụ thuộc Settings — Settings chỉ ảnh hưởng nhận push
- Shared: SettingsToggle, FCM topic manager

---

## Design Context

- **Target audience**: Tất cả User.
- **Usage context**: Configuration — tuỳ chỉnh nhận thông báo.
- **Key UX priority**: Clarity (mỗi toggle rõ mục đích), Trust (FCM sync đúng).
- **Specific constraints**: Toggle min 48dp; SOS cảnh báo khi tắt.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, FCM sync requirement |
