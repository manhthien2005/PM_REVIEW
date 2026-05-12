# Audit: M01 — Routers (HTTP layer)

**Module:** `Iot_Simulator_clean/api_server/routers/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 5A (IoT sim Pass A — security focus)

## Scope

10 router files (~1,200 LoC):

| File | LoC est | Endpoints | Auth applied? |
|---|---|---|---|
| `devices.py` | ~120 | 5 | ✓ `require_admin_key` on `_admin_router` sub-router (line 50-53) |
| `analytics.py` | ~90 | 4 | ✗ |
| `dashboard.py` | ~30 | 1 | ✗ |
| `events.py` | ~80 | 4 | ✗ |
| `registry.py` | ~30 | 1 | ✗ |
| `scenarios.py` | ~450 | 4 | ✗ |
| `sessions.py` | ~150 | 6 | ✗ |
| `settings.py` | ~200 | 3 | ✗ |
| `verification.py` | ~30 | 1 | ✗ |
| `vitals.py` | ~30 | 1 | ✗ |

**Total endpoints:** ~29 (matches Phase -1.B catalog)

**Audit method:** Pass A focus = security coverage. Detailed router logic defer Pass B.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Endpoint pattern consistent. devices.py good admin separation. Defer Pass B for per-endpoint deep. |
| Readability | 2/3 | Routers thin. devices.py double-sub-router pattern (admin vs public) borderline. |
| Architecture | 2/3 | Thin routers ✓. Mixed concerns in scenarios.py (450 LoC). |
| **Security** | **1/3** | 9/10 routers NO auth. devices.py partial coverage only. |
| Performance | 3/3 | Async signatures, no obvious bottleneck. |
| **Total** | **10/15** | Band: **🔴 Critical** (Security=1 below threshold, but not auto-trigger since not 0) |

## Findings

### Correctness (2/3)

- ✓ All routers use FastAPI `APIRouter` with `tags`
- ✓ `devices.py` separates admin endpoints into sub-router (`_admin_router`) with auth → clear public/admin contract
- ✓ Dual `POST /events` + `POST /events/inject` decorators stacked on same function (Phase -1.B noted) — works correctly per FastAPI semantics
- ⚠️ `scenarios.py` 450 LoC = largest router — Phase 3 deep-dive candidate (likely god router pattern)
- ⚠️ `settings.py` mixes runtime config GET/PUT with reset POST — single domain but 3 different concerns
- Defer per-endpoint correctness to Pass B / Phase 3

### Readability (2/3)

- ✓ Each router has prefix + tags (per Phase -1.B catalog)
- ✓ Routers thin (mostly delegate to `runtime.<service>.<method>()`)
- ⚠️ Dual import pattern (try `Iot_Simulator.api_server` / except `api_server`) repeated trong mỗi router → noise. Should extract to single `_imports.py` helper.
- ⚠️ `devices.py` has TWO routers (public `router` + private `_admin_router`) in same file → reader must scroll to understand which endpoint is admin-only

### Architecture (2/3)

**Pros:**
- ✓ Router → SimulatorRuntime delegation (consistent pattern across files)
- ✓ Response models declared via `response_model=` parameter → OpenAPI accurate
- ✓ Pydantic schemas defined trong `api_server/schemas.py` (em chưa scan but inferred from imports)
- ✓ `Depends(get_runtime)` used → testable via override

**Cons:**
- ⚠️ **Routers reach into `runtime.<service>` directly** instead of injecting services as dependencies. Tight coupling: changing service contract requires update at every router.
- ⚠️ `scenarios.py:326-401` apply_scenario logic likely contains business logic better placed in `ScenarioService` (Pass B verify)
- ⚠️ `events.py` injects events directly via runtime — should be `runtime.event_service.inject(...)` pattern (Pass B verify if service exists)

### Security (1/3) — D-015

**🚨 D-015 (Phase -1.B):** 9 out of 10 routers have NO `Depends(require_admin_key)`:

| Router | Auth? | Endpoints exposed |
|---|---|---|
| `devices.py` (admin sub) | ✓ | 5 admin endpoints |
| `analytics.py` | ✗ | sleep history, risk scores |
| `dashboard.py` | ✗ | dashboard summary |
| `events.py` | ✗ | inject fall, device-status events |
| `registry.py` | ✗ | dataset registry status |
| `scenarios.py` | ✗ | apply scenario, sleep backfill |
| `sessions.py` | ✗ | create/start/stop sessions, fall state |
| `settings.py` | ✗ | mutate runtime config!! (security critical) |
| `verification.py` | ✗ | latest verification results |
| `vitals.py` | ✗ | latest vitals data |

**Impact:**
- `settings.py PUT /api/sim/settings/runtime` → modifies runtime config without auth → anyone on network can disable rate limiting (via env var injection) or alter behavior
- `events.py POST /api/sim/events/inject` → spoof fall events into the simulator → false alarm fan-out to backend
- `sessions.py POST /api/sim/sessions` → create unauthorized sim sessions → DB pollution

**Mitigating factors:**
- IoT sim is typically run locally (dev tool). Production deploy practice (if exists) needs explicit policy.
- Rate limit middleware applies globally → spam attacks throttled
- CORS allowlist localhost-only (main.py:76) → browser-based attacks blocked

**Score 1/3 (not 0):** Auth infra exists, partial coverage on most security-sensitive (devices admin). Bumping to 1.

### Performance (3/3)

- ✓ `async def` signatures throughout
- ✓ Runtime delegation O(1) lookups (singleton + dict)
- ✓ No obvious N+1 in router logic (Pass B verify service layer)
- ✓ Pydantic response_model serialization fast (v2 Rust core)

## Recommended actions (Phase 4)

### P0 — Security closure D-015
- [ ] Add `dependencies=[Depends(require_admin_key)]` to ALL 9 unprotected routers
- [ ] Decide policy: which endpoints actually NEED auth vs which are intentional public (vd `vitals.py GET latest` for FE dashboard display)
  - Recommendation: ALL mutating endpoints (POST/PUT/PATCH/DELETE) require auth. Read endpoints (GET) optional based on data sensitivity.
- [ ] Document in main.py header comment what's protected

### P1 — Pass B audit
- [ ] Per-router deep-dive (scenarios.py 450 LoC priority)
- [ ] Verify service layer extraction completeness (`ScenarioService`, `EventService`)
- [ ] Validate request/response schemas at boundary

### P2 — Cleanup
- [ ] Extract dual import boilerplate to `_imports.py` helper
- [ ] Move `devices.py` admin endpoints to separate `devices_admin.py` file (single-router-per-file convention)

## Out of scope (defer Pass B + Phase 3)

- Per-endpoint request/response shape validation
- Detailed business logic review
- Schema parity with consumer (simulator-web React frontend)
- WebSocket route audit (em chỉ check HTTP routers Pass A)

## Cross-references

- Phase -1.B: [D-015](../../tier1/api_contract_v1.md) — Iot_Simulator auth coverage (THIS module fix)
- Phase 0: Module M01 in [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)
- Related: M03 has `require_admin_key` infra, M01 needs to USE it
