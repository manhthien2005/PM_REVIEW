-- ============================================================================
-- File: 14_alter_devices_allow_null_user.sql
-- Description: Cho phép thiết bị chưa có chủ sở hữu (UC025)
-- Author: HealthGuard Development Team
-- Date: 08/03/2026
-- ============================================================================

-- Theo UC025 - BR-025-01: Một thiết bị chỉ có thể gán cho tối đa một user tại một thời điểm
-- Nhưng thiết bị có thể chưa có chủ (user_id = NULL) để Admin gán sau

-- Bước 1: Drop constraint NOT NULL trên user_id
ALTER TABLE devices 
ALTER COLUMN user_id DROP NOT NULL;

-- Bước 2: Thêm comment giải thích
COMMENT ON COLUMN devices.user_id IS 'ID người dùng sở hữu thiết bị. NULL = chưa có chủ, chờ Admin gán (UC025)';

-- Bước 3: Tạo index cho việc tìm kiếm thiết bị chưa có chủ
CREATE INDEX IF NOT EXISTS idx_devices_unassigned ON devices(id) WHERE user_id IS NULL AND deleted_at IS NULL;

COMMENT ON INDEX idx_devices_unassigned IS 'Index để tìm nhanh thiết bị chưa được gán cho user nào';
