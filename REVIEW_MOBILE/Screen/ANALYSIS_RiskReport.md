# 📱 ANALYSIS — Điểm rủi ro AI (Risk Report)

> **UC Ref**: UC016
> **Module**: ANALYSIS
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

Điểm rủi ro AI 0–100. Màu xanh/cam/đỏ theo mức. 1 câu tóm tắt. Nhận `profileId` qua route (optional, null = self). Link "Xem giải thích" → RiskReportDetail, "Lịch sử" → RiskHistory.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm Banner Điểm rủi ro | → This screen (profileId = null) |
| [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) | Bấm điểm rủi ro trên Card | → This screen (profileId từ Card) |
| This screen | Bấm "Xem giải thích" | → [ANALYSIS_RiskReportDetail](./ANALYSIS_RiskReportDetail.md) |
| This screen | Bấm "Lịch sử" | → [ANALYSIS_RiskHistory](./ANALYSIS_RiskHistory.md) |
| This screen | Back | → [HOME_Dashboard](./HOME_Dashboard.md) hoặc [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) |

---

## User Flow

1. Nhận `profileId` (optional) từ route.
2. Hiển thị điểm 0–100 + màu (xanh / cam / đỏ).
3. 1 câu tóm tắt (XAI).
4. Fallback: "Đang phân tích" khi model chưa có output.
5. Nút "Xem giải thích" → RiskReportDetail (breakdown).
6. Nút "Lịch sử" → RiskHistory.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch risk score | Skeleton |
| Success | Có data | Điểm lớn, màu, tóm tắt, 2 nút |
| Analyzing | Model chưa có output | "Đang phân tích..." + spinner |
| Empty | Chưa có dữ liệu đủ để phân tích | "Cần thêm dữ liệu sức khoẻ" |
| Error | API fail, 403 | SnackBar, Back |

---

## Edge Cases

- [ ] `profileId` null → self; `profileId` có → linked profile, cần `can_view_vitals`
- [ ] 403 Forbidden → "Bạn không có quyền xem"
- [ ] Model chưa chạy (thiếu vitals) → "Đang phân tích" hoặc Empty
- [ ] Điểm critical (đỏ) → có thể link "Gọi SOS" (optional)

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/risk-report/latest` với query `?profile_id={profileId}`
- **Input**: Route arg `profileId?`; Header/query `target_profile_id`
- **Output**: `{ score, level, summary, analyzed_at }`

---

## Sync Notes

- Khi ANALYSIS_RiskReportDetail thay đổi → link "Xem giải thích" truyền `profileId`, `reportId`
- Khi ANALYSIS_RiskHistory thay đổi → link "Lịch sử" truyền `profileId`
- Shared: RiskScoreDisplay, RiskLevelBadge

---

## Design Context

- **Target audience**: User (self) hoặc người theo dõi (linked profile).
- **Usage context**: Routine — xem điểm rủi ro.
- **Key UX priority**: Clarity (số to, màu rõ), Calm (không gây hoảng).
- **Specific constraints**: Màu xanh/cam/đỏ rõ; tóm tắt 1 câu dễ hiểu; nút min 48dp.

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
| v2.0 | 2026-03-17 | AI | Regen: full template, profileId, links Detail + History |
