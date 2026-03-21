# 📐 UI Plan: Risk Report Overview

> **Mode**: TASK-guided PLAN (`mobile-agent`)
> **Build Priority**: `01 - Build first`
> **Screen Spec**: [ANALYSIS_RiskReport.md](../ANALYSIS_RiskReport.md)
> **Related UC**: `UC016 - Xem bao cao danh gia rui ro suc khoe`
> **Related source**:
> - `healthguard-ai/models/healthguard/README.md`
> - `health_system/lib/features/home/presentation/widgets/risk_insight_card.dart`
> - `health_system/lib/shared/presentation/theme/app_colors.dart`

---

## 1. Description

- **SRS Ref**: UC016
- **User Role**: User (self) / User xem linked profile da duoc cap quyen
- **Purpose**: Hien thi diem suc khoe AI / diem rui ro AI gan nhat, giai thich o muc do tong quan, va dan huong sang chi tiet XAI va lich su.

### Position in flow

Day la man hinh dau tien sau khi user bam vao `banner diem suc khoe` tu:
- `HOME_Dashboard` (self flow)
- `PersonDetail` / future linked-profile health banner (linked flow)

### Product decision lock

Man nay can chot ro 1 quy uoc ten goi:

1. **Neu dung "Diem rui ro AI"**
   - diem cao = nguy hiem hon
   - mau xanh -> vang -> cam -> do

2. **Neu dung "Diem suc khoe AI"**
   - diem cao = tot hon
   - phai tinh toan tu risk score hoac co mapping ro rang

> **Khuyen nghi cho build v1**: dung `Diem rui ro AI` trong data layer, con UI copy co the hien "Danh gia suc khoe hom nay" de tranh user bi soc vi tu "rui ro".

---

## 2. User Flow

1. User bam vao `banner diem suc khoe`.
2. Route nhan `profileId?`:
   - `null` = self
   - co gia tri = linked profile
3. Screen goi `GET /api/mobile/risk-report/latest?profile_id={profileId}`.
4. He thong tra ve:
   - score
   - level
   - analyzed_at
   - summary
   - short factors
   - trend 7 ngay
   - recommendation preview
5. Screen hien thi hero score + summary.
6. User co 3 huong chinh:
   - `Xem giai thich` -> `RiskReportDetail`
   - `Xem lich su` -> `RiskHistory`
   - `Xem chi so lien quan` -> existing `VitalDetail` / `SleepReport`

### Self flow

- Header copy: `Danh gia suc khoe cua ban`
- Co the hien CTA `Theo doi lai sau 1 gio` neu risk duoc tinh theo chu ky

### Linked profile flow

- Header copy: `Danh gia suc khoe cua Bo/Ma/...`
- Hien ten va quan he o top context header
- Khong hien CTA gay SOS thay nguoi khac

---

## 3. UI States

| State | Description | Display |
|---|---|---|
| Loading | Dang fetch risk report moi nhat | Skeleton hero + skeleton factor chips + skeleton trend |
| Success_Low | Score muc thap | Hero xanh, summary tran an, trend 7 ngay |
| Success_Medium | Score can theo doi | Hero vang/cam nhe, summary goi y theo doi |
| Success_High | Score cao | Hero cam, recommendation preview noi bat |
| Success_Critical | Score rat cao | Hero do nhe, warning strip noi bat, CTA vao chi tiet |
| Analyzing | Model chua co output moi | Progress card "Dang phan tich..." + thoi diem cap nhat cu |
| Insufficient_Data | Chua du 24h data / medical profile chua du | Empty illustration + progress "Da co 12/24 gio" + CTA cap nhat thong tin |
| Permission_Denied | Linked profile khong co quyen xem | InlineErrorBlock + nut quay lai |
| Error | Loi API / network | InlineErrorBlock + Retry + fallback cache neu co |

---

## 4. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  ├─ Title: "Danh gia suc khoe"
│  └─ Subtitle (linked profile only): ten + quan he
├─ Body
│  └─ RefreshIndicator
│     └─ CustomScrollView
│        ├─ RiskContextHeader (linked only / optional)
│        ├─ RiskScoreHeroCard
│        ├─ InlineStatusBanner (critical / analyzing / stale data)
│        ├─ RiskQuickExplanationCard
│        ├─ TopFactorChipsSection
│        ├─ RiskTrendPreviewCard (7 ngay)
│        ├─ RecommendationPreviewCard
│        ├─ RiskActionPanel
│        │  ├─ Button "Xem giai thich"
│        │  ├─ Button "Xem lich su"
│        │  └─ Optional link "Xem chi tiet chi so"
│        └─ MedicalDisclaimerCard
```

### Section detail

#### `RiskScoreHeroCard`
- score lon
- level pill
- timestamp
- 1 cau tong ket
- delta so voi lan truoc: `+6 so voi hom qua`

#### `RiskQuickExplanationCard`
- 1 doan text rat ngan:
  - `Diem hom nay tang chu yeu do nhip tim luc nghi cao va SpO2 giam nhe.`

#### `TopFactorChipsSection`
- toi da 3 factor preview
- vd:
  - `Nhip tim cao`
  - `SpO2 giam`
  - `Ngu kem`

#### `RiskTrendPreviewCard`
- mini line chart 7 ngay
- co legend `On dinh / Tang / Giam`

#### `RecommendationPreviewCard`
- toi da 2 recommendation preview
- co link `Xem day du`

---

## 4.5. Visual Design Spec

### Design direction

`Modern clinical, not cold.`

- Co cam giac hien dai nho hero score ro rang, chart gon, spacing thoang
- Than thien voi nguoi gia nho font lon, text de hieu, CTA it
- Khong "teen qua", khong gradient qua loe loet, khong glassmorphism phuc tap

### Colors

| Role | Token / Value | Usage in this screen |
|---|---|---|
| Screen BG | `AppColors.bgPrimary` | Nen man |
| Card BG | `AppColors.bgSurface` | Card thong thuong |
| Elevated BG | `AppColors.bgElevated` | Hero phan context linked profile |
| Low state | `AppColors.success` + `AppStateColors.successBg` | Risk thap |
| Medium state | `AppColors.warning` + `AppStateColors.warningBg` | Risk trung binh |
| High/Critical state | `AppColors.critical` + `AppStateColors.criticalBg` | Risk cao |
| Brand CTA | `AppColors.brandPrimary` | CTA chinh, tab/action |
| Text primary | `AppColors.textPrimary` | Tieu de/noi dung |
| Text secondary | `AppColors.textSecondary` | Metadata/timestamp |

### Hero styling

- Khong dung card gradient dam nhu `risk_insight_card.dart` hien tai.
- Dung nen sang, co 1 score capsule / radial score ring o ben trai hoac o top center.
- Neu muon giu "DNA" hien tai:
  - chi giu accent xanh navy o header strip nho
  - khong toan bo card mau dam

### Typography

| Element | Size | Weight | Color |
|---|---|---|---|
| Page title | 20sp | SemiBold | textPrimary |
| Hero score | 44-52sp | Bold | semantic color |
| Hero level pill | 14sp | Bold | semantic color |
| Summary | 16sp | Medium | textPrimary |
| Factor chip | 14sp | SemiBold | textPrimary |
| Timestamp | 14sp | Medium | textSecondary |
| CTA button | 16sp | SemiBold | brandPrimary / white |

### Spacing

- Horizontal padding: `20dp`
- Section gap: `16dp`
- Card padding: `16dp`
- Hero internal gap: `12dp`
- CTA button min height: `52dp`

---

## 4.6. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
|---|---|---|
| Screen enter | Subtle fade + upward reveal | 220ms |
| Pull to refresh | RefreshIndicator | system |
| Hero score change | Number tween | 400ms |
| Trend chart render | Stroke draw reveal | 300ms |
| Tap CTA | Scale 0.98 + ripple | 120ms |
| Low -> High state change | Smooth semantic color transition | 250ms |

---

## 4.7. Accessibility Checklist

- [x] Body text >= 16sp
- [x] Caption >= 14sp
- [x] CTA >= 48dp, recommended 52dp
- [x] Score va level co text, khong chi doi mau
- [x] Top factors hien bang chip text ro rang, khong chi icon
- [x] TalkBack/VoiceOver: doc duoc score, level, timestamp
- [x] Linked profile flow co subtitle ten nguoi de tranh nham profile
- [x] Critical state co banner text, khong chi red color

---

## 4.8. Design Rationale

| Decision | Reason |
|---|---|
| Tach `hero trang thai` va `xAI preview` thanh 2 block | Giam cognitive load, de doc trong 3-5 giay |
| Khong dung card risk gradient dam full-screen | Dep mau, hien dai hon, de doc hon cho nguoi gia |
| Dung `top 3 factors` thay vi doan text dai | User de hieu nhanh va de cham vao de drill-down |
| Show `delta so voi lan truoc` | Tao gia tri thuc te, giup user thay xu huong |
| CTA ro rang `Xem giai thich` / `Xem lich su` | Dinh huong luong rat ro, tranh tap mo ho |

---

## 5. Edge Cases Handled

- [x] API tra score nhung khong co trend -> an chart, hien `Chua du lich su`
- [x] API tra trend nhung chua co XAI factor -> van hien overview, factor section fallback
- [x] `profileId` khong co quyen -> 403 + inline denial
- [x] Score moi nhat da qua cu (VD > 6 gio) -> stale banner `Du lieu chua cap nhat moi`
- [x] Insufficient data do chua du 24h -> progress card
- [x] User tu home self va family vao cung mot screen -> dung chung component, doi copy theo context

---

## 6. Dependencies

### Shared widgets needed

- `RiskScoreHeroCard` - NEW
- `RiskLevelPill` - NEW
- `RiskQuickExplanationCard` - NEW
- `TopFactorChipsSection` - NEW
- `RiskTrendPreviewCard` - NEW
- `RecommendationPreviewCard` - NEW
- `MedicalDisclaimerCard` - reuse/create shared
- `RiskContextHeader` - NEW (linked flow)

### Reuse from current app

- `AppColors`, `AppTextStyles`, `AppSpacing`
- `InlineErrorBlock`, `InlineStatusBanner`
- navigation conventions in `AppRouter`
- visual spacing language from `HOME_Dashboard`, `SleepReport`, `VitalDetail`

### API endpoints

- `GET /api/mobile/risk-report/latest?profile_id={profileId}`

### Recommended response shape

```json
{
  "report_id": "risk_20260320_0842",
  "profile_id": "u_123",
  "score": 32,
  "level": "LOW",
  "display_status": "On dinh",
  "summary": "Suc khoe hom nay dang o muc on dinh.",
  "analyzed_at": "2026-03-20T08:42:00Z",
  "previous_score": 38,
  "trend_7d": [42, 39, 44, 36, 35, 38, 32],
  "top_factors": [
    {"key": "heart_rate", "label": "Nhip tim luc nghi cao"},
    {"key": "spo2", "label": "SpO2 giam nhe"}
  ],
  "recommendation_preview": [
    "Do lai sau 1 gio khi da nghi ngoi",
    "Theo doi SpO2 trong ngay hom nay"
  ],
  "confidence": 0.87,
  "is_stale": false
}
```

---

## 7. Confidence Score

- **Plan Confidence: 93%**
- **Reasoning**: UC016 + source AI model + current design system da du thong tin de define mot overview screen rat chac.
- **Uncertainties**:
  - Product team can chot term `Diem rui ro AI` hay `Diem suc khoe AI`
  - Muc do hien thi `confidence` co muon show cho end-user hay chi luu internal

---

## 8. Build Order Justification

### Why build first?

1. Day la man entry chinh tu banner.
2. No khoa structure visual cho 2 man con lai.
3. Cac widget cua no (`RiskScoreHeroCard`, `RiskLevelPill`) se duoc reuse o `RiskReportDetail` va `RiskHistory`.

