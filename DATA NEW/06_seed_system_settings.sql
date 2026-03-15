-- ============================================================================
-- File: 06_seed_system_settings.sql
-- Description: Bơm dữ liệu đầy đủ cho system_settings (Settings UI)
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- Xóa settings cũ và thêm mới
DELETE FROM system_settings WHERE setting_key IN (
    'fall_detection_ai',
    'notification_gateways', 
    'vitals_default_thresholds',
    'system_security'
);

-- 1. AI & Fall Detection Settings
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable) VALUES
('fall_detection_ai', 'ai', '{
    "confidence_threshold": 0.85,
    "auto_sos_countdown_sec": 30,
    "enable_auto_sos": true
}', 'Cấu hình AI phát hiện té ngã và tự động SOS', true);

-- 2. Notification Gateway Settings  
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable) VALUES
('notification_gateways', 'infra', '{
    "push_enabled": true
}', 'Cấu hình các kênh thông báo (Push, SMS, Call)', true);

-- 3. Vital Signs Default Thresholds
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable) VALUES
('vitals_default_thresholds', 'clinical', '{
    "spo2_min": 92,
    "hr_min": 50,
    "hr_max": 120,
    "bp_sys_min": 90,
    "bp_sys_max": 140,
    "temp_max": 37.8
}', 'Ngưỡng cảnh báo mặc định cho các chỉ số sinh tồn', true);

-- 4. System Security Settings
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable) VALUES
('system_security', 'security', '{
    "maintenance_mode": false,
    "session_timeout_minutes": 60
}', 'Cấu hình bảo mật và bảo trì hệ thống', true);

COMMIT;

-- Kiểm tra kết quả
SELECT 
    setting_key,
    setting_group,
    setting_value,
    description,
    is_editable
FROM system_settings 
WHERE setting_key IN (
    'fall_detection_ai',
    'notification_gateways', 
    'vitals_default_thresholds',
    'system_security'
)
ORDER BY setting_key;

-- ✓ System settings seed data completed