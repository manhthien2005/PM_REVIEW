# Track 4 Summary — healthguard-model-api

**Phase:** Phase 1 macro audit
**Date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory:** [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)

---

## TL;DR

**Repo verdict:** **🟡 Healthy với 🔴 Critical security debts (D-013)**

Module quality cao (architecture, readability, correctness >= 2/3 across all modules). NHƯNG **security score = 0** ở 2 modules (M01 routers + M04 bootstrap) do D-013 (no internal secret check) + CORS misconfig → auto-Critical band.

Phase 4 fix D-013 + CORS = unlock band promotion từ 🔴 → 🟡 cho 2 modules. Sau fix, repo overall = 🟢 Mature.

---

## Module scores

| Module | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|
| [M01 Routers](./M01_routers_audit.md) | 3 | 3 | 2 | **0** | 2 | 10/15 | 🔴 Critical |
| [M02 Services](./M02_services_audit.md) | 3 | 2 | 2 | 2 | 2 | 11/15 | 🟡 Healthy |
| [M03 Schemas](./M03_schemas_audit.md) | 2 | 3 | 3 | 2 | 3 | 13/15 | 🟢 Mature |
| [M04 Bootstrap](./M04_bootstrap_audit.md) | 2 | 3 | 3 | **0** | 2 | 10/15 | 🔴 Critical |
| [M05 Scripts](./M05_scripts_audit.md) (skim) | 2 | 2 | 2 | 3 | 3 | 12/15 | 🟡 Healthy |
| **Repo average** | 2.4 | 2.6 | 2.4 | 1.4 | 2.4 | **11.2/15** | 🟡 Healthy* |

*Repo average masks 2 modules at 🔴 Critical from Security=0. Post-fix average: ~12.6/15.

---

## Critical findings (P0 — block Phase 4)

| ID | Module | Issue | Fix file |
|---|---|---|---|
| D-013 | M01, M04 | No `verify_internal_secret` dependency on predict endpoints; no `internal_secret` field in Settings | `config.py`, `main.py`, new `dependencies.py`, all 3 router predict endpoints |
| CORS | M04 | `allow_origins=["*"]` + `allow_credentials=True` (anti-pattern + spec violation) | `main.py:60-66` |
| D-014 | M04 | `/health` semantic collision with `/api/v1/health/*` | Rename to `/healthz` (small, P2) |

**P0 fix sequence:**
1. Add `internal_secret` field to Settings (M04)
2. Create `app/dependencies.py` với `verify_internal_secret` function
3. Add `Depends(verify_internal_secret)` to all 3 `/predict` + 2 `/predict/batch` endpoints (M01)
4. Coordinate cross-repo:
   - `health_system/backend/app/services/model_api_client.py` already sends `X-Internal-Service: health-system-backend` ✓
   - `Iot_Simulator_clean/simulator_core/fall_ai_client.py` MUST add header (D-020)
   - `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` MUST add header (D-020) + fix path (IS-001)
5. Fix CORS allowlist via env var
6. Smoke test mobile flow + IoT sim flow before deploy

**Estimated Phase 4 effort:** 4-6h (small surface, well-isolated)

---

## P1 backlog (Phase 4 secondary)

- [ ] Wrap sync ML inference với `asyncio.to_thread` (M01 + M02)
- [ ] Move sample-cases JSON loader from router to service layer (M01 architecture cleanup)
- [ ] Expose Gemini config via Settings (M02)
- [ ] Add range validators to `SleepRecord` + `HealthRecord` fields (M03 — physiological bounds)

## P2 backlog (defer or Phase 5+)

- [ ] Add rate limiting middleware (M04)
- [ ] Add `TrustedHostMiddleware` (M04)
- [ ] Add `max_length` to string schemas (M03)
- [ ] Convert string fields to Literal enum where bounded (M03)
- [ ] Add structured JSON logging option for prod (M04)
- [ ] Add unit tests for threshold boundary values (M02)
- [ ] Verify ValueError messages don't leak schema internals (M01)

---

## Phase 3 deep-dive candidates (promoted from inventory)

Based on macro findings, these modules warrant per-file deep audit:

- [ ] `services/fall_service.py` — 279 LoC borderline god class; SHAP integration; threshold logic
- [ ] `services/health_service.py` — verify mirror Fall pattern + range bounds
- [ ] `services/sleep_service.py` — verify mirror + IS-001 related (consumer-side)
- [ ] `services/gemini_explainer.py` lines 80-215 — prompt template PHI check
- [ ] `services/prediction_contract.py` lines 80-300 — SHAP base value handling
- [ ] `schemas/health.py` + `schemas/sleep.py` — range constraint addition

---

## Cross-repo coordination (Phase 4)

D-013 fix affects 3 repos:

```
healthguard-model-api (Phase 4 fix)
       ↓ enforce X-Internal-Service header
health_system BE (model_api_client.py — already sends ✓)
       ↓ no change needed
Iot_Simulator_clean (Phase 4 fix simultaneous)
   - fall_ai_client.py: add header
   - sleep_ai_client.py: add header + fix path (IS-001)
```

→ **Phase 4 cần single PR** chứa 3-repo coordinated change (or 3 PRs merged simultaneously) để no downtime.

---

## Out of scope (Phase 1 macro complete)

Phase 1 không cover:
- Per-file deep code review (Phase 3 deep-dive)
- ML model accuracy/fairness (separate ML-ops concern)
- Test coverage matrix (separate report)
- Deployment configs (Docker, uvicorn args)
- Performance benchmarks (load testing)

---

## Phase 1 Track 4 Definition of Done

- [x] All 5 modules (M01-M05) audited với 5-axis rubric
- [x] Each module has output file `Mxx_*_audit.md`
- [x] Critical findings prioritized P0/P1/P2
- [x] Phase 3 deep-dive candidates promoted from macro findings
- [x] Cross-repo coordination noted (D-013 → 3 repos)
- [x] Track summary aggregated (this file)
- [ ] ThienPDM review
- [ ] Commit + PR
- [ ] Merge → Phase 1 Track 5 (IoT sim) start

**Next:** Phase 1 Track 5A (IoT simulator security focus, paired with IS-001 + D-020 fix planning)
