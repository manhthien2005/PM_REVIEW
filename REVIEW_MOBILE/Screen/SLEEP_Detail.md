# 📱 SLEEP — Chi tiết timeline giấc ngủ

> **UC Ref**: UC021
> **Module**: SLEEP
> **Status**: 🔄 Partial (health_system: SleepTimelineBar trong SleepScreen)

## Purpose

Timeline từng giai đoạn giấc ngủ (deep, light, REM, awake). Drill-down từ SLEEP_Report. Nhận `profileId`, `date` qua route (optional). **UI State "No data tonight yet"** nếu đêm đó trước 6:00 sáng (chưa xử lý).

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [SLEEP_Report](./SLEEP_Report.md) | Bấm Timeline / "Xem chi tiết" | → This screen |
| This screen | Bấm Back | → [SLEEP_Report](./SLEEP_Report.md) |

---

## User Flow

1. Nhận `profileId`, `date` từ route.
2. Timeline ngang: Các giai đoạn theo thời gian.
3. Màu theo loại: Deep (xanh đậm), Light (xanh nhạt), REM (tím), Awake (vàng).
4. Tap segment → Tooltip / detail (start, end, duration).

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch | Skeleton |
| Success | Có data | Timeline với segments |
| **No data tonight yet** | Đêm đó, trước 6:00 sáng | "Dữ liệu đêm nay chưa sẵn sàng" |
| Empty | Không có timeline | "Chưa có dữ liệu chi tiết" |
| Error | API fail | SnackBar, Back |

---

## Edge Cases

- [ ] **Trước 6:00 sáng + date = đêm nay** → "No data tonight yet"
- [ ] Timeline rỗng (đêm không ngủ đủ) → Empty
- [ ] Tap segment → tooltip hoặc expand detail
- [ ] Zoom/pinch timeline (optional) cho đêm dài

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sleep/detail` với query `?profile_id={profileId}&date=YYYY-MM-DD`
- **Input**: Route args `profileId?`, `date`
- **Output**: `{ phases: [{ type, start, end, duration_min }] }`

---

## Sync Notes

- Khi SLEEP_Report thay đổi → link "Xem chi tiết" truyền `profileId`, `date`
- Shared: SleepTimelineSegment, PhaseColorMap

---

## Design Context

- **Target audience**: User hoặc người theo dõi — xem chi tiết giấc ngủ.
- **Usage context**: Routine — drill-down từ Report.
- **Key UX priority**: Clarity (timeline rõ, màu phase), Calm.
- **Specific constraints**: Màu phase nhất quán với Report; tap segment min 48dp.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | 🔄 Partial (inline TimelineBar) | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template, "No data tonight yet" |

---

## Implementation Reference (health_system)

- `SleepScreen` có `SleepTimelineBar` — timeline inline. Chưa có màn Detail riêng.
