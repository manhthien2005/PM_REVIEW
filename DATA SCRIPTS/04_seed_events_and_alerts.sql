-- ============================================================================
-- File: 04_seed_events_and_alerts.sql
-- Description: Bơm dữ liệu mẫu cho sự kiện khẩn cấp (Fall, SOS, Alerts) 
-- ============================================================================

BEGIN;

-- 1. Mô phỏng 1 vụ té ngã (Fall Event) từ AI của Cụ A
INSERT INTO fall_events (id, device_id, detected_at, confidence, model_version, latitude, longitude, address, user_notified_at, user_cancelled, sos_triggered) VALUES
(1, 1, NOW() - INTERVAL '1 hour', 0.95, 'v2.1', 10.762622, 106.660172, 'Quận 10, TP.HCM', NOW() - INTERVAL '59.5 minutes', false, true);

-- Reset sequence fall_events
SELECT setval('fall_events_id_seq', (SELECT MAX(id) FROM fall_events));

-- 2. Mô phỏng ca cấp cứu (SOS Event) sinh ra từ vụ ngã trên
INSERT INTO sos_events (id, fall_event_id, device_id, user_id, trigger_type, triggered_at, latitude, longitude, address, status, resolution_notes) VALUES
(1, 1, 1, 2, 'auto', NOW() - INTERVAL '59 minutes', 10.762622, 106.660172, 'Quận 10, TP.HCM', 'resolved', 'Con trai đã xác nhận đưa vào viện an toàn');

-- Reset sequence sos_events
SELECT setval('sos_events_id_seq', (SELECT MAX(id) FROM sos_events));

-- 3. Cập nhật fall_events rằng sos đã trigger
UPDATE fall_events SET sos_triggered_at = NOW() - INTERVAL '59 minutes' WHERE id = 1;

-- 4. Bơm Dữ liệu Alerts (Cảnh báo các loại)
-- 4.1. Alert té ngã SOS
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, fall_event_id, sos_event_id, data, sent_at, delivered_at) VALUES
(3, 1, 'sos_triggered', 'Khẩn cấp! Bố vừa bị ngã', 'Hệ thống tự động kích hoạt SOS do không thấy ông A phản hồi sau khi ngã.', 'critical', 1, 1, 
 '{"heart_rate": 115, "spo2": 95, "battery": 60, "address": "Quận 10, TP.HCM"}', NOW() - INTERVAL '59 minutes', NOW() - INTERVAL '58 minutes');

-- 4.2. Alert nhịp tim cao (gửi cho con dâu C)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at) VALUES
(4, 1, 'vital_abnormal', 'Nhịp tim cao bất thường', 'Nhịp tim của cụ A lên tới 135 BPM.', 'high', 
 '{"heart_rate": 135}', NOW() - INTERVAL '3 minutes', NOW() - INTERVAL '2.9 minutes');

-- 4.3. Alert thiết bị sắp hết pin (gửi cho người đeo là cụ A)
INSERT INTO alerts (user_id, device_id, alert_type, title, message, severity, data, sent_at, delivered_at) VALUES
(2, 1, 'low_battery', 'Pin đồng hồ yếu', 'Đồng hồ chỉ còn 15% pin, vui lòng sạc.', 'low', 
 '{"battery": 15}', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1.9 hours');

COMMIT;
