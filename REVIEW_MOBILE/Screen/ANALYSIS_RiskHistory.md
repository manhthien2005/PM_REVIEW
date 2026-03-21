# 📱 ANALYSIS — Lịch sử điểm rủi ro AI

> **UC Ref**: UC016
> **Module**: ANALYSIS
> **Status**: ⬜ Spec only

## Purpose

Lịch sử điểm rủi ro theo thời gian của **bản thân hoặc linked profile**. **Lazy load (infinite scroll)** — không load toàn bộ 1 lần. Nhận `profileId` qua route (optional).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) | Bấm "Lịch sử" | → This screen |
| This screen | Bấm item | → [ANALYSIS_RiskReportDetail](./ANALYSIS_RiskReportDetail.md) |
| This screen | Back | → [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) |

---

## User Flow

1. Nhận `profileId` (optional) từ route.
2. Load batch đầu (VD: 20 items).
3. Scroll cuối → **infinite scroll** load more.
4. Mỗi item: ngày, điểm, màu. Tap → RiskReportDetail.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch batch đầu | Skeleton |
| Success | Có data | List cards, scroll |
| Loading More | Đang load more (infinite scroll) | Loading indicator cuối list |
| Empty | Không có lịch sử | "Chưa có dữ liệu" + illustration |
| Error | API fail | SnackBar + "Thử lại" |
| End | Đã load hết | Ẩn loading more |

---

## Edge Cases

- [ ] **Lazy load / infinite scroll** — bắt buộc: không fetch toàn bộ; load more khi scroll cuối
- [ ] Pagination: `?page=1&limit=20` → tăng page khi load more
- [ ] `profileId` null → self; `profileId` có → linked profile
- [ ] Tap item → RiskReportDetail với `reportId` từ item
- [ ] Pull-to-refresh → reset to page 1

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/risk-report/history` với query `?profile_id={profileId}&page=&limit=20`
- **Input**: Route arg `profileId?`; Pagination `page`, `limit`
- **Output**: `{ items: [{ report_id, score, level, analyzed_at }], has_more }`

---

## Sync Notes

- Khi ANALYSIS_RiskReport thay đổi → link "Lịch sử" truyền `profileId`
- Khi ANALYSIS_RiskReportDetail thay đổi → tap item truyền `reportId`, `profileId`
- Back quay về `ANALYSIS_RiskReport` cùng ngữ cảnh `profileId` đã nhận ban đầu
- Shared: RiskHistoryCard, InfiniteScrollController

---

## Design Context

- **Target audience**: User hoặc người theo dõi — xem xu hướng điểm rủi ro.
- **Usage context**: Routine — lịch sử.
- **Key UX priority**: Clarity (mỗi item rõ), Speed (lazy load không block).
- **Specific constraints**: Infinite scroll; loading indicator cuối list; item min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `build-plan/ANALYSIS_03_RiskHistory_plan.md` |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Companion Docs

- `build-plan/ANALYSIS_03_RiskHistory_plan.md`

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation (STUB) |
| v2.0 | 2026-03-17 | AI | Regen: full template, lazy load (infinite scroll) |
| v2.1 | 2026-03-17 | AI | Cross-check sync: làm rõ history dùng chung cho self và linked profile |
| v2.2 | 2026-03-20 | AI | Added prioritized build plan `build-plan/ANALYSIS_03_RiskHistory_plan.md`, đồng bộ thứ tự build sau RiskReport và RiskReportDetail |
