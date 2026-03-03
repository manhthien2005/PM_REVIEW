# UC024 - CẤU HÌNH HỆ THỐNG

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC024 |
| **Tên UC** | Cấu hình hệ thống |
| **Tác nhân chính** | Quản trị viên |
| **Mô tả** | Quản trị viên cấu hình các tham số hệ thống toàn cục như ngưỡng cảnh báo, cấu hình AI, chính sách lưu trữ/log, và kênh thông báo mặc định. |
| **Trigger** | Quản trị viên truy cập mục "Cấu hình hệ thống" trên Admin Dashboard. |
| **Tiền điều kiện** | - Admin đã đăng nhập và có quyền cấu hình hệ thống (role `admin`). |
| **Hậu điều kiện** | - Cấu hình mới được lưu và áp dụng cho toàn hệ thống; các thay đổi được ghi vào `audit_logs`. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Admin | Truy cập màn "Cấu hình hệ thống". |
| 2 | Hệ thống | Lấy và hiển thị các giá trị cấu hình hiện tại (VD: ngưỡng nhịp tim, SpO₂, thời gian countdown té ngã, kênh thông báo mặc định, v.v.). |
| 3 | Admin | Chỉnh sửa một số trường cấu hình (VD: SpO₂ cảnh báo từ 92% -> 93%, thời gian countdown từ 30 -> 20 giây). |
| 4 | Admin | Nhấn "Lưu cấu hình". |
| 5 | Hệ thống | Validate dữ liệu cấu hình (giới hạn min/max, kiểu dữ liệu). |
| 6 | Hệ thống | Lưu cấu hình mới vào bảng cấu hình (theo thiết kế: có thể là bảng `system_settings` hoặc file config). |
| 7 | Hệ thống | Ghi log vào `audit_logs` với chi tiết cấu hình cũ/mới. |
| 8 | Hệ thống | Hiển thị thông báo "Cập nhật cấu hình thành công". |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Giá trị cấu hình không hợp lệ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Phát hiện giá trị ngoài khoảng cho phép (VD: SpO₂ ngưỡng > 100%). |
| 5.a.2 | Hệ thống | Hiển thị thông báo lỗi và đánh dấu trường không hợp lệ. |
| 5.a.3 | Admin | Sửa lại giá trị hợp lệ và lưu lại. |

### 4.a - Hủy thay đổi

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Admin | Nhấn "Hủy" hoặc rời khỏi trang mà không lưu. |
| 4.a.2 | Hệ thống | Không thay đổi cấu hình hiện tại. |

---

## Business Rules

- **BR-024-01**: Chỉ người dùng có role `admin` mới truy cập được màn hình cấu hình hệ thống. 
- **BR-024-02**: Mọi thay đổi phải được log đầy đủ trong `audit_logs` (ai, khi nào, thay đổi gì). 
- **BR-024-03**: Một số cấu hình quan trọng (VD: tắt hoàn toàn cảnh báo té ngã) có thể yêu cầu xác nhận bổ sung (nhập lại mật khẩu admin). 

---

## Yêu cầu phi chức năng

- **Security**: 
  - Bảo vệ chặt chẽ endpoint cấu hình, yêu cầu JWT + kiểm tra role. 
- **Reliability**: 
  - Hỗ trợ rollback (khôi phục cấu hình trước đó) nếu cấu hình mới gây lỗi. 
- **Usability**: 
  - Nhóm cấu hình theo các tab: Cảnh báo, AI, Lưu trữ, Thông báo,… để dễ thao tác. 

