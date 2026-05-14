# UC009 - ĐĂNG XUẤT (v2 — confirmed Phase 0.5)

> **Version:** v2 (Phase 0.5 wave HealthGuard, 2026-05-12)
> **Supersedes:** `UC009_Logout.md` (v1)
> **Status:**
> - Admin Web section: 🟢 Confirmed (anh react 2026-05-12)
> - Mobile App section: 🟡 TBD (chờ Phase 0.5 wave 5 mobile review)

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|---|---|
| **Mã UC** | UC009 |
| **Tên UC** | Đăng xuất khỏi hệ thống |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc, Quản trị viên |
| **Mô tả** | Người dùng đăng xuất khỏi hệ thống. Tất cả token (access + refresh) bị vô hiệu hóa server-side ngay lập tức thông qua `token_version` increment. |
| **Trigger** | Người dùng chọn "Đăng xuất" trong menu |
| **Tiền điều kiện** | Người dùng đã đăng nhập (token hợp lệ) |
| **Hậu điều kiện** | - `token_version` được tăng → mọi token cũ invalid<br>- Audit log ghi event<br>- Người dùng được chuyển về màn hình đăng nhập<br>- Mobile: FCM token bị hủy đăng ký |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 1 | Người dùng | Chọn "Cài đặt" → "Đăng xuất" |
| 2 | Hệ thống | Hiển thị popup xác nhận<br>**Mobile (cho bệnh nhân):** kèm cảnh báo "Sau khi đăng xuất, bạn sẽ không nhận được thông báo khẩn cấp trên thiết bị này"<br>**Admin:** popup đơn giản |
| 3 | Người dùng | Xác nhận "Có" |
| 4 | Hệ thống | Mobile: Hủy đăng ký FCM push token cho thiết bị hiện tại |
| 5 | Hệ thống | **Tăng `token_version`** trong DB cho user hiện tại → mọi token cũ (access + refresh) bị invalid ngay lập tức |
| 6 | Hệ thống | Admin: Clear httpOnly cookie (`Set-Cookie: token=; Max-Age=0`)<br>Mobile: Xóa secure storage |
| 7 | Hệ thống | Ghi audit log với `action = 'user.logout'` |
| 8 | Hệ thống | Chuyển về màn hình đăng nhập |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Hủy đăng xuất

| Bước | Hành động |
|---|---|
| 3.a.1 | Người dùng chọn "Hủy" |
| 3.a.2 | Hệ thống đóng popup, giữ nguyên session |

### 4.a - Đăng xuất tất cả thiết bị (🟢 Confirmed Phase 0.5)

| Bước | Hành động |
|---|---|
| 4.a.1 | Người dùng chọn "Đăng xuất tất cả thiết bị" trong Settings |
| 4.a.2 | Hệ thống hiển thị popup confirm với cảnh báo "Mọi phiên đăng nhập trên các thiết bị khác sẽ bị hủy" |
| 4.a.3 | Hệ thống tăng `token_version` (cùng logic với main flow step 5) |
| 4.a.4 | Mobile: Hủy mọi FCM token của user trên mọi devices |
| 4.a.5 | Ghi audit log với `action = 'user.logout_all'` + chi tiết số lượng session bị hủy |
| 4.a.6 | Chuyển về màn hình đăng nhập trên thiết bị hiện tại |

### 5.a - Lỗi khi gọi server (mất kết nối)

| Bước | Hành động |
|---|---|
| 5.a.1 | Hệ thống không gửi được request đến server |
| 5.a.2 | Mobile: Xóa secure storage local, đánh dấu "pending logout" |
| 5.a.3 | Lần đăng nhập tiếp theo, FE gửi request `pending_logout` để server tăng token_version |
| 5.a.4 | Admin: Clear cookie locally, redirect login (không có "pending logout" — admin assume online) |

---

## Business Rules

### Common (cả Admin + Mobile)

- **BR-009-01**: Logout phải tăng `token_version` trong DB → mọi token cũ invalid ngay lập tức (không chờ expire)
- **BR-009-02**: Middleware `authenticate` đã check `token_version` match giữa JWT payload và DB → tự động reject token cũ
- **BR-009-03**: Audit log với `action = 'user.logout'` hoặc `user.logout_all`
- **BR-009-04**: "Logout all devices" endpoint riêng (`POST /auth/logout-all`)

### Admin Web (🟢 Confirmed Phase 0.5)

- **BR-009-A1**: Clear httpOnly cookie (`Set-Cookie: token=; Max-Age=0; HttpOnly; Secure`)
- **BR-009-A2**: Không có FCM token (admin web không có push notification)
- **BR-009-A3**: Logout endpoint trả 200 OK (idempotent — gọi nhiều lần OK)

### Mobile App (🟡 TBD wave 5)

- **BR-009-M1**: Hủy FCM token để không nhận push notification trên thiết bị đó (TBD verify implementation)
- **BR-009-M2**: Refresh token cũng bị invalidate qua `token_version` (TBD verify)
- **BR-009-M3**: Popup xác nhận cho bệnh nhân phải cảnh báo về việc mất thông báo khẩn cấp (TBD verify)

---

## Yêu cầu phi chức năng

- **Security**:
  - Token thực sự bị vô hiệu hóa server-side qua `token_version` (không chỉ xóa local)
  - Logout endpoint phải có rate limiter để chống abuse
- **Usability**:
  - Nút đăng xuất dễ tìm trong Settings
  - "Logout all devices" hiện ở Settings → Security
- **Performance**: Đăng xuất < 1 giây (1 DB write + 1 audit log)
- **Safety** (Mobile): Cảnh báo rõ ràng cho bệnh nhân về mất thông báo khẩn cấp

---

## Mối quan hệ với UC khác

- **UC001 (Login)**: Reverse — UC009 hủy session mà UC001 tạo
- **UC004 (Change Password)**: Mobile-only — sau khi đổi password, các session cũ bị logout tự động (cùng cơ chế `token_version`)
- **UC022 (Manage Users)**: Admin có thể force logout user khác qua endpoint riêng (UC022 scope, không phải UC009)

---

## Phase 0.5 Decisions Log

| Decision ID | Detail | Date |
|---|---|---|
| D-AUTH-03 | Token version increment on logout (immediate invalidation) | 2026-05-12 |
| D-AUTH-04 | Logout-all endpoint riêng (`POST /auth/logout-all`) | 2026-05-12 |

---

## Implementation Reference (Admin BE)

- Logout endpoint: `POST /api/v1/admin/auth/logout` (`auth.routes.js`)
- Service: `auth.service.js logoutUser()` — **CẦN UPDATE** thêm token_version increment (Phase 4 task)
- Logout-all endpoint: `POST /api/v1/admin/auth/logout-all` — **CẦN IMPLEMENT** (Phase 4 task)
- Middleware: `auth.js authenticate` (đã check token_version)
- Reference patterns: R1 (JWT + token_version DB roundtrip)
