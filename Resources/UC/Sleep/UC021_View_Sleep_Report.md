# UC021 - XEM BÁO CÁO GIẤC NGỦ

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC021 |
| **Tên UC** | Xem báo cáo giấc ngủ |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem báo cáo chất lượng giấc ngủ (theo đêm hoặc theo khoảng ngày) dựa trên dữ liệu đã được phân tích từ UC020. |
| **Trigger** | Người dùng mở màn hình "Giấc ngủ" trên ứng dụng. |
| **Tiền điều kiện** | - Hệ thống đã ghi nhận ít nhất một phiên giấc ngủ hợp lệ cho người dùng. |
| **Hậu điều kiện** | Người dùng hiểu được chất lượng giấc ngủ và xu hướng ngủ của mình theo thời gian. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập tab "Giấc ngủ" trên app. |
| 2 | Hệ thống | Hiển thị báo cáo cho đêm gần nhất với các thông tin:<br>- Tổng thời gian ngủ<br>- Thời gian bắt đầu/kết thúc<br>- Số lần thức giấc<br>- Thời gian ngủ sâu/nhẹ (nếu có)<br>- Điểm chất lượng giấc ngủ (0–100, LOW/MEDIUM/HIGH). |
| 3 | Hệ thống | Hiển thị biểu đồ thanh/đường thể hiện chất lượng giấc ngủ 7 ngày gần nhất. |
| 4 | Người dùng | Chọn 1 đêm cụ thể để xem chi tiết. |
| 5 | Hệ thống | Hiển thị timeline giấc ngủ (trục thời gian với các segment: ngủ sâu, ngủ nhẹ, tỉnh giấc). |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Chưa có dữ liệu giấc ngủ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Phát hiện người dùng chưa có phiên giấc ngủ nào. |
| 2.a.2 | Hệ thống | Hiển thị message "Chưa có dữ liệu giấc ngủ. Hãy đeo thiết bị khi ngủ để bắt đầu theo dõi." và hướng dẫn bật chế độ theo dõi (UC020). |

### 3.a - Lọc khoảng thời gian khác

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Người dùng | Chọn khoảng thời gian: 7 ngày, 30 ngày, 90 ngày. |
| 3.a.2 | Hệ thống | Cập nhật biểu đồ xu hướng giấc ngủ theo khoảng đó. |

---

## Business Rules

- **BR-021-01**: Điểm chất lượng giấc ngủ có thể được chuẩn hoá về thang 0–100, dựa trên tổng thời gian, số lần thức, và nhịp tim trong lúc ngủ. 
- **BR-021-02**: Màn hình báo cáo phải có phần "Tóm tắt cho người không rành kỹ thuật" (VD: "Giấc ngủ của bạn đêm qua ở mức TỐT/TRUNG BÌNH/KÉM"). 
- **BR-021-03**: Caregiver chỉ xem được báo cáo giấc ngủ nếu được bệnh nhân cấp quyền trong cài đặt quyền riêng tư. 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Biểu đồ trực quan, dễ đọc cho người lớn tuổi (màu sắc rõ, chữ lớn). 
- **Performance**: 
  - Tải báo cáo 7 ngày gần nhất < 2 giây. 
- **Privacy**: 
  - Cho phép bệnh nhân bật/tắt chia sẻ báo cáo giấc ngủ với caregiver. 

