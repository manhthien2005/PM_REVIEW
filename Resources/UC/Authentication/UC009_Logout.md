# UC009 - ĐĂNG XUẤT

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC009 |
| **Tên UC** | Đăng xuất khỏi hệ thống |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc, Quản trị viên |
| **Mô tả** | Người dùng đăng xuất khỏi hệ thống, hủy phiên đăng nhập hiện tại |
| **Trigger** | Người dùng chọn "Đăng xuất" trong menu cài đặt |
| **Tiền điều kiện** | Người dùng đã đăng nhập |
| **Hậu điều kiện** | - JWT token bị vô hiệu hóa<br>- Người dùng được chuyển về màn hình đăng nhập<br>- Push notification token bị hủy đăng ký |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Chọn "Cài đặt" → "Đăng xuất" |
| 2 | Hệ thống | Hiển thị popup xác nhận "Bạn có chắc muốn đăng xuất?" (kèm cảnh báo cho bệnh nhân: "Sau khi đăng xuất, bạn sẽ không nhận được thông báo khẩn cấp trên thiết bị này") |
| 3 | Người dùng | Xác nhận "Có" |
| 4 | Hệ thống | Hủy đăng ký FCM push token cho thiết bị hiện tại |
| 5 | Hệ thống | Vô hiệu hóa refresh token hiện tại (Mobile) hoặc access token (Admin) |
| 6 | Hệ thống | Xóa dữ liệu session local (secure storage) |
| 7 | Hệ thống | Chuyển về màn hình đăng nhập |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Hủy đăng xuất
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Người dùng | Chọn "Hủy" |
| 3.a.2 | Hệ thống | Đóng popup, giữ nguyên session |

### 4.a - Đăng xuất tất cả thiết bị
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Người dùng | Chọn "Đăng xuất tất cả thiết bị" |
| 4.a.2 | Hệ thống | Vô hiệu hóa tất cả refresh tokens + FCM tokens của user |
| 4.a.3 | Hệ thống | Ghi audit log với chi tiết số lượng session bị hủy |
| 4.a.4 | Hệ thống | Chuyển về màn hình đăng nhập |

### 5.a - Lỗi khi vô hiệu hóa token (mất kết nối)
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Không gửi được request hủy token đến server |
| 5.a.2 | Hệ thống | Xóa dữ liệu local, chuyển về đăng nhập |
| 5.a.3 | Hệ thống | Đánh dấu "pending logout" — lần đăng nhập tiếp theo sẽ hủy token cũ |

---

## Business Rules

- **BR-009-01**: Đăng xuất phải hủy FCM token để không nhận push notification trên thiết bị đó
- **BR-009-02**: Mobile: vô hiệu hóa refresh token (token rotation ngăn reuse)
- **BR-009-03**: Admin: vô hiệu hóa access token (blacklist hoặc xóa khỏi whitelist)
- **BR-009-04**: Ghi audit log với `action = 'user.logout'`
- **BR-009-05**: Popup xác nhận cho bệnh nhân phải cảnh báo về việc mất thông báo khẩn cấp

---

## Yêu cầu phi chức năng

- **Security**: Token phải thực sự bị vô hiệu hóa server-side (không chỉ xóa local)
- **Usability**: Nút đăng xuất dễ tìm trong Settings, không bị nhầm lẫn
- **Performance**: Đăng xuất < 1 giây
- **Safety**: Cảnh báo rõ ràng rằng đăng xuất = mất thông báo khẩn cấp cho bệnh nhân

---

## Mối quan hệ với UC khác

- **Reverse của UC001 (Login)**: Đăng xuất hủy session mà UC001 tạo ra
- **Liên quan UC004 (Change Password)**: Sau khi đổi mật khẩu, các session cũ bị đăng xuất tự động
- **Platform**: Áp dụng cho cả Mobile App và Admin Web
