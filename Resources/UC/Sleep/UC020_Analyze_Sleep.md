# UC020 - PHÂN TÍCH GIẤC NGỦ (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Main Flow update match thực tế IoT simulator gửi sleep session hoàn chỉnh vào `POST /mobile/telemetry/sleep` (không phải server phân tích từ raw vitals). Drop Alt 4.a "nap detection" (D-SLP-02 — DB constraint 1/day, không implement). Keep Alt 3.a "incomplete session" + implement Phase 4 (D-SLP-03 gồm `is_complete` flag + min 2h boundary validation). Add BR-020-04 sleep ML inference flow thuộc UC028 Analysis scope.

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                                   |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Mã UC**          | UC020                                                                                                                                                                                                                                      |
| **Tên UC**         | Phân tích giấc ngủ                                                                                                                                                                                                                         |
| **Tác nhân chính** | IoT device (smartwatch + IoT sim), hệ thống backend                                                                                                                                                                                        |
| **Mô tả**          | Thiết bị thu thập vitals + motion suốt đêm, tổng hợp thành session + phases rồi đẩy sang backend. Backend upsert vào `sleep_sessions`. Output của UC020 là nguồn cho UC021 (patient report) và UC028 Analysis (sleep ML risk, qua UC028). |
| **Trigger**        | Device tự động detect khung giờ ngủ (ví dụ 22:00-06:00) hoặc end-of-session trigger (user thức dậy).                                                                                                                                       |
| **Tiền điều kiện** | - User đã pair device (UC040).<br>- Device thu thập đủ vitals (nhịp tim) + motion (accelerometer).                                                                                                                                        |
| **Hậu điều kiện**  | Một row trong `sleep_sessions` với `user_id + device_id + sleep_date` unique, phases JSONB đầy đủ, `sleep_score 0-100`, `is_complete` flag reflects data quality.                                                                          |

---

## Luồng chính (Main Flow) — Device-side aggregation + BE upsert

| Bước | Người thực hiện      | Hành động                                                                                                                                                                                                                 |
| ---- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Device / IoT sim     | Detect giờ ngủ (configured hoặc auto) và bắt đầu session tracking.                                                                                                                                                        |
| 2    | Device / IoT sim     | Thu thập vitals (HR, SpO2, respiration) + motion (accel) suốt session.                                                                                                                                                    |
| 3    | Device / IoT sim     | Khi session kết thúc (user wake detect), tính toán on-device: `duration_minutes`, `sleep_efficiency_pct`, `phases = {awake, light, deep, rem}` (minutes per stage), `wake_count = phases.awake // 30`.                    |
| 4    | Device / IoT sim     | `POST /mobile/telemetry/sleep` với `{ db_device_id, user_id, date, score, efficiency, duration_minutes, phases, start_time, end_time }`.                                                                                  |
| 5    | Hệ thống (BE)        | Validate Pydantic (`SleepIngestRequest`). Validate `duration_minutes >= 120` (**BR-020-02**, Phase 4). Nếu `duration_minutes < 120` thì set `is_complete = FALSE` (**BR-020-05**, Phase 4).                              |
| 6    | Hệ thống (BE)        | Upsert vào `sleep_sessions`: `INSERT ... ON CONFLICT (user_id, device_id, sleep_date) DO UPDATE`. Score clamped 0-100.                                                                                                    |
| 7    | Hệ thống (BE)        | Commit transaction, respond `{ ingested: 1, errors: [] }`.                                                                                                                                                                |
| 8    | Hệ thống (BE) async  | (optional, UC028 scope) Trigger `POST /mobile/telemetry/sleep-risk` nếu có canonical `SleepRecord` để chạy ML inference. Persist `risk_scores` với `risk_type='sleep'`. Consumed bởi UC028 Analysis, không phải UC021.   |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Thiết bị bị tháo giữa chừng (incomplete session)

| Bước  | Người thực hiện  | Hành động                                                                                                                                              |
| ----- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 3.a.1 | Device / IoT sim | Phát hiện khoảng dài (>30 phút) không có vitals trong session.                                                                                         |
| 3.a.2 | Device / IoT sim | Kết thúc session sớm với data đã thu thập được, flag internal "incomplete".                                                                             |
| 3.a.3 | Device / IoT sim | POST `/mobile/telemetry/sleep` với `duration_minutes` thực tế (có thể < 120).                                                                           |
| 3.a.4 | Hệ thống (BE)    | Bước 5 Main Flow detect `duration_minutes < 120` hoặc client truyền flag incomplete, set `is_complete = FALSE`. UC021 FE hiển thị badge "Không hoàn chỉnh". |

### 5.a - Pydantic validation fail (bad payload)

| Bước  | Người thực hiện | Hành động                                                                         |
| ----- | --------------- | --------------------------------------------------------------------------------- |
| 5.a.1 | Hệ thống (BE)   | Missing required field hoặc type mismatch.                                         |
| 5.a.2 | Hệ thống (BE)   | 422 Pydantic error. IoT sim log + retry next session.                              |

### 6.a - DB conflict resolution

| Bước  | Người thực hiện | Hành động                                                                                                                                                        |
| ----- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6.a.1 | Hệ thống (BE)   | ON CONFLICT (user_id, device_id, sleep_date) hit, đã có session cùng ngày.                                                                                      |
| 6.a.2 | Hệ thống (BE)   | UPDATE row cũ với data mới (start_time, end_time, score, phases, wake_count, is_complete). Behavior: latest ingestion wins — IoT sim gửi nhiều lần trong ngày OK. |

### 7.a - Ingest fail (DB error)

| Bước  | Người thực hiện | Hành động                                                                            |
| ----- | --------------- | ------------------------------------------------------------------------------------ |
| 7.a.1 | Hệ thống (BE)   | SQL exception trong upsert.                                                           |
| 7.a.2 | Hệ thống (BE)   | `db.rollback()`, respond `{ ingested: 0, errors: [str(exc)] }`. IoT sim retry later. |

---

## Business Rules

- **BR-020-01** (scope đồ án 2): Một device + user có đúng 1 session per day (UNIQUE `user_id, device_id, sleep_date`). Không hỗ trợ nap (ngủ trưa tách session) — xem decision D-SLP-02 drop Alt 4.a.
- **BR-020-02** (implement Phase 4): Phiên giấc ngủ phải có `duration_minutes >= 120` (2 giờ) mới được coi là hợp lệ. Boundary validation trong `/telemetry/sleep` ingest path, nếu < 120 thì session vẫn được lưu nhưng `is_complete = FALSE` (xem BR-020-05).
- **BR-020-03**: Các chỉ số phân tích lưu trong `sleep_sessions`:
  - `sleep_score` SMALLINT 0-100 (device-calculated)
  - `phases` JSONB: `{ awake, light, deep, rem }` minutes per stage
  - `wake_count` SMALLINT (device-calculated hoặc `phases.awake // 30` fallback)
  - `start_time`, `end_time`, `sleep_date`
- **BR-020-04** (cross-UC boundary): Sleep ML inference qua `POST /mobile/telemetry/sleep-risk` persist vào `risk_scores` table với `risk_type='sleep'`. Consumed bởi UC028 Analysis risk report, KHÔNG phải UC021 Report. UC021 dùng `sleep_score` từ `sleep_sessions` (device-calculated), không phải ML inference.
- **BR-020-05** (implement Phase 4 cùng BR-020-02): Column `sleep_sessions.is_complete BOOLEAN DEFAULT TRUE`. Set FALSE khi `duration_minutes < 120` hoặc client explicitly báo incomplete. UC021 FE hiển thị badge để user/caregiver nhận biết session không đầy đủ.
- **BR-Auth-01** (implement Phase 4): Endpoint `POST /mobile/telemetry/sleep` hiện KHÔNG có auth guard, bất kỳ ai biết `user_id + db_device_id` có thể inject session giả (xem **HS-004**). Phase 4 add `Depends(require_internal_service)` header `X-Internal-Service` (theo ADR-005 pattern) để chỉ IoT sim + trusted services được ingest.
- **BR-Auth-02**: Read endpoint `GET /metrics/sleep/latest` + `/history` đã enforce JWT user auth + `target_profile_id` resolution (user A chỉ xem data user B nếu `can_view_vitals = TRUE` trong `user_relationships`). Implement OK.

---

## Yêu cầu phi chức năng

- **Performance**: Ingest endpoint < 500ms P95 cho 1 session per request. Upsert cheap vì có UNIQUE index.
- **Security** (Phase 4): 3 endpoint ingest (`/sleep`, `/sleep-risk`, `/imu-window`) phải có `require_internal_service` — fix HS-004.
- **Usability**: UC020 không có UI cho user — device tự trigger. `SleepSettingsScreen` (FE) hiện disabled shell (D-SLP-01), Phase 5+ mới expose user control.
- **Privacy**: Sleep data xếp hạng PHI — encrypt at rest (pgcrypto `phases` JSONB optional Phase 5+), HTTPS mandatory production.

---

## Implementation references

- Ingest route: `health_system/backend/app/api/routes/telemetry.py` (`ingest_sleep_session`, `ingest_sleep_risk`)
- Ingest schema: `health_system/backend/app/api/routes/telemetry.py` (`SleepIngestRequest` inline)
- ML inference schema: `health_system/backend/app/schemas/sleep_telemetry.py` (`SleepRiskRequest`, `SleepRecord`)
- ML adapter: `health_system/backend/app/adapters/sleep_risk_adapter.py` (`SleepRiskAdapter`)
- Read route: `health_system/backend/app/api/routes/monitoring.py` (`get_latest_sleep_session`, `get_sleep_history`)
- Read service: `health_system/backend/app/services/monitoring_service.py` (`_calculate_sleep_metrics`, `_normalize_sleep_date`)
- DB: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` section 04 + 18 (sleep_sessions + UNIQUE index + sleep_date column)
- IoT sim client (ingest): `Iot_Simulator_clean/api_server/services/sleep_service.py`
- IoT sim ML client: `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` (bug IS-001 unrelated scope UC028)
- Related bugs: **HS-004** (telemetry endpoints no auth, Critical)
- Related UCs: UC021 (Report consumer), UC028 (Analysis consumer cho sleep ML risk_scores), UC040 (device pair precondition)
