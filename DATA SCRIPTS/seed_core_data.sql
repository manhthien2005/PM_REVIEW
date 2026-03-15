-- ============================================================================
-- CORE DATA SEED SCRIPT
-- Combined from 01_seed_users_and_devices.sql and 02_seed_relationships.sql
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

COMMIT;
