# Bug HS-026: 14 telemetry tests fail sau Phase 4 BLOCK 3

**Status:** Open
**Repo(s):** health_system (backend tests)
**Module:** backend/tests/test_imu_window_route.py + test_sleep_risk_route.py + test_telemetry_risk_pipeline.py
**Severity:** Medium (Phase 4 regression, must fix truoc Phase 5)
**Reporter:** ThienPDM (via Phase 4 reverify 2026-05-14)
**Created:** 2026-05-14

## Symptom

14 backend tests fail voi loi 403 Forbidden:
"Endpoint nay chi danh cho IoT Simulator internal service"

Tests POST toi 3 endpoint /mobile/telemetry/{sleep,sleep-risk,imu-window} ma KHONG gui header X-Internal-Service.

## Root cause

Phase 4 BLOCK 3 (HS-004 fix) added Depends(require_internal_service) cho 3 telemetry endpoint. Tests cu (pre-Phase 4) chi gui payload, khong gui auth header. Sau khi BLOCK 3 deploy, tests bi 403.

## Affected tests (14 total)

### test_imu_window_route.py (5 tests)
- TestImuWindowHappyPath - 2 tests
- TestImuWindowModelUnavailable - 1 test
- TestImuWindowSchemaValidation - 2 tests

### test_sleep_risk_route.py (5 tests)
- TestSleepRiskHappyPath - 2 tests
- TestSleepRiskModelUnavailable - 1 test
- TestSleepRiskSchemaValidation - 2 tests

### test_telemetry_risk_pipeline.py (4 tests)
- TestTelemetryRiskPipeline - 3 tests
- TestFallConfidenceThreshold - 5 tests

## Fix

Branch: fix/test-regression-phase4 tu develop.

Add header vao moi POST call:

Before:
```python
response = client.post(
    "/mobile/telemetry/imu-window",
    json=payload,
)
```

After:
```python
response = client.post(
    "/mobile/telemetry/imu-window",
    json=payload,
    headers={"X-Internal-Service": "iot-simulator"},
)
```

Helper recommend: shared fixture trong conftest.py
```python
@pytest.fixture
def internal_service_headers():
    return {"X-Internal-Service": "iot-simulator"}
```

## Verification

```
pytest backend/tests/test_imu_window_route.py backend/tests/test_sleep_risk_route.py backend/tests/test_telemetry_risk_pipeline.py
# Expect: 14 tests pass, 0 fail
```

## Related

- ADR-005 internal-service-secret-strategy
- HS-004 (resolved Phase 4 BLOCK 3)
- HS-025 (separate, Low) - 21 pre-existing test fixture drift
- HS-027 (separate, Medium) - schema gap DeviceSettingsRequest

## Effort

~1.5h: 14 line changes + verify red-green cycle.
