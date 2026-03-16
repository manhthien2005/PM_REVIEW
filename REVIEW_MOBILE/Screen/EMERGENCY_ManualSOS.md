# 📱 EMERGENCY — Kích hoạt SOS thủ công

> **UC Ref**: UC011, UC014
> **Module**: EMERGENCY
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

User bấm nút SOS thủ công. **Hold-to-confirm** (giữ 2–3s) hoặc Countdown 5s + Slide-to-cancel để tránh bấm nhầm. Sau countdown → LocalSOSActive.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm FAB SOS | → This screen |
| [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) | Chỉ số critical → "Gọi SOS" | → This screen |
| This screen | Countdown xong / Hold confirm | → [EMERGENCY_LocalSOSActive](./EMERGENCY_LocalSOSActive.md) |
| This screen | Slide-to-cancel | → Back (Dashboard) |

---

## User Flow

1. Bấm SOS → Countdown 5s (hoặc Hold-to-confirm 2–3s).
2. Slide-to-cancel rõ ràng (người già dễ thấy).
3. Hết countdown / Hold xong → Gửi SOS → LocalSOSActive.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Countdown | Đang đếm 5→0 | Số lớn đỏ, "Trượt để hủy" |
| Hold Confirming | User đang giữ nút | Progress ring 2–3s |
| Cancelled | User slide-to-cancel | Back |
| Sending | Đang gửi SOS | Loading → LocalSOSActive |
| Network Loss | Mất mạng khi gửi | Banner "Đang thử kết nối" — cache SOS, retry |
| App Background | App minimize khi countdown | Resume → nếu countdown = 0 → gửi; nếu còn → tiếp tục |

---

## Edge Cases

- [ ] **Countdown = 0** → Gửi SOS, navigate LocalSOSActive
- [ ] **Network loss** khi gửi → Cache request, retry khi có mạng; khi thành công → LocalSOSActive
- [ ] **App background** khi countdown → Resume: countdown = 0 → gửi; còn → tiếp tục
- [ ] User bấm nhầm → Slide-to-cancel dễ thấy, min 56dp touch target
- [ ] Hold-to-confirm: User thả tay giữa chừng → reset, không gửi

---

## Data Requirements

- **API endpoint**: `POST /api/mobile/sos/send` (manual trigger)
- **Input**: `{ source: "manual" }`
- **Output**: `{ sos_id }` → navigate LocalSOSActive; error → retry khi có mạng

---

## Sync Notes

- Khi EMERGENCY_LocalSOSActive thay đổi → nhận `sos_id` từ send
- Khi HOME_Dashboard thay đổi → FAB SOS link đến đây
- Shared: Countdown widget, Slide-to-cancel, Hold-to-confirm

---

## Design Context

- **Target audience**: Người cao tuổi — có thể hoảng, tay run.
- **Usage context**: Emergency — user-triggered.
- **Key UX priority**: Speed (countdown ngắn 5s), Clarity (nút to, slide rõ), Calm (tránh bấm nhầm).
- **Specific constraints**: Màu đỏ; font ≥24sp; nút ≥56dp; hold-to-confirm 2–3s hoặc slide-to-cancel.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, Edge Cases (network loss, countdown=0, app background), hold-to-confirm |
