# Báo cáo phân tích dọn dẹp màn hình v1

> **Ngày**: 2026-03-19  
> **Mục đích**: Xác định các màn hình và widget thuộc v1 (cũ) có thể xóa an toàn mà không ảnh hưởng app v2.

---

## 1. Nguồn tham chiếu

- **Build plan**: `PM_REVIEW/REVIEW_MOBILE/BUILD_PHASES/` + `CROSS_CHECK_REPORT.md`
- **Family refactor**: `FAMILY_UI_Refactor_Build_Plan.md`, `FAMILY_TabGiaDinh_Refactor_Spec.md`
- **Family contacts relink**: `.cursor/plans/family-contacts-relink_014cb793.plan.md`
- **App router**: `health_system/lib/core/routes/app_router.dart`

---

## 2. Kiến trúc v2 hiện tại

| Route | Màn v2 | Ghi chú |
|-------|--------|---------|
| `/dashboard` | `HomeDashboardScreen` | Tab "Tôi" |
| `/family-management` | `FamilyShellScreen` | Tab "Gia đình" — chứa `FamilyDashboardScreen` + `ContactListScreen` |
| `/profile` | `ProfileShellScreen` | Tab "Hồ sơ" |
| `/device` | `DeviceScreen` | Tab "Thiết bị" |
| `/add-contact` | `AddContactScreen` | |
| `/linked-contact-detail` | `LinkedContactDetailScreen` | |
| `/person-detail` | `PersonDetailScreen` | |
| `/vital-detail` | `VitalDetailScreen` | |
| `/sleep-report`, `/sleep-detail`, ... | Các màn Sleep | |
| Auth, Device, Emergency... | Các màn tương ứng | |

---

## 3. Danh sách file v1 — ĐỀ XUẤT XÓA (đã xác minh không dùng)

### 3.1. Màn hình (screens)

| File | Lý do |
|------|-------|
| `family/screens/family_management_screen.dart` | **Không được route nào dùng**. Route `/family-management` đã map sang `FamilyShellScreen`. Màn này dùng flow cũ: tab "Tìm kiếm" + "Người thân" với `UserSearchTab`, `TargetProfileProvider`, `Relationship`. |
| `family/screens/search_user_screen.dart` | Chỉ được `FamilyManagementScreen` import (export `UserSearchTab`). Không màn v2 nào dùng. |
| `family/screens/user_detail_screen.dart` | Chỉ được `FamilyManagementScreen` và `SearchUserScreen` mở. Không màn v2 nào dùng. |
| `home/screens/main_screen.dart` | **Không được dùng**. App v2 không dùng MainScreen. MainScreen là bottom nav 5 tab cũ (Sức khỏe, Giấc ngủ, Khẩn cấp, Gia đình, Cá nhân). |
| `home/screens/dashboard_screen.dart` | **Không được dùng**. Route `/dashboard` map sang `HomeDashboardScreen`. DashboardScreen là màn "Xin chào User" đơn giản cũ. |
| `health_monitoring/screens/health_monitoring_screen.dart` | Chỉ được `MainScreen` dùng (tab 0). MainScreen không dùng → HealthMonitoringScreen orphan. |

---

## 4. File v1 — BỔ SUNG VÀO DANH SÁCH XÓA (đã chuyển sang linked profile)

Anh đã chuyển sang linked profile. `PersonDetailScreen` dùng `sleepDetail` thay vì `sleepReport` để tránh ProfileSwitcher (comment dòng 353). ProfileSwitcher và TargetProfileProvider **không còn được dùng** trong flow thực tế:

| File | Lý do |
|------|-------|
| `family/widgets/profile_switcher.dart` | Dead code. SleepReport chỉ mở từ Home (profileId=null) hoặc PersonDetail dùng sleepDetail. ProfileSwitcher không bao giờ hiển thị. |
| `family/providers/target_profile_provider.dart` | Chỉ ProfileSwitcher và ProfileScreen.clearData() dùng. Có thể bỏ và refactor ProfileScreen. |
| `family/repositories/family_repository.dart` | Chỉ TargetProfileProvider dùng. |
| `family/models/relationship.dart` | TargetProfileProvider, FamilyRepository dùng. |
| `family/models/access_profile.dart` | TargetProfileProvider dùng. |
| `family/models/user_search_result.dart` | FamilyRepository.searchUsers() dùng. Chỉ SearchUserScreen gọi. |

---

## 5. Cập nhật sau xác nhận của anh

Anh đã chuyển sang **linked profile**. ProfileSwitcher và TargetProfileProvider không còn trong flow thực tế. Có thể xóa toàn bộ nhóm v1 này.

---

## 6. Thứ tự thực hiện đề xuất

1. **Bước 1 — Xóa 6 màn v1**  
   - `family_management_screen.dart`, `search_user_screen.dart`, `user_detail_screen.dart`
   - `main_screen.dart`, `dashboard_screen.dart`, `health_monitoring_screen.dart`

2. **Bước 2 — Xóa ProfileSwitcher và refactor SleepReportScreen**  
   - Xóa `profile_switcher.dart`
   - Bỏ import và block `ProfileSwitcher` trong `SleepReportScreen`, bỏ param `showProfileSwitcher`

3. **Bước 3 — Xóa TargetProfileProvider và refactor ProfileScreen + app.dart**  
   - Bỏ `TargetProfileProvider` khỏi `MultiProvider` trong `app.dart`
   - Bỏ `context.read<TargetProfileProvider>().clearData()` trong `ProfileScreen`
   - Xóa `target_profile_provider.dart`

4. **Bước 4 — Xóa FamilyRepository + models**  
   - Xóa `family_repository.dart`, `relationship.dart`, `access_profile.dart`, `user_search_result.dart`

5. **Bước 5 — Kiểm tra build**  
   Chạy `flutter analyze` và `flutter run`.

---

## 7. Tóm tắt

| Loại | Số lượng | Hành động |
|------|----------|-----------|
| Màn v1 | 6 | Xóa |
| ProfileSwitcher + TargetProfileProvider + FamilyRepository + models | 6 | Xóa (đã chuyển sang linked profile) |

---

*Báo cáo được tạo tự động từ phân tích codebase. Anh vui lòng xác nhận trước khi thực hiện xóa.*
