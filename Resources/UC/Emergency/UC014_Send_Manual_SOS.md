# UC014 - GỬI SOS THỦ CÔNG

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC014 |
| **Tên UC** | Gửi SOS khẩn cấp thủ công |
| **Tác nhân chính** | Bệnh nhân |
| **Mô tả** | Bệnh nhân chủ động gửi tin nhắn SOS khi gặp nguy hiểm |
| **Trigger** | Bệnh nhân bấm và giữ nút SOS trên ứng dụng |
| **Tiền điều kiện** | - Đã cấu hình Emergency Contacts<br>- GPS được bật<br>- Có kết nối Internet hoặc SMS |
| **Hậu điều kiện** | - SOS được gửi đến tất cả người giám sát<br>- App ở chế độ Emergency Mode<br>- Sự kiện được ghi log |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Bệnh nhân | Bấm và giữ nút SOS trong 3 giây |
| 2 | Mobile App | Hiển thị popup xác nhận "Bạn có chắc muốn gửi SOS?" |
| 3 | Bệnh nhân | Xác nhận "Có" |
| 4 | Hệ thống | Lấy vị trí GPS hiện tại |
| 5 | Hệ thống | Gửi thông báo đến tất cả Emergency Contacts:<br>- Push notification (FCM)<br>- SMS<br>- Email (nếu có) |
| 6 | Hệ thống | Bật chế độ Emergency Mode với:<br>- Nút "TÔI ĐÃ AN TOÀN" (màu xanh, lớn)<br>- Vị trí GPS real-time<br>- Danh sách người đã được thông báo |
| 7 | Người giám sát | Nhận thông báo và xem vị trí trên bản đồ |
| 8 | Người giám sát | Gọi điện hoặc đến hiện trường |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Hủy gửi SOS
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Bệnh nhân | Chọn "Hủy" trong popup xác nhận |
| 3.a.2 | Hệ thống | Đóng popup, không gửi SOS |

### 6.a - Xác nhận an toàn sau khi gửi
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Bệnh nhân | Nhấn "TÔI ĐÃ AN TOÀN" trong vòng 5 phút |
| 6.a.2 | Hệ thống | Gửi thông báo hủy đến tất cả người giám sát:<br>"✅ [Tên] đã xác nhận an toàn" |
| 6.a.3 | Hệ thống | Tắt Emergency Mode |

### 5.a - Không lấy được GPS
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Sử dụng last known location |
| 5.a.2 | Hệ thống | Ghi chú trong thông báo "Vị trí ước tính" |

### 5.b - Không gửi được notification
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.b.1 | Hệ thống | Retry 3 lần |
| 5.b.2 | Hệ thống | Chuyển sang backup SMS provider nếu primary thất bại |
| 5.b.3 | Hệ thống | Ghi log lỗi để admin xử lý |

---

## Nội dung thông báo SOS

### Push Notification:
```
🚨 CẢNH BÁO KHẨN CẤP
[Tên bệnh nhân] đang cần giúp đỡ
Thời gian: [timestamp]
Vị trí: [Google Maps link]
```

### SMS:
```
[HEALTHGUARD - KHẨN CẤP]
Người thân: {patient_name}
Sự kiện: YÊU CẦU SOS
Thời gian: {timestamp}
Vị trí: {google_maps_url}
```

---

## Quy trình xử lý theo mức độ ưu tiên

| Priority | Hành động |
|----------|-----------|
| **CRITICAL** | Manual SOS → Gửi: PUSH + SMS + EMAIL |
| **HIGH** | Auto SOS (từ Fall Detection) → Gửi: PUSH + SMS |
| **MEDIUM** | Health Alert → Chỉ PUSH |

---

## Business Rules

- **BR-001**: Cần giữ nút SOS 3 giây để tránh bấm nhầm
- **BR-002**: Cho phép hủy SOS trong vòng 5 phút nếu là false alarm
- **BR-003**: Retry notification tối đa 3 lần
- **BR-004**: Emergency Contacts được gửi theo thứ tự ưu tiên (Priority 1-5)

---

## Yêu cầu phi chức năng

- **Performance**: Thời gian từ bấm SOS đến gửi < 5 giây
- **Reliability**: Success rate > 99%
- **Security**: Mã hóa GPS location khi truyền tải
- **Safety**: 
  - Backup SMS provider
  - Log đầy đủ mọi SOS event
- **Privacy**: Chỉ gửi đến Emergency Contacts đã ủy quyền
