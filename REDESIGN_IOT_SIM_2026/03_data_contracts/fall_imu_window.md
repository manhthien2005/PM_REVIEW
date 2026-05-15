# Contract — Fall IMU Window

> **Endpoint:** `POST /api/v1/mobile/telemetry/imu-window`  
> **Producer:** IoT simulator (Phase 7: wire `MobileTelemetryClient` orphan — slice 2b)  
> **Consumer:** Mobile BE (`health_system/backend/app/api/routes/telemetry.py:638`)  
> **Critical changes:** Dispose direct `FallAIClient` (B2), persist IMU window TimescaleDB (OQ2)

---

## 1. Request

### 1.1 Headers

```http
POST /api/v1/mobile/telemetry/imu-window HTTP/1.1
Host: localhost:8000
Content-Type: application/json
X-Internal-Service: iot-simulator
X-Schema-Version: 2026-05-15
Idempotency-Key: <uuid-v4>
```

### 1.2 Request body

```typescript
interface ImuWindowRequest {
  db_device_id: number;          // required, FK to devices.id
  emitted_at: string;            // required, ISO 8601 UTC, window start timestamp
  duration_seconds: number;       // window length, default 2.0
  sample_rate_hz: number;         // default 50
  motion: ImuMotionData;
  context: FallContext;
}

interface ImuMotionData {
  // Each array length = duration_seconds × sample_rate_hz (default 100 samples)
  accel_x: number[];            // m/s², range -160 to 160
  accel_y: number[];
  accel_z: number[];
  gyro_x: number[];             // rad/s, range -35 to 35
  gyro_y: number[];
  gyro_z: number[];
  // Optional orientation (Quaternion-derived euler)
  orientation_pitch?: number[]; // degrees, range -180 to 180
  orientation_roll?: number[];
  orientation_yaw?: number[];
}

interface FallContext {
  scenario_id: string | null;     // simulator scenario name nếu replay
  variant: "fall_1" | "fall_2" | "fall_brief" | "fall_no_response" | null;
  activity_state_before: string;  // "walking", "resting", etc
  inject_environment: boolean;    // sim flag for synthetic
}
```

### 1.3 Validation rules

| Rule | Action when violated |
|---|---|
| `db_device_id` exists | 404 `NOT_FOUND` |
| `emitted_at` valid ISO 8601 + within last 5 min | 422 `OUT_OF_RANGE` |
| `motion.accel_x.length == duration_seconds × sample_rate_hz` | 400 `INVALID_PAYLOAD` |
| All accel arrays same length | 400 `INVALID_PAYLOAD` |
| All gyro arrays same length | 400 `INVALID_PAYLOAD` |
| Sample values range (accel ±160, gyro ±35) | 422 `OUT_OF_RANGE` |
| `duration_seconds` 0.5-10.0 | 422 `OUT_OF_RANGE` |
| `sample_rate_hz` in {25, 50, 100} | 400 `INVALID_PAYLOAD` |

### 1.4 Example valid payload

```json
{
  "db_device_id": 42,
  "emitted_at": "2026-05-15T22:30:00.000Z",
  "duration_seconds": 2.0,
  "sample_rate_hz": 50,
  "motion": {
    "accel_x": [0.12, 0.15, ...],
    "accel_y": [9.81, 9.82, ...],
    "accel_z": [0.05, 0.06, ...],
    "gyro_x": [0.01, 0.02, ...],
    "gyro_y": [-0.01, 0.00, ...],
    "gyro_z": [0.03, 0.04, ...]
  },
  "context": {
    "scenario_id": "fall_high_confidence",
    "variant": "fall_1",
    "activity_state_before": "walking",
    "inject_environment": true
  }
}
```

---

## 2. Response (success)

### 2.1 Success body

```typescript
interface ImuWindowResponse {
  imu_window_id: number;        // FK to imu_windows table
  fall_event_id: number | null; // if model_predict triggered fall
  prediction: {
    label: "fall" | "not_fall" | "uncertain";
    confidence: number;         // 0.0-1.0
    top_features: string[];     // for SHAP explanation
  };
  action_taken: "sos_dispatched" | "soft_caregiver_notice" | "no_action";
  request_id: string;
}
```

### 2.2 Example success (fall detected with SOS)

```json
{
  "imu_window_id": 1024,
  "fall_event_id": 512,
  "prediction": {
    "label": "fall",
    "confidence": 0.95,
    "top_features": ["accel_peak_z", "gyro_peak_y", "orientation_change"]
  },
  "action_taken": "sos_dispatched",
  "request_id": "abc-123"
}
```

### 2.3 Example success (no fall)

```json
{
  "imu_window_id": 1025,
  "fall_event_id": null,
  "prediction": {
    "label": "not_fall",
    "confidence": 0.12,
    "top_features": []
  },
  "action_taken": "no_action",
  "request_id": "abc-124"
}
```

---

## 3. Side-effects (BE processing pipeline)

Sau khi nhận IMU window:

1. **INSERT INTO imu_windows** (TimescaleDB hypertable, retention 7 ngày)
2. **Call model-api** `POST /api/v1/fall/predict` với `X-Internal-Secret`
3. **Process prediction:**
   - `confidence ≥ 0.7` AND variant != `false_alarm` → INSERT `fall_events` + `sos_events` + FCM critical
   - `confidence 0.4-0.7` → INSERT `fall_events` (soft) + FCM caregiver-only soft notice
   - `confidence < 0.4` → INSERT `fall_events` (audit only), no FCM
4. **Emit flow event** WS `/ws/flow/{session_id}` cho simulator-web

---

## 4. Producer reference (IoT sim — Phase 7 wire orphan)

```python
# Iot_Simulator_clean/api_server/dependencies.py (Phase 7)
class SimulatorRuntime:
    def __init__(self):
        # ... existing
        from pre_model_trigger.mobile_telemetry_client import MobileTelemetryClient
        self._mobile_telemetry = MobileTelemetryClient(
            base_url=self._health_backend_url,
            http_sender=self._http_sender_with_body,
            internal_secret=os.getenv("INTERNAL_SECRET"),
        )
    
    def _on_fall_detected(self, device_id: str, motion_window: dict):
        # OLD (DISPOSE): self._fall_ai_client.predict(motion_window, device_id, ...)
        # NEW (target):
        response = self._mobile_telemetry.post_imu_window(
            db_device_id=self._resolve_db_device_id(device_id),
            emitted_at=_utc_now_iso(),
            motion=motion_window,
            context=self._build_fall_context(device_id),
        )
        if response is None:
            logger.warning("IMU window submit failed for device %s", device_id)
            return
        # Cache prediction trong _fall_predictions cho FE poll /sessions/{id}/fall-state
        self._fall_predictions[device_id] = AIPrediction.from_response(response)
```

**Migration:**
- Phase 7 slice 1: Wire `MobileTelemetryClient` + test contract
- Phase 7 slice 2: Replace `FallAIClient.predict()` call sites
- Phase 7 slice 3: Verify smoke E2E fall scenario → mobile FCM
- Phase 7 slice 4: Remove `FallAIClient` class (or keep as utility debug-only)

## 5. Consumer reference (Mobile BE — Phase 7 implement)

Existing handler tại `@d:\DoAn2\VSmartwatch\health_system\backend\app\api\routes\telemetry.py:638` — **cần update:**

1. **Add `INSERT INTO imu_windows`** trước khi call model-api (currently chỉ INSERT fall_events)
2. **Wire model-api fall predict call** — currently có thể đã có nhưng verify
3. **Add FK `imu_window_id` vào fall_events** insert
4. **Schema validation strict** — `extra="forbid"`, range constraints
5. **Idempotency dedup** — `Idempotency-Key` 5 phút window

---

## 6. DB schema target (Phase 4 ADR-022)

```sql
-- Migration: 20260515_imu_windows_hypertable.sql
CREATE TABLE imu_windows (
    time TIMESTAMPTZ NOT NULL,
    device_id BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    fall_event_id BIGINT REFERENCES fall_events(id) ON DELETE SET NULL,
    accel JSONB NOT NULL,
    gyro JSONB NOT NULL,
    orientation JSONB,
    sample_rate_hz INT NOT NULL DEFAULT 50,
    duration_seconds REAL NOT NULL DEFAULT 2.0,
    context JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (time, device_id)
);

SELECT create_hypertable('imu_windows', 'time', chunk_time_interval => INTERVAL '1 day');
SELECT add_retention_policy('imu_windows', INTERVAL '7 days');
ALTER TABLE imu_windows SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('imu_windows', INTERVAL '1 day');

CREATE INDEX idx_imu_windows_fall_event ON imu_windows (fall_event_id) WHERE fall_event_id IS NOT NULL;

-- Add FK column to fall_events (if not exists)
ALTER TABLE fall_events ADD COLUMN IF NOT EXISTS imu_window_id BIGINT;
ALTER TABLE fall_events ADD CONSTRAINT fk_fall_events_imu_window 
    FOREIGN KEY (imu_window_id) REFERENCES imu_windows ON DELETE SET NULL;
```

**Storage projection:**
- 1 fall event ~3.6KB raw (100 samples × 9 channels × 4 bytes)
- 100 user × 100 events/day × 7 days = 252MB rolling
- TimescaleDB compress 10:1 → ~25MB effective

---

## 7. Backward compatibility

- **Breaking change:** Yes — IoT sim hiện call `:8001/api/v1/fall/predict` direct. Sau redesign IoT sim không touch model-api.
- **MobileTelemetryClient orphan đã sẵn sàng** — wire vào runtime là main work
- **Mobile BE endpoint đã có** (`/telemetry/imu-window` line 638) — chỉ thêm DB INSERT imu_windows + structured response

---

## 8. Test cases (Phase 6 plan)

```python
# Contract test (Mobile BE)
def test_imu_window_persist_and_predict():
    payload = build_valid_imu_window(label="fall")
    response = client.post("/api/v1/mobile/telemetry/imu-window",
                          json=payload,
                          headers={"X-Internal-Service": "iot-simulator"})
    assert response.status_code == 200
    body = response.json()
    assert body["imu_window_id"] is not None
    assert body["fall_event_id"] is not None
    assert body["prediction"]["confidence"] >= 0.7
    assert body["action_taken"] == "sos_dispatched"

def test_imu_window_array_length_mismatch():
    payload = build_valid_imu_window()
    payload["motion"]["accel_x"] = payload["motion"]["accel_x"][:50]  # truncate
    response = client.post("/api/v1/mobile/telemetry/imu-window", ...)
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_PAYLOAD"

# Integration test
def test_e2e_fall_scenario_dispatches_fcm():
    runtime.apply_scenario("fall_high_confidence", device_id="SIM-001")
    # Wait for inject + IMU push + model predict + FCM dispatch
    wait_for_fcm_in_mock(timeout=5)
    fcm_messages = mock_fcm.get_messages()
    assert any(m["type"] == "fall_sos" and m["severity"] == "critical" 
               for m in fcm_messages)
```

---

## 9. Related

- ADR-019: IoT sim no direct model-api
- ADR-022: IMU window persistence policy
- OQ2: TimescaleDB TTL 7 ngày
- File `pre_model_trigger/mobile_telemetry_client.py` (orphan ready)
- File `simulator_core/fall_ai_client.py` (to dispose)
