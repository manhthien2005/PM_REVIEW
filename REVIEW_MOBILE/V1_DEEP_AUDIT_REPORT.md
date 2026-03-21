# Báo cáo kiểm tra sâu — Màn hình v1 vs v2

> **Ngày**: 2026-03-19  
> **Mục đích**: Kiểm tra toàn bộ màn hình để đảm bảo không xóa nhầm, không bỏ sót.

---

## 1. Tổng quan kiến trúc v2

**Entry point**: `AppRouter.start` → `AuthPagesScreen` → sau login → `AppRouter.dashboard` → `HomeDashboardScreen`

**Bottom Nav v2** (trong HomeDashboardScreen, FamilyShellScreen, DeviceScreen, ProfileShellScreen):
- Tab "Tôi" → `/dashboard` (HomeDashboardScreen)
- Tab "Gia đình" → `/family-management` (FamilyShellScreen)
- Tab "Thiết bị" → `/device` (DeviceScreen)
- Tab "Hồ sơ" → `/profile` (ProfileShellScreen)

**App Router** không dùng MainScreen. Mỗi tab là một route riêng, pushReplacementNamed khi chuyển tab.

---

## 2. Ma trận màn hình — XÓA (v1, orphaned)

| # | Màn hình | File | Ai dùng? | Route? | Lý do xóa |
|---|----------|------|----------|--------|-----------|
| 1 | **FamilyManagementScreen** | `family/screens/family_management_screen.dart` | Không ai | `/family-management` → FamilyShellScreen | Route đã đổi sang FamilyShellScreen |
| 2 | **SearchUserScreen** (UserSearchTab) | `family/screens/search_user_screen.dart` | Chỉ FamilyManagementScreen | — | Chỉ màn v1 dùng |
| 3 | **UserDetailScreen** | `family/screens/user_detail_screen.dart` | FamilyManagementScreen, SearchUserScreen | — | Chỉ màn v1 dùng |
| 4 | **MainScreen** | `home/screens/main_screen.dart` | Không ai | Không trong app_router | Bottom nav 5 tab cũ, v2 dùng route riêng |
| 5 | **DashboardScreen** | `home/screens/dashboard_screen.dart` | Không ai | `/dashboard` → HomeDashboardScreen | Màn "Xin chào User" đơn giản cũ |
| 6 | **HealthMonitoringScreen** | `health_monitoring/screens/health_monitoring_screen.dart` | Chỉ MainScreen (tab 0) | — | MainScreen orphan → HealthMonitoringScreen orphan |

---

## 3. Ma trận màn hình — GIỮ (v2, đang dùng)

### 3.1. Có trong App Router

| Màn hình | Route | Ghi chú |
|----------|-------|---------|
| AuthPagesScreen, StartScreen, LoginScreen, ... | /start, /login, ... | Auth flow |
| HomeDashboardScreen | /dashboard | Tab Tôi |
| FamilyShellScreen | /family-management | Tab Gia đình |
| FamilyDashboardScreen | /family-dashboard | Tab con trong FamilyShell |
| ContactListScreen | (trong FamilyShell) | Tab Liên hệ |
| AddContactScreen | /add-contact | |
| LinkedContactDetailScreen | /linked-contact-detail | |
| PersonDetailScreen | /person-detail | |
| DeviceScreen | /device | Tab Thiết bị |
| ProfileShellScreen, ProfileScreen | /profile | Tab Hồ sơ |
| EditProfileScreen, MedicalInfoScreen, ChangePasswordScreen, DeleteAccountScreen | /edit-profile, ... | |
| VitalDetailScreen | /vital-detail | |
| SleepReportScreen, SleepDetailScreen, SleepHistoryScreen, SleepSettingsScreen | /sleep-report, ... | |

### 3.2. Dùng qua Navigator.push (không qua route)

| Màn hình | Ai gọi? | Spec |
|----------|---------|------|
| **DeviceConnectScreen** | DeviceScreen._navigateToConnect() | DEVICE_Connect |
| **DeviceStatusDetailScreen** | DevicePriorityCard._handleDeviceTap() | DEVICE_StatusDetail |
| **DeviceConfigureScreen** | DeviceStatusDetailScreen._navigateToConfigure() | DEVICE_Configure |

### 3.3. Cần giữ — chưa có entry point từ v2 (cần wire sau)

| Màn hình | Hiện dùng bởi | Spec | Hành động |
|----------|---------------|------|-----------|
| **HealthReportScreen** | HealthMonitoringScreen (HealthReportBanner) | MONITORING_HealthHistory | Giữ. Wire từ HomeDashboardScreen.onTapHistory |
| **ManualSOSScreen** | WarningScreen | Phase 4 | Giữ. Wire từ EmergencyStickyBar.onPressed |
| **WarningScreen** | EmergencyMainScreen (tab SOS) | Phase 4 | Giữ. Có thể gộp vào flow SOS |
| **EmergencyMainScreen** | MainScreen (tab Khẩn cấp) | Phase 4 | Giữ. Wire từ EmergencyStickyBar hoặc thêm tab/route |
| **EmergencySOSReceivedListScreen** | EmergencyMainScreen (tab 2) | Phase 4 | Giữ |
| **EmergencySOSDetailScreen** | EmergencySOSReceivedListScreen | Phase 4 | Giữ |

---

## 4. Widget / Provider / Model — XÓA (theo màn v1)

| Loại | File | Lý do |
|------|------|-------|
| Widget | `profile_switcher.dart` | Chỉ HealthMonitoringScreen, SleepReportScreen dùng. Anh đã chuyển linked profile → dead code |
| Provider | `target_profile_provider.dart` | ProfileSwitcher + ProfileScreen.clearData. Có thể bỏ |
| Repository | `family_repository.dart` | Chỉ TargetProfileProvider dùng |
| Model | `relationship.dart` | TargetProfileProvider, FamilyRepository, FamilyManagementScreen |
| Model | `access_profile.dart` | TargetProfileProvider |
| Model | `user_search_result.dart` | FamilyRepository.searchUsers, SearchUserScreen |

### Widget có thể orphan khi xóa HealthMonitoringScreen

| Widget | Dùng bởi | Sau khi xóa HealthMonitoringScreen |
|--------|----------|-------------------------------------|
| HealthReportBanner | HealthMonitoringScreen | Orphan. Có thể chuyển sang HomeDashboardScreen (wire HealthReportScreen) |

---

## 5. File duplicate / cấu trúc lạ

- `health_system/lib/lib/features/family/screens/family_management_screen.dart` — **ĐÃ XÁC NHẬN TỒN TẠI** (path lib/lib sai). Xóa — duplicate.

---

## 6. Refactor cần làm khi xóa

| File | Thay đổi |
|------|----------|
| `app.dart` | Bỏ `TargetProfileProvider` khỏi MultiProvider |
| `profile_screen.dart` | Bỏ `context.read<TargetProfileProvider>().clearData()` khi logout |
| `sleep_report_screen.dart` | Bỏ import ProfileSwitcher, bỏ block `if (profileId != null && showProfileSwitcher)`, bỏ param `showProfileSwitcher` |
| `app_router.dart` | Bỏ `showProfileSwitcher` khỏi SleepReportScreen builder |

---

## 7. Không xóa — cần wire (sau khi dọn v1)

1. **HealthReportScreen** — Thêm route `/health-report` hoặc Navigator.push từ HomeDashboardScreen (onTapHistory "Lịch sử chỉ số").
2. **Emergency flow** — Wire EmergencyStickyBar.onPressed → ManualSOSScreen hoặc EmergencyMainScreen. Hiện `onPressed: () {}` rỗng.

---

## 8. Danh sách xóa cuối cùng (đã kiểm chéo)

### Màn hình (6 file) + 1 duplicate
1. `family/screens/family_management_screen.dart`
2. `lib/lib/features/family/screens/family_management_screen.dart` *(duplicate, path sai)*
3. `family/screens/search_user_screen.dart`
4. `family/screens/user_detail_screen.dart`
5. `home/screens/main_screen.dart`
6. `home/screens/dashboard_screen.dart`
7. `health_monitoring/screens/health_monitoring_screen.dart`

### Widget + Provider + Models (6 file)
8. `family/widgets/profile_switcher.dart`
9. `family/providers/target_profile_provider.dart`
10. `family/repositories/family_repository.dart`
11. `family/models/relationship.dart`
12. `family/models/access_profile.dart`
13. `family/models/user_search_result.dart`

### Refactor (4 file)
- `app.dart`, `profile_screen.dart`, `sleep_report_screen.dart`, `app_router.dart`

---

## 9. Rủi ro đã kiểm tra

| Kiểm tra | Kết quả |
|----------|---------|
| DeviceConnectScreen có bị xóa nhầm? | Không — DeviceScreen dùng |
| DeviceStatusDetailScreen có bị xóa nhầm? | Không — DevicePriorityCard dùng |
| DeviceConfigureScreen có bị xóa nhầm? | Không — DeviceStatusDetailScreen dùng |
| HealthReportScreen có bị xóa nhầm? | Không — Giữ, chỉ HealthMonitoringScreen dùng nhưng spec cần |
| Emergency screens có bị xóa nhầm? | Không — Giữ, cần wire từ EmergencyStickyBar |
| ContactListScreen, LinkedContactDetailScreen? | Không — FamilyShellScreen, app_router dùng |
| FamilyDashboardScreen, PersonDetailScreen? | Không — app_router, FamilyShellScreen dùng |

---

*Báo cáo kiểm tra sâu — đã đối chiếu với app_router, BUILD_PHASES, CROSS_CHECK_REPORT.*
