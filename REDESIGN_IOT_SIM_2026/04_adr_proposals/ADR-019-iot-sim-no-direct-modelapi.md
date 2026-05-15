# ADR-019: IoT Simulator No Direct Model-API Call — Route via Mobile BE

**Status:** � Approved (Redesign 2026-05-15)
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [iot-sim, architecture, cross-repo, refactor]
**Resolves:** OQ2 (IMU persistence), OQ5 (risk trigger), B2 (Pattern Unified)

## Context

Phase 1 inventory phát hiện IoT simulator có 2 client gọi trực tiếp model-api `:8001`:
- `FallAIClient.predict()` → `POST :8001/api/v1/fall/predict`
- `SleepAIClient.predict()` → `POST :8001/api/v1/sleep/predict`

**Mismatch với production wearable pattern:**
- Apple Watch fall detection: smartwatch → iPhone (BLE) → iCloud Health → ML inference cloud
- Garmin: smartwatch → Garmin Connect mobile → Garmin server → ML inference
- **NONE call ML direct từ device** — always intermediate server

**Forces:**
- Brainstorm B2 đã chốt Pattern Unified — tất cả AI inference qua BE
- BE cần control: audit log, validate input (HS-024 fix), retry/circuit breaker, fallback
- IoT sim simulation phải đại diện đúng production flow → cho panel chấm thấy chính xác
- 2 orphan client `MobileTelemetryClient` + `SleepRiskDispatcher` đã ready trong `pre_model_trigger/` — chỉ cần wire

**Constraints:**
- IoT sim hiện DUI có UX feature: `/sessions/{id}/fall-state` poll trả về `fall_predictions` cache → operator UI thấy AI verdict realtime. Refactor không được mất feature này.
- `FallAIClient` + `SleepAIClient` có nhiều unit test trong `simulator_core/tests/` — cần handle test suite

**References:**
- Charter OQ2, OQ5
- Brainstorm B2 (Pattern Unified)
- Phase 2 target topology section 4
- Contract `fall_imu_window.md`, `sleep_session.md`

## Decision

**Chose:** Option A — Wire orphan `MobileTelemetryClient` + `SleepRiskDispatcher` thay thế direct AI clients trong IoT sim runtime.

**Why:**
1. **Production-realistic flow** — IoT sim đại diện đúng smartwatch behavior
2. **Pattern Unified** (B2 chốt) — 1 mental model cho 3 data type (vitals, fall, sleep)
3. **BE control hết** — validate, audit, retry, circuit breaker, fallback
4. **Orphan ready** — không phải viết code từ đầu, chỉ wire
5. **AI verdict cache vẫn giữ** — BE response trả prediction → IoT sim cache vào `_fall_predictions` cho FE poll

## Options considered

### Option A (CHOSEN): Wire orphan, dispose direct AI clients

**Description:**
- IoT sim FallAIClient direct call → REPLACE bằng `MobileTelemetryClient.post_imu_window()`
- IoT sim SleepAIClient direct call → REPLACE bằng `SleepRiskDispatcher.dispatch()` (which uses MobileTelemetryClient internally)
- `dependencies.py`:
  - Inject `MobileTelemetryClient` vào `SimulatorRuntime.__init__`
  - Update `_fall_pre_trigger_emit` method gọi mobile telemetry thay vì fall_ai_client.predict
- `sleep_service.py`:
  - Construct `SleepRiskDispatcher` với MobileTelemetryClient
  - Replace `_sleep_ai_client.predict()` call sites
- Keep `FallAIClient` + `SleepAIClient` class files (utility for direct debug / e2e test isolation), but không wire vào runtime

**Pros:**
- Match production flow
- 2 orphan class có purpose
- BE control flow + validation
- Simplify IoT sim mental model

**Cons:**
- Breaking change: existing IoT sim e2e test gọi FallAIClient direct → cần update
- Need verify BE response include `fall_event_id` (already in MobileTelemetryClient contract)
- Loss of low-latency direct AI call (BE adds ~50ms HTTP roundtrip) — acceptable for sim

**Effort:** M (~6-8h):
- 1h: Inject MobileTelemetryClient + SleepRiskDispatcher into runtime
- 2h: Replace FallAIClient direct call sites + adapt response handling
- 2h: Replace SleepAIClient direct call sites + adapt
- 1h: Update IoT sim unit tests (mock mobile BE instead of model-api)
- 1-2h: E2E smoke test fall + sleep scenarios

### Option B (rejected): Keep direct AI clients alongside MobileTelemetryClient

**Description:** Dual path — FallAIClient direct cho speed, MobileTelemetryClient optional fallback.

**Pros:**
- No breaking change
- Optionality

**Cons:**
- Maintain 2 path → confusion
- Hard to verify which path active
- Drift like current XR-001 → repeat

**Why rejected:** Pattern dual-path đã cho thấy là source of drift. YAGNI.

### Option C (rejected): Move FallAIClient/SleepAIClient into BE

**Description:** Move AI client code physically vào health_system/backend, IoT sim chỉ push raw data, BE gọi.

**Pros:**
- Force BE control
- Truly unified

**Cons:**
- Massive code move across repos
- Existing BE đã có `model_api_client.py` doing this → duplicate logic
- Out of scope (IoT sim refactor, not BE refactor)

**Why rejected:** Over-engineer. BE đã có model client, just need IoT sim point to BE.

## Consequences

### Positive
- IoT sim production-equivalent flow
- B2 Pattern Unified achieved
- OQ2 (IMU persistence) + OQ5 (BE auto-trigger risk) naturally fall in place
- Demo cho panel chấm clear flow IoT → BE → AI → mobile

### Negative / Trade-offs accepted
- Existing IoT sim e2e test cần update (mock mobile BE)
- +50ms HTTP latency per AI call (vs direct) — acceptable for sim
- 6-8h refactor effort

### Follow-up actions required
- [ ] Phase 7 slice 1: Wire `MobileTelemetryClient` vào `SimulatorRuntime`
- [ ] Phase 7 slice 2: Replace FallAIClient.predict call sites
- [ ] Phase 7 slice 3: Wire `SleepRiskDispatcher` vào `sleep_service`
- [ ] Phase 7 slice 4: Replace SleepAIClient.predict call sites
- [ ] Phase 7 slice 5: Update IoT sim e2e tests mock layer
- [ ] Phase 7 slice 6: Verify `/sessions/{id}/fall-state` cache still works

## Reverse decision triggers

- Nếu BE latency quá cao (>500ms per AI call) impacting sim demo → consider Option B hybrid
- Nếu BE health unstable → restore direct client as fallback (feature flag controlled)
- Nếu mobile BE refactor block IoT sim (cross-repo deadlock) → phase IoT sim first với mock BE

## Related

- ADR-018: Validation contract (companion — fail-closed at BE)
- ADR-022: IMU persistence (companion — depends on this routing)
- ADR-023: Mobile streaming pattern (companion — FCM dispatch source)
- Contract fall_imu_window.md, sleep_session.md
- Orphan files:
  - `Iot_Simulator_clean/pre_model_trigger/mobile_telemetry_client.py`
  - `Iot_Simulator_clean/pre_model_trigger/sleep_dispatch.py`
- To dispose (or keep as utility):
  - `Iot_Simulator_clean/simulator_core/fall_ai_client.py`
  - `Iot_Simulator_clean/simulator_core/sleep_ai_client.py`

## Notes

### Wiring pattern

```python
# dependencies.py (Phase 7)
class SimulatorRuntime:
    def __init__(self):
        # ... existing
        self._mobile_telemetry_client = MobileTelemetryClient(
            base_url=self._health_backend_url,
            http_sender=self._http_sender_with_body,
            internal_secret=os.getenv("INTERNAL_SECRET"),
        )
        self._sleep_dispatcher = SleepRiskDispatcher(client=self._mobile_telemetry_client)
        # Remove: self._fall_ai_client = FallAIClient(...)
        # Remove: self._sleep_ai_client = SleepAIClient(...)
```

### Backward compatibility

- IoT sim FE `/sessions/{id}/fall-state` endpoint unchanged
- Response shape: BE return `fall_event_id` + confidence + label → IoT sim build `AIPrediction` same shape as before → FE consume same way
- Existing unit tests for `FallAIClient.predict()` standalone → keep but mark as "direct AI test" (vs integration test which goes through BE)
