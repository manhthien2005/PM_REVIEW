-- ============================================================================
-- File: 20260514_user_push_tokens_canonical_align.sql
-- Description: HS-009 Phase 4 — align canonical schema với production reality.
--   1. Rename table user_fcm_tokens -> user_push_tokens.
--   2. Add column device_id (nullable FK -> devices ON DELETE SET NULL).
--   3. Add column last_sync_at TIMESTAMPTZ.
--   4. Rename UNIQUE constraint + index theo naming canonical mới.
-- ADR: ADR-016 user-push-tokens-canonical-rename (Option B).
-- Bug: HS-009 (Critical).
-- Author: ThienPDM
-- Date: 2026-05-14
-- ============================================================================
--
-- PRE-FLIGHT CHECK (production):
--   1. Verify HealthGuard Prisma da drop zombie model fcm_tokens (Session C BLOCK 8 merged).
--      psql> \d user_fcm_tokens   -- expect: relation "user_fcm_tokens" exists
--   2. Verify HealthGuard backend grep "user_fcm_tokens" = 0 hit.
--   3. Verify mobile BE ORM tablename da match (push_token_model.py:13 user_push_tokens).
--
-- ROLLBACK (neu can):
--   ALTER TABLE user_push_tokens DROP COLUMN last_sync_at;
--   ALTER TABLE user_push_tokens DROP COLUMN device_id;
--   ALTER TABLE user_push_tokens RENAME CONSTRAINT uq_user_push_token TO uq_user_fcm_token;
--   ALTER INDEX idx_push_tokens_user_active RENAME TO idx_fcm_tokens_user_active;
--   ALTER TABLE user_push_tokens RENAME TO user_fcm_tokens;
-- ============================================================================

BEGIN;

-- 1. Rename table (giu nguyen het data)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_fcm_tokens'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_push_tokens'
    ) THEN
        ALTER TABLE user_fcm_tokens RENAME TO user_push_tokens;
        RAISE NOTICE 'Renamed table user_fcm_tokens -> user_push_tokens';
    ELSE
        RAISE NOTICE 'Skip rename: target table user_push_tokens may already exist or source missing';
    END IF;
END $$;

-- 2. Add column device_id (nullable FK ON DELETE SET NULL)
ALTER TABLE user_push_tokens
    ADD COLUMN IF NOT EXISTS device_id INT
        REFERENCES devices(id) ON DELETE SET NULL;

-- 3. Add column last_sync_at
ALTER TABLE user_push_tokens
    ADD COLUMN IF NOT EXISTS last_sync_at TIMESTAMPTZ;

-- 4. Rename UNIQUE constraint - chi rename neu constraint THUOC table user_push_tokens
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        JOIN pg_namespace n ON t.relnamespace = n.oid
        WHERE c.conname = 'uq_user_fcm_token'
          AND t.relname = 'user_push_tokens'
          AND n.nspname = 'public'
    ) THEN
        ALTER TABLE user_push_tokens
            RENAME CONSTRAINT uq_user_fcm_token TO uq_user_push_token;
        RAISE NOTICE 'Renamed constraint uq_user_fcm_token -> uq_user_push_token';
    ELSE
        RAISE NOTICE 'Skip rename constraint: uq_user_fcm_token not found on user_push_tokens';
    END IF;
END $$;

-- 5. Rename index
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public' AND indexname = 'idx_fcm_tokens_user_active'
    ) THEN
        ALTER INDEX idx_fcm_tokens_user_active RENAME TO idx_push_tokens_user_active;
        RAISE NOTICE 'Renamed index idx_fcm_tokens_user_active -> idx_push_tokens_user_active';
    END IF;
END $$;

-- 6. Update column comments theo canonical moi
COMMENT ON TABLE  user_push_tokens               IS 'Push notification tokens (FCM/APNs) cua tung user - ghi tu mobile app sau khi login';
COMMENT ON COLUMN user_push_tokens.device_id     IS 'Optional FK toi devices.id (nullable) - link token toi thiet bi cu the neu biet';
COMMENT ON COLUMN user_push_tokens.last_sync_at  IS 'Timestamp lan cuoi client dong bo token (heartbeat dung de pruning stale token)';

COMMIT;

-- ============================================================================
-- POST-CHECK
-- ============================================================================

DO $$
DECLARE
    has_table boolean;
    has_device_id boolean;
    has_last_sync_at boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_push_tokens'
    ) INTO has_table;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'user_push_tokens' AND column_name = 'device_id'
    ) INTO has_device_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'user_push_tokens' AND column_name = 'last_sync_at'
    ) INTO has_last_sync_at;

    IF has_table AND has_device_id AND has_last_sync_at THEN
        RAISE NOTICE 'Migration HS-009 OK - user_push_tokens(device_id, last_sync_at) ready';
    ELSE
        RAISE EXCEPTION 'Migration HS-009 FAILED - table=%, device_id=%, last_sync_at=%',
            has_table, has_device_id, has_last_sync_at;
    END IF;
END $$;
