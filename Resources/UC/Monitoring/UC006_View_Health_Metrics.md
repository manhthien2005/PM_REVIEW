# UC006 - XEM CHỈ SỐ SỨC KHỎE

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC006 |
| **Tên UC** | Xem chỉ số sức khỏe theo thời gian thực |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem các chỉ số sức khỏe hiện tại và nhận cảnh báo khi có bất thường |
| **Trigger** | Người dùng mở ứng dụng hoặc truy cập Dashboard |
| **Tiền điều kiện** | - Người dùng đã đăng nhập<br>- Thiết bị IoT đang kết nối và gửi dữ liệu |
| **Hậu điều kiện** | Người dùng nhìn thấy trạng thái sức khỏe hiện tại |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập màn hình "Sức khỏe" |
| 2 | Hệ thống | Hiển thị các chỉ số hiện tại:<br>- Nhịp tim (BPM)<br>- SpO₂ (%)<br>- Huyết áp (mmHg)<br>- Nhiệt độ (°C)<br>Với màu sắc: Xanh (OK), Vàng (Cảnh báo), Đỏ (Nguy hiểm) |
| 3 | Hệ thống | Hiển thị biểu đồ xu hướng 1 giờ gần nhất |
| 4 | Hệ thống | Cập nhật dữ liệu mỗi khi nhận được dữ liệu mới từ thiết bị (chu kỳ thu thập: 1 phút/lần theo SRS HG-FUNC-01, giao diện tự động refresh khi có data mới) |
| 5 | Hệ thống | Gửi thông báo nếu phát hiện chỉ số bất thường |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Thiết bị offline
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Hiển thị "Thiết bị không kết nối" |
| 2.a.2 | Hệ thống | Hiển thị dữ liệu cuối cùng với timestamp |

### 5.a - Xem chi tiết chỉ số
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người dùng | Click vào biểu đồ chỉ số |
| 5.a.2 | Hệ thống | Hiển thị thống kê chi tiết (min, max, trung bình) |

### 5.b - Thay đổi khoảng thời gian
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.b.1 | Người dùng | Chọn khoảng thời gian: 1h, 6h, 24h, 7 ngày |
| 5.b.2 | Hệ thống | Cập nhật biểu đồ theo khoảng thời gian đã chọn |

---

## Business Rules - Ngưỡng cảnh báo

| Chỉ số | Bình thường (Xanh) | Cảnh báo (Vàng) | Nguy hiểm (Đỏ) |
|--------|-------------------|----------------|----------------|
| **Nhịp tim** | 60-100 BPM | 50-59 hoặc 101-120 | <50 hoặc >120 |
| **SpO₂** | ≥95% | 92-94% | <92% |
| **Huyết áp tâm thu** | 90-120 mmHg | 121-139 hoặc 70-89 | ≥140 hoặc <70 |
| **Huyết áp tâm trương** | 60-80 mmHg | 81-89 hoặc 50-59 | ≥90 hoặc <50 |
| **Nhiệt độ** | 36.1-37.2°C | 37.3-37.7 hoặc 35.5-36.0 | ≥37.8 hoặc <35.5 |

**Quy tắc cảnh báo:**
- SpO₂ < 92%: Gửi cảnh báo ngay lập tức
- Nhiệt độ ≥ 37.8°C: Cảnh báo sốt
- Nhịp tim bất thường kéo dài > 5 phút: Gửi thông báo

---

## Yêu cầu phi chức năng

- **Performance**: 
   - Độ trễ hiển thị < 5 giây kể từ khi Server nhận dữ liệu (SRS HG-FUNC-02)
  - Giao diện cập nhật tự động mỗi khi có dữ liệu mới (chu kỳ thiết bị gửi: 1 phút)
- **Usability**: 
  - Responsive (mobile + web)
  - Font chữ lớn, tương phản cao cho người già
  - Dark mode
- **Security**: Chỉ hiển thị dữ liệu của người dùng được ủy quyền
