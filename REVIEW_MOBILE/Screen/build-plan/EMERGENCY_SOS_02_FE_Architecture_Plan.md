# EMERGENCY SOS — Plan 02: FE Architecture (UI/UX, Mock Data, Style Sync)

> **Agent instruction**: Đọc file này để đồng bộ UI/UX với design system của app. Dùng đúng AppColors, AppTextStyles, AppSpacing. Mock data theo format chuẩn.

---

## 1. Design System — Sync Với App

### 1.1. Màu sắc (AppColors)

| Token | Hex | Dùng cho |
|-------|-----|----------|
| `AppColors.emergency` | `#C83D3D` | Nút SOS, banner SOS active, accent khẩn cấp |
| `AppColors.critical` | `#D95C5C` | Cảnh báo critical |
| `AppColors.criticalBg` | `#FBEFEF` | Nền card SOS active |
| `AppColors.bgSurface` | `#FFFFFF` | Nền card |
| `AppColors.bgPrimary` | `#F4F7FB` | Nền màn |
| `AppColors.textPrimary` | `#12304A` | Chữ chính |
| `AppColors.textSecondary` | `#5B7288` | Chữ phụ |
| `AppColors.brandPrimary` | `#2F80ED` | CTA phụ, link |
| `AppColors.strokeSoft` | `#D8E3EE` | Viền nhẹ |

**Import**: `package:healthguard/shared/presentation/theme/app_colors.dart`

### 1.2. Typography (AppTextStyles)

| Token | Size | Dùng cho |
|-------|------|----------|
| `AppTextStyles.sectionTitle` | 20sp, SemiBold | Tiêu đề section |
| `AppTextStyles.bodyMedium` | 16sp, Medium | Nội dung chính |
| `AppTextStyles.body` | 16sp, Regular | Nội dung |
| `AppTextStyles.bodyLarge` | 17sp | Family module (ưu tiên) |
| `AppTextStyles.caption` | 14sp | Phụ đề, timestamp |
| `AppTextStyles.vitalValue` | 26sp, Bold | Số countdown, giá trị lớn |

**Import**: `package:healthguard/shared/presentation/theme/app_text_styles.dart`

### 1.3. Spacing (AppSpacing)

| Token | Value | Dùng cho |
|-------|-------|----------|
| `AppSpacing.screenHorizontalPadding` | 20 horizontal | Padding màn |
| `AppSpacing.sectionGapMd` | 16 | Khoảng section |
| `AppSpacing.gapMd` | 12 | Gap giữa element |
| `AppSpacing.cardPadding` | 16 all | Padding card |
| `AppSpacing.minTouchTargetSize` | 48 | Nút, tap target tối thiểu |

**Import**: `package:healthguard/shared/presentation/theme/app_spacing.dart`

---

## 2. UI Spec Từng Màn

### 2.1. ManualSOSScreen

| Element | Spec |
|---------|------|
| Nền | `AppColors.emergency` (đỏ) |
| Countdown số | `AppTextStyles.vitalValue`, màu trắng, 120sp |
| Text "Sẽ gửi SOS trong:" | 24sp, Bold, trắng |
| Nút "Trượt để GỬI NGAY" | SlideAction, outerColor trắng, innerColor emergency |
| Nút "Hủy báo động" | TextButton, nền trắng 24% opacity |
| Countdown | 3 giây (không phải 5) |

### 2.2. SosConfirmScreen (mới)

| Element | Spec |
|---------|------|
| Nền | `AppColors.bgPrimary` |
| Icon | Icons.check_circle, `AppColors.success`, size 80 |
| Tiêu đề | "Đã gửi SOS", `AppTextStyles.sectionTitle` |
| Nội dung | "X người thân đã được thông báo.", `AppTextStyles.body` |
| Nút "Về trang chủ" | ElevatedButton, `AppColors.brandPrimary`, full width, height 56 |

### 2.3. EmergencySOSReceivedListScreen

| Element | Spec |
|---------|------|
| Filter chips | Giống Family filter: `AppColors.bgElevated` selected, `strokeSoft` border |
| Search | TextField với `AppSpacing.screenHorizontalPadding` |
| SOS Card active | Viền `AppColors.emergency`, nền `AppColors.criticalBg` |
| SOS Card resolved | Viền `strokeSoft`, nền `bgSurface` |
| Empty state | Icon + text "Chưa có SOS nào", `textSecondary` |

### 2.4. EmergencySOSDetailScreen

| Element | Spec |
|---------|------|
| App bar | `AppColors.emergency` background, chữ trắng |
| Map | Full width, height 200 |
| Nút "Gọi điện" | `AppColors.emergency`, min 56dp |
| Nút "Mở bản đồ" | `AppColors.brandPrimary`, min 48dp |
| Nút "Đã xác nhận an toàn" | `AppColors.success`, full width, 56dp |

### 2.5. FamilySOSFullScreenOverlay

| Element | Spec |
|---------|------|
| Nền overlay | `Colors.black.withOpacity(0.65)` |
| Card thông tin | `Colors.white.withOpacity(0.1)`, viền `AppColors.emergency` |
| CTA "Xem ngay" | `AppColors.emergency`, full width, 56dp |
| Nút "Đóng" | TextButton, màu trắng 60% |

---

## 3. Mock Data

### 3.1. SOSEventModel (đã có)

```dart
// lib/features/emergency/models/sos_event_model.dart
// Cấu trúc: id, status, patient, location, triggerTime, isActive, ...
```

### 3.2. FamilyProfileSnapshot — Thêm sosId

```dart
class FamilyProfileSnapshot {
  final String id;           // profileId
  final String name;
  final String relation;
  final bool isSosActive;
  final String? sosId;       // THÊM: khi isSosActive = true
  // ...
}
```

### 3.3. Mock Family Dashboard — sosId khi SOS active

```dart
// family_dashboard_mock_provider.dart
// Khi generate snapshot với isSosActive = true:
//   sosId = 'sos-${profileId}-${timestamp}' hoặc 'sos-mock-001'
```

### 3.4. Mock SOS List (EmergencyCaregiverProvider)

```dart
// Đã có repository getSOSAlerts — dùng mock nếu API chưa sẵn sàng
// EmergencyCaregiverRepository.getSOSAlerts(status) trả về List<SOSEventModel>
```

### 3.5. SosConfirmScreen — recipientCount

```dart
// Mock: recipientCount = 1 hoặc 2
// Sau này từ API response: { recipients_notified: 2 }
```

---

## 4. Widget Tái Sử Dụng

| Widget | Location | Dùng cho |
|--------|----------|----------|
| `EmergencyStickyBar` | `shared/presentation/emergency/` | Home Dashboard |
| `SOSCard` | `features/emergency/widgets/` | SOS Received List |
| `VitalMetricCard` | `features/home/` | Có thể dùng cho SOS Detail vitals |
| `RiskInsightCard` | `features/home/` | Style reference cho card |

---

## 5. Accessibility

- Touch target ≥ 48dp (`AppSpacing.minTouchTargetSize`)
- Font body ≥ 16sp
- SOS nút: contrast cao (đỏ trên trắng hoặc trắng trên đỏ)
- Semantic labels: `Semantics(button: true, label: 'Gọi SOS khẩn cấp')`

---

## 6. Checklist Implement

- [ ] ManualSOSScreen: dùng AppColors.emergency, countdown 3s
- [ ] Tạo SosConfirmScreen với AppColors, AppTextStyles
- [ ] EmergencySOSReceivedListScreen: filter chips sync Family style
- [ ] SOSCard: active = criticalBg + emergency border
- [ ] FamilyProfileSnapshot: thêm sosId
- [ ] FamilyDashboardMockProvider: gán sosId khi isSosActive
- [ ] FamilySOSFullScreenOverlay: dùng AppColors.emergency cho CTA

---

## 7. File Tham Chiếu

| File | Mục đích |
|------|----------|
| `lib/shared/presentation/theme/app_colors.dart` | Màu |
| `lib/shared/presentation/theme/app_text_styles.dart` | Typography |
| `lib/shared/presentation/theme/app_spacing.dart` | Spacing |
| `lib/features/family/widgets/family_health_hero_card.dart` | Reference chip style |
| `lib/features/home/widgets/risk_insight_card.dart` | Reference card style |

---

*Plan 02 — FE Architecture — v1.0*
