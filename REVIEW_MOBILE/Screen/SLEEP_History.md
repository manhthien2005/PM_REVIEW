# 📱 SLEEP — Lịch sử giấc ngủ (Trend)

> **UC Ref**: UC021
> **Module**: SLEEP
> **Status**: ⬜ Spec only

## Purpose

Xu hướng giấc ngủ nhiều đêm. **Lazy load / pagination** — không fetch 30 đêm cùng lúc. Tap item → SLEEP_Report. Nhận `profileId` qua route (optional). **UI State "No data tonight yet"** cho item "đêm nay" trước 6:00 sáng.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [SLEEP_Report](./SLEEP_Report.md) | Bấm "Chọn ngày khác" | → This screen |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm "Lịch sử giấc ngủ" (nếu có) | → This screen |
| This screen | Bấm item (đêm) | → [SLEEP_Report](./SLEEP_Report.md) với date |
| This screen | Back | → [SLEEP_Report](./SLEEP_Report.md) |

---

## User Flow

1. Nhận `profileId` (optional) từ route.
2. Load batch đầu (VD: 14 đêm).
3. **Lazy load** — scroll cuối → load more.
4. Mỗi item: đêm, duration, quality. Tap → Report với date.
5. Item "đêm nay" trước 6:00 sáng → badge "Chưa có data" hoặc disable tap.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch batch đầu | Skeleton |
| Success | Có data | List cards, scroll |
| Loading More | Đang load more | Loading indicator cuối list |
| **No data tonight yet** | Item "đêm nay" trước 6:00 | Badge "Chưa có data" / disabled |
| Empty | Không có lịch sử | "Chưa có dữ liệu" + illustration |
| Error | API fail | SnackBar, "Thử lại" |

---

## Edge Cases

- [ ] **Lazy load / pagination** — không fetch toàn bộ; load more khi scroll cuối
- [ ] **Đêm nay trước 6:00** → item hiển thị "Chưa có data" hoặc ẩn
- [ ] `profileId` null → self; `profileId` có → linked profile
- [ ] Tap item → Report với `date` từ item
- [ ] Pull-to-refresh → reset

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/sleep/history` với query `?profile_id={profileId}&page=&limit=14`
- **Input**: Route arg `profileId?`; Pagination
- **Output**: `{ items: [{ date, duration_min, quality }], has_more }`

---

## Sync Notes

- Khi SLEEP_Report thay đổi → chọn ngày từ History truyền `date`
- Shared: SleepHistoryCard, InfiniteScrollController

---

## Design Context

- **Target audience**: User hoặc người theo dõi — xem xu hướng.
- **Usage context**: Routine — lịch sử.
- **Key UX priority**: Clarity (mỗi đêm rõ), Speed (lazy load).
- **Specific constraints**: Item min 48dp; "No data tonight yet" rõ.

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
| v1.0 | 2026-03-17 | AI | Initial creation (STUB) |
| v2.0 | 2026-03-17 | AI | Regen: full template, lazy load, "No data tonight yet" |
