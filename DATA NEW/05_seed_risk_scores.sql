-- ============================================================================
-- File: 05_seed_risk_scores.sql
-- Description: Bơm dữ liệu mẫu cho risk scores và risk explanations
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- Xóa dữ liệu risk cũ trước khi insert mới
DELETE FROM risk_explanations;
DELETE FROM risk_scores;

-- 1. Bơm Risk Scores cho các users
-- Cụ A (user_id = 2) - Risk CRITICAL do tuổi tác và bệnh lý
INSERT INTO risk_scores (user_id, device_id, calculated_at, risk_type, score, risk_level, features, model_version, algorithm) VALUES
(2, 1, NOW() - INTERVAL '1 hour', 'general', 92.5, 'critical', 
 '{"age": 74, "hypertension": true, "diabetes": true, "avg_heart_rate": 85, "avg_spo2": 95.2, "mobility_score": 3.2}', 
 'v2.1', 'random_forest'),

(2, 1, NOW() - INTERVAL '1 day', 'stroke', 89.0, 'critical', 
 '{"age": 74, "hypertension": true, "diabetes": true, "avg_heart_rate": 88, "avg_spo2": 96.1, "mobility_score": 3.5}', 
 'v2.1', 'random_forest'),

-- Anh B (user_id = 3) - Risk MEDIUM (khỏe mạnh)
(3, 2, NOW() - INTERVAL '2 hours', 'general', 45.0, 'medium', 
 '{"age": 44, "hypertension": false, "diabetes": false, "avg_heart_rate": 72, "avg_spo2": 98.5, "mobility_score": 8.1}', 
 'v2.1', 'random_forest'),

-- Chị C (user_id = 4) - Risk HIGH do stress và làm việc nhiều
(4, 3, NOW() - INTERVAL '3 hours', 'heartattack', 78.5, 'high', 
 '{"age": 42, "hypertension": false, "diabetes": false, "avg_heart_rate": 76, "avg_spo2": 97.8, "mobility_score": 6.2, "stress_level": "high"}', 
 'v2.1', 'random_forest'),

-- Bác sĩ D (user_id = 5) - Risk LOW (chuyên gia y tế)
(5, 5, NOW() - INTERVAL '4 hours', 'general', 25.0, 'low', 
 '{"age": 49, "hypertension": false, "diabetes": false, "avg_heart_rate": 68, "avg_spo2": 99.0, "mobility_score": 9.0, "medical_knowledge": true}', 
 'v2.1', 'random_forest');

-- Reset sequence
SELECT setval('risk_scores_id_seq', (SELECT MAX(id) FROM risk_scores));

-- 2. Bơm Risk Explanations (Giải thích AI)
-- Lấy ID thực tế từ risk_scores vừa insert
INSERT INTO risk_explanations (risk_score_id, explanation_text, feature_importance, xai_method, recommendations) VALUES
-- Cho Cụ A - lấy risk_score gần nhất của user_id = 2
((SELECT id FROM risk_scores WHERE user_id = 2 AND risk_type = 'general' ORDER BY calculated_at DESC LIMIT 1), 
 'Điểm rủi ro cao do tuổi tác (74 tuổi) kết hợp với bệnh lý nền (tăng huyết áp, tiểu đường). Chỉ số di chuyển thấp (3.2/10) cho thấy khả năng vận động hạn chế.', 
 '{"age": 0.35, "medical_conditions": 0.28, "mobility_score": 0.22, "avg_heart_rate": 0.10, "avg_spo2": 0.05}',
 'shap', 
 '{"Theo dõi huyết áp hàng ngày", "Kiểm tra đường huyết 2 lần/ngày", "Tập vật lý trị liệu nhẹ", "Đảm bảo môi trường an toàn tại nhà"}'),

-- Cho Chị C - lấy risk_score gần nhất của user_id = 4
((SELECT id FROM risk_scores WHERE user_id = 4 AND risk_type = 'heartattack' ORDER BY calculated_at DESC LIMIT 1), 
 'Điểm rủi ro cao chủ yếu do mức độ stress cao từ công việc. Mặc dù các chỉ số sinh tồn bình thường nhưng stress kéo dài có thể ảnh hưởng đến sức khỏe tim mạch.', 
 '{"stress_level": 0.45, "work_hours": 0.25, "sleep_quality": 0.15, "avg_heart_rate": 0.10, "age": 0.05}',
 'lime', 
 '{"Giảm giờ làm việc", "Thực hành thiền định 15 phút/ngày", "Tăng cường vận động", "Cải thiện chất lượng giấc ngủ"}');

-- Reset sequence
SELECT setval('risk_explanations_id_seq', (SELECT MAX(id) FROM risk_explanations));

-- 3. Thêm dữ liệu risk scores lịch sử (7 ngày qua) để có xu hướng
INSERT INTO risk_scores (user_id, device_id, calculated_at, risk_type, score, risk_level, features, model_version, algorithm) VALUES
-- Cụ A - xu hướng tăng dần
(2, 1, NOW() - INTERVAL '2 days', 'stroke', 87.0, 'critical', '{"age": 74, "avg_heart_rate": 82}', 'v2.1', 'random_forest'),
(2, 1, NOW() - INTERVAL '3 days', 'general', 85.5, 'critical', '{"age": 74, "avg_heart_rate": 80}', 'v2.1', 'random_forest'),
(2, 1, NOW() - INTERVAL '4 days', 'general', 83.0, 'high', '{"age": 74, "avg_heart_rate": 78}', 'v2.1', 'random_forest'),

-- Chị C - dao động
(4, 3, NOW() - INTERVAL '2 days', 'heartattack', 75.0, 'high', '{"age": 42, "stress_level": "medium"}', 'v2.1', 'random_forest'),
(4, 3, NOW() - INTERVAL '3 days', 'general', 72.5, 'high', '{"age": 42, "stress_level": "medium"}', 'v2.1', 'random_forest'),

-- Anh B - ổn định
(3, 2, NOW() - INTERVAL '2 days', 'general', 43.0, 'medium', '{"age": 44, "avg_heart_rate": 70}', 'v2.1', 'random_forest'),
(3, 2, NOW() - INTERVAL '3 days', 'general', 41.5, 'medium', '{"age": 44, "avg_heart_rate": 69}', 'v2.1', 'random_forest');

COMMIT;