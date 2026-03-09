-- ============================================================================
-- File: 13_create_system_settings.sql
-- Description: Tạo bảng lưu trữ cấu hình hệ thống toàn cục (Global System Settings)
-- Tables: system_settings
-- Author: HealthGuard Development Team
-- Date: 09/03/2026
-- ============================================================================

-- ============================================================================
-- Table: system_settings
-- Purpose: Quản lý các tham số cấu hình toàn cục bởi Admin (AI, Core sinh tồn, Chi phí SMS/Call)
-- ============================================================================
CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    
    -- Phân nhóm trên giao diện Admin (clinical, ai_model, infrastructure, security)
    setting_group VARCHAR(50) NOT NULL, 
    
    -- Chứa giá trị cấu hình (Dùng JSONB để linh hoạt mở rộng mà không cần ALTER table)
    setting_value JSONB NOT NULL,
    
    -- Giải thích cho cấu hình này
    description TEXT,
    
    -- Cờ hiệu cho phép sửa hay không (Một số preset cứng của hệ thống không cho phép xóa/sửa)
    is_editable BOOLEAN DEFAULT true,
    
    -- Metadata / Audit (Ai là người update cuối cùng)
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INT REFERENCES users(id) ON DELETE SET NULL    
);

COMMENT ON TABLE system_settings IS 'Bảng chứa cấu hình hệ thống toàn cục (Global Settings) dành riêng cho Admin';
COMMENT ON COLUMN system_settings.setting_key IS 'Khóa cấu hình (VD: fall_detection_ai)';
COMMENT ON COLUMN system_settings.setting_group IS 'Nhóm giao diện (clinical, ai, infra, security)';
COMMENT ON COLUMN system_settings.setting_value IS 'Giá trị cấu hình thực tế';

-- Add trigger for auto-update updated_at (Tái sử dụng function ở bảng users)
CREATE TRIGGER update_system_settings_updated_at 
    BEFORE UPDATE ON system_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INSERT DEFAULT CONFIGURATIONS
-- Những cấu hình này đảm bảo tính "thực tế", giải quyết trực tiếp pain-point của sản phẩm
-- ============================================================================
INSERT INTO system_settings (setting_key, setting_group, setting_value, description) VALUES
-- 1. Cấu hình AI & Fall Detection (Chống False Alarm, cân chỉnh thời gian đếm ngược)
(
    'fall_detection_ai', 
    'ai_model', 
    '{"confidence_threshold": 0.85, "auto_sos_countdown_sec": 30, "enable_auto_sos": true}', 
    'Cấu hình engine AI: Ngưỡng tin cậy tối thiểu để kích hoạt té ngã, thời gian đếm ngược trước khi gọi cấp cứu SOS.'
),

-- 2. Quản lý cước phí & Notification (Quyền lực tối đa cho admin can thiệp ngân sách SMS/Call)
(
    'notification_gateways', 
    'infrastructure', 
    '{"sms_enabled": true, "call_enabled": true, "push_enabled": true, "max_sms_per_user_daily": 5}', 
    'Công tắc tổng để bật/tắt các kênh tốn phí (SMS/Call). Giới hạn số lượng SMS mỗi người dùng/ngày để tránh cạn ngân sách.'
),

-- 3. Cấu hình sinh tồn (Cứu cánh khi Caregiver/Doctor chưa set ngưỡng cá nhân cho bệnh nhân)
(
    'vitals_default_thresholds', 
    'clinical', 
    '{"spo2_min": 92, "hr_min": 50, "hr_max": 120}', 
    'Ngưỡng cảnh báo sinh tồn mặc định (Global Default) áp dụng cho bệnh nhân chưa được tuỳ chỉnh ngưỡng riêng.'
),

-- 4. Bảo mật & Bảo trì hệ thống
(
    'system_security', 
    'security', 
    '{"maintenance_mode": false, "session_timeout_minutes": 60}', 
    'Bảo trì hệ thống (Maintenance Mode - chặn tất cả trừ Admin) và quản lý phiên làm việc.'
)
ON CONFLICT (setting_key) DO NOTHING;

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: system_settings';
    RAISE NOTICE '✓ Inserted default practical configurations';
END $$;
