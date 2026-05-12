# Track 5A Summary — Iot_Simulator security + bugs

**Phase:** Phase 1 macro audit, Track 5 Pass A (security focus)
**Date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory:** [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)

---

## TL;DR

**Pass A verdict:** **🟠 Needs attention** — multiple structural concerns + 2 critical security gaps + 1 confirmed critical bug.

3 modules of 4 land in 🟠/🔴 band:
- M01 routers — 🔴 Critical (D-015 only 1/10 protected)
- M03 middleware+deps — 🟠 Needs attention (dependencies.py = 3,266 LoC god file)
- M06 simulator_core — 🟠 Needs attention (IS-001 + D-020)
- M05 backend clients — 🟢 Mature (good design, only ADR-004 path update needed)

Post Phase 4 critical fixes (IS-001, D-015 closure, D-020) → expect Pass A average promote to 🟡 Healthy. Architecture issue (god file split) requires Phase 3 deep-dive + dedicated refactor task.

---

## Module scores

| Module | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|
| [M01 Routers](./M01_routers_audit.md) | 2 | 2 | 2 | **1** | 3 | 10/15 | 🔴 |
| [M03 Middleware+Deps](./M03_middleware_dependencies_audit.md) | 2 | **1** | **1** | 2 | 2 | 8/15 | 🟠 |
| [M05 Backend clients](./M05_backend_clients_audit.md) | 3 | 3 | 3 | 3 | 2 | 14/15 | 🟢 |
| [M06 simulator_core](./M06_simulator_core_audit.md) | **1** | 3 | 2 | 1 | 2 | 9/15 | 🟠 |
| **Pass A average** | 2.0 | 2.25 | 2.0 | 1.75 | 2.25 | **10.25/15** | 🟡* |

*Average masks 2 modules at 🟠 + 1 at 🔴. Architecture + security pulls down strongly.

---

## Critical findings (P0 — block Phase 4)

| ID | Module | Issue | Fix file |
|---|---|---|---|
| **IS-001** | M06 | Sleep AI POST `/predict` → 404 | `simulator_core/sleep_ai_client.py:53` |
| **D-015** | M01, M03 | 9/10 routers no auth | All 9 router files (add `dependencies=[Depends(require_admin_key)]`) |
| **D-020** | M06 | Missing X-Internal-Service header | `fall_ai_client.py:378`, `sleep_ai_client.py:55` |

**P0 fix sequence (cross-repo coordinated với Track 4 model-api):**

```
1. model-api: Add internal_secret to Settings + verify_internal_secret dep (Track 4 fix)
2. model-api: Apply Depends to /predict endpoints
3. IoT sim: fall_ai_client + sleep_ai_client add X-Internal-Service header (D-020)
4. IoT sim: sleep_ai_client fix /predict path (IS-001)
5. IoT sim: Apply require_admin_key to 9 unprotected routers (D-015 closure)
6. Verify SIM_ADMIN_API_KEY env var policy for production
7. Smoke test:
   - IoT sim → model-api: fall predict works ✓ (with header)
   - IoT sim → model-api: sleep predict works ✓ (with correct path + header)
   - IoT sim admin endpoints: 403 without key ✓
```

**Estimated Phase 4 effort:** 8-10h (medium surface, cross-repo coordinate carefully)

---

## P1 backlog (Phase 4 secondary)

- [ ] **D-022** (M06): Change sleep client probe URL `/health` → `/api/v1/sleep/model-info`
- [ ] **M06**: Add self-heal cooldown to sleep client (mirror fall pattern)
- [ ] **M06**: Fix overly-broad `except Exception` in sleep client
- [ ] **M03**: Verify `INTERNAL_SERVICE_SECRET` fail-fast at startup
- [ ] **M03**: Add audit logger for failed auth attempts
- [ ] **M05**: Update base URL to `/api/v1/mobile/admin` post ADR-004
- [ ] **M05**: Verify index `idx_users_email_lower` for case-insensitive email lookup

---

## P2 backlog (defer or Phase 5+)

- [ ] **M03**: Parse `X-Forwarded-For` cho true client IP
- [ ] **M03**: Per-service locks instead of global `RLock`
- [ ] **M01**: Split `devices.py` admin endpoints to separate file
- [ ] **M06**: Extract common `AIClient` base class
- [ ] **M06**: Migrate stdlib urllib → httpx (consistency with M05)
- [ ] **M05**: Add request retry logic with exponential backoff

---

## Phase 3 deep-dive candidates (promoted from macro)

**Critical priorities:**

- [ ] **`dependencies.py` 3,266 LoC god file** — split into runtime.py, records.py, policies.py, log_hub.py
  - Estimated effort: L (~12-16h refactor task)
  - Must complete BEFORE Phase 4 refactor execution to avoid touching unstable file
- [ ] `simulator_core/sleep_ai_client.py` — full rewrite candidate (fix IS-001 + add self-heal + add base class)
- [ ] `scenarios.py` 450 LoC — verify service layer extraction
- [ ] `sim_admin_service.py` 600 LoC — raw SQL queries audit

**Lower priorities:**

- [ ] `simulator_core/fall_ai_client.py` `normalise_verdict` field mapping cross-check với schema
- [ ] `simulator_core/motion_window_to_samples` math validation

---

## Cross-repo coordination (Phase 4)

This Pass A surfaces cross-repo P0 chain — same as Track 4 summary:

```
healthguard-model-api (Track 4 fix)
       ↓ enforce X-Internal-Service
IoT sim simulator_core (THIS Track Pass A fix)
       ↓ add header + fix sleep path
IoT sim api_server (THIS Track Pass A fix)
       ↓ apply require_admin_key
```

**Recommendation:** Phase 4 fix Track 4 + Track 5 Pass A in single coordinated PR set (3 repos: model-api, IoT sim simulator_core, IoT sim api_server — last 2 same repo). Smoke test entire path before merge.

---

## What Pass B will cover

Pass A scoped to security + critical bugs. **Pass B (~25h estimated)** will cover:

- `M02` (api_server/services/) — 5 service files
- `M07` (pre_model_trigger/) — rule engine + threshold logic
- `M04` (repositories/ + db.py) — DB access patterns
- `M08` (transport/) — publisher abstraction
- `M09` (dataset_adapters/ + etl_pipeline/) — data ingestion

Pass C+D defer architecture + frontend later.

---

## Phase 1 Track 5 Pass A Definition of Done

- [x] 4 modules (M01, M03, M05, M06) audited với 5-axis rubric
- [x] Each module has output file `Mxx_*_audit.md`
- [x] Critical findings prioritized P0/P1/P2
- [x] Phase 3 deep-dive candidates promoted
- [x] Cross-repo coordination documented (D-013 → D-015 → D-020 → IS-001 chain)
- [x] Pass A summary aggregated (this file)
- [ ] ThienPDM review
- [ ] Commit + PR
- [ ] Merge → decide next: Track 1A (HealthGuard BE) or Track 5 Pass B

**Next:** Phase 1 Track 1A (HealthGuard BE) — has D-008, D-009, D-011 critical security + HG-001 bug.

Pass B (IoT sim remaining) defer until Track 1A + 2 complete (avoid back-to-back IoT context fatigue, anh prefer rotation).
