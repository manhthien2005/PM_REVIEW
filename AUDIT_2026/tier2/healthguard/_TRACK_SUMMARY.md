# Phase 1 Track 1A — HealthGuard Backend Macro Audit Summary

**Track:** Phase 1 Track 1A
**Repo:** `HealthGuard/backend/`
**Stack:** Express + Prisma
**Scope:** 8 modules (M01-M08)
**Total LoC audited:** ~11,500
**Effort spent:** ~5.5h macro audit (vs estimated 38h — Phase 1 = rubric-only, not deep)
**Date:** 2026-05-12
**Auditor:** AI pair

---

## Module scores aggregated

| Module | LoC | C | R | A | S | P | Total | Band |
|---|---|---|---|---|---|---|---|---|
| M01 Bootstrap | 105 | 3 | 3 | 2 | **1** | 2 | **11/15** | 🟡 |
| M02 Routes | 870 | 3 | 3 | **1** | **1** | 3 | **11/15** | 🟡 |
| M03 Controllers | 2,500 | 3 | 2 | 3 | 3 | 3 | **14/15** | 🟢 |
| M04 Services | 6,000 | **1** | 2 | 2 | 3 | 2 | **10/15** | 🟡 |
| M05 Middlewares | 280 | 3 | 3 | 2 | 2 | 3 | **13/15** | 🟢 |
| M06 Prisma | 577 | 3 | 3 | 2 | 2 | 3 | **13/15** | 🟢 |
| M07 Jobs+Utils | 1,500 | 3 | 3 | 2 | 2 | 3 | **13/15** | 🟢 |
| M08 Tests | (test files) | 2 | 2 | 2 | 2 | 2 | **10/15** | 🟡 |
| **Avg** | — | **2.6** | **2.6** | **2.0** | **2.0** | **2.6** | **11.9/15** | 🟡 |

**Verdict aggregate:** **🟡 Needs attention** — pulled down by Architecture + Security axes; M04 Correctness 1/3 due to active HG-001 bug.

---

## Critical findings consolidated

### 🔴 P0 — Cross-repo coordinated chain

| # | ID | File:line | Issue | Cross-repo? |
|---|---|---|---|---|
| 1 | **HG-001** | M04 `health.service.js:180-181` | Stale comment hides schema-assumption bug; alerts always 'unread' | Coordinates with Track 1B (M11 `ThresholdAlertsTable.jsx`) |
| 2 | **D-013 mirror** | M01 `app.js:24-32` | CORS reflection (`origin → callback(null, origin)` with credentials) | Same pattern as model-api D-013 (Track 4 P0) |
| 3 | **D-011 partial** | M02 `internal.routes.js:11-12` | Internal secret has check **but** hardcoded fallback `'internal-secret-key'` | Same anti-pattern as model-api M04 (Track 4) |

**P0 total effort:** ~6h (HG-001 4h + CORS 0.5h + internal secret 0.5h + tests + verify).

---

### 🟠 P1 — Local critical

| # | ID | File:line | Issue |
|---|---|---|---|
| 4 | M04 F2 | `health.service.js:31-53` | Silent `.catch(() => 0)` x6 hides DB failures |
| 5 | M02 F1 (D-007) | `routes/index.js:19-20` | `/users` mount conflict (relationships + userRoutes both at `/users`) |
| 6 | M02 F2 (D-010) | `routes/index.js:28` | Double `admin` prefix → `/api/v1/admin/admin/vital-alerts` |
| 7 | M02 F4 | `ai-models.routes.js:34-37` | Multer 500 MB memory upload + no rate limit (DoS surface) |
| 8 | M01 F2 | `app.js` | No helmet — missing CSP, HSTS, X-Frame-Options |
| 9 | M05 F4 | `validate.js:20-117` | No strict mode → mass assignment via extra fields possible |

**P1 total effort:** ~10h.

---

### 🟡 P2 — Architecture debt

| # | ID | Issue |
|---|---|---|
| 10 | M06 F11 | Phase -1.A canonical SQL drift — Prisma added tables not synced to `init_full_setup.sql` |
| 11 | M06 F7 | `user_fcm_tokens` + `user_push_tokens` duplication |
| 12 | M07 F1 | `vital-processor.js` permanently disabled — remove or document |
| 13 | M02 F5 | 4 modules missing rate limiter (settings, vital-alerts, ai-models, internal) |
| 14 | M02 F6 | Dashboard routes missing query param `validate()` |
| 15 | M03 F6 | `user.routes.js:46` allows role 'admin' in enum — should restrict |
| 16 | M03 F7 | Auth routes don't use `validate()` middleware (hand-checked in controller) |
| 17 | M04 F3 | Mock data import in production service (ai-models-mlops) |
| 18 | M08 F1 | Jobs (`vital-processor`, `risk-score-job`) untested |
| 19 | M08 F5 | 5 controllers untested (ai-models, dashboard, settings critical) |

**P2 total effort:** ~25h.

---

### 🟢 P3 — Minor cleanup

- M03 F1, F2 — error handling + ApiResponse style inconsistency (~2h)
- M04 F4 = M06 F10 — zero-byte `risk-calculation.service.js` (2 min)
- M07 F5 — typo `SẾPF` (2 min)
- M07 F3 — add `tooManyRequests` factory to ApiError (5 min)

---

## Confirmed false positives from Phase -1

### ❌ D-009 — `/vital-alerts/* no auth`

**Phase -1.B claim:** vital-alerts endpoints unauthenticated.

**Reality** (M02 audit):
- `vital-alerts.js` lines 75-79, 114-119, 145-151, 185-190, 216-221 — **every route has `authenticate, requireAdmin`**
- `vital-alert.routes.js:18` — `router.use(authenticate, requireAdmin, vitalAlertLimiter)` at router level

**Action:** Update `api_contract_v1.md` D-009 status → `confirmed_false_positive`. Phase -1 spec drift docs accuracy improved by Phase 1 audit.

---

## Strengths discovered (reference patterns)

### 🟢 R1 — JWT + token_version + DB roundtrip (M05 F1)

`middlewares/auth.js:25-43` — verifies JWT + checks DB user (soft-delete, is_active, token_version match). **Best-in-class across 5 repos.** Adopt in:
- `health_system/backend/app/routers/` (Track 2)
- `healthguard-model-api/app/routers/` (Track 4 — currently no auth on predict endpoints!)

### 🟢 R2 — Audit context propagation (M03 F4 + M04 F6)

Controller captures `req.ip + user-agent` → service writes `audit_logs` with full forensics on every auth attempt.

### 🟢 R3 — Login lockout (M04 F6)

5 failed attempts → 15-min lockout; full audit log; reset on success; no user enumeration leak.

### 🟢 R4 — ApiError factory (M07 F3)

Typed error class with `isOperational` flag, factory methods, captured stack. Reference for FastAPI services (Track 2/4 currently use raw `HTTPException`).

---

## Phase 4 fix sequence (recommended order)

### Stage 1 — Cross-repo P0 chain (~8-10h coordinated)

```
1. model-api: Add internal_secret + verify_internal_secret (Track 4 P0)
2. model-api: CORS allowlist strict (Track 4 P0)
3. HealthGuard BE: Fix CORS reflection (M01 F1)
4. HealthGuard BE: Fix internal secret fallback (M02 F3)
5. HealthGuard BE: HG-001 fix (M04 F1) — enable read_at/acknowledged_at/expires_at flow
6. HealthGuard FE (Track 1B M11): Wire mark-as-read UI to new endpoint
7. Smoke test entire chain
```

### Stage 2 — Local hardening (~10h)

```
8. M02 F1 D-007 — separate /users + /relationships mount
9. M02 F2 D-010 — fix /admin/admin prefix
10. M02 F4 — multer disk storage + rate limit + extension filter
11. M01 F2 — add helmet
12. M05 F4 — validate strict mode
13. M04 F2 — replace silent .catch with logging
```

### Stage 3 — P2 architecture debt (Phase 4+ rolling, ~20-25h)

```
14. M06 F11 — sync canonical SQL with Prisma
15. M06 F7 — reconcile push token tables (cross-repo)
16. M07 F1 — vital-processor decision
17. M02 F5/F6 — missing rate limits + validates
18. M04 F3 — mock data behind env flag
19. M08 — test gap closure (10h)
```

---

## Phase 3 deep-dive candidates promoted

| File | LoC | Reason | Priority |
|---|---|---|---|
| `services/health.service.js` | 682 | HG-001 fix + split into 4 sub-services | **HIGH** |
| `services/ai-models-mlops.service.js` | 832 | M04 F3 mock separation + size split | Medium |
| `routes/internal.routes.js` | 118 | Internal secret + WebSocket emit pipeline (HG-001 adjacent) | Medium |
| `routes/ai-models.routes.js` + multer pipeline | 72 | M02 F4 + upload workflow | Low |

---

## Cross-repo coordination notes

| Issue | Coordinates with |
|---|---|
| HG-001 fix | Track 1B M11 `ThresholdAlertsTable.jsx` (mark-as-read UI), M10 admin pages |
| CORS pattern | Track 4 model-api D-013 (same fix applied here) |
| Internal secret pattern | Track 4 model-api M04 (same fix applied here) |
| Push token reconciliation | Track 2 (health_system BE `notification.service.py`) + Track 3 mobile FCM |
| Auth reference R1 | Track 2 (health_system BE auth.py — verify if same lockout exists) |

---

## Metrics

| Metric | Value |
|---|---|
| Modules audited | 8/8 (100%) |
| LoC scanned | ~11,500 |
| Phase 4 P0 fixes identified | 3 (1 local + 2 cross-repo chain) |
| Phase 4 P1 fixes identified | 6 |
| Phase 4 P2 fixes identified | 10 |
| Phase 4 P3 cleanup items | 4 |
| Phase 3 deep-dive candidates | 4 |
| False positives from Phase -1 cleared | 1 (D-009) |
| Reference patterns discovered | 4 (JWT, audit ctx, lockout, ApiError) |
| Total Phase 4 effort estimate | ~50-60h (P0+P1 ~16h critical path) |

---

## Verdict

**🟡 Needs attention** — HealthGuard backend is **architecturally solid** (M03/M05/M06/M07 mature 🟢) but has:
1. **One active P0 bug** (HG-001) confirmed root cause in M04
2. **Mirror security gaps** with model-api (CORS, internal secret) needing coordinated cross-repo fix
3. **Architecture debt** in routes mount strategy (D-007, D-010)

**Critical path:** ~16h for P0+P1 fixes unlocks alert lifecycle + closes security gaps.

**Reference value:** 4 best-in-class patterns identified — adopt cross-repo in Track 2 + Track 4 hardening.

---

## Pass B (deferred to later)

Not applicable for Track 1A — em audited all 8 modules in pass A. **Track 1A complete.**

---

## Cross-references

- Phase -1.A db_canonical_diff.md — F11 SQL drift tracking
- Phase -1.B api_contract_v1.md — D-007, D-009 (false positive), D-010, D-011 (partial)
- ADR-004 (`/api/v1/{domain}/*`) — verify all routes compliant (mostly yes, D-010 exception)
- BUG HG-001 — root cause confirmed M04 F1
- Track 4 (model-api) _TRACK_SUMMARY — coordinate CORS + internal secret fixes

---

## Recommended next

**Track 2 (`health_system/backend`)** — FastAPI backend, ~38h scope. Critical reference: adopt R1 (JWT + token_version) + R3 (login lockout) if missing.

Or **Track 3 (mobile)** if anh wants UX focus instead of backend chain.
