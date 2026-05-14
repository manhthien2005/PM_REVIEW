# Audit: M12 — Frontend Services + Hooks + Utils

**Module:** `HealthGuard/frontend/src/{services, hooks, utils}/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1B (HealthGuard frontend)

## Scope

- `services/api.js` (~25 LoC) — `apiFetch` wrapper + auto logout on 401/403
- `services/authService.js` (~110 LoC) — login/logout/forgot/reset/changePassword/verifyToken + getUser/isAuthenticated helpers
- `services/{userService,deviceService,emergencyService,healthService,logsService,dashboardService,relationshipService,aiModelService}.js` — 8 domain API wrappers (~50-100 LoC each)
- `hooks/useWebSocket.js` (~200 LoC) — Socket.IO connection + on/off/emit + auto-reconnect
- `hooks/useAIModelsManager.js` — AI models state management hook (Phase 3 deep-dive scope)
- `utils/dateUtils.js` (~175 LoC) — Vietnam timezone format helpers
- `utils/passwordValidator.js` (~195 LoC) — frontend strength validator (mirror backend)

**Out of scope:** `useAIModelsManager.js` deep review (Phase 3), individual service method parameter audit (Phase 3 per-endpoint).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | `api.js` auto logout on 401/403 đúng. Services delegate URL correctly với URLSearchParams. dateUtils Vietnam timezone format đúng. passwordValidator mirror backend rule. useWebSocket reconnect logic + cleanup effect đúng. |
| Readability | 3/3 | Files ngắn (services 50-100 LoC each, utils 175-195 LoC), JSDoc đầy đủ, Vietnamese error map helper, naming clear. |
| Architecture | 2/3 | `api.js` single source cho API base + auth header injection. 8 domain services split by domain. Hooks extract logic đúng. Gap: `api.js` không handle retry on network fail, không abort on unmount, không throw typed error. |
| **Security** | **0/3** | `api.js` + `authService.js` đọc/ghi localStorage cho session state (same P0 như M09). `useWebSocket` pass session value qua handshake auth depend localStorage. Framework v1 auto-flag. |
| Performance | 2/3 | `apiFetch` không cache, không dedupe — nếu 3 components same page fetch same endpoint → 3 network call. `useWebSocket` connection instance stable (ref). |
| **Total** | **9/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Correctness (2/3)

- ✓ `api.js:3-24` `apiFetch` pattern chuẩn: read session value từ localStorage → attach header → parse JSON → auto logout khi 401/403 (except `/auth/login`).
- ✓ `api.js:17-21` auto logout + redirect `/login` khi session stale → UX đúng.
- ✓ `authService.js:13-14` login success → persist session state. Logout → clear.
- ✓ `authService.js:46-60` `verifyToken` defense: nếu không có user → skip call; nếu call throw → logout cleanup.
- ✓ `authService.js:95-112` `getErrorMessage` helper với Vietnamese map theo BE error code → consistent i18n.
- ✓ Services dùng `URLSearchParams` build query string (vd `healthService.js:32-41`) — safe vs manual string concat.
- ✓ `dateUtils.js` helpers (`formatVietnamDateTime`, `formatVietnamDate`, `formatVietnamTime`, `formatRelativeTime`) — đều có null check + NaN check đầu function → defensive.
- ✓ `dateUtils.js:5, 29, 49, 68` — early return `'—'` cho invalid input → render không crash.
- ✓ `passwordValidator.js:18-22` mirror backend rule: minLength 8 user / 12 admin; max 128 DoS prevent.
- ✓ `passwordValidator.js:28-48` requirement array cho UI render (checkmark/cross per rule) + errors array cho error message display. Hai shape support 2 UX pattern.
- ✓ `useWebSocket.js:20-107` connect/disconnect/on/off/emit/ping API surface — clean. useRef cho socket + reconnect timeout → không re-render storm.
- ✓ `useWebSocket.js:161-178` cleanup effect xóa listener + disconnect on unmount — no memory leak.
- ⚠️ **P2 — `api.js:9-13` hardcode `Content-Type: application/json`** — nếu caller send FormData (multipart upload, vd AI model artifact) → header conflict + browser không set boundary. Verify `services/aiModelService.js` upload method có override header hay không. Priority P2.
  - File: `HealthGuard/frontend/src/services/api.js:9-13`
- ⚠️ **P2 — `api.js` không abort controller** — nếu component unmount trong lúc fetch pending → setState on unmounted warning. Add `AbortController` support. Priority P2.
- ⚠️ **P3 — `useWebSocket.js:31-32` `VITE_API_BASE_URL` fallback to `window.location.origin`** — production cần explicit env, dev fallback OK. Priority P3 — document.

### Readability (3/3)

- ✓ JSDoc comment trên mọi exported function. Reader biết param/return shape.
- ✓ Files ngắn gọn → scan 1 lượt hiểu.
- ✓ `authService.js` divider comments chia 9 section → section nav dễ.
- ✓ `dateUtils.js` Vietnamese timezone naming clear.
- ✓ `useWebSocket.js` divider comments + JSDoc trên mọi method export → hook surface dễ consume.
- ⚠️ **P2 — Emoji trong source** (`useWebSocket.js:20, 35, 38, 44, 52, 58, 70, 75, 80, 87, 93, 99, 112, 126, 138, 153, 159`) — rule workspace `00-operating-mode.md` cấm emoji trong code. Priority P2 — replace bằng `[WS]` prefix.

### Architecture (2/3)

- ✓ **Single source of truth** cho API base URL + auth header injection (`api.js:2-13`) — không duplicate ở mỗi service.
- ✓ 8 domain services tách riêng → scale tốt, không god-service.
- ✓ `useWebSocket` hook encapsulate Socket.IO — components consume via interface, không touch socket instance.
- ✓ `dateUtils` + `passwordValidator` là pure function modules — test + reuse dễ.
- ⚠️ **P2 — `api.js` thiếu retry/dedupe/cache** — modern FE stack dùng SWR hoặc TanStack Query cho data fetching. Priority P2 Phase 5+ — add TanStack Query wrapper.
- ⚠️ **P2 — `api.js` không throw typed error** — caller nhận `body`. Không rõ khi nào throw. Caller phải check `result.success` thủ công. Priority P2 — throw `ApiError` class giống BE + use custom hook.
- ⚠️ **P3 — Service methods chỉ wrapper `apiFetch(url)` one-liner** — scope nhỏ chấp nhận.
- ⚠️ **P3 — `hooks/useAIModelsManager.js`** defer Phase 3 deep-dive — MLOps mock (ADR-006) nên complex logic ở đây.

### Security (0/3) — 🚨 Auto-Critical

**⚠️ P0 — Client-side session storage trong localStorage** (`api.js:4, authService.js:13-14, useWebSocket.js:22`):

- `api.js:4` read session value từ localStorage cho mỗi request.
- `authService.js:13-14` write session state vào localStorage khi login.
- `useWebSocket.js:22` read session value từ localStorage cho Socket.IO handshake auth.
- **Framework v1 anti-pattern auto-flag**: "Token nhạy cảm trong localStorage" → Security = 0 auto-Critical.
- **Steering React rule** `.kiro/steering/24-react-vite.md` explicit cấm client-side JWT storage.
- **Drift AUTH D-AUTH-05** Phase 4 migrate httpOnly cookie + CSRF. Priority P0 per drift (~6-8h BE+FE coord, em đã ghi ở M09 audit).
- Files: `HealthGuard/frontend/src/services/api.js:4`, `authService.js:13-14, 23-24, 46`, `useWebSocket.js:22`

**⚠️ P2 — `api.js` không verify response shape** — nếu BE response corrupt → `body.success` có thể undefined → caller đi nhầm path. Priority P2 — add zod schema validation at client boundary.

**⚠️ P3 — `authService.js:26-28` `logout` fire-and-forget call BE** — clear localStorage trước, gọi BE logout (audit log) sau. Network fail → token_version không increment (drift AUTH D-AUTH-03 Phase 4). Acceptable trade-off. Priority P3.

### Performance (2/3)

- ✓ `api.js` một fetch per call — no middleware overhead.
- ✓ `useWebSocket` socket instance stable (useRef) — không reconnect per render.
- ✓ `dateUtils` pure functions — no state, fast.
- ✓ `passwordValidator` 5-6 regex match — O(n) với n = input length.
- ⚠️ **P2 — No request cache / dedupe** (duplicate Architecture finding) — 3 components fetch same endpoint = 3 network call. Priority P2 Phase 5+.
- ⚠️ **P2 — `apiFetch` parse JSON unconditional** (`api.js:14`) — nếu endpoint return 204 No Content hoặc empty body → `res.json()` throw `SyntaxError`. Priority P2.
- ⚠️ **P3 — Services methods tạo `URLSearchParams` object mỗi call** — minor allocation, không bottleneck. Priority P3.

## Recommended actions (Phase 4)

- [ ] **P0** — Per drift/AUTH.md D-AUTH-05 + M09 audit: Migrate session storage từ localStorage sang httpOnly cookie (~6-8h BE+FE coord).
- [ ] **P2** — `api.js` AbortController support + unmount cancel (~1h).
- [ ] **P2** — `api.js` FormData-aware: skip `Content-Type` khi body instanceof FormData (~15 min).
- [ ] **P2** — `api.js` throw typed ApiError class + caller use try/catch thay vì `result.success` check (~3h cross-service).
- [ ] **P2** — `api.js` handle 204 No Content gracefully (~10 min).
- [ ] **P2** — Replace emoji trong `useWebSocket.js` console.log bằng text prefix `[WS]` (~15 min).
- [ ] **P2 (Phase 5+)** — Integrate TanStack Query cho cache + retry + dedupe.
- [ ] **P3** — Document `VITE_API_BASE_URL` fallback behavior trong README (~10 min).
- [ ] **P3** — Consider adding zod schema validation tại client boundary cho critical endpoints (~per-endpoint cost).

## Out of scope (defer Phase 3 deep-dive)

- `hooks/useAIModelsManager.js` state machine deep review — Phase 3.
- Per-service method parameter audit (match BE route expected query params) — Phase 3.
- `passwordValidator.js` vs backend `passwordValidator.js` drift detection — same source of truth? Phase 3.
- Network error handling granularity (offline, timeout, 5xx retry) — Phase 5+.
- Service worker + optimistic update pattern — Phase 5+.
- FE unit tests cho services + hooks + utils — M08 scope BE only; FE TBD.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-05 cookie migration (P0 Security fix).
- Steering React rule: `.kiro/steering/24-react-vite.md` — client-side JWT storage cấm.
- Framework v1 anti-pattern auto-flag: "Token nhạy cảm trong localStorage".
- ADR-004: [004-api-prefix-standardization.md](../../../ADR/004-api-prefix-standardization.md) — `/api/v1/admin/*` prefix.
- M01 BE Bootstrap: CORS reflection depends CSRF migration.
- M05 BE Middlewares: rate limit kết hợp với FE service → shared-state perf.
- M09 FE Bootstrap: duplicate session storage finding.
- M10 Pages: pages consume services + hooks.
- M11 Components: components consume services (verify coupling Phase 3).
- Module inventory: M12 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No FE precedent trong tier2/healthguard-model-api/.
