# Phase 6 — Hồ sơ cá nhân (Quality of life)

> **Screens:** PROFILE_Overview, PROFILE_EditProfile, PROFILE_MedicalInfo, PROFILE_ChangePassword, PROFILE_DeleteAccount
> **Status:** Spec ✅ 5/5 | Built: Overview, EditProfile, ChangePassword, DeleteAccount ✅ | MedicalInfo (spec only)

---

## Phase Goal

Phase 6 là **quality of life** — không blocking. Build sau khi các luồng chính (Auth, Device, Health, Emergency, Family) ổn định. Cung cấp hub Hồ sơ, chỉnh tên/ảnh, tiền sử bệnh, đổi mật khẩu, xóa tài khoản.

**Unlock:** Profile đầy đủ cho user. MedicalInfo có thể dùng cho Risk Report AI (Phase 3) nếu backend tích hợp.

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 1 (Auth) | Phase 1 | Yes |
| PROFILE_Overview | Screen/ | Yes — đã có |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- DeleteAccount: User bấm nhầm → có confirm đủ mạnh không? 1 dialog không đủ.
- MedicalInfo: Dị ứng thuốc, tiền sử bệnh — có validation không? Text quá dài?
- ChangePassword: Nhập mật khẩu cũ sai 3 lần → có lock tạm không?

### Constraint Guardian
- DeleteAccount: API cần soft-delete hoặc grace period. Không xóa ngay lập tức.
- MedicalInfo: Data nhạy cảm — encrypt at rest. Chỉ hiển thị khi user đã auth.

### User Advocate
- **DeleteAccount là destructive action** — cần **3-step confirm**: (1) "Bạn có chắc?" → (2) Nhập mật khẩu xác nhận → (3) Checkbox "Tôi hiểu dữ liệu sẽ bị xóa vĩnh viễn". Không dùng 1 dialog đơn giản.
- MedicalInfo: Ô nhập tiền sử bệnh, dị ứng — placeholder rõ ràng. Người già cần hướng dẫn "Ví dụ: Cao huyết áp, Tiểu đường".

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK generate PROFILE — Tạo spec cho 2 màn hình còn thiếu:

1. PROFILE_MedicalInfo — Tiền sử bệnh, dị ứng thuốc
   - Link từ PROFILE_Overview
   - Fields: medical_history (text), drug_allergies (text)
   - Validation: max length, sanitize
   - UC Ref: UC005

2. PROFILE_DeleteAccount — Xác nhận xóa tài khoản
   - Link từ PROFILE_Overview (trong Danger Zone)
   - 3-step confirm: (1) Dialog "Bạn có chắc?" → (2) Nhập mật khẩu → (3) Checkbox "Tôi hiểu dữ liệu sẽ bị xóa vĩnh viễn"
   - Không dùng 1 dialog đơn giản
   - UC Ref: UC005

Context: PROFILE_Overview, EditProfile, ChangePassword đã có. Architecture: Self-only. Không Profile Switcher.
```

---

## Screens to Generate

| Screen | File | UC Ref | Key Flow |
| --- | --- | --- | --- |
| PROFILE_MedicalInfo | `PROFILE_MedicalInfo.md` | UC005 | Form: medical_history, drug_allergies. Save/Cancel. |
| PROFILE_DeleteAccount | `PROFILE_DeleteAccount.md` | UC005 | 3-step confirm. Nhập password. Checkbox. API soft-delete. |

---

## Acceptance Gate

- [x] PROFILE_MedicalInfo.md tồn tại *(2026-03-17)*
- [x] PROFILE_DeleteAccount.md tồn tại (ghi chú 3-step)
- [x] PROFILE_Overview, EditProfile, ChangePassword có spec
- [x] DeleteAccount có ghi chú: không 1 dialog, cần multi-step
- [ ] `TASK sync` không báo broken link

> **health_system**: ProfileScreen built. DeleteAccount dùng 1 dialog + password. MedicalInfo chưa có.
