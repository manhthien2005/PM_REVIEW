-- ============================================================================
-- File: 05_create_tables_events_alerts.sql
-- Description: Tạo bảng cho events (fall, SOS) và alerts
-- Tables: fall_events, sos_events, alerts, (+ trigger alerts.updated_at)
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================
-- Migrations incorporated (không cần chạy riêng nữa):
--   19_align_alerts_schema_with_runtime_model.sql → alerts.updated_at + trigger
--   20_migration.sql (alert_type_alignment)       → expanded alert_type CHECK
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
-- Hypertable: imu_windows (ADR-022 / Phase 7 S8)
-- Purpose: Lưu raw IMU window mobile/simulator push qua /telemetry/imu-window
--   để admin web replay false-positive case + future retrain dataset.
-- Source: ADR-022 (OQ2) — migration 20260516_imu_windows_hypertable.sql
-- Frequency: ~1 window per fall detection candidate (rare).
-- Retention: 7 ngày (auto drop) + compression 1 ngày (~10:1).
-- Placement note: defined here (not in 04_create_tables_timeseries.sql)
--   so the FK ``imu_windows.fall_event_id -> fall_events(id)`` resolves
--   at CREATE time. The reverse FK on ``fall_events`` is added below.
-- ============================================================================
CREATE TABLE IF NOT EXISTS imu_windows (
    id BIGSERIAL,
    time TIMESTAMPTZ NOT NULL,
    device_id INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    fall_event_id INT REFERENCES fall_events(id) ON DELETE SET NULL,

    -- Raw signal — kept verbatim from model-api payload for replay.
    accel JSONB NOT NULL,       -- [{t, x, y, z}, ...]
    gyro JSONB NOT NULL,        -- [{t, x, y, z}, ...]
    orientation JSONB,          -- [{t, pitch, roll, yaw}, ...] (optional)

    -- Window metadata so consumers can replot without recomputing.
    sample_rate_hz INT NOT NULL DEFAULT 50
        CHECK (sample_rate_hz > 0 AND sample_rate_hz <= 200),
    duration_seconds REAL NOT NULL DEFAULT 2.0
        CHECK (duration_seconds > 0 AND duration_seconds <= 60),

    -- Free-form tags from simulator: scenario_id, variant, model_request_id.
    context JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT create_hypertable(
    'imu_windows',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Composite PK (id, time) — TimescaleDB requires partitioning column
-- in every unique constraint on the hypertable. ``id`` carried alone
-- on ``fall_events.imu_window_id`` lets downstream code keep a single
-- BIGINT pointer; the matching ``time`` is duplicated onto
-- ``fall_events.imu_window_time`` so the composite FK stays valid.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'imu_windows'::regclass
          AND contype = 'p'
    ) THEN
        ALTER TABLE imu_windows ADD PRIMARY KEY (id, time);
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_imu_windows_device_time
    ON imu_windows (device_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_imu_windows_fall_event
    ON imu_windows (fall_event_id)
    WHERE fall_event_id IS NOT NULL;

ALTER TABLE imu_windows SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('imu_windows', INTERVAL '1 day', if_not_exists => TRUE);
SELECT add_retention_policy('imu_windows', INTERVAL '7 days', if_not_exists => TRUE);

COMMENT ON TABLE imu_windows IS
    'ADR-022 Phase 7 S8: raw IMU window persistence cho fall replay + retrain. TimescaleDB hypertable, 7-day retention, compress after 1 day.';
COMMENT ON COLUMN imu_windows.accel IS
    'Mảng samples accelerometer {t, x, y, z} - JSONB. Length = sample_rate_hz × duration_seconds.';
COMMENT ON COLUMN imu_windows.gyro IS
    'Mảng samples gyroscope {t, x, y, z} - JSONB. Same length as accel.';
COMMENT ON COLUMN imu_windows.orientation IS
    'Mảng samples orientation {t, pitch, roll, yaw} - optional, NULL nếu device không có fused-orientation channel.';
COMMENT ON COLUMN imu_windows.context IS
    'Free-form metadata: scenario_id, variant, activity_before, model_request_id (cho admin replay viewer).';

-- Reverse link: fall_events back to imu_windows via composite FK.
-- Both columns nullable — pre-S8 fall_events rows + events without a
-- raw window (e.g. simulator-only injected events) stay valid.
ALTER TABLE fall_events
    ADD COLUMN IF NOT EXISTS imu_window_id BIGINT;
ALTER TABLE fall_events
    ADD COLUMN IF NOT EXISTS imu_window_time TIMESTAMPTZ;

COMMENT ON COLUMN fall_events.imu_window_id IS
    'ADR-022: surrogate id của imu_windows row mà event này được derive từ. NULL khi event predates Phase 7 S8 hoặc arrived without raw window.';
COMMENT ON COLUMN fall_events.imu_window_time IS
    'ADR-022: matching imu_windows.time partition value — required by composite FK vì imu_windows là hypertable.';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_fall_events_imu_window'
    ) THEN
        ALTER TABLE fall_events
            ADD CONSTRAINT fk_fall_events_imu_window
            FOREIGN KEY (imu_window_id, imu_window_time)
            REFERENCES imu_windows (id, time)
            ON DELETE SET NULL;
    END IF;
END$$;

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
        'vitals_threshold',    -- Vitals threshold breach (runtime alias)
        'fall_detected',       -- Té ngã
        'fall_detection',      -- Té ngã (runtime alias v2)
        'sos',                 -- SOS (runtime alias)
        'sos_triggered',       -- SOS khẩn cấp
        'device_offline',      -- Thiết bị mất kết nối
        'low_battery',         -- Pin dưới 20%
        'high_risk_score',     -- Risk score cao
        'risk_high',           -- Risk score cao (runtime alias)
        'risk_critical',       -- Risk score critical
        'generic_alert'        -- Alert chung fallback
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
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ  -- Auto-cleanup old alerts
);

COMMENT ON TABLE alerts IS 'Bảng central cho tất cả notifications (push, SMS, email)';
COMMENT ON COLUMN alerts.alert_type IS 'Loại cảnh báo: vital_abnormal, vitals_threshold, fall_detected, fall_detection, sos, sos_triggered, device_offline, low_battery, high_risk_score, risk_high, risk_critical, generic_alert';
COMMENT ON COLUMN alerts.severity IS 'Mức độ nghiêm trọng: low, medium, high, critical';
COMMENT ON COLUMN alerts.data IS 'JSONB snapshot dữ liệu tại thời điểm alert (để audit sau này)';
COMMENT ON COLUMN alerts.sent_via IS 'Array các kênh gửi: push, sms, email';
COMMENT ON COLUMN alerts.updated_at IS 'Timestamp lần cập nhật cuối của alert; đồng bộ với runtime ORM model Alert';

-- Trigger auto-update updated_at khi UPDATE alert row
DROP TRIGGER IF EXISTS update_alerts_updated_at ON alerts;
CREATE TRIGGER update_alerts_updated_at
    BEFORE UPDATE ON alerts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: fall_events';
    RAISE NOTICE '✓ Created table: sos_events';
    RAISE NOTICE '✓ Created table: alerts (12 alert_types, updated_at + trigger)';
    RAISE NOTICE '  Incorporated: migration 19 (alerts.updated_at) + migration 20 (alert_type_alignment)';
END $$;
