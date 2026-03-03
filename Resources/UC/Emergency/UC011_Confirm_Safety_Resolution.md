# UC011 - XÁC NHẬN AN TOÀN & KẾT THÚC SỰ CỐ

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC011 |
| **Tên UC** | Xác nhận an toàn & kết thúc sự cố |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Bệnh nhân hoặc người chăm sóc xác nhận rằng sự cố (té ngã/SOS) đã được xử lý an toàn, từ đó hệ thống cập nhật trạng thái và dừng chế độ khẩn cấp. |
| **Trigger** | - Sau UC010 (fall alert) hoặc UC014 (SOS) đã được kích hoạt.<br>- Người chăm sóc nhận SOS (UC015) và xử lý xong. |
| **Tiền điều kiện** | - Tồn tại `fall_event` hoặc `sos_event` ở trạng thái đang hoạt động (`active`/`responded`). |
| **Hậu điều kiện** | - Sự cố được đánh dấu "Đã giải quyết/An toàn".<br>- Cập nhật trạng thái trong `sos_events` và/hoặc `alerts`, ghi log vào `audit_logs`. |

---

## Luồng chính (Main Flow) - Bệnh nhân xác nhận an toàn

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Hệ thống | Trên màn hình Emergency Mode (từ UC010/UC014), hiển thị nút "TÔI ĐÃ AN TOÀN". |
| 2 | Bệnh nhân | Nhấn "TÔI ĐÃ AN TOÀN". |
| 3 | Hệ thống | Xác định `fall_event` / `sos_event` đang hoạt động liên quan tới bệnh nhân. |
| 4 | Hệ thống | Cập nhật trạng thái sự kiện thành `resolved`, lưu `resolved_at` và `resolved_by_user_id`. |
| 5 | Hệ thống | Gửi thông báo đến người chăm sóc: "✅ [Tên] đã xác nhận an toàn sau sự cố". |
| 6 | Hệ thống | Tắt Emergency Mode trên app bệnh nhân. |

---

## Luồng thay thế (Alternative Flows)

### 1.a - Người chăm sóc xác nhận an toàn

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1.a.1 | Người chăm sóc | Từ màn hình nhận SOS (UC015), chọn "Đánh dấu đã an toàn". |
| 1.a.2 | Hệ thống | Cập nhật `sos_events.status = 'resolved'`, ghi chú `resolution_notes` (VD: "Đã kiểm tra trực tiếp, không sao"). |
| 1.a.3 | Hệ thống | Gửi thông báo đến bệnh nhân (nếu online): "Người chăm sóc đã xác nhận bạn an toàn". |

### 3.a - Không tìm thấy sự kiện đang hoạt động

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống | Không tìm thấy `sos_events` hoặc `fall_events` ở trạng thái `active`. |
| 3.a.2 | Hệ thống | Hiển thị thông báo "Không có sự cố nào đang hoạt động" và ghi log anomaly. |

---

## Business Rules

- **BR-011-01**: Chỉ cho phép đánh dấu an toàn khi sự kiện đang ở trạng thái `active` hoặc `responded`.
- **BR-011-02**: Ghi `resolved_by_user_id` để biết ai là người đã xác nhận an toàn (bệnh nhân hay caregiver). 
- **BR-011-03**: Sau khi sự cố được đánh dấu an toàn, mọi thông báo liên quan ở trạng thái chưa đọc có thể được cập nhật trạng thái "đã xử lý". 
- **BR-011-04**: Ghi log đầy đủ vào `audit_logs` với `action = 'sos.resolved'` hoặc `action = 'fall_event.resolved'`. 

---

## Yêu cầu phi chức năng

- **Safety**: 
  - Không tự động đánh dấu an toàn; luôn cần action rõ ràng từ bệnh nhân hoặc caregiver.
- **Usability**: 
  - Nút "TÔI ĐÃ AN TOÀN" / "Đánh dấu đã an toàn" hiển thị rõ, dễ bấm, tránh nhầm lẫn với nút SOS.
- **Reliability**: 
  - Nếu mất mạng lúc xác nhận, hệ thống phải retry cập nhật trạng thái khi có kết nối lại. 

