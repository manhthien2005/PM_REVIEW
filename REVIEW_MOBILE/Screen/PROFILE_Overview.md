# 📱 PROFILE — Tổng quan Hồ sơ

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: ✅ Built (health_system)

## Purpose

Hub Hồ sơ cá nhân của **User** (unified role — không phân patient/caregiver). Avatar, tên, thông tin cơ bản. Links: EditProfile, ChangePassword, MedicalInfo, ContactList (Linked Profiles), Device, DeleteAccount (Danger Zone).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| MainScreen (Tab Cá nhân) | Tab "Cá nhân" | → This screen |
| This screen | Bấm "Chỉnh sửa hồ sơ" | → [PROFILE_EditProfile](./PROFILE_EditProfile.md) |
| This screen | Bấm "Đổi mật khẩu" | → [PROFILE_ChangePassword](./PROFILE_ChangePassword.md) |
| This screen | Bấm "Thông tin y tế" | → [PROFILE_MedicalInfo](./PROFILE_MedicalInfo.md) |
| This screen | Bấm "Danh bạ" / "Liên kết" | → [PROFILE_ContactList](./PROFILE_ContactList.md) |
| This screen | Bấm "Thiết bị" | → [DEVICE_List](./DEVICE_List.md) |
| This screen | Bấm "Xóa tài khoản" (Danger Zone) | → [PROFILE_DeleteAccount](./PROFILE_DeleteAccount.md) |

---

## User Flow

1. Mở tab Cá nhân → fetch profile self.
2. Hiển thị: Avatar, tên, thông tin cơ bản.
3. Các mục: Chỉnh sửa, Đổi mật khẩu, Thông tin y tế, Danh bạ (Linked Profiles), Thiết bị.
4. Danger Zone: Xóa tài khoản (riêng biệt, màu đỏ).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch profile | Skeleton |
| Success | Có data | Profile card + menu items |
| Error | API fail | SnackBar + "Thử lại" |
| Logout | User logout | Navigate AUTH_Login |

---

## Edge Cases

- [ ] Token hết hạn → redirect Login
- [ ] Profile chưa có avatar → placeholder
- [ ] Badge trên "Danh bạ" khi có pending requests (số lời mời chờ)
- [ ] Danger Zone tách rõ, không nhầm với mục thường

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/profile/self` (hoặc từ token/session)
- **Input**: Auth token
- **Output**: `{ id, name, avatar_url, email, ... }`

---

## Sync Notes

- Khi PROFILE_ContactList thay đổi → Badge pending count cập nhật (FCM / refresh)
- Khi PROFILE_EditProfile save → refresh profile card
- Shared: ProfileCard, MenuItem, DangerZone
- **Architecture**: Chỉ User role; "Danh bạ" = quản lý Linked Profiles (không dùng patient/caregiver)

---

## Design Context

- **Target audience**: Tất cả User — cài đặt cá nhân.
- **Usage context**: Routine — settings hub.
- **Key UX priority**: Clarity (menu rõ), Trust (Danger Zone tách biệt).
- **Specific constraints**: Nút menu min 48dp; Logout rõ ràng.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, architecture (User + Linked Profiles, no patient/caregiver) |

---

## Implementation Reference (health_system)

- `lib/features/profile/screens/profile_screen.dart`
- Tab "Cá nhân" trong MainScreen. Có: profile card, device card, edit, change password, logout, delete account.
