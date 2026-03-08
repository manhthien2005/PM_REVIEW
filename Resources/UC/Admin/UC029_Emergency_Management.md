# UC029 - QUẢN LÝ SỰ CỐ KHẨN CẤP (ADMIN)

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                                                        |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC029                                                                                                                                                                                                                                                           |
| **Tên UC**         | Quản lý sự cố khẩn cấp                                                                                                                                                                                                                                          |
| **Tác nhân chính** | Quản trị viên                                                                                                                                                                                                                                                   |
| **Mô tả**          | Quản trị viên giám sát, phân loại và xử lý tất cả sự cố khẩn cấp trong hệ thống bao gồm Fall Events và SOS Events. Admin có thể xem real-time, ghi nhận phản hồi, cập nhật trạng thái sự cố (active → responded → resolved), và xem GPS location của bệnh nhân. |
| **Trigger**        | Admin truy cập mục "Quản lý sự cố" trên Admin Dashboard hoặc nhận thông báo sự cố mới.                                                                                                                                                                          |
| **Tiền điều kiện** | Admin đã đăng nhập với quyền ADMIN.                                                                                                                                                                                                                             |
| **Hậu điều kiện**  | Sự cố được xử lý, trạng thái cập nhật, mọi hành động được ghi log.                                                                                                                                                                                              |

---

## Luồng chính (Main Flow) — Xem danh sách sự cố

| Bước | Người thực hiện | Hành động                                                                                                                                                            |
| ---- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập "Quản lý sự cố khẩn cấp".                                                                                                                                   |
| 2    | Hệ thống        | Hiển thị **Summary Bar**:<br>- SOS Active (đỏ, nhấp nháy nếu > 0)<br>- Falls chưa xử lý (cam)<br>- Resolved hôm nay (xanh)<br>- Tổng sự cố 7 ngày                    |
| 3    | Hệ thống        | Hiển thị bảng **Sự cố đang hoạt động** (realtime, sắp xếp theo urgency):<br>- ID, Loại (Fall/SOS), Bệnh nhân, Thời gian, Trạng thái, GPS, Trigger type (auto/manual) |
| 4    | Hệ thống        | Hiển thị bảng **Lịch sử sự cố** (tab riêng, có phân trang):<br>- Bao gồm cả sự cố đã resolved với thời gian phản hồi, người xử lý                                    |
| 5    | Admin           | Xem tổng quan sự cố và quyết định hành động.                                                                                                                         |

---

## Luồng thay thế (Alternative Flows)

### 5.a — Xem chi tiết sự cố

| Bước  | Người thực hiện | Hành động                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5.a.1 | Admin           | Click vào một sự cố trong danh sách.                                                                                                                                                                                                                                                                                                                                                                                                                    |
| 5.a.2 | Hệ thống        | Hiển thị chi tiết sự cố:<br>- **Thông tin bệnh nhân**: Tên, tuổi, medical conditions, emergency contacts<br>- **Chi tiết sự kiện**: Loại, thời gian trigger, confidence score (fall), trigger_type<br>- **Vitals snapshot**: HR, SpO₂, BP, Temp tại thời điểm sự cố (từ `alerts.data` JSON)<br>- **GPS Location**: Bản đồ vị trí bệnh nhân (nếu có)<br>- **Timeline**: Chuỗi sự kiện liên quan (fall → countdown → SOS → notification sent → responded) |

### 5.b — Cập nhật trạng thái sự cố

| Bước  | Người thực hiện | Hành động                                                                                                      |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------- |
| 5.b.1 | Admin           | Chọn sự cố đang `active` và click "Đã phản hồi" hoặc "Đã giải quyết".                                          |
| 5.b.2 | Hệ thống        | Popup xác nhận kèm ô ghi chú (bắt buộc).                                                                       |
| 5.b.3 | Admin           | Nhập ghi chú (VD: "Đã liên hệ caregiver Nguyễn Văn A, xác nhận an toàn") và xác nhận.                          |
| 5.b.4 | Hệ thống        | Cập nhật `sos_events.status` (active → responded → resolved), lưu `responded_at`/`resolved_at`, ghi audit log. |

### 5.c — Liên hệ khẩn cấp từ Dashboard

| Bước  | Người thực hiện | Hành động                                                                             |
| ----- | --------------- | ------------------------------------------------------------------------------------- |
| 5.c.1 | Admin           | Trong trang chi tiết sự cố, click "Gọi Emergency Contact".                            |
| 5.c.2 | Hệ thống        | Hiển thị danh sách emergency contacts (từ bảng `emergency_contacts` theo `priority`). |
| 5.c.3 | Admin           | Chọn contact và ghi nhận đã liên hệ (Log action: `admin.contact_emergency`).          |

### 5.d — Lọc sự cố

| Bước  | Người thực hiện | Hành động                                                                                         |
| ----- | --------------- | ------------------------------------------------------------------------------------------------- |
| 5.d.1 | Admin           | Chọn bộ lọc: Loại sự cố (Fall/SOS/All), Trạng thái (Active/Responded/Resolved), Khoảng thời gian. |
| 5.d.2 | Hệ thống        | Lọc lại bảng sự cố theo điều kiện đã chọn.                                                        |

### 5.e — Xuất báo cáo sự cố

| Bước  | Người thực hiện | Hành động                                                                                  |
| ----- | --------------- | ------------------------------------------------------------------------------------------ |
| 5.e.1 | Admin           | Click "Xuất báo cáo" cho khoảng thời gian đã chọn.                                         |
| 5.e.2 | Hệ thống        | Tạo file CSV/PDF chứa tổng hợp sự cố kèm thống kê (thời gian phản hồi TB, tỷ lệ resolved). |

---

## Business Rules

- **BR-029-01**: Trang sự cố active phải auto-refresh mỗi 15 giây để đảm bảo realtime.
- **BR-029-02**: Sự cố SOS `active` phải được highlight đỏ và có hiệu ứng nhấp nháy.
- **BR-029-03**: Khi update status, ghi chú (notes) là **BẮT BUỘC** để đảm bảo traceability.
- **BR-029-04**: Admin KHÔNG được xóa hay chỉnh sửa dữ liệu sự cố (append-only workflow), chỉ update status.
- **BR-029-05**: Mọi hành động (xem chi tiết, update status, liên hệ emergency) phải ghi `audit_logs`.
- **BR-029-06**: Luồng trạng thái: `active` → `responded` → `resolved`. Không được skip bước (VD: active → resolved).

---

## Yêu cầu phi chức năng

- **Performance**:
  - Bảng sự cố active load < 1 giây (dữ liệu ít, query đơn giản trên `sos_events` và `fall_events`).
  - Auto-refresh không gây flicker (incremental update).
- **Security**:
  - Chỉ ADMIN role truy cập.
  - GPS location là dữ liệu nhạy cảm, chỉ hiển thị trong context sự cố active.
  - Audit log đầy đủ cho compliance.
- **Usability**:
  - Sound notification khi có SOS mới (optional, configurable).
  - Bảng sự cố có sticky header khi scroll.
  - Timeline sự kiện hiển thị dạng vertical timeline cho dễ đọc.
- **Reliability**:
  - Nếu mất kết nối, hiển thị warning "Dữ liệu có thể không cập nhật" và retry tự động.
