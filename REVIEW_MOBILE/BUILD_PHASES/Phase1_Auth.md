# Phase 1 — Shell & Auth (Cổng vào ứng dụng)

> **Screens:** AUTH_Splash, AUTH_Login, AUTH_Register, AUTH_VerifyEmail, AUTH_ForgotPassword, AUTH_ResetPassword, Bottom Navigation Bar
> **Status:** Code built ✅ | Spec ✅ — Verify & sync only

---

## Phase Goal

Phase 1 là **entry point duy nhất** của ứng dụng. Phải build xong nhóm này trước khi test bất cứ thứ gì. Không có Auth = không có token, không có session, không vào được app.

**Unlock cho phase sau:** Token + session → gọi API. Bottom Nav → shell chứa 4 tab (Sức khoẻ, Gia đình, Thiết bị, Hồ sơ).

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| SRS UC001–UC003 (Login, Register, Forgot Password) | Resources/SRS | Yes |
| API Auth endpoints | Backend | Yes |
| Deep-link scheme (email verify) | App config | No — có fallback manual |

**Phase 1 không phụ thuộc phase nào.** Đây là phase đầu tiên.

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- Token expiry flow: Khi token hết hạn giữa session, app có redirect về Login không? Có clear local storage không?
- Deep-link resume sau email verify: User bấm link trong email → app mở từ background. Có handle `getInitialLink` / `getLinks` đúng không?
- Register → VerifyEmail: Nếu user đóng app trước khi verify, mở lại có nhắc "Vui lòng xác minh email" không?

### Constraint Guardian
- **Bottom Nav** là shared component — không phải screen riêng nhưng là prerequisite. Cần define widget spec: 4 tab items, selected state, badge (pending contacts).
- Secure storage: Token không được lưu SharedPreferences plain text. Cần `flutter_secure_storage` hoặc tương đương.

### User Advocate
- Người già: Nút "Quên mật khẩu" đủ to (min 48dp). Không ẩn quá sâu.
- Error message: "Email hoặc mật khẩu sai" thay vì "401 Unauthorized".

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

Chạy TASK scan để verify Phase 1 — Shell & Auth:
- AUTH_Splash, AUTH_Login, AUTH_Register, AUTH_VerifyEmail, AUTH_ForgotPassword, AUTH_ResetPassword
- Bottom Navigation Bar (shared widget — không phải screen riêng)

Sau đó chạy TASK sync để validate cross-links giữa các màn Auth và HOME_Dashboard.

Context: Phase 1 đã có code built. Chỉ cần verify spec tồn tại, cross-link đúng, và Bottom Nav widget được document trong build-plan hoặc shared component spec.
```

---

## Bottom Nav Widget Spec (Reference)

Bottom Nav Bar chứa 4 tab:
1. **Sức khoẻ của tôi** → HOME_Dashboard
2. **Gia đình** → HOME_FamilyDashboard
3. **Thiết bị** → DEVICE_List
4. **Hồ sơ** → PROFILE_Overview

- Badge trên tab "Hồ sơ" khi có pending contact requests (số lời mời chờ duyệt).
- Min touch target 48dp mỗi item.
- Selected state: icon + label đổi màu primary.

---

## Acceptance Gate

- [x] Tất cả 6 màn Auth có spec file trong `Screen/` *(2026-03-17: Đã tạo từ health_system)*
- [x] Cross-links giữa Login ↔ Register ↔ ForgotPassword ↔ ResetPassword ↔ VerifyEmail đúng 2 chiều *(trong spec)*
- [x] Splash → Login (chưa đăng nhập) hoặc → HOME_Dashboard (đã đăng nhập)
- [x] Bottom Nav được document (trong Phase1 + README)
- [ ] `TASK sync` không báo broken link *(một số spec khác chưa có file)*

> **Lưu ý**: App health_system có Bottom Nav 5 tab (Sức khỏe, Giấc ngủ, Khẩn cấp, Gia đình, Cá nhân) — khác spec 4 tab. Xem [PROGRESS_REPORT.md](../PROGRESS_REPORT.md).
