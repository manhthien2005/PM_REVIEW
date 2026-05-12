# M05 — Middlewares Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Middlewares (`backend/src/middlewares/`)
**LoC:** ~280 (auth 119 + errorHandler 47 + validate 120)
**Effort spent:** ~50 min
**Auditor:** AI pair
**Date:** 2026-05-12

---

## Scope

| File | LoC | Role |
|---|---|---|
| `auth.js` | 119 | JWT verify + role check + rate limiters (login/forgot/change-pw) |
| `errorHandler.js` | 47 | Global error formatter + Prisma error mapping |
| `validate.js` | 120 | Schema-driven request validation |

**Mode:** Full (security-critical, small).

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | JWT verify + token_version invalidation; Prisma P2002/P2025 mapped; date range validation. |
| **Readability** | 3 | Each file single-responsibility, JSDoc comments, Vietnamese error messages consistent. |
| **Architecture** | 2 | Solid auth/role/limit composition; `validate.js` lacks nested object + strict mode. |
| **Security** | 2 | Strong JWT pattern; **stack trace leaked in dev mode** (intentional but flag); no CSRF token with cookie auth. |
| **Performance** | 3 | JWT verify + 1 user query per request (acceptable); rate limit in-memory (single-instance OK). |

**Total: 13/15 → 🟢 Mature**

---

## Strengths (reference patterns)

### F1 🟢 Strong JWT + token_version pattern

**File:** `auth.js:25-43`

```js
const decoded = jwt.verify(token, env.JWT_SECRET);
const user = await prisma.users.findFirst({
  where: { id: decoded.id, deleted_at: null },
  select: { id, email, role, is_active, full_name, token_version },
});
if (!user.is_active) throw ApiError.locked(...);
if (decoded.tokenVersion !== user.token_version) throw ApiError.unauthorized(...);
```

**Why good:**
- DB roundtrip on every request — token revocation works (logout, password change bumps version)
- Soft delete check `deleted_at: null` enforced at auth layer
- Account-locked separate status code (423)
- Select only needed columns

**This is the reference pattern for `health_system/backend` to adopt** — em sẽ note trong Track 2.

---

### F2 🟢 Composable rate limiters

**File:** `auth.js:82-116`

Three named limiters exported, applied per-route (login, forgot, change-password). Each has tailored window/max.

**Cross-check** with `health.routes.js:9-15` and `vital-alert.routes.js:9-15` — additional per-router limiters. Consistent pattern.

---

### F3 🟢 Validate middleware features

**File:** `validate.js`

Supports:
- Required + type check
- Sanitize HTML (line 49-53 — XSS protection)
- Regex pattern
- Enum
- Min/max length
- Custom date validation (line 77-97 — birthdate bounds 1900-now-150y)
- Custom password validator (line 100-108)

Good coverage for boundary validation.

---

## Findings

### F4 🟠 Validate `validate.js` lacks strict mode

**File:** `validate.js:20-117`

**Issue:** Extra fields beyond `rules[source]` are **silently passed through**. No `additionalProperties: false` equivalent.

**Risk:** Mass assignment — a client can POST `{ email, full_name, role: 'admin' }` to a user-update endpoint, and if controller spreads `req.body` to Prisma update, role gets escalated.

**Verify in M03 (controllers):** check if controllers do `prisma.users.update({ data: req.body })` directly.

**Fix (Phase 4):**
```js
// Add at end of validate loop
const allowedFields = new Set(Object.keys(fields));
const extraFields = Object.keys(data).filter(f => !allowedFields.has(f));
if (extraFields.length && rule.strict !== false) {
  errors.push({ field: extraFields.join(','), message: 'Trường không được phép' });
}
```

**Severity:** P1 (depends on M03 verification)
**Effort:** 1h + test all consumers

---

### F5 🟠 No CSRF protection with cookie + credentials

**Context:** `app.js` sets `credentials: true` for CORS. If JWT tokens are stored in cookies (not just localStorage), the app is vulnerable to CSRF because:
- F1 CORS reflection (M01) lets any origin send credentialed requests
- No CSRF token middleware

**Verify:** Check `frontend/src/services/` to confirm whether tokens are in cookies or localStorage.

**If cookies:** Add `csurf` or `csrf-csrf` package + double-submit token.

**Severity:** P1 (conditional — depends on token storage)
**Effort:** 2h + frontend coordination

---

### F6 🟡 Stack trace in dev error response

**File:** `errorHandler.js:41`

```js
...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
```

**Status:** Acceptable for dev. Verify production env strict (`NODE_ENV=production` always set in prod).

**Risk:** If `NODE_ENV` accidentally unset/blank, default behavior may leak stack.

**Fix (Phase 4 hardening):**
```js
...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
```

Inverts logic — leak only when NOT production (safer fail-closed).

**Severity:** P2
**Effort:** 5 min

---

### F7 🟡 `validate.js` no nested object validation

**File:** `validate.js:29-109`

Rules iteration is flat — cannot validate `{ user: { email, password } }` shape.

**Impact:** `vital-alerts.js:33-42` reimplements nested validation manually (`validateVitalData`). Code duplication.

**Fix (Phase 4):** Switch to `zod` or `joi` for one-liner schemas. Out of scope for Phase 1.

**Severity:** P3 (refactor candidate Phase 3)
**Effort:** Estimated 8h migration if going Phase 3.

---

## Anti-pattern flags

- 🚩 **Silent extra field acceptance** (F4) — mass assignment risk
- 🚩 **Credentials true without CSRF** (F5) — conditional on cookie use

---

## Phase 3 deep-dive candidates

| File | Reason | Priority |
|---|---|---|
| `validate.js` | Migrate to `zod` for nested + strict mode (P3) | Low |
| `auth.js` | If session/cookie tokens added, add CSRF (P1 conditional) | Medium |

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F4 Add strict-mode to validate | P1 | 1h + tests |
| 2 | F5 Add CSRF if cookies used | P1* | 2h |
| 3 | F6 Invert NODE_ENV check | P2 | 5 min |

\* P1 conditional — verify token storage first.

**Total: 3-4h.**

---

## Cross-references

- D-009 Phase -1.B (vital-alerts no auth) — **FALSE POSITIVE confirmed** by M02 audit (auth is applied in both vital-alerts files)
- ADR-004 (auth `iss=healthguard-admin`) — verify in `auth.service.js` (M04)
- Bug HG-001 (alerts always unread) — not in auth scope

---

## Verdict

**🟢 Mature module.** Strong JWT pattern + composable rate limiting + sanitize HTML. F4 + F5 are surgical Phase 4 hardening (~3-4h coordinated).

**Reference value:** F1 pattern (JWT + token_version + DB roundtrip) is **best-in-class** across the 5 repos. Adopt in `health_system/backend` (Track 2).
