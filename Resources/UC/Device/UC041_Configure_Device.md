# UC041 - CẤU HÌNH THIẾT BỊ IOT

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC041 |
| **Tên UC** | Cấu hình thiết bị IoT |
| **Tác nhân chính** | Bệnh nhân |
| **Mô tả** | Người dùng cấu hình một số tuỳ chọn cho thiết bị của mình như tần suất đo, mức cảnh báo rung, bật/tắt tính năng theo dõi giấc ngủ. |
| **Trigger** | Người dùng mở phần "Cài đặt thiết bị" cho một thiết bị đã được kết nối. |
| **Tiền điều kiện** | - Thiết bị đã được gán cho user (UC040).<br>- Thiết bị đang ở trạng thái active. |
| **Hậu điều kiện** | Cấu hình mới được lưu và (nếu cần) gửi xuống thiết bị/simulator. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Chọn thiết bị trong danh sách và mở "Cài đặt thiết bị". |
| 2 | Hệ thống | Hiển thị các tuỳ chọn cấu hình hiện tại (VD: tần suất gửi dữ liệu, bật/tắt rung khi cảnh báo, bật/tắt theo dõi giấc ngủ). |
| 3 | Người dùng | Thay đổi một số tuỳ chọn và nhấn "Lưu". |
| 4 | Hệ thống | Validate giá trị (VD: tần suất đo không nhỏ hơn ngưỡng cho phép). |
| 5 | Hệ thống | Lưu cấu hình mới (VD: trong `calibration_data` hoặc bảng cấu hình thiết bị riêng). |
| 6 | Hệ thống | Gửi lệnh cấu hình đến thiết bị/simulator (nếu kiến trúc hỗ trợ). |

---

## Luồng thay thế (Alternative Flows)

### 4.a - Cấu hình không hợp lệ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống | Phát hiện giá trị cấu hình ngoài phạm vi (VD: tần suất gửi < 1 giây). |
| 4.a.2 | Hệ thống | Hiển thị lỗi, không cho lưu. |

### 6.a - Thiết bị không online

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Hệ thống | Không gửi được lệnh cấu hình đến thiết bị (offline). |
| 6.a.2 | Hệ thống | Lưu cấu hình ở server và đánh dấu "pending sync". |
| 6.a.3 | Hệ thống | Lần sau khi thiết bị online, push cấu hình mới xuống. |

---

## Business Rules

- **BR-041-01**: Một số cấu hình có thể chỉ áp dụng ở server (VD: tần suất hiển thị), một số phải sync xuống thiết bị (VD: rung cảnh báo). 
- **BR-041-02**: Mọi thay đổi cấu hình phải ghi log với `action = 'device.config.updated'`. 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Không hiển thị quá nhiều tham số kỹ thuật; nhóm các tuỳ chọn thành "Cơ bản" và "Nâng cao". 
- **Reliability**: 
  - Đảm bảo cấu hình sẽ được áp dụng kể cả khi thiết bị đang tạm offline (cơ chế pending sync). 

