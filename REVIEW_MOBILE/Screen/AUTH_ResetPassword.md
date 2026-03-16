# 📱 AUTH — Đặt lại mật khẩu (Reset Password)

> **UC Ref**: UC003
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Nhập mật khẩu mới + xác nhận sau khi đã verify OTP (từ ForgotPassword flow). Nhận `email` và `code` từ `ResetOtpVerificationScreen` hoặc deep-link.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [AUTH_ForgotPassword](./AUTH_ForgotPassword.md) | OTP verified (qua ResetOtpVerificationScreen) | → This screen |
| *Deep link* | `reset-password?code=xxx&email=yyy` | → verifyResetOtp → This screen |
| This screen | Đặt lại thành công | → [AUTH_Login](./AUTH_Login.md) |

---

## User Flow

1. Nhập mật khẩu mới + xác nhận (có password strength indicator).
2. Bấm "Đặt lại mật khẩu" → API resetPassword(email, code, newPassword).
3. **Success** → SnackBar xanh → `pushNamedAndRemoveUntil(login)`.
4. **Fail** → SnackBar đỏ.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang gọi API resetPassword | CircularProgressIndicator, disable button |
| Idle | Form sẵn sàng nhập | New password, confirm password, "Đặt lại mật khẩu" |
| Success | Đặt lại thành công | SnackBar xanh → navigate Login |
| Error | Code hết hạn, validation fail | SnackBar đỏ, form giữ giá trị |
| Validation Error | Password ≠ confirm, strength yếu | Inline error, disable submit |

---

## Edge Cases

- [ ] Code OTP hết hạn → message "Link đặt lại đã hết hạn. Vui lòng thử Quên mật khẩu lại"
- [ ] Password ≠ confirmPassword → inline error
- [ ] Password strength yếu → indicator, có thể block submit (tuỳ BR)
- [ ] Deep-link với code+email → pre-fill từ route args
- [ ] User đóng app giữa chừng → mở lại từ deep-link có thể invalid
- [ ] Network timeout → message thân thiện, cho phép retry

---

## Data Requirements

- **API endpoint**: `POST /api/auth/reset-password`
- **Input**: `{ email: string, code: string, newPassword: string }` (code từ OTP verify)
- **Output**: `{ success: true }` → navigate Login; error: 400 (invalid/expired code)

---

## Sync Notes

- Khi AUTH_ForgotPassword thay đổi → flow VerifyOtp → ResetPassword với email+code.
- Khi AUTH_Login thay đổi → navigate về Login sau success.
- Shared: Password strength widget (giống Register).

---

## Design Context

- **Target audience**: User đã request reset (qua ForgotPassword).
- **Usage context**: Recovery — one-time sau verify OTP.
- **Key UX priority**: Clarity (2 field rõ), Security (password strength).
- **Specific constraints**: Nút "Đặt lại mật khẩu" min 48dp; show/hide password.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | build-plan |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |

---

## Implementation Reference (health_system)

- `lib/features/auth/screens/reset_password_screen.dart`
- Route: `AppRouter.resetPassword` = `/reset-password`
- Predecessor: `ResetOtpVerificationScreen` (verify OTP trước khi vào màn này)
