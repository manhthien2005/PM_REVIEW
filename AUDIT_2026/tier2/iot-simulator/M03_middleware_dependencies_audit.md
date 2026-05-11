# Audit: M03 — Middleware + Dependencies

**Module:** `Iot_Simulator_clean/api_server/{middleware/, dependencies.py}`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 5A (IoT sim Pass A — security focus)

## Scope

| File | LoC | Role |
|---|---|---|
| `middleware/auth.py` | 39 | `require_admin_key` FastAPI dependency (X-Admin-Key header) |
| `middleware/rate_limit.py` | 119 | Sliding-window in-memory rate limiter (per-IP) |
| `dependencies.py` | **3,266** | God file — SimulatorRuntime + all service wiring + dataclasses |

**Total:** ~3,424 LoC (but `dependencies.py` alone = 95% of module)

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Auth + rate limit logic OK. SimulatorRuntime massive — multiple risks. |
| Readability | 1/3 | dependencies.py 3,266 LoC = clear bypass of file-size hygiene. |
| Architecture | 1/3 | Service layer extracted ✓ but runtime god class persists; D-015 enforcement incomplete. |
| **Security** | **2/3** | Auth/rate limit infra good. Applied to only 1/10 routers — D-015. |
| Performance | 2/3 | Rate limit O(1) sliding window. SimulatorRuntime lock contention risk under load. |
| **Total** | **8/15** | Band: **🟠 Needs attention** |

## Findings

### Correctness (2/3)

**middleware/auth.py:**
- ✓ Pattern correct: env var unset → bypass (dev mode), env set → enforce header
- ✓ HTTP 403 với message clear ("Invalid or missing admin API key")
- ⚠️ No structured logging cho audit trail (failed auth attempts NOT logged) — security incident invisible

**middleware/rate_limit.py:**
- ✓ Sliding window correct (line 70-83): cutoff = now - window, evict old timestamps, check len < max
- ✓ Periodic eviction prevents memory leak (line 67-68: every 100 calls)
- ✓ Read/write split với separate limiters (line 91-96)
- ✓ Headers `Retry-After: 60` + `X-RateLimit-Remaining` returned
- ⚠️ `client_ip = request.client.host if request.client else "unknown"` (line 103) → all unknown clients share single bucket → easy bypass by spoofing
- ⚠️ No `X-Forwarded-For` / `X-Real-IP` parsing → behind proxy, all requests appear from proxy IP (single bucket)

**dependencies.py:**
- ✓ Lifespan auto-recovery: `recover_active_sessions()` reloads from DB on startup (line 65)
- ✓ Dual import path `try Iot_Simulator.api_server / except ModuleNotFoundError` supports both `python -m` and `uvicorn` patterns (line 27-161)
- ⚠️ **3,266 LoC** in single file — increases bug surface area dramatically
- ⚠️ `SimulatorRuntime.__init__` ~270 lines (líne 596-870 est) — initializes 5+ service singletons + 20+ state dicts → constructor doing too much
- ⚠️ `_FALL_VARIANT_POLICIES` dataclass với 6 variants hardcoded (line 218-284) — should be config-driven (matches existing pattern trong `pre_model_trigger/rules_config.json`)

### Readability (1/3)

**middleware/auth.py:** ✓ 3/3 standalone — clear docstring, single function, obvious behavior
**middleware/rate_limit.py:** ✓ 3/3 standalone — well-commented, naming clear, sliding window logic transparent

**dependencies.py: 1/3** — single biggest readability issue trong toàn workspace audit so far:
- 🚨 **File size: 3,266 LoC** vs framework guideline (≤ 500 LoC split candidate) → 6.5x over
- 🚨 SimulatorRuntime class has dataclasses + helpers + class body all in one file
- ⚠️ Multiple `dataclass` definitions interleaved với business logic (DeviceRecord line 376, SessionRecord 413, EventRecord 438, RiskSnapshot 460, PendingTickPublish 472, PendingHeartbeatUpdate 478, PendingAlertCall 484, PreparedAlertPush 492, SessionSideEffects 502) — should be in `schemas.py` or `models.py`
- ⚠️ `LogHub` class (line 515-579) embedded — should be separate `logs.py`
- ⚠️ Comments verbose nhưng code commentary outdated trong vài chỗ (vd "MEDIUM #7", "MEDIUM #8", "HIGH #1 fix", "HIGH #6 fix" — historical fix tags accumulate noise)
- ✓ Module docstring explanation re: dual import paths (line 23-26) clear

### Architecture (1/3)

**Service decomposition incomplete:**
- ✓ Decent service extraction: `DeviceService`, `VitalsService`, `AlertService`, `SessionService`, `SleepService` exists (per comments "Task 3.1" - "Task 3.5")
- ✗ **`SimulatorRuntime` still god class** — comment line 581-594 claims "thin orchestration facade" but class body extends beyond line 770 (~2,500+ LoC class)
- ✗ Mutable shared state passed by reference (devices dict, sessions dict, etc.) to services → tight coupling, hard to test in isolation
- ✗ `_dashboard_cache_ref: list = [None]` (line 736) — workaround pattern to share mutable cache across services. Code smell of incomplete extraction.

**D-015 (Phase -1.B) status:**
- ✓ Infrastructure exists (`require_admin_key`)
- ✓ Applied to `devices.py` admin sub-router (`devices.py:50-53`)
- ✗ **NOT applied to other 9 routers** (analytics, dashboard, events, registry, scenarios, sessions, settings, verification, vitals) — verified via `grep` (only `devices.py` references `require_admin_key`)

→ **Partial D-015 closure**: dev/prod distinction relies entirely on env var presence. Production deploy CHECKLIST must verify `SIM_ADMIN_API_KEY` set + verify all routers carry auth (currently only devices).

### Security (2/3)

**Positives:**
- ✓ `auth.py` graceful dev bypass (env unset → allow) — clear contract
- ✓ Rate limiter applied globally via `RateLimitMiddleware` middleware (main.py:82) → covers ALL endpoints
- ✓ `dependencies.py:692` reads `INTERNAL_SERVICE_SECRET` cho `HealthGuardAPIClient` → internal secret pattern available
- ✓ HttpPublisher (line 673) sends `X-Internal-Service: iot-simulator` header ✓

**Negatives:**
- ⚠️ **D-015 partial**: only 1/10 routers protected. Most data exposed without auth (vitals, sessions, scenarios, settings).
- ⚠️ No audit log for failed auth (`require_admin_key` mismatch → 403 but no logger.warning) — security incident invisible
- ⚠️ Rate limiter keyed by `request.client.host` — behind proxy = bypass
- ⚠️ `dependencies.py:692` `os.environ.get("INTERNAL_SERVICE_SECRET") or None` — secret can be None silently if env missing → outbound calls to backend admin will fail at runtime not startup
- ⚠️ `_FALL_VARIANT_POLICIES` hardcoded simulated_confidence values (line 229, 239, 250, 261, 271, 282) — should be env-configurable for production tuning without code change

**Anti-pattern flag check:** No `eval`, `exec`, SQL concat. No `dangerouslySetInnerHTML`. No hardcoded credentials (env-based ✓).

### Performance (2/3)

**Positives:**
- ✓ Sliding window rate limiter O(1) amortized (deque + cutoff prune)
- ✓ Periodic eviction (every 100 calls) — bounded memory
- ✓ `RLock` instead of `Lock` allows reentrancy → no deadlock risk from nested service calls

**Concerns:**
- ⚠️ Single `RLock` shared across services (line 659) → high contention under concurrent requests. Service operations on different domain (vitals vs sessions vs sleep) serialize unnecessarily.
- ⚠️ `event_history: collections.deque(maxlen=2000)` (line 649) — bounded ✓ but no per-device pruning, can flood for high-traffic device
- ⚠️ Dashboard cache via mutable list (`_dashboard_cache_ref: list = [None]` line 736) — TTL logic likely in service layer, but pattern fragile
- ⚠️ Background tick thread (line 64 `runtime.start_background_tick()`) — verify Phase 3 thread join on shutdown to prevent zombie threads

## Recommended actions (Phase 4)

### P0 — Security
- [ ] **D-015 closure:** Add `dependencies=[Depends(require_admin_key)]` to ALL 10 router declarations (currently only `devices.py`)
- [ ] Verify `INTERNAL_SERVICE_SECRET` env var REQUIRED at startup (fail-fast if missing in production) — currently silent None
- [ ] Add audit logger for failed `require_admin_key` (line 35) — log IP + path + timestamp

### P1 — Architecture cleanup
- [ ] **Split `dependencies.py`** into:
  - `dependencies.py` — FastAPI deps only (`get_runtime`, `set_runtime`)
  - `runtime.py` — SimulatorRuntime class body
  - `records.py` — DeviceRecord, SessionRecord, EventRecord, RiskSnapshot dataclasses
  - `policies.py` — FALL_VARIANT_POLICIES, FALL_VARIANT_TO_PERSONA
  - `log_hub.py` — LogHub class
- [ ] Extract `_FALL_VARIANT_POLICIES` to YAML config (mirror `pre_model_trigger/health_rules/rules_config.json` pattern)

### P2 — Defense in depth
- [ ] Rate limiter: parse `X-Forwarded-For` for true client IP (verify trust chain)
- [ ] Per-service locks instead of single global `RLock`
- [ ] Bounded per-device event history (vd `deque(maxlen=200)` per device)

## Out of scope (defer Phase 3 deep-dive)

- Lines 773-3266 of `dependencies.py` (SimulatorRuntime method body) — Phase 3 mandatory deep-dive
- Service wiring detail (DeviceService, VitalsService internals)
- Background tick thread lifecycle
- Cache eviction strategy
- TriggerOrchestrator integration depth

## Cross-references

- Phase -1.B: [D-015](../../tier1/api_contract_v1.md) — Iot_Simulator auth coverage
- Phase 0: Module M03 in [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)
- **Phase 3 critical candidate:** `dependencies.py` 3,266 LoC god file split
