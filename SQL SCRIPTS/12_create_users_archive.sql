-- ============================================================================
-- File: 12_create_users_archive.sql
-- Description: Tạo bảng users_archive để lưu trữ người dùng đã xóa/lưu trữ (archived)
-- Tables: users_archive
-- Author: HealthGuard Development Team
-- ============================================================================

CREATE TABLE IF NOT EXISTS users_archive (
    id SERIAL PRIMARY KEY,
    original_id INT NOT NULL,
    uuid UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    user_data JSON NOT NULL,
    archived_at TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    archived_by INT
);

CREATE INDEX IF NOT EXISTS idx_users_archive_original_id ON users_archive(original_id);
CREATE INDEX IF NOT EXISTS idx_users_archive_email ON users_archive(email);

-- Add comments
COMMENT ON TABLE users_archive IS 'Bảng lưu trữ thông tin người dùng đã bị xóa (archived)';
COMMENT ON COLUMN users_archive.original_id IS 'ID gốc của người dùng trong bảng users trước khi xóa';
COMMENT ON COLUMN users_archive.user_data IS 'Dữ liệu toàn vẹn của người dùng được lưu dưới định dạng JSON';
COMMENT ON COLUMN users_archive.archived_at IS 'Thời gian lưu trữ (mặc định là lúc tạo bản ghi archive)';
COMMENT ON COLUMN users_archive.archived_by IS 'ID của người dùng/admin thực hiện lưu trữ (nếu có)';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: users_archive';
    RAISE NOTICE '✓ Created indexes for users_archive';
END $$;
