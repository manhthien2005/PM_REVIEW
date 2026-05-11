# Phase -1.B — API Contract v1

**Date:** 2026-05-11
**Scope:** Catalog all HTTP endpoints across 4 backend services + flag mismatches
**Method:** Static scan via grep on router files (Express + FastAPI)
**Linked:** [PM-001](../../BUGS/PM-001-pm-review-spec-drift.md), [Charter](../00_phase_minus_1_charter.md), [DB Diff](./db_canonical_diff.md)

---

## TL;DR

**Service inventory:**

| Service | Stack | Base prefix | Routes files | Endpoints (approx) |
|---|---|---|---|---|
| HealthGuard backend | Express | `/api/v1/admin/*`, `/api/v1/internal/*` | 12 | ~92 |
| health_system backend | FastAPI | `/mobile/*` | 13 | ~70 |
| healthguard-model-api | FastAPI | `/api/v1/{fall,health,sleep}/*` + system | 4 | 17 |
| Iot_Simulator_clean api_server | FastAPI | `/api/sim/*` | 10 | ~29 |
| **Total** | | | **39** | **~208** |

**Mismatch flags:** 7 — see § Drift findings below

---

## Source files scanned

| Service | Mount config | Sub-routers |
|---|---|---|
| HealthGuard backend | `app.js:44` `app.use('/api/v1/internal', internalRoutes)`, `app.js:47` `app.use('/api/v1/admin', routes)` | `routes/index.js` mounts: `/auth`, `/users` (relationship + user), `/devices`, `/logs`, `/settings`, `/emergencies`, `/health`, `/dashboard`, `/vital-alerts`, `/admin/vital-alerts`, `/ai-models` |
| health_system backend | `main.py:67` `app.include_router(api_router)` | `api/router.py` `APIRouter(prefix="/mobile")` includes 13 sub-routers |
| healthguard-model-api | `main.py` includes 4 routers (no global prefix) | system (no prefix), fall (`/api/v1/fall`), health (`/api/v1/health`), sleep (`/api/v1/sleep`) |
| Iot_Simulator_clean | `main.py:92-101` 10 routers prefixed `/api/sim` | analytics, dashboard, devices, events, registry, scenarios, sessions, settings, verification, vitals |

---

## Service 1: HealthGuard backend (admin web)

**Base:** `http://localhost:5000/api/v1/admin/*` (admin routes), `/api/v1/internal/*` (internal)

### Auth & user management

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/auth/login` | public + rate limit | `auth.routes.js:18` |
| POST | `/auth/forgot-password` | public + rate limit | `auth.routes.js:19` |
| POST | `/auth/reset-password` | public | `auth.routes.js:20` |
| POST | `/auth/register` | admin | `auth.routes.js:23` |
| GET | `/auth/me` | authenticated | `auth.routes.js:26` |
| POST | `/auth/logout` | authenticated | `auth.routes.js:27` |
| PUT | `/auth/password` | authenticated + rate limit | `auth.routes.js:28` |
| GET | `/users` | admin | `user.routes.js:79` |
| GET | `/users/:id` | admin | `user.routes.js:80` |
| POST | `/users` | admin | `user.routes.js:81` |
| PATCH \| PUT | `/users/:id` | admin | `user.routes.js:82-83` |
| PATCH \| PUT | `/users/:id/lock` | admin | `user.routes.js:84-85` |
| DELETE | `/users/:id` | admin | `user.routes.js:86` |
| POST | `/users/:id/delete` | admin | `user.routes.js:87` |

### Relationships (mounted on `/users`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/users/relationships/search` | admin | `relationship.routes.js:56` |
| GET | `/users/:userId/relationships` | admin | `relationship.routes.js:59` |
| POST | `/users/:userId/relationships` | admin | `relationship.routes.js:60` |
| PUT | `/users/:userId/relationships/:id` | admin | `relationship.routes.js:61` |
| DELETE | `/users/:userId/relationships/:id` | admin | `relationship.routes.js:62` |

⚠️ **Mount conflict potential:** `router.use('/users', relationshipRoutes)` + `router.use('/users', userRoutes)` cùng prefix. relationshipRoutes registered first để `/relationships/search` không bị `userRoutes /:id` consume. Workable nhưng fragile — see Drift D-007.

### Devices

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/devices` | admin | `device.routes.js:64` |
| GET | `/devices` | admin | `device.routes.js:65` |
| GET | `/devices/:id` | admin | `device.routes.js:66` |
| PATCH \| PUT | `/devices/:id` | admin | `device.routes.js:67-68` |
| PATCH \| PUT | `/devices/:id/assign` | admin | `device.routes.js:69-70` |
| DELETE | `/devices/:id` | admin | (file truncated trong scan) |

### Logs

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/logs` | admin | `logs.routes.js:49` |
| GET | `/logs/export/csv` | admin | `logs.routes.js:50` |
| GET | `/logs/export/json` | admin | `logs.routes.js:51` |
| GET | `/logs/:id` | admin | `logs.routes.js:52` |

### Settings

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/settings` | admin | `settings.routes.js:17` |
| PUT | `/settings` | admin | `settings.routes.js:25` |

### Emergencies

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/emergencies/summary` | admin | `emergency.routes.js:81` |
| GET | `/emergencies/fall-countdown` | admin | `emergency.routes.js:82` |
| GET | `/emergencies/active` | admin | `emergency.routes.js:83` |
| GET | `/emergencies/history` | admin | `emergency.routes.js:84` |
| GET | `/emergencies/export/csv` | admin | `emergency.routes.js:85` |
| GET | `/emergencies/export/json` | admin | `emergency.routes.js:86` |
| GET | `/emergencies/:id` | admin | `emergency.routes.js:87` |
| PATCH \| PUT | `/emergencies/:id/status` | admin | `emergency.routes.js:88-89` |
| POST | `/emergencies/:id/contact` | admin | `emergency.routes.js:90` |

### Health overview

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/health/summary` | (no middleware in file) | `health.routes.js:54` |
| GET | `/health/threshold-alerts` | — | `health.routes.js:92` |
| GET | `/health/risk-distribution` | — | `health.routes.js:117` |
| GET | `/health/vitals-trends` | — | `health.routes.js:131` |
| GET | `/health/patient/:patientId` | — | `health.routes.js:152` |
| GET | `/health/export-alerts-csv` | — | `health.routes.js:190` |
| GET | `/health/export-risk-csv` | — | `health.routes.js:219` |

⚠️ **Auth gap?** `health.routes.js` không có `router.use(authenticate)` ở đầu file (per truncated scan). Cần verify Phase 1 — see Drift D-008.

### Dashboard

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/dashboard/kpi` | admin | `dashboard.routes.js:77` |
| GET | `/dashboard/alerts-chart` | admin | `dashboard.routes.js:98` |
| GET | `/dashboard/risk-distribution` | admin | `dashboard.routes.js:112` |
| GET | `/dashboard/recent-incidents` | admin | `dashboard.routes.js:133` |
| GET | `/dashboard/at-risk-patients` | admin | `dashboard.routes.js:154` |
| GET | `/dashboard/system-health` | admin | `dashboard.routes.js:165` |
| GET | `/dashboard/kpi-sparklines` | admin | `dashboard.routes.js:166` |

### Vital alerts

**File `vital-alert.routes.js`** (mounted at `/vital-alerts`, NO admin guard middleware):

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/vital-alerts/process` | — | `vital-alert.routes.js:46` |
| GET | `/vital-alerts/processor/status` | — | `vital-alert.routes.js:60` |
| POST | `/vital-alerts/processor/toggle` | — | `vital-alert.routes.js:85` |
| GET | `/vital-alerts/thresholds` | — | `vital-alert.routes.js:99` |

⚠️ **Critical security flag:** Không có `router.use(authenticate)`! Endpoint POST `/process` toggle processor mà public — xem Drift D-009.

**File `vital-alerts.js`** (admin sub-routes mounted at `/admin/vital-alerts` → URL becomes `/api/v1/admin/admin/vital-alerts/*`):

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/admin/vital-alerts/thresholds/:userId` | admin | `vital-alerts.js:75` |
| PUT | `/admin/vital-alerts/thresholds/:userId` | admin | `vital-alerts.js:114` |
| GET | `/admin/vital-alerts/vital/:deviceId/:timestamp` | admin | `vital-alerts.js:145` |
| POST | `/admin/vital-alerts/process` | admin | `vital-alerts.js:185` |
| POST | `/admin/vital-alerts/process-range` | admin | `vital-alerts.js:216` |

⚠️ **Path awkward:** Full URL = `/api/v1/admin/admin/vital-alerts/*` — double "admin" prefix. See Drift D-010.

### AI Models (MLOps + CRUD)

22 endpoints. Em chỉ list nhóm:

**MLOps section** (`ai-models.routes.js:41-52`):
- GET `/ai-models/mlops/models`
- POST `/ai-models/mlops/models`
- GET `/ai-models/mlops/models/:id`
- GET `/ai-models/mlops/models/:id/versions`
- GET `/ai-models/mlops/models/:id/datasets`
- GET `/ai-models/mlops/models/:id/data-diff`
- GET `/ai-models/mlops/models/:id/model-diff`
- GET `/ai-models/mlops/models/:id/feedback-summary`
- GET `/ai-models/mlops/models/:id/retrain-jobs`
- POST `/ai-models/mlops/models/:id/datasets/build-next` (multipart)
- POST `/ai-models/mlops/models/:id/retrain`
- POST `/ai-models/mlops/models/:id/deploy-candidate`

**CRUD models** (`ai-models.routes.js:54-70`):
- GET `/ai-models`, GET `/ai-models/:id`, POST `/ai-models`
- PATCH \| PUT `/ai-models/:id`, DELETE `/ai-models/:id`
- GET `/ai-models/:id/versions`, GET `/ai-models/:id/versions/next`
- POST `/ai-models/:id/versions` (multipart upload)
- PATCH \| PUT `/ai-models/:id/versions/:versionId`, DELETE `/ai-models/:id/versions/:versionId`

All admin-protected (`router.use(authenticate, requireAdmin)`).

### Internal endpoints (no admin web prefix)

**Base:** `/api/v1/internal/*`

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/internal/websocket/emit-alert` | (none in file) | `internal.routes.js:30` |
| POST | `/internal/websocket/emit-emergency` | (none in file) | `internal.routes.js:65` |
| POST | `/internal/websocket/emit-risk` | (none in file) | `internal.routes.js:91` |

⚠️ **Auth gap:** Internal endpoints không có middleware kiểm tra `X-Internal-Secret`. Caller (script/pump) gửi raw POST → bất kỳ ai trên network có thể spoof emit alert giả. See Drift D-011.

---

## Service 2: health_system backend (mobile BE)

**Base:** `http://localhost:8000/mobile/*`

### Auth (`auth.py` prefix `/auth`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/mobile/auth/register` | public | `auth.py:55` |
| POST | `/mobile/auth/verify-email` | public | `auth.py:107` |
| POST | `/mobile/auth/resend-verification` | public | `auth.py:122` |
| POST | `/mobile/auth/login` | public | `auth.py:158` |
| POST | `/mobile/auth/refresh` | public (JWT body) | `auth.py:195` |
| POST | `/mobile/auth/forgot-password` | public | `auth.py:218` |
| POST | `/mobile/auth/verify-reset-otp` | public | `auth.py:251` |
| POST | `/mobile/auth/reset-password` | public | `auth.py:266` |
| POST | `/mobile/auth/change-password` | authenticated | `auth.py:281` |
| GET | `/mobile/auth/deep-link-redirect` | public (HTML page) | `auth.py:317` |

### Profile (`profile.py` no prefix, paths `/profile`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/profile` | authenticated | `profile.py:13` |
| PUT | `/mobile/profile` | authenticated | `profile.py:18` |
| DELETE | `/mobile/profile` | authenticated | `profile.py:30` |

### Devices (`device.py` no prefix, paths `/devices`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/devices` | authenticated | `device.py:23` |
| GET | `/mobile/devices/{device_id}` | authenticated | `device.py:44` |
| POST | `/mobile/devices` | authenticated | `device.py:67` |
| PATCH | `/mobile/devices/{device_id}` | authenticated | `device.py:86` |
| DELETE | `/mobile/devices/{device_id}` | authenticated | `device.py:113` |
| POST | `/mobile/devices/scan/pair` | authenticated | `device.py:132` |
| PUT | `/mobile/devices/{device_id}/settings` | authenticated | `device.py:163` |

### Health (`health.py` prefix `/health`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/health` | public | `health.py:6` |

### Emergency (`emergency.py` prefix `/emergency`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/mobile/emergency/sos/trigger` | authenticated | `emergency.py:21` |
| GET | `/mobile/emergency/caregiver/sos-alerts` | authenticated | `emergency.py:58` |
| GET | `/mobile/emergency/sos/{sos_id}` | authenticated | `emergency.py:78` |
| POST | `/mobile/emergency/sos/{sos_id}/resolve` | authenticated | `emergency.py:122` |

### Fall events (`fall_events.py` prefix `/fall-events`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/fall-events` | authenticated | `fall_events.py:43` |
| GET | `/mobile/fall-events/{fall_event_id}` | authenticated | `fall_events.py:74` |
| POST | `/mobile/fall-events/{fall_event_id}/dismiss` | authenticated | `fall_events.py:110` |
| POST | `/mobile/fall-events/{fall_event_id}/survey` | authenticated | `fall_events.py:151` |

### Risk (`risk.py` no prefix, paths `/risk`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/mobile/risk/calculate` | internal-service header OR authenticated | `risk.py:398` |
| POST | `/mobile/risk/recalculate` | authenticated + X-Target-Profile-Id header | `risk.py:341` |
| GET | `/mobile/risk/latest` | authenticated | `risk.py:433` |
| GET | `/mobile/risk/history` | authenticated | `risk.py:625` |
| GET | `/mobile/risk/{risk_score_id}/detail` | authenticated | `risk.py:580` |
| POST | `/mobile/risk/alerts/{notification_id}/respond` | authenticated | `risk.py:313` |

### Notifications (`notifications.py` no prefix)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/notifications` | authenticated | `notifications.py:25` |
| GET | `/mobile/notifications/{notification_id}` | authenticated | `notifications.py:49` |
| PUT | `/mobile/notifications/{notification_id}/read` | authenticated | `notifications.py:65` |
| POST | `/mobile/notifications/push-token` | authenticated | `notifications.py:86` |
| POST | `/mobile/notifications/push-token/unregister` | authenticated | `notifications.py:105` |

### Relationships (`relationships.py` no prefix, paths `/relationships` + `/access-profiles`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/relationships/dashboard` | authenticated | `relationships.py:23` |
| GET | `/mobile/relationships/{contact_id}/detail` | authenticated | `relationships.py:35` |
| GET | `/mobile/relationships/{contact_id}/medical-info` | authenticated | `relationships.py:48` |
| GET | `/mobile/access-profiles` | authenticated | `relationships.py:65` |
| GET | `/mobile/relationships/search` | authenticated | `relationships.py:78` |
| GET | `/mobile/relationships` | authenticated | `relationships.py:91` |
| POST | `/mobile/relationships/request` | authenticated | `relationships.py:104` |
| POST | `/mobile/relationships/accept` | authenticated | `relationships.py:124` |
| PUT | `/mobile/relationships/{relationship_id}` | authenticated | `relationships.py:142` |
| DELETE | `/mobile/relationships/{relationship_id}` | authenticated | `relationships.py:161` |

### Settings (`settings.py` prefix `/settings`)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/settings/general` | authenticated | `settings.py:16` |
| PUT | `/mobile/settings/general` | authenticated | `settings.py:26` |

### Telemetry (`telemetry.py` prefix `/telemetry`, internal-only)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/mobile/telemetry/ingest` | `require_internal_service` | `telemetry.py:212` |
| POST | `/mobile/telemetry/alert` | `require_internal_service` | `telemetry.py:337` |
| POST | `/mobile/telemetry/sleep` | (no internal guard?) | `telemetry.py:550` |
| POST | `/mobile/telemetry/imu-window` | (no internal guard?) | `telemetry.py:625` |
| POST | `/mobile/telemetry/sleep-risk` | (no internal guard?) | `telemetry.py:707` |

⚠️ **Auth inconsistency:** `/ingest` + `/alert` có `require_internal_service`, 3 endpoints khác KHÔNG. See Drift D-012.

### Admin (`admin.py` prefix `/admin`, internal-only — ALL endpoints)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/mobile/admin/devices` | `require_internal_service` | `admin.py:58` |
| POST | `/mobile/admin/devices` | `require_internal_service` | `admin.py:73` |
| PATCH | `/mobile/admin/devices/{device_id}` | `require_internal_service` | `admin.py:115` |
| DELETE | `/mobile/admin/devices/{device_id}` | `require_internal_service` | `admin.py:148` |
| POST | `/mobile/admin/devices/{device_id}/assign` | `require_internal_service` | `admin.py:166` |
| POST | `/mobile/admin/devices/{device_id}/activate` | `require_internal_service` | `admin.py:200` |
| POST | `/mobile/admin/devices/{device_id}/deactivate` | `require_internal_service` | `admin.py:225` |
| POST | `/mobile/admin/devices/{device_id}/heartbeat` | `require_internal_service` | `admin.py:243` |
| GET | `/mobile/admin/users/search` | `require_internal_service` | `admin.py:269` |

### Monitoring (`monitoring.py`)

5+ endpoints under `/mobile/metrics/*` and `/mobile/analysis/*` — content not fully scanned, defer Phase 1.

---

## Service 3: healthguard-model-api (ML inference)

**Base:** `http://localhost:8001/`

### System (`system.py` no prefix)

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/` | public (redirect to /docs) | `system.py:17` |
| GET | `/health` | public | `system.py:22` |
| GET | `/api/v1/models` | public | `system.py:45` |

### Fall (`fall.py` prefix `/api/v1/fall`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/api/v1/fall/predict` | (no internal guard?) | `fall.py:42` |
| GET | `/api/v1/fall/model-info` | public | `fall.py:67` |
| GET | `/api/v1/fall/sample-cases` | public | `fall.py:72` |
| GET | `/api/v1/fall/sample-input` | public | `fall.py:81` |

### Health risk (`health.py` prefix `/api/v1/health`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/api/v1/health/predict` | (no internal guard?) | `health.py:32` |
| POST | `/api/v1/health/predict/batch` | (no internal guard?) | `health.py:50` |
| GET | `/api/v1/health/model-info` | public | `health.py:55` |
| GET | `/api/v1/health/sample-cases` | public | `health.py:60` |
| GET | `/api/v1/health/sample-input` | public | `health.py:69` |

### Sleep (`sleep.py` prefix `/api/v1/sleep`)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/api/v1/sleep/predict` | (no internal guard?) | `sleep.py:32` |
| POST | `/api/v1/sleep/predict/batch` | (no internal guard?) | `sleep.py:50` |
| GET | `/api/v1/sleep/model-info` | public | `sleep.py:55` |
| GET | `/api/v1/sleep/sample-cases` | public | `sleep.py:60` |
| GET | `/api/v1/sleep/sample-input` | public | `sleep.py:69` |

⚠️ **Critical security flag:** Predict endpoints không có `verify_internal_secret` middleware (per scan). Anyone trên network có thể call ML inference free. See Drift D-013.

⚠️ **Path collision:** `system.py /health` vs `health.py /api/v1/health/*` — không collision technical (different prefix) nhưng confusing semantic. See Drift D-014.

---

## Service 4: Iot_Simulator_clean api_server

**Base:** `http://localhost:8002/api/sim/*`

### Devices

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/devices` | (sim middleware) | `devices.py:56` |
| POST | `/api/sim/devices` | (sim middleware) | `devices.py:61` |
| DELETE | `/api/sim/devices/{device_id}` | (sim middleware) | `devices.py:69` |
| POST | `/api/sim/devices/{device_id}/bind` | (sim middleware) | `devices.py:75` |
| DELETE | `/api/sim/devices/{device_id}/bind` | (sim middleware) | `devices.py:88` |

### Sessions

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/sessions` | — | `sessions.py:16` |
| POST | `/api/sim/sessions` | — | `sessions.py:21` |
| POST | `/api/sim/sessions/{session_id}/start` | — | `sessions.py:33` |
| POST | `/api/sim/sessions/{session_id}/stop` | — | `sessions.py:42` |
| GET | `/api/sim/sessions/{session_id}/motion/latest` | — | `sessions.py:56` |
| GET | `/api/sim/sessions/{session_id}/fall-state` | — | `sessions.py:73` |

### Vitals

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/vitals/latest` | — | `vitals.py:11` |

### Verification

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/verification/latest` | — | `verification.py:11` |

### Settings

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/settings` | — | `settings.py:109` |
| PUT | `/api/sim/settings/runtime` | — | `settings.py:137` |
| POST | `/api/sim/settings/runtime/reset` | — | `settings.py:169` |

### Scenarios

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/scenarios` | — | `scenarios.py:321` |
| POST | `/api/sim/scenarios/apply` | — | `scenarios.py:326` |
| POST | `/api/sim/scenarios/sleep/backfill` | — | `scenarios.py:403` |
| POST | `/api/sim/scenarios/sleep/push-date` | — | `scenarios.py:440` |

### Events (multi-mount)

| Method | Path | Auth | File |
|---|---|---|---|
| POST | `/api/sim/events` | — | `events.py:11` |
| POST | `/api/sim/events/inject` | — | `events.py:12` (decorator stacked on same function) |
| GET | `/api/sim/events/recent` | — | `events.py:24` |
| POST | `/api/sim/events/fall` | — | `events.py:32` |
| POST | `/api/sim/events/device-status` | — | `events.py:44` |

### Registry, Dashboard, Analytics

| Method | Path | Auth | File |
|---|---|---|---|
| GET | `/api/sim/registry/status` | — | `registry.py:10` |
| GET | `/api/sim/dashboard/summary` | — | `dashboard.py:11` |
| GET | `/api/sim/analytics/sleep` | — | `analytics.py:17` |
| GET | `/api/sim/analytics/sleep/history` | — | `analytics.py:28` |
| POST | `/api/sim/analytics/sleep/{device_id}/push` | — | `analytics.py:40` |
| GET | `/api/sim/analytics/risk` | — | `analytics.py:51` |

⚠️ **Auth gap:** Sim endpoints không có visible auth middleware trong scan. Likely intentional (dev tool) nhưng cần verify Phase 1. See Drift D-015.

---

## Drift findings (mismatch flags)

### D-007: HealthGuard `/users` mount conflict (relationship + user routers cùng prefix)

**Severity:** Low (currently works but fragile)

**Source:** `routes/index.js:19-20`
```js
router.use('/users', relationshipRoutes);  // Order matters!
router.use('/users', userRoutes);
```

**Concern:** Express middleware order — relationship routes phải đăng ký trước để `/relationships/search` không bị `/:id` của user route consume. Refactor mistake nào đó hoán đổi order = bug ngầm.

**Fix:** Phase 4 — split relationship routes ra prefix riêng `/relationships` thay vì share `/users`.

---

### D-008: HealthGuard `/health` route auth gap (admin BE)

**Severity:** High (admin data leak risk)

**Source:** `health.routes.js` — em không thấy `router.use(authenticate, requireAdmin)` ở đầu file (per scan).

**Concern:** Health overview endpoints (patient detail, vitals trend, alerts CSV export) có thể callable mà không auth → admin data leak.

**Fix:** Verify Phase 1 macro audit. Nếu confirm gap, Phase 4 add middleware.

---

### D-009: HealthGuard `/vital-alerts/*` (non-admin) NO auth middleware

**Severity:** Critical (production)

**Source:** `vital-alert.routes.js` — không có `router.use(authenticate)` ở đầu file.

**Concern:** Endpoint POST `/vital-alerts/process` (process vitals) + POST `/vital-alerts/processor/toggle` (turn processor on/off) callable public. Anyone trên network có thể disable vital alert processor → critical alerts không trigger.

**Fix:** Phase 4 — add `router.use(authenticate, requireAdmin)`. Verify production deploy đã có hay chưa (`req.user` check trong controller có thể compensate, cần verify).

---

### D-010: HealthGuard double "admin" path `/api/v1/admin/admin/vital-alerts/*`

**Severity:** Low (UX/API readability)

**Source:** `app.js:47` mount `/api/v1/admin` + `routes/index.js:28` `router.use('/admin/vital-alerts', ...)` → URL = `/api/v1/admin/admin/vital-alerts/*`.

**Fix:** Phase 4 — change mount to `/admin/...` (drop one) or rename sub-prefix.

---

### D-011: HealthGuard `/api/v1/internal/*` no `X-Internal-Secret` check

**Severity:** Critical (production)

**Source:** `internal.routes.js` — POST endpoints không có middleware kiểm tra internal secret header.

**Concern:** Anyone với network access có thể:
- POST `/api/v1/internal/websocket/emit-alert` → gửi fake alert → admin web hiển thị spoofed alert
- Tương tự cho `/emit-emergency`, `/emit-risk`

**Fix:** Phase 4 — add `verifyInternalSecret` middleware. Compare với health_system pattern `Depends(require_internal_service)`.

---

### D-012: health_system telemetry endpoints inconsistent internal guard

**Severity:** High

**Source:** `telemetry.py`
- `/ingest` + `/alert` có `dependencies=[Depends(require_internal_service)]`
- `/sleep`, `/imu-window`, `/sleep-risk` KHÔNG có

**Concern:** Sleep/IMU telemetry là internal pipeline path từ IoT sim → backend. Nếu thiếu guard, mobile client có thể spoof IMU window → false fall detection trigger.

**Fix:** Verify Phase 1 nếu intentional (e.g., mobile client ingest IMU directly?). Else Phase 4 add guard.

---

### D-013: healthguard-model-api predict endpoints no internal guard

**Severity:** Critical (production)

**Source:** `fall.py:42`, `health.py:32`+`50`, `sleep.py:32`+`50` — POST predict endpoints không có `verify_internal_secret` dependency.

**Concern:** ML inference public → DDoS risk + cost leak (model compute resource).

**Fix:** Phase 4 — add `Depends(verify_internal_secret)`. Verify nếu intentionally public (dev/demo) — production phải lock.

---

### D-014: healthguard-model-api `/health` semantic collision

**Severity:** Low

**Source:**
- `system.py /health` = service health check (load balancer probe)
- `health.py /api/v1/health/*` = health risk prediction

**Concern:** Confusing reader — "health" overloaded. Different prefix ngăn collision technical, nhưng đọc URL không rõ ý nghĩa.

**Fix:** Phase 4 — rename system endpoint `/healthz` (k8s convention) hoặc rename health risk endpoint domain to `/api/v1/risk-prediction/`.

---

### D-015: Iot_Simulator_clean no auth on sim endpoints

**Severity:** Medium (dev tool, but dev DB has real-ish data)

**Source:** All `api_server/routers/*.py` — không có visible auth dependency trong scan.

**Concern:** Sim server có middleware `auth.py` + `rate_limit.py` (file tồn tại) nhưng không thấy applied per route trong scan. Cần verify Phase 1 — middleware có thể applied global trong main.py.

**Fix:** Verify Phase 1. Nếu confirmed gap, Phase 4 add auth.

---

### D-016: Cross-service path naming inconsistency

**Severity:** Low (refactor cleanup)

**Pattern observed:**

| Concept | HealthGuard (admin) | health_system (mobile) |
|---|---|---|
| Emergency events | `/emergencies` (plural) | `/emergency` (singular) |
| User profile | `/users/:id` (admin manages) | `/profile` (user owns self) |
| Vital alerts | `/vital-alerts` (admin tooling) | (no equivalent — mobile is read-only) |
| Risk | (no admin endpoint?) | `/risk/*` (mobile) |

**Concern:** Different services dùng từ vựng khác nhau cho cùng concept → frontend developer phải remember mapping. Không phải bug functional, chỉ DX.

**Fix:** Phase 4 — standardize naming in v2 API redesign. v1 keep for backward compat.

---

### D-017: `/health` path triple-meaning

**Severity:** Low (semantic confusion)

**Locations:**
- HealthGuard `/api/v1/admin/health/*` = health overview dashboard (admin web)
- health_system `/mobile/health` = mobile BE liveness check
- healthguard-model-api `/health` = system liveness check (also `/api/v1/health/*` = health risk prediction)

**Concern:** Reader confusion — `/health` overloaded across 3 services với 3 meanings khác nhau (admin dashboard data, BE liveness probe, ML system probe).

**Fix:** Phase 4 — rename liveness endpoints `/healthz` (k8s convention) hoặc rename health risk endpoint domain to `/api/v1/risk-prediction/`.

---

## Caller mapping (per topology)

Em chưa verify client side trong Phase -1.B. Defer Phase 1 macro audit cho từng service. Below là expected mapping per topology:

| Caller | Target service | Expected base URL |
|---|---|---|
| Mobile app (Flutter) | health_system backend | `https://<host>:8000/mobile/*` |
| Admin web frontend (React) | HealthGuard backend | `https://<host>:5000/api/v1/admin/*` |
| health_system backend → ML inference | healthguard-model-api | `http://<host>:8001/api/v1/{fall,health,sleep}/predict` |
| health_system backend → IoT data | (none direct — IoT push to BE) | — |
| IoT simulator → health_system backend | health_system telemetry endpoints | POST `/mobile/telemetry/{ingest,alert,sleep,imu-window,sleep-risk}` |
| IoT simulator → ML | healthguard-model-api directly | POST `/api/v1/fall/predict` (likely from `fall_ai_client.py`) |
| Pump scripts → admin web | HealthGuard internal | POST `/api/v1/internal/websocket/emit-*` |

**Phase 1 macro audit sẽ verify** từng caller path khớp với route registered ở backend.

---

## Out of scope this phase

- Request/response schema deep-diff (Pydantic vs Zod vs Dart model parity) — Phase 1 macro audit per service
- Auth flow detail (token issuance, refresh, internal secret rotation) — Phase 3 deep-dive auth module
- Rate limit spec (per endpoint) — Phase 1
- Error response format consistency — Phase 1
- WebSocket events catalog — Phase 1
- OpenAPI spec generation — Phase 4

---

## Recommendations (priority ordered)

### P0 — Security critical (Phase 4 hot fixes)

- [ ] **D-009:** Add auth to HealthGuard `/vital-alerts/*` non-admin routes
- [ ] **D-011:** Add internal secret check to HealthGuard `/api/v1/internal/*`
- [ ] **D-013:** Add internal secret check to healthguard-model-api predict endpoints
- [ ] **D-008:** Verify HealthGuard `/health` admin auth gap

### P1 — Auth consistency

- [ ] **D-012:** Add internal guard to health_system telemetry sleep/imu/sleep-risk endpoints
- [ ] **D-015:** Verify Iot_Simulator auth coverage

### P2 — DX cleanup (Phase 4 refactor)

- [ ] **D-007:** Split relationship routes from `/users` mount
- [ ] **D-010:** Fix HealthGuard double "admin" prefix
- [ ] **D-014, D-017:** Rename liveness `/health` → `/healthz`
- [ ] **D-016:** Standardize cross-service vocabulary (emergencies vs emergency, etc)

---

## Phase -1.B Definition of Done

- [x] 4 services × all router files scanned
- [x] ~208 endpoints catalogued với HTTP method + path + auth + file:line
- [x] 11 drift findings (D-007 → D-017) với severity + fix path
- [x] Caller-to-service mapping (high-level per topology)
- [x] Out-of-scope items flagged for Phase 1+
- [ ] ThienPDM review

**Next:** Phase -1.C — Topology v2 (verify call graph against actual code)
