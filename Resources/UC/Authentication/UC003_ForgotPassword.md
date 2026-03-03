# UC003 - QUÊN MẬT KHẨU

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC003 |
| **Tên UC** | Khôi phục mật khẩu khi quên |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng yêu cầu đặt lại mật khẩu thông qua email khi quên mật khẩu |
| **Trigger** | Người dùng nhấn "Quên mật khẩu?" trên màn hình đăng nhập |
| **Tiền điều kiện** | - Người dùng đã có tài khoản trong hệ thống<br>- Email đăng ký vẫn còn hoạt động |
| **Hậu điều kiện** | - Mật khẩu mới được thiết lập<br>- Email thông báo thay đổi mật khẩu được gửi |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Chọn "Quên mật khẩu?" trên màn hình đăng nhập |
| 2 | Hệ thống | Hiển thị form nhập email |
| 3 | Người dùng | Nhập email đã đăng ký |
| 4 | Người dùng | Nhấn "Gửi yêu cầu" |
| 5 | Hệ thống | Kiểm tra email có tồn tại trong hệ thống |
| 6 | Hệ thống | Gửi email chứa link reset mật khẩu (có hiệu lực 15 phút) |
| 7 | Hệ thống | Hiển thị "Đã gửi email hướng dẫn. Vui lòng kiểm tra hộp thư" |
| 8 | Người dùng | Mở email và nhấn vào link reset |
| 9 | Hệ thống | Xác thực token và hiển thị form đặt mật khẩu mới |
| 10 | Người dùng | Nhập mật khẩu mới và xác nhận mật khẩu |
| 11 | Người dùng | Nhấn "Đặt lại mật khẩu" |
| 12 | Hệ thống | Cập nhật mật khẩu mới và vô hiệu hóa token |
| 13 | Hệ thống | Hiển thị "Đặt lại mật khẩu thành công" và chuyển đến trang đăng nhập |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Email không tồn tại trong hệ thống
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Hiển thị "Đã gửi email hướng dẫn. Vui lòng kiểm tra hộp thư" (không để lộ email không tồn tại - bảo mật) |
| 5.a.2 | Use case kết thúc | |

### 6.a - Email không gửi được (lỗi SMTP)
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Hệ thống | Log lỗi và hiển thị "Có lỗi xảy ra. Vui lòng thử lại sau" |
| 6.a.2 | Người dùng | Thử lại hoặc liên hệ hỗ trợ |

### 9.a - Token đã hết hạn (> 15 phút)
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 9.a.1 | Hệ thống | Hiển thị "Link đã hết hạn. Vui lòng yêu cầu lại" |
| 9.a.2 | Hệ thống | Cung cấp nút "Gửi lại yêu cầu" |

### 9.b - Token không hợp lệ
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 9.b.1 | Hệ thống | Hiển thị "Link không hợp lệ" |
| 9.b.2 | Hệ thống | Chuyển hướng về trang "Quên mật khẩu" |

### 10.a - Mật khẩu mới giống mật khẩu cũ
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 10.a.1 | Hệ thống | Hiển thị "Mật khẩu mới không được giống mật khẩu cũ" |
| 10.a.2 | Người dùng | Nhập mật khẩu khác |

### 10.b - Mật khẩu xác nhận không khớp
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 10.b.1 | Hệ thống | Hiển thị "Mật khẩu xác nhận không khớp" |
| 10.b.2 | Người dùng | Nhập lại |

---

## Business Rules

- **BR-001**: Link reset mật khẩu có hiệu lực 15 phút
- **BR-002**: Token reset chỉ sử dụng được 1 lần
- **BR-003**: Mật khẩu mới phải khác mật khẩu cũ
- **BR-004**: Mật khẩu mới tối thiểu 6 ký tự
- **BR-005**: Không để lộ thông tin email có tồn tại hay không (chống enumeration attack)
- **BR-006**: Giới hạn 3 lần yêu cầu reset/15 phút cho cùng 1 email (chống abuse)

---

## Data Requirements

### Input Data (Bước 3):
| Trường | Kiểu | Bắt buộc | Validation |
|--------|------|----------|------------|
| Email | String | Có | Format email hợp lệ |

### Input Data (Bước 10):
| Trường | Kiểu | Bắt buộc | Validation |
|--------|------|----------|------------|
| Mật khẩu mới | String | Có | Tối thiểu 6 ký tự, khác mật khẩu cũ |
| Xác nhận mật khẩu | String | Có | Phải khớp với mật khẩu mới |

### URL Parameters (Bước 8):
| Tham số | Kiểu | Description |
|---------|------|-------------|
| token | String | JWT token chứa user_id và expiry time |

---

## Yêu cầu phi chức năng

- **Performance**: 
  - Thời gian gửi email < 5 giây
  - Xác thực token < 1 giây
- **Security**: 
  - Token sử dụng JWT với signature
  - Không để lộ thông tin user qua error message
  - Rate limiting: 3 requests/15 phút cho cùng 1 email
  - Token được vô hiệu hóa ngay sau khi sử dụng
- **Usability**: 
  - Email template thân thiện với người cao tuổi (font lớn, hướng dẫn rõ ràng)
  - Hiển thị đồng hồ đếm ngược thời gian còn lại của token
  - Nút "Gửi lại" rõ ràng khi token hết hạn
- **Reliability**: Retry mechanism khi gửi email thất bại (tối đa 3 lần)
