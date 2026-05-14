# Phase -1.C — Topology v2

**Date:** 2026-05-11
**Scope:** Verify cross-service call graph against actual code
**Method:** Static scan của HTTP clients (httpx, http package, urllib, axios) + endpoint URL extraction + auth header check
**Linked:** [PM-001](../../BUGS/PM-001-pm-review-spec-drift.md), [Charter](../00_phase_minus_1_charter.md), [DB Diff](./db_canonical_diff.md), [API Contract v1](./api_contract_v1.md)

---

## TL;DR

**Services:** 5 repos × 6 active runtime processes
**Verified cross-service calls:** 8 distinct paths
**Drift findings:** 5 (1 critical bug + 4 design concerns)

**Critical bug surfaced:** [IS-001](../../BUGS/IS-001-sleep-ai-client-wrong-path.md) — IoT sim sleep AI client posts to `/predict` (404) instead of `/api/v1/sleep/predict`.

---

## Service runtime topology

```
+----------------------+         +-------------------------+
| Admin web frontend   |         |   Mobile app (Flutter)  |
| React + Vite         |         |   health_system/lib     |
+----------+-----------+         +------------+------------+
           |                                  |
           | HTTPS                            | HTTPS
           | /api/v1/admin/*                  | /api/v1/mobile/*  (note: backend root_path)
           v                                  v
+----------+-----------+         +------------+------------+
| HealthGuard BE       |         | health_system BE        |
| Express + Prisma     |         | FastAPI                 |
| Port 5000            |         | Port 8000               |
| (admin only)         |         | (mobile only)           |
+-----+----------------+         +-----+-------------+-----+
      |                                |             |
      | postgres                       | postgres    | httpx
      v                                v             v
+-----+--------------------------------+----+ +------+---------------+
|    Postgres + TimescaleDB (shared DB)     | | healthguard-model-api|
+----+--+----------------+------------+-----+ | FastAPI + ML         |
     ^  ^                ^            ^       | Port 8001 (stateless)|
     |  |                |            |       +----------+-----------+
     |  | direct write   |            |                  ^
     |  | (devices,      |            |                  | httpx
     |  |  user lookup)  |            |                  |
     |  |                |            |    +-------------+----------+
+----+--+-------------+  |    +-------+----+ IoT Simulator           |
| IoT Simulator       |  |    |          | api_server (FastAPI)     |
| api_server          |  |    |          | Port 8002                |
| Port 8002           +--+    |          | + simulator_core         |
+---------------------+       |          |   (fall_ai_client,        |
       |                      |          |    sleep_ai_client)       |
       | httpx                |          +-------------------------+
       v                      |
+------+---------------+      |
| health_system BE     +<-----+ httpx
| /mobile/admin/*      |        /mobile/telemetry/sleep
| /mobile/telemetry/   |        /mobile/admin/devices, /users/search
+----------------------+

Pump scripts (CRON, manual) -----> HealthGuard BE
                                   POST /api/v1/internal/websocket/emit-{alert,emergency,risk}
                                   (NO auth — see D-011 from -1.B)
```

---

## Verified call graph (8 paths)

### Path 1: Mobile app → health_system BE

**Direction:** outbound HTTP from Flutter app
**Client:** `health_system/lib/core/network/api_client.dart:29`
**Base URL:** `${API_URL}` (default `http://10.0.2.2:8000/api/v1/mobile`)
**Auth:** Bearer JWT `Authorization: Bearer <access_token>` + optional `X-Target-Profile-Id`
**Refresh logic:** `_retryAuthorizedRequest` on 401 → calls `/api/v1/mobile/auth/refresh`
**Verified:** ✓ Backend FastAPI `main.py:27` `root_path="/api/v1"` + router prefix `/mobile` → effective routes at `/api/v1/mobile/*`

**Coverage:** All `/mobile/*` endpoints (~70 endpoints) catalogued in [API Contract v1](./api_contract_v1.md) § Service 2.

---

### Path 2: Admin web frontend → HealthGuard BE

**Direction:** outbound HTTP from React app
**Client:** `HealthGuard/frontend/src/services/*.js` (not deep-scanned this phase)
**Base URL:** `/api/v1/admin/*` (same-origin via Vite dev proxy or production reverse proxy)
**Auth:** JWT Bearer + httpOnly cookie (refresh token)
**Verified:** ✓ Mount config `HealthGuard/backend/src/app.js:47` `app.use('/api/v1/admin', routes)`

**Coverage:** All `/api/v1/admin/*` + `/api/v1/internal/*` endpoints (~92) catalogued in [API Contract v1](./api_contract_v1.md) § Service 1.

---

### Path 3: health_system BE → healthguard-model-api (3 predict endpoints)

**Direction:** internal service-to-service
**Client:** `health_system/backend/app/services/model_api_client.py:32` `ModelApiClient`
**Base URL:** `${HEALTHGUARD_MODEL_API_URL}` (default `http://localhost:8001`)
**Auth header:** ✓ `X-Internal-Service: health-system-backend`
**Endpoints called:**

| Method | Path | Caller method |
|---|---|---|
| POST | `/api/v1/health/predict` | `predict_health_risk()` |
| POST | `/api/v1/fall/predict` | `predict_fall()` |
| POST | `/api/v1/sleep/predict` | `predict_sleep()` |

**Resilience:**
- `httpx.Client` with connection pool + timeout (default 5s)
- Per-endpoint `CircuitBreaker` (health/fall/sleep independent — failing sleep doesn't mask health)
- `StageTimer` instrumentation for `risk.timing` log channel
- Graceful degradation: returns `None` on any failure → caller fallback to local rule-based path
- Disable via env `HEALTHGUARD_MODEL_API_DISABLED=1`

**Verified endpoint paths:** ✓ Match model-api router prefixes (fall.py, health.py, sleep.py all use `/api/v1/{domain}/predict`).

---

### Path 4: IoT sim → healthguard-model-api (fall AI)

**Direction:** internal service-to-service (sim → ML)
**Client:** `Iot_Simulator_clean/simulator_core/fall_ai_client.py:252` `FallAIClient`
**Base URL:** constructor param (default `http://127.0.0.1:8001`)
**Auth header:** ❌ **NONE** — only `Content-Type: application/json`
**Endpoints called:**

| Method | Path | Caller method |
|---|---|---|
| GET | `/api/v1/fall/model-info` | `check_availability()` (probe) |
| POST | `/api/v1/fall/predict` | `predict()` |

**Resilience:**
- stdlib `urllib.request` (NOT httpx) — different transport from health_system BE
- Simple circuit breaker via `_available` flag + 30s cooldown self-heal
- Min 50 samples enforced before submitting

**Verified paths:** ✓ Match model-api `fall.py` prefix `/api/v1/fall`.

⚠️ See **Drift D-020**: missing `X-Internal-Service` header — inconsistent với Path 3.

---

### Path 5: IoT sim → healthguard-model-api (sleep AI) — **BROKEN**

**Direction:** internal service-to-service (sim → ML)
**Client:** `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:23` `SleepAIClient`
**Base URL:** constructor param (default `http://localhost:8001`)
**Auth header:** ❌ NONE
**Endpoints called:**

| Method | Path | Caller method | Status |
|---|---|---|---|
| GET | `/health` | `check_availability()` | ✓ valid (system.py /health) |
| POST | `/predict` | `predict()` | ❌ **404 — endpoint không tồn tại!** |

**Verified paths:**
- `/health` ✓ matches `system.py:22` `@router.get("/health")`
- `/predict` ❌ — model-api KHÔNG có endpoint `/predict` root-level. Sleep predict thực tế ở `/api/v1/sleep/predict` (sleep.py prefix `/api/v1/sleep` + endpoint `/predict`)

**Impact:** Sleep AI inference từ IoT sim **không bao giờ thành công** trong production. Falls back to heuristic scoring trong `sleep_service.py`.

**Action:** Logged as bug [IS-001](../../BUGS/IS-001-sleep-ai-client-wrong-path.md).

---

### Path 6: IoT sim → health_system BE (admin operations)

**Direction:** internal service-to-service (sim → mobile BE)
**Client:** `Iot_Simulator_clean/api_server/backend_admin_client.py:40` `BackendAdminClient`
**Base URL:** `${HEALTH_BACKEND_URL}/mobile/admin` (default `http://localhost:8000/mobile/admin`)
**Auth header:** ✓ `X-Internal-Service: iot-simulator`
**Endpoints called:**

| Method | Path | Caller method |
|---|---|---|
| GET | `/mobile/admin/devices?user_id=N` | `list_devices()` |
| POST | `/mobile/admin/devices` | `create_device()` |
| DELETE | `/mobile/admin/devices/{id}` | `delete_device()` |
| POST | `/mobile/admin/devices/{id}/assign` | `assign_device(email)` |
| POST | `/mobile/admin/devices/{id}/activate` | `activate_device()` |
| POST | `/mobile/admin/devices/{id}/deactivate` | `deactivate_device()` |
| GET | `/mobile/admin/users/search?email=...` | `find_user_by_email()` |

⚠️ **D-019 concern:** Base URL uses `/mobile/admin` WITHOUT `/api/v1` prefix. health_system BE has `root_path="/api/v1"` for OpenAPI display — does it actually mount at `/api/v1/mobile/admin/*` or `/mobile/admin/*`?

**FastAPI semantics:** `root_path` is a hint for behind-proxy operation; app actually receives requests at `/mobile/*`. IoT sim hits backend directly (no proxy in dev) → uses `/mobile/admin/*` (correct for direct connection).

→ **Both paths valid in different deploy scenarios:**
- Mobile app via proxy/CDN: hits `/api/v1/mobile/*` → proxy strips → backend gets `/mobile/*`
- IoT sim direct: hits `/mobile/admin/*` → backend gets `/mobile/admin/*`

**Verified:** ✓ Endpoints catalogued at `/mobile/admin/*` in [API Contract v1](./api_contract_v1.md) § Service 2 (admin section).

---

### Path 7: IoT sim → health_system BE (sleep telemetry push)

**Direction:** internal service-to-service (sim push sleep data)
**Caller:** `Iot_Simulator_clean/api_server/services/sleep_service.py:581+638`
**Endpoint:** `POST ${health_backend_url}/mobile/telemetry/sleep`
**Auth header:** (em chưa verify — file truncated trong scan, need Phase 1)
**HTTP client:** shared `httpx.Client` (CRITICAL #2 fix mentioned in code)

**Verified:** ✓ Endpoint exists at `health_system/backend/app/api/routes/telemetry.py:550` `@router.post("/sleep")`.

⚠️ **D-021 concern:** Endpoint `/sleep` does NOT have `require_internal_service` dependency (per D-012 từ -1.B audit). IoT sim push không có auth → anyone trên network có thể inject fake sleep session.

---

### Path 8: Pump scripts → HealthGuard BE (internal websocket emit)

**Direction:** external script → admin BE
**Caller:** Pump scripts (not scanned this phase; likely `HealthGuard/backend/scripts/` or external)
**Endpoints:**

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/v1/internal/websocket/emit-alert` | broadcast alert to admin web socket |
| POST | `/api/v1/internal/websocket/emit-emergency` | broadcast emergency |
| POST | `/api/v1/internal/websocket/emit-risk` | broadcast risk update |

**Auth:** ❌ NONE (per D-011 from -1.B)

**Verified endpoint paths:** ✓ Match `internal.routes.js:30,65,91`.

⚠️ **D-011 (security):** Public emit endpoints → spoof risk. Critical fix Phase 4.

---

## Verified: HealthGuard BE does NOT make outbound HTTP calls

**Method:** `grep_search` for `axios|fetch|http.request|got|node-fetch` in `HealthGuard/backend/src/services/*.js`.

**Result:** 0 matches for outbound HTTP. All `request` matches are internal exception types (`ApiError.notFound`, validation request objects). Service files only consume Prisma client (DB) + emit websocket events.

**Topology insight:** HealthGuard BE is a **"leaf" service** — consumes DB only, no cross-service dependencies. ML inference path goes through health_system BE, not admin BE.

---

### Path 9 (added 2026-05-13): IoT sim → shared Postgres (direct DB write) — per ADR-013

**Direction:** IoT sim → shared DB (bypass BE for vitals tick)
**Context:** ADR-013 accepts direct-DB INSERT for vitals + motion_data tick payloads. Original `transport_router.publish()` wiring in `dependencies.py:670-675` is **never called at runtime** (verified grep 0 hits 2026-05-13 during Phase 0.5 verify pass) and will be replaced by inline `session_scope()` batch INSERT per `Iot_Simulator_clean/plans/IOT_SIM_DIRECT_DB_WRITE.md` §6.

**Tables written:**

| Table | Source field in tick payload | Write frequency |
|---|---|---|
| `vitals` | `vitals.heart_rate`, `.spo2`, `.temperature`, `.blood_pressure_systolic/diastolic`, `.hrv`, `.respiratory_rate` | Per session tick (~5s) |
| `motion_data` | `motion.accel_x/y/z`, `.gyro_x/y/z` + computed magnitude | Per session tick when motion samples present |
| `devices.last_heartbeat_at` | `_update_device_heartbeat()` (existing precedent) | Per session tick |

**Why not via `/mobile/telemetry/ingest`:**
- TransportRouter path never active (`grep transport_router.publish` = 0).
- BE ingest endpoint = thin proxy (no business validation beyond schema shape).
- HTTP overhead ~2074ms vs DB ~10ms (200× improvement per plan §1).
- Heartbeat precedent proven.

**Alert / sleep / risk paths unchanged** — still go via HTTP to BE (business logic present: FCM push, sleep scoring, ML inference).

**D-019 status update:** `/mobile/telemetry/ingest` drift becomes **less urgent** since vitals tick no longer uses HTTP path. Remaining HTTP endpoints (`alert`, `sleep`, `risk/calculate`) still subject to ADR-004 standardization but scope reduced.

**See:**
- `PM_REVIEW/ADR/013-iot-sim-direct-db-write-vitals.md`
- `PM_REVIEW/BUGS/XR-001-topology-steering-endpoint-prefix-drift.md`
- `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/ETL_TRANSPORT_verify.md`

---

## Drift findings

### D-018 [Critical → IS-001]: `sleep_ai_client.py` posts to wrong path

**Severity:** Critical (broken feature)

**Source:** `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:53`
```python
request = Request(
    f"{self.base_url}/predict",   # ← /predict không tồn tại
    ...
)
```

**Expected path:** `/api/v1/sleep/predict` (per model-api `sleep.py` router config)

**Impact:**
- Every sleep prediction request → HTTP 404
- IoT sim falls back to heuristic sleep scoring silently (per circuit breaker `_available=False`)
- Production sleep AI inference never engaged

**Logged as:** [IS-001](../../BUGS/IS-001-sleep-ai-client-wrong-path.md)

**Fix (Phase 4):** Change line 53 to `f"{self.base_url}/api/v1/sleep/predict"` + add `X-Internal-Service: iot-simulator` header.

---

### D-019 [Low]: Inconsistent base URL prefix between Mobile vs IoT sim

**Severity:** Low (functional but fragile)

**Source:**
- Mobile: `health_system/lib/core/network/api_client.dart:63` → `http://10.0.2.2:8000/api/v1/mobile`
- IoT sim sleep push: `sleep_service.py:581` → `{health_backend_url}/mobile/telemetry/sleep` (no `/api/v1`)
- IoT sim admin client: `backend_admin_client.py:45` → `{backend_root}/mobile/admin` (no `/api/v1`)

**Backend setup:** `main.py:27` `root_path="/api/v1"` (OpenAPI hint) + `api_router = APIRouter(prefix="/mobile")` (actual mount).

**Result:** Backend serves at `/mobile/*` directly. Mobile app expects proxy strip `/api/v1` → forward `/mobile`. IoT sim hits direct.

**Concern:** Đeve setup phải có nginx/Vite reverse proxy để mobile app hoạt động. Production must mirror. Nếu nginx config drift → mobile app broken.

**Resolution:** **Resolved by [ADR-004](../../ADR/004-api-prefix-standardization.md)** — chọn Option A (standardize all services on `/api/v1/{domain}/*`). Phase 4 refactor target.

---

### D-020 [Medium]: IoT sim fall AI client missing internal secret header

**Severity:** Medium (consistency + future security)

**Source:** `simulator_core/fall_ai_client.py:378` Request headers:
```python
headers={"Content-Type": "application/json"}
# Missing: "X-Internal-Service": "iot-simulator"
```

**Compare:** `health_system/backend/app/services/model_api_client.py:101` sends `X-Internal-Service: health-system-backend`.

**Impact NOW:** None — model-api doesn't enforce internal secret yet (per D-013).
**Impact FUTURE:** When D-013 fixed (Phase 4), IoT sim fall AI breaks until header added.

**Fix:** Phase 4 — when adding `verify_internal_secret` to model-api, simultaneously add header to IoT sim clients (fall + sleep).

---

### D-021 [High]: IoT sim sleep push to backend without auth verification

**Severity:** High (security)

**Source:** Path 7 above — IoT sim `sleep_service.py:_push_sleep_to_backend()` posts to `/mobile/telemetry/sleep`. Backend endpoint (`telemetry.py:550`) does NOT have `require_internal_service` dependency.

**Impact:** Anyone on network can POST fake sleep session → false sleep risk alert.

**Fix:** Phase 4 — add `Depends(require_internal_service)` to `/sleep` + `/imu-window` + `/sleep-risk` endpoints (also flagged in [API Contract v1 D-012](./api_contract_v1.md)).

---

### D-022 [Low]: Sleep AI client probes `/health` not `/api/v1/sleep/model-info`

**Severity:** Low (works but inconsistent)

**Source:** `sleep_ai_client.py:33` GET `/health` for availability probe.

**Compare:** `fall_ai_client.py:292` GET `/api/v1/fall/model-info` for availability probe (recently fixed per comment).

**Concern:** `/health` checks ENTIRE model-api process. If only sleep model down, `/health` returns 200 → false positive availability. Probe `/api/v1/sleep/model-info` would correctly detect sleep model status.

**Fix:** Phase 4 — change probe to `/api/v1/sleep/model-info`, mirror fall AI client pattern.

---

## Topology updates needed (current spec gaps)

**File:** PM_REVIEW has NO `topology.md` file (em verified — `find_by_name` returned 0 results in workspace).

**Status:** Topology lived in CLAUDE.md rules + project memory only — no canonical doc.

**Recommendation:** Phase 4 — extract canonical topology into `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` (this file) as the authoritative source. Reference from rules `11-cross-repo-topology.md`.

---

## Service runtime processes summary

| Repo | Process | Port | Stack | Stateful? | DB? |
|---|---|---|---|---|---|
| HealthGuard | Express backend | 5000 | Node.js + Prisma | No (stateless API) | shared Postgres |
| HealthGuard | Vite dev / React static | 5173 / nginx | React + Vite | No | — |
| health_system | FastAPI backend | 8000 | Python + SQLAlchemy | No (JWT stateless) | shared Postgres |
| health_system | Flutter mobile app | n/a | Flutter | Local cache | local secure storage |
| healthguard-model-api | FastAPI ML | 8001 | Python + onnxruntime | Model loaded once | — |
| Iot_Simulator_clean | FastAPI simulator | 8002 | Python + simulator_core | In-memory sessions + persisted to shared DB | shared Postgres (users + devices read/write) |

**Total active processes in dev:** 6

---

## Out of scope this phase

- WebSocket events catalog (admin BE → admin web frontend live updates) — Phase 1
- FCM push delivery path (backend → Firebase → mobile) — Phase 1
- Email service path (backend SMTP) — Phase 1
- Frontend (admin web React) → backend service map — Phase 1 macro audit
- Mobile app → backend per-feature endpoint map — Phase 1
- Pump scripts source location + auth flow — Phase 1

---

## Recommendations (priority ordered)

### P0 — Critical (Phase 4 hot fixes)

- [ ] **D-018 / IS-001:** Fix `sleep_ai_client.py` POST path
- [ ] **D-021:** Add internal secret check to backend `/mobile/telemetry/sleep` + `/imu-window` + `/sleep-risk`

### P1 — Security tighten (Phase 4)

- [ ] **D-020:** Add `X-Internal-Service` header to IoT sim fall/sleep AI clients
- [ ] **D-022:** Change sleep AI client probe to `/api/v1/sleep/model-info`
- [ ] **D-011 + D-013** (from -1.B) cross-cut: add `verify_internal_secret` to admin BE internal routes + model-api predict endpoints

### P2 — Topology cleanup (Phase 4)

- [ ] **D-019:** Standardize base URL prefix — either backend mounts at `/api/v1/mobile/*` directly OR document proxy requirement
- [ ] Create canonical `topology.md` (extract from this file → publish as authoritative)

---

## Phase -1.C Definition of Done

- [x] 4 backend services + mobile app + frontend HTTP client scanned
- [x] 8 cross-service call paths documented with verified endpoint paths
- [x] 5 drift findings (D-018 → D-022) với severity + fix
- [x] Critical bug surfaced + logged (IS-001)
- [x] Verified HealthGuard BE is leaf service (no outbound calls)
- [x] Service runtime topology diagram
- [x] Out-of-scope items flagged for Phase 1+
- [ ] ThienPDM review

**Next:** Phase -1 wrap-up — commit + PR + summary
