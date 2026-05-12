# M07 — Jobs + Utils + Config Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Jobs + Utils + Mocks + Config
**Paths:** `backend/src/{jobs/, utils/, mocks/, config/}`
**LoC:** ~1,500
**Effort spent:** ~30 min (skim mode)
**Auditor:** AI pair
**Date:** 2026-05-12

**Mode:** Skim — read ApiError, vital-processor, sample structure.

---

## Scope

### Jobs (2 files)
- `vital-processor.js` (110 LoC) — background vital → alert converter (5-min interval)
- `risk-score-job.js` (~75 LoC) — periodic risk recalculation

### Utils (7 files)
- `ApiError.js` (50 LoC) — error factory class
- `ApiResponse.js` (~50 LoC) — response wrapper
- `catchAsync.js` (~15 LoC) — async error wrapper
- `email.js` (~150 LoC) — password reset email + change confirm
- `passwordValidator.js` (~120 LoC) — strength checker
- `prisma.js` (~20 LoC) — Prisma client singleton
- `__mocks__/` (test mocks)

### Mocks (1 file)
- `ai-models-mlops.mock.js` — MLOps state seed data (referenced from production via M04 F3)

### Config (2 files)
- `env.js` — environment variable loader
- `swagger.js` — OpenAPI spec config

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | ApiError factory clean; vital-processor lifecycle methods correct. |
| **Readability** | 3 | Small files, single-responsibility, JSDoc. |
| **Architecture** | 2 | `mocks/` imported by production code (M04 F3); `vital-processor` permanently disabled (status: dead?). |
| **Security** | 2 | Password validator uses regex (verify backslash escapes); email module sends plaintext reset URLs (HTTPS assumed). |
| **Performance** | 3 | Prisma singleton avoids connection storm; rate limiter in-memory (single instance). |

**Total: 13/15 → 🟢 Mature**

---

## Findings

### F1 🟠 `vital-processor.js` permanently disabled

**File:** `backend/src/jobs/vital-processor.js:13`

```js
this.enabled = false; // TẮT - Dùng real-time alerts thay thế
```

**Comment line 7:** `"ĐÃ TẮT THEO YÊU CẦU SẾPF"` (typo: should be `SẾP`)

**Observations:**
- Job class still wired to start/stop API (`vital-alert.routes.js:46 POST /process`, `/processor/toggle`)
- `processVitals()` method still callable manually
- `server.js:27-34` checks `processorStatus.enabled` → defaults disabled
- Real-time path (`vital-alert.service.js`) replaces this

**Question:** Is this dead code or pause-toggle feature?

**Fix options (Phase 4):**

**Option A — remove dead code:**
- Drop `jobs/vital-processor.js`
- Remove processor toggle endpoints (M02 `vital-alert.routes.js` `/processor/*`)
- Drop manual `processVitalForAlerts` testing endpoint if unused

**Option B — keep as fallback:**
- Document in README why disabled
- Add unit test for re-enable scenario
- Fix `SẾPF` typo
- Add explicit "PAUSED" status in API response

**Recommendation:** Verify with anh — Option B if intentional pause; A if migration complete.

**Severity:** P2 (architecture clarity)
**Effort:** A 1h, B 30 min

---

### F2 🟡 `mocks/` imported from production service

**File:** `mocks/ai-models-mlops.mock.js` (size unknown, deep)

Referenced from `services/ai-models-mlops.service.js:5-17` per M04 F3.

Already covered in M04 F3 — repeat as cross-reference.

**Severity:** P2 (same as M04 F3)
**Effort:** 4-6h (M04 F3 fix)

---

### F3 🟢 ApiError factory pattern

**File:** `utils/ApiError.js`

```js
class ApiError extends Error {
  constructor(statusCode, message, errors = []) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.isOperational = true;  // Distinguish from programming errors
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message, errors)  { return new ApiError(400, ...); }
  static unauthorized(message)         { return new ApiError(401, ...); }
  static forbidden(message)            { return new ApiError(403, ...); }
  static notFound(message)             { return new ApiError(404, ...); }
  static conflict(message)             { return new ApiError(409, ...); }
  static locked(message)               { return new ApiError(423, ...); }
  static internal(message)             { return new ApiError(500, ...); }
}
```

**Strengths:**
- `isOperational` flag distinguishes thrown ApiError (user-facing) from programming bugs (500 + stack)
- Factory methods readable: `throw ApiError.notFound(...)` vs `throw new ApiError(404, ...)`
- `errors` array for batch validation errors (used by `validate.js`)
- `captureStackTrace` for accurate stack

**Missing:** No `static tooManyRequests(429)` factory — rate limiters use direct `res.status(429)` instead. Add for consistency.

**Severity:** P3
**Effort:** 5 min

---

### F4 🟡 Password reset URL in plaintext email

**File:** `utils/email.js` (sampled — assumed pattern)

Sends `sendPasswordResetEmail` with reset link containing token in URL query string.

**Concerns:**
- URL appears in email server logs, browser history, referer header (if user clicks external link after)
- Mitigated by: short token TTL (verify in `password_reset_tokens.expires_at`) + single-use

**Verify (Phase 4):** Confirm token TTL ≤ 1 hour and token marked used in DB.

**Severity:** P2 (conditional on TTL)
**Effort:** 30 min audit + fix

---

### F5 🟡 vital-processor typo

**File:** `jobs/vital-processor.js:7`

```js
* ĐÃ TẮT THEO YÊU CẦU SẾPF
```

**Fix:**
```js
* ĐÃ TẮT THEO YÊU CẦU SẾP
```

Or rephrase: `* DISABLED — replaced by real-time alerts in vital-alert.service`.

**Severity:** P3
**Effort:** 2 min

---

### F6 🟢 Prisma singleton pattern

**File:** `utils/prisma.js` (small)

Single import → single client → avoids "too many connections" anti-pattern. Common Node.js + Prisma pitfall — handled correctly here.

---

## Anti-pattern flags

- 🚩 **Disabled job still wired** (F1) — dead-code-by-config ambiguity
- 🚩 **Mock imports in production** (F2, cross-ref M04 F3)
- 🚩 **Reset URL in plaintext** (F4) — defense-in-depth gap

---

## Phase 3 deep-dive candidates

None — utils + jobs are small. Phase 4 surgical fixes sufficient.

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F1 vital-processor decision (remove or document) | P2 | 0.5-1h |
| 2 | F4 Verify reset token TTL + single-use | P2 | 30 min |
| 3 | F3 Add `tooManyRequests` factory | P3 | 5 min |
| 4 | F5 Fix typo `SẾPF` → `SẾP` | P3 | 2 min |

**Total: 1.5-2h.**

---

## Cross-references

- M04 F3 (ai-models-mlops mock in production)
- M02 — vital-processor toggle endpoints
- M05 — ApiError used everywhere in middleware

---

## Verdict

**🟢 Mature** with minor cleanup. ApiError + Prisma singleton + catchAsync are well-designed primitives. Main item: F1 vital-processor decision (does anh want it removed or documented?).
