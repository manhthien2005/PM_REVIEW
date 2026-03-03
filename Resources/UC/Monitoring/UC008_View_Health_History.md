# UC008 - XEM LỊCH SỬ CHỈ SỐ SỨC KHỎE

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC008 |
| **Tên UC** | Xem lịch sử chỉ số sức khỏe |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem lại lịch sử các chỉ số sức khỏe trong khoảng thời gian dài (ngày, tuần, tháng) để theo dõi xu hướng. |
| **Trigger** | Người dùng chọn chức năng "Lịch sử sức khỏe" từ màn hình chính hoặc từ UC006. |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Có ít nhất một khoảng thời gian đã được ghi nhận dữ liệu. |
| **Hậu điều kiện** | Người dùng xem được biểu đồ và thống kê lịch sử chỉ số sức khỏe theo khoảng thời gian đã chọn. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập màn hình "Lịch sử sức khỏe". |
| 2 | Hệ thống | Hiển thị bộ lọc: Khoảng thời gian (7 ngày, 30 ngày, 3 tháng, tùy chọn from/to), loại chỉ số (Nhịp tim, SpO₂, Huyết áp, Nhiệt độ). |
| 3 | Người dùng | Chọn khoảng thời gian và chỉ số cần xem. |
| 4 | Hệ thống | Truy vấn dữ liệu từ các bảng tổng hợp (`vitals_hourly`, `vitals_daily`). |
| 5 | Hệ thống | Hiển thị biểu đồ xu hướng (line chart/area chart) cho chỉ số đã chọn kèm các giá trị min/max/avg theo từng ngày/giờ. |
| 6 | Người dùng | Cuộn và quan sát xu hướng, có thể chuyển đổi giữa các chỉ số. |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Người dùng chưa có đủ dữ liệu

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Phát hiện thời gian sử dụng < 24 giờ hoặc không có dữ liệu trong khoảng mặc định. |
| 2.a.2 | Hệ thống | Hiển thị thông báo "Chưa đủ dữ liệu lịch sử. Vui lòng sử dụng thiết bị ít nhất 24 giờ." |

### 5.a - Xem chi tiết 1 ngày

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người dùng | Chạm vào 1 điểm/ngày trên biểu đồ. |
| 5.a.2 | Hệ thống | Hiển thị popup chi tiết cho ngày đó (min, max, avg, số lần vượt ngưỡng, link sang UC007 để xem chi tiết hơn). |

### 6.a - Lọc theo khoảng thời gian custom

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Người dùng | Chọn “Tuỳ chỉnh” và nhập ngày bắt đầu/kết thúc. |
| 6.a.2 | Hệ thống | Validate khoảng thời gian (không vượt quá 1 năm, ngày bắt đầu <= ngày kết thúc). |
| 6.a.3 | Hệ thống | Nếu hợp lệ: nạp lại dữ liệu; nếu không: hiển thị lỗi. |

---

## Business Rules

- **BR-008-01**: Mặc định hiển thị lịch sử 7 ngày gần nhất.
- **BR-008-02**: Nếu chọn khoảng > 30 ngày, hệ thống sử dụng `vitals_daily` để hiển thị (không dùng dữ liệu thô).
- **BR-008-03**: Caregiver chỉ được xem lịch sử của bệnh nhân mà họ có quan hệ trong `user_relationships` với `can_view_vitals = true`.
- **BR-008-04**: Không hiển thị dữ liệu vượt ngoài thời gian retention đã cấu hình (VD: > 1 năm có thể không còn dữ liệu chi tiết). 

---

## Yêu cầu phi chức năng

- **Performance**: 
  - Thời gian truy vấn và vẽ biểu đồ lịch sử 30 ngày < 3 giây.
- **Usability**: 
  - Biểu đồ rõ ràng, hỗ trợ xoay ngang màn hình để xem full width.
  - Dùng màu sắc consistent với UC006 (xanh/vàng/đỏ) cho vùng bình thường/bất thường.
- **Security & Privacy**: 
  - Dữ liệu lịch sử được bảo vệ như dữ liệu hiện tại; bắt buộc dùng HTTPS/TLS.

