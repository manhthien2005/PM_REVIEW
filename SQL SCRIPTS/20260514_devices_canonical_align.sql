-- ============================================================================
-- File: 20260514_devices_canonical_align.sql
-- Description: HS-001 Phase 4 — devices.user_id alignment per ADR-010.
--   Canonical: user_id INT REFERENCES users(id) ON DELETE SET NULL (nullable).
--   Drift production (neu deploy tu health_system/SQL SCRIPTS/03_create_tables_devices.sql):
--     user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE.
--   Migration nay align production ve canonical (idempotent).
-- ADR: ADR-010 devices-schema-canonical.
-- Bug: HS-001 (Critical).
-- Author: ThienPDM
-- Date: 2026-05-14
-- ============================================================================
--
-- PRE-FLIGHT (production):
--   1. Verify table exists: SELECT 1 FROM devices LIMIT 1;
--   2. Check current FK behavior:
--      SELECT con.confupdtype, con.confdeltype FROM pg_constraint con
--        JOIN pg_class rel ON rel.oid = con.conrelid
--        WHERE rel.relname='devices' AND con.contype='f' AND con.conname LIKE '%user_id%';
--      Expected after migration: confdeltype='n' (SET NULL).
--   3. Snapshot devices count before:
--      SELECT COUNT(*) FROM devices; -- record value, verify same after
--
-- ROLLBACK (neu can revert):
--   ALTER TABLE devices ALTER COLUMN user_id SET NOT NULL;
--   ALTER TABLE devices DROP CONSTRAINT devices_user_id_fkey;
--   ALTER TABLE devices ADD CONSTRAINT devices_user_id_fkey
--       FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
-- ============================================================================

BEGIN;

-- 1. Drop NOT NULL constraint (no-op neu da nullable)
DO $$
DECLARE
    is_nullable_now boolean;
BEGIN
    SELECT (is_nullable = 'YES') INTO is_nullable_now
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id';

    IF NOT is_nullable_now THEN
        ALTER TABLE devices ALTER COLUMN user_id DROP NOT NULL;
        RAISE NOTICE 'Dropped NOT NULL on devices.user_id';
    ELSE
        RAISE NOTICE 'devices.user_id already nullable (no-op)';
    END IF;
END $$;

-- 2. Drop existing FK + recreate with ON DELETE SET NULL
DO $$
DECLARE
    fk_name text;
    delete_action char;
BEGIN
    -- Find existing FK constraint name on devices.user_id
    SELECT con.conname, con.confdeltype
    INTO fk_name, delete_action
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
    WHERE rel.relname = 'devices'
      AND con.contype = 'f'
      AND att.attname = 'user_id'
    LIMIT 1;

    IF fk_name IS NULL THEN
        -- No FK found, just add new one
        ALTER TABLE devices
            ADD CONSTRAINT devices_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added new FK devices_user_id_fkey ON DELETE SET NULL';
    ELSIF delete_action = 'n' THEN
        -- Already SET NULL
        RAISE NOTICE 'FK % already ON DELETE SET NULL (no-op)', fk_name;
    ELSE
        -- Drop and recreate
        EXECUTE format('ALTER TABLE devices DROP CONSTRAINT %I', fk_name);
        ALTER TABLE devices
            ADD CONSTRAINT devices_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
        RAISE NOTICE 'Recreated FK % -> devices_user_id_fkey ON DELETE SET NULL', fk_name;
    END IF;
END $$;

COMMIT;

-- ============================================================================
-- POST-CHECK
-- ============================================================================

DO $$
DECLARE
    is_nullable_now boolean;
    delete_action char;
BEGIN
    SELECT (is_nullable = 'YES') INTO is_nullable_now
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'devices' AND column_name = 'user_id';

    SELECT con.confdeltype INTO delete_action
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
    WHERE rel.relname = 'devices'
      AND con.contype = 'f'
      AND att.attname = 'user_id'
    LIMIT 1;

    IF is_nullable_now AND delete_action = 'n' THEN
        RAISE NOTICE 'Migration HS-001 OK - devices.user_id nullable + ON DELETE SET NULL';
    ELSE
        RAISE EXCEPTION 'Migration HS-001 FAILED - nullable=%, delete_action=%',
            is_nullable_now, delete_action;
    END IF;
END $$;
