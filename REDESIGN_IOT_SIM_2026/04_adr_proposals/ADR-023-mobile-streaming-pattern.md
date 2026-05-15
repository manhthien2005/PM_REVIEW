# ADR-023: Mobile Streaming Pattern — FCM Push + REST Polling

**Status:** � Approved (Redesign 2026-05-15)
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [mobile, streaming, fcm, polling, ux, battery]
**Resolves:** Charter section 3.2 streaming pattern + OQ3 (hybrid takeover) + OQ4 (linked profile)

## Context

Charter section 3.2 đã chốt streaming pattern sau khi research production wearable. Phase 2 target topology section 5 detail. ADR này document chính thức decision.

**Production wearable pattern (researched 2026-05-15):**
- Apple Watch HealthKit: `HKObserverQuery` (observer) + `HKAnchoredObjectQuery` (incremental) → APNS push
- Google Fit Wear OS: Sensors API + WorkManager → FCM push
- Fitbit: Webhooks server-to-server → REST app fetch
- Garmin: Batch sync mỗi vài phút → notification

**Common: NONE use WebSocket persistent cho patient mobile app.**

**Forces:**
- Mobile elderly app phải tiết kiệm pin (OS suspend background)
- Critical alerts (fall) phải push <2s
- Vitals chart update khi user mở Health Monitoring screen → cần realtime feel
- Demo dramatic: panel chấm thấy alert lan tỏa từ smartwatch → BE → 2 phone <2s
- OQ4 linked profile demo: FCM fanout patient + caregivers

**Constraints:**
- iOS suspend WebSocket sau 30s background
- Android Doze mode + battery optimization kill persistent connection
- FCM rate limit 1000/sec per project (đủ cho đồ án)
- Polling interval trade-off: 1s impressive demo / 3s production-realistic / 5-10s industry standard

**References:**
- Charter section 3.2
- Phase 2 topology section 5
- Contract `alert_push.md` (FCM payload spec)
- OQ3 (hybrid full-screen takeover)
- OQ4 (linked profile fanout)
- Bug research links (CodeByte, Zigpoll, Wear OS docs)

## Decision

**Chose:** Option A — Hybrid: FCM critical push (data-only) + REST polling per active screen + WebSocket cho admin/sim FE only.

**Why:**
1. **Production-realistic** — match Apple/Google/Fitbit/Garmin
2. **Battery-friendly** — no persistent socket, polling auto-dispose
3. **Critical events fast** — FCM <2s, OS-level
4. **Demo dramatic** — full-screen takeover impressive
5. **WebSocket cho admin/sim** — operator dashboard có lý do (browser persistent)

## Options considered

### Option A (CHOSEN): Hybrid FCM + polling + admin WebSocket

**Description:**

**Mobile app patterns per surface:**

| Surface | Transport | Detail |
|---|---|---|
| Critical alerts (fall, vitals critical) | FCM data-only | `fullScreenIntent: true` cho fall, sound critical |
| Vitals chart (Health Monitoring screen) | REST polling 2-3s `.autoDispose` | Active screen only, off khi exit |
| Home Dashboard | REST polling 5s `.autoDispose` | Active screen |
| Family Linked Dashboard | REST polling 5s `.autoDispose` | Active screen |
| Risk Report List/Detail | On-demand fetch + manual refresh | Less frequent update |
| Sleep Report | On-demand fetch + manual refresh | Data đã batch |
| Notifications | FCM-driven + refresh on open | OS wake app |
| SOS Confirm | FCM-driven, full-screen | Critical |

**Admin web pattern:**
- WebSocket `/ws/admin/realtime` cho ops dashboard (multiple device monitoring)
- Exponential backoff reconnect (1s → 16s max)

**Simulator-web FE pattern:**
- WebSocket `/ws/logs/{session_id}` (existing) — device log
- WebSocket `/ws/flow/{session_id}` (NEW per ADR-024) — flow events sequence diagram

**Pros:**
- Match production wearable
- Battery-friendly mobile
- Critical events fast (<2s FCM)
- Demo flow dramatic
- Each pattern serves clear purpose

**Cons:**
- 3 patterns to maintain (FCM, polling, WebSocket)
- Polling rate cần tuning (2-3s sweet spot)

**Effort:** L (~10-12h spread over Phase 7):
- 2h: FCM payload structure (Phase 7 slice 1)
- 2h: Mobile FE polling Riverpod patterns
- 3h: Mobile FE FCM handler + full-screen Activity
- 2h: AndroidManifest permissions + iOS APNS config
- 1h: Admin web WebSocket consumer (limited scope)
- 2h: E2E test 2 device fanout

### Option B (rejected): WebSocket everywhere

**Description:** Mobile + Admin + Sim đều dùng WebSocket cho mọi data.

**Pros:**
- 1 pattern
- Persistent connection elegant

**Cons:**
- iOS/Android kill background socket
- Battery drain
- Not production-pattern wearable
- Charter Q3 đã reject

**Why rejected:** Charter Q3 anti-pattern.

### Option C (rejected): Polling everywhere

**Description:** Drop FCM, mobile polls /alerts every 5s.

**Pros:**
- 1 pattern simple

**Cons:**
- Critical alert <2s impossible
- Background polling = battery + data overhead
- Fall takeover impossible (need OS wake)

**Why rejected:** Critical UX requirement fails.

### Option D (rejected): SSE for mobile

**Description:** Server-Sent Events 1-way streaming.

**Pros:**
- Lightweight than WebSocket
- 1-way fits server-push pattern

**Cons:**
- iOS không native support
- Android cần third-party library
- Same background suspend issue as WebSocket

**Why rejected:** Mobile SSE support poor (research confirmed).

## Consequences

### Positive
- Production-equivalent mobile UX
- Battery-friendly
- Critical alert <2s via FCM
- Demo dramatic
- OQ3 hybrid takeover achievable
- OQ4 linked fanout natural

### Negative / Trade-offs accepted
- 3 patterns to learn/maintain
- FCM Firebase dependency (already have)
- Polling interval cần tuning per screen

### Follow-up actions required
- [ ] Phase 7: FCM payload structure per ADR-018 + alert_push contract
- [ ] Phase 7: Mobile Riverpod polling patterns (autoDispose)
- [ ] Phase 7: FCM handler Flutter (data-only message parsing)
- [ ] Phase 7: AndroidManifest USE_FULL_SCREEN_INTENT + showWhenLocked Activity
- [ ] Phase 7: iOS critical alert entitlement (dev mode)
- [ ] Phase 7: Real device runbook update (test 2 phones FCM fanout)
- [ ] Phase 7: Admin web WebSocket realtime (optional, limited scope)

## Reverse decision triggers

- Nếu FCM unreliable trên emulator demo → fallback polling 1s temporary
- Nếu battery drain testing fail → consider polling cao hơn 5s
- Nếu Critical alert FCM ETA >5s consistently → investigate FCM project priority

## Related

- Charter section 3.2 (decisions)
- Phase 2 target topology section 5
- Contract `alert_push.md` (FCM payload)
- ADR-018 (validation contract — alert source of truth)
- OQ3, OQ4

## Notes

### Polling tuning per screen (configurable via env)

```dart
class PollingConfig {
  static Duration get vitalsTimeseries => 
      Duration(seconds: int.parse(dotenv.env['POLL_VITALS_SEC'] ?? '3'));
  
  static Duration get homeDashboard => 
      Duration(seconds: int.parse(dotenv.env['POLL_HOME_SEC'] ?? '5'));
  
  static Duration get familyDashboard => 
      Duration(seconds: int.parse(dotenv.env['POLL_FAMILY_SEC'] ?? '5'));
}

// Demo mode override
class DemoModeOverride {
  static bool get enabled => dotenv.env['DEMO_MODE'] == 'true';
  
  static Duration get vitalsTimeseries =>
      enabled ? Duration(seconds: 1) : PollingConfig.vitalsTimeseries;
}
```

### FCM channel structure (Android)

```kotlin
// MainActivity.kt or NotificationChannelManager
val fallCriticalChannel = NotificationChannel(
    "fall_critical_channel",
    "Cảnh báo té ngã",
    NotificationManager.IMPORTANCE_MAX
).apply {
    description = "Cảnh báo té ngã cần phản ứng ngay"
    setBypassDnd(true)
    enableVibration(true)
    setVibrationPattern(longArrayOf(0, 1000, 500, 1000))
    setSound(
        Uri.parse("android.resource://$packageName/raw/alarm"),
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .build()
    )
}

val vitalsWarningChannel = NotificationChannel(
    "vitals_warning_channel",
    "Cảnh báo sức khỏe",
    NotificationManager.IMPORTANCE_HIGH
)

val infoChannel = NotificationChannel(
    "info_channel",
    "Thông báo",
    NotificationManager.IMPORTANCE_DEFAULT
)
```

### Test plan FCM fanout

```python
# tests/e2e/test_fcm_linked_profile_fanout.py
def test_fall_critical_dispatches_to_patient_and_caregivers(
    elderly_device, family_phone, elderly_phone, mock_fcm
):
    # Setup
    patient_id = elderly_device.user.id
    caregiver_id = family_phone.user.id
    create_linked_relationship(patient_id, caregiver_id)
    register_push_token(patient_id, elderly_phone.fcm_token)
    register_push_token(caregiver_id, family_phone.fcm_token)
    
    # Trigger fall
    runtime.apply_scenario("fall_high_confidence", device_id=elderly_device.id)
    
    # Wait for FCM dispatch
    wait_for_fcm_message(timeout=5)
    
    messages = mock_fcm.get_messages()
    assert len(messages) == 2
    
    patient_msg = next(m for m in messages if m["token"] == elderly_phone.fcm_token)
    assert patient_msg["data"]["fullScreenIntent"] == "true"
    assert patient_msg["data"]["click_action"] == "OPEN_SOS_CONFIRM"
    
    family_msg = next(m for m in messages if m["token"] == family_phone.fcm_token)
    assert family_msg["data"]["fullScreenIntent"] == "false"
    assert family_msg["data"]["click_action"] == "OPEN_NOTIFICATION_LIST"
```
