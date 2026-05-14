# Track 1 Summary — HealthGuard (admin web fullstack)

**Phase:** Phase 1 macro audit
**Date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory:** [01_healthguard.md](../../module_inventory/01_healthguard.md)

---

## TL;DR

**Repo verdict:** **Healthy với 3 Critical modules + 1 Needs-attention**

HealthGuard admin web có base hạ tầng (Express + Prisma + React + Vite) với pattern R1/R3 authentication chất lượng cao và architecture thin-controller chuẩn. Tuy nhiên 3 module auto-Critical do Security=0 (M02 Routes + M09 FE Bootstrap + M12 FE Services) + 1 module Needs-attention (M04 Services) vì các findings trải rộng:

- 3 Security auto-Critical có thể thu về 2 root causes: (a) internal secret fallback cross-repo ADR-005, (b) client-side session value persisted drift AUTH D-AUTH-05.
- M04 Needs-attention do HG-001 bug tracker + Q7 risk_level enum mismatch cross-repo + D-HEA-01 Continuous Aggregates bỏ qua.

Phase 4 fix 3 root causes (~12-15h) + HG-001 (~4h) + Q7 (~2.5h cross-repo) = unlock 3 modules band promotion. Post-fix repo = Mature.

---

## Module scores

| Module | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|
| [M01 Bootstrap](./M01_bootstrap_audit.md) | 2 | 3 | 2 | 1 | 3 | 11/15 | 🟡 Healthy |
| [M02 Routes](./M02_routes_audit.md) | 2 | 2 | 1 | **0** | 3 | 8/15 | 🔴 Critical |
| [M03 Controllers](./M03_controllers_audit.md) | 1 | 2 | 2 | 3 | 3 | 11/15 | 🟡 Healthy |
| [M04 Services](./M04_services_audit.md) | 1 | 2 | 2 | 2 | 2 | 9/15 | 🟠 Needs-attention |
| [M05 Middlewares](./M05_middlewares_audit.md) | 3 | 3 | 3 | 2 | 2 | 13/15 | 🟢 Mature |
| [M06 Prisma schema](./M06_prisma_schema_audit.md) | 2 | 2 | 2 | 2 | 2 | 10/15 | 🟡 Healthy |
| [M07 Jobs+Utils+Config](./M07_jobs_utils_config_audit.md) | 2 | 3 | 3 | 2 | 3 | 13/15 | 🟢 Mature |
| [M08 Tests](./M08_tests_audit.md) | 2 | 2 | 2 | 3 | 3 | 12/15 | 🟡 Healthy |
| [M09 FE Bootstrap](./M09_frontend_bootstrap_audit.md) | 2 | 3 | 2 | **0** | 3 | 10/15 | 🔴 Critical |
| [M10 FE Pages](./M10_frontend_pages_audit.md) | 2 | 2 | 2 | 2 | 2 | 10/15 | 🟡 Healthy |
| [M11 FE Components](./M11_frontend_components_audit.md) | 2 | 2 | 2 | 3 | 2 | 11/15 | 🟡 Healthy |
| [M12 FE Services+Hooks+Utils](./M12_frontend_services_hooks_utils_audit.md) | 2 | 3 | 2 | **0** | 2 | 9/15 | 🔴 Critical |
| [M13 FE Support](./M13_frontend_support_audit.md) | 3 | 3 | 3 | 3 | 3 | 15/15 | 🟢 Mature |
| **Repo average** | 2.0 | 2.5 | 2.2 | 1.8 | 2.5 | **10.9/15** | 🟡 Healthy* |

*Repo average bị kéo xuống bởi 3 Security=0 auto-Critical + M04 Needs-attention. Post-fix 3 root causes + HG-001 + Q7 → repo average ~12.5/15 Mature.

### Band distribution

- 🟢 **Mature (13-15):** 3 modules — M05 Middlewares, M07 Jobs+Utils, M13 FE Support
- 🟡 **Healthy (10-12):** 6 modules — M01 Bootstrap, M03 Controllers, M06 Prisma, M08 Tests, M10 Pages, M11 Components
- 🟠 **Needs-attention (7-9):** 1 module — M04 Services (HG-001 + Q7 + D-HEA-01)
- 🔴 **Critical (0-6 OR Security=0):** 3 modules — M02 Routes, M09 FE Bootstrap, M12 FE Services (all Security=0 auto-trigger)

---

## Critical findings (P0 — block Phase 4)

| # | ID | Module | Issue | Drift / ADR ref | Est. effort |
|---|---|---|---|---|---|
| 1 | **Q7 risk_level enum** | M04, M06, M08 | 4 levels code vs 3 levels DB canonical → INSERT FAIL (risk-calculator.service.js:155-159) + admin dashboard `high` count luôn 0 (health.service.js:46) | drift/HEALTH D-HEA-07 | 2.5h cross-repo + DB backfill |
| 2 | **D-INT-01 internal secret fallback** | M01, M02 | `internal.routes.js:13` fallback literal khi env missing → auth bypass trivial | drift/INTERNAL D-INT-01 + ADR-005 | 15 min remove + env.js required array |
| 3 | **CORS reflection + credentials** | M01 | `app.js:22-29` reflect any origin + credentials=true → CSRF attack surface | drift/AUTH D-AUTH-05 | 30 min allowlist fix |
| 4 | **Client-side session storage** | M09, M12 | `api.js:4, authService.js:13-14, useWebSocket.js:22` — XSS compromise → session leak. Steering React rule explicit cấm | drift/AUTH D-AUTH-05 | 6-8h BE+FE cookie migration coord |
| 5 | **HG-001 admin alerts always unread** | M04 | `health.service.js:353-358` hardcode `status='unread'` vì code đọc spec cũ | HG-001 bug tracker | 4h pivot sang `notification_reads` |

**Critical fix sequence (Phase 4 priority):**

1. **Week 1 — Security foundation:**
   - #2 D-INT-01 internal secret required (cross-repo ADR-005 coord).
   - #3 CORS allowlist fix (prepare cho cookie migration).
2. **Week 2 — Cross-repo data integrity:**
   - #1 Q7 risk_level enum fix (2.5h cross-service + DB backfill).
   - #5 HG-001 pivot sang `notification_reads` (4h + FE verify).
3. **Week 3 — Cookie migration:**
   - #4 BE + FE coordinate — httpOnly cookie + CSRF token (6-8h).

**Estimated Phase 4 P0 total:** 13-15h (excluding cross-repo ADR-005 coord time).

---

## P1 backlog (Phase 4 secondary)

**Security + auth:**
- [ ] **M01** — Add `helmet()` middleware (~30 min, drift AUTH #2).
- [ ] **M04** — `auth.service.js:143-152` logoutUser increment `token_version` (~5 min, drift D-AUTH-03).
- [ ] **M05** — `authenticate` middleware thêm cookie fallback + CSRF check khi cookie migration hoàn thành.
- [ ] **M09** — `ProtectedRoute` add real verify call trước render.
- [ ] **M10** — Add `<ErrorBoundary>` wrap Routes ở `App.jsx`.

**Correctness + data integrity:**
- [ ] **M04 + M06** — D-HEA-01 refactor service use TimescaleDB Continuous Aggregates (~3h).
- [ ] **M06** — Map `severity/status/risk_level/role` từ VARCHAR sang enum type (~30 min + regen client).
- [ ] **M06** — Handle TimescaleDB CA trong Prisma (`$queryRaw` hoặc view workaround, ~1h).
- [ ] **M02** — Per drift VITAL_ALERT D-VAA-01/02: Drop `vital-alerts.js` entirely (~1.5h, bundled với M03 vital-alert.controller.js fix).
- [ ] **M08** — Test mock data update D-HEA-07 cho health + dashboard service tests.

**Architecture:**
- [ ] **M02** — Internal routes rate limit + validate + audit log per drift D-INT-02/03/04 (~2h).
- [ ] **M03** — Move CSV render logic từ controller sang service (~2h).

---

## P2 backlog

- [ ] **M01** — Gate Swagger UI bằng env flag hoặc auth middleware.
- [ ] **M02** — Remove PUT aliases ở 4 route files (drift D-DEV-02 + D-USERS-04).
- [ ] **M04** — Replace `.catch(() => 0)` silent-fail bằng logger.warn + structured error.
- [ ] **M04** — Verify + consolidate `risk-calculator.service.js` vs `risk-calculation.service.js`.
- [ ] **M04** — `getPatientHealthDetail` refactor Promise.all concurrent.
- [ ] **M04** — Remove register role restriction ở controller + service (drift D-AUTH-06).
- [ ] **M04** — Extract `_formatAlertMetric` helper từ health.service.js.
- [ ] **M06** — Drop `user_fcm_tokens` zombie + `alerts.read_at` zombie columns (cùng HG-001 pivot).
- [ ] **M06** — Hash `users.verification_code` + `reset_code` trước khi store.
- [ ] **M07** — `email.js` HTML escape dynamic fields.
- [ ] **M08** — Add test cho `risk-calculator.service.js`.
- [ ] **M08** — Setup integration test layer Docker postgres (Phase 5+).
- [ ] **M10** — Delete legacy + test variant page files (`.old.jsx`, `*Test.jsx`).
- [ ] **M10** — Lazy load admin pages với `React.lazy`.
- [ ] **M11** — Consolidate `ai-models/` + `aimodels/` duplicate folders.
- [ ] **M12** — `api.js` AbortController + FormData-aware + 204 handling + typed ApiError.

## P3 backlog (nit)

- [ ] Remove emoji trong source code (M01, M04, M05, M07, M12 — nhiều console.log literal).
- [ ] Fix typo `SẾPF` → `SẾP` trong `vital-processor.js:7`.
- [ ] Replace debug `console.log` statement trong `health.service.js:311-324`.
- [ ] Unify AI models folder naming (3 variants `ai-models/` + `aimodels/` + `AIModels/`).
- [ ] Audit `users_archive` table — keep hoặc drop.
- [ ] Move internal routes mount từ `app.js` inline sang `routes/index.js`.

---

## Phase 3 deep-dive candidates

Based on macro findings, các modules/files warrant per-file deep audit:

**Backend:**
- [ ] `services/health.service.js` (580+ LoC god-service) — HG-001 fix point + Q7 fix + D-HEA-01 CA refactor. **High priority Phase 3.**
- [ ] `services/risk-calculator.service.js` — Q7 INSERT fail + no test coverage.
- [ ] `services/risk-calculation.service.js` — verify overlap vs risk-calculator.service.js.
- [ ] `services/ai-models-mlops.service.js` — ADR-006 mock integration depth.
- [ ] `services/auth.service.js` — reference pattern R3 verify cookie migration readiness.
- [ ] `services/websocket.service.js` — Socket.IO handshake auth + room isolation.
- [ ] `routes/internal.routes.js` — D-INT-01 fix verification + validate middleware addition.
- [ ] `middlewares/auth.js` — cookie fallback integration point.

**Frontend:**
- [ ] `pages/admin/HealthOverviewPage.jsx` (~600-900 LoC estimate) — god-component, HG-001 consumer.
- [ ] `pages/admin/EmergencyPage.jsx` — emergency response flow, real-time WS.
- [ ] `services/api.js` — cookie migration consumer, ApiError class introduction.
- [ ] `hooks/useAIModelsManager.js` — MLOps state machine depth.
- [ ] `components/health/ThresholdAlertsTable.jsx` — HG-001 UI consumer.
- [ ] Verify `dangerouslySetInnerHTML` exhaustive scan across 79 components.

**Prisma:**
- [ ] Continuous Aggregates view declaration workaround.
- [ ] Low-selectivity index `@@index([deleted_at])` — drop/partial migration.

---

## Cross-repo coordination (Phase 4)

Các fix cần simultaneous change với repo khác:

### 1. D-INT-01 + ADR-005 (internal secret cross-repo)

**Affected repos:**
```
HealthGuard BE (Phase 4 fix D-INT-01 here)
       ↓ enforce X-Internal-Service header
health_system BE (already enforce via require_internal_service)
       ↓ no change needed
healthguard-model-api (Phase 4 fix D-013 same pattern)
       ↓ cross-ref tier2/healthguard-model-api/M01_routers_audit.md finding
Iot_Simulator_clean (Phase 4 add required headers)
```

### 2. Q7 risk_level 3 levels (cross-service)

**Affected repos:**
```
HealthGuard BE (health.service + risk-calculator.service + tests) — Phase 4 P0 here
health_system BE (already 3 levels — source of truth, no change)
healthguard-model-api (gemini_explainer.py legacy 4-dict — Phase 4 align)
PM_REVIEW SQL CHECK + index 08_create_indexes.sql:104 — Phase 4 update
```

### 3. D-AUTH-05 cookie migration (BE + FE coord)

**Affected surface:**
```
HealthGuard BE auth.service.js — set Set-Cookie: HttpOnly + Secure + SameSite=Strict
HealthGuard BE middlewares/auth.js — cookie fallback
HealthGuard BE app.js — CORS allowlist specific origin
HealthGuard FE authService.js — remove localStorage.setItem
HealthGuard FE api.js — credentials: 'include' for cross-origin
HealthGuard FE useWebSocket.js — cookie included trong Socket.IO handshake
```

### 4. HG-001 + `alerts.read_at` zombie cleanup

**Affected surface (single repo HealthGuard + DB migration coord):**
```
HealthGuard BE health.service.js — pivot JOIN notification_reads
Prisma schema.prisma — drop read_at column (after service pivot)
SQL canonical init_full_setup.sql — drop column (post-fix)
```

---

## Cross-module patterns (Phase 1 observations)

### Shared anti-patterns (systemic debt)

1. **Emoji trong code** (M01, M04, M05, M07, M12) — cross-cutting rule violation. Steering `00-operating-mode.md` cấm emoji trong code/commit/PR. Replace bằng text prefix `[OK]`, `[WARN]`, `[ERROR]`, `[INFO]` — ~30 min cross-file sweep.

2. **Client-side session storage** (M09 + M12) — 2 FE modules cùng root cause. Fix qua D-AUTH-05 cookie migration → unlock 2 modules.

3. **Silent catch `.catch(() => 0)`** (M04 health.service.js) — mask errors thành empty result thay vì log + surface. Drift CONFIG D-CFG-05 scope verify.

4. **Hardcoded fallback trong auth middleware** (M01 + M02 via `internal.routes.js:13`) — drift INTERNAL D-INT-01 fix cover.

5. **Outdated comments vs reality** (M04 health.service.js:7-10 declare 4-level BR-028-06 sai, M06 schema.prisma 22 auto-generated comments repeat) — doc drift cần cleanup.

6. **PUT + PATCH duplicate routes** (M02 user/device/emergency/ai-models — 4 files) — drift D-DEV-02 + D-USERS-04 drop PUT aliases.

7. **Vietnamese literal trong business logic** (M04 health.service.js:255-305 `message.includes('SpO')`) — fragile vs message template change. Dùng enum field.

### Shared strengths (reference patterns)

1. **JSDoc comment đầy đủ** — cross-module consistent trên services + utils + hooks. Reader onboard nhanh.

2. **Vietnamese error messages + English identifier** — match convention dự án, i18n-ready surface.

3. **`ApiError` + `ApiResponse` + `catchAsync` utility standardization** (M07) — consistent error handling + response shape across BE.

4. **R1 (JWT + token_version) + R3 (bcrypt + lockout + audit log) pattern** (M05 + M04 auth.service.js) — security posture mature.

5. **Thin controller → service → Prisma layering** (M03) — separation đúng, 10/11 files follow pattern.

6. **Prisma singleton + global hot-reload cache** (M07) — no connection pool leak.

7. **Constants extraction per domain** (FE M11 components) — magic strings centralized, maintainable.

8. **Pattern consistency across 11 controller files + 16 service files** — onboard mới hiểu nhanh.

---

## Relationship với prior findings

### Phase -1 findings (status verification)

| Phase -1 ID | Status | Current audit ref |
|---|---|---|
| D-007 `/users` mount conflict | ✅ Resolved during review | M02 Routes |
| D-008 `/health/*` admin auth gap | ✅ Resolved (per-route authenticate verified) | M02 Routes |
| D-009 `/vital-alerts/*` no auth | ⚠️ **Downgrade severity** — em verify per-route authenticate exists, thực tế là D-010 double prefix | M02 Routes + M03 + M04 |
| D-010 Double `admin` prefix | 🔴 **Still active** | M02 Routes + drift D-VAA-01 |
| D-011 `/internal/*` no secret | 🔴 **Still active** | M01 + M02 + drift D-INT-01 |
| HG-001 admin alerts unread | 🔴 **Still active** | M04 Services |

### Phase 0.5 drift coverage

Tất cả 12 Phase 0.5 drift docs đã được cross-ref vào module tương ứng:

| Drift doc | Cross-ref modules |
|---|---|
| AUTH | M01 + M03 + M04 + M05 + M09 + M10 + M12 |
| ADMIN_USERS | M02 + M04 |
| DEVICES | M02 + M04 + M06 |
| HEALTH | M04 + M06 + M08 + M10 |
| EMERGENCY | M02 + M03 + M04 |
| VITAL_ALERT_ADMIN | M02 + M03 + M04 + M07 |
| DASHBOARD | M04 + M10 |
| LOGS | M02 + M03 + M04 |
| CONFIG | M02 + M04 + M07 |
| RELATIONSHIP | M02 + M03 + M04 + M06 |
| AI_MODELS | M02 + M11 + M13 |
| INTERNAL | M01 + M02 + M03 + M04 + M05 |

---

## Out of scope (Phase 1 macro complete)

Phase 1 không cover:
- Per-file deep code review (Phase 3 deep-dive).
- Per-endpoint contract test (controller vs Swagger spec).
- Test coverage percentage metrics (`npm run test:coverage` output).
- FE test coverage (no `frontend/__tests__/` folder detected).
- Accessibility audit (ARIA, keyboard nav, contrast).
- Visual regression testing.
- Bundle size analysis.
- ML model accuracy (separate concern).
- Deployment configs (Docker, CI/CD).
- Performance load testing (`k6`, `artillery`).
- Test flakiness metric.

---

## Phase 1 Track 1 Definition of Done

- [x] 13/13 modules audited với 5-axis rubric (Correctness/Readability/Architecture/Security/Performance).
- [x] Each module có output file `M01-M13_*_audit.md`.
- [x] 5 Critical findings (P0) prioritized + effort estimated.
- [x] P1/P2/P3 backlog populated across all 13 modules.
- [x] Phase 3 deep-dive candidates promoted (8 BE + 5 FE + 2 Prisma).
- [x] Cross-repo coordination noted (D-INT-01/ADR-005, Q7 enum, D-AUTH-05 cookie, HG-001 cleanup).
- [x] Track summary aggregated (this file).
- [x] Cross-module patterns documented (7 anti-patterns + 8 strengths).
- [x] Phase -1 findings status verified + Phase 0.5 drift coverage mapped.
- [ ] ThienPDM review
- [ ] Commit + PR tới `chore/audit-2026-phase-1-healthguard`
- [ ] Merge → Phase 1 Track 2 (health_system backend) start

**Next:** Phase 1 Track 2 (`health_system/backend` — mobile BE FastAPI, covers D-012/D-021 telemetry auth gaps).


---

## Phase 3 deep-dive results (2026-05-13)

Phase 3 deep-dive 14 files (15 candidates, F14+F15 combined) hoàn tất. Track summary: [tier3/healthguard/_TRACK_SUMMARY.md](../../tier3/healthguard/_TRACK_SUMMARY.md).

| File | Total | Band | Audit doc |
|---|---|---|---|
| F01 health.service.js | 6/15 | 🔴 Critical | [link](../../tier3/healthguard/F01_health_service_audit.md) |
| F02 risk-calculator.service.js | 10/15 | 🟡 Healthy (Critical Correctness) | [link](../../tier3/healthguard/F02_risk_calculator_service_audit.md) |
| F03 risk-calculation.service.js | 15/15 | 🟢 Mature (empty file) | [link](../../tier3/healthguard/F03_risk_calculation_service_audit.md) |
| F04 auth.service.js | 14/15 | 🟢 Mature | [link](../../tier3/healthguard/F04_auth_service_audit.md) |
| F05 middlewares/auth.js | 13/15 | 🟢 Mature | [link](../../tier3/healthguard/F05_middleware_auth_audit.md) |
| F06 internal.routes.js | 9/15 | 🔴 Critical (Security=0) | [link](../../tier3/healthguard/F06_internal_routes_audit.md) |
| F07 websocket.service.js | 10/15 | 🟡 Healthy | [link](../../tier3/healthguard/F07_websocket_service_audit.md) |
| F08 ai-models-mlops.service.js | 10/15 | 🟡 Healthy | [link](../../tier3/healthguard/F08_ai_models_mlops_service_audit.md) |
| F09 HealthOverviewPage.jsx | 7/15 | 🟠 Needs-attention | [link](../../tier3/healthguard/F09_health_overview_page_audit.md) |
| F10 EmergencyPage.jsx | 11/15 | 🟡 Healthy | [link](../../tier3/healthguard/F10_emergency_page_audit.md) |
| F11 useAIModelsManager.js | 13/15 | 🟢 Mature | [link](../../tier3/healthguard/F11_use_ai_models_manager_hook_audit.md) |
| F12 ThresholdAlertsTable.jsx | 11/15 | 🟡 Healthy | [link](../../tier3/healthguard/F12_threshold_alerts_table_audit.md) |
| F13 frontend/services/api.js | 9/15 | 🔴 Critical (Security=0) | [link](../../tier3/healthguard/F13_frontend_api_audit.md) |
| F14+F15 Prisma schema | 11/15 | 🟡 Healthy | [link](../../tier3/healthguard/F14_F15_prisma_schema_deepdive_audit.md) |
| **Average** | **10.7/15** | 🟡 Healthy | - |

**Band distribution:** 4 Mature (F03, F04, F05, F11), 6 Healthy (F02, F07, F08, F10, F12, F14+F15), 1 Needs-attention (F09), 3 Critical (F01 Total≤6, F06 Security=0, F13 Security=0).

### Phase 3 top findings (new, distinct from Phase 1 + drift)

50+ Phase 3 new findings beyond Phase 1 macro. Top 10 escalate Phase 4 backlog:

1. F-HG-P3-01 (P0 Correctness) — F02 Q7 INSERT FAIL exact line 163. Cross-file F01 line 46 filter luôn miss.
2. F-HG-P3-02 (P0 HG-001) — F01 lines 177-181, 353-358 + F09 line 65 + F12 line 198 UI mirror. Cluster A fix (~4h).
3. F-HG-P3-03 (P0 D-INT-01) — F06 line 13 fallback literal khi env missing. Cross-repo coord HealthGuard + model API + IoT sim (~4h).
4. F-HG-P3-04 (P0 D-AUTH-05) — F13 line 4 + F09 + F12 cookie migration cluster. Cross-file BE+FE (~6-8h).
5. F-HG-P3-05 (P1 D-HEA-01) — F01 lines 479-490, 566-576 groupBy bug → 2.5M rows RAM. Depend F14.
6. F-HG-P3-06 (P1 F07 handshake gap) — không check token_version + is_active + deleted_at → revoked token vẫn connect.
7. F-HG-P3-07 (P1 CORS reflection) — F07 + M01 app.js same broken pattern. Unify config/cors.js single source.
8. F-HG-P3-08 (P1 F11 error handling) — useAIModelsManager không try/catch + Promise.all all-or-nothing.
9. F-HG-P3-09 (P2 cross-cutting) — F01 + F09 Vietnamese parse logic duplicate. BE emit metric enum field.
10. F-HG-P3-10 (P2 F08 N×1 query) — listModels loop sequential. Refactor 1 query với WHERE model_id IN (...).

### Phase 4 fix clusters (cohesive sequencing)

- Cluster A — HG-001 + Q7 + D-HEA (~10h): F02 risk_level fix + F01 multi-fix + F09 FE handler + F12 propagate auto + tests + DB backfill.
- Cluster B — D-INT-01 cross-repo (~4h cross-file): F06 + healthguard-model-api M04 + IoT sim D-020.
- Cluster C — D-AUTH-05 cookie migration (~6-8h cross-file BE+FE): F04 + F05 + F07 + F09 + F12 + F13 + M01 CORS.
- Cluster D — F14 Prisma CA workaround (~1h, prerequisites Cluster A part D-HEA-01).

Total Phase 4 P0+P1 effort: ~20-25h → repo 10.7/15 Healthy → ~12.5/15 Mature post-fix.

### Phase 3 Definition of Done

- [x] 14 deep-dive files audited with 5-axis rubric.
- [x] All Phase 1 macro findings confirmed/escalated/revised (M02 D-009 downgrade + others verified).
- [x] 50+ Phase 3 new findings surfaced (specific line numbers + file refs).
- [x] 4 Critical band files identified (F01, F06, F13 + F09 Needs-attention).
- [x] 4 Phase 4 fix clusters defined (A: HG-001+Q7+D-HEA, B: D-INT-01, C: D-AUTH-05, D: F14 Prisma).
- [x] Cross-repo coordination plan documented (D-INT-01 + D-AUTH-05 + Q7).
- [x] Phase 5+ candidates promoted (8 architectural refactors).
- [x] Phase 3 track summary aggregated (tier3/healthguard/_TRACK_SUMMARY.md).
- [x] Phase 1 track summary updated với Phase 3 results (this file).
- [ ] ThienPDM review.
- [ ] Commit + PR `chore/audit-2026-phase-3-healthguard`.
- [ ] Merge → Phase 4 fix execution start.
