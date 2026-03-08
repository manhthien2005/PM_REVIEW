# UC025 - QUẢN LÝ THIẾT BỊ IOT

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC025                                                                                                                                                                                                               |
| **Tên UC**         | Quản lý thiết bị IoT                                                                                                                                                                                                |
| **Tác nhân chính** | Quản trị viên                                                                                                                                                                                                       |
| **Mô tả**          | Quản trị viên quản lý danh sách thiết bị IoT trong hệ thống: xem, tìm kiếm, khoá/mở khoá, gán/bỏ gán cho người dùng. **Lưu ý**: UC này dành cho Admin quản trị tập trung; việc user tự pair thiết bị xem tại UC040. |
| **Trigger**        | Quản trị viên truy cập mục "Quản lý thiết bị" trên Admin Dashboard.                                                                                                                                                 |
| **Tiền điều kiện** | - Admin đã đăng nhập.                                                                                                                                                                                               |
| **Hậu điều kiện**  | Danh sách thiết bị, trạng thái kho (chưa gán) và gán người dùng được cập nhật, ghi log chi tiết.                                                                                                                    |

---

## Luồng chính (Main Flow) - Xem danh sách thiết bị

| Bước | Người thực hiện | Hành động                                                                                                                                |
| ---- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập "Quản lý thiết bị".                                                                                                             |
| 2    | Hệ thống        | Hiển thị bảng danh sách thiết bị với các cột: Tên thiết bị, Loại, Chủ sở hữu (user), Trạng thái (active/inactive), Pin, Lần cuối online. |
| 3    | Hệ thống        | Hiển thị ô tìm kiếm theo tên thiết bị, serial, user.                                                                                     |
| 4    | Admin           | Lọc/tìm kiếm thiết bị theo nhu cầu.                                                                                                      |

---

## Luồng thay thế (Alternative Flows)

### 4.a - Gán thiết bị cho người dùng

| Bước  | Người thực hiện | Hành động                                                             |
| ----- | --------------- | --------------------------------------------------------------------- |
| 4.a.1 | Admin           | Chọn 1 thiết bị chưa có chủ (`user_id` NULL) và click "Gán cho user". |
| 4.a.2 | Hệ thống        | Hiển thị danh sách user hoặc ô tìm kiếm email/user code.              |
| 4.a.3 | Admin           | Chọn user và xác nhận.                                                |
| 4.a.4 | Hệ thống        | Cập nhật `devices.user_id` và ghi log vào `audit_logs`.               |

### 4.b - Khoá/Mở khoá thiết bị

| Bước  | Người thực hiện | Hành động                                                               |
| ----- | --------------- | ----------------------------------------------------------------------- |
| 4.b.1 | Admin           | Click "Khoá" trên 1 thiết bị.                                           |
| 4.b.2 | Hệ thống        | Popup xác nhận "Bạn có chắc muốn khoá thiết bị này?".                   |
| 4.b.3 | Admin           | Xác nhận.                                                               |
| 4.b.4 | Hệ thống        | Cập nhật `is_active = false`, dừng nhận dữ liệu từ thiết bị và ghi log. |

### 4.c - Xem chi tiết thiết bị

| Bước  | Người thực hiện | Hành động                                                                                          |
| ----- | --------------- | -------------------------------------------------------------------------------------------------- |
| 4.c.1 | Admin           | Click vào 1 thiết bị trong danh sách.                                                              |
| 4.c.2 | Hệ thống        | Hiển thị chi tiết: model, firmware, MAC, trạng thái pin, tín hiệu, last_seen_at, calibration_data. |

### 4.d - Thêm thiết bị thủ công (Admin nhập kho)

| Bước  | Người thực hiện | Hành động                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------- |
| 4.d.1 | Admin           | Click "Thêm thiết bị mới".                                                             |
| 4.d.2 | Hệ thống        | Hiển thị form gồm: Tên thiết bị, Loại, Model, Firmware, MAC Address, Serial Number.    |
| 4.d.3 | Admin           | Điền thông tin và Lưu (không cần chọn User).                                           |
| 4.d.4 | Hệ thống        | Lưu thiết bị với trạng thái `user_id = NULL` (Thiết bị rảnh/Trong kho), ghi log audit. |

### 4.e - Import thiết bị hàng loạt

| Bước  | Người thực hiện | Hành động                                                                      |
| ----- | --------------- | ------------------------------------------------------------------------------ |
| 4.e.1 | Admin           | Click "Import thiết bị" và chọn file CSV/Excel mẫu.                            |
| 4.e.2 | Hệ thống        | Validate file (định dạng, trùng lặp MAC/Serial).                               |
| 4.e.3 | Hệ thống        | Import hàng loạt thiết bị với `user_id = NULL`, xuất báo cáo row lỗi (nếu có). |

---

## Business Rules

- **BR-025-01**: Một thiết bị chỉ có thể gán cho tối đa một user tại một thời điểm. Khi mới nạp vào hệ thống, thiết bị ở trạng thái "rảnh" (`user_id = NULL`).
- **BR-025-02**: Không được xoá cứng thiết bị nếu đã từng phát sinh dữ liệu trong `vitals`/`motion_data` (chỉ soft delete hoặc set inactive). 
- **BR-025-03**: Mọi thay đổi về gán thiết bị, khoá/mở khoá phải được ghi vào `audit_logs`. 

---

## Yêu cầu phi chức năng

- **Security**: 
  - Chỉ admin mới có thể gán/bỏ gán và khoá/mở khoá thiết bị. 
- **Performance**: 
  - Trang danh sách thiết bị hỗ trợ phân trang, load < 2 giây với 10.000 thiết bị. 
- **Usability**: 
  - Có filter nhanh: Active/Inactive, Có chủ/Chưa có chủ. 

