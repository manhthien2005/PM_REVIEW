# UC001 - ĐĂNG NHẬP (v2 — confirmed Phase 0.5)

> **Version:** v2 (Phase 0.5 wave HealthGuard, 2026-05-12)
> **Supersedes:** `UC001_Login.md` (v1)
> **Status:**
> - Admin Web section: 🟢 Confirmed (anh react 2026-05-12)
> - Mobile App section: 🟡 TBD (chờ Phase 0.5 wave 5 mobile review)

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|---|---|
| **Mã UC** | UC001 |
| **Tên UC** | Đăng nhập vào hệ thống |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc, Quản trị viên |
| **Mô tả** | Người dùng đăng nhập vào hệ thống bằng email và mật khẩu để truy cập các chức năng theo phân quyền |
| **Trigger** | Người dùng nhấn nút "Đăng nhập" trên ứng dụng |
| **Tiền điều kiện** | - Người dùng đã có tài khoản trong hệ thống<br>- Tài khoản chưa bị khóa (`is_active = true`, `locked_until` không trong tương lai) |
| **Hậu điều kiện** | - Người dùng được xác thực và chuyển đến Dashboard<br>- Session được tạo với JWT token (cookie cho Admin, secure storage cho Mobile)<br>- `failed_login_attempts` reset về 0 |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 1 | Người dùng | Chọn chức năng "Đăng nhập" |
| 2 | Hệ thống | Hiển thị form đăng nhập (email, password) |
| 3 | Người dùng | Nhập email và mật khẩu |
| 4 | Người dùng | Nhấn "Đăng nhập" |
| 5 | Hệ thống | Validate input (email format, password ≥ 8 chars) |
| 6 | Hệ thống | Kiểm tra rate limit per IP (5 fail/15 phút) |
| 7 | Hệ thống | Kiểm tra email tồn tại + tài khoản active + chưa locked |
| 8 | Hệ thống | Verify password (bcrypt compare) |
| 9 | Hệ thống | Tạo JWT token với `token_version` hiện tại của user |
| 10 | Hệ thống | Ghi audit log (success) |
| 11 | Hệ thống | Reset `failed_login_attempts = 0` |
| 12 | Hệ thống | Trả token về client (admin: httpOnly cookie; mobile: response body) |
| 13 | Hệ thống | Chuyển hướng đến Dashboard tương ứng vai trò |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Validation fail (email format hoặc password < 8 chars)

| Bước | Hành động |
|---|---|
| 5.a.1 | Hệ thống hiển thị lỗi validation, không gọi API |

### 6.a - Rate limit per IP exceeded

| Bước | Hành động |
|---|---|
| 6.a.1 | Hệ thống trả 429 Too Many Requests |
| 6.a.2 | Hiển thị "Quá nhiều lần thử. Vui lòng đợi 15 phút." |

### 7.a - Email không tồn tại HOẶC password sai

| Bước | Hành động |
|---|---|
| 7.a.1 | Hệ thống tăng `failed_login_attempts` cho user (nếu email tồn tại) |
| 7.a.2 | Nếu `failed_login_attempts ≥ 5`: set `locked_until = now() + 15 phút` |
| 7.a.3 | Ghi audit log với reason `invalid_credentials` |
| 7.a.4 | Trả lỗi generic "Email hoặc mật khẩu không đúng" (không lộ email tồn tại hay không) |

### 7.b - Tài khoản bị locked (locked_until trong tương lai)

| Bước | Hành động |
|---|---|
| 7.b.1 | Ghi audit log reason `account_locked` |
| 7.b.2 | Trả 423 Locked với "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên." |

### 7.c - Tài khoản inactive (is_active = false)

| Bước | Hành động |
|---|---|
| 7.c.1 | Trả "Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên." |

---

## Business Rules

### Common (cả Admin + Mobile)

- **BR-001-01**: Mật khẩu phải được hash với bcrypt (salt cost ≥ 10)
- **BR-001-04**: **Defense-in-depth lockout** — 2 layers:
  - **Per USER**: 5 lần fail liên tiếp → lock 15 phút (`failed_login_attempts` + `locked_until`)
  - **Per IP**: rate limiter ở route level (5 requests/15 phút/IP) — chống credential stuffing đa-account
- **BR-001-05**: Mật khẩu tối thiểu 8 ký tự
- **BR-001-06**: Audit log mọi attempt (success + fail) với `user_id, ip, user_agent, status, reason, timestamp`
- **BR-001-07**: Generic error message — không lộ email tồn tại hay không (chống user enumeration)
- **BR-001-08**: JWT payload bao gồm `token_version` để hỗ trợ logout invalidation (xem UC009)

### Admin Web (🟢 Confirmed Phase 0.5)

- **BR-001-A1**: JWT secret riêng cho admin BE (không share với mobile BE)
- **BR-001-A2**: Token expiry: **8 giờ** (access only, không có refresh token cho admin)
- **BR-001-A3**: JWT issuer: `healthguard-admin`
- **BR-001-A4**: Role: `ADMIN` only
- **BR-001-A5**: Token storage: **httpOnly cookie** với `Secure; SameSite=Strict` (không localStorage)
- **BR-001-A6**: CSRF token bắt buộc cho mọi mutating request (Q5 decision)

### Mobile App (🟡 TBD wave 5)

- **BR-001-M1**: JWT secret riêng cho mobile BE (TBD)
- **BR-001-M2**: Access token 30 ngày + refresh token 90 ngày (rotation) (TBD verify)
- **BR-001-M3**: JWT issuer: `healthguard-mobile`
- **BR-001-M4**: Roles: `PATIENT`, `CAREGIVER` (TBD verify)
- **BR-001-M5**: Token storage: secure storage (Keychain iOS / Keystore Android) (TBD verify)

---

## Yêu cầu phi chức năng

- **Performance**: Thời gian phản hồi < 2 giây
- **Security**:
  - Mật khẩu không được log ra console/file
  - Bcrypt salt ≥ 10 (admin BE hiện tại = 10, consider bump 12 trong Phase 4+)
  - Token không xuất hiện trong URL query
- **Usability**:
  - Hiển thị/ẩn mật khẩu khi click icon "con mắt"
  - Lỗi validation hiển thị inline, không cần submit form

---

## Mối quan hệ với UC khác

- **UC009 (Logout)**: Reverse — UC009 invalidate session/token mà UC001 tạo
- **UC003 (Forgot Password)**: Mobile-only flow (Phase 0.5 confirmed admin KHÔNG có)
- **UC004 (Change Password)**: Mobile-only flow (Phase 0.5 confirmed admin KHÔNG có)
- **UC022 (Manage Users)**: Admin tạo user mới qua endpoint riêng (không phải UC001)

---

## Phase 0.5 Decisions Log

| Decision ID | Detail | Date |
|---|---|---|
| D-AUTH-02 | Lockout granularity = cả 2 (per USER + per IP) | 2026-05-12 |
| D-AUTH-05 | Admin frontend: httpOnly cookie + CSRF (không localStorage) | 2026-05-12 |
| D-AUTH-08 | Hide/show password icon: keep | 2026-05-12 |

---

## Implementation Reference (Admin BE)

- Login endpoint: `POST /api/v1/admin/auth/login` (`auth.routes.js`)
- Service: `auth.service.js loginUser()` (lockout + audit log)
- Middleware: `auth.js authenticate` (token_version DB roundtrip)
- Reference patterns: R1 (JWT + token_version), R3 (login lockout)
