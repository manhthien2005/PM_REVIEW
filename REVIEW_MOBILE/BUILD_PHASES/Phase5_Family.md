# Phase 5 — Liên kết gia đình

> **Screens:** PROFILE_ContactList, PROFILE_AddContact, PROFILE_LinkedContactDetail, HOME_FamilyDashboard
> **Status:** Spec ✅ 4/4 | Built ✅ 4/4 (FamilyManagementScreen)

---

## Phase Goal

Tab "Gia đình" chỉ có nghĩa khi đã có linked contacts. Phase 5 là **prerequisite cho FamilyDashboard** — quản lý danh bạ liên kết, thêm/xóa, cài đặt 3 quyền (xem chỉ số, nhận SOS, xem GPS).

**Unlock:** HOME_FamilyDashboard hiển thị bird's-eye view người thân có `can_view_vitals = true`. Card phải có đủ **Vitals + Sleep + Risk summary + SOS badge** để drill-down `VitalDetail`, `SleepReport`, `RiskReport` với `profileId`.

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 1 (Auth) | Phase 1 | Yes |
| Phase 3 (Health core screens tồn tại) | Phase 3 | Partial — cần để drill-down Sleep / Risk / Vital |
| Phase 4 (SOS flow) | Phase 4 | Partial — `can_receive_alerts` toggle sync FCM |
| API: contacts, pending, permissions | Backend | Yes |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- **`can_view_vitals` OFF → FamilyDashboard:** Card người thân phải hiển thị `Perm_Denied` state (chỉ số `---` + badge khóa). Không crash khi permission thay đổi giữa lúc app mở.
- Pending request: User nhận 2 lời mời cùng lúc — Accept một cái, Decline cái kia. UI có restore đúng không?
- AddContact: Quét QR của chính mình → có chặn không?

### Constraint Guardian
- LinkedContactDetail: Khi toggle `can_receive_alerts` OFF → gọi `unsubscribeFromTopic` FCM. Khi ON → `subscribeToTopic`. Không chỉ lưu DB.
- ContactList: Pending section có badge count → sync với backend.
- FamilyDashboard API phải có `risk_summary` trong payload nếu muốn card mở đúng `ANALYSIS_RiskReport(profileId)` mà không cần fetch dư.

### User Advocate
- PermissionSetupBottomSheet (sau Accept): 3 toggle với default an toàn. "Cài sau" không được ẩn — người già có thể bỏ qua.
- LinkedContactDetail: Label mỗi toggle rõ ràng — "Cho phép [Tên] xem chỉ số sức khoẻ của tôi" thay vì "can_view_vitals".

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK sync — Validate Phase 5 (Family linking):

1. Kiểm tra cross-links:
   - PROFILE_Overview → ContactList
   - ContactList → AddContact, LinkedContactDetail
   - AddContact → ContactList (sau gửi lời mời)
   - LinkedContactDetail → ContactList (sau Unlink)
   - HOME_FamilyDashboard → ContactList (Empty State CTA), VitalDetail(profileId), SleepReport(profileId), RiskReport(profileId), SOSReceivedDetail

2. Verify permission flow với Phase 4:
   - LinkedContactDetail có 3 toggle: can_view_vitals, can_receive_alerts, can_view_location
   - can_receive_alerts OFF → FCM unsubscribe. ON → subscribe.
   - FamilyDashboard chỉ hiển thị người có can_view_vitals = true
   - Perm_Denied: Card hiển thị nhưng chỉ số --- + badge khóa. Tap → popup hướng dẫn.
   - FamilyDashboard card có `risk_summary` và tap vào đó mở `ANALYSIS_RiskReport(profileId)`

3. Cập nhật spec nếu thiếu: PermissionSetupBottomSheet (sau Accept) với default: can_view_vitals OFF, can_receive_alerts ON, can_view_location ON.

Context: Phase 5 spec đã có (In Progress). Chỉ cần sync và validate. Đảm bảo không crash khi can_view_vitals OFF.
```

---

## Permission Toggles Reference

| Toggle | Default (sau Accept) | Ảnh hưởng |
| --- | --- | --- |
| can_view_vitals | OFF | Xuất hiện trong FamilyDashboard, xem VitalDetail, SleepReport, RiskReport |
| can_receive_alerts | ON | Nhận FCM khi SOS phát |
| can_view_location | ON | Xem map trong SOSReceivedDetail |

---

## Acceptance Gate

- [x] ContactList, AddContact, LinkedContactDetail có spec đầy đủ
- [x] Cross-links 2 chiều đúng
- [x] LinkedContactDetail có 3 toggle + FCM sync note
- [x] FamilyDashboard Perm_Denied state được document
- [ ] FamilyDashboard card có `risk_summary` + link `RiskReport(profileId)`
- [ ] `TASK sync` không báo broken link

> **health_system**: FamilyManagementScreen = 2 tabs (Tìm kiếm = AddContact, Người thân = ContactList + FamilyDashboard). UserDetailScreen = LinkedContactDetail.
