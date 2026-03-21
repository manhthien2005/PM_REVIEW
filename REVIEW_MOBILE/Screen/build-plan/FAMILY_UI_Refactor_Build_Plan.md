# FAMILY UI Refactor — Build Plan Chi Tiết

> **Mục tiêu**: Giảm rối mắt, giữ chỉ số sinh tồn rõ ràng, giao diện thân thiện gia đình nhưng đủ chức năng theo dõi thực thụ.  
> **Scope**: Màn `Gia đình` (Theo dõi) + màn `Chi tiết thông tin` (Person Detail).  
> **Data**: Toàn bộ mockup — không có BE/API.

---

## 1. Tổng Quan Thay Đổi

| Màn | Thay đổi chính |
|-----|----------------|
| **Family Dashboard** | Bỏ Attention banner; rút gọn hero; làm dịu chip filter; SOS → full-screen overlay khi active |
| **Person Detail** | App bar `Chi tiết thông tin`; bỏ block "Xem biểu đồ chi tiết"; thẻ vital có viền cảnh báo + tap toàn card; thêm Health Score banner; Sleep card navy gradient + animation nhẹ |

---

## 2. Family Dashboard Screen

### 2.1. Bỏ Attention Banner
- **File**: `health_system/lib/features/family/screens/family_dashboard_screen.dart`
- **Hành động**: Xóa hoàn toàn `FamilyAttentionSummaryBanner` (index 2 trong ListView).
- **Lý do**: Giảm thông tin thừa; người cần chú ý đã được sort lên đầu list.

### 2.2. SOS Full-Screen Overlay
- **Yêu cầu**: Khi có SOS active, hiển thị **toàn màn hình** thay vì banner nhỏ.
- **Cách làm**:
  1. Tạo `FamilySOSFullScreenOverlay` — màn modal/dialog full-screen khi `sosCount > 0`.
  2. Khi user vào tab `Theo dõi` và có SOS: push overlay lên trên cùng.
  3. Overlay có: thông tin người SOS, CTA `Xem ngay` → Person Detail (profileId), nút đóng.
  4. Không còn `FamilySOSPriorityBanner` trong list.
- **File mới**: `health_system/lib/features/family/widgets/family_sos_full_screen_overlay.dart`
- **Logic**: Trong `FamilyDashboardScreen`, `initState` hoặc sau khi load xong, nếu `provider.sosCount > 0` thì `showDialog` hoặc `Navigator.push` full-screen route.

### 2.3. Hero Banner Rút Gọn
- **File**: `health_system/lib/features/family/widgets/family_health_hero_card.dart`
- **Thiết kế mới** (compact, tiết kiệm không gian):

```
┌─────────────────────────────────────────────────────┐
│ [icon] Gia đình của bạn · 3 người đang theo dõi     │
│        [3 Tổng] [2 Ổn định] [1 Cần chú ý]          │
└─────────────────────────────────────────────────────┘
```

- **Thay đổi**:
  - Bỏ dòng "Gia đình của bạn" riêng; gộp thành 1 dòng: `Gia đình của bạn · X người đang theo dõi`.
  - Giảm padding: `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
  - Giảm font: title 18sp, sub 14sp.
  - Stat chips: giữ 3 chip nhưng thu nhỏ (padding 6/8, font 12sp).
  - Chiều cao tổng: ~72–80dp thay vì ~120dp.

### 2.4. Chip Filter Làm Dịu
- **File**: `family_dashboard_screen.dart` — method `_buildChip` / `_buildFilterChips`.
- **Thay đổi**:
  - `selectedColor`: `Color(0xFFE8EEF6)` (xám xanh rất nhạt) thay vì `0xFFE2E8F0`.
  - `backgroundColor`: `Color(0xFFF8FAFC)` thay vì trắng.
  - Border: `strokeSoft` khi selected, không dùng màu xanh đậm.
  - Label: `textSecondary` khi unselected, `textPrimary` khi selected.
  - Không dùng `checkmarkColor` quá nổi.

### 2.5. Sort Linh Hoạt
- **File**: `family_dashboard_mock_provider.dart`
- **Thêm**: Cho phép user chọn sort order (mặc định: SOS → Cần chú ý → Ổn định).
- **UI**: Thêm icon sort ở góc hero hoặc cạnh filter chips; tap mở bottom sheet: "Sắp xếp theo: Mức độ ưu tiên / Tên A-Z / Cập nhật gần nhất".
- **Mock**: Chỉ cần 1 enum `FamilySortOrder` và logic sort trong `displayList`.

---

## 3. Person Detail Screen

### 3.1. App Bar
- **File**: `person_detail_screen.dart`
- **Thay đổi**: `AppBar(title: Text('Chi tiết thông tin'))`.
- **Không** hiển thị tên người thân trên app bar — chỉ ở hero.

### 3.2. Bỏ Block "Xem biểu đồ chi tiết"
- **Hành động**: Xóa hoàn toàn `_buildVitalShortcuts`.
- **Thay thế**: Mỗi thẻ vital trở thành tap target; tap toàn card → `Navigator.pushNamed(context, AppRouter.vitalDetail, arguments: {...})`.

### 3.3. Thẻ Vital Có Viền Cảnh Báo
- **File**: `person_detail_screen.dart` — `_buildVitalCard` hoặc tạo widget riêng.
- **Logic**: Map từ `FamilyProfileSnapshot` + rule đơn giản:
  - **HR**: <60 hoặc >100 → warning; <50 hoặc >120 → critical.
  - **SpO2**: <95 → warning; <90 → critical.
  - **BP**: systolic >140 hoặc diastolic >90 → warning; >160/100 → critical.
  - **Temp**: >37.5 → warning; >38.5 → critical.
- **Visual** (dùng `VitalMetricCard` pattern từ home):
  - `normal`: viền `AppColors.success` nhẹ (1px), nền `successBg`.
  - `warning`: viền `AppColors.warning`, nền `warningBg`.
  - `critical`: viền `AppColors.emergency`, nền `criticalBg`.
- **Tái sử dụng**: Import `VitalMetricCard`, `VitalMetricItem`, `VitalMetricVisualState` từ home; build list `VitalMetricItem` từ profile, mỗi item `onTap` → vital detail.

### 3.4. Health Score Banner
- **Vị trí**: Ngay trên block Sleep.
- **Thiết kế**: Giống `RiskInsightCard` ở home dashboard — gradient tối, điểm số lớn, summary.
- **Nội dung mock**:
  - `scoreLabel`: "78" (0–100).
  - `levelLabel`: "Thấp" / "Trung bình" / "Cao".
  - `summary`: "Tổng hợp 7 ngày gần nhất".
- **Tap**: `onTap` để sau (chưa có màn chi tiết) — có thể để empty hoặc SnackBar "Đang phát triển".
- **File**: Tái dùng `RiskInsightCard` từ home, hoặc tạo `PersonHealthScoreBanner` tương tự với text "Điểm sức khoẻ 7 ngày".

### 3.5. Sleep Block Redesign
- **Thiết kế**: Navy gradient + animation nhẹ, đồng bộ với `SleepInsightCard` ở home.
- **File**: Tái dùng `SleepInsightCard` hoặc tạo `PersonSleepSummaryCard` với:
  - Gradient: `[Color(0xFF131A2F), Color(0xFF1C274B)]`.
  - Nội dung: Số giờ ngủ + chất lượng (Tốt / Trung bình / Kém).
  - Animation: Lottie `sleep_animation.json` nếu có, hoặc `Opacity` nhấp nháy rất nhẹ (0.3s) cho icon sao.
  - Chevron bên phải; tap toàn card → `AppRouter.sleepDetail`.
- **Data mock**: `sleepDurationMinutes`, `sleepQuality` (string).

### 3.6. Hero Wording Đời Thường
- **Thay đổi**:
  - `Khẩn cấp` → giữ (đã rõ).
  - `Cần chú ý` → `Cần theo dõi` hoặc `Cần kiểm tra`.
  - `Ổn định` → `Đang ổn định`.
- **Nhãn**: Giữ badge `profile.relation` (Gia đình, Bác sĩ).

### 3.7. SOS Banner Trên Person Detail
- **Khi `profile.isSosActive`**: Giữ banner đỏ ở top, nhưng làm **rõ ràng nhưng không gây hoảng**:
  - Giảm độ đậm: dùng `Color(0xFFE53935)` thay vì `0xFFD95C5C` nếu cần.
  - Icon + text rõ; CTA "Xem" → màn SOS/emergency (mock: SnackBar).
- **Lưu ý**: SOS full-screen chỉ ở **Family Dashboard** khi vào tab; ở Person Detail vẫn là banner vì user đã drill-down rồi.

---

## 4. Tăng Font
- **File**: `app_text_styles.dart` hoặc override tại từng màn.
- **Thay đổi**:
  - Body: 16sp → 17sp.
  - Card title: 18sp → 19sp.
  - Section title: 18sp → 20sp.
- **Hoặc**: Thêm `AppTextStyles.bodyLarge` (17sp) cho family module.

---

## 5. Mock Data Bổ Sung

### FamilyProfileSnapshot
- Thêm `sleepDurationMinutes`, `sleepQuality` (String) nếu chưa có.
- Thêm `healthScore7Days` (int 0–100), `healthScoreLevel` (String) cho Person Detail.

### SharedFamilyMockProvider / generateDashboardSnapshots
- Gán giá trị mock cho các field mới.

---

## 6. Thứ Tự Implement

| # | Task | File(s) | Ước lượng |
|---|------|---------|-----------|
| 1 | Rút gọn FamilyHealthHeroCard | `family_health_hero_card.dart` | 15 phút |
| 2 | Bỏ Attention banner | `family_dashboard_screen.dart` | 5 phút |
| 3 | Làm dịu chip filter | `family_dashboard_screen.dart` | 10 phút |
| 4 | Tạo FamilySOSFullScreenOverlay | `family_sos_full_screen_overlay.dart` (mới) | 30 phút |
| 5 | Wire SOS overlay vào FamilyDashboardScreen | `family_dashboard_screen.dart` | 15 phút |
| 6 | Person Detail: đổi app bar title | `person_detail_screen.dart` | 2 phút |
| 7 | Person Detail: bỏ _buildVitalShortcuts | `person_detail_screen.dart` | 5 phút |
| 8 | Person Detail: vital cards dùng VitalMetricCard + visual state | `person_detail_screen.dart` | 45 phút |
| 9 | Person Detail: thêm Health Score banner | `person_detail_screen.dart` | 20 phút |
| 10 | Person Detail: Sleep block → SleepInsightCard style | `person_detail_screen.dart` | 30 phút |
| 11 | Hero wording đời thường | `person_detail_screen.dart` | 5 phút |
| 12 | Tăng font family module | `app_text_styles.dart` hoặc local | 10 phút |
| 13 | Mock data: sleep, health score | `shared_family_mock_provider.dart`, `family_profile_snapshot.dart` | 15 phút |
| 14 | Sort linh hoạt (optional) | `family_dashboard_mock_provider.dart`, UI | 25 phút |

**Tổng ước lượng**: ~4–5 giờ.

---

## 7. Acceptance Criteria

- [ ] Màn Gia đình không còn Attention banner.
- [ ] Hero banner rút gọn, chiều cao giảm ~40%.
- [ ] Chip filter màu dịu, không chói.
- [ ] Khi có SOS: full-screen overlay xuất hiện khi vào tab Theo dõi.
- [ ] Màn Chi tiết thông tin: app bar "Chi tiết thông tin".
- [ ] Không còn block "Xem biểu đồ chi tiết"; tap từng thẻ vital → vital detail.
- [ ] Thẻ vital có viền màu theo mức cảnh báo (xanh nhạt / vàng / đỏ).
- [ ] Health Score banner nằm trên Sleep, mock 7 ngày.
- [ ] Sleep card: navy gradient, animation nhẹ, chevron, tap → sleep detail.
- [ ] Wording đời thường ở hero.
- [ ] Font tăng nhẹ cho family module.

---

## 8. Rủi Ro & Ghi Chú

- **SOS full-screen**: Cần quyết định có cho phép đóng overlay không (nút X) hay bắt buộc phải "Xem ngay". Đề xuất: có nút đóng, nhưng badge vẫn hiện trên tab.
- **Sleep animation**: Nếu Lottie nặng, dùng `Opacity` + `AnimatedOpacity` nhẹ thay thế.
- **Health score**: Chưa có màn chi tiết — tap tạm để SnackBar hoặc không làm gì.

---

## 9. File Structure Sau Refactor

```
lib/features/family/
├── screens/
│   ├── family_shell_screen.dart
│   ├── family_dashboard_screen.dart
│   └── person_detail_screen.dart
├── widgets/
│   ├── family_health_hero_card.dart      # rút gọn
│   ├── family_sos_full_screen_overlay.dart  # mới
│   ├── family_sos_priority_banner.dart   # có thể xóa nếu dùng overlay
│   ├── family_profile_health_card.dart
│   └── ...
├── models/
│   └── family_profile_snapshot.dart     # thêm sleep, healthScore
└── providers/
    └── shared_family_mock_provider.dart # mock mới
```

---

*Plan v1.0 — 2026-03-18*
