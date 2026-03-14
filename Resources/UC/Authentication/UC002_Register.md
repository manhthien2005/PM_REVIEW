# UC002 - ĐĂNG KÝ TÀI KHOẢN

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                      |
| ------------------ | ----------------------------------------------------------------------------- |
| **Mã UC**          | UC002                                                                         |
| **Tên UC**         | Đăng ký tài khoản mới                                                         |
| **Tác nhân chính** | User                                                                          |
| **Mô tả**          | Người dùng tạo tài khoản mới để sử dụng hệ thống                              |
| **Trigger**        | Người dùng nhấn "Đăng ký" trên màn hình đăng nhập                             |
| **Tiền điều kiện** | Người dùng chưa có tài khoản                                                  |
| **Hậu điều kiện**  | - Tài khoản được tạo và kích hoạt<br>- Email xác nhận được gửi đến người dùng |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                  |
| ---- | --------------- | -------------------------------------------------------------------------- |
| 1    | Người dùng      | Chọn "Đăng ký tài khoản mới"                                               |
| 2    | Hệ thống        | Hiển thị form đăng ký                                                      |
| 3    | Người dùng      | Nhập thông tin: Email, Mật khẩu, Họ tên, Số điện thoại, Ngày sinh          |
| 4    | Người dùng      | Chấp nhận điều khoản sử dụng và nhấn "Đăng ký"                             |
| 5    | Hệ thống        | Kiểm tra thông tin hợp lệ (email chưa tồn tại, mật khẩu đủ mạnh)           |
| 6    | Hệ thống        | Tạo tài khoản và gửi email xác thực                                        |
| 7    | Hệ thống        | Hiển thị "Đăng ký thành công" và chuyển đến trang đăng nhập                |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Email đã tồn tại
| Bước  | Người thực hiện | Hành động                             |
| ----- | --------------- | ------------------------------------- |
| 5.a.1 | Hệ thống        | Hiển thị "Email đã được sử dụng"      |
| 5.a.2 | Người dùng      | Nhập email khác hoặc chọn "Đăng nhập" |

### 5.b - Mật khẩu không đủ mạnh
| Bước  | Người thực hiện | Hành động                                   |
| ----- | --------------- | ------------------------------------------- |
| 5.b.1 | Hệ thống        | Hiển thị "Mật khẩu phải có ít nhất 8 ký tự" |
| 5.b.2 | Người dùng      | Nhập lại mật khẩu mạnh hơn                  |

### 5.c - Chưa chấp nhận điều khoản
| Bước  | Người thực hiện | Hành động                                        |
| ----- | --------------- | ------------------------------------------------ |
| 5.c.1 | Hệ thống        | Hiển thị "Vui lòng chấp nhận điều khoản sử dụng" |
| 5.c.2 | Người dùng      | Đọc và chấp nhận điều khoản                      |

---

## Business Rules

- **BR-002-01**: Email phải là duy nhất trong hệ thống
- **BR-002-02**: Mật khẩu tối thiểu 8 ký tự
- **BR-002-03**: Người dùng phải chấp nhận điều khoản trước khi đăng ký
- **BR-002-04**: Email xác thực có hiệu lực 24 giờ
- **BR-002-05**: Hệ thống tự động gán role mặc định là `user` cho mọi tài khoản đăng ký mới

---

## Data Requirements

### Input Data:
| Trường        | Kiểu   | Bắt buộc | Validation                        |
| ------------- | ------ | -------- | --------------------------------- |
| Email         | String | Có       | Format email hợp lệ, chưa tồn tại |
| Mật khẩu      | String | Có       | Tối thiểu 8 ký tự                 |
| Họ tên        | String | Có       | 1-100 ký tự                       |
| Số điện thoại | String | Có       | 10-11 số, bắt đầu bằng 0          |
| Ngày sinh     | Date   | Có       | Trong quá khứ                     |

---

## Yêu cầu phi chức năng

- **Performance**: Thời gian xử lý đăng ký < 3 giây
- **Security**: Mật khẩu được mã hóa trước khi lưu trữ (chi tiết trong Technical Spec)
- **Usability**: 
  - Real-time validation khi người dùng nhập
  - Hiển thị độ mạnh của mật khẩu
- **Privacy**: Tuân thủ các nguyên tắc bảo vệ dữ liệu cá nhân (tương đương HIPAA ở mức độ học thuật) - thu thập đồng ý xử lý dữ liệu
