# UC031 - QUẢN LÝ THÔNG BÁO

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC031                                                                                                                         |
| **Tên UC**         | Quản lý thông báo                                                                                                             |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc                                                                                                     |
| **Mô tả**          | Người dùng quản lý trung tâm thông báo của mình: xem danh sách thông báo, lọc theo mức độ/loại, đánh dấu đã đọc (từng mục hoặc tất cả). |
| **Trigger**        | Người dùng mở màn hình "Thông báo".                                                                                            |
| **Tiền điều kiện** | Người dùng đã đăng nhập.                                                                                                                      |
| **Hậu điều kiện**  | Trạng thái đọc của thông báo (từng mục hoặc tất cả) được cập nhật.                                                              |

---

## Luồng chính (Main Flow) - Xem & đánh dấu thông báo

| Bước | Người thực hiện | Hành động                                                                                                                         |
| ---- | --------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Người dùng      | Mở màn "Thông báo".                                                                                                               |
| 2    | Hệ thống        | Truy vấn danh sách thông báo của người dùng, sắp xếp mới nhất trước.                                                              |
| 3    | Hệ thống        | Hiển thị danh sách thông báo với: tiêu đề, thời gian, mức độ (low/medium/high/critical), trạng thái đọc/chưa đọc.                 |
| 4    | Người dùng      | Chạm vào một thông báo để xem chi tiết.                                                                                           |
| 5    | Hệ thống        | Hiển thị chi tiết `message`, dữ liệu snapshot (`data`), và các hành động liên quan (VD: mở màn hình bệnh nhân, xem bản đồ, v.v.). |
| 6    | Hệ thống        | Đánh dấu thông báo đó là "đã đọc" (`read_at` được set).                                                                           |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Lọc theo mức độ / loại thông báo (client-side)

| Bước  | Người thực hiện | Hành động                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------- |
| 3.a.1 | Người dùng      | Chọn filter mức độ (Tất cả / Chưa đọc / Đã đọc) hoặc loại (SOS / Sức khoẻ / Thuốc / Hệ thống).     |
| 3.a.2 | Hệ thống        | Lọc danh sách client-side trên dữ liệu đã tải; chỉ filter "Chưa đọc" gửi query `unread_only=true` lên BE. |

**Implementation note (Phase 0.5):** Client-side filter là intentional — dataset mobile nhỏ (< 100 notif/user), FE filter local nhanh hơn round-trip BE. BR-031-03 quick filter "critical only" thực thi qua type filter `sos`/`health` ở FE.

### 6.a - Đánh dấu tất cả là đã đọc

| Bước  | Người thực hiện | Hành động                                                          |
| ----- | --------------- | ------------------------------------------------------------------ |
| 6.a.1 | Người dùng      | Chọn "Đánh dấu tất cả là đã đọc".                                  |
| 6.a.2 | Hệ thống        | Gửi `PUT /notifications/read-all` — BE set `read_at=NOW()` cho tất cả thông báo `read_at IS NULL` của user. |
| 6.a.3 | Hệ thống        | Trả về số lượng notification đã update + refresh UI counter về 0. |

---

## Business Rules

- **BR-031-01**: Các thông báo critical (sos_triggered, fall_detected, risk_critical) luôn được gửi qua kênh FCM riêng biệt (`sos_fullscreen_alerts`, `risk_alerts`) với `fullScreenIntent`; user có thể quản lý bật/tắt từng kênh ở cấp độ hệ điều hành (Android Settings > Apps > HealthGuard > Notifications per-channel) theo pattern consumer mobile app chuẩn.
- **BR-031-02**: Alert cũ hơn 90 ngày tự động expire (`expires_at`) và ẩn khỏi UI mặc định qua APScheduler worker chạy hàng ngày; grace period 30 ngày trước khi hard delete.
- **BR-031-03**: Lọc nhanh "Chỉ sự kiện quan trọng" (`severity IN ('high', 'critical')`) được thực thi client-side trên type filter (`sos` + `health`) theo Alt 3.a; không cần BE query param riêng.

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Màn hình thông báo thiết kế tương tự các app nhắn tin, dễ hiểu. 
- **Performance**: 
  - Phải phân trang khi số lượng thông báo lớn; mỗi lần chỉ tải 20–50 bản ghi. 
- **Privacy**: 
  - Nội dung thông báo không nên quá chi tiết trên màn hình khóa (tuỳ chọn ẩn chi tiết cho privacy). 

