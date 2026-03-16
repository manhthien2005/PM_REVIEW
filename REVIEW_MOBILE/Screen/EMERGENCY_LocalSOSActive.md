# 📱 EMERGENCY — Chế độ SOS đang phát (Emergency Mode)

> **UC Ref**: UC011, UC014
> **Module**: EMERGENCY
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

SOS đã phát. Hiển thị trạng thái "Đang gửi tín hiệu" đến contacts. Nút "Xác nhận an toàn" to, rõ → Resolved → Home. Màu đỏ emergency.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [EMERGENCY_ManualSOS](./EMERGENCY_ManualSOS.md) | Countdown xong | → This screen |
| [EMERGENCY_FallAlert](./EMERGENCY_FallAlert.md) | Countdown 30s xong | → This screen |
| This screen | Bấm "Xác nhận an toàn" | → [HOME_Dashboard](./HOME_Dashboard.md) |
| This screen | *(Nếu network loss)* | Vẫn hiển thị, retry gửi khi có mạng |

---

## User Flow

1. SOS active — đang gửi tín hiệu đến contacts.
2. Nút "Xác nhận an toàn" to (≥56dp), rõ.
3. Tap (hoặc hold-to-confirm) → API resolve → về Home.
4. Network loss → Cache resolve request, retry khi có mạng.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Sending | Đang gửi SOS | "Đang gửi tín hiệu...", nút "Xác nhận an toàn" |
| Sent | Đã gửi xong | "Đã thông báo contacts", nút "Xác nhận an toàn" |
| Resolving | User bấm xác nhận | Loading → Home |
| Network Loss | Mất mạng khi gửi/resolve | Banner "Đang thử kết nối" — retry |
| App Background | App minimize | On resume: vẫn hiển thị; retry nếu chưa gửi/resolve xong |

---

## Edge Cases

- [ ] **Network loss** khi gửi SOS → Cache request, retry; hiển thị "Đang thử kết nối"
- [ ] **Network loss** khi resolve → Cache resolve, retry; khi thành công → Home
- [ ] **App background** → On resume: kiểm tra trạng thái; nếu đã resolve → Home; nếu chưa → retry
- [ ] User hoảng, bấm nhầm "Xác nhận" → Có thể hold-to-confirm 2s
- [ ] Contacts đã nhận → Hiển thị "X người đã nhận" (optional)

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/sos/send` (nếu từ FallAlert/ManualSOS chưa gửi); `POST /api/mobile/sos/:sosId/resolve`
- **Input**: `sos_id` (từ send response)
- **Output**: Resolve → 200 → Home; error → retry

---

## Sync Notes

- Khi EMERGENCY_FallAlert / ManualSOS thay đổi → navigate với `sos_id`
- Khi HOME_Dashboard thay đổi → Back về đây
- FCM: Contacts nhận push qua `can_receive_alerts`; payload có `sos_id`, `profile_id`

---

## Design Context

- **Target audience**: Người cao tuổi — vừa có thể ngã hoặc gửi SOS.
- **Usage context**: Emergency — SOS đang active.
- **Key UX priority**: Clarity (trạng thái rõ), Calm (nút xác nhận an toàn to).
- **Specific constraints**: Màu đỏ; font ≥24sp; nút ≥56dp; hold-to-confirm cho "Xác nhận an toàn" tránh bấm nhầm.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (network loss, app background), UX (56dp, hold-to-confirm) |
