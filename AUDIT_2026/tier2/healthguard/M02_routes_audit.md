# Audit: M02 — Routes (HTTP routing layer)

**Module:** `HealthGuard/backend/src/routes/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

14 files trong `backend/src/routes/`:
- `index.js` — gom admin routes + healthcheck
- `auth.routes.js` — login/logout/password (public + authenticated)
- `user.routes.js` — admin users CRUD
- `device.routes.js` — admin devices CRUD
- `logs.routes.js` — audit logs
- `settings.routes.js` — system settings (re-auth)
- `emergency.routes.js` — emergency events
- `health.routes.js` — health overview + threshold alerts + risk distribution
- `dashboard.routes.js` — admin dashboard KPI
- `relationship.routes.js` — user-relationships sub-resource của `/users`
- `vital-alert.routes.js` — processor lifecycle (mount `/admin/vital-alerts`)
- `vital-alerts.js` — legacy testing + per-user thresholds (mount `/vital-alerts` WITHOUT admin prefix)
- `ai-models.routes.js` — AI model + MLOps management
- `internal.routes.js` — internal websocket emit (mount outside admin prefix)

**Out of scope:** Controller logic (M03), service internals (M04), middleware implementation (M05).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Auth + requireAdmin áp đặt đúng ở 13/14 files. `vital-alerts.js` mount ngoài `/admin` prefix (drift D-010). Duplicate PUT + PATCH nhiều nơi. Custom inline validators lệch pattern. |
| Readability | 2/3 | ASCII art headers + JSDoc Swagger đầy đủ ở 7/14 file. Nhưng pattern inconsistent (có file dùng `validate()` rules, có file tự viết middleware), tên file không đồng nhất (`vital-alert.routes.js` vs `vital-alerts.js`). |
| Architecture | 1/3 | D-010 drift: `vital-alerts.js` mount `/api/v1/vital-alerts` bypassing admin prefix; `internal.routes.js` mount inline trong app.js thay vì qua `routes/index.js`. 2 route files cùng scope vital-alerts. D-REL-01 route pattern nested conflict UC v2 (ratified accept). |
| **Security** | **0/3** | D-011 `/internal/*` secret fallback literal (P0 Critical auto-flag per framework v1 anti-pattern list), D-009 `/vital-alerts/*` mount ngoài admin prefix nhưng có authenticate per-route (verified không bypass — downgrade severity), multer upload 500MB không limit type. → Auto-Critical per framework v1 rule. |
| Performance | 3/3 | Rate limit đúng mọi module (30-100 req/min tuỳ domain). No N+1 pattern ở route layer (delegate xuống service). |
| **Total** | **8/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Correctness (2/3)

- ✓ `auth.routes.js:18-28` — public routes (`/login`, `/forgot-password`, `/reset-password`) có rate limit per-IP; protected routes (`/register`, `/me`, `/logout`, `/password`) có `authenticate` + `requireAdmin` nơi cần. Thứ tự middleware đúng.
- ✓ `user.routes.js:72`, `device.routes.js:56`, `logs.routes.js:49`, `emergency.routes.js:97`, `dashboard.routes.js:17`, `health.routes.js:19`, `relationship.routes.js:64`, `ai-models.routes.js:41` — `router.use(authenticate, requireAdmin, <limiter>)` áp đặt đồng nhất cho toàn file. Pattern reference R1 (drift AUTH).
- ✓ `settings.routes.js:16-25` — `GET` + `PUT /settings` mỗi route declare middleware chain riêng thay vì `router.use`. Verbose hơn nhưng explicit → readable.
- ✓ `internal.routes.js:16-23` — middleware `checkInternalSecret` áp đặt `router.use` trước mọi route.
- ⚠️ **Duplicate PUT + PATCH routes** ở 4 files (`user.routes.js:78-82`, `device.routes.js:64-71`, `emergency.routes.js:109-110`, `ai-models.routes.js:67-68, 76-77`). Cả 2 verb trỏ cùng controller method → hoạt động đúng nhưng API surface double. Drift DEV D-DEV-02 + drift USERS D-USERS-04 đã quyết định Phase 4 drop PUT aliases. Priority P2 per drift.
- ⚠️ **`vital-alerts.js` custom inline validators** (`validateUserId`, `validateDeviceId`, `validateTimestamp`, `validateVitalData`, `validateTimeRange` — `vital-alerts.js:11-57`): từng middleware ad-hoc trả `res.status(400).json({error})` không qua `ApiError` → error response shape lệch chuẩn `{success, statusCode, message, errors}`. Drift VITAL_ALERT_ADMIN D-VAA-02 đã quyết định drop file toàn bộ. Priority P2 per drift.
- ⚠️ `routes/index.js:18` — `router.use('/users', relationshipRoutes)` mount TRƯỚC `router.use('/users', userRoutes)` để `/users/relationships/search` match trước `/users/:id`. Comment inline `(before userRoutes, so /relationships/search matches first)` giải thích nhưng rất dễ gẫy nếu thêm route mới. Drift RELATIONSHIP D-REL-01 đã ratify route pattern nested. Priority P3 — refactor cleanup khi merge relationship/user routes.

### Readability (2/3)

- ✓ ASCII art header box ở 7 file (`user/device/logs/emergency/relationship/ai-models/auth.routes.js`) — scan nhanh endpoint list + Vietnamese comment semantic.
- ✓ JSDoc Swagger đầy đủ ở `health.routes.js`, `dashboard.routes.js`, `vital-alert.routes.js`, `vital-alerts.js` — mỗi endpoint có `@swagger` block với path, parameters, responses. Redundant với `config/swagger.js` nhưng gần code dễ maintain hơn.
- ✓ Validation rules literal trên top file rồi dùng trong route (`user.routes.js:40-73`, `device.routes.js:33-58`, `emergency.routes.js:42-82`) — reader đọc rules trước, routes sau, không scroll ngược.
- ⚠️ **Pattern inconsistency** — 3 styles validate hiện diện:
  - `validate(rules)` factory (7 files: user/device/logs/emergency/settings/relationship/ai-models).
  - Inline ad-hoc middleware (`vital-alerts.js`).
  - Không validate (`dashboard.routes.js`, `health.routes.js`, `vital-alert.routes.js`) — query params trust client.
  → Priority P2: align toàn bộ về `validate()` rules (drift VITAL_ALERT Q2).
- ⚠️ **Tên file lệch convention** — 13/14 file dùng `.routes.js`, chỉ `vital-alerts.js` không có suffix. Drift VITAL_ALERT_ADMIN D-VAA-02 quyết định drop file → resolve tự nhiên. Priority P3.
- ⚠️ `relationship.routes.js` mount ở `/users` (routes/index.js:18) nhưng file tên `relationship.routes.js` → file name vs mount path không match rõ intent. Pattern nested accepted (drift D-REL-01) nhưng comment trong `routes/index.js` cần bổ sung. Priority P3.

### Architecture (1/3)

- ⚠️ **P0 — `vital-alerts.js` + double admin prefix** (`routes/index.js:22-23`): Verify via mount sequence:
  - Line 22: `router.use('/vital-alerts', vitalAlertRoutes)` → resolves `/api/v1/admin/vital-alerts`
  - Line 23: `router.use('/admin/vital-alerts', vitalAlertAdminRoutes)` → resolves `/api/v1/admin/admin/vital-alerts` (double prefix)
  - Phase -1 D-010 đã flag. Drift VITAL_ALERT_ADMIN D-VAA-01 quyết định drop file `vital-alerts.js` + keep `vital-alert.routes.js` (renamed cleanly) + fix mount prefix. Priority P0 per drift.
  - File: `HealthGuard/backend/src/routes/index.js:22-23`
- ⚠️ **P2 — Internal routes mount inline** — `app.js:40-43` mount `require('./routes/internal.routes')` trực tiếp thay vì qua `routes/index.js`. Tương tự finding M01. Phase 4 coordinate với ADR-004 API prefix work. Priority P2 per drift INTERNAL.
- ⚠️ **P2 — 2 route files trùng scope vital-alerts**: `vital-alert.routes.js` (processor lifecycle) + `vital-alerts.js` (testing + per-user thresholds). Duplicate `POST /process` endpoint với khác signature (range vs single). Drift VITAL_ALERT_ADMIN D-VAA-02 drop file → resolve. Priority P2 per drift.
- ⚠️ **P3 — Relationship nested pattern** (`routes/index.js:18` mount cùng `/users` prefix, phải đặt trước userRoutes để priority match). Pattern nested chọn accept per drift D-REL-01 nhưng cost: tight coupling giữa 2 route modules. Refactor Phase 5+ về flat `/relationships` nếu xảy ra route collision mới. Priority P3.
- ✓ `settings.routes.js` — chain middleware per-route (không `router.use`) dễ audit từng endpoint. Design choice chấp nhận được cho module nhỏ 2 endpoints.

### Security (0/3) — 🚨 Auto-Critical

**⚠️ P0 — `internal.routes.js` secret fallback** (`routes/internal.routes.js:13`):

- Middleware `checkInternalSecret` có pattern `process.env.INTERNAL_SECRET || '<literal-fallback>'` — nếu deploy quên set env → fallback literal trong source → trivial auth bypass.
- Phase -1 D-011 đã flag. Drift INTERNAL D-INT-01 quyết định Phase 4 remove fallback + add vào `env.js` required array (xem M01 audit finding).
- **Framework v1 anti-pattern auto-flag** (quote list: credential literal trong source code) → Security score = 0.
- **Cross-module impact:** Cùng pattern D-013 (model-api) + pending fix IoT sim (D-020). Coordinate cross-repo Phase 4 per ADR-005.
- **Action:** per drift/INTERNAL.md D-INT-01 — Phase 4 remove fallback (~15min route side) + bootstrap side fail-fast.
- File: `HealthGuard/backend/src/routes/internal.routes.js:13`

**⚠️ P2 — `vital-alerts.js` mount prefix drift (D-009 re-verify)** (`routes/index.js:22`):

- Phase -1 D-009 claim `/vital-alerts/*` non-admin routes NO auth. Em verify:
  - `routes/index.js:22` mount `router.use('/vital-alerts', vitalAlertRoutes)` — vì `routes/index.js` được mount tại `/api/v1/admin` trong `app.js:45`, full path = `/api/v1/admin/vital-alerts/*`.
  - `vital-alerts.js:71-175` — **MỖI ROUTE** có `authenticate, requireAdmin` per-route (không `router.use` globally).
  - → **D-009 severity downgrade: không phải "no auth", mà là "double admin prefix drift D-010"**. Auth middleware vẫn enforce. Phase -1 finding phần nào outdated (đã có partial fix).
- Drift VITAL_ALERT_ADMIN D-VAA-02 drop file toàn bộ → resolve drift này.
- Priority P2 per drift (re-confirmed, không escalate P0).
- File: `HealthGuard/backend/src/routes/vital-alerts.js:71-175`

**⚠️ P2 — `ai-models.routes.js` multer upload 500MB không limit MIME** (`ai-models.routes.js:35-38`):

- `multer({ storage: memoryStorage(), limits: { fileSize: 500MB } })` — accept mọi file type, load full vào RAM.
- Risk:
  - Memory pressure: 500MB × N concurrent uploads → crash.
  - MIME spoofing: attacker upload `.exe` rename `.pkl` → backend đọc binary + save → downstream loader có thể exec.
- Mitigation hiện có: `authenticate + requireAdmin` per `router.use` (`ai-models.routes.js:41`) → chỉ admin compromised mới exploit.
- **Action (new, không drift-flagged):** Phase 5+ — thêm `fileFilter` check MIME + extension whitelist (`.pkl`, `.onnx`, `.pt`, `.joblib`); cân nhắc `multer.diskStorage()` để không load RAM; hạ limit xuống 100MB (artifact thật typical < 50MB).
- Priority P2.
- File: `HealthGuard/backend/src/routes/ai-models.routes.js:35-38`

**⚠️ P3 — `logs.routes.js` search filter không sanitize SQL-safe** (`logs.routes.js:31-40`):

- Rule `search: { type: 'string', sanitize: true }` — sanitize-html strip tag, không escape SQL wildcard.
- Controller có thể pass vào Prisma `contains: search` (parameterized, an toàn) hoặc tự build `$queryRaw` (risk).
- Verify Phase 3 `logs.controller.js` → nếu dùng Prisma `contains` → OK, không cần escape thêm.
- Priority P3 — verify only.
- File: `HealthGuard/backend/src/routes/logs.routes.js:31-40`, `controllers/logs.controller.js`

**✓** `auth.routes.js` — rate limit tiers đúng (login 5/15min per-IP → drift AUTH D-AUTH-02 layer 2).
**✓** Mọi admin route có `requireAdmin` → role-based deny default.

### Performance (3/3)

- ✓ Rate limit per domain: `authLimiter` 5/15min, `userLimiter/deviceLimiter/logsLimiter/emergencyLimiter/relationshipLimiter` 100/min, `healthLimiter/dashboardLimiter` 60/min, `vitalAlertLimiter` 30/min, `loginLimiter/forgotPasswordLimiter/changePasswordLimiter` 5/15min. Tiers match sensitivity đúng.
- ✓ Routes không hit DB trực tiếp — delegate xuống controller → service → Prisma. Layered design.
- ✓ No sync file IO hoặc blocking call ở route layer.
- ✓ `multer.memoryStorage()` cho AI model upload — acceptable cho scope đồ án 2 (admin-only, ít concurrent), nhưng xem Security finding về hạn chế.
- ✓ `ai-models.routes.js:40` single global `router.use(authenticate, requireAdmin)` → 1 lần middleware chain setup, không repeat cost.

## Recommended actions (Phase 4)

- [ ] **P0** — Per drift/INTERNAL.md D-INT-01: Remove fallback literal trong `internal.routes.js:13` + config/env.js thêm INTERNAL_SECRET required (~15 min route side).
- [ ] **P0** — Per drift/VITAL_ALERT_ADMIN.md D-VAA-01/02: Drop `vital-alerts.js` entirely, keep `vital-alert.routes.js` (~1.5h cleanup + service code removal).
- [ ] **P1** — Per drift/INTERNAL.md D-INT-02: Add rate limit middleware cho `internal.routes.js` (1000 req/min per-IP, ~30 min).
- [ ] **P1** — Per drift/INTERNAL.md D-INT-04: Add `validate()` middleware cho 3 internal endpoints với schema `emit-alert/emit-emergency/emit-risk` (~1h).
- [ ] **P1** — Per drift/INTERNAL.md D-INT-06: Sanitize error responses cho internal routes (~30 min).
- [ ] **P1** — Per drift/INTERNAL.md D-INT-03: Add audit log cho internal emit calls (~30 min).
- [ ] **P2** — Per drift/DEVICES.md D-DEV-02 + USERS D-USERS-04: Remove PUT aliases ở 4 route files (user/device/emergency/ai-models), keep PATCH only (~15 min).
- [ ] **P2** — Fix double admin prefix: `routes/index.js:22-23` restructure để `/vital-alerts` chỉ mount 1 chỗ với prefix rõ (~30 min, đồng bộ với drop vital-alerts.js).
- [ ] **P2** — Gate Swagger JSDoc duplicate content — cân nhắc chỉ keep trong `config/swagger.js` thay vì inline (~1h consistency cleanup).
- [ ] **P3** — Align validation pattern: route `dashboard.routes.js`, `health.routes.js`, `vital-alert.routes.js` thêm `validate()` cho query params (~1h).
- [ ] **P3** — Rename `vital-alerts.js` → xóa (drift decision), `relationship.routes.js` giữ tên + comment rõ mount nested tại `routes/index.js`.

## Out of scope (defer Phase 3 deep-dive)

- Route-controller contract deep check (request body schema vs controller expectation) — Phase 3 per-endpoint.
- Swagger spec path accuracy vs actual path match — Phase 3.
- Rate limit threshold tuning (verify production traffic baseline) — Phase 5+.
- Multer `fileFilter` MIME validation implementation — Phase 5+ with AI model upload hardening.
- Route-level telemetry/tracing (morgan, pino-http) — not currently wired.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — rate limit tiers reference R1.
- Phase 0.5 drift: [drift/INTERNAL.md](../../tier1.5/intent_drift/healthguard/INTERNAL.md) — D-INT-01..06 backlog (Phase 4).
- Phase 0.5 drift: [drift/VITAL_ALERT_ADMIN.md](../../tier1.5/intent_drift/healthguard/VITAL_ALERT_ADMIN.md) — D-VAA-01..04 module scope decisions.
- Phase 0.5 drift: [drift/DEVICES.md](../../tier1.5/intent_drift/healthguard/DEVICES.md) — D-DEV-02 remove PUT aliases.
- Phase 0.5 drift: [drift/ADMIN_USERS.md](../../tier1.5/intent_drift/healthguard/ADMIN_USERS.md) — D-USERS-04 REST clean + D-USERS-05 relationship routes accept nested.
- Phase 0.5 drift: [drift/RELATIONSHIP.md](../../tier1.5/intent_drift/healthguard/RELATIONSHIP.md) — D-REL-01 nested pattern ratify.
- Phase 0.5 drift: [drift/LOGS.md](../../tier1.5/intent_drift/healthguard/LOGS.md) — logs filter details.
- Phase -1 findings: [phase_minus_1_summary.md](../../phase_minus_1_summary.md) — D-007 (relationship mount order), D-008 (`/health/*` auth verify — verified OK), D-009 (`/vital-alerts/*` — downgrade per em verify per-route authenticate exists), D-010 (double admin prefix — ACTIVE), D-011 (`/internal/*` secret — ACTIVE, see M01).
- ADR-004: [004-api-prefix-standardization.md](../../../ADR/004-api-prefix-standardization.md) — routing architecture constraint.
- ADR-005: [005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — internal auth contract.
- Module inventory: M02 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M01_routers_audit.md](../healthguard-model-api/M01_routers_audit.md) — compare Express routes vs FastAPI router pattern.
