# 📱 PROFILE — Xác nhận xóa tài khoản

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: ✅ Built (health_system — 1 dialog, chưa đủ 3-step)

## Purpose

Xóa tài khoản User. **Spec**: 3-step confirm — (1) Dialog "Bạn có chắc?" → (2) Nhập mật khẩu → (3) Checkbox "Tôi hiểu dữ liệu sẽ bị xóa vĩnh viễn". API soft-delete / grace period.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Xóa tài khoản" (Danger Zone) | → This screen |
| This screen | Xác nhận xóa | → [AUTH_Login](./AUTH_Login.md) |
| This screen | Hủy | → [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow (Spec — 3-step)

1. Dialog "Bạn có chắc?"
2. Nhập mật khẩu xác nhận.
3. Checkbox "Tôi hiểu dữ liệu sẽ bị xóa vĩnh viễn".
4. Bấm "Xóa" → API → Logout → Login.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Step 1 | Confirm dialog | "Bạn có chắc?" + Hủy / Tiếp |
| Step 2 | Password input | Field mật khẩu + Hủy / Xóa |
| Step 3 | Checkbox + final | Checkbox + "Xóa vĩnh viễn" (disabled until checked) |
| Deleting | Đang gọi API | Loading |
| Success | Xóa thành công | Logout → Login |
| Error | Sai mật khẩu, API fail | SnackBar |

---

## Edge Cases

- [ ] Sai mật khẩu → message "Mật khẩu không đúng"
- [ ] Chưa tick checkbox → disable "Xóa"
- [ ] Grace period (VD: 30 ngày) → message "Tài khoản sẽ bị xóa sau 30 ngày"
- [ ] Network loss khi gửi → retry
- [ ] User hủy giữa chừng → Back Overview

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/profile/delete-account` hoặc `DELETE /api/mobile/profile`
- **Input**: `{ password }` (xác nhận)
- **Output**: `{ success: true }` → logout, clear token → Login

---

## Sync Notes

- Khi AUTH_Login thay đổi → navigate về sau khi xóa
- Shared: DangerZone, ConfirmDialog
- **Architecture**: User (unified) — xóa chính mình, không liên quan patient/caregiver

---

## Design Context

- **Target audience**: User muốn xóa tài khoản.
- **Usage context**: Danger — irreversible.
- **Key UX priority**: Trust (cảnh báo rõ), Calm (không gây hoảng nhưng nghiêm túc).
- **Specific constraints**: Màu đỏ Danger Zone; 3-step tránh bấm nhầm; checkbox bắt buộc.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ 1 dialog (chưa 3-step) | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, 3-step flow |

---

## Implementation Reference (health_system)

- `ProfileScreen._confirmDeleteAccount()` — 1 dialog với password field. Text: "Tài khoản và toàn bộ dữ liệu của bạn sẽ bị xóa sau 30 ngày." Chưa có 3-step đầy đủ.
