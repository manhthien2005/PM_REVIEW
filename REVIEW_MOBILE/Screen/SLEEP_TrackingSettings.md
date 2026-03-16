# 📱 SLEEP — Cài đặt theo dõi giấc ngủ

> **UC Ref**: UC020
> **Module**: SLEEP
> **Status**: ⬜ Spec only

## Purpose

Bật/tắt **tracking giấc ngủ** và set **giờ ngủ mục tiêu**. Nhắc nhở (local notification). Cần local notification permission. User tự cấu hình theo dõi giấc ngủ.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [SLEEP_Report](./SLEEP_Report.md) | Bấm "Cài đặt" | → This screen |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Cài đặt giấc ngủ" (nếu có) | → This screen |
| This screen | Save / Back | → [SLEEP_Report](./SLEEP_Report.md) hoặc [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Toggle "Bật theo dõi giấc ngủ" — ON/OFF.
2. **Giờ ngủ mục tiêu** — time picker (VD: 22:00, 23:00).
3. Nhắc nhở: "Nhắc tôi đi ngủ lúc X" — optional, cần notification permission.
4. Save → API + schedule local notification (nếu bật).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch settings | Skeleton |
| Idle | Form sẵn sàng | Toggle tracking, time picker, toggle nhắc nhở |
| Saving | Đang gọi API | Loading, disable Save |
| Success | Save thành công | Toast → Back |
| Perm Denied | Chưa cấp notification | "Cần quyền thông báo để nhắc nhở" + nút Cấp quyền |
| Error | API fail | SnackBar |

---

## Edge Cases

- [ ] Tracking OFF → ẩn nhắc nhở; vẫn lưu giờ mục tiêu (cho khi bật lại)
- [ ] Notification permission denied → disable toggle nhắc nhở, message rõ
- [ ] Giờ ngủ mục tiêu: 18:00–06:00 (hợp lý)
- [ ] Local notification: schedule daily tại (target_time - 30 phút) hoặc tương tự

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sleep/settings`; `PATCH /api/mobile/sleep/settings`
- **Input**: `{ tracking_enabled: boolean, target_bedtime: "HH:mm", reminder_enabled?: boolean }`
- **Output**: `{ success: true }`; client schedule local notification nếu reminder_enabled

---

## Sync Notes

- Khi SLEEP_Report thay đổi → tracking OFF có thể ẩn data mới (tuỳ logic)
- Local notification: `flutter_local_notifications` hoặc tương đương
- Shared: TimePicker, Toggle, PermissionRequest

---

## Design Context

- **Target audience**: User — cấu hình theo dõi giấc ngủ.
- **Usage context**: Configuration — không thường xuyên.
- **Key UX priority**: Clarity (toggle rõ, giờ mục tiêu rõ), Trust (permission rõ).
- **Specific constraints**: Toggle min 48dp; time picker dễ chọn; permission flow rõ.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, bật/tắt tracking, giờ ngủ mục tiêu |
