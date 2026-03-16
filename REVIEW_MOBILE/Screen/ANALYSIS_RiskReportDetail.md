# 📱 ANALYSIS — Chi tiết giải thích XAI (Risk Report Detail)

> **UC Ref**: UC016, UC017
> **Module**: ANALYSIS
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

**Breakdown từng chỉ số đóng góp** vào điểm rủi ro AI. XAI giải thích tại sao điểm cao/thấp. Các yếu tố: HR, SpO₂, BP, Temp, Sleep, Activity... — mỗi cái đóng góp bao nhiêu. Gợi ý hành động (nếu có).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) | Bấm "Xem giải thích" | → This screen |
| This screen | Bấm Back | → [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) |
| This screen | Chỉ số critical → "Xem chi tiết" | → [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) |

---

## User Flow

1. Nhận `reportId`, `profileId` (optional) từ route.
2. Hiển thị điểm tổng + **breakdown từng chỉ số**:
   - HR: +X điểm (hoặc -X nếu tốt)
   - SpO₂: +Y điểm
   - BP: +Z điểm
   - Temp: ...
   - Sleep: ...
   - Activity: ...
3. Giải thích ngôn ngữ tự nhiên (XAI).
4. Gợi ý hành động (nếu có).
5. Link "Xem chi tiết" từng chỉ số → VitalDetail.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch detail | Skeleton |
| Success | Có data | Điểm tổng + breakdown list + XAI text + gợi ý |
| Error | API fail, 404 | SnackBar, Back |
| Empty | Report không có breakdown | Chỉ điểm + "Chưa có giải thích chi tiết" |

---

## Edge Cases

- [ ] Breakdown từng chỉ số đóng góp — bắt buộc có: HR, SpO₂, BP, Temp, Sleep (tối thiểu)
- [ ] Chỉ số đóng góp cao → có thể link "Xem chi tiết" → VitalDetail
- [ ] XAI text dài → scroll, font đọc rõ
- [ ] Gợi ý hành động: "Nên đo lại sau 2 giờ", "Tham khảo bác sĩ"

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/risk-report/:reportId` hoặc `GET /api/mobile/risk-report/latest/detail`
- **Input**: Route args `reportId`, `profileId?`
- **Output**: `{ score, level, summary, breakdown: [{ metric, contribution, value, unit }], xai_explanation, suggestions }`

---

## Sync Notes

- Khi ANALYSIS_RiskReport thay đổi → link "Xem giải thích" truyền `reportId`, `profileId`
- Khi MONITORING_VitalDetail thay đổi → link "Xem chi tiết" truyền `vitalType`, `profileId`
- Shared: BreakdownBar, XAITextBlock

---

## Design Context

- **Target audience**: User hoặc người theo dõi — muốn hiểu tại sao điểm cao/thấp.
- **Usage context**: Routine — giải thích XAI.
- **Key UX priority**: Clarity (breakdown rõ từng chỉ số), Trust (giải thích dễ hiểu).
- **Specific constraints**: Breakdown dạng bar hoặc list; XAI text font đọc; nút min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, breakdown từng chỉ số đóng góp vào điểm rủi ro AI |
