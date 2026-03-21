# 🏗️ HOME_Dashboard — Flutter-ready Widget Tree

> **Screen**: `HOME_Dashboard`
> **Goal**: Handoff cho dev để tách widget nhanh, build theo component thay vì mò lại từ spec
> **Companion docs**:
> - `HOME_Dashboard.md`
> - `HOME_Dashboard_plan.md`
> - `HOME_Dashboard_wireframe.md`

---

## 1. Build mindset

### Mục tiêu build

- Build dashboard theo hướng **shell trước, content sau, state cuối cùng**.
- Tách rõ:
  - `screen orchestration`
  - `section widgets`
  - `state widgets`
  - `shared shell widgets`

### Flutter principles áp dụng

- Dùng `const` ở mọi widget tĩnh có thể.
- Chia nhỏ widget theo section, tránh một file `build()` quá dài.
- `Bottom Navigation` và `EmergencyStickyBar` phải là shared widgets, không hardcode ngay trong screen.
- Dùng `LayoutBuilder` hoặc breakpoint helper cho grid/list responsive.

---

## 2. Widget Tree tổng thể

```dart
MainScaffoldShell(
  backgroundColor: AppColors.bgPrimary,
  currentTab: AppMainTab.me,
  bottomNavigation: AppShellBottomNav(
    currentTab: AppMainTab.me,
    familyHasAlertBadge: familyHasAlertBadge,
    deviceHasAttentionBadge: deviceHasAttentionBadge,
    onTabSelected: onTabSelected,
  ),
  stickyBottomBar: EmergencyStickyBar(
    emphasis: emergencyBarEmphasis,
    onPressed: onTapManualSos,
  ),
  child: SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: DashboardGreetingHeader(...)),
          SliverToBoxAdapter(child: HealthStatusHeroCard(...)),
          SliverToBoxAdapter(child: ConnectionStatusStrip(...)),
          SliverToBoxAdapter(child: DashboardTopBannerArea(...)),
          SliverToBoxAdapter(child: LiveVitalsSection(...)),
          SliverToBoxAdapter(child: SleepInsightCard(...)),
          SliverToBoxAdapter(child: RiskInsightCard(...)),
          SliverToBoxAdapter(child: DashboardSecondaryLinks(...)),
          SliverPadding(
            padding: EdgeInsets.only(bottom: stickyBottomBarSpacing),
            sliver: SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ),
  ),
);
```

---

## 3. Suggested file structure

```text
lib/
└─ features/home/presentation/
   ├─ screens/
   │  └─ home_dashboard_screen.dart
   ├─ widgets/
   │  ├─ dashboard_greeting_header.dart
   │  ├─ health_status_hero_card.dart
   │  ├─ connection_status_strip.dart
   │  ├─ dashboard_top_banner_area.dart
   │  ├─ live_vitals_section.dart
   │  ├─ vital_metric_card.dart
   │  ├─ sleep_insight_card.dart
   │  ├─ risk_insight_card.dart
   │  ├─ dashboard_secondary_links.dart
   │  └─ inline_error_block.dart
   └─ models/
      └─ home_dashboard_view_model.dart

lib/shared/presentation/
├─ shell/
│  ├─ main_scaffold_shell.dart
│  └─ app_shell_bottom_nav.dart
├─ emergency/
│  └─ emergency_sticky_bar.dart
├─ feedback/
│  ├─ inline_status_banner.dart
│  └─ semantic_badge.dart
└─ theme/
   ├─ app_colors.dart
   ├─ app_text_styles.dart
   ├─ app_spacing.dart
   ├─ app_radii.dart
   └─ app_bottom_nav_tokens.dart
```

---

## 4. Screen composition chi tiết

## 4.1 `HomeDashboardScreen`

### Responsibility

- bind state từ bloc/cubit/viewmodel
- resolve screen-level state
- map state sang section widgets
- wire navigation callbacks

### Pseudo structure

```dart
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        final vm = HomeDashboardViewModel.fromState(state);

        return MainScaffoldShell(
          currentTab: AppMainTab.me,
          bottomNavigation: AppShellBottomNav(
            currentTab: AppMainTab.me,
            familyHasAlertBadge: vm.familyHasAlertBadge,
            deviceHasAttentionBadge: vm.deviceNeedsAttention,
            onTabSelected: (tab) => _onTabSelected(context, tab),
          ),
          stickyBottomBar: EmergencyStickyBar(
            emphasis: vm.emergencyBarEmphasis,
            onPressed: () => _openManualSos(context),
          ),
          child: _DashboardBody(vm: vm),
        );
      },
    );
  }
}
```

---

## 4.2 `_DashboardBody`

### Responsibility

- build scrollable content
- giữ padding và spacing thống nhất
- hiển thị section theo đúng order ưu tiên

### Suggested tree

```dart
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.vm});

  final HomeDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: vm.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AppSpacing.screenHorizontalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                DashboardGreetingHeader(...),
                SizedBox(height: AppSpacing.sectionGapMd),
                HealthStatusHeroCard(...),
                SizedBox(height: AppSpacing.sectionGapSm),
                ConnectionStatusStrip(...),
                SizedBox(height: AppSpacing.sectionGapSm),
                DashboardTopBannerArea(...),
                SizedBox(height: AppSpacing.sectionGapMd),
                LiveVitalsSection(...),
                SizedBox(height: AppSpacing.sectionGapMd),
                SleepInsightCard(...),
                SizedBox(height: AppSpacing.sectionGapMd),
                RiskInsightCard(...),
                SizedBox(height: AppSpacing.sectionGapMd),
                DashboardSecondaryLinks(...),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}
```

---

## 5. Section widgets

## 5.1 `DashboardGreetingHeader`

### Inputs

- `displayName`
- `avatarUrl`
- `latestUpdatedLabel`
- `hasUnreadNotifications`
- `onTapNotifications`

### Responsibility

- show greeting
- show metadata line
- show notification icon/badge

### Notes

- metadata line đổi nội dung theo state:
  - normal: cập nhật lúc...
  - device offline: đồng hồ offline...
  - offline: đang hiển thị dữ liệu đã lưu...

---

## 5.2 `HealthStatusHeroCard`

### Inputs

- `overallStatus`
- `title`
- `summary`
- `secondaryCtaLabel`
- `onTapSecondaryCta`
- `showCallHelpCta`
- `onTapCallHelp`

### Responsibility

- render health summary quan trọng nhất trên màn
- đổi visual theo `normal / warning / critical / noDevice`

### Suggested enum

```dart
enum DashboardOverallStatus {
  normal,
  warning,
  critical,
  noDevice,
  offline,
}
```

---

## 5.3 `ConnectionStatusStrip`

### Inputs

- `deviceConnectionState`
- `batteryPercent`
- `lastUpdatedLabel`
- `onTapDevice`

### Responsibility

- trả lời nhanh "thiết bị có đang gửi dữ liệu thật không?"
- giữ UI gọn, không chiếm nhiều chiều cao

### Suggested enum

```dart
enum DeviceConnectionUiState {
  connected,
  offline,
  notPaired,
}
```

---

## 5.4 `DashboardTopBannerArea`

### Responsibility

- render optional top banners:
  - warning banner
  - offline banner
  - error block
- nếu không có banner nào thì trả `SizedBox.shrink()`

### Suggested tree

```dart
if (vm.hasError) {
  return InlineErrorBlock(...);
}

if (vm.isOffline) {
  return InlineStatusBanner.offline(...);
}

if (vm.hasWarningBanner) {
  return InlineStatusBanner.warning(...);
}

return const SizedBox.shrink();
```

---

## 5.5 `LiveVitalsSection`

### Inputs

- `List<VitalMetricItem> items`
- `bool useSingleColumnLayout`
- `VoidCallback? onTapHistory`

### Responsibility

- render title section
- render 4 metric cards
- tự quyết định grid hay list

### Suggested model

```dart
class VitalMetricItem {
  final VitalMetricType type;
  final String label;
  final String value;
  final String statusLabel;
  final String? timestampLabel;
  final VitalMetricVisualState visualState;
  final VoidCallback onTap;
}
```

### Suggested layout logic

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final useSingleColumn =
        MediaQuery.textScalerOf(context).scale(1) >= 1.4 ||
        constraints.maxWidth < 360;

    if (useSingleColumn) {
      return Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VitalMetricCard(item: item),
                ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) => VitalMetricCard(item: items[index]),
    );
  },
);
```

---

## 5.6 `VitalMetricCard`

### Inputs

- `VitalMetricItem item`

### Responsibility

- hiển thị icon, nhãn, giá trị, status, timestamp
- accent visual theo `normal / warning / critical / stale`

### Suggested enum

```dart
enum VitalMetricVisualState {
  normal,
  warning,
  critical,
  stale,
  empty,
}
```

### Notes

- Không tô full đỏ/vàng cả card nếu chỉ warning.
- Critical có thể dùng nền tint nhẹ hơn bình thường.

---

## 5.7 `SleepInsightCard`

### Inputs

- `title`
- `durationLabel`
- `qualityLabel`
- `avgSleepHrLabel`
- `insightSummary`
- `onTap`

### Responsibility

- hiển thị insight dạng human-readable, không chỉ raw numbers

### Suggested layout

```dart
InsightCardBase(
  leadingIcon: AppIcons.sleep,
  title: 'Giấc ngủ đêm qua',
  trailingCtaLabel: 'Xem chi tiết',
  onTap: onTap,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(durationLabel, style: AppTextStyles.metricLarge),
      Text('$qualityLabel • $avgSleepHrLabel'),
      Text(insightSummary),
    ],
  ),
);
```

---

## 5.8 `RiskInsightCard`

### Inputs

- `scoreLabel`
- `levelLabel`
- `summary`
- `riskVisualState`
- `onTap`

### Responsibility

- hiển thị score + meaning, tránh để user phải tự diễn giải con số

### Suggested enum

```dart
enum RiskVisualState {
  low,
  moderate,
  high,
}
```

---

## 5.9 `DashboardSecondaryLinks`

### Responsibility

- chứa quick links phụ như:
  - `Xem lịch sử chỉ số`
  - `Thiết bị`
  - `Thông báo`

### Rule

- Đây là secondary navigation, không được cạnh tranh visual với hero hay SOS.

---

## 6. Shared shell widgets

## 6.1 `MainScaffoldShell`

### Responsibility

- background chung
- handle bottom safe area
- render `bottomNavigation`
- render `stickyBottomBar`
- đảm bảo scroll body không bị che

### Required API

```dart
class MainScaffoldShell extends StatelessWidget {
  const MainScaffoldShell({
    super.key,
    required this.child,
    required this.currentTab,
    required this.bottomNavigation,
    this.stickyBottomBar,
    this.backgroundColor,
  });
}
```

---

## 6.2 `AppShellBottomNav`

### Inputs

- `currentTab`
- `familyHasAlertBadge`
- `deviceHasAttentionBadge`
- `onTabSelected`

### Responsibility

- shell nav dùng chung cho app
- giữ label luôn hiện
- active indicator dạng pill

### Suggested enum

```dart
enum AppMainTab {
  me,
  family,
  device,
  profile,
}
```

---

## 6.3 `EmergencyStickyBar`

### Inputs

- `VoidCallback onPressed`
- `EmergencyBarEmphasis emphasis`

### Suggested enum

```dart
enum EmergencyBarEmphasis {
  defaultLevel,
  heightened,
}
```

### Responsibility

- CTA khẩn cấp luôn visible
- chuyển emphasis theo `normal` vs `critical`
- không gửi SOS trực tiếp; chỉ mở `ManualSOS`

---

## 7. State mapping

| Domain state | Screen handling | Widget notes |
| --- | --- | --- |
| initial loading | render skeleton version | shell ổn định |
| success normal | hero normal + neutral cards | no top banner |
| success warning | hero warning + warning banner | chỉ affected cards đổi accent |
| success critical | hero critical + call help CTA | sticky bar emphasis heightened |
| no device | noDevice hero + pairing CTA | live vitals thay bằng onboarding |
| device offline | offline strip + cached vitals | timestamp rõ |
| offline phone | offline banner + cached content | nav/sos không đổi |
| api error | inline error block | cache nếu có vẫn hiện |

---

## 8. Suggested view model shape

```dart
class HomeDashboardViewModel {
  final String displayName;
  final String? avatarUrl;
  final String latestUpdatedLabel;
  final DashboardOverallStatus overallStatus;
  final String heroTitle;
  final String heroSummary;
  final bool showCallHelpCta;

  final DeviceConnectionUiState deviceConnectionState;
  final int? batteryPercent;
  final bool isOffline;
  final bool hasWarningBanner;
  final bool hasError;

  final List<VitalMetricItem> vitalItems;

  final String sleepDurationLabel;
  final String sleepQualityLabel;
  final String sleepAvgHrLabel;
  final String sleepInsightSummary;

  final String riskScoreLabel;
  final String riskLevelLabel;
  final String riskSummary;
  final RiskVisualState riskVisualState;

  final bool familyHasAlertBadge;
  final bool deviceNeedsAttention;
  final EmergencyBarEmphasis emergencyBarEmphasis;

  final Future<void> Function() onRefresh;
}
```

---

## 9. Build order gợi ý cho dev

1. Build `AppShellBottomNav`
2. Build `EmergencyStickyBar`
3. Build `DashboardGreetingHeader`
4. Build `HealthStatusHeroCard`
5. Build `ConnectionStatusStrip`
6. Build `VitalMetricCard`
7. Build `LiveVitalsSection`
8. Build `SleepInsightCard`
9. Build `RiskInsightCard`
10. Build `DashboardTopBannerArea`
11. Wire `HomeDashboardScreen`
12. Add responsive behavior + semantics
13. Add loading/error/offline/no-device states

---

## 10. Quick acceptance checklist

- [ ] `Bottom Navigation` là shared widget, không hardcode trong screen
- [ ] `EmergencyStickyBar` không che scroll content
- [ ] `LiveVitalsSection` chuyển list dọc khi text scale lớn
- [ ] Warning chỉ accent đúng card bất thường
- [ ] Critical nổi bật hơn warning nhưng không full-screen panic
- [ ] `Error` dùng inline block, không snackbar-only
- [ ] Mọi tab nav có semantic label
- [ ] SOS chỉ mở `ManualSOS`, không trigger trực tiếp từ dashboard
