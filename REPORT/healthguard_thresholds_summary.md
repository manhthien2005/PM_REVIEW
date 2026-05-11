# Tổng hợp Ngưỡng Y tế Hệ thống HealthGuard

> Tài liệu thu thập ngưỡng từ source code thực tế phục vụ báo cáo.  
> Ngày thu thập: 01/05/2026  
> Nguồn: `rules_config.json`, `fall_pipeline_wrist_config.json`, `app/config.py`, SQL Scripts 13 & 17.

---

## A. Pre-Model Trigger — Ngưỡng Sinh hiệu (Vital Signs)

> Nguồn: `Iot_Simulator_clean/pre_model_trigger/health_rules/rules_config.json`  
> Mục đích: Lớp phân loại tức thời trước khi gọi AI model, routing dữ liệu xuống downstream.

### A1. Instant Rules (Ngưỡng tức thời)

| Thông số | **URGENT** (Cảnh báo khẩn) | **SEND_TO_MODEL** (Gửi AI) | **WATCH** (Theo dõi) |
|---|---|---|---|
| **Heart Rate (bpm)** | ≤ 40 hoặc ≥ 131 | 41–50 hoặc 111–130 | 91–110 |
| **Resp Rate (lần/phút)** | ≤ 8 hoặc ≥ 25 | 21–24 | 19–20 |
| **Nhiệt độ (°C)** | ≤ 35.0 hoặc ≥ 39.1 | 35.1–36.0 hoặc 38.0–39.0 | 37.5–38.0 |
| **SpO2 (%)** | < 90 | ≤ 94 | = 95 |
| **SBP — Huyết áp tâm thu (mmHg)** | ≤ 90 hoặc ≥ 180 | 91–100 hoặc ≥ 140 | 121–139 |
| **DBP — Huyết áp tâm trương (mmHg)** | ≥ 120 | ≥ 90 | 80–89 |
| **MAP — Huyết áp trung bình (mmHg)** | < 65 | 65–74 | 75–84 |
| **Pulse Pressure (mmHg)** | — | — | < 30 hoặc > 60 |

**Mức độ ưu tiên:** URGENT > SEND_TO_MODEL > WATCH > NORMAL  
**Nguyên tắc:** Luật tức thời URGENT không thể bị ghi đè bởi bất kỳ điều chỉnh profile hay time-series nào.

### A2. Time-Series Rules (Ngưỡng xu hướng thời gian)

| Điều kiện | Mức | Reason Code |
|---|---|---|
| HR ≥ baseline + 10 bpm trong ≥ 5 phút | WATCH | `HR_BASELINE_DELTA_WATCH` |
| HR ≥ baseline + 15 bpm trong ≥ 10 phút | SEND_TO_MODEL | `HR_BASELINE_DELTA_SEND` |
| HR > 100 bpm lúc nghỉ ≥ 10 phút | SEND_TO_MODEL | `HR_PERSISTENT_HIGH_AT_REST` |
| HR tăng ≥ 20 bpm trong 5 phút (không do vận động) | SEND_TO_MODEL | `HR_RAPID_RISE` |
| SpO2 ≤ baseline − 2% trong ≥ 2 lần đọc | WATCH | `SPO2_BASELINE_DROP_WATCH` |
| SpO2 ≤ baseline − 3% trong 2 lần liên tiếp | SEND_TO_MODEL | `SPO2_BASELINE_DROP_SEND` |
| SpO2 giảm ≥ 3 điểm trong 10 phút | SEND_TO_MODEL | `SPO2_RAPID_DROP` |
| Nhiệt độ ≥ baseline + 1.0°C trong 24h | SEND_TO_MODEL | `TEMP_BASELINE_DELTA_SEND` |
| SBP giảm ≥ 20 mmHg trong 15 phút | SEND_TO_MODEL | `SBP_RAPID_DROP` |
| DBP giảm ≥ 10 mmHg trong 15 phút | SEND_TO_MODEL | `DBP_RAPID_DROP` |
| MAP ≤ baseline − 15 trong ≥ 2 lần liên tiếp | SEND_TO_MODEL | `MAP_BASELINE_DROP_SEND` |
| HRV ≤ baseline × 0.8 trong ≥ 2 windows | SEND_TO_MODEL | `HRV_BASELINE_DROP_SEND` |
| Cùng một bất thường xảy ra ≥ 3 lần trong 24h | SEND_TO_MODEL | `ABNORMALITY_RECURRENT_24H` |

### A3. Combination Rules (Kết hợp nhiều chỉ số)

| Điều kiện kết hợp | Mức | Reason Code |
|---|---|---|
| HR > 100 + RR ≥ 20 | SEND_TO_MODEL | `HR_RR_HIGH_COMBINATION` |
| SpO2 ≤ 94 + RR ≥ 20 | SEND_TO_MODEL | `SPO2_RR_COMBINATION` |
| Nhiệt độ ≥ 38.0°C + HR > 100 | SEND_TO_MODEL | `TEMP_HR_COMBINATION` |
| SBP ≤ 100 + HR > 100 | SEND_TO_MODEL | `SBP_HR_COMBINATION` |
| SpO2 giảm ≥ 3% + HR ≥ baseline + 10 | SEND_TO_MODEL | `SPO2_HR_COMBINATION` |
| HRV giảm ≥ 20% + HR ≥ baseline + 10 | SEND_TO_MODEL | `HRV_HR_COMBINATION` |

### A4. Profile Adjustment (Điều chỉnh theo hồ sơ bệnh nhân)

Kích hoạt khi: tuổi ≥ 65, BMI < 18.5, BMI ≥ 25 (global) hoặc BMI ≥ 23 (Asian mode).

- Nâng ngưỡng WATCH → SEND_TO_MODEL khi: HR > 90 kéo dài ≥ 10 phút lúc nghỉ
- Nâng ngưỡng khi: DBP 80–89 mmHg trong ≥ 2 lần đọc liên tiếp
- Nâng ngưỡng khi: SBP 130–139 mmHg trong ≥ 2 lần đọc liên tiếp

---

## B. Global Default Thresholds (Ngưỡng mặc định hệ thống)

> Nguồn: `PM_REVIEW/SQL SCRIPTS/17_sleep_threshold_settings.sql`  
> Tham chiếu lâm sàng: AHA 2023 (HR) · WHO (SpO2) · ERS/ATS (RR) · ACC/AHA 2023 (BP)

### B1. Ban ngày — `vitals_default_thresholds`

| Thông số | Critical | Warning |
|---|---|---|
| Heart Rate | < 50 hoặc > 120 bpm | < 55 hoặc > 110 bpm |
| SpO2 | < 90% | < 94% |
| Respiratory Rate | < 10 hoặc > 25 lần/phút | — |
| SBP (Huyết áp tâm thu) | ≥ 180 mmHg | ≥ 140 mmHg |
| DBP (Huyết áp tâm trương) | ≥ 120 mmHg | ≥ 90 mmHg |

### B2. Khi ngủ — `vitals_sleep_thresholds` (AASM 2020 / ICSD-3)

| Thông số | Critical | Warning | Ghi chú |
|---|---|---|---|
| Heart Rate | < 38 hoặc > 100 bpm | < 42 hoặc > 90 bpm | Deep sleep HR 40–55 là bình thường |
| SpO2 | < 85% | < 90% | OSA alert trigger: SpO2 < **88%** |
| Respiratory Rate | < 6 hoặc > 25 | — | Apnea threshold: RR < 6 |
| SBP | ≥ 180 mmHg | ≥ 160 mmHg | Ngưỡng cảnh báo lỏng hơn ban ngày |
| DBP | ≥ 120 mmHg | ≥ 100 mmHg | — |
| Nocturnal Tachycardia | HR > 120 bpm khi ngủ | — | Trigger alert riêng |

---

## C. Té ngã (Fall Detection) — Hệ thống 3 giai đoạn

> Nguồn: `Iot_Simulator_clean/pre_model_trigger/fall/fall_pipeline_wrist_config.json`  
> + `healthguard-model-api/app/config.py`  
> + `PM_REVIEW/SQL SCRIPTS/13_create_system_settings.sql`

### C1. Stage 1 — Pre-trigger IMU (Trên thiết bị, chạy liên tục)

| Loại trigger | Điều kiện | Reason Code |
|---|---|---|
| **Hard trigger** | Gia tốc đỉnh ≥ **3.0g** | `IMPACT_PEAK_3G` |
| **Soft trigger** | Accel ≥ 2.5g + Góc thay đổi tư thế ≥ 45° | `IMPACT_PLUS_POSTURE_CHANGE` |
| **Soft trigger** | Accel ≥ 2.5g + Bất động sau va chạm ≥ 1.0s | `IMPACT_PLUS_LOW_MOTION` |
| **Soft trigger** | Gyro ≥ **250 dps** + Góc thay đổi ≥ 45° | `GYRO_PLUS_POSTURE_CHANGE` |
| **Soft trigger** | Accel ≥ 2.0g + Rung sàn đột biến + Thay đổi pressure mat | `MULTIMODAL_ENVIRONMENTAL_TRIGGER` |

> Định nghĩa "bất động" (low motion): accel_mag_std ≤ 0.15g và gyro_mag_std ≤ 20 dps.

### C2. Stage 2 — Ngưỡng độ tin cậy AI Model (Fall Classifier)

| Ngưỡng | Giá trị | Ý nghĩa |
|---|---|---|
| `fall_true_at` | **0.50** | Nhãn nhị phân: "fall" |
| `warning_at` | **0.60** | `requires_attention = true` |
| `model_threshold_default` (pipeline) | **0.70** | Phân loại FALL_CANDIDATE |
| `confidence_threshold` (system settings) | **0.85** | Kích hoạt quy trình SOS tự động |
| `critical_at` | **0.85** | HIGH_PRIORITY_ALERT / CONFIRMED_FALL |

### C3. Fusion Logic — Kết hợp Stage 1 + Stage 2 + Stage 3

| Điều kiện | Kết quả | Hành động |
|---|---|---|
| Stage 1 không trigger | `NO_EVENT` / `NON_FALL` | Không làm gì |
| Stage 1 + probability < 0.70 | `NON_FALL_CANDIDATE` | Ghi log |
| Stage 1 + probability ≥ 0.70 | `FALL_CANDIDATE` | Alert nhẹ |
| Stage 1 + probability ≥ 0.70 + vital rule | `HIGH_RISK_FALL` | Alert cao |
| Stage 1 + probability ≥ 0.85 + bất động/nằm | `CONFIRMED_FALL` | **SOS đếm ngược 30 giây** |
| Bất kỳ vital URGENT sau té ngã | `URGENT` | **Gọi cấp cứu ngay** |

### C4. Stage 3 — Post-fall Vital Validation (Ngưỡng sinh hiệu sau té ngã)

Dùng lại ngưỡng từ section A, áp dụng trong cửa sổ 10–60 phút sau sự kiện:

| Điều kiện | Mức |
|---|---|
| SpO2 < 90% | URGENT |
| SpO2 ≤ 94% | SEND_TO_MODEL |
| RR ≤ 8 hoặc ≥ 25 | URGENT |
| SBP ≤ 90 mmHg | URGENT |
| HR ≤ 40 hoặc ≥ 131 | URGENT |
| MAP < 65 mmHg | URGENT |

---

## D. Health Risk AI Model — Ngưỡng phân loại rủi ro

> Nguồn: `healthguard-model-api/app/config.py` — class `HealthThresholds`

| Ngưỡng probability | Giá trị | Phân loại |
|---|---|---|
| `warning_at` | **0.35** | warning |
| `high_risk_true_at` | **0.50** | high_risk |
| `critical_at` | **0.65** | critical |

---

## E. Sleep Score — Ngưỡng điểm giấc ngủ

> Nguồn: `healthguard-model-api/app/config.py` — class `SleepThresholds`  
> Thang điểm: 0–100

| Score | Phân loại |
|---|---|
| ≥ 85 | **Good** (Tốt) |
| 75–84 | **Fair** (Trung bình) |
| 60–74 | **Poor** (Kém) |
| 50–59 | **Alert** (Cảnh báo) |
| < 50 | **Critical** (Nguy hiểm) |

---

## F. Tham chiếu lâm sàng

| Tiêu chuẩn | Áp dụng cho |
|---|---|
| **AHA 2023** | Heart Rate thresholds |
| **WHO** | SpO2 thresholds |
| **ERS/ATS** | Respiratory Rate thresholds |
| **ACC/AHA 2023** | Blood Pressure thresholds |
| **AASM 2020** | Sleep vitals thresholds |
| **ICSD-3** | Sleep apnea (RR < 6 = pre-apnea) |
| **Ohayon et al. 2004 meta-analysis** | Sleep staging norms |
