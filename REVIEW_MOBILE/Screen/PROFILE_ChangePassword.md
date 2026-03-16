# 📱 PROFILE — Đổi mật khẩu

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: ✅ Built (health_system)

## Purpose

Đổi mật khẩu khi đã đăng nhập. Nhập mật khẩu cũ + mật khẩu mới + xác nhận. User (unified role).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Đổi mật khẩu" | → This screen |
| This screen | Đổi thành công | → [PROFILE_Overview](./PROFILE_Overview.md) |
| This screen | Bấm Back | → [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Form: currentPassword, newPassword, confirmPassword.
2. Validation: new = confirm, strength, current đúng.
3. Save → API → Back Overview.
4. Có thể cần re-login sau khi đổi (tuỳ backend).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Idle | Form sẵn sàng | 3 fields, Save |
| Saving | Đang gọi API | Loading, disable Save |
| Success | Đổi thành công | SnackBar → Back |
| Error | Sai mật khẩu cũ, validation | SnackBar, form giữ giá trị |

---

## Edge Cases

- [ ] Sai mật khẩu cũ → message "Mật khẩu hiện tại không đúng"
- [ ] newPassword ≠ confirmPassword → inline error
- [ ] Password strength yếu → indicator
- [ ] Sau khi đổi → token có thể invalid → redirect Login (tuỳ backend)

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/profile/change-password`
- **Input**: `{ current_password, new_password }`
- **Output**: `{ success: true }`; có thể trả 401 → cần re-login

---

## Sync Notes

- Khi PROFILE_Overview thay đổi → link "Đổi mật khẩu" giữ nguyên
- Shared: Password strength widget (giống Register)

---

## Design Context

- **Target audience**: Tất cả User.
- **Usage context**: Security — không thường xuyên.
- **Key UX priority**: Clarity (3 field rõ), Trust (không lộ mật khẩu).
- **Specific constraints**: Show/hide password; nút Save min 48dp.

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
| v2.0 | 2026-03-17 | AI | Regen: full template |

---

## Implementation Reference (health_system)

- `lib/features/auth/screens/change_password_screen.dart`
- Route: `/change-password`
