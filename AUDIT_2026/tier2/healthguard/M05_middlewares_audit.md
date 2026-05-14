# Audit: M05 — Middlewares (auth, validate, errorHandler, rate limiters)

**Module:** `HealthGuard/backend/src/middlewares/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

- `auth.js` (~120 LoC) — `authenticate` JWT + DB check, `requireAdmin`, 3 rate limiters (login, changePassword, forgotPassword)
- `errorHandler.js` (~45 LoC) — global error mapper (ApiError → response, Prisma P2002/P2025 → HTTP 4xx)
- `validate.js` (~110 LoC) — generic request validator factory (body/params/query × required/type/pattern/enum/sanitize/length/date/password)

**Out of scope:** route-level wiring (M02), rate limit runtime verification (needs load test), `sanitize-html` config audit (rely on library defaults).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | JWT verify covers 3 error classes, DB check `deleted_at IS NULL` + `is_active` + `token_version`. errorHandler maps P2002/P2025. validate() handles 8 rule types. |
| Readability | 3/3 | File ngắn (~40-120 LoC mỗi file), JSDoc trên public fns, Vietnamese error messages user-facing, English identifier. |
| Architecture | 3/3 | Single-responsibility mỗi middleware. `authenticate` + `requireAdmin` composable. `validate()` factory take rules object — reusable ở mọi route. |
| **Security** | **2/3** | Strong base (JWT + DB active check + token_version pattern + rate limit + sanitize-html). Gaps: validate() không check number range, P2003 FK không map, rate limit per-process (multi-instance scale lệch). Không hit anti-pattern auto-flag. |
| Performance | 2/3 | DB roundtrip per authenticated request (R1 reference pattern, trade-off accepted). Rate limit in-memory chỉ single-instance. `validate.js` lazy require `passwordValidator` inside handler. |
| **Total** | **13/15** | Band: **🟢 Mature** |

## Findings

### Correctness (3/3)

- ✓ `auth.js:13-21` — Token extract từ `Authorization: Bearer` header, reject nếu missing/malformed.
- ✓ `auth.js:23` — `jwt.verify(token, env.JWT_SECRET)` → error branches phân biệt `JsonWebTokenError` (invalid) vs `TokenExpiredError` (expired) vs generic `ApiError` (`auth.js:60-71`).
- ✓ `auth.js:26-30` — DB query `findFirst` với `deleted_at: null` filter + `select` các field cần, không leak password hash về req.user.
- ✓ `auth.js:36-38` — Check `!user.is_active` → 423 Locked (đúng semantic), không phải 401.
- ✓ `auth.js:40-42` — `token_version` mismatch reject (ready cho D-AUTH-03 logout-increment pattern).
- ✓ `auth.js:45-50` — Gắn `req.user` chỉ chứa `id/email/role/full_name` — không expose `token_version` hoặc internal flag ra downstream handler.
- ✓ `auth.js:74-78` — `requireAdmin` đặt sau `authenticate`, check `req.user.role !== 'admin'` → 403. Dependency ordering rõ ràng qua JSDoc comment.
- ✓ `errorHandler.js:17-25` — Map Prisma `P2002` → 409 Conflict với field name từ `err.meta.target`, `P2025` → 404 Not Found.
- ✓ `errorHandler.js:28-35` — NODE_ENV=development expose stack; production chỉ expose `{ success, statusCode, message, errors? }` → không leak stack trace tới client.
- ✓ `validate.js:22-88` — Loop `body/params/query` sources, skip nếu rule source không khai báo. Required check trước type check (correct order).
- ✓ `validate.js:43-48` — Skip optional fields nếu không provided (`undefined/null/empty string`) — không false-positive validation lỗi.
- ✓ `validate.js:53-58` — `sanitize: true` dùng `sanitize-html` strip toàn bộ tag, ghi đè `req[source][field]` — XSS defense trước khi chạm controller.
- ✓ `validate.js:77-96` — `validateDate` check phạm vi hợp lý (year >= 1900, không future, age ≤ 150) — ngăn DOB invalid flow xuống service.
- ✓ `validate.js:99-106` — `validatePassword` delegate sang `passwordValidator.validatePasswordStrength` với context `isAdmin` lấy từ `req.body.role` — consistent với business rule admin password strict hơn.
- ⚠️ `validate.js:34-42` — `typeof value !== rule.type` không phân biệt array vs object (`typeof [] === 'object'`). Nếu rule yêu cầu `type: 'array'` → handler không có path xử lý → fallthrough silent. Không bug trong code hiện tại (không endpoint nào khai array trong rules) nhưng extensibility hole. Priority P2. File: `HealthGuard/backend/src/middlewares/validate.js:34-38`.

### Readability (3/3)

- ✓ 3 file đều ≤ 120 LoC, mỗi function ≤ 50 LoC → scan 1 lượt hiểu flow.
- ✓ JSDoc ở top mỗi exported function (`auth.js:6-9`, `validate.js:4-18`, `errorHandler.js:3-8`) — mô tả usage + param shape.
- ✓ Section comments trong `errorHandler.js` (`── Default values`, `── Prisma known errors`, `── Response`) chia block rõ ràng.
- ✓ Vietnamese user-facing error messages (`'Vui lòng đăng nhập lại'`, `'Tài khoản đã bị khoá'`) — match convention dự án, không trộn tiếng Việt trong identifier.
- ✓ Rate limiter config object (`auth.js:83-95`) literal dễ đọc — windowMs, max, message shape consistent qua 3 limiters.
- ⚠️ `errorHandler.js:28` — `console.error` literal prefix dùng emoji trong source — rule workspace `00-operating-mode.md` cấm emoji trong code. Priority P3 cosmetic.

### Architecture (3/3)

- ✓ **Single responsibility** — `auth.js` chỉ JWT, `validate.js` chỉ input validation, `errorHandler.js` chỉ error mapping. Không module nào overlap concern.
- ✓ **Composability** — `authenticate + requireAdmin` chain tự nhiên qua Express middleware. Route declare thứ tự: `router.post('/x', authenticate, requireAdmin, validate(rules), controller.fn)` — đọc top-down = execution order.
- ✓ **DI-friendly** — `auth.js` require `prisma` + `env` từ module path cố định (singleton). Test có thể mock qua jest.mock.
- ✓ **Rule object pattern** (`validate.js:10-15`) — rules declarative, không cần viết validation logic mỗi route, giảm duplication. Precedent: controller `user.controller.js` + `device.controller.js` dùng chung pattern này.
- ✓ Rate limiters export riêng (`changePasswordLimiter`, `loginLimiter`, `forgotPasswordLimiter`) — opt-in per route, không global side effect.

### Security (2/3)

- ✓ **JWT verify pattern R1** (`auth.js:23-42`) — verify signature → DB lookup (`deleted_at: null`) → `is_active` check → `token_version` check. Phát hiện token của user đã xoá/khoá/đổi password ngay lập tức mà không phụ thuộc token expiry.
- ✓ **Rate limit tiers** (`auth.js:83-118`) — login 5/15min, changePassword 5/15min, forgotPassword 3/15min — per-IP qua `express-rate-limit` + `trust proxy` ở bootstrap. Defense against credential stuffing.
- ✓ **XSS defense** (`validate.js:53-58`) — `sanitize-html({ allowedTags: [], allowedAttributes: {} })` strip toàn bộ HTML. User input đi qua `validate()` với `sanitize: true` sẽ plain text trước khi chạm service.
- ✓ **Error response sanitization** (`errorHandler.js:37-43`) — production không leak `err.stack`, chỉ trả `message` đã được `ApiError` shape sẵn (Vietnamese, không chứa internal detail).
- ✓ **Password strength** (`validate.js:98-106`) — delegate sang `passwordValidator` với admin/user context → admin password rule strict hơn (config-driven).
- ⚠️ **P1 — Middleware chưa hỗ trợ cookie fallback** (`auth.js:13-21`): Token chỉ đọc từ `Authorization: Bearer` header. Drift AUTH D-AUTH-05 quyết định migrate sang httpOnly cookie + CSRF — khi Phase 4 thực thi migration, `authenticate` cần đọc `req.cookies.token` fallback và kèm CSRF check. Per drift/AUTH.md Phase 4 backlog #3 (cookie + CSRF ~6-8h coord BE+FE).
- ⚠️ **P2 — validate() không có number range check**: Rule hiện tại có `minLength/maxLength` cho string, nhưng không có `min/max` cho number. Nếu service nhận `limit=99999` hoặc `age=-5` → fallthrough xuống Prisma/business. Precedent: endpoint `/users?limit=N` (route-level validate) dùng default + clamp trong controller/service, không xảy ra exploit hiện tại nhưng extensibility nên thêm. Priority P2. File: `HealthGuard/backend/src/middlewares/validate.js:34-48`.
- ⚠️ **P2 — errorHandler không map Prisma P2003** (FK violation): `errorHandler.js:17-25` chỉ map P2002 (unique) và P2025 (not found). P2003 (FK violation khi delete parent có child) → fallthrough 500 với generic message. Ảnh hưởng delete user/device có dependent records → UX không rõ "tại sao không xoá được". Priority P2. File: `HealthGuard/backend/src/middlewares/errorHandler.js:17-25`.
- ⚠️ **P3 — Rate limiter `message` shape lệch ApiResponse convention**: `auth.js:85-89` rate limiter trả `{ success: false, statusCode: 429, message: ... }` không có field `errors` array như các endpoint khác. FE code expect consistent shape có thể tạm thời null-check. Priority P3. File: `HealthGuard/backend/src/middlewares/auth.js:85-118`.

### Performance (2/3)

- ✓ **Prisma `select`** (`auth.js:28`) — chỉ lấy 6 field cần (`id/email/role/is_active/full_name/token_version`), không `SELECT *`.
- ✓ **`findFirst` vs `findMany`** — single user lookup, expected 0-1 row, đúng method.
- ✓ Rate limiter `standardHeaders: true, legacyHeaders: false` — compliant với RFC 6585, payload nhỏ.
- ⚠️ **DB roundtrip mỗi request authenticated** (`auth.js:26-30`): R1 reference pattern accepted trade-off — đánh đổi performance để có instant revocation (token_version + is_active). Ở scale ~100 concurrent admin users: 100 DB queries/sec, acceptable cho đồ án 2 + VPS single-node. Phase 5+ khi scale → cân nhắc Redis cache user state với TTL 60s. Priority P2 (Phase 5+).
- ⚠️ **Rate limiter in-memory per-process** — `express-rate-limit` default store là memory. Nếu deploy multi-instance (PM2 cluster, K8s replica) → mỗi instance có counter riêng → user test 5 attempts ở instance A + 5 ở instance B = 10 total (bypass limit danh nghĩa 5). Đồ án 2 single-instance OK, production cần Redis store. Priority P3 (Phase 5+).
- ⚠️ **P3 — validate.js lazy require** (`validate.js:101`): `require('../utils/passwordValidator')` nằm **bên trong** handler function, không hoisted ở top file. Node cache require sau lần đầu nên impact micro, nhưng style inconsistent với các middleware khác. File: `HealthGuard/backend/src/middlewares/validate.js:101`.

## Recommended actions (Phase 4)

- [ ] **P1** — Per drift/AUTH.md Phase 4 #3: `authenticate` middleware thêm cookie fallback + CSRF check khi migration cookie hoàn thành (~phần nhỏ của 6-8h BE+FE effort).
- [ ] **P2** — `errorHandler.js` thêm map Prisma `P2003` → 409 Conflict với message "Không thể xóa do có dữ liệu liên quan" (~10 min).
- [ ] **P2** — `validate.js` thêm `min`/`max` rule cho number type (~20 min, thêm 2 branch sau type check).
- [ ] **P2** — `validate.js` thêm type `'array'` với `minItems/maxItems/itemRule` (~30 min). Hiện tại no endpoint need nhưng foundation cho Phase 4 new features.
- [ ] **P3** — Move `require('../utils/passwordValidator')` lên đầu file `validate.js` (~2 min style).
- [ ] **P3** — Replace emoji prefix trong `errorHandler.js:28` bằng `[ERROR]` prefix (~2 min rule compliance).
- [ ] **P3** — Rate limiter `message` shape thêm field `errors: []` hoặc cùng ApiResponse shape (~10 min consistency).
- [ ] **P3 (Phase 5+)** — Rate limiter dùng `rate-limit-redis` store khi multi-instance deploy.
- [ ] **P3 (Phase 5+)** — `authenticate` cache user state trong Redis TTL 60s khi scale.

## Out of scope (defer Phase 3 deep-dive)

- `sanitize-html` config exhaustive — verify no allowlist bypass (defer Phase 3 per-attack-vector audit).
- Rate limiter effectiveness load test — chạy `artillery` hoặc `k6` replay 1000 req/10s verify limit trigger 429 đúng threshold.
- JWT expiry handling trên edge case: token issued ngay trước pod restart + `token_version` mismatch race — verify Phase 3 concurrent scenario.
- `ApiError` utility class surface (`ApiError.unauthorized`, `.forbidden`, `.locked`, `.notFound`, `.badRequest`) — thuộc M07 Utils.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-01..09 decisions, đặc biệt D-AUTH-03 (token_version increment on logout — middleware đã ready), D-AUTH-04 (logout-all endpoint), D-AUTH-05 (cookie + CSRF migration).
- Phase 0.5 drift: [drift/INTERNAL.md](../../tier1.5/intent_drift/healthguard/INTERNAL.md) — D-INT-04 schema validation cho internal routes reuse `validate()` pattern.
- ADR-005: [005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — cross-repo internal auth uses `X-Internal-Service` + `X-Internal-Secret`; HealthGuard internal routes hiện có `checkInternalSecret` inline trong `internal.routes.js`, không qua M05 — xem M02 Routes audit cho finding.
- Module inventory: M05 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M01_routers_audit.md](../healthguard-model-api/M01_routers_audit.md) — compare middleware-less FastAPI vs Express middleware chain pattern.
