# Phase 4 — Khẩn cấp SOS (Safety critical)

> **Screens:** EMERGENCY_ManualSOS, EMERGENCY_LocalSOSActive, EMERGENCY_FallAlert, EMERGENCY_IncomingSOSAlarm, EMERGENCY_SOSReceivedList, EMERGENCY_SOSReceivedDetail
> **Status:** Tất cả spec ✅ Done — Sync & validate only

---

## Phase Goal

Phase 4 là **safety critical** — không được delay. Build song song hoặc ngay sau Phase 3. Tính năng an toàn không được để cuối.

**Unlock:** FCM P0 IncomingSOSAlarm đè lên mọi màn hình. Permission `can_receive_alerts` (từ PROFILE_LinkedContactDetail) gating việc nhận SOS.

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 2 (Device) | Phase 2 | Yes — Fall detection cần đồng hồ |
| Phase 3 (optional) | Phase 3 | No — SOS có thể gửi ngay |
| Phase 5 (LinkedContactDetail) | Phase 5 | Partial — `can_receive_alerts` toggle ảnh hưởng FCM topic |
| FCM setup | App config | Yes |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- IncomingSOSAlarm: User đang ở màn hình khác (Settings, Profile) → FCM có mở full-screen alarm không? Hay chỉ notification nhỏ?
- ManualSOS countdown 5s: User bấm nhầm → slide-to-cancel có đủ rõ không? Người già có thấy không?
- FallAlert countdown 30s: User nằm ngửa, màn hình úp → có rung + âm thanh không?

### Constraint Guardian
- **IncomingSOSAlarm Z-Index P0** phải đè lên MỌI màn hình — cần verify widget overlay architecture (OverlayEntry, Navigator overlay, hoặc route riêng). Không được để bị che bởi Bottom Nav hay Dialog.
- FCM data payload: `sos_id`, `profile_id`, `sender_name` — cần document trong spec.

### User Advocate
- SOS Received Detail (War Room): Map + vitals + nút "Đã xác nhận an toàn" — nút phải to, rõ.
- Người già nhận SOS: Full-screen alarm không thể bỏ qua. Có nút "Tôi đã biết" để dismiss.

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK sync — Validate cross-links Phase 4 (Emergency SOS):

1. Kiểm tra tất cả 6 màn Emergency có cross-link đúng:
   - ManualSOS → LocalSOSActive
   - FallAlert → LocalSOSActive
   - IncomingSOSAlarm → SOSReceivedDetail
   - SOSReceivedList → SOSReceivedDetail
   - SOSReceivedDetail → Home (Resolved)

2. Verify sync với Phase 5:
   - PROFILE_LinkedContactDetail có toggle `can_receive_alerts` — khi OFF, user không nhận FCM SOS.
   - SOSReceivedDetail cần `can_view_location` để hiển thị map.

3. Thêm vào EMERGENCY_IncomingSOSAlarm spec (nếu chưa có):
   - Architecture note: Z-Index P0 overlay — phải đè lên mọi màn hình (Bottom Nav, Dialog, bất kỳ route nào).
   - FCM trigger: data payload chứa sos_id, profile_id, sender_name.

Context: Phase 4 spec đã có. Chỉ cần sync và validate. Không generate màn mới.
```

---

## FCM Overlay Architecture Note

IncomingSOSAlarm phải:
- Lắng nghe FCM `onMessage` / `onMessageOpenedApp`
- Hiển thị full-screen overlay **không phụ thuộc Navigator stack** — dùng Overlay hoặc route riêng với `fullscreenDialog: true`
- Z-Index cao hơn mọi widget khác
- Có nút "Xem chi tiết" → SOSReceivedDetail

---

## Acceptance Gate

- [x] 6 màn Emergency đều có spec *(2026-03-17)*
- [x] Cross-links 2 chiều đúng
- [x] IncomingSOSAlarm spec có ghi chú Z-Index P0 overlay
- [x] Sync với LinkedContactDetail: `can_receive_alerts`, `can_view_location`
- [ ] `TASK sync` không báo broken link

> **health_system**: Chỉ SOSReceivedList + SOSReceivedDetail built. ManualSOS, FallAlert, IncomingSOSAlarm, LocalSOSActive chưa có.
