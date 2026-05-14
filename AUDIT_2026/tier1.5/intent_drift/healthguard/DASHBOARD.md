# Intent Drift Review — `HealthGuard / DASHBOARD`

**Status:** 🟠 Confirmed v3 (Q1-Q6 anh chọn theo em recommend; Q7 NEW post-cross-repo-verify 2026-05-12 — propagated enum bug từ HEALTH module, link D-HEA-07; add-ons keep #5 #6, drop #1-#4)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** DASHBOARD (Admin overview KPIs + charts + drill-down lists)
**Related UCs (old):** UC027 (Admin Dashboard)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 7 (Q1-Q6 confirmed v2 + Q7 cross-repo enum bug propagated từ HEALTH Q7 — medium-CRITICAL severity)

---

## 🎯 Mục tiêu

Capture intent cho DASHBOARD module. UC027 mention 5 KPI cards + 3 chart types + 2 drill-down tables. Code đã có 7 endpoints.

---

## 📚 UC027 cũ summary

- Actor: Admin
- Main: 5 KPI cards (Users / Devices / Alerts today / SOS active / At-risk patients) + 3 charts (alerts trend 7d, risk distribution pie, devices online line) + 2 tables (recent incidents 5, at-risk patients 5)
- Alt: 6.a drill-down, 6.b time range change, 6.c manual refresh
- BR-027-01 auto-refresh 60s, BR-027-02 aggregated data only (no raw vitals/motion query), BR-027-03 recent incidents 24h, BR-027-04 at-risk HIGH/CRITICAL only, BR-027-05 audit `admin.view_dashboard`
- NFR: < 2s load, Continuous Aggregates (`vitals_daily`, `vitals_hourly`), caching TTL 30s

---

## 🔧 Code state

**Routes (`dashboard.routes.js`):**

```
authenticate + requireAdmin + rateLimit 60/min — all 7 endpoints

GET    /api/v1/dashboard/kpi                  16 parallel counts → users/devices/alerts/sos/atRisk/aiModels
GET    /api/v1/dashboard/alerts-chart         alerts + sos + fall events grouped by day
GET    /api/v1/dashboard/risk-distribution    LOW/MODERATE/HIGH/CRITICAL/UNASSESSED counts
GET    /api/v1/dashboard/recent-incidents     fall_events PENDING + sos active/responded
GET    /api/v1/dashboard/at-risk-patients     all patients sorted by risk level + score
GET    /api/v1/dashboard/system-health        DB up + uptime (BONUS, không có trong UC)
GET    /api/v1/dashboard/kpi-sparklines       7d sparklines per KPI (BONUS, không có trong UC)
```

**Service highlights (`dashboard.service.js`):**
- ✅ `Promise.all` parallel queries (perf good)
- ✅ Raw SQL với `DISTINCT ON (user_id) ORDER BY calculated_at DESC` cho latest risk score (đúng pattern)
- ✅ Aggregation từ `alerts`, `devices`, `users`, `sos_events`, `fall_events` counts — BR-027-02 ✅
- ✅ At-risk sort: critical > high > medium > low > unassessed, tie-break bằng score
- ⚠️ **NO caching** — mỗi GET /kpi = 16 parallel DB queries (NFR-Perf "TTL 30s" violated)
- ⚠️ **Recent incidents drop 24h limit** — code comment: "Hiện tất cả PENDING/IN_PROGRESS, không giới hạn 24h" (drift intentional, BR-027-03 violated)
- ⚠️ **NO self-audit** `admin.view_dashboard` (BR-027-05 violated)
- ⚠️ **Recent incidents thiếu Vital Alert** — UC nói "Fall/SOS/Vital Alert", code chỉ fall + sos
- ⚠️ **`usersTotal == usersActive` duplicate query** — paste bug (2 queries cùng condition)
- ⚠️ **NO Continuous Aggregates** `vitals_daily/hourly` (NFR-Perf mention) — code aggregate from alerts/sos/fall events trực tiếp

**🔴 CROSS-REPO finding CRITICAL (post-cross-repo-verify 2026-05-12) — propagated từ HEALTH Q7:**

- **Line 74**: `prisma.$queryRaw… AND rs.risk_level = 'high'` với comment `"đồng bộ với health service"` → schema chỉ có `low/medium/critical` (3 levels) → query luôn return 0 → KPI `atRisk.high` = 0
- **Line 287**: `result = { LOW, MODERATE, HIGH, CRITICAL, UNASSESSED }` — 5 keys legacy với `MODERATE` (UC027 v1 only, schema dùng `medium`) + `HIGH` (luôn = 0)
- **Line 293-294**: `level === 'MEDIUM' ? 'MODERATE' : level` — mapping legacy, giữ cho FE backward compat nhưng confuse: DB tiếng UPPERCASE? Schema lưu lowercase, em check dùng `toUpperCase()` defensive
- **Line 404**: `RISK_ORDER = { critical, high, medium, low }` — có key 'high' thừa (không bao giờ match)
- **3 enum representations trong cùng 1 file** (lowercase với 'high' / UPPERCASE với MODERATE / lowercase + UNASSESSED) → maintainability nightmare
- **UC027 v2** đã generated TRƯỚC khi phát hiện Q7 → cần update UC027 v2 sau khi fix
- **getAlertsChart line 236**: `alert.severity === 'high'` — KHÔNG phải bug. Đây là `alerts.severity` enum (schema `05_create_tables_events_alerts.sql:131` vẫn `low/medium/high/critical` 4 values) — KHÁC `risk_scores.risk_level`. 2 enum khác nhau, em flag clarify.

→ **Severity: 🔴 CRITICAL (same as HEALTH Q7)** — fix dùng chung bản với D-HEA-07 (cross-module commit).

**Phase 1 audit findings (relevant):**
- M02 Routes 🟢 clean pattern
- M04 Services 🟡 nhiều `console.error` swallow trong service (pattern consistency với writeLog)

---

## 💬 Anh react block

> Em ưu tiên drift quan trọng. Add-ons cuối doc.

---

### Q1: Caching layer (NFR-Perf TTL 30s)

**UC NFR:** "Hỗ trợ caching KPI data (TTL 30 giây)"
**Code:** Không có cache. Mỗi GET = 16 parallel queries cho `/kpi`, 3 queries cho `/alerts-chart`, vv.

**Implications:**
- BR-027-01 auto-refresh 60s + 10 admin online concurrent = 10 req/min cho mỗi endpoint = OK với DB hiện tại
- Với 100 admin concurrent = 100 req/min = ~1.6 query/s × 16 = 25 query/s spike → DB load tăng
- TTL 30s: cache hit giảm DB load 80-90%

**Em recommend:**
- **Reuse pattern in-memory cache từ CONFIG (D-CFG-03)** — cùng singleton Map + TTL helper
- Apply cho `/kpi`, `/alerts-chart`, `/risk-distribution` (3 endpoints heavy)
- KHÔNG cache `/recent-incidents`, `/at-risk-patients` (data changes fast, cần fresh)
- TTL 30s per UC NFR
- Invalidate hook: khi có alert/sos/fall event mới được create → publish event → cache clear (defer Phase 5+ cho event bus)

**Anh decision:**
- ✅ **Em recommend (cache /kpi, /alerts-chart, /risk-distribution; skip recent/at-risk; TTL 30s)** ← anh CHỌN
- ☐ Cache tất cả 7 endpoints
- ☐ Skip cache (đồ án 2 demo concurrent admin ít, không cần)
- ☐ Khác: ___

---

### Q2: Recent incidents — UC 24h limit vs Code "all unresolved"

**UC BR-027-03:** "Sự cố gần đây chỉ hiện sự cố trong 24h gần nhất"
**Code comment:** "Hiện tất cả sự cố PENDING/IN_PROGRESS, không giới hạn 24h"

**Trade-off:**
- **24h limit (UC):** admin chỉ thấy nóng hổi, danh sách ngắn. Nếu có sự cố 2 ngày trước chưa resolve → invisible trong dashboard → admin phải vào UC029 Emergency để xem.
- **All unresolved (code):** admin thấy tất cả pending bất kể thời gian → không miss sự cố cũ chưa xử lý.

**Em recommend:**
- **Override UC → giữ code behavior (all unresolved + LIMIT 5)** vì sự cố unresolved 2 ngày là vấn đề nghiêm trọng hơn sự cố 1 giờ → cần visible.
- UC v2 update BR-027-03: "Hiện 5 sự cố unresolved gần đây nhất, không giới hạn thời gian. Nếu admin muốn filter 24h → drill-down vào UC029."
- Hoặc compromise: hiển thị badge "Cũ 3 ngày" cho sự cố > 24h để admin attention.

**Anh decision:**
- ✅ **Em recommend (giữ all unresolved + LIMIT 5, UC v2 update)** ← anh CHỌN
- ☐ Strict 24h per UC (code phải sửa)
- ☐ Hybrid (all unresolved + badge cảnh báo nếu > 24h)
- ☐ Khác: ___

---

### Q3: Self-audit `admin.view_dashboard` scope

**UC BR-027-05:** "Mọi lượt truy cập Dashboard được ghi vào `audit_logs` với action `admin.view_dashboard`"
**Code:** KHÔNG có writeLog call

**Implications:**
- Dashboard auto-refresh mỗi 60s (BR-027-01) → 1 admin xem 1 giờ = 60 audit entries. 10 admin × 8h = 4800 entries/day → noise lớn.
- Có thể giới hạn: chỉ log lần load đầu (session-based), không log auto-refresh.
- Hoặc throttle: 1 entry / admin / 5 min.

**Em recommend:**
- **Implement throttled self-audit:**
  - Log `admin.view_dashboard` chỉ khi admin **explicit click "Dashboard" nav link** (BE detect qua header `X-Dashboard-Refresh-Type: manual` vs `auto`)
  - Skip auto-refresh
- Hoặc đơn giản hơn: chỉ log lần đầu sau mỗi 5 phút per admin (throttle BE-side với in-memory Set)

**Anh decision:**
- ✅ **Em recommend (FE-side header + BE check, log manual only)** ← anh CHỌN
- ☐ BE throttle 5min/admin (simpler, FE không thay đổi)
- ☐ Log mọi refresh (accept noise)
- ☐ Drop BR-027-05 (UC update, không log dashboard view)
- ☐ Khác: ___

---

### Q4: Recent incidents thiếu Vital Alert

**UC Main Flow bước 4:** "Loại (Fall/SOS/**Vital Alert**), Bệnh nhân, Thời gian, Trạng thái"
**Code `getRecentIncidents`:** Chỉ query `fall_events` + `sos_events`. KHÔNG include `alerts` table (severity high/critical).

**Em recommend:**
- **Add Vital Alert (severity high/critical) vào recent incidents query:**
  - Filter: `alerts WHERE severity IN ('high', 'critical') AND resolved_at IS NULL`
  - Map type: `'VITAL_ALERT'`, status: `'PENDING'` hoặc `'ACKNOWLEDGED'` từ alerts.status
- Tổng list: fall + sos + vital alerts → sort desc theo timestamp → LIMIT 5
- UI badge phân biệt 3 loại

**Anh decision:**
- ✅ **Em recommend (add vital alerts high/critical unresolved)** ← anh CHỌN
- ☐ Keep current (chỉ fall + sos)
- ☐ Khác: ___

---

### Q5: Continuous Aggregates (`vitals_daily`, `vitals_hourly`) — UC outdated hay code missing?

**UC NFR-Perf:** "KPI queries sử dụng Continuous Aggregates (`vitals_daily`, `vitals_hourly`)"
**Code:** KHÔNG query vitals tables ở dashboard. Aggregation từ `alerts`, `sos_events`, `fall_events` (đã pre-aggregated counts).

**Phân tích:**
- UC027 KPIs hiện tại (users, devices, alerts today, SOS active, at-risk) **không cần** vitals raw data → không cần Continuous Aggregates.
- Có thể UC outdated: ngày xưa dashboard tính trung bình HR / SpO2 từ vitals → cần aggregates. Hiện code dashboard thuần count alerts.
- Nếu sau này có KPI "Average HR system" → mới cần `vitals_daily`.

**Em recommend:**
- **UC v2 drop "Continuous Aggregates" mention** (UC outdated)
- Note: nếu future có KPI cần aggregate vitals → revisit + add `vitals_daily/hourly` materialized view (TimescaleDB continuous aggregate). ADR record.
- Phase 4 KHÔNG thêm gì.

**Anh decision:**
- ✅ **Em recommend (UC drop mention, không cần aggregates)** ← anh CHỌN
- ☐ Add `vitals_daily/hourly` Phase 4 (UC outdated nhưng future-proof, ~4h SQL)
- ☐ Add new KPI cards dùng aggregates (vd "Avg HR last 24h", "Avg SpO2 last 24h") — scope creep
- ☐ Khác: ___

---

### Q7: 🔴 CRITICAL — `risk_level` enum bug propagated từ HEALTH module (NEW post-cross-repo-verify)

**Context:**
- Cross-repo verify (xem `HEALTH.md` Q7) phát hiện: DB schema `risk_scores.risk_level CHECK IN ('low','medium','critical')` — **3 values**.
- Admin BE (cả `health.service.js` + `dashboard.service.js`) vẫn dùng 4 levels với 'high' key.
- Mobile BE đã align 3 levels với threshold LOW 0-33 / MEDIUM 34-66 / **CRITICAL 67-100**.

**Dashboard-specific impact:**
- `getSystemKPI` line 74 query `risk_level = 'high'` → KPI `atRisk.high` luôn = 0 (silent fail).
- `getRiskDistribution` line 287 distribution object có `MODERATE` (legacy v1) + `HIGH` (luôn = 0) keys.
- `getAtRiskPatients` line 404 RISK_ORDER có `high: 1` key thừa.
- 3 enum representations inconsistent trong 1 file.
- UC027 v2 đã tạo (`UC027_Admin_Dashboard_v2.md`) trước khi phát hiện Q7 → phải regenerate sau fix.

**Em recommend (link D-HEA-07):**
- **Fix đồng bộ với HEALTH Q7** (1 commit cross-module):
  1. `getSystemKPI` line 74: drop `riskHigh` query, hoặc dồn vào `riskCritical` (nếu UC v2 keep 2 KPI cards "At-risk high" + "At-risk critical") → quyết định với UC v2.
  2. `getRiskDistribution` line 287: drop `HIGH` + `MODERATE` keys → `{ LOW, MEDIUM, CRITICAL, UNASSESSED }` (consistent với schema).
  3. `getRiskDistribution` line 293-294: drop mapping `MEDIUM → MODERATE`.
  4. `getAtRiskPatients` line 404: drop `high` key trong RISK_ORDER.
  5. Test mock data: `dashboard.service.test.js:134` mock `'moderate'` → `'medium'`, mock `'high'` → split `'medium'` hoặc `'critical'` theo score.
  6. UC027 v2: regenerate sau fix để reflect 3 levels.
- **Effort dashboard-specific**: ~45min (gộp vào D-HEA-07 sub-task #2 "Fix admin BE health.service.js" → mở rộng cover cả dashboard.service.js).
- **Tests dashboard**: ~30min add vào D-HEA-07 sub-task #5.
- **UC027 v2 regenerate**: ~10min, sau khi schema final.

**Anh decision (anh CONFIRM 2026-05-12):**
- ✅ **Em recommend: Fix đồng bộ với D-HEA-07 (cross-module commit)** ← anh CHỌN
- ☐ Tách task riêng D-DASH-07 (rủi ro fix không đồng bộ)
- ☐ Skip update DASHBOARD.md (giữ HEALTH.md primary)
- ☐ Khác: ___

---

### Q6: `usersTotal === usersActive` paste bug

**Code line 34-35:**
```js
prisma.users.count({ where: { role: 'user', is_active: true, deleted_at: null } }),  // usersTotal
prisma.users.count({ where: { role: 'user', is_active: true, deleted_at: null } }),  // usersActive — SAME!
```

→ `usersTotal` == `usersActive` luôn. UC nói "Tổng Users (Active/Locked)" → cần `total = all` (kể cả is_active=false) và `active = is_active true`.

**Em recommend:**
- **Phase 4 fix:**
  - `usersTotal`: `prisma.users.count({ where: { role: 'user', deleted_at: null } })` (drop `is_active: true`)
  - `usersActive`: keep current
  - UI sẽ hiển thị: Total 100 / Active 95 / Locked 5

**Anh decision:**
- ✅ **Em recommend (fix duplicate, total = all non-deleted)** ← anh CHỌN
- ☐ Keep current (UC drop "Locked" mention)
- ☐ Khác: ___

---

## 🆕Industry standard add-ons — anh's selection

**Keep (essential, low effort):**
- ✅ **#5 Comparison mode** — BE đã có `usersDelta`, `alertsDelta`, `sosDelta`. Chỉ cần FE wire up KPI card hiển thị % delta + tooltip "vs hôm qua". Không nhở scope (BE đã done).
- ✅ **#6 Drill-down deep links** — UC027 v1 đã có 6.a drill-down. Chỉ formalize URL pattern (`/users?role=user`, `/alerts?date=today&severity=critical`, etc) trong UC v2 cho FE implement.

**Drop (không cần thiết, tránh scope creep):**
- ❌ WebSocket/SSE real-time (Phase 5+ heavy)
- ❌ Customizable widget layout (UX nice-to-have)
- ❌ Date range selector global (UC v1 6.b chỉ áp dụng alerts-chart, giữ nguyên)
- ❌ Export dashboard PDF (scope nở)

---

## ❌ Features anh muốn DROP

_(anh add nếu có)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC027 Admin Dashboard | Major updates | `UC027_Admin_Dashboard_v2.md` |

Key changes UC v2:
- BR-027-03 ratify code behavior: "5 incidents unresolved gần nhất, không giới hạn thời gian"
- BR-027-05 self-audit clarify: chỉ log khi admin click nav (manual), skip auto-refresh
- NFR drop "Continuous Aggregates (`vitals_daily`, `vitals_hourly`)" — UC outdated
- NFR clarify caching: TTL 30s in-memory, apply 3 heavy endpoints
- Add UI mention 3 types incident: Fall/SOS/Vital Alert
- Add 2 endpoints bonus document: `/system-health`, `/kpi-sparklines`
- Section URL drill-down pattern (FE reference)
- Comparison mode delta % UI requirement (BE delta data đã có)

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task |
|---|---|---|
| Caching missing | Add (D-DASH-01) | `feat: dashboard cache TTL 30s (3 endpoints)` (~2h) |
| Recent incidents time scope | Ratify code (D-DASH-02) | UC v2 doc only |
| Self-audit missing | Manual-only log (D-DASH-03) | `feat: dashboard self-audit (header-based)` (~1h) |
| Vital Alert missing | Add (D-DASH-04) | `feat: include alerts high/critical recent-incidents` (~1.5h) |
| Continuous Aggregates | Drop UC mention (D-DASH-05) | None |
| usersTotal duplicate bug | Fix (D-DASH-06) | `fix: dashboard usersTotal count all non-deleted` (~30min) |
| Comparison mode FE wire | Add-on #5 | `feat: KPI card delta % display` (~1h FE) |
| Drill-down URL pattern | Add-on #6 | `docs: UC027 v2 drill-down URL spec` (done in UC v2) |
| **risk_level enum bug propagated (Q7)** | **Link D-HEA-07 cross-module fix (D-DASH-07)** | `fix(critical): dashboard.service.js risk_level 4→3 levels + drop MODERATE/HIGH legacy keys (gộp D-HEA-07)` (~45min dashboard-specific + UC027 v2 regenerate ~10min) | 🔴 CRITICAL (silent KPI fail) |

**Estimated Phase 4 effort:** ~7h (BE 5.75h + FE 1h + UC v2 regenerate ~10min) — tăng từ 6h sau khi add Q7

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-DASH-01 | Caching layer | **Add in-memory TTL 30s (3 heavy endpoints)** | NFR-Perf compliance; reuse CONFIG pattern; skip recent/at-risk cần fresh |
| D-DASH-02 | Recent incidents time scope | **All unresolved + LIMIT 5 (override UC)** | An toàn hơn: admin thấy mọi unresolved bao gồm cả cái cũ > 24h |
| D-DASH-03 | Self-audit scope | **Manual nav click only** | Tránh noise auto-refresh; FE header `X-Dashboard-Refresh-Type` distinguish |
| D-DASH-04 | Vital Alert include | **Add (Fall/SOS/Vital high+critical unresolved)** | UC đã mention, code thiếu — fix |
| D-DASH-05 | Continuous Aggregates | **Drop UC mention** | UC outdated; KPI hiện tại không cần vitals aggregates |
| D-DASH-06 | usersTotal duplicate | **Fix: total = all non-deleted, active = is_active** | Paste bug rõ ràng; UI có tác dụng Total/Active/Locked |
| D-DASH-07 | risk_level enum bug propagated | **Fix đồng bộ với D-HEA-07 (cross-module commit)** | Same root cause với HEALTH Q7 (DB 3 levels vs code 4 levels). Dashboard-specific changes: drop `MODERATE`/`HIGH` keys, drop `'high'` query, drop `RISK_ORDER.high`. UC027 v2 regenerate sau fix. |

### Add-ons selection

| # | Add-on | Decision |
|---|---|---|
| 1 | WebSocket/SSE real-time | ❌ Drop (Phase 5+) |
| 2 | Customizable widget layout | ❌ Drop |
| 3 | Date range global selector | ❌ Drop (giữ UC 6.b chỉ alerts-chart) |
| 4 | Export dashboard PDF | ❌ Drop |
| 5 | Comparison mode delta % | ✅ **Keep** (BE đã có data, chỉ FE wire) |
| 6 | Drill-down deep links | ✅ **Keep** (formalize URL pattern UC v2) |

---

## Cross-references

- UC027 cũ: `Resources/UC/Admin/UC027_Admin_Dashboard.md`
- UC027 v2 (đã generate, cần regenerate sau Q7 fix): `Resources/UC/Admin/UC027_Admin_Dashboard_v2.md`
- Phase 1 audit: M02 Routes, M04 Services
- CONFIG D-CFG-03: in-memory cache pattern → reuse cho Q1
- LOGS D-LOGS-01: self-audit pattern → consistent với Q3
- UC028 Health Overview: at-risk patients có thể share logic với UC027
- UC029 Emergency Management: recent incidents drill-down
- **HEALTH Q7 (D-HEA-07)**: same root cause, fix đồng bộ cross-module — see `HEALTH.md` Q7 section
- **Cross-repo source-of-truth (Q7)**: `health_system/backend/app/services/risk_inference_service.py:64-72` (Mobile BE 3 levels với threshold 0-33/34-66/67-100)
- **DB schema canonical**: `PM_REVIEW/SQL SCRIPTS/06_create_tables_ai_analytics.sql:30` (CHECK 3 values)
