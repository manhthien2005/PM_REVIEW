# 📐 UI Plan: DEVICE_StatusDetail Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [DEVICE_StatusDetail.md](../DEVICE_StatusDetail.md)  
> **Existing Code**: `health_system/lib/features/device/screens/device_status_detail_screen.dart`  
> **Refactor Goal**: Đồng bộ `DEVICE_StatusDetail` với visual system mới của `DEVICE_List` và `HOME_Dashboard`: calm, premium, status-first, không còn cảm giác utility sheet mở rộng.

---

## 1. Description

- **SRS Ref**: UC041, UC042
- **User Role**: User (self only)
- **Purpose**: Làm cho màn chi tiết thiết bị trở thành nơi user nhìn vào là biết ngay “thiết bị này đang ổn hay có vấn đề”, đồng thời vẫn cung cấp lớp kỹ thuật ở tầng dưới.

### 1.1. Problem Statement

Màn detail hiện đã có cấu trúc tốt nhưng chưa đồng bộ hoàn toàn với refactor mới:
- hero chưa đủ “premium” như định hướng mới,
- warning/pending sync chưa cùng cấp thị giác với `DEVICE_List`,
- cần làm rõ hơn relation giữa `status`, `action`, `configure`,
- cần siết visual language để cả module giống một hệ thống thống nhất.

### 1.2. Design Goal

- **Status-first**: pin, kết nối, last sync là thứ đầu tiên user thấy.
- **Calm clinical**: cảnh báo rõ nhưng không gây hoảng.
- **Layered information**: routine info ở trên, technical info ở dưới.
- **Strong handoff**: từ `DEVICE_List` -> `DEVICE_StatusDetail` -> `DEVICE_Configure` phải mượt và logic.

---

## 2. User Flow

1. User bấm card thiết bị ở `DEVICE_List`.
2. App mở `DEVICE_StatusDetail` với snapshot ban đầu nếu có.
3. Screen refetch detail.
4. Hero summary hiển thị:
   - tên thiết bị,
   - loại thiết bị,
   - pin,
   - online/offline,
   - last sync / last seen.
5. Nếu có cảnh báo:
   - `Low battery`
   - `Offline too long`
   - `Pending sync`
   hiện trong `Status Insight Banner`.
6. User đọc nhanh trạng thái.
7. User bấm `Cấu hình thiết bị` nếu muốn xử lý sâu hơn.
8. Quay về từ configure:
   - refresh detail,
   - hoặc pop về list nếu đã unpair.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Thiết bị này là thiết bị nào?
2. Nó đang ổn hay không?
3. Nếu có vấn đề thì vấn đề gì?
4. Tôi nên bấm gì tiếp theo?
5. Nếu cần hỗ trợ kỹ thuật thì xem thông tin ở đâu?

### Điều phải tránh

- Không để technical info chen lên ngang hàng với status
- Không để cảnh báo chìm xuống như text phụ
- Không để CTA configure trôi lạc khỏi narrative của màn

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Tải lần đầu | Hero skeleton + sections skeleton |
| Success_Normal | Thiết bị hoạt động ổn | Hero sạch, không warning |
| Success_Warning | Pin yếu / sync chậm | Status insight banner màu warning |
| Success_Offline | Thiết bị offline | Hero vẫn rõ, banner offline + last seen |
| Success_PendingSync | Có config chờ sync | Info banner + helper text |
| Error | API fail | Error card + Retry + Back |
| NotFound | Thiết bị bị xoá / unpair | Empty state + back to list |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  └─ Title("Trạng thái thiết bị")
└─ Body: RefreshIndicator
   └─ ListView
      ├─ DeviceStatusHeroCard
      ├─ StatusInsightBanner
      ├─ DeviceInfoSection("Thông tin chính")
      │  ├─ InfoRow("Kết nối", ...)
      │  ├─ InfoRow("Đồng bộ lần cuối", ...)
      │  └─ InfoRow("Lần cuối online", ...)
      ├─ PrimaryActionCard
      │  └─ FilledButton("Cấu hình thiết bị")
      ├─ DeviceInfoSection("Thông tin kỹ thuật")
      │  ├─ InfoRow("Firmware", ...)
      │  ├─ InfoRow("Serial", ...)
      │  ├─ InfoRow("MAC", ...)
      │  └─ InfoRow("MQTT", ...)
      └─ Bottom spacing
```

### 5.1. New / Refined Widgets

- `DeviceStatusHeroCard` — refine từ `DeviceHeroSummaryCard`
- `StatusInsightBanner` — refine / merge warning logic
- `PrimaryActionCard` — NEW
- `DeviceInfoSection` — refine từ `DeviceStatusSection`
- `InfoRow` — reuse

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ ← Trạng thái thiết bị                      │
├────────────────────────────────────────────┤
│  Health Band B2                            │
│  Vòng đeo sức khoẻ                         │
│  Pin 12%                     [Online]      │
│  Đồng bộ 1 giờ trước                       │
├────────────────────────────────────────────┤
│  ⚠ Thiết bị cần chú ý                      │
│  Pin đang thấp, nên sạc sớm                │
├────────────────────────────────────────────┤
│  Kết nối            Đang hoạt động         │
│  Đồng bộ lần cuối   1 giờ trước            │
│  Lần cuối online    Vừa xong               │
├────────────────────────────────────────────┤
│      [ Cấu hình thiết bị ]                 │
├────────────────────────────────────────────┤
│  Firmware           1.0.3                  │
│  Serial             VS-A1-2026-0001        │
│  MAC                AA:BB:CC:11:22:33      │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn này phải là phần mở rộng tự nhiên của `DEVICE_List`:
- cùng palette,
- cùng kiểu hero rõ ràng,
- cùng nhịp spacing,
- cùng tinh thần “calm but informative”.

### 7.2. Colors

| Role | Token / Value | Usage in this screen |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Background |
| `bg.surface` | `#FFFFFF` | Sections |
| `brand.primary` | `#0F766E` | Hero accent / CTA |
| `brand.soft` | `#E6FFFB` | Hero soft surface |
| `success` | `#0F9D7A` | Online / healthy |
| `warning` | `#F2A93B` | Low battery / stale sync |
| `offline` | `#94A3B8` | Offline |
| `info` | `#3B82F6` | Pending sync |
| `text.primary` | `#12304A` | Main text |
| `text.secondary` | `#5B7288` | Supportive text |

### 7.3. Typography

| Element | Size | Weight | Color |
| --- | --- | --- | --- |
| Device name | 22sp | 700 | `text.primary` |
| Battery metric | 30-32sp | 800 | `text.primary` |
| Hero subtitle | 16sp | 400 | `text.secondary` |
| Section title | 18sp | 700 | `text.primary` |
| Body row | 16sp | 400/600 | mixed |
| Caption | 14sp | 400 | `text.secondary` |

### 7.4. Spacing

- Horizontal padding: `16dp`
- Hero padding: `20dp`
- Section gap: `20-24dp`
- Section padding: `18-20dp`
- CTA min height: `56dp`

---

## 8. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
| --- | --- | --- |
| Loading -> success | Crossfade | 180ms |
| Banner appear | Slide down | 180ms |
| Pull to refresh | Native | system |
| Configure tap | Standard push transition | 250ms |

---

## 9. Accessibility Checklist

- [x] Body >= 16sp
- [x] Hero metric đủ lớn để đọc xa
- [x] Badge có text, không chỉ màu
- [x] Banner có icon + lời giải thích
- [x] CTA >= 56dp
- [x] Text scaling 150-200% không vỡ section
- [x] Screen reader đọc được pin, status, sync

---

## 10. Design Rationale

| Decision | Reason |
| --- | --- |
| Hero mạnh hơn và nhất quán với list hero | Cả module phải cùng chất lượng thị giác |
| Tách `StatusInsightBanner` riêng | Low battery / offline / pending sync là nội dung quan trọng nhất sau hero |
| Dùng `PrimaryActionCard` cho configure | CTA có chỗ đứng rõ ràng trong flow |
| Thông tin kỹ thuật xuống cuối | Progressive disclosure |

---

## 11. Edge Cases Handled

- [x] `404` khi thiết bị đã bị xoá
- [x] Pin / RSSI / timestamp null
- [x] Offline lâu nhưng user vẫn cần biết sync gần nhất
- [x] Pull-to-refresh fail nhưng giữ content cũ
- [x] Return từ `DEVICE_Configure` với `true` / `deleted`
- [x] Mở sai linked context

---

## 12. Dependencies

### 12.1. Shared Widgets Needed

- `DeviceStatusHeroCard` — refine
- `StatusInsightBanner` — refine
- `PrimaryActionCard` — NEW
- `DeviceInfoSection` — refine
- `InfoRow` — reuse

### 12.2. API / State

- `GET /api/mobile/devices/:deviceId`
- `DeviceStatusDetailProvider`
- Return contract từ `DEVICE_Configure`:
  - `true` = refetch
  - `'deleted'` = pop về list

---

## 13. Recommended File Structure

- `lib/features/device/screens/device_status_detail_screen.dart`
- `lib/features/device/providers/device_status_detail_provider.dart`
- `lib/features/device/widgets/device_status/device_status_hero_card.dart`
- `lib/features/device/widgets/device_status/status_insight_banner.dart`
- `lib/features/device/widgets/device_status/device_info_section.dart`
- `lib/features/device/widgets/device_status/primary_action_card.dart`

---

## 14. Dev Implementation Sequence

1. Refactor hero summary theo style mới
2. Chuẩn hoá banner logic: low battery / offline / pending sync
3. Tạo `PrimaryActionCard` cho CTA configure
4. Refine section hierarchy và spacing
5. Đồng bộ return flow với `DEVICE_Configure`
6. Polish accessibility + visual sync

---

## 15. Acceptance Criteria

- [ ] Màn detail cùng visual family với `DEVICE_List` và `HOME_Dashboard`
- [ ] User đọc 3-5 giây biết thiết bị có ổn không
- [ ] CTA `Cấu hình thiết bị` có vị trí rõ ràng
- [ ] Warning/pending sync đủ mạnh về hierarchy
- [ ] Technical info không lấn át status info

---

## 16. Out of Scope

- Refactor `DEVICE_Connect`
- Refactor toàn bộ logic backend của device
- Family-owned device monitoring

---

## 17. Confidence Score

- **Plan Confidence: 97%**
- **Reasoning**: Màn này đã có nền tảng tốt nên refactor chủ yếu là đồng bộ hierarchy, visual system và status emphasis.
- **Uncertainties**:
  - `pendingSync` field backend đã sẵn sàng hay chưa
