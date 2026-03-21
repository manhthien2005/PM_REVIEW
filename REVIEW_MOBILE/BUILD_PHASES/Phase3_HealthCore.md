# Phase 3 — Theo dõi sức khoẻ bản thân (Core value P0)

> **Screens:** MONITORING_VitalDetail, MONITORING_HealthHistory, SLEEP_Report, SLEEP_Detail, ANALYSIS_RiskReport, ANALYSIS_RiskReportDetail
> **Status:** Spec ✅ 6/6 | Built: VitalDetail, HealthHistory, SLEEP_Report ✅ | RiskReport (spec only)

---

## Phase Goal

Đây là **lý do user dùng app mỗi ngày**. Phase 3 cung cấp drill-down chi tiết từng chỉ số (HR, SpO₂...), biểu đồ 24h, xu hướng 7/30 ngày, báo cáo giấc ngủ, và điểm rủi ro AI (USP của sản phẩm).

**Cách build khuyến nghị:** triển khai **self flow trước** từ `HOME_Dashboard`, nhưng tất cả màn phải giữ kiến trúc **contextual** (`profileId?`) ngay từ đầu.

**Unlock cho phase sau:** Sau khi Phase 5 có FamilyDashboard + linked permissions, quay lại verify linked flow cho `VitalDetail`, `SleepReport`, `RiskReport`.

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 2 (Device + Dashboard) | Phase 2 | Yes — cần data từ đồng hồ |
| HOME_Dashboard | Screen/ | Yes |
| API: vitals timeseries, sleep, risk score | Backend | Yes |
| Phase 5 (Family + permissions) | Phase 5 | Partial — cần để test linked flow thật sự |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- **`profileId` route argument phải optional:** `profileId == null` → self. Nếu thiếu xử lý sẽ crash khi drill-down từ Family tab.
- VitalDetail: Chỉ số ngoài vùng hợp lệ (HR=0, sensor rời) → hiển thị `"--"` + icon cảnh báo, không crash.
- RiskReportDetail (XAI): Model chưa có output → có fallback "Đang phân tích" không?

### Constraint Guardian
- Biểu đồ 24h: Không fetch toàn bộ raw data 1 lần. Cần aggregation/pagination.
- SLEEP_History (Phase 7) cần lazy load — không fetch 30 đêm cùng lúc. Ghi chú trong spec.
- RiskReport phải tách rõ 2 lớp build: `self risk` là P0 ở Phase 3, còn `linked risk entry` được verify sau khi Phase 5 có FamilyDashboard card + `profileId`.

### User Advocate
- **Người già cần biểu đồ đơn giản** — không dùng chart phức tạp. Line chart rõ ràng, font to.
- VitalDetail phải có **"giải thích bằng tiếng người"** bên cạnh số (VD: "82 BPM — Bình thường").
- RiskReport: Điểm 0–100 cần màu sắc trực quan (xanh / cam / đỏ) + 1 câu tóm tắt.

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK implement / sync cho Phase 3 — Health Core theo 2 pass:

Pass 1 — Self flow P0:
1. MONITORING_VitalDetail — verify/build self flow từ HOME_Dashboard
2. MONITORING_HealthHistory — verify/build self flow từ HOME_Dashboard / VitalDetail
3. SLEEP_Detail — tách màn detail riêng từ SLEEP_Report
4. ANALYSIS_RiskReport — implement màn risk overview cho self
5. ANALYSIS_RiskReportDetail — implement màn XAI detail cho self

Pass 2 — Context-ready:
6. Giữ `profileId?` trong route cho tất cả màn trên, dù Pass 1 mới build self
7. Sau khi Phase 5 xong, quay lại verify linked flow từ HOME_FamilyDashboard:
   - VitalDetail(profileId)
   - SLEEP_Report(profileId)
   - ANALYSIS_RiskReport(profileId)

Context:
- Architecture Hybrid v3.0
- Self tab và Family tab không dùng profile switcher
- `profileId = null` -> self; có giá trị -> linked profile
- Risk là core value, nhưng linked risk entry chỉ test được sau khi FamilyDashboard có risk summary card
```

---

## Screens to Generate

| Screen | File | UC Ref | Key Flow |
| --- | --- | --- | --- |
| MONITORING_VitalDetail | `MONITORING_VitalDetail.md` | UC007 | Chart 24h, giải thích, profileId optional |
| MONITORING_HealthHistory | `MONITORING_HealthHistory.md` | UC008 | 7/30 ngày trend, profileId optional |
| SLEEP_Detail | `SLEEP_Detail.md` | UC021 | Timeline giai đoạn, từ SleepReport |
| ANALYSIS_RiskReport | `ANALYSIS_RiskReport.md` | UC016 | Score 0–100, màu, tóm tắt |
| ANALYSIS_RiskReportDetail | `ANALYSIS_RiskReportDetail.md` | UC017 | XAI explanation, từ RiskReport |

---

## Acceptance Gate

- [x] 5 file spec tồn tại *(2026-03-17: VitalDetail, HealthHistory, SleepDetail, RiskReport, RiskReportDetail)*
- [x] Mọi màn drill-down có `profileId` optional trong spec
- [x] VitalDetail có "giải thích bằng tiếng người"
- [x] Cross-links: HOME_Dashboard, HOME_FamilyDashboard, SLEEP_Report → các màn Phase 3
- [ ] Self flow hoạt động end-to-end từ `HOME_Dashboard`
- [ ] Sau Phase 5, linked flow được verify từ `HOME_FamilyDashboard` với `profileId`
- [ ] `TASK sync` không báo broken link

> **health_system**: VitalDetailScreen, HealthReportScreen, SleepScreen built. RiskReport chưa có.
