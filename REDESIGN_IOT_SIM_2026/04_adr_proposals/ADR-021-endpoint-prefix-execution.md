# ADR-021: Endpoint Prefix Execution — Execute ADR-004 Across 5 Repos

**Status:** 🟡 Proposed (Redesign 2026-05-15) — EXECUTES ADR-004
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [api, cross-repo, refactor, execution]
**Executes:** ADR-004 (API prefix standardization)
**Resolves:** XR-001, D-019, OQ1

## Context

ADR-004 (Accepted 2026-05-11) đã chốt standardize `/api/v1/{domain}/*` cho 5 backend services. NHƯNG Phase 4 follow-up tasks (rollout) **chưa execute** — drift vẫn tồn tại:
- IoT sim hits `/mobile/*` (no v1)
- health_system BE mount `root_path="/api/v1"` + router prefix `/mobile` (magic hack)
- Steering doc claim `/api/internal/*` (sai cả 2)
- IoT sim BE router prefix `/api/sim` (no v1)

**Phase 1 inventory verified state:**
- Mobile app baseUrl `http://10.0.2.2:8000/api/v1/mobile` (đã đúng ADR-004)
- IoT sim `_telemetry_*_endpoint` methods build URL `/mobile/...` (no v1)
- `MobileTelemetryClient` orphan dùng `/api/v1/mobile/...` (đúng)
- FastAPI `root_path` magic strip request path during routing

**Forces:**
- OQ1 chốt execute ADR-004
- Cross-repo redesign trigger — momentum lớn để fix dứt điểm
- Mobile app đã đúng path → chỉ cần fix server-side
- IoT sim đổi 4 file là main work

**Constraints:**
- Phase 7 deploy đồng thời tất cả repo (workspace local, không production rolling deploy)
- Test suite IoT sim + Mobile BE đều có hardcoded path — cần update

**References:**
- ADR-004 (canonical decision)
- Bug XR-001 (drift)
- Phase 1 inventory section 2.2 + section 10.5

## Decision

**Chose:** Option A — Execute ADR-004 fully trong Phase 7. Drop FastAPI `root_path` hack. Single path `/api/v1/{domain}/*` everywhere.

**Why:**
1. **Execute existing decision** — không phải decide mới, chỉ execute. ADR-004 rationale vẫn valid.
2. **OQ1 đã chốt** — Charter section 7
3. **Cross-repo momentum** — Phase 7 đụng cả 5 repo, cost marginal để fix prefix
4. **Resolve XR-001 + D-019 dứt điểm** — eliminate drift source

## Options considered

### Option A (CHOSEN): Full execution, single path

**Description:**

**health_system/backend:**
- `app/main.py`: drop `root_path="/api/v1"`, drop `docs_url="/mobile-docs"` magic
- `app/api/router.py`: change `api_router = APIRouter(prefix="/api/v1/mobile")`
- All sub-routers unchanged
- Update OpenAPI servers list

**Iot_Simulator_clean/api_server:**
- `main.py:92-101`: change prefix `/api/sim` → `/api/v1/sim` for 10 router includes
- `dependencies.py`:
  - `_telemetry_ingest_endpoint`: return `/api/v1/mobile/telemetry/ingest`
  - `_telemetry_alert_endpoint`: return `/api/v1/mobile/telemetry/alert`
  - `_risk_calculate_endpoint`: (dispose per OQ5, no migration needed)
- `backend_admin_client.py:45`: `/mobile/admin` → `/api/v1/mobile/admin`
- `services/sleep_service.py:581,638`: `/mobile/telemetry/sleep` → `/api/v1/mobile/telemetry/sleep-risk` (also rename per contract change)

**Iot_Simulator_clean/simulator-web (FE):**
- Update API client to `/api/v1/sim/*`
- Update any hardcoded path in tests

**Steering files (5 repos):**
- Update `.windsurf/rules/11-cross-repo-topology.md` (5 copies) to reflect `/api/v1/mobile/*` reality
- Remove `/api/internal/*` confusing claim

**HealthGuard admin web + healthguard-model-api:**
- Already on `/api/v1/admin/*` and `/api/v1/{fall,sleep,health}/*` — no change

**Pros:**
- Consistent contract
- Drop magic hack `root_path`
- Resolve XR-001 + D-019 dứt điểm
- Match industry REST versioning standard
- Smoke test: `curl /api/v1/mobile/health` returns 200

**Cons:**
- Touch 5+ files in IoT sim + 2 files in mobile BE
- Cross-repo coordinate

**Effort:** S (~3-4h):
- 0.5h: mobile BE main.py + router.py refactor + tests update
- 1h: IoT sim 4 file update + tests update
- 0.5h: IoT sim FE config update
- 0.5h: Steering 5 file sync
- 1h: E2E smoke test all paths

### Option B (rejected): Phase migration with dual-mount transitional

**Description:** Add dual-mount `/mobile/*` + `/api/v1/mobile/*` cùng tồn tại trong 1-2 deploy, then remove old.

**Pros:**
- Safer rollback
- No big-bang risk

**Cons:**
- Add transitional code complexity
- 2 entry point trong code maintained
- Solo dev workspace local — no production rolling deploy needed
- Drift Window mở rộng

**Why rejected:** Solo dev + workspace local — không có lý do dual-mount. Direct cutover OK.

### Option C (rejected): Reverse ADR-004, standardize on `/mobile/*` (no v1)

**Description:** Drop v1 versioning everywhere.

**Pros:**
- Mobile app phải đổi baseUrl... wait, it's already `/api/v1/mobile`

**Cons:**
- Mobile app phải đổi → MORE breaking changes
- Lose versioning insurance
- Mâu thuẫn với HealthGuard pattern (already v1)

**Why rejected:** Already explored in ADR-004 § Option C. ADR-004 chốt giữ v1 — reverse without strong reason.

## Consequences

### Positive
- 5/5 services consistent
- Drop FastAPI `root_path` magic
- XR-001 + D-019 resolved
- Mobile app NO change required (path already correct)
- Steering docs sync to reality

### Negative / Trade-offs accepted
- Cross-repo coordinate Phase 7
- Test suite update (mock paths)
- ~3-4h effort dedicated

### Follow-up actions required
- [ ] Update bug XR-001 status to ✅ Resolved
- [ ] Update D-019 in topology_v2.md
- [ ] Phase 7 slice 1: mobile BE refactor (main.py + router.py)
- [ ] Phase 7 slice 2: IoT sim 4 file update
- [ ] Phase 7 slice 3: Steering 5 file sync (chore branch)
- [ ] Phase 7 slice 4: Smoke E2E test

## Reverse decision triggers

- Nếu production deployment với nginx proxy strip `/api/v1` → revisit, có thể keep magic hack
- Nếu cross-repo coordination block — phase one repo at a time với dual-mount transitional

## Related

- **Executes:** ADR-004 (canonical)
- **Companion:** ADR-018 (validation), ADR-019 (no direct model-api), ADR-020 (vitals HTTP)
- Bug XR-001: Topology steering endpoint prefix drift
- Phase 1 inventory section 10.5 (endpoint mismatch matrix)
- Code:
  - `health_system/backend/app/main.py:28` (drop root_path)
  - `health_system/backend/app/api/router.py:17` (update prefix)
  - `Iot_Simulator_clean/api_server/main.py:92-101` (10 prefixes)
  - `Iot_Simulator_clean/api_server/dependencies.py:911-923` (3 endpoint methods)
  - `Iot_Simulator_clean/api_server/backend_admin_client.py:45`
  - `Iot_Simulator_clean/api_server/services/sleep_service.py:581,638`

## Notes

### Smoke test post-cutover

```pwsh
# Mobile BE
curl http://localhost:8000/api/v1/mobile/health
# Expected: 200

curl http://localhost:8000/mobile/health
# Expected: 404 (old path gone)

# IoT sim BE
curl http://localhost:8002/api/v1/sim/health
# Expected: 200

curl http://localhost:8002/api/sim/health
# Expected: 404 (old path gone)

# IoT sim → mobile BE end-to-end
curl -X POST http://localhost:8000/api/v1/mobile/telemetry/ingest \
  -H "X-Internal-Service: iot-simulator" \
  -d '{"messages":[...]}'
# Expected: 200 + ingested count
```

### Risk: docs generation

FastAPI auto-generates OpenAPI from routes. With `root_path` dropped:
- `/mobile-docs` → become `/docs` (or update `docs_url` arg)
- Swagger UI display path under `/api/v1/mobile/*` correctly
- Mobile app SDK codegen (if any) update OpenAPI fetch URL

Phase 7 slice 1 verify docs work post-cutover.

### Backward compatibility

- Mobile app: NO change (path already correct)
- IoT sim: BREAKING — must deploy together with BE
- Admin web: NO change
- Model-api: NO change
- E2E tests cross-repo: UPDATE hardcoded paths
