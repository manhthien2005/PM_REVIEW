-- ============================================================================
-- FULL DATA SEED SCRIPT
-- Combined and fixed from 4 individual seed scripts
-- Date: 2026-03-14
-- ============================================================================

BEGIN;

-- ############################################################################
-- SECTION 01: seed_users_and_devices.sql
-- Description: Bơm dữ liệu mẫu cho bảng users, emergency_contacts, system_settings, devices
-- ############################################################################

-- 1. Bơm System Settings (Dữ liệu nền tảng)
INSERT INTO system_settings (setting_key, setting_group, setting_value, description) VALUES
('default_timezone', 'infra', '"Asia/Ho_Chi_Minh"', 'Múi giờ mặc định cho hệ thống'),
('maintenance_mode', 'security', 'false', 'Bật/tắt chế độ bảo trì'),
('sos_timeout_seconds', 'clinical', '30', 'Thời gian chờ (giây) trước khi tự động gọi SOS sau khi phát hiện té ngã'),
('jwt_access_expiry_minutes', 'security', '43200', 'Thời gian sống của Access Token (30 ngày) cho Mobile App')
ON CONFLICT (setting_key) DO NOTHING;


-- 2. Bơm Dữ liệu Users (Người dùng)
INSERT INTO users (id, email, password_hash, phone, full_name, date_of_birth, gender, role, is_active, is_verified, blood_type, height_cm, weight_kg, medical_conditions) VALUES
-- Admin
(1, 'admin@healthguard.com', '$2b$10$tQ4qLEfCKXWpjXZDwC/rE.S3sIsqCL3D1vX/nimOrIJlxqAkG/N72', '0123456789', 'System Administrator', '1985-05-15', 'male', 'admin', true, true, null, null, null, null),

-- Người dùng bị khóa tài khoản
(6, 'locked.account@siu.edu.vn', '$2b$10$jdmt8y6xEqUAsYr/NJjteec/byZWbO.y4z7H79aQVmHw5/fH3DCfe', '0977223513', 'Locked Account', '1990-01-01', 'other', 'user', false, true, null, null, null, null),

-- Người dùng chưa xác minh email
(7, 'unverified.account@siu.edu.vn', '$2b$10$qBFb7czAIgACiwn1RBKfp.osyGQdw3eYZQmVEK//mCFLvqprpZfPG', null, 'Unverified Account', '1995-12-31', 'other', 'user', true, false, null, null, null, null),

-- Cụ Ông Nguyễn Văn A
(2, 'nguyen.van.a@demo.local', '$2a$12$DummyHashForPatientA123456', '0912345678', 'Nguyễn Văn A', '1950-01-01', 'male', 'user', true, true, 'O+', 165, 60.5, '{"hypertension", "diabetes"}'),

-- Anh Nguyễn Văn B
(3, 'nguyen.van.b@demo.local', '$2a$12$DummyHashForCaregiverB123', '0987654321', 'Nguyễn Văn B (Con Trai)', '1980-08-08', 'male', 'user', true, true, 'O+', 170, 75.0, null),

-- Chị Trần Thị C
(4, 'tran.thi.c@demo.local', '$2a$12$DummyHashForCaregiverC123', '0977777777', 'Trần Thị C (Con Dâu)', '1982-10-10', 'female', 'user', true, true, 'A+', 160, 55.0, null),

-- Bác sĩ Lê Văn D
(5, 'dr.le.van.d@demo.local', '$2a$12$DummyHashForDoctorD123456', '0909999999', 'BS. Lê Văn D', '1975-12-12', 'male', 'user', true, true, null, null, null, null)
ON CONFLICT (email) DO NOTHING;

-- Reset sequence cho bảng users
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));


-- 3. Bơm Danh bạ khẩn cấp (Emergency Contacts)
-- Sử dụng subquery để tránh duplicate nếu chạy nhiều lần
INSERT INTO emergency_contacts (user_id, name, phone, relationship, priority, notify_via_sms, notify_via_call)
SELECT * FROM (VALUES
    (2, 'Nguyễn Văn B (Con trai)', '0987654321', 'child', 1, true, true),
    (2, 'Trần Thị C (Con dâu)', '0977777777', 'child', 2, true, false),
    (2, 'BS. Lê Văn D (Bác sĩ)', '0909999999', 'doctor', 3, true, false)
) AS v(user_id, name, phone, relationship, priority, notify_via_sms, notify_via_call)
WHERE NOT EXISTS (
    SELECT 1 FROM emergency_contacts e 
    WHERE e.user_id = v.user_id AND e.name = v.name AND e.phone = v.phone
);


-- 4. Bơm Dữ Liệu Thiết Bị (Devices)
INSERT INTO devices (id, user_id, mac_address, device_name, model, firmware_version, is_active, last_seen_at) VALUES
(1, 2, '00:1A:2B:3C:4D:5E', 'Watch Cụ A', 'HealthGuard Pro v1', '1.0.5', true, NOW()),
(2, null, 'AA:BB:CC:DD:EE:FF', 'Thiết bị lưu kho', 'HealthGuard Basic', '1.0.0', false, null)
ON CONFLICT (id) DO NOTHING;

SELECT setval('devices_id_seq', (SELECT MAX(id) FROM devices));


-- ############################################################################
-- SECTION 02: seed_relationships.sql
-- Description: Bơm dữ liệu mẫu mô phỏng danh sách Linked Profiles
-- ############################################################################

INSERT INTO user_relationships (patient_id, caregiver_id, relationship_type, is_primary, can_view_vitals, can_receive_alerts, can_view_location) VALUES
(2, 3, 'family', true, true, true, true),
(2, 4, 'family', false, true, true, false),
(2, 5, 'doctor', false, true, false, false)
ON CONFLICT (patient_id, caregiver_id) DO NOTHING;

INSERT INTO user_relationships (patient_id, caregiver_id, relationship_type, is_primary, can_view_vitals, can_receive_alerts, can_view_location) VALUES
(3, 4, 'family', false, true, false, false),
(4, 3, 'family', false, true, false, false)
ON CONFLICT (patient_id, caregiver_id) DO NOTHING;

SELECT setval('user_relationships_id_seq', (SELECT MAX(id) FROM user_relationships));


-- ############################################################################
-- SECTION 03: seed_timeseries_vitals.sql
-- Description: Bơm dữ liệu mẫu cho Timeseries Data (vitals)
-- ############################################################################

-- 1. Bơm dữ liệu generator (Normal values)
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    -- FIXED: Round to nearest second to avoid jitter collisions
    date_trunc('second', NOW() - (i * INTERVAL '1 minute')) AS time,
    1 AS device_id,
    floor(random() * (85 - 65 + 1) + 65)::int AS heart_rate,
    (random() * (99 - 96) + 96)::decimal(4,2) AS spo2,
    (random() * (37.0 - 36.5) + 36.5)::decimal(4,2) AS temperature,
    floor(random() * (130 - 110 + 1) + 110)::int AS blood_pressure_sys,
    floor(random() * (85 - 70 + 1) + 70)::int AS blood_pressure_dia,
    floor(random() * (60 - 40 + 1) + 40)::int AS hrv,
    floor(random() * (20 - 14 + 1) + 14)::int AS respiratory_rate,
    floor(random() * (100 - 80 + 1) + 80)::int AS signal_quality,
    false AS motion_artifact
FROM generate_series(1, 1440) AS s(i)
ON CONFLICT (device_id, time) DO NOTHING;

-- 2. Abnormal data for testing alerts
-- FIXED: Added ON CONFLICT DO UPDATE to handle potential race condition/collison with generated sequence
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(date_trunc('second', NOW() - INTERVAL '5 minutes'), 1, 125, 93.5, 36.8, 145, 90, 30, 24, 95, true),
(date_trunc('second', NOW() - INTERVAL '4 minutes'), 1, 130, 92.0, 36.8, 150, 95, 25, 26, 95, true),
(date_trunc('second', NOW() - INTERVAL '3 minutes'), 1, 135, 91.0, 36.9, 155, 98, 20, 28, 90, true)
ON CONFLICT (device_id, time) DO UPDATE SET
    heart_rate = EXCLUDED.heart_rate,
    spo2 = EXCLUDED.spo2,
    temperature = EXCLUDED.temperature,
    blood_pressure_sys = EXCLUDED.blood_pressure_sys,
    blood_pressure_dia = EXCLUDED.blood_pressure_dia,
    hrv = EXCLUDED.hrv,
    respiratory_rate = EXCLUDED.respiratory_rate,
    signal_quality = EXCLUDED.signal_quality,
    motion_artifact = EXCLUDED.motion_artifact;

-- Force refresh continuous aggregates
CALL refresh_continuous_aggregate('vitals_5min', NOW() - INTERVAL '2 days', NOW());
CALL refresh_continuous_aggregate('vitals_hourly', NOW() - INTERVAL '2 days', NOW());
CALL refresh_continuous_aggregate('vitals_daily', NOW() - INTERVAL '2 days', NOW());


-- ############################################################################
-- SECTION 04: seed_events_and_alerts.sql
-- Description: Bơm dữ liệu mẫu cho sự kiện khẩn cấp (Fall, SOS, Alerts) 
-- ############################################################################

INSERT INTO fall_events (id, device_id, detected_at, confidence, model_version, latitude, longitude, address, user_notified_at, user_cancelled, sos_triggered) VALUES
(1, 1, NOW() - INTERVAL '1 hour', 0.95, 'v2.1', 10.762622, 106.660172, 'Quận 10, TP.HCM', NOW() - INTERVAL '59.5 minutes', false, true)
ON CONFLICT (id) DO NOTHING;

SELECT setval('fall_events_id_seq', (SELECT MAX(id) FROM fall_events));

INSERT INTO sos_events (id, fall_event_id, device_id, user_id, trigger_type, triggered_at, latitude, longitude, address, status, resolution_notes) VALUES
(1, 1, 1, 2, 'auto', NOW() - INTERVAL '59 minutes', 10.762622, 106.660172, 'Quận 10, TP.HCM', 'resolved', 'Con trai đã xác nhận đưa vào viện an toàn')
ON CONFLICT (id) DO NOTHING;

SELECT setval('sos_events_id_seq', (SELECT MAX(id) FROM sos_events));

UPDATE fall_events SET sos_triggered_at = NOW() - INTERVAL '59 minutes' WHERE id = 1;

-- Thêm alert với check để tránh duplicate khi chạy lại script
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, fall_event_id, sos_event_id, data, sent_at, delivered_at)
SELECT * FROM (VALUES
 (3, 1, 'sos_triggered', 'Khẩn cấp! Bố vừa bị ngã', 'Hệ thống tự động kích hoạt SOS do không thấy ông A phản hồi sau khi ngã.', 'critical', 1, 1, 
 '{"heart_rate": 115, "spo2": 95, "battery": 60, "address": "Quận 10, TP.HCM"}'::jsonb, NOW() - INTERVAL '59 minutes', NOW() - INTERVAL '58 minutes')
) AS v(user_id, device_id, alert_type, title, message, severity, fall_event_id, sos_event_id, data, sent_at, delivered_at)
WHERE NOT EXISTS (
    SELECT 1 FROM alerts a 
    WHERE a.user_id = v.user_id AND a.alert_type = v.alert_type AND a.created_at > (NOW() - INTERVAL '1 day')
);

INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at)
SELECT * FROM (VALUES
 (4, 1, 'vital_abnormal', 'Nhịp tim cao bất thường', 'Nhịp tim của cụ A lên tới 135 BPM.', 'high', 
 '{"heart_rate": 135}'::jsonb, NOW() - INTERVAL '3 minutes', NOW() - INTERVAL '2.9 minutes')
) AS v(user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at)
WHERE NOT EXISTS (
    SELECT 1 FROM alerts a 
    WHERE a.user_id = v.user_id AND a.alert_type = v.alert_type AND a.created_at > (NOW() - INTERVAL '1 day')
);

INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at)
SELECT * FROM (VALUES
 (2, 1, 'low_battery', 'Pin đồng hồ yếu', 'Đồng hồ chỉ còn 15% pin, vui lòng sạc.', 'low', 
 '{"battery": 15}'::jsonb, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1.9 hours')
) AS v(user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at)
WHERE NOT EXISTS (
    SELECT 1 FROM alerts a 
    WHERE a.user_id = v.user_id AND a.alert_type = v.alert_type AND a.created_at > (NOW() - INTERVAL '1 day')
);

COMMIT;
