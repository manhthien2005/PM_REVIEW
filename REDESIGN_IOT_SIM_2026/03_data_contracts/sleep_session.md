# Contract — Sleep Session

> **Endpoint:** `POST /api/v1/mobile/telemetry/sleep-risk`  
> **Producer:** IoT simulator (Phase 7: wire `SleepRiskDispatcher` orphan)  
> **Consumer:** Mobile BE (`health_system/backend/app/api/routes/telemetry.py:720`)  
> **Critical changes:** Dispose direct `SleepAIClient` (B2), unified pattern qua BE

---

## 1. Request

### 1.1 Headers

```http
POST /api/v1/mobile/telemetry/sleep-risk HTTP/1.1
Host: localhost:8000
Content-Type: application/json
X-Internal-Service: iot-simulator
X-Schema-Version: 2026-05-15
Idempotency-Key: <uuid-v4>
```

### 1.2 Request body

```typescript
interface SleepRiskRequest {
  db_device_id: number;
  db_user_id: number;
  record: SleepRecord;          // 41-field canonical record
}

interface SleepRecord {
  // Session metadata (4 fields)
  session_date: string;          // ISO date YYYY-MM-DD
  session_start_time: string;    // ISO 8601 datetime
  session_end_time: string;      // ISO 8601 datetime
  total_duration_minutes: number;// computed end-start, range 60-720
  
  // Sleep phase distribution (5 fields, sum should be ~100%)
  light_sleep_pct: number;       // 0-100
  deep_sleep_pct: number;        // 0-100
  rem_sleep_pct: number;         // 0-100
  awake_pct: number;             // 0-100
  unknown_pct: number;           // 0-100
  
  // Phase duration absolute (5 fields, minutes)
  light_sleep_minutes: number;   // 0-600
  deep_sleep_minutes: number;
  rem_sleep_minutes: number;
  awake_minutes: number;
  unknown_minutes: number;
  
  // Quality indicators (10 fields)
  sleep_efficiency_pct: number;          // 0-100
  awakenings_count: number;              // 0-50
  long_awakenings_count: number;         // awakenings > 5min, 0-20
  sleep_onset_latency_minutes: number;   // time-to-sleep, 0-120
  rem_latency_minutes: number;           // time-to-first-REM, 0-180
  wake_after_sleep_onset_minutes: number;// WASO, 0-300
  sleep_fragmentation_index: number;     // 0.0-10.0
  movement_index: number;                // 0.0-100.0
  position_changes: number;              // 0-100
  snoring_episodes: number;              // 0-200
  
  // Cardiorespiratory averages during sleep (10 fields)
  avg_heart_rate: number;        // bpm, 30-120
  min_heart_rate: number;        // bpm, 30-120
  max_heart_rate: number;        // bpm, 30-180
  avg_spo2: number;              // %, 80-100
  min_spo2: number;              // %, 70-100
  spo2_drops_below_90: number;   // count, 0-200
  avg_respiratory_rate: number;  // /min, 5-30
  apnea_hypopnea_events: number; // AHI events, 0-200
  avg_temperature: number;       // °C, 34-39
  avg_hrv: number;               // ms, 10-150
  
  // Context (7 fields)
  scenario_id: string | null;    // for sim scenarios
  device_battery_pct: number;    // 0-100
  ambient_light_lux: number | null;// 0-1000
  ambient_noise_db: number | null; // 0-90
  bedroom_temp_celsius: number | null; // 10-35
  user_self_rating: number | null;// 1-5 stars (if user provided)
  notes: string | null;          // free text
}
```

### 1.3 Validation rules

| Rule | Action |
|---|---|
| `db_device_id`, `db_user_id` exist | 404 `NOT_FOUND` |
| `session_start_time < session_end_time` | 422 `OUT_OF_RANGE` |
| `total_duration_minutes` matches end-start (±1 min tolerance) | 422 `OUT_OF_RANGE` |
| `light+deep+rem+awake+unknown ≈ 100` (±5% tolerance) | 422 `OUT_OF_RANGE` |
| Phase minutes sum matches total_duration (±5% tolerance) | 422 `OUT_OF_RANGE` |
| All 41 fields range-validated | 422 `OUT_OF_RANGE` |
| `min_heart_rate ≤ avg ≤ max` | 422 `OUT_OF_RANGE` |
| `min_spo2 ≤ avg_spo2` | 422 `OUT_OF_RANGE` |

### 1.4 Example valid payload

```json
{
  "db_device_id": 42,
  "db_user_id": 7,
  "record": {
    "session_date": "2026-05-15",
    "session_start_time": "2026-05-15T22:30:00.000Z",
    "session_end_time": "2026-05-16T06:30:00.000Z",
    "total_duration_minutes": 480,
    
    "light_sleep_pct": 50,
    "deep_sleep_pct": 22,
    "rem_sleep_pct": 23,
    "awake_pct": 5,
    "unknown_pct": 0,
    
    "light_sleep_minutes": 240,
    "deep_sleep_minutes": 106,
    "rem_sleep_minutes": 110,
    "awake_minutes": 24,
    "unknown_minutes": 0,
    
    "sleep_efficiency_pct": 92.5,
    "awakenings_count": 3,
    "long_awakenings_count": 1,
    "sleep_onset_latency_minutes": 15,
    "rem_latency_minutes": 90,
    "wake_after_sleep_onset_minutes": 24,
    "sleep_fragmentation_index": 1.8,
    "movement_index": 12.5,
    "position_changes": 18,
    "snoring_episodes": 5,
    
    "avg_heart_rate": 62,
    "min_heart_rate": 52,
    "max_heart_rate": 78,
    "avg_spo2": 97,
    "min_spo2": 93,
    "spo2_drops_below_90": 0,
    "avg_respiratory_rate": 14,
    "apnea_hypopnea_events": 2,
    "avg_temperature": 36.4,
    "avg_hrv": 48,
    
    "scenario_id": "good_sleep_night",
    "device_battery_pct": 78,
    "ambient_light_lux": 5,
    "ambient_noise_db": 35,
    "bedroom_temp_celsius": 22,
    "user_self_rating": 4,
    "notes": null
  }
}
```

---

## 2. Response (success)

```typescript
interface SleepRiskResponse {
  sleep_session_id: number;
  model_request_id: string;       // for trace correlation
  prediction: {
    sleep_score: number;          // 0-100, model output
    sleep_quality_label: "poor" | "fair" | "good" | "excellent";
    stage_probabilities: {        // optional, model-dependent
      light: number;
      deep: number;
      rem: number;
      awake: number;
    } | null;
    risk_factors: string[];       // e.g., ["apnea_suspected", "fragmented"]
  };
  notification_dispatched: boolean; // true nếu BE push FCM info
}
```

### 2.1 Example success

```json
{
  "sleep_session_id": 256,
  "model_request_id": "req-sleep-abc-123",
  "prediction": {
    "sleep_score": 82,
    "sleep_quality_label": "good",
    "stage_probabilities": {
      "light": 0.48,
      "deep": 0.22,
      "rem": 0.25,
      "awake": 0.05
    },
    "risk_factors": []
  },
  "notification_dispatched": false
}
```

### 2.2 Example success (poor sleep → notification)

```json
{
  "sleep_session_id": 257,
  "model_request_id": "req-sleep-abc-124",
  "prediction": {
    "sleep_score": 52,
    "sleep_quality_label": "poor",
    "risk_factors": ["fragmented", "high_awakenings", "low_efficiency"]
  },
  "notification_dispatched": true
}
```

---

## 3. Side-effects

1. **Call model-api** `POST /api/v1/sleep/predict` với `X-Internal-Secret`
2. **INSERT INTO sleep_sessions** với score + quality_label + risk_factors
3. **Notification dispatch logic:**
   - `sleep_score < 60` → push FCM info-level "Giấc ngủ chưa tốt"
   - `sleep_score < 40` OR `apnea_hypopnea_events > 30` → push FCM warning "Cần khám bác sĩ"
4. **Emit flow event** WS `/ws/flow/{session_id}` cho simulator-web

---

## 4. Producer reference (IoT sim — Phase 7 wire orphan)

```python
# Iot_Simulator_clean/api_server/services/sleep_service.py (Phase 7)
from pre_model_trigger.sleep_dispatch import SleepRiskDispatcher
from pre_model_trigger.mobile_telemetry_client import MobileTelemetryClient

class SleepService:
    def __init__(self, runtime: SimulatorRuntime):
        # ... existing
        client = MobileTelemetryClient(
            base_url=runtime.health_backend_url,
            http_sender=runtime.http_sender_with_body,
        )
        self._dispatcher = SleepRiskDispatcher(client=client)
    
    def on_sleep_end(self, device_id: str, sleep_record: dict):
        # OLD (DISPOSE): self._sleep_ai_client.predict(sleep_record)
        # NEW (target):
        result = self._dispatcher.dispatch(
            record=sleep_record,
            db_device_id=self._resolve_db_device_id(device_id),
            db_user_id=self._resolve_db_user_id(device_id),
        )
        if result is None:
            logger.warning("Sleep dispatch failed for device %s", device_id)
```

---

## 5. Consumer reference (Mobile BE)

Existing handler `@d:\DoAn2\VSmartwatch\health_system\backend\app\api\routes\telemetry.py:720` (`/sleep-risk`) — **cần update:**

1. Call `model_api_client.predict_sleep_score(record)` (existing helper)
2. INSERT sleep_sessions với score + quality_label
3. Push FCM info/warning dựa trên score threshold
4. Return structured `SleepRiskResponse`

---

## 6. Backward compatibility

- **Breaking change:** Yes — IoT sim hiện direct call `:8001/api/v1/sleep/predict`
- **SleepRiskDispatcher orphan ready** — 16 unit tests pass
- **Endpoint `/telemetry/sleep-risk` đã có** — chỉ extend response shape
- **Deprecation:** `/telemetry/sleep` (without risk eval) → mark deprecated, mobile clients KHÔNG gọi

---

## 7. Test cases (Phase 6)

```python
def test_sleep_session_persist_and_predict():
    payload = build_valid_sleep_record(score_target="good")
    response = client.post("/api/v1/mobile/telemetry/sleep-risk", ...)
    assert response.status_code == 200
    assert response.json()["prediction"]["sleep_quality_label"] in ["good", "excellent"]

def test_sleep_phase_sum_validation():
    payload = build_valid_sleep_record()
    payload["record"]["light_sleep_pct"] = 80
    payload["record"]["deep_sleep_pct"] = 30  # sum > 100%
    response = client.post(...)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "OUT_OF_RANGE"

def test_poor_sleep_triggers_notification():
    payload = build_valid_sleep_record(score_target="poor")  # score < 60
    response = client.post(...)
    assert response.json()["notification_dispatched"] is True
```

---

## 8. Related

- ADR-019: IoT sim no direct model-api
- File `pre_model_trigger/sleep_dispatch.py:167` (SleepRiskDispatcher ready)
- File `pre_model_trigger/mobile_telemetry_client.py:153` (post_sleep_record method)
- File `simulator_core/sleep_ai_client.py` (to dispose)
