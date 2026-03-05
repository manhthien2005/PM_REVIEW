# UC001 - ĐĂNG NHẬP

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                           |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC001                                                                                              |
| **Tên UC**         | Đăng nhập vào hệ thống                                                                             |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc, Quản trị viên                                                           |
| **Mô tả**          | Người dùng đăng nhập vào hệ thống bằng email và mật khẩu để truy cập các chức năng theo phân quyền |
| **Trigger**        | Người dùng nhấn nút "Đăng nhập" trên ứng dụng                                                      |
| **Tiền điều kiện** | - Người dùng đã có tài khoản trong hệ thống<br>- Tài khoản chưa bị khóa                            |
| **Hậu điều kiện**  | - Người dùng được xác thực và chuyển đến Dashboard<br>- Session được tạo với JWT token             |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                         |
| ---- | --------------- | ------------------------------------------------- |
| 1    | Người dùng      | Chọn chức năng "Đăng nhập"                        |
| 2    | Hệ thống        | Hiển thị form đăng nhập (email, password)         |
| 3    | Người dùng      | Nhập email và mật khẩu                            |
| 4    | Người dùng      | Nhấn "Đăng nhập"                                  |
| 5    | Hệ thống        | Kiểm tra email và mật khẩu có khớp trong database |
| 6    | Hệ thống        | Tạo JWT token và session                          |
| 7    | Hệ thống        | Chuyển hướng đến Dashboard tương ứng vai trò      |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Email hoặc mật khẩu sai
| Bước  | Người thực hiện | Hành động                                           |
| ----- | --------------- | --------------------------------------------------- |
| 5.a.1 | Hệ thống        | Hiển thị thông báo "Email hoặc mật khẩu không đúng" |
| 5.a.2 | Hệ thống        | Cho phép người dùng nhập lại (tối đa 5 lần/15 phút) |

### 5.b - Tài khoản bị khóa
| Bước  | Người thực hiện   | Hành động                                                       |
| ----- | ----------------- | --------------------------------------------------------------- |
| 5.b.1 | Hệ thống          | Hiển thị "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên" |
| 5.b.2 | Use case kết thúc |                                                                 |

---

## Business Rules

- **BR-001-01**: Mật khẩu phải được hash (chi tiết implementation trong Technical Spec)
- **BR-001-02**: JWT token expiry theo platform:
  - Admin Web: access token 8 giờ, role: `ADMIN`
  - Mobile App: access token 30 ngày, refresh token 90 ngày (rotation — mỗi lần refresh tạo cặp token mới, invalidate token cũ), roles: `PATIENT`, `CAREGIVER`
- **BR-001-03**: Admin Backend và Mobile Backend sử dụng JWT secret key riêng biệt, hoàn toàn độc lập
- **BR-001-04**: Giới hạn 5 lần đăng nhập sai trong 15 phút, sau đó khóa tạm thời IP
- **BR-001-05**: Mật khẩu tối thiểu 8 ký tự

---

## Yêu cầu phi chức năng

- **Performance**: Thời gian phản hồi < 2 giây
- **Security**: Mật khẩu không được log ra console/file
- **Usability**: Hiển thị/ẩn mật khẩu khi người dùng click icon "con mắt"
