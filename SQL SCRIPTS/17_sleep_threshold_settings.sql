-- ============================================================================
-- File: 17_sleep_threshold_settings.sql
-- Description: Thêm cấu hình ngưỡng sinh tồn khi ngủ (AASM-compliant)
--              vào bảng system_settings.
--              Mở rộng vitals_default_thresholds và thêm vitals_sleep_thresholds.
-- Tables affected: system_settings (existing)
-- Depends on: 13_create_system_settings.sql (table + base rows must exist)
-- Author: HealthGuard Development Team
-- Date: 2026-04-01
-- ============================================================================

-- ============================================================================
-- STEP 1: Mở rộng vitals_default_thresholds (ban ngày)
-- Cập nhật từ JSONB rút gọn → đầy đủ tất cả các field cần thiết
-- Source: AHA 2023 (HR), WHO (SpO2), ERS/ATS (RR), ACC/AHA (BP)
-- ============================================================================
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable)
VALUES (
    'vitals_default_thresholds',
    'clinical',
    '{
        "hr_critical_min": 50,
        "hr_critical_max": 120,
        "hr_warning_min": 55,
        "hr_warning_max": 110,
        "spo2_critical": 90,
        "spo2_warning": 94,
        "rr_critical_min": 10,
        "rr_critical_max": 25,
        "bp_sys_critical": 180,
        "bp_dia_critical": 120,
        "bp_sys_warning": 140,
        "bp_dia_warning": 90
    }',
    'Ngưỡng cảnh báo sinh tồn mặc định ban ngày (Global Default). Áp dụng khi activity_state != sleeping. Nguồn: AHA 2023 / WHO / ERS-ATS / ACC-AHA.',
    true
)
ON CONFLICT (setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    description   = EXCLUDED.description,
    updated_at    = NOW();


-- ============================================================================
-- STEP 2: Thêm vitals_sleep_thresholds (ngưỡng khi ngủ, AASM-compliant)
-- Chỉ áp dụng khi activity_state = "sleeping"
-- Source: AASM 2020 Sleep Staging Manual, ICSD-3, Ohayon et al. 2004 meta-analysis
-- ============================================================================
INSERT INTO system_settings (setting_key, setting_group, setting_value, description, is_editable)
VALUES (
    'vitals_sleep_thresholds',
    'clinical',
    '{
        "hr_critical_min": 38,
        "hr_critical_max": 100,
        "hr_warning_min": 42,
        "hr_warning_max": 90,
        "spo2_critical": 85,
        "spo2_warning": 90,
        "rr_critical_min": 6,
        "rr_critical_max": 25,
        "bp_sys_critical": 180,
        "bp_dia_critical": 120,
        "bp_sys_warning": 160,
        "bp_dia_warning": 100,
        "osa_alert_spo2_threshold": 88,
        "nocturnal_tachy_hr": 120,
        "apnea_rr_threshold": 6
    }',
    'Ngưỡng sinh tồn khi ngủ (AASM 2020). HR 40-55 bpm khi deep sleep là bình thường. Chỉ alert khi vượt ngưỡng bệnh lý thực sự. Ngưỡng OSA: SpO2 < 88%; Nocturnal Tachycardia: HR > 120; Ngưng thở: RR < 6.',
    true
)
ON CONFLICT (setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    description   = EXCLUDED.description,
    updated_at    = NOW();


-- ============================================================================
-- SLEEP THRESHOLD REFERENCE (Comment documentation)
-- ============================================================================
--
-- vitals_sleep_thresholds — Giải thích lâm sàng:
--
-- HR thresholds:
--   hr_critical_min = 38   → Arrest-level bradycardia (AASM: deep sleep HR 40-55 bình thường)
--   hr_critical_max = 100  → Nocturnal tachycardia (sustained >100 bpm khi ngủ = bất thường)
--   hr_warning_min  = 42   → Cảnh báo sớm bradycardia sâu
--   hr_warning_max  = 90   → Cảnh báo sớm tachycardia
--
-- SpO2 thresholds:
--   spo2_critical = 85     → Severe OSA / respiratory depression (AASM: AHI severe)
--   spo2_warning  = 90     → Moderate OSA indicator (SpO2 88-94% = clinician review needed)
--   osa_alert_spo2_threshold = 88  → Mốc trigger alert "sleep_apnea_suspected"
--
-- Respiratory Rate:
--   rr_critical_min = 6    → Apnea / respiratory arrest (ICSD-3: apnea = RR ≈ 0, RR<6 = pre-apnea)
--   rr_critical_max = 25   → Giữ nguyên như ban ngày (tachypnea khi ngủ = bất thường)
--   apnea_rr_threshold = 6 → Trigger alert "respiratory_arrest_risk"
--
-- Blood Pressure:
--   bp_sys_critical = 180  → Hypertensive crisis (unchanged — nguy hiểm bất kể ngủ hay thức)
--   bp_sys_warning  = 160  → Slightly relaxed vs daytime (160 vs 140)
--
-- Applied contexts:
--   Backend SettingsService → IoT Simulator alert evaluation (sleep_context = true)
--   Admin Site → có thể chỉnh sửa thông qua Admin Dashboard hiện có
-- ============================================================================


-- Print confirmation
DO $$
BEGIN
    RAISE NOTICE '✓ Updated: vitals_default_thresholds → full daytime threshold fields';
    RAISE NOTICE '✓ Inserted: vitals_sleep_thresholds → AASM 2020 sleep physiology thresholds';
    RAISE NOTICE '  OSA alert threshold: SpO2 < 88%%';
    RAISE NOTICE '  Nocturnal tachycardia: HR > 120 bpm';
    RAISE NOTICE '  Respiratory arrest: RR < 6 lpm';
END $$;
