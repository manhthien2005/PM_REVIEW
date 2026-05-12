# M04 — Services Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Services (`backend/src/services/`)
**Files:** 16 (15 active + 1 zero-byte dead)
**LoC:** ~6,000 (largest backend module)
**Effort spent:** ~1.5h
**Auditor:** AI pair
**Date:** 2026-05-12

**Mode:** Sample-deep on critical files (HG-001 fix point + auth + ai-models-mlops); rubric extrapolated.

---

## Scope sampled

| File | Bytes | Status |
|---|---|---|
| `health.service.js` | 25 KB / 682 LoC | ✅ Deep-read (HG-001 fix point) |
| `auth.service.js` | 18 KB / 467 LoC | ✅ Deep-read (security-critical) |
| `ai-models-mlops.service.js` | 31 KB / 832 LoC | ✅ Skim (largest service) |
| `vital-alert.service.js` | 21 KB | Skim (HG-001 adjacent) |
| `risk-calculation.service.js` | **0 KB** | 🟠 Dead file |

Others (not deep-read): `dashboard`, `emergency`, `user`, `device`, `logs`, `settings`, `relationship`, `r2`, `risk-calculator`, `websocket`, `ai-models`, `notification` services.

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | **1** | **HG-001 root cause confirmed** (stale schema-assumption comment hides bug); silent error swallow `catch(() => 0)` hides real failures. |
| **Readability** | 2 | `health.service.js` 682 LoC + verbose date switch; `ai-models-mlops.service.js` 832 LoC mixed with mock data imports. |
| **Architecture** | 2 | Service layering OK; mix Prisma ORM + raw SQL `$queryRaw`; **mock import in production path** (ai-models-mlops.service:17). |
| **Security** | 3 | Strong auth flow (lockout, audit log, bcrypt salt 10); no SQL injection (parameterized); password validation enforced. |
| **Performance** | 2 | Promise.all parallelism good; raw SQL subqueries may be slow at scale; no caching layer. |

**Total: 10/15 → 🟡 Needs attention (low Correctness — HG-001 active bug)**

---

## CRITICAL FINDING: HG-001 root cause confirmed

### F1 🔴 HG-001 — Alerts always unread (Correctness)

**File:** `backend/src/services/health.service.js:180-181`

```js
// NOTE: Status filter disabled - schema không có read_at, acknowledged_at, expires_at
```

**Reality:** Prisma schema (M06 audit) `alerts` model **HAS** these fields:

```prisma
// schema.prisma:27-28, 32
read_at              DateTime? @db.Timestamptz(6)
acknowledged_at      DateTime? @db.Timestamptz(6)
expires_at           DateTime? @db.Timestamptz(6)
```

**Impact:**
- Service hardcodes status='unread' for all alerts returned
- Admin UI cannot mark alerts as read/acknowledged → entire alert lifecycle broken
- Tracked as bug HG-001 since Phase -1

**Fix (Phase 4):**

```js
// In health.service.js select clause for alerts:
select: {
  id: true, title: true, severity: true, created_at: true,
  read_at: true, acknowledged_at: true, expires_at: true,
  user_id: true, alert_type: true, message: true,
}

// Status derivation:
function deriveAlertStatus(alert) {
  if (alert.expires_at && alert.expires_at < new Date()) return 'expired';
  if (alert.acknowledged_at) return 'acknowledged';
  if (alert.read_at) return 'read';
  return 'unread';
}

// Apply status filter in whereClause:
if (status === 'unread') whereClause.read_at = null;
if (status === 'read') whereClause.read_at = { not: null };
if (status === 'acknowledged') whereClause.acknowledged_at = { not: null };
```

**Coordinated with:**
- M02 internal routes `emit-alert` already wires WebSocket to admin → "mark as read" UI flow needs admin endpoint
- Frontend `ThresholdAlertsTable.jsx` (Track 1B M11) — consumes status; verify display logic

**Severity:** P0
**Effort:** 4h (service fix + endpoint to mark-read + test + frontend wire)

---

## Other critical findings

### F2 🔴 Silent error swallowing (Correctness)

**File:** `health.service.js:31-53`

```js
prisma.users.count({...}).catch(() => 0),
prisma.alerts.findMany({...}).catch(() => []),
prisma.$queryRaw`SELECT ...`.catch(() => []),
```

**Pattern repeats 6 times in `getSummary()`.**

**Issues:**
- A connection failure / SQL syntax error / typo in query → silently returns 0 → KPI dashboards show false zeros
- No logging → can't diagnose; bug masquerades as "no data"
- Cascading: `assessedRaw[0]?.cnt ?? 0` gracefully handles, but masks DB error

**Fix (Phase 4):**

```js
// Add error logging at minimum:
prisma.users.count({...}).catch((err) => {
  console.error('getSummary.totalPatients failed:', err.message);
  return 0;
}),
```

**Better:** Throw, let controller `catchAsync` → errorHandler return 500. Dashboard should refresh/retry, not show false zeros.

**Severity:** P1 (bug-masking pattern)
**Effort:** 2h (add logging + test failure paths)

---

### F3 🟠 Mock data import in production service (Architecture)

**File:** `services/ai-models-mlops.service.js:5-17`

```js
const {
  FALL_MODEL_ID, FALL_MODEL_KEY, FEATURE_ORDER,
  buildInitialState, buildModelDiff, buildRetrainReason,
  ...
} = require('../mocks/ai-models-mlops.mock');
```

**Function `createDemoFallPayload(dbModel)`** (line 63) — fills demo data when MLOps state is empty. Used in production response path.

**Risk:**
- Frontend may display mock data as real → user confusion
- Test/prod boundary blurred — mock dataset versions, model diffs, feedback summaries

**Fix (Phase 4 architecture cleanup):**
- Move mock to separate "seed" or "demo mode" feature
- Conditional behind `env.DEMO_MODE` flag
- Or remove if MLOps real data pipeline is now production-ready

**Severity:** P2
**Effort:** 4-6h (depends on real-vs-mock dependency depth)

---

### F4 🟠 `risk-calculation.service.js` zero-byte file (Architecture)

**File:** `backend/src/services/risk-calculation.service.js` (0 bytes)

Confirmed M06 F10. Dead file from rename to `risk-calculator.service.js`.

**Fix:** `git rm`. 2 min.

---

### F5 🟠 Service file size — split candidates

**Sizes:**
- `ai-models-mlops.service.js` — 832 LoC ⚠️
- `health.service.js` — 682 LoC ⚠️
- `vital-alert.service.js` — ~500 LoC
- `dashboard.service.js` — ~450 LoC
- `auth.service.js` — 467 LoC
- `emergency.service.js` — ~430 LoC

**Threshold (per Phase 0 framework):** > 500 LoC = readability deduction; > 700 LoC = split candidate.

**Phase 3 deep-dive:**
- `health.service.js` split: getSummary + getThresholdAlerts + getRiskDistribution + getPatientHealthDetail → 3-4 sub-services
- `ai-models-mlops.service.js` split: mock-helpers + real-data + retrain-jobs + feedback

**Severity:** P2 (refactor)
**Effort:** Phase 3 deep-dive — 8-12h per service

---

## Strengths

### F6 🟢 Auth service — strong lockout + audit

**File:** `auth.service.js:69-89`

```js
const isMatch = await bcrypt.compare(password, user.password_hash);
if (!isMatch) {
  const attempts = (user.failed_login_attempts || 0) + 1;
  let updateData = { failed_login_attempts: attempts };
  if (attempts >= 5) {
    updateData.locked_until = new Date(Date.now() + 15 * 60 * 1000);
  }
  await prisma.users.update({ where: { id: user.id }, data: updateData });
  await this._logAudit({ ..., reason: 'invalid_credentials', attempts, status: 'failure' });
  throw ApiError.unauthorized('Email hoặc mật khẩu không đúng');
}
```

**Strengths:**
- Bruteforce defense (lockout after 5 failures, 15-min cooldown)
- Audit log on **every** failed + successful login (forensic trail)
- Generic error message ("Email hoặc mật khẩu không đúng") — no user enumeration leak
- Reset attempts on success (line 92-100)

**Cross-repo: adopt in `health_system/backend/app/routers/auth.py` (Track 2)** if not present.

### F7 🟢 Comprehensive input validation (auth.service)

**File:** `auth.service.js:148-187`

- Email regex
- Phone regex (`^0\d{9,10}$` — Vietnam-specific)
- Name regex (full Vietnamese diacritics whitelist)
- Date-of-birth: not future + age ≥ 13
- Role allowlist

**Defense-in-depth:** route → validate middleware → service-layer re-check.

### F8 🟢 bcrypt salt 10 (acceptable; consider 12)

**File:** `auth.service.js:196`

```js
const passwordHash = await bcrypt.hash(password, 10);
```

**Recommendation:** Salt 10 = ~10 hashes/sec on modern CPU. 12 = ~2.5 hashes/sec — safer vs GPU bruteforce. **Trade-off:** 4x slower login.

**Phase 4 consideration:** Move to argon2 (memory-hard) or bump salt to 12. Mid-priority.

---

## Anti-pattern flags

- 🚩 **Stale code comment hiding active bug** (F1 HG-001) — high-impact debt
- 🚩 **Silent error swallow** (F2) — bug-masking
- 🚩 **Mock data in production service** (F3) — test/prod boundary blur
- 🚩 **Zero-byte file** (F4) — dead code
- 🚩 **Service > 700 LoC** (F5) — readability

---

## Phase 3 deep-dive candidates

| File | Priority | Reason |
|---|---|---|
| `health.service.js` | **HIGH** | F1 HG-001 fix + split into sub-services |
| `ai-models-mlops.service.js` | Medium | F3 mock separation + F5 split |
| `auth.service.js` | Low | Already mature; consider argon2 migration |
| `vital-alert.service.js` | Medium | Alert lifecycle alignment with F1 fix |

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F1 HG-001 — enable status fields | **P0** | 4h |
| 2 | F2 Replace silent catch with logging | P1 | 2h |
| 3 | F3 Mock data behind env flag | P2 | 4-6h |
| 4 | F4 Remove zero-byte file | P3 | 2 min |
| 5 | F8 (consider) Bump bcrypt salt to 12 | P3 | 0.5h + perf test |

**Total: 10-12h.**

---

## Cross-references

- **HG-001** (Phase -1 bug log) — F1 root cause confirmed in this audit
- M06 F10 — same dead file finding
- M02 — internal routes wire WebSocket emit for alerts (touchpoint for F1 fix)
- ADR-004 — backend `iss=healthguard-admin` in JWT — verify present in F6 token payload (line 113-117 — not present, only `id, email, role, tokenVersion`). **Minor gap with ADR-004; add `iss` claim.**

---

## Verdict

**🟡 Needs attention.** Services have **active bug HG-001 root cause** (F1) + silent error pattern (F2). Auth service is reference-quality. Total Phase 4 effort ~10-12h; HG-001 alone 4h critical-path.

**Single most impactful fix in Track 1A: F1 HG-001 enable status fields.** Unblocks entire alert acknowledgement UX.
