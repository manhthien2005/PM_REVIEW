-- ============================================================================
-- File: 06_create_tables_ai_analytics.sql
-- Description: Tạo bảng cho AI/ML (risk scores, XAI explanations, risk alert responses)
-- Tables: risk_scores, risk_explanations, risk_alert_responses
-- Author: HealthGuard Development Team
-- Date: 02/02/2026
-- ============================================================================
-- Migrations incorporated (không cần chạy riêng nữa):
--   20260416_risk_alert_escalation.sql  → risk_level CHECK, risk_alert_responses table
--   20260424_shap_explanation_columns   → top/ai/shap _json cols on risk_explanations
--   20260427_model_request_id           → model_request_id col on risk_explanations
--   20260427_audience_payload_json      → audience_payload_json col on risk_explanations
--   20260427_sleep_risk_type            → 'sleep' added to risk_type CHECK
-- ============================================================================

-- ============================================================================
-- Table: risk_scores
-- Purpose: Lưu kết quả tính toán risk score từ AI model
-- Frequency: Tính định kỳ (6h hoặc 24h)
-- ============================================================================
CREATE TABLE IF NOT EXISTS risk_scores (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INT REFERENCES devices(id) ON DELETE SET NULL,
    
    -- Score
    calculated_at TIMESTAMPTZ NOT NULL,
    risk_type VARCHAR(50) NOT NULL CHECK (risk_type IN ('stroke', 'heartattack', 'afib', 'general', 'sleep')),
    score DECIMAL(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),  -- 0.00 - 100.00
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'critical')),
    
    -- Input Features (for reproducibility & explainability)
    features JSONB NOT NULL,
    /* Example:
    {
        "avg_hr_24h": 85,
        "hrv_sdnn": 30,
        "low_spo2_events": 5,
        "age": 65,
        "has_hypertension": true,
        "bmi": 28.5
    }
    */
    
    -- Model Info
    model_version VARCHAR(20),
    algorithm VARCHAR(50),  -- 'random_forest', 'neural_network', 'gradient_boosting'

    -- ADR-018 data quality contract (Phase 7 S4) — promoted from features
    -- JSONB blob to first-class columns so admin analytics, retraining
    -- pipelines and audit reports can query them without parsing JSON.
    is_synthetic_default BOOLEAN NOT NULL DEFAULT FALSE,
    defaults_applied JSONB,
    effective_confidence DECIMAL(5,4),
    data_quality_warning TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE risk_scores IS 'Bảng lưu kết quả tính toán risk score từ AI model';
COMMENT ON COLUMN risk_scores.risk_type IS 'Risk domain: general (vitals), stroke/heartattack/afib (legacy vital-derived), sleep (sleep score risk). Fall events live in fall_events table.';
COMMENT ON COLUMN risk_scores.score IS 'Điểm rủi ro (0-100)';
COMMENT ON COLUMN risk_scores.risk_level IS 'Mức độ: low | medium | critical (không dùng high nữa — backfill thành medium)';
COMMENT ON COLUMN risk_scores.features IS 'Input features dạng JSONB (để reproduce & explain)';
COMMENT ON COLUMN risk_scores.is_synthetic_default IS 'ADR-018 / Phase 7 S4: TRUE khi ít nhất một soft field (BP, HRV, weight, height) bị default trong inference; FALSE trên record vitals đầy đủ và rule-based fallback.';
COMMENT ON COLUMN risk_scores.defaults_applied IS 'ADR-018 / Phase 7 S4: ordered list các soft field name bị default (vd ["hrv","weight_kg"]); NULL khi không default. Mirror với features JSONB blob.';
COMMENT ON COLUMN risk_scores.effective_confidence IS 'ADR-018 / Phase 7 S4: confidence consumer hiển thị (= raw confidence × 0.5 khi synthetic, = raw khi sạch); NULL trên rule-based fallback. Range 0.0000-1.0000.';
COMMENT ON COLUMN risk_scores.data_quality_warning IS 'ADR-018 / Phase 7 S4: warning text từ model-api khi soft default applied; NULL trên record sạch và fallback path.';

-- ============================================================================
-- Table: risk_explanations
-- Purpose: Explainable AI (XAI) - giải thích tại sao risk score cao
-- ============================================================================
CREATE TABLE IF NOT EXISTS risk_explanations (
    id SERIAL PRIMARY KEY,
    risk_score_id INT NOT NULL REFERENCES risk_scores(id) ON DELETE CASCADE,
    
    -- Explanation (Natural Language)
    explanation_text TEXT NOT NULL,
    /* Example:
    "Nguy cơ cao do nhịp tim tăng vọt 120bpm khi đang nghỉ ngơi 
     và HRV thấp bất thường (25ms). Khuyến nghị kiểm tra y tế."
    */
    
    -- Feature Importance (for visualization)
    feature_importance JSONB,
    /* Example:
    {
        "low_hrv": 0.45,          // Most important
        "high_resting_hr": 0.30,
        "age": 0.15,
        "low_spo2": 0.10
    }
    */
    
    -- XAI Method
    xai_method VARCHAR(50) CHECK (xai_method IN ('shap', 'lime', 'rule_based', 'permutation')),
    
    -- Actionable Recommendations
    recommendations TEXT[],
    /* Example:
    ARRAY[
        'Nghỉ ngơi đầy đủ, ngủ 7-8 giờ/ngày',
        'Uống đủ nước (2 lít/ngày)',
        'Liên hệ bác sĩ nếu triệu chứng kéo dài > 48h'
    ]
    */

    -- SHAP / AI Explanation Payloads (healthguard-model-api Phase SHAP)
    top_features_json JSONB,        -- SHAP top_features: [{feature, feature_value, impact, direction, reason}]
    ai_explanation_json JSONB,      -- PredictionExplanation: {short_text, clinical_note, recommended_actions}
    shap_details_json JSONB,        -- SHAP waterfall: {base_value, prediction_value, values[]}
    model_request_id VARCHAR(36),   -- healthguard-model-api meta.request_id (để trace log end-to-end)
    audience_payload_json JSONB,    -- Phase-7 cache: pre-assembled mobile DTOs by audience profile

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE risk_explanations IS 'Bảng giải thích AI (XAI) - tại sao risk score cao';
COMMENT ON COLUMN risk_explanations.explanation_text IS 'Giải thích bằng ngôn ngữ tự nhiên (tiếng Việt)';
COMMENT ON COLUMN risk_explanations.feature_importance IS 'Ranking features theo độ ảnh hưởng (0-1)';
COMMENT ON COLUMN risk_explanations.xai_method IS 'Phương pháp XAI: SHAP, LIME, rule-based';
COMMENT ON COLUMN risk_explanations.recommendations IS 'Khuyến nghị hành động cụ thể (array)';
COMMENT ON COLUMN risk_explanations.top_features_json IS 'Structured SHAP top_features from model-api (impact, direction, reason per feature).';
COMMENT ON COLUMN risk_explanations.ai_explanation_json IS 'Structured PredictionExplanation from model-api (short_text, clinical_note, recommended_actions).';
COMMENT ON COLUMN risk_explanations.shap_details_json IS 'Optional SHAP waterfall payload for advanced visualization.';
COMMENT ON COLUMN risk_explanations.model_request_id IS 'healthguard-model-api meta.request_id for end-to-end log correlation; NULL on rule_based/ONNX/LightGBM fallback paths.';
COMMENT ON COLUMN risk_explanations.audience_payload_json IS 'Phase-7 cache: pre-assembled mobile DTOs keyed by audience. Shape: {"<audience>": {"contract_version": "x.y.z", "payload": {...}}}. NULL = cache miss, rebuild via MonitoringService.';

-- Partial indexes for traceability columns (only NOT NULL rows indexed)
CREATE INDEX IF NOT EXISTS idx_risk_explanations_model_request_id
    ON risk_explanations (model_request_id)
    WHERE model_request_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_risk_explanations_audience_payload_present
    ON risk_explanations ((audience_payload_json IS NOT NULL))
    WHERE audience_payload_json IS NOT NULL;

-- ============================================================================
-- Table: risk_alert_responses
-- Purpose: Terminal response table for risk alert acknowledgements/escalations
--          (user taps overlay: safe / help_requested; or system escalates on timeout)
-- ============================================================================
CREATE TABLE IF NOT EXISTS risk_alert_responses (
    id BIGSERIAL PRIMARY KEY,
    notification_id BIGINT NOT NULL UNIQUE REFERENCES alerts(id) ON DELETE CASCADE,
    response_action VARCHAR(32) NOT NULL,
    risk_score_id BIGINT NULL,
    source VARCHAR(32) NOT NULL,
    device_id BIGINT NULL,
    latitude DOUBLE PRECISION NULL,
    longitude DOUBLE PRECISION NULL,
    address TEXT NULL,
    responded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sos_event_id BIGINT NULL REFERENCES sos_events(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT check_risk_alert_response_action
        CHECK (response_action IN ('safe', 'help_requested', 'timeout_escalated')),
    CONSTRAINT check_risk_alert_response_source
        CHECK (source IN ('overlay', 'push_tap'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_risk_alert_responses_notification_id
    ON risk_alert_responses (notification_id);

COMMENT ON TABLE risk_alert_responses IS 'Terminal response cho risk alert overlay (safe/help_requested/timeout_escalated)';

-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Created table: risk_scores (risk_type includes sleep, risk_level: low|medium|critical)';
    RAISE NOTICE '✓ Created table: risk_explanations (+ SHAP cols: top_features, ai_explanation, shap_details, model_request_id, audience_payload)';
    RAISE NOTICE '✓ Created table: risk_alert_responses';
    RAISE NOTICE '  Incorporated: migrations 20260416_risk_alert_escalation, 20260424_shap_explanation_columns,';
    RAISE NOTICE '                20260427_model_request_id, 20260427_audience_payload_json, 20260427_sleep_risk_type';
END $$;
