# Phase -1 Summary — Selective Rebuild of Tier 1 Specs

**Date:** 2026-05-11
**Branch:** `chore/audit-2026-foundation` @ PM_REVIEW
**Status:** ✅ Complete — ready for review + commit
**Linked charter:** [00_phase_minus_1_charter.md](./00_phase_minus_1_charter.md)

---

## TL;DR

Phase -1 rebuilt **3 trust-critical baseline artifacts** từ actual code thay vì stale spec. Surfaced **17 drift findings** (3 critical security gaps + 11 design issues + 3 dead code). Logged **3 bugs** vào BUGS/. Confirmed **4 vocabulary/design decisions** với ThienPDM.

Phase 1 macro audit có thể start ngay — anh có trust-able baseline trong tay.

---

## Deliverables produced

| File | Size | Purpose |
|---|---|---|
| [tier1/db_canonical_diff.md](./tier1/db_canonical_diff.md) | 24 tables matrix | DB schema source-of-truth diff |
| [tier1/api_contract_v1.md](./tier1/api_contract_v1.md) | ~208 endpoints | API endpoint catalog × 4 services |
| [tier1/topology_v2.md](./tier1/topology_v2.md) | 8 call paths | Cross-service call graph verified |
| [00_phase_minus_1_charter.md](./00_phase_minus_1_charter.md) | scope record | Charter for selective rebuild |
| [BUGS/PM-001](../BUGS/PM-001-pm-review-spec-drift.md) | parent bug | Systemic drift tracker (open) |
| [BUGS/HG-001](../BUGS/HG-001-admin-web-alerts-always-unread.md) | child bug | Admin alerts always unread (open) |
| [BUGS/IS-001](../BUGS/IS-001-sleep-ai-client-wrong-path.md) | child bug | Sleep AI client wrong path (open, critical) |

---

## Critical findings consolidated

### Security (P0 — Phase 4 hot fixes)

| ID | Service | Finding | Impact |
|---|---|---|---|
| D-009 | HealthGuard BE | `/vital-alerts/*` non-admin routes NO auth | Anyone can toggle vital processor off |
| D-011 | HealthGuard BE | `/api/v1/internal/*` no `X-Internal-Secret` check | Spoof websocket emit (fake alerts) |
| D-013 | healthguard-model-api | Predict endpoints no `verify_internal_secret` | DDoS + ML cost leak |
| D-021 | health_system BE | `/mobile/telemetry/{sleep,imu-window,sleep-risk}` no internal guard | Fake telemetry inject |

### Broken features (P0 — Phase 4)

| ID | Component | Finding | Impact |
|---|---|---|---|
| **IS-001** | IoT sim sleep AI | POST tới `/predict` (404) thay vì `/api/v1/sleep/predict` | Sleep AI silently broken, heuristic fallback only |
| **HG-001** | HealthGuard admin BE | Treat ALL alerts là 'unread' (code wrong assumption) | Admin can't filter read state |

### Schema drift (P0)

| Source of truth | Issue |
|---|---|
| Canonical SQL | Missing 3 tables (`ai_model_mlops_states`, `user_push_tokens`, `notification_reads`) |
| Canonical SQL | `risk_scores.risk_level` CHECK skip `'high'` |
| SQLAlchemy | `alerts.severity` vocabulary `'normal/high/critical'` conflicts canonical 4-level |
| Prisma | `user_relationships` có 3 extra cols không có ở canonical |

### Dead code/zombies (P1 — Phase 4 cleanup)

| ID | Asset | Status |
|---|---|---|
| D2 (from -1.A) | `user_fcm_tokens` table | 0 code references — drop |
| D3 (from -1.A) | `alerts.read_at` column | Dead — replaced by `notification_reads` |

---

## Decisions confirmed (ThienPDM)

| # | Topic | Decision | Rationale |
|---|---|---|---|
| D1 | Severity vocabulary | `low/medium/high/critical` (4 levels) | Match canonical + Prisma enum + admin web RISK_LEVEL hierarchy |
| D2 | `user_fcm_tokens` vs `user_push_tokens` | `user_push_tokens` active, `user_fcm_tokens` deprecated zombie | 0 code refs to fcm_tokens verified |
| D3 | Notification read state | `notification_reads` table = truth (multi-recipient), `alerts.read_at` = dead | Per-user read tracking for linked caregivers |
| D4 | Re-baseline approach | Defer Phase 4 (option C) | Avoid scope creep — current Phase -1 docs đủ trust |
| D5 | API prefix standardization | All 5 backend services standardize on `/api/v1/{domain}/*` | Logged as [ADR-004](../ADR/004-api-prefix-standardization.md). Resolves D-019 drift. Phase 4 refactor target. |

---

## Phase -1 metrics

| Metric | Value |
|---|---|
| Repos scanned | 5 (PM_REVIEW, HealthGuard, health_system, healthguard-model-api, Iot_Simulator_clean) |
| Backend services scanned | 4 (admin BE, mobile BE, ML, IoT sim) |
| Frontend HTTP clients scanned | 2 (mobile Flutter, admin React partial) |
| Tables compared | 24 (canonical SQL × Prisma × SQLAlchemy × IoT raw SQL) |
| Endpoints catalogued | ~208 |
| Cross-service paths verified | 8 |
| Drift findings | 22 (D-001 → D-022) |
| Bugs logged | 3 (PM-001, HG-001, IS-001) |
| Decisions confirmed | 4 |
| Total artifact lines | ~1,500 lines markdown |

---

## Top 10 issues for Phase 4 backlog

Ordered by severity + repo:

| # | ID | Severity | Repo | Title |
|---|---|---|---|---|
| 1 | IS-001 | Critical | Iot_Simulator_clean | Sleep AI client wrong path → 404 |
| 2 | D-009 | Critical | HealthGuard | `/vital-alerts/*` no auth |
| 3 | D-011 | Critical | HealthGuard | `/internal/*` no secret check |
| 4 | D-013 | Critical | healthguard-model-api | Predict endpoints no secret check |
| 5 | D-021 | High | health_system | telemetry sleep/imu no internal guard |
| 6 | D-008 | High | HealthGuard | `/health/*` (admin) verify auth gap |
| 7 | D-012 | High | health_system | telemetry endpoints inconsistent guards |
| 8 | HG-001 | Medium | HealthGuard | Admin web alerts always unread |
| 9 | D1 fix actions | Medium | health_system + HealthGuard + Flutter | Severity vocab 4-level rollout |
| 10 | D-001/D-002/D-003 | Medium | PM_REVIEW | Add 3 missing tables to canonical SQL |

---

## Trust statement

**Em đảm bảo:**
- Tier 1 baseline (DB / API / Topology) reflects **actual code state** as of 2026-05-11
- Every endpoint listed has corresponding code file:line reference
- Drift findings backed by exact source pointers (greppable)
- No fabricated specs

**Em KHÔNG đảm bảo:**
- Request/response schema parity (Pydantic vs Zod vs Dart model) — deferred Phase 1 macro audit
- Auth middleware actual behavior at runtime — static scan only, production verification needed
- Module-level code quality (em chỉ count endpoints, không evaluate implementation)
- Test coverage per endpoint — Phase 1+

---

## Phase 0 entry criteria (next phase)

Anh có đủ baseline để start Phase 0 (audit framework + module inventory):

✅ DB truth source identified (Prisma temporarily; canonical SQL needs P0 fix later)
✅ API endpoint catalog complete (4 services)
✅ Cross-service topology verified
✅ Vocabulary decisions confirmed (severity, read state, dead tables)
✅ Critical bugs logged separately (not blocking other phases)
✅ Trust baseline established

**Next phase TODO list:**
- Phase 0: build audit framework rubric (correctness, security, perf, testability, maintainability axes)
- Phase 0: module inventory per repo (granular — service/router/utility level)
- Phase 1: macro audit per repo (5 parallel tracks possible)

---

## Out of scope (deferred)

- Mobile app `lib/features/*` deep scan — Phase 1
- Admin web frontend page-level audit — Phase 1
- WebSocket event catalog — Phase 1
- FCM push delivery flow — Phase 1
- Email service integration — Phase 1
- Background scheduler/jobs (APScheduler, Celery, cron) — Phase 1
- Pump scripts source location — Phase 1
- Module-level code quality — Phase 1+
- Test coverage matrix — Phase 1+
- Schema migration history — Phase 4 (when re-baseline)

---

## Commit plan

**Branch:** `chore/audit-2026-foundation` (already created)

**Files to commit:**
```
PM_REVIEW/AUDIT_2026/00_phase_minus_1_charter.md
PM_REVIEW/AUDIT_2026/phase_minus_1_summary.md (this file)
PM_REVIEW/AUDIT_2026/tier1/db_canonical_diff.md
PM_REVIEW/AUDIT_2026/tier1/api_contract_v1.md
PM_REVIEW/AUDIT_2026/tier1/topology_v2.md
PM_REVIEW/BUGS/PM-001-pm-review-spec-drift.md
PM_REVIEW/BUGS/HG-001-admin-web-alerts-always-unread.md
PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md
PM_REVIEW/BUGS/INDEX.md (updated)
PM_REVIEW/ADR/004-api-prefix-standardization.md
PM_REVIEW/ADR/INDEX.md (updated)
```

**Commit message:**
```
docs(audit-2026): hoàn thành Phase -1 selective rebuild

Rebuild 3 baseline specs trust-critical từ actual code:
- DB canonical diff (24 tables × 4 sources)
- API contract v1 (~208 endpoints × 4 services)
- Topology v2 (8 cross-service paths verified)

Surface 22 drift findings + 5 decisions confirmed.
Log 3 bugs: PM-001 (systemic), HG-001 (admin alerts),
IS-001 (sleep AI broken).
Log ADR-004: standardize API prefix /api/v1/{domain}/*.

Refs: PM-001, ADR-004
```

**PR target:** `main` (PM_REVIEW only — single-repo change)

---

## Definition of Done — Phase -1

- [x] Charter file created
- [x] PM-001 bug logged (parent tracker)
- [x] Phase -1.A: DB canonical diff complete + decisions confirmed
- [x] Phase -1.B: API contract v1 complete
- [x] Phase -1.C: Topology v2 complete
- [x] HG-001 + IS-001 bugs logged separately (parallel tracks)
- [x] BUGS/INDEX.md updated với 3 bugs
- [x] Summary report written (this file)
- [ ] **Pending:** ThienPDM final review + approve
- [ ] **Pending:** Commit + push branch + open PR
- [ ] **Pending:** Merge to main (after review)

**After Phase -1 merged:** Phase 0 can start.
