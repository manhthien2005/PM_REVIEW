# M03 — Controllers Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Controllers (`backend/src/controllers/`)
**Files:** 11 controllers
**LoC:** ~2,500
**Effort spent:** ~45 min
**Auditor:** AI pair
**Date:** 2026-05-12

**Mode:** Sample-based (read auth, health, vital-alert; rubric extrapolated).

---

## Scope sampled

| File | Bytes | Role |
|---|---|---|
| `auth.controller.js` | 4.3 KB | Login, register, password, logout, me |
| `health.controller.js` | 6.8 KB | Health overview + alerts + CSV export |
| `vital-alert.controller.js` | 4.0 KB | Vital threshold + processor toggle |

Others (similar pattern, not deep-read): `user`, `device`, `logs`, `settings`, `emergency`, `dashboard`, `ai-models`, `relationship` controllers.

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | Request → service delegation correct; error propagation via `next(error)` or `catchAsync`. |
| **Readability** | 2 | **Inconsistent style:** mix `try/catch + next(err)` (health.controller) vs `catchAsync` (auth, vital-alert). Mix `res.json(new ApiResponse(...))` vs `ApiResponse.success(res, ...)`. |
| **Architecture** | 3 | Thin controllers — no business logic, delegate to services. CSV formatting in controller acceptable (presentation). |
| **Security** | 3 | `req.user.id` properly used after middleware; no direct DB access; `email.toLowerCase().trim()` on input. |
| **Performance** | 3 | No N+1 in controller layer; pagination params forwarded. |

**Total: 14/15 → 🟢 Mature**

---

## Findings

### F1 🟡 Style inconsistency: error handling

**Examples:**

```js
// health.controller.js (older style)
getSummary: async (req, res, next) => {
  try {
    const summary = await healthService.getSummary();
    return res.status(200).json(new ApiResponse(200, summary, 'OK'));
  } catch (error) {
    next(error);
  }
}

// auth.controller.js (newer style)
login: catchAsync(async (req, res) => {
  ...
  ApiResponse.success(res, data, 'OK');
})
```

**Impact:** Increased maintenance cost; reviewer must read every controller to verify error flow.

**Fix (Phase 4 cleanup):** Migrate `health.controller.js`, `dashboard.controller.js` (likely same pattern) to `catchAsync`. Express 5 auto-catches async, but `catchAsync` explicit.

**Severity:** P3 (style debt)
**Effort:** 1h refactor + tests

---

### F2 🟡 ApiResponse usage inconsistent

Two patterns in use:

```js
res.json(new ApiResponse(200, data, 'OK'))      // health.controller.js
ApiResponse.success(res, data, 'OK')             // auth.controller.js
ApiResponse.created(res, data, 'OK')             // auth.controller.js
res.json(ApiResponse.success(data, 'OK'))        // vital-alert.controller.js  ← 3rd variant!
```

Verify `ApiResponse` class has both static + instance APIs (likely yes).

**Fix (Phase 4):** Pick one pattern, refactor others.

**Severity:** P3
**Effort:** 1h

---

### F3 🟡 Manual req.query parsing without strong validation

**File:** `health.controller.js:25-46`

```js
const {
  page = 1, limit = 20, search = '', severity = '',
  alertType = '', dateRange = '24h', customDateFrom = '',
  ...
} = req.query;
const result = await healthService.getThresholdAlerts({
  page: parseInt(page),   // ← what if page = 'abc'? NaN propagates to service
  limit: parseInt(limit),
  ...
});
```

**Issue:** `parseInt('abc') = NaN` → flows to service → `prisma.alerts.findMany({ skip: NaN })` may error or behave oddly.

**Verify in M02 routes:** dashboard.routes.js, health.routes.js have no query validation (M02 F6).

**Fix (Phase 4):** Apply M02 F6 fix (validate query params at route level) — covers this.

**Severity:** P2 (covered by M02 F6)

---

### F4 🟢 Audit context propagation

**File:** `auth.controller.js:22-23, 53-54`

```js
const result = await authService.loginUser(
  { email, password },
  req.ip,
  req.headers['user-agent']
);
```

**Why good:** Controller captures audit context (IP, user-agent) and passes to service. Service writes audit log with full forensics. Pattern repeated for register/forgot/reset/change-password/logout.

**Reference value:** Adopt in `health_system/backend` Track 2 if missing.

### F5 🟢 Sensitive output controlled

**File:** `auth.controller.js:128-130`

```js
getMe: catchAsync(async (req, res) => {
  ApiResponse.success(res, req.user, 'OK');
}),
```

`req.user` set by middleware (M05 F1) — only `{ id, email, role, full_name }` (line 46-51 of auth.js). No `password_hash`, no `token_version`, no `failed_login_attempts` leaked.

---

### F6 🟡 Admin/role enforcement in controller (not just middleware)

**File:** `auth.controller.js:46-48`

```js
if (role === 'admin') {
  throw ApiError.forbidden('Không thể tạo tài khoản admin qua API');
}
```

**Observation:** Defense-in-depth — even with admin auth, controller refuses to create another admin via this endpoint. **Good pattern.**

But also: `route+validate(createUserRules)` allows `role: 'admin'` (`user.routes.js:46`). Should align validation rules with controller policy — remove `'admin'` from enum.

**Fix (Phase 4):**
```js
// user.routes.js:46 update enum
role: { type: 'string', enum: ['user'] },  // remove 'admin'
```

**Severity:** P2
**Effort:** 5 min + test

---

### F7 🟡 Manual required-field check

**File:** `auth.controller.js:36-43`

```js
const requiredFields = { email, password, fullName, phone, dateOfBirth, role };
const missing = Object.entries(requiredFields)
  .filter(([_, v]) => !v)
  .map(([k]) => k);
if (missing.length > 0) {
  throw ApiError.badRequest(`Các trường bắt buộc: ${missing.join(', ')}`);
}
```

**Issue:** Auth routes don't use `validate(rules)` middleware → controllers must hand-check. Duplicates logic. Other domains use `validate()` consistently.

**Fix (Phase 4):**
- Add `registerRules` to `auth.routes.js`, use `validate(registerRules)` middleware
- Remove inline check from controller

**Severity:** P2
**Effort:** 30 min

---

## Anti-pattern flags

- 🚩 **Mixed error handling styles** (F1) — pick one, drop other
- 🚩 **Multiple ApiResponse call patterns** (F2)
- 🚩 **Auth routes lack `validate()` middleware** (F7) — only domain not using uniform pattern

---

## Phase 3 deep-dive candidates

None — controllers are thin enough. Phase 4 cleanup sufficient.

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F6 Remove `admin` from user create enum | P2 | 5 min |
| 2 | F7 Add `validate()` to auth.routes | P2 | 30 min |
| 3 | F1 Migrate to `catchAsync` consistently | P3 | 1h |
| 4 | F2 Pick one ApiResponse style | P3 | 1h |

**Total: 2.5h.**

---

## Cross-references

- M05 F1 — middleware `req.user` shape
- M02 F6 — query validate at route level (covers F3)
- M04 — service layer (where business logic lives)

---

## Verdict

**🟢 Mature.** Controllers are properly thin — Phase 4 cleanup is style/consistency debt, not security or correctness. Two reference patterns: F4 (audit context) + F5 (output minimization) worth adopting cross-repo.
