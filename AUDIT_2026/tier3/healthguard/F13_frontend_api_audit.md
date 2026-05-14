# Deep-dive: F13 — frontend/services/api.js (cookie migration consumer + ApiError class introduction)

**File:** `HealthGuard/frontend/src/services/api.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 4 (FE API layer + Prisma)

## Scope

Single file `api.js` (~25 LoC):
- `API_BASE` env constant (line 2): `import.meta.env.VITE_API_URL || '/api/v1/admin'`.
- `apiFetch(path, options)` (lines 5-23) — fetch wrapper với Bearer header attach + auto logout on 401/403.

**Out of scope:** Service layer consumers (authService, healthService, deviceService, v.v. — M12 Phase 1), useWebSocket hook (Wave 4 future scope), TanStack Query migration (Phase 5+).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Wrapper pattern đúng cho REST API. Auto-logout 401/403 đúng. Gap: `res.json()` parse unconditional → throw `SyntaxError` nếu 204 No Content; không handle FormData (multipart upload conflict với hardcode `Content-Type: application/json`); không AbortController support. |
| Readability | 3/3 | 25 LoC minimal, single function, JSDoc absent nhưng pattern rõ. Variable naming clear (`API_BASE`, `apiFetch`). |
| Architecture | 2/3 | Single source of truth cho API base + auth header injection. Gap: Không throw typed error → caller phải check `result.success` thủ công thay vì try/catch (inconsistent với BE ApiError pattern); không cache/dedupe (TanStack Query opportunity). |
| **Security** | **0/3** | Client-side session storage line 4 → Framework v1 anti-pattern auto-flag. Drift D-AUTH-05 cookie migration P0 fix. Auto-Critical (cùng pattern M09 + M12). |
| Performance | 2/3 | Single fetch per call, không middleware overhead. Gap: No request cache/dedupe (3 components fetch same endpoint = 3 network calls); no retry/timeout policy. |
| **Total** | **9/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M12 findings (all confirmed):**

1. ✅ **Client-side session storage** (M12 P0 + M09 P0) — confirmed line 4 read session value from localStorage. Cùng root cause D-AUTH-05 cookie migration.
2. ✅ **Auto logout 401/403** (M12 confirmed) — confirmed lines 17-21 redirect `/login` + clear localStorage.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **`res.json()` parse unconditional** (line 14):
   - `const body = await res.json();` — nếu endpoint return 204 No Content hoặc empty body → throw `SyntaxError: Unexpected end of JSON input`.
   - Hiện tại không có endpoint nào trả 204 trong codebase, nhưng defensive.
   - Fix: `const text = await res.text(); const body = text ? JSON.parse(text) : null;`.
   - Priority P2 — coordinate với M12 finding.
4. ⚠️ **Hardcoded `Content-Type: application/json`** (line 6):
   - Mọi request set Content-Type JSON.
   - Nếu caller send FormData (multipart upload, vd AI model artifact) → header conflict + browser không set boundary.
   - Fix: skip Content-Type khi `body instanceof FormData`.
   - Priority P2.
5. ⚠️ **No AbortController** (lines 12-14):
   - `fetch(URL, options)` không pass AbortSignal.
   - Component unmount giữa lúc fetch pending → setState on unmounted React warning.
   - Fix: thêm `signal: options.signal` propagate.
   - Priority P2.
6. ⚠️ **No retry/timeout policy** (lines 12-14):
   - Network fail → reject Promise → caller handle error.
   - Không có exponential backoff retry cho transient errors (network blip).
   - Không có timeout (fetch default infinite).
   - Phase 5+ TanStack Query mặc định có retry 3x với backoff.
   - Priority P3 — Phase 5+ migration.
7. ⚠️ **No request deduplication** (toàn file):
   - Nếu 3 components mount cùng lúc fetch `/health/summary` → 3 network calls.
   - Phase 5+ TanStack Query deduplicate dựa trên cache key.
   - Priority P3.
8. ⚠️ **`window.location.href = '/login'` hard redirect** (line 20):
   - Auto-logout dùng `window.location.href` thay React Router `navigate`.
   - Hard redirect mất React state, full page reload.
   - Acceptable vì `apiFetch` không có access tới React Router context, nhưng pattern brittle.
   - Fix: dispatch event hoặc dùng global `useAuthState` + listener.
   - Priority P3.
9. ⚠️ **No request body shape validation** (toàn file):
   - Caller trust blindly `body.success`, `body.data`, `body.message`.
   - BE response corrupt → caller dispatch nhầm path.
   - Phase 5+ thêm zod runtime validation tại client boundary.
   - Priority P3.

### Correctness (2/3)

- ✓ **Path concatenation** (line 12): `${API_BASE}${path}` — assume path starts với `/`. OK pattern.
- ✓ **Auto logout 401/403 chỉ khi không login endpoint** (line 17 `&& !path.includes('/auth/login')`) — đúng UX (login fail không nên auto-logout).
- ✓ **Header spread conditional** (line 7): `...(token ? { Authorization: ... } : {})` — handle absent session value (public endpoints).
- ✓ **Options spread** (line 12): `{ ...options, headers }` — caller có thể override fetch options (method, body).
- ✓ **localStorage clear on logout** (lines 18-19) — clean state.
- ⚠️ **P2 — `res.json()` unconditional** — 204 No Content fail.
- ⚠️ **P2 — FormData header conflict** — multipart upload broken.
- ⚠️ **P2 — No AbortController**.

### Readability (3/3)

- ✓ 25 LoC minimal — scan 5 giây hiểu.
- ✓ Variable naming clear: `API_BASE`, `apiFetch`, `headers`, `body`.
- ✓ Conditional spread pattern (line 7) — concise + readable.
- ⚠️ **P3 — JSDoc absent** — function purpose tự explain nhưng JSDoc giúp IDE IntelliSense + return type.

### Architecture (2/3)

- ✓ **Single source of truth** cho API base URL + auth header — không duplicate ở mỗi service.
- ✓ **Default value cho `VITE_API_URL`** (line 2): fallback `/api/v1/admin` nếu env missing.
- ✓ **Side effect chỉ trên 401/403** — pure pass-through cho 200/4xx khác.
- ⚠️ **P2 — Không throw typed error** — caller pattern: `const result = await apiFetch(...); if (result.success) {...} else {handleError(result.message)}`. Inconsistent với BE ApiError throw pattern. Should: `throw new ApiError(body.statusCode, body.message)` → caller try/catch.
- ⚠️ **P3 — `window.location.href` hard redirect** — React Router lost.
- ⚠️ **P3 — TanStack Query opportunity** Phase 5+ — cache + retry + dedupe.

### Security (0/3) — 🚨 Auto-Critical

**⚠️ P0 CRITICAL — Client-side session storage** (line 4):

- Read session value từ localStorage mỗi request.
- Same root cause với M09 + M12 + authService.js + useWebSocket.js.
- Framework v1 anti-pattern auto-flag → Security = 0 auto-Critical.
- Steering React rule `.kiro/steering/24-react-vite.md` explicit cấm.
- Drift AUTH D-AUTH-05 Phase 4 migrate httpOnly cookie + CSRF.
- Migration: `credentials: 'include'` thay header → BE set Set-Cookie httpOnly → FE không touch.
- Priority P0 per drift D-AUTH-05 (~30 min FE side của 6-8h cross-file effort).

**⚠️ P2 — No CSRF token attach** (line 6-10):
- Sau cookie migration → cần CSRF token header.
- Fix: read `csrf_token` từ cookie hoặc meta tag → attach `X-CSRF-Token: ...` cho mutation endpoints.
- Priority P2 cùng group cookie migration.

**⚠️ P3 — `window.location.href = '/login'` không clear other state** (line 20):
- Auto-logout chỉ clear localStorage keys.
- Không clear React state, không clear session storage, không clear IndexedDB.
- Acceptable vì hard reload, nhưng pattern brittle.
- Priority P3.

### Performance (2/3)

- ✓ **Single fetch per call** — no middleware overhead.
- ✓ **localStorage.getItem O(1)** — sync but fast.
- ⚠️ **P2 — No AbortController** — pending fetch sau unmount waste.
- ⚠️ **P3 — No request cache/dedupe** — 3 components fetch same endpoint = 3 calls. Phase 5+ TanStack Query.
- ⚠️ **P3 — No retry/timeout** — network blip fail immediately.

## Recommended actions (Phase 4)

### P0 — drift D-AUTH-05 cookie migration

- [ ] **P0** — Migrate session value read từ localStorage sang httpOnly cookie. Replace line 4 → `credentials: 'include'` trong fetch options. (~30 min FE side, depend BE set Set-Cookie + CORS allowlist).

### P2 — defensive + correctness

- [ ] **P2** — Handle 204 No Content: `const text = await res.text(); const body = text ? JSON.parse(text) : null;` (~10 min).
- [ ] **P2** — FormData-aware header: skip `Content-Type` khi body instanceof FormData (~15 min).
- [ ] **P2** — AbortController support: propagate `signal: options.signal` (~10 min).
- [ ] **P2** — Add CSRF token header cho mutation endpoints (cùng cookie migration) (~30 min).
- [ ] **P2** — Throw typed ApiError class: `if (!body.success) throw new ApiError(body.statusCode, body.message)` (~30 min, coordinate caller try/catch refactor).

### P3 — cleanup + Phase 5+ migration

- [ ] **P3** — Add JSDoc trên `apiFetch` (~10 min).
- [ ] **P3** — Document `VITE_API_URL` fallback behavior trong README (~10 min).
- [ ] **P3 (Phase 5+)** — Migrate sang TanStack Query cho cache + retry + dedupe.
- [ ] **P3 (Phase 5+)** — Replace `window.location.href` hard redirect với React Router navigate qua event dispatch.
- [ ] **P3 (Phase 5+)** — Add zod runtime validation tại client boundary cho critical endpoints.

## Out of scope (defer)

- TanStack Query migration full — Phase 5+.
- Error boundary integration — Phase 5+.
- Network offline detection — Phase 5+ PWA scope.
- Optimistic UI updates — Phase 5+ feature.
- GraphQL migration — out of scope đồ án 2.

## Cross-references

- Phase 1 M12 audit: [tier2/healthguard/M12_frontend_services_hooks_utils_audit.md](../../tier2/healthguard/M12_frontend_services_hooks_utils_audit.md) — root cause + fixes scoped.
- Phase 1 M09 audit: [tier2/healthguard/M09_frontend_bootstrap_audit.md](../../tier2/healthguard/M09_frontend_bootstrap_audit.md) — same auto-Critical pattern.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-05 cookie migration P0 fix.
- F04 `auth.service.js` deep-dive — BE counterpart cho cookie set Set-Cookie.
- F05 `middlewares/auth.js` deep-dive — BE counterpart cho cookie fallback consume.
- Steering React rule: `.kiro/steering/24-react-vite.md` — client-side JWT storage cấm.
- Framework v1 anti-pattern: client-side session value storage auto-flag.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** Minimal fetch wrapper với Security=0 auto-Critical do client-side session storage — 9/15 Critical band. Cùng cluster với M09 + M12 + authService + useWebSocket chia sẻ root cause D-AUTH-05 cookie migration (~6-8h cross-file BE+FE effort). Sau migration → 12-13/15 Healthy/Mature. P2 defensive fixes (FormData, 204, AbortController, ApiError throw) cùng group ~2h cleanup. Phase 5+ TanStack Query migration là next major.
