# Intent Drift Review — `HealthGuard / HEALTH`

**Status:** � Confirmed v3 (Q1-Q6 anh chọn theo em recommend; Q7 NEW post-cross-repo-verify 2026-05-12 — risk_level enum mismatch CRITICAL bug, anh confirm 3 levels theo Mobile BE threshold; 5 add-ons drop)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** HEALTH (Admin giám sát sức khỏe & rủi ro toàn hệ thống)
**Related UCs (old):** UC028 Health Overview
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 7 (2 BR violations + 2 code bugs CRITICAL + 4 enhancement/missing) — Q7 cross-repo enum mismatch

---

## 🎯 Mục tiêu

Capture intent cho HEALTH module — admin giám sát toàn bộ patient health data + risk scores. Chú ý: scope **admin overview/aggregate**, không phải user-self vitals (UC006/UC016).

---

## 📚 UC028 cũ summary (memory aid)

- **Actor:** Admin only
- **Main:** Summary cards + Tab "Cảnh báo Ngưỡng" + Tab "Phân bố Risk" + Vitals trends 30d
- **Alt 6.a:** Patient detail (vitals 24h/7d, risk trend 30d, alert history)
- **Alt 6.b:** Filter (metric, severity, time range, risk level)
- **Alt 6.c:** Export CSV
- **BR-028-01:** 🔴 BẮT BUỘC dùng Continuous Aggregates (`vitals_5min`/`hourly`/`daily`), KHÔNG query raw `vitals`
- **BR-028-04:** Audit log `admin.view_patient_health` mọi lần view detail
- **BR-028-06:** Risk levels: LOW (0-33), MEDIUM (34-66), HIGH (67-84), CRITICAL (85-100)
- **BR-028-07:** Risk trend (↑↓→) so sánh score gần nhất với lần trước

---

## 🔧 Code state — verified

### Routes (`health.routes.js`) — 7 endpoints

```
authenticate + requireAdmin + healthLimiter (60/min)

GET  /summary                     Summary cards (totalPatients, activeAlerts, criticalPatients, averageVitals)
GET  /threshold-alerts            24h alerts paginated + search + filter severity
GET  /risk-distribution           Donut chart data + risk-cao patient list
GET  /vitals-trends               30 ngày vitals trends                      ⚠️ BR-028-01 violation
GET  /patient/:patientId          Detail vitals + risk + history (Alt 6.a)   ✅ audit log
GET  /export-alerts-csv           Export alerts CSV
GET  /export-risk-csv             Export risk patients CSV
```

### Service findings (verified)

**✅ Aligned with UC:**
- BR-028-04: Audit log `admin.view_patient_health` line 616 (verify ✓)
- BR-028-06: Risk levels query filter `('high', 'critical')` (verify ✓)
- Latest risk per user query đúng pattern (DISTINCT ON line 392)
- Patient detail enrichment: vitals + risk_scores + device latest (line 528-535)
- Search bệnh nhân (Alt 6.b partial) trong threshold-alerts ✓
- Export CSV cho alerts + risk ✓

**🔴 BR violations + Code bugs (post-verify 2026-05-12):**

1. **BR-028-01 + Code logic bug — `vitals.groupBy({by:['time']})` tại 2 chỗ:**
   - **Chỗ 1**: `getVitalsTrends` line 479-490 (UC028 Main flow vitals trends 30d)
   - **Chỗ 2**: `getPatientHealthDetail` line 568-576 (UC028 Alt 6.a patient vitals 7d)
   - **Bug:** `by: ['time']` group theo TIMESTAMP NGUYÊN (vitals raw = 1 row/sec) → mỗi group chỉ có 1 row → KHÔNG AGGREGATE gì cả. Sau đó JS loop aggregate by day → **memory explosion + slow + crash risk** với data thật.
   - **Comment dev MISLEADING:** Line 474 nói "Dùng groupBy theo ngày" — sai, code `by: ['time']` KHÔNG phải theo ngày.
   - **Comment tiêu đề file OUTDATED:** Line 7 declare "(không có Continuous Aggregates)" — sai với SQL canonical 04_create_tables_timeseries.sql:106-173 đã setup `vitals_5min/hourly/daily`.
   - UC explicit ràng buộc dùng `vitals_5min`/`vitals_hourly`/`vitals_daily`
   - → **Severity: 🟠 Bug + Perf + BR (không chỉ perf)**

2. **BR-028-07 — Risk trend (↑↓→) calculation MISSING:**
   - Em không thấy code tính trend direction
   - `currentRisk` (line 632-636) chỉ trả latest score, không có comparison với previous
   - UC nói so sánh score gần nhất vs lần trước → emit ↑/↓/→ flag

3. **Magic number + misleading variable name (`take: 288`):**
   - Line 558-565: `vitals24h = await prisma.vitals.findMany({..., take: 288})`
   - Vitals raw = 1 row/sec → 24h = 86400 rows. `take: 288` với `orderBy: time desc` = chỉ ~5 phút gần nhất, KHÔNG phải 24h.
   - Variable name `vitals24h` SAI semantic. FE hiển thị chart "24h" sẽ thiếu dữ liệu.
   - Magic number không có comment giải thích.

**🔴 CROSS-REPO finding CRITICAL (post-cross-repo-verify 2026-05-12):**

4. **`risk_level` enum mismatch — PRODUCTION TIME BOMB:**
   - **DB schema canonical** (`06_create_tables_ai_analytics.sql:30`): CHECK `risk_level IN ('low','medium','critical')` — **3 values**
   - **Mobile BE source-of-truth** (`risk_inference_service.py:64-72`): 3 levels với threshold LOW 0-33 / MEDIUM 34-66 / **CRITICAL 67-100**
   - **Model API** (`gemini_explainer.py:69-72`): 4 values dictionary (legacy)
   - **Admin BE có 4 levels (VI PHẠM)**:
     - `risk-calculator.service.js:155-159`: tính `risk_level='high'` cho score 67-84 → **INSERT FAIL** (CHECK constraint violation)
     - `health.service.js:46`: filter `IN ('high','critical')` → 'high' không trả row → admin dashboard `highRiskCount` BUG
     - `health.service.js:405`: distribution `{low,medium,high,critical,unassessed}` → `high` luôn = 0
   - **UC028 BR-028-06**: 4 levels với threshold OLD (67-84 high, 85-100 critical) — OUTDATED
   - **Tests**: mock `'high'` + `'moderate'` (`dashboard.service.test.js:134`) — SAI schema
   - **Index** `08_create_indexes.sql:104`: `WHERE risk_level IN ('high','critical')` — wasted (no row match 'high')
   - → **Severity: � CRITICAL** — risk-calculator INSERT FAIL silently, dashboard count sai, cross-repo 4 services out of sync.

**� Other observations (post-verify):**

- **Status filter disabled** (service line 180): comment "schema không có read_at, acknowledged_at, expires_at"
- **Risk level filter cho threshold-alerts:** code chỉ có `severity` filter (vitals threshold), KHÔNG có `risk_level` filter (ML model output). UC Alt 6.b conflate 2 concepts khác.
- **PHI:** Patient detail expose vitals + risk + email + device. Đã có audit log ✅ nhưng UC không có rule mask cho admin (admin có quyền xem)
- **Swagger drift:** `routes/health.routes.js:50-52` document `averageVitals` field trong `/summary` response, nhưng `service.js:61-68` KHÔNG trả field này. → Swagger out of sync.
- **Error handling inconsistent:** `getSummary` có `.catch(() => 0)` per-query, `getRiskDistribution` có outer try-catch, nhưng `getPatientHealthDetail` (line 549-565) KHÔNG có catch → DB error → 500 leak stack trace.
- **Comment SQL canonical line 56 OUTDATED:** "backfill thành medium" — conflict với Mobile BE threshold (CRITICAL 67-100). Cần verify data thực tế + backfill lại theo score thật.

---

## 💬 Anh react block

> 7 câu (Q7 add sau post-cross-repo-verify 2026-05-12) — module phức tạp với 1 CRITICAL bug cross-repo (risk_level enum) + 4 findings phụ.

---

### Q1: 🔴 BR-028-01 violation — Continuous Aggregates vs raw vitals query

**Code current:**
```js
// service line 476-479
async getVitalsTrends() {
  const raw = await prisma.vitals.groupBy({  // raw vitals scan
    by: ['date_trunc('day', created_at)'],
    ...
  });
}
```

**UC ràng buộc:** "BR-028-01: Dữ liệu vitals tổng quan **BẮT BUỘC** lấy từ Continuous Aggregates (`vitals_5min`, `vitals_hourly`, `vitals_daily`), KHÔNG ĐƯỢC query trực tiếp bảng `vitals`."

**Em cần verify:**
- TimescaleDB có set up CA chưa? Hay chỉ raw `vitals` table?
- Em check: `Iot_Simulator_clean/datasets/01_vitals/...` có schema CA không?

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| **A. Implement CA + use** | Tuân BR-028-01, fast (~10ms vs ~500ms với 100k rows) | Cần verify CA setup; nếu chưa có cần create migration |
| **B. Keep raw query, drop BR-028-01** | Simpler, no migration | Performance bottleneck với data lớn; mất scope spec |
| **C. Hybrid:** raw query với indexes optimization | Middle ground | Vẫn slow ở scale, không tận dụng TimescaleDB |

**Em recommend:**
- **Phase 0.5 verify CA setup** (em đọc SQL canonical + migrations)
- Nếu CA exists: **Phase 4 fix code use CA** (~2h refactor)
- Nếu CA missing: **Defer Phase 5+** (drop BR-028-01 từ UC v2 hoặc mark "Phase 5+ requirement"), Phase 4 thêm index `vitals(created_at)` nếu chưa có

**Em verified 2026-05-12:** CA setup **ĐÃ SET UP ĐỦ** trong SQL canonical:
- `PM_REVIEW/SQL SCRIPTS/04_create_tables_timeseries.sql:106-173` — cả `vitals_5min`, `vitals_hourly`, `vitals_daily` Materialized View
- `PM_REVIEW/SQL SCRIPTS/09_create_policies.sql:72-92` — auto-refresh policies (5min/1h/1d)
- `vitals` hypertable với 7-day chunks (TimescaleDB)

→ **Code admin BE đang VI PHẠM BR-028-01** vì CA sẵn sàng. Phase 4 task = refactor service.

**Anh decision:**
- ✅ **Em recommend (verify CA → fix code)** ← anh CHỌN; CA verified EXISTS, Phase 4 refactor `~3h` (fix 2 chỗ: line 479 + line 568)
- ☐ Drop BR-028-01 hoàn toàn từ UC v2 (raw query OK với pagination)
- ☐ Phase 4 add CA migration + refactor code (~6h cross-DB-schema)
- ☐ Khác: ___

**Phase 4 sub-tasks (post-verify):**
1. Refactor `getVitalsTrends` (line 479) → use `vitals_daily` CA cho 30d range (~1h)
2. Refactor `getPatientHealthDetail` vitals 7d (line 568) → use `vitals_hourly` CA (~1h)
3. Sửa comment outdated line 5-9 service → remove "(không có Continuous Aggregates)" + add ADR ref nếu có (~5min)
4. Verify CA refresh policies active (`09_create_policies.sql:72-92`) production (~30min)

---

### Q2: BR-028-07 Risk trend (↑↓→) — implement hay drop?

**UC ràng buộc:** "Xu hướng risk (↑↓→) tính bằng so sánh score lần đánh giá gần nhất với lần trước đó"

**Code state:** Em không thấy logic tính trend trong service. Patient detail có `currentRisk` (latest only) nhưng không có `riskTrend` field.

**Implementation options:**
- **A. BE compute trend:** Service query 2 latest scores per user, compare, emit `trend: 'up'|'down'|'stable'` field
- **B. FE compute từ risk history:** BE expose risk history endpoint, FE tính trend
- **C. Drop từ UC v2:** Trend không essential cho admin overview

**Em recommend:**
- **Option A — BE compute** (~1h): consistent với BE logic patterns existing, FE chỉ render
- Add to:
  - `GET /summary` summary cards (overall trend %)
  - `GET /risk-distribution` bảng risk-cao (per patient trend column)
  - `GET /patient/:patientId` detail (trend display)
- Field name: `riskTrend: 'up' | 'down' | 'stable'` + `riskDelta: number` (score change)

**Anh decision:**
- ✅ **Em recommend (BE compute trend, ~1h)** ← anh CHỌN
- ☐ FE compute (BE expose history endpoint)
- ☐ Drop từ UC v2 (không essential)
- ☐ Khác: ___

---

### Q3: Severity vs Risk Level filter conflation

**UC Alt 6.b:** "Filter: Loại chỉ số (HR/SpO₂/BP/Temp), Mức độ (Warning/Critical), Khoảng thời gian, Risk Level (LOW/MEDIUM/HIGH/CRITICAL)"

**Code current:** `threshold-alerts` chỉ có `severity` filter (`low/medium/high/critical`)

**Issue:** UC mix 2 concepts khác nhau:
- **Severity** = vitals threshold breach severity (alert table `severity` field)
- **Risk Level** = ML model output (risk_scores table `risk_level` field)

→ "Cảnh báo Ngưỡng" tab (UC Tab 1) là alerts từ vitals breach, không phải từ risk score → severity filter ĐÚNG, risk level filter KHÔNG áp dụng cho tab này.

**Em recommend:**
- **Document trong UC v2:** Severity filter cho Tab 1 (Cảnh báo Ngưỡng), Risk Level filter cho Tab 2 (Phân bố Risk)
- Tách Alt 6.b thành 2 alt flows riêng
- KHÔNG add risk_level filter vào threshold-alerts endpoint (nó không applicable)

**Anh decision:**
- ✅ **Em recommend (clarify UC, không add filter)** ← anh CHỌN
- ☐ Add `risk_level` filter vào threshold-alerts (cross-table query, ~1h)
- ☐ Khác: ___

---

### Q4: Alert status filter — schema gap

**Code state (line 180):**
```js
// NOTE: Status filter disabled - schema không có read_at, acknowledged_at, expires_at
```

**Implications:**
- UC v1 không mention alert acknowledgment workflow
- Code có TODO/note nói schema gap
- Possible future feature: admin "acknowledge" alert → status change

**Em recommend:**
- **Document trong UC v2** alert workflow scope: hiện tại chỉ "view + export", KHÔNG có acknowledge/dismiss workflow
- Phase 5+ enhancement: add acknowledge feature (cần schema migration `read_at`, `acknowledged_by`, `acknowledged_at`)
- KHÔNG add Phase 4 (out of scope đồ án 2)

**Anh decision:**
- ✅ **Em recommend (document scope, defer Phase 5+)** ← anh CHỌN
- ☐ Add schema + acknowledge feature Phase 4 (~3h migration + code)
- ☐ Khác: ___

---

### Q6: Magic number `take: 288` + misleading variable name (NEW post-verify)

**Code current (line 558-565):**
```js
vitals24h = await prisma.vitals.findMany({
  where: {
    device_id: deviceId,
    time: { gte: new Date(referenceTime.getTime() - 24 * 60 * 60 * 1000) },
  },
  orderBy: { time: 'desc' },
  take: 288,  // 🔴 Magic number, semantic không rõ ràng
});
```

**Issue:**
- Variable name `vitals24h` claim 24 giờ, where clause filter `gte: -24h`, nhưng `take: 288` với `orderBy: time desc` → chỉ lấy 288 records gần nhất.
- Vitals = 1 row/sec → 288 sec = ~5 phút. → **FE chart "24h" hiển thị 5 phút data** = false advertising.
- `take: 288` magic number không document. Có thể intent original = 288 = 1 sample/5min × 24h (nếu dataset 5-min aggregated) — nhưng aggregation không xảy ra ở bước này.

**Em recommend Option A — fix logic với CA:**
- Combine với Q1 refactor: `vitals24h` → query `vitals_5min` CA, lấy all 288 records (24h × 12 buckets/h = 288) → semantic khớp với variable name.
- Add code comment: `// take: 288 = 24h × 12 buckets/5min from vitals_5min CA`.
- Effort: ~30min (đồng bộ với Q1 refactor).

**Trade-off vs Option B:**
- Option B = giữ raw query nhưng sửa `take: 86400` (24h × 3600 sec) → dữ liệu đúng nhưng response payload **khổng lồ** (86400 rows JSON) → slow FE render.
- Option C = aggregate tại query, nếu không dùng CA: `prisma.$queryRaw` với `time_bucket('5 min')` → trade-off với Q1 dùng CA (Option A ưu hơn).

**Anh decision:**
- ✅ **Option A: Fix combine với Q1 dùng CA `vitals_5min` (em recommend)** ← anh CHỌN
- ☐ Option B: Giữ raw query, fix `take` con số đúng (response lớn)
- ☐ Option C: Aggregate raw query bằng `time_bucket` (không dùng CA)
- ☐ Khác: ___

---

### Q7: 🔴 CRITICAL — `risk_level` enum mismatch cross-repo (4 levels code vs 3 levels schema)

**Context (cross-repo verified 2026-05-12):**

| Source | Levels | Threshold |
|---|---|---|
| **DB schema canonical** | `low,medium,critical` (3) | (CHECK enum only) |
| **Mobile BE** ✅ | `low,medium,critical` (3) | LOW 0-33, MEDIUM 34-66, **CRITICAL 67-100** |
| **HealthGuard admin BE** 🔴 | `low,medium,high,critical` (4) | OLD 0-33/34-66/67-84/85-100 |
| **UC028 BR-028-06** 🔴 | LOW/MEDIUM/HIGH/CRITICAL (4) | OLD thresholds |
| **Model API** | mixed (legacy 4 dict) | n/a |

**Bug impact:**
- `risk-calculator.service.js:155-159` tính `risk_level='high'` cho score 67-84 → INSERT vào `risk_scores` → **CHECK constraint violation** → INSERT FAIL silently
- `health.service.js:46` filter `IN ('high','critical')` → 'high' không match → dashboard `highRiskCount` thiếu user 67-84
- Cross-repo OUT OF SYNC: 4 services (admin BE / mobile BE / model API / tests) có 4 representation khác nhau

**Anh decision (anh CONFIRM 2026-05-12):**
- ✅ **3 levels + threshold Mobile BE (em recommend)** ← anh CHỌN
  - LOW 0-33 (ổn định) | MEDIUM 34-66 (cần theo dõi) | CRITICAL 67-100 (nguy hiểm)
  - Rationale anh: 3 levels match consumer/family-facing UX; "vượt mức nguy hiểm = critical" matches medical sense; mobile BE đã production-ready 3 levels.

**Phase 4 sub-tasks (CRITICAL priority):**
1. **Fix admin BE risk-calculator** (`risk-calculator.service.js:155-159`): xoá `else if (riskScore >= 67) riskLevel = 'high'`, expand `critical >= 67` (~15min)
2. **Fix admin BE health.service.js** filter `IN ('critical')` (line 46), distribution drop `high` key (line 405-419) (~30min)
3. **Fix UC028 BR-028-06**: 3 levels + threshold mới (LOW 0-33 / MEDIUM 34-66 / CRITICAL 67-100) (~10min UC update)
4. **Fix index** `08_create_indexes.sql:104`: drop `'high'` từ WHERE clause (~5min migration)
5. **Fix tests admin BE**: mock `'moderate'` → `'medium'`, mock `'high'` → split between `'medium'` + `'critical'` theo score (~30min)
6. **DATA backfill** (🟡 PRODUCTION SAFE): `UPDATE risk_scores SET risk_level='critical' WHERE score >= 67 AND risk_level IN ('medium','high');` (~10min migration; backfill lại theo score thật vì comment SQL canonical hiện nay claim 'high → medium' SAI với threshold mới)
7. **Update SQL canonical comment** (`06_create_tables_ai_analytics.sql:56`): sửa "backfill thành medium" → "backfill theo threshold mới (LOW 0-33, MEDIUM 34-66, CRITICAL 67-100)" (~5min)
8. **Cross-repo verify**: chạy test mobile BE / model API sau backfill để ensure derive_health_level / risk_alert_service không break (~30min)

**Total Q7 effort:** ~2.5h cross-repo fix + 1 DATA migration

---

### Q5: PHI handling cho patient detail view

**UC NFR Security:** "Dữ liệu y tế chi tiết chỉ hiển thị khi Admin drill-down vào bệnh nhân cụ thể, có ghi audit log."

**Code state:**
- Patient detail (line 528+): expose vitals (HR, SpO₂, BP, Temp) + risk + email + device info
- Audit log `admin.view_patient_health` ✓ (BR-028-04)
- KHÔNG có rate limit per-patient view (admin có thể loop xem all patients)

**Risk:**
- Admin abuse: query loop patient/1, /2, /3, ... export all PHI
- Currently chỉ healthLimiter 60/min global, không per-patient

**Em recommend:**
- **Audit log đã đủ** cho compliance (admin actions traceable)
- **KHÔNG add rate limit per-patient** (admin có legitimate use case xem nhiều patient)
- **KHÔNG mask PHI** (admin có quyền xem)
- **Phase 5+ enhancement:** Anomaly detection (admin xem > 50 patient/hour → alert security team)

**Anh decision:**
- ✅ **Em recommend (audit log đủ, không mask, defer anomaly detection)** ← anh CHỌN
- ☐ Add rate limit per-patient view (1 view / 5min / patient)
- ☐ Mask PHI fields except role-based reveal
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Real-time WebSocket** push — INTERNAL `emit-alert` đã có cho admin FE realtime (overlap UC027)
- ❌ **Alert acknowledge workflow** — Q4 đã defer Phase 5+
- ❌ **Cohort analysis** — research feature, đồ án 2 không cần
- ❌ **PDF report export** — consistent với EMERGENCY Q4 (UC v1 không nói PDF, CSV đã đủ)
- ❌ **Predictive forecast** — depend ADR-006 MLOps mock

---

## 🆕 Features mới em recommend

**Không có** rõ ràng. Có thể consider:
- **(Tùy chọn)** Risk trend trend display ở Q2 (em đã include trong Q2 decision)

---

## ❌ Features em recommend DROP

**Không có.** Tất cả 7 endpoints có purpose, không có dead code.

---

## 🆕 Features anh nghĩ ra

_(anh add nếu có)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC028 Health Overview | **Update v2** | Q1 BR-028-01 CA usage + fix groupBy bug 2 chỗ, Q2 risk trend BE-compute, Q3 filter clarification (severity vs risk_level), Q4 acknowledge defer Phase 5+, Q5 PHI audit-only rule, Q6 `vitals24h` semantic fix với CA, **Q7 BR-028-06 update: 3 levels (LOW/MEDIUM/CRITICAL) + threshold mới (0-33 / 34-66 / 67-100)** |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| BR-028-01 + groupBy bug (Q1) | Refactor 2 chỗ use CA + sửa comment outdated (D-HEA-01) | `refactor(perf+bug): fix vitals.groupBy by:['time'] bug + use vitals_5min/hourly/daily CA` (~3h: 1h getVitalsTrends + 1h getPatientHealthDetail + 30min comment + 30min verify CA policies) | 🟠 Bug + Perf + BR |
| Risk trend missing (Q2) | BE compute trend (D-HEA-02) | `feat: BE compute riskTrend ↑↓→ + riskDelta cho summary/risk-distribution/patient detail` (~1h) | 🟡 Feature |
| Filter conflation (Q3) | Document UC v2, no code change (D-HEA-03) | 0h code; UC update | 🟢 Doc only |
| Status filter schema gap (Q4) | Defer Phase 5+ (D-HEA-04) | 0h Phase 4 | Defer |
| PHI handling (Q5) | Audit log đủ (D-HEA-05) | 0h code | 🟢 Doc only |
| Magic `take: 288` (Q6) | Combine với Q1 refactor dùng CA (D-HEA-06) | `fix: vitals24h truncated to 288 raw rows → use vitals_5min CA (288 = 24h×12 buckets)` (~30min, đồng bộ Q1) | 🟠 Bug (UX) |
| risk_level enum cross-repo mismatch (Q7) | 3 levels theo Mobile BE threshold 67-100 critical (D-HEA-07) | `fix(critical): risk_level 4→3 levels + threshold align Mobile BE + DB backfill + UC update` (~2.5h: 8 sub-tasks) | 🔴 CRITICAL (insert fail + dashboard bug) |

**Estimated Phase 4 effort:** ~7h code (3h Q1 fix 2 chỗ + comment + 1h Q2 risk trend + 30min Q6 combine + 2.5h Q7 cross-repo enum fix) + 1 DATA migration backfill + 1 UC v2 update

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-HEA-01 | Continuous Aggregates vs raw query | **Refactor service use CA (verified setup EXISTS)** | CA đã có trong SQL canonical từ đầu; code chỉ cần dùng. Performance 10-100x faster |
| D-HEA-02 | Risk trend implementation | **BE compute `riskTrend` + `riskDelta`** | Consistent BE pattern; FE chỉ render; affects 3 endpoints (summary/risk-dist/patient) |
| D-HEA-03 | Severity vs Risk Level filter | **Clarify UC v2, không add cross-table filter** | 2 concepts khác nhau (vitals threshold vs ML model output); tab riêng có filter riêng |
| D-HEA-04 | Alert status filter / acknowledge | **Document scope view+export, defer Phase 5+ acknowledge** | Schema gap (read_at, acknowledged_*) không có; out of scope đồ án 2 |
| D-HEA-05 | PHI handling rate limit | **Audit log đủ, no mask/limit** | Admin có quyền xem PHI; audit traceable; anomaly detection defer Phase 5+ |
| D-HEA-06 | Magic `take: 288` semantic fix | **Combine với Q1 refactor: `vitals_5min` CA 288 = 24h × 12 buckets/5min** | Variable name `vitals24h` claim 24h nhưng trả 5 phút raw → fix đồng bộ Q1 use CA; đúng semantic + perf |
| D-HEA-07 | risk_level enum cross-repo mismatch | **3 levels theo Mobile BE: LOW 0-33, MEDIUM 34-66, CRITICAL 67-100** | DB schema canonical đã 3 levels, Mobile BE đã align; admin BE + UC + tests + index OUT OF SYNC. Anh confirm rationale: 3 levels match consumer/family UX + medical sense |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Real-time WebSocket push | ❌ Drop (overlap INTERNAL emit-alert) |
| Alert acknowledge workflow | ❌ Drop (Q4 defer Phase 5+) |
| Cohort analysis | ❌ Drop (research feature) |
| PDF report export | ❌ Drop (consistent EMERGENCY Q4) |
| Predictive forecast | ❌ Drop (ADR-006 mock) |

**All 5 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

- UC028 cũ: `Resources/UC/Admin/UC028_Health_Overview.md`
- Routes: `HealthGuard/backend/src/routes/health.routes.js`
- Service admin: `HealthGuard/backend/src/services/health.service.js`
- Risk calculator admin: `HealthGuard/backend/src/services/risk-calculator.service.js` (Q7 — fix threshold)
- DB tables: `vitals`, `vitals_5min`, `vitals_hourly`, `vitals_daily` (CA), `alerts`, `risk_scores`
- SQL canonical: `PM_REVIEW/SQL SCRIPTS/04_create_tables_timeseries.sql` (CA), `06_create_tables_ai_analytics.sql` (risk_scores schema)
- SQL policies: `PM_REVIEW/SQL SCRIPTS/09_create_policies.sql:72-93` (CA refresh policies)
- SQL indexes: `PM_REVIEW/SQL SCRIPTS/08_create_indexes.sql:104` (Q7 — fix `'high'` index)
- **Cross-repo source-of-truth (Q7)**: 
  - Mobile BE: `health_system/backend/app/services/risk_inference_service.py:64-72` (RISK_THRESHOLDS_BY_LEVEL)
  - Model API: `healthguard-model-api/app/services/gemini_explainer.py:69-72` (legacy 4-level dict, phải sync)
- Tests: `HealthGuard/backend/src/__tests__/services/{health,dashboard}.service.test.js` (Q7 — fix mock data)
- UC027 Dashboard: overlap (alerts count, risk distribution) — **same Q7 enum bug phải fix dashboard.service.js**
- UC024 CONFIG: thresholds settings (BR-028-02 ref UC024)
- UC006/UC007/UC016/UC017: User-self vitals/risk (mobile, separate scope)
