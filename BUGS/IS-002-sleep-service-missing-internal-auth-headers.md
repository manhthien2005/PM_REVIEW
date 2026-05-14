# Bug IS-002: SleepService _push_sleep_to_backend thiếu internal auth headers (drift với AlertService)

**Status:** Open
**Repo(s):** Iot_Simulator_clean (api_server)
**Module:** api_server/services/sleep_service
**Severity:** Critical
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass B audit (M02)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

SleepService gui sleep session push toi `/mobile/telemetry/sleep` endpoint cua health_system backend voi CHI `Content-Type: application/json` header. Khong co `X-Internal-Service` hay `X-Internal-Secret` nhu ADR-005 yeu cau.

Sister service cung file (`alert_service.py`) LAI co du headers khi push alert. Drift giua 2 service flow trong cung IoT sim repo.

## Repro steps

1. Grep `Iot_Simulator_clean/api_server/services/sleep_service.py` cho tu khoa `X-Internal-Service`
2. Ket qua: 0 matches
3. Grep cung tu khoa trong `alert_service.py`
4. Ket qua: 2 matches (`_push_alert_to_backend` line ~140)

**Expected:** Ca 2 service flow deu gui `X-Internal-Service: iot-simulator` + `X-Internal-Secret: <env>` per ADR-005.

**Actual:** SleepService gui plaintext push, khong xac thuc duoc nguon.

**Repro rate:** 100% (code-path deterministic)

## Environment

- Repo: `Iot_Simulator_clean@develop`
- Files affected:
  - `Iot_Simulator_clean/api_server/services/sleep_service.py` line 608-670 (`_push_sleep_to_backend`)
  - `Iot_Simulator_clean/api_server/services/sleep_service.py` line 700-725 (`_post_sleep_payload`)
- Target endpoint: `POST /mobile/telemetry/sleep` (health_system backend port 8000)

## Root cause

### File: `sleep_service.py:640-665`

```python
def _push_sleep_to_backend(self, ...):
    ...
    endpoint = f"{self._health_backend_url}/mobile/telemetry/sleep"
    try:
        client = self._get_http_client()
        resp = client.post(
            endpoint,
            content=_json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},   # <-- ONLY Content-Type
        )
        ...
```

### File: `sleep_service.py:700-725` `_post_sleep_payload` (sibling helper):

```python
def _post_sleep_payload(self, *, payload: dict[str, Any], device_id: str):
    endpoint = f"{self._health_backend_url}/mobile/telemetry/sleep"
    client = self._get_http_client()
    resp = client.post(
        endpoint,
        content=_json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},   # <-- ONLY Content-Type
    )
    ...
```

### Contrast: `alert_service.py:130-145` (correct pattern):

```python
_iot_headers: dict[str, str] = {"X-Internal-Service": "iot-simulator"}
if self._internal_secret:
    _iot_headers["X-Internal-Secret"] = self._internal_secret
for attempt in range(1, _ALERT_PUSH_MAX_RETRIES + 1):
    try:
        status_code = self._http_sender(endpoint, prepared.payload_json, _iot_headers)
        ...
```

AlertService nhan `internal_secret: str | None = None` qua `__init__`.
SleepService __init__ (sleep_service.py:71-101) KHONG nhan `internal_secret` param.

### Why bug exists

2 code path cho 2 destination endpoint (mobile telemetry alert vs mobile telemetry sleep) duoc extract tu SimulatorRuntime God Object thanh 2 service rieng biet. Extraction task 3.5 (alert) chua lai lo hong header, task 3.4 (sleep) ke thua flow cu chua tung co header.

## Impact

### Option A: BE bo ngo endpoint (current state, per HS-004)

- IoT sim push thanh cong (HTTP 200)
- Bat ky ai biet URL deu co the push sleep session data vao DB user bat ky
- PHI leak risk
- Violates ADR-005 internal service auth strategy

### Option B: BE enforce header (sau Phase 4 HS-004 fix)

- IoT sim push bi reject (HTTP 403)
- Feature sleep tracking tu IoT sim bi broken hoan toan
- Heuristic fallback NOT applicable cho push path (chi applicable cho scoring)

Du roi vao option nao, P0 fix la add headers.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | SleepService extraction task 3.4 bo sot copy header injection pattern tu AlertService | Confirmed — not in __init__ signature |
| H2 | SleepService __init__ co nhan `internal_secret` ma em miss? | Rejected — read line 71-101 ky, no such param |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass B audit 2026-05-13, defer Phase 4)_

## Resolution

_(Fill in when resolved — Phase 4 target)_

**Fix approach (planned):**

### Step 1: Accept `internal_secret` trong `SleepService.__init__`

```python
def __init__(
    self,
    *,
    devices: dict[str, "DeviceRecord"],
    sessions: dict[str, "SessionRecord"],
    ...
    internal_secret: str | None = None,   # <-- ADD
) -> None:
    ...
    self._internal_secret = internal_secret
```

### Step 2: Build header dict giong AlertService

```python
def _build_internal_headers(self) -> dict[str, str]:
    headers = {
        "Content-Type": "application/json",
        "X-Internal-Service": "iot-simulator",
    }
    if self._internal_secret:
        headers["X-Internal-Secret"] = self._internal_secret
    return headers
```

### Step 3: Thay `headers={"Content-Type": ...}` tai 2 call sites

- `sleep_service.py:647` (`_push_sleep_to_backend`)
- `sleep_service.py:705` (`_post_sleep_payload`)

### Step 4: Update caller (`dependencies.py`) inject `internal_secret`

Tim noi instantiate `SleepService(...)` trong dependencies.py, pass `internal_secret=settings.INTERNAL_SERVICE_SECRET` (hoac tuong tu).

**Fix scope summary:** ~15 LoC change trong 2 file. Est 20 min coding + test. Tien hanh chung voi HS-004 BE-side fix theo batched PR.

**Test added (planned):**
- `Iot_Simulator_clean/tests/api_server/services/test_sleep_service.py::test_push_sleep_includes_internal_headers`
- `Iot_Simulator_clean/tests/api_server/services/test_sleep_service.py::test_post_sleep_payload_includes_internal_headers`
- Mock httpx.Client, assert headers dict contains `X-Internal-Service=iot-simulator`

**Verification:**
1. Run unit test -> green
2. E2E smoke: `scripts/e2e_fall_lab_smoke.ps1` extended version (sleep flow) — verify HS backend receives header
3. Grep sleep_service.py -> 2+ matches cho `X-Internal-Service`

## Related

- **Parent audit:** [M02 services audit](../AUDIT_2026/tier2/iot-simulator/M02_services_audit.md) 
- **Sister bug (BE side):** [HS-004](./HS-004-telemetry-sleep-endpoints-no-auth.md) — BE must enforce same header
- **ADR:** [ADR-005 internal-service-secret-strategy](../ADR/005-internal-service-secret-strategy.md) — mo ta contract bi vi pham
- **Reference pattern:** `Iot_Simulator_clean/api_server/services/alert_service.py:130-145` — correct implementation de copy
- **Phase -1 drift:** Khong co drift ID cu the — audit nay expose lo hong sau hon D-021 (D-021 chi mention "no auth verify" chua deep dive impl)

## Notes

- Surgical fix (1 param + 1 helper + 2 call site updates)
- Phase 4 coordination: ship cung HS-004 PR de tranh gap
- Verify `INTERNAL_SERVICE_SECRET` env var propagation tu dotenv -> settings -> dependencies.py -> SleepService
- Khong co heuristic fallback cho push path — khac voi scoring path
