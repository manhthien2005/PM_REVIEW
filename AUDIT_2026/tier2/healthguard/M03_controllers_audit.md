# Audit: M03 — Controllers (HTTP handlers)

**Module:** `HealthGuard/backend/src/controllers/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

11 files:
- `auth.controller.js` (~140 LoC) — login/register/logout/password/me
- `user.controller.js` (~85 LoC) — users CRUD + toggleLock
- `device.controller.js` (~105 LoC) — devices CRUD + assign/unassign/toggleLock
- `logs.controller.js` (~105 LoC) — audit logs list/detail/export
- `settings.controller.js` (~30 LoC) — settings GET/PUT
- `emergency.controller.js` (~105 LoC) — emergency events CRUD + export
- `health.controller.js` (~175 LoC) — health overview + CSV exports
- `dashboard.controller.js` (~70 LoC) — admin dashboard KPI endpoints
- `vital-alert.controller.js` (~125 LoC) — vital processor + per-user thresholds (legacy, drop per drift D-VAA-02)
- `relationship.controller.js` (~55 LoC) — linked profiles CRUD
- `ai-models.controller.js` (~170 LoC) — AI models CRUD + MLOps wrappers

**Out of scope:** Service internals (M04), middleware implementation (M05), Swagger spec verbosity (M01/M02), audit log content accuracy (Phase 3 per-endpoint).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | `vital-alert.controller.js` toàn bộ 9 handlers gọi `ApiResponse.success(data, msg)` SAI signature → TypeError runtime cho mọi request. `health.controller.js` split try/catch + catchAsync inconsistent. `emergency.controller.js` inline require Prisma. |
| Readability | 2/3 | JSDoc + Vietnamese comments đầy đủ. Pattern thin controller rõ ở 10/11 file. Nhưng style lẫn lộn (`catchAsync` wrapper vs try/catch + next(err)). |
| Architecture | 2/3 | 10/11 file thin controller (delegate service). `health.controller.js:exportAlertsCSV/exportRiskCSV` format CSV in-controller (~90 LoC logic) — should be service. `emergency.controller.js` ghi audit log trực tiếp từ controller, bypass service layer. |
| Security | 3/3 | `auth.controller.js` email `.toLowerCase().trim()` normalize, validate required fields trước khi gọi service. IP address + user agent passed xuống service cho audit. Không emit credential values ra log ở controller layer. |
| Performance | 3/3 | Không N+1 ở controller layer. Query param parse + delegate, không DB call trực tiếp. CSV export dùng Array.map + join (synchronous nhưng small dataset, acceptable). |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (1/3)

**⚠️ P0 NEW BUG — `vital-alert.controller.js` gọi `ApiResponse.success` sai signature toàn bộ file** (`vital-alert.controller.js:17, 28, 41, 55, 69, 77, 88, 100, 108`):

- Hiện tại: `res.json(ApiResponse.success(thresholds, 'msg'))` — truyền data làm arg đầu.
- Đúng (theo `ApiResponse.js:21`): `ApiResponse.success(res, data, message)` — static helper tự `res.status(200).json(...)`, không return JSON object để wrap.
- Khi truyền data thay cho `res` → helper gọi `data.status(200)` → **TypeError: data.status is not a function** runtime.
- Hệ quả: TẤT CẢ 9 method (getUserVitalThresholds, updateUserVitalThresholds, getAlertsForVital, processVitalForAlerts, processVitalsInTimeRange, getProcessorStatus, toggleProcessor, processVitals, getThresholds) crash 500 ngay khi được gọi.
- Drift VITAL_ALERT_ADMIN D-VAA-01/02 đã quyết định **drop 6 endpoints + keep 3 processor endpoints** (status, toggle, thresholds). Bug này tự resolve khi Phase 4 cleanup rewrite lại 3 endpoint giữ lại. Priority P0 cho tới khi drift thực hiện — không cần escalate bug riêng HG-XXX vì drift đã cover.
- File: `HealthGuard/backend/src/controllers/vital-alert.controller.js:17,28,41,55,69,77,88,100,108`

- ✓ `auth.controller.js:17-22, 34-45, 62-64, 79-81, 99-101` — validate required fields trước khi gọi service. Throw `ApiError.badRequest` với Vietnamese message — consistent với convention.
- ✓ `auth.controller.js:21` — `email.toLowerCase().trim()` normalize trước khi pass xuống service → defense tại controller boundary, tránh mismatch lookup case-sensitive sau normalize lẻ tẻ ở service.
- ✓ `user.controller.js`, `device.controller.js`, `logs.controller.js`, `dashboard.controller.js`, `relationship.controller.js`, `ai-models.controller.js` — dùng `catchAsync` wrapper đồng đều, async error bubble lên `errorHandler` middleware.
- ✓ `emergency.controller.js:45-60` `updateEventStatus` — wrap websocket emit trong try/catch riêng (`catch (_) { /* ignore */ }`) → nếu websocket crash không ảnh hưởng DB update thành công. Pattern acceptable.
- ⚠️ **P2 — `health.controller.js` trộn 2 style error handling** (`health.controller.js:9-81` dùng `try/catch + next(error)` cho 5 handler đầu; `:92-168` dùng `catchAsync` cho 2 export handler cuối). Không bug, nhưng inconsistent — reader scan phải hiểu cả 2 pattern. Priority P2.
  - File: `HealthGuard/backend/src/controllers/health.controller.js:9-168`
- ⚠️ **P2 — `emergency.controller.js` inline require Prisma + write audit log trực tiếp** (`emergency.controller.js:77-85, 97-105`):
  - `await require('../utils/prisma').audit_logs.create({...})` ghi audit log từ controller, không qua service. Bypass pattern tầng (controller → service → Prisma).
  - Thêm `.catch(() => {})` swallow error silently (rule drift LOGS D-LOGS-04 chấp nhận pattern này nhưng nên ở service layer, không controller).
  - Priority P2 — refactor move vào `emergencyService.logExport()` method.
- ⚠️ **P3 — Ambiguous parse** (`logs.controller.js:45-51, 73-80, 99-107` + `health.controller.js:98-117`): `parseInt(req.query.page) || 1` — nếu `page='abc'` → NaN → `|| 1` → fallback. OK, nhưng `parseInt('12abc', 10) === 12` (silently accept dirty input). Priority P3.

### Readability (2/3)

- ✓ JSDoc comments trên mỗi controller method (`health.controller.js`, `dashboard.controller.js` đầy đủ). `auth.controller.js:6-8` + `user.controller.js:6-9` + `device.controller.js:6-9` module-level JSDoc mô tả vai trò.
- ✓ Vietnamese success messages consistent (`'Đăng nhập thành công'`, `'Lấy danh sách thành công'`, `'Cập nhật thành công'`) — match convention.
- ✓ Route → controller method name mapping rõ (`getAll`, `getById`, `create`, `update`, `softDelete`, `toggleLock`) — CRUD verbs chuẩn.
- ⚠️ **P2 — Style inconsistency** — 2 styles:
  - Object literal + `catchAsync` (7 file): `{ getAll: catchAsync(...), ... }`
  - Named `const` + module.exports object (vital-alert.controller.js): `const getUserVitalThresholds = catchAsync(...); module.exports = { getUserVitalThresholds, ... }`
  - Mixed try/catch + next(err) (health.controller.js 5 handler đầu) vs catchAsync (2 handler export cuối)
  - Priority P2 — unify về object literal + catchAsync như 7 file chính.
- ⚠️ **P3 — `health.controller.js:135-154` + `:171-189` literal Vietnamese text inline** — switch-case-style mapping `alert.severity === 'critical' ? 'Nguy hiểm' : ...` inline trong CSV render. Nếu đổi label → sửa 3 chỗ (controller, FE, export). Extract sang `constants.js` hoặc service. Priority P3.
- ⚠️ `vital-alert.controller.js` thiếu module-level JSDoc intent (file header `* Vital Alert Controller - Quản lý cảnh báo từ vital` nhưng không giải thích tại sao 2 endpoints duplicate `processVitalsInTimeRange` vs `processVitals`). Drift D-VAA-02 giải quyết khi drop. Priority P3.

### Architecture (2/3)

- ✓ **Thin controller pattern** (10/11 file): controller chỉ parse query/body + gọi service + trả response. Không chứa business logic, DB call, hoặc external integration.
- ✓ `auth.controller.js`, `user.controller.js`, `device.controller.js`, `relationship.controller.js`, `ai-models.controller.js` pass `(req.ip, req.headers['user-agent'])` xuống service cho audit log — uniform interface.
- ⚠️ **P2 — `health.controller.js:92-168` logic CSV render trong controller** (~90 LoC):
  - `exportAlertsCSV` + `exportRiskCSV` tự build header array + row mapping + label mapping inline trong controller.
  - Business concern (how to serialize alerts/risk to CSV) không thuộc controller layer.
  - So sánh với `logs.controller.js:69-80` + `emergency.controller.js:69-86` — delegate sang `logsService.exportToCSV()` / `emergencyService.exportToCSV()` (đúng pattern).
  - Refactor: move CSV logic vào `healthService.exportAlertsToCSV()` + `healthService.exportRiskToCSV()`. Priority P2.
  - File: `HealthGuard/backend/src/controllers/health.controller.js:92-188`
- ⚠️ **P2 — `emergency.controller.js:77-85, 97-105` inline Prisma audit write** — controller dùng `require('../utils/prisma').audit_logs.create` trực tiếp. Bypass service abstraction. Service layer đã có helper (`logsService.writeLog`) theo pattern `logs.controller.js:73-80`. Priority P2 — refactor dùng `logsService.writeLog()` hoặc `emergencyService.logExport()`.
- ⚠️ **P3 — `dashboard.controller.js` không pass IP/userAgent** — dashboard endpoints không ghi audit log (HEALTH module đã ghi `admin.view_patient_health` per BR-028-04). Dashboard view không audit-worthy (admin view KPI aggregate). Accept trade-off cho đồ án 2. Priority P3.
- ⚠️ **P3 — `settings.controller.js` chỉ 2 method, 30 LoC**: thin file OK nhưng không có JSDoc module header. Priority P3.
- ✓ `ai-models.controller.js` phân chia AI Models CRUD vs MLOps endpoints rõ (section comment + method name prefix `getMLOps...`). Single controller quản 2 service (aiModelsService + aiModelsMLOpsService) — acceptable khi domain gần.

### Security (3/3)

- ✓ **Input normalize tại boundary** (`auth.controller.js:21, 50, 69`): `email.toLowerCase().trim()` trước khi pass xuống service — tránh case-sensitivity lookup sai; tránh user input trailing space.
- ✓ **Required field check** (`auth.controller.js:17-22, 34-45, 62-64, 79-81, 99-101`) — controller tự reject nếu thiếu password/email/newPassword trước khi `validate()` middleware fire. Defense-in-depth.
- ✓ `auth.controller.js:46-48` reject `role === 'admin'` khi register → **nhưng drift AUTH D-AUTH-06 quyết định REVERT inline role block này** vì register là dev tool (admin đã authenticate → có thể tạo admin khác). Phase 4 task drift AUTH #6 (remove check, ~5 min). Priority P2 per drift.
- ✓ `auth.controller.js:118-124` logout check `req.user && req.user.id` trước khi gọi service — defensive.
- ✓ Không log `req.body` raw ở controller nào → không leak credentials trong log.
- ✓ `user.controller.js:67-74`, `device.controller.js:95-102`, `relationship.controller.js:27-33, 39-47, 52-59` pass `(adminId, ip, userAgent)` xuống service → audit log context đầy đủ. Consistent.
- ✓ `auth.controller.js:125` comment `// Clear token handled on frontend` — controller không xóa cookie (drift AUTH D-AUTH-05 migration sẽ thêm). Hiện tại acceptable vì JWT bearer.
- ✓ `health.controller.js:83-91` `getPatientHealthDetail` pass `req.ip + req.get('user-agent')` xuống service để audit BR-028-04 — enforced per drift HEALTH D-HEA-05.
- ✓ `emergency.controller.js:71, 95` CSV/JSON export audit log ghi `req.user.id + req.query filters` → trace admin export action. Rule LOGS D-LOGS-04.
- ✓ `ai-models.controller.js` mọi CUD endpoint pass IP + userAgent + user.id → audit trail cho AI model lifecycle (training, version upgrade, delete).

### Performance (3/3)

- ✓ Controllers không hit DB/external service trực tiếp (trừ `emergency.controller.js:77-85, 97-105` audit log inline — còn đã flag P2 Architecture).
- ✓ `health.controller.js:120-150, 166-183` CSV render: Array.map + .join tạo string — synchronous nhưng với pagination limit 1000 rows (`:94, :164`) → worst case ~100KB response. Acceptable cho đồ án 2.
- ✓ `emergency.controller.js:69, 95` CSV/JSON export delegate hoàn toàn xuống service — controller chỉ set Content-Type headers.
- ✓ Query param parse (`Number(page) || 1`, `parseInt(limit) || 20`) → O(1), no bottleneck.
- ✓ Không có `await` trong loop ở controller layer (serial await anti-pattern) — loops ở service/service layer (xem M04).

## Recommended actions (Phase 4)

- [ ] **P0** — Per drift/VITAL_ALERT_ADMIN.md D-VAA-01/02: Drop 6 methods trong `vital-alert.controller.js` (getUserVitalThresholds, updateUserVitalThresholds, getAlertsForVital, processVitalForAlerts, processVitalsInTimeRange, processVitals). Keep + fix `ApiResponse.success(res, ...)` signature cho 3 method giữ lại (getProcessorStatus, toggleProcessor, getThresholds) (~1h: cùng lúc drop file routes vital-alerts.js per M02 finding).
- [ ] **P2** — Per drift/AUTH.md Q6 D-AUTH-06: Remove inline role block `if (role === 'admin') throw ApiError.forbidden(...)` trong `auth.controller.js:46-48` (~5 min per drift Phase 4 #6).
- [ ] **P2** — Move CSV render logic từ `health.controller.js:92-188` sang `healthService.exportAlertsToCSV()` + `healthService.exportRiskToCSV()` (~2h).
- [ ] **P2** — Refactor `emergency.controller.js:77-85, 97-105` → dùng `logsService.writeLog()` hoặc `emergencyService.logExport()` thay vì inline Prisma audit write (~30 min).
- [ ] **P2** — Unify error handling style: `health.controller.js` convert 5 handler đầu từ try/catch sang `catchAsync` wrapper (~15 min consistency).
- [ ] **P3** — Unify controller style: `vital-alert.controller.js` từ `const + module.exports` sang object literal (~10 min, nếu không drop hoàn toàn per D-VAA-01).
- [ ] **P3** — Extract Vietnamese label mapping (`severity` → 'Nguy hiểm/Cao/Cảnh báo/...', `status` → 'Chưa đọc/Đã đọc/...') từ `health.controller.js` sang `constants/labels.js` hoặc service helper (~30 min).
- [ ] **P3** — Add module-level JSDoc header cho `settings.controller.js`, `vital-alert.controller.js` (~5 min mỗi file).
- [ ] **P3** — Tighten `parseInt` query param: reject `NaN` explicitly thay vì `|| fallback` (~1h cross-controller, defer).

## Out of scope (defer Phase 3 deep-dive)

- Per-endpoint request/response schema validation (controller vs Swagger spec) — Phase 3.
- Service method contract verification (controller param order match service signature) — Phase 3.
- Audit log content exhaustiveness (mọi action, mọi resource type có log không) — Phase 3 per-module audit.
- CSV dialect compatibility (Excel locale, BOM handling) — đã có BOM ở `health.controller.js:154, 188`, cần verify cross-browser.
- `req.connection?.remoteAddress` fallback behaviour khi `trust proxy` không chuẩn — M01 đã flag `trust proxy = 1` OK cho current setup.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-06 remove register admin inline block, D-AUTH-05 cookie migration.
- Phase 0.5 drift: [drift/VITAL_ALERT_ADMIN.md](../../tier1.5/intent_drift/healthguard/VITAL_ALERT_ADMIN.md) — D-VAA-01/02 drop 6 methods (P0 bug self-resolve).
- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-05 PHI audit pattern (controller pass IP/UA xuống service).
- Phase 0.5 drift: [drift/LOGS.md](../../tier1.5/intent_drift/healthguard/LOGS.md) — D-LOGS-04 writeLog swallow error pattern.
- Phase 0.5 drift: [drift/EMERGENCY.md](../../tier1.5/intent_drift/healthguard/EMERGENCY.md) — export CSV audit log pattern (đã match).
- Phase 0.5 drift: [drift/RELATIONSHIP.md](../../tier1.5/intent_drift/healthguard/RELATIONSHIP.md) — D-REL-01 nested route → controller method nested (đã match).
- HG-001 bug: [HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — root cause ở service layer (M04), controller chỉ pass query.
- M02 Routes audit: validate middleware wiring feeds vào controller.
- M04 Services audit: pattern "controller → service → Prisma" verify tiếp.
- M05 Middlewares audit: `catchAsync` utility source + error propagation.
- Module inventory: M03 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M01_routers_audit.md](../healthguard-model-api/M01_routers_audit.md) — FastAPI router = Express controller equivalent, compare thin-handler pattern.
