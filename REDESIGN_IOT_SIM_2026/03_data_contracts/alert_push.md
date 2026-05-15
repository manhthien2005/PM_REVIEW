# Contract — Alert Push (Telemetry Alert + FCM Payload)

> **Endpoints:**  
> - `POST /api/v1/mobile/telemetry/alert` (IoT sim → Mobile BE)  
> - FCM data message (Mobile BE → Mobile app via Firebase)  
>  
> **Producer:** IoT simulator (rule-engine triggered) + Mobile BE (auto from telemetry)  
> **Consumer:** Mobile BE (persist + fanout) + Mobile app (render banner / full-screen takeover)  
> **Critical changes:** Hybrid full-screen takeover (OQ3), linked profile fanout (OQ4)

---

## Part A — Telemetry Alert (IoT sim → Mobile BE)

### A.1 Headers

```http
POST /api/v1/mobile/telemetry/alert HTTP/1.1
Host: localhost:8000
Content-Type: application/json
X-Internal-Service: iot-simulator
Idempotency-Key: <uuid-v4>
```

### A.2 Request body

```typescript
interface AlertIngestRequest {
  db_device_id: number;
  user_id: number | null;        // resolved from device.user_id if null
  event_type: AlertEventType;
  severity: AlertSeverity;
  timestamp: string;             // ISO 8601 UTC
  metadata: AlertMetadata;
}

type AlertEventType = 
  | "vitals_out_of_range"        // HR/SpO2/BP threshold breach
  | "sleep_apnea_suspected"      // SpO2 < 88% during sleep
  | "respiratory_arrest_risk"    // RR < 8 during sleep
  | "nocturnal_tachycardia"      // HR > 100 during sleep
  | "fall_detected"              // From IMU window flow (DEPRECATED — use /imu-window)
  | "device_offline"             // Heartbeat missing
  | "battery_low";               // < 15%

type AlertSeverity = "critical" | "high" | "medium" | "low";

interface AlertMetadata {
  source: "tick" | "rule_engine" | "manual";
  timestamp: string;
  scenario_id?: string;          // sim scenario nếu có
  
  // Vitals fields (nếu event_type = vitals_out_of_range)
  heart_rate?: number;
  spo2?: number;
  temperature?: number;
  blood_pressure_sys?: number;
  blood_pressure_dia?: number;
  respiratory_rate?: number;
  
  // Context fields
  sleep_context?: boolean;       // "true" if alert during sleep
  activity_label?: string;
  priority?: "low" | "medium" | "high" | "critical";
  message?: string;              // VI/EN human-readable
}
```

### A.3 Severity → action mapping

| Severity | DB persist | FCM action | Mobile UX |
|---|---|---|---|
| `critical` | `alerts` + `sos_events` (if fall) | data-only + fullScreenIntent | SOSConfirmScreen takeover + ring |
| `high` | `alerts` | data + notification | Banner + sound + vibrate |
| `medium` | `alerts` | notification | Banner only |
| `low` | `alerts` | none (notification center only) | List item only |

### A.4 Example payload — vitals critical

```json
{
  "db_device_id": 42,
  "user_id": 7,
  "event_type": "vitals_out_of_range",
  "severity": "critical",
  "timestamp": "2026-05-15T22:30:00.000Z",
  "metadata": {
    "source": "tick",
    "heart_rate": 145,
    "spo2": 86,
    "activity_label": "resting",
    "scenario_id": "hypoxia_critical",
    "priority": "critical",
    "message": "SpO2 86% — nguy cơ thiếu oxy"
  }
}
```

### A.5 Example payload — sleep apnea

```json
{
  "db_device_id": 42,
  "user_id": 7,
  "event_type": "sleep_apnea_suspected",
  "severity": "critical",
  "timestamp": "2026-05-15T03:15:00.000Z",
  "metadata": {
    "source": "tick",
    "spo2": 85,
    "sleep_context": true,
    "scenario_id": "sleep_apnea_severe",
    "priority": "critical",
    "message": "SpO2 < 88% khi ngủ — nghi ngờ ngưng thở"
  }
}
```

### A.6 Response

```typescript
interface AlertIngestResponse {
  alert_id: number;
  fall_event_id?: number;        // if event_type = fall_detected
  sos_event_id?: number;         // if SOS triggered
  fcm_dispatched: boolean;
  recipients: number;             // count of FCM tokens reached
}
```

---

## Part B — FCM Data Message (Mobile BE → Mobile app)

### B.1 FCM message structure

Mobile BE dùng `firebase-admin` SDK push **data-only message** (NOT notification message) để:
- Control hoàn toàn render trên client
- Bypass system notification on iOS critical alerts
- Full-screen intent trên Android

```json
{
  "message": {
    "token": "<recipient_fcm_token>",
    "data": {
      "type": "fall_sos",
      "severity": "critical",
      "alert_id": "1234",
      "fall_event_id": "512",
      "sos_event_id": "256",
      "patient_user_id": "7",
      "patient_name": "Bố Nguyễn Văn A",
      "is_recipient_patient": "true",
      "confidence": "0.95",
      "timestamp": "2026-05-15T22:30:00.000Z",
      "vitals_snapshot": "{\"heart_rate\":145,\"spo2\":86}",
      "click_action": "OPEN_SOS_CONFIRM",
      "fullScreenIntent": "true",
      "channel_id": "fall_critical_channel"
    },
    "android": {
      "priority": "high",
      "ttl": "30s"
    },
    "apns": {
      "headers": {
        "apns-priority": "10",
        "apns-push-type": "alert"
      },
      "payload": {
        "aps": {
          "content-available": 1,
          "interruption-level": "critical",
          "sound": {
            "critical": 1,
            "name": "alarm.caf",
            "volume": 1.0
          }
        }
      }
    }
  }
}
```

### B.2 Data field schema (full vocabulary)

| Field | Type | Purpose | Required |
|---|---|---|---|
| `type` | enum | Event type discriminator | ✅ |
| `severity` | enum | `critical`, `high`, `medium`, `low` | ✅ |
| `alert_id` | string | FK alerts.id | ✅ |
| `fall_event_id` | string | FK fall_events.id (if fall) | Optional |
| `sos_event_id` | string | FK sos_events.id (if SOS) | Optional |
| `risk_score_id` | string | FK risk_scores.id (if risk alert) | Optional |
| `patient_user_id` | string | User who experienced event | ✅ |
| `patient_name` | string | Vietnamese display name | ✅ |
| `is_recipient_patient` | string | "true" if recipient = patient, "false" if caregiver | ✅ |
| `confidence` | string | Model confidence 0-1 (if fall) | Optional |
| `timestamp` | string | ISO 8601 UTC event time | ✅ |
| `vitals_snapshot` | string | JSON-stringified vitals at event time | Optional |
| `click_action` | enum | Route hint: `OPEN_SOS_CONFIRM`, `OPEN_RISK_REPORT`, `OPEN_VITALS_DETAIL`, `OPEN_NOTIFICATION_LIST` | ✅ |
| `fullScreenIntent` | string | "true" if Android full-screen takeover required | Conditional |
| `channel_id` | string | Android notification channel | ✅ |

### B.3 Severity → UI behavior matrix

| Severity | type | is_recipient_patient | UI Action |
|---|---|---|---|
| critical | fall_sos | true | **SOSConfirmScreen takeover** + countdown 30s + ring `alarm.caf` |
| critical | fall_sos | false | Banner notification "Bố/mẹ té ngã — tap để gọi" + sound critical |
| critical | sleep_apnea_suspected | true | Banner + sound + vibrate, route to RiskReportDetail |
| critical | sleep_apnea_suspected | false | Notification only |
| critical | vitals_critical | true | Banner + route VitalsDetail screen |
| critical | vitals_critical | false | Notification banner family |
| high | vitals_warning | * | Notification banner |
| medium | health_advice | * | Notification only (no sound) |
| low | info | * | List item only |

### B.4 Fanout logic (OQ4 linked profile)

Mobile BE code path khi receive alert:

```python
# health_system/backend/app/services/push_notification_service.py:417 (existing)
def send_fall_critical_alert(db, patient_user_id, fall_event_id, confidence):
    # 1. Determine recipients
    recipients = EmergencyRepository.get_alert_recipient_user_ids(
        db, patient_user_id=patient_user_id
    )
    # recipients = [patient_user_id] + [caregiver_user_ids from UserRelationship]
    
    # 2. Fetch active FCM tokens
    tokens = UserPushToken.query.filter(
        UserPushToken.user_id.in_(recipients),
        UserPushToken.is_active == True
    ).all()
    
    # 3. Build per-recipient payload
    for token in tokens:
        is_patient = (token.user_id == patient_user_id)
        payload = build_fcm_payload(
            type="fall_sos",
            severity="critical",
            alert_id=alert_id,
            fall_event_id=fall_event_id,
            patient_user_id=patient_user_id,
            patient_name=fetch_user_name(patient_user_id),
            is_recipient_patient=str(is_patient).lower(),
            confidence=str(confidence),
            full_screen_intent=str(is_patient).lower(),  # only patient gets takeover
            click_action="OPEN_SOS_CONFIRM" if is_patient else "OPEN_NOTIFICATION_LIST",
        )
        firebase_admin.messaging.send(payload)
```

### B.5 Mobile app handler (Phase 7 implement Flutter)

```dart
// health_system/lib/features/notifications/services/fcm_handler.dart
class FcmHandler {
  Future<void> onMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final severity = data['severity'];
    final isPatient = data['is_recipient_patient'] == 'true';
    
    if (type == 'fall_sos' && severity == 'critical') {
      if (isPatient) {
        // Patient receives → full-screen takeover
        await _showFullScreenSos(data);
      } else {
        // Caregiver receives → banner
        await _showCriticalBanner(data, sound: true);
      }
    } else if (severity == 'critical') {
      await _showCriticalBanner(data, sound: true);
    } else if (severity == 'high') {
      await _showRegularNotification(data, sound: true);
    } else {
      await _showRegularNotification(data, sound: false);
    }
  }
  
  Future<void> _showFullScreenSos(Map<String, dynamic> data) async {
    await _localNotifications.show(
      data['alert_id'].hashCode,
      'Phát hiện té ngã',
      'Bạn có cần trợ giúp khẩn cấp không?',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fall_critical_channel',
          'Cảnh báo té ngã',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound('alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: 'alarm.caf',
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: jsonEncode(data),
    );
    // Route to SOSConfirmScreen via NavigationService
    _navigatorKey.currentState?.pushNamed(
      '/sos/confirm',
      arguments: data,
    );
  }
}
```

### B.6 Android setup (Phase 7)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<activity 
    android:name=".SOSConfirmActivity"
    android:showWhenLocked="true"
    android:turnScreenOn="true"
    android:launchMode="singleTask"
    android:taskAffinity="" />

<!-- Notification channels (registered programmatically Phase 7) -->
<!-- fall_critical_channel: IMPORTANCE_MAX, bypass DND -->
<!-- vitals_warning_channel: IMPORTANCE_HIGH -->
<!-- info_channel: IMPORTANCE_DEFAULT -->
```

### B.7 iOS setup (Phase 7)

```swift
// ios/Runner/AppDelegate.swift — entitlements
// Need: com.apple.developer.usernotifications.critical-alerts
// → Apple developer approval required for production
// → Dev mode: works with TestFlight + development entitlement
```

---

## Part C — Backward compatibility

- Endpoint `/telemetry/alert` đã có → chỉ extend schema (add `priority`, `message`, `vitals_snapshot`)
- Existing IoT sim caller (`AlertService._push_alert_to_backend`) → cần migrate prefix `/mobile/*` → `/api/v1/mobile/*`
- FCM payload structure → **breaking change** for mobile app handler. Phase 7 deploy mobile + BE đồng thời.

---

## Part D — Test cases (Phase 6)

```python
# Contract test
def test_alert_critical_dispatches_fcm_to_patient_and_caregivers():
    # Setup: elderly + 2 family caregivers linked
    setup_linked_profile(patient_id=7, caregiver_ids=[8, 9])
    setup_push_tokens([7, 8, 9])
    
    payload = build_alert_payload(severity="critical", event_type="fall_detected")
    response = client.post("/api/v1/mobile/telemetry/alert", json=payload)
    
    fcm_messages = mock_fcm.get_messages()
    assert len(fcm_messages) == 3  # patient + 2 caregivers
    
    patient_msg = next(m for m in fcm_messages if m["data"]["is_recipient_patient"] == "true")
    assert patient_msg["data"]["fullScreenIntent"] == "true"
    assert patient_msg["data"]["click_action"] == "OPEN_SOS_CONFIRM"
    
    caregiver_msgs = [m for m in fcm_messages if m["data"]["is_recipient_patient"] == "false"]
    assert all(m["data"]["fullScreenIntent"] == "false" for m in caregiver_msgs)

def test_alert_low_no_fcm():
    payload = build_alert_payload(severity="low", event_type="battery_low")
    response = client.post(...)
    assert response.json()["fcm_dispatched"] is False
```

---

## Part E — Related

- ADR-023: Mobile streaming pattern (FCM)
- OQ3: Hybrid full-screen takeover
- OQ4: 2 mobile device linked profile demo
- `flutter_local_notifications` package — Flutter pub
- `firebase_messaging` package — Flutter FCM consumer
- File `health_system/lib/features/notifications/services/fcm_handler.dart` (to extend)
- File `health_system/lib/features/emergency/screens/sos_confirm_screen.dart` (target Activity)
