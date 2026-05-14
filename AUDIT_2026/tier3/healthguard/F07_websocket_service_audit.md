# Deep-dive: F07 — websocket.service.js (Socket.IO handshake auth + room-based emit)

**File:** `HealthGuard/backend/src/services/websocket.service.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 2 (Security foundation)

## Scope

Single file `websocket.service.js` (~210 LoC, Singleton class `WebSocketService`):
- `initialize(httpServer)` — lines 19-88. Setup Socket.IO server với CORS, auth middleware (JWT verify), connection handler, admin-room auto-join.
- `emitNewHealthAlert(alert)` — lines 93-103. Emit `health:new-alert` to `admin-room`.
- `emitRiskScoreUpdate(riskScore)` — lines 109-119. Emit `health:risk-update` to `admin-room`.
- `emitNewEmergency(emergency)` — lines 125-135. Emit `emergency:new-event` to `admin-room`.
- `emitEmergencyStatusUpdate(emergency)` — lines 141-151. Emit `emergency:status-update` to `admin-room`.
- `emitDashboardUpdate(kpiData)` — lines 157-167. Emit `dashboard:kpi-update` to `admin-room`.
- `emitToUser(userId, event, data)` — lines 171-181. Emit đến personal room `user-${userId}`.
- `getConnectedCount()`, `isUserConnected(userId)`, `getIO()` — utility methods.

**Out of scope:** Consumer-side FE hook (`useWebSocket.js` F11+), caller endpoints (F06 internal.routes.js + emergency.controller.js direct emit), Socket.IO client library behavior.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Singleton pattern ok, auth middleware verify JWT đúng (`io.use`), room-based emit scope đúng. Gap: không check user.is_active tại handshake (user locked vẫn connect được), `connectedClients` Map chứa duplicate key nếu user connect từ 2 tabs. |
| Readability | 2/3 | JSDoc mỗi method, comment UC reference (UC027/UC028/UC029). Nhưng file có 15 emoji literal trong console.log (rule violation), không có section divider giữa 8 emit methods. |
| Architecture | 2/3 | Singleton class + room-based emit pattern đúng Socket.IO best practice. Admin-room isolation tốt. Gap: CORS handshake logic duplicate với `app.js:22-29` (same reflection pattern, 2 sources), không integrate với F04 token_version check (khác R1 middleware). |
| **Security** | **1/3** | JWT verify handshake ok. Gaps: (1) CORS reflection same issue với `app.js` (drift D-AUTH-05), (2) không check token_version tại handshake → revoked token vẫn connect, (3) không check user.is_active/deleted_at → locked user connect được, (4) `emitToUser` không authorization check. |
| Performance | 3/3 | Map lookup O(1) cho `connectedClients`. Room-based emit hiệu quả. No DB call tại emit path. Handshake auth 1 JWT verify roundtrip. |
| **Total** | **10/15** | Band: **🟡 Healthy** (Security=1, không auto-Critical trigger) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M04 findings (all confirmed):**

1. ✅ **WebSocket service state** (M04 flag) — confirmed `connectedClients: Map<userId, socketId>` lines 13. Singleton class instance-level state.
2. ✅ **Handshake auth flow** (M01 + M04 flagged Phase 3 verify) — confirmed lines 38-55 `io.use` middleware verify JWT.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **Handshake KHÔNG check token_version** (lines 40-51):
   - Middleware chỉ JWT verify → extract decoded.id/userId + role.
   - KHÔNG check `decoded.tokenVersion === user.token_version` (pattern R1 F05 đã có cho HTTP requests).
   - Hệ quả: user logout (sau D-AUTH-03 fix token_version increment) → JWT cũ bị invalidate cho HTTP nhưng WebSocket connection persist → user vẫn nhận events đến JWT expiry (8h).
   - Use case: admin logout vì nghi ngờ tài khoản bị lộ → HTTP reject nhưng WebSocket stream data tiếp tục.
   - Fix: thêm `prisma.users.findFirst` tại handshake, check `token_version` match + `is_active` + rotate logic.
   - Priority P1 — security correctness.
4. ⚠️ **Handshake KHÔNG check user.is_active** (lines 40-51):
   - User bị lock (`is_active=false`) hoặc soft-delete (`deleted_at != null`) vẫn pass JWT verify nếu token còn hiệu lực.
   - Fix: cùng P1 trên — DB lookup + check is_active + deleted_at.
   - Priority P1.
5. ⚠️ **CORS reflection same issue với `app.js`** (lines 22-30):
   - Middleware `cors.origin` callback reflect any origin nếu NODE_ENV=development OR origin present.
   - Production pattern: same broken reflection với `app.js:22-29` (M01 P0 finding, drift D-AUTH-05).
   - Phase 4 cookie migration cần allowlist specific origins cho cả Socket.IO handshake.
   - Priority P1 per drift D-AUTH-05 + M01.
6. ⚠️ **`connectedClients.set(userId, socket.id)` duplicate key** (line 60):
   - Nếu user connect từ 2 tabs → tab 2 overwrite tab 1 socket.id → tab 1 mất tracking (emitToUser target tab 2 only).
   - Tab 1 vẫn joined `user-${userId}` room → nhận emit, nhưng `isUserConnected(userId)` chỉ return tab 2.
   - Fix: Map<userId, Set<socketId>> thay vì Map<userId, string>.
   - Priority P2 — minor UX issue.
7. ⚠️ **`emitToUser` không authorization check** (lines 171-181):
   - Caller có thể emit bất kỳ event với data đến user_id bất kỳ.
   - Hiện tại chỉ internal caller (`emergency.controller.js:47` direct emit) trust scope.
   - Nếu Phase 4 thêm endpoint exposed (vd admin "gửi notification manual") → cần authorization check.
   - Priority P3 — defensive.
8. ⚠️ **Dashboard KPI emit unused** (lines 157-167) — `emitDashboardUpdate` method tồn tại nhưng grep codebase: 0 caller. Dead method candidate. Verify Phase 4. Priority P3.
9. ⚠️ **Handshake không rate limit** — attacker có valid JWT → flood Socket.IO handshake → memory pressure. Drift INTERNAL D-INT-02 scope HTTP, không cover WebSocket. Priority P3.
10. ⚠️ **Connection cleanup race** (lines 75-79) — `on('disconnect', ...)` delete `connectedClients.get(userId)`. Nếu có 2 sockets từ 1 userId (P2 duplicate key issue) → delete 1 key = delete cả 2. Priority P3 fix combine với P2.
11. ⚠️ **Ping/pong thủ công** (lines 82-85) — Socket.IO v4 đã có built-in ping/pong (server → client). Ping handler `on('ping') → emit('pong')` trong source là redundant hoặc custom health check logic. Verify FE use case. Priority P3.

### Correctness (2/3)

- ✓ **Singleton pattern** (lines 12-16, 203-205): class + module.exports instance → shared state across imports.
- ✓ **Handshake auth middleware** (lines 38-55): `io.use` + JWT verify + `next(err)` — standard Socket.IO v4 pattern.
- ✓ **Room-based emit**: `admin-room` isolation + `user-${userId}` personal room.
- ✓ **Error catch handshake** (lines 49-54): JWT verify throw → `next(new Error('Invalid token'))` → client disconnect.
- ✓ **`disconnect` cleanup** (lines 75-79): `connectedClients.delete(userId)` + log reason.
- ✓ **`io === null` guard** (lines 94, 110, 126, 142, 158, 172): emit methods check trước khi gọi `this.io.to(...)`.
- ⚠️ **P1 — Handshake thiếu DB check** (lines 40-51) — no token_version check, no is_active check, no deleted_at check.
- ⚠️ **P2 — `connectedClients` duplicate key** — 2-tab user tracking broken.

### Readability (2/3)

- ✓ JSDoc top mỗi method với UC reference.
- ✓ Comment inline giải thích ý đồ (vd `// Allow all origins in development, specific in production` line 24).
- ✓ Method naming tự explain (`emitNewHealthAlert`, `emitEmergencyStatusUpdate`, `emitDashboardUpdate`).
- ⚠️ **P2 — 15 emoji literal trong console.log** (lines 58, 64, 67, 75, 87, 101, 117, 133, 149, 165, 179) — rule `00-operating-mode.md` cấm emoji trong code. Priority P2 — replace bằng `[WS]`, `[ADMIN]`, `[EMIT]` prefix.
- ⚠️ **P3 — 210 LoC no section divider giữa 8 emit methods** — reader phải scan class body để biết method boundary. Priority P3 — add section comments.

### Architecture (2/3)

- ✓ **Singleton class + singleton instance export** (lines 12, 203-205).
- ✓ **Room-based emit**: admin-room (role=admin) + user-{id} personal → isolation đúng.
- ✓ **Socket.IO v4 patterns**: `io.use` middleware, `socket.join`, `io.to(room).emit` — standard API.
- ✓ **Stateless emit methods**: không DB call tại emit path.
- ⚠️ **P2 — CORS duplicate với `app.js`** — 2 sources same config (reflection). Phase 4 unify: inject `corsOptions` từ `config/cors.js` single source, re-use cho cả Express + Socket.IO.
- ⚠️ **P2 — Không tích hợp với F04 token_version invariant** — HTTP middleware R1 check token_version, WebSocket handshake không. Phase 4 unify auth helper hoặc call shared `verifyUserState(userId, tokenVersion)` function.
- ⚠️ **P3 — `emitDashboardUpdate` dead method** — verify + remove.

### Security (1/3)

- ✓ **Handshake JWT verify** (lines 38-55) — reject nếu missing/invalid/expired token.
- ✓ **Room-based isolation**: admin-room ACL qua `socket.userRole === 'admin'` check (line 63), personal room scoped by userId.
- ✓ **`io === null` guard**: emit methods defensive.
- ⚠️ **P1 — CORS reflection production** (lines 22-30):
  - `callback(null, origin)` reflect any origin nếu NODE_ENV=development OR origin present.
  - Sau cookie migration (D-AUTH-05) → CSRF attack via WebSocket.
  - Fix: cùng fix với `app.js:22-29` — allowlist `FRONTEND_URL` + env configurable list.
  - Priority P1 per drift D-AUTH-05.
- ⚠️ **P1 — Handshake không check token_version** (lines 40-51):
  - JWT verify ok nhưng không check `decoded.tokenVersion === user.token_version`.
  - Hệ quả: logout (post-D-AUTH-03 fix) → HTTP reject nhưng WebSocket persist → user vẫn nhận events.
  - Fix: thêm DB lookup + check token_version match + is_active + deleted_at tại handshake middleware.
  - Priority P1 — coordinate với D-AUTH-03 fix cho full invalidation path.
- ⚠️ **P2 — Handshake không check user.is_active** — locked user connect được. Combine fix với P1 above.
- ⚠️ **P2 — `emitToUser` không authorization** — hiện tại internal caller trust, Phase 4 endpoint exposed cần check. Priority P2.
- ⚠️ **P3 — Handshake không rate limit** — attacker có JWT → flood. Priority P3 Phase 5+.

### Performance (3/3)

- ✓ **Map lookup O(1)** cho `connectedClients`.
- ✓ **Room-based emit**: Socket.IO internal broadcast efficient → O(N) với N = room members.
- ✓ **Emit methods sync**: no await, no DB call.
- ✓ **Singleton instance**: 1 `WebSocketService` instance cho toàn process.
- ✓ Handshake auth 1 JWT verify + 0 DB query (current, post-P1 fix sẽ +1 DB query mỗi handshake).

## Recommended actions (Phase 4)

### P1 — security correctness (drift D-AUTH-03 + D-AUTH-05)

- [ ] **P1** — Handshake add DB lookup + check token_version + is_active + deleted_at (~1h). Pattern: sau JWT verify, gọi `prisma.users.findFirst({where: {id: decoded.id, deleted_at: null}, select: {id, role, is_active, token_version}})`, kiểm tra `!user`, `!user.is_active`, `decoded.tokenVersion !== user.token_version` — mỗi fail → `next(new Error(...))`.
- [ ] **P1** — Fix CORS reflection (lines 22-30) cùng với `app.js:22-29` — allowlist specific origins. Cross-file unify qua `config/cors.js`. (~30 min).

### P2 — architecture + defensive

- [ ] **P2** — Map<userId, Set<socketId>> cho multi-tab tracking (~1h).
- [ ] **P2** — Extract `corsOptions` single source from `config/cors.js` → re-use Express + Socket.IO (~30 min).
- [ ] **P2** — Replace emoji trong console.log bằng `[WS]` prefix (~15 min).
- [ ] **P2** — `emitToUser` authorization check khi Phase 4 thêm endpoint exposed (defensive scope).
- [ ] **P2 (Phase 5+)** — Extract shared `verifyUserState(userId, tokenVersion)` helper dùng chung R1 middleware + WebSocket handshake.

### P3 — cleanup

- [ ] **P3** — Remove `emitDashboardUpdate` nếu verify 0 caller (~5 min).
- [ ] **P3** — Add section divider comments giữa 8 emit methods (~10 min).
- [ ] **P3** — Verify ping/pong handler cần thiết hay Socket.IO built-in đủ (~10 min research).
- [ ] **P3 (Phase 5+)** — Handshake rate limit khi scale (1000 connections/sec limit).

## Out of scope (defer)

- Socket.IO Redis adapter cho multi-instance horizontal scale — Phase 5+ ops.
- Graceful disconnect on server shutdown (SIGTERM handler) — Phase 5+ ops.
- WebSocket connection metrics (Prometheus) — Phase 5+ ops.
- Client-side reconnect strategy — FE scope (F11+ useWebSocket hook).
- Event payload schema validation (vd `alert` shape must match ApiResponse) — Phase 5+ contract testing.

## Cross-references

- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — websocket state flag + M01 handshake auth verify.
- Phase 1 M01 audit: [tier2/healthguard/M01_bootstrap_audit.md](../../tier2/healthguard/M01_bootstrap_audit.md) — HTTP server attach Socket.IO same port, CORS reflection flag.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-03 (token_version on logout) + D-AUTH-05 (cookie migration + CSRF).
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/INTERNAL.md](../../tier1.5/intent_drift/healthguard/INTERNAL.md) — `emit*` caller from F06 internal routes.
- F04 `auth.service.js` deep-dive — JWT sign source, token_version state.
- F05 `middlewares/auth.js` deep-dive — HTTP middleware R1 pattern counterpart.
- F06 `internal.routes.js` deep-dive — caller của emit methods.
- Caller: `controllers/emergency.controller.js:47` — direct emit khi admin update status.
- Caller: `jobs/risk-score-job.js:45-50` — emit risk score update post batch calc.
- Precedent format: [tier3/healthguard-model-api/F1_fall_service_audit.md](../healthguard-model-api/F1_fall_service_audit.md) — tier3 deep-dive format.

---

**Verdict:** WebSocket service functional nhưng security gap đáng kể — 10/15 Healthy band (Security=1). Phase 4 cần 2 fix P1 cohesive với drift D-AUTH-03 + D-AUTH-05: (a) handshake DB check (1h), (b) CORS allowlist (30 min cùng `app.js` fix). Sau Phase 4 → 13/15 Mature (Security=3).
