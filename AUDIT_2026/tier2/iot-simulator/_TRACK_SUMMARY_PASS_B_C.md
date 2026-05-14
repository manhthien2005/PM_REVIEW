# Track 5 Summary — Iot_Simulator Pass B + C aggregate (repo-level)

**Phase:** Phase 1 macro audit, Track 5 Pass B (core logic) + Pass C (data + transport)
**Date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory:** [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)

---

## TL;DR

**Verdict:** Iot_Simulator repo overall is **Healthy** — Pass A + B + C combined average = 11.4/15. Security drift is the dominant concern; architecture + correctness generally solid.

Post Phase 4 security fixes (IS-002 + HS-004 coordinated + dependencies.py split) -> expect repo average to promote to **Mature** band.

Critical: 1 P0 drift bug surfaced (IS-002 sleep push auth). 8 new bugs filed across Pass B+C. 1 cleanup cluster (IS-005).

---

## Aggregate repo score (Pass A + B + C combined)

| Module | Pass | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|---|
| [M01 Routers](./M01_routers_audit.md) | A | 2 | 2 | 2 | **1** | 3 | 10/15 | Critical |
| [M02 Services](./M02_services_audit.md) | B | 2 | 2 | 2 | **1** | 2 | 9/15 | Needs attention |
| [M03 Middleware+Deps](./M03_middleware_dependencies_audit.md) | A | 2 | **1** | **1** | 2 | 2 | 8/15 | Needs attention |
| [M04 Repos + DB](./M04_repositories_db_audit.md) | C | 3 | 3 | 2 | 3 | 2 | 13/15 | Mature |
| [M05 Backend clients](./M05_backend_clients_audit.md) | A | 3 | 3 | 3 | 3 | 2 | 14/15 | Mature |
| [M06 simulator_core](./M06_simulator_core_audit.md) | A | **1** | 3 | 2 | 1 | 2 | 9/15 | Needs attention |
| [M07 pre_model_trigger](./M07_pre_model_trigger_audit.md) | B | 3 | 3 | 3 | 3 | 2 | 14/15 | Mature |
| [M08 Transport](./M08_transport_audit.md) | C | 3 | 3 | 3 | 2 | 2 | 13/15 | Mature |
| [M09 Dataset + ETL](./M09_dataset_etl_audit.md) | C | 2 | 2 | 3 | 3 | 2 | 12/15 | Healthy |
| **Weighted avg** | — | 2.3 | 2.4 | 2.3 | 2.1 | 2.1 | **11.4/15** | Healthy |
| **Median** | — | 2 | 3 | 2 | 2 | 2 | 12 | Healthy |

**Band distribution:**
- Mature: 4 modules (M04, M05, M07, M08)
- Healthy: 1 module (M09)
- Needs attention: 3 modules (M02, M03, M06)
- Critical: 1 module (M01, auto-critical via Security=1 router coverage)

---

## Top 5 risks (prioritized for Phase 4)

### Risk #1 — Sleep push path missing internal auth headers (IS-002)

- **Severity:** Critical (P0)
- **Module:** M02 `api_server/services/sleep_service.py`
- **Pattern:** AlertService adds `X-Internal-Service` + `X-Internal-Secret`; SleepService does NOT. Drift within same repo.
- **Impact:** Sleep telemetry push either unauthenticated (current, HS-004 scope) or broken (when BE enforces header post HS-004 fix).
- **Fix:** Mirror AlertService pattern (+ ~15 LoC). Batch with HS-004 cross-repo PR.
- **Reference impl:** `pre_model_trigger/healthguard_client.py` (M07 scored 3/3 security) or `alert_service.py` (M02).

### Risk #2 — `dependencies.py` 3,266 LoC god file (M03)

- **Severity:** Architecture P0 (blocks Phase 4 refactor quality)
- **Module:** M03 `api_server/dependencies.py`
- **Pattern:** Single file owns DI wiring + singleton state + push path helpers + event log hub + runtime state. 3,266 LoC is largest single file in repo.
- **Impact:** Every service extraction touches this file. Parallel PRs conflict. Phase 4 refactors risk introducing bugs if split not done first.
- **Fix:** Phase 3 deep-dive task = split into `runtime.py`, `records.py`, `policies.py`, `log_hub.py`. Est L (12-16h).
- **Priority:** Complete BEFORE Phase 4 fix execution to avoid touching unstable file.

### Risk #3 — `sleep_service.py` 1,315 LoC mixing 5-6 responsibilities (IS-002/003/004 all in this file)

- **Severity:** Maintenance P1
- **Module:** M02 `api_server/services/sleep_service.py`
- **Pattern:** Single file handles: window computation, heuristic scoring, AI scoring, backend push, DB history query, phase advancement, backfill with overwrite. 3 bugs surfaced (IS-002/003/004) all trace back to commingled concerns.
- **Fix:** Phase 3 split into `sleep_window.py`, `sleep_scoring.py`, `sleep_push.py`, `sleep_history.py`. Keep SleepService as facade.
- **Priority:** Sequence AFTER M03 dependencies.py split (shared upstream).

### Risk #4 — IoT sim -> model-api sleep predict path still broken (IS-001)

- **Severity:** Critical (P0) — pre-existing from Pass A
- **Module:** M06 `simulator_core/sleep_ai_client.py`
- **Pattern:** POST to `/predict` (404) instead of `/api/v1/sleep/predict`. 4 related changes needed per verify C1 (path + probe + header + response schema).
- **Impact:** Sleep AI scoring falls back to heuristic silently. AI verdict never engaged.
- **Fix:** 4-change commit (path + probe URL + X-Internal-Service header + response key `results` not `predictions`). Est 35 min.
- **Coord:** With Track 4 (model-api) to ensure BE side `X-Internal-Service` enforcement.

### Risk #5 — Router security coverage 1/10 (D-015 from Pass A)

- **Severity:** Critical (P0) — pre-existing from Pass A
- **Module:** M01 `api_server/routers/` (9 routers out of 10 unprotected)
- **Pattern:** Only `verification.py` has `Depends(require_admin_key)`. Other 9 admin endpoints accept any caller.
- **Impact:** Without auth, any network peer can start/stop simulator, mutate device state, inject fake alerts.
- **Fix:** Add `dependencies=[Depends(require_admin_key)]` to 9 router files. Coordinate with `SIM_ADMIN_API_KEY` env var policy.
- **Coord:** Same PR as IS-002 for unified security posture.

---

## Cross-module patterns

### Shared strengths

| Pattern | Modules | Why good |
|---|---|---|
| **X-Internal-Service header pattern (CORRECT impl)** | M05 backend_admin_client, M07 healthguard_client + mobile_telemetry_client, M02 AlertService | Reference implementation for cross-service auth per ADR-005. Use as template for IS-002 fix. |
| **Callback injection for DI** | M02 services extraction, M07 orchestrator, M08 publishers | Breaks circular deps; enables clean test doubles; documents coupling at constructor. |
| **Optional dep pattern `try: import; except: = None`** | M08 MQTT (paho), M09 ETL (pandas/pyarrow) | Graceful degradation when heavy deps absent. |
| **Parameterized SQL `:param` bind vars** | M04 DeviceRepository, M04 SimAdminService, M02 SleepService | 100% parameterized, zero SQL injection risk. |
| **Soft-delete + `deleted_at IS NULL` discipline** | M04 all SQL queries | Consistent; prevents accidental read of deleted rows. |
| **Data quality gate** | M07 orchestrator | Suppress PHI rule eval when signal poor; still run motion-based fall trigger. Clear separation of trusted vs suspect input. |
| **Dataclass with `to_dict()` explicit serialization** | M08 PublishResult, M09 SleepSessionRecord, M07 TriggerActionItem | Pydantic-free data contracts. |
| **Fix-numbered comments (`Fix #1`, `HIGH #6`, `MEDIUM #9`)** | M02 services, M07 rule engine | Audit trail within code. Useful for future archaeology. |

### Shared anti-patterns

| Anti-pattern | Modules | Risk |
|---|---|---|
| **`except Exception: return <fallback>`** silently swallow | M02 sleep_service (6 instances), M09 normalize.py ETL (multiple) | DB errors / adapter errors return sentinel; caller can't distinguish "empty" vs "unknown". Surfaced as IS-003 + IS-012. |
| **Dual import path** `try: from Iot_Simulator... except: from api_server...` | M02 ALL service files, M03 | Cargo-cult fragility; masks real ModuleNotFoundError. Replace with fixed import strategy. |
| **Module-level mutable globals** | M02 sleep_service (SLEEP_SCENARIO_PHASES), M03 dependencies.py state | State leak between instances; test flakiness. Surfaced as IS-004. |
| **Caller responsible for auth headers (no default)** | M08 HttpPublisher, M02 SleepService (pre-IS-002 fix) | Easy to forget. Should auto-inject if `internal_secret` provided. Surfaced as IS-010. |
| **File > 500 LoC god files** | M02 sleep_service (1,315 LoC), M03 dependencies.py (3,266 LoC), M09 normalize.py (452 LoC approaching) | Mixing concerns; hard to split safely. Phase 3 deep-dive candidates. |
| **N+1 queries** | M04 list_active_devices | Seq roundtrips scale with device count. Surfaced as IS-008. |
| **No retry logic on transient network failures** | M08 publishers, M07 MobileTelemetryClient | Single-attempt = message loss on transient errors. Contrast with M02 AlertService retry+backoff. |
| **Deferred imports inside methods** (`from ... import ... inside function`) | M02 services (8+ sites), M03 | Signals circular dep. Resolve by splitting god file. |

---

## Phase 4 backlog additions (delta vs Pass A)

### New P0 (Critical)
- [ ] **IS-002**: SleepService missing `X-Internal-Service` + `X-Internal-Secret` headers. Batch with HS-004.

### New P1 (Phase 4)
- [ ] **IS-008**: Eliminate N+1 in `list_active_devices` via DeviceRepository filter variant.
- [ ] **IS-003**: Propagate DB error from `_sleep_session_exists` (prevent double-write).
- [ ] Complete DeviceRepository migration for `assign_device`, `activate_device`, `deactivate_device`, `update_heartbeat` (Phase 3 refactor).

### New P2 (Phase 5 hygiene)
- [ ] **IS-005**: M07 cleanup cluster (dead code + dup consts).
- [ ] **IS-004**: SLEEP_SCENARIO_PHASES module global -> instance attr.
- [ ] **IS-009**: activate_device rollback before raise.
- [ ] **IS-010**: HttpPublisher auto internal-secret injection (NOT yet filed as bug — pending anh decision).
- [ ] **IS-011**: HttpPublisher retry logic (NOT yet filed).
- [ ] **IS-012**: ETL track success/failure ratio, raise on high failure rate (NOT yet filed).
- [ ] **IS-013**: VitalDBAdapter public `has_required_tracks` method (NOT yet filed).

### New Phase 3 deep-dive candidates (from Pass B+C)
- [ ] **`sleep_service.py` 1,315 LoC** split (Phase 3 L).
- [ ] **`normalize.py` 452 LoC** ETL split if grows further.
- [ ] Per-adapter audit (M09 defers 8 files).
- [ ] `dependencies.py` split promoted from Pass A stays.

---

## Cross-repo coordination chain (Phase 4 PR set)

Same chain as Pass A + extend with sleep push:

```
healthguard-model-api (Track 4 — enforce X-Internal-Service on /predict)
       |
       v
IoT sim simulator_core/sleep_ai_client (Pass A IS-001 — 4 fixes: path + probe + header + schema)
IoT sim simulator_core/fall_ai_client (Pass A D-020 — add header)
       |
       v
IoT sim api_server/services/sleep_service (Pass B IS-002 — add internal headers)
IoT sim api_server/services/alert_service (already correct — reference impl)
       |
       v
IoT sim api_server/routers/ (Pass A D-015 — apply require_admin_key to 9 routers)
       |
       v
health_system/backend (HS-004 — enforce internal-secret on /mobile/telemetry/sleep, /sleep-risk, /imu-window)
```

**Recommendation:** Phase 4 PR batching:
1. PR set 1 (security, coordinated): HS-004 BE enforcement + IS-002 sim sender headers + IS-001 sim path fix + Track 4 model-api enforcement + D-015 router coverage
2. PR set 2 (M04 cleanup): IS-008 + IS-009 + complete repo migration
3. PR set 3 (god file split): M03 dependencies.py decomposition (prerequisite)
4. PR set 4 (sleep service split): M02 sleep_service decomposition (after M03)
5. PR set 5 (hygiene): IS-005 + IS-004 + IS-010/011 + IS-012/013

---

## Phase 1 Track 5 Pass B + C Definition of Done

- [x] 5 modules (M02, M04, M07, M08, M09) audited with 5-axis rubric
- [x] Each module has output file `Mxx_*_audit.md`
- [x] New bugs created as real files in `PM_REVIEW/BUGS/` (IS-002, IS-003, IS-004, IS-005 cluster, IS-008, IS-009)
- [x] BUGS INDEX updated
- [x] Cross-module patterns documented
- [x] Top 5 risks prioritized
- [x] Phase 4 backlog delta documented
- [x] Cross-repo coordination chain updated
- [x] Pass B+C aggregate summary (this file)
- [ ] ThienPDM review + confirm IS-010/011/012/013 either file as bugs or defer
- [ ] Commit + PR (chore branch)

**Next options for anh:**
1. **Phase 1 Track 5 COMPLETE** — close out, move to Phase 1 Track 1A (HealthGuard BE) as originally sequenced
2. **M10 simulator-web audit** (defer per original plan, P2 dev tool UI) — ~12h if anh want full repo coverage
3. **Phase 3 deep-dive prep**: identify which split tasks (dependencies.py, sleep_service.py) to schedule first

Em recommend Option 1 — rotate to next repo per original plan to avoid context fatigue.
