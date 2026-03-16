# 📱 AUTH — Đăng nhập (Login)

> **UC Ref**: UC001
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Màn hình đăng nhập với email + mật khẩu. Xử lý login thành công → Dashboard, unverified email → VerifyEmail, và các link sang Register, ForgotPassword.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [AUTH_Splash](./AUTH_Splash.md) | Bấm "Bắt đầu ngay" / Swipe | → This screen |
| This screen | Đăng nhập thành công | → [HOME_Dashboard](./HOME_Dashboard.md) |
| This screen | Bấm "Đăng ký" | → [AUTH_Register](./AUTH_Register.md) |
| This screen | Bấm "Quên mật khẩu" | → [AUTH_ForgotPassword](./AUTH_ForgotPassword.md) |
| This screen | Email chưa xác thực (SnackBar "Xác thực") | → [AUTH_VerifyEmail](./AUTH_VerifyEmail.md) |

---

## User Flow

1. Nhập email, mật khẩu.
2. Bấm "Đăng nhập" → gọi API login.
3. **Success** → `Navigator.pushNamedAndRemoveUntil(dashboard)`.
4. **Unverified email** → SnackBar với action "Xác thực" → Resend token + navigate VerifyEmail.
5. **Lỗi khác** → SnackBar đỏ.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang gọi API login | CircularProgressIndicator, disable button |
| Idle | Form sẵn sàng nhập | Email + password fields, "Đăng nhập", links |
| Success | Login thành công | Navigate away (không hiển thị) |
| Error | Sai email/password, tài khoản khóa | SnackBar đỏ, form vẫn hiển thị |
| Unverified | Email chưa xác thực | SnackBar với action "Xác thực" → VerifyEmail |
| Rate Limited | 5 lần sai trong 15 phút | SnackBar "Tạm khoá trong 15 phút", disable button |

---

## Edge Cases

- [ ] Sai mật khẩu 5 lần liên tiếp → backend block 15 phút → hiển thị message "Tạm khoá trong 15 phút"
- [ ] Tài khoản bị khóa (`is_active=false`) → message "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên"
- [ ] Email không tồn tại → message chung "Email hoặc mật khẩu không đúng" (không tiết lộ)
- [ ] Network timeout / mất mạng → message thân thiện, cho phép retry
- [ ] Admin cố login trên mobile → message "Tài khoản admin chỉ đăng nhập trên Web Admin"
- [ ] Token hết hạn giữa session → redirect về Login (xử lý ở interceptor)

---

## Data Requirements

- **API endpoint**: `POST /api/auth/login` (hoặc tương đương)
- **Input**: `{ email: string, password: string }`
- **Output**: `{ token: string, user: {...} }` hoặc `{ verified: false }` → VerifyEmail; error codes: 401, 403 (locked), 429 (rate limit)

---

## Sync Notes

- Khi AUTH_Register thay đổi → link "Đăng ký" giữ nguyên; có thể nhận `registeredEmail` khi pop để pre-fill.
- Khi AUTH_VerifyEmail thay đổi → SnackBar "Xác thực" navigate với `email` argument.
- Shared: Form validation (email format, password non-empty).

---

## Design Context

- **Target audience**: Tất cả User (không phân patient/caregiver — unified role).
- **Usage context**: Routine — mỗi lần mở app chưa login.
- **Key UX priority**: Clarity (error message rõ), Speed (response < 2s).
- **Specific constraints**: Nút "Quên mật khẩu" min 48dp; icon show/hide password; không lộ thông tin nhạy cảm trong error.

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

- `lib/features/auth/screens/login_screen.dart`
- Route: `AppRouter.login` = `/login`
- Links: Register (pushNamed), ForgotPassword (pushNamed), Dashboard (pushNamedAndRemoveUntil)
