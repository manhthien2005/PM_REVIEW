-- ============================================================================
-- File: 20260514_phase4_all_migrations.sql
-- Description: Phase 4 consolidated migration. Chay 1 lan qua pgAdmin Query Tool.
--   1. HS-009 - rename user_fcm_tokens -> user_push_tokens + 2 cot moi
--   2. HS-001 - devices.user_id NULL + ON DELETE SET NULL
--   3. HS-003 - drop 3 cot calibration offsets
--   4. HS-002 - devices.mac_address UNIQUE global
--   5. HS-012 - user_relationships default permission TRUE
--   6. XR-002 - alerts.severity rename normal -> low + CHECK 4-level
--
-- Cach chay:
--   pgAdmin Query Tool -> File -> Open file nay -> F5
--   Moi step doc lap qua DO block + EXCEPTION handler.
--   1 step fail KHONG abort cac step sau.
--
-- Author: ThienPDM (via Kiro)
-- Date: 2026-05-14
-- ============================================================================

-- PRE-FLIGHT INFO
DO $$
DECLARE
    v_severity_normal_count int;
    v_fcm_count int;
    v_push_count int;
    v_mac_dup_count int;
    v_calibration_cols int;
    v_devices_user_nullable text;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO v_severity_normal_count FROM alerts WHERE severity = 'normal';
    EXCEPTION WHEN undefined_table THEN
        v_severity_normal_count := -1;
    END;

    SELECT COUNT(*) INTO v_fcm_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_fcm_tokens';

    SELECT COUNT(*) INTO v_push_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_push_tokens';

    BEGIN
        SELECT COUNT(*) INTO v_mac_dup_count
        FROM (
            SELECT mac_address FROM devices
            WHERE mac_address IS NOT NULL
            GROUP BY mac_address HAVING COUNT(*) > 1
        ) AS dup;
    EXCEPTION WHEN undefined_table THEN
        v_mac_dup_count := -1;
    END;

    SELECT COUNT(*) INTO v_calibration_cols
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'devices'
      AND column_name IN ('heart_rate_offset', 'spo2_calibration', 'temperature_offset');

    SELECT is_nullable INTO v_devices_user_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id';

    RAISE NOTICE '=== PRE-FLIGHT ===';
    RAISE NOTICE 'XR-002: alerts severity=normal rows = %', v_severity_normal_count;
    RAISE NOTICE 'HS-009: user_fcm_tokens table count = %', v_fcm_count;
    RAISE NOTICE 'HS-009: user_push_tokens table count = %', v_push_count;
    RAISE NOTICE 'HS-002: MAC duplicate groups = %', v_mac_dup_count;
    RAISE NOTICE 'HS-003: calibration columns count = %', v_calibration_cols;
    RAISE NOTICE 'HS-001: devices.user_id nullable = %', v_devices_user_nullable;
    RAISE NOTICE '==================';
END $$;


-- STEP 1: HS-009 user_fcm_tokens -> user_push_tokens
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_fcm_tokens')
       AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_push_tokens') THEN
        ALTER TABLE user_fcm_tokens RENAME TO user_push_tokens;
        RAISE NOTICE 'HS-009 1a: renamed table';
    ELSE
        RAISE NOTICE 'HS-009 1a: skip rename';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-009 1a FAILED: % - %', SQLSTATE, SQLERRM;
END $$;


-- HS-009 1b add device_id
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_push_tokens')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_push_tokens' AND column_name='device_id') THEN
        ALTER TABLE user_push_tokens ADD COLUMN device_id INT REFERENCES devices(id) ON DELETE SET NULL;
        RAISE NOTICE 'HS-009 1b: added device_id';
    ELSE
        RAISE NOTICE 'HS-009 1b: skip';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-009 1b: % %', SQLSTATE, SQLERRM;
END $$;


-- HS-009 1c last_sync_at
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_push_tokens')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_push_tokens' AND column_name='last_sync_at') THEN
        ALTER TABLE user_push_tokens ADD COLUMN last_sync_at TIMESTAMPTZ;
        RAISE NOTICE 'HS-009 1c added last_sync_at';
    ELSE
        RAISE NOTICE 'HS-009 1c skip';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-009 1c err';
END $$;


-- HS-009 1d rename constraint scoped
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid=t.oid
        JOIN pg_namespace n ON t.relnamespace=n.oid
        WHERE c.conname='uq_user_fcm_token' AND t.relname='user_push_tokens' AND n.nspname='public'
    ) THEN
        ALTER TABLE user_push_tokens RENAME CONSTRAINT uq_user_fcm_token TO uq_user_push_token;
        RAISE NOTICE 'HS-009 1d renamed';
    ELSE
        RAISE NOTICE 'HS-009 1d skip';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-009 1d err';
END $$;


-- HS-009 1e rename idx
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='idx_fcm_tokens_user_active') THEN
        ALTER INDEX idx_fcm_tokens_user_active RENAME TO idx_push_tokens_user_active;
        RAISE NOTICE 'HS-009 1e renamed';
    ELSE
        RAISE NOTICE 'HS-009 1e skip';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-009 1e err';
END $$;


-- STEP 2 HS-001 devices.user_id NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='devices'
          AND column_name='user_id' AND is_nullable='NO'
    ) THEN
        ALTER TABLE devices ALTER COLUMN user_id DROP NOT NULL;
        RAISE NOTICE 'HS-001 2a DROP NOT NULL';
    ELSE
        RAISE NOTICE 'HS-001 2a already nullable';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-001 2a err';
END $$;


-- HS-001 2b verify FK ondelete setnull
DO $$
DECLARE
    v_fk_name text;
    v_fk_action char;
BEGIN
    SELECT con.conname, con.confdeltype
    INTO v_fk_name, v_fk_action
    FROM pg_constraint con
    JOIN pg_class t ON con.conrelid=t.oid
    JOIN pg_attribute a ON a.attnum=ANY(con.conkey) AND a.attrelid=con.conrelid
    WHERE con.contype='f' AND t.relname='devices' AND a.attname='user_id'
    LIMIT 1;

    IF v_fk_action IS NULL THEN
        ALTER TABLE devices
            ADD CONSTRAINT devices_user_id_fkey FOREIGN KEY (user_id)
            REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE 'HS-001 2b added FK';
    ELSIF v_fk_action <> 'n' THEN
        EXECUTE 'ALTER TABLE devices DROP CONSTRAINT ' || quote_ident(v_fk_name);
        ALTER TABLE devices
            ADD CONSTRAINT devices_user_id_fkey FOREIGN KEY (user_id)
            REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE 'HS-001 2b recreated FK';
    ELSE
        RAISE NOTICE 'HS-001 2b FK already setnull';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-001 2b err';
END $$;


-- STEP 3 HS-003 drop calib cols
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='devices' AND column_name='heart_rate_offset') THEN
        ALTER TABLE devices DROP COLUMN heart_rate_offset;
        RAISE NOTICE 'HS-003 dropped heart_rate_offset';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='devices' AND column_name='spo2_calibration') THEN
        ALTER TABLE devices DROP COLUMN spo2_calibration;
        RAISE NOTICE 'HS-003 dropped spo2_calibration';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='devices' AND column_name='temperature_offset') THEN
        ALTER TABLE devices DROP COLUMN temperature_offset;
        RAISE NOTICE 'HS-003 dropped temp_offset';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-003 err';
END $$;


-- STEP 4 HS-002 mac unique
DO $$
DECLARE
    v_dup int;
BEGIN
    SELECT COUNT(*) INTO v_dup
    FROM (SELECT mac_address FROM devices WHERE mac_address IS NOT NULL GROUP BY mac_address HAVING COUNT(*)>1) d;

    IF v_dup>0 THEN
        RAISE WARNING 'HS-002 ABORT % dup MAC', v_dup;
    ELSIF EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid=t.oid
        WHERE c.conname='uq_devices_mac' AND t.relname='devices'
    ) THEN
        RAISE NOTICE 'HS-002 exists';
    ELSE
        ALTER TABLE devices ADD CONSTRAINT uq_devices_mac UNIQUE (mac_address);
        RAISE NOTICE 'HS-002 added UNIQUE';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-002 err';
END $$;


-- STEP 5 HS-012 relationship perm TRUE
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_relationships' AND column_name='can_view_vitals') THEN
        ALTER TABLE user_relationships ALTER COLUMN can_view_vitals SET DEFAULT TRUE;
        RAISE NOTICE 'HS-012 view default TRUE';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_relationships' AND column_name='can_receive_alerts') THEN
        ALTER TABLE user_relationships ALTER COLUMN can_receive_alerts SET DEFAULT TRUE;
        RAISE NOTICE 'HS-012 alert default TRUE';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'HS-012 err';
END $$;


-- STEP 6 XR-002 severity backfill normal->low
DO $$
DECLARE
    v_normal int;
BEGIN
    SELECT COUNT(*) INTO v_normal FROM alerts WHERE severity='normal';
    IF v_normal>0 THEN
        UPDATE alerts SET severity='low' WHERE severity='normal';
        RAISE NOTICE 'XR-002 6a backfilled %', v_normal;
    ELSE
        RAISE NOTICE 'XR-002 6a no normal rows';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'XR-002 6a err';
END $$;


-- STEP 6 XR-002 6b drop old check
DO $$
DECLARE
    v_check_name text;
BEGIN
    SELECT con.conname INTO v_check_name
    FROM pg_constraint con
    JOIN pg_class t ON con.conrelid=t.oid
    WHERE con.contype='c' AND t.relname='alerts'
      AND pg_get_constraintdef(con.oid) ILIKE '%severity%'
    LIMIT 1;

    IF v_check_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE alerts DROP CONSTRAINT ' || quote_ident(v_check_name);
        RAISE NOTICE 'XR-002 6b dropped %', v_check_name;
    ELSE
        RAISE NOTICE 'XR-002 6b no old check';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'XR-002 6b err';
END $$;


-- STEP 6 XR-002 6c add CHECK 4-level
DO $$
BEGIN
    ALTER TABLE alerts
        ADD CONSTRAINT check_alert_severity
        CHECK (severity IN ('low','medium','high','critical'));
    RAISE NOTICE 'XR-002 6c added CHECK 4-level';
EXCEPTION WHEN duplicate_object THEN
    RAISE NOTICE 'XR-002 6c exists';
WHEN OTHERS THEN
    RAISE WARNING 'XR-002 6c err';
END $$;


-- POST-CHECK
DO $$
DECLARE
    v_push_table boolean;
    v_push_device_id boolean;
    v_push_last_sync boolean;
    v_devices_nullable text;
    v_calib_cols int;
    v_mac_unique boolean;
    v_rel_default text;
    v_sev_normal int;
BEGIN
    SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_push_tokens') INTO v_push_table;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_push_tokens' AND column_name='device_id') INTO v_push_device_id;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='user_push_tokens' AND column_name='last_sync_at') INTO v_push_last_sync;
    SELECT is_nullable INTO v_devices_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name='devices' AND column_name='user_id';
    SELECT COUNT(*) INTO v_calib_cols FROM information_schema.columns WHERE table_schema='public' AND table_name='devices' AND column_name IN ('heart_rate_offset','spo2_calibration','temperature_offset');
    SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON c.conrelid=t.oid WHERE c.conname='uq_devices_mac' AND t.relname='devices') INTO v_mac_unique;
    SELECT column_default INTO v_rel_default FROM information_schema.columns WHERE table_schema='public' AND table_name='user_relationships' AND column_name='can_view_vitals';
    SELECT COUNT(*) INTO v_sev_normal FROM alerts WHERE severity='normal';

    RAISE NOTICE '';
    RAISE NOTICE '=== POST-CHECK ===';
    RAISE NOTICE 'HS-009 push table=% device_id=% last_sync_at=%', v_push_table, v_push_device_id, v_push_last_sync;
    RAISE NOTICE 'HS-001 devices nullable=%', v_devices_nullable;
    RAISE NOTICE 'HS-003 calib cols=%', v_calib_cols;
    RAISE NOTICE 'HS-002 mac unique=%', v_mac_unique;
    RAISE NOTICE 'HS-012 default=%', v_rel_default;
    RAISE NOTICE 'XR-002 normal=%', v_sev_normal;
END $$;
