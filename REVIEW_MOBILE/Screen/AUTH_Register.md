# 📱 AUTH — Đăng ký (Register)

> **UC Ref**: UC002
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Màn hình đăng ký tài khoản mới. Thu thập email, họ tên, mật khẩu, xác nhận mật khẩu, số điện thoại (optional), ngày sinh. Có password strength indicator và đồng ý Điều khoản.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [AUTH_Login](./AUTH_Login.md) | Bấm "Đăng ký" | → This screen |
| This screen | Đăng ký thành công | → [AUTH_VerifyEmail](./AUTH_VerifyEmail.md) |
| This screen | Bấm "Đã có tài khoản" / Back | → [AUTH_Login](./AUTH_Login.md) |

---

## User Flow

1. Nhập email, fullName, password, confirmPassword, phone (optional), dateOfBirth.
2. Tick đồng ý Điều khoản & Chính sách Bảo mật.
3. Bấm "Đăng ký" → API register.
4. **Success** → `pushReplacementNamed(verifyEmail, arguments: {email})`.
5. **Fail** → SnackBar.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang gọi API register | CircularProgressIndicator, disable button |
| Idle | Form sẵn sàng nhập | Các field, checkbox Điều khoản, "Đăng ký" |
| Success | Đăng ký thành công | Navigate → VerifyEmail |
| Error | Email trùng, validation fail | SnackBar đỏ, form giữ giá trị |
| Validation Error | Password không khớp, chưa tick Điều khoản | Inline error, disable submit |

---

## Edge Cases

- [ ] Email đã tồn tại → message "Email này đã được đăng ký"
- [ ] Password ≠ confirmPassword → inline error, không gọi API
- [ ] Chưa tick Điều khoản → disable "Đăng ký", hoặc SnackBar nhắc
- [ ] Network timeout → message thân thiện, cho phép retry
- [ ] Password strength yếu → indicator đỏ/vàng; có thể cho phép submit nhưng cảnh báo (tuỳ BR)
- [ ] Back từ VerifyEmail → Login có thể nhận `registeredEmail` để pre-fill

---

## Data Requirements

- **API endpoint**: `POST /api/auth/register`
- **Input**: `{ email, fullName, password, confirmPassword?, phone?, dateOfBirth? }` — Role mặc định `user` (backend hardcode, không gửi từ client)
- **Output**: `{ success: true }` → navigate VerifyEmail; error: 409 (email exists), 400 (validation)

---

## Sync Notes

- Khi AUTH_VerifyEmail thay đổi → cập nhật arguments `{email}` khi pushReplacementNamed.
- Khi AUTH_Login thay đổi → có thể nhận `registeredEmail` khi pop để pre-fill email.
- Shared: Password strength widget, validation logic.

---

## Design Context

- **Target audience**: User mới — chưa có tài khoản.
- **Usage context**: Setup — one-time registration.
- **Key UX priority**: Clarity (form rõ ràng), Trust (Điều khoản rõ).
- **Specific constraints**: Form dài → scroll; checkbox Điều khoản min 48dp; link Điều khoản mở webview/in-app browser.

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

- `lib/features/auth/screens/register_screen.dart`
- Route: `AppRouter.register` = `/register`
- Return: Login nhận `registeredEmail` khi pop để pre-fill email.
