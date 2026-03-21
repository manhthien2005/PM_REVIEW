# 📱 MONITORING — Lịch sử chỉ số (Health History)

> **UC Ref**: UC006, UC008
> **Module**: MONITORING
> **Status**: ✅ Built (health_system — HealthReportScreen)

## Purpose

Xu hướng dài hạn 7/30 ngày. Timeline events + Thống kê. Nhận `profileId` qua route (optional, null = self) — xem lịch sử của bản thân hoặc người được monitor.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm "Xem lịch sử chỉ số" | → This screen (profileId = null) |
| [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) | Bấm "Xu hướng" | → This screen |
| This screen | Bấm event / Chỉ số | → [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) |
| This screen | Back | → [HOME_Dashboard](./HOME_Dashboard.md) hoặc [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) |

---

## User Flow

1. Nhận `profileId` (optional) từ route.
2. Nếu là self flow, user thường vào từ `HOME_Dashboard`; nếu là linked profile flow, user vào qua `MONITORING_VitalDetail(profileId)`.
3. Tab "Nhật ký" — Timeline events theo ngày (HR, SpO₂, BP, Temp).
4. Tab "Thống kê" — Xu hướng 7/30 ngày, aggregation.
5. Bấm event → drill-down VitalDetail với vitalType + timestamp.
6. Pagination — không fetch toàn bộ raw data 1 lần.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch timeline/trends | Skeleton / CircularProgressIndicator |
| Success | Có data | Timeline list hoặc Chart theo tab |
| Empty | Không có event trong khoảng chọn | "Chưa có dữ liệu trong 7 ngày qua" + illustration |
| Error | API fail, 403 | SnackBar + "Thử lại" |
| Filtered | Đã chọn 7d/30d | Data đã lọc |

---

## Edge Cases

- [ ] `profileId` null → data self; `profileId` có → data linked profile, cần `can_view_vitals`
- [ ] 403 Forbidden → message "Bạn không có quyền xem" → Back
- [ ] Khoảng 7d/30d không có data → Empty state thân thiện
- [ ] Pagination: load more khi scroll cuối
- [ ] Tab switch 7d ↔ 30d → refetch với range mới
- [ ] Event có giá trị invalid (-- ) → vẫn hiển thị trong timeline với badge "Không đo được"

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/health-history` với query `?profile_id={profileId}&range=7d|30d&page=&limit=`
- **Input**: Route arg `profileId?`; Tab selection (7d/30d); Pagination params
- **Output**: `{ events: [{ timestamp, vitalType, value, status }], trends: {...} }` hoặc tương đương

---

## Sync Notes

- Khi MONITORING_VitalDetail thay đổi → link "Xu hướng" truyền `profileId`
- Khi HOME_Dashboard thay đổi → link "Lịch sử" truyền `profileId = null`
- Shared: `TimelineEventCard`, `TrendChart`, tab selector
- Bấm event → navigate VitalDetail với `vitalType`, `profileId`, `timestamp` (optional)

---

## Design Context

- **Target audience (profileId = null)**: Người cao tuổi xem lịch sử của mình — timeline rõ, ít tab phức tạp.
- **Target audience (profileId có)**: Người theo dõi xem lịch sử người thân — header hiển thị tên người được xem.
- **Usage context**: Routine — xem xu hướng, không khẩn cấp.
- **Key UX priority**: Clarity (timeline dễ đọc), Calm (không gây áp lực).
- **Specific constraints**: Tab 7d/30d min 48dp; lazy load; Text Scaling 150% → list wrap.

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
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context (profileId/audience), Pipeline Status, Changelog |
| v2.1 | 2026-03-17 | AI | Cross-check sync: linked profile flow đi qua `VitalDetail(profileId)`, bỏ entry trực tiếp chưa tồn tại từ FamilyDashboard |

---

## Implementation Reference (health_system)

- `lib/features/health_monitoring/screens/health_report_screen.dart`
- Tabs: Nhật ký (Timeline), Thống kê (Trends). Mock data hiện tại.
