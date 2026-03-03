# UC022 - QUẢN LÝ NGƯỜI DÙNG

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC022 |
| **Tên UC** | Quản lý người dùng |
| **Tác nhân chính** | Quản trị viên |
| **Mô tả** | Quản trị viên quản lý danh sách người dùng: xem, thêm, sửa, khóa/mở khóa tài khoản |
| **Trigger** | Quản trị viên truy cập "Quản lý người dùng" trên Admin Dashboard |
| **Tiền điều kiện** | Đã đăng nhập với quyền ADMIN |
| **Hậu điều kiện** | Danh sách người dùng được cập nhật, mọi thay đổi được ghi log |

---

## Luồng chính (Main Flow) - Xem danh sách

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Admin | Truy cập "Quản lý người dùng" |
| 2 | Hệ thống | Kiểm tra quyền ADMIN |
| 3 | Hệ thống | Hiển thị bảng danh sách người dùng với:<br>- ID, Họ tên, Email<br>- Vai trò (Bệnh nhân/Người chăm sóc/Admin)<br>- Trạng thái (Active/Locked)<br>- Ngày đăng ký<br>- Nút Sửa/Xóa/Khóa |
| 4 | Hệ thống | Hiển thị phân trang (20 users/page) |
| 5 | Hệ thống | Cung cấp bộ lọc và tìm kiếm |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Thêm người dùng mới
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Admin | Click "Thêm người dùng" |
| 5.a.2 | Hệ thống | Hiển thị form nhập thông tin |
| 5.a.3 | Admin | Nhập: Email, Mật khẩu, Họ tên, Số điện thoại, Vai trò |
| 5.a.4 | Admin | Submit form |
| 5.a.5 | Hệ thống | Validate và tạo user mới |
| 5.a.6 | Hệ thống | Hiển thị "Thêm thành công", reload danh sách |

### 5.b - Sửa thông tin người dùng
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.b.1 | Admin | Click "Sửa" tại hàng người dùng |
| 5.b.2 | Hệ thống | Hiển thị form với thông tin hiện tại |
| 5.b.3 | Admin | Chỉnh sửa (không được sửa email) |
| 5.b.4 | Hệ thống | Cập nhật và hiển thị "Cập nhật thành công" |

### 5.c - Khóa/Mở khóa tài khoản
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.c.1 | Admin | Click "Khóa" |
| 5.c.2 | Hệ thống | Popup xác nhận "Bạn có chắc muốn khóa tài khoản?" |
| 5.c.3 | Admin | Xác nhận |
| 5.c.4 | Hệ thống | Khóa tài khoản và gửi email thông báo |
| 5.c.5 | Hệ thống | Hiển thị "Đã khóa tài khoản" |

### 5.d - Xóa người dùng
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.d.1 | Admin | Click "Xóa" |
| 5.d.2 | Hệ thống | Popup "⚠️ Xóa vĩnh viễn? Dữ liệu không thể khôi phục!" |
| 5.d.3 | Admin | Nhập mật khẩu admin để xác nhận |
| 5.d.4 | Hệ thống | Soft delete (cập nhật `deleted_at`) |
| 5.d.5 | Hệ thống | Archive dữ liệu vào bảng backup |
| 5.d.6 | Hệ thống | Hiển thị "Đã xóa người dùng" |

### 5.e - Tìm kiếm và lọc
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.e.1 | Admin | Nhập từ khóa hoặc chọn bộ lọc (vai trò, trạng thái) |
| 5.e.2 | Hệ thống | Hiển thị kết quả phù hợp |

---

## Business Rules

- **BR-001**: Chỉ ADMIN mới truy cập được
- **BR-002**: Xóa người dùng cần xác thực mật khẩu admin
- **BR-003**: Sử dụng soft delete để bảo toàn dữ liệu
- **BR-004**: Ghi audit log mọi hành động (thêm/sửa/xóa/khóa)
- **BR-005**: Email chưa tồn tại khi thêm mới

---

## Yêu cầu phi chức năng

- **Security**: 
  - Chỉ ADMIN truy cập
  - Xóa cần xác thực mật khẩu
  - Audit log đầy đủ
- **Performance**: Load danh sách < 1 giây
- **Data Integrity**: Soft delete thay vì hard delete
- **Usability**: Pagination, search, filter
