# Phase 6 — Test Plan

> **Goal:** Define test pyramid per stack, mock strategy, contract test per ADR, E2E smoke plan. Đây là blueprint cho Phase 7 TDD build cycle.

**Phase:** P6 — Test Plan
**Date:** 2026-05-15
**Author:** Cascade
**Reviewer:** ThienPDM (pending)
**Status:** ✅ v1.0 Approved (2026-05-15)
**Inputs:** Charter v1.0, Gap Analysis v1.0, Migration Roadmap v1.0, 7 ADRs v1.0, 5 Contracts v1.0

---

## 1. Test pyramid principle

```
       ┌──────────────────┐
       │ E2E smoke        │  ← 4 demo scenarios (8 hours)
       │ (12-15 tests)    │
       └─────┬────────────┘
             │ ↓ slow, broad
       ┌────────────────────┐
       │ Integration        │  ← Cross-component (40-50 tests)
       │ (40-50 tests)      │
       └─────┬──────────────┘
             │ ↓ medium speed
       ┌────────────────────────┐
       │ Unit + Component       │  ← Per-function (150-200 tests)
       │ (150-200 tests)        │
       └────────────────────────┘
             ↓ fast, isolated
```

**Coverage target redesign:**
- Critical paths (8 gap P0): 100% line + branch
- High paths (24 gap P1): 80%+
- Medium/Low: best-effort

---

## 2. Test stack per repo

### 2.1 IoT Simulator BE (Python FastAPI)

**Stack:** pytest + pytest-asyncio + httpx + pytest-mock

**Test types:**

| Type | Folder | Run command | Coverage |
|---|---|---|---|
| Unit | `tests/test_*.py` | `pytest tests/` | 80%+ on services |
| Async unit | `tests/test_async_*.py` | `pytest tests/test_async_*.py` | 80%+ on runtime |
| Contract test | `tests/contract/test_*_contract.py` | `pytest tests/contract/` | 100% on outbound clients |
| Integration | `tests/integration/test_*.py` | `pytest tests/integration/` | Smoke critical |
| Pre-model-trigger | `pre_model_trigger/tests/` | `pytest pre_model_trigger/tests/` | Existing pass |

**Mock strategy:**
- Mobile BE: mock via `pytest-mock` or `httpx_mock`
- Model-API: NEVER call direct from IoT sim (ADR-019). Test với mock Mobile BE response shape only.
- DB: pytest fixture spin Postgres docker or use `pytest-asyncio` with `SQLAlchemy in-memory`

### 2.2 Mobile BE (Python FastAPI)

**Stack:** pytest + pytest-asyncio + httpx + sqlalchemy testing

**Test types:**

| Type | Folder | Coverage |
|---|---|---|
| Unit (services) | `tests/services/` | 90%+ on risk_alert_service |
| Unit (adapters) | `tests/adapters/` | 90%+ on model_api_health_adapter |
| Unit (routes) | `tests/routes/` | 80%+ schema validation |
| Integration | `tests/integration/` | Cross-service tests |
| Contract | `tests/contract/` | Match ADR-018 + contracts |

**Mock strategy:**
- Model-API: mock via `httpx_mock` (do NOT spin model-api docker for unit test)
- DB: `pytest-postgresql` fixture spin real Postgres for migration test
- FCM: `firebase-admin` mock per `mock.patch('firebase_admin.messaging.send')`

### 2.3 Model-API (Python FastAPI)

**Stack:** pytest + pytest-asyncio

**Test types:**
- Schema validation tests (Pydantic Field constraints)
- Predict endpoint tests with sample data
- Internal secret middleware tests

**Mock strategy:**
- ML model: lazy load, test với pre-loaded fixture
- Real ONNX inference cho integration tests

### 2.4 Mobile FE (Flutter/Dart)

**Stack:** flutter_test + mocktail + integration_test + flutter_driver

**Test types:**

| Type | Folder | Coverage |
|---|---|---|
| Widget | `test/widget/` | UI component render + interaction |
| Unit (repositories, providers) | `test/unit/` | 80%+ business logic |
| Integration | `integration_test/` | App-level flows |
| Golden | `test/golden/` | UI screenshot regression |

**Mock strategy:**
- API client: mock via `mocktail`
- FCM: mock `firebase_messaging` package
- Local notifications: mock `flutter_local_notifications`

### 2.5 Simulator-web FE (React + TypeScript)

**Stack:** Vitest + React Testing Library + Playwright (E2E)

**Test types:**

| Type | Folder | Coverage |
|---|---|---|
| Component | `src/**/__tests__/*.tsx` | UI render + interaction |
| Hook | `src/**/__tests__/use*.ts` | Logic |
| E2E | `e2e/` | Playwright apply scenario flow |

**Mock strategy:**
- WebSocket: `WS` mock library
- API: `msw` (Mock Service Worker)

---

## 3. Contract tests per ADR

### 3.1 ADR-018 (Validation Contract)

**Mobile BE tests (S3 dependency):**

```python
# tests/contract/test_validation_contract.py

def test_reject_when_heart_rate_null():
    """HS-024 fix: critical field NULL → InsufficientVitalsError"""
    vitals = build_vitals(heart_rate=None, spo2=98)
    with pytest.raises(InsufficientVitalsError) as exc:
        calculate_device_risk(device_id=42, user_id=7)
    assert "heart_rate" in exc.value.missing_fields

def test_reject_when_spo2_null():
    """HS-024 fix: critical field NULL"""
    vitals = build_vitals(heart_rate=72, spo2=None)
    with pytest.raises(InsufficientVitalsError):
        calculate_device_risk(device_id=42, user_id=7)

def test_reject_when_respiratory_rate_null():
    """HS-024 fix: respiratory_rate added to critical"""
    vitals = build_vitals(heart_rate=72, spo2=98, respiratory_rate=None)
    with pytest.raises(InsufficientVitalsError):
        calculate_device_risk(device_id=42, user_id=7)

def test_reject_when_temperature_null():
    """HS-024 fix: body_temperature added to critical"""
    vitals = build_vitals(heart_rate=72, spo2=98, respiratory_rate=16, temperature=None)
    with pytest.raises(InsufficientVitalsError):
        calculate_device_risk(device_id=42, user_id=7)

def test_tracks_defaults_for_soft_fields():
    """HS-024 fix: defaults_applied tracking complete"""
    vitals = build_complete_critical_vitals()
    user = setup_user_no_weight_height(user_id=7)
    result = calculate_device_risk(device_id=42, user_id=7)
    assert result.is_synthetic_default is True
    assert result.defaults_applied["weight_kg"] is True
    assert result.defaults_applied["height_cm"] is True
    assert result.defaults_applied["blood_pressure_sys"] is True
    assert result.defaults_applied["heart_rate"] is False  # critical not defaulted

def test_hrv_default_consistent_across_layers():
    """HS-024 fix: HRV default sync Layer 1 = Layer 2"""
    vitals = build_complete_critical_vitals(hrv=None)
    result = calculate_device_risk(device_id=42, user_id=7)
    # Layer 1: _build_inference_payload uses 40
    # Layer 2: ModelApiHealthAdapter.to_record should ALSO use 40 (not 50)
    assert result.defaults_applied["hrv"] is True
    # Verify both layers send same HRV to model-api
    mock_call = mock_model_api.last_call()
    assert mock_call.json()["records"][0]["hrv"] == 40.0
```

**Model-API tests (S2 dependency):**

```python
# healthguard-model-api/tests/test_contract_validation.py

def test_reject_out_of_range_heart_rate():
    """XR-003 fix: Field(ge=20, le=250) rejects out-of-range"""
    payload = {"records": [{"heart_rate": 500, ...}]}
    response = client.post("/api/v1/health/predict", json=payload, headers={"X-Internal-Secret": "..."})
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VITALS_OUT_OF_RANGE"
    assert response.json()["error"]["details"]["field"] == "heart_rate"

def test_reject_negative_spo2():
    payload = {"records": [{"spo2": -10, ...}]}
    response = client.post("/api/v1/health/predict", json=payload)
    assert response.status_code == 422

def test_accept_synthetic_flag():
    """XR-003 fix: is_synthetic_default optional accepted"""
    payload = {"records": [{
        "heart_rate": 72, "spo2": 98, ...,
        "is_synthetic_default": True,
        "defaults_applied": ["weight_kg", "blood_pressure_sys"]
    }]}
    response = client.post("/api/v1/health/predict", json=payload)
    assert response.status_code == 200

def test_effective_confidence_degraded_for_synthetic():
    """XR-003 fix: confidence × 0.5 when synthetic"""
    payload = {"records": [{..., "is_synthetic_default": True}]}
    response = client.post("/api/v1/health/predict", json=payload)
    result = response.json()["predictions"][0]
    assert result["effective_confidence"] < result["confidence"]
    assert result["effective_confidence"] == pytest.approx(result["confidence"] * 0.5)

def test_data_quality_warning_when_synthetic():
    payload = {"records": [{..., "is_synthetic_default": True, "defaults_applied": ["weight_kg"]}]}
    response = client.post("/api/v1/health/predict", json=payload)
    result = response.json()["predictions"][0]
    assert result["data_quality_warning"] is not None
    assert "weight_kg" in result["data_quality_warning"]
```

### 3.2 ADR-019 (No Direct Model-API)

**IoT sim tests (S9, S10):**

```python
# tests/contract/test_no_direct_modelapi.py

def test_fall_flow_goes_through_mobile_be(mock_mobile_be):
    """ADR-019: IoT sim NOT call model-api direct for fall"""
    runtime = build_test_runtime()
    runtime.apply_scenario("fall_high_confidence", device_id="SIM-001")
    runtime.tick_once()
    
    # Verify HTTP call to MOBILE BE (not model-api)
    mock_mobile_be.assert_called_with(
        path="/api/v1/mobile/telemetry/imu-window",
        method="POST",
        headers_contain={"X-Internal-Service": "iot-simulator"},
    )

def test_no_direct_fall_predict_call():
    """ADR-019: FallAIClient NOT invoked in runtime"""
    runtime = build_test_runtime()
    with patch.object(FallAIClient, 'predict') as mock_predict:
        runtime.apply_scenario("fall_high_confidence")
        runtime.tick_once()
        mock_predict.assert_not_called()

def test_sleep_dispatcher_used_not_direct_client():
    """ADR-019: SleepRiskDispatcher invoked, not SleepAIClient direct"""
    sleep_service = build_test_sleep_service()
    with patch.object(SleepAIClient, 'predict') as mock_predict:
        sleep_service.on_sleep_end(device_id="SIM-001", sleep_record={...})
        mock_predict.assert_not_called()
```

### 3.3 ADR-020 (Vitals HTTP Migration)

**IoT sim tests (S6):**

```python
# tests/contract/test_vitals_http_migration.py

def test_vitals_published_via_http(mock_mobile_be):
    """ADR-020: tick → HTTP /telemetry/ingest, NOT DB direct"""
    runtime = build_test_runtime()
    runtime.tick_once()
    
    mock_mobile_be.assert_called_with(
        path="/api/v1/mobile/telemetry/ingest",
        method="POST",
        body_match=lambda body: "messages" in body,
    )

def test_no_direct_db_insert_in_tick():
    """ADR-020: dispose direct DB INSERT"""
    runtime = build_test_runtime()
    with patch('sqlalchemy.session.Session.execute') as mock_execute:
        runtime.tick_once()
        # Should NOT call db.execute("INSERT INTO vitals...")
        assert not any(
            "INSERT INTO vitals" in str(call.args[0]) 
            for call in mock_execute.call_args_list
        )

def test_http_publish_handles_400(mock_mobile_be):
    """Vitals push handle error gracefully"""
    mock_mobile_be.return_value.status_code = 400
    runtime = build_test_runtime()
    runtime.tick_once()
    
    # Verify error tracked in last_publish_*
    session = runtime.sessions["test-session"]
    assert session.last_publish_ok is False
    assert session.last_publish_error is not None
```

### 3.4 ADR-021 (Prefix Migration)

**Cross-repo tests (S1):**

```python
# tests/smoke/test_endpoint_prefix.py

def test_mobile_be_at_v1_prefix():
    """ADR-021: Mobile BE at /api/v1/mobile/*"""
    response = requests.get("http://localhost:8000/api/v1/mobile/health")
    assert response.status_code == 200

def test_old_mobile_path_404():
    """ADR-021: Old /mobile/* no longer served"""
    response = requests.get("http://localhost:8000/mobile/health")
    assert response.status_code == 404

def test_iot_sim_at_v1_prefix():
    response = requests.get("http://localhost:8002/api/v1/sim/health")
    assert response.status_code == 200

def test_iot_sim_old_path_404():
    response = requests.get("http://localhost:8002/api/sim/health")
    assert response.status_code == 404
```

### 3.5 ADR-022 (IMU Window Persistence)

**Mobile BE tests (S8):**

```python
# tests/contract/test_imu_persistence.py

def test_imu_window_inserted_to_hypertable(test_db):
    """ADR-022: POST /imu-window persists raw data"""
    payload = build_valid_imu_window()
    response = client.post("/api/v1/mobile/telemetry/imu-window", json=payload, headers={"X-Internal-Service": "iot-simulator"})
    assert response.status_code == 200
    
    rows = test_db.execute("SELECT * FROM imu_windows WHERE device_id = :dev", {"dev": payload["db_device_id"]}).fetchall()
    assert len(rows) == 1

def test_retention_policy_active(test_db):
    """ADR-022: 7-day retention policy active"""
    rows = test_db.execute("""
        SELECT * FROM timescaledb_information.jobs 
        WHERE hypertable_name = 'imu_windows' 
        AND proc_name = 'policy_retention'
    """).fetchall()
    assert len(rows) > 0
    # Verify interval is 7 days
    config = json.loads(rows[0]["config"])
    assert config["drop_after"] == "7 days"

def test_compression_policy_active(test_db):
    rows = test_db.execute("""
        SELECT * FROM timescaledb_information.jobs 
        WHERE hypertable_name = 'imu_windows' 
        AND proc_name = 'policy_compression'
    """).fetchall()
    assert len(rows) > 0

def test_fall_event_links_to_imu_window(test_db):
    """ADR-022: FK fall_events.imu_window_id"""
    payload = build_valid_imu_window(scenario="fall_high_confidence")
    response = client.post("/api/v1/mobile/telemetry/imu-window", json=payload)
    
    fall_event_id = response.json()["fall_event_id"]
    row = test_db.execute("SELECT imu_window_id FROM fall_events WHERE id = :id", {"id": fall_event_id}).fetchone()
    assert row["imu_window_id"] is not None
```

### 3.6 ADR-023 (Mobile Streaming Pattern)

**Mobile FE tests (S12):**

```dart
// test/unit/fcm_handler_test.dart

void main() {
  test('critical fall sos triggers full-screen takeover', () async {
    final mockLocalNoti = MockFlutterLocalNotificationsPlugin();
    final handler = FcmHandler(localNoti: mockLocalNoti);
    
    final message = RemoteMessage(data: {
      'type': 'fall_sos',
      'severity': 'critical',
      'is_recipient_patient': 'true',
      'fullScreenIntent': 'true',
      'alert_id': '123',
    });
    
    await handler.onMessage(message);
    
    verify(() => mockLocalNoti.show(
      any(), any(), any(),
      argThat(predicate<NotificationDetails>((d) =>
        d.android?.fullScreenIntent == true &&
        d.android?.importance == Importance.max
      )),
      payload: any(named: 'payload'),
    )).called(1);
  });
  
  test('caregiver receives non-fullscreen notification', () async {
    final handler = FcmHandler();
    final message = RemoteMessage(data: {
      'type': 'fall_sos',
      'severity': 'critical',
      'is_recipient_patient': 'false',  // caregiver
      'fullScreenIntent': 'false',
    });
    
    await handler.onMessage(message);
    
    // Verify NOT triggering full-screen
    verifyNever(() => mockLocalNoti.show(any(), any(), any(),
      argThat(predicate<NotificationDetails>((d) => d.android?.fullScreenIntent == true)),
      payload: any(named: 'payload'),
    ));
  });
}
```

**Mobile BE tests (S13):**

```python
def test_fall_critical_fanout_to_patient_and_caregivers(mock_fcm):
    """ADR-023: send_fall_critical_alert dispatches to patient + linked caregivers"""
    create_linked_relationship(patient_id=7, caregiver_ids=[8, 9])
    register_push_token(7, "elderly_token")
    register_push_token(8, "family_1_token")
    register_push_token(9, "family_2_token")
    
    PushNotificationService.send_fall_critical_alert(
        db=test_db,
        patient_user_id=7,
        fall_event_id=512,
        confidence=0.95,
    )
    
    sent_messages = mock_fcm.get_sent_messages()
    assert len(sent_messages) == 3
    
    patient_msg = next(m for m in sent_messages if m.token == "elderly_token")
    assert patient_msg.data["is_recipient_patient"] == "true"
    assert patient_msg.data["fullScreenIntent"] == "true"
    assert patient_msg.data["click_action"] == "OPEN_SOS_CONFIRM"
    
    for caregiver_msg in [m for m in sent_messages if m.token in ("family_1_token", "family_2_token")]:
        assert caregiver_msg.data["is_recipient_patient"] == "false"
        assert caregiver_msg.data["fullScreenIntent"] == "false"
        assert caregiver_msg.data["click_action"] == "OPEN_NOTIFICATION_LIST"
```

### 3.7 ADR-024 (Sim WS Flow)

**IoT sim BE tests (S14):**

```python
def test_ws_flow_endpoint_streams_events(test_client):
    """ADR-024: /ws/flow/{session_id} streams flow events"""
    with test_client.websocket_connect("/ws/flow/test-session") as ws:
        runtime = get_runtime()
        runtime.publish_flow_event("test-session", {
            "step": "vitals_ingest",
            "status": "done",
            "ts": "2026-05-15T22:30:00Z",
        })
        
        received = ws.receive_json()
        assert received["step"] == "vitals_ingest"
        assert received["status"] == "done"

def test_ws_flow_multi_subscriber():
    """Two operators can subscribe to same session"""
    with test_client.websocket_connect("/ws/flow/test-session") as ws1, \
         test_client.websocket_connect("/ws/flow/test-session") as ws2:
        
        runtime.publish_flow_event("test-session", {"step": "alert_push", "status": "done"})
        
        # Both subscribers receive
        assert ws1.receive_json()["step"] == "alert_push"
        assert ws2.receive_json()["step"] == "alert_push"

def test_ws_flow_queue_full_drops_event():
    """Slow consumer drops events at queue full"""
    # Subscribe but don't consume → queue fills
    # Verify publish_flow_event doesn't block
    ...
```

**Simulator-web FE tests (S15):**

```typescript
// src/components/sequence_diagram/__tests__/useSequenceFlow.test.ts

describe('useSequenceFlow', () => {
  it('appends incoming events to state', async () => {
    const ws = new WS('ws://localhost:8002/ws/flow/test-session');
    const { result } = renderHook(() => useSequenceFlow('test-session'));
    
    await ws.connected;
    ws.send(JSON.stringify({
      step: 'vitals_ingest',
      status: 'done',
      ts: '2026-05-15T22:30:00Z',
    }));
    
    await waitFor(() => {
      expect(result.current.events).toHaveLength(1);
      expect(result.current.events[0].step).toBe('vitals_ingest');
    });
  });
  
  it('highlights activeStep then clears after 500ms', async () => {
    // Verify CSS active class applied + removed
  });
});
```

---

## 4. Integration tests per phase

### 4.1 Phase 7.B Integration (Validation Layer)

```python
# tests/integration/test_validation_e2e.py

def test_iot_sim_push_incomplete_vitals_rejected_chain():
    """
    Full chain:
    IoT sim → /telemetry/ingest (rejected) → IoT sim error log
    """
    # 1. IoT sim push vitals with HR=None
    runtime = build_test_runtime()
    runtime.tick_with_payload(heart_rate=None, spo2=98)
    
    # 2. Verify Mobile BE returned 422 INSUFFICIENT_VITALS
    last_log = runtime.logs.get_session_logs("test-session")[-1]
    assert "INSUFFICIENT_VITALS" in last_log["message"]
    
    # 3. Verify no risk_scores inserted
    rows = test_db.execute("SELECT COUNT(*) FROM risk_scores WHERE user_id = 7").scalar()
    assert rows == 0
```

### 4.2 Phase 7.C Integration (Vitals HTTP)

```python
def test_iot_sim_tick_to_mobile_chart_update():
    """
    Full chain:
    IoT sim tick → HTTP ingest → BE INSERT vitals → auto-risk → mobile chart updates
    """
    runtime.apply_scenario("normal_rest")
    runtime.tick_once()
    
    # Wait HTTP roundtrip + risk eval
    time.sleep(0.5)
    
    # Mobile poll vitals
    response = requests.get(f"/api/v1/mobile/monitoring/vitals/timeseries?device_id=42",
                            headers={"Authorization": f"Bearer {jwt_token}"})
    assert len(response.json()) > 0
    assert response.json()[-1]["heart_rate"] is not None
```

### 4.3 Phase 7.D Integration (Fall + Sleep)

```python
def test_fall_scenario_e2e():
    """
    IoT sim scenario apply → IMU window push → BE persist + predict → FCM dispatch
    """
    runtime.apply_scenario("fall_high_confidence", device_id="SIM-001")
    
    time.sleep(1)  # Wait full pipeline
    
    # Verify imu_windows row inserted
    iw = test_db.execute("SELECT * FROM imu_windows ORDER BY time DESC LIMIT 1").fetchone()
    assert iw is not None
    
    # Verify fall_events row with FK
    fe = test_db.execute("SELECT * FROM fall_events WHERE imu_window_id = :id", {"id": iw["id"]}).fetchone()
    assert fe is not None
    assert fe["confidence"] >= 0.7
    
    # Verify sos_events row
    sos = test_db.execute("SELECT * FROM sos_events WHERE fall_event_id = :id", {"id": fe["id"]}).fetchone()
    assert sos is not None
    
    # Verify FCM dispatched (mock)
    assert mock_fcm.sent_count() >= 1
```

### 4.4 Phase 7.E Integration (Mobile UX)

```dart
// integration_test/mobile_fcm_takeover_test.dart

void main() {
  testWidgets('FCM critical fall triggers SOSConfirmScreen', (tester) async {
    final mockFcm = MockFcmReceiver();
    await tester.pumpWidget(MyApp(fcm: mockFcm));
    
    // Simulate FCM data message
    await mockFcm.simulateMessage({
      'type': 'fall_sos',
      'severity': 'critical',
      'is_recipient_patient': 'true',
      'fullScreenIntent': 'true',
    });
    
    await tester.pumpAndSettle();
    
    expect(find.byType(SOSConfirmScreen), findsOneWidget);
    expect(find.text('Phát hiện té ngã'), findsOneWidget);
    expect(find.text('30'), findsOneWidget); // countdown
  });
}
```

---

## 5. E2E smoke tests (4 demo scenarios)

### 5.1 E2E setup

**Pre-condition:**
- All services running: model-api :8001, mobile BE :8000, IoT sim BE :8002, simulator-web :5173
- DB initialized với test seed
- 2 Android emulators (or 1 real + 1 emulator) registered FCM tokens
- 2 user accounts: `elderly@test.com`, `family@test.com` linked

**E2E framework:**
- Playwright cho simulator-web FE
- Flutter integration_test cho mobile
- Pytest E2E orchestrator

### 5.2 Demo scenarios

#### E2E-1: Vitals continuous + auto-risk

```python
@pytest.mark.e2e
def test_demo_vitals_continuous_risk_eval():
    """
    1. Operator login simulator-web
    2. Apply scenario "tachycardia_warning" on device SIM-001
    3. Wait 5-10s tick
    4. Verify simulator-web sequence diagram shows: vitals_ingest done → risk_eval running → risk_eval done
    5. Verify Mobile app (elderly@test.com) Home screen shows risk banner
    6. Verify Family app (family@test.com) Linked Dashboard shows elderly risk
    """
```

#### E2E-2: Fall takeover + FCM fanout

```python
@pytest.mark.e2e
def test_demo_fall_takeover_2_phones():
    """
    1. Operator apply "fall_high_confidence" on SIM-001
    2. Verify simulator-web shows: imu_push → model_predict (confidence 0.95) → fcm_dispatch (recipients: 2)
    3. Verify Elderly phone:
       - Screen wakes from locked
       - SOSConfirmScreen takeover
       - Ring alarm sound
       - Countdown 30s
    4. Verify Family phone:
       - Notification banner "Bố/mẹ té ngã - tap để xem"
       - Tap → opens RiskReportDetailScreen
    """
```

#### E2E-3: Sleep batch + report

```python
@pytest.mark.e2e
def test_demo_sleep_report():
    """
    1. Operator apply "good_sleep_night"
    2. Wait until sleep_end event (5-10 min compressed time)
    3. Verify mobile Sleep Report screen shows score 80+
    4. Verify chart phases distribution correct
    """
```

#### E2E-4: HS-024 prevention demo

```python
@pytest.mark.e2e
def test_demo_hs024_prevention():
    """
    1. Insert vitals with HR=NULL, SpO2=NULL into DB
    2. User taps "Tính lại" trên RiskReportScreen
    3. Verify response 422 INSUFFICIENT_VITALS
    4. Mobile shows banner "Cần đeo thiết bị thêm 5 phút..."
    """
```

---

## 6. Mock strategy per service

### Mobile BE → Model-API

```python
# pytest fixture
@pytest.fixture
def mock_model_api(httpx_mock):
    httpx_mock.add_response(
        url="http://localhost:8001/api/v1/health/predict",
        json={
            "predictions": [{
                "risk_level": "low",
                "confidence": 0.85,
                "effective_confidence": 0.85,
                "top_features": [],
                "data_quality_warning": None,
            }],
            "model_version": "test-v1",
            "request_id": "test-123",
        },
    )
    return httpx_mock
```

### IoT sim → Mobile BE

```python
@pytest.fixture
def mock_mobile_be(httpx_mock):
    httpx_mock.add_response(
        url="http://localhost:8000/api/v1/mobile/telemetry/ingest",
        json={
            "ingested": 1,
            "rejected": 0,
            "errors": [],
            "risk_evaluated_devices": [42],
        },
    )
    return httpx_mock
```

### Mobile FE → Mobile BE

```dart
// flutter mock
final mockClient = MockClient((request) async {
  if (request.url.path == '/api/v1/mobile/monitoring/vitals/timeseries') {
    return http.Response(jsonEncode([
      {'time': '...', 'heart_rate': 72, 'spo2': 98},
    ]), 200);
  }
  return http.Response('Not found', 404);
});
```

---

## 7. Coverage targets

| Stack | Target | Tool | Output |
|---|---|---|---|
| Mobile BE | 80% line + 70% branch | `pytest --cov` | `coverage.xml` |
| IoT sim BE | 80% line + 70% branch | `pytest --cov` | `coverage.xml` |
| Model-API | 90% line (small codebase) | `pytest --cov` | `coverage.xml` |
| Mobile FE | 70% line + 60% branch | `flutter test --coverage` | `coverage/lcov.info` |
| Simulator-web FE | 70% line | `vitest --coverage` | `coverage/` |

**Phase 7 gate:** Coverage không giảm so với baseline. Mỗi slice merge phải maintain hoặc tăng.

---

## 8. Test execution per slice (TDD pattern)

```
Slice N start
   ↓
1. Read ADR + contract spec for slice
   ↓
2. Write FAILING test (red)
   ↓
3. Implement minimum code (green)
   ↓
4. Refactor if needed
   ↓
5. Verify test pass + coverage maintained
   ↓
6. Commit slice với test fixture
   ↓
Slice N done
```

**Anti-pattern em không làm:**
- Write code first, test sau
- Skip test cho "small change"
- Disable failing test để merge
- Mock everything (test loses value)

---

## 9. CI/CD integration (post Phase 7)

**Phase 7 deferred:** GitHub Actions setup không phải scope đồ án (Charter section 2.3 non-goal). Em chạy test manual:

```pwsh
# All repos
cd D:\DoAn2\VSmartwatch
pytest health_system/backend/tests/
pytest Iot_Simulator_clean/tests/
pytest healthguard-model-api/tests/
cd health_system && flutter test
cd Iot_Simulator_clean/simulator-web && npm test
```

---

## 10. Acceptance criteria Phase 6

- [x] Test pyramid per stack documented
- [x] Mock strategy clear cho mỗi cross-service boundary
- [x] Contract test per ADR (7 ADRs covered)
- [x] Integration test per phase
- [x] E2E smoke (4 demo scenarios)
- [x] Coverage targets per stack
- [x] TDD pattern explicit per slice

---

## 11. Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-15 | Cascade | Initial test plan — pyramid, contracts, integration, E2E, mocks, coverage |
