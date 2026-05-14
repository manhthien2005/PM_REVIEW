-- ============================================================================
-- File: 20260514_drop_calibration_offsets.sql
-- Description: HS-003 Phase 4 — purge calibration offset keys khoi devices.calibration_data
--   per ADR-012 (drop dead fields).
--   3 keys da xoa: heart_rate_offset, spo2_calibration, temperature_offset.
--   Keys nay never consumed by mobile BE, IoT sim, or HealthGuard backend.
--
-- NOTE: 3 keys song trong JSONB column calibration_data, KHONG phai column rieng.
-- Migration nay chi UPDATE rows existing de purge dead keys, KHONG ALTER schema.
--
-- ADR: ADR-012 drop-calibration-offset-fields.
-- Bug: HS-003 (Medium).
-- Author: ThienPDM
-- Date: 2026-05-14
-- ============================================================================
--
-- PRE-FLIGHT (production):
--   1. Snapshot rows affected:
--      SELECT COUNT(*) FROM devices
--        WHERE calibration_data ?| ARRAY['heart_rate_offset','spo2_calibration','temperature_offset'];
--   2. Sample current shape:
--      SELECT id, calibration_data FROM devices
--        WHERE calibration_data IS NOT NULL LIMIT 5;
--
-- ROLLBACK: KHONG can - 3 keys da deprecated, khong code consumer doc.
--   Neu can revert (unlikely), restore tu DB backup.
-- ============================================================================

BEGIN;

-- Purge 3 dead keys khoi tat ca rows
UPDATE devices
SET calibration_data = calibration_data
    - 'heart_rate_offset'
    - 'spo2_calibration'
    - 'temperature_offset'
WHERE calibration_data IS NOT NULL
  AND calibration_data ?| ARRAY['heart_rate_offset', 'spo2_calibration', 'temperature_offset'];

-- Set calibration_data = NULL neu sau purge tro thanh empty object
UPDATE devices
SET calibration_data = NULL
WHERE calibration_data = '{}'::jsonb;

COMMIT;

-- ============================================================================
-- POST-CHECK
-- ============================================================================

DO $$
DECLARE
    leftover_count int;
BEGIN
    SELECT COUNT(*) INTO leftover_count
    FROM devices
    WHERE calibration_data ?| ARRAY['heart_rate_offset', 'spo2_calibration', 'temperature_offset'];

    IF leftover_count = 0 THEN
        RAISE NOTICE 'Migration HS-003 OK - calibration offset keys purged';
    ELSE
        RAISE EXCEPTION 'Migration HS-003 FAILED - % rows still contain dead keys', leftover_count;
    END IF;
END $$;
