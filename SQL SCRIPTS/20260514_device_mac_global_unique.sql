-- ============================================================================
-- File: 20260514_device_mac_global_unique.sql
-- Description: HS-002 Phase 4 — partial UNIQUE indexes cho devices identity
--   per BR-040-01 (1 physical device = 1 user mapping).
--
--   3 partial UNIQUE indexes (deleted_at IS NULL + col IS NOT NULL):
--     1. devices_mac_active_uniq    on mac_address
--     2. devices_serial_active_uniq on serial_number
--     3. devices_mqtt_active_uniq   on mqtt_client_id
--
--   WHY partial UNIQUE thay vi hard UNIQUE constraint:
--     - Cho phep re-pair sau soft-delete (deleted_at IS NOT NULL row khong block).
--     - Tolerate NULL value (devices_mqtt_client_id can NULLable cho devices chua connect).
--
-- Bug: HS-002 (High).
-- Author: ThienPDM
-- Date: 2026-05-14
-- ============================================================================
--
-- PRE-FLIGHT (production - MANDATORY):
--   1. Detect existing duplicate MAC active rows BEFORE applying:
--      SELECT mac_address, COUNT(*) FROM devices
--        WHERE deleted_at IS NULL AND mac_address IS NOT NULL
--        GROUP BY mac_address HAVING COUNT(*) > 1;
--      Neu co duplicate -> manual resolve TRUOC (delete duplicate hoac soft-delete).
--   2. Same check cho serial_number va mqtt_client_id.
--   3. Neu skip pre-flight, migration se RAISE ERROR khi build index.
--
-- ROLLBACK:
--   DROP INDEX IF EXISTS devices_mac_active_uniq;
--   DROP INDEX IF EXISTS devices_serial_active_uniq;
--   DROP INDEX IF EXISTS devices_mqtt_active_uniq;
-- ============================================================================

BEGIN;

-- 1. mac_address partial UNIQUE
CREATE UNIQUE INDEX IF NOT EXISTS devices_mac_active_uniq
    ON devices(mac_address)
    WHERE deleted_at IS NULL AND mac_address IS NOT NULL;

-- 2. serial_number partial UNIQUE
CREATE UNIQUE INDEX IF NOT EXISTS devices_serial_active_uniq
    ON devices(serial_number)
    WHERE deleted_at IS NULL AND serial_number IS NOT NULL;

-- 3. mqtt_client_id partial UNIQUE
CREATE UNIQUE INDEX IF NOT EXISTS devices_mqtt_active_uniq
    ON devices(mqtt_client_id)
    WHERE deleted_at IS NULL AND mqtt_client_id IS NOT NULL;

COMMIT;

-- ============================================================================
-- POST-CHECK
-- ============================================================================

DO $$
DECLARE
    has_mac boolean;
    has_serial boolean;
    has_mqtt boolean;
BEGIN
    SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'devices_mac_active_uniq')    INTO has_mac;
    SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'devices_serial_active_uniq') INTO has_serial;
    SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'devices_mqtt_active_uniq')   INTO has_mqtt;

    IF has_mac AND has_serial AND has_mqtt THEN
        RAISE NOTICE 'Migration HS-002 OK - 3 partial UNIQUE indexes created';
    ELSE
        RAISE EXCEPTION 'Migration HS-002 FAILED - mac=%, serial=%, mqtt=%',
            has_mac, has_serial, has_mqtt;
    END IF;
END $$;
