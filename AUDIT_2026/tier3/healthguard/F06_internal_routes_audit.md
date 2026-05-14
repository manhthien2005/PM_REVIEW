# Deep-dive: F06 — internal.routes.js (D-INT-01 fix verification point)

**File:** `HealthGuard/backend/src/routes/internal.routes.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 2 (Security foundation)

## Scope

Single file `internal.routes.js` (~120 LoC):
- `checkInternalSecret` middleware (lines 9-23) — read `X-Internal-Secret` header, compare với env. Fallback literal if env missing — root cause Phase -1 D-011 + drift D-INT-01.
- `POST /websocket/emit-alert` (lines 30-55) — body `{alert: {id, ...}}`, delegate websocketService.emitNewHealthAlert.
- `POST /websocket/emit-emergency` (lines 57-90) — body `{emergency: {id, ...}}`, delegate websocketService.emitNewEmergency.
- `POST /websocket/emit-risk` (lines 91-120) — body `{riskScore: {userId, ...}}`, delegate websocketService.emitRiskScoreUpdate.

**Out of scope:** WebSocket service internals (F07 deep-dive), cross-repo caller authentication (pump scripts, IoT sim), model API internal secret pattern (tier2 healthguard-model-api M01 cover).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | 3 endpoints đều validate body.{entity}.id tối thiểu, try/catch + 500 response, delegate đúng service. Gap: không validate schema đầy đủ (severity enum, timestamp format, user_id FK), error body leak error.message. |
| Readability | 2/3 | JSDoc mỗi endpoint, Vietnamese comment inline. Nhưng `emit-risk` định nghĩa 2 lần (1 comment placeholder line 58 + thực tế line 91) — reader confuse. 120 LoC chấp nhận được. |
| Architecture | 2/3 | Middleware applied `router.use` — scope rõ. Nhưng: mount `app.js:40-43` inline thay vì qua `routes/index.js` (cross-file inconsistency flagged M02); internal emit endpoints trùng scope với `emergency.controller.js:47` direct emit — 2 paths cho cùng event. |
| **Security** | **0/3** | 🚨 D-INT-01 CRITICAL: fallback literal line 13 — nếu env missing → trivial auth bypass. Framework v1 anti-pattern auto-flag "hardcoded secret literal trong source". Cộng: error leak, no rate limit, no audit log, no schema validate. |
| Performance | 3/3 | Delegate WebSocket emit sync (non-blocking), không DB call. No N+1. Response 4 fields max. |
| **Total** | **9/15** | Band: **🔴 Critical** (Security=0 auto-Critical per framework v1 anti-pattern list) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M02 findings (all confirmed):**

1. ✅ **D-INT-01 internal secret fallback literal** (line 13) — confirmed. Root cause flagged Phase -1 D-011 + drift INTERNAL D-INT-01. Phase 4 fix: remove fallback + add INTERNAL_SECRET vào `config/env.js` required array.
2. ✅ **Mount inline trong app.js:40-43** — confirmed, không qua `routes/index.js` → cross-file inconsistency. M02 flagged.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **Error response leak `error.message`** (lines 52, 82, 115):
   - `console.error('Error emitting WebSocket:', error)` + `res.status(500).json({ success: false, message: error.message })`.
   - Nếu error message chứa internal path, stack trace fragment, Prisma query → leak attack surface.
   - Drift INTERNAL D-INT-06 Phase 4 fix: replace error.message → generic message + trace via requestId in logs.
   - Priority P1 per drift D-INT-06.
4. ⚠️ **Duplicate `emit-risk` definition** — lines 58 comment placeholder rồi lines 91-120 redefine endpoint. Reader confuse. Verify runtime: Express last-defined wins → lines 91-120 active, lines 58 dead comment. Priority P3 — cleanup.
5. ⚠️ **No schema validation** (all 3 endpoints) — chỉ check `alert/emergency/riskScore.id` tồn tại. Không validate:
   - `alert.severity` enum (low/medium/high/critical — drift ADR-015 taxonomy).
   - `alert.user_id` FK tồn tại.
   - `emergency.type` enum (Fall/SOS).
   - `emergency.trigger_type` enum (auto/manual).
   - `riskScore.risk_level` enum (post-D-HEA-07 3 levels).
   - Timestamp format ISO 8601.
   - Drift INTERNAL D-INT-04 Phase 4 fix: Add `validate()` middleware với schema cho 3 endpoints.
   - Priority P1 per drift D-INT-04.
6. ⚠️ **No rate limit** — 3 endpoints không có `rate-limit-express` middleware. Attacker có secret → flood admin FE với fake alerts.
   - Drift INTERNAL D-INT-02 Phase 4 fix: Add `rate-limit-express` 1000 req/min per-IP.
   - Priority P1 per drift D-INT-02.
7. ⚠️ **No audit log internal calls** — Phase -1 D-INT-03 flag: internal endpoints không ghi `audit_logs`. Admin không trace được ai gọi, khi nào, từ đâu.
   - Drift INTERNAL D-INT-03 Phase 4 fix: Add audit log per internal call (action='internal.emit_alert/emergency/risk', user_id=null system action).
   - Priority P1 per drift D-INT-03.
8. ⚠️ **Body validate tối thiểu** (lines 37-42, 65-70, 97-102) — chỉ `!alert || !alert.id` check. Không check type, không check required fields khác. Priority P2 — cover qua `validate()` middleware D-INT-04.

### Correctness (2/3)

- ✓ **Middleware `checkInternalSecret` apply `router.use`** (line 25) — scope toàn file, không phải per-route.
- ✓ **Error → 403 forbidden** (lines 16-21) — semantic đúng cho auth fail.
- ✓ **`websocketService` delegate** (lines 47, 79, 111) — thin route, không chứa business logic.
- ✓ **Try/catch wrap** — không crash Express handler nếu WebSocket emit throw.
- ✓ **Body minimal validate** (lines 37-42, 65-70, 97-102) — reject nếu thiếu id.
- ⚠️ **P3 — `emit-risk` duplicate** (lines 58 comment vs 91-120 actual) — cleanup.

### Readability (2/3)

- ✓ JSDoc comment mỗi endpoint với path + purpose.
- ✓ Vietnamese comment inline — convention match.
- ✓ Error message consistent shape `{success: false, message: '...'}`.
- ⚠️ **P3 — `emit-risk` duplicate define comment + actual** — reader confuse.
- ⚠️ **P3 — Error message inline literal** — scattered across handlers. Extract constants top file giúp consistency. Priority P3.

### Architecture (2/3)

- ✓ **Middleware centralized `router.use(checkInternalSecret)`** (line 25).
- ✓ **Thin delegate** → `websocketService.emit*` (F07).
- ⚠️ **P2 — Mount inline `app.js:40-43`** (M02 flagged) — không qua `routes/index.js`. Phase 4 coordinate ADR-004 API prefix work.
- ⚠️ **P2 — Duplicate scope với `emergency.controller.js`** (line 47 `websocketService.emitEmergencyStatusUpdate` internal call). Khi admin update status → controller emit trực tiếp. Pump script emit qua `POST /internal/websocket/emit-emergency`. 2 paths cho cùng event nhưng semantic khác (admin action vs external ingest). Document boundary rõ trong UC027 v2 hoặc ADR Phase 4.
- ⚠️ **P3 — `checkInternalSecret` inline trong route file** thay vì thuộc `middlewares/` folder. Nếu Phase 4 reuse cho endpoints khác → move sang `middlewares/internalAuth.js`. Priority P3.

### Security (0/3) — 🚨 Auto-Critical

**⚠️ P0 CRITICAL — D-INT-01 internal secret fallback literal** (line 13):

- Middleware `checkInternalSecret` có pattern `process.env.INTERNAL_SECRET || <literal-fallback>` — nếu deploy quên set env → fallback literal → trivial auth bypass.
- Framework v1 anti-pattern auto-flag: "hardcoded secret trong source code" → Security = 0 auto-Critical.
- Phase -1 D-011 + drift INTERNAL D-INT-01 quyết định Phase 4 fix:
  - Remove fallback: `const expectedSecret = process.env.INTERNAL_SECRET;`.
  - `config/env.js:28` required array add `'INTERNAL_SECRET'` → fail-fast startup.
  - `.env.example` document generate command.
  - Cross-repo coordinate: model API M04 same pattern, IoT sim sleep AI client missing secret header (D-020).
- Priority P0 per drift D-INT-01 (~15 min route side + `env.js` line).

**⚠️ P1 — D-INT-06 error response leak** (lines 52, 82, 115):

- `res.status(500).json({ success: false, message: error.message })` — leak internal error detail.
- Fix (per drift D-INT-06): replace → generic message + log `error.stack` server-side với requestId.
- Priority P1 per drift (~30 min × 3 endpoints).

**⚠️ P1 — D-INT-02 no rate limit** — attacker có secret → flood. Fix add `rate-limit-express` 1000 req/min per-IP. Priority P1 per drift (~30 min).

**⚠️ P1 — D-INT-03 no audit log** — not trace internal trigger. Fix add `logsService.writeLog({action: 'internal.emit_alert', ...})` sau mỗi emit. Priority P1 per drift (~30 min).

**⚠️ P1 — D-INT-04 no schema validate** — body check tối thiểu id. Fix add `validate()` middleware với schema đầy đủ. Priority P1 per drift (~1h).

**⚠️ P2 — No IP allowlist** — production scope, không phải đồ án 2. Defer Phase 5+ per drift D-INT-02.

### Performance (3/3)

- ✓ **Delegate WebSocket emit sync** — no DB call, no N+1.
- ✓ Response body 2-3 fields.
- ✓ Middleware `checkInternalSecret` O(1) compare.
- ✓ Không có async/await blocking.

## Recommended actions (Phase 4)

### P0 CRITICAL — D-INT-01 fix (cross-repo coord)

- [ ] **P0** — Remove fallback line 13 (~5 min).
- [ ] **P0** — `config/env.js:28` thêm `'INTERNAL_SECRET'` vào required array (~2 min).
- [ ] **P0** — `.env.example` document generate command (~5 min).
- [ ] **P0 (cross-repo)** — Coordinate model API D-013 fix + IoT sim D-020 fix (add required headers).

### P1 — drift INTERNAL D-INT-02/03/04/06

- [ ] **P1** — Add rate limit middleware 1000 req/min per-IP (~30 min).
- [ ] **P1** — Add audit log mỗi internal call (action='internal.emit_alert/emergency/risk') (~30 min).
- [ ] **P1** — Add `validate()` middleware với schema cho 3 endpoints (severity enum, FK exists, timestamp ISO) (~1h).
- [ ] **P1** — Sanitize error response: replace `error.message` → generic message + requestId trong logs (~30 min × 3 endpoints).

### P2 — architecture cleanup

- [ ] **P2** — Mount route qua `routes/index.js` thay vì `app.js:40-43` inline — coordinate ADR-004 API prefix (~15 min, per M02).
- [ ] **P2** — Document boundary: 2 paths `emergency.controller.js` direct emit vs `POST /internal/websocket/emit-emergency` pump script emit — UC027 v2 hoặc ADR Phase 4 (~30 min doc).
- [ ] **P2 (Phase 5+)** — IP allowlist via env.

### P3 — cleanup

- [ ] **P3** — Remove duplicate `emit-risk` comment/placeholder lines 58 (~2 min).
- [ ] **P3** — Extract error message literals → constants top file (~15 min).
- [ ] **P3** — Move `checkInternalSecret` sang `middlewares/internalAuth.js` nếu reuse (~10 min).

## Out of scope (defer)

- Health check endpoint (`/internal/health`) — drop per drift D-INT add-ons.
- Idempotency-Key header — Phase 5+ ops.
- API versioning split `/internal/v1/*` — minor, defer.
- Metrics Prometheus endpoint — Phase 5+ ops.

## Cross-references

- Phase 1 M02 audit: [tier2/healthguard/M02_routes_audit.md](../../tier2/healthguard/M02_routes_audit.md) — D-INT-01 + mount inline flag.
- Phase -1 finding: [phase_minus_1_summary.md](../../phase_minus_1_summary.md) — D-011 `/internal/*` no secret check (resolved via drift D-INT-01).
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/INTERNAL.md](../../tier1.5/intent_drift/healthguard/INTERNAL.md) — D-INT-01..06 full backlog Phase 4.
- ADR-005: [ADR/005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — cross-repo internal auth contract.
- F07 `websocket.service.js` deep-dive — emit method consumer, handshake auth.
- M01 Bootstrap audit: [tier2/healthguard/M01_bootstrap_audit.md](../../tier2/healthguard/M01_bootstrap_audit.md) — `env.js` required array + mount inline finding.
- Cross-repo similar pattern: [tier2/healthguard-model-api/M01_routers_audit.md](../healthguard-model-api/M01_routers_audit.md) — D-013 predict endpoints no internal secret, same fallback issue.
- Cross-repo consumer: `Iot_Simulator_clean/simulator_core/fall_ai_client.py` — missing `X-Internal-Service` header (D-020), fix simultaneously.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** D-INT-01 Security=0 auto-Critical — 9/15 Critical band. Phase 4 cross-repo coord (~4h total: HealthGuard 15 min + model API 15 min + IoT sim 30 min + env.js require + ADR-005 doc). Sau fix + rate limit + validate + audit log + sanitize error → ~14/15 Mature.
