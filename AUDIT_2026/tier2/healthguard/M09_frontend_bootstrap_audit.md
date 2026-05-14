# Audit: M09 — Frontend Bootstrap (App + main + routing)

**Module:** `HealthGuard/frontend/src/{App.jsx, main.jsx, App.css, index.css}`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1B (HealthGuard frontend)

## Scope

- `main.jsx` (~11 LoC) — React 19 createRoot + StrictMode + BrowserRouter + App render
- `App.jsx` (~130 LoC) — routes declaration, auth gate (`ProtectedRoute`), `isVerifying` state, route title update
- `App.css` + `index.css` — styles (defer Phase 3 style audit)

**Out of scope:** Individual page components (M10), admin layout shell component (M17 scope), styles (defer Phase 3), React Router route transitions (Phase 3).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | `ProtectedRoute` pattern đúng, `isVerifying` loader UX ok, route title update effect đúng. Nhưng `ProtectedRoute` chỉ check `isAuthenticated()` (localStorage presence) mà không re-verify token — có thể bypass với corrupted local state. |
| Readability | 3/3 | `App.jsx` 130 LoC, route declarations clean, JSDoc absent nhưng naming tự explain (ProtectedRoute, routeTitles object, isVerifying state). `main.jsx` minimal 11 LoC đúng convention. |
| Architecture | 2/3 | BrowserRouter wrap ở `main.jsx` — đúng. Auth gate `ProtectedRoute` component wrap `AdminLayout`. Nhưng: auth state không dùng Context/Zustand/Redux → mỗi component tự gọi `getUser()` từ localStorage; route title object inline trong App (nên tách `constants/routeTitles.js`). |
| **Security** | **0/3** | localStorage lưu `hg_token` + `hg_user` — XSS compromise sẽ leak token (per drift AUTH D-AUTH-05, steering React rule explicit cấm). Auto-Critical per framework v1 anti-pattern auto-flag. |
| Performance | 3/3 | `createRoot` + `StrictMode` đúng React 19 pattern. No heavy work tại bootstrap. `isVerifying` initial state minimize loading flash (`!!getUser()` check). |
| **Total** | **10/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Correctness (2/3)

- ✓ `main.jsx:8-13` — React createRoot + StrictMode + BrowserRouter + App render. Pattern chuẩn React 19.
- ✓ `App.jsx:21-26` `ProtectedRoute` component — wrap children + Navigate to `/login` nếu không authenticated. Pattern đúng.
- ✓ `App.jsx:28-31` `isVerifying` initial state = `!!getUser()` — nếu có local user state → show loader đợi verify; nếu chưa login → skip verify + show login directly. UX tối ưu.
- ✓ `App.jsx:34-49` route title `useEffect` — update `document.title` theo `location.pathname`. Map đúng 11 route.
- ✓ `App.jsx:51-65` `checkAuth` async effect — gọi `verifyToken()` nếu có user → fallback set `isVerifying = false` sau check hoàn tất.
- ✓ `App.jsx:85-87` root redirect `/` → `/admin/overview` nếu authenticated, else `/login`. Smart default.
- ✓ `App.jsx:100-102` public auth-recovery routes (forgot + reset flows) — không wrap ProtectedRoute. Đúng.
- ✓ `App.jsx:104-123` admin nested routes với `AdminLayout` parent + `Outlet` rendering. Pattern React Router v6 đúng.
- ⚠️ **P1 — `ProtectedRoute` chỉ check client-side localStorage** (`App.jsx:22`):
  - `isAuthenticated()` = `!!getUser()` = check `localStorage.getItem('hg_user')` không null.
  - Attacker / user corrupt local state → set fake user JSON → bypass ProtectedRoute render.
  - `verifyToken()` chỉ gọi 1 lần mount, không per-route transition → invalid token có thể lingering vài giây trên admin page.
  - Mitigation hiện có: `api.js:20-23` `apiFetch` auto logout + redirect khi nhận 401/403 → mỗi API call sẽ detect stale token.
  - Drift AUTH D-AUTH-05 cookie migration sẽ giải quyết — httpOnly cookie không modifiable từ JS. Priority P1 per drift.
  - File: `HealthGuard/frontend/src/App.jsx:22, 51-65`
- ⚠️ **P3 — `routeTitles` object literal inline** (`App.jsx:36-47`) — 11 entries hardcode trong component body → re-eval mỗi render (mặc dù effect chỉ re-run khi location đổi). Minor memory. Priority P3 — move ra constants file.

### Readability (3/3)

- ✓ `main.jsx:1-13` minimal 11 LoC, reader scan 2 giây hiểu cấu trúc.
- ✓ `App.jsx:8-18` import list clear, page components grouped (LoginPage + auth-recovery pages first, then admin pages).
- ✓ `ProtectedRoute` naming self-explanatory.
- ✓ `isVerifying` state name rõ intent.
- ✓ `routeTitles` object key = full path + value = Vietnamese title — scan 1 lượt biết title structure.
- ✓ Không có `any` / `unknown` TypeScript (repo JS, nhưng JSDoc absent chấp nhận được cho bootstrap nhỏ).
- ⚠️ **P3 — Loading UI gradient animation** (`App.jsx:69-81`) — 13 LoC inline JSX cho loading spinner với animated gradient. Visual rich nhưng extract thành `components/ui/LoadingSpinner.jsx` giảm App.jsx complexity + reusable. Priority P3.

### Architecture (2/3)

- ✓ `main.jsx` separation: ReactDOM render + BrowserRouter wrap — component free.
- ✓ `App.jsx` separation: route declarations + auth gate logic. Không hit API trực tiếp — delegate qua `services/authService`.
- ✓ `AdminLayout` parent route với `onLogout` prop → `navigate('/login')` callback → pattern lift state lên App.jsx.
- ⚠️ **P2 — Không có global auth state management** — mỗi component (Header, Sidebar, Protected pages) tự gọi `getUser()` từ localStorage. Nếu user state đổi (admin update profile) → stale ở các component không reload. React Context hoặc Zustand + subscription sẽ re-render tự động. Priority P2 — Phase 5+ refactor khi scale.
  - File: `HealthGuard/frontend/src/services/authService.js:33-40, App.jsx` + consumer components.
- ⚠️ **P2 — Auth gate không handle role-based route** — ProtectedRoute chỉ check `isAuthenticated()` (có user, bất kỳ role). Nếu có user role 'user' bypass local và navigate `/admin/*` → ProtectedRoute cho qua. BE sẽ trả 403 → api.js auto logout → OK nhưng UX chậm 1 roundtrip. FE nên block tại ProtectedRoute với role check. Priority P2 — add `requireRole={['admin']}` prop.
  - File: `HealthGuard/frontend/src/App.jsx:21-26, 104-123`
- ⚠️ **P3 — `onLogout` inline callback** (`App.jsx:108-111`) — `AdminLayout` nhận `onLogout` prop là arrow function inline → re-create mỗi App re-render → AdminLayout re-render dù không cần. Low-impact vì App re-render hiếm. Priority P3.
- ✓ `routeTitles` không vi phạm rule — const object, không nested deep.

### Security (0/3) — 🚨 Auto-Critical

**⚠️ P0 — Client-side token storage (localStorage)** (inherit từ `authService.js:13-14`):

- `authService.js:12-14` `login` write token + user info vào localStorage keys (`hg_token`, `hg_user`).
- XSS vulnerability: nếu trang có `dangerouslySetInnerHTML` với user input (verify M11 Components) → attacker steal token qua `localStorage.getItem`.
- **Steering React rule** `.kiro/steering/24-react-vite.md` explicit cấm: client-side storage cho JWT → dùng httpOnly cookie.
- **Drift AUTH D-AUTH-05** quyết định Phase 4 migrate httpOnly cookie + CSRF. Priority P0 per drift.
- **Framework v1 anti-pattern auto-flag**: "Token nhạy cảm trong localStorage" → Security = 0 auto-Critical.
- Mitigation hiện có: `api.js:20-23` auto logout khi 401/403 — reactive, không prevent XSS.
- File: `HealthGuard/frontend/src/services/authService.js:13-14`
- File: `HealthGuard/frontend/src/services/api.js:4` (token read)

**⚠️ P1 — `ProtectedRoute` client-side only** (`App.jsx:22`) — duplicate của Correctness finding trên. Score đã deduct ở Correctness.

**⚠️ P2 — `verifyToken` chỉ 1 lần mount** (`App.jsx:51-65`) — không periodic (vd 5 phút verify lại) → token expired ở giữa session sẽ lingering cho tới next API call. `api.js` auto-logout compensate nhưng không proactive. Priority P2 — Phase 5+ add interval timer hoặc ref count API activity.

**⚠️ P3 — `useLocation` trong `useEffect` deps** — `App.jsx:46` `useEffect([location])` → mỗi navigation → effect fire + set title. OK nhưng verify Phase 3 không leak listener.

### Performance (3/3)

- ✓ `main.jsx` minimal — no heavy work tại bootstrap.
- ✓ `App.jsx:31` `isVerifying` initial value computed synchronously từ `getUser()` → không extra render cycle.
- ✓ `StrictMode` wrap (`main.jsx:10`) — double-render dev mode để catch side effect, production single render.
- ✓ React 19 `createRoot` (vs ReactDOM.render deprecated) — concurrent mode opt-in.
- ✓ Routes không lazy load nhưng admin app nhỏ (8 pages), acceptable cho đồ án 2. Phase 5+ `React.lazy` nếu bundle >500KB.
- ✓ `document.title` update via effect → async, không block render.
- ⚠️ **P3 — `isAuthenticated()` call multiple times** trong App.jsx (`:86, 90, 93`) — 3 lần gọi hàm đọc localStorage per render cycle. `localStorage.getItem` là sync disk access fast nhưng nên memo. Priority P3 — `const authed = useMemo(isAuthenticated, [user state]);`.

## Recommended actions (Phase 4)

- [ ] **P0** — Per drift/AUTH.md D-AUTH-05 + steering React rule: Migrate token storage từ localStorage sang httpOnly cookie (BE set cookie, FE không touch) + CSRF token (~6-8h BE+FE coord).
- [ ] **P1** — `ProtectedRoute` add real token verify call trước render (không chỉ check localStorage presence) hoặc chấp nhận trade-off + depend cookie migration.
- [ ] **P2** — Add role-based route protection: `<ProtectedRoute requireRole={['admin']}>` (~1h).
- [ ] **P2** — Introduce auth Context provider hoặc Zustand store cho user state → components subscribe thay vì đọc localStorage (~2h).
- [ ] **P2** — Add periodic `verifyToken` call (5-10 phút interval) để detect expired session proactive (~30 min).
- [ ] **P3** — Move `routeTitles` object sang `src/constants/routeTitles.js` (~10 min).
- [ ] **P3** — Extract loading spinner UI thành `components/ui/LoadingSpinner.jsx` (~20 min).
- [ ] **P3** — Memoize `isAuthenticated()` call trong App.jsx (~10 min).

## Out of scope (defer Phase 3 deep-dive)

- React Router route transitions + data loaders (v6.4+) — Phase 5+ upgrade candidate.
- `App.css` + `index.css` style audit — Phase 3 cosmetic.
- Bundle size analysis (Vite build output) — Phase 3 ops.
- Error boundary wrap cho route tree — Phase 3 resilience.
- SSR (React Server Components) — đồ án 2 scope SPA only.
- PWA (service worker) — đồ án 2 scope không có offline mode.

## Cross-references

- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-05 cookie + CSRF migration (P0 Security fix).
- Steering React rule: `.kiro/steering/24-react-vite.md` — client-side JWT storage cấm, `dangerouslySetInnerHTML` cấm với user input.
- Framework v1 anti-pattern auto-flag: "Token nhạy cảm trong localStorage" → Security=0 auto-Critical.
- ADR-004: [004-api-prefix-standardization.md](../../../ADR/004-api-prefix-standardization.md) — `/api/v1/admin/*` prefix tương thích với `api.js:2` `VITE_API_URL`.
- M01 Backend Bootstrap audit: CORS reflection issue (`app.js:22-29`) sẽ enable CSRF sau cookie migration — cần allowlist trước.
- M10 Pages audit: pages consume `authService`, wrap bởi ProtectedRoute.
- M12 Services audit: `api.js` interceptor logic, `authService.js` localStorage write.
- Module inventory: M09 (FE Bootstrap) in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No Express/React precedent trong tier2/healthguard-model-api/. Compare pattern via steering rule.
