# 📦 Kế Hoạch Bơm Dữ Liệu Mẫu (Seed Data)

Tài liệu này hướng dẫn thứ tự và cách thức bơm dữ liệu mẫu vào cơ sở dữ liệu HealthGuard một cách an toàn, tránh vi phạm các ràng buộc khóa ngoại (Foreign Key Constraints) và ràng buộc toàn vẹn dữ liệu.

## 🏗️ Nguyên Tắc Đổ Dữ Liệu
Do kiến trúc Relational Database, dữ liệu phải được bơm theo thứ tự **từ bảng gốc (Master Tables) đến các bảng phụ thuộc (Child/Transaction Tables)**.

---

## 📋 Thứ Tự Bơm Dữ Liệu (Insertion Order)

### 🔴 Phase 1: Core Master Data (Foundation)
Đổ dữ liệu vào các bảng gốc không phụ thuộc vào khóa ngoại của bảng khác.
1. **`users`**: Tạo trước danh sách tài khoản hợp lệ (bao gồm `admin` và `user`). 
2. **`devices`**: Đăng ký danh sách các phần cứng (Smartwatch, Cảm biến) có trong kho.
3. **`system_settings`**: Nạp tham số cấu hình hệ thống mặc định.

### 🟡 Phase 2: Relationships & Assignments (Mapping)
Thiết lập các liên kết cần thiết cho hệ thống.
4. **`user_relationships`**: Gắn quyền xem dữ liệu giữa các `user` (Mô phỏng 1 user là bố/mẹ, 1 user là con cái theo dõi). Bắt buộc phải có `users` trước.
5. **`emergency_contacts`**: Nạp danh bạ khẩn cấp cho từng người dùng. Bắt buộc phải có `users` trước.
6. **`user_device_assignments` (nếu có)** hoặc cập nhật trạng thái gán thiết bị cho `users`.

### 🟢 Phase 3: Time-Series & Logs (Simulated Active Data)
Mô phỏng dữ liệu phát sinh theo thời gian thực từ thiết bị và hệ thống.
7. **`vitals` (Hypertable)**: Bơm dữ liệu nhịp tim, nhiệt độ, SpO2. Yêu cầu có `users` và `devices`.
8. **`motion_data` (Hypertable)**: Bơm dữ liệu cảm biến chuyển động. Yêu cầu có `users` và `devices`.
9. **`system_metrics` (Hypertable)**: Bơm metric hiệu năng hệ thống.

### 🟣 Phase 4: Events, Alerts & Analytics (Reactive Data)
Bơm dữ liệu kết quả phân tích và sự kiện phát sinh.
10. **`fall_events` / `sos_events`**: Mô phỏng các ca té ngã hoặc bấm nút SOS thủ công.
11. **`alerts`**: Tạo các bản ghi cảnh báo đi kèm snapshot dữ liệu sinh tồn.
12. **`risk_scores` / `risk_explanations`**: Bơm dữ liệu đánh giá của AI.
13. **`audit_logs` (Hypertable)**: Sinh log cập nhật thông tin giả lập cho bảng Audit.

---

## 🛠️ Cấu Trúc Các File Script

Dựa theo thứ tự trên, chúng ta sẽ chia các luồng bơm data thành các file SQL đánh số thứ tự rõ ràng:
- `01_seed_users_and_devices.sql` (Phase 1)
- `02_seed_relationships.sql` (Phase 2)
- `03_seed_timeseries_vitals.sql` (Phase 3)
- `04_seed_events_and_alerts.sql` (Phase 4)

 *(Các file này sẽ được thiết kế để chạy trực tiếp trên Postgres/TimescaleDB).*
