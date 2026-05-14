-- ============================================================================
-- FULL DATABASE SETUP SCRIPT
-- Combined from 18 individual scripts (01 → 18)
-- Date: 2026-03-14  |  Last updated: 2026-04-28
-- All migrations incorporated — scripts 19 & 20 are DEPRECATED (merged into 05)
-- Health system backend migrations merged into 06 (risk_scores, risk_explanations)
-- ============================================================================

-- ############################################################################
-- SECTION 01: init_timescaledb.sql
-- Description: Khởi tạo TimescaleDB extension và cấu hình cơ bản
-- ############################################################################

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Enable other useful extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- For UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- For password hashing

-- Create custom types
DO $$ 
BEGIN
    -- User roles
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('user', 'admin');
    END IF;

    -- Alert severity
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'alert_severity') THEN
        CREATE TYPE alert_severity AS ENUM ('low', 'medium', 'high', 'critical');
    END IF;

    -- SOS status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sos_status') THEN
        CREATE TYPE sos_status AS ENUM ('active', 'responded', 'cancelled', 'resolved');
    END IF;

    -- Risk level
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_level') THEN
        CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high', 'critical');
    END IF;
END $$;

-- Configure TimescaleDB
-- Set chunk time interval (default: 7 days for hypertables)
-- Will be applied when creating hypertables

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ TimescaleDB extension enabled successfully';
    RAISE NOTICE '✓ Supporting extensions enabled';
    RAISE NOTICE '✓ Custom types created';
    RAISE NOTICE '→ Ready to create tables';
END $$;


-- ############################################################################
-- SECTION 02: create_tables_user_management.sql
-- Description: Tạo các bảng quản lý người dùng, relationships, emergency contacts
-- ############################################################################

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    
    -- Authentication
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    
    -- Profile
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    avatar_url TEXT,
    
    -- Role & Status
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Medical Info (for patients)
    blood_type VARCHAR(5) CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    height_cm SMALLINT CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg DECIMAL(5,2) CHECK (weight_kg > 0 AND weight_kg < 500),
    medical_conditions TEXT[],  -- Array: ['hypertension', 'diabetes']
    medications TEXT[],
    allergies TEXT[],
    
    -- Preferences
    language VARCHAR(10) DEFAULT 'vi',
    timezone VARCHAR(50) DEFAULT 'Asia/Ho_Chi_Minh',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ  -- Soft delete for GDPR compliance
);

-- Add comments
COMMENT ON TABLE users IS 'Bảng lưu trữ thông tin người dùng (bệnh nhân, người giám sát, admin)';
COMMENT ON COLUMN users.uuid IS 'UUID public cho API (không expose internal ID)';
COMMENT ON COLUMN users.medical_conditions IS 'Danh sách bệnh lý (hypertension, diabetes, etc.)';
COMMENT ON COLUMN users.deleted_at IS 'Soft delete timestamp (GDPR compliance)';

-- Table: user_relationships
CREATE TABLE IF NOT EXISTS user_relationships (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    caregiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Relationship
    relationship_type VARCHAR(50) CHECK (relationship_type IN ('family', 'friend', 'doctor', 'nurse', 'other')),
    is_primary BOOLEAN DEFAULT false,  -- Primary emergency contact
    
    -- Permissions (GDPR - fine-grained access control)
    can_view_vitals BOOLEAN DEFAULT true,
    can_receive_alerts BOOLEAN DEFAULT true,
    can_view_location BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraint: Unique relationship pair
    CONSTRAINT unique_patient_caregiver UNIQUE(patient_id, caregiver_id),
    
    -- Constraint: Patient and caregiver must be different
    CONSTRAINT different_users CHECK (patient_id != caregiver_id)
);

COMMENT ON TABLE user_relationships IS 'Mối quan hệ bệnh nhân - người giám sát (nhiều-nhiều)';
COMMENT ON COLUMN user_relationships.is_primary IS 'Người liên hệ khẩn cấp chính (gọi đầu tiên khi SOS)';
COMMENT ON COLUMN user_relationships.can_view_location IS 'Quyền xem vị trí GPS thời gian thực';

-- Table: emergency_contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Contact Info
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    relationship VARCHAR(50),  -- 'spouse', 'child', 'doctor'
    
    -- Priority (1 = call first)
    priority SMALLINT DEFAULT 1 CHECK (priority > 0),
    
    -- Notification Preferences
    notify_via_sms BOOLEAN DEFAULT true,
    notify_via_call BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE emergency_contacts IS 'Danh bạ khẩn cấp (có thể là người ngoài hệ thống)';
COMMENT ON COLUMN emergency_contacts.priority IS 'Thứ tự gọi khi SOS (1 = ưu tiên cao nhất)';

-- Create function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created user management tables and triggers';
END $$;


-- ############################################################################
-- SECTION 03: create_tables_devices.sql
-- Description: Tạo bảng quản lý thiết bị IoT
-- ############################################################################

CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    
    -- Ownership
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    
    -- Device Info
    device_name VARCHAR(100),
    device_type VARCHAR(50) DEFAULT 'smartwatch' CHECK (device_type IN ('smartwatch', 'fitness_band', 'medical_device')),
    model VARCHAR(100),
    firmware_version VARCHAR(20),
    
    -- Identification
    mac_address VARCHAR(17),
    serial_number VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    battery_level SMALLINT CHECK (battery_level >= 0 AND battery_level <= 100),
    signal_strength SMALLINT,
    
    -- Connection
    last_seen_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ,
    mqtt_client_id VARCHAR(100),
    
    -- Calibration & Settings
    calibration_data JSONB,
    
    -- Metadata
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE devices IS 'Bảng quản lý thiết bị IoT của người dùng';

-- Add trigger for auto-update updated_at
CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: devices and trigger';
END $$;


-- ############################################################################
-- SECTION 04: create_tables_timeseries.sql
-- Description: Tạo hypertables cho dữ liệu time-series (vitals, motion)
-- ############################################################################

-- Hypertable: vitals
CREATE TABLE IF NOT EXISTS vitals (
    time TIMESTAMPTZ NOT NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    heart_rate SMALLINT CHECK (heart_rate > 0 AND heart_rate < 300),
    spo2 DECIMAL(4,2) CHECK (spo2 >= 0 AND spo2 <= 100),
    temperature DECIMAL(4,2) CHECK (temperature > 30 AND temperature < 45),
    blood_pressure_sys SMALLINT CHECK (blood_pressure_sys > 0 AND blood_pressure_sys < 300),
    blood_pressure_dia SMALLINT CHECK (blood_pressure_dia > 0 AND blood_pressure_dia < 200),
    hrv SMALLINT,
    respiratory_rate SMALLINT CHECK (respiratory_rate >= 0 AND respiratory_rate < 100),
    signal_quality SMALLINT CHECK (signal_quality >= 0 AND signal_quality <= 100),
    motion_artifact BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT create_hypertable('vitals', 'time', 
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

ALTER TABLE vitals ADD PRIMARY KEY (device_id, time);

-- Hypertable: motion_data
CREATE TABLE IF NOT EXISTS motion_data (
    time TIMESTAMPTZ NOT NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    accel_x REAL,
    accel_y REAL,
    accel_z REAL,
    gyro_x REAL,
    gyro_y REAL,
    gyro_z REAL,
    magnitude REAL,
    sampling_rate SMALLINT DEFAULT 50 CHECK (sampling_rate > 0 AND sampling_rate <= 200)
);

SELECT create_hypertable('motion_data', 'time', 
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

ALTER TABLE motion_data ADD PRIMARY KEY (device_id, time);

-- Continuous Aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS vitals_5min
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('5 minutes', time) AS bucket,
    device_id,
    AVG(heart_rate) AS avg_hr,
    MIN(heart_rate) AS min_hr,
    MAX(heart_rate) AS max_hr,
    STDDEV(heart_rate) AS std_hr,
    AVG(spo2) AS avg_spo2,
    MIN(spo2) AS min_spo2,
    AVG(temperature) AS avg_temp,
    AVG(blood_pressure_sys) AS avg_bp_sys,
    MAX(blood_pressure_sys) AS max_bp_sys,
    AVG(blood_pressure_dia) AS avg_bp_dia,
    MIN(blood_pressure_dia) AS min_bp_dia,
    COUNT(*) AS sample_count
FROM vitals
GROUP BY bucket, device_id
WITH NO DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS vitals_hourly
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 hour', time) AS bucket,
    device_id,
    AVG(heart_rate) AS avg_hr,
    MIN(heart_rate) AS min_hr,
    MAX(heart_rate) AS max_hr,
    AVG(spo2) AS avg_spo2,
    MIN(spo2) AS min_spo2,
    AVG(temperature) AS avg_temp,
    AVG(blood_pressure_sys) AS avg_bp_sys,
    MAX(blood_pressure_sys) AS max_bp_sys,
    AVG(blood_pressure_dia) AS avg_bp_dia,
    MIN(blood_pressure_dia) AS min_bp_dia,
    COUNT(*) AS sample_count
FROM vitals
GROUP BY bucket, device_id
WITH NO DATA;

CREATE MATERIALIZED VIEW IF NOT EXISTS vitals_daily
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 day', time) AS bucket,
    device_id,
    AVG(heart_rate) AS avg_hr,
    MIN(heart_rate) AS min_hr,
    MAX(heart_rate) AS max_hr,
    AVG(spo2) AS avg_spo2,
    MIN(spo2) AS min_spo2,
    AVG(temperature) AS avg_temp,
    AVG(blood_pressure_sys) AS avg_bp_sys,
    MAX(blood_pressure_sys) AS max_bp_sys,
    AVG(blood_pressure_dia) AS avg_bp_dia,
    MIN(blood_pressure_dia) AS min_bp_dia,
    COUNT(*) AS sample_count
FROM vitals
GROUP BY bucket, device_id
WITH NO DATA;

-- sleep_sessions
CREATE TABLE IF NOT EXISTS sleep_sessions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    sleep_score SMALLINT CHECK (sleep_score >= 0 AND sleep_score <= 100),
    phases JSONB,
    wake_count SMALLINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sleep_sessions_user_time ON sleep_sessions(user_id, start_time DESC);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created hypertables and materialized views';
END $$;


-- ############################################################################
-- SECTION 05: create_tables_events_alerts.sql
-- Description: Tạo bảng cho events (fall, SOS) và alerts
-- Incorporated: migration 19 (alerts.updated_at + trigger), migration 20 (alert_type_alignment)
-- ############################################################################

CREATE TABLE IF NOT EXISTS fall_events (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    detected_at TIMESTAMPTZ NOT NULL,
    confidence DECIMAL(4,3) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    model_version VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_accuracy REAL,
    address TEXT,
    user_notified_at TIMESTAMPTZ,
    user_responded_at TIMESTAMPTZ,
    user_cancelled BOOLEAN DEFAULT false,
    cancel_reason VARCHAR(255),
    sos_triggered BOOLEAN DEFAULT false,
    sos_triggered_at TIMESTAMPTZ,
    features JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sos_events (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    fall_event_id INT REFERENCES fall_events(id) ON DELETE SET NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trigger_type VARCHAR(20) NOT NULL CHECK (trigger_type IN ('auto', 'manual')),
    triggered_at TIMESTAMPTZ NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    address TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'responded', 'cancelled', 'resolved')),
    resolved_at TIMESTAMPTZ,
    resolved_by_user_id INT REFERENCES users(id),
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_sos_events_updated_at 
    BEFORE UPDATE ON sos_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'vital_abnormal',
        'vitals_threshold',
        'fall_detected',
        'fall_detection',
        'sos',
        'sos_triggered',
        'device_offline',
        'low_battery',
        'high_risk_score',
        'risk_high',
        'risk_critical',
        'generic_alert'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT,
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    fall_event_id INT REFERENCES fall_events(id) ON DELETE SET NULL,
    sos_event_id INT REFERENCES sos_events(id) ON DELETE SET NULL,
    data JSONB,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    sent_via TEXT[] DEFAULT ARRAY['push'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

DROP TRIGGER IF EXISTS update_alerts_updated_at ON alerts;
CREATE TRIGGER update_alerts_updated_at
    BEFORE UPDATE ON alerts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created events and alerts tables (12 alert_types, updated_at)';
END $$;


-- ############################################################################
-- SECTION 06: create_tables_ai_analytics.sql
-- Description: Tạo bảng cho AI/ML (risk scores, XAI explanations, risk alert responses)
-- Incorporated: 20260416_risk_alert_escalation, 20260424_shap_explanation_columns,
--              20260427_model_request_id, 20260427_audience_payload_json, 20260427_sleep_risk_type
-- ############################################################################

CREATE TABLE IF NOT EXISTS risk_scores (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    calculated_at TIMESTAMPTZ NOT NULL,
    risk_type VARCHAR(50) NOT NULL CHECK (risk_type IN ('stroke', 'heartattack', 'afib', 'general', 'sleep')),
    score DECIMAL(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'critical')),
    features JSONB NOT NULL,
    model_version VARCHAR(20),
    algorithm VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS risk_explanations (
    id SERIAL PRIMARY KEY,
    risk_score_id INT NOT NULL REFERENCES risk_scores(id) ON DELETE CASCADE,
    explanation_text TEXT NOT NULL,
    feature_importance JSONB,
    xai_method VARCHAR(50) CHECK (xai_method IN ('shap', 'lime', 'rule_based', 'permutation')),
    recommendations TEXT[],
    top_features_json JSONB,
    ai_explanation_json JSONB,
    shap_details_json JSONB,
    model_request_id VARCHAR(36),
    audience_payload_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_risk_explanations_model_request_id
    ON risk_explanations (model_request_id)
    WHERE model_request_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_risk_explanations_audience_payload_present
    ON risk_explanations ((audience_payload_json IS NOT NULL))
    WHERE audience_payload_json IS NOT NULL;

CREATE TABLE IF NOT EXISTS risk_alert_responses (
    id BIGSERIAL PRIMARY KEY,
    notification_id BIGINT NOT NULL UNIQUE REFERENCES alerts(id) ON DELETE CASCADE,
    response_action VARCHAR(32) NOT NULL,
    risk_score_id BIGINT NULL,
    source VARCHAR(32) NOT NULL,
    device_id BIGINT NULL,
    latitude DOUBLE PRECISION NULL,
    longitude DOUBLE PRECISION NULL,
    address TEXT NULL,
    responded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sos_event_id BIGINT NULL REFERENCES sos_events(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_risk_alert_response_action
        CHECK (response_action IN ('safe', 'help_requested', 'timeout_escalated')),
    CONSTRAINT check_risk_alert_response_source
        CHECK (source IN ('overlay', 'push_tap'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_risk_alert_responses_notification_id
    ON risk_alert_responses (notification_id);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created AI analytics tables: risk_scores, risk_explanations, risk_alert_responses';
END $$;


-- ############################################################################
-- SECTION 07: create_tables_system.sql
-- Description: Tạo bảng cho system logs và metrics
-- ############################################################################

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL,
    time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    status VARCHAR(20) CHECK (status IN ('success', 'failure', 'pending')),
    error_message TEXT
);

SELECT create_hypertable('audit_logs', 'time', 
    chunk_time_interval => INTERVAL '1 month',
    if_not_exists => TRUE
);

ALTER TABLE audit_logs ADD PRIMARY KEY (id, time);

CREATE TABLE IF NOT EXISTS system_metrics (
    time TIMESTAMPTZ NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value REAL NOT NULL,
    tags JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT create_hypertable('system_metrics', 'time', 
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

ALTER TABLE system_metrics ADD PRIMARY KEY (metric_name, time);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created system logging and metrics hypertables';
END $$;


-- ############################################################################
-- SECTION 08: create_indexes.sql
-- Description: Tạo tất cả indexes để optimize queries
-- ############################################################################

-- users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- user_relationships
CREATE INDEX IF NOT EXISTS idx_relationships_patient ON user_relationships(patient_id);
CREATE INDEX IF NOT EXISTS idx_relationships_caregiver ON user_relationships(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_relationships_primary ON user_relationships(patient_id, is_primary) WHERE is_primary = true;

-- devices
CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_active ON devices(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_devices_uuid ON devices(uuid);
-- [HS-002 BR-040-01] Partial UNIQUE indexes: chan duplicate cross-user, exclude soft-deleted.
CREATE UNIQUE INDEX IF NOT EXISTS devices_mac_active_uniq
    ON devices(mac_address)
    WHERE deleted_at IS NULL AND mac_address IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS devices_serial_active_uniq
    ON devices(serial_number)
    WHERE deleted_at IS NULL AND serial_number IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS devices_mqtt_active_uniq
    ON devices(mqtt_client_id)
    WHERE deleted_at IS NULL AND mqtt_client_id IS NOT NULL;

-- vitals
CREATE INDEX IF NOT EXISTS idx_vitals_device_time ON vitals(device_id, time DESC);

-- alerts
CREATE INDEX IF NOT EXISTS idx_alerts_user ON alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_unread ON alerts(user_id, created_at DESC) WHERE read_at IS NULL;

-- audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id, time DESC);

-- system_metrics (GIN index for JSONB tags)
CREATE INDEX IF NOT EXISTS idx_system_metrics_tags ON system_metrics USING GIN (tags);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created essential indexes';
END $$;


-- ############################################################################
-- SECTION 09: create_policies.sql
-- Description: Tạo compression, retention, và continuous aggregate policies
-- ############################################################################

-- Compression
ALTER TABLE vitals SET (timescaledb.compress, timescaledb.compress_segmentby = 'device_id');
SELECT add_compression_policy('vitals', INTERVAL '7 days', if_not_exists => TRUE);

ALTER TABLE audit_logs SET (timescaledb.compress, timescaledb.compress_segmentby = 'user_id');
SELECT add_compression_policy('audit_logs', INTERVAL '30 days', if_not_exists => TRUE);

-- Retention
SELECT add_retention_policy('vitals', INTERVAL '1 year', if_not_exists => TRUE);
SELECT add_retention_policy('audit_logs', INTERVAL '2 years', if_not_exists => TRUE);

-- Refresh Policies
SELECT add_continuous_aggregate_policy('vitals_5min',
    start_offset => INTERVAL '1 hour', end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes', if_not_exists => TRUE);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Configured TimescaleDB policies';
END $$;


-- ############################################################################
-- SECTION 10: update_users_auth_fields.sql
-- Description: Cập nhật các cột mới cho bảng users để phục vụ Auth
-- ############################################################################

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS token_version INT NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ(6);

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Updated users table with auth fields';
END $$;


-- ############################################################################
-- SECTION 11: create_password_reset_tokens.sql
-- Description: Tạo bảng reset password tokens
-- ############################################################################

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE cascade,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_hash ON password_reset_tokens(token_hash);


-- ############################################################################
-- SECTION 12: create_users_archive.sql
-- Description: Tạo bảng users_archive để lưu trữ người dùng đã xóa
-- ############################################################################

CREATE TABLE IF NOT EXISTS users_archive (
    id SERIAL PRIMARY KEY,
    original_id INT NOT NULL,
    uuid UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    user_data JSON NOT NULL,
    archived_at TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    archived_by INT
);

CREATE INDEX IF NOT EXISTS idx_users_archive_original_id ON users_archive(original_id);


-- ############################################################################
-- SECTION 13: create_system_settings.sql
-- Description: Tạo bảng lưu trữ cấu hình hệ thống toàn cục
-- ############################################################################

CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_group VARCHAR(50) NOT NULL, 
    setting_value JSONB NOT NULL,
    description TEXT,
    is_editable BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INT REFERENCES users(id) ON DELETE SET NULL    
);

CREATE TRIGGER update_system_settings_updated_at 
    BEFORE UPDATE ON system_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

INSERT INTO system_settings (setting_key, setting_group, setting_value, description) VALUES
('fall_detection_ai', 'ai_model', '{"confidence_threshold": 0.85, "auto_sos_countdown_sec": 30, "enable_auto_sos": true}', 'Cấu hình engine AI'),
('notification_gateways', 'infrastructure', '{"sms_enabled": true, "call_enabled": true, "push_enabled": true, "max_sms_per_user_daily": 5}', 'Cấu hình gateway notification'),
('vitals_default_thresholds', 'clinical', '{"spo2_min": 92, "hr_min": 50, "hr_max": 120}', 'Ngưỡng cảnh báo sinh tồn mặc định'),
('system_security', 'security', '{"maintenance_mode": false, "session_timeout_minutes": 60}', 'Bảo mật hệ thống')
ON CONFLICT (setting_key) DO NOTHING;


-- ############################################################################
-- SECTION 14: add_verification_codes_to_users.sql
-- Description: Thêm cột mã PIN 6 số vào users (thay JWT token)
-- ############################################################################

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS verification_code       VARCHAR(6),
    ADD COLUMN IF NOT EXISTS verification_code_expires_at TIMESTAMPTZ(6);

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS reset_code              VARCHAR(6),
    ADD COLUMN IF NOT EXISTS reset_code_expires_at   TIMESTAMPTZ(6);

CREATE INDEX IF NOT EXISTS idx_users_verification_code
    ON users (email, verification_code)
    WHERE verification_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_reset_code
    ON users (email, reset_code)
    WHERE reset_code IS NOT NULL;


-- ############################################################################
-- SECTION 15: add_table_models.sql
-- Description: Tạo bảng quản lý AI model registry
-- ############################################################################

CREATE TABLE IF NOT EXISTS ai_models (
    id SERIAL NOT NULL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    key VARCHAR(100) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    task VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    active_version_id INTEGER,
    created_at TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    CONSTRAINT ai_models_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_model_versions (
    id SERIAL NOT NULL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL,
    version VARCHAR(50) NOT NULL,
    artifact_path VARCHAR(500) NOT NULL,
    artifact_sha256 VARCHAR(64) NOT NULL,
    artifact_size_bytes BIGINT,
    format VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    release_notes TEXT,
    created_by INTEGER,
    created_at TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ(6),
    CONSTRAINT ai_model_versions_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS ai_models_uuid_key ON ai_models(uuid);
CREATE UNIQUE INDEX IF NOT EXISTS ai_models_key_key ON ai_models(key);
CREATE INDEX IF NOT EXISTS idx_ai_models_key ON ai_models(key);
CREATE INDEX IF NOT EXISTS idx_ai_models_task ON ai_models(task);
CREATE UNIQUE INDEX IF NOT EXISTS ai_model_versions_uuid_key ON ai_model_versions(uuid);
CREATE INDEX IF NOT EXISTS idx_ai_model_versions_model ON ai_model_versions(model_id);
CREATE UNIQUE INDEX IF NOT EXISTS unique_ai_model_version ON ai_model_versions(model_id, version);

ALTER TABLE ai_models ADD CONSTRAINT ai_models_active_version_id_fkey
    FOREIGN KEY (active_version_id) REFERENCES ai_model_versions(id) ON DELETE SET NULL;
ALTER TABLE ai_model_versions ADD CONSTRAINT ai_model_versions_model_id_fkey
    FOREIGN KEY (model_id) REFERENCES ai_models(id) ON DELETE CASCADE;
ALTER TABLE ai_model_versions ADD CONSTRAINT ai_model_versions_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;


-- ############################################################################
-- SECTION 16: verify_bp_columns_and_push_tokens.sql
-- Description: Xác nhận BP columns tồn tại + tạo bảng user_push_tokens
-- Note (HS-009 Phase 4): Renamed from user_fcm_tokens to user_push_tokens
-- per ADR-016 (production reality — supports FCM + APNs + future channels).
-- ############################################################################

CREATE TABLE IF NOT EXISTS user_push_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Optional FK to devices: link push token to a specific device (nullable)
    device_id   INT REFERENCES devices(id) ON DELETE SET NULL,
    token       TEXT NOT NULL,
    platform    VARCHAR(10) DEFAULT 'android'
                    CHECK (platform IN ('android', 'ios', 'web')),
    is_active   BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_push_token UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user_active
    ON user_push_tokens (user_id)
    WHERE is_active = TRUE;


-- ############################################################################
-- SECTION 17: sleep_threshold_settings.sql
-- Description: Thêm ngưỡng sinh tồn ban ngày (cập nhật) và khi ngủ (AASM)
-- ############################################################################

INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable)
VALUES (
    'vitals_default_thresholds',
    'clinical',
    '{
        "hr_critical_min": 50, "hr_critical_max": 120,
        "hr_warning_min": 55,  "hr_warning_max": 110,
        "spo2_critical": 90,   "spo2_warning": 94,
        "rr_critical_min": 10, "rr_critical_max": 25,
        "bp_sys_critical": 180, "bp_dia_critical": 120,
        "bp_sys_warning": 140,  "bp_dia_warning": 90
    }',
    'Ngưỡng cảnh báo sinh tồn mặc định ban ngày (AHA 2023/WHO/ERS-ATS/ACC-AHA).',
    true
)
ON CONFLICT (setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    description   = EXCLUDED.description,
    updated_at    = NOW();

INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable)
VALUES (
    'vitals_sleep_thresholds',
    'clinical',
    '{
        "hr_critical_min": 38,  "hr_critical_max": 100,
        "hr_warning_min": 42,   "hr_warning_max": 90,
        "spo2_critical": 85,    "spo2_warning": 90,
        "rr_critical_min": 6,   "rr_critical_max": 25,
        "bp_sys_critical": 180, "bp_dia_critical": 120,
        "bp_sys_warning": 160,  "bp_dia_warning": 100,
        "osa_alert_spo2_threshold": 88,
        "nocturnal_tachy_hr": 120,
        "apnea_rr_threshold": 6
    }',
    'Ngưỡng sinh tồn khi ngủ (AASM 2020). HR 40-55 bpm deep sleep bình thường.',
    true
)
ON CONFLICT (setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    description   = EXCLUDED.description,
    updated_at    = NOW();


-- ############################################################################
-- SECTION 18: add_sleep_unique_constraint.sql
-- Description: Thêm cột sleep_date và UNIQUE constraint vào sleep_sessions
-- ############################################################################

ALTER TABLE sleep_sessions
    ADD COLUMN IF NOT EXISTS sleep_date DATE;

CREATE UNIQUE INDEX IF NOT EXISTS uq_sleep_user_device_date
    ON sleep_sessions (user_id, device_id, sleep_date);


-- ############################################################################
-- Print completion
-- ############################################################################
DO $$
BEGIN
    RAISE NOTICE '==================================================';
    RAISE NOTICE '✓ DATABASE SETUP COMPLETED SUCCESSFULLY';
    RAISE NOTICE '  Sections 01-18 applied (all migrations incorporated)';
    RAISE NOTICE '==================================================';
END $$;
