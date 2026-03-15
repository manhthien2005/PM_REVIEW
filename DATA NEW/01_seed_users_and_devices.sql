-- ============================================================================
-- File: 01_seed_users_and_devices.sql
-- Description: Bơm dữ liệu mẫu cho bảng users, emergency_contacts, system_settings, devices
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- 1. Bơm System Settings (Dữ liệu nền tảng)
INSERT INTO system_settings (setting_key, setting_group, setting_value, description) VALUES
('default_timezone', 'infra', '"Asia/Ho_Chi_Minh"', 'Múi giờ mặc định cho hệ thống'),
('maintenance_mode', 'security', 'false', 'Bật/tắt chế độ bảo trì'),
('sos_timeout_seconds', 'clinical', '30', 'Thời gian chờ (giây) trước khi tự động gọi SOS sau khi phát hiện té ngã'),
('jwt_access_expiry_minutes', 'security', '43200', 'Thời gian sống của Access Token (30 ngày) cho Mobile App')
ON CONFLICT (setting_key) DO NOTHING;


-- 2. Bơm Dữ liệu Users (Người dùng) - Mật khẩu đã hash với bcryptjs
-- Tất cả mật khẩu mặc định là "123456" đã được hash với bcryptjs rounds=10
INSERT INTO users (id, email, password_hash, phone, full_name, date_of_birth, gender, role, is_active, is_verified, blood_type, height_cm, weight_kg, medical_conditions, medications, allergies) VALUES
-- Admin (password: 123456)
(1, 'admin@healthguard.vn', '$2b$10$sSa5lqWNJYqSuF60WGJc8uuX6cv3z3j93YWtckEVI6Q20uKfc3mXu', '0123456789', 'System Administrator', '1985-05-15', 'male', 'admin', true, true, null, null, null, '{}', '{}', '{}'),

-- Cụ Ông Nguyễn Văn A (Bệnh nhân chính) (password: 123456)
(2, 'nguyen.van.a@demo.local', '$2b$10$7xm3Else5h7YoBPly9Q2helRf9nUx/vwOCc19MK6eMNZ/xzSNjkkG', '0912345678', 'Nguyễn Văn A', '1950-01-01', 'male', 'user', true, true, 'O+', 165, 60.5, '{"hypertension", "diabetes"}', '{"metformin", "lisinopril"}', '{"penicillin"}'),

-- Anh Nguyễn Văn B (Con trai cụ A) (password: 123456)
(3, 'nguyen.van.b@demo.local', '$2b$10$jN0ZcMznjFxAy4MbD6fpbOuAIObOhhNnFtQ6sM0Jdi7D0j1rzZqTG', '0987654321', 'Nguyễn Văn B (Con Trai)', '1980-08-08', 'male', 'user', true, true, 'O+', 170, 75.0, '{}', '{}', '{}'),

-- Chị Trần Thị C (Con dâu cụ A) (password: 123456)
(4, 'tran.thi.c@demo.local', '$2b$10$gHTUW/x2sd0WH0.LRI24yuU3T27UbI8O48M.xPqh6axbdbwkmuRga', '0977777777', 'Trần Thị C (Con Dâu)', '1982-10-10', 'female', 'user', true, true, 'A+', 160, 55.0, '{}', '{}', '{}'),

-- Bác sĩ Lê Văn D (Bác sĩ điều trị cụ A) (password: 123456)
(5, 'dr.le.van.d@demo.local', '$2b$10$HDUTXh7u7yCPOXUk9u1xxOXmGjV4IFFvs0HebsKakJ0OgqmKkztkG', '0909999999', 'BS. Lê Văn D', '1975-12-12', 'male', 'user', true, true, null, null, null, '{}', '{}', '{}'),

-- Người dùng bị khóa tài khoản (password: 123456)
(6, 'locked.account@siu.edu.vn', '$2b$10$7OpQzx/FPjknUGW2a6sBC.pGs6zWV1yI5LLWbFZWQtgAjDvzJrUnW', '0977223513', 'Locked Account', '1990-01-01', 'other', 'user', false, true, null, null, null, '{}', '{}', '{}'),

-- Người dùng chưa xác minh email (password: 123456)
(7, 'unverified.account@siu.edu.vn', '$2b$10$G3oRnNvpa2dAqeuYoCp4VOOwFHYVmj4aTrt3XjG64eLCfQOQ8tO/m', null, 'Unverified Account', '1995-12-31', 'other', 'user', true, false, null, null, null, '{}', '{}', '{}')
ON CONFLICT (email) DO NOTHING;

-- Reset sequence cho bảng users để tránh lỗi primary key autoincrement
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));


-- 3. Bơm Danh bạ khẩn cấp (Emergency Contacts)
-- Dành cho Cụ A
INSERT INTO emergency_contacts (user_id, name, phone, relationship, priority, notify_via_sms, notify_via_call) VALUES
(2, 'Nguyễn Văn B (Con trai)', '0987654321', 'child', 1, true, true),
(2, 'Trần Thị C (Con dâu)', '0977777777', 'child', 2, true, false),
(2, 'BS. Lê Văn D (Bác sĩ)', '0909999999', 'doctor', 3, true, false);

-- 4. Bơm Dữ Liệu Thiết Bị (Devices)
INSERT INTO devices (id, user_id, device_name, device_type, model, firmware_version, mac_address, serial_number, is_active, battery_level, signal_strength, last_seen_at, mqtt_client_id, calibration_data) VALUES
-- Thiết bị của Cụ A
(1, 2, 'Watch Cụ A', 'smartwatch', 'HealthGuard Pro v1', '1.0.5', '00:1A:2B:3C:4D:5E', 'HG001234567', true, 85, 95, NOW() - INTERVAL '5 minutes', 'device_001_client', '{"heart_rate_offset": 0, "spo2_offset": 0}'),

-- Thiết bị của Anh B
(2, 3, 'Watch Anh B', 'smartwatch', 'HealthGuard Standard', '1.0.3', '00:1A:2B:3C:4D:5F', 'HG001234568', true, 92, 88, NOW() - INTERVAL '2 minutes', 'device_002_client', '{"heart_rate_offset": 2, "spo2_offset": -1}'),

-- Thiết bị của Chị C
(3, 4, 'Watch Chị C', 'smartwatch', 'HealthGuard Lite', '1.0.2', '00:1A:2B:3C:4D:60', 'HG001234569', true, 78, 92, NOW() - INTERVAL '1 hour', 'device_003_client', '{"heart_rate_offset": -1, "spo2_offset": 1}'),

-- Thiết bị lưu kho (chưa gán cho ai)
(4, null, 'Thiết bị lưu kho #1', 'smartwatch', 'HealthGuard Basic', '1.0.0', 'AA:BB:CC:DD:EE:FF', 'HG001234570', false, null, null, null, null, null),

-- Thiết bị demo cho bác sĩ
(5, 5, 'Demo Device - Dr. D', 'smartwatch', 'HealthGuard Monitor', '2.1.0', '00:1A:2B:3C:4D:61', 'HG001234571', true, 100, 100, NOW(), 'device_005_client', '{}')
ON CONFLICT (id) DO NOTHING;

SELECT setval('devices_id_seq', (SELECT MAX(id) FROM devices));

COMMIT;