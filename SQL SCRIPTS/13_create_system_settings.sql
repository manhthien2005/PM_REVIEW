-- Create system_settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    data_type VARCHAR(20) DEFAULT 'string',
    created_at TIMESTAMPTZ(6) DEFAULT NOW(),
    updated_at TIMESTAMPTZ(6) DEFAULT NOW()
);

-- Create index on category for faster filtering
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);

-- Insert default settings
INSERT INTO system_settings (key, value, category, description, data_type) VALUES
-- Alert thresholds
('alert.heart_rate.min', '50', 'alerts', 'Ngưỡng nhịp tim tối thiểu (bpm)', 'number'),
('alert.heart_rate.max', '120', 'alerts', 'Ngưỡng nhịp tim tối đa (bpm)', 'number'),
('alert.spo2.min', '92', 'alerts', 'Ngưỡng SpO2 tối thiểu (%)', 'number'),
('alert.temperature.min', '35.5', 'alerts', 'Ngưỡng nhiệt độ tối thiểu (°C)', 'number'),
('alert.temperature.max', '38.0', 'alerts', 'Ngưỡng nhiệt độ tối đa (°C)', 'number'),

-- Fall detection
('fall_detection.enabled', 'true', 'fall_detection', 'Bật/tắt phát hiện té ngã', 'boolean'),
('fall_detection.countdown_seconds', '30', 'fall_detection', 'Thời gian đếm ngược sau khi phát hiện té (giây)', 'number'),
('fall_detection.sensitivity', 'medium', 'fall_detection', 'Độ nhạy phát hiện: low, medium, high', 'string'),

-- Notifications
('notification.default_channel', 'push', 'notifications', 'Kênh thông báo mặc định: push, sms, email', 'string'),
('notification.quiet_hours.enabled', 'false', 'notifications', 'Bật chế độ im lặng theo giờ', 'boolean'),
('notification.quiet_hours.start', '22:00', 'notifications', 'Giờ bắt đầu im lặng', 'string'),
('notification.quiet_hours.end', '07:00', 'notifications', 'Giờ kết thúc im lặng', 'string'),

-- Data retention
('data_retention.vitals_days', '90', 'data_retention', 'Số ngày lưu trữ dữ liệu sinh hiệu', 'number'),
('data_retention.logs_days', '30', 'data_retention', 'Số ngày lưu trữ audit logs', 'number')

ON CONFLICT (key) DO NOTHING;
