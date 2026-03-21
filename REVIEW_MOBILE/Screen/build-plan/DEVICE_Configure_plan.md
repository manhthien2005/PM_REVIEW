# 📐 UI Plan: DEVICE_Configure Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [DEVICE_Configure.md](../DEVICE_Configure.md)  
> **Existing Code**: `health_system/lib/features/device/screens/device_configure_screen.dart` (partial), plus rename/toggle/delete logic in device module  
> **Refactor Goal**: Đồng bộ `DEVICE_Configure` với visual system mới của `DEVICE_List` và `DEVICE_StatusDetail`: ít áp lực, rõ section, rõ hành động chính, không giống màn settings kỹ thuật khô cứng.

---

## 1. Description

- **SRS Ref**: UC041
- **User Role**: User (self only)
- **Purpose**: Tạo lại màn cấu hình thiết bị theo đúng tinh thần “an toàn và dễ hiểu”: cho user chỉnh được thứ cần chỉnh, nhìn rõ thứ gì đang chờ sync, và không bấm nhầm vào vùng nguy hiểm.

### 1.1. Problem Statement

Nếu chỉ dừng ở form chức năng, màn này dễ trở thành:
- một settings page rất khô,
- nhiều switch/field ngang cấp,
- thiếu liên kết visual với 2 màn trước,
- thiếu cảm giác “mình đang cấu hình đúng cái thiết bị vừa xem”.

### 1.2. Design Goal

- **Continuation of context**: user thấy rõ mình đang cấu hình thiết bị nào.
- **Section-first**: chia section mạnh, giảm cognitive load.
- **One primary action**: lưu thay đổi luôn là CTA chính.
- **Danger clearly isolated**: unpair phải có khoảng cách vật lý và thị giác.

---

## 2. User Flow

1. User vào từ `DEVICE_StatusDetail`.
2. App fetch config hiện tại.
3. Phần đầu màn có `ConfigureHeroHeader` nhỏ:
   - tên thiết bị,
   - trạng thái hiện tại,
   - optional note nếu đang offline / pending sync.
4. Bên dưới là 4 section:
   - `Cơ bản`
   - `Theo dõi & cảnh báo`
   - `Đồng bộ`
   - `Vùng nguy hiểm`
5. User chỉnh field.
6. Khi có thay đổi:
   - xuất hiện dirty footer rõ ràng.
7. User bấm `Lưu thay đổi`.
8. Success:
   - back về `DEVICE_StatusDetail`,
   - refetch detail.
9. Nếu unpair:
   - confirm sheet rõ hậu quả,
   - success -> pop về `DEVICE_List`.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Tôi đang cấu hình thiết bị nào?
2. Cái gì cần chỉnh thường xuyên?
3. Có gì đang chờ sync / cần lưu?
4. Nếu muốn huỷ liên kết thì ở đâu?

### Điều phải tránh

- Không để toàn bộ field trông như một cột form vô tận
- Không để zone nguy hiểm lẫn với zone save
- Không để user quên rằng mình đang chỉnh đúng một thiết bị cụ thể

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Fetch config | Hero skeleton + section skeleton |
| Idle | Chưa chỉnh gì | Sections + disabled footer CTA |
| Dirty | Có thay đổi chưa lưu | Sticky dirty footer CTA active |
| Saving | Đang lưu | CTA loading + form disabled |
| PendingSync | Save xong nhưng chờ online | Info banner / helper note |
| Success | Save thành công | Toast/snackbar + back |
| Error | Save fail | Inline error + giữ input user |
| UnpairConfirm | Chuẩn bị unpair | Danger sheet |
| Unpairing | Đang unpair | Full screen disable / loading |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  └─ Title("Cấu hình thiết bị")
├─ Body: ListView
│  ├─ ConfigureHeroHeader
│  ├─ PendingSyncBanner (optional)
│  ├─ ConfigSectionCard("Cơ bản")
│  │  └─ TextFormField(deviceName)
│  ├─ ConfigSectionCard("Theo dõi & cảnh báo")
│  │  ├─ SwitchTile(vibrationAlert)
│  │  ├─ SwitchTile(sleepTracking)
│  │  └─ Slider/Dropdown(lowBatteryThreshold)
│  ├─ ConfigSectionCard("Đồng bộ")
│  │  ├─ Dropdown(syncInterval)
│  │  └─ HelperText(pending sync)
│  ├─ DangerZoneCard
│  │  └─ DestructiveButton("Ngắt kết nối thiết bị")
│  └─ Bottom spacing
└─ Sticky DirtyFooterBar
   └─ PrimaryButton("Lưu thay đổi")
```

### 5.1. New / Refined Widgets

- `ConfigureHeroHeader` — NEW
- `ConfigSectionCard` — refine
- `PendingSyncBanner` — refine
- `DirtyFooterBar` — refine
- `DangerZoneCard` — refine
- `DiscardChangesDialog` — NEW

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ ← Cấu hình thiết bị                        │
├────────────────────────────────────────────┤
│  Health Band B2                            │
│  Online • Đồng bộ gần nhất 1 giờ trước     │
├────────────────────────────────────────────┤
│  Cơ bản                                    │
│  [ Tên thiết bị______________________ ]    │
├────────────────────────────────────────────┤
│  Theo dõi & cảnh báo                       │
│  [Rung khi cảnh báo]              [ON]     │
│  [Theo dõi giấc ngủ]              [ON]     │
│  [Cảnh báo pin yếu ở mức ____ ]            │
├────────────────────────────────────────────┤
│  Đồng bộ                                   │
│  [Tần suất sync ▼]                         │
│  Thiết bị sẽ nhận cấu hình khi online      │
├────────────────────────────────────────────┤
│  Vùng nguy hiểm                            │
│  [ Ngắt kết nối thiết bị ]                 │
└────────────────────────────────────────────┘
           [ Lưu thay đổi ]
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn `Configure` phải giống một phần tiếp nối của `StatusDetail`, không phải một settings page rời rạc:
- cùng palette,
- cùng section rhythm,
- cùng mức “calm, clean, product-grade”.

### 7.2. Colors

| Role | Token / Value | Usage in this screen |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Background |
| `bg.surface` | `#FFFFFF` | Cards / sections |
| `brand.primary` | `#0F766E` | Save CTA |
| `brand.soft` | `#E6FFFB` | Hero header accent |
| `info` | `#3B82F6` | Pending sync |
| `warning` | `#F2A93B` | Validation / warning |
| `danger` | `#DC2626` | Unpair zone |
| `text.primary` | `#12304A` | Main text |
| `text.secondary` | `#5B7288` | Helper text |

### 7.3. Typography

| Element | Size | Weight | Color |
| --- | --- | --- | --- |
| Title | 22sp | 700 | `text.primary` |
| Hero title | 20sp | 700 | `text.primary` |
| Section title | 18sp | 700 | `text.primary` |
| Field label | 16sp | 500 | `text.primary` |
| Helper text | 14sp | 400 | `text.secondary` |
| CTA label | 17-18sp | 700 | white |

### 7.4. Spacing

- Screen padding: `16dp`
- Hero padding: `18dp`
- Section gap: `18-20dp`
- Section padding: `18dp`
- Sticky CTA height: `56dp`

---

## 8. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
| --- | --- | --- |
| Dirty state appear | Footer elevate + fade in | 160ms |
| Save success | Toast/snackbar + back | 200ms |
| Danger sheet open | Slide up | 220ms |
| Pending sync banner | Slide down | 180ms |

---

## 9. Accessibility Checklist

- [x] Body >= 16sp
- [x] All toggles / CTA >= 48dp
- [x] Danger area tách xa save area
- [x] Không jargon kỹ thuật ở label chính
- [x] Validation dễ hiểu
- [x] Text scaling 150-200% không vỡ sticky footer

---

## 10. Design Rationale

| Decision | Reason |
| --- | --- |
| Thêm `ConfigureHeroHeader` | Giữ continuity từ detail sang configure |
| Section cards rõ ràng | Giảm tải nhận thức |
| Dirty footer sticky | 1 hành động chính luôn ổn định |
| Danger zone riêng | Tránh thao tác nhầm |
| Pending sync xuất hiện ngay gần nội dung liên quan | User hiểu “lưu rồi nhưng chưa áp dụng ngay” |

---

## 11. Edge Cases Handled

- [x] Thiết bị offline khi save
- [x] Back khi có thay đổi chưa lưu
- [x] Validation name / interval
- [x] Unpair fail
- [x] Mở sai linked context
- [x] Backend chỉ hỗ trợ một phần config fields

---

## 12. Dependencies

### 12.1. Shared Widgets Needed

- `ConfigureHeroHeader` — NEW
- `ConfigSectionCard` — refine
- `DirtyFooterBar` — refine
- `PendingSyncBanner` — refine
- `DangerZoneCard` — refine
- `DiscardChangesDialog` — NEW

### 12.2. API / State

- `GET /api/mobile/devices/:deviceId/config`
- `PATCH /api/mobile/devices/:deviceId`
- `DELETE /api/mobile/devices/:deviceId`
- Config provider riêng hoặc view-model riêng

### 12.3. Navigation

- Success update -> back `DEVICE_StatusDetail`
- Success unpair -> pop `DEVICE_List`

---

## 13. Recommended File Structure

- `lib/features/device/screens/device_configure_screen.dart`
- `lib/features/device/providers/device_configure_provider.dart`
- `lib/features/device/widgets/device_configure/configure_hero_header.dart`
- `lib/features/device/widgets/device_configure/config_section_card.dart`
- `lib/features/device/widgets/device_configure/dirty_footer_bar.dart`
- `lib/features/device/widgets/device_configure/danger_zone_card.dart`

---

## 14. Dev Implementation Sequence

1. Refactor layout theo 4 section + hero header
2. Thêm dirty state + discard confirm
3. Refine pending sync presentation
4. Hook save/unpair API + return flow
5. Polish accessibility + visual sync với module

---

## 15. Acceptance Criteria

- [ ] Màn `Configure` cùng visual family với `DEVICE_List` và `DEVICE_StatusDetail`
- [ ] User thấy rõ mình đang cấu hình thiết bị nào
- [ ] Save CTA luôn rõ ràng, ổn định
- [ ] Danger zone tách biệt, khó bấm nhầm
- [ ] Dirty state và pending sync đều dễ hiểu

---

## 16. Out of Scope

- Refactor `DEVICE_List`
- Refactor `DEVICE_Connect`
- Refactor backend contracts lớn

---

## 17. Confidence Score

- **Plan Confidence: 96%**
- **Reasoning**: Hướng refactor rất rõ sau khi đã chốt visual system mới cho cả module; màn này chủ yếu cần continuity, hierarchy và clarity.
- **Uncertainties**:
  - Backend thực tế hỗ trợ bao nhiêu config fields
