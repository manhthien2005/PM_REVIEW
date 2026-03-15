-- ============================================================================
-- File: 04_seed_events_and_alerts.sql
-- Description: Bơm dữ liệu mẫu cho sự kiện khẩn cấp (Fall, SOS, Alerts) 
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- 1. Mô phỏng sự kiện té ngã của Cụ A
INSERT INTO fall_events (id, device_id, detected_at, confidence, model_version, latitude, longitude, address, user_notified_at, user_cancelled, sos_triggered, sos_triggered_at) VALUES
-- Sự kiện ngã đã xử lý
(1, 1, NOW() - INTERVAL '2 hours', 0.95, 'v2.1', 10.762622, 106.660172, 'Quận 10, TP.HCM', NOW() - INTERVAL '119 minutes', false, true, NOW() - INTERVAL '118 minutes'),
(2, 1, NOW() - INTERVAL '1 day', 0.87, 'v2.1', 10.762622, 106.660172, 'Quận 10, TP.HCM', NOW() - INTERVAL '1 day' + INTERVAL '30 seconds', true, false, null),

-- Sự kiện ngã ĐANG CHỜ XỬ LÝ (mới phát hiện)
(3, 1, NOW() - INTERVAL '5 minutes', 0.92, 'v2.1', 10.762622, 106.660172, 'Quận 10, TP.HCM', NOW() - INTERVAL '4 minutes', false, false, null),
(4, 2, NOW() - INTERVAL '15 minutes', 0.88, 'v2.1', 10.775622, 106.665172, 'Quận 1, TP.HCM', NOW() - INTERVAL '14 minutes', false, false, null),
(5, 3, NOW() - INTERVAL '30 minutes', 0.91, 'v2.1', 10.780622, 106.670172, 'Quận 3, TP.HCM', NOW() - INTERVAL '29 minutes', false, false, null);

-- Reset sequence fall_events
SELECT setval('fall_events_id_seq', (SELECT MAX(id) FROM fall_events));

-- 2. Mô phỏng sự kiện SOS
INSERT INTO sos_events (id, fall_event_id, device_id, user_id, trigger_type, triggered_at, latitude, longitude, address, status, resolved_at, resolution_notes) VALUES
-- SOS đã xử lý
(1, 1, 1, 2, 'auto', NOW() - INTERVAL '118 minutes', 10.762622, 106.660172, 'Quận 10, TP.HCM', 'resolved', NOW() - INTERVAL '90 minutes', 'Con trai đã xác nhận đưa vào viện an toàn'),
(2, null, 2, 3, 'manual', NOW() - INTERVAL '6 hours', 10.762622, 106.660172, 'Quận 1, TP.HCM', 'resolved', NOW() - INTERVAL '5.5 hours', 'Nhấn nhầm nút SOS'),

-- SOS ĐANG HOẠT ĐỘNG (chưa xử lý)
(3, 3, 1, 2, 'auto', NOW() - INTERVAL '4 minutes', 10.762622, 106.660172, 'Quận 10, TP.HCM', 'active', null, null),
(4, null, 3, 4, 'manual', NOW() - INTERVAL '10 minutes', 10.780622, 106.670172, 'Quận 3, TP.HCM', 'active', null, null),
(5, null, 2, 3, 'manual', NOW() - INTERVAL '25 minutes', 10.775622, 106.665172, 'Quận 1, TP.HCM', 'responded', null, null);

-- Reset sequence sos_events
SELECT setval('sos_events_id_seq', (SELECT MAX(id) FROM sos_events));

-- 3. Bơm dữ liệu Alerts đa dạng
-- 3.1. Alert SOS khẩn cấp (gửi cho con trai - user_id = 3)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, fall_event_id, sos_event_id, data, sent_at, delivered_at, read_at) VALUES
-- SOS đã xử lý
(3, 1, 'sos_triggered', 'Khẩn cấp! Bố vừa bị ngã', 'Hệ thống tự động kích hoạt SOS do không thấy ông A phản hồi sau khi ngã.', 'critical', 1, 1, 
 '{"heart_rate": 115, "spo2": 95, "battery": 60, "address": "Quận 10, TP.HCM"}', NOW() - INTERVAL '118 minutes', NOW() - INTERVAL '117 minutes', NOW() - INTERVAL '115 minutes'),

-- SOS ĐANG HOẠT ĐỘNG (chưa đọc)
(3, 1, 'sos_triggered', 'KHẨN CẤP! Bố bị ngã lần nữa!', 'Phát hiện té ngã với độ tin cậy 92%. SOS tự động được kích hoạt.', 'critical', 3, 3, 
 '{"heart_rate": 125, "spo2": 93, "battery": 45, "address": "Quận 10, TP.HCM", "confidence": 0.92}', NOW() - INTERVAL '4 minutes', NOW() - INTERVAL '3.5 minutes', null),

(4, 3, 'sos_triggered', 'SOS khẩn cấp từ mẹ', 'Chị C đã nhấn nút SOS khẩn cấp. Cần hỗ trợ ngay lập tức.', 'critical', null, 4, 
 '{"heart_rate": 95, "spo2": 97, "battery": 65, "address": "Quận 3, TP.HCM", "trigger": "manual"}', NOW() - INTERVAL '10 minutes', NOW() - INTERVAL '9.5 minutes', null),

(4, 2, 'sos_triggered', 'SOS từ anh B', 'Anh B đã kích hoạt SOS. Đang xử lý.', 'critical', null, 5, 
 '{"heart_rate": 88, "spo2": 98, "battery": 78, "address": "Quận 1, TP.HCM", "trigger": "manual"}', NOW() - INTERVAL '25 minutes', NOW() - INTERVAL '24.5 minutes', null);

-- 3.2. Alerts cho Fall Events (té ngã chờ xử lý)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, fall_event_id, data, sent_at, delivered_at) VALUES
-- Fall event của Cụ A (đã có SOS)
(3, 1, 'fall_detected', 'Phát hiện té ngã - Cụ A', 'AI phát hiện té ngã với độ tin cậy 92%. Đã thông báo người thân.', 'high', 3, 
 '{"confidence": 0.92, "location": "Quận 10, TP.HCM", "heart_rate": 125}', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '4.5 minutes'),

-- Fall event của Anh B (chờ xử lý)
(4, 2, 'fall_detected', 'Phát hiện té ngã - Anh B', 'AI phát hiện té ngã với độ tin cậy 88%. Cần kiểm tra tình trạng.', 'high', 4, 
 '{"confidence": 0.88, "location": "Quận 1, TP.HCM", "heart_rate": 95}', NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '14.5 minutes'),

-- Fall event của Chị C (chờ xử lý)
(2, 3, 'fall_detected', 'Phát hiện té ngã - Chị C', 'AI phát hiện té ngã với độ tin cậy 91%. Vui lòng kiểm tra an toàn.', 'high', 5, 
 '{"confidence": 0.91, "location": "Quận 3, TP.HCM", "heart_rate": 88}', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '29.5 minutes');

-- 3.3. Alert nhịp tim cao (gửi cho con dâu - user_id = 4)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at) VALUES
(4, 1, 'vital_abnormal', 'Nhịp tim cao bất thường', 'Nhịp tim của cụ A lên tới 140 BPM trong 10 phút qua.', 'high', 
 '{"heart_rate": 140, "duration_minutes": 10}', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '4 minutes');

-- 3.4. Alert SpO2 thấp (gửi cho bác sĩ - user_id = 5)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at) VALUES
(5, 1, 'vital_abnormal', 'SpO2 thấp nguy hiểm', 'SpO2 của bệnh nhân Nguyễn Văn A xuống 90.5%, cần kiểm tra ngay.', 'critical', 
 '{"spo2": 90.5, "threshold": 95}', NOW() - INTERVAL '3 minutes', NOW() - INTERVAL '2 minutes');

-- 3.5. Alert pin yếu (gửi cho chính cụ A - user_id = 2)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at, read_at) VALUES
(2, 1, 'low_battery', 'Pin đồng hồ yếu', 'Đồng hồ chỉ còn 15% pin, vui lòng sạc.', 'low', 
 '{"battery": 15}', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2.9 hours', NOW() - INTERVAL '2.5 hours');

-- 3.6. Alert huyết áp cao (gửi cho con trai - user_id = 3)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at) VALUES
(3, 1, 'vital_abnormal', 'Huyết áp cao', 'Huyết áp của bố đạt 180/105 mmHg, vượt ngưỡng an toàn.', 'high', 
 '{"blood_pressure_sys": 180, "blood_pressure_dia": 105, "threshold_sys": 140}', NOW() - INTERVAL '8 minutes', NOW() - INTERVAL '7 minutes');

-- 3.7. Alerts hôm qua để có dữ liệu biểu đồ
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at, read_at) VALUES
(3, 1, 'vital_abnormal', 'Nhịp tim bất thường', 'Nhịp tim không đều trong 5 phút.', 'medium', 
 '{"heart_rate_variance": "high"}', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '1 minute', NOW() - INTERVAL '1 day' + INTERVAL '10 minutes'),

(4, 2, 'device_offline', 'Thiết bị mất kết nối', 'Đồng hồ của anh B mất kết nối hơn 30 phút.', 'medium', 
 '{"offline_duration": 35}', NOW() - INTERVAL '1 day' + INTERVAL '2 hours', NOW() - INTERVAL '1 day' + INTERVAL '2 hours' + INTERVAL '1 minute', null),

(4, 3, 'vital_abnormal', 'Nhiệt độ cao', 'Nhiệt độ cơ thể chị C đạt 37.8°C.', 'medium', 
 '{"temperature": 37.8, "threshold": 37.5}', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '30 seconds', NOW() - INTERVAL '2 days' + INTERVAL '5 minutes');

-- 3.8. Alerts tuần trước để có dữ liệu 7 ngày
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at, read_at) VALUES
(3, 1, 'vital_abnormal', 'Nhịp tim chậm', 'Nhịp tim xuống dưới 50 BPM.', 'medium', 
 '{"heart_rate": 48}', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '1 minute', NOW() - INTERVAL '3 days' + INTERVAL '15 minutes'),

(4, 1, 'vital_abnormal', 'SpO2 thấp', 'SpO2 xuống 94%.', 'high', 
 '{"spo2": 94, "threshold": 95}', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '30 seconds', null),

(2, 1, 'low_battery', 'Pin yếu', 'Pin còn 10%.', 'low', 
 '{"battery": 10}', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '1 minute', NOW() - INTERVAL '5 days' + INTERVAL '2 hours'),

(5, 1, 'vital_abnormal', 'Huyết áp cao', 'Huyết áp 160/95 mmHg.', 'high', 
 '{"blood_pressure_sys": 160, "blood_pressure_dia": 95}', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '1 minute', NOW() - INTERVAL '6 days' + INTERVAL '30 minutes');

COMMIT;
