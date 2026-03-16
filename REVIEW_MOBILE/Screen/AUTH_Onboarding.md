# 📱 AUTH — Hướng dẫn lần đầu (Onboarding)

> **UC Ref**: UC009
> **Module**: AUTH
> **Status**: ⬜ Spec only

## Purpose

Hướng dẫn lần đầu mở app. Không blocking. Có thể skip. Giới thiệu tính năng chính (sức khoẻ, gia đình, SOS, thiết bị) qua slides/carousel. Link → Login, Register.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| *First launch* | Chưa xem onboarding (local flag) | → This screen |
| [AUTH_Splash](./AUTH_Splash.md) | Có thể chèn Onboarding làm page 0 (tuỳ config) | → This screen |
| This screen | Bấm "Bắt đầu" / "Đăng nhập" | → [AUTH_Login](./AUTH_Login.md) |
| This screen | Bấm "Đăng ký" | → [AUTH_Register](./AUTH_Register.md) |
| This screen | Bấm "Bỏ qua" | → [AUTH_Login](./AUTH_Login.md) |

---

## User Flow

1. App detect first launch (chưa set `onboarding_seen=true`).
2. Hiển thị 3–4 slides giới thiệu (PageView).
3. User swipe qua hoặc bấm "Bỏ qua" → set flag → navigate Login.
4. Ở slide cuối: "Bắt đầu" → Login; có thể có "Đăng ký" link.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Slides | Đang xem onboarding | PageView với 3–4 slides, dots indicator |
| Last Slide | Slide cuối | "Bắt đầu", "Đăng ký", "Bỏ qua" (nếu chưa ở slide cuối) |
| Skip | User bấm "Bỏ qua" | Set flag → navigate Login |

---

## Edge Cases

- [ ] User đóng app giữa onboarding → mở lại → tiếp tục từ slide đã xem hoặc bắt đầu lại (tuỳ lưu state)
- [ ] Đã xem onboarding rồi → không hiển thị nữa (check flag)
- [ ] Deep-link vào app → có thể bypass onboarding (ưu tiên deep-link target)
- [ ] Người già: slides đơn giản, ít chữ, icon lớn; nút min 48dp

---

## Data Requirements

- **API endpoint**: Không gọi API.
- **Input**: Local storage `onboarding_seen` (boolean).
- **Output**: Set `onboarding_seen=true` khi hoàn thành hoặc skip.

---

## Sync Notes

- Khi AUTH_Splash thay đổi → có thể chèn Onboarding làm page 0 trong PageView (trước Start).
- Khi AUTH_Login thay đổi → link "Bắt đầu" / "Đăng nhập" giữ nguyên.
- Shared: PageView, dots indicator (có thể dùng package intro_slider, smooth_page_indicator).

---

## Design Context

- **Target audience**: User mới — first launch.
- **Usage context**: One-time onboarding — không blocking.
- **Key UX priority**: Clarity (giới thiệu ngắn gọn), Calm (không gây áp lực).
- **Specific constraints**: Người già — ít chữ, icon lớn, nút to; có thể skip bất kỳ lúc nào.

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
| v1.0 | 2026-03-17 | AI | Initial creation (STUB) |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
