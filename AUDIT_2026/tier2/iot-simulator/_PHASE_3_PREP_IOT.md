# Phase 3 Deep-Dive Prep — Iot_Simulator_clean

**Date:** 2026-05-13
**Author:** ThienPDM (via Kiro)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Prerequisite:** Phase 1 Track 5 Pass A + B + C audits complete

---

## Purpose

Identify + sequence Phase 3 deep-dive refactor tasks cho Iot_Simulator repo. Phase 3 = per-file line-by-line deep audits + targeted refactors, promoted from Phase 1 macro findings.

Outcome: ordered backlog voi dependencies, effort estimates, entry/exit criteria, risk flags.

---

## Deep-dive candidates (promoted from Pass A + B + C)

### Tier 1 — Critical path (must complete before Phase 4 execution)

| # | Task | Module | Est | Blocks | Rationale |
|---|---|---|---|---|---|
| **D3-01** | Split `dependencies.py` | M03 | L (12-16h) | Phase 4 any refactor touching runtime | 3,266 LoC god file. Every service extraction touches it. Parallel PRs conflict. Must complete BEFORE Phase 4 to avoid unstable base. |
| **D3-02** | Split `sleep_service.py` | M02 | M (8-10h) | IS-002/003/004 fix | 1,315 LoC mixing 5-6 concerns. 3 bugs (IS-002/003/004) trace to this commingling. Split enables targeted fix without touching irrelevant code. |

### Tier 2 — High value (parallel after Tier 1)

| # | Task | Module | Est | Blocks | Rationale |
|---|---|---|---|---|---|
| **D3-03** | Deep audit `sleep_ai_client.py` + fix IS-001 | M06 | S (3-4h) | Phase 4 model-api integration | Path bug + 3 related fixes (probe/header/schema). Cross-repo coordination. |
| **D3-04** | Deep audit `fall_ai_client.py` | M06 | S (2-3h) | — | D-020 + schema field mapping verify. Last untouched critical client. |
| **D3-05** | Complete DeviceRepository migration | M04 | M (6-8h) | — | Move assign/activate/deactivate/heartbeat/update from SimAdminService to repo. Eliminates half-migrated pattern. |
| **D3-06** | Deep audit `scenarios.py` | M01 (router) | S (3-4h) | — | 450 LoC flagged in Pass A; verify service-layer extraction opportunity. |
| **D3-07** | Deep audit `sim_admin_service.py` | M04/M05 | S (3-4h) | D3-05 | 345 LoC raw SQL deep review, promotion candidate to repo. |

### Tier 3 — Hygiene (low-risk, defer if time-tight)

| # | Task | Module | Est | Blocks | Rationale |
|---|---|---|---|---|---|
| **D3-08** | Per-adapter deep audit (8 files) | M09 | L (~16h total, 2h each) | — | Dataset-specific correctness. Separate from code structure. |
| **D3-09** | `normalize.py` refactor | M09 | S (3-4h) | — | 452 LoC approaching threshold. Split pipeline loaders. |
| **D3-10** | Extract AI client base class | M06 | S (2-3h) | D3-03 + D3-04 | Shared pattern between sleep + fall AI clients. |
| **D3-11** | Replace stdlib urllib with httpx.Client | M06 | S (2h) | D3-03 | Consistency with M05/M07 pattern. |

---

## Dependency graph

```
D3-01 (dependencies.py split)
    |
    +--> D3-02 (sleep_service split)
    |        |
    |        +--> IS-002/003/004 fixes (Phase 4)
    |
    +--> D3-03 (sleep_ai_client) + D3-04 (fall_ai_client)
             |
             +--> D3-10 (AI client base class) + D3-11 (httpx migration)
                      |
                      +--> IS-001 fix (Phase 4)

Independent:
D3-05 (repo migration) -- independent
D3-06 (scenarios.py) -- independent
D3-07 (sim_admin_service) <-- depends D3-05
D3-08 (per-adapter) -- independent
D3-09 (normalize.py) <-- depends D3-08 partial
```

**Critical path:** D3-01 -> D3-02 -> Phase 4 sleep security fixes. ~20-26h before Phase 4 sleep work can safely start.

**Parallel opportunity:** D3-05 + D3-06 + D3-08 can run concurrently with D3-01 (different files, no conflict).

---

## Entry/exit criteria per task

### D3-01: Split `dependencies.py` 3,266 LoC

**Entry:**
- [x] Pass A M03 audit complete (`M03_middleware_dependencies_audit.md`)
- [ ] Create dedicated branch `refactor/dependencies-split`
- [ ] Tag current state as `pre-d3-01-dependencies-split` (rollback point)
- [ ] Identify callers of current monolith (grep `from api_server.dependencies import`)

**Exit:**
- [ ] Split into `runtime.py`, `records.py`, `policies.py`, `log_hub.py` (or similar decomposition)
- [ ] Each resulting file <= 800 LoC
- [ ] All existing tests pass (no behaviour change)
- [ ] No circular import (verify via `python -c "import api_server.dependencies"`)
- [ ] Import graph documented in ADR
- [ ] Backward-compatible imports preserved for 1 release (re-exports in dependencies.py)
- [ ] M03 re-audit -> Architecture axis improves from 1/3 to at least 2/3

**Risk flags:**
- Circular import hell if dataclass shared (DeviceRecord, EventRecord, SessionRecord, PendingAlertPush) not carefully placed
- Runtime singletons must retain single-instance semantics post-split
- 8+ services currently do deferred-inside-method imports `from api_server.dependencies import X` — those paths may change
- Test flakiness if shared state moves to wrong module

**Mitigation:**
- Phased split: dataclass first (records.py), then singletons (runtime.py), then helpers
- Green test suite between each phase
- Preserve public API via re-exports

### D3-02: Split `sleep_service.py` 1,315 LoC

**Entry:**
- [x] Pass B M02 audit complete (`M02_services_audit.md`)
- [ ] D3-01 complete (dependencies.py stable base)
- [ ] IS-004 fix applied (remove module globals) before split
- [ ] Create branch `refactor/sleep-service-split`

**Exit:**
- [ ] Split into 4 focused files:
  - `sleep_window.py` — window computation + phase helpers
  - `sleep_scoring.py` — score calculation + AI integration
  - `sleep_push.py` — backend push logic
  - `sleep_history.py` — DB history query + backfill
- [ ] `SleepService` retained as facade in `sleep_service.py` (delegates to sub-modules)
- [ ] Each sub-module <= 400 LoC
- [ ] Tests pass
- [ ] M02 re-audit -> Readability axis improves from 2/3 to 3/3

**Risk flags:**
- Shared state across sub-modules (SLEEP_SCENARIO_PHASES module globals, _http_client singleton) — must unify or carefully distribute
- Overlap with IS-004 fix (remove module globals) — sequence: fix IS-004 first, then split
- AI client dependency (SleepAIClient) — sub-module must inject

**Mitigation:**
- Fix IS-004 first (~15 min) to remove module globals before split
- Define explicit injection contract between sub-modules via facade
- Preserve public `sleep_service.SleepService` import path

### D3-03: `sleep_ai_client.py` fix IS-001

**Entry:**
- [x] IS-001 bug file documented (`PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md`)
- [ ] Track 4 (model-api) verify `/api/v1/sleep/predict` endpoint behaviour + response schema
- [ ] Create branch `fix/sleep-ai-client-path`

**Exit:**
- [ ] 4 changes committed:
  - Path `/predict` -> `/api/v1/sleep/predict`
  - Probe URL `/health` -> `/api/v1/sleep/model-info`
  - Add `X-Internal-Service: iot-simulator` header
  - Response schema key `predictions[0]` -> `results[0]`
- [ ] Regression test: `test_sleep_ai_client::test_predict_correct_path_and_schema`
- [ ] E2E smoke: sleep scenario in running sim -> model-api -> BE, verify AI verdict engaged (not heuristic fallback)

**Risk flags:**
- Cross-repo breaking change if model-api also updated simultaneously
- Response schema mismatch (`predictions` vs `results`) may mask other field renames

**Mitigation:**
- Coordinate with Track 4 PR timing
- Write test with expected JSON response shape FIRST (red), then fix (green)

### Remaining tasks (D3-04 through D3-11) — pattern similar to above

Each follows entry/exit framework:
1. Entry: Relevant audit complete + branch ready + upstream deps stable
2. Exit: Scope-specific deliverables + tests pass + axis re-score target met

Detailed criteria deferred to individual task spec when scheduled.

---

## Effort estimates summary

| Tier | Tasks | Total est |
|---|---|---|
| Tier 1 (critical path) | D3-01, D3-02 | 20-26h |
| Tier 2 (high value) | D3-03 to D3-07 | 14-18h |
| Tier 3 (hygiene) | D3-08 to D3-11 | 23-29h |
| **Total Phase 3 IoT** | **11 tasks** | **57-73h** |

**Session cadence:** Assuming 3-4h/session focused work = ~16-24 sessions.

**Recommended sequence (session-by-session):**

1. Session 1-2: D3-01 phase 1 (dataclass extraction to records.py)
2. Session 3-4: D3-01 phase 2 (singletons to runtime.py) + green tests
3. Session 5: D3-01 phase 3 (policies.py + log_hub.py) + re-audit
4. Session 6: D3-05 or D3-06 (parallel opportunity during D3-01 cooldown)
5. Session 7: IS-004 quick fix + D3-02 (sleep_service split)
6. Session 8: D3-03 + D3-04 (AI clients)
7. Session 9-12: D3-08 per-adapter deep audit (batch 2 per session)
8. Session 13: D3-07 + D3-09
9. Session 14-15: D3-10 + D3-11 consolidation

---

## Exit criteria — Phase 3 IoT complete

Phase 3 cho IoT repo done khi:

- [ ] All 11 D3 tasks complete with commit + PR merged
- [ ] M02 re-audit: Readability 3/3, Architecture >= 2/3, Total >= 12/15
- [ ] M03 re-audit: Architecture >= 2/3, Total >= 11/15
- [ ] M04 re-audit: Architecture = 3/3 (repo migration done), Total >= 14/15
- [ ] M06 re-audit: Correctness >= 2/3 (IS-001 fixed), Total >= 11/15
- [ ] M09 re-audit: minor (per-adapter deep done)
- [ ] All Phase 1 new bugs (IS-002 through IS-013) either resolved or explicitly deferred with ADR
- [ ] Repo-level avg >= 13/15 (Mature band)
- [ ] No file > 800 LoC in api_server/
- [ ] Zero circular imports (verified via tool)
- [ ] Zero `dependencies.py` deferred-inside-method imports trong services/

---

## Cross-repo coordination (Phase 3 level)

Phase 3 IoT tasks may trigger cross-repo work:

| Task | Cross-repo impact | Coord needed |
|---|---|---|
| D3-03 IS-001 fix | model-api `/api/v1/sleep/predict` response schema stable | Yes — Track 4 |
| D3-05 repo migration | Cross-check `devices` schema assumptions vs Prisma + init_full_setup.sql | Yes — HS/HG |
| D3-02 sleep_service split | Callers in `dependencies.py` (same repo) | Internal |
| D3-08 per-adapter | Dataset files may have drifted — verify dataset version | Data science review |

---

## Approved decisions (2026-05-13)

Em recommend + anh approved per solo-dev capstone context.

### Decision 1 — Priority: Parallel D3-01 + Tier 2 independent (NOT strict sequence)

**Rationale:**
- D3-01 (12-16h) is large L task — solo dev context fatigue risk if done linearly
- D3-05 (repo migration) + D3-06 (scenarios.py audit) touch different files → zero merge conflict
- Interleaving reduces burnout while preserving critical path
- D3-02 strictly blocked by D3-01 (services import dependencies.py)

**Applied sequence:**
```
Sess 1-2: D3-01 phase 1 (records.py — dataclass extraction)
Sess 3:   D3-05 OR D3-06 (mental refresh, zero dep conflict)
Sess 4-5: D3-01 phase 2-3 (runtime.py + helpers)
Sess 6:   IS-004 quick fix + D3-02 kickoff
Sess 7-8: D3-02 completion + D3-03/04 AI clients
```

### Decision 2 — Rollback strategy: Fix forward via phased commits

**Rationale:**
- D3-01 done in 3 phases (dataclass → singletons → helpers) — mỗi phase commit riêng
- Green tests = continue. Tests red > 1 session → rollback + redesign
- Transition score drop acceptable (e.g. Readability 3 → 2 tạm thời) — chỉ flag if Architecture drops to 0 or tests red
- Solo dev without QA: revert toàn bộ work = lãng phí effort vs surgical fix forward

**Tag strategy:**
- Before D3-01: tag `pre-d3-01-dependencies-split` (last-resort rollback)
- After each D3-01 phase: tag `d3-01-phase-{1,2,3}-complete`

**Green-bar rule:** Tests failing for > 1 session = STOP, reassess.

### Decision 3 — Test coverage: Regression tests required, no per-task %

**Rationale:**
- Per-task coverage % adds ceremony without CI infra to enforce
- Simpler rule maps to existing testing-discipline steering: "Bug fix luôn có regression test"
- Current coverage baseline unknown → target % là guess
- Phase 5 hygiene can schedule dedicated "coverage audit" task when baseline established

**Rules applied:**
- **Bug fix tasks** (IS-001/002/003/008/010-013): regression test MANDATORY
- **Refactor tasks** (D3-01/02): existing tests must pass + not be weakened (iron law)
- **New public API** (D3-05 `has_required_tracks`): unit test MANDATORY
- **Deep audit only** tasks (D3-06/07/08): optional, spot-check if findings warrant

### Decision 4 — D3-08 per-adapter: 4/8 prioritized, skip stable ones

**Rationale:**
- 8 x 2h = 16h; cut 50% = 8h saved
- Research datasets released 2015-2018, adapters stable in production sim — regression unlikely
- Prioritized by risk + usage frequency
- Skipped ones remain auditable ad-hoc if runtime/Phase 4 exposes issue

**Priority adapters (4, ~8h):**
1. **PIF v3 adapter** — synthetic baseline, actively extended
2. **VitalDB adapter** — largest (250 LoC) + IS-013 consumer ties to this file
3. **UP-Fall adapter** — motion critical for fall detection pipeline
4. **Sleep-EDF adapter** — sleep scoring critical, ties to IS-001 flow

**Skipped adapters (4):**
- BIDMC (respiration — stable)
- WESAD (stress — secondary path, stable)
- PPG-DaLiA (HR — secondary path, stable)
- PAMAP2 (activity — stable)

**Revisit trigger:** Any bug surfaced in skipped adapter → promote to ad-hoc audit.

### Decision 5 — Timeline: Interleave rotation across repos (NOT 3-week aggressive IoT)

**Rationale:**
- Capstone = balanced coverage cross all 5 repos for presentation
- 3-week focused IoT skews presentation quality
- Context rotation reduces fatigue + cross-pollinates learning (e.g. M07 headers pattern led to IS-002 discovery in M02)
- Phase 4 security PR batch (IS-001 + IS-002 + HS-004 + D-015 cross-repo chain) requires ALL repos at Phase 1 baseline
- Only Tier 1 (D3-01, D3-02, ~25h) is strict prerequisite for Phase 4 sleep security

**Applied weekly flow:**

| Week | Focus | Tasks |
|---|---|---|
| 1-2 | IoT Phase 3 Tier 1 | D3-01 + D3-02 (~25h) |
| 3 | HealthGuard BE Phase 1 Track 1A | Pass A equivalent for HG |
| 4 | model-api Track 4 | IS-001 + internal-secret enforcement baseline |
| 5 | health_system BE Phase 1 | Pass A equivalent for HS BE |
| 6-7 | Phase 4 coordinated security PR | Batch IS-001/002/HS-004/D-015 cross-repo |
| 8+ | Phase 3 IoT Tier 2/3 + other repos Phase 3 | Interleaved per bandwidth |

**Key insight:** Phase 4 coordinated security fix cần understanding cross-repo impact → all repos phai Phase 1 audited TRUOC khi Phase 4 executes. Do do Tier 2/3 IoT defer den khi other repos catch up.

---

## Effort revised (after decisions)

| Tier | Tasks | Original est | Post-decision |
|---|---|---|---|
| Tier 1 (critical path) | D3-01, D3-02 | 20-26h | 20-26h (unchanged) |
| Tier 2 (high value) | D3-03 to D3-07 | 14-18h | 14-18h (unchanged) |
| Tier 3 (hygiene) | D3-08 to D3-11 | 23-29h | **15-21h** (D3-08 halved) |
| **Total Phase 3 IoT** | **11 tasks** | **57-73h** | **49-65h** |

**Session count:** ~14-22 sessions (3-4h each).

---

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Pass A summary: [_TRACK_SUMMARY_PASS_A.md](./_TRACK_SUMMARY_PASS_A.md)
- Pass B+C summary: [_TRACK_SUMMARY_PASS_B_C.md](./_TRACK_SUMMARY_PASS_B_C.md)
- Individual module audits: M01-M09
- Bugs: IS-001 through IS-013 in `PM_REVIEW/BUGS/`
- ADR pending: none currently. Phase 3 kickoff may trigger ADR-016 (dependencies.py split rationale), ADR-017 (sleep_service decomposition boundary).
