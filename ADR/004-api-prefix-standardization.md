# ADR-004: Standardize API prefix `/api/v1/{domain}/*` cho tất cả backend services

**Status:** 🟢 Accepted
**Date:** 2026-05-11
**Decision-maker:** ThienPDM (solo)
**Tags:** [api, cross-repo, backend, refactor, workflow]

## Context

Phase -1.B (API Contract v1 audit) phát hiện URL prefix **không nhất quán** giữa 4 backend services:

| Service | Current prefix | Standard `/api/v1/*`? |
|---|---|---|
| HealthGuard BE (admin) | `/api/v1/admin/*` | ✓ |
| HealthGuard BE (internal) | `/api/v1/internal/*` | ✓ |
| healthguard-model-api (ML) | `/api/v1/{fall,health,sleep}/*` | ✓ (mostly — system `/`, `/health`, `/api/v1/models` outliers) |
| **health_system BE (mobile)** | `/mobile/*` direct (FastAPI `root_path="/api/v1"` chỉ là OpenAPI hint) | ✗ |
| **Iot_Simulator (sim)** | `/api/sim/*` (thiếu `v1`) | ✗ |

**Forces:**
- 3/5 services đã follow `/api/v1/*` pattern → 2 outliers tạo cognitive overhead
- health_system BE hiện rely vào reverse proxy strip `/api/v1` để mobile app hit `/api/v1/mobile/*` mà backend serve `/mobile/*` → fragile design. Nếu nginx config drift → mobile app broken
- IoT sim → backend admin client gọi `/mobile/admin/*` (no v1) trong khi mobile app gọi `/api/v1/mobile/*` → dual contract cho cùng 1 backend → confusion
- Drift D-019 (Phase -1.C topology) flag rõ inconsistency này

**Constraints:**
- Solo dev — không có deploy infra team manage proxy configs
- Production có thể có CDN/nginx — phải verify deployment checklist
- Existing clients (mobile + IoT sim) đang work với current pattern qua proxy hack

**References:**
- [Phase -1.B § Service 2](../AUDIT_2026/tier1/api_contract_v1.md) — health_system BE catalog
- [Phase -1.C § D-019](../AUDIT_2026/tier1/topology_v2.md) — drift finding
- ThienPDM raise issue trong PR review feedback Phase -1

## Decision

**Chose:** Option A — Standardize all backend services on `/api/v1/{domain}/*` prefix.

**Why:**
1. **Consistency** — All 5 service URLs follow same versioning pattern, dễ remember + grep + log filter
2. **Remove proxy dependency** — health_system BE mount directly tại `/api/v1/mobile/*` thay vì rely on nginx strip → eliminate fragile design
3. **Explicit versioning** — v2 future migration straightforward (`/api/v2/mobile/*`)
4. **Drop FastAPI `root_path` hack** — OpenAPI display sai trong dev, removed by direct prefix
5. **Resolve D-019 drift** tự nhiên
6. **Bug tracking** — URL trong stack trace + access log map 1-1 sang route file:line, không cần mental translation

## Options considered

### Option A (chosen): Standardize `/api/v1/{domain}/*` cho tất cả 5 services

**Description:** Update 2 backend services không follow pattern:
- `health_system/backend/app/main.py` — drop `root_path="/api/v1"`, change `api_router = APIRouter(prefix="/api/v1/mobile")`
- `Iot_Simulator_clean/api_server/main.py` — change include prefix từ `/api/sim` → `/api/v1/sim`
- healthguard-model-api system endpoints (`/`, `/health`, `/api/v1/models`) giữ nguyên — system probe endpoints intentionally outside versioning

Cập nhật clients đồng bộ:
- `IoT_Simulator_clean/api_server/backend_admin_client.py:45` — `/mobile/admin` → `/api/v1/mobile/admin`
- `IoT_Simulator_clean/api_server/services/sleep_service.py:581,638` — `/mobile/telemetry/sleep` → `/api/v1/mobile/telemetry/sleep`
- `health_system/lib/core/network/api_client.dart:63` — verify default `10.0.2.2:8000/api/v1/mobile` still work post-refactor (likely OK do mobile đã expect path này)

**Pros:**
- Consistent contract across all services
- Explicit versioning supports v2 migration
- Remove proxy dependency (less fragile)
- Logging + monitoring easier (regex `/api/v1/*` catches all)
- Resolves D-019 cleanly

**Cons:**
- Breaking change cho IoT sim clients (2 files touched)
- Need transitional dual-mount để no-downtime deploy
- Touch deployment/proxy configs nếu production có nginx

**Effort:** M (~4-6h):
- 1h: backend code change (2 files)
- 1h: IoT sim client updates (2 files)
- 1h: smoke test (mobile + IoT sim + ML inference flow)
- 1h: dual-mount transitional code + remove after verify
- 1-2h: documentation update (OpenAPI specs, deployment checklist)

### Option B (rejected): Keep current `/mobile/*` + `/api/sim/*` patterns

**Description:** Document current dual-pattern trong ADR, accept inconsistency, focus refactor effort elsewhere.

**Pros:**
- Zero code change
- No breaking risk
- Faster to "decide"

**Cons:**
- Drift D-019 stays open forever
- New dev (or anh sau 6 tháng) phải remember 2 patterns
- Proxy dependency fragile — silent failure mode
- Inconsistent với 3 other services
- Logging filter complex

**Why rejected:** Solo dev codebase will outlive memory — consistency now < cleanup later. Cost của Option A là M effort, benefit lifetime. ROI rõ.

### Option C (rejected): Standardize WITHOUT version (`/{domain}/*` everywhere)

**Description:** Drop `v1` from all services. Use `/admin/*`, `/mobile/*`, `/sim/*`, `/fall/*`, `/health/*`, `/sleep/*`.

**Pros:**
- Even shorter URLs
- Less prefix typing

**Cons:**
- Loses explicit versioning — v2 migration harder
- Conflict với existing HealthGuard pattern (would force HealthGuard refactor too)
- Industry standard expects `/api/v{N}/*` cho REST APIs

**Why rejected:** Versioning là long-term insurance. Solo dev đồ án có thể chưa cần v2 ngay nhưng cost của Option A so với C là minimal — keep insurance.

---

## Consequences

### Positive

- 5/5 backend services follow consistent prefix pattern
- Removes FastAPI `root_path` workaround (cleaner code)
- D-019 drift resolved
- New endpoints có pattern rõ ràng — không debate prefix per PR
- Logging/monitoring rules simpler

### Negative / Trade-offs accepted

- Phase 4 refactor effort ~4-6h dedicated
- Transitional dual-mount period adds temporary complexity (mitigated: short window, removed after smoke test)
- Documentation (OpenAPI specs, README) phải update — anh accept overhead này
- Production deployment checklist must verify proxy config (nếu có)

### Follow-up actions required

- [ ] **Phase 4 task:** Implement Option A — touch 4 code files + 2 doc files (rollout sequence trong Notes)
- [ ] **Phase 4 task:** Add dual-mount transitional period (1-2 deploys)
- [ ] **Phase 4 task:** Update [topology_v2.md](../AUDIT_2026/tier1/topology_v2.md) D-019 status → Resolved
- [ ] **Phase 4 task:** Update [api_contract_v1.md](../AUDIT_2026/tier1/api_contract_v1.md) prefix tables
- [ ] **Phase 4 task:** Update deployment checklist trong PM_REVIEW (nếu có)
- [ ] **Phase 4 task:** Add CI test verify endpoints respond at `/api/v1/*` (e.g., curl `/api/v1/mobile/auth/login` returns 401, not 404)

## Reverse decision triggers

Conditions để reconsider:

- Nếu team scale → ≥3 backend engineers cần distinct prefix per service (vd team A owns `/admin`, team B owns `/mobile`) — reconsider per-service versioning
- Nếu cần backward compat hard (vd legacy mobile app version 1.0.x deployed widely) — duy trì dual-mount lâu hơn 1-2 deploys
- Nếu chuyển sang GraphQL/gRPC cho 1 service — service đó được exempt versioning

## Related

- ADR: (none supersede/superseded yet)
- Bug: surfaced by PM-001 audit + flagged trong api_contract_v1.md D-019
- Code:
  - `health_system/backend/app/main.py:27,67` (will change)
  - `Iot_Simulator_clean/api_server/main.py:92-101` (will change)
  - `Iot_Simulator_clean/api_server/backend_admin_client.py:45` (will change)
  - `Iot_Simulator_clean/api_server/services/sleep_service.py:581,638` (will change)
- Spec: [api_contract_v1.md § D-019](../AUDIT_2026/tier1/api_contract_v1.md)

## Notes

### Rollout sequence (Phase 4 execution)

**Step 1 — Backend dual-mount** (transitional, 1 deploy):

```python
# health_system/backend/app/main.py
# OLD: app.include_router(api_router)  # api_router prefix="/mobile"
# NEW: dual-mount during transition
app.include_router(api_router, prefix="/api/v1")  # new path: /api/v1/mobile/*
app.include_router(api_router_legacy)  # keep old /mobile/* alive temporarily
# Note: api_router_legacy = copy of api_router với prefix="/mobile" (no v1)

# Iot_Simulator main.py — same dual-mount pattern
```

**Step 2 — Update IoT sim clients** (same PR as Step 1):

- `backend_admin_client.py:45` → `/api/v1/mobile/admin`
- `sleep_service.py:581,638` → `/api/v1/mobile/telemetry/sleep`

**Step 3 — Smoke test:**

- Mobile app: login, fetch vitals, mark notification read — verify `/api/v1/mobile/*` paths work
- IoT sim: bind device, push sleep, list devices via admin client — verify new paths work
- Health_system BE: model-api inference still works (no change to this path)

**Step 4 — Remove dual-mount** (next deploy after smoke test pass):

- Drop `api_router_legacy` từ backend
- Drop legacy `/api/sim` mount từ IoT sim
- Keep new `/api/v1/*` only

### Considered alternative: Use Express-style global prefix

FastAPI middleware có thể add prefix tự động. Em đã consider nhưng reject vì:
- Explicit prefix trong code dễ grep
- Match HealthGuard Express pattern (explicit mount với prefix)
- Avoid magic behavior

### Dev environment URLs after refactor

| Service | New base URL (dev) |
|---|---|
| HealthGuard BE | `http://localhost:5000/api/v1/admin/*` (no change) |
| health_system BE | `http://localhost:8000/api/v1/mobile/*` |
| healthguard-model-api | `http://localhost:8001/api/v1/{fall,health,sleep}/*` (no change) |
| IoT sim | `http://localhost:8002/api/v1/sim/*` |
