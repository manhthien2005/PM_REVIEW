# UC040 - KẾT NỐI THIẾT BỊ IOT

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC040 |
| **Tên UC** | Kết nối thiết bị IoT với tài khoản |
| **Tác nhân chính** | Bệnh nhân |
| **Mô tả** | Bệnh nhân gán (pair) một thiết bị IoT (smartwatch/band) với tài khoản HealthGuard của mình để bắt đầu thu thập dữ liệu. |
| **Trigger** | Người dùng chọn "Kết nối thiết bị" trong ứng dụng. |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Thiết bị đã được tạo trước trong hệ thống (do Admin nhập hoặc auto-provision). |
| **Hậu điều kiện** | Thiết bị được liên kết với tài khoản (`devices.user_id` được gán), hệ thống bắt đầu nhận dữ liệu cho user đó. |

---

## Luồng chính (Main Flow) - Nhập mã thiết bị

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Mở "Cài đặt" → "Thiết bị" → "Kết nối thiết bị mới". |
| 2 | Hệ thống | Hiển thị form nhập mã thiết bị (device code/serial) hoặc quét QR. |
| 3 | Người dùng | Nhập mã thiết bị hoặc quét QR code. |
| 4 | Hệ thống | Kiểm tra thiết bị tồn tại trong `devices` và chưa gán cho user khác (hoặc cho phép chuyển quyền). |
| 5 | Hệ thống | Nếu hợp lệ, gán thiết bị cho user hiện tại, cập nhật `user_id`, `registered_at`. |
| 6 | Hệ thống | Hiển thị thông báo "Kết nối thiết bị thành công" và trạng thái thiết bị. |

---

## Luồng thay thế (Alternative Flows)

### 4.a - Thiết bị không tồn tại hoặc đã bị khoá

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống | Không tìm thấy thiết bị hoặc `is_active = false`. |
| 4.a.2 | Hệ thống | Hiển thị "Thiết bị không hợp lệ hoặc đã bị khoá. Vui lòng liên hệ hỗ trợ." |

### 4.b - Thiết bị đang gán cho user khác

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.b.1 | Hệ thống | Phát hiện thiết bị đã có `user_id` khác. |
| 4.b.2 | Hệ thống | Hiển thị thông báo và (tuỳ chính sách) đề xuất quy trình "chuyển quyền sở hữu" nếu được phép. |

---

## Business Rules

- **BR-040-01**: Một user có thể có nhiều thiết bị, nhưng mỗi thiết bị tại một thời điểm chỉ gán cho một user. 
- **BR-040-02**: Các thông số hiệu chỉnh (`calibration_data`) đi theo thiết bị, không theo user. 
- **BR-040-03**: Mọi thao tác kết nối/thay đổi kết nối phải được ghi log `audit_logs` với `action = 'device.bound'` hoặc `device.rebound`. 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Hỗ trợ quét QR code để tránh nhập mã dài. 
- **Security**: 
  - Mã thiết bị không nên quá dễ đoán; có thể kết hợp nhiều trường (model + serial + checksum). 

