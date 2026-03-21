# 📱 ANALYSIS — Điểm rủi ro AI (Risk Report)

> **UC Ref**: UC016
> **Module**: ANALYSIS
> **Status**: ⬜ Spec only (health_system chưa có)

## Purpose

Điểm rủi ro AI 0–100. Màu xanh/cam/đỏ theo mức. 1 câu tóm tắt. Đây là màn hình **contextual**: nhận `profileId` qua route (optional, null = self; có giá trị = linked profile từ `HOME_FamilyDashboard`). Link "Xem giải thích" → RiskReportDetail, "Lịch sử" → RiskHistory.

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
2. Nếu `profileId = null` → load risk của bản thân từ `HOME_Dashboard`; nếu có `profileId` → load risk của linked profile từ `HOME_FamilyDashboard`.
3. Hiển thị điểm 0–100 + màu (xanh / cam / đỏ).
4. 1 câu tóm tắt (XAI).
5. Fallback: "Đang phân tích" khi model chưa có output.
6. Nút "Xem giải thích" → RiskReportDetail (breakdown).
7. Nút "Lịch sử" → RiskHistory.

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
- **Input**: Route arg `profileId?` (contextual route arg, không dùng global profile switcher)
- **Output**: `{ score, level, summary, analyzed_at }`

---

## Sync Notes

- `HOME_Dashboard` → mở màn này với `profileId = null` (self).
- `HOME_FamilyDashboard` → mở màn này với `profileId` của linked profile.
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
| PLAN | ✅ Done | `build-plan/ANALYSIS_01_RiskReport_plan.md` |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Companion Docs

- `build-plan/ANALYSIS_01_RiskReport_plan.md`

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, profileId, links Detail + History |
| v2.1 | 2026-03-17 | AI | Cross-check sync: xác nhận contextual self/linked flow và bỏ dấu vết `target_profile_id` |
| v2.2 | 2026-03-20 | AI | Added prioritized build plan `build-plan/ANALYSIS_01_RiskReport_plan.md`, khóa vai trò màn entry từ banner điểm sức khỏe |
