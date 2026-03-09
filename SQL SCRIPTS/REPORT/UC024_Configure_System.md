# UC024 - CẤU HÌNH HỆ THỐNG

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC024 |
| **Tên UC** | Cấu hình hệ thống |
| **Tác nhân chính** | Quản trị viên (Admin) |
| **Tác nhân phụ** | Hệ thống HealthGuard, CSDL PostgreSQL/TimescaleDB |
| **Mô tả** | Quản trị viên cấu hình các tham số hệ thống toàn cục bao gồm: ngưỡng cảnh báo sinh hiệu (vitals), cấu hình AI/ML, chính sách lưu trữ dữ liệu (retention/compression), cấu hình thông báo mặc định, cấu hình fall detection, và các thông số vận hành hệ thống. |
| **Trigger** | Quản trị viên truy cập mục "Cấu hình hệ thống" trên Admin Dashboard. |
| **Tiền điều kiện** | 1. Admin đã đăng nhập thành công (có JWT hợp lệ). <br> 2. Admin có role = `admin` trong bảng `users`. <br> 3. Token chưa hết hạn và `token_version` khớp với DB. |
| **Hậu điều kiện** | 1. Cấu hình mới được lưu vào bảng `system_settings`. <br> 2. Hệ thống áp dụng cấu hình mới ngay lập tức (hoặc theo schedule). <br> 3. Toàn bộ thay đổi được ghi vào `audit_logs` với chi tiết cấu hình cũ/mới. <br> 4. Lịch sử phiên bản cấu hình được lưu lại phục vụ rollback. |

---

## Bảng CSDL liên quan

| Bảng | Vai trò trong UC024 |
|------|---------------------|
| `system_settings` | **[CẦN TẠO MỚI]** Lưu trữ tất cả cấu hình hệ thống dạng key-value (JSONB). |
| `audit_logs` | Ghi log mọi thay đổi cấu hình (action = `settings.changed`). |
| `users` | Xác thực admin (kiểm tra `role = 'admin'`, `is_active = true`). |
| `vitals` | Ảnh hưởng bởi ngưỡng cảnh báo (CHECK constraints: `heart_rate`, `spo2`, `temperature`, `blood_pressure_sys/dia`). |
| `alerts` | Ảnh hưởng bởi cấu hình kênh thông báo mặc định (`sent_via`), severity levels. |
| `fall_events` | Ảnh hưởng bởi cấu hình fall detection (countdown, confidence threshold). |
| `risk_scores` | Ảnh hưởng bởi cấu hình AI model (risk thresholds, tần suất tính toán). |
| `devices` | Ảnh hưởng bởi cấu hình device timeout (offline detection dựa trên `last_seen_at`). |
| `system_metrics` | Monitor hiệu năng hệ thống sau khi thay đổi cấu hình. |

---

## Đề xuất bảng `system_settings` (Script SQL mới)

> [!IMPORTANT]
> Hiện tại schema **chưa có** bảng `system_settings`. Cần tạo script `13_create_tables_system_settings.sql` để hỗ trợ UC024.

```sql
CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    
    -- Setting Identity
    category VARCHAR(50) NOT NULL,
    -- Categories: 'vital_thresholds', 'fall_detection', 'ai_config', 
    --             'notification', 'retention', 'device', 'security', 'general'
    setting_key VARCHAR(100) NOT NULL,
    
    -- Value (JSONB for flexibility)
    setting_value JSONB NOT NULL,
    default_value JSONB NOT NULL,
    
    -- Validation
    value_type VARCHAR(20) NOT NULL CHECK (value_type IN ('number', 'string', 'boolean', 'json', 'array')),
    min_value DECIMAL(10,2),
    max_value DECIMAL(10,2),
    allowed_values TEXT[],
    
    -- Metadata
    description TEXT,
    is_critical BOOLEAN DEFAULT false,  -- Yêu cầu xác nhận bổ sung khi thay đổi
    requires_restart BOOLEAN DEFAULT false,
    
    -- Versioning (hỗ trợ rollback)
    version INT NOT NULL DEFAULT 1,
    updated_by INT REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    CONSTRAINT unique_setting UNIQUE(category, setting_key)
);

-- Bảng lưu lịch sử thay đổi (hỗ trợ rollback)
CREATE TABLE IF NOT EXISTS system_settings_history (
    id BIGSERIAL PRIMARY KEY,
    setting_id INT NOT NULL REFERENCES system_settings(id) ON DELETE CASCADE,
    old_value JSONB,
    new_value JSONB NOT NULL,
    version INT NOT NULL,
    changed_by INT REFERENCES users(id) ON DELETE SET NULL,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    change_reason TEXT
);

CREATE INDEX idx_settings_category ON system_settings(category);
CREATE INDEX idx_settings_key ON system_settings(category, setting_key);
CREATE INDEX idx_settings_history_setting ON system_settings_history(setting_id, changed_at DESC);
```

---

## Các nhóm cấu hình chi tiết

### Tab 1: Ngưỡng cảnh báo sinh hiệu (Vital Thresholds)

Dựa trên CHECK constraints bảng `vitals` và partial indexes bảng `08_create_indexes.sql`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `hr_high_threshold` | Ngưỡng nhịp tim cao | 120 | 60 | 250 | BPM |
| `hr_low_threshold` | Ngưỡng nhịp tim thấp | 50 | 30 | 80 | BPM |
| `spo2_low_threshold` | Ngưỡng SpO₂ thấp | 92 | 70 | 100 | % |
| `temp_high_threshold` | Ngưỡng nhiệt độ cao | 37.8 | 37.0 | 42.0 | °C |
| `temp_low_threshold` | Ngưỡng nhiệt độ thấp | 35.5 | 33.0 | 36.5 | °C |
| `bp_sys_high_threshold` | Ngưỡng HA tâm thu cao | 140 | 100 | 250 | mmHg |
| `bp_dia_low_threshold` | Ngưỡng HA tâm trương thấp | 90 | 40 | 100 | mmHg |
| `signal_quality_min` | Chất lượng tín hiệu tối thiểu chấp nhận | 50 | 10 | 100 | % |
| `abnormal_alert_severity` | Mức severity mặc định cho cảnh báo bất thường | `"high"` | — | — | enum |
| `consecutive_readings` | Số lần đọc liên tục vượt ngưỡng trước khi cảnh báo | 3 | 1 | 10 | lần |

### Tab 2: Cấu hình Fall Detection

Dựa trên bảng `fall_events` và `motion_data`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `fall_countdown_seconds` | Thời gian countdown trước khi kích hoạt SOS | 30 | 10 | 120 | giây |
| `fall_confidence_threshold` | Ngưỡng confidence tối thiểu để xác định là té ngã | 0.75 | 0.50 | 0.99 | — |
| `fall_magnitude_threshold` | Ngưỡng magnitude (gia tốc) phát hiện té ngã | 20.0 | 10.0 | 50.0 | m/s² |
| `fall_auto_sos_enabled` | Bật/tắt tự động kích hoạt SOS | `true` | — | — | boolean |
| `fall_model_version` | Phiên bản model AI fall detection đang dùng | `"v1.0"` | — | — | string |
| `fall_sampling_rate` | Tần số lấy mẫu motion data | 50 | 25 | 200 | Hz |

### Tab 3: Cấu hình AI/ML Analytics

Dựa trên bảng `risk_scores` và `risk_explanations`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `risk_calculation_interval` | Tần suất tính toán risk score | 6 | 1 | 24 | giờ |
| `risk_high_threshold` | Ngưỡng điểm risk level "high" | 70 | 50 | 90 | điểm |
| `risk_critical_threshold` | Ngưỡng điểm risk level "critical" | 85 | 70 | 100 | điểm |
| `risk_types_enabled` | Các loại risk đang bật | `["stroke","heartattack","afib","general"]` | — | — | array |
| `ai_algorithm` | Thuật toán AI đang sử dụng | `"gradient_boosting"` | — | — | enum |
| `xai_method` | Phương pháp giải thích AI | `"shap"` | — | — | enum |
| `ai_auto_alert_enabled` | Tự động tạo alert khi risk score cao | `true` | — | — | boolean |

### Tab 4: Cấu hình thông báo (Notification)

Dựa trên bảng `alerts` và `emergency_contacts`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `default_notification_channels` | Kênh thông báo mặc định | `["push"]` | — | — | array |
| `available_channels` | Các kênh có thể dùng | `["push","sms","email"]` | — | — | array |
| `critical_alert_channels` | Kênh cho cảnh báo critical | `["push","sms"]` | — | — | array |
| `alert_expiry_days` | Số ngày alert tự hết hạn | 30 | 7 | 90 | ngày |
| `max_alerts_per_hour` | Giới hạn số alert gửi mỗi giờ/user | 10 | 1 | 50 | alert |
| `sos_sms_enabled` | Bật/tắt gửi SMS khi SOS | `true` | — | — | boolean |
| `sos_call_enabled` | Bật/tắt gọi điện khi SOS | `false` | — | — | boolean |

### Tab 5: Chính sách lưu trữ (Data Retention & Compression)

Dựa trên `09_create_policies.sql`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `vitals_retention_days` | Thời gian giữ raw vitals data | 365 | 90 | 730 | ngày |
| `vitals_compress_after_days` | Thời gian trước khi compress vitals | 7 | 1 | 30 | ngày |
| `motion_retention_days` | Thời gian giữ motion data | 90 | 30 | 365 | ngày |
| `motion_compress_after_days` | Thời gian trước khi compress motion | 3 | 1 | 14 | ngày |
| `audit_log_retention_years` | Thời gian giữ audit logs | 2 | 1 | 7 | năm |
| `audit_compress_after_days` | Thời gian trước khi compress audit | 30 | 7 | 90 | ngày |
| `metrics_retention_months` | Thời gian giữ system metrics | 6 | 1 | 24 | tháng |
| `aggregate_refresh_5min` | Tần suất refresh vitals_5min | 5 | 1 | 15 | phút |
| `aggregate_refresh_hourly` | Tần suất refresh vitals_hourly | 60 | 30 | 120 | phút |

### Tab 6: Cấu hình thiết bị (Device)

Dựa trên bảng `devices`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `device_offline_timeout_min` | Thời gian không nhận data → đánh dấu offline | 5 | 1 | 30 | phút |
| `low_battery_threshold` | Ngưỡng pin thấp để cảnh báo | 20 | 5 | 50 | % |
| `device_sync_interval_sec` | Khoảng thời gian sync data từ device | 60 | 10 | 300 | giây |
| `allowed_device_types` | Loại thiết bị được phép | `["smartwatch","fitness_band","medical_device"]` | — | — | array |
| `max_devices_per_user` | Số thiết bị tối đa/user | 3 | 1 | 10 | thiết bị |

### Tab 7: Bảo mật (Security)

Dựa trên bảng `users` (auth fields), `password_reset_tokens`:

| Setting Key | Mô tả | Giá trị mặc định | Min | Max | Đơn vị |
|-------------|--------|-------------------|-----|-----|--------|
| `max_failed_login_attempts` | Số lần login sai tối đa trước khi khóa | 5 | 3 | 10 | lần |
| `account_lock_duration_min` | Thời gian khóa tài khoản tạm thời | 30 | 5 | 120 | phút |
| `password_reset_expiry_min` | Thời hạn token reset password | 60 | 15 | 1440 | phút |
| `jwt_access_token_ttl_min` | Thời hạn JWT access token | 15 | 5 | 60 | phút |
| `jwt_refresh_token_ttl_days` | Thời hạn JWT refresh token | 7 | 1 | 30 | ngày |
| `session_max_concurrent` | Số session đồng thời tối đa/user | 5 | 1 | 20 | session |
| `require_password_for_critical` | Yêu cầu nhập lại MK khi thay đổi cấu hình critical | `true` | — | — | boolean |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động | Chi tiết kỹ thuật |
|------|----------------|-----------|--------------------|
| 1 | Admin | Truy cập trang "Cấu hình hệ thống" từ Admin Dashboard. | `GET /api/admin/settings` — Kiểm tra JWT + role `admin`. |
| 2 | Hệ thống | Kiểm tra quyền truy cập. | Verify JWT token → kiểm tra `users.role = 'admin'` AND `users.is_active = true` AND `token_version` khớp. |
| 3 | Hệ thống | Lấy tất cả cấu hình hiện tại từ bảng `system_settings`, nhóm theo `category`. | Query: `SELECT * FROM system_settings ORDER BY category, setting_key`. |
| 4 | Hệ thống | Hiển thị giao diện cấu hình với 7 tab tương ứng 7 nhóm, mỗi field hiển thị giá trị hiện tại, giá trị mặc định, mô tả, và trạng thái validation. | Hiển thị badge "Critical" cho các settings có `is_critical = true`. |
| 5 | Admin | Chỉnh sửa một hoặc nhiều giá trị cấu hình. VD: SpO₂ threshold từ 92% → 93%, countdown từ 30s → 20s. | Frontend validate realtime dựa trên `min_value`, `max_value`, `value_type`. |
| 6 | Admin | Nhấn "Lưu cấu hình". | `PUT /api/admin/settings` với payload chứa các settings đã thay đổi. |
| 7 | Hệ thống | Validate dữ liệu phía server. | Kiểm tra: value type, min/max range, allowed_values (nếu có). |
| 8 | Hệ thống | Kiểm tra có setting nào là `is_critical = true` không. | Nếu có → yêu cầu xác nhận bổ sung (bước 8.a). |
| 9 | Hệ thống | Bắt đầu transaction. Với mỗi setting thay đổi: | `BEGIN TRANSACTION;` |
| 9a | | → Lưu giá trị cũ vào `system_settings_history`. | `INSERT INTO system_settings_history (setting_id, old_value, new_value, version, changed_by)` |
| 9b | | → Cập nhật `system_settings` với giá trị mới, tăng `version`. | `UPDATE system_settings SET setting_value = $new, version = version + 1, updated_by = $admin_id` |
| 9c | | → Ghi audit log. | `INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, ip_address, status)` với `action = 'settings.changed'`, `details = {"category": "...", "key": "...", "old_value": ..., "new_value": ...}` |
| 10 | Hệ thống | Commit transaction. | `COMMIT;` |
| 11 | Hệ thống | Áp dụng cấu hình mới vào runtime. | Broadcast config update event → các service reload cấu hình từ DB/cache. |
| 12 | Hệ thống | Hiển thị thông báo "Cập nhật cấu hình thành công" kèm chi tiết các field đã thay đổi. | Toast notification + highlight các fields vừa cập nhật. |

---

## Luồng thay thế (Alternative Flows)

### 7.a - Giá trị cấu hình không hợp lệ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 7.a.1 | Hệ thống | Phát hiện giá trị ngoài khoảng cho phép. VD: SpO₂ threshold > 100%; countdown < 10 giây; `value_type` không khớp. |
| 7.a.2 | Hệ thống | Trả về HTTP 422 với danh sách lỗi validation cho từng field. |
| 7.a.3 | Hệ thống | Hiển thị thông báo lỗi và đánh dấu trường không hợp lệ (viền đỏ + tooltip lỗi). |
| 7.a.4 | Admin | Sửa lại giá trị hợp lệ và lưu lại → quay về bước 6. |

### 6.a - Hủy thay đổi

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Admin | Nhấn "Hủy" hoặc rời khỏi trang mà không lưu. |
| 6.a.2 | Hệ thống | Hiển thị dialog xác nhận: "Bạn có thay đổi chưa được lưu. Xác nhận hủy?". |
| 6.a.3 | Admin | Xác nhận hủy → Hệ thống không thay đổi cấu hình, reload giá trị gốc. |

### 8.a - Xác nhận thay đổi cấu hình Critical

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 8.a.1 | Hệ thống | Phát hiện có setting critical bị thay đổi (VD: tắt fall detection, thay đổi retention policy). |
| 8.a.2 | Hệ thống | Hiển thị dialog cảnh báo: "Thay đổi này ảnh hưởng đến an toàn hệ thống. Vui lòng nhập mật khẩu để xác nhận." |
| 8.a.3 | Admin | Nhập mật khẩu admin. |
| 8.a.4 | Hệ thống | Xác thực mật khẩu (so sánh hash với `users.password_hash` qua `pgcrypto`). |
| 8.a.5a | | ✅ Thành công → tiếp tục bước 9. |
| 8.a.5b | | ❌ Sai mật khẩu → hiển thị lỗi, cho phép thử lại (tối đa 3 lần). Ghi `audit_logs` với `status = 'failure'`. |

### 11.a - Rollback cấu hình

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 11.a.1 | Admin | Phát hiện cấu hình mới gây lỗi hệ thống (VD: ngưỡng cảnh báo quá nhạy, gây alert spam). |
| 11.a.2 | Admin | Truy cập lịch sử cấu hình (tab "Lịch sử thay đổi"). | 
| 11.a.3 | Hệ thống | Hiển thị danh sách thay đổi từ `system_settings_history` kèm diff (old vs new value). | 
| 11.a.4 | Admin | Chọn "Khôi phục" phiên bản cụ thể. |
| 11.a.5 | Hệ thống | Rollback: cập nhật `system_settings.setting_value` = `history.old_value`, tăng version, ghi audit log với `action = 'settings.rollback'`. |
| 11.a.6 | Hệ thống | Hiển thị thông báo "Đã khôi phục cấu hình phiên bản X". |

### 5.a - Reset về giá trị mặc định

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Admin | Nhấn "Khôi phục mặc định" cho một field cụ thể hoặc toàn bộ tab. |
| 5.a.2 | Hệ thống | Hiển thị dialog xác nhận kèm danh sách các field sẽ bị reset. |
| 5.a.3 | Admin | Xác nhận → Hệ thống gán `setting_value = default_value`, ghi audit log. |

---

## Business Rules

| Mã | Quy tắc | Ánh xạ CSDL |
|----|---------|-------------|
| **BR-024-01** | Chỉ user có `role = 'admin'` và `is_active = true` mới truy cập được màn hình cấu hình. | `users.role`, `users.is_active` |
| **BR-024-02** | Mọi thay đổi cấu hình phải được ghi đầy đủ vào `audit_logs`: ai thay đổi, thời gian, giá trị cũ/mới, IP address. | `audit_logs.action = 'settings.changed'`, `audit_logs.details` (JSONB), `audit_logs.ip_address` |
| **BR-024-03** | Các cấu hình critical (`is_critical = true`) yêu cầu xác nhận bằng mật khẩu admin trước khi lưu. Bao gồm: tắt fall detection, thay đổi retention policy, thay đổi ngưỡng bảo mật. | `system_settings.is_critical`, `users.password_hash` |
| **BR-024-04** | Giá trị cấu hình phải nằm trong khoảng `[min_value, max_value]` và khớp `value_type`. Nếu có `allowed_values`, giá trị phải nằm trong danh sách cho phép. | `system_settings.min_value`, `max_value`, `value_type`, `allowed_values` |
| **BR-024-05** | Hệ thống phải giữ lịch sử thay đổi cấu hình để hỗ trợ rollback. Mỗi lần thay đổi tăng `version` lên 1. | `system_settings.version`, `system_settings_history` |
| **BR-024-06** | Thay đổi retention policy phải tuân thủ yêu cầu compliance: audit logs tối thiểu 1 năm (HIPAA), vitals data tối thiểu 90 ngày. | `system_settings.min_value` cho retention settings |
| **BR-024-07** | Ngưỡng cảnh báo sinh hiệu phải phù hợp y khoa: SpO₂ ≥ 70%, nhịp tim ≥ 30 BPM, nhiệt độ ≥ 33°C. Không cho phép cấu hình ngưỡng phi thực tế. | `system_settings.min_value`, `system_settings.max_value` |
| **BR-024-08** | Khi thay đổi cấu hình AI (model version, algorithm), hệ thống phải kiểm tra tính tương thích trước khi áp dụng. | Validate tại tầng application logic |
| **BR-024-09** | Mỗi thao tác cấu hình phải là atomic (tất cả thành công hoặc tất cả rollback) — sử dụng database transaction. | PostgreSQL `BEGIN/COMMIT/ROLLBACK` |
| **BR-024-10** | Cấu hình `fall_auto_sos_enabled = false` phải yêu cầu xác nhận 2 lần vì ảnh hưởng trực tiếp đến an toàn bệnh nhân. | `system_settings.is_critical = true` |

---

## Luồng ngoại lệ (Exception Flows)

| Mã | Ngoại lệ | Xử lý |
|----|----------|-------|
| **EX-024-01** | Mất kết nối DB khi đang lưu | Rollback transaction, hiển thị lỗi "Không thể lưu cấu hình. Vui lòng thử lại.", ghi `audit_logs` với `status = 'failure'`. |
| **EX-024-02** | JWT hết hạn trong khi đang chỉnh sửa | Redirect đến trang đăng nhập. Cấu hình đang chỉnh sửa được lưu tạm vào localStorage để khôi phục sau khi login lại. |
| **EX-024-03** | Concurrent edit conflict (2 admin sửa cùng lúc) | Kiểm tra `version` trước khi update (Optimistic Locking). Nếu version không khớp → thông báo "Cấu hình đã được thay đổi bởi admin khác. Vui lòng tải lại." |
| **EX-024-04** | Cấu hình mới gây lỗi runtime | Hệ thống tự động phát hiện qua `system_metrics` → gửi alert cho admin. Admin có thể rollback qua luồng 11.a. |
| **EX-024-05** | Admin bị khóa tài khoản (`locked_until > NOW()`) | Từ chối truy cập, hiển thị thời gian còn lại trước khi mở khóa. |

---

## API Endpoints

| Method | Endpoint | Mô tả | Request/Response |
|--------|----------|-------|------------------|
| `GET` | `/api/admin/settings` | Lấy toàn bộ cấu hình, nhóm theo category | Response: `{ categories: { vital_thresholds: [...], ... } }` |
| `GET` | `/api/admin/settings/:category` | Lấy cấu hình theo nhóm cụ thể | Response: `{ settings: [...] }` |
| `PUT` | `/api/admin/settings` | Cập nhật nhiều cấu hình cùng lúc (batch) | Request: `{ changes: [{ category, key, value }], password?: string }` |
| `PUT` | `/api/admin/settings/:category/:key` | Cập nhật 1 cấu hình cụ thể | Request: `{ value, password?: string }` |
| `POST` | `/api/admin/settings/reset` | Reset cấu hình về mặc định | Request: `{ category?: string, keys?: string[] }` |
| `GET` | `/api/admin/settings/history` | Lấy lịch sử thay đổi cấu hình | Query: `?category=&page=&limit=` |
| `POST` | `/api/admin/settings/rollback/:historyId` | Rollback cấu hình về phiên bản cũ | Response: `{ restored_settings: [...] }` |

---

## Yêu cầu phi chức năng

### Security
- **Xác thực**: Bảo vệ tất cả endpoints bằng JWT middleware + kiểm tra `role = 'admin'`.
- **Xác nhận bổ sung**: Cấu hình critical yêu cầu xác thực lại password (`require_password_for_critical`).
- **Audit trail**: Ghi đầy đủ log vào `audit_logs` (who, when, what, from_where) — tuân thủ HIPAA/GDPR.
- **Rate limiting**: Giới hạn tần suất gọi API settings (VD: max 30 requests/phút/admin).
- **Input sanitization**: Validate và sanitize tất cả input trước khi lưu vào JSONB.

### Performance
- **Caching**: Cache cấu hình trong Redis/memory với TTL 5 phút. Invalidate cache khi có thay đổi.
- **Response time**: API settings phải phản hồi < 500ms.
- **Lazy loading**: Chỉ load cấu hình của tab đang active (không load tất cả 7 tab cùng lúc).

### Reliability
- **Atomic operations**: Sử dụng DB transaction cho mọi thay đổi cấu hình.
- **Rollback**: Hỗ trợ rollback bất kỳ thay đổi nào thông qua `system_settings_history`.
- **Optimistic locking**: Sử dụng `version` field để tránh concurrent edit conflicts.
- **Default fallback**: Nếu không đọc được cấu hình từ DB → sử dụng `default_value`.

### Usability
- **Tab-based UI**: Nhóm cấu hình theo 7 tab: Cảnh báo, Fall Detection, AI/ML, Thông báo, Lưu trữ, Thiết bị, Bảo mật.
- **Inline validation**: Realtime validation khi user nhập giá trị (hiển thị min/max, kiểu dữ liệu).
- **Diff view**: Hiển thị so sánh trước/sau khi lưu (confirmation dialog).
- **Search**: Cho phép tìm kiếm cấu hình theo tên hoặc mô tả.
- **Unsaved changes warning**: Cảnh báo khi rời trang có thay đổi chưa lưu.
- **Default reset**: Nút "Khôi phục mặc định" cho từng field và từng tab.

### Compliance
- **HIPAA**: Audit logs lưu tối thiểu 2 năm (`audit_log_retention_years ≥ 1`).
- **GDPR**: Không lưu thông tin cá nhân trong `system_settings`. Retention policies phải configurable.

---

## Ma trận truy xuất (Traceability Matrix)

| Yêu cầu | Bảng CSDL | API | UI Component |
|----------|-----------|-----|--------------|
| Cấu hình ngưỡng vitals | `system_settings` (category=vital_thresholds) | `PUT /api/admin/settings` | Tab "Cảnh báo" |
| Cấu hình fall detection | `system_settings` (category=fall_detection) | `PUT /api/admin/settings` | Tab "Fall Detection" |
| Cấu hình AI/ML | `system_settings` (category=ai_config) | `PUT /api/admin/settings` | Tab "AI/ML" |
| Cấu hình thông báo | `system_settings` (category=notification) | `PUT /api/admin/settings` | Tab "Thông báo" |
| Cấu hình retention | `system_settings` (category=retention) | `PUT /api/admin/settings` | Tab "Lưu trữ" |
| Cấu hình device | `system_settings` (category=device) | `PUT /api/admin/settings` | Tab "Thiết bị" |
| Cấu hình bảo mật | `system_settings` (category=security) | `PUT /api/admin/settings` | Tab "Bảo mật" |
| Ghi audit log | `audit_logs` | — (internal) | Tab "Lịch sử thay đổi" |
| Rollback cấu hình | `system_settings_history` | `POST /api/admin/settings/rollback/:id` | Dialog rollback |
| Xác thực admin | `users` | JWT middleware | Login form |

---

## Wireframe mô tả (Text-based)

```
┌─────────────────────────────────────────────────────────────────┐
│ HealthGuard Admin > Cấu hình hệ thống            [🔍 Tìm kiếm]│
├─────────────────────────────────────────────────────────────────┤
│ [Cảnh báo] [Fall Detection] [AI/ML] [Thông báo] [Lưu trữ]     │
│ [Thiết bị] [Bảo mật] [Lịch sử thay đổi]                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─ Tab: Cảnh báo sinh hiệu ─────────────────────────────────┐ │
│  │                                                             │ │
│  │  SpO₂ ngưỡng thấp          [  93  ] %    (Mặc định: 92)   │ │
│  │  ├─ Min: 70  |  Max: 100                                   │ │
│  │                                                             │ │
│  │  Nhịp tim ngưỡng cao       [ 120  ] BPM  (Mặc định: 120)  │ │
│  │  ├─ Min: 60  |  Max: 250                                   │ │
│  │                                                             │ │
│  │  Nhịp tim ngưỡng thấp      [  50  ] BPM  (Mặc định: 50)   │ │
│  │  ├─ Min: 30  |  Max: 80                                    │ │
│  │                                                             │ │
│  │  Nhiệt độ ngưỡng cao       [ 37.8 ] °C   (Mặc định: 37.8) │ │
│  │                                                             │ │
│  │  Severity mặc định         [▼ High    ]   (Mặc định: High) │ │
│  │                                                             │ │
│  │  Số đọc liên tục trước     [   3  ] lần  (Mặc định: 3)    │ │
│  │  khi cảnh báo                                               │ │
│  │                                                             │ │
│  │  [Khôi phục mặc định tab]                                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│           [ Hủy ]                    [ 💾 Lưu cấu hình ]       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
