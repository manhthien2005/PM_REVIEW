-- ============================================================================
-- File: 03_seed_timeseries_vitals.sql
-- Description: Bơm dữ liệu mẫu cho Timeseries Data (vitals)
-- ============================================================================

BEGIN;

-- Bơm dữ liệu sinh tồn mẫu cho Thiết bị 1 của Cụ A trong vòng 1 tuần qua
-- Lưu ý: Thực tế dữ liệu sẽ rất lớn, đây chỉ là lượng dữ liệu mô phỏng để test biểu đồ

-- Cách tạo: sinh data ngẫu nhiên
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '1 minute') AS time,
    1 AS device_id,
    -- Giả lập nhịp tim từ 65 đến 85
    floor(random() * (85 - 65 + 1) + 65)::int AS heart_rate,
    -- Giả lập SpO2 từ 96 đến 99
    (random() * (99 - 96) + 96)::decimal(4,2) AS spo2,
    -- Giả lập nhiệt độ từ 36.5 đến 37.0
    (random() * (37.0 - 36.5) + 36.5)::decimal(4,2) AS temperature,
    -- Giả lập huyết áp tâm thu 110-130
    floor(random() * (130 - 110 + 1) + 110)::int AS blood_pressure_sys,
    -- Giả lập huyết áp tâm trương 70-85
    floor(random() * (85 - 70 + 1) + 70)::int AS blood_pressure_dia,
    -- HRV
    floor(random() * (60 - 40 + 1) + 40)::int AS hrv,
    -- Nhịp thở
    floor(random() * (20 - 14 + 1) + 14)::int AS respiratory_rate,
    -- Chất lượng tín hiệu
    floor(random() * (100 - 80 + 1) + 80)::int AS signal_quality,
    false AS motion_artifact
FROM generate_series(1, 1440) AS s(i); -- Tạo 1440 records tương đương 24 giờ (1 record/phút)

-- Thêm một đoạn dữ liệu bất thường (Nhịp tim cao, SpO2 thấp) để test Alert
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(NOW() - INTERVAL '5 minutes', 1, 125, 93.5, 36.8, 145, 90, 30, 24, 95, true),
(NOW() - INTERVAL '4 minutes', 1, 130, 92.0, 36.8, 150, 95, 25, 26, 95, true),
(NOW() - INTERVAL '3 minutes', 1, 135, 91.0, 36.9, 155, 98, 20, 28, 90, true);

-- Force refresh the continuous aggregates để dashboard có thể query ngay lập tức
CALL refresh_continuous_aggregate('vitals_5min', NOW() - INTERVAL '2 days', NOW());
CALL refresh_continuous_aggregate('vitals_hourly', NOW() - INTERVAL '2 days', NOW());
CALL refresh_continuous_aggregate('vitals_daily', NOW() - INTERVAL '2 days', NOW());

COMMIT;
