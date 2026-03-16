# 📱 AUTH — Xác minh Email (Verify Email)

> **UC Ref**: UC002
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Nhập mã OTP 6 chữ số gửi qua email để xác thực tài khoản sau đăng ký. Hỗ trợ deep-link: khi user bấm link trong email (có `?code=xxx`), app mở và pre-fill OTP.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [AUTH_Register](./AUTH_Register.md) | Đăng ký thành công | → This screen |
| [AUTH_Login](./AUTH_Login.md) | SnackBar "Xác thực" (unverified) | → This screen |
| *Deep link* | `verify-email?code=xxx&email=yyy` | → This screen |
| This screen | Xác thực thành công | → [AUTH_Login](./AUTH_Login.md) |

---

## User Flow

1. Nhập 6 chữ số OTP (hoặc nhận từ deep-link).
2. Bấm "Xác thực" → API verifyEmail.
3. **Success** → SnackBar xanh → `pushNamedAndRemoveUntil(login)`.
4. **Fail** → SnackBar đỏ.
5. "Gửi lại mã" → resendVerificationToken, countdown 60s.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang gọi API verify | CircularProgressIndicator, disable button |
| Idle | Form sẵn sàng nhập OTP | 6-digit input, "Xác thực", "Gửi lại mã" |
| Success | Xác thực thành công | SnackBar xanh → navigate Login |
| Error | OTP sai / hết hạn | SnackBar đỏ, form giữ giá trị |
| Resend Countdown | Đang đếm 60s trước khi gửi lại | "Gửi lại mã" disabled, hiển thị "60s" |
| Deep-link Prefill | Nhận code từ deep-link | OTP field đã điền sẵn, user chỉ cần bấm "Xác thực" |

---

## Edge Cases

- [ ] OTP hết hạn → message "Mã đã hết hạn. Vui lòng gửi lại"
- [ ] OTP sai 3+ lần → có thể rate limit (tuỳ backend)
- [ ] Deep-link khi app đang chạy → `getLinks` / `getInitialLink` → parse `?code=&email=` → pre-fill
- [ ] App mở từ background qua deep-link → handle `getInitialLink` khi resume
- [ ] User đóng app trước khi verify → mở lại từ Login → SnackBar "Xác thực" vẫn có
- [ ] Email không hiển thị (chỉ nhận từ args) → có thể hiển thị "Mã đã gửi đến ***@gmail.com" (masked)

---

## Data Requirements

- **API endpoint**: `POST /api/auth/verify-email`; `POST /api/auth/resend-verification`
- **Input**: `{ email: string, code: string }` (code 6 digits)
- **Output**: `{ success: true }` → navigate Login; error: 400 (invalid/expired code)

---

## Sync Notes

- Khi AUTH_Register thay đổi → arguments `{email}` được truyền qua.
- Khi AUTH_Login thay đổi → SnackBar "Xác thực" navigate với `email`.
- Deep-link scheme: `app://verify-email?code=xxx&email=yyy` — cấu hình trong `app.dart` _handleDeepLink.

---

## Design Context

- **Target audience**: User mới vừa đăng ký hoặc User chưa verify.
- **Usage context**: One-time verification sau register; có thể lặp nếu chưa verify.
- **Key UX priority**: Clarity (6 ô OTP rõ), Speed (deep-link pre-fill giảm thao tác).
- **Specific constraints**: OTP input có thể dùng package (pin_code_fields); nút "Gửi lại mã" min 48dp.

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

- `lib/features/auth/screens/email_verification_screen.dart`
- Route: `AppRouter.verifyEmail` = `/verify-email`
- Deep-link: `app.dart` _handleDeepLink → verifyEmail với code, email
