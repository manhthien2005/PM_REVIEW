# EMERGENCY SOS — Plan 03: Folder Architecture

> **Agent instruction**: Đọc file này để tạo/sửa đúng cấu trúc thư mục. Đặt file đúng vị trí, import đúng path.

---

## 1. Cấu Trúc Thư Mục Hiện Tại & Mới

```
lib/
├── core/
│   └── routes/
│       └── app_router.dart                    # SỬA: thêm manualSos, emergencySosDetail
│
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_dashboard_screen.dart # SỬA: onPressed EmergencyStickyBar
│   │
│   ├── emergency/
│   │   ├── models/
│   │   │   └── sos_event_model.dart           # CÓ SẴN
│   │   ├── providers/
│   │   │   └── emergency_caregiver_provider.dart  # CÓ SẴN
│   │   ├── repositories/
│   │   │   └── emergency_caregiver_repository.dart # CÓ SẴN
│   │   ├── screens/
│   │   │   ├── manual_sos_screen.dart        # CÓ SẴN - SỬA countdown, navigate
│   │   │   ├── sos_confirm_screen.dart       # MỚI - màn xác nhận sau gửi
│   │   │   ├── emergency_sos_received_list_screen.dart  # CÓ SẴN
│   │   │   ├── emergency_sos_detail_screen.dart         # CÓ SẴN
│   │   │   ├── incoming_sos_alarm_screen.dart           # CÓ SẴN (nếu có)
│   │   │   └── warning_screen.dart           # CÓ SẴN (có thể deprecate)
│   │   └── widgets/
│   │       └── sos_card.dart                 # CÓ SẴN
│   │
│   └── family/
│       ├── models/
│       │   └── family_profile_snapshot.dart   # SỬA: thêm sosId
│       ├── providers/
│       │   └── family_dashboard_mock_provider.dart  # SỬA: gán sosId
│       ├── screens/
│       │   ├── family_shell_screen.dart      # SỬA: thêm tab SOS
│       │   └── family_dashboard_screen.dart  # SỬA: overlay → sosId
│       └── widgets/
│           └── family_sos_full_screen_overlay.dart  # SỬA: onViewDetail(sosId)
│
└── shared/
    └── presentation/
        ├── emergency/
        │   └── emergency_sticky_bar.dart     # CÓ SẴN
        └── theme/
            ├── app_colors.dart
            ├── app_text_styles.dart
            └── app_spacing.dart
```

---

## 2. Import Path Chuẩn

### 2.1. Từ Home

```dart
import 'package:healthguard/core/routes/app_router.dart';
import 'package:healthguard/features/emergency/screens/manual_sos_screen.dart';
import 'package:healthguard/shared/presentation/emergency/emergency_sticky_bar.dart';
```

### 2.2. Từ Emergency

```dart
import 'package:healthguard/core/routes/app_router.dart';
import 'package:healthguard/shared/presentation/theme/app_colors.dart';
import 'package:healthguard/shared/presentation/theme/app_text_styles.dart';
import 'package:healthguard/shared/presentation/theme/app_spacing.dart';
import 'package:healthguard/features/emergency/models/sos_event_model.dart';
import 'package:healthguard/features/emergency/repositories/emergency_caregiver_repository.dart';
import 'package:healthguard/features/emergency/widgets/sos_card.dart';
```

### 2.3. Từ Family

```dart
import 'package:healthguard/core/routes/app_router.dart';
import 'package:healthguard/features/emergency/screens/emergency_sos_received_list_screen.dart';
import 'package:healthguard/features/emergency/screens/emergency_sos_detail_screen.dart';
import 'package:healthguard/features/family/models/family_profile_snapshot.dart';
import 'package:healthguard/features/family/widgets/family_sos_full_screen_overlay.dart';
```

---

## 3. File Mới Cần Tạo

| File | Path | Mô tả |
|------|------|-------|
| SosConfirmScreen | `lib/features/emergency/screens/sos_confirm_screen.dart` | Màn xác nhận sau gửi SOS thành công |

---

## 4. File Cần Sửa

| File | Thay đổi |
|------|----------|
| `app_router.dart` | Thêm route manualSos, emergencySosDetail; thêm case trong switch |
| `home_dashboard_screen.dart` | EmergencyStickyBar onPressed → pushNamed(manualSos) |
| `manual_sos_screen.dart` | Countdown 3; sau gửi → push SosConfirmScreen |
| `family_profile_snapshot.dart` | Thêm field `String? sosId` |
| `family_dashboard_mock_provider.dart` | Gán sosId khi isSosActive |
| `family_shell_screen.dart` | TabController length 3; tab SOS; TabBarView child 3 |
| `family_sos_full_screen_overlay.dart` | onViewDetail(sosId) → push emergencySosDetail |
| `family_dashboard_screen.dart` | Overlay onViewDetail truyền sosId từ profile.sosId |

---

## 5. File Có Thể Deprecate

| File | Lý do |
|------|-------|
| `emergency_main_screen.dart` | Không dùng trong nav chính; SOS List nhúng vào Family Shell |
| `warning_screen.dart` | Tab SOS trong EmergencyMainScreen; có thể giữ nếu deep link cần |

---

## 6. Dependency Graph

```
home_dashboard_screen
  └─ emergency_sticky_bar
  └─ app_router
  └─ manual_sos_screen

manual_sos_screen
  └─ emergency_caregiver_repository
  └─ sos_confirm_screen (mới)
  └─ app_router

family_shell_screen
  └─ emergency_sos_received_list_screen
  └─ family_dashboard_screen
  └─ contact_list_screen

family_dashboard_screen
  └─ family_sos_full_screen_overlay
  └─ family_dashboard_mock_provider
  └─ family_profile_snapshot (có sosId)

family_sos_full_screen_overlay
  └─ app_router (push emergencySosDetail)
  └─ family_profile_snapshot

emergency_sos_received_list_screen
  └─ emergency_caregiver_provider
  └─ sos_card
  └─ emergency_sos_detail_screen
  └─ app_router

emergency_sos_detail_screen
  └─ emergency_caregiver_provider
  └─ app_router
```

---

## 7. Checklist Implement

- [ ] Tạo `sos_confirm_screen.dart` trong `features/emergency/screens/`
- [ ] Sửa `family_profile_snapshot.dart` thêm sosId
- [ ] Sửa `family_dashboard_mock_provider.dart` gán sosId
- [ ] Sửa `family_shell_screen.dart` thêm tab SOS
- [ ] Sửa `family_sos_full_screen_overlay.dart` onViewDetail(sosId)
- [ ] Sửa `family_dashboard_screen.dart` truyền sosId vào overlay
- [ ] Sửa `app_router.dart` thêm 2 route
- [ ] Sửa `home_dashboard_screen.dart` onPressed
- [ ] Sửa `manual_sos_screen.dart` countdown + navigate

---

*Plan 03 — Folder Architecture — v1.0*
