-- ============================================================================
-- File: 16_verify_bp_columns_and_fcm_tokens.sql
-- Description: 
--   1. Xác nhận cột blood_pressure_sys / blood_pressure_dia tồn tại trong bảng vitals
--      (đã được tạo từ 04_create_tables_timeseries.sql)
--   2. Tạo bảng user_push_tokens để hỗ trợ push notification (Phase 8)
--      [HS-009 Phase 4] Renamed from user_fcm_tokens to user_push_tokens per ADR-016.
-- Author: HealthGuard Development Team
-- Date: 2026-03-24 (rev 2026-05-14: rename + add device_id, last_sync_at)
-- ============================================================================

-- ============================================================================
-- PART 1: Xác nhận BP columns trong bảng vitals
-- ============================================================================

DO $$
DECLARE
    v_col_sys   text;
    v_col_dia   text;
BEGIN
    -- Kiểm tra blood_pressure_sys
    SELECT column_name INTO v_col_sys
    FROM information_schema.columns
    WHERE table_name = 'vitals'
      AND column_name = 'blood_pressure_sys'
      AND table_schema = 'public';

    -- Kiểm tra blood_pressure_dia
    SELECT column_name INTO v_col_dia
    FROM information_schema.columns
    WHERE table_name = 'vitals'
      AND column_name = 'blood_pressure_dia'
      AND table_schema = 'public';

    IF v_col_sys IS NOT NULL AND v_col_dia IS NOT NULL THEN
        RAISE NOTICE '✅ vitals.blood_pressure_sys  : EXISTS (type SMALLINT)';
        RAISE NOTICE '✅ vitals.blood_pressure_dia  : EXISTS (type SMALLINT)';
        RAISE NOTICE '→ BP columns OK — không cần migration thêm.';
    ELSE
        -- Nếu vì lý do nào đó cột chưa có (chạy script 04 chưa xong), thêm vào:
        IF v_col_sys IS NULL THEN
            ALTER TABLE vitals
                ADD COLUMN blood_pressure_sys SMALLINT
                    CHECK (blood_pressure_sys IS NULL OR (blood_pressure_sys > 0 AND blood_pressure_sys < 300));
            RAISE NOTICE '⚠️  Added missing column: vitals.blood_pressure_sys';
        END IF;

        IF v_col_dia IS NULL THEN
            ALTER TABLE vitals
                ADD COLUMN blood_pressure_dia SMALLINT
                    CHECK (blood_pressure_dia IS NULL OR (blood_pressure_dia > 0 AND blood_pressure_dia < 200));
            RAISE NOTICE '⚠️  Added missing column: vitals.blood_pressure_dia';
        END IF;
    END IF;
END $$;

-- ============================================================================
-- PART 2: Tạo bảng user_push_tokens (Phase 8 — Push Notification)
-- [HS-009 Phase 4] Renamed from user_fcm_tokens to user_push_tokens per ADR-016.
-- Added: device_id (FK devices, nullable), last_sync_at (TIMESTAMPTZ).
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_push_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Optional FK to devices: link push token to a specific device (nullable)
    device_id   INT REFERENCES devices(id) ON DELETE SET NULL,

    -- Push token từ Firebase SDK / APNs (mobile app gửi lên sau khi login)
    token       TEXT NOT NULL,
    platform    VARCHAR(10) DEFAULT 'android'
                    CHECK (platform IN ('android', 'ios', 'web')),

    -- Quản lý vòng đời token
    is_active   BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),

    -- Mỗi (user, token) là duy nhất — tránh duplicate khi re-login
    CONSTRAINT uq_user_push_token UNIQUE (user_id, token)
);

-- Index: query token hoạt động của 1 user
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_active
    ON user_push_tokens (user_id)
    WHERE is_active = TRUE;

-- Comments
COMMENT ON TABLE  user_push_tokens               IS 'Push notification tokens (FCM/APNs) của từng user — ghi từ mobile app sau khi login';
COMMENT ON COLUMN user_push_tokens.device_id     IS 'Optional FK tới devices.id (nullable) — link token tới thiết bị cụ thể nếu biết';
COMMENT ON COLUMN user_push_tokens.token         IS 'Push registration token từ Firebase SDK / APNs (hết hạn theo provider policy)';
COMMENT ON COLUMN user_push_tokens.platform      IS 'Nền tảng thiết bị: android | ios | web';
COMMENT ON COLUMN user_push_tokens.is_active     IS 'FALSE nếu token đã bị thu hồi hoặc user logout';
COMMENT ON COLUMN user_push_tokens.last_sync_at  IS 'Timestamp lần cuối client đồng bộ token (heartbeat dùng để pruning stale token)';

-- ============================================================================
-- PART 3: Kiểm tra toàn bộ bảng cần thiết cho integration
-- ============================================================================

DO $$
DECLARE
    tbl text;
    tbl_exists boolean;
    required_tables text[] := ARRAY[
        'users', 'devices', 'vitals', 'motion_data',
        'fall_events', 'sos_events', 'alerts',
        'sleep_sessions', 'risk_scores', 'risk_explanations',
        'user_push_tokens'
    ];
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Integration Readiness Check ===';
    FOREACH tbl IN ARRAY required_tables LOOP
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = tbl AND table_schema = 'public'
        ) INTO tbl_exists;

        IF tbl_exists THEN
            RAISE NOTICE '✅  %', tbl;
        ELSE
            RAISE NOTICE '❌  % — MISSING! Chạy script tương ứng.', tbl;
        END IF;
    END LOOP;
    RAISE NOTICE '===================================';
    RAISE NOTICE '→ Script 16 hoàn thành. Sẵn sàng cho Integration Phase 0.';
END $$;
