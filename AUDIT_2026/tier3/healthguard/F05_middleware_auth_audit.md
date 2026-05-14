# Deep-dive: F05 — middlewares/auth.js (R1 JWT + cookie fallback integration point)

**File:** `HealthGuard/backend/src/middlewares/auth.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 2 (Security foundation)

## Scope

Single file `middlewares/auth.js` (~120 LoC, 2 middleware + 3 rate limiters):
- `authenticate` (lines 11-71) — R1 reference pattern: extract Bearer token → verify JWT → DB lookup `deleted_at: null` + `is_active` + `token_version` match → gắn `req.user`.
- `requireAdmin` (lines 73-78) — check `req.user.role === 'admin'` → forbidden otherwise.
- `changePasswordLimiter` (lines 83-94) — 5 req/15min per-IP.
- `loginLimiter` (lines 96-107) — 5 req/15min per-IP.
- `forgotPasswordLimiter` (lines 109-120) — 3 req/15min per-IP.

**Out of scope:** JWT sign logic (F04 auth.service.js), rate limiter store backend (in-memory vs Redis — M05 Phase 1 flag Phase 5+), errorHandler + validate middlewares (M05 Phase 1 cover).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | R1 pattern complete: JWT verify 3 error branches (invalid/expired/unknown), DB lookup 3 check (deleted_at/is_active/token_version), req.user minimal shape. requireAdmin dependent order rõ. |
| Readability | 3/3 | 120 LoC 5 exports, JSDoc trên mọi exported fn, Vietnamese error message user-facing, English identifier. Rate limiter config object literal consistent qua 3 limiters. |
| Architecture | 3/3 | Single-responsibility: authenticate pure JWT, requireAdmin pure role check, rate limiters independent. Composable qua Express chain. DI-friendly. |
| Security | 2/3 | R1 reference pattern. Gap: Chỉ đọc `Authorization: Bearer` header, KHÔNG đọc cookie → cookie migration D-AUTH-05 cần fallback logic. Rate limit in-memory per-process (multi-instance scale lệch). Không có CSRF check (Phase 4 cookie migration cần thêm). |
| Performance | 2/3 | DB roundtrip per authenticated request (R1 trade-off accepted). Rate limit in-memory (không cross-instance sync). |
| **Total** | **13/15** | Band: **🟢 Mature** |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M05 findings (all confirmed):**

1. ✅ **R1 reference pattern** — confirmed lines 23-42 flow: jwt.verify → prisma.users.findFirst(deleted_at:null) → is_active check → token_version check → gắn req.user. Instant revocation qua token_version (synced với F04 logout+change+reset).
2. ✅ **req.user shape minimal** (lines 45-50) — `{id, email, role, full_name}` — không leak password_hash/token_version/internal fields ra downstream handler.
3. ✅ **423 Locked vs 401** (line 37) — semantic đúng cho disabled account.
4. ✅ **Rate limiter tiers** (lines 83-120) — login 5/15min, changePassword 5/15min, forgotPassword 3/15min — per-IP qua express-rate-limit + trust proxy.

**Phase 1 M05 gaps confirmed:**

5. ✅ **No cookie fallback** (lines 13-21) — Token chỉ đọc từ `Authorization: Bearer`. Drift D-AUTH-05 Phase 4 cookie migration cần add fallback.

**Phase 3 new findings (beyond Phase 1 macro):**

6. ⚠️ **JWT verify không check `aud` / `iss` claim** (line 23) — chỉ verify signature + expiry. Không validate `iss=healthguard-admin` per security guardrail steering. Priority P2 — cross-repo token forge risk.
7. ⚠️ **Rate limiter `message` shape lệch `ApiResponse`** (lines 86-90, 99-103, 112-116) — rate limiter trả `{success, statusCode, message}` không có field `errors: []` như `ApiError`. Priority P3.
8. ⚠️ **`req.user` không include `token_version`** (lines 45-50) — nếu downstream handler cần verify user state (vd logoutAll endpoint Phase 4 D-AUTH-04) → không có token_version để compare. Priority P3.
9. ⚠️ **`authenticate` DB roundtrip mỗi request** (lines 26-30) — R1 design trade-off: latency vs instant revocation. Phase 5+ cache user state Redis TTL 60s khi scale. Priority P3.
10. ⚠️ **Error branch order** (lines 60-71) — check `ApiError instanceof` trước → OK.
11. ⚠️ **`requireAdmin` không check req.user exists** (lines 74-76) — assume `authenticate` đã chạy trước. Defensive check `if (!req.user) → 401` tránh cryptic error. Priority P3.

### Correctness (3/3)

- ✓ **Token extract** (lines 13-21): `Authorization: Bearer <token>` → split → reject nếu missing/malformed.
- ✓ **JWT verify 3 branches** (lines 23, 60-70):
  - `JsonWebTokenError` → 401 invalid token.
  - `TokenExpiredError` → 401 expired.
  - Generic `ApiError` → pass-through.
  - Other → next(error) (Express 5 auto async catch).
- ✓ **DB check 3 conditions** (lines 26-42):
  - `deleted_at: null` — soft-deleted users rejected.
  - `!user.is_active` → 423 Locked.
  - `decoded.tokenVersion !== user.token_version` → 401 expired session.
- ✓ **Minimal req.user** (lines 45-50) — only 4 fields exposed downstream.
- ✓ **`requireAdmin` dependent order** (line 74 comment) — explicit pattern.

### Readability (3/3)

- ✓ JSDoc top mỗi function (lines 6-9, 73).
- ✓ Section comment mỗi step (`// 1. Lấy token`, `// 2. Verify token`, `// 3. Kiểm tra user`, `// 4. Gắn user info`) → reader scan 4 steps dễ.
- ✓ Vietnamese error messages (`'Vui lòng đăng nhập lại'`, `'Tài khoản đã bị khoá'`) — user-facing consistent.
- ✓ Rate limiter config object literal consistent (windowMs, max, message shape, standardHeaders, legacyHeaders).
- ⚠️ **P3 — 120 LoC nhưng no section divider giữa 5 exports** — reader phải scan để biết đâu là fn boundary. Priority P3 — add section comment banners.

### Architecture (3/3)

- ✓ **Single responsibility**: `authenticate` chỉ JWT + DB, `requireAdmin` chỉ role check, rate limiters độc lập.
- ✓ **Composable**: `router.post('/x', authenticate, requireAdmin, validate(rules), controller.fn)` → top-down execution order = reading order.
- ✓ **DI-friendly**: `prisma`, `env`, `ApiError` imported singleton.
- ✓ **Rate limiters export riêng**: opt-in per route, không global side effect.
- ✓ **Pattern R1** reference: instant revocation via token_version check synced với F04.

### Security (2/3)

- ✓ **R1 JWT + DB pattern** — instant revocation.
- ✓ **Rate limit tiers per-action** (login/changePassword/forgotPassword) — defense credential stuffing per-endpoint.
- ✓ **req.user minimal shape** — no leak sensitive field.
- ✓ **`trust proxy` bootstrap enable** — rate limiter per-IP accurate sau reverse proxy.
- ✓ **Error response sanitized** — Vietnamese message không leak internal detail.
- ⚠️ **P1 — No cookie fallback** (lines 13-21):
  - Token chỉ đọc từ `Authorization: Bearer` header.
  - Drift D-AUTH-05 Phase 4 cookie migration: BE set httpOnly cookie, FE không touch → middleware cần đọc `req.cookies.token` fallback.
  - Migration effort: thêm fallback sau header check; cần `cookie-parser` middleware chain (đã có trong `app.js:31`). Kèm CSRF check cho mutation endpoints (POST/PUT/PATCH/DELETE).
  - Priority P1 per drift D-AUTH-05 (~30 min BE side của 6-8h cross-file effort).
- ⚠️ **P2 — JWT không check `iss` claim** (line 23):
  - Chỉ verify signature + expiry + notBefore.
  - Nếu mobile BE (health_system) share secret (Phase 5+ concern) → mobile token với `iss=healthguard-mobile` có thể đọc được bởi admin BE nếu signature verify OK.
  - Steering `40-security-guardrails.md`: "JWT cho mobile (iss=healthguard-mobile) + admin (iss=healthguard-admin)".
  - Fix: thêm option `{ issuer: 'healthguard-admin', audience: 'healthguard-admin-web' }` cho jwt.verify. Depend F04 sign logic cần add `{ issuer }` option tương ứng.
  - Priority P2 — cross-repo token isolation.
- ⚠️ **P2 — No CSRF check** (toàn file) — Phase 4 cookie migration (D-AUTH-05) cần add CSRF check cho mutation endpoints. Middleware `csurf` hoặc double-submit cookie pattern. Priority P2 cùng group cookie migration.
- ⚠️ **P3 — Rate limit in-memory per-process** — multi-instance deploy bypass. Phase 5+ `rate-limit-redis` store.
- ⚠️ **P3 — `requireAdmin` không defensive check** (lines 74-76) — Priority P3.

### Performance (2/3)

- ✓ **Prisma `select` projection** (line 28) — 6 fields cần (id/email/role/is_active/full_name/token_version) → no wildcard.
- ✓ **`findFirst`** cho single user lookup — bounded.
- ✓ **Rate limiter `standardHeaders: true`** — RFC 6585 compliant.
- ⚠️ **P2 — DB roundtrip per authenticated request** (lines 26-30):
  - R1 trade-off: latency +~5-10ms vs instant revocation.
  - Với 100 concurrent admin users: 100 DB queries/sec — acceptable đồ án 2 single-instance.
  - Phase 5+ scale: cache user state Redis TTL 60s → balance latency vs revocation lag.
  - Priority P2 Phase 5+.
- ⚠️ **P3 — Rate limit in-memory per-process** — single-instance OK, multi-instance scale lệch. Priority P3 Phase 5+.

## Recommended actions (Phase 4)

### P1 — drift D-AUTH-05 cookie migration

- [ ] **P1** — Add cookie fallback (lines 13-21): đọc `req.cookies.token` sau header check. (~30 min BE side của cross-file cookie migration effort).

### P2 — security hardening

- [ ] **P2** — JWT verify add `issuer` option — cross-repo token isolation (lines 23, coordinate F04 sign) (~15 min).
- [ ] **P2** — Add CSRF check middleware cho mutation endpoints (cùng cookie migration) (~2h integration).
- [ ] **P2 (Phase 5+)** — Rate limiter store Redis (`rate-limit-redis`) khi multi-instance deploy.
- [ ] **P2 (Phase 5+)** — Cache user state Redis TTL 60s — balance latency vs revocation.

### P3 — cleanup + defensive

- [ ] **P3** — Add section divider comments giữa 5 exports (~10 min).
- [ ] **P3** — `requireAdmin` add defensive `if (!req.user) → 401` check (~2 min).
- [ ] **P3** — Rate limiter `message` shape align `ApiResponse` (add `errors: []`) (~5 min × 3 limiters).

## Out of scope (defer)

- Rate limiter effectiveness load test — Phase 5+ ops.
- JWT sign issuer/audience implementation (F04 side) — coordinate với F05 verify fix.
- Integration test middleware → controller → service — Phase 5+.
- Session token revocation list (alternative to token_version) — Phase 5+ research.

## Cross-references

- Phase 1 M05 audit: [tier2/healthguard/M05_middlewares_audit.md](../../tier2/healthguard/M05_middlewares_audit.md) — R1 reference pattern flagged.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-03 (token_version on logout), D-AUTH-04 (logout-all), D-AUTH-05 (cookie migration).
- F04 `auth.service.js` deep-dive — JWT sign source, coordinate issuer claim + logoutUser token_version increment.
- ADR-005: [ADR/005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — internal vs user auth isolation.
- Steering security: `.kiro/steering/40-security-guardrails.md` — JWT `iss=healthguard-admin` requirement.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** R1 reference pattern middleware — 13/15 Mature. 1 P1 gap (cookie fallback, ~30 min part của cookie migration effort) + 2 P2 gap (JWT issuer check, CSRF). Sau Phase 4 cookie migration full → 14/15 Mature consistent với F04.
