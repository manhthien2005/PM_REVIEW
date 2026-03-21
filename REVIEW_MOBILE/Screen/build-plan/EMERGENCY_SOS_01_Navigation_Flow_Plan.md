# EMERGENCY SOS — Plan 01: Luồng Màn Hình & Navigation

> **Agent instruction**: Đọc file này để hiểu rõ luồng điều hướng và link giữa các màn hình. Implement đúng thứ tự, đúng route name và arguments.

---

## 1. Route Constants (AppRouter)

Thêm vào `lib/core/routes/app_router.dart`:

```dart
static const String manualSos = '/manual-sos';
static const String emergencySosDetail = '/emergency/sos/detail';
```

---

## 2. Ma Trận Điều Hướng

| Từ màn hình | Thao tác | Đến màn hình | Route | Arguments |
|-------------|----------|--------------|-------|-----------|
| **HomeDashboardScreen** | Bấm EmergencyStickyBar | ManualSOSScreen | `manualSos` | — |
| **ManualSOSScreen** | Gửi SOS thành công | SosConfirmScreen (màn xác nhận) | (push cùng stack) | `{ count: int }` |
| **SosConfirmScreen** | Bấm "Về trang chủ" | HomeDashboardScreen | `pushNamedAndRemoveUntil` `/dashboard` | — |
| **FamilyShellScreen** | Tab "SOS" (sub-tab 3) | EmergencySOSReceivedListScreen | (TabBarView child) | — |
| **EmergencySOSReceivedListScreen** | Tap item SOS | EmergencySOSDetailScreen | `emergencySosDetail` | `{ sosId: String }` |
| **FamilySOSFullScreenOverlay** | Bấm "Xem ngay" | EmergencySOSDetailScreen | `emergencySosDetail` | `{ sosId: String }` |
| **IncomingSOSAlarmScreen** | Bấm "Xem chi tiết" | EmergencySOSDetailScreen | `emergencySosDetail` | `{ sosId: String }` |
| **EmergencySOSDetailScreen** | Bấm "Đã xác nhận an toàn" | Pop về trước đó | `Navigator.pop` | — |

---

## 3. Luồng Chi Tiết

### 3.1. Luồng Gửi SOS (Tab Tôi)

```
HomeDashboardScreen
  └─ onEmergencyStickyBarPressed:
       Navigator.pushNamed(context, AppRouter.manualSos)

ManualSOSScreen
  └─ onSosSentSuccess:
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (_) => SosConfirmScreen(recipientCount: count),
         ),
       )

SosConfirmScreen (mới)
  └─ onBackToHome:
       Navigator.pushNamedAndRemoveUntil(
         context, '/dashboard', (r) => r.settings.name == '/dashboard',
       )
```

### 3.2. Luồng Xem Danh Sách SOS (Tab Gia đình)

```
FamilyShellScreen
  └─ TabBarView children[2] = EmergencySOSReceivedListScreen
       (Tab 0: Theo dõi, Tab 1: Liên hệ, Tab 2: SOS)

EmergencySOSReceivedListScreen
  └─ onSosCardTap(sos):
       Navigator.pushNamed(
         context, AppRouter.emergencySosDetail,
         arguments: {'sosId': sos.id},
       )
```

### 3.3. Luồng SOS Active Overlay (Tab Gia đình)

```
FamilyDashboardScreen
  └─ when provider.sosCount > 0:
       showGeneralDialog(..., FamilySOSFullScreenOverlay(...))

FamilySOSFullScreenOverlay
  └─ onViewDetail(primary.id):
       Navigator.pop(context);  // đóng overlay
       Navigator.pushNamed(
         context, AppRouter.emergencySosDetail,
         arguments: {'sosId': primary.sosId},  // CHÚ Ý: sosId, không phải profileId
       )
```

### 3.4. Luồng FCM Deep Link (P1)

```
App handle URI: healthguard://sos/{sosId}
  └─ _routeToDeepLink(AppRouter.emergencySosDetail, {'sosId': sosId})
       HOẶC mở IncomingSOSAlarm với sosId
```

---

## 4. Điều Kiện Hiện Tab SOS

- **FamilyShellScreen**: Tab "SOS" chỉ hiện khi `canReceiveAlerts == true`
- Mock: `canReceiveAlerts = true` (luôn hiện) cho giai đoạn dev
- Khi `canReceiveAlerts == false`: TabController length = 2 (Theo dõi | Liên hệ)

---

## 5. Checklist Implement

- [ ] Thêm `manualSos`, `emergencySosDetail` vào AppRouter
- [ ] HomeDashboardScreen: `EmergencyStickyBar onPressed` → `pushNamed(manualSos)`
- [ ] AppRouter switch case: `manualSos` → ManualSOSScreen
- [ ] AppRouter switch case: `emergencySosDetail` → EmergencySOSDetailScreen(sosId)
- [ ] ManualSOSScreen: sau gửi thành công → push SosConfirmScreen
- [ ] Tạo SosConfirmScreen (màn xác nhận)
- [ ] FamilyShellScreen: thêm tab "SOS", TabBarView child = EmergencySOSReceivedListScreen
- [ ] FamilySOSFullScreenOverlay: onViewDetail → push emergencySosDetail với sosId
- [ ] FamilyProfileSnapshot: thêm field `sosId` khi isSosActive

---

## 6. File Tham Chiếu

| File | Vai trò |
|------|---------|
| `lib/core/routes/app_router.dart` | Định nghĩa route, switch case |
| `lib/features/home/presentation/screens/home_dashboard_screen.dart` | EmergencyStickyBar onPressed |
| `lib/features/emergency/screens/manual_sos_screen.dart` | Navigate sau gửi SOS |
| `lib/features/family/screens/family_shell_screen.dart` | Tab SOS, TabBarView |
| `lib/features/family/screens/family_dashboard_screen.dart` | Overlay logic |
| `lib/features/family/widgets/family_sos_full_screen_overlay.dart` | onViewDetail |
| `lib/features/family/models/family_profile_snapshot.dart` | Thêm sosId |

---

*Plan 01 — Navigation Flow — v1.0*
