# Audit: M01 — Bootstrap (app entry + server + config)

**Module:** `HealthGuard/backend/src/{app.js, server.js, config/env.js, config/swagger.js}`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

- `app.js` (~70 LoC) — Express app factory, middleware chain, route mounting, SPA fallback, error handler
- `server.js` (~36 LoC) — HTTP server, WebSocket init, Vital Processor + Risk Score Job start, listen callback
- `config/env.js` (~36 LoC) — dotenv load, typed env object, required vars fail-fast
- `config/swagger.js` (~1693 LoC) — OpenAPI 3.0 spec object (data-only, no logic)

**Out of scope:** individual route handlers (M02), WebSocket protocol semantics (M04), job internals (M07). Swagger spec **nội dung** (path + schema definitions) defer Phase 3 contract review — scope hiện tại chỉ chấm việc wire-up Swagger vào app.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Healthcheck first, errorHandler last, 404 catch-all OK. CORS reflection + Internal routes mounted inline tách rời `routes/index.js` giảm 1 điểm. |
| Readability | 3/3 | File ngắn, section comments rõ, env object typed, imports gom đầu. |
| Architecture | 2/3 | app vs server split đúng. 3 nit: internal routes mount inline trong app.js; `fs.existsSync` + static serve mixed với route wiring; `env.js` `process.exit(1)` trong module-level require (fail-fast OK nhưng couple). |
| **Security** | **1/3** | CORS reflection + credentials=true (drift AUTH P0), không helmet (drift AUTH P1), Swagger `/admin-docs` public (new P2), internal secret fallback trong `internal.routes.js` (drift INTERNAL D-INT-01 P0 — bootstrap phải fail-fast). |
| Performance | 3/3 | Bootstrap không có hot path. `trust proxy 1` đúng cho rate-limit downstream. 10mb JSON limit permissive nhưng không block. |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (2/3)

- ✓ `app.get('/health')` đặt đầu tiên, skip toàn bộ middleware chain (`app.js:18-20`) — healthcheck nhanh, đúng precedent.
- ✓ `errorHandler` đăng ký cuối cùng sau catch-all 404 (`app.js:66-68`) — Express 5 async error propagation đúng thứ tự.
- ✓ `BigInt.prototype.toJSON = toString` patch ở module top (`app.js:12-14`) — fix Prisma BigInt serialize, global nhưng cần thiết cho `alerts.id`/`audit_logs.id`.
- ✓ `trust proxy = 1` (`app.js:17`) — `express-rate-limit` dùng `req.ip` từ `X-Forwarded-For` đúng, không bị đếm theo proxy IP.
- ✓ `server.js:11-16` tạo `http.Server` wrap Express để Socket.IO attach — pattern chuẩn cho WebSocket + HTTP chung port.
- ✓ `config/env.js:27-32` fail-fast nếu thiếu `DATABASE_URL` hoặc `JWT_SECRET` — prevent startup với state sai.
- ⚠️ `app.js:43` mount `require('./routes/internal.routes')` inline thay vì qua `routes/index.js` → duplicate wiring pattern, dễ miss khi refactor prefix (xem Architecture finding). Không phải bug correctness nhưng cross-module consistency giảm.
- ⚠️ `server.js:25-34` start Vital Processor + Risk Score Job trong `listen` callback **không `await`** — nếu job start throw → crash chỉ in `console.log`, process vẫn listen HTTP. Currently both jobs là fire-and-forget sync start → OK nhưng defense-in-depth nên có try/catch wrapper. Priority P3.

### Readability (3/3)

- ✓ File `app.js` chỉ ~70 LoC, section comments (CORS, SPA, error handler) đủ nhưng không thừa.
- ✓ `config/env.js` export 1 object typed rõ — reader scan 1 lượt biết toàn bộ env surface.
- ✓ Imports gom đầu mỗi file, không lazy-require ở runtime path.
- ✓ Vietnamese comment trong code = trung tính (vd `// Internal API routes (for scripts, no /admin prefix)`) — không vi phạm rule English code vì comment chứ không phải identifier.
- ⚠️ `server.js:20-24` template string startup banner trộn emoji (✅🚫💡) trong `console.log` literal — rule workspace `00-operating-mode.md` cấm emoji trong code/commit/PR. Log output không phải code nhưng literal string nằm trong source → khi grep log dễ miss. Priority P3 cosmetic.

### Architecture (2/3)

- ✓ `app.js` chỉ wire middleware + routes, `server.js` chỉ listen + start jobs — tách đúng 2 vai trò (app factory vs process runner).
- ✓ `config/env.js` là single source of truth cho env → service/middleware không đọc `process.env` trực tiếp.
- ⚠️ **Internal routes mount inline trong app.js:40-43** thay vì qua `routes/index.js`. Hệ quả: nếu Phase 4 thay prefix `/api/v1/internal` → phải sửa 2 nơi (app.js + internal.routes.js). `routes/index.js` hiện chỉ gom `admin/*` routes, tạo split không đồng nhất. Priority P2 — fix cùng Phase 4 ADR-004 (API prefix standardization).
  - File: `HealthGuard/backend/src/app.js:40-43`, `HealthGuard/backend/src/routes/index.js`
- ⚠️ **SPA fallback logic mixed với route wiring** (`app.js:49-58`). `fs.existsSync` runtime check + `express.static` + wildcard catch-all trộn chung khu vực routing. Nếu FE build artifact vắng mặt → silently skip SPA serving không log. Priority P3.
- ⚠️ `env.js` thực hiện `process.exit(1)` tại `require` time (`config/env.js:30-32`) — side effect trong module boundary. Acceptable fail-fast pattern nhưng làm unit test của bất kỳ module nào require env phải mock env đầy đủ. Priority P3.

### Security (1/3)

**⚠️ P0 — CORS reflection + credentials=true** (`app.js:22-29`):

- `origin` callback reflect bất kỳ origin nào được gửi kèm request về `Access-Control-Allow-Origin`, kết hợp `credentials: true` → tương đương CORS `*` với credentials (OWASP anti-pattern).
- Hiện tại FE dùng `Authorization: Bearer` trong localStorage nên CSRF surface thấp. Sau khi cookie migration (drift AUTH D-AUTH-05), reflection pattern này sẽ enable CSRF attack toàn cục.
- **Drift:** see drift/AUTH.md Q5 (D-AUTH-05) — quyết định Phase 4 cookie + CSRF migration, CORS phải allowlist cụ thể trước.
- **Action:** per drift/AUTH.md Phase 4 backlog #1 (CORS fix ~30 min).

**⚠️ P1 — Thiếu `helmet` middleware** (`app.js` toàn bộ):
- Không có `app.use(helmet())` → thiếu các header bảo vệ: `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`, `Content-Security-Policy`, `Referrer-Policy`.
- **Drift:** see drift/AUTH.md Phase 4 backlog #2 (add helmet ~30 min).

**⚠️ P0 — Bootstrap thiếu required check cho `INTERNAL_SECRET`** (cross-module, `config/env.js:28`):
- `app.js:42` mount internal routes; middleware `checkInternalSecret` trong `internal.routes.js:9-23` có fallback literal nếu `process.env.INTERNAL_SECRET` không set.
- Nếu production deploy quên set env → fallback literal được dùng → trivial auth bypass.
- Bootstrap chịu trách nhiệm enforce fail-fast nhưng `config/env.js:28` chỉ required `['DATABASE_URL', 'JWT_SECRET']` — thiếu `INTERNAL_SECRET`.
- **Drift:** see drift/INTERNAL.md D-INT-01 — quyết định Phase 4 remove fallback + add vào required list.
- **Action:** per drift/INTERNAL.md — bootstrap side cần thêm `INTERNAL_SECRET` vào `required` array trong `env.js`.

**⚠️ P2 — Swagger UI `/admin-docs` public** (`app.js:37-39`):
- `swaggerUi.serve + setup` không kèm auth middleware → bất kỳ ai truy cập port 3000 có thể xem toàn bộ endpoint catalog (~1693 LoC OpenAPI spec) bao gồm request/response schema, error codes.
- Information disclosure: endpoint discovery + field-level schema leak (PII columns, internal IDs).
- Mitigations hiện có: actual endpoints protected by JWT → attacker không exploit được discovery alone. Nhưng giảm attack surface = security posture tốt hơn.
- **Action (new, không drift-flagged):** Phase 5+ — gate Swagger bằng `authenticate + requireAdmin` (hoặc env flag `SWAGGER_ENABLED=false` trong production). Acceptable scope đồ án 2.
- File: `HealthGuard/backend/src/app.js:37-39`

**⚠️ P3 — JSON body limit 10mb permissive** (`app.js:32`):
- `express.json({ limit: '10mb' })` cao so với admin API (typical POST user/device ≤ 10KB).
- Rationale tiềm năng: R2 artifact upload proxy? Verify Phase 3 `services/r2.service.js` upstream call chain.
- Nếu R2 upload stream trực tiếp → hạ limit về 1mb. Nếu proxy qua BE → giữ 10mb.
- File: `HealthGuard/backend/src/app.js:32`

### Performance (3/3)

- ✓ Bootstrap không chứa hot path — mọi request flow qua `app.js` middleware chain rồi đi xuống route handler, không có sync work ở app level.
- ✓ `trust proxy = 1` cho rate-limit per-IP chính xác khi chạy sau reverse proxy (Cloudflare, Nginx).
- ✓ `server.js` WebSocket init + jobs start sau khi `listen` callback fire → không block listen.
- ✓ `cookie-parser`, `express.json`, `express.urlencoded` đúng thứ tự, không redundant middleware.
- ⚠️ JSON limit 10mb — tiềm năng memory pressure nếu attacker gửi 10mb body lặp lại (no request timeout at bootstrap layer). Rate limit tại route-level giảm rủi ro. Priority P3.

## Recommended actions (Phase 4)

- [ ] **P0** — Per drift/AUTH.md Phase 4 #1: Fix CORS reflection → allowlist `FRONTEND_URL` + `.env` configurable list (~30 min).
- [ ] **P0** — Per drift/INTERNAL.md D-INT-01: Thêm `INTERNAL_SECRET` vào `env.js` required array + remove hardcode fallback trong `internal.routes.js` (~15 min bootstrap side).
- [ ] **P1** — Per drift/AUTH.md Phase 4 #2: Add `helmet()` ở đầu middleware chain (~30 min).
- [ ] **P2** — Move `internal.routes.js` mount qua `routes/index.js` (hoặc giữ inline nhưng comment lý do) để unify routing architecture — coordinate với ADR-004 API prefix work.
- [ ] **P2** — Gate Swagger UI bằng env flag `SWAGGER_ENABLED` hoặc `authenticate + requireAdmin` middleware (~30 min).
- [ ] **P3** — Verify JSON body limit 10mb cần thiết (R2 proxy?) hoặc hạ xuống 1mb (Phase 3 depth review).
- [ ] **P3** — Try/catch wrap `vitalProcessor.start()` + `riskScoreJob.start()` trong `server.js:27-34` để không crash silent nếu job init throw.
- [ ] **P3** — Xóa dead redirect `/api-docs` và `/api-doc` → `/admin-docs` nếu không còn external link pointing tới (grep FE `main.jsx`, docs verify).
- [ ] **P3** — Replace emoji trong `server.js` startup banner + `errorHandler.js` `console.error` bằng text prefix ("[OK]", "[BLOCKED]") để tuân thủ rule no-emoji-in-code.

## Out of scope (defer Phase 3 deep-dive)

- Swagger spec **nội dung** accuracy (path/method match thật không, request/response schema reflect Prisma model không) — cần cross-check từng endpoint vs controller, quá chi tiết cho macro audit.
- `websocket.service.initialize` handshake auth flow — thuộc M04 Services.
- `vitalProcessor.start()` scheduler logic, idempotency, time drift — thuộc M07 Jobs.
- `riskScoreJob.start()` cron cadence + per-user calc — thuộc M07 Jobs.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-05 cookie migration + CORS fix (P0), M01 F1 + F2 elevated to Phase 4 #1 + #2.
- Phase 0.5 drift: [drift/INTERNAL.md](../../tier1.5/intent_drift/healthguard/INTERNAL.md) — D-INT-01 internal secret fallback (P0 Critical, cross-repo ADR candidate).
- Phase -1 findings: [phase_minus_1_summary.md](../../phase_minus_1_summary.md) — D-011 `/internal/*` no secret check (resolved via drift D-INT-01).
- ADR-004: [004-api-prefix-standardization.md](../../../ADR/004-api-prefix-standardization.md) — rationale cho `/api/v1/{domain}/*` prefix.
- ADR-005: [005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — cross-repo internal auth contract.
- Module inventory: M01 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M04_bootstrap_audit.md](../healthguard-model-api/M04_bootstrap_audit.md) — CORS reflection cross-repo pattern.
