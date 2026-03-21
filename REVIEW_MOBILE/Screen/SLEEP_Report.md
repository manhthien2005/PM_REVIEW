# 📱 SLEEP — Báo cáo giấc ngủ (Latest Night)

> **UC Ref**: UC020, UC021
> **Module**: SLEEP
> **Status**: ✅ Built (health_system)

## Purpose

Báo cáo giấc ngủ đêm qua (hoặc đêm được chọn). Tổng thời gian, chất lượng, timeline giai đoạn. Link đến SLEEP_Detail. Nhận `profileId` qua route (optional). **UI State "No data tonight yet"** cho ngày hiện tại trước 6:00 sáng (dữ liệu sleep xử lý ban đêm).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm Banner Giấc ngủ | → This screen (profileId = null) |
| [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) | Bấm Giấc ngủ trên Card | → This screen (profileId từ Card) |
| This screen | Bấm "Xem chi tiết" / Timeline | → [SLEEP_Detail](./SLEEP_Detail.md) |
| This screen | Bấm "Chọn ngày khác" | → [SLEEP_History](./SLEEP_History.md) hoặc date picker |
| This screen | Bấm "Cài đặt" (self only) | → [SLEEP_TrackingSettings](./SLEEP_TrackingSettings.md) |
| This screen | Back | → [HOME_Dashboard](./HOME_Dashboard.md) hoặc [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) |

---

## User Flow

1. Nhận `profileId` (optional), `date` (optional, default: đêm qua).
2. Hiển thị đêm được chọn.
3. Hero card: Tổng thời gian, chất lượng, nhịp tim khi ngủ.
4. Phase composition (deep, light, REM, awake).
5. Timeline bar → tap → SLEEP_Detail.
6. **Trước 6:00 sáng, chọn "đêm nay"** → State "No data tonight yet".
7. Nếu là self (`profileId = null`) → hiển thị nút "Cài đặt". Nếu là linked profile → ẩn nút này.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch | Skeleton |
| Success | Có data | Hero card, phase chart, timeline |
| **No data tonight yet** | Ngày hiện tại, trước 6:00 sáng | "Dữ liệu đêm nay chưa sẵn sàng. Thử lại sau 6:00." + illustration |
| Empty | Đêm đó không có data (chưa đeo đồng hồ) | "Chưa có dữ liệu đêm này" |
| Error | API fail, 403 | SnackBar, Back |

---

## Edge Cases

- [ ] **Trước 6:00 sáng + chọn "đêm nay"** → "No data tonight yet" (dữ liệu xử lý ban đêm)
- [ ] `profileId` null → self; `profileId` có → linked profile, cần `can_view_vitals`
- [ ] Đêm chưa kết thúc (đang ngủ) → "Đang theo dõi..." hoặc ẩn
- [ ] Date picker: giới hạn không chọn tương lai
- [ ] Linked profile flow → không hiển thị `SLEEP_TrackingSettings` vì đây là cấu hình self-only

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sleep/report` với query `?profile_id={profileId}&date=YYYY-MM-DD`
- **Input**: Route args `profileId?`, `date?`; date = đêm (VD: 2026-03-16 = đêm 16→17)
- **Output**: `{ duration_min, quality, avg_hr_sleep, phases: [...], timeline }`

---

## Sync Notes

- Khi SLEEP_Detail thay đổi → link "Xem chi tiết" truyền `profileId`, `date`
- Khi SLEEP_History thay đổi → chọn ngày → refetch Report
- Khi SLEEP_TrackingSettings thay đổi → tracking off có thể ẩn data mới (self flow only)
- Shared: SleepHeroCard, PhaseCompositionChart, SleepTimelineBar

---

## Design Context

- **Target audience**: User hoặc người theo dõi.
- **Usage context**: Routine — xem báo cáo đêm qua.
- **Key UX priority**: Clarity (số to, phase rõ), Calm (màu nhẹ).
- **Specific constraints**: "No data tonight yet" message thân thiện; phase màu: deep (xanh đậm), light (xanh nhạt), REM (tím), awake (vàng).

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, UI State "No data tonight yet" trước 6:00 sáng |
| v2.1 | 2026-03-17 | AI | Cross-check sync: `SLEEP_TrackingSettings` chỉ hiển thị trong self flow, không áp dụng cho linked profile |

---

## Implementation Reference (health_system)

- `lib/features/sleep_analysis/screens/sleep_screen.dart`
- Widgets: SleepHeroCard, PhaseCompositionChart, SleepTimelineBar, SleepTrendChart
- Date picker để chọn đêm. profileId cho context.
