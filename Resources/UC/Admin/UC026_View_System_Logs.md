# UC026 - XEM NHẬT KÝ HỆ THỐNG

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC026 |
| **Tên UC** | Xem nhật ký hệ thống |
| **Tác nhân chính** | Quản trị viên |
| **Mô tả** | Quản trị viên xem nhật ký hoạt động hệ thống (audit logs, sự kiện quan trọng) để kiểm tra bảo mật, điều tra sự cố hoặc audit. |
| **Trigger** | Admin truy cập mục "Nhật ký hệ thống" trên Admin Dashboard. |
| **Tiền điều kiện** | - Admin đã đăng nhập và có quyền xem log. |
| **Hậu điều kiện** | Admin xem được danh sách log, có thể lọc theo thời gian, user, hành động. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Admin | Mở màn "Nhật ký hệ thống". |
| 2 | Hệ thống | Truy vấn bảng `audit_logs` với khoảng thời gian mặc định (24 giờ gần nhất). |
| 3 | Hệ thống | Hiển thị bảng log với các cột: Thời gian, User, Hành động, Resource, Kết quả (success/failure). |
| 4 | Admin | Dùng ô tìm kiếm/bộ lọc để lọc theo: thời gian, user, loại hành động (VD: `user.login`, `sos.triggered`, `settings.changed`). |
| 5 | Admin | Chọn 1 log để xem chi tiết. |
| 6 | Hệ thống | Hiển thị chi tiết `details` (JSON) dưới dạng format dễ đọc (old/new value, IP, user agent…). |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Không có log trong khoảng thời gian

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Không tìm thấy bản ghi nào. |
| 2.a.2 | Hệ thống | Hiển thị thông báo "Không có sự kiện nào trong khoảng thời gian đã chọn". |

### 4.a - Xuất log ra file

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Admin | Chọn "Xuất CSV" hoặc "Xuất JSON" cho khoảng thời gian hiện tại. |
| 4.a.2 | Hệ thống | Tạo file chứa dữ liệu log và cho phép tải về. |

---

## Business Rules

- **BR-026-01**: Nhật ký không được chỉnh sửa sau khi ghi; chỉ có thể thêm log mới (append-only). 
- **BR-026-02**: Dữ liệu log được lưu tối thiểu 2 năm (theo `retention policy`). 
- **BR-026-03**: Không hiển thị các trường nhạy cảm (VD: password, token) trong giao diện log. 

---

## Yêu cầu phi chức năng

- **Security**: 
  - Chỉ tài khoản admin có quyền đặc biệt mới truy cập được màn hình log. 
- **Performance**: 
  - Hỗ trợ phân trang, không load tất cả log một lúc. 
- **Auditability**: 
  - Chính màn hình xem log cũng nên ghi log lại (VD: `admin.view_logs`). 

