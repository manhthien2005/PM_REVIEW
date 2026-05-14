# Verification Report - `Iot_Simulator_clean / API_SERVER_ROUTERS`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/API_SERVER_ROUTERS.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** PASS - 1 CRITICAL (Q6 already done) + 2 MEDIUM + 2 LOW findings.
**Verdict (resolved 2026-05-13):** PASS v2 - Anh approved F-AR-01 through F-AR-05. All 5 doc fixes DONE. No code changes, no ADR. Phase 4 backlog empty for this module.

---

## TL;DR

- **10 routers OK** (verified by `ls routers/` + `main.py` include_router calls): analytics, dashboard, devices, events, registry, scenarios, sessions, settings, verification, vitals. Exact match.
- **Admin sub-router OK** — `_admin_router` trong `devices.py:50-54` with `Depends(require_admin_key)` dependency. Merged into main router via `router.include_router(_admin_router)` line 245.
- **5 services OK** — DeviceService / VitalsService / AlertService / SessionService / SleepService all exist under `api_server/services/`.
- **Auto-recovery OK** — `lifespan()` calls `runtime.recover_active_sessions()` on startup.
- **WebSocket OK** — `/ws/logs/{session_id}` registered at app level.
- **Rate limiting OK** — `RateLimitMiddleware` added + CORS middleware (outermost per LIFO note).
- **CRITICAL finding C1: Q6 already implemented.** Health payload v2 (`dependencies.py:1973-2070`) ALREADY contains `preTrigger` block + `degradedReasons` with `pre_trigger_misconfigured` flag. Phase 4 task "add pre-model trigger status" = NOOP, should be removed.
- **M1 Boundary cross-ref wrong.** Doc says "IoT sim -> health_system BE `/api/internal/telemetry`" (inherited same mistake tu ETL_TRANSPORT/SIMULATOR_CORE earlier verify). Per ADR-013 + XR-001: actual `/mobile/telemetry/*`.
- **L1 ADR-004 prefix target missing** — doc doesn't reference ADR-004 `/api/v1/sim/*` target state.
- **L2 Health payload scope broader than claim** — doc says "subsystem status (API, backend, MQTT, DB, model-api)" but payload v2 actually has: runtime/database/backend/modelApi/preTrigger/telemetry + legacy flat keys + degradedReasons. Richer than doc implies.

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 Router count + prefix

**Doc claim:** 10 routers duoi `/api/sim/`.

**Code reality** (`main.py:92-101` + `routers/` dir):

| Router | File | Prefix | Registered |
|---|---|---|---|
| devices | `devices.py` | `/api/sim` | OK |
| dashboard | `dashboard.py` | `/api/sim` | OK |
| registry | `registry.py` | `/api/sim` | OK |
| scenarios | `scenarios.py` | `/api/sim` | OK |
| sessions | `sessions.py` | `/api/sim` | OK |
| vitals | `vitals.py` | `/api/sim` | OK |
| events | `events.py` | `/api/sim` | OK |
| verification | `verification.py` | `/api/sim` | OK |
| analytics | `analytics.py` | `/api/sim` | OK |
| settings | `settings.py` | `/api/sim` | OK |

**Count:** 10 routers. OK match.

**ADR-004 note (L1):** Target prefix per ADR-004 = `/api/v1/sim/*`. Current `/api/sim/*` = D-019 drift item (missing `/v1`). Doc should reference ADR-004 as target.

### 1.2 Admin sub-router

**Doc claim:** "Admin sub-router (`/api/sim/admin/*`) protected boi `require_admin_key`".

**Code reality** (`devices.py:50-54, 245`):
```
_admin_router = APIRouter(
    tags=["admin-devices"],
    dependencies=[Depends(require_admin_key)],
)
# ... endpoints @_admin_router.get("/admin/db-devices"), etc.
router.include_router(_admin_router)  # merged into main devices router
```

Admin endpoints:
- `GET /admin/db-devices`
- `POST /admin/db-devices`, `/admin/db-devices/{id}/assign`, `/activate`, `/deactivate`, `/batch-activate`
- `DELETE /admin/db-devices/{id}`
- `GET /admin/users/search`

Final path after main router `/api/sim` prefix + admin routes = `/api/sim/admin/*`. OK confirmed.

**Verdict:** OK Admin sub-router structure accurate. Only attached to devices router (not a standalone admin router across all domains).

### 1.3 5 services claim

**Doc claim:** "5 services: device, vitals, alert, session, sleep".

**Code reality** (grep `class.*Service` trong `api_server/services/`):

| Service | Class | File |
|---|---|---|
| Device | `DeviceService` | `device_service.py:64` |
| Vitals | `VitalsService` | `vitals_service.py:69` |
| Alert | `AlertService` | `alert_service.py:42` |
| Session | `SessionService` | `session_service.py:46` |
| Sleep | `SleepService` | `sleep_service.py:66` |

**Verdict:** OK 5/5 exact match.

### 1.4 Lifespan + auto-recovery

**Doc claim:** "Lifespan: auto-recover active DB device sessions on startup".

**Code reality** (`main.py:61-76`):
```
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    runtime = SimulatorRuntime()
    set_runtime(runtime)
    app.state.runtime = runtime
    runtime.start_background_tick()
    recovered = runtime.recover_active_sessions()
    if recovered:
        logger.info("Auto-recovered %d active device session(s) on startup", recovered)
    ...
    yield
    runtime.shutdown()
```

**Verdict:** OK Auto-recovery confirmed + background tick + shutdown handler.

### 1.5 WebSocket + CORS + RateLimit

**Doc claim:** WebSocket `/ws/logs/{session_id}`, CORS localhost:5173/5174, RateLimitMiddleware custom.

**Code reality** (`main.py:79-90, 114-117`):
- `ws_logs(websocket, session_id)` route at app level OK.
- CORS: `ALLOWED_ORIGINS` env var default `http://localhost:5173,http://localhost:5174` + regex `http://localhost:\d+` for any port. Broader than just 5173/5174.
- `RateLimitMiddleware` added before CORS (LIFO = CORS outermost per explicit comment).

**Verdict:** OK Claims accurate. Minor: CORS regex allows any localhost port (not just 5173/5174 as doc says).

### 1.6 Health endpoint scope (Q6 + B7) — CRITICAL finding

**Doc claim Q6:** "Keep + ensure reflect pre-model trigger status" + Phase 4 task "Health endpoint: add pre-model trigger status | New | P2 | 1h".

**Code reality** (`dependencies.py:1973-2070` `health_payload()`):

Payload v2 already contains:
```
{
    "schemaVersion": "2.0",
    "runtime": {state, version, uptimeSeconds},
    "database": {state, lastCheckMs},
    "backend": {state, url, lastLatencyMs, lastError},
    "modelApi": {state, url, lastCheckedAt, lastScoreSource, lastError},
    "preTrigger": pre_trigger_block,    # ALREADY INCLUDES PRE-MODEL TRIGGER
    "telemetry": telemetry_block,
    "degradedReasons": [...],           # includes "pre_trigger_misconfigured"
    # Legacy flat keys for backward compat
}
```

`_compute_pre_trigger_block()` (referenced in PRE_MODEL_TRIGGER verify) returns `{mode, threshold_source, ...}` per F-PT-03 mode matrix.

**Verdict:** FAIL Q6 Phase 4 task "add pre-model trigger status to health endpoint" = ALREADY DONE. Health payload v2 implemented with `preTrigger` block. 1h effort estimate = 0min (already shipped).

Phase 4 remaining work for health endpoint:
- Per F-PT-03: Fix `preTrigger.mode` report accuracy (shadow detection works per mode matrix).
- Per F-PT-04: Fix `threshold_source` false-positive "db" label -> "Hardcode defaults".

Both tracked in PRE_MODEL_TRIGGER v2 backlog, NOT duplicated here.

### 1.7 Boundary cross-reference claim

**Doc claim (Cross-references):** "Boundary contract: IoT sim -> health_system BE `/api/internal/telemetry`".

**Verified earlier** (ETL_TRANSPORT verify C2 + XR-001): Reality = `/mobile/telemetry/*`. No `/api/internal/*` endpoint in health_system BE serving IoT sim.

**Verdict:** FAIL Same cross-ref bug as ETL_TRANSPORT v1. Doc API_SERVER_ROUTERS inherited the wrong boundary from steering. Fix to reference corrected paths from topology_v2.md Path 6 + Path 7 + ADR-013 + XR-001.

### 1.8 Admin FE consumer claim

**Doc claim:** "Admin FE: simulator-web (Vite + React) consumes all these endpoints".

**Code reality:**
- `simulator-web/` exists at repo root.
- FE API client `simulator-web/src/services/*.ts` (verified earlier - `scenarioApi.ts`, `deviceApi.ts`, etc.).
- CORS middleware allows localhost:* regex.

**Verdict:** OK Claim accurate. Note: simulator-web is separate FE from admin web (HealthGuard admin frontend port 5173). Both use Vite + React but different repos + different domains.

### 1.9 Transport publish claim (B6)

**Doc claim B6:** "Transport publish: tick output -> HTTP to health_system BE".

**Code reality:** Per ADR-013 (from ETL_TRANSPORT verify), transport layer is NOT active at runtime. Vitals tick writes direct to DB per plan. Alert/sleep/risk go via direct httpx (not TransportRouter).

**Verdict:** WARN B6 wording outdated. Should reference ADR-013 multi-path architecture:
- Vitals tick -> direct DB INSERT (per ADR-013).
- Alert push -> `alert_service._push_alert_to_backend()` HTTP.
- Sleep push -> `sleep_service._push_sleep_to_backend()` HTTP.
- Risk -> `_trigger_risk_inference()` HTTP.
- Heartbeat -> direct DB write.

---

## 2. Issues enumerated (prioritized)

### CRITICAL - Phase 4 backlog error

**C1. Q6 "add pre-model trigger status" Phase 4 task already DONE**
- **Evidence:** Section 1.6. Health payload v2 has `preTrigger` block + `degradedReasons` including `pre_trigger_misconfigured`.
- **Impact:** Phase 4 backlog P2 "1h" task = NOOP. Effort budget over-allocated.
- **Fix direction:** Remove Phase 4 task. Replace with note: "Health payload v2 already includes preTrigger block (dependencies.py:2029). Phase 4 work for pre-model trigger status lives in PRE_MODEL_TRIGGER module (F-PT-03 mode accuracy + F-PT-04 threshold source label)".
- **Effort:** Doc 10min.

### HIGH - none

### MEDIUM - Wrong cross-refs

**M1. Boundary cross-reference `/api/internal/telemetry` wrong**
- **Evidence:** Section 1.7. Same as ETL_TRANSPORT v1 + XR-001.
- **Impact:** Doc continues to propagate wrong boundary. Reader confused.
- **Fix direction:** Update Cross-references - link to topology_v2.md Path 6 + Path 7 + ADR-013 + XR-001 for actual paths. Remove `/api/internal/telemetry` line.
- **Effort:** Doc 10min.

**M2. B6 transport publish outdated post-ADR-013**
- **Evidence:** Section 1.9. Transport path unused; multi-path architecture present.
- **Impact:** Reader expects single transport pipeline, reality = 5 separate paths.
- **Fix direction:** Rewrite B6:
  - "Telemetry delivery = 5 paths per ADR-013: vitals tick -> direct DB, alert -> HTTP, sleep -> HTTP, risk -> HTTP, heartbeat -> direct DB. Transport router (`transport/*`) unused at runtime, reserved for future MQTT enable."
- **Effort:** Doc 10min.

### LOW - Wording

**L1. ADR-004 prefix target not referenced**
- **Evidence:** Section 1.1. Current `/api/sim/*` is D-019 drift per ADR-004 standardization.
- **Fix direction:** Add note: "Current `/api/sim/*` prefix. Per ADR-004 target = `/api/v1/sim/*` (Phase 4 refactor)."
- **Effort:** 5min doc.

**L2. Health payload scope broader than claim**
- **Evidence:** Section 1.6. Payload v2 has runtime/database/backend/modelApi/preTrigger/telemetry + degradedReasons + legacy flat keys. Doc only mentions "API, backend, MQTT, DB, model-api".
- **Fix direction:** Update B7 + Q6 description:
  - "Health payload v2: runtime state + database + backend probe + modelApi probe + preTrigger block + telemetry block + degradedReasons array + legacy flat keys (for backward compat)."
- **Effort:** 10min doc.

---

## 3. Fix backlog (prioritized) — status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-AR-01 | Remove Phase 4 Q6 task (C1) - already implemented | P0 | 10min | **DONE** — v2 Q6 revised, Impact Phase 4 table shows "DONE" |
| F-AR-02 | Fix cross-reference `/api/internal/telemetry` (M1) | P1 | 10min | **DONE** — v2 Cross-references Topology section |
| F-AR-03 | Rewrite B6 multi-path per ADR-013 (M2) | P1 | 10min | **DONE** — v2 B6 rewritten |
| F-AR-04 | Add ADR-004 prefix target note (L1) | P2 | 5min | **DONE** — v2 Code state + Intent Statement |
| F-AR-05 | Expand health payload v2 description (L2) | P2 | 10min | **DONE** — v2 Code state health endpoint block + B7 |

**Status summary:** 5/5 DONE.

**Total effort spent today:** ~50min (verify report + drift doc v2 rewrite).
**Remaining (Phase 4 code branch):** Effectively empty for API_SERVER_ROUTERS module. Related work tracked elsewhere:
- PRE_MODEL_TRIGGER v2 (F-PT-03/04) - preTrigger mode + threshold source accuracy.
- ADR-004 rollout - prefix standardization.
- SLEEP_AI_CLIENT F-SA-03 - `lastSuccessAt` addition to modelApi block.

---

## 4. Cross-repo impact

### Affected docs/specs
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/ETL_TRANSPORT.md` v2 - already reflects ADR-013 multi-path.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/PRE_MODEL_TRIGGER.md` v2 - owns preTrigger block work.
- `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - reference source cho correct boundaries.
- `PM_REVIEW/BUGS/XR-001-topology-steering-endpoint-prefix-drift.md` - cross-ref topic.
- `PM_REVIEW/ADR/004-api-prefix-standardization.md` + ADR-013 - reference targets.

### Affected code repos
None. Module verified stable. No code changes.

### ADRs needed
None. All decisions already covered by ADR-004, ADR-013, ADR-015.

---

## 5. Next steps - em de xuat

1. **Anh approve em apply F-AR-01 through F-AR-05 doc fixes** (~45min total).
2. **No decisions needed** - all refinements are factual corrections.
3. **Phase 4 backlog** post-fix = effectively empty for API_SERVER_ROUTERS module.

---

## Appendix - evidence index

- Main entry: `api_server/main.py` (router registration + lifespan + middleware)
- Routers: `api_server/routers/*.py` (10 files verified)
- Admin sub-router: `api_server/routers/devices.py:50-54, 245`
- Admin auth: `api_server/middleware/auth.py:26-29` (`require_admin_key`)
- Rate limit: `api_server/middleware/rate_limit.py` (custom RateLimitMiddleware)
- Health payload: `api_server/dependencies.py:1973-2070` (v2 payload with preTrigger block)
- Services: `api_server/services/{device,vitals,alert,session,sleep}_service.py`
- WebSocket: `api_server/ws/log_stream.py`
- FE consumer: `simulator-web/src/services/*.ts`
- ADRs: ADR-004 (api prefix), ADR-013 (direct-DB vitals), ADR-015 (severity mapping)
- Topology: `tier1/topology_v2.md` § Path 6, Path 7
