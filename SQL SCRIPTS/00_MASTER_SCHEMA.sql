-- ============================================================================
-- File: 01_init_timescaledb.sql
-- Description: Khởi tạo TimescaleDB extension và cấu hình cơ bản
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

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
        CREATE TYPE user_role AS ENUM ('patient', 'caregiver', 'admin');
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
-- ============================================================================
-- File: 02_create_tables_user_management.sql
-- Description: Tạo các bảng quản lý người dùng, relationships, emergency contacts
-- Tables: users, user_relationships, emergency_contacts
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Table: users
-- Purpose: Lưu trữ thông tin tất cả người dùng (bệnh nhân, caregiver, admin)
-- ============================================================================
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
    role VARCHAR(20) NOT NULL DEFAULT 'patient' CHECK (role IN ('patient', 'caregiver', 'admin')),
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

-- ============================================================================
-- Table: user_relationships
-- Purpose: Quản lý mối quan hệ many-to-many giữa bệnh nhân và caregiver
-- ============================================================================
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

-- ============================================================================
-- Table: emergency_contacts
-- Purpose: Lưu số điện thoại khẩn cấp (có thể là người ngoài hệ thống)
-- ============================================================================
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

-- ============================================================================
-- Create function to auto-update updated_at
-- ============================================================================
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
    RAISE NOTICE '✓ Created table: users';
    RAISE NOTICE '✓ Created table: user_relationships';
    RAISE NOTICE '✓ Created table: emergency_contacts';
    RAISE NOTICE '✓ Created triggers for auto-update timestamps';
END $$;
-- ============================================================================
-- File: 03_create_tables_devices.sql
-- Description: Tạo bảng quản lý thiết bị IoT
-- Tables: devices
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Table: devices
-- Purpose: Quản lý thiết bị IoT (smartwatch, fitness band)
-- ============================================================================
CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    
    -- Ownership
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Device Info
    device_name VARCHAR(100),
    device_type VARCHAR(50) DEFAULT 'smartwatch' CHECK (device_type IN ('smartwatch', 'fitness_band', 'medical_device')),
    model VARCHAR(100),
    firmware_version VARCHAR(20),
    
    -- Identification
    mac_address VARCHAR(17),  -- Format: AA:BB:CC:DD:EE:FF
    serial_number VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    battery_level SMALLINT CHECK (battery_level >= 0 AND battery_level <= 100),
    signal_strength SMALLINT,  -- RSSI value
    
    -- Connection
    last_seen_at TIMESTAMPTZ,
    last_sync_at TIMESTAMPTZ,
    mqtt_client_id VARCHAR(100),
    
    -- Calibration & Settings
    calibration_data JSONB,  -- Store sensor calibration parameters
    -- Example: {"heart_rate_offset": 0, "spo2_calibration": 1.02}
    
    -- Metadata
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- Soft delete
);

COMMENT ON TABLE devices IS 'Bảng quản lý thiết bị IoT của người dùng';
COMMENT ON COLUMN devices.last_seen_at IS 'Timestamp lần cuối device gửi data (dùng để detect offline)';
COMMENT ON COLUMN devices.mqtt_client_id IS 'Client ID để map với MQTT messages';
COMMENT ON COLUMN devices.calibration_data IS 'Tham số hiệu chỉnh cảm biến (JSONB để flexible)';
COMMENT ON COLUMN devices.battery_level IS 'Mức pin (0-100%)';

-- Add trigger for auto-update updated_at
CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: devices';
    RAISE NOTICE '✓ Added trigger for auto-update timestamps';
END $$;
-- ============================================================================
-- File: 04_create_tables_timeseries.sql
-- Description: Tạo hypertables cho dữ liệu time-series (vitals, motion)
-- Tables: vitals, motion_data
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Hypertable: vitals
-- Purpose: Lưu trữ dữ liệu chỉ số sinh tồn theo thời gian thực
-- Frequency: 1 record/second/device
-- Retention: 1 year (with compression after 7 days)
-- ============================================================================
CREATE TABLE IF NOT EXISTS vitals (
    time TIMESTAMPTZ NOT NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    -- Vital Signs
    heart_rate SMALLINT CHECK (heart_rate > 0 AND heart_rate < 300),  -- BPM (beats per minute)
    spo2 DECIMAL(4,2) CHECK (spo2 >= 0 AND spo2 <= 100),  -- % (0-100)
    temperature DECIMAL(4,2) CHECK (temperature > 30 AND temperature < 45),  -- Celsius
    blood_pressure_sys SMALLINT CHECK (blood_pressure_sys > 0 AND blood_pressure_sys < 300), -- Systolic BP
    blood_pressure_dia SMALLINT CHECK (blood_pressure_dia > 0 AND blood_pressure_dia < 200), -- Diastolic BP
    
    -- Derived Metrics
    hrv SMALLINT,  -- Heart Rate Variability (ms)
    respiratory_rate SMALLINT CHECK (respiratory_rate >= 0 AND respiratory_rate < 100),  -- Breaths per minute
    
    -- Quality Indicators
    signal_quality SMALLINT CHECK (signal_quality >= 0 AND signal_quality <= 100),  -- PPG signal quality (0-100)
    motion_artifact BOOLEAN DEFAULT false,  -- True if motion detected during measurement
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Convert to hypertable (TimescaleDB magic!)
-- Partition by time with 7-day chunks
SELECT create_hypertable('vitals', 'time', 
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Add composite primary key
ALTER TABLE vitals ADD PRIMARY KEY (device_id, time);

COMMENT ON TABLE vitals IS 'Hypertable lưu trữ chỉ số sinh tồn (heart rate, SpO2, temperature, blood pressure) - 1 record/giây';
COMMENT ON COLUMN vitals.heart_rate IS 'Nhịp tim (BPM - beats per minute)';
COMMENT ON COLUMN vitals.spo2 IS 'Độ bão hòa oxy trong máu (%, 0-100)';
COMMENT ON COLUMN vitals.blood_pressure_sys IS 'Huyết áp tâm thu (Systolic)';
COMMENT ON COLUMN vitals.blood_pressure_dia IS 'Huyết áp tâm trương (Diastolic)';
COMMENT ON COLUMN vitals.hrv IS 'Heart Rate Variability - biến thiên nhịp tim (ms)';
COMMENT ON COLUMN vitals.signal_quality IS 'Chất lượng tín hiệu PPG (0-100), < 50 = unreliable';
COMMENT ON COLUMN vitals.motion_artifact IS 'True nếu phát hiện chuyển động khi đo (có thể ảnh hưởng độ chính xác)';

-- ============================================================================
-- Hypertable: motion_data
-- Purpose: Lưu dữ liệu cảm biến chuyển động cho fall detection AI
-- Frequency: 50-100 records/second/device (high frequency!)
-- Retention: 3 months (with compression after 3 days)
-- ============================================================================
CREATE TABLE IF NOT EXISTS motion_data (
    time TIMESTAMPTZ NOT NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    -- Accelerometer (gia tốc 3 trục, m/s²)
    accel_x REAL,
    accel_y REAL,
    accel_z REAL,
    
    -- Gyroscope (con quay hồi chuyển, rad/s)
    gyro_x REAL,
    gyro_y REAL,
    gyro_z REAL,
    
    -- Derived
    magnitude REAL,  -- Pre-computed: sqrt(accel_x² + accel_y² + accel_z²)
    
    -- Metadata
    sampling_rate SMALLINT DEFAULT 50 CHECK (sampling_rate > 0 AND sampling_rate <= 200)  -- Hz
);

-- Convert to hypertable with 1-day chunks (high volume data)
SELECT create_hypertable('motion_data', 'time', 
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Add composite primary key
ALTER TABLE motion_data ADD PRIMARY KEY (device_id, time);

COMMENT ON TABLE motion_data IS 'Hypertable lưu dữ liệu cảm biến chuyển động (accelerometer, gyroscope) - 50-100 records/giây';
COMMENT ON COLUMN motion_data.accel_x IS 'Gia tốc trục X (m/s²)';
COMMENT ON COLUMN motion_data.accel_y IS 'Gia tốc trục Y (m/s²)';
COMMENT ON COLUMN motion_data.accel_z IS 'Gia tốc trục Z (m/s²)';
COMMENT ON COLUMN motion_data.magnitude IS 'Độ lớn vector gia tốc (pre-computed để tránh tính lại khi query)';
COMMENT ON COLUMN motion_data.sampling_rate IS 'Tần số lấy mẫu (Hz), thường 50-100';

-- ============================================================================
-- Create Continuous Aggregates (auto-downsampling)
-- Purpose: Pre-compute aggregates để query nhanh hơn
-- ============================================================================

-- 5-minute aggregates (for app charts)
CREATE MATERIALIZED VIEW IF NOT EXISTS vitals_5min
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('5 minutes', time) AS bucket,
    device_id,
    AVG(heart_rate) AS avg_hr,
    MIN(heart_rate) AS min_hr,
    MAX(heart_rate) AS max_hr,
    STDDEV(heart_rate) AS std_hr,  -- For HRV calculation
    AVG(spo2) AS avg_spo2,
    MIN(spo2) AS min_spo2,
    AVG(temperature) AS avg_temp,
    AVG(blood_pressure_sys) AS avg_bp_sys,
    MAX(blood_pressure_sys) AS max_bp_sys,
    AVG(blood_pressure_dia) AS avg_bp_dia,
    MIN(blood_pressure_dia) AS min_bp_dia,
    COUNT(*) AS sample_count
FROM vitals
GROUP BY bucket, device_id;

COMMENT ON MATERIALIZED VIEW vitals_5min IS 'Continuous aggregate: vitals theo 5 phút (dùng cho charts trong app)';

-- Hourly aggregates (for history view)
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
GROUP BY bucket, device_id;

COMMENT ON MATERIALIZED VIEW vitals_hourly IS 'Continuous aggregate: vitals theo giờ (dùng cho lịch sử 1 tuần, 1 tháng)';

-- Daily aggregates (for long-term trends)
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
GROUP BY bucket, device_id;

COMMENT ON MATERIALIZED VIEW vitals_daily IS 'Continuous aggregate: vitals theo ngày (dùng cho trends dài hạn)';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created hypertable: vitals (7-day chunks)';
    RAISE NOTICE '✓ Created hypertable: motion_data (1-day chunks)';
    RAISE NOTICE '✓ Created continuous aggregate: vitals_5min';
    RAISE NOTICE '✓ Created continuous aggregate: vitals_hourly';
    RAISE NOTICE '✓ Created continuous aggregate: vitals_daily';
    RAISE NOTICE '→ Aggregates will auto-refresh based on policies (setup in 09_create_policies.sql)';
END $$;
-- ============================================================================
-- File: 05_create_tables_events_alerts.sql
-- Description: Tạo bảng cho events (fall, SOS) và alerts
-- Tables: fall_events, sos_events, alerts
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Table: fall_events
-- Purpose: Lưu trữ các sự kiện té ngã được AI phát hiện
-- ============================================================================
CREATE TABLE IF NOT EXISTS fall_events (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    -- Detection
    detected_at TIMESTAMPTZ NOT NULL,
    confidence DECIMAL(4,3) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),  -- 0.000 - 1.000
    model_version VARCHAR(20),  -- For A/B testing different models
    
    -- Location (GPS)
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_accuracy REAL,  -- meters
    address TEXT,  -- Reverse geocoded address
    
    -- User Response Workflow
    user_notified_at TIMESTAMPTZ,
    user_responded_at TIMESTAMPTZ,
    user_cancelled BOOLEAN DEFAULT false,
    cancel_reason VARCHAR(255),
    
    -- SOS Status
    sos_triggered BOOLEAN DEFAULT false,
    sos_triggered_at TIMESTAMPTZ,
    
    -- AI Explainability (XAI)
    features JSONB,  -- Store input features for explainability
    -- Example: {"max_accel": 15.2, "impact_duration_ms": 250, "post_impact_motion": "low"}
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE fall_events IS 'Bảng lưu trữ các sự kiện té ngã được AI phát hiện';
COMMENT ON COLUMN fall_events.confidence IS 'Độ tin cậy từ AI model (0.000 - 1.000)';
COMMENT ON COLUMN fall_events.model_version IS 'Version của model (để so sánh performance giữa các versions)';
COMMENT ON COLUMN fall_events.user_cancelled IS 'True nếu user cancel trong 30 giây (false alarm)';
COMMENT ON COLUMN fall_events.features IS 'Input features cho XAI explanation (JSONB)';

-- ============================================================================
-- Table: sos_events
-- Purpose: Tracking các cuộc gọi cứu hộ khẩn cấp
-- ============================================================================
CREATE TABLE IF NOT EXISTS sos_events (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    
    -- Source
    fall_event_id INT REFERENCES fall_events(id) ON DELETE SET NULL,  -- NULL if manual SOS
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Trigger
    trigger_type VARCHAR(20) NOT NULL CHECK (trigger_type IN ('auto', 'manual')),
    triggered_at TIMESTAMPTZ NOT NULL,
    
    -- Location
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    address TEXT,
    
    -- Response Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'responded', 'cancelled', 'resolved')),
    resolved_at TIMESTAMPTZ,
    resolved_by_user_id INT REFERENCES users(id),  -- Who resolved it
    resolution_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE sos_events IS 'Bảng tracking các cuộc gọi SOS khẩn cấp';
COMMENT ON COLUMN sos_events.trigger_type IS 'auto (từ fall detection) hoặc manual (user bấm nút SOS)';
COMMENT ON COLUMN sos_events.status IS 'active (đang xử lý), responded (đã nhận), cancelled, resolved (đã giải quyết)';

-- Add trigger for auto-update updated_at
CREATE TRIGGER update_sos_events_updated_at 
    BEFORE UPDATE ON sos_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Table: alerts
-- Purpose: Central table cho TẤT CẢ notifications
-- ============================================================================
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    
    -- Target (người nhận alert)
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    
    -- Alert Type
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'vital_abnormal',      -- SpO2 < 92%, HR > 120
        'fall_detected',       -- Té ngã
        'sos_triggered',       -- SOS khẩn cấp
        'device_offline',      -- Thiết bị mất kết nối
        'low_battery',         -- Pin dưới 20%
        'high_risk_score'      -- Risk score cao
    )),
    
    -- Content
    title VARCHAR(255) NOT NULL,
    message TEXT,
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    
    -- Related Entities
    fall_event_id INT REFERENCES fall_events(id) ON DELETE SET NULL,
    sos_event_id INT REFERENCES sos_events(id) ON DELETE SET NULL,
    
    -- Data Snapshot (store context at alert time)
    data JSONB,
    -- Example: {"heart_rate": 135, "spo2": 88, "battery": 15, "location": {...}}
    
    -- Delivery Status
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,  -- FCM/APNs confirmation
    read_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    
    -- Delivery Channels
    sent_via TEXT[] DEFAULT ARRAY['push'],  -- ['push', 'sms', 'email']
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ  -- Auto-cleanup old alerts
);

COMMENT ON TABLE alerts IS 'Bảng central cho tất cả notifications (push, SMS, email)';
COMMENT ON COLUMN alerts.alert_type IS 'Loại cảnh báo: vital_abnormal, fall_detected, sos_triggered, etc.';
COMMENT ON COLUMN alerts.severity IS 'Mức độ nghiêm trọng: low, medium, high, critical';
COMMENT ON COLUMN alerts.data IS 'JSONB snapshot dữ liệu tại thời điểm alert (để audit sau này)';
COMMENT ON COLUMN alerts.sent_via IS 'Array các kênh gửi: push, sms, email';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: fall_events';
    RAISE NOTICE '✓ Created table: sos_events';
    RAISE NOTICE '✓ Created table: alerts';
END $$;
-- ============================================================================
-- File: 06_create_tables_ai_analytics.sql
-- Description: Tạo bảng cho AI/ML (risk scores, XAI explanations)
-- Tables: risk_scores, risk_explanations
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Table: risk_scores
-- Purpose: Lưu kết quả tính toán risk score từ AI model
-- Frequency: Tính định kỳ (6h hoặc 24h)
-- ============================================================================
CREATE TABLE IF NOT EXISTS risk_scores (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    
    -- Score
    calculated_at TIMESTAMPTZ NOT NULL,
    risk_type VARCHAR(50) NOT NULL CHECK (risk_type IN ('stroke', 'heartattack', 'afib', 'general')),
    score DECIMAL(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),  -- 0.00 - 100.00
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    
    -- Input Features (for reproducibility & explainability)
    features JSONB NOT NULL,
    /* Example:
    {
        "avg_hr_24h": 85,
        "hrv_sdnn": 30,
        "low_spo2_events": 5,
        "age": 65,
        "has_hypertension": true,
        "bmi": 28.5
    }
    */
    
    -- Model Info
    model_version VARCHAR(20),
    algorithm VARCHAR(50),  -- 'random_forest', 'neural_network', 'gradient_boosting'
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE risk_scores IS 'Bảng lưu kết quả tính toán risk score từ AI model';
COMMENT ON COLUMN risk_scores.risk_type IS 'Loại rủi ro: stroke (đột quỵ), heartattack (nhồi máu cơ tim), afib (rung nhĩ)';
COMMENT ON COLUMN risk_scores.score IS 'Điểm rủi ro (0-100)';
COMMENT ON COLUMN risk_scores.risk_level IS 'Mức độ: low, medium, high, critical';
COMMENT ON COLUMN risk_scores.features IS 'Input features dạng JSONB (để reproduce & explain)';

-- ============================================================================
-- Table: risk_explanations
-- Purpose: Explainable AI (XAI) - giải thích tại sao risk score cao
-- ============================================================================
CREATE TABLE IF NOT EXISTS risk_explanations (
    id SERIAL PRIMARY KEY,
    risk_score_id INT NOT NULL REFERENCES risk_scores(id) ON DELETE CASCADE,
    
    -- Explanation (Natural Language)
    explanation_text TEXT NOT NULL,
    /* Example:
    "Nguy cơ cao do nhịp tim tăng vọt 120bpm khi đang nghỉ ngơi 
     và HRV thấp bất thường (25ms). Khuyến nghị kiểm tra y tế."
    */
    
    -- Feature Importance (for visualization)
    feature_importance JSONB,
    /* Example:
    {
        "low_hrv": 0.45,          // Most important
        "high_resting_hr": 0.30,
        "age": 0.15,
        "low_spo2": 0.10
    }
    */
    
    -- XAI Method
    xai_method VARCHAR(50) CHECK (xai_method IN ('shap', 'lime', 'rule_based', 'permutation')),
    
    -- Actionable Recommendations
    recommendations TEXT[],
    /* Example:
    ARRAY[
        'Nghỉ ngơi đầy đủ, ngủ 7-8 giờ/ngày',
        'Uống đủ nước (2 lít/ngày)',
        'Liên hệ bác sĩ nếu triệu chứng kéo dài > 48h'
    ]
    */
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE risk_explanations IS 'Bảng giải thích AI (XAI) - tại sao risk score cao';
COMMENT ON COLUMN risk_explanations.explanation_text IS 'Giải thích bằng ngôn ngữ tự nhiên (tiếng Việt)';
COMMENT ON COLUMN risk_explanations.feature_importance IS 'Ranking features theo độ ảnh hưởng (0-1)';
COMMENT ON COLUMN risk_explanations.xai_method IS 'Phương pháp XAI: SHAP, LIME, rule-based';
COMMENT ON COLUMN risk_explanations.recommendations IS 'Khuyến nghị hành động cụ thể (array)';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: risk_scores';
    RAISE NOTICE '✓ Created table: risk_explanations';
END $$;
-- ============================================================================
-- File: 07_create_tables_system.sql
-- Description: Tạo bảng cho system logs và metrics
-- Tables: audit_logs, system_metrics
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- Hypertable: audit_logs
-- Purpose: Ghi lại tất cả hành động quan trọng (compliance requirement)
-- Retention: 2 years
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL,
    time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Actor (who performed the action)
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    
    -- Action
    action VARCHAR(100) NOT NULL,  
    -- Examples: 'user.login', 'user.logout', 'alert.sent', 'data.exported', 'settings.changed'
    
    resource_type VARCHAR(50),  -- 'user', 'device', 'alert', 'vital'
    resource_id INT,
    
    -- Details (JSONB for flexibility)
    details JSONB,
    /* Example:
    {
        "old_value": {"email": "old@example.com"},
        "new_value": {"email": "new@example.com"},
        "ip_address": "192.168.1.100"
    }
    */
    
    -- Client Info
    ip_address INET,
    user_agent TEXT,
    
    -- Result
    status VARCHAR(20) CHECK (status IN ('success', 'failure', 'pending')),
    error_message TEXT
);

-- Convert to hypertable (partitioned by month)
SELECT create_hypertable('audit_logs', 'time', 
    chunk_time_interval => INTERVAL '1 month',
    if_not_exists => TRUE
);

-- Add primary key
ALTER TABLE audit_logs ADD PRIMARY KEY (id, time);

COMMENT ON TABLE audit_logs IS 'Hypertable audit logs - ghi lại tất cả hành động quan trọng (GDPR/HIPAA compliance)';
COMMENT ON COLUMN audit_logs.action IS 'Hành động: user.login, alert.sent, data.exported, etc.';
COMMENT ON COLUMN audit_logs.details IS 'Chi tiết hành động (JSONB để flexible)';

-- ============================================================================
-- Hypertable: system_metrics
-- Purpose: Monitor performance của hệ thống
-- ============================================================================
CREATE TABLE IF NOT EXISTS system_metrics (
    time TIMESTAMPTZ NOT NULL,
    
    -- Metric
    metric_name VARCHAR(100) NOT NULL,
    /* Examples:
    - 'mqtt.messages_received'
    - 'api.latency_ms'
    - 'db.connections_active'
    - 'ai.inference_time_ms'
    */
    
    value REAL NOT NULL,
    
    -- Dimensions (tags for filtering)
    tags JSONB,
    /* Example:
    {
        "service": "api",
        "endpoint": "/vitals",
        "status_code": 200,
        "region": "asia-southeast"
    }
    */
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Convert to hypertable
SELECT create_hypertable('system_metrics', 'time', 
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Add composite primary key
ALTER TABLE system_metrics ADD PRIMARY KEY (metric_name, time);

COMMENT ON TABLE system_metrics IS 'Hypertable system metrics - monitor performance hệ thống';
COMMENT ON COLUMN system_metrics.metric_name IS 'Tên metric: mqtt.messages_received, api.latency_ms, etc.';
COMMENT ON COLUMN system_metrics.tags IS 'Dimensions để filter (service, endpoint, region, etc.)';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created hypertable: audit_logs (1-month chunks)';
    RAISE NOTICE '✓ Created hypertable: system_metrics (7-day chunks)';
END $$;
-- ============================================================================
-- File: 08_create_indexes.sql
-- Description: Tạo tất cả indexes để optimize queries
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- INDEXES FOR: users
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- ============================================================================
-- INDEXES FOR: user_relationships
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_relationships_patient ON user_relationships(patient_id);
CREATE INDEX IF NOT EXISTS idx_relationships_caregiver ON user_relationships(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_relationships_primary ON user_relationships(patient_id, is_primary) 
    WHERE is_primary = true;

-- ============================================================================
-- INDEXES FOR: emergency_contacts
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user ON emergency_contacts(user_id, priority);

-- ============================================================================
-- INDEXES FOR: devices
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_active ON devices(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_devices_uuid ON devices(uuid);
CREATE INDEX IF NOT EXISTS idx_devices_mqtt_client ON devices(mqtt_client_id);

-- ============================================================================
-- INDEXES FOR: vitals (hypertable)
-- ============================================================================
-- Composite index for time-range queries
CREATE INDEX IF NOT EXISTS idx_vitals_device_time ON vitals(device_id, time DESC);

-- Partial indexes for abnormal values (fast alert queries)
CREATE INDEX IF NOT EXISTS idx_vitals_abnormal_hr ON vitals(device_id, time DESC) 
    WHERE heart_rate < 50 OR heart_rate > 120;

CREATE INDEX IF NOT EXISTS idx_vitals_low_spo2 ON vitals(device_id, time DESC) 
    WHERE spo2 < 92;

CREATE INDEX IF NOT EXISTS idx_vitals_abnormal_temp ON vitals(device_id, time DESC) 
    WHERE temperature < 35.5 OR temperature > 37.8;

CREATE INDEX IF NOT EXISTS idx_vitals_abnormal_bp ON vitals(device_id, time DESC) 
    WHERE blood_pressure_sys > 140 OR blood_pressure_dia < 90;

-- Index for signal quality filtering
CREATE INDEX IF NOT EXISTS idx_vitals_quality ON vitals(signal_quality);

-- ============================================================================
-- INDEXES FOR: motion_data (hypertable)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_motion_device_time ON motion_data(device_id, time DESC);

-- Index for high magnitude (potential falls)
CREATE INDEX IF NOT EXISTS idx_motion_high_magnitude ON motion_data(device_id, time DESC) 
    WHERE magnitude > 20;  -- Threshold for potential fall

-- ============================================================================
-- INDEXES FOR: fall_events
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_fall_events_device ON fall_events(device_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_fall_events_pending ON fall_events(device_id, detected_at DESC) 
    WHERE user_responded_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_fall_events_sos ON fall_events(sos_triggered, sos_triggered_at DESC) 
    WHERE sos_triggered = true;
CREATE INDEX IF NOT EXISTS idx_fall_events_confidence ON fall_events(confidence DESC);

-- ============================================================================
-- INDEXES FOR: sos_events
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_sos_events_user ON sos_events(user_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_events_device ON sos_events(device_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_events_active ON sos_events(status, triggered_at DESC) 
    WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_sos_events_fall ON sos_events(fall_event_id);

-- ============================================================================
-- INDEXES FOR: alerts
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_alerts_user ON alerts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_unread ON alerts(user_id, created_at DESC) 
    WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_alerts_critical ON alerts(severity, created_at DESC) 
    WHERE severity IN ('high', 'critical');
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(alert_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_device ON alerts(device_id, created_at DESC);

-- ============================================================================
-- INDEXES FOR: risk_scores
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_risk_scores_user ON risk_scores(user_id, calculated_at DESC);
CREATE INDEX IF NOT EXISTS idx_risk_scores_high ON risk_scores(user_id, calculated_at DESC) 
    WHERE risk_level IN ('high', 'critical');
CREATE INDEX IF NOT EXISTS idx_risk_scores_type ON risk_scores(risk_type, calculated_at DESC);

-- ============================================================================
-- INDEXES FOR: risk_explanations
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_risk_explanations_score ON risk_explanations(risk_score_id);

-- ============================================================================
-- INDEXES FOR: audit_logs (hypertable)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action, time DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_status ON audit_logs(status, time DESC);

-- ============================================================================
-- INDEXES FOR: system_metrics (hypertable)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_system_metrics_name ON system_metrics(metric_name, time DESC);

-- GIN index for JSONB tags (for filtering on tags)
CREATE INDEX IF NOT EXISTS idx_system_metrics_tags ON system_metrics USING GIN (tags);

-- ============================================================================
-- INDEXES FOR: Continuous Aggregates
-- ============================================================================
-- Indexes are automatically created for continuous aggregates by TimescaleDB

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created indexes for users (4 indexes)';
    RAISE NOTICE '✓ Created indexes for user_relationships (3 indexes)';
    RAISE NOTICE '✓ Created indexes for devices (6 indexes)';
    RAISE NOTICE '✓ Created indexes for vitals (7 indexes, including partial indexes)';
    RAISE NOTICE '✓ Created indexes for motion_data (2 indexes)';
    RAISE NOTICE '✓ Created indexes for fall_events (4 indexes)';
    RAISE NOTICE '✓ Created indexes for sos_events (4 indexes)';
    RAISE NOTICE '✓ Created indexes for alerts (6 indexes)';
    RAISE NOTICE '✓ Created indexes for risk_scores (3 indexes)';
    RAISE NOTICE '✓ Created indexes for audit_logs (4 indexes)';
    RAISE NOTICE '✓ Created indexes for system_metrics (2 indexes + GIN)';
    RAISE NOTICE '';
    RAISE NOTICE '→ Total: 45 indexes created';
    RAISE NOTICE '→ Partial indexes optimize abnormal value queries';
    RAISE NOTICE '→ Composite indexes optimize time-range queries';
END $$;
-- ============================================================================
-- File: 09_create_policies.sql
-- Description: Tạo compression, retention, và continuous aggregate policies
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================

-- ============================================================================
-- COMPRESSION POLICIES
-- Purpose: Tự động nén data cũ để tiết kiệm storage (90% reduction)
-- ============================================================================

-- Vitals: Compress sau 7 ngày
ALTER TABLE vitals SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('vitals', INTERVAL '7 days', if_not_exists => TRUE);

-- Motion Data: Compress sau 3 ngày (high volume)
ALTER TABLE motion_data SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('motion_data', INTERVAL '3 days', if_not_exists => TRUE);

-- Audit Logs: Compress sau 30 ngày
ALTER TABLE audit_logs SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'user_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('audit_logs', INTERVAL '30 days', if_not_exists => TRUE);

-- System Metrics: Compress sau 7 ngày
ALTER TABLE system_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'metric_name',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('system_metrics', INTERVAL '7 days', if_not_exists => TRUE);

-- ============================================================================
-- RETENTION POLICIES
-- Purpose: Tự động xóa data cũ để quản lý storage
-- ============================================================================

-- Vitals: Xóa sau 1 năm (giữ aggregates)
SELECT add_retention_policy('vitals', INTERVAL '1 year', if_not_exists => TRUE);

-- Motion Data: Xóa sau 3 tháng (chỉ dùng cho inference, không cần lưu lâu)
SELECT add_retention_policy('motion_data', INTERVAL '3 months', if_not_exists => TRUE);

-- Audit Logs: Xóa sau 2 năm (compliance requirement)
SELECT add_retention_policy('audit_logs', INTERVAL '2 years', if_not_exists => TRUE);

-- System Metrics: Xóa sau 6 tháng
SELECT add_retention_policy('system_metrics', INTERVAL '6 months', if_not_exists => TRUE);

-- ============================================================================
-- CONTINUOUS AGGREGATE REFRESH POLICIES
-- Purpose: Tự động refresh materialized views
-- ============================================================================

-- vitals_5min: Refresh mỗi 5 phút
SELECT add_continuous_aggregate_policy('vitals_5min',
    start_offset => INTERVAL '1 hour',
    end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes',
    if_not_exists => TRUE
);

-- vitals_hourly: Refresh mỗi giờ
SELECT add_continuous_aggregate_policy('vitals_hourly',
    start_offset => INTERVAL '1 day',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

-- vitals_daily: Refresh mỗi ngày
SELECT add_continuous_aggregate_policy('vitals_daily',
    start_offset => INTERVAL '1 week',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- ============================================================================
-- VERIFY POLICIES
-- ============================================================================

-- Check compression policies
DO $$
DECLARE
    compression_count INT;
BEGIN
    SELECT COUNT(*) INTO compression_count
    FROM timescaledb_information.jobs
    WHERE proc_name = 'policy_compression';
    
    RAISE NOTICE '→ Compression policies created: %', compression_count;
END $$;

-- Check retention policies
DO $$
DECLARE
    retention_count INT;
BEGIN
    SELECT COUNT(*) INTO retention_count
    FROM timescaledb_information.jobs
    WHERE proc_name = 'policy_retention';
    
    RAISE NOTICE '→ Retention policies created: %', retention_count;
END $$;

-- Check continuous aggregate policies
DO $$
DECLARE
    cagg_count INT;
BEGIN
    SELECT COUNT(*) INTO cagg_count
    FROM timescaledb_information.jobs
    WHERE proc_name = 'policy_refresh_continuous_aggregate';
    
    RAISE NOTICE '→ Continuous aggregate refresh policies created: %', cagg_count;
END $$;

-- Print summary
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'POLICIES SUMMARY';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'COMPRESSION (auto compress old data):';
    RAISE NOTICE '  • vitals: after 7 days';
    RAISE NOTICE '  • motion_data: after 3 days';
    RAISE NOTICE '  • audit_logs: after 30 days';
    RAISE NOTICE '  • system_metrics: after 7 days';
    RAISE NOTICE '';
    RAISE NOTICE 'RETENTION (auto delete old data):';
    RAISE NOTICE '  • vitals: after 1 year';
    RAISE NOTICE '  • motion_data: after 3 months';
    RAISE NOTICE '  • audit_logs: after 2 years';
    RAISE NOTICE '  • system_metrics: after 6 months';
    RAISE NOTICE '';
    RAISE NOTICE 'CONTINUOUS AGGREGATES (auto refresh):';
    RAISE NOTICE '  • vitals_5min: every 5 minutes';
    RAISE NOTICE '  • vitals_hourly: every 1 hour';
    RAISE NOTICE '  • vitals_daily: every 1 day';
    RAISE NOTICE '';
    RAISE NOTICE '→ Expected storage savings: ~90%% after compression';
    RAISE NOTICE '→ Query performance: 10-100x faster with aggregates';
    RAISE NOTICE '';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✓ ALL POLICIES CONFIGURED SUCCESSFULLY!';
    RAISE NOTICE '===============================================';
END $$;

-- ============================================================================
-- ADDITIONAL PERFORMANCE TIPS
-- ============================================================================

-- Enable parallel query execution (if using PostgreSQL 14+)
-- Uncomment if your server has multiple CPU cores
-- ALTER DATABASE healthguard SET max_parallel_workers_per_gather = 4;

-- Increase work_mem for complex queries (adjust based on your RAM)
-- ALTER DATABASE healthguard SET work_mem = '64MB';

-- Enable JIT compilation for faster queries (PostgreSQL 11+)
-- ALTER DATABASE healthguard SET jit = on;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'OPTIONAL: For better performance, consider:';
    RAISE NOTICE '1. Enable parallel queries (max_parallel_workers_per_gather)';
    RAISE NOTICE '2. Increase work_mem for complex aggregations';
    RAISE NOTICE '3. Enable JIT compilation';
    RAISE NOTICE '';
    RAISE NOTICE 'See commented lines in this file for details.';
END $$;
