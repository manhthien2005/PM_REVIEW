-- ============================================================================
-- File: 18_add_sleep_unique_constraint.sql
-- Description: Thêm cột sleep_date (DATE thường) và UNIQUE constraint vào
--              bảng sleep_sessions để ngăn duplicate records từ IoT Simulator.
-- Tables affected: sleep_sessions (existing)
-- Depends on: 04_create_tables_timeseries.sql (sleep_sessions phải tồn tại)
-- Idempotent: an toàn khi chạy lại nhiều lần (IF NOT EXISTS throughout)
-- Author: HealthGuard Development Team
-- Date: 2026-04-01
-- ============================================================================
-- NOTE: Không dùng GENERATED ALWAYS AS (start_time::date) vì start_time là
-- TIMESTAMPTZ — biểu thức phụ thuộc TimeZone GUC, không phải IMMUTABLE.
-- Giải pháp: Dùng cột DATE thường, backend điền từ payload.date khi INSERT.
-- ============================================================================

-- ============================================================================
-- STEP 1: Thêm cột sleep_date DATE (plain column, không GENERATED)
-- Backend telemetry.py sẽ điền cột này từ payload.date (IoT SIM đã gửi sẵn)
-- ============================================================================
ALTER TABLE sleep_sessions
    ADD COLUMN IF NOT EXISTS sleep_date DATE;


-- ============================================================================
-- STEP 2: Tạo UNIQUE index theo (user_id, device_id, sleep_date)
-- Mục đích: Ngăn IoT Simulator push nhiều lần cùng ngày cho cùng thiết bị
-- Khi conflict: Backend dùng ON CONFLICT (user_id, device_id, sleep_date) DO UPDATE
-- ============================================================================
CREATE UNIQUE INDEX IF NOT EXISTS uq_sleep_user_device_date
    ON sleep_sessions (user_id, device_id, sleep_date);


-- ============================================================================
-- Print confirmation
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✓ Column sleep_date DATE added to sleep_sessions (IF NOT EXISTS)';
    RAISE NOTICE '✓ UNIQUE INDEX uq_sleep_user_device_date created (IF NOT EXISTS)';
    RAISE NOTICE '  Constraint: (user_id, device_id, sleep_date)';
    RAISE NOTICE '  Backend telemetry.py: INSERT must include sleep_date from payload.date';
    RAISE NOTICE '  Backend telemetry.py: ON CONFLICT (user_id, device_id, sleep_date) DO UPDATE';
END $$;
