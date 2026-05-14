# Bug HS-004: Mobile telemetry endpoints (`/sleep`, `/sleep-risk`, `/imu-window`) thiếu auth guard

**Status:** 🔴 Open
**Repo(s):** health_system (mobile BE)
**Module:** telemetry
**Severity:** Critical
**Reporter:** ThienPDM (self) via Phase 0.5 SLEEP deep-dive
**Created:** 2026-05-13
**Resolved:** —

## Symptom

3 endpoint trong `telemetry.py` KHÔNG có `Depends(require_internal_service)`:

- `POST /mobile/telemetry/sleep` (line 551) — sleep session ingest
- `POST /mobile/telemetry/sleep-risk` (line ~540 trong section Phase 4A-thin) — ML sleep risk inference
- `POST /mobile/telemetry/imu-window` (line ~440 Phase 4B-thin) — fall model inference from raw IMU

So sánh với 2 endpoint có auth trong cùng file:
- `POST /mobile/telemetry/ingest` — `dependencies=[Depends(require_internal_service)]` ✓
- `POST /mobile/telemetry/alert` — `dependencies=[Depends(require_internal_service)]` ✓

Nghĩa là 3 endpoint trên là public — bất kỳ ai biết `db_device_id + user_id` có thể POST sleep session, sleep ML inference, hoặc fall IMU window data với payload tự chế. Vi phạm steering rule `40-security-guardrails.md`:

> "Mọi endpoint phải có middleware check auth + role. Default: deny."

## Repro steps

### Repro A: Inject sleep session không auth

1. Start mobile BE (`uvicorn app.main:app --port 8000`).
2. Trên terminal khác gọi:
   ```
   POST http://localhost:8000/mobile/telemetry/sleep
   Content-Type: application/json
   Body:
   {
     "db_device_id": 1,
     "user_id": 1,
     "date": "2026-05-13",
     "score": 95,
     "efficiency": 0.98,
     "duration_minutes": 480,
     "phases": {"awake": 20, "light": 200, "deep": 150, "rem": 110},
     "start_time": "2026-05-13T22:00:00Z",
     "end_time": "2026-05-14T06:00:00Z"
   }
   ```
3. Không có header `Authorization` hoặc `X-Internal-Service`.

**Expected:** 401 Unauthorized hoặc 403 Forbidden.
**Actual:** 200 OK `{"ingested": 1, "errors": []}`. Row insert thành công vào `sleep_sessions`.

### Repro B: Forge sleep ML inference

1. Cùng setup Repro A.
2. POST `http://localhost:8000/mobile/telemetry/sleep-risk` với full SleepRecord body, không header.
3. Request gọi model-api sleep endpoint + persist `risk_scores` với forged `risk_type='sleep'` cho `user_id` giả mạo.

**Expected:** 401/403.
**Actual:** 200 OK, row persisted.

### Repro C: Forge IMU window (fall detection)

1. Cùng setup.
2. POST `/mobile/telemetry/imu-window` với fake IMU samples, model-api predict, persist `fall_events`.
3. Forged fall event có thể trigger SOS escalation pipeline trong bước sau (nếu attacker cũng POST `/telemetry/alert` với `event_type=fall_detected`).

**Expected:** 401/403.
**Actual:** Fall event row persisted. SOS trigger path chỉ require auth trên `/alert` endpoint (has auth), nên exploit full-chain cần attacker post cả 2 endpoint, nhưng riêng `imu-window` đã là attack surface độc lập.

**Repro rate:** 100%.

## Environment

- Affected file: `health_system/backend/app/api/routes/telemetry.py`
- Affected routes:
  - `@router.post("/sleep", response_model=IngestResponse)` — line 551
  - `@router.post("/imu-window", response_model=ImuWindowResponse)` — line ~440
  - `@router.post("/sleep-risk", response_model=SleepRiskResponse)` — line ~500
- ADR reference: `PM_REVIEW/ADR/005-internal-service-secret-strategy.md` (pattern đã chốt, chỉ miss apply)

## Logs / Stack trace

Không có error log — bug là "silent accept", không raise exception.

## Investigation

### Hypothesis log

| #  | Hypothesis                                                                            | Status      |
| -- | ------------------------------------------------------------------------------------- | ----------- |
| H1 | 3 endpoint mới (Phase 4A-thin + 4B-thin) add sau khi apply pattern cho `/ingest`+`/alert`, miss copy pattern | ✅ Confirmed (lịch sử git sẽ confirm) |
| H2 | Endpoint nằm trong `/mobile/` prefix nên dev assume đã có auth chung                  | ✅ Possible, `router = APIRouter(prefix="/telemetry")` không có `dependencies` ở router level |

### Attempts

Chưa có — bug mới phát hiện Phase 0.5.

---

## Resolution

_(Fill in when resolved Phase 4)_

**Fix approach:**

### Option 1 (recommended): Add `dependencies` ở 3 route decorator

Pattern:
```python
@router.post(
    "/sleep",
    response_model=IngestResponse,
    dependencies=[Depends(require_internal_service)],
)
def ingest_sleep_session(...):
    ...
```

Áp dụng tương tự cho `/imu-window` và `/sleep-risk`.

### Option 2 (alternative): Add dependencies ở router level

```python
router = APIRouter(
    prefix="/telemetry",
    tags=["mobile-telemetry"],
    dependencies=[Depends(require_internal_service)],
)
```

Trade-off: Nếu Phase 5+ muốn thêm user-auth telemetry endpoint, phải override.

**Em recommend Option 1** — explicit per-endpoint để rõ intent, match hiện tại (2 endpoint khác cũng dùng pattern này).

### Step 2: Update IoT sim + any sender to pass `X-Internal-Service` header

IoT sim `Iot_Simulator_clean/api_server/services/sleep_service.py` + `telemetry_service.py` phải add header `X-Internal-Service: iot-simulator` khi POST. Nếu chưa có, Phase 4 task bundle thêm 1 effort nhỏ.

Grep `X-Internal-Service` trong IoT sim hiện tại:
- `fall_ai_client.py` đã có pattern (sau fix bug đơn tương tự trước đó)
- Sleep + IMU path cần verify.

**Regression test:**
- `health_system/backend/tests/test_telemetry_routes_http.py::test_sleep_endpoint_requires_internal_service`
- `tests/test_telemetry_routes_http.py::test_imu_window_endpoint_requires_internal_service`
- `tests/test_telemetry_routes_http.py::test_sleep_risk_endpoint_requires_internal_service`

Mỗi test:
1. POST không header, assert 401/403.
2. POST với header sai, assert 401/403.
3. POST với header đúng, assert 200.

## Related

- UC: UC020 v2 (BR-Auth-01)
- JIRA: _(chưa có)_
- Linked bug: —
- ADR: **ADR-005** (Internal service-to-service auth strategy, pattern đã chốt, bug là miss apply)
- Code: `health_system/backend/app/api/routes/telemetry.py:551` (`ingest_sleep_session`), line ~440 (`ingest_imu_window`), line ~500 (`ingest_sleep_risk`)
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/SLEEP.md` (section A2.2)

## Notes

- Fix surgical: 3 line change + IoT sim header verify.
- Không cần migration, không breaking DB.
- Breaking change cho client existing: IoT sim + bất kỳ script test nào đang POST 3 endpoint này phải add header. Mitigation: `_INTERNAL_SECRET` env đã có, chỉ cần add header trong client.
- Scope rộng hơn `SLEEP` module vì `/imu-window` thuộc FALL module, nhưng chung nguyên nhân (miss auth apply) nên track chung bug này.
