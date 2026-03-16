# 📱 PROFILE — Danh bạ Liên kết (Linked Contacts)

> **UC Ref**: UC005, UC030
> **Module**: PROFILE
> **Status**: 🔄 In Progress

## Purpose

Quản lý **Linked Profiles** (không dùng patient/caregiver — unified User role). Danh sách tài khoản đang kết nối, gom nhóm theo nhãn (Gia đình, Bác sĩ, Bạn bè). Xem và xử lý lời mời kết nối (Pending requests).

## Navigation Links (🔗 Related Screens)
| From Screen                           | Action            | To Screen                                               |
| ------------------------------------- | ----------------- | ------------------------------------------------------- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Nhấn "Danh bạ"    | → This screen                                           |
| [PROFILE_Overview](./PROFILE_Overview.md)| Nhấn "Liên kết" | → This screen                                           |
| This screen                           | Nhấn FAB (+)      | → [PROFILE_AddContact](./PROFILE_AddContact.md)         |
| This screen                           | Nhấn 1 liên hệ    | → [PROFILE_LinkedContactDetail](./PROFILE_LinkedContactDetail.md)|
| This screen                           | Nhấn Back         | → [PROFILE_Overview](./PROFILE_Overview.md)             |

## User Flow
1. Mở màn hình -> Tải danh sách lời mời chờ duyệt (Pending) và Danh bạ liên hệ kết nối thành công (Contacts).
2. Nếu có Pending -> Hiện thành 1 sub-list nằm ngang trên cùng kèm nút Accept/Decline.
2a. **Sau khi tap Accept** -> Hiện BottomSheet "Bạn muốn chia sẻ gì với [Tên]?" gồm 3 toggle với default an toàn:
   - `can_view_vitals`: **OFF** (không tự ý chia sẻ sức khoẻ)
   - `can_receive_alerts`: **ON** (người thân nên nhận SOS)
   - `can_view_location`: **ON** (người thân nên xem vị trí trong SOS)
   - Nút "Xác nhận" (lưu và đóng) và "Cài sau" (dismiss, dùng default). Tap "Cài sau" -> dùng default values, có thể chỉnh sau trong LinkedContactDetail.
3. Phần thân màn hình hiển thị danh sách Liên hệ được Group theo các Nhãn dán.
4. Bấm [+] để đi qua màn hình Tạo mới liên kết.
5. Bấm vào ai đó để đi qua màn hình Cài đặt chia sẻ chi tiết.

## UI States
| State   | Description | Display |
| ------- | ----------- | ------- |
| Loading | Tải dữ liệu | Skeleton Shimmer Loading (Avatar, Line text) |
| Empty   | Không có ai | Ảnh minh hoạ + Text "Bạn chưa kết nối với ai" + Nút "Thêm Liên Hệ" bự |
| Success | Có dữ liệu  | Section Pending (nếu có) + Section Contact List phân Group (Accordion hoặc Title List) |
| Error   | Rớt mạng    | Banner "Không thể kết nối máy chủ" + Retry Button |

## Edge Cases
- [x] Lỗi mạng khi đang gọi Action (Chấp nhận/Từ chối). Cần show Toast và Restore UI state.
- [x] Người dùng không có trong nhóm nào? (Cho vào thẻ "Chưa phân loại" - Uncategorized).
- [x] Chữ to rõ (min 16sp), vùng bấm của nút Accept/Decline lớn (min 48dp) để người già dễ chạm.
- [x] User tap "Cài sau" trong Permission Setup BottomSheet -> dùng default values, có thể chỉnh sau trong LinkedContactDetail.

## Data Requirements
- API endpoint: 
  - `GET /api/mobile/contacts` (Danh bạ)
  - `GET /api/mobile/contacts/pending` (Danh bạ chờ duyệt)
  - `POST /api/mobile/contacts/{id}/accept`
  - `POST /api/mobile/contacts/{id}/reject`
- Input: Headers[TargetProfileId] - (Luôn gửi của Self)
- Output: List of Contacts with { id, name, avatar, role, label, status }

## Sync Notes

- **FCM Notification**: Khi server nhận `POST /api/mobile/contacts/request`, bắn FCM đến target user với title: "[Tên] muốn kết nối với bạn". Tap notification → deep link thẳng vào ContactList với Pending section expand sẵn.
- **Badge**: Pending section có badge count hiển thị trên icon ContactList ở Profile tab (số lời mời chờ duyệt).
- Shared widgets used: `ContactCard`, `PendingCard`, `SectionHeader`, `PermissionSetupBottomSheet`.
- **Architecture**: Linked Profiles — User chia sẻ quyền (can_view_vitals, can_receive_alerts, can_view_location) với người khác. Không dùng role patient/caregiver.

---

## Design Context

- **Target audience**: Tất cả User — quản lý người được chia sẻ quyền.
- **Usage context**: Configuration — Linked Profiles.
- **Key UX priority**: Clarity (nhóm theo label rõ), Trust (permission setup rõ).
- **Specific constraints**: Nút Accept/Decline min 48dp; chữ min 16sp cho người già.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | 🔄 In Progress | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog
| Version | Date       | Author  | Changes          |
| ------- | ---------- | ------- | ---------------- |
| v1.0    | 2026-03-16 | AI      | Initial creation |
| v2.0    | 2026-03-17 | AI      | Regen: Design Context, Pipeline Status, architecture (Linked Profiles, no patient/caregiver) |
