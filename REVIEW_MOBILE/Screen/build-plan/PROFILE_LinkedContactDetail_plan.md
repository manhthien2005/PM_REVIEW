# 📐 UI Plan: PROFILE_LinkedContactDetail Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [PROFILE_LinkedContactDetail.md](../PROFILE_LinkedContactDetail.md)  
> **Visual Parent**: `DEVICE_StatusDetail`, `DEVICE_Configure`  
> **Refactor Goal**: Biến màn cài đặt quyền liên hệ thành một **trust-driven permission center**: dễ hiểu, dễ đổi, ít sợ sai, đồng bộ với style Home/Device.

---

## 1. Description

- **SRS Ref**: UC005, UC015, UC030
- **User Role**: User (self)
- **Purpose**: Cho phép user chỉnh các quyền mà **mình chia sẻ ra ngoài** cho một liên hệ cụ thể.

### 1.1. Problem Statement

Permission screen là nơi user dễ lo lắng nhất. Nếu wording và hierarchy không tốt:
- user không hiểu mình đang cho phép điều gì,
- dễ nhầm “quyền mình nhận” và “quyền mình cấp”,
- thao tác unlink dễ gây sợ,
- đổi toggle mà không có feedback rõ sẽ làm mất niềm tin.

### 1.2. Design Goal

- **Rất rõ đây là quyền tôi cấp ra**
- **Mỗi toggle phải dễ hiểu bằng ngôn ngữ đời thường**
- **Lưu mượt nhưng có feedback rõ**
- **Danger zone nghiêm túc nhưng không đe doạ**

---

## 2. User Flow

### 2.1. Primary Flow

1. User từ `PROFILE_ContactList` bấm một liên hệ.
2. App gọi `GET /api/mobile/contacts/{contact_id}`.
3. Hero đầu màn hiển thị:
   - avatar,
   - tên,
   - label,
   - relationship summary.
4. Bên dưới là 3 permission blocks:
   - xem chỉ số sức khoẻ,
   - nhận cảnh báo SOS,
   - xem vị trí khi SOS.
5. User bật/tắt toggle.
6. Screen gửi API update và hiển thị inline loading trong block.
7. Thành công:
   - hiện trạng thái mới,
   - optionally toast nhỏ.
8. User có thể đổi label.
9. User có thể `Huỷ liên kết` trong danger zone.

### 2.2. Unlink Flow

1. User bấm `Huỷ liên kết`.
2. Mở confirm dialog đỏ nhẹ, wording rõ.
3. User xác nhận.
4. Thành công:
   - pop về `PROFILE_ContactList`.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Đây là ai?
2. Tôi đang chia sẻ gì cho người này?
3. Nếu bật/tắt từng quyền thì điều gì xảy ra?
4. Tôi đổi nhãn hoặc huỷ liên kết ở đâu?

### Điều phải tránh

- Không hiển thị toggle trần trụi thiếu giải thích
- Không dùng từ ngữ kỹ thuật như một màn settings hệ thống
- Không để danger zone chen vào giữa các quyền

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải chi tiết contact | Hero skeleton + permission block skeleton |
| Initial | Có dữ liệu ổn định | Hero + 3 permission blocks + label chip + danger zone |
| Saving | Đang update một quyền | Chỉ block đang chỉnh chuyển loading |
| Error_Save | Update lỗi | Revert state + inline error / snackbar |
| Label_Editing | Đổi nhãn | Label picker bottom sheet |
| Unlink_Confirm | Xác nhận huỷ liên kết | Confirm dialog |
| Error | Không tải được chi tiết | Error block + Retry |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar(title: "Quyền chia sẻ")
└─ Body: ListView
   ├─ LinkedContactHeroCard
   ├─ SharingContextInfoBanner
   ├─ PermissionSectionHeader
   ├─ PermissionToggleCard(can_view_vitals)
   ├─ PermissionToggleCard(can_receive_alerts)
   ├─ PermissionToggleCard(can_view_location)
   ├─ LabelManagementCard
   ├─ DangerZoneSection
   │  └─ UnlinkActionCard
   └─ BottomSafeSpacer
```

### 5.1. New / Refined Widgets

- `LinkedContactHeroCard` — NEW
- `SharingContextInfoBanner` — NEW
- `PermissionToggleCard` — NEW
- `LabelManagementCard` — REFRESH
- `DangerZoneSection` — REFRESH
- `UnlinkConfirmDialog` — REFRESH

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ Quyền chia sẻ                              │
├────────────────────────────────────────────┤
│ [Avatar] Bố - Nguyễn Văn A                 │
│ Nhãn: Gia đình                             │
│ Bạn đang chia sẻ thông tin của mình cho Bố │
├────────────────────────────────────────────┤
│ Chỉ số sức khoẻ                            │
│ Cho phép xem nhịp tim, SpO₂, huyết áp      │
│                                     [ON]   │
├────────────────────────────────────────────┤
│ Cảnh báo SOS                               │
│ Bố sẽ nhận thông báo khi bạn phát SOS      │
│                                     [ON]   │
├────────────────────────────────────────────┤
│ Vị trí khi SOS                             │
│ Chỉ chia sẻ khi có tình huống khẩn cấp     │
│                                    [OFF]   │
├────────────────────────────────────────────┤
│ Nhãn liên hệ                       [Đổi]   │
├────────────────────────────────────────────┤
│ Khu vực nhạy cảm                           │
│ [ Huỷ liên kết ]                           │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn này nên là “configure screen” cùng họ với `DEVICE_Configure`:
- card-based,
- copy rõ ràng,
- tình huống nguy hiểm tách riêng,
- không có cảm giác “settings technical”.

### 7.2. Colors

| Token | Value | Usage |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | App background |
| `bg.surface` | `#FFFFFF` | Cards |
| `bg.elevated` | `#EEF4FF` | Hero / context banner |
| `text.primary` | `#12304A` | Main |
| `text.secondary` | `#5B7288` | Secondary |
| `brand.primary` | `#2F80ED` | Switch active / CTA |
| `danger.soft` | `#FDEEEE` | Danger zone background |
| `danger.text` | `#C94A4A` | Destructive action |

### 7.3. Typography

- Hero name: `22sp`
- Section title: `18-20sp`
- Permission title: `18sp`
- Description: `16sp`
- Caption: `14sp`

### 7.4. Spacing

- Screen padding: `16dp`
- Card padding: `18dp`
- Card gap: `12-16dp`
- Toggle row minimum height: `64dp`

---

## 8. Interaction & Behavior

| Trigger | Behavior | Duration |
| --- | --- | --- |
| Toggle change | Block-level loading state | 160ms |
| Save success | Inline success feedback / toast nhỏ | 120ms |
| Tap change label | Open label picker | 220ms |
| Tap unlink | Open confirm dialog | 180ms |

---

## 9. Permission Block Copy Guidance

### `can_view_vitals`

- Title: `Cho phép xem chỉ số sức khoẻ của tôi`
- Description: `Người này sẽ xem được nhịp tim, SpO₂, huyết áp và các chỉ số liên quan của bạn.`

### `can_receive_alerts`

- Title: `Cho phép nhận cảnh báo SOS của tôi`
- Description: `Người này sẽ nhận thông báo khi bạn phát tín hiệu khẩn cấp SOS.`

### `can_view_location`

- Title: `Cho phép xem vị trí của tôi khi SOS`
- Description: `Chỉ chia sẻ vị trí trong tình huống khẩn cấp để hỗ trợ tìm kiếm nhanh hơn.`

### UX Rule

- mô tả luôn ở ngôn ngữ đời thường,
- không viết bằng key kỹ thuật,
- luôn gắn hậu quả khi bật/tắt.

---

## 10. Accessibility Checklist

- [x] Toggle block >= 48dp touch target
- [x] Description đủ rõ, không cần dựa vào icon
- [x] Danger zone có title riêng
- [x] Text scaling 150-200% vẫn đọc tốt
- [x] Inline loading không làm layout nhảy mạnh

---

## 11. Design Rationale

| Decision | Reason |
| --- | --- |
| Hero + context banner | Giảm nhầm lẫn “mình cấp hay mình nhận quyền” |
| Mỗi quyền là một card riêng | User đọc từng quyền rõ hơn |
| Label tách riêng khỏi permission blocks | Tránh nhiễu |
| Danger zone xuống cuối màn | Hợp chuẩn mental model và an toàn hơn |

---

## 12. Edge Cases Handled

- [x] Spam toggle liên tục
- [x] Update lỗi mạng
- [x] Contact detail không load được
- [x] Đổi label ngay tại màn
- [x] Unlink action là destructive

---

## 13. Dependencies

### 13.1. API / State

- `GET /api/mobile/contacts/{contact_id}`
- `PATCH /api/mobile/contacts/{contact_id}/permissions`
- `PATCH /api/mobile/contacts/{contact_id}/label`
- `DELETE /api/mobile/contacts/{contact_id}`

### 13.2. Cross-module effects

- Toggle `can_receive_alerts` -> update FCM topic subscription
- Toggle `can_view_vitals` -> invalidates viewer's access profile cache

### 13.3. Shared Widgets

- `PermissionToggleCard`
- `LabelPickerBottomSheet`
- `UnlinkConfirmDialog`

---

## 14. Recommended File Structure

- `lib/features/family/screens/linked_contact_detail_screen.dart`
- `lib/features/family/widgets/linked_contact_hero_card.dart`
- `lib/features/family/widgets/sharing_context_info_banner.dart`
- `lib/features/family/widgets/permission_toggle_card.dart`
- `lib/features/family/widgets/label_management_card.dart`
- `lib/features/family/widgets/unlink_confirm_dialog.dart`

---

## 15. Dev Implementation Sequence

1. Build hero + context banner
2. Build 3 permission toggle cards
3. Add block-level loading / error revert logic
4. Add label management card
5. Add danger zone + confirm dialog
6. Wire side effects for permission updates

---

## 16. Acceptance Criteria

- [ ] User hiểu rõ đang chia sẻ quyền của mình cho ai
- [ ] 3 quyền đều có wording đời thường, dễ hiểu
- [ ] Update toggle có feedback rõ, không mơ hồ
- [ ] Danger zone an toàn và đủ nghiêm túc
- [ ] Visual style đồng bộ với `DEVICE_Configure`

---

## 17. Out of Scope

- Contact list regrouping logic sau update
- Family dashboard update visuals sau permission change

---

## 18. Confidence Score

- **Plan Confidence: 97%**
- **Reasoning**: Đây là màn cấu hình quyền điển hình; design direction và interaction pattern rất rõ sau khi đồng bộ với `DEVICE_Configure`.
