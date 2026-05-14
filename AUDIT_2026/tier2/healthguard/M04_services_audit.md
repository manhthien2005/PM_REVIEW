# Audit: M04 — Services (business logic layer)

**Module:** `HealthGuard/backend/src/services/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

16 files in `backend/src/services/`:
- `auth.service.js` (~360 LoC) — login/register/logout/forgot/reset/change credential flows
- `user.service.js` — users CRUD + softDelete + toggleLock
- `device.service.js` — devices CRUD + assign/unassign + toggleLock
- `logs.service.js` — audit log list/query + CSV/JSON export + `writeLog` helper
- `settings.service.js` — system settings GET/PUT with re-auth + audit
- `emergency.service.js` — emergency events (SOS + Fall) list + detail + status update + export
- `health.service.js` (~580 LoC) — health overview + threshold alerts + risk distribution + patient detail
- `dashboard.service.js` — admin KPI + charts + recent incidents
- `relationship.service.js` — linked profiles CRUD + search
- `vital-alert.service.js` — threshold evaluation + alert creation (legacy, partially drop per D-VAA-02)
- `ai-models.service.js` — AI model CRUD + version upload (R2)
- `ai-models-mlops.service.js` — MLOps mock orchestration (ADR-006 mock)
- `websocket.service.js` — Socket.IO room emit (new alert / emergency / risk update)
- `risk-calculator.service.js` — server-side risk score calculation (Q7 enum bug root cause)
- `risk-calculation.service.js` — duplicate/overlap với risk-calculator.service.js?
- `r2.service.js` — Cloudflare R2 artifact upload wrapper

**Out of scope:** Controller layer (M03), Prisma query performance profile (Phase 3 per-service), R2 actual file upload (ops/R2 bucket config), WebSocket Socket.IO handshake auth (M01 findings defer to deep-dive).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | HG-001 active bug (health.service.js:353-358 hardcode status='unread'). Q7 enum mismatch (health.service.js:46 filter `IN ('high','critical')` + risk-calculator.service.js:155-159 set 'high' → INSERT fail). D-HEA-01 groupBy bug (line 479, 566 `by:['time']` → no aggregate). D-HEA-06 `take: 288` semantic wrong. |
| Readability | 2/3 | auth.service.js R3 reference pattern: 6 sections với separator comment đẹp. Nhưng health.service.js file 580+ LoC (god-service candidate), nhiều nested if/else cho format alert metric display (lines 195-305). |
| Architecture | 2/3 | Service layer đúng — không expose HTTP concern. HG-001 + Q7 + D-HEA-01 cho thấy service chứa business logic đúng layer nhưng có bugs. `websocket.service.js` chứa state (rooms, socket list). `r2.service.js` wrapper abstraction OK. Duplicate naming `risk-calculator` vs `risk-calculation`. |
| Security | 2/3 | auth.service.js R3 reference: bcrypt salt 10 ✓, lockout 5x/15min per-user ✓, audit log success + failure ✓, token_version increment on credential change (reset + change) ✓, reset token hash stored ✓, email enumeration protection ✓ (line 264-268). Gaps: logoutUser không increment token_version (drift D-AUTH-03 Phase 4), verification_code + reset_code raw-stored ở DB (cross-ref M06). |
| Performance | 2/3 | Indexes tận dụng tốt (user_id + time DESC, device_id + time DESC). Gaps: D-HEA-01 raw `vitals.groupBy` thay vì CA (`vitals_5min/hourly/daily`); `Promise.all` + `.catch(() => 0)` per query → mask errors thay vì surface; `health.service.js:getPatientHealthDetail` nhiều query sequential + groupBy per-day aggregate in JS (slow với 7d data). |
| **Total** | **9/15** | Band: **🟠 Needs-attention** |

## Findings

### Correctness (1/3)

**⚠️ P1 — HG-001 bug ACTIVE** (`health.service.js:177-181, 353-358`):

- Line 177-181 comment admit `// NOTE: Status filter disabled - schema không có read_at, acknowledged_at, expires_at`.
- Line 353-358 hardcode `let alertStatus = 'unread';` cho mọi alert.
- Drift -1.A + HG-001 bug tracker đã verify: `alerts.read_at` column TỒN TẠI trong Prisma schema (line 28, xem M06 audit) + canonical SQL. Mobile BE pivot sang `notification_reads` table cho per-user read state, `alerts.read_at` zombie column.
- **Root cause:** admin code đọc spec cũ (no `read_at`) → hardcode → mỗi alert hiện 'unread' → admin dashboard filter bể.
- **Action (planned):** HG-001 fix bug tracker Phase 4 — pivot sang `notification_reads` + aggregate read state per-alert. ~4h per bug tracker estimate. Priority P0 bug fix.
- File: `HealthGuard/backend/src/services/health.service.js:177-181, 353-358`
- Tracked: HG-001.

**⚠️ P0 CRITICAL — Q7 `risk_level` enum mismatch cross-service** (drift D-HEA-07):

- **`health.service.js:46`** filter `risk_level IN ('high', 'critical')` — 'high' sẽ không match row vì canonical DB CHECK `risk_level IN ('low','medium','critical')` (3 levels, Mobile BE truth).
- **`health.service.js:405-419`** `distribution = { low, medium, high, critical, unassessed }` — `high` key luôn = 0.
- **`risk-calculator.service.js:155-159`** (file em chưa đọc đầy đủ, ref drift D-HEA-07): tính `riskLevel='high'` cho score 67-84 → **INSERT FAIL** silently do CHECK constraint.
- **Tests** `__tests__/services/{health,dashboard}.service.test.js:134` mock `'high'` + `'moderate'` → SAI schema.
- Drift HEALTH D-HEA-07 đã chốt Phase 4 fix: 3 levels (LOW 0-33, MEDIUM 34-66, CRITICAL 67-100) match Mobile BE + DB.
- Priority P0 CRITICAL per drift.
- Files: `HealthGuard/backend/src/services/health.service.js:46, 405-419`, `HealthGuard/backend/src/services/risk-calculator.service.js:155-159`

**⚠️ P1 — D-HEA-01 `vitals.groupBy({by:['time']})` bug** (`health.service.js:479-490, 566-576`):

- Line 479-490 `getVitalsTrends` (30d system-wide) + line 566-576 `getPatientHealthDetail` vitals 7d: `prisma.vitals.groupBy({ by: ['time'], ... })` group theo TIMESTAMP NGUYÊN.
- Vitals raw = 1 row/sec → mỗi group chỉ có 1 row → KHÔNG AGGREGATE gì cả. Sau đó JS loop aggregate by day → **memory explosion** với 100k+ rows (30d × 86400s).
- Comment line 474 `// Dùng groupBy theo ngày` sai — code không dùng `date_trunc`.
- Canonical SQL 04_create_tables_timeseries.sql:106-173 có sẵn `vitals_5min`, `vitals_hourly`, `vitals_daily` Continuous Aggregates. Code admin BE KHÔNG dùng.
- Drift HEALTH D-HEA-01 đã chốt Phase 4 fix: refactor use CA. ~3h.
- Priority P1 per drift.
- File: `HealthGuard/backend/src/services/health.service.js:479-490, 566-576`

**⚠️ P2 — D-HEA-06 `vitals24h take: 288` bug** (`health.service.js:558-565`):

- Claim `vitals24h` (24h) nhưng `take: 288` với `orderBy: time desc` → chỉ lấy 288 records gần nhất.
- Vitals = 1 row/sec → 288 sec = ~5 phút (không phải 24h như variable name).
- FE chart "24h" hiển thị 5 phút data → false advertising UX.
- Drift HEALTH D-HEA-06 chốt combine fix với D-HEA-01: use `vitals_5min` CA → 288 = 24h × 12 buckets/5min (đúng semantic).
- Priority P2 per drift.
- File: `HealthGuard/backend/src/services/health.service.js:558-565`

- ✓ **auth.service.js reference pattern R3** (lines 24-141 login flow): 5-fail lockout 15min per-user (`:64-75`), audit log every success + failure branch (`:29-36, 48-56, 85-93, 95-102, 117-124`), email regex check tại service boundary (`:25-27`), bcrypt verify with user input (`:79`). Matches drift AUTH Q2 layer 1 design.
- ✓ `auth.service.js:8-11` email + phone + Vietnamese name regex tại top file → centralized validation patterns.
- ✓ `auth.service.js:210-228` `requestPasswordReset` email enumeration protection: user không tồn tại → trả same SUCCESS message (`:264-266`). Reset token JWT 15min + hash stored (`:230-249`).
- ✓ `auth.service.js:306-318` `resetPassword` transaction atomic (update user + mark token used) — consistent state.
- ✓ `auth.service.js:325-371` `changePassword` — validate current credential trước + check new value không trùng cũ + strict admin stronger rule (`:346-351`) — defense-in-depth.
- ⚠️ **P2 — `auth.service.js:143-152` logoutUser KHÔNG increment token_version** (drift AUTH D-AUTH-03 Phase 4):
  - Code chỉ `_logAudit({ action: 'auth.logout' })`, không invalidate token server-side.
  - Drift D-AUTH-03 chốt increment token_version khi logout → immediate token invalidation (pattern R1 middleware đã ready).
  - Priority P2 per drift (5 min fix).
  - File: `HealthGuard/backend/src/services/auth.service.js:143-152`
- ⚠️ **P2 — `auth.service.js:176-178` registerUser restrict role to `['user']` only** — conflict với `auth.controller.js:46-48` inline block `role === 'admin' → 403`.
  - Service layer: `allowedRoles = ['user']; if (!allowedRoles.includes(role)) badRequest`. → Reject 'admin' nhưng với message "Role phải là 'user'" (badRequest 400).
  - Controller layer: check before service → throw 403 forbidden với message "Không thể tạo tài khoản admin qua API".
  - Drift AUTH D-AUTH-06 quyết định REVERT cả 2 chỗ: register là dev tool, admin có thể tạo admin khác. Phase 4 task: remove role restriction ở controller + service (~5 min cả 2 chỗ).
  - Priority P2 per drift.
  - File: `HealthGuard/backend/src/services/auth.service.js:176-178` + `HealthGuard/backend/src/controllers/auth.controller.js:46-48`
- ⚠️ **P3 — `health.service.js:186-203` dateRange switch-case không có upper bound** — user có thể pass `dateRange=all` → `startDate = new Date('2020-01-01')` → query toàn bộ alerts table. Nếu DB có 10M rows → response time tăng. Priority P3 — add LIMIT hoặc hạ ngưỡng `'all'` xuống 1 năm.
- ⚠️ **P3 — `health.service.js:311-324` debug `console.log('Alert query debug:', ...)`** — debug statement leaked to production code. Should use proper logger với level. Priority P3.

### Readability (2/3)

- ✓ **`auth.service.js` section dividers** (`:24-26, :145-147, :159-161, :205-207, :278-280, :335-337`) — reader scan dễ, biết đang ở flow nào (login/logout/register/forgot/reset/change).
- ✓ JSDoc top file (`auth.service.js:16-18`, `health.service.js:6-10`) — intent rõ.
- ✓ Vietnamese error messages consistent (`'Email không đúng định dạng'`, `'Mật khẩu không đủ mạnh'`, `'Tài khoản đã bị khoá'`) — match convention.
- ✓ `auth.service.js:380-398` `_logAudit` helper — DRY pattern, 10+ call sites dùng chung.
- ⚠️ **P1 — `health.service.js` file size 580+ LoC** — god-service candidate. `getThresholdAlerts` một method 195-305 (~110 LoC) chứa switch-case xử lý format alert metric cho 7 alert_type × 4-5 data shape. Khó test, khó grep. Priority P2 — extract `_formatAlertMetric(alert, thresholds)` helper; Phase 3 deep-dive candidate.
  - File: `HealthGuard/backend/src/services/health.service.js:186-350`
- ⚠️ **P2 — `health.service.js:255-305` Vietnamese literal in business logic** — `message.includes('SpO')` + `'Nhịp tim'` hardcoded Vietnamese string check. Nếu message template thay đổi → broken detection. Priority P2 — dùng `alert_type` hoặc `alert.data.metric` field thay vì parse Vietnamese message.
- ⚠️ **P2 — Emoji trong code** (`health.service.js:326` `console.log` literal có emoji, `auth.service.js:394` `console.error` literal có emoji) — rule workspace 00-operating-mode.md cấm emoji trong code/commit/PR. Priority P2.
- ⚠️ `health.service.js:7-10` comment declare `BR-028-06: Risk score phân loại: LOW (0-33), MEDIUM (34-66), HIGH (67-84), CRITICAL (85-100)` — SAI per drift D-HEA-07 (3 levels). Outdated doc trong code. Priority P2 cùng group với D-HEA-07 fix.

### Architecture (2/3)

- ✓ **Separation of concern** đúng — controller → service → Prisma. Services không import Express req/res types.
- ✓ `auth.service.js:380-398` `_logAudit` helper internal — DRY + single responsibility.
- ✓ `auth.service.js:306-318` transaction pattern (`prisma.$transaction([userUpdate, tokenUpdate])`) — atomic guarantee.
- ✓ `health.service.js:17-85` `getSummary` dùng `Promise.all([...])` + per-query `.catch(() => 0)` — parallel execution đúng cho non-dependent queries.
- ⚠️ **P2 — `health.service.js:33-40, 47-53` `.catch(() => 0)` / `.catch(() => [])` silent-fail pattern** — mask errors (DB down, query syntax lỗi) thành empty result. Admin dashboard hiển thị số 0 không biết đang degraded. Should logger.warn tối thiểu trước khi fallback. Priority P2.
  - File: `HealthGuard/backend/src/services/health.service.js:33-53, 399-413`
- ⚠️ **P2 — Duplicate naming `risk-calculator.service.js` vs `risk-calculation.service.js`** — 2 files cùng domain, verify Phase 3 có overlap logic hay không. Nếu redundant → consolidate. Priority P2.
  - File: `HealthGuard/backend/src/services/risk-calculator.service.js`, `risk-calculation.service.js`
- ⚠️ **P3 — `health.service.js` file scope mix**: summary + alerts + risk distribution + vitals trends + patient detail + processNewVital (delegate vital-alert). Consider split thành `health-overview.service.js` + `threshold-alerts.service.js` + `patient-health.service.js` Phase 5+. Priority P3.
- ⚠️ **P3 — `health.service.js:622-634` `processNewVital` is thin wrapper** gọi `VitalAlertService.processVitalForAlerts` — có thể inline từ caller thay vì tầng indirection thêm. Priority P3.

### Security (2/3)

- ✓ **bcrypt salt 10** (`auth.service.js:158, 295, 367`) — industry-standard cost factor cho 2026 (~100ms hash time). Không dùng giá trị khác tiền lệ.
- ✓ **Lockout mechanism R3** (`auth.service.js:79-101`) — 5 fails trong 15 phút → `locked_until` timestamp. Reset khi login thành công (`:108-114`). Pattern defense-in-depth against credential stuffing.
- ✓ **Audit log every auth branch** — success + 3 failure branches (user_not_found, account_locked, invalid_credentials). Forensic visibility đầy đủ.
- ✓ **token_version increment on credential change** (`auth.service.js:308-314, 362-368`) — invalidate active sessions ngay khi credential đổi. Pattern R1 + R3.
- ✓ **Reset token hash stored** (`auth.service.js:230-249`) — DB giữ hash SHA-256 của reset token, không giữ raw token. Verify đúng + prevent replay. Pattern industry standard.
- ✓ **Email enumeration protection** (`auth.service.js:264-268`) — `requestPasswordReset` trả same success message bất kể email tồn tại hay không.
- ✓ **New value không trùng cũ check** (`auth.service.js:285-288, 355-358`) — prevent user reuse exact same value sau reset.
- ✓ **Confirm check** (`auth.service.js:252-255, 328-331`) — defense tại service layer (ngoài FE validation).
- ✓ `health.service.js:602-613` audit log `admin.view_patient_health` cho PHI access — per drift HEALTH D-HEA-05.
- ⚠️ **P2 — `auth.service.js:143-152` logoutUser không increment token_version** — drift D-AUTH-03 Phase 4 fix (5 min). Pattern R1 middleware đã ready check token_version mismatch. Priority P2 per drift.
- ⚠️ **P3 — `auth.service.js:158, 367` hash cost 10** — acceptable 2026, nhưng thiết bị low-end CI có thể ≥ 200ms. Phase 5+ benchmark cost 12 khi scale. Priority P3.
- ⚠️ Rate limiter per-IP (`changePasswordLimiter 5/15min` trong M05) + lockout per-USER (`auth.service.js`) = 2 layers defense per drift AUTH D-AUTH-02. Strong posture.

### Performance (2/3)

- ✓ **Promise.all parallelization** (`health.service.js:22-55`) — 6 queries parallel cho `getSummary`. Đúng.
- ✓ **Prisma `select` projections** — `auth.service.js findUnique` không leak sensitive columns ra response (service tự filter khi return).
- ✓ **Index coverage** — `user_id + time DESC`, `device_id + time DESC`, `action + time DESC` covered bởi M06 Prisma.
- ✓ **Raw SQL DISTINCT ON** (`health.service.js:46-52, 378-383`) — đúng pattern PostgreSQL cho "latest per user" query, tránh window function overhead.
- ⚠️ **P1 — D-HEA-01 raw vitals.groupBy thay vì CA** (duplicate với Correctness finding) — query 30d × 86400 rows sẽ load 2.5M rows vào RAM. Priority P1 per drift.
- ⚠️ **P2 — `health.service.js:603-613` `getPatientHealthDetail` multiple sequential queries** (line 553-599: latestVitals → vitals24h → vitals7dGrouped → alerts7dRaw). Có thể Promise.all 3-4 query non-dependent. Priority P2 — refactor concurrent.
- ⚠️ **P3 — `auth.service.js:79-91` `.update` per-failure** — mỗi login fail ghi 1 update vào users table (increment `failed_login_attempts`). Nếu attacker bruteforce 1000 attempt/s → 1000 UPDATE/s pressure lên users table. Phase 5+ cân nhắc rate limit tại router (đã có) + batch update via cron. Priority P3.
- ⚠️ **P2 — `health.service.js:586-591` `vitals7dGrouped.orderBy: time desc`** — groupBy with orderBy là expensive pattern nếu bảng có index DESC + composite. Với CA view (post-D-HEA-01 fix) → negligible. Priority P2 resolve via D-HEA-01.

## Recommended actions (Phase 4)

- [ ] **P0 CRITICAL** — Per drift/HEALTH.md D-HEA-07: Fix `risk_level` 4→3 levels cross-service:
  - `health.service.js:46` filter `IN ('critical')` only
  - `health.service.js:405-419` distribution drop `high` key
  - `risk-calculator.service.js:155-159` expand `critical >= 67` (remove 'high' branch)
  - Update tests (~30 min)
  - ~2.5h cross-repo fix + DB migration backfill per drift plan
- [ ] **P1** — Fix HG-001: pivot `getThresholdAlerts` + `getSummary` từ hardcode `'unread'` sang JOIN `notification_reads` table. Update docstring BR-028-06. ~4h per HG-001 tracker.
- [ ] **P1** — Per drift/HEALTH.md D-HEA-01 + D-HEA-06: Refactor `getVitalsTrends` (line 479) dùng `vitals_daily` CA + `getPatientHealthDetail` vitals 7d (line 566) dùng `vitals_hourly` CA + vitals24h (line 558) dùng `vitals_5min` CA. Remove JS-side day aggregate loop. Update comment line 7-9. ~3h.
- [ ] **P2** — Per drift/AUTH.md D-AUTH-03: `logoutUser` increment `token_version` (~5 min).
- [ ] **P2** — Per drift/AUTH.md D-AUTH-06: Remove register role restriction ở `auth.service.js:176-178` + `auth.controller.js:46-48` (~5 min cả 2).
- [ ] **P2** — Replace `.catch(() => 0)` / `.catch(() => [])` silent-fail ở `health.service.js` bằng logger.warn + structured error context (~1h).
- [ ] **P2** — Verify + consolidate `risk-calculator.service.js` vs `risk-calculation.service.js` duplicate (Phase 3 deep-dive candidate).
- [ ] **P2** — Extract `_formatAlertMetric(alert, thresholds)` helper từ `health.service.js:186-350` switch-case (~2h).
- [ ] **P2** — Replace Vietnamese literal check `message.includes('SpO')` bằng `alert.data.metric` field enum (~1h).
- [ ] **P2** — Remove emoji trong code (`console.log` + `console.error` literal prefix) → text prefix (~10 min).
- [ ] **P2** — `getPatientHealthDetail` refactor 3-4 queries thành Promise.all concurrent (~30 min).
- [ ] **P3** — Remove debug `console.log('Alert query debug:', ...)` ở `health.service.js:311-324` (~5 min).
- [ ] **P3** — Split `health.service.js` 580+ LoC thành 2-3 module (Phase 5+ refactor).

## Out of scope (defer Phase 3 deep-dive)

- Per-service deep contract test (service method signature vs controller call) — Phase 3.
- `emergency.service.js`, `device.service.js`, `user.service.js`, `logs.service.js`, `settings.service.js`, `dashboard.service.js`, `relationship.service.js`, `vital-alert.service.js`, `ai-models.service.js`, `ai-models-mlops.service.js`, `websocket.service.js`, `r2.service.js` — scan macro-level chỉ, deep audit cần Phase 3.
- `notification.service.js` (per inventory M04 mentions) — verify existence + scope Phase 3.
- `risk-calculator.service.js` vs `risk-calculation.service.js` disambiguation — need side-by-side diff Phase 3.
- Socket.IO handshake auth verify (`websocket.service.initialize`) — M01 audit raised, Phase 3 depth.
- Transaction isolation level cho `settings.service.js` + `auth.service.js` — Phase 3 DB concurrency audit.
- R2 upload error handling + retries — Phase 3 ops audit.

## Cross-references

- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-01 (CA usage), D-HEA-05 (PHI audit), D-HEA-06 (vitals24h fix), D-HEA-07 (risk_level 3 levels).
- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-02 (2-layer lockout), D-AUTH-03 (token_version increment on logout), D-AUTH-06 (register role restriction revert), reference pattern R3.
- Phase 0.5 drift: [drift/VITAL_ALERT_ADMIN.md](../../tier1.5/intent_drift/healthguard/VITAL_ALERT_ADMIN.md) — D-VAA-01/02 (drop service code cho 6 dropped endpoints).
- Phase 0.5 drift: [drift/RELATIONSHIP.md](../../tier1.5/intent_drift/healthguard/RELATIONSHIP.md) — D-REL-05 service set `status='active'` fix.
- Phase 0.5 drift: [drift/CONFIG.md](../../tier1.5/intent_drift/healthguard/CONFIG.md) — D-CFG-03 cache layer Phase 4 + D-CFG-04 maintenance mode + D-CFG-05 validation schema + D-CFG-06 restore defaults.
- Phase -1 findings: [phase_minus_1_summary.md](../../phase_minus_1_summary.md) — D1 severity 4-level (not affecting service directly), D3 `alerts.read_at` zombie (HG-001 root cause).
- HG-001 bug: [HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — service layer root cause confirmed.
- ADR-006: [006-mlops-mock-vs-real-integration.md](../../../ADR/006-mlops-mock-vs-real-integration.md) — `ai-models-mlops.service.js` mock mandate.
- ADR-007: [007-r2-artifact-vs-model-api-serving-disconnect.md](../../../ADR/007-r2-artifact-vs-model-api-serving-disconnect.md) — `r2.service.js` + `ai-models.service.js` R2 upload scope.
- ADR-008: [008-mobile-be-no-system-settings-write.md](../../../ADR/008-mobile-be-no-system-settings-write.md) — `settings.service.js` admin-only write.
- ADR-015: [015-alert-severity-taxonomy.md](../../../ADR/015-alert-severity-taxonomy.md) — `severity` 4 layers enforced at service layer.
- M02 Routes audit: controller → service mapping.
- M03 Controllers audit: thin controllers delegate đúng vào services.
- M06 Prisma schema audit: schema enum sync requirement (Q7 fix depends).
- Module inventory: M04 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M02_services_audit.md](../healthguard-model-api/M02_services_audit.md) — compare Express service pattern vs FastAPI service pattern.
