# 📐 UI Plan: Risk Report Detail (XAI)

> **Mode**: TASK-guided PLAN (`mobile-agent`)
> **Build Priority**: `02 - Build second`
> **Screen Spec**: [ANALYSIS_RiskReportDetail.md](../ANALYSIS_RiskReportDetail.md)
> **Related UC**: `UC016`, `UC017`
> **Related source**:
> - `healthguard-ai/models/healthguard/README.md`
> - existing `VitalDetailScreen`
> - existing `SleepReportScreen`

---

## 1. Description

- **SRS Ref**: UC016, UC017
- **User Role**: User (self) / User xem linked profile da duoc cap quyen
- **Purpose**: Giai thich chi tiet tai sao he thong cham diem nhu vay, su dung XAI o muc do de hieu voi nguoi dung pho thong nhung van du chinh xac cho san pham y te.

### Core principle

Day **khong** phai man "du lieu ky thuat".  
No phai la man:
- de hieu voi nguoi gia
- co logic cho nguoi tre
- co do tin cay cho app health

Nghia la:
- dung nguyen nhan bang ngon ngu doi thuong
- co factor bars / contribution list
- co recommendation ro rang
- co link sang `Vital Detail` / `Sleep Report`

---

## 2. User Flow

1. User o `Risk Report` bam `Xem giai thich`.
2. Route nhan:
   - `reportId`
   - `profileId?`
3. Screen goi `GET /api/mobile/risk-report/:reportId`
4. API tra ve snapshot chi tiet:
   - score
   - level
   - xai_explanation
   - breakdown factors
   - recommendations
   - feature snapshot tai thoi diem danh gia
5. Screen hien:
   - tong quan ngan
   - top factor bars
   - giai thich bang van ban
   - recommended actions
   - quick links sang chi so / sleep
6. User bam vao tung factor:
   - `heart_rate`, `spo2`, `bp`, `temp` -> `VitalDetail`
   - `sleep` -> `SleepReport`
7. Back quay ve `Risk Report`.

---

## 3. UI States

| State | Description | Display |
|---|---|---|
| Loading | Dang fetch chi tiet XAI | Skeleton summary + skeleton factor bars |
| Success_Full | Co du breakdown + explanation + recommendations | Full detail layout |
| Success_NoXAI | Chi co score, chua co xai breakdown | Hien summary, hide factor bars, thong bao nhe |
| Success_Limited | Co breakdown mot phan | Hien factor co san + text fallback |
| Permission_Denied | 403 cho linked profile | Error block + back |
| Not_Found | reportId khong ton tai | Empty detail + CTA quay lai lich su |
| Error | Loi network/API | Retry + fallback |

---

## 4. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  ├─ Title: "Giai thich diem suc khoe"
│  └─ Subtitle (linked only): ten + quan he
├─ Body
│  └─ CustomScrollView
│     ├─ RiskDetailSummaryCard
│     ├─ RiskSnapshotMetaRow
│     ├─ XaiNarrativeCard
│     ├─ FactorContributionSection
│     │  ├─ FactorContributionCard x N
│     │  └─ factor tap target
│     ├─ SupportingMetricsSnapshotCard
│     ├─ RecommendationChecklistCard
│     ├─ RelatedDrilldownSection
│     │  ├─ Xem chi tiet nhip tim
│     │  ├─ Xem chi tiet SpO2
│     │  ├─ Xem chi tiet huyet ap
│     │  ├─ Xem chi tiet nhiet do
│     │  └─ Xem giac ngu
│     └─ MedicalDisclaimerCard
```

### Section detail

#### `RiskDetailSummaryCard`
- score + level
- 1 dong `Tai sao he thong danh gia nhu vay`
- analyzed_at

#### `XaiNarrativeCard`
- nguyen van giai thich bang nguon tu AI/service
- viet de hieu, 3-5 cau toi da

#### `FactorContributionSection`
- danh sach top factors
- moi factor co:
  - ten yeu to
  - gia tri tai thoi diem do
  - muc dong gop `+18 diem`
  - progress bar hoac horizontal bar
  - semantic label `Anh huong cao / vua / thap`

#### `SupportingMetricsSnapshotCard`
- hien snapshot metrics tai luc tinh score:
  - HR
  - SpO2
  - BP
  - Temp
  - HRV
  - MAP
  - Sleep flag neu co

#### `RecommendationChecklistCard`
- toi da 5 dong
- icon check / warning
- chia theo muc:
  - theo doi
  - nen lien he
  - khan cap

---

## 4.5. Visual Design Spec

### Design direction

`Readable explainability.`

- Man nay can giong mot ban giai thich thong minh, khong giong dashboard tong hop
- Uu tien card sang, typography ro, bar chart ngang de doc tren mobile
- Giu mau semantic theo he thong, nhung khong lam thanh "bao dong do" lien tuc

### Colors

| Role | Token / Value | Usage |
|---|---|---|
| Screen BG | `AppColors.bgPrimary` | Nen |
| Card BG | `AppColors.bgSurface` | Card detail |
| Low contribution | `AppColors.success` | Factor tot / lam giam rui ro |
| Medium contribution | `AppColors.warning` | Factor can chu y |
| High contribution | `AppColors.critical` | Factor chinh keo score xau |
| Link / Drilldown | `AppColors.brandPrimary` | CTA phu |
| Secondary BG | `AppColors.bgElevated` | Snapshot / info card |

### Typography

| Element | Size | Weight | Color |
|---|---|---|---|
| Summary score | 36sp | Bold | semantic |
| Section title | 18sp | SemiBold | textPrimary |
| Narrative text | 16sp | Regular | textPrimary |
| Factor title | 16sp | SemiBold | textPrimary |
| Factor meta | 14sp | Medium | textSecondary |
| Recommendation item | 16sp | Medium | textPrimary |

### Spacing

- Screen padding: `20dp`
- Section gap: `16dp`
- Inside card: `16dp`
- Factor row vertical gap: `12dp`
- Recommendation item min height: `52dp`

---

## 4.6. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
|---|---|---|
| Screen enter | Fade + slight upward motion | 220ms |
| Factor card reveal | Staggered fade | 60ms/item |
| Tap factor | Ripple + navigate | 120ms |
| Expand long narrative | Smooth size transition | 180ms |

---

## 4.7. Accessibility Checklist

- [x] Narrative text >= 16sp
- [x] Factor rows >= 48dp touch target
- [x] Bars co label va so diem, khong dung mau don le
- [x] Recommendation item doc duoc voi TalkBack
- [x] Linked profile title ro rang de tranh nham ngu canh
- [x] Co disclaimer y khoa ro rang

---

## 4.8. Design Rationale

| Decision | Reason |
|---|---|
| Dung `factor cards` thay vi 1 pie chart lon | Pie chart dep nhung kho doc chinh xac tren mobile |
| Tach `narrative` va `breakdown` | Nguoi gia co the doc text tong quan truoc, nguoi tre co the scan bar breakdown |
| Hien `snapshot metric values` tai thoi diem danh gia | Dung voi UC017: khong duoc tinh lai bang du lieu hien tai |
| Drill-down sang `VitalDetail` va `SleepReport` | Tan dung man da co, tranh tao man trung lap |

---

## 5. Edge Cases Handled

- [x] Co score nhung khong co XAI record -> `Success_NoXAI`
- [x] Khong phai factor nao cung co man detail -> factor khong drill duoc se disable arrow
- [x] Explanation text qua dai -> collapse/expand
- [x] Recommendation rong -> show fallback `Tiep tuc theo doi va cap nhat du lieu`
- [x] Linked profile khong duoc xem sleep -> an CTA sleep, show privacy note
- [x] Chi so snapshot co gia tri invalid -> show `Khong xac dinh`

---

## 6. Dependencies

### Shared widgets needed

- `RiskDetailSummaryCard` - NEW
- `XaiNarrativeCard` - NEW
- `FactorContributionCard` - NEW
- `SupportingMetricsSnapshotCard` - NEW
- `RecommendationChecklistCard` - NEW
- `RelatedDrilldownSection` - NEW
- `MedicalDisclaimerCard` - reuse/create shared

### Reuse

- `RiskLevelPill` tu Plan 01
- `AppColors`, `AppTextStyles`, `AppSpacing`
- `VitalDetail` routes
- `SleepReport` routes

### API endpoints

- `GET /api/mobile/risk-report/:reportId`

### Recommended response shape

```json
{
  "report_id": "risk_20260320_0842",
  "profile_id": "u_123",
  "score": 32,
  "level": "LOW",
  "summary": "Suc khoe hom nay dang o muc on dinh.",
  "analyzed_at": "2026-03-20T08:42:00Z",
  "breakdown": [
    {
      "key": "heart_rate",
      "label": "Nhip tim luc nghi cao",
      "contribution_score": 18,
      "impact_level": "high",
      "value": "108",
      "unit": "bpm",
      "route_target": "vital_hr"
    },
    {
      "key": "spo2",
      "label": "SpO2 giam nhe",
      "contribution_score": 12,
      "impact_level": "medium",
      "value": "93",
      "unit": "%",
      "route_target": "vital_spo2"
    }
  ],
  "xai_explanation": "Diem tang chu yeu do nhip tim luc nghi cao va SpO2 giam nhe trong buoi sang.",
  "recommendations": [
    "Nghi ngoi 15 phut roi do lai nhip tim.",
    "Theo doi SpO2 trong ngay hom nay."
  ],
  "snapshot": {
    "heart_rate": 108,
    "spo2": 93,
    "sys_bp": 138,
    "dia_bp": 86,
    "body_temp": 36.9,
    "hrv": 28,
    "map_val": 103
  }
}
```

---

## 7. Confidence Score

- **Plan Confidence: 91%**
- **Reasoning**: UC017 mo ta kha ro output mong muon. Data model AI cung da cho biet nhung feature nao quan trong cho UI.
- **Uncertainties**:
  - Co show `confidence` prediction cho end-user hay khong
  - Mapping chinh xac factor nao route sang `SleepReport` neu sleep score khong ton tai doc lap

---

## 8. Build Order Justification

### Why build second?

1. Phu thuoc visual language cua `Risk Report`.
2. Can reuse score hero/pill tu plan 01.
3. Sau khi co man nay, user moi thuc su thay duoc gia tri cua banner AI.

