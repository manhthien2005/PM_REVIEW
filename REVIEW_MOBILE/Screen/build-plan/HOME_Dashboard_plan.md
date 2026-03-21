# 📐 UI Refactor Plan — HOME_Dashboard + Bottom Navigation

> **Plan type**: Refactor UI/UX + Theme alignment
> **Target screen**: `HOME_Dashboard`
> **Scope mở rộng**: `Bottom Navigation Bar` dùng chung cho shell chính
> **Related specs**: `HOME_Dashboard.md`, `HOME_FamilyDashboard.md`, `Screen/README.md`
> **Status**: Draft for review

---

## 1. Understanding Lock

### Tóm tắt bài toán

- Refactor lại tab mặc định `HOME_Dashboard` để màn hình nhìn hiện đại hơn, bình tĩnh hơn, ít "dữ liệu thô" hơn nhưng vẫn đọc nhanh.
- Refactor luôn `Bottom Navigation Bar` vì đây là shell lõi ảnh hưởng trực tiếp đến cảm nhận của toàn app.
- Kết quả phải dùng được như **mẫu chuẩn** để áp dụng cho các màn còn lại, đặc biệt là `HOME_FamilyDashboard`, `DEVICE_List`, `PROFILE_Overview`.
- Kiến trúc **Hybrid Tabs** phải được giữ nguyên: `HOME_Dashboard` là self-only, `HOME_FamilyDashboard` là family-only.
- Ưu tiên UX cho người lớn tuổi hoặc người tự theo dõi sức khoẻ: chữ lớn, phân cấp rõ, ít nhiễu, thao tác chạm dễ, tránh gây hoảng loạn.
- Cho phép refactor theme nếu cần, nhưng theme mới phải đủ linh hoạt để dùng xuyên suốt app, không chỉ đẹp riêng cho một màn.

### Assumptions

- App là mobile app cross-platform, nhiều khả năng dùng `Flutter`, target cả iOS và Android.
- `Bottom Navigation` vẫn giữ **4 tab chính**: `Tôi`, `Gia đình`, `Thiết bị`, `Hồ sơ`; không đổi IA ở mức route.
- Nút SOS **không** được đưa vào `Bottom Navigation`; vẫn là CTA tách riêng có độ ưu tiên cao hơn.
- Dữ liệu backend, luồng điều hướng, và các trạng thái business hiện có không thay đổi; chỉ refactor presentation, shell, và design system.
- `HOME_Dashboard` vẫn phải support đầy đủ các state trong spec: `Loading`, `Success_Normal`, `Success_Warning`, `Success_Critical`, `No_Device`, `Device_Offline`, `Error`, `Offline`.

### Open Questions

- Có muốn ưu tiên visual gần `Material 3` mặc định hay chấp nhận một design language riêng rõ nét hơn cho app y tế này?
- Badge cảnh báo trên `Bottom Navigation` có nên xuất hiện ở tab `Gia đình` khi có SOS linked profile không?
- Mức độ animation mong muốn là tối giản hay trung bình?

> Nếu chưa có câu trả lời ngay cho các câu hỏi trên, plan này sẽ dùng phương án mặc định: `Material 3 + custom health theme`, badge cảnh báo có điều kiện ở tab `Gia đình`, animation nhẹ.

---

## 2. MFRI Quick Check

### Mobile Feasibility & Risk Index

| Dimension | Đánh giá | Ghi chú |
| --- | --- | --- |
| Platform clarity | 4/5 | Chưa nêu chính thức nhưng ngữ cảnh mobile app rõ |
| Interaction complexity | 3/5 | Có state health, emergency CTA, nav shell |
| Performance risk | 3/5 | Dashboard nhiều state, có real-time vitals |
| Offline dependence | 4/5 | Bắt buộc hiển thị cache, offline banner |
| Accessibility readiness | 5/5 | Yêu cầu đã khá rõ trong spec |

**Kết luận MFRI**: `+2` đến `+3`  
Refactor khả thi, nhưng cần tránh layout quá giàu thông tin và tránh nav animation nặng.

---

## 3. Mục tiêu Refactor

### Mục tiêu chính

1. Làm cho `HOME_Dashboard` dễ quét trong 3-5 giây, ngay cả khi user mới mở app hoặc đang căng thẳng.
2. Giảm cảm giác "màn tổng hợp kỹ thuật", tăng cảm giác "bảng sức khoẻ cá nhân dễ hiểu".
3. Tách rõ 3 lớp thông tin:
   - Tình trạng hiện tại
   - Chỉ số quan trọng
   - Insight / điều hướng sâu
4. Biến `Bottom Navigation` thành shell thống nhất, dễ mở rộng, dễ tái dùng.
5. Tạo một **theme/tokens layer** đủ mạnh để áp dụng cho nhiều màn tiếp theo mà không phải chỉnh lại từng chỗ.

### Non-goals

- Không thay đổi business logic của WebSocket, polling, cache, hay SOS flow.
- Không gộp `HOME_Dashboard` và `HOME_FamilyDashboard`.
- Không thêm tab mới.
- Không biến dashboard thành màn biểu đồ chi tiết.

---

## 4. Đánh giá màn hiện tại

### Điểm mạnh hiện có trong spec

- Đã có phân tách rất rõ `self` vs `family`.
- State business đầy đủ, phù hợp app y tế.
- SOS được coi là hành động ưu tiên và có flow an toàn.
- Responsive text scaling đã được nghĩ đến.

### Vấn đề UX tiềm ẩn nếu build đúng theo spec hiện tại nhưng không refactor

1. **Thông tin ngang hàng quá nhiều**  
   Grid 2x2 vitals + sleep + risk + SOS trong cùng một trục ưu tiên dễ làm người dùng không biết nhìn đâu trước.

2. **Màu trạng thái dễ trở nên "ồn"**  
   Nếu mỗi card tự tô xanh/cam/đỏ mạnh, toàn màn sẽ bị chói và tăng stress.

3. **Header còn khá generic**  
   Greeting + ngày tháng tốt, nhưng chưa có "health summary" để user hiểu ngay trạng thái hiện tại.

4. **Bottom nav chưa được định nghĩa như một shell system**  
   Mới chỉ là danh sách tab; chưa có rule rõ về chiều cao, safe area, badge, active indicator, icon-label hierarchy.

5. **SOS cạnh tranh thị giác với dữ liệu**  
   Nếu FAB đỏ luôn nổi bật mạnh, dashboard routine sẽ luôn mang cảm giác báo động.

---

## 5. Các hướng thiết kế

### Option A — Calm Clinical Dashboard

**Khuyến nghị chọn**

- Màn hình có một "hero summary" bình tĩnh ở trên.
- Vital cards dùng nền trung tính; màu trạng thái chỉ là accent, không phủ full card trừ critical.
- Sleep, risk, device status được gom thành insight cards theo chiều dọc.
- SOS là sticky action riêng, rõ ràng nhưng không phá mood của màn.

**Ưu điểm**

- Dễ nhân rộng sang toàn app.
- Hợp với người lớn tuổi.
- Giữ cân bằng giữa y tế và thân thiện.

**Nhược điểm**

- Cần thiết kế token kỹ hơn.

### Option B — Data Dense Medical Console

- Ưu tiên hiển thị càng nhiều dữ liệu càng tốt ngay trên fold đầu.
- Hợp với caregiver, ít hợp với self-screen cho người cao tuổi.

**Không khuyến nghị** vì tăng cognitive load.

### Option C — Hero-first Wellness Dashboard

- Tập trung visual đẹp, các chỉ số bị ẩn sâu hơn.

**Không khuyến nghị** vì app này có tính safety-critical, cần đọc nhanh số liệu thật.

### Quyết định

Chọn **Option A — Calm Clinical Dashboard**.

---

## 6. Design Direction Đề xuất

### Concept

**“Calm, trustworthy, fast-to-read.”**

Dashboard phải cho cảm giác:

- Bình tĩnh khi mọi thứ ổn
- Cảnh báo rõ khi có vấn đề
- Không bắt user suy nghĩ nhiều để hiểu trạng thái

### Visual principles

1. **Calm first, alert second**  
   Màu base luôn trung tính. Màu cảnh báo chỉ xuất hiện có chủ đích.

2. **State over decoration**  
   Mọi visual phải giúp đọc trạng thái nhanh hơn, không chỉ để đẹp.

3. **One-primary-focus per section**  
   Mỗi block chỉ có 1 điểm nhấn.

4. **Emergency is available, not screaming**  
   Nút SOS luôn sẵn sàng nhưng không biến màn dashboard thành màn panic.

---

## 7. Theme Refactor Đề xuất

## 7.1 Theme Strategy

Đề xuất chuyển từ kiểu màu chức năng rời rạc sang một **Health Design Token System**:

- `surface`: nền chính, card, elevated card
- `content`: text primary, secondary, tertiary
- `accent`: brand/interactive
- `semantic`: success, warning, critical, info
- `emergency`: dành riêng cho SOS

### Theme name gợi ý

`HealthGuard Calm`

## 7.2 Palette đề xuất

| Token | Value gợi ý | Vai trò |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Nền app |
| `bg.surface` | `#FFFFFF` | Card chính |
| `bg.elevated` | `#EEF4FF` | Hero / card nhấn nhẹ |
| `text.primary` | `#12304A` | Nội dung chính |
| `text.secondary` | `#5B7288` | Phụ đề |
| `stroke.soft` | `#D8E3EE` | Border nhẹ |
| `brand.primary` | `#2F80ED` | Active state, CTA phụ |
| `success` | `#2E9B6F` | Bình thường |
| `warning` | `#F2A93B` | Theo dõi |
| `critical` | `#D95C5C` | Nguy hiểm |
| `emergency` | `#C83D3D` | SOS |
| `info` | `#4B8BBE` | Device/offline/info |

## 7.3 Typography

| Role | Size | Weight | Use |
| --- | --- | --- | --- |
| Display compact | 28-30sp | SemiBold/Bold | Hero status |
| Section title | 20sp | SemiBold | Tên block |
| Vital value | 24-28sp | Bold | Nhịp tim, SpO2, v.v. |
| Body | 16-17sp | Regular/Medium | Text chính |
| Caption | 14sp | Medium | Timestamp, hint |
| Nav label | 12-13sp | Medium/SemiBold | Bottom nav |

## 7.4 Radius, spacing, elevation

- Radius hệ thống: `16`, `20`, `24`
- Horizontal padding màn: `20dp`
- Khoảng cách section: `16-20dp`
- Card padding: `16dp`
- Sticky bottom CTA gap với nav: `12dp`
- Shadow cực nhẹ; ưu tiên phân tách bằng surface + stroke

---

## 8. Kiến trúc UI mới cho HOME_Dashboard

### Cấu trúc tổng thể

```text
SafeArea
└─ Scaffold
   ├─ AppBar / Top greeting
   ├─ Scrollable content
   │  ├─ Health status hero
   │  ├─ Device / connectivity strip
   │  ├─ Live vitals section
   │  ├─ Sleep insight card
   │  ├─ Risk insight card
   │  └─ Quick links / secondary actions
   ├─ Sticky SOS action
   └─ Shared Bottom Navigation
```

### Thứ tự ưu tiên nội dung mới

1. **Tôi đang ổn hay không?**
2. **Chỉ số nào đáng chú ý nhất lúc này?**
3. **Thiết bị có đang cập nhật không?**
4. **Đêm qua ngủ thế nào / AI đánh giá ra sao?**
5. **Nếu cần khẩn cấp, SOS ở đâu?**

---

## 9. Widget Tree chi tiết đề xuất

### 9.1 App shell

- `MainScaffoldShell`
  - quản lý safe area, background, sticky CTA, bottom nav

### 9.2 Dashboard body

- `DashboardGreetingHeader`
  - avatar
  - lời chào
  - ngày / thời gian cập nhật gần nhất
  - notification shortcut

- `HealthStatusHeroCard`
  - tiêu đề: "Hôm nay bạn đang ổn"
  - overall state chip: `Ổn định` / `Cần theo dõi` / `Nguy cơ cao`
  - summary sentence ngắn
  - optional secondary CTA: `Xem lịch sử`

- `ConnectionStatusStrip`
  - trạng thái đồng hồ
  - pin
  - online / offline / chưa kết nối

- `LiveVitalsSection`
  - section header
  - responsive grid/list container
  - 4 `VitalMetricCard`

- `SleepInsightCard`
  - duration
  - quality
  - 1 dòng insight
  - CTA `Xem chi tiết`

- `RiskInsightCard`
  - score
  - level chip
  - summary
  - CTA `Xem báo cáo AI`

- `DashboardQuickActionsRow` hoặc `DashboardSecondaryLinks`
  - `Lịch sử chỉ số`
  - `Thiết bị`
  - `Thông báo` nếu cần

- `EmergencyStickyBar`
  - full-width button hoặc pill button
  - không dùng FAB nhỏ nổi một góc

---

## 10. Refactor chi tiết từng khu vực

### 10.1 Header

#### Hiện trạng

- Greeting + ngày tháng + notification

#### Refactor

- Giữ greeting nhưng tăng giá trị thông tin:
  - Dòng 1: `Chào Minh Thiện`
  - Dòng 2: `Cập nhật sức khoẻ mới nhất lúc 08:42`
- Nếu `Device_Offline`, dòng 2 đổi thành trạng thái offline thay vì chỉ hiện ngày.
- Notification icon có badge nhỏ nếu có cảnh báo chưa đọc.

#### Lý do

- Header không còn chỉ mang tính trang trí.
- Người dùng hiểu ngay dữ liệu có mới hay không.

### 10.2 Hero card

#### Mục tiêu

Tạo một nơi duy nhất trả lời câu hỏi "Hôm nay tình trạng tổng quát ra sao?".

#### Nội dung

- Health label: `Ổn định`, `Cần chú ý`, `Cần xử lý sớm`
- Summary sentence:
  - Normal: `Các chỉ số hiện trong ngưỡng an toàn`
  - Warning: `Một vài chỉ số cần theo dõi thêm hôm nay`
  - Critical: `Có chỉ số bất thường, nên kiểm tra ngay`

#### Visual

- Nền xanh nhạt / vàng nhạt / đỏ nhạt tùy level
- Không dùng đỏ đậm trừ critical

### 10.3 Live vitals

#### Refactor layout

- Mặc định: grid 2 cột
- Khi text scale lớn hoặc chiều ngang hẹp: tự chuyển thành list dọc
- Mỗi card gồm:
  - icon
  - nhãn chỉ số
  - giá trị lớn
  - trạng thái phụ
  - timestamp mini nếu stale

#### State styling

- Normal: viền xám-xanh, accent success
- Warning: viền vàng + badge nhỏ
- Critical: nền critical nhẹ + CTA phụ `Xem ngay`

#### Quy tắc

- Chỉ dùng màu ở viền, chip, icon accent
- Không tô full-color 4 card cùng lúc nếu không critical

### 10.4 Sleep insight card

- Không chỉ là banner 2 dòng.
- Nâng lên thành card insight:
  - `7h20 ngủ`
  - `Chất lượng: Tốt`
  - `Nhịp tim khi ngủ: 58 BPM`
  - insight text ngắn: `Giấc ngủ ổn định hơn 2 đêm trước`

### 10.5 Risk insight card

- Tách score và message rõ ràng hơn:
  - score pill lớn
  - level label
  - summary 1-2 dòng tối đa
- Nếu score thấp: dùng màu trung tính + brand
- Nếu score cao: warning/critical accent nhưng không đỏ chói cả card

### 10.6 SOS action

#### Quyết định

Refactor từ `FAB đỏ` sang **sticky bottom emergency bar**:

- full-width hoặc near-full-width
- cố định phía trên bottom nav
- icon + text rõ
- chiều cao `56-60dp`

#### Lý do

- Dễ chạm hơn FAB.
- Rõ ràng hơn với người lớn tuổi.
- Ít che nội dung hơn.
- Có thể dùng chung cho các self-critical screens sau này.

---

## 11. Bottom Navigation Refactor Plan

### 11.1 Nguyên tắc

- Không tăng số lượng tab.
- Không dùng shifting navigation.
- Luôn hiển thị icon + label.
- Active tab phải rõ bằng **indicator + màu + weight**, không chỉ đổi màu icon.
- Height đủ lớn cho người lớn tuổi và thiết bị có safe area.

### 11.2 Spec đề xuất

| Thuộc tính | Giá trị đề xuất |
| --- | --- |
| Tab count | 4 |
| Height base | `72dp` + safe area |
| Top border | Có, rất nhẹ |
| Background | `bg.surface` |
| Active indicator | pill mềm hoặc rounded capsule |
| Icon size | `22-24dp` |
| Label size | `12-13sp` |
| Touch target | tối thiểu `64dp x 48dp` |

### 11.3 Visual behavior

- Active tab:
  - nền indicator xanh nhạt
  - icon `brand.primary`
  - label semi-bold
- Inactive tab:
  - icon xám xanh
  - label muted
- Không animate kiểu nhảy mạnh; chỉ fade/scale rất nhẹ 120-160ms

### 11.4 Thứ tự tab

Giữ nguyên:

1. `Tôi`
2. `Gia đình`
3. `Thiết bị`
4. `Hồ sơ`

#### Lý do

- Phù hợp mental model hiện tại
- Tab đầu tiên là home self view
- Không phá hybrid architecture

### 11.5 Badge rules

- `Gia đình`: badge đỏ nhỏ khi có SOS active hoặc unread critical family event
- `Thiết bị`: badge chấm nhỏ khi device disconnected hoặc cần attention
- `Hồ sơ`: không badge mặc định, trừ notification/settings bắt buộc
- `Tôi`: không gắn badge để tránh tự cạnh tranh với nội dung hero

### 11.6 Accessibility rules cho nav

- label không được ẩn ở inactive state
- mỗi tab có semantic label đầy đủ:
  - `Tab Sức khoẻ của tôi`
  - `Tab Gia đình`
  - `Tab Thiết bị`
  - `Tab Hồ sơ`
- badge phải được đọc là `có cảnh báo`

---

## 12. Responsive & Accessibility Plan

### Text scaling

- `100-130%`: grid 2 cột giữ nguyên
- `150-200%`: vitals chuyển list dọc
- bottom nav vẫn giữ label, nhưng có thể wrap mềm hoặc giảm khoảng cách ngang

### One-hand usage

- CTA quan trọng nằm nửa dưới màn
- sticky SOS nằm trong thumb zone
- notification không phải điểm chạm chính

### Contrast & target size

- body text >= `16sp`
- caption >= `14sp`
- touch targets >= `48dp`
- contrast >= `4.5:1`

### Cognitive accessibility

- dùng từ ngữ đời thường hơn thay vì quá y khoa
- luôn có summary sentence ngắn ở hero và risk card
- error copy cần nêu rõ phải làm gì tiếp theo

---

## 13. UI States Mapping sau refactor

| State | Hiển thị sau refactor |
| --- | --- |
| `Loading` | Skeleton cho hero, vitals, 2 insight card, nav shell ổn định |
| `Success_Normal` | Hero xanh nhạt, vitals trung tính, no banner |
| `Success_Warning` | Hero vàng nhạt + 1 inline alert strip, chỉ card bất thường đổi accent |
| `Success_Critical` | Hero đỏ nhạt + CTA `Gọi trợ giúp ngay`, sticky SOS chuyển emphasis cao |
| `No_Device` | Hero thông tin + card onboarding thiết bị + ẩn vitals grid thật |
| `Device_Offline` | Status strip màu info/warning, dùng cached vitals + timestamp |
| `Offline` | Banner vàng trên content, shell giữ nguyên |
| `Error` | Inline error card + retry, tránh chỉ dùng snackbar |

### Quyết định quan trọng

State lỗi không nên chỉ là `Snackbar`, vì người lớn tuổi dễ bỏ lỡ.  
Đề xuất dùng **inline error block** trong content và chỉ dùng snackbar như tín hiệu phụ.

---

## 14. Shared Component Plan

### Component cần tạo hoặc chuẩn hoá

- `AppShellBottomNav`
- `DashboardGreetingHeader`
- `HealthStatusHeroCard`
- `ConnectionStatusStrip`
- `VitalMetricCard`
- `InsightCardBase`
- `SleepInsightCard`
- `RiskInsightCard`
- `EmergencyStickyBar`
- `InlineStatusBanner`
- `SemanticBadge`

### Token groups cần tạo

- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppRadii`
- `AppShadows`
- `AppStateColors`
- `AppBottomNavTokens`

### Tái sử dụng cho màn khác

- `InsightCardBase` dùng lại cho `FamilyDashboard`, `RiskReport`, `SleepReport`
- `ConnectionStatusStrip` dùng lại cho `DEVICE_List`, `DEVICE_StatusDetail`
- `AppShellBottomNav` dùng cho toàn bộ tab shell

---

## 15. Decision Log

| Decision | Alternatives | Why chosen |
| --- | --- | --- |
| Dùng `Calm Clinical Dashboard` | data-dense, hero-first | Cân bằng readability và safety |
| Giữ 4 tab hiện tại | thêm tab SOS, đổi thứ tự | Tránh phá IA và mental model |
| SOS chuyển sang sticky bar | FAB tròn, center docked button | Dễ chạm hơn, hợp người lớn tuổi |
| Màu trạng thái dùng accent thay vì full fill | tô full card | Giảm stress, giữ màn bình tĩnh |
| Có badge ở tab `Gia đình` | badge global, không badge | Family là nơi hợp logic nhất cho linked alerts |
| Error dùng inline block + snackbar phụ | snackbar-only | Dễ thấy, ít bị bỏ lỡ |

---

## 16. Kế hoạch implementation theo pha

### Phase A — Information Architecture & Theme

1. Chốt token hệ thống cho màu, type, spacing, radii.
2. Chốt spec `Bottom Navigation` dùng chung.
3. Chốt cấu trúc section mới của `HOME_Dashboard`.

### Phase B — Shell Components

1. Build `AppShellBottomNav`
2. Build `EmergencyStickyBar`
3. Build `InlineStatusBanner`

### Phase C — Dashboard Surface

1. Build `DashboardGreetingHeader`
2. Build `HealthStatusHeroCard`
3. Build `ConnectionStatusStrip`

### Phase D — Content Components

1. Build `VitalMetricCard`
2. Build `SleepInsightCard`
3. Build `RiskInsightCard`

### Phase E — State Completion

1. Wire `Loading`
2. Wire `No_Device`
3. Wire `Device_Offline`
4. Wire `Offline`
5. Wire `Error`
6. Verify `Success_Normal / Warning / Critical`

### Phase F — Polish & Reuse

1. Tune spacing, contrast, typography
2. Add semantic labels
3. Propagate tokens/components sang `HOME_FamilyDashboard`

---

## 17. Verification Checklist

### UX

- [ ] Màn hình có thể hiểu trong 5 giây đầu
- [ ] Chỉ có 1 vùng nhấn mạnh chính ở top
- [ ] SOS luôn thấy nhưng không áp đảo màn khi trạng thái bình thường

### Accessibility

- [ ] Font/body >= 16sp
- [ ] Touch target >= 48dp
- [ ] Text scaling 200% không vỡ layout
- [ ] Screen reader đọc đúng nav labels và badge

### Safety

- [ ] `Critical` state nổi bật rõ hơn `Warning`
- [ ] `No_Device`, `Offline`, `Error` có hướng xử lý tiếp theo
- [ ] Không có chỗ nào màu sắc là tín hiệu duy nhất

### Reusability

- [ ] `Bottom Navigation` tách thành shared shell component
- [ ] Theme tokens không gắn cứng riêng cho dashboard
- [ ] `InsightCardBase` dùng lại được ở màn khác

---

## 18. Kết quả mong đợi sau refactor

- `HOME_Dashboard` nhìn giống một **trung tâm sức khoẻ cá nhân đáng tin cậy**, không còn là danh sách block chức năng rời rạc.
- `Bottom Navigation` trở thành một shell nhất quán, trưởng thành, đủ chuẩn để nhân rộng.
- Theme mới tạo ra ngôn ngữ thị giác chung cho app: nhẹ, sáng, an toàn, có phân tầng cảnh báo rõ.
- Các màn sau như `HOME_FamilyDashboard`, `DEVICE_List`, `PROFILE_Overview` có thể refactor nhanh hơn nhờ tái dùng cùng token và component set.

---

## 19. Khuyến nghị chốt trước khi BUILD

### Nên chốt với stakeholder 3 điểm này trước

1. Có đồng ý đổi SOS từ `FAB` sang `sticky emergency bar` không?
2. Có đồng ý dùng `badge` trên tab `Gia đình` cho linked emergency không?
3. Có đồng ý dùng theme `calm clinical` thay cho tông màu cảnh báo mạnh hiện tại không?

### Confidence

**Plan Confidence: 91%**

Lý do:

- Context màn và kiến trúc tổng thể khá rõ.
- Mục tiêu người dùng lớn tuổi và self-dashboard đã được xác định tốt.
- Điểm chưa chắc chủ yếu nằm ở mức độ “đậm” của theme mới và cách hiển thị badge trên bottom nav.
