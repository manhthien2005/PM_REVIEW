# UC004 - THAY ĐỔI MẬT KHẨU

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC004 |
| **Tên UC** | Thay đổi mật khẩu |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng đã đăng nhập thay đổi mật khẩu của mình |
| **Trigger** | Người dùng chọn "Đổi mật khẩu" trong phần Cài đặt tài khoản |
| **Tiền điều kiện** | - Người dùng đã đăng nhập vào hệ thống<br>- Session còn hiệu lực |
| **Hậu điều kiện** | - Mật khẩu được cập nhật<br>- Email thông báo thay đổi mật khẩu được gửi<br>- Tất cả session cũ (trừ session hiện tại) bị vô hiệu hóa |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập phần "Cài đặt" > "Bảo mật" |
| 2 | Hệ thống | Hiển thị tùy chọn "Đổi mật khẩu" |
| 3 | Người dùng | Chọn "Đổi mật khẩu" |
| 4 | Hệ thống | Hiển thị form đổi mật khẩu |
| 5 | Người dùng | Nhập mật khẩu hiện tại, mật khẩu mới, xác nhận mật khẩu mới |
| 6 | Người dùng | Nhấn "Cập nhật mật khẩu" |
| 7 | Hệ thống | Xác thực mật khẩu hiện tại |
| 8 | Hệ thống | Kiểm tra mật khẩu mới hợp lệ |
| 9 | Hệ thống | Cập nhật mật khẩu mới vào database |
| 10 | Hệ thống | Vô hiệu hóa tất cả session cũ (trừ session hiện tại) |
| 11 | Hệ thống | Gửi email thông báo thay đổi mật khẩu thành công |
| 12 | Hệ thống | Hiển thị "Đổi mật khẩu thành công" |

---

## Luồng thay thế (Alternative Flows)

### 7.a - Mật khẩu hiện tại không đúng
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 7.a.1 | Hệ thống | Hiển thị "Mật khẩu hiện tại không đúng" |
| 7.a.2 | Hệ thống | Cho phép nhập lại (tối đa 3 lần/phiên) |
| 7.a.3 | Nếu sai 3 lần | Đăng xuất người dùng và yêu cầu đăng nhập lại |

### 8.a - Mật khẩu mới giống mật khẩu hiện tại
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 8.a.1 | Hệ thống | Hiển thị "Mật khẩu mới phải khác mật khẩu hiện tại" |
| 8.a.2 | Người dùng | Nhập mật khẩu mới khác |

### 8.b - Mật khẩu mới không đủ mạnh
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 8.b.1 | Hệ thống | Hiển thị "Mật khẩu phải có ít nhất 6 ký tự" |
| 8.b.2 | Người dùng | Nhập mật khẩu mạnh hơn |

### 8.c - Mật khẩu xác nhận không khớp
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 8.c.1 | Hệ thống | Hiển thị "Mật khẩu xác nhận không khớp" |
| 8.c.2 | Người dùng | Nhập lại |

### 11.a - Email không gửi được
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 11.a.1 | Hệ thống | Log lỗi nhưng vẫn hoàn thành việc đổi mật khẩu |
| 11.a.2 | Hệ thống | Hiển thị warning "Đổi mật khẩu thành công nhưng không thể gửi email thông báo" |

---

## Business Rules

- **BR-001**: Mật khẩu mới phải khác mật khẩu hiện tại
- **BR-002**: Mật khẩu mới tối thiểu 6 ký tự
- **BR-003**: Phải nhập đúng mật khẩu hiện tại mới được đổi
- **BR-004**: Giới hạn 3 lần nhập sai mật khẩu hiện tại trong 1 phiên
- **BR-005**: Sau khi đổi mật khẩu, tất cả session cũ (web, mobile) bị đăng xuất (trừ session hiện tại)
- **BR-006**: Email thông báo phải được gửi để cảnh báo về hoạt động thay đổi mật khẩu

---

## Data Requirements

### Input Data:
| Trường | Kiểu | Bắt buộc | Validation |
|--------|------|----------|------------|
| Mật khẩu hiện tại | String | Có | Phải khớp với mật khẩu trong DB |
| Mật khẩu mới | String | Có | Tối thiểu 6 ký tự, khác mật khẩu hiện tại |
| Xác nhận mật khẩu mới | String | Có | Phải khớp với mật khẩu mới |

---

## Yêu cầu phi chức năng

- **Performance**: 
  - Thời gian cập nhật mật khẩu < 2 giây
  - Vô hiệu hóa session cũ < 1 giây
- **Security**: 
  - Mật khẩu được hash bằng bcrypt trước khi lưu
  - Yêu cầu xác thực mật khẩu hiện tại trước khi đổi
  - Tất cả session cũ bị vô hiệu hóa (chống session hijacking)
  - Rate limiting: 5 lần thử/15 phút cho cùng 1 user
  - Email cảnh báo gửi đến địa chỉ email đã đăng ký
- **Usability**: 
  - Hiển thị độ mạnh của mật khẩu mới (weak/medium/strong)
  - Toggle show/hide password
  - Real-time validation khi người dùng nhập
  - Hiển thị danh sách yêu cầu mật khẩu (ít nhất 6 ký tự, v.v.)
- **Auditability**: Log hoạt động thay đổi mật khẩu (user_id, timestamp, IP address, device)

---

## Mối quan hệ với UC khác

- **Extends UC001 (Login)**: Sau khi đổi mật khẩu thành công, người dùng có thể đăng nhập bằng mật khẩu mới
- **Khác với UC003 (Forgot Password)**: UC004 yêu cầu người dùng đã đăng nhập và phải nhập mật khẩu hiện tại
