# UC016 - XEM BÁO CÁO RỦI RO SỨC KHỎE

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC016 |
| **Tên UC** | Xem báo cáo đánh giá rủi ro sức khỏe |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem báo cáo đánh giá rủi ro tim mạch/đột quỵ với giải thích rõ ràng |
| **Trigger** | - Người dùng click "Đánh giá rủi ro" trên app<br>- Hoặc hệ thống tự động đánh giá mỗi 6 giờ |
| **Tiền điều kiện** | - Đã đăng nhập<br>- Có dữ liệu sức khỏe liên tục ít nhất 24 giờ<br>- Đã cập nhật thông tin bệnh lý nền |
| **Hậu điều kiện** | Người dùng nhìn thấy điểm rủi ro và khuyến nghị hành động |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Click "Đánh giá rủi ro sức khỏe" |
| 2 | Hệ thống | Kiểm tra có đánh giá trong 1 giờ gần nhất không |
| 3 | Hệ thống | Nếu chưa có: Thực hiện đánh giá mới (AI service - xem Technical Spec) |
| 4 | Hệ thống | Hiển thị báo cáo với:<br>- **Điểm rủi ro** (0-100)<br>- **Mức độ** (LOW/MEDIUM/HIGH/CRITICAL)<br>- **Biểu đồ tròn** màu sắc theo mức độ |
| 5 | Hệ thống | Hiển thị **giải thích** (XAI):<br>"Rủi ro cao (78 điểm) do:<br>1. Nhịp tim tăng (120 BPM) - Ảnh hưởng 30%<br>2. HRV thấp (25ms) - Ảnh hưởng 25%<br>3. SpO₂ giảm (88%) - Ảnh hưởng 20%<br>..." |
| 6 | Hệ thống | Hiển thị **xu hướng**: Biểu đồ điểm rủi ro 7 ngày |
| 7 | Hệ thống | Hiển thị **khuyến nghị** theo mức độ rủi ro |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Đã có đánh giá gần đây
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Hiển thị kết quả đánh giá cũ (trong 1 giờ gần nhất) |
| 2.a.2 | Hệ thống | Hiển thị thông báo "Cập nhật lúc [timestamp]" |

### 3.a - Không đủ dữ liệu
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống | Hiển thị "Chưa đủ dữ liệu để đánh giá (cần ít nhất 24 giờ)" |
| 3.a.2 | Hệ thống | Hiển thị tiến trình thu thập: "Đã có 12/24 giờ" |

### 7.a - Tải báo cáo PDF
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 7.a.1 | Người dùng | Click "TẢI BÁO CÁO PDF" |
| 7.a.2 | Hệ thống | Tạo PDF với đầy đủ thông tin đánh giá |
| 7.a.3 | Hệ thống | Lưu file vào thiết bị hoặc gửi email |

### 7.b - Gọi bác sĩ (nếu rủi ro cao)
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 7.b.1 | Người dùng | Click "GỌI BÁC SĨ" |
| 7.b.2 | Hệ thống | Mở ứng dụng điện thoại với số hotline đã cấu hình |

---

## Phân loại mức độ và khuyến nghị

| Mức độ | Điểm | Màu | Khuyến nghị |
|--------|------|-----|-------------|
| **LOW** | 0-33 | 🟢 Xanh | - Duy trì lối sống lành mạnh<br>- Vận động đều đặn |
| **MEDIUM** | 34-66 | 🟡 Vàng | - Theo dõi chặt chẽ hơn<br>- Tham khảo bác sĩ<br>- Điều chỉnh chế độ ăn |
| **HIGH** | 67-84 | 🟠 Cam | - ⚠️ Liên hệ bác sĩ sớm<br>- Theo dõi huyết áp hàng ngày<br>- Hạn chế hoạt động mạnh |
| **CRITICAL** | 85-100 | 🔴 Đỏ | - 🚨 KHẨN CẤP: Đi bệnh viện<br>- Gọi cấp cứu nếu có triệu chứng<br>- Thông báo người thân |

---

## Giải thích AI (XAI)

**Ví dụ hiển thị giải thích:**

```
💡 Tại sao điểm rủi ro là 78?

Top 5 yếu tố ảnh hưởng:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Nhịp tim tăng cao (120 BPM khi nghỉ)
   Ảnh hưởng: ████████████████████████████ 30%
   
2. HRV thấp (25ms, bình thường >50ms)
   Ảnh hưởng: ████████████████████ 25%
   
3. SpO₂ giảm (88%, bình thường >95%)
   Ảnh hưởng: ████████████████ 20%
   
4. Có tiền sử cao huyết áp
   Ảnh hưởng: ████████████ 15%
   
5. Tuổi 75
   Ảnh hưởng: ████████ 10%
```

---

## Business Rules

- **BR-001**: Chỉ đánh giá lại sau 1 giờ (tránh spam)
- **BR-002**: Cần ít nhất 24 giờ dữ liệu liên tục
- **BR-003**: Nếu rủi ro HIGH/CRITICAL → Gửi thông báo đến người giám sát
- **BR-004**: Luôn hiển thị disclaimer: "Đây là công cụ hỗ trợ, không thay thế chẩn đoán y khoa"

---

## Yêu cầu phi chức năng

- **Accuracy**: AUC-ROC > 0.85, Sensitivity > 90%
- **Performance**: Thời gian tính toán < 3 giây, hiển thị < 1 giây
- **Transparency**: 
  - Luôn hiển thị độ tin cậy dự đoán
  - Giải thích rõ ràng, ngôn ngữ đơn giản
- **Privacy**: Không chia sẻ kết quả với bên thứ 3
