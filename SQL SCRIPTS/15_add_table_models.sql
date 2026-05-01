-- =====================================================
-- SCRIPT: Tạo 3 bảng quản lý AI Models
-- =====================================================
-- Bảng 1: ai_models (Danh mục model)
-- Bảng 2: ai_model_versions (Các phiên bản của model)
-- Bảng 3: ai_model_mlops_states (Trạng thái MLOps)
-- =====================================================

-- =====================================================
-- 1. BẢNG: ai_models
-- Mục đích: Lưu thông tin tổng quan về model
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_models (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Unique Identifiers
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    key VARCHAR(100) NOT NULL UNIQUE,
    
    -- Model Information
    display_name VARCHAR(255) NOT NULL,
    task VARCHAR(50) NOT NULL CHECK (task IN ('fall_detection', 'health_monitoring', 'sleep_tracking')),
    description TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Active Version Reference
    active_version_id INTEGER, -- FK -> ai_model_versions.id (sẽ thêm constraint sau)
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes cho ai_models
CREATE INDEX IF NOT EXISTS idx_ai_models_key ON ai_models(key);
CREATE INDEX IF NOT EXISTS idx_ai_models_task ON ai_models(task);
CREATE INDEX IF NOT EXISTS idx_ai_models_deleted_at ON ai_models(deleted_at);
CREATE INDEX IF NOT EXISTS idx_ai_models_active_version_id ON ai_models(active_version_id);

-- Comments
COMMENT ON TABLE ai_models IS 'Danh mục các AI models trong hệ thống';
COMMENT ON COLUMN ai_models.id IS 'ID duy nhất của model';
COMMENT ON COLUMN ai_models.uuid IS 'UUID của model';
COMMENT ON COLUMN ai_models.key IS 'Key định danh model (unique, không thể trùng)';
COMMENT ON COLUMN ai_models.display_name IS 'Tên hiển thị cho người dùng';
COMMENT ON COLUMN ai_models.task IS 'Loại nhiệm vụ: fall_detection, health_monitoring, sleep_tracking';
COMMENT ON COLUMN ai_models.description IS 'Mô tả chi tiết về model';
COMMENT ON COLUMN ai_models.is_active IS 'Model có đang hoạt động không';
COMMENT ON COLUMN ai_models.active_version_id IS 'ID của version đang được sử dụng trong production';
COMMENT ON COLUMN ai_models.deleted_at IS 'Thời điểm xóa (soft delete)';

-- =====================================================
-- 2. BẢNG: ai_model_versions
-- Mục đích: Lưu các phiên bản của mỗi model
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_model_versions (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Unique Identifiers
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    
    -- Foreign Key
    model_id INTEGER NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
    
    -- Version Information
    version VARCHAR(50) NOT NULL, -- Format: X.Y.Z (vd: 1.0.0, 2.0.0)
    
    -- Artifact Information
    artifact_path VARCHAR(500) NOT NULL, -- Đường dẫn file trên R2/S3
    artifact_sha256 VARCHAR(64) NOT NULL, -- Checksum để verify file
    artifact_size_bytes BIGINT, -- Kích thước file (bytes)
    format VARCHAR(20) NOT NULL CHECK (format IN ('pt', 'pth', 'onnx', 'tflite', 'h5', 'keras', 'pb', 'pkl', 'joblib', 'zip')),
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'deprecated')),
    
    -- Metadata
    release_notes TEXT,
    created_by INTEGER REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Unique Constraint: Một model không thể có 2 versions trùng tên
    CONSTRAINT unique_ai_model_version UNIQUE (model_id, version)
);

-- Indexes cho ai_model_versions
CREATE INDEX IF NOT EXISTS idx_ai_model_versions_model_id ON ai_model_versions(model_id);
CREATE INDEX IF NOT EXISTS idx_ai_model_versions_status ON ai_model_versions(status);
CREATE INDEX IF NOT EXISTS idx_ai_model_versions_deleted_at ON ai_model_versions(deleted_at);
CREATE INDEX IF NOT EXISTS idx_ai_model_versions_created_at ON ai_model_versions(created_at DESC);

-- Comments
COMMENT ON TABLE ai_model_versions IS 'Các phiên bản (versions) của mỗi AI model';
COMMENT ON COLUMN ai_model_versions.id IS 'ID duy nhất của version';
COMMENT ON COLUMN ai_model_versions.uuid IS 'UUID của version';
COMMENT ON COLUMN ai_model_versions.model_id IS 'ID của model (FK -> ai_models.id)';
COMMENT ON COLUMN ai_model_versions.version IS 'Tên version theo format X.Y.Z (vd: 1.0.0, 2.0.0)';
COMMENT ON COLUMN ai_model_versions.artifact_path IS 'Đường dẫn file model trên R2/S3';
COMMENT ON COLUMN ai_model_versions.artifact_sha256 IS 'SHA256 checksum của file để verify tính toàn vẹn';
COMMENT ON COLUMN ai_model_versions.artifact_size_bytes IS 'Kích thước file (bytes)';
COMMENT ON COLUMN ai_model_versions.format IS 'Định dạng file: pt, onnx, tflite, etc.';
COMMENT ON COLUMN ai_model_versions.status IS 'Trạng thái: draft (nháp), published (đang dùng), deprecated (đã ngừng)';
COMMENT ON COLUMN ai_model_versions.release_notes IS 'Ghi chú phiên bản';
COMMENT ON COLUMN ai_model_versions.created_by IS 'User ID người tạo version';
COMMENT ON COLUMN ai_model_versions.deleted_at IS 'Thời điểm xóa (soft delete)';

-- =====================================================
-- 3. BẢNG: ai_model_mlops_states
-- Mục đích: Lưu trạng thái MLOps mở rộng (JSON)
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_model_mlops_states (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Foreign Key (One-to-One với ai_models)
    model_id INTEGER NOT NULL UNIQUE REFERENCES ai_models(id) ON DELETE CASCADE,
    
    -- JSON Payload
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes cho ai_model_mlops_states
CREATE INDEX IF NOT EXISTS idx_ai_model_mlops_states_model_id ON ai_model_mlops_states(model_id);
CREATE INDEX IF NOT EXISTS idx_ai_model_mlops_states_payload ON ai_model_mlops_states USING GIN (payload);

-- Comments
COMMENT ON TABLE ai_model_mlops_states IS 'Trạng thái MLOps mở rộng cho mỗi model (lưu dạng JSON)';
COMMENT ON COLUMN ai_model_mlops_states.id IS 'ID duy nhất';
COMMENT ON COLUMN ai_model_mlops_states.model_id IS 'ID của model (FK -> ai_models.id, one-to-one)';
COMMENT ON COLUMN ai_model_mlops_states.payload IS 'JSON payload chứa: datasets, modelVersions, retrainJobs, modelDiffs, feedbackSummary, feedbackStore';
COMMENT ON COLUMN ai_model_mlops_states.created_at IS 'Thời điểm tạo';
COMMENT ON COLUMN ai_model_mlops_states.updated_at IS 'Thời điểm cập nhật';

-- =====================================================
-- 4. THÊM FOREIGN KEY CONSTRAINT
-- =====================================================

-- Thêm FK constraint cho ai_models.active_version_id
-- (Phải thêm sau khi ai_model_versions đã tồn tại)
ALTER TABLE ai_models 
ADD CONSTRAINT fk_ai_models_active_version 
FOREIGN KEY (active_version_id) 
REFERENCES ai_model_versions(id) 
ON DELETE SET NULL;

-- =====================================================
-- 5. TRIGGER: Tự động cập nhật updated_at
-- =====================================================

-- Function để update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger cho ai_models
DROP TRIGGER IF EXISTS trigger_ai_models_updated_at ON ai_models;
CREATE TRIGGER trigger_ai_models_updated_at
    BEFORE UPDATE ON ai_models
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger cho ai_model_mlops_states
DROP TRIGGER IF EXISTS trigger_ai_model_mlops_states_updated_at ON ai_model_mlops_states;
CREATE TRIGGER trigger_ai_model_mlops_states_updated_at
    BEFORE UPDATE ON ai_model_mlops_states
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. DỮ LIỆU MẪU (Optional)
-- =====================================================

-- Tạo model mẫu
INSERT INTO ai_models (key, display_name, task, description, is_active)
VALUES 
    ('fall_detection_v1', 'Phát hiện té ngã v1', 'fall_detection', 'Model phát hiện té ngã cho người cao tuổi', true),
    ('health_monitoring_v1', 'Theo dõi sức khỏe v1', 'health_monitoring', 'Model theo dõi các chỉ số sức khỏe', true),
    ('sleep_tracking_v1', 'Theo dõi giấc ngủ v1', 'sleep_tracking', 'Model phân tích chất lượng giấc ngủ', true)
ON CONFLICT (key) DO NOTHING;

-- Lấy ID của model vừa tạo
DO $$
DECLARE
    fall_model_id INTEGER;
BEGIN
    SELECT id INTO fall_model_id FROM ai_models WHERE key = 'fall_detection_v1';
    
    IF fall_model_id IS NOT NULL THEN
        -- Tạo version 1.0.0 cho model
        INSERT INTO ai_model_versions (model_id, version, artifact_path, artifact_sha256, artifact_size_bytes, format, status)
        VALUES (
            fall_model_id,
            '1.0.0',
            'ai-models/fall_detection_v1/1.0.0/artifact.pt',
            'abc123def456...',
            10485760, -- 10MB
            'pt',
            'published'
        )
        ON CONFLICT (model_id, version) DO NOTHING;
        
        -- Cập nhật active_version_id
        UPDATE ai_models 
        SET active_version_id = (
            SELECT id FROM ai_model_versions 
            WHERE model_id = fall_model_id AND version = '1.0.0'
        )
        WHERE id = fall_model_id;
    END IF;
END $$;

-- =====================================================
-- 7. KIỂM TRA KẾT QUẢ
-- =====================================================

-- Xem tất cả models
SELECT 
    m.id,
    m.key,
    m.display_name,
    m.task,
    m.is_active,
    m.active_version_id,
    v.version AS active_version,
    m.created_at
FROM ai_models m
LEFT JOIN ai_model_versions v ON m.active_version_id = v.id
WHERE m.deleted_at IS NULL
ORDER BY m.id;

-- Xem tất cả versions
SELECT 
    v.id,
    m.key AS model_key,
    v.version,
    v.status,
    v.format,
    v.artifact_size_bytes,
    CASE 
        WHEN m.active_version_id = v.id THEN '✅ ACTIVE'
        ELSE ''
    END AS is_active,
    v.created_at
FROM ai_model_versions v
JOIN ai_models m ON v.model_id = m.id
WHERE v.deleted_at IS NULL
ORDER BY m.id, v.created_at DESC;

-- =====================================================
-- 8. SCRIPT XÓA (Nếu cần reset)
-- =====================================================

/*
-- CẢNH BÁO: Script này sẽ XÓA TẤT CẢ DỮ LIỆU!
-- Chỉ chạy khi cần reset hoàn toàn

DROP TABLE IF EXISTS ai_model_mlops_states CASCADE;
DROP TABLE IF EXISTS ai_model_versions CASCADE;
DROP TABLE IF EXISTS ai_models CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
*/
