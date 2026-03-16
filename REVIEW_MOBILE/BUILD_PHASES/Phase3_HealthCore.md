# Phase 3 — Theo dõi sức khoẻ bản thân (Core value P0)

> **Screens:** MONITORING_VitalDetail, MONITORING_HealthHistory, SLEEP_Report, SLEEP_Detail, ANALYSIS_RiskReport, ANALYSIS_RiskReportDetail
> **Status:** Spec ✅ 6/6 | Built: VitalDetail, HealthHistory, SLEEP_Report ✅ | RiskReport (spec only)

---

## Phase Goal

Đây là **lý do user dùng app mỗi ngày**. Phase 3 cung cấp drill-down chi tiết từng chỉ số (HR, SpO₂...), biểu đồ 24h, xu hướng 7/30 ngày, báo cáo giấc ngủ, và điểm rủi ro AI (USP của sản phẩm).

**Unlock cho phase sau:** VitalDetail, SleepDetail, RiskReport nhận `profileId` qua route — dùng cho cả Self và Family drill-down (Phase 5).

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 2 (Device + Dashboard) | Phase 2 | Yes — cần data từ đồng hồ |
| HOME_Dashboard | Screen/ | Yes |
| API: vitals timeseries, sleep, risk score | Backend | Yes |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- **`profileId` route argument phải optional:** `profileId == null` → self. Nếu thiếu xử lý sẽ crash khi drill-down từ Family tab.
- VitalDetail: Chỉ số ngoài vùng hợp lệ (HR=0, sensor rời) → hiển thị `"--"` + icon cảnh báo, không crash.
- RiskReportDetail (XAI): Model chưa có output → có fallback "Đang phân tích" không?

### Constraint Guardian
- Biểu đồ 24h: Không fetch toàn bộ raw data 1 lần. Cần aggregation/pagination.
- SLEEP_History (Phase 7) cần lazy load — không fetch 30 đêm cùng lúc. Ghi chú trong spec.

### User Advocate
- **Người già cần biểu đồ đơn giản** — không dùng chart phức tạp. Line chart rõ ràng, font to.
- VitalDetail phải có **"giải thích bằng tiếng người"** bên cạnh số (VD: "82 BPM — Bình thường").
- RiskReport: Điểm 0–100 cần màu sắc trực quan (xanh / cam / đỏ) + 1 câu tóm tắt.

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK generate cho Phase 3 — Health Core. Tạo spec cho 5 màn hình còn thiếu:

1. MONITORING_VitalDetail — Drill-down 1 chỉ số (HR, SpO₂, BP, Temp) + biểu đồ 24h
   - Nhận profileId qua route (optional, null = self)
   - Có "giải thích bằng tiếng người" bên cạnh số
   - UC Ref: UC007

2. MONITORING_HealthHistory — Xu hướng dài hạn 7/30 ngày
   - Nhận profileId qua route (optional)
   - UC Ref: UC008

3. SLEEP_Detail — Timeline từng giai đoạn giấc ngủ (deep, light, REM, awake)
   - Nhận profileId qua route (optional)
   - Link từ SLEEP_Report
   - UC Ref: UC021

4. ANALYSIS_RiskReport — Điểm rủi ro AI 0–100, màu xanh/cam/đỏ, 1 câu tóm tắt
   - Nhận profileId qua route (optional)
   - UC Ref: UC016

5. ANALYSIS_RiskReportDetail — XAI giải thích tại sao điểm cao/thấp
   - Link từ RiskReport
   - UC Ref: UC017

Context: Architecture Hybrid v3.0. Tất cả màn drill-down nhận profileId. HOME_Dashboard và HOME_FamilyDashboard link đến các màn này. SLEEP_Report đã có spec.
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
- [ ] `TASK sync` không báo broken link

> **health_system**: VitalDetailScreen, HealthReportScreen, SleepScreen built. RiskReport chưa có.
