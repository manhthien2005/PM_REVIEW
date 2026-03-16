# 📱 PROFILE — Chỉnh sửa hồ sơ

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: ✅ Built (health_system)

## Purpose

Chỉnh sửa tên, ảnh đại diện, thông tin cơ bản của User. Save/Cancel.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Chỉnh sửa hồ sơ" | → This screen |
| This screen | Bấm Save | → [PROFILE_Overview](./PROFILE_Overview.md) |
| This screen | Bấm Back | → [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Form: name, avatar (camera/gallery), optional fields.
2. Bấm Save → API update → Back Overview.
3. Bấm Back/Cancel → discard → Back Overview.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch profile | Skeleton |
| Idle | Form sẵn sàng | Các field, Save, Cancel |
| Saving | Đang gọi API | Loading, disable Save |
| Success | Save thành công | Back Overview |
| Error | API fail, validation | SnackBar, form giữ giá trị |

---

## Edge Cases

- [ ] Avatar upload fail → message, cho phép retry
- [ ] Validation: tên không rỗng, max length
- [ ] Network loss khi save → retry
- [ ] User Back không save → discard (có thể confirm nếu đã chỉnh)

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/profile/self`; `PATCH /api/mobile/profile/self`; `POST /api/mobile/profile/avatar` (upload)
- **Input**: `{ name?, avatar? }`
- **Output**: `{ success: true }` hoặc profile object

---

## Sync Notes

- Khi PROFILE_Overview thay đổi → Back refresh profile card
- Shared: Form validation, image picker

---

## Design Context

- **Target audience**: Tất cả User.
- **Usage context**: Configuration — không thường xuyên.
- **Key UX priority**: Clarity (form rõ), Speed (save nhanh).
- **Specific constraints**: Nút Save min 48dp; avatar crop rõ.

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
| v2.0 | 2026-03-17 | AI | Regen: full template |

---

## Implementation Reference (health_system)

- `lib/features/profile/screens/edit_profile_screen.dart`
- Route: `/edit-profile`
