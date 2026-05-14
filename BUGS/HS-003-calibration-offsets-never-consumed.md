# Bug HS-003: Device calibration offsets never consumed (dead write-only data)

**Status:** 🔴 Open
**Repo(s):** health_system (mobile BE + FE), cross-repo impact Iot_Simulator_clean
**Module:** device
**Severity:** Medium
**Reporter:** ThienPDM (self) via Phase 0.5 DEVICE deep-dive
**Created:** 2026-05-13
**Resolved:** —

## Symptom

3 field trong `DeviceSettingsRequest` (Pydantic) + `devices.calibration_data` (JSONB) được user set qua `PUT /mobile/devices/:id/settings` nhưng KHÔNG có service / consumer nào đọc ra để áp dụng:

- `heart_rate_offset` (integer, -50..50 BPM)
- `spo2_calibration` (float, 0.8..1.2 multiplier)
- `temperature_offset` (float, -5..5 độ C)

Cross-repo grep kết quả:
- `Iot_Simulator_clean/**` cho pattern `calibration` — 0 match. IoT sim sinh vitals không consume calibration config.
- `health_system/backend/app/services/monitoring_service.py` — 0 match `heart_rate_offset|spo2_calibration|temperature_offset`.
- `health_system/backend/app/services/notification_service.py` — 0 match tương tự.
- `HealthGuard/backend/**` — 0 match.

Nghĩa là user save offset, lưu DB thành công, không bao giờ ảnh hưởng đến vitals, alerts, hoặc UI.

Đối chiếu với 3 notification toggle trong cùng JSONB (`notify_high_hr`, `notify_low_spo2`, `notify_high_bp`): FE seed vào toggle UI nên user thấy state giữ lại đúng, nhưng notification_service Phase 4+ vẫn cần consume các flag này trước khi push alert (currently: push không check flag, user tắt toggle vẫn nhận alert).

Related: FE attention heuristic `_deviceNeedsAttention` có bug edge case — device vừa pair xong chưa có vitals telemetry đầu tiên có `last_sync_at = NULL`, khiến FE trigger attention zone sai ngay cho device mới hoàn toàn. Tracked như sub-task 3 (Low severity) để Phase 4 dọn chung với notification service consume.

## Repro steps

### Repro A: Offset không apply

1. User pair device qua BLE.
2. Mở DeviceConfigureScreen, set `heart_rate_offset = 10` (Phase 4, sau khi FE expose field — hiện tại FE chỉ expose 3 notify toggles).
3. Save. BE lưu `calibration_data = {"heart_rate_offset": 10, ...}` vào DB.
4. IoT sim sinh vital record với heart_rate = 70 BPM.
5. API `GET /mobile/monitoring/latest` trả `heart_rate = 70`.

**Expected (per old UC041):** heart_rate trả về = 70 + 10 = 80 BPM (offset applied).
**Actual:** heart_rate = 70 BPM (offset ignored).

### Repro B: Notify toggle bypass

1. User set `notify_high_hr = false` (muốn tắt cảnh báo nhịp tim cao).
2. IoT sim generate vital với heart_rate = 150 BPM (ngưỡng high).
3. Monitoring service detect abnormal, trigger alert, push notification.

**Expected:** Notification skip vì user đã tắt `notify_high_hr`.
**Actual:** Notification vẫn push (service không check calibration_data flag).

### Repro C: FE attention zone trigger sai cho device mới pair

1. User pair device, row created với `last_sync_at = NULL` (trước khi có vitals ingest đầu tiên).
2. Mở DeviceScreen ngay sau pair.
3. FE `_deviceNeedsAttention(device)` evaluate: `is_active=true && lastSyncAt=null` trả TRUE.
4. Device mới pair hoàn toàn bị đẩy lên attention zone với message gây hiểu lầm.

**Expected:** Device mới pair không nên trong attention zone ít nhất 1 giờ đầu (grace period).
**Actual:** Attention trigger ngay từ lúc pair xong.

**Self-correction note (2026-05-13):** Claim ban đầu "`last_sync_at` dead column" là SAI. Grep verify lại workspace-wide trong session INGESTION:
- `telemetry.py:287-291` CÓ `UPDATE devices SET last_sync_at = NOW()` sau vitals ingest batch.
- `Iot_Simulator_clean/api_server/dependencies.py:1046-1050` CÓ UPDATE trong direct-DB path (ADR-013).

`last_sync_at` được populate đúng cách khi device nhận vitals. Bug thực là FE heuristic edge case, không phải schema dead.

**Repro rate:** 100%.

## Environment

- Affected files:
  - Schema: `health_system/backend/app/schemas/device.py` (3 offset fields)
  - Service: `health_system/backend/app/services/device_service.py` (`update_device_settings`, dict build)
  - Missing consumer: `health_system/backend/app/services/monitoring_service.py`, `notification_service.py`
  - IoT sim: `Iot_Simulator_clean/api_server/` (no calibration read)
  - FE attention: `health_system/lib/features/device/providers/device_provider.dart` (`_deviceNeedsAttention`)

## Logs / Stack trace

Không có error log — bug là "silent noop", user tưởng config work.

## Investigation

### Hypothesis log

| #  | Hypothesis                                                                      | Status      |
| -- | ------------------------------------------------------------------------------- | ----------- |
| H1 | 3 offset fields là tái tạo từ UC cũ spec, chưa implement consumer               | ✅ Confirmed |
| H2 | 3 notify toggle có FE seed nhưng BE service chưa check                          | ✅ Confirmed |
| H3 | FE `_deviceNeedsAttention` heuristic bug edge case với device mới pair (last_sync_at NULL before first telemetry) | ✅ Confirmed (self-correction 2026-05-13, initial claim "dead column" sai) |

### Attempts

Chưa có — bug mới phát hiện Phase 0.5.

---

## Resolution

_(Fill in when resolved Phase 4)_

**Fix approach chia 3 sub-task:**

### Sub-task 1: Drop 3 offset field (theo ADR-012)

- Remove `heart_rate_offset`, `spo2_calibration`, `temperature_offset` khỏi `DeviceSettingsRequest`.
- Remove 3 keys khỏi `calibration_data` JSONB build trong `update_device_settings`.
- Cleanup script (optional): purge 3 key khỏi existing rows.
- Test: POST `/mobile/devices/:id/settings` với 3 field — expect 422 (Pydantic reject unknown field hoặc validator ignore).

### Sub-task 2: Notification service respect 3 toggle flag

Notification service hoặc alert pipeline phải check `calibration_data.notify_high_hr/low_spo2/high_bp` trước khi push. Implementation (pseudo-code Phase 4):
```python
def should_push_alert(device_id, alert_type, db):
    device = db.query(Device).get(device_id)
    flags = device.calibration_data or {}
    if alert_type == "high_hr" and not flags.get("notify_high_hr", True):
        return False
    if alert_type == "low_spo2" and not flags.get("notify_low_spo2", True):
        return False
    if alert_type == "high_bp" and not flags.get("notify_high_bp", True):
        return False
    return True
```

Test: `tests/test_notification_service.py::test_push_skipped_when_notify_high_hr_false`.

### Sub-task 3: Fix FE `_deviceNeedsAttention` grace period cho device mới pair (severity Low, self-corrected)

**Self-correction context (2026-05-13):** Initial claim "dead column" SAI. `last_sync_at` được update bởi `telemetry.py:287-291` + IoT sim direct-DB path (ADR-013). Bug thực là FE heuristic edge case.

**Fix:** Update FE `_deviceNeedsAttention(device)` trong `health_system/lib/features/device/providers/device_provider.dart`:

```dart
bool _deviceNeedsAttention(DeviceModel device) {
  // Low battery, always trigger
  final batteryLevel = device.batteryLevel;
  if (batteryLevel != null && batteryLevel <= 20) return true;

  // Grace period: skip attention for newly paired devices (< 1h from registered_at)
  // vì last_sync_at = NULL là expected cho device chưa nhận vitals đầu tiên
  final registered = device.registeredAt;
  if (registered != null &&
      DateTime.now().difference(registered).inHours < 1) {
    return false;
  }

  // Rest of heuristic (> 24h offline, no sync on active device)
  final lastSyncAt = device.lastSyncAt;
  if (device.isActive && lastSyncAt == null) return true;
  if (lastSyncAt != null &&
      DateTime.now().difference(lastSyncAt).inHours >= 24) return true;

  return false;
}
```

Test: `test/features/device/providers/device_provider_test.dart::test_new_paired_device_not_in_attention_zone`.

**Effort:** ~15min Phase 4 (FE-only change, không cần DB migration vì `last_sync_at` đã OK).

**KHÔNG cần:** Drop `last_sync_at` column, không cần populate hook nào (đã có trong ingest path).

## Related

- UC: UC041 v2 (BR-041-04 drop sensor offsets), UC042 v2 (BR-042-03 attention zone heuristic)
- JIRA: _(chưa có)_
- Linked bug: —
- ADR: **ADR-012** (drop calibration offsets)
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md` (section A2.3, B.2, B.5)

## Notes

Phase 4 triển khai theo thứ tự:
1. Sub-task 1 (drop schema) trước vì simpler, unblock Phase 4 backlog.
2. Sub-task 2 (notification consume) sau vì cần hiểu sâu notification pipeline.
3. Sub-task 3 (FE grace period) parallel với 1 — FE-only change, ~15min, không depend DB.
