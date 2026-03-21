# 📐 UI Plan: DEVICE_List Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [DEVICE_List.md](../DEVICE_List.md)  
> **Existing Code**: `health_system/lib/features/device/screens/device_screen.dart`  
> **Refactor Goal**: Nâng `DEVICE_List` từ màn list CRUD/basic lên một **device health center** cùng đẳng cấp visual và UX với `HOME_Dashboard`.

---

## 1. Description

- **SRS Ref**: UC040, UC041, UC042
- **User Role**: User (self only)
- **Purpose**: Tạo lại màn `Thiết bị` để user chỉ mất 3-5 giây là hiểu:
  1. Tôi có bao nhiêu thiết bị?
  2. Thiết bị nào đang ổn?
  3. Thiết bị nào cần xử lý ngay?

### 1.1. Problem Statement

**Màn hiện tại chạy được nhưng chưa đủ "product-grade"**:
- quá nhiều thành phần có cùng trọng lượng thị giác,
- card thiết bị còn mang cảm giác list admin,
- warning chưa đủ mạnh,
- FAB đè nội dung,
- visual language chưa tương xứng với `HOME_Dashboard`.

### 1.2. Design Goal

Refactor màn `DEVICE_List` theo hướng:
- **State-first** thay vì data-first,
- **Consumer app** thay vì utility/admin screen,
- **Calm but informative** giống `HOME_Dashboard`,
- **Self-only hub** cho toàn bộ module DEVICE.

### 1.3. Success Criteria Summary

Sau refactor, user phải:
- nhìn là biết có vấn đề hay không,
- bấm được đúng card cần xử lý,
- thấy màn `Thiết bị` cùng chất lượng với `Home`,
- không bị overwhelm bởi chip/badge/filter/FAB.

---

## 2. User Flow

### 2.1. Primary Flow

1. User mở tab `Thiết bị`.
2. App fetch self device list.
3. Hero summary trả lời ngay:
   - tổng số thiết bị,
   - số thiết bị đang hoạt động tốt,
   - số thiết bị cần chú ý.
4. Nếu có thiết bị cần xử lý:
   - hiển thị `Attention Zone` ngay dưới hero.
5. Danh sách card được sắp xếp theo ưu tiên:
   - thiết bị lỗi / offline lâu / pin yếu,
   - thiết bị bình thường,
   - thiết bị mới thêm / ít quan trọng hơn.
6. User bấm card để vào `DEVICE_StatusDetail`.
7. User bấm CTA chính để vào `DEVICE_Connect`.

### 2.2. Secondary Flow

1. User muốn lọc theo trạng thái hoặc loại.
2. Filter chỉ xuất hiện như công cụ phụ, không giành spotlight với hero và attention zone.
3. Khi user filter:
   - list update mượt,
   - attention context vẫn giữ được nếu còn liên quan.

### 2.3. Empty / First-Time Flow

1. User chưa có thiết bị nào.
2. Hero đổi sang trạng thái onboarding nhẹ.
3. Empty state giải thích rõ:
   - tại sao cần kết nối thiết bị,
   - 1 CTA chính `Kết nối thiết bị mới`.

### 2.4. Error / Offline Flow

1. Nếu lỗi mạng nhưng có cache:
   - vẫn giữ content cũ,
   - hiện banner `Đang xem dữ liệu đã lưu`.
2. Nếu lỗi mạng và không có dữ liệu:
   - hiển thị error state chuẩn, không chỉ snackbar.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. **Tổng quan tình trạng thiết bị**
2. **Thiết bị nào cần chú ý**
3. **Card thiết bị ưu tiên cao**
4. **Công cụ lọc**
5. **CTA thêm thiết bị**

### Những gì phải giảm nhấn mạnh

- Dropdown/filter không được đứng ngang hàng với hero.
- Chip thông số trong card không được dày đặc như hiện tại.
- FAB không được che nội dung hoặc cắt nhịp cuộn.

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải lần đầu | Hero skeleton + attention skeleton + 2 card skeleton |
| Empty | Chưa có thiết bị | Empty onboarding state + CTA connect |
| Success_Normal | Tất cả thiết bị ổn | Hero xanh calm + list card sạch |
| Success_Attention | Có 1+ thiết bị cần chú ý | Hero vẫn ổn định, `Attention Zone` rõ, cards lỗi được đẩy lên đầu |
| Success_AllOffline | Tất cả offline | Hero chuyển semantic warning, giải thích rõ `thiết bị đang mất kết nối` |
| OfflineCache | Mất mạng nhưng có cache | Banner info + dữ liệu cũ giữ nguyên |
| Error | Không có dữ liệu và API fail | Error state card + Retry |
| Filtered | User đang lọc | List có filtered label nhẹ, không phá hierarchy |

---

## 5. Widget Tree (proposed)

```text
MainScaffoldShell
└─ Scaffold
   ├─ AppBar
   │  ├─ Title("Thiết bị")
   │  ├─ Optional Debug Action (dev only)
   │  └─ Refresh Action
   ├─ Body: RefreshIndicator
   │  └─ ListView
   │     ├─ DeviceHealthHeroCard
   │     ├─ AttentionZoneCard (optional)
   │     ├─ FilterToolbar (secondary)
   │     ├─ [Empty] DeviceOnboardingEmptyState
   │     └─ [Success] DeviceCardList
   │        └─ DevicePriorityCard*
   └─ Bottom CTA Area
      └─ AddDevicePrimaryAction
```

### 5.1. New / Refined Widgets

- `DeviceHealthHeroCard` — NEW
- `AttentionZoneCard` — NEW
- `DevicePriorityCard` — refactor từ `DeviceListCard`
- `FilterToolbar` — refine
- `DeviceOnboardingEmptyState` — refine từ `EmptyDeviceState`
- `AddDevicePrimaryAction` — NEW/refactor thay vì FAB đè card

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ Thiết bị                              [↻] │
├────────────────────────────────────────────┤
│  Thiết bị của bạn                         │
│  3 thiết bị đang hoạt động tốt            │
│                                            │
│  [ 5 Tổng ] [ 3 Ổn định ] [ 2 Cần chú ý ] │
├────────────────────────────────────────────┤
│  ⚠ Cần kiểm tra ngay                      │
│  Có 2 thiết bị đang pin yếu hoặc sync chậm│
│  [Xem thiết bị cần chú ý]                 │
├────────────────────────────────────────────┤
│  [Tất cả] [Ổn định] [Cần chú ý] [Offline] │
│  [Tất cả loại ▼]                           │
├────────────────────────────────────────────┤
│  Health Band B2                 [Online]  │
│  Pin yếu • Đồng bộ 1h trước               │
│  [Pin 12%] [RSSI -67] [Kiểm tra ngay →]   │
├────────────────────────────────────────────┤
│  Thiết bị #105                 [Online]   │
│  Hoạt động ổn định                         │
│  [Pin 84%] [Đồng bộ vài phút trước]       │
├────────────────────────────────────────────┤
│      [ + Kết nối thiết bị mới ]           │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Refactor theo cùng family với `HOME_Dashboard`:
- nền sáng, sạch, thoáng,
- hero card có cảm giác premium, không phải stat box admin,
- semantic color tiết chế,
- card ít noise hơn, hierarchy mạnh hơn.

### 7.2. Colors

| Role | Token / Value | Usage in this screen |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Nền màn |
| `bg.surface` | `#FFFFFF` | Card, filter, dropdown |
| `brand.primary` | `#0F766E` | Hero accent, CTA |
| `brand.soft` | `#E6FFFB` | Hero inner blocks, icon bg |
| `success` | `#0F9D7A` | Healthy status |
| `warning` | `#F2A93B` | Needs attention |
| `critical` | `#D97706` hoặc `#E67E22` | Stronger attention without panic |
| `offline` | `#94A3B8` | Offline status |
| `text.primary` | `#12304A` | Title / content |
| `text.secondary` | `#5B7288` | Metadata |

### 7.3. Typography

| Element | Size | Weight | Color |
| --- | --- | --- | --- |
| Screen title | 22sp | 700 | `text.primary` |
| Hero title | 24sp | 700 | white / high contrast |
| Hero metric | 24sp | 800 | white |
| Attention title | 18sp | 700 | `warning/critical` |
| Card title | 19sp | 700 | `text.primary` |
| Card subtitle | 16sp | 400 | `text.secondary` |
| Pill text | 14sp | 600 | semantic |
| CTA label | 17-18sp | 700 | white |

### 7.4. Spacing

- Horizontal padding: `16dp`
- Hero padding: `20dp`
- Major section gap: `16-20dp`
- Card padding: `18dp`
- Card gap: `14dp`
- Bottom CTA min height: `56dp`

---

## 8. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
| --- | --- | --- |
| Loading -> success | Crossfade skeleton to content | 180ms |
| Hero metric refresh | Subtle count/fade update | 200ms |
| Attention zone appear | Slide down + fade | 180ms |
| Filter change | Quick fade-through, no layout jump | 150ms |
| Card tap | Material ripple + route push | system |
| CTA pressed | Scale 0.98 + haptic light | 120ms |

---

## 9. Accessibility Checklist

- [x] Body text >= `16sp`
- [x] Badge và trạng thái không chỉ dựa vào màu
- [x] Card có touch target đủ rộng
- [x] Bottom CTA >= `56dp`
- [x] Text scaling `150-200%` không vỡ hero/card
- [x] Attention zone có text rõ, không chỉ icon
- [x] Online/Offline/Pin yếu đều có semantic labels cho screen reader
- [x] Không đưa MAC/MQTT/serial lên surface level

---

## 10. Design Rationale

| Decision | Reason |
| --- | --- |
| Dùng `DeviceHealthHeroCard` thay `overview card` hiện tại | Hero cần cùng đẳng cấp với `Home`, không chỉ là 3 stat box |
| Tách `Attention Zone` riêng | Đây là insight quan trọng nhất sau hero |
| Refactor card sang `status-first` | User vào tab này để biết thiết bị còn ổn không, không phải để đọc metadata |
| Hạ cấp visual của filter | Filter là secondary control, không phải nội dung chính |
| Bỏ FAB nổi đè card | FAB hiện tại làm bố cục rối và che nội dung |
| Giữ self-only context | Phù hợp kiến trúc Hybrid và tránh mơ hồ với tab Gia đình |

---

## 11. Edge Cases Handled

- [x] Tất cả thiết bị offline
- [x] Có cache nhưng đang mất mạng
- [x] Device bị xoá từ backend sau refresh
- [x] Pin / RSSI / sync data thiếu hoặc null
- [x] User bấm filter liên tục
- [x] User có nhiều thiết bị attention cùng lúc
- [x] Không có thiết bị nào nhưng vẫn phải thấy CTA rõ
- [x] Mở sai linked/family context

---

## 12. Dependencies

### 12.1. Shared Widgets Needed

- `DeviceHealthHeroCard` — NEW
- `AttentionZoneCard` — NEW
- `DevicePriorityCard` — refactor từ `DeviceListCard`
- `FilterToolbar` — NEW/refine
- `DeviceOnboardingEmptyState` — refine
- `AddDevicePrimaryAction` — NEW

### 12.2. API / State

- `GET /api/mobile/devices`
- Reuse `DeviceProvider`, nhưng thêm:
  - `needsAttentionDevices`
  - `healthyCount`
  - sorting rule theo severity
  - cached-data timestamp nếu có

### 12.3. Navigation

- Tap card -> `DEVICE_StatusDetail`
- Primary add action -> `DEVICE_Connect`
- Manual fallback dialog chỉ giữ cho dev/test, không phải CTA surface chính

---

## 13. Recommended File Structure

- `lib/features/device/screens/device_screen.dart`
- `lib/features/device/widgets/device_list/device_health_hero_card.dart`
- `lib/features/device/widgets/device_list/attention_zone_card.dart`
- `lib/features/device/widgets/device_list/device_priority_card.dart`
- `lib/features/device/widgets/device_list/filter_toolbar.dart`
- `lib/features/device/widgets/device_list/device_onboarding_empty_state.dart`
- `lib/features/device/widgets/device_list/add_device_primary_action.dart`

---

## 14. Dev Implementation Sequence

1. **Refactor information hierarchy first**
   - di chuyển `overview` thành hero mới,
   - thiết lập order: hero -> attention -> filter -> list -> CTA.
2. **Thay FAB bằng bottom CTA hoặc in-flow CTA**
   - không để che card.
3. **Tạo `AttentionZoneCard`**
   - summary số lượng device cần chú ý,
   - optional CTA filter nhanh.
4. **Refactor `DeviceListCard` -> `DevicePriorityCard`**
   - status-first,
   - giảm số pill/badge,
   - tăng hierarchy cho pin/offline/sync.
5. **Refactor `EmptyDeviceState`**
   - đưa về kiểu onboarding nhẹ, cùng style `Home`.
6. **Refine filter**
   - secondary visual,
   - không chiếm spotlight.
7. **Bổ sung state `OfflineCache` và `AllOffline`**
   - giữ dữ liệu cũ có timestamp.
8. **Thêm semantic sorting**
   - attention devices lên đầu.
9. **Polish animation + accessibility**
   - text scaling,
   - semantics,
   - touch targets.

---

## 15. Acceptance Criteria

- [ ] Màn `Thiết bị` có hero card cùng đẳng cấp visual với `Home`
- [ ] Có khu `Cần chú ý` rõ ràng khi tồn tại thiết bị lỗi
- [ ] Device card ưu tiên trạng thái thay vì metadata
- [ ] Không còn FAB đè lên card list
- [ ] Filter nhìn là secondary control
- [ ] Empty state có cảm giác onboarding, không phải placeholder
- [ ] User vào màn trong 3-5 giây biết ngay có thiết bị nào cần xử lý
- [ ] Text scaling 150-200% vẫn usable
- [ ] Điều hướng sang `Connect` và `StatusDetail` vẫn mượt, rõ

---

## 16. Out of Scope

- Refactor toàn bộ `DEVICE_StatusDetail`
- Refactor `DEVICE_Connect`
- Backend contract lớn cho module device
- Family-owned device monitoring từ tab `Gia đình`

---

## 17. Confidence Score

- **Plan Confidence: 97%**
- **Reasoning**: Có đủ context từ spec, code hiện tại, và chênh lệch thị giác rất rõ giữa `DEVICE_List` và `HOME_Dashboard` để đưa ra một plan refactor hoàn chỉnh, khả thi, có thể build theo phase.
- **Uncertainties**:
  - `pendingSync` là field backend thật hay cần derive.
  - Team muốn CTA cuối màn theo dạng sticky bottom hay inline action.
