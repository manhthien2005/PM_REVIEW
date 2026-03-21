# 📐 UI Plan: PROFILE_ContactList Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [PROFILE_ContactList.md](../PROFILE_ContactList.md)  
> **Visual Parent**: `HOME_Dashboard`, `DEVICE_List`  
> **Refactor Goal**: Biến `Danh bạ liên kết` thành một **trust-first relationship management screen**: rõ pending, rõ liên hệ đã liên kết, rõ quyền, và đồng bộ style `HealthGuard Calm`.

---

## 1. Description

- **SRS Ref**: UC005, UC030
- **User Role**: User (self-managing linked profiles)
- **Purpose**: Quản lý toàn bộ kết nối gia đình/người thân/bác sĩ theo logic `Linked Profiles`.

### 1.1. Problem Statement

Code hiện tại có nhiều chức năng, nhưng trải nghiệm đang bị chia nhỏ:
- pending nằm chung với search flow,
- hierarchy chưa rõ đâu là “việc cần xử lý ngay”,
- chưa có trust cues đủ mạnh cho người lớn tuổi,
- visual system chưa đồng bộ với Home / Device refactor.

### 1.2. Design Goal

- **Pending requests phải nổi bật nhưng không ồn**
- **Accepted contacts phải dễ lướt, dễ nhận diện**
- **Liên kết và quyền chia sẻ phải tạo cảm giác an toàn**
- **Màn này là hub điều hướng của toàn bộ module Family / Contacts**

---

## 2. User Flow

### 2.1. Primary Flow

1. User mở `Danh bạ liên kết`.
2. App tải:
   - pending requests,
   - accepted contacts.
3. Hero đầu màn hiển thị:
   - tổng số liên hệ,
   - số lời mời đang chờ,
   - CTA `Thêm liên hệ`.
4. Nếu có pending:
   - section `Cần xử lý` hiển thị ngay dưới hero.
5. Bên dưới là list accepted contacts theo label:
   - Gia đình,
   - Bác sĩ,
   - Bạn bè,
   - Chưa phân loại.
6. Tap contact:
   - vào `PROFILE_LinkedContactDetail`.
7. Tap `Thêm liên hệ`:
   - vào `PROFILE_AddContact`.

### 2.2. Accept Flow

1. User bấm `Xác nhận` ở pending card.
2. Mở `PermissionSetupBottomSheet`.
3. User chọn quyền chia sẻ mặc định an toàn.
4. Bấm `Xác nhận`.
5. Contact chuyển từ pending sang accepted section.

### 2.3. Empty Flow

1. Chưa có liên hệ nào.
2. Hiển thị empty state:
   - giải thích ngắn,
   - CTA lớn `Thêm liên hệ`.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Tôi có lời mời nào cần xử lý không?
2. Tôi đang liên kết với bao nhiêu người?
3. Những người quan trọng nhất là ai?
4. Tôi thêm liên hệ mới ở đâu?

### Điều phải tránh

- Không nhét search, pending, accepted vào cùng một logic list mơ hồ
- Không để người già đọc không hiểu “ai đã kết nối / ai đang chờ”
- Không để thao tác accept/reject quá nhỏ hoặc quá gần nhau

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải lần đầu | Hero skeleton + pending skeleton + list skeleton |
| Success_WithPending | Có pending requests | Hero + pending section + grouped contacts |
| Success_NoPending | Chỉ có accepted contacts | Hero + grouped contacts |
| Empty | Chưa có liên hệ nào | Empty state + CTA |
| Error | API lỗi | Error block + Retry |
| OfflineCache | Offline nhưng có cache | Banner info + cache content |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ Title("Danh bạ liên kết")
│  └─ Add action
└─ Body: RefreshIndicator
   └─ ListView
      ├─ LinkedContactsHeroCard
      ├─ PendingRequestsSection (optional)
      │  └─ PendingRequestCard*
      ├─ ContactsSectionHeader*
      ├─ GroupedContactsSection*
      │  └─ LinkedContactCard*
      ├─ EmptyState (optional)
      └─ BottomSafeSpacer
```

### 5.1. New / Refined Widgets

- `LinkedContactsHeroCard` — NEW
- `PendingRequestsSection` — NEW
- `PendingRequestCard` — REFRESH
- `LinkedContactCard` — REFRESH
- `ContactsGroupHeader` — NEW
- `PermissionSetupBottomSheet` — REFRESH
- `LinkedContactsEmptyState` — NEW

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ Danh bạ liên kết                    [+]    │
├────────────────────────────────────────────┤
│  Liên kết của bạn                         │
│  6 liên hệ • 2 yêu cầu chờ xử lý          │
│  [ Thêm liên hệ mới ]                     │
├────────────────────────────────────────────┤
│  Cần xử lý ngay                            │
│  [Avatar] Nguyễn Văn C                     │
│  Muốn kết nối với bạn                      │
│  [Hủy] [Xác nhận]                          │
├────────────────────────────────────────────┤
│  Gia đình                                  │
│  [Avatar] Bố - Nguyễn Văn A        [Xem →] │
│  Nhận SOS • Được xem chỉ số                │
├────────────────────────────────────────────┤
│  Bác sĩ                                    │
│  [Avatar] BS Trần B                [Xem →] │
│  Chỉ nhận cảnh báo                         │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn này không nên trông giống “settings list”. Nó cần:
- có hero nhẹ như Home/Device,
- có pending block rõ ràng,
- contact card sạch, ấm, thân thiện,
- giữ tone an toàn và tin cậy.

### 7.2. Colors

| Token | Value | Usage |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | App background |
| `bg.surface` | `#FFFFFF` | Default cards |
| `bg.elevated` | `#EEF4FF` | Hero |
| `bg.pending` | `#FFF6E9` | Pending section |
| `text.primary` | `#12304A` | Main text |
| `text.secondary` | `#5B7288` | Metadata |
| `brand.primary` | `#2F80ED` | CTA |
| `warning` | `#F2A93B` | Pending / caution |
| `success` | `#2E9B6F` | Accepted / positive |

### 7.3. Typography

- Hero title: `24sp`
- Section title: `20sp`
- Contact name: `18sp`
- Permission summary: `16sp`
- Caption: `14sp`

### 7.4. Spacing

- Screen padding: `16dp`
- Hero/card radius: `20dp`
- Action button height: `48-52dp`
- Section gap: `16dp`

---

## 8. Interaction & Behavior

| Trigger | Behavior | Duration |
| --- | --- | --- |
| Tap `Xác nhận` | Open `PermissionSetupBottomSheet` | 220ms |
| Accept success | Card transitions to accepted list | 200ms |
| Reject success | Card fades out | 180ms |
| Tap contact | Push detail route | system |
| Pull to refresh | Refresh data | system |

---

## 9. Permission Setup Bottom Sheet Spec

### Structure

- Title: `Bạn muốn chia sẻ gì với [Tên]?`
- Supporting text: giải thích đây là quyền user cấp ra ngoài
- 3 toggle blocks:
  - `can_view_vitals`
  - `can_receive_alerts`
  - `can_view_location`
- CTA row:
  - `Cài sau`
  - `Xác nhận`

### UX Rules

- default an toàn:
  - `can_view_vitals = OFF`
  - `can_receive_alerts = ON`
  - `can_view_location = ON`
- mỗi toggle có description 1 dòng
- action buttons phải đủ lớn, không quá sát nhau

---

## 10. Accessibility Checklist

- [x] Nút `Hủy` / `Xác nhận` >= 48dp
- [x] Body text >= 16sp
- [x] Pending state không chỉ dựa vào màu
- [x] Group headers rõ ràng cho screen reader
- [x] Empty state CTA rõ và lớn
- [x] Text scaling 150-200% không vỡ layout

---

## 11. Design Rationale

| Decision | Reason |
| --- | --- |
| Hero tóm tắt liên kết | Tạo context nhanh thay vì vào màn là list ngay |
| Pending section đặt trên accepted list | Ưu tiên việc cần xử lý |
| Grouped accepted contacts | Dễ hiểu hơn list phẳng |
| Permission bottom sheet ngay lúc accept | Tạo trust và giảm việc quên cấu hình |

---

## 12. Edge Cases Handled

- [x] Accept/reject lỗi mạng
- [x] Không có nhãn -> `Chưa phân loại`
- [x] User bấm `Cài sau`
- [x] Pending nhiều nhưng accepted rỗng
- [x] Offline nhưng có cache

---

## 13. Dependencies

### 13.1. API / State

- `GET /api/mobile/contacts`
- `GET /api/mobile/contacts/pending`
- `POST /api/mobile/contacts/{id}/accept`
- `POST /api/mobile/contacts/{id}/reject`

### 13.2. Navigation

- Push `PROFILE_AddContact`
- Push `PROFILE_LinkedContactDetail`

### 13.3. Shared Widgets

- `LinkedContactsHeroCard`
- `PendingRequestCard`
- `LinkedContactCard`
- `PermissionSetupBottomSheet`

---

## 14. Recommended File Structure

- `lib/features/family/screens/contact_list_screen.dart`
- `lib/features/family/widgets/linked_contacts_hero_card.dart`
- `lib/features/family/widgets/pending_request_card.dart`
- `lib/features/family/widgets/linked_contact_card.dart`
- `lib/features/family/widgets/permission_setup_bottom_sheet.dart`

---

## 15. Dev Implementation Sequence

1. Build hero + empty/error/loading states
2. Build pending request section
3. Build grouped accepted contacts section
4. Build `PermissionSetupBottomSheet`
5. Wire accept/reject + regrouping after success
6. Hook navigation to `AddContact` and `LinkedContactDetail`

---

## 16. Acceptance Criteria

- [ ] Pending requests nằm ở vị trí ưu tiên và dễ thao tác
- [ ] Accepted contacts được nhóm rõ ràng
- [ ] Màn hình cùng visual style với Home/Device
- [ ] Permission setup tạo cảm giác an toàn, không mơ hồ
- [ ] Empty state và CTA thêm liên hệ rõ

---

## 17. Out of Scope

- QR scanner implementation chi tiết
- Detail permission screen implementation
- Family dashboard implementation

---

## 18. Confidence Score

- **Plan Confidence: 96%**
- **Reasoning**: Đây là hub trung tâm của module; spec nghiệp vụ đủ rõ, chỉ cần chuẩn hoá hierarchy và design language.
