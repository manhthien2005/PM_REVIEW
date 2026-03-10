# HOME (Mobile)

> Sprint 1-2 | JIRA: N/A (UI Infrastructure) | UC: N/A

## Purpose & Technique

- Main navigation shell with custom bottom navigation bar (5 tabs)
- Gradient blue design with animated tab selection (glow effect, scale animation)
- Routes to 5 feature modules: Health Monitoring, Sleep, Emergency, Device, Profile

## Screen Index

| Screen                   | Path                                            | Status         | Note                            |
| ------------------------ | ----------------------------------------------- | -------------- | ------------------------------- |
| Main Navigation Shell    | lib/features/home/screens/main_screen.dart      | ✅ Implemented | Custom bottom nav bar (120 LOC) |
| Dashboard (Patient View) | lib/features/home/screens/dashboard_screen.dart | ⬜ Placeholder | Simple centered text (20 LOC)   |

## Navigation Structure

**5 Bottom Navigation Tabs:**

1. **Sức khỏe** (Health) → `health_monitoring_screen.dart`
2. **Giấc ngủ** (Sleep) → `sleep_screen.dart`
3. **Cảnh báo** (Warning) → `warning_screen.dart`
4. **Thiết bị** (Device) → `device_screen.dart`
5. **Cá nhân** (Profile) → `profile_screen.dart`

## File Index

| Path                                            | Role                          | LOC |
| ----------------------------------------------- | ----------------------------- | --- |
| lib/features/home/screens/main_screen.dart      | Bottom nav container          | 120 |
| lib/features/home/screens/dashboard_screen.dart | Patient dashboard placeholder | 20  |

## Implementation Details

**Custom Navigation Bar** (replaced default `BottomNavigationBar` due to overflow issues):

- Container height: 70px
- Border radius: 12px
- Gradient: `Colors.blue.shade800` → `Colors.blue.shade600`
- Padding: Bottom 16px, left/right 16px
- Shadow: Blue glow, blur 20px, offset (0,5)

**Tab Selection Animation**:

- Selected icon: 28px with white glow effect (boxShadow with blur 20px, spread 5px)
- Unselected icon: 24px with 50% opacity
- Animation duration: 300ms
- Font: Selected 10px bold, Unselected 10px normal

**Navigation Logic**:

- State management: `StatefulWidget` with `_currentIndex` state
- Tap handler: Updates `_currentIndex` → switches displayed screen
- All screens: Imported from respective feature modules

## Known Issues

- Dashboard screen is placeholder only — no actual patient data display
- All feature screens are placeholders (simple centered text)
- No data flow/state management between screens yet
- No back navigation logic for nested routes

## Cross-References

| Type            | Ref                                                       |
| --------------- | --------------------------------------------------------- |
| DB Tables       | N/A (UI only)                                             |
| UC Files        | N/A                                                       |
| Related Modules | All feature modules (Device, Emergency, Monitoring, etc.) |
| Theme Config    | lib/core/theme/app_theme.dart                             |
| Routing         | lib/core/routes/app_router.dart (routes to MainScreen)    |

## Review

| Date | Score | Detail           |
| ---- | ----- | ---------------- |
| —    | —     | Not reviewed yet |
