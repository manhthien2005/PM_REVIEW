# 📱 PROFILE — Chi tiết cài đặt Liên hệ (Linked Contact Detail)

> **UC Ref**: UC005, UC015, UC030
> **Module**: PROFILE
> **Status**: 🔄 In Progress

## Purpose
Hiển thị cài đặt quyền lợi cho một Liên hệ cụ thể. **Perspective**: Người đang mở màn hình đang cấu hình quyền mà MÌNH chia sẻ ra ngoài cho người kia — không phải quyền mình nhận vào. Thay đổi nhãn dán ở đây cũng được hỗ trợ.

## 3 Permission Toggles (Định nghĩa tường minh)
| Toggle | Label hiển thị | Key | Mô tả |
| ------ | -------------- | --- | ----- |
| 1 | "Cho phép [Tên] xem chỉ số sức khoẻ của tôi" | `can_view_vitals` | Khi ON → người này xuất hiện trong Family Dashboard của họ và xem được Health Metrics, Sleep Report của mình (Linked Profile). |
| 2 | "Cho phép [Tên] nhận cảnh báo SOS của tôi" | `can_receive_alerts` | Khi ON → người này nhận FCM khi mình phát SOS. Liên quan trực tiếp đến EMERGENCY flow. |
| 3 | "Cho phép [Tên] xem vị trí GPS của tôi trong SOS" | `can_view_location` | Khi ON → người này thấy bản đồ real-time trong SOSReceivedDetail War Room. |

## Navigation Links (🔗 Related Screens)
| From Screen                           | Action            | To Screen                                               |
| ------------------------------------- | ----------------- | ------------------------------------------------------- |
| [PROFILE_ContactList](./PROFILE_ContactList.md) | Bấm Avatar | → This screen                                           |
| This screen                           | Bấm Back / Xoá liên kết | → [PROFILE_ContactList](./PROFILE_ContactList.md)       |

## User Flow
1. Chọn liên hệ từ Danh bạ.
2. Màn hình load 2 thông tin: Dữ liệu cá nhân (Tên, Ảnh, Nhãn dán) + Trạng thái 3 công tắc Settings (Permissions): `can_view_vitals`, `can_receive_alerts`, `can_view_location`.
3. Khi User gạt công tắc -> Call API update lên Server mượt mà (Loading indicator ở ngay thẻ).
4. Khi User muốn gỡ liên kết -> Click Huỷ Cấp Quyền (Unlink) -> Popup Đỏ xác nhận xoá -> Thành công, văng ra ngoài list.

## UI States
| State   | Description | Display |
| ------- | ----------- | ------- |
| Initial | Hiển thị thông tin chuẩn | Các Toggle Switch On/Off tải từ config về |
| Loading | Khi bấm gạt công tắc | Hiện CircularProgressSpinner nhỏ bên trong Switch thay vì vòng tròn gạt |
| Error   | Lưu thất bại | Trả lại trạng thái cũ của công tắc + Toast báo lỗi cực nhỏ giọt |
| Unlink_Confirm| Hỏi lần cuối trước khi cắt đứt| Nền Dim + Dialog Confirmation với Button Hành động đỏ |

## Edge Cases
- [x] Chặn spam click công tắc bằng cách Disable công tắc lúc nó đang trong state `Loading`.
- [x] Huỷ cấp quyền (Unlink) là hành động nguy hiểm vì có kết nối liên hệ là cực hạn đối với elderly. Cần ghi chú rõ Dialog.
- [x] Thay đổi Nhãn (Label) trực tiếp tại Screen này bằng việc nhấn vào tên Label (Action Chip).

## Data Requirements
- API endpoint: 
  - `GET /api/mobile/contacts/{contact_id}` (Lấy chi tiết và settings)
  - `PATCH /api/mobile/contacts/{contact_id}/permissions` (Cập nhật settings)
  - `PATCH /api/mobile/contacts/{contact_id}/label` (Cập nhật tag)
  - `DELETE /api/mobile/contacts/{contact_id}` (Huỷ liên kết)

## Sync Notes

- Quan trọng: Khi công tắc Tắt/Mở "Nhận cảnh báo" (`can_receive_alerts`) thành công → Bắn sự kiện sang Native Module Firebase `subscribeToTopic` / `unsubscribe`.
- **Linked Profiles / access-profiles**: Khi Toggle 1 (`can_view_vitals`) chuyển OFF → ON thành công → server invalidate cache `access-profiles` của người được cấp quyền. Lần tiếp theo họ mở Family Dashboard, mình sẽ xuất hiện trong danh sách.
- **Notification**: Khi `can_view_vitals` chuyển OFF → ON thành công → người được cấp quyền nhận FCM: "[Tên] đã cho phép bạn xem chỉ số sức khoẻ của họ."
- Shared widgets used: `SettingsSwitchBlock`, `DangerZoneButton`, `DangerousConfirmDialog`.
- **Architecture**: Linked Profiles — User cấu hình quyền MÌNH chia sẻ ra; không dùng patient/caregiver.

---

## Design Context

- **Target audience**: User — cấu hình quyền chia sẻ với Linked Profile.
- **Usage context**: Configuration — quản lý quyền.
- **Key UX priority**: Clarity (3 toggle rõ), Trust (Unlink confirm nghiêm túc).
- **Specific constraints**: Disable toggle khi Loading; Unlink dialog màu đỏ; nút min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `build-plan/PROFILE_LinkedContactDetail_plan.md` |
| BUILD | 🔄 In Progress | — |
| REVIEW | ⬜ Not started | — |

### Companion Docs

- `build-plan/PROFILE_LinkedContactDetail_plan.md`

---

## Changelog
| Version | Date       | Author  | Changes          |
| ------- | ---------- | ------- | ---------------- |
| v1.0    | 2026-03-16 | AI      | Initial creation |
| v2.0    | 2026-03-17 | AI      | Regen: Design Context, Pipeline Status, architecture (Linked Profiles, Family Dashboard thay Profile Switcher) |
| v2.1    | 2026-03-18 | AI      | Added detailed build plan `build-plan/PROFILE_LinkedContactDetail_plan.md`, chuẩn hoá permission center UX và đồng bộ style với `DEVICE_Configure` |
