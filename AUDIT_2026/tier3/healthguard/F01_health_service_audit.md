# Deep-dive: F01 — health.service.js (HG-001 + Q7 + D-HEA-01 god-service)

**File:** `HealthGuard/backend/src/services/health.service.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 1 (HG-001 + Q7 cluster)

## Scope

Single file `health.service.js` (~635 LoC, 6 public methods):
- `getSummary()` — lines 17-85. Summary cards cho Admin Dashboard.
- `getThresholdAlerts(params)` — lines 90-350. List alerts 24h với filter severity/alertType/dateRange + render metric display cho 7 alert_type.
- `getRiskDistribution(params)` — lines 355-435. Donut chart distribution + list users theo risk_level.
- `getVitalsTrends()` — lines 440-490. Aggregate vitals 30d cho chart.
- `getPatientHealthDetail(patientId, adminId, ipAddress, userAgent)` — lines 495-620. Drill-down per-patient với medical-data audit log.
- `processNewVital(vitalData, deviceId, timestamp)` — lines 625-634. Thin wrapper gọi VitalAlertService.processVitalForAlerts.

**Out of scope:** Consumer-side UI rendering (covered F09 HealthOverviewPage + F12 ThresholdAlertsTable), VitalAlertService internals (M04 Phase 1 macro), Continuous Aggregates view setup (M06 + F14).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 0/3 | HG-001 active bug (lines 177-181, 353-358 hardcode status='unread'). Q7 filter 'high' never matches (line 46). D-HEA-01 groupBy `by:['time']` no aggregate (lines 479, 566). D-HEA-06 take:288 semantic wrong (line 565). 4 correctness issues trong 1 file. |
| Readability | 2/3 | Section divider comments per method đẹp. Nhưng `getThresholdAlerts` 260 LoC với switch-case 7 branches inline — hard to scan. File 635 LoC god-service. |
| Architecture | 1/3 | God-service: 6 responsibilities ghép (summary + alerts + risk distribution + trends + patient detail + vital processor wrapper). `processNewVital` thin wrapper thêm indirection không cần thiết. Vietnamese message parse `message.includes('SpO')` coupling với template text. |
| Security | 2/3 | Audit log `admin.view_patient_health` đúng BR-028-04. Prisma parameterized queries. Gap: `dateRange='all'` query 5+ năm data → DoS vector; debug console.log leak filter state line 311-324. |
| Performance | 1/3 | D-HEA-01 raw vitals.groupBy thay vì CA → load 2.5M rows vào RAM với 30d×86400s. `.catch(() => 0)` silent fail mask DB errors. `getPatientHealthDetail` 4 queries sequential. |
| **Total** | **6/15** | Band: **🔴 Critical** (Total ≤6 auto-Critical per framework v1 band mapping) |

**Auto-Critical trigger:** Total 6/15 ≤ 6 → Band Critical per framework v1 (`00_audit_framework.md` band mapping "Critical 0-6"). File này là highest-priority fix target của toàn repo HealthGuard.

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M04 findings (all confirmed + escalate):**

1. ✅ **HG-001 hardcode status='unread'** — confirmed lines 177-181 comment admit schema gap, lines 353-358 hardcode literal. Revise severity: Phase 1 M04 đề Priority P1 (bug tracker), Phase 3 escalate P0 cùng với Q7 vì user-facing impact trực tiếp (admin dashboard filter broken cho mọi user).
2. ✅ **Q7 filter line 46** — confirmed `rs.risk_level IN ('high', 'critical')` trong raw SQL. 'high' không match DB (per F02 Q7 INSERT FAIL) → `highRiskCount` luôn 0 cho users score 67-84.
3. ✅ **D-HEA-01 groupBy bug** — confirmed lines 479-490 (getVitalsTrends) + lines 566-576 (getPatientHealthDetail 7d) dùng `by: ['time']` → raw timestamp, không aggregate.
4. ✅ **D-HEA-06 take:288 semantic** — confirmed line 565 `take: 288` với `orderBy time desc` → 288 sec ~5 phút (không phải 24h).
5. ✅ **Outdated header comment** — confirmed lines 7-10 declare `BR-028-06: LOW/MEDIUM/HIGH/CRITICAL (4 levels)` sai per D-HEA-07.
6. ✅ **getThresholdAlerts god-method** — confirmed ~260 LoC với 7-branch switch-case inline.
7. ✅ **Silent catch** — confirmed 8 chỗ `.catch(() => 0)` / `.catch(() => [])` trong getSummary + getRiskDistribution.

**Phase 3 new findings (beyond Phase 1 macro):**

8. ⚠️ **Debug console.log leak** — lines 311-324 gồm `console.log('Alert query debug:', { ...whereClause })` prints full query state vào prod log. Priority P2.
9. ⚠️ **`alertType` filter no-op branch** — lines 157-163 comment `"Nếu không có alertType → lấy tất cả"` + câu `if (alertType) whereClause.alert_type = alertType;` → OK nhưng code branch duplicate sau comment misleading. Priority P3.
10. ⚠️ **`dateRange='all'` query 2020+** — line 210 `startDate = new Date('2020-01-01')` → 5+ năm scan khi admin click "All time" filter. Với 10M alerts → full table scan. Priority P2.
11. ⚠️ **`formatAlertMetric` logic 110 LoC inline** — lines 200-305 switch-case 7 alert_type × 4-5 data shape branch. Priority P2 extract helper.
12. ⚠️ **`getPatientHealthDetail` sequential queries** — lines 525-599: latestVitals (567) → vitals24h (570) → vitals7dGrouped (583) → alerts7dRaw (592). 4 queries serial, 3/4 có thể Promise.all (không dependent).
13. ⚠️ **`processNewVital` dead wrapper** — lines 625-634 thin wrapper gọi VitalAlertService. 0 grep match trong codebase cho `healthService.processNewVital`. Dead code candidate — verify Phase 4 remove.
14. ⚠️ **Vietnamese literal parse** — lines 241-305 `message.includes('SpO')`, `message.includes('Nhịp tim')`, v.v. Nếu alert message template đổi → detection broken silently. Priority P2 — dùng `alert.data.metric` field enum thay vì parse text.
15. ⚠️ **`alertType === 'sos_triggered'`** (line 201) không có SOS alert record thật (SOS trong `sos_events` table, không phải `alerts`) — branch unreachable? Verify Phase 4 grep alert_type enum trong alerts.create.

### Correctness (0/3) — 🚨 Critical

**⚠️ P0 — HG-001 active bug** (lines 177-181, 353-358):

Root cause: admin code đọc spec cũ, comment explicit `// NOTE: Status filter disabled - schema không có read_at, acknowledged_at, expires_at`. Service hardcode `let alertStatus = 'unread';` cho mọi alert. Hệ quả:

- Admin dashboard "Cảnh báo Ngưỡng" tab — mọi row status = 'unread' → filter read/unread broken.
- FE `pages/admin/HealthOverviewPage.jsx` + `components/health/ThresholdAlertsTable.jsx` render `status='unread'` → admin không biết caregiver đã read alert qua mobile app.

Fix (per HG-001 tracker + D-HEA-04 drift):

- Schema `notification_reads(user_id, alert_id, read_at)` là source of truth per-user (Mobile BE pivot).
- Service pivot: JOIN `notification_reads` → aggregate read state per alert (vd: "read by any linked caregiver" hay "read by ≥50% caregivers"?). UC v2 cần confirm aggregation rule.
- Drop column `alerts.read_at` (zombie per -1.A D3, M06 flag).

Test required: mock `notification_reads` row → verify status='read'.

**⚠️ P0 — Q7 filter** (line 46):

Raw SQL trong `getSummary` dùng filter 4-level enum `rs.risk_level IN ('high', 'critical')`. 'high' không match DB CHECK (per F02) → `highRiskCount` luôn = count users risk_level='critical'.

Fix: drop `'high'` → `IN ('critical')`. Cross-ref F02 Q7 cùng commit.

**⚠️ P1 — `getRiskDistribution` distribution object** (line 399-419):

- Khai `distribution = { low: 0, medium: 0, high: 0, critical: 0, unassessed: 0 }` với key `high`.
- Loop qua latestRisks (DISTINCT ON (user_id)) → `distribution[level]++` với `level.toLowerCase()`.
- Nếu DB có row `risk_level='medium'` (post-F02 fix) → distribution.medium tăng. OK.
- Nhưng `distribution.high` LUÔN = 0 sau F02 fix (không còn user 'high' level).
- FE render donut chart với 5 segments, segment 'high' luôn 0 → visual confuse.
- Fix: drop `high` key khỏi distribution object, FE chart render 4 segments (low/medium/critical/unassessed).
- Priority P1 cùng group với Q7.

**⚠️ P1 — D-HEA-01 groupBy bug** (lines 479-490, 566-576):

2 chỗ dùng `prisma.vitals.groupBy({ by: ['time'] })`:

- `getVitalsTrends` line 479: aggregate 30 ngày system-wide.
- `getPatientHealthDetail` line 566: aggregate 7 ngày cho 1 patient.

Bug: `by: ['time']` = group theo TIMESTAMP NGUYÊN (1 row/sec). Mỗi group chỉ có 1 row → KHÔNG aggregate gì cả. Sau đó JS loop aggregate by day (line 486-495, 593-604) → load toàn bộ rows vào RAM + compute client-side.

Với 30 ngày × 100 devices × 86400 rows/day = 2.6 tỷ rows tiềm năng (worst case), realistic ~2.5M rows với 1 device active. Memory explosion + slow response.

Fix (per D-HEA-01):

- Dùng `prisma.$queryRaw` với TimescaleDB Continuous Aggregates đã có sẵn:
  - 30d trend → `vitals_daily` CA (1 row/ngày/device).
  - 7d trend → `vitals_hourly` CA (24 rows/ngày/device).
  - 24h trend → `vitals_5min` CA (288 rows/ngày/device).
- Update file header comment line 9 `(không có Continuous Aggregates)` → `(dùng vitals_5min / hourly / daily CA)`.
- F14 Prisma audit cover view declaration workaround.

**⚠️ P1 — D-HEA-06 take:288 semantic** (line 565):

- `vitals24h` variable name claim 24h window.
- `take: 288` với `orderBy time desc` + raw `vitals` table → 288 sec từ timestamp mới nhất = ~5 phút.
- FE chart hiển thị "24h" với 5 phút data.

Fix (combine với D-HEA-01):

- Refactor dùng `vitals_5min` CA: 288 rows = 24h × 12 buckets/h đúng semantic.
- Comment inline: `// take: 288 = 24h × 12 buckets/5min from vitals_5min CA`.

**⚠️ P2 — Outdated header comment** (lines 7-10):

- Declare `BR-028-06: Risk score phân loại: LOW (0-33), MEDIUM (34-66), HIGH (67-84), CRITICAL (85-100)` — 4 levels với threshold OLD.
- Per D-HEA-07: 3 levels (LOW 0-33 / MEDIUM 34-66 / CRITICAL 67-100).
- Fix cùng commit với Q7.

**⚠️ P3 — `alertType === 'sos_triggered'` branch** (lines 201-205):

- SOS events lưu `sos_events` table, không `alerts`.
- Grep `alerts.create` trong codebase cho `alert_type: 'sos_triggered'`: 1 match trong `emergency.service.js` (verify Phase 3 F-next wave).
- Nếu alerts table thực tế có `alert_type='sos_triggered'` → branch OK. Nếu không → dead code.
- Verify Phase 4 grep production alerts table cho SOS type.

### Readability (2/3)

- ✓ Section comments Vietnamese rõ cho 6 methods (`// ========== getSummary ==========`, etc.).
- ✓ Variable naming tự explain (`totalPatients`, `highRiskPatients`, `abnormalVitalsPatients`, `vitals24h`, `vitals7d`).
- ✓ JSDoc trên mỗi method declare BR reference (BR-028-01, BR-028-04, v.v.) — traceable.
- ⚠️ **P2 — File 635 LoC god-service** — 6 responsibilities lớn ghép. Steering + framework readability rubric `File > 500 lines = split candidate`. Priority P2 — Phase 5+ split:
  - `health-overview.service.js` — getSummary, getVitalsTrends.
  - `threshold-alerts.service.js` — getThresholdAlerts.
  - `risk-distribution.service.js` — getRiskDistribution.
  - `patient-detail.service.js` — getPatientHealthDetail + processNewVital.
- ⚠️ **P2 — `getThresholdAlerts` 260 LoC** — bao gồm date range calc (25 LoC), where clause build (25 LoC), alerts query + count (25 LoC), debug log (15 LoC), format alert metric (110 LoC), return (10 LoC). Extract helpers:
  - `_computeDateRange(dateRange, custom...)` → 25 LoC.
  - `_formatAlertMetric(alert, thresholds)` → 110 LoC.
  - Main method remaining ~90 LoC, scannable.
- ⚠️ **P3 — Emoji trong code** (line 311 `console.log` literal có emoji prefix) — rule cấm.

### Architecture (1/3)

- ⚠️ **P2 — God-service 6 responsibilities** (duplicate với Readability P2).
- ⚠️ **P2 — `processNewVital` thin wrapper** (lines 625-634): 9 LoC wrap `VitalAlertService.processVitalForAlerts(vitalData, deviceId, timestamp)`. Grep codebase: 0 caller gọi `healthService.processNewVital`. Dead code candidate — Phase 4 verify + remove.
- ⚠️ **P2 — Vietnamese message parse business logic** (lines 241-305): `if (message.includes('SpO') ...) { metric = 'SpO₂'; ... }` — parse text template để phân loại. Nếu Mobile BE đổi message template → admin detection broken silently. Dùng `alert.data.metric` enum field (đã có trong data shape per code line 215 `alert.data && alert.data.vitals`). Priority P2.
- ⚠️ **P3 — `distribution` object literal hardcode** (line 399) — `{ low: 0, medium: 0, high: 0, critical: 0, unassessed: 0 }`. Post-F02 fix cần drop 'high'. Priority P3 cùng group với Q7.
- ✓ Service đúng layer — không import Express req/res, không touch HTTP concern.
- ✓ `Promise.all` trong getSummary (line 22-55) — parallel execution.

### Security (2/3)

- ✓ **Audit log BR-028-04** (lines 602-614): `getPatientHealthDetail` insert `audit_logs` row với action='admin.view_patient_health', resource_id=patientId, ip + user_agent. Medical-data access traceable.
- ✓ Prisma parameterized queries (`findUnique`, `findFirst`, `findMany`, `$queryRaw` với tagged template).
- ✓ Không log sensitive data raw trong console.log (ngoại trừ P2 debug leak).
- ⚠️ **P2 — Debug log leak query state** (lines 311-324):
  - `console.log` prints toàn bộ filter params + DB stats.
  - Production log sẽ chứa query pattern admin thực hiện. Không direct data leak nhưng operational behavior visible.
  - Priority P2 — gate bằng `if (process.env.NODE_ENV === 'development')` hoặc xóa.
- ⚠️ **P2 — `dateRange='all'` DoS vector** (line 210):
  - Admin click filter "All time" → `startDate = '2020-01-01'` → query 5+ năm alerts data.
  - Với DB ~10M rows alerts → full table scan, response time 10+ seconds, connection pool pressure.
  - Mitigation: healthLimiter 60/min per-IP + admin-only route.
  - Priority P2 — hạ `'all'` xuống 1 năm hoặc forced pagination.
- ✓ Input sanitize: `search` param đi qua `validate()` middleware M05 (route-level) → qua `sanitize-html` → Prisma `contains: search` parameterized.
- ⚠️ **P3 — `getRiskDistribution` không audit log** — per BR-028-04 chỉ `getPatientHealthDetail` log. `getRiskDistribution` liệt kê patient names + phone trong `patients` array (line 424) → admin có thể bulk export qua loop pagination. Verify UC028 scope nếu cần audit. Priority P3.

### Performance (1/3)

- ⚠️ **P1 — D-HEA-01 raw groupBy thay vì CA** (duplicate với Correctness finding). Impact: 2.5M rows/request, 10+ second response với 30d data, connection pool burst.
- ⚠️ **P2 — Silent fail `.catch(() => 0)`** (8 chỗ trong getSummary + getRiskDistribution):
  - Mask DB errors thành empty result.
  - Admin dashboard show "0 total patients, 0 alerts today" → operational invisibility cho DB outage.
  - Priority P2 — replace `logger.warn('getSummary.totalPatients failed', err.message)` + fallback 0.
- ⚠️ **P2 — `getPatientHealthDetail` 4 queries sequential** (lines 525-599):
  - latestVitals → vitals24h → vitals7dGrouped → alerts7dRaw.
  - latestVitals phải chạy trước (compute `referenceTime` từ timestamp nó).
  - Nhưng vitals24h + vitals7dGrouped + alerts7dRaw đều depend trên `referenceTime` — có thể Promise.all cả 3.
  - Priority P2 — Promise.all wrap 3 queries sau latestVitals, ~-400ms response time.
- ⚠️ **P3 — `getRiskDistribution` sort in JS** (line 421): loop `allUsers.sort((a,b) => ...)` với RISK_ORDER map — O(N log N) với N = all active users. DB ORDER BY nhanh hơn. Priority P3 Phase 5+.
- ✓ Indexes exploited (user_id + calculated_at DESC).
- ✓ Prisma `select` projection giảm payload.

## Recommended actions (Phase 4)

### P0 CRITICAL — commit đầu (cluster với F02 + drift D-HEA-07)

- [ ] **P0** — Fix Q7 line 46 + 405-419: `IN ('critical')` only + drop 'high' key trong distribution object (~15 min, combine F02 fix).
- [ ] **P0** — Fix HG-001 lines 177-181, 353-358: pivot `alerts` query JOIN `notification_reads` + aggregate read state. Update header comment sync BR-028-04. Drop `alerts.read_at` column (depend F14 Prisma). Test + manual verify (~4h per HG-001 tracker).
- [ ] **P0** — Update header comment lines 7-10: 3 levels threshold (~2 min).

### P1 — cùng sprint Phase 4

- [ ] **P1** — D-HEA-01: Refactor `getVitalsTrends` (line 479) dùng `vitals_daily` CA + `getPatientHealthDetail` 7d (line 566) dùng `vitals_hourly` CA. Remove JS-side day aggregate loop (~2h).
- [ ] **P1** — D-HEA-06: Refactor `vitals24h` (line 558-565) dùng `vitals_5min` CA với 288 buckets (~30 min, combine D-HEA-01).
- [ ] **P1** — Promise.all 3 queries sau latestVitals trong `getPatientHealthDetail` (~30 min).

### P2 — sprint tiếp

- [ ] **P2** — Extract `_formatAlertMetric(alert, thresholds)` helper (110 LoC → separate file) (~2h).
- [ ] **P2** — Extract `_computeDateRange(dateRange, custom...)` helper (~30 min).
- [ ] **P2** — Replace `message.includes('SpO')` parse logic bằng `alert.data.metric` enum field (~1h, depend Mobile BE contract verify).
- [ ] **P2** — Replace `.catch(() => 0)` silent fail bằng logger.warn + structured error context (~1h, 8 chỗ).
- [ ] **P2** — Remove debug console.log lines 311-324 hoặc gate NODE_ENV=development (~5 min).
- [ ] **P2** — Limit `dateRange='all'` về 1 năm max hoặc forced pagination (~15 min).

### P3 — cleanup

- [ ] **P3** — Verify `processNewVital` wrapper có caller không; nếu không → remove (~5 min).
- [ ] **P3** — Verify `alert_type='sos_triggered'` có alert record thật không; nếu không → remove branch (~5 min).
- [ ] **P3** — Replace emoji trong console.log (~5 min).
- [ ] **P3** — Add audit log cho `getRiskDistribution` bulk list (cân nhắc, ~15 min).
- [ ] **P3 (Phase 5+)** — Split file thành 4 sub-services (~6h architectural refactor).

## Out of scope (defer)

- FE consumer rendering (HealthOverviewPage god-component) — F09 deep-dive scope.
- ThresholdAlertsTable UI state — F12 deep-dive scope.
- TimescaleDB CA view declaration trong Prisma — F14 deep-dive scope.
- Alert acknowledge workflow (schema fields read_at/acknowledged_at/expires_at) — defer Phase 5+ per drift D-HEA-04.
- Cohort analysis (age/gender/condition-specific risk) — UC research feature Phase 5+.
- PDF report export — drop per drift decision.
- Real-time WebSocket alert push — overlap INTERNAL emit-alert (covered M02).

## Cross-references

- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — 4 findings flagged (HG-001, Q7, D-HEA-01, D-HEA-06) — tất cả confirmed ở Phase 3.
- Phase 1 M06 audit: [tier2/healthguard/M06_prisma_schema_audit.md](../../tier2/healthguard/M06_prisma_schema_audit.md) — `alerts.read_at` zombie column, drop cùng HG-001 fix.
- Phase 1 M08 audit: [tier2/healthguard/M08_tests_audit.md](../../tier2/healthguard/M08_tests_audit.md) — test mock data Q7 outdated flag.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-01/04/05/06/07 — full coverage matrix.
- HG-001 bug: [BUGS/HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — root cause confirmed ở service layer.
- F02 `risk-calculator.service.js` deep-dive — Q7 INSERT FAIL source, consumer filter ở F01 phải fix cùng commit.
- F14 Prisma CA view (Wave 4) — prerequisites cho D-HEA-01 service refactor.
- Cross-repo Mobile BE truth: `health_system/backend/app/services/risk_inference_service.py:64-72` — 3 levels.
- Canonical DB: `PM_REVIEW/SQL SCRIPTS/04_create_tables_timeseries.sql:106-173` CA + `06_create_tables_ai_analytics.sql:30` risk_level CHECK.
- Caller: `controllers/health.controller.js` — HTTP layer delegate xuống F01 methods.
- Precedent format: [tier3/healthguard-model-api/F2_health_service_audit.md](../healthguard-model-api/F2_health_service_audit.md) — compare health service deep-dive pattern.

---

**Verdict:** File này là highest-priority fix target toàn repo HealthGuard.

- Total 6/15 = Critical band.
- 3 P0 findings (HG-001 + Q7 + header comment) + 3 P1 findings (D-HEA-01 + D-HEA-06 + Promise.all) + 7 P2 + 4 P3.
- Phase 4 effort estimate: P0 = ~4.5h (HG-001 4h + Q7 15min + comment 2min), P1 = ~3h (D-HEA-01 + D-HEA-06 + Promise.all), P2 = ~6h cleanup — ~13-15h total cho 1 file duy nhất.
- Fix unlock: M04 Services band Needs-attention → Healthy. M06 Prisma band Healthy (sau drop read_at) → Healthy consistent. HG-001 resolve. Q7 resolve cross-service với F02.
- Phase 5+ split recommendation: không blocking, nhưng god-service 635 LoC sẽ cản maintenance khi thêm UC mới (UC028 v2 extend features).
