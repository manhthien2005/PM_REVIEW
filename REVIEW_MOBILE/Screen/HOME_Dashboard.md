# 📱 HOME — Sức khoẻ của tôi (My Health Dashboard)

> **UC Ref**: UC006, UC007, UC008, UC016, UC020
> **Module**: HOME
> **Status**: 🟡 Planned Refactor Ready

## Purpose
Tab đầu tiên và mặc định của ứng dụng. Đây là **dashboard sức khoẻ cá nhân** của chính user, tập trung vào việc trả lời thật nhanh 3 câu hỏi:

1. **Hôm nay tôi đang ổn hay không?**
2. **Chỉ số nào cần chú ý nhất lúc này?**
3. **Nếu khẩn cấp thì SOS ở đâu?**

Màn hình này chỉ hiển thị dữ liệu của **bản thân user**, không hiển thị dữ liệu người khác. Tab `HOME_FamilyDashboard` vẫn là khu vực duy nhất để theo dõi người thân.

> **Lưu ý kiến trúc**: `HOME_Dashboard` là self-only trong Hybrid Architecture. Không còn `Profile Switcher Context`, không còn trạng thái "đang xem hồ sơ nào" trên màn này.

---

## Navigation Links (🔗 Màn hình Liên quan)
| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| `AUTH_Login` / `AUTH_Splash` | Đăng nhập thành công | → This screen (tab mặc định) |
| This screen | Bấm tab `Gia đình` ở Bottom Nav | → [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) |
| This screen | Bấm vào `VitalMetricCard` | → [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) |
| This screen | Bấm `Xem lịch sử chỉ số` | → [MONITORING_HealthHistory](./MONITORING_HealthHistory.md) |
| This screen | Bấm `SleepInsightCard` | → [SLEEP_Report](./SLEEP_Report.md) |
| This screen | Bấm `RiskInsightCard` | → [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) |
| This screen | Bấm `EmergencyStickyBar` | → [EMERGENCY_ManualSOS](./EMERGENCY_ManualSOS.md) |
| This screen | Bấm tab `Thiết bị` ở Bottom Nav | → [DEVICE_List](./DEVICE_List.md) |
| This screen | Bấm tab `Hồ sơ` ở Bottom Nav | → [PROFILE_Overview](./PROFILE_Overview.md) |
| *System Event* | Resume app khi có `active_sos_event` | → [EMERGENCY_LocalSOSActive](./EMERGENCY_LocalSOSActive.md) |

---

## User Flow
1. Sau khi đăng nhập hoặc mở lại app, user vào thẳng tab **`Sức khoẻ của tôi`**.
2. App gọi `GET /api/mobile/dashboard/self` để lấy snapshot dashboard.
3. Phần đầu màn hiển thị `DashboardGreetingHeader` và `HealthStatusHeroCard`:
   - Greeting cá nhân hoá
   - Thời gian cập nhật mới nhất
   - Trạng thái tổng quát: `Ổn định` / `Cần chú ý` / `Nguy cơ cao`
4. Bên dưới hero là `ConnectionStatusStrip`:
   - Đồng hồ đang online / offline / chưa kết nối
   - Pin thiết bị nếu có
5. `LiveVitalsSection` hiển thị 4 `VitalMetricCard`:
   - Nhịp tim
   - SpO₂
   - Huyết áp
   - Nhiệt độ
   Các card cập nhật real-time qua WebSocket khi tab active; nếu không có realtime thì dùng dữ liệu mới nhất từ API/cache.
6. `SleepInsightCard` tóm tắt giấc ngủ đêm qua bằng ngôn ngữ dễ hiểu, bấm vào để xem sâu hơn.
7. `RiskInsightCard` hiển thị điểm rủi ro AI + level + tóm tắt ngắn, bấm vào để xem báo cáo chi tiết.
8. `EmergencyStickyBar` luôn hiện phía trên `Bottom Navigation`, cho phép vào luồng SOS thủ công mà **không gửi SOS trực tiếp tại dashboard**.
9. Khi app resume:
   - Nếu có `active_sos_event` → điều hướng thẳng sang `EMERGENCY_LocalSOSActive`
   - Nếu không → giữ user tại dashboard

---

## Information Hierarchy
### Thứ tự ưu tiên đọc trên màn

1. **Tình trạng tổng quát của tôi**
2. **Chỉ số nào đang cần chú ý**
3. **Thiết bị có đang cập nhật dữ liệu không**
4. **Insight giấc ngủ và AI risk**
5. **Lối vào SOS**

### Thiết kế tư duy

- **Calm first, alert second**: trạng thái bình thường phải tạo cảm giác yên tâm.
- **State over decoration**: mọi khối đều phục vụ việc đọc trạng thái nhanh.
- **Emergency is available, not screaming**: SOS luôn thấy nhưng không lấn át dashboard routine.

---

## UI Structure
```text
SafeArea
└─ MainScaffoldShell
   ├─ Scrollable dashboard body
   │  ├─ DashboardGreetingHeader
   │  ├─ HealthStatusHeroCard
   │  ├─ ConnectionStatusStrip
   │  ├─ InlineStatusBanner (nếu warning/offline)
   │  ├─ LiveVitalsSection
   │  ├─ SleepInsightCard
   │  ├─ RiskInsightCard
   │  └─ DashboardSecondaryLinks
   ├─ EmergencyStickyBar
   └─ AppShellBottomNav
```

---

## UI States
| Trạng thái | Điều kiện | Hiển thị |
| --- | --- | --- |
| **Loading** | Lần đầu tải sau đăng nhập | Skeleton cho `GreetingHeader`, `HeroCard`, `ConnectionStatusStrip`, 4 `VitalMetricCard`, `SleepInsightCard`, `RiskInsightCard`. `Bottom Navigation` đã ổn định, không nhảy layout. |
| **Success_Normal** | Tất cả chỉ số nằm trong ngưỡng an toàn | `HealthStatusHeroCard` nền xanh nhạt, không có alert banner. Các vital card dùng nền trắng/trung tính với accent xanh. |
| **Success_Warning** | Một hoặc nhiều chỉ số cần theo dõi | `HealthStatusHeroCard` nền vàng nhạt. Có `InlineStatusBanner` ngắn ở trên section vitals. Chỉ card bất thường đổi accent cam. |
| **Success_Critical** | Có chỉ số nguy hiểm | `HealthStatusHeroCard` nền đỏ nhạt + CTA `Gọi trợ giúp ngay`. Card critical được nhấn bằng nền đỏ rất nhạt và label rõ. `EmergencyStickyBar` tăng emphasis. |
| **No_Device** | Chưa kết nối đồng hồ | `HealthStatusHeroCard` chuyển thành onboarding nhẹ: "Kết nối đồng hồ để bắt đầu theo dõi". Ẩn vitals thực, thay bằng card hướng dẫn kết nối. |
| **Device_Offline** | Đồng hồ đã từng kết nối nhưng hiện offline | `ConnectionStatusStrip` hiển thị trạng thái offline + timestamp dữ liệu cuối cùng. Vital cards vẫn hiện cache với badge `Dữ liệu gần nhất`. |
| **Offline** | Điện thoại mất mạng | Banner vàng ở đầu content. Vẫn hiển thị dữ liệu cache. Không phá `Bottom Navigation` hay sticky SOS. |
| **Error** | Lỗi API | Hiển thị `InlineErrorBlock` trong content với nút `Thử lại`. Có thể dùng snackbar như tín hiệu phụ nhưng không phải cơ chế chính. |

---

## Bottom Navigation Spec
### Mục tiêu

`Bottom Navigation` là shell điều hướng chính dùng chung cho app, không phải thành phần riêng của mỗi màn.

### Cấu hình

- **Tab cố định**: `Tôi`, `Gia đình`, `Thiết bị`, `Hồ sơ`
- **Số tab**: 4
- **Chiều cao**: `72dp + safe area`
- **Icon size**: `22-24dp`
- **Label size**: `12-13sp`
- **Touch target tối thiểu**: `64dp x 48dp`
- **Active state**:
  - indicator pill mềm
  - icon `brand.primary`
  - label semi-bold
- **Inactive state**:
  - icon muted
  - label vẫn luôn hiện
- **Badge rules**:
  - `Gia đình`: badge đỏ nhỏ khi có SOS linked profile hoặc cảnh báo critical chưa đọc
  - `Thiết bị`: badge chấm nhỏ khi thiết bị cần attention
  - `Tôi`: không dùng badge mặc định
  - `Hồ sơ`: không dùng badge mặc định

### Accessibility

- Không ẩn label ở tab inactive
- Mỗi tab có semantic label riêng
- Badge phải được screen reader đọc thành "có cảnh báo"

---

## Visual Direction
### Theme direction

Theme refactor theo hướng **`HealthGuard Calm`**:

- nền sáng, sạch, dễ đọc
- màu trạng thái dùng tiết chế, chỉ accent vào đúng điểm cần chú ý
- không dùng full-fill xanh/cam/đỏ trên toàn bộ grid khi chưa cần

### Palette gợi ý

| Token | Value gợi ý | Vai trò |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Nền app |
| `bg.surface` | `#FFFFFF` | Card chính |
| `bg.elevated` | `#EEF4FF` | Hero / elevated surface |
| `text.primary` | `#12304A` | Nội dung chính |
| `text.secondary` | `#5B7288` | Phụ đề / metadata |
| `brand.primary` | `#2F80ED` | CTA phụ / active tab |
| `success` | `#2E9B6F` | Normal |
| `warning` | `#F2A93B` | Warning |
| `critical` | `#D95C5C` | Critical |
| `emergency` | `#C83D3D` | SOS |

### Typography

- Display compact: `28-30sp`
- Section title: `20sp`
- Vital value: `24-28sp`
- Body: `16-17sp`
- Caption: `14sp`

---

## Layout Gợi ý
```text
┌─────────────────────────────────────────────┐
│ [Avatar] Chào Minh Thiện        [🔔•]       │
│ Cập nhật sức khoẻ mới nhất lúc 08:42        │
├─────────────────────────────────────────────┤
│  Hôm nay bạn đang ổn                         │  ← HealthStatusHeroCard
│  [Ổn định] Các chỉ số hiện trong ngưỡng an toàn │
│  [Xem lịch sử chỉ số →]                      │
├─────────────────────────────────────────────┤
│  [⌚ Đồng hồ đang kết nối]  [Pin 82%]        │  ← ConnectionStatusStrip
├─────────────────────────────────────────────┤
│  ❤️ Nhịp tim     💧 SpO₂                     │
│  82 BPM          97%                         │
│  Bình thường     Tốt                         │
│                                             │  ← LiveVitalsSection
│  🩸 Huyết áp      🌡️ Nhiệt độ                │
│  120/80          36.5°C                      │
│  Theo dõi        Tốt                         │
├─────────────────────────────────────────────┤
│  😴 Giấc ngủ đêm qua                         │  ← SleepInsightCard
│  7h20 ngủ • Chất lượng tốt                   │
│  Nhịp tim khi ngủ: 58 BPM                    │
├─────────────────────────────────────────────┤
│  🤖 Điểm rủi ro AI                           │  ← RiskInsightCard
│  [32/100] Thấp                               │
│  Không có nguy cơ đáng lo ngại               │
├─────────────────────────────────────────────┤
│  [ 🆘 GỬI TÍN HIỆU KHẨN CẤP SOS ]            │  ← EmergencyStickyBar
└─────────────────────────────────────────────┘
        [Tôi] [Gia đình] [Thiết bị] [Hồ sơ]      ← AppShellBottomNav
```

---

## Edge Cases
- [x] **Thiết bị chưa từng kết nối** → `No_Device` state với hướng dẫn rõ ràng, không hiển thị số giả như `0` hay `--`.
- [x] **Resume app khi đang có SOS active** → redirect sang `EMERGENCY_LocalSOSActive`; dashboard không được flicker trước rồi mới chuyển.
- [x] **AI Fall Detection phát cảnh báo đột ngột** → `EMERGENCY_FallAlert` có ưu tiên P0, đè lên dashboard mà không cần đổi tab.
- [x] **Người lớn tuổi mở app lần đầu, chưa có dữ liệu đo** → hero card dùng copy nhẹ nhàng, mỗi vital card hiển thị "Đang chờ dữ liệu từ đồng hồ".
- [x] **Text Scaling 150-200%** → `LiveVitalsSection` tự chuyển từ grid 2 cột sang list dọc. `Bottom Navigation` vẫn giữ label.
- [x] **User bấm nhầm SOS** → luôn đi qua `EMERGENCY_ManualSOS` với countdown + slide-to-cancel; dashboard không trigger SOS trực tiếp.
- [x] **Device offline nhưng phone online** → dùng cache cuối cùng + timestamp rõ + strip trạng thái offline.
- [x] **API lỗi trong khi có cache** → dùng `InlineErrorBlock` nhưng vẫn giữ content cũ nếu có dữ liệu trước đó.

---

## Data Requirements
- **API Endpoint:**
  - `GET /api/mobile/dashboard/self`
    - `vitals: { hr, spo2, bp_sys, bp_dia, temp, last_updated }`
    - `sleep_summary: { duration_min, quality, avg_hr_sleep }`
    - `risk_score: { score, level, summary }`
    - `device_status: { connected, battery_percent }`
    - `active_sos_event?`
- **Realtime:**
  - `WS /api/mobile/vitals/stream` chỉ hoạt động khi tab đang active và màn đang visible
- **Cache:**
  - lưu snapshot dashboard cuối cùng để support `Offline` và `Device_Offline`

---

## Shared Widgets
- `AppShellBottomNav`
- `DashboardGreetingHeader`
- `HealthStatusHeroCard`
- `ConnectionStatusStrip`
- `InlineStatusBanner`
- `VitalMetricCard`
- `SleepInsightCard`
- `RiskInsightCard`
- `EmergencyStickyBar`
- `InlineErrorBlock`

---

## Sync Notes
- **Không còn Profile Switcher** ở màn này. Dữ liệu luôn là self profile.
- **Tách biệt hoàn toàn** với `HOME_FamilyDashboard`: self data và linked-profile data không bao giờ trộn trong cùng UI tree.
- WebSocket ở màn này chỉ phục vụ **self vitals**. `HOME_FamilyDashboard` vẫn dùng polling 30s + FCM.
- Màn hình này **không nhận** SOS notification của người khác trong content; linked SOS chỉ đi qua `HOME_FamilyDashboard` hoặc `EMERGENCY_IncomingSOSAlarm`.
- `Bottom Navigation` là shell dùng chung, spec tại màn này được coi là chuẩn để tái áp dụng cho các tab còn lại.
- SOS action được refactor từ FAB sang `EmergencyStickyBar` phía trên nav để tăng khả năng chạm và giảm cảm giác báo động liên tục.

---

## Design Context
- **Target audience**: User xem sức khoẻ của chính mình; ưu tiên người cao tuổi hoặc người tự theo dõi.
- **Usage context**: Routine dashboard — màn mặc định mỗi khi mở app.
- **Key UX priority**: Clarity, Calm, Speed-to-understand, Safe emergency access.
- **Specific constraints**:
  - font lớn, body >= `16sp`
  - touch target >= `48dp`
  - text scaling `150-200%` vẫn usable
  - SOS phải nổi bật nhưng không áp đảo màn hình khi trạng thái bình thường

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `build-plan/HOME_Dashboard_plan.md` |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

### Companion Docs

- `build-plan/HOME_Dashboard_plan.md`
- `build-plan/HOME_Dashboard_wireframe.md`
- `build-plan/HOME_Dashboard_flutter_widget_tree.md`

---

## Changelog
| Version | Date       | Author | Changes |
| ------- | ---------- | ------ | ------- |
| v1.0 | 2026-03-16 | AI | Initial creation — Hybrid Architecture (Self-only, bỏ Profile Switcher) |
| v2.0 | 2026-03-17 | AI | Regen: bổ sung Design Context, Pipeline Status theo template chuẩn mới |
| v3.0 | 2026-03-18 | AI | Refactor spec theo `Calm Clinical Dashboard`: thêm `HealthStatusHeroCard`, `ConnectionStatusStrip`, `SleepInsightCard`, `RiskInsightCard`, `EmergencyStickyBar`, chuẩn hoá `AppShellBottomNav`, đồng bộ với plan refactor và theme mới |
