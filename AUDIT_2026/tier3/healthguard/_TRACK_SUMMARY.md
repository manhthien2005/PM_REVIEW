# Phase 3 Track Summary — HealthGuard deep-dive

**Phase:** Phase 3 deep-dive
**Date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Phase 1 baseline:** [tier2/healthguard/_TRACK_SUMMARY.md](../../tier2/healthguard/_TRACK_SUMMARY.md)

---

## TL;DR

**Repo verdict:** Healthy với 4 Critical files (3 Security=0 + 1 Total ≤6) + 1 Needs-attention

Phase 3 deep-dive 14 files (15 candidates, F14+F15 combined) — confirm + escalate Phase 1 macro findings, surface 50+ Phase 3 new findings.

Key outcomes:

- F01 Critical 6/15 highest-priority fix target: HG-001 + Q7 + D-HEA-01 + D-HEA-06 cluster (3 P0 findings).
- F02 Critical Correctness (Q7 INSERT FAIL exact line 163 confirmed): cùng commit với F01 line 46 filter fix.
- F06 + F13 Security=0 auto-Critical (D-INT-01 + D-AUTH-05): cross-repo coord HealthGuard + model API + IoT sim.
- F07 Healthy 10/15 Security=1: handshake DB check + CORS allowlist (~1.5h fix).
- F09 Needs-attention 7/15: god-component HG-001 + Q7 UI mirror.
- F03 + F04 + F05 Mature: dead empty file confirmed (F03), R3 reference (F04), R1 reference (F05).
- F08 + F10 + F11 + F12 Healthy: MLOps mock + emergency page + AI hook + threshold table.
- F14 + F15 Healthy: Prisma CA view workaround prerequisites cho F01 D-HEA-01 fix.

Phase 4 Critical fix sequence cohesive:

1. Cluster A — HG-001 + Q7 + D-HEA-01 (~10h): F02 risk_level fix (15 min) + F01 health.service multi-fix (HG-001 4h + Q7 + D-HEA-01 3h + D-HEA-06 30 min) + F09 FE handler (15 min) + F12 propagate auto + tests update + DB backfill.
2. Cluster B — D-INT-01 cross-repo (~4h cross-file): F06 internal.routes secret + env.js required + sanitize + rate limit + audit log + validate (cross-coord model API + IoT sim).
3. Cluster C — D-AUTH-05 cookie migration (~6-8h cross-file BE+FE): F04 + F05 + F07 + F09 + F12 + F13 + M01 CORS coordinate.
4. Cluster D — F14 Prisma CA workaround (~1h, prerequisites Cluster A part D-HEA-01).

---

## File scores

| File | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|
| [F01 health.service.js](./F01_health_service_audit.md) | 0 | 2 | 1 | 2 | 1 | 6/15 | 🔴 Critical (Total ≤6) |
| [F02 risk-calculator.service.js](./F02_risk_calculator_service_audit.md) | 0 | 3 | 2 | 3 | 2 | 10/15 | 🟡 Healthy (Critical Correctness) |
| [F03 risk-calculation.service.js](./F03_risk_calculation_service_audit.md) | 3 | 3 | 3 | 3 | 3 | 15/15 | 🟢 Mature (empty file) |
| [F04 auth.service.js](./F04_auth_service_audit.md) | 3 | 3 | 3 | 2 | 3 | 14/15 | 🟢 Mature |
| [F05 middlewares/auth.js](./F05_middleware_auth_audit.md) | 3 | 3 | 3 | 2 | 2 | 13/15 | 🟢 Mature |
| [F06 internal.routes.js](./F06_internal_routes_audit.md) | 2 | 2 | 2 | 0 | 3 | 9/15 | 🔴 Critical (Security=0) |
| [F07 websocket.service.js](./F07_websocket_service_audit.md) | 2 | 2 | 2 | 1 | 3 | 10/15 | 🟡 Healthy |
| [F08 ai-models-mlops.service.js](./F08_ai_models_mlops_service_audit.md) | 2 | 1 | 2 | 3 | 2 | 10/15 | 🟡 Healthy |
| [F09 HealthOverviewPage.jsx](./F09_health_overview_page_audit.md) | 1 | 1 | 1 | 2 | 2 | 7/15 | 🟠 Needs-attention |
| [F10 EmergencyPage.jsx](./F10_emergency_page_audit.md) | 2 | 2 | 2 | 2 | 3 | 11/15 | 🟡 Healthy |
| [F11 useAIModelsManager.js](./F11_use_ai_models_manager_hook_audit.md) | 2 | 3 | 3 | 3 | 2 | 13/15 | 🟢 Mature |
| [F12 ThresholdAlertsTable.jsx](./F12_threshold_alerts_table_audit.md) | 2 | 2 | 2 | 3 | 2 | 11/15 | 🟡 Healthy |
| [F13 frontend/services/api.js](./F13_frontend_api_audit.md) | 2 | 3 | 2 | 0 | 2 | 9/15 | 🔴 Critical (Security=0) |
| [F14+F15 Prisma schema](./F14_F15_prisma_schema_deepdive_audit.md) | 2 | 2 | 2 | 3 | 2 | 11/15 | 🟡 Healthy |
| **Average** | 2.0 | 2.3 | 2.1 | 2.1 | 2.3 | **10.7/15** | 🟡 Healthy |

Repo average kéo xuống bởi F01 Critical (Total 6) + F09 Needs-attention (Total 7) + 2 Security=0 auto-Critical files (F06 + F13). Post-Phase 4 Cluster A+B+C+D fixes → average ~12.5/15 Mature.

### Band distribution

- 🟢 Mature (13-15): 4 files — F03 (empty), F04, F05, F11 (28.6%)
- 🟡 Healthy (10-12): 6 files — F02, F07, F08, F10, F12, F14+F15 (42.9%)
- 🟠 Needs-attention (7-9): 1 file — F09 (7.1%)
- 🔴 Critical (0-6 OR Security=0): 3 files — F01 (Total ≤6), F06 (Security=0), F13 (Security=0) (21.4%)

---

## Critical findings (P0 — block Phase 4)

| # | ID | File(s) | Issue | Cluster | Effort |
|---|---|---|---|---|---|
| 1 | HG-001 hardcode `status='unread'` | F01 + F09 + F12 | health.service.js:177-181, 353-358 + HealthOverviewPage.jsx:65 + ThresholdAlertsTable line 198 | A | 4h pivot notification_reads |
| 2 | Q7 INSERT FAIL | F02 line 163 + F01 line 46 + 405-419 | risk-calculator set 'high' → DB CHECK violation; health.service filter 'high' luôn miss | A | 30 min code + 1h test + DB backfill |
| 3 | D-HEA-01 groupBy bug | F01 lines 479-490, 566-576 | `by:['time']` → no aggregate, 2.5M rows RAM. Depend F14 Prisma CA | A | 3h refactor depend F14 |
| 4 | D-HEA-06 take:288 semantic wrong | F01 line 565 | `vitals24h` chỉ 5 phút raw. Combine F14 CA fix | A | 30 min combine D-HEA-01 |
| 5 | D-INT-01 internal secret fallback | F06 line 13 | env fallback literal auto-bypass | B | 15 min route + env.js + cross-repo coord |
| 6 | D-AUTH-05 client-side session storage | F13 line 4 + F09 + F12 + M09 + M12 | localStorage session value → XSS leak. Steering React rule cấm. | C | 6-8h cross-file BE+FE migration |

Total P0 effort: ~13-15h (Cluster A 8h + B 1h + C 6-8h, Cluster D 1h merge vô A).

---

## P1 backlog (Phase 4 secondary)

Security:
- [ ] F04 logoutUser increment token_version (D-AUTH-03, ~5 min).
- [ ] F05 cookie fallback authenticate middleware (~30 min part Cluster C).
- [ ] F05 JWT verify add `issuer` option (~15 min).
- [ ] F06 rate limit + audit log + validate + sanitize error response (D-INT-02/03/04/06, ~3h).
- [ ] F07 handshake DB check token_version + is_active + deleted_at (~1h).
- [ ] F07 CORS allowlist (~30 min unify với app.js fix).

Correctness + perf:
- [ ] F01 Promise.all 3 queries trong getPatientHealthDetail (~30 min).
- [ ] F02 Track failedUsers separately + admin alert aggregate (~1h).
- [ ] F09 HG-001 FE handler đọc `read_state` từ payload (~15 min cùng F01).
- [ ] F14 Declare 3 CA views Prisma model với `@@ignore` (~1h depend F01).

Architecture:
- [ ] F08 listModels 1 query với `WHERE model_id IN (...)` (~30 min).
- [ ] F11 add error state + Promise.allSettled (~1h).
- [ ] F12 fix `key={alert.id}` thay `key={idx}` (~5 min).

---

## P2 backlog

Cross-cutting:
- [ ] F01 + F09 Vietnamese parse logic duplicate — BE emit `alert.data.metric` enum field, FE consume directly (~1h).
- [ ] F01 + F12 + F09 Severity nested ternary duplicate — extract `getSeverityLabel` helper (~10 min).
- [ ] F11 + F13 + F08 Promise.all không partial fail handling — refactor allSettled (~30 min × 3).

Per-file P2:
- [ ] F01 Extract `_formatAlertMetric` helper (110 LoC) (~2h).
- [ ] F01 Replace `.catch(() => 0)` silent fail bằng logger.warn (~1h).
- [ ] F01 Limit `dateRange='all'` về 1 năm (~15 min).
- [ ] F02 Extract 4 sub-methods từ `calculateRiskScore` god-method (~2h).
- [ ] F08 listModels N×1 query refactor (~30 min).
- [ ] F08 loadStateRecord structuredClone thay JSON.parse/stringify (~10 min).
- [ ] F09 Extract `ThresholdFilterBar.jsx` từ filter form inline 125 LoC (~2h).
- [ ] F09 Replace console.log debug bằng `if (import.meta.env.DEV)` gate (~10 min).
- [ ] F09 Merge `fetchAlertsWithoutSearch` + `fetchAlerts` (~30 min).
- [ ] F10 Extract `useEmergencyData()` custom hook (~3h).
- [ ] F12 Extract 4 inline helpers sang HealthConstants (~30 min).
- [ ] F12 Wrap component với `React.memo` (~10 min).
- [ ] F13 Handle 204 No Content (~10 min).
- [ ] F13 FormData-aware header (~15 min).
- [ ] F13 AbortController support (~10 min).
- [ ] F13 Throw typed ApiError class (~30 min cross-service).
- [ ] F15 Drop `@@index([deleted_at])` raw SQL migration (~5 min).

---

## P3 backlog (cleanup)

- [ ] Remove emoji trong console.log cross-files (F01, F02, F08, F09, F11) (~30 min total).
- [ ] Add JSDoc cho hooks + services thiếu (~1h cross-files).
- [ ] F01 verify `processNewVital` dead wrapper + remove (~5 min).
- [ ] F01 verify `alert_type='sos_triggered'` reachable + remove if dead (~5 min).
- [ ] F02 Replace `DEFAULT_VITALS_DAY` literal với system_settings cache (~1h).
- [ ] F03 git rm `risk-calculation.service.js` empty file (~1 min).
- [ ] F04 Extract `BCRYPT_SALT_ROUNDS = 10` constant (~5 min).
- [ ] F04 Reset token TTL env tunable (~10 min).
- [ ] F05 Add section divider comments giữa 5 exports (~10 min).
- [ ] F07 Remove `emitDashboardUpdate` dead method (~5 min).
- [ ] F08 Extract Vietnamese inline literals → constants (~30 min).
- [ ] F11 Verify exhaustive-deps lint warning (~5 min).
- [ ] F12 Extract `<UserAvatar />` component reusable (~30 min).
- [ ] F13 Add JSDoc trên `apiFetch` (~10 min).

---

## Phase 5+ candidates

- F01 split god-service 635 LoC thành 4 sub-services (health-overview, threshold-alerts, risk-distribution, patient-detail).
- F02 batch parallel `calculateAllRiskScores` với `p-limit(5)`.
- F08 split file 830 LoC thành 5 sub-modules + persist setTimeout retrain với BullMQ.
- F09 extract `useHealthOverview()` custom hook + split component.
- F10 extract `useWebSocketBurstHandler()` reusable hook.
- F11 split sub-hooks (`useAIModelsList` + `useAIModelsDetail`) + AbortController integration.
- F13 TanStack Query migration (cache + retry + dedupe).
- F14 CI lint check schema.prisma vs canonical SQL CA schema match.

---

## Cross-repo coordination

### D-INT-01 (Cluster B)

```
HealthGuard BE F06 (Phase 4 fix here) ← root
       ↓ enforce X-Internal-Service header
healthguard-model-api M04 bootstrap (D-013 same pattern fix)
       ↓ + Iot_Simulator_clean fall_ai_client (D-020 add headers)
       ↓ + Iot_Simulator_clean sleep_ai_client (IS-001 + D-020)
```

### D-AUTH-05 (Cluster C cookie migration)

```
HealthGuard BE F04 auth.service set Set-Cookie HttpOnly + Secure + SameSite=Strict
HealthGuard BE F05 middlewares/auth cookie fallback
HealthGuard BE M01 app.js CORS allowlist specific origin
HealthGuard FE F13 api.js credentials: 'include' (remove localStorage read)
HealthGuard FE F09 + F12 + M09 + M12 propagate (no localStorage read)
HealthGuard FE F07 useWebSocket cookie via Socket.IO handshake
```

### D-HEA-07 + Q7 (Cluster A)

```
HealthGuard BE F02 risk-calculator.service.js:163 fix 4→3 levels
       ↓
HealthGuard BE F01 health.service.js:46, 405-419 filter + distribution
       ↓
HealthGuard FE F09 + F12 propagate (rendering auto fix)
       ↓
HealthGuard tests M08 mock data update D-HEA-07
       ↓
PM_REVIEW SQL backfill migration
       ↓ + index 08_create_indexes.sql:104 update
healthguard-model-api gemini_explainer.py legacy 4-dict align
```

---

## Phase -1 + Phase 0.5 + Phase 1 reconciliation

| Source | Status reconcile Phase 3 |
|---|---|
| Phase -1 D-007 `/users` mount conflict | ✅ Resolved during M02 review |
| Phase -1 D-008 `/health/*` admin auth gap | ✅ Resolved (per-route authenticate verified F05) |
| Phase -1 D-009 `/vital-alerts/*` no auth | ⚠️ Downgrade (M02 verify per-route auth, drift D-VAA-01 cover Phase 4 file drop) |
| Phase -1 D-010 Double `admin` prefix | 🔴 Still active (M02 + drift D-VAA-01 file drop) |
| Phase -1 D-011 `/internal/*` no secret | 🔴 Still active (F06 + drift D-INT-01) |
| HG-001 admin alerts unread | 🔴 Still active (F01 + F09 + F12 cluster A fix) |
| Drift HEALTH D-HEA-01..07 | 🔴 6/7 still active (F01 + F02 + F14 cluster A fix) |
| Drift AUTH D-AUTH-01..09 | 🔴 4/9 still active (F04 + F05 + F07 + cluster C cookie migration) |
| Drift INTERNAL D-INT-01..06 | 🔴 6/6 still active (F06 + cluster B cross-repo) |

---

## Phase 3 Definition of Done

- [x] 14 deep-dive files audited (15 candidates, F14+F15 combined).
- [x] All Phase 1 macro findings confirmed/escalated/revised.
- [x] 50+ Phase 3 new findings surfaced (specific line numbers + file refs).
- [x] 4 Critical band files identified (F01, F06, F13 + F09 Needs-attention).
- [x] 4 Phase 4 fix clusters defined (A: HG-001+Q7+D-HEA, B: D-INT-01, C: D-AUTH-05, D: F14 Prisma).
- [x] Cross-repo coordination plan documented (D-INT-01 + D-AUTH-05 + Q7).
- [x] Phase 5+ candidates promoted (8 architectural refactors).
- [x] Track summary aggregated (this file).
- [ ] ThienPDM review.
- [ ] Commit + PR `chore/audit-2026-phase-3-healthguard`.
- [ ] Merge → Phase 4 fix execution start.

---

## Out of scope (Phase 3 deep-dive complete)

Phase 3 không cover:
- Per-file Phase 5+ refactoring (god-service split).
- TanStack Query / SWR migration FE.
- Persist setTimeout với BullMQ.
- E2E test framework integration.
- Visual regression testing.
- Accessibility audit (Phase 5+).
- Performance load testing với k6/artillery.
- Cross-repo contract test (Pact, OpenAPI generator).

---

**Phase 3 verdict:** 14 file deep-dive surface 50+ new findings beyond Phase 1 macro. Highest-priority Phase 4 fix cluster A (~10h) — HG-001 + Q7 + D-HEA. Cluster B (~4h cross-repo D-INT-01) + Cluster C (~6-8h D-AUTH-05 cookie). Total ~20-25h Phase 4 P0+P1+P2 cluster fixes → repo từ 10.7/15 Healthy → 12.5/15 Mature post-fix. Phase 5+ split god-services + TanStack Query migration là next major track.
