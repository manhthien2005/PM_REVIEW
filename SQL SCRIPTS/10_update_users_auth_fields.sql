-- ============================================================================
-- File: 10_update_users_auth_fields.sql
-- Description: Cập nhật các cột mới cho bảng users để phục vụ Auth (token version & password reset)
-- Target Table: users
-- Author: HealthGuard Development Team (Bot)
-- Date: 05/03/2026
-- ============================================================================

-- 1. Thêm cột token_version để hỗ trợ session invalidation (SRS §5.3)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS token_version INT NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ(6);

-- 2. Thêm comments mô tả mục đích các cột
COMMENT ON COLUMN users.token_version IS 'Phiên bản token hiện tại (Tăng lên để logout tất cả thiết bị khi đổi mật khẩu)';
COMMENT ON COLUMN users.failed_login_attempts IS 'Số lần đăng nhập sai mật khẩu (Reset sau khi thành công)';
COMMENT ON COLUMN users.locked_until IS 'Thời gian khóa tài khoản tạm thời (do bruteforce)';

-- 3. Thông báo hoàn tất
DO $$
BEGIN
    RAISE NOTICE '✓ Updated table: users with new auth fields (token_version, failed_login_attempts, locked_until)';
END $$;
