# 📱 EMERGENCY — Cảnh báo SOS đến (Incoming SOS Alarm)

> **UC Ref**: UC015
> **Module**: EMERGENCY
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

FCM P0 full-screen alarm khi nhận SOS từ người thân. **Z-Index P0** — đè lên mọi màn hình (Bottom Nav, Dialog). Không thể bỏ qua. Nút "Xem chi tiết" → SOSReceivedDetail. Màu đỏ, font lớn.

---

## Architecture Note (QUAN TRỌNG)

- Lắng nghe FCM `onMessage` / `onMessageOpenedApp`
- Full-screen overlay **không phụ thuộc Navigator stack** — Overlay hoặc route `fullscreenDialog: true`
- Z-Index cao hơn mọi widget
- FCM data payload: `sos_id`, `profile_id`, `sender_name`

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| *FCM trigger* | Nhận SOS từ người thân (can_receive_alerts) | → This screen |
| This screen | Bấm "Xem chi tiết" | → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md) |
| This screen | Bấm "Tôi đã biết" | → Dismiss overlay |

---

## User Flow

1. FCM nhận SOS → Hiển thị full-screen overlay ngay.
2. Hiển thị: Tên người gửi, "SOS Khẩn cấp", nút "Xem chi tiết" (≥56dp), "Tôi đã biết".
3. "Xem chi tiết" → SOSReceivedDetail với `sosId`.
4. "Tôi đã biết" → Dismiss overlay.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Alarm | Đang hiển thị overlay | Full-screen đỏ, tên người gửi, 2 nút to |
| Dismissed | User bấm "Tôi đã biết" | Overlay đóng |
| Navigate | User bấm "Xem chi tiết" | → SOSReceivedDetail |
| App Background | App đang background khi FCM đến | Wake app → overlay hiển thị ngay |
| Network Loss | App đang mở, FCM có thể delay | Không ảnh hưởng FCM (high priority) |

---

## Edge Cases

- [ ] **App background** khi FCM đến → Wake app, hiển thị overlay ngay (FCM data payload)
- [ ] **Network loss** → FCM P0 vẫn ưu tiên; nếu mất FCM → user có thể nhìn thấy từ SOSReceivedList
- [ ] Nhiều SOS cùng lúc → Overlay hiển thị SOS mới nhất; "Xem chi tiết" → list hoặc detail
- [ ] User đang ở SOSReceivedDetail → FCM mới → Overlay vẫn đè lên (Z-Index P0)
- [ ] Nút "Xem chi tiết" → truyền `sosId` từ FCM payload

---

## Data Requirements

- **API endpoint**: Không gọi API trực tiếp — FCM nhận payload.
- **Input**: FCM data: `sos_id`, `profile_id`, `sender_name`
- **Output**: Navigate với `sosId`; Dismiss → overlay đóng

---

## Sync Notes

- Khi EMERGENCY_SOSReceivedDetail thay đổi → nhận `sosId` từ FCM payload
- FCM topic: `user_{userId}_sos_alerts` — user có `can_receive_alerts` với sender
- Shared: Overlay manager, FCM handler

---

## Design Context

- **Target audience**: Người theo dõi (caregiver/family) — nhận SOS từ người thân.
- **Usage context**: Emergency — incoming alarm.
- **Key UX priority**: Speed (hiển thị ngay), Clarity (tên người gửi rõ), Calm (nút to, không gây thêm hoảng).
- **Specific constraints**: Màu đỏ; font ≥24sp; nút ≥56dp; Z-Index P0; không thể bỏ qua (phải bấm 1 trong 2 nút).

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (app background), UX (56dp, Z-Index P0) |
