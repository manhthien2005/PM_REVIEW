# UC031 - QUẢN LÝ THÔNG BÁO

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC031 |
| **Tên UC** | Quản lý thông báo |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng quản lý trung tâm thông báo của mình: xem danh sách thông báo, đánh dấu đã đọc, cấu hình loại thông báo muốn nhận. |
| **Trigger** | Người dùng mở màn hình "Thông báo" hoặc "Cài đặt thông báo". |
| **Tiền điều kiện** | Người dùng đã đăng nhập. |
| **Hậu điều kiện** | Trạng thái đọc/tham số cấu hình thông báo của người dùng được cập nhật. |

---

## Luồng chính (Main Flow) - Xem & đánh dấu thông báo

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Mở màn "Thông báo". |
| 2 | Hệ thống | Truy vấn bảng `alerts` theo `user_id`, sắp xếp mới nhất trước. |
| 3 | Hệ thống | Hiển thị danh sách thông báo với: tiêu đề, thời gian, mức độ (low/medium/high/critical), trạng thái đọc/chưa đọc. |
| 4 | Người dùng | Chạm vào một thông báo để xem chi tiết. |
| 5 | Hệ thống | Hiển thị chi tiết `message`, dữ liệu snapshot (`data`), và các hành động liên quan (VD: mở màn hình bệnh nhân, xem bản đồ, v.v.). |
| 6 | Hệ thống | Đánh dấu thông báo đó là "đã đọc" (`read_at` được set). |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Lọc theo mức độ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Người dùng | Chọn filter: Tất cả / Chỉ critical / Chỉ chưa đọc. |
| 3.a.2 | Hệ thống | Lọc danh sách dựa trên `severity` và `read_at`. |

### 6.a - Đánh dấu tất cả là đã đọc

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Người dùng | Chọn "Đánh dấu tất cả là đã đọc". |
| 6.a.2 | Hệ thống | Cập nhật `read_at` cho tất cả alerts chưa đọc của user. |

### 1.a - Cấu hình loại thông báo muốn nhận

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1.a.1 | Người dùng | Mở "Cài đặt thông báo". |
| 1.a.2 | Hệ thống | Hiển thị các tuỳ chọn: nhận thông báo cho các loại `alert_type` (vital_abnormal, fall_detected, sos_triggered, high_risk_score, device_offline, low_battery). |
| 1.a.3 | Người dùng | Bật/tắt từng loại theo nhu cầu (VD: cho phép low_battery chỉ ở mức push, không SMS). |
| 1.a.4 | Hệ thống | Lưu cấu hình vào bảng settings của user (có thể là JSON hoặc bảng riêng). |

---

## Business Rules

- **BR-031-01**: Các thông báo critical (sos_triggered, fall_detected) luôn phải gửi push; user chỉ có thể hạn chế SMS/email, không được tắt hoàn toàn. 
- **BR-031-02**: Alert cũ hơn một khoảng thời gian nhất định (VD: 90 ngày) có thể tự động expire (`expires_at`) và ẩn khỏi UI mặc định. 
- **BR-031-03**: Cho phép lọc nhanh "Chỉ sự kiện quan trọng" = `severity IN ('high', 'critical')`. 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Màn hình thông báo thiết kế tương tự các app nhắn tin, dễ hiểu. 
- **Performance**: 
  - Phải phân trang khi số lượng thông báo lớn; mỗi lần chỉ tải 20–50 bản ghi. 
- **Privacy**: 
  - Nội dung thông báo không nên quá chi tiết trên màn hình khóa (tuỳ chọn ẩn chi tiết cho privacy). 

