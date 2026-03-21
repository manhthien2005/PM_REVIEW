# 📐 UI Plan: Risk History

> **Mode**: TASK-guided PLAN (`mobile-agent`)
> **Build Priority**: `03 - Build third`
> **Screen Spec**: [ANALYSIS_RiskHistory.md](../ANALYSIS_RiskHistory.md)
> **Related UC**: `UC016`
> **Related source**:
> - `ANALYSIS_RiskReport.md`
> - `health_system/lib/features/health_monitoring/screens/health_report_screen.dart`

---

## 1. Description

- **SRS Ref**: UC016
- **User Role**: User (self) / User xem linked profile da duoc cap quyen
- **Purpose**: Hien thi lich su danh gia diem suc khoe/risk score theo thoi gian, giup user thay xu huong tot len hay xau di, va mo lai tung ban ghi de xem chi tiet.

### Position in flow

Day la man thu 3 trong luong banner:

1. `Risk Report`
2. `Risk Report Detail`
3. `Risk History`

No duoc build sau cung vi:
- phu thuoc data contract cua 2 man truoc
- co the reuse nhieu widget/semantic colors

---

## 2. User Flow

1. User bam `Xem lich su` tu `Risk Report`.
2. Route nhan `profileId?`.
3. Screen load:
   - summary trend chart
   - batch list dau tien
4. User chon range:
   - `7 ngay`
   - `30 ngay`
   - `90 ngay`
5. User scroll list:
   - lazy load them neu can
6. User cham vao 1 item -> mo `RiskReportDetail(reportId)`.
7. Pull-to-refresh -> reset ve batch dau.

---

## 3. UI States

| State | Description | Display |
|---|---|---|
| Loading | Dang fetch batch dau | Skeleton chart + skeleton history items |
| Success | Co data | Trend summary + grouped list |
| Loading_More | Dang fetch them | Footer loader |
| Empty | Chua co lich su | Empty illustration + CTA quay lai banner tong quan |
| Permission_Denied | Linked profile khong duoc xem | Error block + back |
| Error | Loi API | Retry block |
| End_Of_List | Da load het | Footer end message nhe / no loader |

---

## 4. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  ├─ Title: "Lich su diem suc khoe"
│  └─ Subtitle (linked only)
├─ Body
│  └─ RefreshIndicator
│     └─ CustomScrollView
│        ├─ RangeFilterChips
│        ├─ RiskTrendSummaryCard
│        ├─ CompareInsightCard
│        ├─ HistorySectionHeader
│        ├─ GroupedRiskHistoryList
│        │  ├─ DateHeader
│        │  └─ RiskHistoryItemCard x N
│        └─ PaginationFooter
```

### Section detail

#### `RangeFilterChips`
- 7 ngay
- 30 ngay
- 90 ngay
- neu can, button `Tuy chinh` o phase sau

#### `RiskTrendSummaryCard`
- chart line/area
- gia tri trung binh
- gia tri cao nhat / thap nhat
- huong chung: `Dang giam dan`

#### `CompareInsightCard`
- 1 cau ngan:
  - `7 ngay qua, diem rui ro giam 12 diem so voi tuan truoc.`

#### `RiskHistoryItemCard`
- score
- level
- analyzed_at
- top reason preview 1 dong
- chevron

---

## 4.5. Visual Design Spec

### Design direction

`History that feels light, not bureaucratic.`

- Lich su thuong de bi kho, nhieu list, nhieu filter
- Man nay phai giong mot timeline suc khoe nhe nhang
- Khong lam nặng nhu table report

### Colors

| Role | Token / Value | Usage |
|---|---|---|
| Screen BG | `AppColors.bgPrimary` | Nen |
| Card BG | `AppColors.bgSurface` | Chart + history cards |
| Selected filter | `AppColors.brandPrimary` | Filter active |
| Low level | `AppColors.success` | Badge/item score |
| Medium level | `AppColors.warning` | Badge/item score |
| High level | `AppColors.critical` | Badge/item score |
| Secondary text | `AppColors.textSecondary` | Date, meta |

### Typography

| Element | Size | Weight | Color |
|---|---|---|---|
| Page title | 20sp | SemiBold | textPrimary |
| Range chip | 14sp | SemiBold | brand/text |
| Summary score | 24sp | Bold | textPrimary |
| Item score | 20sp | Bold | semantic |
| Item reason | 14-16sp | Medium | textPrimary |
| Item timestamp | 14sp | Medium | textSecondary |

### Spacing

- Horizontal padding: `20dp`
- Top filter gap: `12dp`
- Section gap: `16dp`
- History item padding: `16dp`
- List item gap: `10-12dp`

---

## 4.6. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
|---|---|---|
| Range switch | Chart/list crossfade + refetch | 180ms |
| Pull refresh | RefreshIndicator | system |
| Scroll to end | Footer spinner append | system |
| Tap item | Ripple + navigate detail | 120ms |

---

## 4.7. Accessibility Checklist

- [x] Filter chips >= 48dp height
- [x] Item cards >= 48dp touch target
- [x] Score + level + date deu co text ro
- [x] Trend chart co text summary de khong phu thuoc bieu do
- [x] Infinite scroll khong phai cach duy nhat de biet het du lieu; co end label nhe

---

## 4.8. Design Rationale

| Decision | Reason |
|---|---|
| Hien chart summary tren cung | User thay duoc trend tong quan truoc khi doc list |
| Group item theo ngay/thang | De quet nhanh, it "ke toan" hon |
| Moi item co 1 line reason preview | Giup list co gia tri, khong chi la so diem |
| Build sau cung | Giam risk vi list/history phu thuoc contract cua report detail |

---

## 5. Edge Cases Handled

- [x] Khong co data trong range -> Empty state
- [x] Chuyen range khi dang scroll cuoi -> reset pagination
- [x] Item khong co reason preview -> fallback `Khong co tom tat`
- [x] API tra duplicate records -> merge by `report_id`
- [x] Linked profile flow -> subtitle context ro rang
- [x] Very long list -> lazy load, khong fetch het 1 lan

---

## 6. Dependencies

### Shared widgets needed

- `RangeFilterChips` - NEW/shared
- `RiskTrendSummaryCard` - NEW
- `CompareInsightCard` - NEW
- `RiskHistoryItemCard` - NEW
- `PaginationFooter` - NEW/simple

### Reuse

- `RiskLevelPill` / semantic colors tu plan 01
- list/timeline spacing logic tu `HealthReportScreen`
- `AppColors`, `AppTextStyles`, `AppSpacing`

### API endpoints

- `GET /api/mobile/risk-report/history?profile_id={profileId}&range=7d|30d|90d&page=1&limit=20`

### Recommended response shape

```json
{
  "range": "30d",
  "summary": {
    "average_score": 41,
    "highest_score": 66,
    "lowest_score": 28,
    "delta_vs_previous_period": -9,
    "trend_points": [62, 58, 54, 49, 45, 43, 41]
  },
  "items": [
    {
      "report_id": "risk_20260320_0842",
      "score": 32,
      "level": "LOW",
      "analyzed_at": "2026-03-20T08:42:00Z",
      "reason_preview": "Nhip tim va SpO2 da on dinh hon hom qua."
    }
  ],
  "page": 1,
  "limit": 20,
  "has_more": true
}
```

---

## 7. Confidence Score

- **Plan Confidence: 89%**
- **Reasoning**: Flow history ro, nhung chat luong UX phu thuoc kha nhieu vao API summary va pagination contract.
- **Uncertainties**:
  - Co can date filter tuy chinh ngay tu v1 khong
  - Team muon infinite scroll hay chi pagination im lang

---

## 8. Build Order Justification

### Why build third?

1. Day la man phu trong luong.
2. Co the reuse level color language, item summary, route logic tu 2 man truoc.
3. Build sau cung se de khoa API shape va avoid rework.

