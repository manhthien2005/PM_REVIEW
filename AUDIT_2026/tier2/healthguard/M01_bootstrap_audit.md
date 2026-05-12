# M01 — Bootstrap Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Bootstrap (`backend/src/app.js` + `server.js`)
**LoC:** ~105
**Effort spent:** ~45 min
**Auditor:** AI pair
**Date:** 2026-05-12

---

## Scope

| File | LoC | Role |
|---|---|---|
| `backend/src/app.js` | 66 | Express app factory — middleware chain, CORS, route mount |
| `backend/src/server.js` | 39 | HTTP server boot, WebSocket init, background jobs start |

**Mode:** Full (small module).

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | BigInt.toJSON patch correct, trust proxy set, error handler last. |
| **Readability** | 3 | 66 lines clean, section comments, single responsibility. |
| **Architecture** | 2 | Mount order correct; missing helmet, compression, body size guard at app level. |
| **Security** | **1** | **CORS reflection bug 🔴**; no helmet, no global rate limit; fallback CORS = effective `*` with credentials. |
| **Performance** | 2 | 10 MB JSON limit (generous but safe); no compression middleware. |

**Total: 11/15 → 🟡 trending 🔴 (Security 1/3)**

---

## Critical findings

### F1 🔴 CORS reflection bug (mirrors D-013 model-api)

**File:** `backend/src/app.js:24-32`

```js
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    return callback(null, origin);   // <-- echoes ANY origin
  },
  credentials: true,
  ...
}));
```

**Impact:**
- Effectively `Access-Control-Allow-Origin: *` but with `Access-Control-Allow-Credentials: true`
- Browser CSRF protection bypassed for cookie-auth flows
- Same anti-pattern as model-api (Phase -1.B finding D-013)

**Fix (Phase 4):**
```js
const allowedOrigins = (env.ALLOWED_ORIGINS || '').split(',').filter(Boolean);
app.use(cors({
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    if (allowedOrigins.includes(origin)) return cb(null, true);
    return cb(new Error('CORS rejected'));
  },
  credentials: true,
  ...
}));
```

Add `ALLOWED_ORIGINS=https://admin.healthguard.app,http://localhost:5173` to `.env`.

**Severity:** P0
**Effort:** 0.5h

---

### F2 🟠 Missing security headers (no helmet)

**File:** `backend/src/app.js`

No `helmet()` middleware → missing:
- `X-Frame-Options` (clickjacking)
- `Content-Security-Policy`
- `Strict-Transport-Security`
- `X-Content-Type-Options: nosniff`

**Fix (Phase 4):**
```js
const helmet = require('helmet');
app.use(helmet({
  contentSecurityPolicy: env.NODE_ENV === 'production' ? undefined : false,
}));
```

**Severity:** P1
**Effort:** 0.5h (+ test CSP doesn't break SPA)

---

### F3 🟡 No global rate limit

Auth routes have per-endpoint limiters (login, forgot, change-password — 3-5 req/15min). **Other admin endpoints have none.**

**Risk:** Bruteforce on `/api/v1/admin/users/:id` to enumerate user IDs; large `/dashboard` queries DoS.

**Fix (Phase 4):**
```js
const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  standardHeaders: true,
});
app.use('/api/v1/admin/', globalLimiter);
```

**Severity:** P2
**Effort:** 0.5h

---

## Readability findings

### F4 🟢 Clean structure

- 66 lines, comment-delimited sections, no dead code.
- Healthcheck `GET /health` placed **before** CORS to bypass middleware overhead (line 20-22) — good intentional design.
- SPA fallback correctly skips `/api/` paths (line 53-56).
- `app.set('trust proxy', 1)` — correct for Heroku/Cloudflare.

---

## Architecture findings

### F5 🟡 Mount order observation

```js
app.use('/api/v1/internal', internalRoutes);  // line 44
app.use('/api/v1/admin', routes);              // line 47
```

**Issue:** Internal routes mounted at app level (skips admin auth middleware) but `internal.routes.js` has its own `checkInternalSecret` middleware at router level — **correct pattern**.

**However:** internal secret default fallback `'internal-secret-key'` (see M02 audit F11) weakens this.

---

## Security findings (rolled up)

| ID | Issue | File | Fix effort |
|---|---|---|---|
| F1 | CORS reflection | `app.js:24-32` | 0.5h |
| F2 | No helmet | `app.js` | 0.5h |
| F3 | No global rate limit | `app.js` | 0.5h |
| — | Internal secret fallback | `routes/internal.routes.js:12` (M02) | — |

---

## Performance findings

### F6 🟡 No compression

Add `app.use(compression())` for response gzip — admin dashboard responses can be 100 KB+.

**Fix (Phase 4):**
```js
const compression = require('compression');
app.use(compression());
```

**Effort:** 0.25h
**Impact:** -60-80% payload on JSON list responses.

---

## Anti-pattern flags

- 🚩 **CORS-reflection-allow-credentials** (F1) — security anti-pattern, repeated across repos
- 🚩 **No security headers** (F2) — common omission

---

## Phase 3 deep-dive candidates

None at module level — bootstrap is small + simple. F1, F2, F3 are Phase 4 surgical fixes.

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F1 CORS strict allowlist | P0 | 0.5h |
| 2 | F2 Add helmet | P1 | 0.5h |
| 3 | F6 Add compression | P2 | 0.25h |
| 4 | F3 Global rate limit | P2 | 0.5h |

**Total: 1.75h**

**Cross-repo coordination:** Same CORS fix pattern as model-api (D-013). Use identical env var name `ALLOWED_ORIGINS` for consistency.

---

## Cross-references

- D-013 (model-api CORS) — Phase -1.B
- M04 model-api bootstrap audit — identical CORS anti-pattern
- ADR-004 (API prefix `/api/v1/{domain}/*`) — bootstrap mounts already comply

---

## Verdict

**🟡 Acceptable but with critical security gap (F1 CORS).** Module structure + readability solid; security at bootstrap level needs Phase 4 surgical fix (~2h total).
