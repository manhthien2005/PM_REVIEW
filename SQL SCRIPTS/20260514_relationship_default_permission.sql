-- ============================================================================
-- File: 20260514_relationship_default_permission.sql
-- Description: HS-012 Phase 4 - flip default can_view_vitals + can_receive_alerts
--   from FALSE to TRUE on user_relationships per ADR-017.
--
--   Canonical (init_full_setup.sql:121-123) already has DEFAULT true; this
--   migration aligns production DB if previously deployed via ORM-driven
--   schema (Python-side default=False).
--
--   Rows existing keep their old values (no backfill) - migration only
--   affects rows inserted AFTER apply.
--
-- ADR: ADR-017 relationship-default-permission-true.
-- Bug: HS-012 (Medium).
-- Author: ThienPDM
-- Date: 2026-05-14
-- ============================================================================
--
-- PRE-FLIGHT (production):
--   1. Verify mobile BE deploy with ORM default=True FIRST (ADR-017 Note).
--   2. Snapshot rows count:
--      SELECT COUNT(*) FROM user_relationships;
--
-- ROLLBACK:
--   ALTER TABLE user_relationships ALTER COLUMN can_view_vitals SET DEFAULT FALSE;
--   ALTER TABLE user_relationships ALTER COLUMN can_receive_alerts SET DEFAULT FALSE;
-- ============================================================================

BEGIN;

ALTER TABLE user_relationships
    ALTER COLUMN can_view_vitals SET DEFAULT TRUE;

ALTER TABLE user_relationships
    ALTER COLUMN can_receive_alerts SET DEFAULT TRUE;

-- can_view_location + can_view_medical_info stay DEFAULT FALSE (opt-in for sensitive data).

COMMIT;

-- ============================================================================
-- POST-CHECK
-- ============================================================================

DO $$
DECLARE
    vitals_default text;
    alerts_default text;
BEGIN
    SELECT column_default INTO vitals_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_relationships'
      AND column_name = 'can_view_vitals';

    SELECT column_default INTO alerts_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_relationships'
      AND column_name = 'can_receive_alerts';

    IF vitals_default ILIKE '%true%' AND alerts_default ILIKE '%true%' THEN
        RAISE NOTICE 'Migration HS-012 OK - can_view_vitals + can_receive_alerts DEFAULT TRUE';
    ELSE
        RAISE EXCEPTION 'Migration HS-012 FAILED - vitals=%, alerts=%',
            vitals_default, alerts_default;
    END IF;
END $$;
