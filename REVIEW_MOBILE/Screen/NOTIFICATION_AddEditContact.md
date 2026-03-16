# 📱 NOTIFICATION — Thêm/sửa SĐT khẩn cấp

> **UC Ref**: UC030
> **Module**: NOTIFICATION
> **Status**: ⬜ Spec only

## Purpose

Form thêm hoặc sửa **SĐT khẩn cấp** (gọi ngoài app khi SOS). Validation VN: 10 số (03, 05, 07, 08, 09). Add mode: tạo mới. Edit mode: nhận `contactId` từ route.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [NOTIFICATION_EmergencyContacts](./NOTIFICATION_EmergencyContacts.md) | Bấm FAB "Thêm" | → This screen (Add) |
| [NOTIFICATION_EmergencyContacts](./NOTIFICATION_EmergencyContacts.md) | Bấm item | → This screen (Edit) |
| This screen | Save thành công | → [NOTIFICATION_EmergencyContacts](./NOTIFICATION_EmergencyContacts.md) |
| This screen | Back / Cancel | → [NOTIFICATION_EmergencyContacts](./NOTIFICATION_EmergencyContacts.md) |

---

## User Flow

1. Form: name (optional), phone (bắt buộc).
2. Validation: phone 10 số VN, format 0xxxxxxxxx.
3. Save → API → Back list.
4. Edit: pre-fill từ contactId.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch (Edit mode) | Skeleton |
| Idle | Form sẵn sàng | Name, Phone fields, Save |
| Saving | Đang gọi API | Loading, disable Save |
| Success | Save thành công | Toast → Back |
| Error | Validation, API fail (số trùng) | SnackBar, form giữ giá trị |

---

## Edge Cases

- [ ] Validation VN: 10 số, bắt đầu 03/05/07/08/09
- [ ] Số trùng (đã có trong list) → "Số này đã được thêm"
- [ ] Edit: xoá số → confirm "Bạn có chắc xoá?"
- [ ] Name optional — nếu trống có thể hiển thị "SĐT 1", "SĐT 2" trong list

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/emergency-contacts` (Add); `PATCH /api/mobile/emergency-contacts/:id` (Edit); `DELETE` (Edit mode xoá)
- **Input**: `{ name?, phone }` — phone 10 số
- **Output**: `{ id, name, phone }` → Back list; error: 400 (validation), 409 (duplicate)

---

## Sync Notes

- Khi NOTIFICATION_EmergencyContacts thay đổi → Back refresh list
- Shared: PhoneInput với validation VN, Form validation

---

## Design Context

- **Target audience**: User — thêm SĐT gọi khi SOS.
- **Usage context**: Configuration — Emergency Contacts.
- **Key UX priority**: Clarity (validation rõ), Trust (format đúng).
- **Specific constraints**: Phone input với format hint "VD: 0912345678"; nút Save min 48dp.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, validation VN 10 số |
