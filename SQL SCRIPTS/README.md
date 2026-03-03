# 📊 DB Architecture Master Context — HealthGuard

> **Hệ Thống:** Môi trường Database Trung tâm (Shared Database)
> **Engine:** PostgreSQL + TimescaleDB (Time-series optimization)
> **Mục Đích Document:** Context cốt lõi dành riêng cho **AI Code Reviewer** (Loại bỏ các bước setup/CLI).

---

## 🏛️ 1. Tổng Quan Kiến Trúc (Architecture Overview)

Cơ sở dữ liệu HealthGuard được chia thành 6 Layer/Domain chính, được ánh xạ thành các bảng vật lý và được thiết kế để xử lý lượng lớn dữ liệu time-series IoT cùng với luồng sự kiện (Events & Alerts).

1. **User Management:** Quản lý Bệnh nhân (Patients), Người giám sát (Caregivers), Admin và các mối quan hệ quyền hạn.
2. **Device Management:** Quản lý thiết bị IoT, trạng thái kết nối MQTT.
3. **Time-Series Data:** Dữ liệu chuỗi thời gian cực lớn (Vitals, Motion) lưu trên Hypertables của TimescaleDB.
4. **Events & Alerts:** Quản lý sự kiện khẩn cấp (Fall, SOS) và trạng thái phân phối thông báo.
5. **AI Analytics:** Lưu trữ kết quả dự đoán rủi ro và giải thích XAI.
6. **System & Audit:** Context về hệ thống, logging, metrics.

---

## 🧠 2. Lõi Dữ Liệu & Entity-Relationships (Core ERD)

### Layer 1: Users & Relationships
- **`users`**: Bảng trung tâm. Cột quan trọng: `role` (patient/caregiver/admin), `medical_conditions` (Mảng bệnh lý). Soft delete áp dụng qua cột `deleted_at`.
- **`user_relationships`**: Mapping (Many-to-Many) giữa Patient và Caregiver. Ràng buộc cứng: Caregiver chỉ được xem data của Patient nếu có mapping tại đây. Có cột `is_primary` ưu tiên liên lạc.
- **`emergency_contacts`**: Lưu số điện thoại (từ ngoài hệ thống) để gọi khẩn cấp dựa trên `priority` (1-5).

### Layer 2: Devices
- **`devices`**: Chứa thông tin phần cứng IoT.
- **Cột sống còn**: `last_seen_at` (Dấu vết kết nối MQTT cuối cùng). Nếu `last_seen_at` > 5 phút → Device Offline.

### Layer 3: Time-Series (Hypertables & Continuous Aggregates)
- **`vitals` (Hypertable)**: Lưu nhịp tim, SpO2, nhiệt độ. Rate: 1 record/giây. 
- **`motion_data` (Hypertable)**: Lưu gia tốc (accel), vận tốc góc (gyro). Rate: 50-100 records/giây.
- **Continuous Aggregates (View hiệu suất cao)**: 
  - Hệ thống sử dụng tự động `vitals_5min`, `vitals_hourly`, `vitals_daily` để hiển thị biểu đồ/báo cáo. 
  - *Constraint cho AI Reviewer*: Code Backend lấy data để vẽ biểu đồ **TUYỆT ĐỐI KHÔNG** query trên bảng `vitals` gốc mà bắt buộc phải query trên các Aggregates Views này.

### Layer 4: Events, Alerts & SOS Workflow
- **`fall_events`**: Ghi nhận từ AI Inference.
  - *Luồng:* Ghi vào bảng → Gửi thông báo (`user_notified_at`) → Nếu user không hủy (`user_cancelled = false`) trong 30s → trigger `sos_events`.
- **`sos_events`**: Call emergency workflow. Tracking bằng cột `status` (active/responded/resolved).
- **`alerts`**: Bảng **Centralized** cho mọi loại thông báo (push, SMS). Lưu snapshot dữ liệu sinh tồn vào tại cột jsonb `data` ngay thời điểm alert phát sinh.

### Layer 5: AI Analytics (Risk & XAI)
- **`risk_scores`**: Risk định lượng (0-100) được đánh giá định kỳ.
- **`risk_explanations`**: Giải thích XAI (Explainable AI) lưu dạng jsonb `feature_importance`.

### Layer 6: Audit & System
- **`audit_logs`**: Hypertable partition theo tháng. Mọi hành động nhạy cảm (VD: xóa user, truy cập data) phải được log với `resource_type`, `resource_id`, và `ip_address`.

---

## 📜 3. Các Thiết Kế Tối Ưu Tích Hợp (Policies & Optimization)

*AI Reviewer phải đối chiếu code backend xem có xung đột với các logic ngầm của Database sau đây không:*

1. **Retention Policies (Hủy data cũ tự động):**
   - Bảng `vitals`: Dữ liệu thô bị xóa sau 1 năm (chỉ giữ bản aggregated).
   - Bảng `motion_data`: Bị xóa sau 3 tháng.
   *→ Hậu quả Code Review:* Backend tải lịch sử bệnh án > 1 năm không được truy tìm raw `vitals`.
2. **Compression:**
   - Dữ liệu `vitals` cũ hơn 7 ngày tự động bị nén. (Tốc độ query cho dữ liệu bị nén sẽ chậm nếu không query đúng cách kèm thời gian).
3. **Time-based Indexing:** Tùy biến cực mạnh cho điều kiện WHERE kết hợp thời gian. 
   - `(device_id, time DESC)` là composite index chính trên toàn bộ khối Time-Series.

---

## ⚠️ 4. Quy Tắc Ngữ Cảnh Dành Riêng AI Reviewer (AI Review Constraints)

Khi thực hiện task `@DanhGiaChiTiet`, Agent cần khắc cốt ghi tâm các database rules sau khi đọc Code Backend:

1. **NO RAW QUERIES FOR CHARTS:** Nếu BE controller cung cấp API trả về data cho biểu đồ Frontend (Chart/Trends), kiểm tra SQL query xem nó có trỏ vào `vitals_5min` / `hourly` hay không. Nếu query trực tiếp vào bảng `vitals`, hãy **FLAG LÀ LỖI MEDIUM/HIGH**.
2. **SOFT DELETE COMPLIANCE:** Nếu BE thực hiện hành động DELETE một user, kiểm tra xem code đó đang dùng hàm ORM Soft Delete (`deleted_at = NOW()`) hay Hard Delete. Nếu Hard Delete -> **FLAG SECURITY ERROR**.
3. **AUTHORIZATION LEAK:** Bất cứ API nào đọc data của Patient đều phải có logic cross-check trong bảng `user_relationships` trước để xem Caregiver đó có được phép (`permissions`) hay không.
4. **ALERT DATA SNAPSHOTTING:** Khi BE lưu một alert khẩn cấp (vd Fall detected), code có lưu snapshot của sinh tồn vào cột `data` dạng JSON không? Nếu thiếu -> **FLAG LỖI LOGIC**.
5. **TIME-BUILTIN:** Bất cứ Query time-series nào từ ORM (Prisma/SQLAlchemy) không được thiếu điều kiện filter thời gian rõ ràng (Time range bounding). Query không có giới hạn `time >` hay `time <` rủi ro quét toàn bộ Hypertable -> **FLAG LỖI PERFORMANCE**.
