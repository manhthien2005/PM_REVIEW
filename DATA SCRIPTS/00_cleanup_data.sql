-- ============================================================================
-- File: 00_cleanup_data.sql
-- Description: Xóa dữ liệu cũ từ tất cả các bảng theo thứ tự đúng
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- Xóa dữ liệu theo thứ tự ngược lại để tránh lỗi foreign key constraint

-- 1. Xóa các bảng con trước (có foreign key)
DELETE FROM audit_logs;
DELETE FROM alerts;
DELETE FROM risk_explanations;
DELETE FROM risk_scores;
DELETE FROM fall_events;
DELETE FROM sos_events;
DELETE FROM motion_data;
DELETE FROM vitals;
DELETE FROM sleep_sessions;
DELETE FROM emergency_contacts;
DELETE FROM user_relationships;
DELETE FROM password_reset_tokens;

-- 2. Xóa devices (có foreign key tới users)
DELETE FROM devices;

-- 3. Xóa users (bảng cha)
DELETE FROM users;
DELETE FROM users_archive;

-- 4. Xóa system settings
DELETE FROM system_settings;

-- 5. Xóa system metrics
DELETE FROM system_metrics;

-- 6. Reset sequences về 1
SELECT setval('users_id_seq', 1, false);
SELECT setval('devices_id_seq', 1, false);
SELECT setval('alerts_id_seq', 1, false);
SELECT setval('emergency_contacts_id_seq', 1, false);
SELECT setval('fall_events_id_seq', 1, false);
SELECT setval('sos_events_id_seq', 1, false);
SELECT setval('risk_scores_id_seq', 1, false);
SELECT setval('risk_explanations_id_seq', 1, false);
SELECT setval('user_relationships_id_seq', 1, false);
SELECT setval('password_reset_tokens_id_seq', 1, false);
SELECT setval('sleep_sessions_id_seq', 1, false);
SELECT setval('users_archive_id_seq', 1, false);

COMMIT;

-- Hiển thị thông báo
SELECT 'Đã xóa sạch tất cả dữ liệu và reset sequences!' as status;