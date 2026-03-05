-- ============================================================================
-- File: 10_update_users_auth_fields.sql
-- Description: Cập nhật các cột mới cho bảng users để phục vụ Auth (token version & password reset)
-- Target Table: users
-- Author: HealthGuard Development Team (Bot)
-- Date: 05/03/2026
-- ============================================================================

-- 1. Thêm cột token_version để hỗ trợ session invalidation (SRS §5.3)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS token_version INT NOT NULL DEFAULT 1;

-- 2. Thêm các cột cho tính năng quên mật khẩu (one-time use token) (EP12-S01-AC5)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS reset_token_hash VARCHAR(255),
ADD COLUMN IF NOT EXISTS reset_token_expiry TIMESTAMPTZ(6);

-- 3. Thêm comments mô tả mục đích các cột
COMMENT ON COLUMN users.token_version IS 'Phiên bản token hiện tại (Tăng lên để logout tất cả thiết bị khi đổi mật khẩu)';
COMMENT ON COLUMN users.reset_token_hash IS 'Hash của token reset mật khẩu (Dùng 1 lần)';
COMMENT ON COLUMN users.reset_token_expiry IS 'Thời gian hết hạn của reset token';

-- 4. Thông báo hoàn tất
DO $$
BEGIN
    RAISE NOTICE '✓ Updated table: users with new auth fields (token_version, reset_token_hash, reset_token_expiry)';
END $$;
