# 📱 AUTH — Quên mật khẩu (Forgot Password)

> **UC Ref**: UC003
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Nhập email để nhận OTP đặt lại mật khẩu. Gửi request → Backend gửi email OTP → Chuyển sang màn xác thực OTP (ResetOtpVerificationScreen) rồi ResetPassword.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [AUTH_Login](./AUTH_Login.md) | Bấm "Quên mật khẩu" | → This screen |
| This screen | Gửi OTP thành công | → OTP Verification → [AUTH_ResetPassword](./AUTH_ResetPassword.md) |
| This screen | Bấm Back | → [AUTH_Login](./AUTH_Login.md) |

---

## User Flow

1. Nhập email.
2. Bấm "Gửi mã" → API forgotPassword.
3. **Success** → `pushReplacementNamed(verifyResetOtp, arguments: {email})`.
4. **Fail** → SnackBar đỏ.

> **Ghi chú**: App có màn `ResetOtpVerificationScreen` (verify OTP) giữa ForgotPassword và ResetPassword. Deep-link reset-password cũng vào verifyResetOtp.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang gọi API forgotPassword | CircularProgressIndicator, disable button |
| Idle | Form sẵn sàng nhập | Email field, "Gửi mã" |
| Success | OTP đã gửi | Navigate → ResetOtpVerificationScreen |
| Error | Email không tồn tại, rate limit | SnackBar đỏ (message chung để không lộ email) |

---

## Edge Cases

- [ ] Email không tồn tại → message chung "Nếu email tồn tại, bạn sẽ nhận mã" (security: không tiết lộ)
- [ ] Rate limit (gửi quá nhiều lần) → message "Vui lòng thử lại sau X phút"
- [ ] Network timeout → message thân thiện, cho phép retry
- [ ] User nhập sai email → vẫn hiển thị success (không lộ) → user vào VerifyOtp nhưng không nhận được email
- [ ] Deep-link reset-password → có thể bypass ForgotPassword nếu có code+email trong URL

---

## Data Requirements

- **API endpoint**: `POST /api/auth/forgot-password`
- **Input**: `{ email: string }`
- **Output**: `{ success: true }` (luôn trả success để không lộ email); error: 429 (rate limit)

---

## Sync Notes

- Khi AUTH_ResetPassword thay đổi → flow ForgotPassword → VerifyOtp → ResetPassword.
- ResetOtpVerificationScreen không có spec riêng — có thể tạo hoặc gộp logic vào AUTH_ResetPassword.
- Khi AUTH_Login thay đổi → link "Quên mật khẩu" giữ nguyên.

---

## Design Context

- **Target audience**: User quên mật khẩu.
- **Usage context**: Recovery — không thường xuyên.
- **Key UX priority**: Clarity (chỉ cần email), Trust (không lộ thông tin).
- **Specific constraints**: Nút "Gửi mã" min 48dp; Back rõ ràng để quay Login.

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

- `lib/features/auth/screens/forgot_password_screen.dart`
- Route: `AppRouter.forgotPassword` = `/forgot-password`
- Next: `AppRouter.verifyResetOtp` → ResetOtpVerificationScreen → ResetPasswordScreen
