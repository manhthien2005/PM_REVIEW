# Intent Drift Review — Iot_Simulator_clean / API_SERVER_ROUTERS

**Status:** Confirmed v2 (2026-05-13) — C1 Q6 task removed (already shipped), M1/M2 cross-ref + B6 transport wording fixed per ADR-013, L1/L2 minor additions
**Repo:** `Iot_Simulator_clean`
**Module:** API_SERVER_ROUTERS
**Related UCs (old):** N/A (internal tooling — no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/API_SERVER_ROUTERS_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** 10 routers + admin sub-router + 5 services + lifespan + middleware documented. Q6 Phase 4 task proposed (1h add preTrigger status).
- **v2 (2026-05-13 afternoon):** Verify pass phat hien:
  - C1 Q6 already DONE - health payload v2 ALREADY includes preTrigger block. Phase 4 task = NOOP.
  - M1 Cross-ref `/api/internal/telemetry` wrong (same XR-001 bug) -> fixed to reference topology_v2.md + ADR-013.
  - M2 B6 transport publish outdated -> rewritten per ADR-013 multi-path architecture.
  - L1 ADR-004 prefix target note added.
  - L2 Health payload v2 scope broader than v1 claim - expanded description.

---

## Muc tieu doc nay

Capture intent cho API Server Routers — REST surface layer cua IoT Simulator.
Internal tooling, khong co UC cu.

---

## Code state — what currently exists

**Router structure (10 routers):**
- 10 routers duoi `/api/sim/` prefix (current) - analytics, dashboard, devices, events, registry, scenarios, sessions, settings, verification, vitals.
- **ADR-004 target:** `/api/v1/sim/*` (Phase 4 refactor, current = D-019 drift).

**Admin protection:**
- `_admin_router` embedded in `devices.py:50-54` - protected by `Depends(require_admin_key)` (X-Admin-Key header).
- Endpoints: `/api/sim/admin/db-devices*`, `/api/sim/admin/users/search`.
- Admin scope: device CRUD + user search only (not a cross-domain admin router).

**Non-admin:** Open (no auth) - IoT sim = internal localhost tool per Q1.

**Services (5) — `api_server/services/`:**
- `DeviceService` - simulated device CRUD + binding + admin DB device lifecycle.
- `VitalsService` - vitals severity classification + sample building.
- `AlertService` - alert pushing + event recording + event history.
- `SessionService` - session CRUD + lifecycle.
- `SleepService` - sleep session build/score/push/backfill/history.

**Orchestration:** `SimulatorRuntime` singleton (`dependencies.py`) — facade over 5 services + orchestrator + AI clients.

**WebSocket:** `/ws/logs/{session_id}` - real-time log stream via LogHub pub/sub.

**Middleware:**
- `RateLimitMiddleware` (custom, `api_server/middleware/rate_limit.py`).
- `CORSMiddleware` outermost (LIFO order per explicit comment) - allows `ALLOWED_ORIGINS` env + regex `http://localhost:\d+` (any localhost port).

**Lifespan:**
- `SimulatorRuntime()` init -> `start_background_tick()` -> `recover_active_sessions()` on startup.
- `runtime.shutdown()` on teardown.

**Health endpoint (`/api/sim/health`) - payload v2 schema:**
```
{
    "schemaVersion": "2.0",
    "runtime": {state, version, uptimeSeconds},
    "database": {state, lastCheckMs},
    "backend": {state, url, lastLatencyMs, lastError},
    "modelApi": {state, url, lastCheckedAt, lastScoreSource, lastError},
    "preTrigger": {mode, threshold_source, ...},   # ALREADY IMPLEMENTED v2 (per F-PT-03/04)
    "telemetry": {...},
    "degradedReasons": ["backend_unreachable", "model_api_unavailable", "pre_trigger_misconfigured", ...],
    # + legacy flat keys (status, api, backendStatus, mqtt, db, version) for backward compat
}
```

Key finding: `preTrigger` block already ships - NO additional Phase 4 work needed for "add pre-model trigger status" as originally planned in v1 Q6.

---

## Anh's decisions

### Q1: Auth model?

**Decision (unchanged):** Keep API key for admin ops. Non-admin endpoints open.

**Rationale:** IoT sim = internal tool, localhost only. API key simple + effective cho single-operator use. JWT = over-engineering.

### Q2: 10 routers structure?

**Decision (unchanged):** Keep 10. Moi router = 1 domain ro rang.

**Rationale:** Merge = muddy responsibilities. Split them = fragmentation. 10 = sweet spot.

### Q3: WebSocket log stream?

**Decision (unchanged):** Keep. Essential cho operator monitoring.

**Rationale:** Polling logs = bad UX. WebSocket = instant feedback. LogHub pub/sub pattern da implement dung.

### Q4: Rate limiting?

**Decision (unchanged):** Keep. Safety net.

**Rationale:** Protect khoi FE polling flood (dashboard refresh x nhieu devices). Khong co rate limit = FE bug co the DDoS own backend.

### Q5: Auto-recovery on startup?

**Decision (unchanged):** Keep. Zero manual intervention after restart.

**Rationale:** Server crash -> restart -> sessions resume automatically. DX improvement.

### Q6: Health endpoint scope (**REVISED v2 per C1**)

**Decision:** Health endpoint IS single source of truth cho system status. `preTrigger` block **ALREADY implemented** in payload v2 (`dependencies.py:1973-2070`).

**Rationale v1 proposed Phase 4 task "add preTrigger status" (1h). Verify pass phat hien task ALREADY DONE:**
- `_compute_pre_trigger_block()` returns `{mode, threshold_source, ...}` per F-PT-03 mode matrix.
- `degradedReasons` includes `"pre_trigger_misconfigured"` flag.
- No code work needed for initial integration.

**Remaining Phase 4 work for preTrigger status:** tracked in PRE_MODEL_TRIGGER v2 module:
- F-PT-03: Fix `preTrigger.mode` accuracy (shadow detection logic works per mode matrix, but FE badge display is Phase 4 P2).
- F-PT-04: Fix `threshold_source` false-positive "db" label - should report "Hardcode defaults" (30min BE + 1h FE).

Not duplicated in API_SERVER_ROUTERS backlog.

---

## Features moi

Khong co feature moi. v1 "Q6 health endpoint enhancement" finding superseded by verify C1 (already implemented).

---

## Features DROP

Khong co.

---

## Confirmed Intent Statement (v2)

> API Server Routers cung cap REST interface cho operator dieu khien IoT Simulator. 10 routers cover full functionality (devices, sessions, vitals, scenarios, events, analytics, dashboard, registry, verification, settings). Admin ops (device CRUD + user search) protected boi API key qua `require_admin_key` dependency. WebSocket cho real-time log monitoring. Auto-recovery on startup. 
>
> Health endpoint (`/api/sim/health`) returns v2 payload voi runtime / database / backend / modelApi / preTrigger / telemetry blocks + degradedReasons array + legacy flat keys for backward compat. preTrigger block da ship - KHONG can Phase 4 code work cho initial integration.
>
> Current prefix `/api/sim/*` se refactor sang `/api/v1/sim/*` per ADR-004 (Phase 4).

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status |
|---|---|---|
| B1 | Device CRUD: create/delete simulated device, bind/unbind DB device | Confirmed |
| B2 | Admin DB device management: CRUD on production DB (protected) | Confirmed |
| B3 | Session lifecycle: create -> start -> tick -> stop | Confirmed |
| B4 | Scenario injection: apply built-in scenario to streaming device | Confirmed |
| B5 | Real-time monitoring: WebSocket log stream + dashboard summary | Confirmed |
| B6 | Telemetry delivery = 5 paths per ADR-013: vitals tick -> direct DB INSERT, alert/sleep/risk -> HTTP via direct httpx, heartbeat -> direct DB. Transport router (`transport/*`) unused at runtime, reserved for future MQTT enable. | Confirmed v2 (rewritten per ADR-013) |
| B7 | Health endpoint v2: runtime + database + backend + modelApi + preTrigger + telemetry blocks + degradedReasons + legacy flat keys. preTrigger block DA SHIP. | Confirmed v2 (expanded) |
| B8 | Rate limiting: protect from FE polling flood | Confirmed |
| B9 | Auto-recovery: startup recover active DB devices | Confirmed |
| B10 | Settings runtime: hot-reload push interval, speed, transport mode | Confirmed |

---

## Impact on Phase 4 fix plan (v2)

| Phase 4 task | Status | Priority | Effort |
|---|---|---|---|
| ADR-004 prefix migration (`/api/sim/*` -> `/api/v1/sim/*`) | Tracked in ADR-004 | P2 | Included in ADR-004 rollout (separate) |
| Health endpoint preTrigger block | **DONE** (shipped in payload v2) | — | — |
| No other API_SERVER_ROUTERS tasks identified | — | — | — |

Related Phase 4 work tracked in other modules:
- F-PT-03 + F-PT-04: preTrigger accuracy (in PRE_MODEL_TRIGGER v2).
- SLEEP_AI_CLIENT F-SA-03: `last_ai_success_at` tracking in `_HealthState` - will surface in `modelApi.lastSuccessAt` (future).

---

## Cross-references (v2 corrected)

- **SIMULATOR_CORE:** SimulatorRuntime singleton orchestrates all services + tick loop.
- **SCENARIOS:** Scenarios router delegates to `runtime.set_device_scenario()`. Apply atomic per Module B.2.
- **SLEEP_AI_CLIENT:** Sleep service called via scenarios/sessions routers. AI inference per ADR-013 + IS-001 Phase 4 fix.
- **PRE_MODEL_TRIGGER v2:** Health endpoint `preTrigger` block already integrated. F-PT-03/F-PT-04 tasks own mode + threshold source label work.
- **ETL_TRANSPORT v2:** Per ADR-013, transport layer unused at runtime. Telemetry = 5 direct paths (not transport router).
- **Topology:** `tier1/topology_v2.md` § Path 6 (IoT sim -> health_system BE admin ops) + Path 7 (sleep telemetry push). Actual endpoint paths `/mobile/telemetry/*` + `/mobile/admin/*`, NOT `/api/internal/telemetry` (inherited mistake from v1 + XR-001).
- **ADRs:**
  - ADR-004 (API prefix standardization) - target `/api/v1/sim/*`.
  - ADR-013 (IoT sim direct-DB vitals) - transport architecture.
  - ADR-015 (severity mapping) - orchestrator -> canonical severity transform.
- **Bugs:**
  - XR-001 (topology steering endpoint drift) - affects cross-references across multiple drift docs.
- **Admin FE:** `simulator-web` (Vite + React) at repo root. Separate FE from HealthGuard admin frontend (port 5173). Both use Vite + React but different repos + different domains.

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 10 routers + admin + 5 services + lifespan confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 1 CRITICAL + 2 MEDIUM + 2 LOW findings | Em |
| 2026-05-13 afternoon | Anh approved F-AR-01 through F-AR-05 doc fixes | Anh |
| 2026-05-13 afternoon | v2 rewrite - Q6 removed, B6 per ADR-013, preTrigger DONE | Em (doc) |
