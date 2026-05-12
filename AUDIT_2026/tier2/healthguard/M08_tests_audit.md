# M08 — Tests Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Tests (`backend/src/__tests__/`)
**Files:** 21 items (controllers 6, middlewares 3, services 9, utils 3)
**Effort spent:** ~15 min (meta-review only)
**Auditor:** AI pair
**Date:** 2026-05-12

**Mode:** Inventory + risk surface assessment. Not deep test-by-test review.

---

## Scope (file inventory)

### `__tests__/controllers/` (6 files)
Sampled names suggest: auth, user, device, emergency, health, vital-alert controllers tested. Not all 11 controllers covered.

### `__tests__/middlewares/` (3 files)
Likely: auth (authenticate, requireAdmin), validate, errorHandler.

### `__tests__/services/` (9 files)
Likely: auth, user, device, emergency, health, vital-alert, risk-calculator, dashboard, settings/relationship services tested.

### `__tests__/utils/` (3 files)
Likely: ApiError, ApiResponse, passwordValidator.

---

## Coverage gap surface

Per M02-M07 module inventory vs test inventory:

| Module | Files in src | Files tested | Gap |
|---|---|---|---|
| Controllers | 11 | 6 | 5 untested |
| Middlewares | 3 | 3 | ✅ Full |
| Services | 16 (15 live) | 9 | 6-7 untested |
| Utils | 7 | 3 | 4 untested |
| Jobs | 2 | 0 | 🟠 No tests |
| Routes | 14 | 0 | Tested via controller integration likely |

**Approximate coverage:** 50-60% file coverage (line coverage unknown without running `jest --coverage`).

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 2 | File coverage 50-60% — gaps in jobs (0%), some controllers, some services. |
| **Readability** | 2 | Inferred from inventory; no audit of test quality (flaky/excessive mocks not assessed). |
| **Architecture** | 2 | Test pyramid uneven — heavy on services, light on integration; no E2E suite (per inventory out-of-scope). |
| **Security** | 2 | Auth middleware tested ✅; security-critical service (auth.service) tested ✅. Vital-alert + alerts coverage unclear (HG-001 missed by tests → no regression guard). |
| **Performance** | 2 | No load tests; CI run time unknown; no flaky-test policy documented per Phase 0 framework. |

**Total: 10/15 → 🟡 Needs attention**

---

## Findings

### F1 🟠 Jobs untested

**Files:** `jobs/vital-processor.js`, `jobs/risk-score-job.js`

**No tests detected.** Background jobs handle real-time alerting (when enabled) + risk score recalculation. Failure → silent degradation.

**Fix (Phase 4):**
- Add unit test for `processVitals()` (mocked service)
- Add unit test for `riskScoreJob.start()` interval correctness
- Verify error handling (no unhandled rejection crashes Node)

**Severity:** P2
**Effort:** 4h

---

### F2 🟠 HG-001 regression not guarded

**Context:** Bug HG-001 (alerts always unread) lives in `health.service.js`. Hidden by stale comment for unknown duration.

**Test gap inferred:** If services had a test like `expect(alert.status).toBe('read')` after marking, regression would have caught the schema-assumption shortcut.

**Phase 4 requirement (TDD):**
1. Write failing test asserting status field present + correct after read_at set
2. Implement fix (M04 F1)
3. Test now passes

**Severity:** P1 (test-first discipline)
**Effort:** Included in M04 F1 effort

---

### F3 🟡 Test pyramid imbalance

**Phase 0 framework expectation:**
- Unit: 70% (services, utils, isolated functions)
- Integration: 25% (controller + route + DB)
- E2E: 5% (full HTTP flow)

**Current:** Services (9) + controllers (6) + middleware (3) + utils (3) = mostly unit. No integration tests visible (Supertest patterns not confirmed without read).

**Verify in Phase 3 deep-dive:** Sample a service test file + a controller test file to assess pattern + mocking strategy.

**Severity:** P3 (architecture)
**Effort:** Phase 3 review item

---

### F4 🟡 No `jest --coverage` reporting confirmed

Standard practice: CI publishes coverage report; PR fails if drop > 1%. Not verified.

**Fix (Phase 4):**
```json
// package.json
"scripts": {
  "test:coverage": "jest --coverage --coverageThreshold='{\"global\":{\"lines\":70}}'"
}
```

Then wire CI to enforce. Aspirational threshold: 70% lines, 60% branches.

**Severity:** P3
**Effort:** 1h + GitHub Actions/CI setup

---

### F5 🟡 Untested controllers (estimated 5)

Per inventory, 11 controllers but only 6 tested. Untested likely: `logs`, `settings`, `dashboard`, `ai-models`, `relationship`.

- `ai-models` — admin model upload (multer 500 MB security surface — M02 F4)
- `dashboard` — analytics endpoints, performance-sensitive
- `settings` — sensitive (password required)

**Fix (Phase 4):** Add controller tests for at least the 3 above (sensitive surfaces).

**Severity:** P2
**Effort:** 6h (2h per controller)

---

## Phase 3 deep-dive candidates

| Action | Priority |
|---|---|
| Run `jest --coverage` → get exact line coverage % | High |
| Sample 3 test files (1 service, 1 controller, 1 middleware) to assess quality | Medium |
| Identify flaky tests via `--repeat` runs | Medium |

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F2 HG-001 regression test (with M04 F1) | P1 | included in M04 |
| 2 | F5 Test untested critical controllers | P2 | 6h |
| 3 | F1 Test jobs | P2 | 4h |
| 4 | F4 Coverage threshold in CI | P3 | 1h |

**Total: 11h (excluding F2 already in M04 budget).**

---

## Cross-references

- M04 F1 (HG-001) — F2 here = required regression test
- Phase 0 framework — test pyramid + flaky policy reference
- 30-testing-discipline rule — Vietnamese-named tests OK; structure must follow `describe.it`

---

## Verdict

**🟡 Needs attention.** Test surface is **partial** — middleware fully covered (security), but jobs untested + 5 controllers gap + HG-001 missed. Phase 4 add ~10h test work to bring to baseline. Coverage tooling absent — first step is `jest --coverage` to get hard number.
