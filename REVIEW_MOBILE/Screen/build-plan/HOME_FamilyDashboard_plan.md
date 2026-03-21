# 📐 UI Plan: HOME_FamilyDashboard Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [HOME_FamilyDashboard.md](../HOME_FamilyDashboard.md)  
> **Visual Parent**: `HOME_Dashboard` (`HealthGuard Calm`)  
> **Refactor Goal**: Xây `Gia đình` thành một **family health center** cùng visual language với `HOME_Dashboard`, nhưng tối ưu cho vai trò theo dõi nhiều người thân.

---

## 1. Description

- **SRS Ref**: UC006, UC015, UC030
- **User Role**: User (linked-family viewer)
- **Purpose**: Tạo màn tổng quan người thân giúp user trả lời thật nhanh:
  1. Hôm nay ai đang ổn?
  2. Ai đang cần chú ý?
  3. Có ai đang SOS không?

### 1.1. Problem Statement

Spec hiện tại đúng hướng nghiệp vụ, nhưng chưa đủ chặt về hierarchy và visual parity với `HOME_Dashboard`:
- cần cùng family design, không như một tab rời rạc,
- cần ưu tiên SOS và người có vấn đề lên trước,
- cần rõ empty state và quyền theo dõi,
- cần tránh việc card quá dày thông tin gây rối cho người lớn tuổi.

### 1.2. Design Goal

- **Bird's-eye, not cluttered**
- **SOS first, monitoring second**
- **Linked-profile clarity**
- **Cùng hệ thiết kế với `HOME_Dashboard`**

---

## 2. User Flow

### 2.1. Primary Flow

1. User bấm tab `Gia đình` trên bottom nav.
2. App gọi `GET /api/mobile/family-dashboard`.
3. Hero đầu màn hiển thị:
   - số người thân đang theo dõi,
   - số người đang ổn,
   - số người cần chú ý,
   - badge/summary SOS nếu có.
4. Nếu có active SOS:
   - hiển thị `FamilySOSPriorityBanner` trên cùng danh sách.
5. Danh sách profile card được sắp xếp:
   - SOS active,
   - cần chú ý,
   - bình thường.
6. User bấm card người thân:
   - vào drill-down monitoring/sleep/risk qua `profileId`.
7. User bấm CTA `Quản lý liên hệ`:
   - chuyển sang `PROFILE_ContactList`.

### 2.2. Empty Flow

1. User chưa có linked profile nào.
2. Hero chuyển sang state onboarding nhẹ.
3. Empty state giải thích:
   - cần liên kết người thân để theo dõi,
   - CTA `Liên kết người thân`.

### 2.3. Permission-Limited Flow

1. User có liên kết nhưng không có `can_view_vitals`.
2. Hiển thị `LockedProfileCard`:
   - avatar + tên,
   - text giải thích chưa được cấp quyền,
   - CTA `Quản lý quyền`.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Có ai đang SOS không?
2. Tổng quan gia đình hôm nay ra sao?
3. Ai cần chú ý nhất?
4. Từng người đang ổn / không ổn như thế nào?
5. Tôi có thể quản lý liên kết ở đâu?

### Điều phải tránh

- Không để mọi card có trọng số như nhau
- Không biến tab này thành list “contacts with vitals”
- Không để alert và normal card có cùng visual emphasis

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải lần đầu | Hero skeleton + profile card skeleton |
| Success_Normal | Có linked profiles, không có SOS | Hero calm + list người thân |
| Success_Attention | Có người cần chú ý | Hero vẫn ổn định, `AttentionSummaryBanner` + priority cards |
| Success_SOS_Active | Có SOS active | `FamilySOSPriorityBanner` + SOS cards ở đầu |
| Empty | Chưa liên kết ai | Empty onboarding state + CTA `Liên kết người thân` |
| Perm_Denied | Có liên kết nhưng chưa được chia sẻ vitals | Locked card / message card |
| OfflineCache | Offline nhưng có cache | Banner info + content cũ |
| Error | Lỗi và không có cache | Error card + Retry |

---

## 5. Widget Tree (proposed)

```text
MainScaffoldShell
└─ Scaffold
   ├─ AppBar
   │  ├─ Title("Gia đình")
   │  └─ Notification / manage action (optional)
   ├─ Body: RefreshIndicator
   │  └─ ListView
   │     ├─ FamilyHealthHeroCard
   │     ├─ FamilySOSPriorityBanner (optional)
   │     ├─ FamilyAttentionSummaryBanner (optional)
   │     ├─ FamilyFilterChips (optional / secondary)
   │     ├─ [Empty] FamilyOnboardingEmptyState
   │     ├─ [Locked] LockedProfileCard*
   │     └─ [Success] FamilyProfileHealthCard*
   └─ Bottom CTA area / inline section footer
      └─ ManageLinkedContactsAction
```

### 5.1. New / Refined Widgets

- `FamilyHealthHeroCard` — NEW
- `FamilySOSPriorityBanner` — NEW
- `FamilyAttentionSummaryBanner` — NEW
- `FamilyProfileHealthCard` — NEW
- `LockedProfileCard` — NEW
- `FamilyOnboardingEmptyState` — NEW
- `ManageLinkedContactsAction` — NEW

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ Gia đình                              [•] │
├────────────────────────────────────────────┤
│  Gia đình của bạn                         │
│  4 người đang được theo dõi               │
│  [ 4 Tổng ] [ 2 Ổn định ] [ 1 Cần chú ý ] │
├────────────────────────────────────────────┤
│  🆘 Có 1 người đang cần trợ giúp ngay      │
│  [Xem SOS hiện tại]                       │
├────────────────────────────────────────────┤
│  Bố — Nguyễn Văn A                        │
│  Nhịp tim 82 • SpO₂ 97% • Risk thấp       │
│  Cập nhật 2 phút trước         [Xem →]    │
├────────────────────────────────────────────┤
│  Mẹ — Trần Thị B                ⚠         │
│  Huyết áp cần theo dõi                    │
│  Cập nhật 8 phút trước         [Xem →]    │
├────────────────────────────────────────────┤
│      [ Quản lý liên hệ & quyền xem ]      │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn này phải là “người anh em” của `HOME_Dashboard`:
- cùng nền sáng,
- cùng hero elevated,
- cùng semantic color restraint,
- cùng typography system,
- nhưng nhiều card hơn và ưu tiên SOS mạnh hơn.

### 7.2. Colors

| Token | Value | Usage |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Nền app |
| `bg.surface` | `#FFFFFF` | Card chính |
| `bg.elevated` | `#EEF4FF` | Hero / elevated card |
| `text.primary` | `#12304A` | Nội dung chính |
| `text.secondary` | `#5B7288` | Metadata |
| `brand.primary` | `#2F80ED` | CTA phụ / active tab |
| `success` | `#2E9B6F` | Normal |
| `warning` | `#F2A93B` | Attention |
| `critical` | `#D95C5C` | SOS / critical |

### 7.3. Typography

| Element | Size | Weight |
| --- | --- | --- |
| Screen title | 22sp | 700 |
| Hero title | 24sp | 700 |
| Hero metric | 24sp | 800 |
| Card name | 18sp | 700 |
| Vital / summary text | 16sp | 400/600 |
| Caption | 14sp | 400 |

### 7.4. Spacing

- Screen padding: `16dp`
- Hero padding: `20dp`
- Section gap: `16-20dp`
- Card padding: `18dp`
- CTA height: `56dp`

---

## 8. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
| --- | --- | --- |
| Loading -> success | Crossfade | 180ms |
| SOS banner appear | Slide down + subtle pulse | 220ms |
| Attention summary appear | Slide down | 180ms |
| Card tap | Ripple + route push | system |

---

## 9. Accessibility Checklist

- [x] Font body >= 16sp
- [x] Card tap targets >= 48dp
- [x] SOS state không chỉ dựa vào màu
- [x] Text scaling 150-200% không vỡ card layout
- [x] Screen reader đọc được tên profile + trạng thái + last updated
- [x] Empty state CTA đủ lớn và rõ

---

## 10. Design Rationale

| Decision | Reason |
| --- | --- |
| `FamilyHealthHeroCard` riêng | Gia đình cần summary khác với self dashboard |
| SOS banner tách riêng | SOS phải là tín hiệu ưu tiên tuyệt đối |
| Priority sorting | Người dùng theo dõi nhiều người phải thấy ai cần chú ý trước |
| CTA quản lý liên hệ ở cuối màn | Kết nối rõ với flow Liên hệ mà không làm loãng nhiệm vụ monitor |

---

## 11. Edge Cases Handled

- [x] Nhiều SOS cùng lúc
- [x] Có profile nhưng chưa được cấp quyền xem
- [x] Không có profile nào
- [x] Dữ liệu invalid (`HR=0`, sensor rời)
- [x] Offline cache
- [x] Text scaling 150-200%

---

## 12. Dependencies

### 12.1. Shared Widgets Needed

- `FamilyHealthHeroCard`
- `FamilySOSPriorityBanner`
- `FamilyAttentionSummaryBanner`
- `FamilyProfileHealthCard`
- `LockedProfileCard`
- `FamilyOnboardingEmptyState`

### 12.2. API / State

- `GET /api/mobile/family-dashboard`
- `GET /api/mobile/access-profiles`
- Polling every 30s when active
- FCM hook for SOS badge update

### 12.3. Navigation

- Drill-down to `VitalDetail(profileId)`
- Drill-down to `SleepReport(profileId)`
- Drill-down to `RiskReport(profileId)`
- CTA to `PROFILE_ContactList`

---

## 13. Recommended File Structure

- `lib/features/family/screens/family_dashboard_screen.dart`
- `lib/features/family/providers/family_dashboard_provider.dart`
- `lib/features/family/widgets/family_health_hero_card.dart`
- `lib/features/family/widgets/family_sos_priority_banner.dart`
- `lib/features/family/widgets/family_profile_health_card.dart`
- `lib/features/family/widgets/family_onboarding_empty_state.dart`

---

## 14. Dev Implementation Sequence

1. Build `FamilyHealthHeroCard`
2. Build `FamilyProfileHealthCard` with priority sorting
3. Add `SOSPriorityBanner` + `AttentionSummaryBanner`
4. Wire polling + cache + FCM badge
5. Hook CTA to `PROFILE_ContactList`
6. Accessibility / text scaling polish

---

## 15. Acceptance Criteria

- [ ] Tab `Gia đình` cùng visual family với `HOME_Dashboard`
- [ ] SOS state cực rõ và lên đầu
- [ ] User thấy ngay ai cần chú ý
- [ ] Empty state dẫn đúng sang `PROFILE_ContactList`
- [ ] Linked profile cards không quá dày thông tin

---

## 16. Out of Scope

- Full implementation của `PROFILE_ContactList`
- Risk / Sleep detail screens
- SOS War Room screen

---

## 17. Confidence Score

- **Plan Confidence: 95%**
- **Reasoning**: Spec nghiệp vụ đã khá rõ; trọng tâm là tổ chức hierarchy và đồng bộ design language với `HOME_Dashboard`.
- **Uncertainties**:
  - API shape cuối cùng của `family-dashboard`
