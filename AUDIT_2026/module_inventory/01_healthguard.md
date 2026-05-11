# Module Inventory — HealthGuard (admin web fullstack)

**Repo:** `HealthGuard/`
**Stack:** Express + Prisma (backend) + React + Vite (frontend) — same repo, separate workspaces
**Role:** Admin web for vital monitoring, alert management, AI model ops, user management
**Total LoC scope:** ~15,000+ (backend + frontend combined)
**Phase 1 track suggestion:** Track 1 (split into 1A backend + 1B frontend parallel)

---

## Overview

HealthGuard repo chứa **2 stacks separate**:
- `backend/` — Express + Prisma, port 5000, mount `/api/v1/admin/*` + `/api/v1/internal/*`
- `frontend/` — React + Vite, admin dashboard UI

**Critical role:** "Leaf" service trong cross-service topology — chỉ consume DB, không call external services. Trust boundary cao (admin-only access).

**Known issues từ Phase -1:**
- [HG-001](../../BUGS/HG-001-admin-web-alerts-always-unread.md): Admin alerts always unread → P1 Phase 4
- [D-007](../tier1/api_contract_v1.md): `/users` mount conflict (relationship + user routes) → P2 Phase 4
- [D-008](../tier1/api_contract_v1.md): `/health/*` admin auth gap → P0 verify Phase 1
- [D-009](../tier1/api_contract_v1.md): `/vital-alerts/*` NO auth → **P0 Critical**
- [D-010](../tier1/api_contract_v1.md): Double "admin" prefix → P2 cleanup
- [D-011](../tier1/api_contract_v1.md): `/internal/*` no secret check → **P0 Critical**

---

## Backend modules (Express + Prisma)

### M01: `backend/src/app.js` + `server.js` — Bootstrap

**Path:** `HealthGuard/backend/src/{app.js, server.js}`
**LoC:** ~120
**Effort:** S (~1h)
**Priority:** P1 (init flow, CORS, middleware chain)
**Dependencies:** Express, all sub-modules

**Audit focus:**
- Security: CORS allowlist, helmet config, cookie-parser settings
- Architecture: middleware order, error handler placement
- Correctness: error handler last middleware

### M02: `backend/src/routes/` — HTTP routing

**Path:** `HealthGuard/backend/src/routes/`
**Files:** 12 (auth, user, device, logs, settings, emergency, health, dashboard, vital-alert, ai-models, internal, index)
**LoC:** ~800
**Effort:** M (~5h)
**Priority:** P0 (security gaps D-008, D-009, D-011 lie here)
**Dependencies:** controllers, middlewares

**Audit focus:**
- Security: auth middleware coverage (verify D-008, D-009, D-011)
- Architecture: route → controller pattern, no logic in routes
- Readability: Swagger doc completeness

### M03: `backend/src/controllers/` — HTTP handlers

**Path:** `HealthGuard/backend/src/controllers/`
**Files:** 11 (auth, user, device, logs, settings, emergency, health, dashboard, vital-alert, ai-models, relationship)
**LoC:** ~2,500
**Effort:** L (~8h)
**Priority:** P0 (request handling layer)
**Dependencies:** services/, schemas/, utils/ApiError

**Audit focus:**
- Architecture: thin controllers (delegate to services)
- Correctness: input parsing, error mapping
- Security: input validation chained correctly

### M04: `backend/src/services/` — Business logic

**Path:** `HealthGuard/backend/src/services/`
**Files:** 16 (auth, user, device, logs, settings, emergency, health, dashboard, vital-alert, vital-alert-admin, ai-models, ai-models-mlops, relationship, r2, notification, ...)
**LoC:** ~6,000 (largest module)
**Effort:** L (~12h)
**Priority:** P0 (core business + HG-001 fix point)
**Dependencies:** Prisma client, R2/S3 for file storage

**Audit focus:**
- Architecture: service layering, no circular dep
- Correctness: Prisma transaction usage, error handling (P2002, P2025)
- Performance: query patterns (N+1 risk), pagination
- HG-001: `health.service.js` schema assumption fix needed

### M05: `backend/src/middlewares/` — Auth + validation

**Path:** `HealthGuard/backend/src/middlewares/`
**Files:** 3 (authenticate, requireAdmin, validate)
**LoC:** ~400
**Effort:** S (~2h)
**Priority:** P0 (security foundation)
**Dependencies:** JWT lib

**Audit focus:**
- Security: JWT verification correctness, role check, rate limiting
- Architecture: composability, error response format

### M06: `backend/prisma/` — DB schema

**Path:** `HealthGuard/backend/prisma/`
**Files:** schema.prisma + migrations/
**LoC:** ~600 (schema only)
**Effort:** S (~2h)
**Priority:** P0 (canonical truth temporarily per Phase -1)
**Dependencies:** Postgres

**Audit focus:**
- Architecture: model relationships, FK strategy
- Correctness: missing tables in canonical SQL (per Phase -1.A drift)
- Performance: index coverage

### M07: `backend/src/jobs/` + `mocks/` + `utils/` + `config/`

**Path:** `HealthGuard/backend/src/{jobs/, mocks/, utils/, config/}`
**LoC:** ~1,500
**Effort:** M (~5h)
**Priority:** P1
**Dependencies:** —

**Audit focus:**
- Jobs: cron/scheduler correctness, idempotency
- Utils: ApiError, validation rules
- Config: Swagger, env loading

### M08: `backend/src/__tests__/` — Test suite

**Path:** `HealthGuard/backend/src/__tests__/`
**Files:** 21 items
**Effort:** S (~3h — meta-review, not deep)
**Priority:** P2 (test quality, not blocking)

**Audit focus:**
- Coverage gap (em report separate metric)
- Test smell (excessive mocking, flaky tests)

---

## Frontend modules (React + Vite)

### M09: `frontend/src/App.jsx` + `main.jsx` — Bootstrap

**Path:** `HealthGuard/frontend/src/`
**LoC:** ~200
**Effort:** S (~1h)
**Priority:** P1
**Dependencies:** routes, providers

**Audit focus:**
- Architecture: router setup, context providers
- Security: auth guard wrappers

### M10: `frontend/src/pages/` — Page-level components

**Path:** `HealthGuard/frontend/src/pages/`
**Files:** Login/Forgot/Reset + admin/ (11 admin pages)
**LoC:** ~3,000
**Effort:** L (~10h)
**Priority:** P0 (user-facing surface)
**Dependencies:** components/, services/

**Audit focus:**
- Architecture: page composition, smart vs dumb components
- Correctness: form validation, async error handling
- Security: token storage, role-based access
- Performance: data loading patterns (refetch storms?)

### M11: `frontend/src/components/` — Shared UI

**Path:** `HealthGuard/frontend/src/components/`
**Files:** 79 items (largest folder)
**LoC:** ~4,000+
**Effort:** L (~10h)
**Priority:** P1 (reusable building blocks)
**Dependencies:** —

**Audit focus:**
- Architecture: component reusability, prop types
- Readability: file size, naming
- Performance: re-render optimization (memo, useMemo)

### M12: `frontend/src/services/` + `hooks/` + `utils/`

**Path:** `HealthGuard/frontend/src/{services/, hooks/, utils/}`
**Files:** services 10 + hooks 2 + utils 2
**LoC:** ~1,500
**Effort:** M (~5h)
**Priority:** P0 (API layer + state hooks)
**Dependencies:** API client lib

**Audit focus:**
- Architecture: API client abstraction, error mapping
- Security: token handling, no leak via console.log
- Correctness: hook dependencies array

### M13: `frontend/src/mocks/` + `styles/` + `types/`

**LoC:** ~500
**Effort:** S (~1h)
**Priority:** P2 (support files)

---

## Phase 1 macro audit plan

**Track 1A — Backend** (sequential, em một mình):

| Order | Module | Effort | Why |
|---|---|---|---|
| 1 | M01 (Bootstrap) | 1h | Init flow context |
| 2 | M05 (Middlewares) | 2h | Auth foundation (Critical D-009, D-011) |
| 3 | M02 (Routes) | 5h | Security gaps surface |
| 4 | M06 (Prisma) | 2h | Schema truth |
| 5 | M03 (Controllers) | 8h | Request handling |
| 6 | M04 (Services) | 12h | Business logic — HG-001 fix |
| 7 | M07 (Jobs/utils) | 5h | Support |
| 8 | M08 (Tests) | 3h | Coverage report |

**Track 1A total:** ~38h

**Track 1B — Frontend** (sequential, em một mình):

| Order | Module | Effort |
|---|---|---|
| 1 | M09 (Bootstrap) | 1h |
| 2 | M12 (Services/hooks) | 5h |
| 3 | M10 (Pages) | 10h |
| 4 | M11 (Components) | 10h |
| 5 | M13 (Support) | 1h |

**Track 1B total:** ~27h

**Total HealthGuard:** ~65h

---

## Phase 3 deep-dive candidates

**Backend:**
- [ ] `services/health.service.js` — HG-001 fix point (schema assumption)
- [ ] `services/auth.service.js` — token issuance, refresh flow
- [ ] `services/ai-models-mlops.service.js` — MLOps integration depth
- [ ] `services/vital-alert.service.js` — alert pipeline
- [ ] `middlewares/authenticate.js` — D-009, D-011 fix verification
- [ ] `routes/internal.routes.js` — D-011 internal secret add

**Frontend:**
- [ ] `pages/admin/HealthOverviewPage.jsx` — display alert status (HG-001 related)
- [ ] `pages/admin/*Emergencies*` — emergency response flow
- [ ] `services/*` API client error handling
- [ ] `components/health/ThresholdAlertsTable.jsx` — alert table consumer of HG-001

---

## Out of scope

- Docker/deploy configs
- Migration history (focus current schema only)
- 3rd party lib upgrade paths
- E2E test framework (em focus unit + integration)
- Old/deprecated pages (`AdminOverviewPage.old.jsx` etc)
