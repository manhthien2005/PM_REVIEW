# M02 — Routes Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Routes (`backend/src/routes/`)
**Files:** 14 (index + 13 route modules)
**LoC:** ~870
**Effort spent:** ~1.5h
**Auditor:** AI pair
**Date:** 2026-05-12

---

## Scope

| File | LoC | Auth | Rate Limit | Validate |
|---|---|---|---|---|
| `index.js` | 36 | router level | — | — |
| `auth.routes.js` | 30 | per-route | per-route (3) | — |
| `user.routes.js` | 89 | router.use | 100/min | schema |
| `device.routes.js` | 77 | router.use | 100/min | schema |
| `emergency.routes.js` | 92 | router.use | 100/min | schema |
| `health.routes.js` | 221 | router.use | 60/min | — |
| `dashboard.routes.js` | 168 | router.use | 60/min | **none** 🟡 |
| `vital-alerts.js` | 222 | per-route | **none** 🟡 | inline |
| `vital-alert.routes.js` | 100 | router.use | 30/min | **none** 🟡 |
| `logs.routes.js` | 54 | router.use | 100/min | schema |
| `settings.routes.js` | 33 | per-route | **none** 🟡 | schema |
| `relationship.routes.js` | 64 | router.use | 100/min | schema |
| `ai-models.routes.js` | 72 | router.use | **none** 🟡 | partial |
| `internal.routes.js` | 118 | **fallback secret** 🔴 | none | inline |

**Mode:** Full (security-critical, surface area).

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | Route handlers wire correctly to controllers; URL patterns consistent. |
| **Readability** | 3 | JSDoc + Swagger annotations; section header comments; Vietnamese labels. |
| **Architecture** | **1** | D-007 `/users` double-mount (relationship + user routes); D-010 `/admin/vital-alerts` double prefix `/api/v1/admin/admin/vital-alerts`. |
| **Security** | **1** | Internal secret hardcoded fallback; multer 500 MB no rate limit (DoS); 4 modules missing rate limit; D-009 confirmed **false positive**. |
| **Performance** | 3 | Rate limit pattern consistent where applied; pagination param validation present. |

**Total: 11/15 → 🟡 Needs attention (low Arch + Sec)**

---

## Confirmed P0/P1 Phase 4 fixes

### F1 🔴 D-007 — `/users` mount conflict (Architecture)

**File:** `routes/index.js:19-20`

```js
router.use('/users', relationshipRoutes);  // GET /relationships/search inside
router.use('/users', userRoutes);          // GET /, /:id, etc.
```

**Issue:**
- Express tries `relationshipRoutes` first, falls through to `userRoutes` if no match
- `/users/relationships/search` works only because `relationshipRoutes` lacks `/:id` catch
- Adding `/relationships/search` to `userRoutes` would silently shadow
- Order-dependent fragility

**Fix (Phase 4):**
```js
// Option A: separate mount paths
router.use('/users',              userRoutes);
router.use('/relationships',      relationshipRoutes);  // move /relationships routes out

// Option B: merge into one router
// (preferred — cleaner, but more refactor)
```

**Severity:** P1 (works today but fragile)
**Effort:** 1h (move + update frontend URLs if used)

---

### F2 🔴 D-010 — Double `admin` prefix (Architecture)

**File:** `routes/index.js:27-28`

```js
router.use('/vital-alerts',       vitalAlertRoutes);          // → /api/v1/admin/vital-alerts
router.use('/admin/vital-alerts', vitalAlertAdminRoutes);    // → /api/v1/admin/admin/vital-alerts  ← bug
```

**App-level mount:** `app.js:47 app.use('/api/v1/admin', routes)` — adds `/api/v1/admin` prefix.

So the second mount creates **`/api/v1/admin/admin/vital-alerts/*`** — wrong URL!

**Fix (Phase 4):**
```js
router.use('/vital-alerts',       vitalAlertRoutes);     // public-side admin endpoints
router.use('/vital-alerts/admin', vitalAlertAdminRoutes); // processor toggles, threshold mgmt
// OR rename the file's purpose — they serve overlapping concerns
```

**Severity:** P1 (admin frontend may have hardcoded wrong URL)
**Effort:** 1h + frontend service URL update

---

### F3 🔴 Internal secret fallback hardcoded (Security)

**File:** `routes/internal.routes.js:11-12`

```js
const secret = req.headers['x-internal-secret'];
const expectedSecret = process.env.INTERNAL_SECRET || 'internal-secret-key';
```

**Issue:**
- If `INTERNAL_SECRET` env not set, **anyone** knowing the literal `'internal-secret-key'` (in public git history) can call internal endpoints
- 3 endpoints affected: `/emit-alert`, `/emit-emergency`, `/emit-risk`
- These broadcast WebSocket events — admin clients receive forged alerts/SOS

**Same anti-pattern in model-api M04 audit (Track 4) — coordinated fix.**

**Fix (Phase 4):**
```js
const expectedSecret = process.env.INTERNAL_SECRET;
if (!expectedSecret) {
  throw new Error('INTERNAL_SECRET env var not set — refusing to start');
}
// fail fast on boot, not on first request
```

**Severity:** P0
**Effort:** 0.5h + env.js validation (raise on undefined)

---

### F4 🟠 Multer 500 MB memory upload (Security + Performance)

**File:** `routes/ai-models.routes.js:34-37`

```js
const multerUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 500 * 1024 * 1024 },  // 500 MB
});
```

**Issues:**
1. **Memory storage** — 500 MB upload loads entirely into Node heap; 3 concurrent uploads = 1.5 GB RAM
2. **No rate limit on `ai-models.routes.js`** — single bad actor can OOM-kill server
3. **No file type/extension check at route level** — depends on controller

**Fix (Phase 4):**
```js
const multerUpload = multer({
  storage: multer.diskStorage({ destination: '/tmp/uploads' }),
  limits: { fileSize: 200 * 1024 * 1024 },  // 200 MB more conservative
  fileFilter: (req, file, cb) => {
    const allowedExts = ['.tflite', '.onnx', '.h5', '.pkl'];
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, allowedExts.includes(ext));
  },
});

const aiModelsLimiter = rateLimit({ windowMs: 60_000, max: 20 });
router.use(authenticate, requireAdmin, aiModelsLimiter);  // add rate limit
```

**Severity:** P1
**Effort:** 2h + cleanup job for `/tmp/uploads`

---

### F5 🟡 Missing rate limit (4 modules)

**Files:**
- `vital-alerts.js` (5 routes, no router-level limiter)
- `vital-alert.routes.js` ✅ has 30/min (good)
- `settings.routes.js` (sensitive! requires password — bruteforce risk)
- `ai-models.routes.js` (covered by F4)
- `internal.routes.js` (internal — debatable, but events flood possible)

**Fix (Phase 4):** Add module-level limiter consistent with peers (100/min admin, 30/min sensitive).

**Severity:** P2
**Effort:** 30 min

---

### F6 🟡 Dashboard routes missing query validation

**File:** `routes/dashboard.routes.js`

Routes accept `days`, `limit` query params (lines 89-126, 154) but **no `validate()` schema**. Controller likely does `parseInt` — but bad input may DoS large queries.

**Fix (Phase 4):**
```js
const dashboardQueryRules = {
  query: {
    days: { type: 'string', pattern: /^(7|14|30|90)$/ },
    limit: { type: 'string', pattern: /^\d{1,3}$/ },
  },
};
router.get('/recent-incidents', validate(dashboardQueryRules), ...);
```

**Severity:** P2
**Effort:** 30 min

---

### F7 🟡 D-009 — **FALSE POSITIVE** (clarification)

**Phase -1.B finding D-009:** `/vital-alerts/* no auth` → **WRONG**.

**Reality:**
- `vital-alerts.js` lines 75-79, 114-119, 145-151, 185-190, 216-221 — every route has `authenticate, requireAdmin`
- `vital-alert.routes.js:18` — router-level `authenticate, requireAdmin`
- Both files = auth-protected

**Action:** Update `api_contract_v1.md` D-009 status to `confirmed_false_positive`. Phase -1 spec drift docs need correction.

---

## Strengths

### F8 🟢 Comprehensive validation rules

`user.routes.js`, `device.routes.js`, `emergency.routes.js`, `logs.routes.js`, `relationship.routes.js`, `ai-models.routes.js`, `settings.routes.js` — all use `validate(schema)` consistently with structured rules (type, enum, sanitize, pattern).

### F9 🟢 Granular rate limits per domain

- Auth: 3-5 req/15min (tight)
- Health/Dashboard: 60/min
- Users/Devices/Emergencies/Relationships/Logs: 100/min
- Vital alerts (admin sub): 30/min

Sensible defaults reflecting endpoint cost.

### F10 🟢 Swagger annotations on most files

`vital-alerts.js`, `health.routes.js`, `dashboard.routes.js`, `vital-alert.routes.js` have JSDoc Swagger blocks. Generated `/admin-docs` UI.

---

## Anti-pattern flags

- 🚩 **Route mount order dependence** (F1 D-007)
- 🚩 **URL prefix double-stacking** (F2 D-010)
- 🚩 **Hardcoded secret fallback** (F3) — repeated across model-api + this repo
- 🚩 **Memory storage for large uploads** (F4)
- 🚩 **PATCH + PUT for same handler** (e.g., `user.routes.js:82-83`) — REST ambiguity, not actively harmful

---

## Phase 3 deep-dive candidates

| File | Reason | Priority |
|---|---|---|
| `index.js` — refactor mount strategy | F1 + F2 fix architecture | Medium |
| `internal.routes.js` | F3 + bug HG-001 surface (websocket emit pipeline) | High |
| `ai-models.routes.js` | F4 + multer pipeline overhaul | Medium |

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F3 Internal secret fail-fast | P0 | 0.5h |
| 2 | F1 D-007 mount separation | P1 | 1h |
| 3 | F2 D-010 prefix fix | P1 | 1h |
| 4 | F4 Multer disk + filter + rate limit | P1 | 2h |
| 5 | F5 Missing rate limits | P2 | 0.5h |
| 6 | F6 Dashboard query validate | P2 | 0.5h |
| 7 | F7 Update D-009 status in Phase -1.B | doc | 15 min |

**Total: 5.75h.**

---

## Cross-references

- D-007 (mount conflict) — Phase -1.B confirmed here
- D-009 (vital-alerts no auth) — Phase -1.B **FALSE POSITIVE** confirmed here
- D-010 (double admin prefix) — Phase -1.B confirmed here
- D-011 (internal no secret) — Phase -1.B **partially mitigated** (has check, fallback weak)
- ADR-004 (`/api/v1/{domain}/*`) — current paths compliant except D-010

---

## Verdict

**🟡 Needs attention.** Routes layer has **3 confirmed Phase -1 drifts** (D-007, D-010, D-011-partial) + 1 new finding (F4 multer DoS). All P0/P1 fixes total ~5h. False-positive D-009 reduces Track 4 critical scope. After fix → expect 🟢 Mature band.
