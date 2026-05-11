# Module Inventory — INDEX

**Phase:** Phase 0 deliverable — Phase 1 macro audit input
**Framework:** [00_audit_framework.md](../00_audit_framework.md) (5-axis rubric)
**Date:** 2026-05-11

---

## Files

| # | File | Repo | Stack | Track |
|---|---|---|---|---|
| 01 | [healthguard](./01_healthguard.md) | HealthGuard | Express + Prisma (BE) + React + Vite (FE) | Track 1A + 1B |
| 02 | [health_system_backend](./02_health_system_backend.md) | health_system | FastAPI + SQLAlchemy | Track 2 |
| 03 | [health_system_mobile](./03_health_system_mobile.md) | health_system | Flutter + Riverpod | Track 3 |
| 04 | [healthguard_model_api](./04_healthguard_model_api.md) | healthguard-model-api | FastAPI + onnxruntime | Track 4 |
| 05 | [iot_simulator](./05_iot_simulator.md) | Iot_Simulator_clean | FastAPI + simulator_core + React | Track 5 |

---

## Phase 1 macro audit effort estimate

| Track | Repo | Realistic effort | Notes |
|---|---|---|---|
| 1A | HealthGuard backend | ~38h | Express + Prisma |
| 1B | HealthGuard frontend | ~27h | React + Vite |
| 2 | health_system backend | ~61h | Heaviest BE logic |
| 3 | health_system mobile | ~40-50h (skim mode) | Largest LoC, skim recommended |
| 4 | healthguard-model-api | ~20h | Smallest service |
| 5 | Iot_Simulator | ~39h core (skip frontend M10) | Multi-pass approach |
| **Total** | | **~225-235h** | ~6 weeks at 40h/wk solo |

**Optimization:** Phase 1 macro NOT detailed line-by-line. Apply skim mode cho Mobile (Track 3) + IoT frontend (defer M10). Phase 3 deep-dive sẽ zoom vào modules flagged critical.

---

## Track parallelism plan

Tracks **không có dependencies giữa nhau** (mỗi track scan 1 repo độc lập). 5 tracks có thể chạy parallel — nhưng anh solo dev → sequential mới realistic.

**Recommended sequential order** (prioritized by Phase -1 critical findings):

1. **Track 4** (model-api) — smallest + has D-013 critical security gap
2. **Track 5 Pass A** (IoT sim security + bugs) — has IS-001 critical + D-021
3. **Track 1A** (HealthGuard BE) — has D-009, D-011 critical
4. **Track 2** (health_system BE) — has D-021, D-012, D1 fixes
5. **Track 3** (mobile) — has D1 fix, lowest urgency security
6. **Track 1B** (HealthGuard FE) — has HG-001 fix
7. **Track 5 Pass B-D** (IoT sim remaining)

**Rationale:** Critical security first, smallest scope first (faster wins), defer largest skim modules last.

---

## Audit output structure

Each track Phase 1 produces:
```
PM_REVIEW/AUDIT_2026/tier2/<track-slug>/<module>_audit.md
```

Example for Track 4:
```
PM_REVIEW/AUDIT_2026/tier2/healthguard-model-api/M01_routers_audit.md
PM_REVIEW/AUDIT_2026/tier2/healthguard-model-api/M02_services_audit.md
...
```

Output format follows template in `00_audit_framework.md § Audit output template`.

---

## Critical findings consolidated từ Phase -1 (re-grouped per track)

| Track | Critical issues (P0 in Phase 4) |
|---|---|
| 1A (HealthGuard BE) | D-008 `/health/*` auth gap, D-009 `/vital-alerts/*` no auth, D-011 `/internal/*` no secret, HG-001 admin alerts unread |
| 1B (HealthGuard FE) | HG-001 display fix |
| 2 (health_system BE) | D-021 telemetry sleep/imu no internal guard, D-012 inconsistent guards, D1 severity vocab |
| 3 (mobile) | D1 severity bucket fix in notification_severity.dart |
| 4 (model-api) | D-013 predict endpoints no internal secret |
| 5 (IoT sim) | IS-001 sleep AI broken, D-020 missing X-Internal-Service header, D-015 no auth verify |

---

## Out of scope

- Per-screen mobile review (defer Phase 3 deep-dive)
- Test coverage matrix (separate report)
- Migration history audit (Phase 4 only when re-baseline)
- 3rd party deps upgrade plan (separate ADR if needed)
- Infrastructure/deployment configs
