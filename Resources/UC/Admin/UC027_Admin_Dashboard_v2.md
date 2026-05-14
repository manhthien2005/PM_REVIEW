# UC027 v2 - DASHBOARD TỔNG QUAN HỆ THỐNG

> **Phiên bản:** v2 (rebuild Phase 0.5 — 2026-05-12)
> **Thay thế:** UC027 v1 (`UC027_Admin_Dashboard.md`)
> **Quyết định nguồn:** `AUDIT_2026/tier1.5/intent_drift/healthguard/DASHBOARD.md`

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung |
| ------------------ | -------- |
| **Mã UC**          | UC027 |
| **Tên UC**         | Dashboard tổng quan hệ thống (Admin Dashboard) |
| **Tác nhân chính** | Quản trị viên (Admin) |
| **Mô tả**          | Admin xem tổng hợp KPI và trạng thái hoạt động hệ thống: thống kê user/device/alert/SOS, biểu đồ xu hướng 7 ngày, sự cố chưa resolve, bệnh nhân risk cao. Dashboard là entry point chính của Admin Web, hỗ trợ drill-down vào module chi tiết. |
| **Trigger**        | Admin đăng nhập thành công hoặc click "Dashboard" trên nav. |
| **Tiền điều kiện** | Admin đã đăng nhập (`role = 'admin'`). |
| **Hậu điều kiện**  | Admin xem được tổng hợp KPI cache TTL 30s. Audit log entry chỉ ghi khi admin manual nav (không log auto-refresh). |

---

## 1. Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Admin | Truy cập Dashboard (trang chính sau đăng nhập hoặc click nav). |
| 2 | FE | Gửi 5 request parallel với header `X-Dashboard-Refresh-Type: manual` (nav click) hoặc `auto` (60s polling): `/kpi`, `/alerts-chart?days=7`, `/risk-distribution`, `/recent-incidents`, `/at-risk-patients`. Có thể thêm `/system-health`, `/kpi-sparklines`. |
| 3 | Hệ thống | Cache-aware: cache hit (TTL 30s) hoặc fresh DB query. Trả về aggregated KPIs (BR-027-02). Nếu header `manual` → ghi audit `admin.view_dashboard`. |
| 4 | FE | Render **5 KPI Cards** (Users / Devices / Alerts today / SOS active / At-risk patients) với delta % vs hôm qua. |
| 5 | FE | Render **3 charts**: alerts trend 7 ngày (bar), risk distribution (pie), devices online trend (line). |
| 6 | FE | Render **Recent Incidents table** (5 sự cố unresolved gần nhất, bao gồm Fall / SOS / Vital Alert). |
| 7 | FE | Render **At-Risk Patients table** (5 bệnh nhân HIGH/CRITICAL hoặc top theo risk score). |
| 8 | Admin | Xem tổng quan → quyết định action (drill-down, refresh, change time range). |

---

## 2. Luồng thay thế (Alternative Flows)

### 2.a Drill-down vào chi tiết (URL pattern)
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Admin | Click vào KPI Card hoặc 1 row trong table. |
| 2.a.2 | FE | Navigate qua URL pattern formalized:
- KPI "Users" → `/users?role=user&is_active=true`
- KPI "Devices" → `/devices?is_active=true`
- KPI "Alerts today" → `/alerts?date=today` (FE map date filter)
- KPI "SOS active" → `/emergency?status=active`
- KPI "At-risk patients" → `/users?risk_level=high,critical`
- Row Recent Incident (Fall) → `/emergency/fall/:id`
- Row Recent Incident (SOS) → `/emergency/sos/:id`
- Row Recent Incident (Vital Alert) → `/alerts/:id`
- Row At-risk patient → `/users/:id` |

### 2.b Thay đổi khoảng thời gian biểu đồ alerts
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.b.1 | Admin | Chọn dropdown trong card biểu đồ alerts: Hôm nay / 7 ngày / 14 ngày / 30 ngày / Tùy chọn. |
| 2.b.2 | FE | `GET /api/v1/dashboard/alerts-chart?days=14` hoặc `?startDate=&endDate=`. |
| 2.b.3 | Hệ thống | Re-query (cache-aware) → trả chart data mới. |

> **Lưu ý v2:** Time range selector chỉ áp dụng cho alerts-chart, KHÔNG global (giảm scope, tránh phức tạp UX). KPI cards luôn dùng "today vs yesterday" cố định.

### 2.c Refresh thủ công
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.c.1 | Admin | Click nút "Refresh" hoặc icon reload. |
| 2.c.2 | FE | Re-fetch all dashboard endpoints với header `X-Dashboard-Refresh-Type: manual` + cache bypass header `X-Cache-Bypass: true`. |
| 2.c.3 | Hệ thống | Skip cache → fresh DB query. Ghi audit `admin.view_dashboard` (manual). |

---

## 3. KPI Definitions (Section mới — formalize)

### KPI Card 1: Users
- `total`: count(users) WHERE role='user' AND deleted_at IS NULL
- `active`: count(users) WHERE role='user' AND is_active=true AND deleted_at IS NULL
- `withDevices`: count(users) WHERE has active device
- `newToday`: count(users) WHERE created_at >= today_start
- `delta`: % change vs yesterday

### KPI Card 2: Devices
- `total`: count(devices) WHERE deleted_at IS NULL
- `online`: count(devices) WHERE is_active=true AND deleted_at IS NULL

### KPI Card 3: Alerts Today
- `today`: count(alerts) WHERE created_at >= today_start
- `critical`: subset with severity='critical'
- `delta`: % vs yesterday

### KPI Card 4: SOS Active
- `unresolved`: count(sos_events) WHERE status IN ('active', 'responded')
- `total`: count(sos_events) ALL
- `delta`: % vs yesterday

### KPI Card 5: At-Risk Patients
- `critical`: count distinct users with latest risk_level='critical'
- `high`: count distinct users with latest risk_level='high'

### Bonus KPI: AI Models Active
- `active`: count(ai_models) WHERE is_active=true AND deleted_at IS NULL

---

## 4. Charts

### Chart 1: Alerts Trend (7-14-30 days configurable)
- X-axis: dates
- Y-axis: counts per severity (low/medium/high/critical) + fall + sos
- Stacked bar chart

### Chart 2: Risk Distribution
- Pie chart: LOW / MODERATE / HIGH / CRITICAL / UNASSESSED
- Each slice = distinct user count với latest risk_score

### Chart 3: Devices Online Trend
- Line chart 7 ngày
- Y-axis: online device count tại snapshot mỗi ngày (Phase 4 cần track historic snapshots — hoặc compute từ events, document approach)

### Bonus: KPI Sparklines (BR-bonus, không trong UC v1)
- Sparkline 7d cho mỗi KPI Card
- Endpoint: `GET /api/v1/dashboard/kpi-sparklines` (đã có)

---

## 5. Drill-down Tables

### Table 1: Recent Incidents (LIMIT 5)
- **Time scope:** Tất cả unresolved (KHÔNG giới hạn 24h — BR-027-03 v2 ratify code behavior).
- **Sources:** Union 3 tables:
  - `fall_events` WHERE `sos_triggered=false AND user_cancelled=false AND user_responded_at IS NULL`
  - `sos_events` WHERE `status IN ('active', 'responded')`
  - `alerts` WHERE `severity IN ('high', 'critical') AND resolved_at IS NULL` (NEW Phase 4)
- **Sort:** desc theo timestamp
- **Columns:** Type (FALL/SOS/VITAL_ALERT), Patient, Timestamp, Status, Location (optional)
- **UI:** Badge màu khác biệt cho 3 type (Fall vàng, SOS đỏ, Vital Alert cam)

### Table 2: At-Risk Patients (LIMIT 5)
- **Filter:** Tất cả patients sort theo: critical > high > medium > low > unassessed, tie-break score desc.
- **BR-027-04 v2 update:** Bảng SHOULD chỉ hiển thị HIGH/CRITICAL (UC v1). Code đang show all patients sorted — em đề xuất giữ code (cho admin context khi không có high/critical) HOẶC strict UC (chỉ HIGH/CRITICAL, empty state nếu không có).
- **Columns:** Tên, Age, Risk Score, Risk Level, Last Assessment

---

## 6. Business Rules

- **BR-027-01 (Auto-Refresh):** FE auto-refresh dashboard mỗi 60s (configurable via UC024 setting).
- **BR-027-02 (Aggregated Data):** KPI queries dùng counts từ `alerts`, `sos_events`, `fall_events`, `devices`, `users`, `risk_scores`. KHÔNG query raw `vitals` hoặc `motion_data`.
- **BR-027-03 (Recent Incidents v2):** Hiển thị 5 incidents unresolved gần đây nhất, **KHÔNG giới hạn thời gian** (override UC v1 24h limit). Lý do: incident unresolved 2 ngày trước nghiêm trọng hơn 1 giờ, cần visible.
- **BR-027-04 (At-Risk Patients):** Sort theo risk level priority, hiển thị top 5. Nếu không có HIGH/CRITICAL → show LOW/MODERATE để admin context (code current behavior).
- **BR-027-05 (Self-Audit v2):** Ghi `audit_logs.action='admin.view_dashboard'` CHỈ khi header `X-Dashboard-Refresh-Type: manual` (nav click hoặc refresh button). KHÔNG ghi cho auto-refresh polling (tránh log noise).
- **BR-027-06 (Caching v2 - NEW):** Cache TTL 30s in-memory cho 3 endpoints heavy: `/kpi`, `/alerts-chart`, `/risk-distribution`. `recent-incidents` + `at-risk-patients` luôn fresh (data thay đổi nhanh).

---

## 7. Yêu cầu phi chức năng (NFR)

- **Performance:**
  - Dashboard load lần đầu (cache miss) < 2s.
  - Cache hit < 100ms.
  - 16 parallel queries cho `/kpi` với `Promise.all` (đã có).
- **Security:**
  - Tất cả 7 endpoints `authenticate + requireAdmin`.
  - Rate limit 60 req/min.
  - Không expose raw PHI (chỉ aggregated counts + minimal patient info: name/email/age).
- **Auditability:**
  - Self-audit theo BR-027-05 v2.
- **Usability:**
  - Responsive desktop (1280px+).
  - Color coding: severity (Green/Yellow/Orange/Red), online/offline (Green/Gray).
  - Comparison delta % UI cho mỗi KPI Card (BE đã expose `usersDelta`, `alertsDelta`, `sosDelta` — FE wire up Phase 4).
  - Drill-down deep links per Section 2.a URL pattern.

---

## 8. Cross-references

- **Code paths:**
  - Routes: `HealthGuard/backend/src/routes/dashboard.routes.js`
  - Controller: `HealthGuard/backend/src/controllers/dashboard.controller.js`
  - Service: `HealthGuard/backend/src/services/dashboard.service.js`
- **Schema:** `users`, `devices`, `alerts`, `sos_events`, `fall_events`, `risk_scores`, `ai_models` tables
- **Cross-UC:**
  - UC024 Configure System: BR-027-01 refresh interval configurable
  - UC026 View System Logs: self-audit pattern consistent (D-LOGS-01 mẫu)
  - UC028 Health Overview: at-risk patients drill-down detail
  - UC029 Emergency Management: recent incidents drill-down
  - UC022 Manage Users: users KPI drill-down

---

## 9. Out of scope (defer Phase 5+)

- **WebSocket / SSE real-time push** thay polling 60s — Phase 5+ event bus.
- **Continuous Aggregates `vitals_daily/hourly`** — UC v1 mention nhưng không cần với KPI hiện tại. Revisit khi có "Avg HR system" KPI.
- **Customizable widget layout** (drag/drop) — UX nice-to-have.
- **Global date range selector** áp dụng toàn dashboard — phức tạp UX.
- **Export dashboard snapshot PDF** — scope nở.
- **Pub/Sub Redis cache invalidation** (D-CFG-02 cross-cutting) — single-instance đồ án 2 không cần.

---

## 10. Decisions log reference

Xem `AUDIT_2026/tier1.5/intent_drift/healthguard/DASHBOARD.md` Section "Anh's decisions log" cho rationale:
- D-DASH-01: Caching strategy
- D-DASH-02: Recent incidents time scope
- D-DASH-03: Self-audit scope
- D-DASH-04: Vital Alert include
- D-DASH-05: Continuous Aggregates drop
- D-DASH-06: usersTotal duplicate fix
- Add-ons #5 #6 keep, #1-4 drop
