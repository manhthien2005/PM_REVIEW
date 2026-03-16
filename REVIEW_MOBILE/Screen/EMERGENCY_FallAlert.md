# 📱 EMERGENCY — Cảnh báo té ngã (Fall Alert Countdown)

> **UC Ref**: UC010
> **Module**: EMERGENCY
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

AI phát hiện ngã → Countdown 30s full-screen. User có thể bấm "Tôi ổn" để hủy. Hết 30s (countdown = 0) → LocalSOSActive. Rung + âm thanh. **Z-Index P0** — đè lên mọi màn hình.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| *System Event* | AI phát hiện ngã | → This screen |
| This screen | Bấm "Tôi ổn" | → Back (Dashboard) |
| This screen | Hết 30s (countdown = 0) | → [EMERGENCY_LocalSOSActive](./EMERGENCY_LocalSOSActive.md) |

---

## User Flow

1. Full-screen overlay, Z-Index P0.
2. Countdown 30s. Rung + âm thanh.
3. "Tôi ổn" (hold-to-confirm hoặc tap) → Hủy SOS → Back.
4. Hết 30s → Gửi SOS → LocalSOSActive.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Countdown | Đang đếm 30→0 | Số lớn (48sp+), vòng tròn đỏ, "Tôi ổn" nút to |
| Confirmed Safe | User bấm "Tôi ổn" | Checkmark xanh → Back |
| Countdown Zero | Hết 30s | Chuyển ngay → LocalSOSActive |
| Network Loss | Mất mạng khi countdown | Banner "Đang thử kết nối" — vẫn đếm; khi = 0 → cache SOS, retry khi có mạng |
| App Background | App minimize khi countdown | Resume → kiểm tra countdown còn lại; nếu đã = 0 → LocalSOSActive |

---

## Edge Cases

- [ ] **Countdown = 0** → Gửi SOS ngay, navigate LocalSOSActive (không chờ user)
- [ ] **Network loss** khi countdown → Cache SOS request, retry khi có mạng; vẫn chuyển LocalSOSActive
- [ ] **App background** khi countdown → On resume: nếu countdown đã = 0 → LocalSOSActive; nếu còn → tiếp tục đếm
- [ ] User nằm xuống, màn ướt → Nút "Tôi ổn" min 56dp, dễ bấm
- [ ] Rung + âm bị tắt → Vẫn hiển thị countdown rõ, không phụ thuộc âm thanh

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/sos/cancel` (khi "Tôi ổn"); `POST /api/mobile/sos/send` (khi countdown = 0)
- **Input**: `fall_event_id` (từ AI), `cancel: boolean`
- **Output**: Cancel → 200; Send → 200, navigate LocalSOSActive

---

## Sync Notes

- Khi EMERGENCY_LocalSOSActive thay đổi → nhận `sos_id` từ send response
- Shared: Countdown widget, vibration/haptic, overlay manager
- Z-Index P0: Overlay không phụ thuộc Navigator — dùng OverlayEntry hoặc route fullscreenDialog

---

## Design Context

- **Target audience**: Người cao tuổi — có thể vừa ngã, hoảng, tay run.
- **Usage context**: Emergency — AI-triggered.
- **Key UX priority**: Speed (phản hồi nhanh), Clarity (số to, nút to), Calm (không gây thêm hoảng).
- **Specific constraints**: Màu đỏ emergency; font ≥24sp; nút "Tôi ổn" ≥56dp; có thể dùng hold-to-confirm 2s tránh bấm nhầm.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (network loss, countdown=0, app background), UX (56dp, hold-to-confirm) |
