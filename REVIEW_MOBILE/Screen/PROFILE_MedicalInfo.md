# 📱 PROFILE — Thông tin y tế (Medical Info)

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

Tiền sử bệnh, dị ứng thuốc của User. Form: medical_history (text), drug_allergies (text). Validation: max length, sanitize. Encrypt at rest.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [PROFILE_Overview](./PROFILE_Overview.md) | Bấm "Thông tin y tế" | → This screen |
| This screen | Bấm Save | → [PROFILE_Overview](./PROFILE_Overview.md) |
| This screen | Bấm Cancel | → [PROFILE_Overview](./PROFILE_Overview.md) |

---

## User Flow

1. Form: medical_history, drug_allergies.
2. Placeholder: "Ví dụ: Cao huyết áp, Tiểu đường".
3. Validation: max length.
4. Save/Cancel.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch medical info | Skeleton |
| Idle | Form sẵn sàng | 2 text area, Save, Cancel |
| Saving | Đang gọi API | Loading, disable Save |
| Success | Save thành công | Back Overview |
| Error | API fail, validation | SnackBar |

---

## Edge Cases

- [ ] Dữ liệu nhạy cảm → encrypt at rest (backend)
- [ ] Max length (VD: 500 chars mỗi field) → validation
- [ ] Empty → cho phép để trống (optional fields)
- [ ] Network loss khi save → retry

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/profile/medical-info`; `PATCH /api/mobile/profile/medical-info`
- **Input**: `{ medical_history?, drug_allergies? }`
- **Output**: `{ success: true }`; data encrypted at rest

---

## Sync Notes

- Khi PROFILE_Overview thay đổi → có thể hiển thị badge "Đã cập nhật" nếu vừa save
- Shared: Form validation, secure text input

---

## Design Context

- **Target audience**: User (đặc biệt người cao tuổi) — thông tin y tế cá nhân.
- **Usage context**: Configuration — nhạy cảm.
- **Key UX priority**: Trust (dữ liệu bảo mật), Clarity (placeholder rõ).
- **Specific constraints**: Cảnh báo "Chỉ chia sẻ với người được ủy quyền" (Linked Profiles có can_view_vitals).

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
| v2.0 | 2026-03-17 | AI | Regen: full template |
