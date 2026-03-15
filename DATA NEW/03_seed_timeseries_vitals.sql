-- ============================================================================
-- File: 03_seed_timeseries_vitals.sql
-- Description: Bơm dữ liệu mẫu cho Timeseries Data (vitals)
-- ============================================================================

-- Rollback any existing transaction first
ROLLBACK;

BEGIN;

-- Xóa dữ liệu vitals cũ trước khi insert mới
DELETE FROM vitals WHERE device_id IN (1, 2, 3);

-- Bơm dữ liệu sinh tồn mẫu cho các thiết bị trong vòng 7 ngày qua
-- Device 1: Cụ A (user_id = 2)
-- Device 2: Anh B (user_id = 3) 
-- Device 3: Chị C (user_id = 4)

-- 1. Dữ liệu vitals cho Cụ A (device_id = 1) - 7 ngày qua
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '5 minutes') AS time,
    1 AS device_id,
    -- Nhịp tim cụ A: 70-90 (cao hơn do tuổi tác)
    floor(random() * (90 - 70 + 1) + 70)::int AS heart_rate,
    -- SpO2: 95-98 (thấp hơn do tuổi tác)
    (random() * (98 - 95) + 95)::decimal(4,2) AS spo2,
    -- Nhiệt độ: 36.3-37.1
    (random() * (37.1 - 36.3) + 36.3)::decimal(4,2) AS temperature,
    -- Huyết áp cao do tuổi tác: 130-150
    floor(random() * (150 - 130 + 1) + 130)::int AS blood_pressure_sys,
    floor(random() * (95 - 80 + 1) + 80)::int AS blood_pressure_dia,
    floor(random() * (50 - 30 + 1) + 30)::int AS hrv,
    floor(random() * (22 - 16 + 1) + 16)::int AS respiratory_rate,
    floor(random() * (100 - 85 + 1) + 85)::int AS signal_quality,
    (random() < 0.1) AS motion_artifact
FROM generate_series(1, 2016) AS s(i); -- 7 ngày * 24h * 12 records/hour = 2016 records

-- 2. Dữ liệu vitals cho Anh B (device_id = 2) - 3 ngày qua
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '10 minutes') AS time,
    2 AS device_id,
    -- Nhịp tim anh B: 60-80 (khỏe mạnh)
    floor(random() * (80 - 60 + 1) + 60)::int AS heart_rate,
    -- SpO2: 97-99
    (random() * (99 - 97) + 97)::decimal(4,2) AS spo2,
    -- Nhiệt độ: 36.5-37.0
    (random() * (37.0 - 36.5) + 36.5)::decimal(4,2) AS temperature,
    -- Huyết áp bình thường: 110-130
    floor(random() * (130 - 110 + 1) + 110)::int AS blood_pressure_sys,
    floor(random() * (85 - 70 + 1) + 70)::int AS blood_pressure_dia,
    floor(random() * (60 - 40 + 1) + 40)::int AS hrv,
    floor(random() * (20 - 14 + 1) + 14)::int AS respiratory_rate,
    floor(random() * (100 - 90 + 1) + 90)::int AS signal_quality,
    (random() < 0.05) AS motion_artifact
FROM generate_series(1, 432) AS s(i); -- 3 ngày * 24h * 6 records/hour = 432 records

-- 3. Dữ liệu vitals cho Chị C (device_id = 3) - 2 ngày qua
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '15 minutes') AS time,
    3 AS device_id,
    -- Nhịp tim chị C: 65-85
    floor(random() * (85 - 65 + 1) + 65)::int AS heart_rate,
    -- SpO2: 96-99
    (random() * (99 - 96) + 96)::decimal(4,2) AS spo2,
    -- Nhiệt độ: 36.4-37.0
    (random() * (37.0 - 36.4) + 36.4)::decimal(4,2) AS temperature,
    -- Huyết áp: 105-125
    floor(random() * (125 - 105 + 1) + 105)::int AS blood_pressure_sys,
    floor(random() * (80 - 65 + 1) + 65)::int AS blood_pressure_dia,
    floor(random() * (55 - 35 + 1) + 35)::int AS hrv,
    floor(random() * (18 - 12 + 1) + 12)::int AS respiratory_rate,
    floor(random() * (100 - 88 + 1) + 88)::int AS signal_quality,
    (random() < 0.03) AS motion_artifact
FROM generate_series(1, 192) AS s(i); -- 2 ngày * 24h * 4 records/hour = 192 records

-- 4. Thêm dữ liệu bất thường gần đây để tạo alerts
-- Cụ A có nhịp tim cao và SpO2 thấp
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(NOW() - INTERVAL '10 minutes', 1, 125, 93.5, 36.8, 165, 95, 25, 24, 95, true),
(NOW() - INTERVAL '8 minutes', 1, 130, 92.0, 36.9, 170, 98, 22, 26, 90, true),
(NOW() - INTERVAL '5 minutes', 1, 135, 91.0, 37.0, 175, 100, 20, 28, 85, true),
(NOW() - INTERVAL '2 minutes', 1, 140, 90.5, 37.1, 180, 105, 18, 30, 80, true)
ON CONFLICT (device_id, time) DO NOTHING;

-- 5. Thêm dữ liệu vitals gần đây cho Anh B (device_id = 2) để hiển thị đầy đủ
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(NOW() - INTERVAL '1 minute', 2, 72, 98.36, 36.7, 120, 75, 45, 16, 95, false),
(NOW() - INTERVAL '5 minutes', 2, 75, 98.27, 36.6, 118, 73, 47, 15, 96, false),
(NOW() - INTERVAL '10 minutes', 2, 68, 97.87, 36.8, 122, 76, 44, 17, 94, false),
(NOW() - INTERVAL '15 minutes', 2, 71, 97.75, 36.5, 115, 72, 46, 16, 97, false),
(NOW() - INTERVAL '20 minutes', 2, 73, 97.43, 36.9, 125, 78, 43, 18, 93, false)
ON CONFLICT (device_id, time) DO NOTHING;

-- 6. Thêm dữ liệu vitals gần đây cho Chị C (device_id = 3) để hiển thị đầy đủ  
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(NOW() - INTERVAL '3 minutes', 3, 78, 97.2, 36.4, 110, 68, 38, 14, 92, false),
(NOW() - INTERVAL '8 minutes', 3, 82, 96.8, 36.6, 108, 65, 40, 13, 94, false),
(NOW() - INTERVAL '12 minutes', 3, 76, 97.5, 36.3, 112, 70, 37, 15, 91, false)
ON CONFLICT (device_id, time) DO NOTHING;

-- 7. Thêm dữ liệu vitals cho Bác sĩ D (device_id = 5) - chỉ số tốt
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
VALUES
(NOW() - INTERVAL '1 minute', 5, 65, 99.1, 36.5, 115, 70, 55, 14, 98, false),
(NOW() - INTERVAL '6 minutes', 5, 68, 98.9, 36.4, 118, 72, 52, 15, 97, false),
(NOW() - INTERVAL '11 minutes', 5, 62, 99.2, 36.6, 112, 68, 58, 13, 99, false),
(NOW() - INTERVAL '16 minutes', 5, 66, 98.8, 36.3, 120, 75, 54, 16, 96, false)
ON CONFLICT (device_id, time) DO NOTHING;

-- 8. Thêm thêm dữ liệu lịch sử cho tất cả devices (để có đủ dữ liệu 24h)
-- Cụ A - thêm dữ liệu bình thường trước khi bất thường
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '30 minutes') AS time,
    1 AS device_id,
    floor(random() * (85 - 75 + 1) + 75)::int AS heart_rate,
    (random() * (97 - 94) + 94)::decimal(4,2) AS spo2,
    (random() * (37.0 - 36.5) + 36.5)::decimal(4,2) AS temperature,
    floor(random() * (145 - 135 + 1) + 135)::int AS blood_pressure_sys,
    floor(random() * (90 - 80 + 1) + 80)::int AS blood_pressure_dia,
    floor(random() * (45 - 35 + 1) + 35)::int AS hrv,
    floor(random() * (20 - 16 + 1) + 16)::int AS respiratory_rate,
    floor(random() * (95 - 85 + 1) + 85)::int AS signal_quality,
    (random() < 0.05) AS motion_artifact
FROM generate_series(1, 48) AS s(i)
ON CONFLICT (device_id, time) DO NOTHING;

-- Anh B - thêm dữ liệu 24h
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '30 minutes') AS time,
    2 AS device_id,
    floor(random() * (78 - 68 + 1) + 68)::int AS heart_rate,
    (random() * (99 - 97) + 97)::decimal(4,2) AS spo2,
    (random() * (36.8 - 36.4) + 36.4)::decimal(4,2) AS temperature,
    floor(random() * (125 - 115 + 1) + 115)::int AS blood_pressure_sys,
    floor(random() * (78 - 70 + 1) + 70)::int AS blood_pressure_dia,
    floor(random() * (50 - 40 + 1) + 40)::int AS hrv,
    floor(random() * (18 - 14 + 1) + 14)::int AS respiratory_rate,
    floor(random() * (98 - 92 + 1) + 92)::int AS signal_quality,
    (random() < 0.02) AS motion_artifact
FROM generate_series(1, 48) AS s(i)
ON CONFLICT (device_id, time) DO NOTHING;

-- Chị C - thêm dữ liệu 24h
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '30 minutes') AS time,
    3 AS device_id,
    floor(random() * (82 - 72 + 1) + 72)::int AS heart_rate,
    (random() * (98 - 96) + 96)::decimal(4,2) AS spo2,
    (random() * (36.7 - 36.2) + 36.2)::decimal(4,2) AS temperature,
    floor(random() * (115 - 105 + 1) + 105)::int AS blood_pressure_sys,
    floor(random() * (72 - 62 + 1) + 62)::int AS blood_pressure_dia,
    floor(random() * (42 - 32 + 1) + 32)::int AS hrv,
    floor(random() * (16 - 12 + 1) + 12)::int AS respiratory_rate,
    floor(random() * (95 - 88 + 1) + 88)::int AS signal_quality,
    (random() < 0.03) AS motion_artifact
FROM generate_series(1, 48) AS s(i)
ON CONFLICT (device_id, time) DO NOTHING;

-- Bác sĩ D - thêm dữ liệu 24h (chỉ số tốt)
INSERT INTO vitals (time, device_id, heart_rate, spo2, temperature, blood_pressure_sys, blood_pressure_dia, hrv, respiratory_rate, signal_quality, motion_artifact)
SELECT
    NOW() - (i * INTERVAL '30 minutes') AS time,
    5 AS device_id,
    floor(random() * (70 - 60 + 1) + 60)::int AS heart_rate,
    (random() * (99.5 - 98.5) + 98.5)::decimal(4,2) AS spo2,
    (random() * (36.7 - 36.3) + 36.3)::decimal(4,2) AS temperature,
    floor(random() * (120 - 110 + 1) + 110)::int AS blood_pressure_sys,
    floor(random() * (75 - 65 + 1) + 65)::int AS blood_pressure_dia,
    floor(random() * (60 - 50 + 1) + 50)::int AS hrv,
    floor(random() * (16 - 12 + 1) + 12)::int AS respiratory_rate,
    floor(random() * (99 - 95 + 1) + 95)::int AS signal_quality,
    false AS motion_artifact
FROM generate_series(1, 48) AS s(i)
ON CONFLICT (device_id, time) DO NOTHING;

COMMIT;
