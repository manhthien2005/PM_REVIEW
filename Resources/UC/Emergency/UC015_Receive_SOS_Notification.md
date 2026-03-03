# UC015 - NGƯỜI CHĂM SÓC NHẬN & XỬ LÝ THÔNG BÁO SOS

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC015 |
| **Tên UC** | Nhận và xử lý thông báo SOS |
| **Tác nhân chính** | Người chăm sóc |
| **Mô tả** | Người chăm sóc nhận thông báo SOS (tự động từ té ngã hoặc bệnh nhân bấm nút) và thực hiện các hành động cần thiết. |
| **Trigger** | - UC014 được kích hoạt (SOS thủ công).<br>- UC010 không được phản hồi và hệ thống tự động gửi SOS. |
| **Tiền điều kiện** | - Người chăm sóc đã được cấu hình trong `user_relationships` hoặc `emergency_contacts` với quyền nhận alert.<br>- Thiết bị bệnh nhân đang cấu hình gửi SOS đến người chăm sóc tương ứng. |
| **Hậu điều kiện** | - Người chăm sóc đã xem thông báo SOS, có thể gọi lại, đánh dấu đã xử lý, và hệ thống cập nhật trạng thái sự kiện. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Hệ thống | Tạo `sos_events` với trạng thái `active` và gửi thông báo đến tất cả người chăm sóc liên quan (push/SMS/email). |
| 2 | Người chăm sóc | Nhận thông báo SOS trên mobile app (push notification). |
| 3 | Người chăm sóc | Chạm vào thông báo để mở màn hình chi tiết SOS. |
| 4 | Hệ thống | Hiển thị chi tiết: <br>- Tên bệnh nhân<br>- Thời gian kích hoạt SOS<br>- Vị trí GPS (bản đồ)<br>- Loại: auto/manual<br>- Mức độ ưu tiên. |
| 5 | Người chăm sóc | Chọn một trong các hành động: Gọi điện, Mở chỉ đường, Đánh dấu đã xử lý. |
| 6 | Hệ thống | Nếu chọn "Đánh dấu đã xử lý", chuyển `sos_events.status` sang `responded` hoặc `resolved` và ghi `resolved_at`, `resolved_by_user_id`. |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Người chăm sóc không online (chỉ nhận SMS)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Không gửi được push, fallback sang SMS. |
| 2.a.2 | Người chăm sóc | Nhận SMS với nội dung: tên bệnh nhân, thời gian, link Google Maps. |

### 4.a - Vị trí không khả dụng

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống | Không có toạ độ GPS hợp lệ. |
| 4.a.2 | Hệ thống | Hiển thị "Vị trí không khả dụng" và gợi ý liên lạc qua điện thoại. |

### 5.a - Nhiều người chăm sóc cùng nhận SOS

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người chăm sóc A | Nhấn "Đã xử lý" trên app. |
| 5.a.2 | Hệ thống | Cập nhật `sos_events.status = 'responded'`/`resolved` và ghi `resolved_by_user_id = A`. |
| 5.a.3 | Hệ thống | Gửi thông báo tới các người chăm sóc khác: "Người chăm sóc A đã nhận và xử lý SOS". |

---

## Business Rules

- **BR-015-01**: Tất cả người chăm sóc được đánh dấu `can_receive_alerts = true` sẽ nhận SOS, nhưng chỉ cần 1 người xác nhận "Đã xử lý". 
- **BR-015-02**: Hệ thống ưu tiên gửi push, sau đó mới SMS/email nếu push thất bại hoặc user offline. 
- **BR-015-03**: Mọi hành động "Đã xử lý" phải được log vào `audit_logs` với `action = 'sos.handled'`. 
- **BR-015-04**: Không cho phép chỉnh sửa nội dung SOS sau khi đã gửi (chỉ được thêm `resolution_notes`). 

---

## Yêu cầu phi chức năng

- **Performance**: 
  - Thời gian từ lúc SOS được tạo đến khi push/SMS được gửi ≤ 5 giây.
- **Reliability**: 
  - Cơ chế retry gửi thông báo (tối thiểu 3 lần với backoff). 
- **Usability**: 
  - Màn hình chi tiết SOS đơn giản, tập trung vào 3 hành động chính: Gọi, Xem bản đồ, Đánh dấu đã xử lý. 
- **Security & Privacy**: 
  - Chỉ người chăm sóc có quyền mới xem được vị trí và chi tiết SOS của bệnh nhân. 

