# 📱 NOTIFICATION — SĐT khẩn cấp (Emergency Contacts)

> **UC Ref**: UC030
> **Module**: NOTIFICATION
> **Status**: ⬜ Spec only

## Purpose

Danh sách **SĐT gọi ngoài app** khi User phát SOS. Các số này được gọi tự động (IVR/backend) khi SOS kích hoạt. Validation VN: 10 số. **Link sang [PROFILE_ContactList](./PROFILE_ContactList.md)** — "Liên hệ trong app" (Linked Profiles) khác với SĐT khẩn cấp (số điện thoại gọi ngoài).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [NOTIFICATION_Settings](./NOTIFICATION_Settings.md) | Bấm "SĐT khẩn cấp" | → This screen |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "SĐT khẩn cấp" | → This screen |
| This screen | Bấm FAB "Thêm" | → [NOTIFICATION_AddEditContact](./NOTIFICATION_AddEditContact.md) |
| This screen | Bấm item (edit) | → [NOTIFICATION_AddEditContact](./NOTIFICATION_AddEditContact.md) |
| This screen | Bấm "Liên hệ trong app" | → [PROFILE_ContactList](./PROFILE_ContactList.md) |
| This screen | Back | → [NOTIFICATION_Settings](./NOTIFICATION_Settings.md) hoặc [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Hiển thị danh sách SĐT khẩn cấp (tên + số).
2. "SĐT sẽ được gọi tự động khi bạn phát SOS."
3. FAB "Thêm" → AddEditContact.
4. Tap item → Edit.
5. Link "Quản lý liên hệ trong app" → PROFILE_ContactList (Linked Profiles nhận FCM, khác SĐT gọi).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch | Skeleton |
| Empty | Chưa có SĐT | Illustration + "Thêm SĐT khẩn cấp" + FAB |
| Success | Có 1+ SĐT | List + FAB |
| Error | API fail | SnackBar + "Thử lại" |

---

## Edge Cases

- [ ] Validation VN: 10 số (bắt đầu 03, 05, 07, 08, 09)
- [ ] Số trùng → message "Số này đã có"
- [ ] Giới hạn số lượng (VD: tối đa 5) → disable FAB khi đủ
- [ ] Link PROFILE_ContactList: "Liên hệ trong app nhận thông báo SOS qua app. SĐT khẩn cấp được gọi tự động."

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/emergency-contacts`; `POST`/`PATCH`/`DELETE` qua AddEditContact
- **Input**: Auth token
- **Output**: `[{ id, name, phone, order }]` — phone 10 số VN

---

## Sync Notes

- Khi NOTIFICATION_AddEditContact save/delete → refresh list
- **Phân biệt**: PROFILE_ContactList = Linked Profiles (in-app, FCM). NOTIFICATION_EmergencyContacts = SĐT gọi ngoài (IVR/backend).
- Shared: EmergencyContactCard, validation util

---

## Design Context

- **Target audience**: User (đặc biệt người cao tuổi) — cấu hình SĐT gọi khi SOS.
- **Usage context**: Configuration — quan trọng cho emergency.
- **Key UX priority**: Clarity (số rõ, link PROFILE_ContactList rõ), Trust (validation đúng).
- **Specific constraints**: Nút min 48dp; giải thích rõ SĐT vs Liên hệ trong app.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, link PROFILE_ContactList, phân biệt SĐT vs Linked Profiles |
