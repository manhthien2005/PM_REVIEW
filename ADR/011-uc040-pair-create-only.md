# ADR-011: UC040 Connect Device = pair-create only (drop pair-claim flow)

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [scope, uc, health_system, mobile, graduation-project]

## Context

Phase 0.5 deep-dive DEVICE module phát hiện UC040 cũ specify flow **pair-claim** (Main Flow step 2-4):
1. User nhập device code / QR scan
2. BE kiểm tra device tồn tại trong `devices` table
3. BE gán `user_id = current_user.id` cho device đã tồn tại

Nhưng code hiện tại implement **pair-create**:
- `POST /mobile/devices/scan/pair` luôn INSERT row mới vào `devices`.
- `POST /mobile/devices` cũng INSERT row mới.
- Không có endpoint nào nhận device_code để update `user_id` cho row đã tồn tại.
- Alt Flow 4.a "Thiết bị không tồn tại" và 4.b "Thiết bị đang gán cho user khác" không thể trigger được — endpoint luôn CREATE mới.

Admin flow (qua HealthGuard admin web `PATCH /api/v1/devices/:id/assign`) có tạo device `is_active=FALSE` chờ user claim, nhưng không có flow bên mobile để user claim device đó. Nói cách khác: 2 flow (admin provisioning và mobile self-service pair) đang disjoint trong code.

Constraints:
- Đồ án 2 scope: BLE scan đơn giản, không có physical QR sticker trên device thật, không có device stock backend.
- Flow admin provision device trước rồi user claim là over-engineering — chủ yếu cho SaaS B2B có kho device.
- Effort implement pair-claim properly: thêm endpoint + logic check ownership transfer + Alt flow + E2E test (~3h).

## Decision

**Chose:** UC040 v2 = pair-create only. User tự BLE scan + pair device, BE tạo row mới với `user_id = current_user.id`.

**Why:**

1. YAGNI cho đồ án 2: Không có use case business cho pair-claim trong demo scope. IoT sim + physical device prototype đều chưa tồn tại physical QR stock.
2. Match code hiện tại: UC phải trace được về code thật, không mô tả hypothetical flow chưa implement.
3. Admin provisioning flow vẫn orthogonal có ích (cho testing, IoT sim auto-provision), document như alternate flow BE ngoài scope user UC (BR-040-05).

## Options considered

### Option A (chosen): Pair-create only — rewrite UC040 v2

**Description:** UC040 Main Flow chỉ còn "BLE scan, tạo device mới với user_id = current_user.id". Drop Alt 4.a/4.b. Alt 7.a chỉ handle case MAC duplicate cross-user (khi có Phase 4 UNIQUE constraint).

**Pros:**
- 0h code work, 100% doc work.
- Match code hiện có, không lie cho stakeholder.
- UC040 v2 implementable + testable ngay.

**Cons:**
- Nếu Phase 5+ scale lên SaaS, cần revisit (admin stock + user claim flow).

**Effort:** S (~15min — UC rewrite).

### Option B (rejected): Pair-claim full — add `POST /devices/claim` endpoint

**Description:** Implement flow UC040 cũ. Add endpoint nhận `device_code`, verify tồn tại và chưa claim, update `user_id`. Update Alt 4.a/4.b logic.

**Pros:**
- Match UC cũ exactly.
- Future-proof cho SaaS scale.

**Cons:**
- +3h implementation cho flow không có user demand đồ án 2.
- Thêm complexity: cần device_code generation, admin panel để generate, flow chuyển quyền.
- YAGNI — solo dev không có budget.

**Why rejected:** Over-engineering cho đồ án 2. Nếu cần scale SaaS sau, revisit ADR này.

### Option C (rejected): Dual flow — keep both pair-create + pair-claim

**Description:** UC040 Main Flow = pair-create, Alt Flow thêm pair-claim cho case "user có device code từ admin".

**Pros:**
- Flexible.

**Cons:**
- Cùng lý do Option B reject cộng với: hai flow overlap làm confused actor lookup + ambiguous duplicate check logic.

**Why rejected:** Complexity không justified.

---

## Consequences

### Positive

- UC040 v2 shippable ngay, không cần wait code change.
- Phase 4 backlog không có task pair-claim endpoint.
- Admin provisioning vẫn tồn tại qua `AdminDeviceService` route `/mobile/admin/devices/*` — documented BR-040-05.

### Negative / Trade-offs accepted

- SaaS scale (nếu có Phase 5+) phải revisit: user chỉ claim được device admin đã tạo trước, không tự tạo.
- Admin provision device (user_id=NULL, is_active=FALSE) hiện tại không có cách user mobile claim — device orphan. Giải pháp tạm cho đồ án 2: admin assign device qua HealthGuard admin web (đã có `:id/assign`), không phải qua mobile.

### Follow-up actions required

- [x] UC040 v2 rewrite (done Phase 0.5, commit trong `PM_REVIEW/Resources/UC/Device/UC040_Connect_Device.md`)
- [ ] Parking lot: revisit ADR nếu Phase 5+ scale SaaS

## Reverse decision triggers

- Nếu business model shift sang B2B (clinics, hospitals) với device stock preload, reimplement pair-claim.
- Nếu physical device prototype có QR sticker thật và user expect scan-to-claim UX, reconsider.

## Related

- UC: UC040 v2 (scope chính)
- ADR: —
- Bug: —
- Code: `health_system/backend/app/services/device_service.py` (`pair_new_device`), `health_system/backend/app/services/admin_device_service.py` (admin orthogonal flow)
- Spec: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/DEVICE.md`

## Notes

Admin flow (HealthGuard `/api/v1/devices/:id/assign`) và IoT sim auto-provision đang cùng dùng `devices.user_id=NULL` pattern. ADR-010 đã chốt nullable. Flow "user claim" không có trong mobile, nhưng admin có thể assign trực tiếp cho user từ admin web.
