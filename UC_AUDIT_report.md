# BÁO CÁO KIỂM TRA USE CASE — HealthGuard

> **Ngày**: 08/03/2026
> **Phiên bản**: 2 (Post-Audit with Fix Plan)
> **Tổng UC kiểm tra**: 26
> **Công cụ**: UC_AUDIT Skill v1.0

---

## 1. TỔNG QUAN KIỂM TRA

| Metric                  | Kết quả                        |
| ----------------------- | ------------------------------ |
| Tổng UC                 | 26                             |
| UC đạt chất lượng       | 18                             |
| UC cần sửa              | 10                             |
| HG-FUNC được phủ        | 11/11 (Thiếu định nghĩa Sleep) |
| UC có JIRA Task         | 24/26                          |
| Cột SQL được phủ bởi UC | ~80% (Thiếu bảng Sleep)        |
| Tổng findings           | 35                             |

---

## 2. BẢNG KIỂM TRA UC (Inventory)

### 2.1 Authentication (6 UC)

| UC    | Tên               | Actors         | Platform       | Steps | Alt Flows | BRs | Relevance  | Quality | JIRA          | Issues             |
| ----- | ----------------- | -------------- | -------------- | ----- | --------- | --- | ---------- | ------- | ------------- | ------------------ |
| UC001 | Đăng nhập         | BN, NCS, Admin | Mobile + Admin | 7     | 2         | 5   | SUPPORTING | ⚠️       | EP04-Login    | BR naming generic  |
| UC002 | Đăng ký tài khoản | BN, NCS        | Mobile         | 7     | 3         | 4   | SUPPORTING | ⚠️       | EP05-Register | BR naming generic  |
| UC003 | Quên mật khẩu     | BN, NCS        | Mobile         | 9     | 5         | 6   | SUPPORTING | ⚠️       | EP12-Password | Alt flow numbering |
| UC004 | Thay đổi mật khẩu | BN, NCS        | Mobile         | 8     | 4         | 6   | SUPPORTING | ⚠️       | EP12-Password | Alt flow numbering |
| UC005 | Quản lý hồ sơ     | BN, NCS        | Mobile         | 7     | 3         | 5   | SUPPORTING | ⚠️       | ❌ Không có    | UC_NO_TASK, DB ref |
| UC009 | Đăng xuất         | BN, NCS, Admin | Mobile + Admin | 7     | 3         | 5   | SUPPORTING | ✅       | ❌ Không có    | UC_NO_TASK         |

### 2.2 Monitoring (3 UC)

| UC    | Tên                 | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA            | Issues |
| ----- | ------------------- | ------- | -------- | ----- | --------- | --- | --------- | ------- | --------------- | ------ |
| UC006 | Xem chỉ số sức khỏe | BN, NCS | Mobile   | 5     | 3         | 5*  | CORE      | ✅       | EP08-Monitoring | —      |
| UC007 | Chi tiết chỉ số     | BN, NCS | Mobile   | 6     | 3         | 4   | CORE      | ✅       | EP08-Monitoring | —      |
| UC008 | Lịch sử chỉ số      | BN, NCS | Mobile   | 6     | 3         | 4   | CORE      | ✅       | EP08-Monitoring | —      |

### 2.3 Emergency (4 UC)

| UC    | Tên                 | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA            | Issues            |
| ----- | ------------------- | ------- | -------- | ----- | --------- | --- | --------- | ------- | --------------- | ----------------- |
| UC010 | Xác nhận sau té ngã | BN      | Mobile   | 6     | 2         | 4   | CORE      | ⚠️       | EP09-FallDetect | BR naming generic |
| UC011 | Xác nhận an toàn    | BN, NCS | Mobile   | 6     | 2         | 4   | CORE      | ✅       | EP10-SOS        | —                 |
| UC014 | Gửi SOS thủ công    | BN      | Mobile   | 8     | 4         | 4   | CORE      | ⚠️       | EP10-SOS        | BR naming generic |
| UC015 | Nhận SOS            | NCS     | Mobile   | 6     | 3         | 4   | CORE      | ⚠️       | EP10-SOS        | DB refs in text   |

### 2.4 Analysis (2 UC)

| UC    | Tên                | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA           | Issues            |
| ----- | ------------------ | ------- | -------- | ----- | --------- | --- | --------- | ------- | -------------- | ----------------- |
| UC016 | Xem báo cáo rủi ro | BN, NCS | Mobile   | 7     | 4         | 4   | CORE      | ⚠️       | EP13-RiskScore | BR naming generic |
| UC017 | Chi tiết rủi ro    | BN, NCS | Mobile   | 6     | 2         | 4   | CORE      | ⚠️       | EP13-RiskScore | DB refs in text   |

### 2.5 Sleep (2 UC)

| UC    | Tên                  | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA       | Issues |
| ----- | -------------------- | ------- | -------- | ----- | --------- | --- | --------- | ------- | ---------- | ------ |
| UC020 | Phân tích giấc ngủ   | BN      | Mobile   | 5     | 2         | 3   | CORE      | ✅       | EP14-Sleep | —      |
| UC021 | Xem báo cáo giấc ngủ | BN, NCS | Mobile   | 5     | 2         | 3   | CORE      | ✅       | EP14-Sleep | —      |

### 2.6 Admin (4 UC)

| UC    | Tên                  | Actors | Platform  | Steps | Alt Flows | BRs | Relevance  | Quality | JIRA             | Issues            |
| ----- | -------------------- | ------ | --------- | ----- | --------- | --- | ---------- | ------- | ---------------- | ----------------- |
| UC022 | Quản lý người dùng   | Admin  | Admin Web | 5     | 5         | 5   | MANAGEMENT | ⚠️       | EP15-AdminManage | BR naming generic |
| UC024 | Cấu hình hệ thống    | Admin  | Admin Web | 8     | 2         | 3   | MANAGEMENT | ✅       | EP16-AdminConfig | —                 |
| UC025 | Quản lý thiết bị     | Admin  | Admin Web | 4     | 3         | 3   | MANAGEMENT | ✅       | EP15-AdminManage | —                 |
| UC026 | Xem nhật ký hệ thống | Admin  | Admin Web | 6     | 2         | 3   | MANAGEMENT | ✅       | EP16-AdminConfig | —                 |

### 2.7 Notification (2 UC)

| UC    | Tên                | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA              | Issues          |
| ----- | ------------------ | ------- | -------- | ----- | --------- | --- | --------- | ------- | ----------------- | --------------- |
| UC030 | Emergency Contacts | BN      | Mobile   | 8     | 2         | 3   | CORE      | ⚠️       | EP11-Notification | DB refs in text |
| UC031 | Quản lý thông báo  | BN, NCS | Mobile   | 6     | 3         | 3   | CORE      | ⚠️       | EP11-Notification | DB refs in text |

### 2.8 Device (3 UC)

| UC    | Tên               | Actors  | Platform | Steps | Alt Flows | BRs | Relevance | Quality | JIRA        | Issues          |
| ----- | ----------------- | ------- | -------- | ----- | --------- | --- | --------- | ------- | ----------- | --------------- |
| UC040 | Kết nối thiết bị  | BN      | Mobile   | 6     | 2         | 3   | CORE      | ⚠️       | EP07-Device | DB refs in text |
| UC041 | Cấu hình thiết bị | BN      | Mobile   | 6     | 2         | 2   | CORE      | ✅       | EP07-Device | —               |
| UC042 | Xem trạng thái    | BN, NCS | Mobile   | 5     | 2         | 2   | CORE      | ⚠️       | EP07-Device | DB refs in text |

> **Ghi chú**: BN = Bệnh nhân, NCS = Người chăm sóc

### 2.9 Chi tiết bổ sung (Data Fields, DB Tables, NFR)

| UC    | Data Fields                                                                                                                                         | DB Tables Referenced                                           | NFR Categories                                        |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------- |
| UC001 | email, password, JWT token, role                                                                                                                    | users                                                          | Performance, Security, Usability                      |
| UC002 | email, password, full_name, phone, date_of_birth, role, is_verified                                                                                 | users                                                          | Performance, Security, Usability, Privacy             |
| UC003 | email, password, reset token                                                                                                                        | users                                                          | Performance, Security, Usability, Reliability         |
| UC004 | current password, new password                                                                                                                      | users                                                          | Performance, Security, Usability, Auditability        |
| UC005 | full_name, phone, date_of_birth, gender, avatar_url, medical_conditions, blood_type, height_cm, weight_kg, medications, allergies                   | users                                                          | Privacy, Usability, Performance, Security             |
| UC009 | JWT token, FCM push token, refresh token                                                                                                            | users, audit_logs                                              | Security, Usability, Performance, Safety              |
| UC006 | heart_rate, spo2, blood_pressure, temperature                                                                                                       | vitals                                                         | Performance, Usability, Security                      |
| UC007 | heart_rate/spo2/bp/temp (detail), time range, min/max/avg                                                                                           | vitals (aggregated)                                            | Performance, Usability, Security                      |
| UC008 | heart_rate/spo2/bp/temp (history), time range                                                                                                       | vitals (aggregated)                                            | Performance, Usability, Security/Privacy              |
| UC010 | confidence, accel/gyro features, GPS, cancel_reason                                                                                                 | fall_events                                                    | Accuracy, Performance, Safety, Usability              |
| UC011 | sos/fall event status, resolved_at, resolved_by_user_id                                                                                             | sos_events, fall_events                                        | Safety, Usability, Reliability                        |
| UC014 | GPS (lat/long), trigger_type, priority, address                                                                                                     | sos_events, emergency_contacts                                 | Performance, Reliability, Security, Safety, Privacy   |
| UC015 | sos status, trigger_type, GPS, resolved_at, resolved_by, resolution_notes                                                                           | sos_events, user_relationships, emergency_contacts, audit_logs | Performance, Reliability, Usability, Security/Privacy |
| UC016 | score, risk_level, feature_importance, risk_type                                                                                                    | risk_scores, risk_explanations                                 | Accuracy, Performance, Transparency, Privacy          |
| UC017 | score, risk_level, risk_type, features, explanation_text, recommendations                                                                           | risk_scores, risk_explanations                                 | Transparency, Performance, Privacy                    |
| UC020 | heart_rate (sleep), motion_data, sleep duration, wake count                                                                                         | vitals, motion_data                                            | Performance, Usability, Privacy                       |
| UC021 | sleep quality score, sleep phases, duration, wake count                                                                                             | (sleep analysis results)                                       | Usability, Performance, Privacy                       |
| UC022 | email, full_name, phone, role, is_active, deleted_at                                                                                                | users, audit_logs                                              | Security, Performance, Data Integrity, Usability      |
| UC024 | system config params (thresholds, AI config, notification channels)                                                                                 | system_config, audit_logs                                      | Security, Reliability, Usability                      |
| UC025 | device_name, device_type, model, firmware_version, mac_address, serial_number, is_active, user_id, battery_level, signal_strength, calibration_data | devices, audit_logs                                            | Security, Performance, Usability                      |
| UC026 | action, resource_type, resource_id, details, ip_address, user_agent, status                                                                         | audit_logs                                                     | Security, Performance, Auditability                   |
| UC030 | name, phone, relationship, priority, notify_via_sms, notify_via_call                                                                                | emergency_contacts, user_relationships                         | Usability, Security/Privacy                           |
| UC031 | alert_type, title, message, severity, data, read_at, sent_via, expires_at                                                                           | alerts                                                         | Usability, Performance, Privacy                       |
| UC040 | serial_number, device code/QR, user_id, is_active                                                                                                   | devices, audit_logs                                            | Usability, Security                                   |
| UC041 | calibration_data, device config params                                                                                                              | devices                                                        | Usability, Reliability                                |
| UC042 | device_name, battery_level, signal_strength, last_seen_at, last_sync_at                                                                             | devices                                                        | Usability, Performance                                |

---

## 3. ĐÁNH GIÁ TÍNH LIÊN QUAN (SRS Alignment)

### 3.1 HG-FUNC Coverage

| HG-FUNC    | Description                          | UCs                  | Status                    |
| ---------- | ------------------------------------ | -------------------- | ------------------------- |
| HG-FUNC-01 | Thu thập dữ liệu sinh tồn mỗi 1 phút | (background process) | ✅ N/A — không cần UC      |
| HG-FUNC-02 | Hiển thị trên Mobile App ≤5s latency | UC006, UC007         | ✅ Covered                 |
| HG-FUNC-03 | Cảnh báo khi vượt ngưỡng             | UC006, UC031         | ✅ Covered                 |
| HG-FUNC-04 | AI phát hiện té ngã                  | (background process) | ✅ N/A — trigger cho UC010 |
| HG-FUNC-05 | AI trigger "Fall Alert"              | UC010                | ✅ Covered                 |
| HG-FUNC-06 | App: rung + âm thanh + countdown 30s | UC010                | ✅ Covered                 |
| HG-FUNC-07 | Auto-SOS với GPS nếu không phản hồi  | UC010→UC014→UC015    | ✅ Covered (trigger chain) |
| HG-FUNC-08 | Risk Score = f(HRV, SpO₂, HR, BP)    | UC016                | ✅ Covered                 |
| HG-FUNC-09 | XAI explanation cho HIGH risk        | UC016, UC017         | ✅ Covered                 |
| HG-FUNC-10 | Stream processing từ nhiều simulator | (background process) | ✅ N/A — Infra task        |
| HG-FUNC-11 | Lưu trữ lịch sử trong PostgreSQL     | UC008                | ✅ Covered                 |

**Kết quả**: 11/11 HG-FUNC được phủ ✅ (3 background processes đúng là N/A)

### 3.2 UC Relevance Classification

| Level      | UCs                                                                                                            | Count |
| ---------- | -------------------------------------------------------------------------------------------------------------- | ----- |
| CORE       | UC006, UC007, UC008, UC010, UC011, UC014, UC015, UC016, UC017, UC020, UC021, UC030, UC031, UC040, UC041, UC042 | 16    |
| SUPPORTING | UC001, UC002, UC003, UC004, UC005, UC009                                                                       | 6     |
| MANAGEMENT | UC022, UC024, UC025, UC026                                                                                     | 4     |
| LOW        | (không có)                                                                                                     | 0     |

**Kết luận**: Không có `ORPHAN_UC` — tất cả 26 UC đều có mục đích rõ ràng.

---

## 4. KIỂM TRA CHÉO (Cross-Check)

### 4.1 UC ↔ JIRA Gaps

| UC        | Expected Epic     | Actual            | Status | Flag           |
| --------- | ----------------- | ----------------- | ------ | -------------- |
| UC001     | EP04-Login        | EP04-Login        | ✅      | —              |
| UC002     | EP05-Register     | EP05-Register     | ✅      | —              |
| UC003     | EP12-Password     | EP12-Password     | ✅      | —              |
| UC004     | EP12-Password     | EP12-Password     | ✅      | —              |
| **UC005** | **???**           | **Not found**     | ❌      | **UC_NO_TASK** |
| UC006     | EP08-Monitoring   | EP08-Monitoring   | ✅      | —              |
| UC007     | EP08-Monitoring   | EP08-Monitoring   | ✅      | —              |
| UC008     | EP08-Monitoring   | EP08-Monitoring   | ✅      | —              |
| **UC009** | **???**           | **Not found**     | ❌      | **UC_NO_TASK** |
| UC010     | EP09-FallDetect   | EP09-FallDetect   | ✅      | —              |
| UC011     | EP10-SOS          | EP10-SOS          | ✅      | —              |
| UC014     | EP10-SOS          | EP10-SOS          | ✅      | —              |
| UC015     | EP10-SOS          | EP10-SOS          | ✅      | —              |
| UC016     | EP13-RiskScore    | EP13-RiskScore    | ✅      | —              |
| UC017     | EP13-RiskScore    | EP13-RiskScore    | ✅      | —              |
| UC020     | EP14-Sleep        | EP14-Sleep        | ✅      | —              |
| UC021     | EP14-Sleep        | EP14-Sleep        | ✅      | —              |
| UC022     | EP15-AdminManage  | EP15-AdminManage  | ✅      | —              |
| UC024     | EP16-AdminConfig  | EP16-AdminConfig  | ✅      | —              |
| UC025     | EP15-AdminManage  | EP15-AdminManage  | ✅      | —              |
| UC026     | EP16-AdminConfig  | EP16-AdminConfig  | ✅      | —              |
| UC030     | EP11-Notification | EP11-Notification | ✅      | —              |
| UC031     | EP11-Notification | EP11-Notification | ✅      | —              |
| UC040     | EP07-Device       | EP07-Device       | ✅      | —              |
| UC041     | EP07-Device       | EP07-Device       | ✅      | —              |
| UC042     | EP07-Device       | EP07-Device       | ✅      | —              |

**Epics không cần UC** (Infra — chấp nhận):
- EP01-Database, EP02-AdminBE, EP03-MobileBE, EP06-Ingestion

**Tổng**: 24/26 UC có JIRA Task ✅ | 2 UC thiếu task ❌ (UC005, UC009)

### 4.2 UC ↔ SQL Gaps

#### Bảng `users` (02_create_tables_user_management.sql)

| Column             | Type        | Covered by UC              | Status          |
| ------------------ | ----------- | -------------------------- | --------------- |
| email              | VARCHAR     | UC001, UC002, UC003, UC005 | ✅               |
| password_hash      | VARCHAR     | UC001, UC002, UC003, UC004 | ✅               |
| phone              | VARCHAR     | UC002, UC005               | ✅               |
| full_name          | VARCHAR     | UC002, UC005, UC022        | ✅               |
| date_of_birth      | DATE        | UC002, UC005               | ✅               |
| gender             | VARCHAR     | UC005                      | ✅               |
| avatar_url         | TEXT        | UC005                      | ✅               |
| role               | VARCHAR     | UC001, UC002, UC022        | ✅               |
| is_active          | BOOLEAN     | UC022                      | ✅               |
| is_verified        | BOOLEAN     | UC002                      | ⚠️ WEAK_COVERAGE |
| blood_type         | VARCHAR     | —                          | ⚠️ ORPHAN_COLUMN |
| height_cm          | SMALLINT    | —                          | ⚠️ ORPHAN_COLUMN |
| weight_kg          | DECIMAL     | —                          | ⚠️ ORPHAN_COLUMN |
| medical_conditions | TEXT[]      | UC005 ("tiền sử bệnh lý")  | ✅               |
| medications        | TEXT[]      | —                          | ⚠️ ORPHAN_COLUMN |
| allergies          | TEXT[]      | —                          | ⚠️ ORPHAN_COLUMN |
| language           | VARCHAR     | —                          | ⚠️ ORPHAN_COLUMN |
| timezone           | VARCHAR     | —                          | ⚠️ ORPHAN_COLUMN |
| last_login_at      | TIMESTAMPTZ | UC001 (implicit)           | ⚠️ WEAK_COVERAGE |

#### Bảng `user_relationships` (02_create_tables_user_management.sql)

| Column             | Type    | Covered by UC       | Status          |
| ------------------ | ------- | ------------------- | --------------- |
| patient_id         | INT     | UC015, UC030        | ✅               |
| caregiver_id       | INT     | UC015, UC030        | ✅               |
| relationship_type  | VARCHAR | UC030               | ✅               |
| is_primary         | BOOLEAN | UC030               | ✅               |
| can_view_vitals    | BOOLEAN | UC007, UC008, UC017 | ✅               |
| can_receive_alerts | BOOLEAN | UC015               | ✅               |
| can_view_location  | BOOLEAN | —                   | ⚠️ ORPHAN_COLUMN |

#### Bảng `emergency_contacts` (02_create_tables_user_management.sql)

| Column          | Type     | Covered by UC | Status |
| --------------- | -------- | ------------- | ------ |
| name            | VARCHAR  | UC030         | ✅      |
| phone           | VARCHAR  | UC030         | ✅      |
| relationship    | VARCHAR  | UC030         | ✅      |
| priority        | SMALLINT | UC030, UC014  | ✅      |
| notify_via_sms  | BOOLEAN  | UC030         | ✅      |
| notify_via_call | BOOLEAN  | UC030         | ✅      |

#### Bảng `devices` (03_create_tables_devices.sql)

| Column           | Type        | Covered by UC | Status          |
| ---------------- | ----------- | ------------- | --------------- |
| user_id          | INT         | UC040, UC025  | ✅               |
| device_name      | VARCHAR     | UC025, UC042  | ✅               |
| device_type      | VARCHAR     | UC025         | ✅               |
| model            | VARCHAR     | UC025         | ✅               |
| firmware_version | VARCHAR     | UC025         | ✅               |
| mac_address      | VARCHAR     | UC025         | ✅               |
| serial_number    | VARCHAR     | UC040         | ✅               |
| is_active        | BOOLEAN     | UC025, UC040  | ✅               |
| battery_level    | SMALLINT    | UC042         | ✅               |
| signal_strength  | SMALLINT    | UC042         | ✅               |
| last_seen_at     | TIMESTAMPTZ | UC042         | ✅               |
| last_sync_at     | TIMESTAMPTZ | UC042         | ✅               |
| mqtt_client_id   | VARCHAR     | —             | ⚠️ ORPHAN_COLUMN |
| calibration_data | JSONB       | UC041         | ✅               |

#### Bảng `fall_events` (05_create_tables_events_alerts.sql)

| Column             | Type        | Covered by UC | Status          |
| ------------------ | ----------- | ------------- | --------------- |
| device_id          | INT         | UC010         | ✅               |
| detected_at        | TIMESTAMPTZ | UC010         | ✅               |
| confidence         | DECIMAL     | UC010         | ✅               |
| model_version      | VARCHAR     | —             | ⚠️ ORPHAN_COLUMN |
| latitude/longitude | DECIMAL     | UC010, UC014  | ✅               |
| location_accuracy  | REAL        | —             | ⚠️ ORPHAN_COLUMN |
| address            | TEXT        | UC014         | ✅               |
| user_notified_at   | TIMESTAMPTZ | UC010         | ✅               |
| user_responded_at  | TIMESTAMPTZ | UC010         | ✅               |
| user_cancelled     | BOOLEAN     | UC010         | ✅               |
| cancel_reason      | VARCHAR     | —             | ⚠️ ORPHAN_COLUMN |
| sos_triggered      | BOOLEAN     | UC010         | ✅               |
| features           | JSONB       | UC010 (XAI)   | ✅               |

#### Bảng `sos_events` (05_create_tables_events_alerts.sql)

| Column              | Type        | Covered by UC | Status |
| ------------------- | ----------- | ------------- | ------ |
| fall_event_id       | INT         | UC010→UC014   | ✅      |
| device_id           | INT         | UC014         | ✅      |
| user_id             | INT         | UC014         | ✅      |
| trigger_type        | VARCHAR     | UC014, UC015  | ✅      |
| status              | VARCHAR     | UC011, UC015  | ✅      |
| resolved_at         | TIMESTAMPTZ | UC011, UC015  | ✅      |
| resolved_by_user_id | INT         | UC011, UC015  | ✅      |
| resolution_notes    | TEXT        | UC015         | ✅      |
| latitude/longitude  | DECIMAL     | UC014         | ✅      |

#### Bảng `alerts` (05_create_tables_events_alerts.sql)

| Column          | Type        | Covered by UC | Status          |
| --------------- | ----------- | ------------- | --------------- |
| user_id         | INT         | UC031         | ✅               |
| alert_type      | VARCHAR     | UC031         | ✅               |
| title           | VARCHAR     | UC031         | ✅               |
| message         | TEXT        | UC031         | ✅               |
| severity        | VARCHAR     | UC031         | ✅               |
| data            | JSONB       | UC031         | ✅               |
| read_at         | TIMESTAMPTZ | UC031         | ✅               |
| sent_via        | TEXT[]      | UC031         | ✅               |
| expires_at      | TIMESTAMPTZ | UC031         | ✅               |
| acknowledged_at | TIMESTAMPTZ | —             | ⚠️ ORPHAN_COLUMN |

#### Bảng `risk_scores` (06_create_tables_ai_analytics.sql)

| Column        | Type        | Covered by UC | Status          |
| ------------- | ----------- | ------------- | --------------- |
| user_id       | INT         | UC016         | ✅               |
| calculated_at | TIMESTAMPTZ | UC016, UC017  | ✅               |
| risk_type     | VARCHAR     | UC017         | ✅               |
| score         | DECIMAL     | UC016, UC017  | ✅               |
| risk_level    | VARCHAR     | UC016, UC017  | ✅               |
| features      | JSONB       | UC017         | ✅               |
| model_version | VARCHAR     | —             | ⚠️ ORPHAN_COLUMN |
| algorithm     | VARCHAR     | —             | ⚠️ ORPHAN_COLUMN |

#### Bảng `risk_explanations` (06_create_tables_ai_analytics.sql)

| Column             | Type    | Covered by UC | Status          |
| ------------------ | ------- | ------------- | --------------- |
| risk_score_id      | INT     | UC017         | ✅               |
| explanation_text   | TEXT    | UC017         | ✅               |
| feature_importance | JSONB   | UC016, UC017  | ✅               |
| xai_method         | VARCHAR | —             | ⚠️ ORPHAN_COLUMN |
| recommendations    | TEXT[]  | UC017         | ✅               |

#### Bảng `audit_logs` (07_create_tables_system.sql)

| Column        | Type    | Covered by UC              | Status |
| ------------- | ------- | -------------------------- | ------ |
| user_id       | INT     | UC026                      | ✅      |
| action        | VARCHAR | UC009, UC022, UC024, UC026 | ✅      |
| resource_type | VARCHAR | UC026                      | ✅      |
| resource_id   | INT     | UC026                      | ✅      |
| details       | JSONB   | UC026                      | ✅      |
| ip_address    | INET    | UC026                      | ✅      |
| user_agent    | TEXT    | UC026                      | ✅      |
| status        | VARCHAR | UC026                      | ✅      |

#### Bảng `system_metrics` (07_create_tables_system.sql)
→ Bảng infra/monitoring, không cần UC phủ. ✅ N/A

#### Tổng hợp ORPHAN_COLUMN

| Table              | Column            | Lý do có thể chấp nhận                             |
| ------------------ | ----------------- | -------------------------------------------------- |
| users              | blood_type        | Medical data — nên bổ sung vào UC005               |
| users              | height_cm         | Medical data — nên bổ sung vào UC005               |
| users              | weight_kg         | Medical data — nên bổ sung vào UC005               |
| users              | medications       | Medical data — nên bổ sung vào UC005               |
| users              | allergies         | Medical data — nên bổ sung vào UC005               |
| users              | language          | Preference — implicit, chấp nhận                   |
| users              | timezone          | Preference — implicit, chấp nhận                   |
| user_relationships | can_view_location | Privacy control — nên bổ sung vào UC030 hoặc UC005 |
| devices            | mqtt_client_id    | Infra field — chấp nhận (backend internal)         |
| fall_events        | model_version     | AI internal — chấp nhận                            |
| fall_events        | location_accuracy | GPS detail — implicit, chấp nhận                   |
| fall_events        | cancel_reason     | Nên bổ sung vào UC010 (user feedback)              |
| alerts             | acknowledged_at   | Flow detail — nên bổ sung vào UC031                |
| risk_scores        | model_version     | AI internal — chấp nhận                            |
| risk_scores        | algorithm         | AI internal — chấp nhận                            |
| risk_explanations  | xai_method        | AI internal — chấp nhận                            |

**Tổng**: 16 orphan columns (7 chấp nhận được, **9 nên bổ sung vào UC**)

### 4.3 Internal Consistency

| #   | Check                | Source A                    | Source B              | Match | Flag                  |
| --- | -------------------- | --------------------------- | --------------------- | ----- | --------------------- |
| 1   | UC count — list      | 00_DANH_SACH (26 UC)        | Actual files (26)     | ✅     | —                     |
| 2   | UC count — README    | 00_DANH_SACH (26 UC)        | UC/README.md (24 UC)  | ❌     | **STATS_DESYNC**      |
| 3   | Platform — Mobile    | 00_DANH_SACH (22 UC Mobile) | UC/README.md (20 UC)  | ❌     | **PLATFORM_MISMATCH** |
| 4   | Platform — Admin     | 00_DANH_SACH (6 UC Admin)   | UC/README.md (5 UC)   | ❌     | **PLATFORM_MISMATCH** |
| 5   | MASTER_INDEX AUTH    | Module row: UC001-UC004     | Actual: UC001-005+009 | ❌     | **INDEX_MISMATCH**    |
| 6   | Include: UC006→UC007 | UC006 includes UC007        | UC007 exists          | ✅     | —                     |
| 7   | Include: UC016→UC017 | UC016 includes UC017        | UC017 exists          | ✅     | —                     |
| 8   | Extend: UC010→UC014  | UC010 extends to UC014      | UC014 exists          | ✅     | —                     |
| 9   | Deleted UCs          | UC005-old, UC018, UC023     | No zombie files       | ✅     | —                     |

---

## 5. PHÁT HIỆN CHẤT LƯỢNG CHI TIẾT

### 5.1 Alt Flow Numbering Mismatches

| UC    | Issue                                             | Chi tiết                                                                     |
| ----- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| UC003 | Alt flow `10.a`, `10.b` refs step 10              | Main flow chỉ có 9 bước (Phase 1: 5 bước + Phase 2: 4 bước = 9)              |
| UC004 | Alt flow `7.a`, `8.a-c`, `11.a` refs steps 7/8/11 | Main flow chỉ có 8 bước. `7.a` check mật khẩu nhưng bước 5 mới là bước check |

### 5.2 Business Rule Naming Inconsistency

| Pattern                         | UCs sử dụng                                            | Vấn đề                                            |
| ------------------------------- | ------------------------------------------------------ | ------------------------------------------------- |
| **Generic** `BR-001, BR-002...` | UC001, UC002, UC003, UC004, UC010, UC014, UC016, UC022 | Không phân biệt được BR giữa các UC, gây nhầm lẫn |
| **Proper** `BR-{UCID}-{NN}`     | UC005, UC009, UC011, UC015, UC017, UC020-UC042         | ✅ Đúng chuẩn, mỗi BR unique                       |

**Khuyến nghị**: Đổi tất cả BR generic sang format `BR-{UCID}-{NN}` (VD: UC001 → `BR-001-01`, `BR-001-02`)

### 5.3 Technical Details in UC Text

| UC    | Vị trí         | Technical detail                                    | Nên loại bỏ?          |
| ----- | -------------- | --------------------------------------------------- | --------------------- |
| UC004 | NFR/Security   | "Mật khẩu được hash bằng bcrypt"                    | ⚠️ Nên generic         |
| UC005 | Main Flow #6   | "Cập nhật thông tin trong bảng `users`"             | ❌ Phải loại bỏ        |
| UC015 | Precondition   | "`user_relationships` hoặc `emergency_contacts`"    | ⚠️ Nên generic         |
| UC017 | Main Flow #2   | "bảng `risk_scores` và `risk_explanations`"         | ❌ Phải loại bỏ        |
| UC030 | Postcondition  | "bảng `emergency_contacts` và `user_relationships`" | ⚠️ Nên generic         |
| UC031 | Main Flow #2   | "Truy vấn bảng `alerts`"                            | ❌ Phải loại bỏ        |
| UC040 | Main Flow #4-5 | "`devices`", "`user_id`", "`registered_at`"         | ❌ Phải loại bỏ        |
| UC042 | Main Flow #2   | "Truy vấn bảng `devices`"                           | ❌ Phải loại bỏ        |
| UC042 | Alt Flow 5.a   | "`NOW() - last_seen_at > X`"                        | ❌ Phải loại bỏ        |
| UC025 | Alt Flow 4.a-b | "`devices.user_id`", "`is_active = false`"          | ⚠️ Admin UC, chấp nhận |

---

## 6. KHUYẾN NGHỊ ƯU TIÊN

| Priority | Issue                       | Action Required                                                                                        | Affected UCs                                    |
| -------- | --------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| **P0**   | Thiếu luồng CRUD (UC025)    | Bổ sung luồng "Thêm/Import Thiết bị" vào UC025 (Admin). Cập nhật JIRA và SQL.                          | UC025                                           |
| **P0**   | Lỗi Compliance (App Store)  | Bổ sung tính năng "Xóa tài khoản vĩnh viễn" vào hệ thống (tạo UC mới hoặc thêm vào UC009).             | Auth Module                                     |
| **P1**   | Thiếu SQL Schema (Sleep)    | Bổ sung bảng `sleep_sessions` vào database để phục vụ UC020, UC021.                                    | UC020, UC021                                    |
| **P1**   | SRS Orphan UCs              | Bổ sung `HG-FUNC-12: Sleep tracking` vào tài liệu `SRS_INDEX.md`.                                      | UC020, UC021                                    |
| **P1**   | UC_NO_TASK (2)              | Tạo JIRA Story cho UC005 (Profile) và UC009 (Logout) — thêm vào EP04 hoặc EP mới                       | UC005, UC009                                    |
| **P1**   | STATS_DESYNC                | Cập nhật `UC/README.md` v3.0 → v4.0: tổng = 26 UC, thêm UC005+UC009                                    | README.md                                       |
| **P1**   | ORPHAN_COLUMN (medical)     | Bổ sung `blood_type`, `height_cm`, `weight_kg`, `medications`, `allergies` vào UC005                   | UC005                                           |
| **P2**   | INDEX_MISMATCH              | Cập nhật MASTER_INDEX AUTH: UC001-UC004 → UC001-UC005, UC009                                           | MASTER_INDEX                                    |
| **P2**   | PLATFORM_MISMATCH           | Cập nhật UC/README.md Platform Mapping: Mobile = 22, Admin = 6 (thêm UC005, UC009)                     | README.md                                       |
| **P2**   | BR Naming Inconsistency (8) | Đổi BR generic → `BR-{UCID}-{NN}` cho 8 UC cũ                                                          | UC001-004, UC010, UC014, UC016, UC022           |
| **P2**   | Technical details (9 lỗi)   | Xóa tên bảng DB/SQL khỏi Main Flow, Preconditions, Postconditions                                      | UC005, UC015, UC017, UC030, UC031, UC040, UC042 |
| **P2**   | Alt flow numbering (2)      | Sửa numbering cho UC003 (10.a→8.a), UC004 (7.a→5.a)                                                    | UC003, UC004                                    |
| **P2**   | ORPHAN_COLUMN misc (4)      | Bổ sung `can_view_location` vào UC030, `cancel_reason` vào UC010, `acknowledged_at` vào UC031          | UC010, UC030, UC031                             |
| **P3**   | ORPHAN_COLUMN infra (7)     | Chấp nhận: language, timezone, mqtt_client_id, model_version, algorithm, location_accuracy, xai_method | —                                               |

---

## 7. THỐNG KÊ TỔNG HỢP

| Metric                      | Số lượng | Tỷ lệ    |
| --------------------------- | -------- | -------- |
| **UC đạt chuẩn chất lượng** | 18/26    | 69.2%    |
| **UC cần sửa nhỏ**          | 8/26     | 30.8%    |
| **UC CORE**                 | 16       | 61.5%    |
| **UC SUPPORTING**           | 6        | 23.1%    |
| **UC MANAGEMENT**           | 4        | 15.4%    |
| **JIRA Coverage**           | 24/26    | 92.3%    |
| **SRS Coverage**            | 11/11    | 100%     |
| **Findings P0**             | 0        | —        |
| **Findings P1**             | 3        | —        |
| **Findings P2**             | 5        | —        |
| **Findings P3**             | 1        | —        |
| **Total Findings**          | 11 nhóm  | 35 items |

---

## 8. KẾ HOẠCH KHẮC PHỤC (FIX PLAN) TÍNH NĂNG THIẾU

Dựa trên yêu cầu rà soát các luồng CRUD (như UC025 thiếu Thêm Thiết Bị), dưới đây là kế hoạch bổ sung nghiệp vụ chi tiết nhằm đảm bảo vòng đời hệ thống hoàn chỉnh:

### 8.1. Bổ sung luồng "Thêm Thiết Bị" (UC025 - Quản lý thiết bị)
**Vấn đề:** Admin có thể Gán, Khóa thiết bị nhưng chưa có Use Case/Flow cho việc *nhập thiết bị mới* vào kho.
**Hành động chi tiết:**
- **Tài liệu UC (`UC025_Manage_Devices.md`)**: Bổ sung Alt Flow `4.d - Thêm thiết bị thủ công` (nhập form) và `4.e - Import thiết bị hàng loạt` (upload file CSV excel).
- **Thiết kế CSDL (SQL)**: Bảng `devices` cần làm rõ trạng thái thiết bị rảnh (VD: bổ sung field `is_provisioned` hoặc mặc định `user_id = NULL`).
- **JIRA Task**: Tạo thêm Story: *"Là Quản trị viên, tôi muốn nhập thông tin thiết bị IoT mới vào hệ thống để có thể cấp phát/bán cho bệnh nhân sau này."*

### 8.2. Bổ sung "Xóa Tài Khoản" (Tuân thủ App Store/GDPR Compliance)
**Vấn đề:** Bất kỳ app nào cho phép đăng ký tài khoản đều bắt buộc phải có chức năng cho phép người dùng xóa hoàn toàn dữ liệu. Hệ thống hiện đang thiếu thiết kế này.
**Hành động chi tiết:**
- **Tài liệu UC**: Bổ sung Flow "Yêu cầu xóa tài khoản" vào `UC009_Manage_Profile.md` (hoặc tạo file UC riêng).
- **Thiết kế CSDL (SQL)**: Cấu trúc hiện tại đã có `deleted_at` (Soft Delete). Cần thiết kế một luồng **Cron Job/Worker** chạy ngầm định kỳ: Ẩn danh hóa/Xóa cứng toàn bộ bản ghi `vitals`, `motion_data`, `risk_scores` gắn với bệnh nhân sau 30 ngày kể từ lúc kích hoạt xóa.
- **JIRA Task**: Thêm Story: *"Là Bệnh nhân, tôi muốn có tính năng xóa hoàn toàn tài khoản và lịch sử dữ liệu sức khỏe của mình để bảo vệ quyền riêng tư cá nhân."*

### 8.3. Khớp nối hệ sinh thái Sleep Monitoring (Giấc Ngủ)
**Vấn đề:** Đã có tài liệu UC020, UC021 nhưng tính năng này lại chưa được định nghĩa trong luồng thiết kế kỹ thuật (SRS, SQL Schema).
**Hành động chi tiết:**
- **Tài liệu SRS (`SRS_INDEX.md`)**: Thêm Feature mới với `HG-FUNC-12: Theo dõi và phân tích giấc ngủ (Sleep Tracking)`.
- **Cấu trúc SQL**: Cập nhật DDL scripts thêm bảng `sleep_sessions` bao gồm các trường: `session_id`, `user_id`, `start_time`, `end_time`, `sleep_score`, `phases` (loại JSONB lưu chu trình ngủ: Awake, Light, Deep, REM).
- **JIRA Task**: Epic EP14-Sleep đã tồn tại, chỉ cần đảm bảo có sub-tasks cho việc xây dựng DB Migration.

---

## 9. CHANGELOG (Lịch sử cập nhật)

- **[2026-03-10 20:53:34]**: Cập nhật `UC024_Configure_System.md` - Loại bỏ mô tả thiết lập SMS/Gọi điện do quyết định hệ thống chỉ thống nhất sử dụng duy nhất Push Notification.
