# ADR-012: Drop calibration offset fields khỏi device schema + UC041

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [scope, schema, health_system, mobile, dead-code, graduation-project]

## Context

Phase 0.5 deep-dive DEVICE module phát hiện `DeviceSettingsRequest` (Pydantic schema) + `calibration_data` (JSONB trên `devices` table) đang chứa 3 field sensor calibration offset:

- `heart_rate_offset: int | None = Field(default=None, ge=-50, le=50)` (BPM)
- `spo2_calibration: float | None = Field(default=None, ge=0.8, le=1.2)` (multiplier)
- `temperature_offset: float | None = Field(default=None, ge=-5.0, le=5.0)` (độ C)

User có thể set các field này qua `PUT /mobile/devices/:id/settings` và chúng được lưu vào `devices.calibration_data` JSONB.

Grep cross-repo:
- `Iot_Simulator_clean/**` cho `calibration` trả 0 match. IoT sim sinh vitals không đọc `calibration_data`.
- `health_system/backend/app/services/monitoring_service.py` + `notification_service.py` grep `heart_rate_offset|spo2_calibration|temperature_offset` trả 0 match.
- `HealthGuard/backend/**` cho 3 field này trả 0 match.

Nghĩa là user lưu offset vào DB nhưng không service/consumer nào đọc ra để áp dụng. Dead write-only data.

Đối chiếu với 4 field khác trong cùng JSONB:
- `notify_high_hr`, `notify_low_spo2`, `notify_high_bp`: FE đã seed vào DeviceConfigureScreen toggle UI, có use case rõ (dù notification service Phase 4 vẫn cần consume — xem HS-003).
- `wear_side`: thuần UI preference, không cần consumer.

Constraints:
- Đồ án 2 scope: IoT sim + mobile không có firmware-level sensor integration. Sensor offsets không áp dụng được vì BE không push config xuống device thật.
- Real sensor calibration (ví dụ FDA device y tế) là Phase 5+ work, cần device SDK + OTA update channel.
- Giữ field dead trong schema gây misleading UX (user nghĩ "đã set offset, sensor sẽ đúng hơn").

## Decision

**Chose:** Drop 3 offset field khỏi `DeviceSettingsRequest` + `calibration_data` payload builder. Giữ 3 notify toggle + wear_side.

**Why:**

1. Dead write-only data: 3 field lưu DB nhưng không consumer — misleading user.
2. YAGNI: Sensor calibration thực tế cần firmware channel + OTA + device SDK, hoàn toàn out of scope đồ án 2.
3. Schema đơn giản hơn — ít code duplicate validation ranges (ge/le), ít FE code seed state, ít test case.

## Options considered

### Option A (chosen): Drop 3 offset field, giữ 3 toggle + wear_side

**Description:**
- Pydantic `DeviceSettingsRequest`: remove `heart_rate_offset`, `spo2_calibration`, `temperature_offset` fields.
- `device_service.update_device_settings`: remove 3 keys khỏi `calibration_data` JSONB build.
- UC041 v2: drop BR-041 mention sensor calibration.
- Schema migration: `calibration_data` JSONB flexibility nên không cần DB migration, chỉ cần không ghi 3 key nữa (old rows vẫn giữ key đó, nhưng ignore).

**Pros:**
- Ship ngay với code change nhỏ (~30min).
- Schema honest với actual capability của hệ thống.
- Less surface area cho regression bug.

**Cons:**
- Breaking change nhỏ cho client nào đang gửi 3 field — Pydantic sẽ reject (422). Mitigation: FE hiện không gửi các field này (check `device_configure_provider.dart` chỉ gửi `notify_*`, không có offset), nên effect = 0 cho mobile FE hiện tại.

**Effort:** S (~30min Phase 4).

### Option B (rejected): Implement consumer — IoT sim + monitoring service đọc offset

**Description:**
- IoT sim load `calibration_data` khi sinh vitals, apply offset.
- monitoring_service normalize vitals trước khi trigger alert.

**Pros:**
- Keep UC041 cũ exactly.

**Cons:**
- +3h effort mà không cải thiện gì cho demo đồ án 2 (IoT sim sinh data random, offset không có nghĩa).
- Add dependency: IoT sim phải poll DB để lấy calibration, phức tạp.

**Why rejected:** Over-engineering cho đồ án 2, scope drift.

### Option C (rejected): Keep fields dead + document "not implemented"

**Description:** Không đổi schema, thêm comment "dead, Phase 5+".

**Pros:**
- 0 code change.

**Cons:**
- Dead code in production schema.
- User vẫn có thể set field, misleading UX.
- Phase 4 test case phải cover dead field, waste.

**Why rejected:** Anti-pattern — keep schema honest, drop dead code.

---

## Consequences

### Positive

- `DeviceSettingsRequest` simpler, FE form smaller.
- UC041 alignment với actual capability.
- Test surface giảm (không cần test validator range của 3 field).

### Negative / Trade-offs accepted

- Phase 5+ nếu implement real calibration, phải revert add fields back + schema evolve.
- Existing DB rows có 3 key trong `calibration_data` JSONB không auto-cleanup. Chấp nhận: dead keys in JSONB không gây hại runtime (không ai đọc).

### Follow-up actions required

- [ ] Phase 4: Update `health_system/backend/app/schemas/device.py` — remove 3 offset fields từ `DeviceSettingsRequest`.
- [ ] Phase 4: Update `health_system/backend/app/services/device_service.py` `update_device_settings` — remove 3 keys từ `calibration_data` dict build.
- [ ] Phase 4: Update test `health_system/backend/tests/` nếu có test touch 3 field.
- [ ] Cleanup script (optional): purge 3 key khỏi existing JSONB rows via `UPDATE devices SET calibration_data = calibration_data - 'heart_rate_offset' - 'spo2_calibration' - 'temperature_offset' WHERE ...`. Chạy thủ công, không auto migration.

## Reverse decision triggers

- Nếu Phase 5+ integrate real device SDK cho calibration, revert + implement consumer.
- Nếu có compliance requirement (medical device regulation) yêu cầu user-facing sensor calibration, revert.

## Related

- UC: UC041 v2 (BR-041-04 drop sensor offsets)
- ADR: —
- Bug: triggered by **HS-003** (calibration offsets never consumed)
- Code: to-be-updated `health_system/backend/app/schemas/device.py`, `health_system/backend/app/services/device_service.py`
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md`

## Notes

`wear_side` giữ lại vì thuần UI preference (left/right) không đòi hỏi consumer. Notify toggles giữ lại vì notification service Phase 4 sẽ consume (xem HS-003 follow-up).
