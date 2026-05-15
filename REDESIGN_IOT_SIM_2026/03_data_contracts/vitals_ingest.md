# Contract — Vitals Ingest

> **Endpoint:** `POST /api/v1/mobile/telemetry/ingest`  
> **Producer:** IoT simulator (transition: từ DB direct → HTTP per B1 + ADR-020)  
> **Consumer:** Mobile BE (`health_system/backend/app/api/routes/telemetry.py:225`)  
> **Critical bugs fixed:** XR-001 (prefix), HS-024 (silent default fill prevention)

---

## 1. Request

### 1.1 Headers

```http
POST /api/v1/mobile/telemetry/ingest HTTP/1.1
Host: localhost:8000
Content-Type: application/json
X-Internal-Service: iot-simulator
X-Schema-Version: 2026-05-15
Idempotency-Key: <uuid-v4>
```

### 1.2 Request body

```typescript
interface VitalIngestRequest {
  messages: VitalIngestItem[];   // batch up to 50 items
}

interface VitalIngestItem {
  db_device_id: number;          // required, FK to devices.id
  emitted_at: string;            // required, ISO 8601 UTC timestamp
  vitals: VitalsPayload;
}

interface VitalsPayload {
  // Critical fields (at least 1 of HR/SpO2 required — see validation)
  heart_rate: number | null;       // bpm, range 20-250 inclusive, nullable
  spo2: number | null;             // %, range 50-100 inclusive, nullable
  
  // Optional clinical fields (nullable, range-validated if present)
  temperature: number | null;       // °C, range 30-45 inclusive
  hrv: number | null;               // ms, range 0-300 inclusive
  respiratory_rate: number | null;  // /min, range 5-60 inclusive
  blood_pressure_sys: number | null;// mmHg, range 60-260 inclusive
  blood_pressure_dia: number | null;// mmHg, range 30-180 inclusive
  signal_quality: number | null;    // 0.0-1.0, indicates sensor reliability
  motion_artifact: boolean | null;  // true nếu signal có nhiễu chuyển động
  
  // Metadata
  source_mode: "synthetic" | "replay" | "real";  // default "real"
  activity_state: "resting" | "walking" | "running" | "sleeping" | "fall";
}
```

### 1.3 Validation rules (target — fix HS-024)

| Rule | Action when violated |
|---|---|
| `messages.length` 1-50 | 400 `INVALID_PAYLOAD` |
| `db_device_id` exists in `devices` table | 404 `NOT_FOUND` |
| `emitted_at` valid ISO 8601 + within last 60 min | 422 `OUT_OF_RANGE` |
| `heart_rate` range 20-250 (if not null) | 422 `OUT_OF_RANGE` |
| `spo2` range 50-100 (if not null) | 422 `OUT_OF_RANGE` |
| `temperature` range 30-45 (if not null) | 422 `OUT_OF_RANGE` |
| All other fields ranges as above | 422 `OUT_OF_RANGE` |
| **Critical:** ≥1 of `heart_rate` HOẶC `spo2` MUST be non-null per item | 422 `INSUFFICIENT_VITALS` |

**HS-024 root cause fix:** Mobile BE **MUST NOT** silently fill defaults. Reject record nếu critical field NULL.

### 1.4 Example valid payload

```json
{
  "messages": [
    {
      "db_device_id": 42,
      "emitted_at": "2026-05-15T22:30:00.000Z",
      "vitals": {
        "heart_rate": 72,
        "spo2": 98,
        "temperature": 36.6,
        "hrv": 45,
        "respiratory_rate": 16,
        "blood_pressure_sys": 118,
        "blood_pressure_dia": 76,
        "signal_quality": 0.92,
        "motion_artifact": false,
        "source_mode": "synthetic",
        "activity_state": "resting"
      }
    }
  ]
}
```

### 1.5 Example invalid payload (rejected per HS-024 fix)

```json
{
  "messages": [
    {
      "db_device_id": 42,
      "emitted_at": "2026-05-15T22:30:00.000Z",
      "vitals": {
        "heart_rate": null,
        "spo2": null,
        "temperature": 36.6,
        "source_mode": "synthetic",
        "activity_state": "resting"
      }
    }
  ]
}
```

Response:
```json
{
  "error": {
    "code": "INSUFFICIENT_VITALS",
    "message": "messages[0]: cần ít nhất 1 trong heart_rate hoặc spo2",
    "details": {
      "device_id": 42,
      "emitted_at": "2026-05-15T22:30:00.000Z",
      "missing_fields": ["heart_rate", "spo2"]
    }
  },
  "request_id": "abc-123"
}
```

---

## 2. Response (success)

### 2.1 Success body

```typescript
interface IngestResponse {
  ingested: number;             // count successfully INSERTed
  rejected: number;             // count rejected (INSUFFICIENT_VITALS, OUT_OF_RANGE)
  errors: IngestError[];        // per-item error details
  risk_evaluated_devices: number[];  // device_ids triggered auto-risk eval
}

interface IngestError {
  index: number;                // index in messages array
  device_id: number;
  emitted_at: string;
  error_code: string;
  message: string;
}
```

### 2.2 Example success response

```json
{
  "ingested": 1,
  "rejected": 0,
  "errors": [],
  "risk_evaluated_devices": [42]
}
```

### 2.3 Example partial success (some rejected)

```json
{
  "ingested": 2,
  "rejected": 1,
  "errors": [
    {
      "index": 1,
      "device_id": 43,
      "emitted_at": "2026-05-15T22:30:05.000Z",
      "error_code": "INSUFFICIENT_VITALS",
      "message": "cần ít nhất 1 trong heart_rate hoặc spo2"
    }
  ],
  "risk_evaluated_devices": [42]
}
```

Note: HTTP status 200 vì có ingest thành công. Caller xem `errors[]` để retry per-item logic.

---

## 3. Side-effects (BE auto-trigger after ingest)

Theo OQ5: sau mỗi batch ingest thành công, BE auto-call `calculate_device_risk` cho mỗi unique `device_id`:

1. Check cooldown (default 60s per device)
2. If cooldown OK + vitals đủ → call `/api/v1/health/predict` (model-api)
3. INSERT result vào `risk_scores` với `is_synthetic_default=false` (vitals real)
4. If severity ≥ medium → push FCM
5. WebSocket emit flow event tới `/ws/flow/{session_id}` cho simulator-web

---

## 4. Producer reference (IoT sim — Phase 7 implement)

```python
# Iot_Simulator_clean/api_server/services/vitals_publisher.py (NEW)
class VitalsHttpPublisher:
    def __init__(self, base_url: str, internal_service_id: str = "iot-simulator"):
        self._base_url = base_url.rstrip("/")
        self._client = httpx.Client(timeout=10.0)
        self._headers = {"X-Internal-Service": internal_service_id}
    
    def publish_batch(self, messages: list[dict]) -> IngestResult:
        endpoint = f"{self._base_url}/api/v1/mobile/telemetry/ingest"
        idempotency_key = str(uuid.uuid4())
        response = self._client.post(
            endpoint,
            json={"messages": messages},
            headers={**self._headers, "Idempotency-Key": idempotency_key},
        )
        return IngestResult.from_response(response)
```

**Migration path:**
- Phase 7 slice 1: Add `VitalsHttpPublisher` + tests
- Phase 7 slice 2: Wire vào `_execute_pending_tick_publish` thay thế DB direct INSERT
- Phase 7 slice 3: Verify smoke E2E + remove old `_execute_pending_tick_publish` code path

## 5. Consumer reference (Mobile BE — Phase 7 implement)

Existing handler tại `@d:\DoAn2\VSmartwatch\health_system\backend\app\api\routes\telemetry.py:225` — **cần update:**

1. **Schema strict** — thay `VitalIngestVitals.model_config = ConfigDict(extra="allow")` bằng `extra="forbid"` để reject unknown fields
2. **Add range validation** — `Field(ge=20, le=250)` cho `heart_rate`, etc
3. **Add `INSUFFICIENT_VITALS` check** — line 264-289 cần check `heart_rate is None AND spo2 is None`
4. **Structured error response** — thay raw `errors: list[str]` bằng `errors: list[IngestError]`
5. **Idempotency dedup** — check `Idempotency-Key` trong 5 phút window (Redis hoặc in-memory)

---

## 6. Consumer reference (Mobile app — KHÔNG trực tiếp call)

Mobile app **không** call endpoint này. Mobile chỉ:
- Poll `GET /api/v1/mobile/monitoring/vitals/timeseries` để xem vitals đã INSERT
- Nhận FCM nếu BE auto-trigger detect critical risk

---

## 7. Backward compatibility

- **Breaking change:** Yes — IoT sim hiện DB direct write, sau redesign HTTP push. Cần update IoT sim code.
- **Migration window:** Phase 7 deploy IoT sim + Mobile BE đồng thời. Không có dual-mount transitional vì cùng repo workspace.
- **Mobile BE backward compat:** Endpoint đã có (line 225) — chỉ thêm validation strict. Existing test suite cần update để gửi đủ field.

---

## 8. Test cases (Phase 6 plan)

### Contract test (Mobile BE)

```python
# tests/test_telemetry_ingest_contract.py
def test_reject_missing_critical_vitals():
    payload = {"messages": [{
        "db_device_id": 42,
        "emitted_at": "2026-05-15T22:30:00.000Z",
        "vitals": {"heart_rate": None, "spo2": None}
    }]}
    response = client.post("/api/v1/mobile/telemetry/ingest", 
                          json=payload, 
                          headers={"X-Internal-Service": "iot-simulator"})
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "INSUFFICIENT_VITALS"

def test_reject_out_of_range_heart_rate():
    # heart_rate=500 should be rejected
    ...

def test_idempotency_dedup_within_5min():
    # Same idempotency_key twice → second call returns same result, no DB duplicate
    ...
```

### Integration test (IoT sim + Mobile BE)

```python
# tests/test_e2e_vitals_flow.py
def test_iot_sim_publish_vitals_triggers_risk_eval(test_runtime, test_mobile_be):
    test_runtime.apply_scenario("tachycardia_warning")
    test_runtime.tick_once()
    # Wait for HTTP push to complete
    time.sleep(0.5)
    # Verify vitals INSERTed
    vitals = test_mobile_be.get_latest_vitals(device_id=42)
    assert vitals.heart_rate >= 110  # tachycardia threshold
    # Verify auto-risk triggered
    risk = test_mobile_be.get_latest_risk(user_id=1)
    assert risk.risk_level in ["warning", "high"]
```

---

## 9. Related

- ADR-018: Health input validation contract (resolves HS-024 + XR-003)
- ADR-019: IoT sim no direct model-api
- ADR-020: Vitals path migration DB direct → HTTP
- ADR-021: Endpoint prefix execution
- Bug HS-024: Silent default fill
- Bug XR-001: Endpoint prefix drift
- Bug XR-003: Validation contract gap
