-- ============================================================================
-- File: 14_add_verification_codes_to_users.sql
-- Description: Thêm cột lưu mã PIN 6 số (thay thế JWT token) vào bảng users
--              cho luồng xác thực email và đặt lại mật khẩu.
-- Target Table: users
-- Author: HealthGuard Development Team
-- Date: 14/03/2026
-- Ref: Implementation Plan - Refactor Verification Token -> 6-digit Code
-- ============================================================================

-- ============================================================================
-- Lý do thay đổi:
--   JWT verification token cũ rất dài, không thân thiện với UX mobile.
--   Hệ thống mới dùng mã PIN 6 số (dạng string để giữ số 0 đầu, VD: '012345')
--   lưu trực tiếp trong bảng users, kết hợp với email để đảm bảo tính duy nhất.
--
--   Bảng password_reset_tokens (file 11) được giữ nguyên để backward-compat
--   nhưng KHÔNG còn được sử dụng trong luồng Auth mới.
-- ============================================================================

-- 1. Thêm cột lưu mã xác thực email (email verification)
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS verification_code       VARCHAR(6),
    ADD COLUMN IF NOT EXISTS verification_code_expires_at TIMESTAMPTZ(6);

-- 2. Thêm cột lưu mã đặt lại mật khẩu (password reset)
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS reset_code              VARCHAR(6),
    ADD COLUMN IF NOT EXISTS reset_code_expires_at   TIMESTAMPTZ(6);

-- 3. Thêm comments mô tả mục đích các cột
COMMENT ON COLUMN users.verification_code IS
    'Mã PIN 6 chữ số xác thực email (NULL sau khi xác thực xong). Lưu dạng VARCHAR để giữ số 0 đầu (VD: 012345)';
COMMENT ON COLUMN users.verification_code_expires_at IS
    'Thời hạn hiệu lực của mã xác thực email (thường 15 phút sau khi gửi)';
COMMENT ON COLUMN users.reset_code IS
    'Mã PIN 6 chữ số để đặt lại mật khẩu (NULL sau khi sử dụng). Lưu dạng VARCHAR để giữ số 0 đầu.';
COMMENT ON COLUMN users.reset_code_expires_at IS
    'Thời hạn hiệu lực của mã đặt lại mật khẩu (thường 15 phút sau khi gửi)';

-- 4. Tạo index để tăng tốc tra cứu theo email + code (composite lookup)
--    Khi user submit mã, backend sẽ query: WHERE email = ? AND verification_code = ?
CREATE INDEX IF NOT EXISTS idx_users_verification_code
    ON users (email, verification_code)
    WHERE verification_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_reset_code
    ON users (email, reset_code)
    WHERE reset_code IS NOT NULL;

-- 5. Thông báo hoàn tất
DO $$
BEGIN
    RAISE NOTICE '✓ Updated table: users';
    RAISE NOTICE '  + verification_code (VARCHAR6)';
    RAISE NOTICE '  + verification_code_expires_at (TIMESTAMPTZ)';
    RAISE NOTICE '  + reset_code (VARCHAR6)';
    RAISE NOTICE '  + reset_code_expires_at (TIMESTAMPTZ)';
    RAISE NOTICE '  + Index: idx_users_verification_code';
    RAISE NOTICE '  + Index: idx_users_reset_code';
    RAISE NOTICE '⚠ NOTE: Bảng password_reset_tokens (file 11) đã deprecated.';
    RAISE NOTICE '  Luồng reset password mới dùng cột reset_code trong bảng users.';
END $$;
