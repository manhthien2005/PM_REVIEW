-- ============================================================================
-- File: 11_create_password_reset_tokens.sql
-- Description: [DEPRECATED] Bảng phụ lưu JWT token reset mật khẩu
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================
--
-- ⚠️  DEPRECATED (từ 14/03/2026):
--     Luồng Auth mới (file 14) đã chuyển sang dùng mã PIN 6 số lưu trực tiếp
--     trong cột `reset_code` và `reset_code_expires_at` của bảng `users`.
--     Bảng này KHÔNG còn được sử dụng trong Auth Service mới.
--     Giữ lại để backward-compat với DB instance đã chạy script này trước đó.
--
-- ============================================================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_hash ON password_reset_tokens(token_hash);

DO $$
BEGIN
    RAISE NOTICE '⚠ Created table: password_reset_tokens (DEPRECATED - See file 14)';
END $$;
