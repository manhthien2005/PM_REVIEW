# 📱 AUTH — Màn hình Khởi động (Splash / Start)

> **UC Ref**: UC001 (entry point), UC009 (onboarding flow)
> **Module**: AUTH
> **Status**: ✅ Built (health_system)

## Purpose

Màn hình đầu tiên khi mở app. Hiển thị welcome/hero, sau đó user có thể swipe hoặc bấm "Bắt đầu ngay" để chuyển sang Login. **Implementation**: `AuthPagesScreen` (route `/start`) chứa PageView với `StartScreen` (page 0) và `LoginScreen` (page 1).

> **Lưu ý**: App dùng `initialRoute: AppRouter.start`. Không có Splash native riêng — `FlutterNativeSplash` remove sau khi routing resolve.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| *App cold start* | Chưa đăng nhập | → This screen (StartScreen) |
| This screen | Bấm "Bắt đầu ngay" / Swipe phải | → [AUTH_Login](./AUTH_Login.md) |
| This screen | *(Nếu đã có token)* | → [HOME_Dashboard](./HOME_Dashboard.md) |

> **Ghi chú**: App hiện tại luôn bắt đầu từ `/start`. Auth check (token) có thể được thêm sau để redirect thẳng Dashboard nếu đã login.

---

## User Flow

1. App mở → `AuthPagesScreen` với `StartScreen` (page 0).
2. User xem hero, content, footer.
3. Bấm "Bắt đầu ngay" hoặc swipe → `LoginScreen` (page 1 trong PageView).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | App đang resolve route / check token | FlutterNativeSplash hoặc blank → chuyển nhanh |
| Initial | Chưa đăng nhập, hiển thị Start | Hero image, welcome text, "Bắt đầu ngay" button |
| Has Token | Đã có token hợp lệ | Redirect ngay → HOME_Dashboard (không hiển thị Start) |
| Error | Token invalid / expired | Fallback về Start (như Initial) |

---

## Edge Cases

- [ ] App cold start mất network → vẫn hiển thị Start (không cần API); token check có thể fail → fallback về Start
- [ ] User đóng app giữa chừng trên Start → mở lại → Start (page 0)
- [ ] Deep-link từ email verify → app mở từ background → có thể vào VerifyEmail trực tiếp (bypass Start)
- [ ] Token hết hạn giữa session → app resume → cần clear token và redirect về Start/Login

---

## Data Requirements

- **API endpoint**: Không gọi API trực tiếp từ Start. Token check optional (local storage: `flutter_secure_storage`).
- **Input**: `initialRoute` từ config; `getStoredToken()` (async).
- **Output**: Route decision: `/start` (Start) hoặc `/dashboard` (nếu token valid).

---

## Sync Notes

- Khi AUTH_Login thay đổi route → cập nhật link "Bắt đầu ngay" → AUTH_Login.
- Shared: `AuthPagesScreen` (PageView) chứa Start + Login; có thể thêm [AUTH_Onboarding](./AUTH_Onboarding.md) làm page đầu nếu chưa xem onboarding.
- Khi HOME_Dashboard thay đổi route → cập nhật link "Đã đăng nhập" trong bảng này.

---

## Design Context

- **Target audience**: Tất cả người dùng (User) — mở app lần đầu hoặc chưa đăng nhập.
- **Usage context**: Entry point — cold start, first launch.
- **Key UX priority**: Clarity (rõ ràng đây là app gì), Speed (chuyển nhanh sang Login).
- **Specific constraints**: Màn hình tĩnh, không cần input; nút "Bắt đầu ngay" min 48dp touch target.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | build-plan |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |

---

## Implementation Reference (health_system)

- `lib/features/auth/screens/auth_pages_screen.dart` — PageView container
- `lib/features/auth/screens/start_screen.dart` — StartScreen content
- Route: `AppRouter.start` = `/start`
