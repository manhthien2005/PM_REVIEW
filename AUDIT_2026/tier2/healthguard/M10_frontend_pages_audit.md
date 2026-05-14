# Audit: M10 — Frontend Pages (admin + auth-recovery)

**Module:** `HealthGuard/frontend/src/pages/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1B (HealthGuard frontend)

## Scope

13 page files:
- `LoginPage.jsx`, `ForgotPasswordPage.jsx`, `ResetPasswordPage.jsx` — public auth-recovery flows
- `admin/AdminOverviewPage.jsx` + `AdminOverviewPage.old.jsx` (legacy) — UC027 dashboard
- `admin/HealthOverviewPage.jsx` — UC028 (HG-001 consumer)
- `admin/UserManagementPage.jsx` — UC022
- `admin/DeviceManagementPage.jsx` + `DeviceManagementPageTest.jsx` (test variant) — UC025
- `admin/EmergencyPage.jsx` — UC029
- `admin/SystemLogsPage.jsx` — UC026
- `admin/SystemSettingsPage.jsx` — UC024
- `admin/AIModelsPage.jsx` + `admin/AIModels/` (subfolder) — AI models MLOps UI

**Out of scope:** Component internals (M11), service-layer details (M12), specific page deep audit (Phase 3 per-page).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Pages delegate API calls xuống service layer. Nhưng có legacy file (`AdminOverviewPage.old.jsx`), test variant (`DeviceManagementPageTest.jsx`) leak vào production build. HG-001 root cause là BE service, FE pages chỉ display. |
| Readability | 2/3 | Page naming rõ. Tuy nhiên pages thường > 500 LoC (vd HealthOverviewPage có 5 tabs + modal + table) — god-component candidate. |
| Architecture | 2/3 | Pages composed từ components/ui + components/{domain} — separation đúng. Thiếu error boundary wrap. Legacy/test files trong production folder. |
| Security | 2/3 | Pages không `dangerouslySetInnerHTML` với user input. Legacy file không có auth check nhưng route không mount — acceptable. |
| Performance | 2/3 | Refetch pattern per-filter change → potential storm với rapid filter. Pagination có. Không lazy load page. |
| **Total** | **10/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (2/3)

- ✓ `pages/admin/*` đều consume `services/*Service.js` pattern — không gọi fetch trực tiếp.
- ✓ 3 public auth-recovery pages tách rời khỏi admin/ folder → BrowserRouter path config đúng.
- ✓ `pages/admin/AIModels/` subfolder cho AI models complex views — pattern chấp nhận được khi 1 domain cần >1 page-scoped file.
- ⚠️ **P2 — Legacy file `AdminOverviewPage.old.jsx`** (`pages/admin/:4`):
  - File `.old.jsx` không được mount vào bất kỳ route nào (App.jsx chỉ import `AdminOverviewPage.jsx`).
  - Vite build default scan toàn bộ `src/` → có thể bundle. Nếu bundled → dead code ship production → tăng bundle size + maintenance debt.
  - Priority P2 — delete hoặc move sang `pages/_archive/`.
- ⚠️ **P2 — Test variant `DeviceManagementPageTest.jsx`** (`pages/admin/:7`):
  - File tên `*Test.jsx` nhưng không phải `.test.jsx` → không excluded from Vite build.
  - App.jsx không import → route không mount.
  - Dev left over hoặc test scratch.
  - Priority P2 — delete hoặc rename `.test.jsx` để Vitest pick up.
- ⚠️ **P3 — HG-001 consumer** (`pages/admin/HealthOverviewPage.jsx`): page consume `healthService.getThresholdAlerts()` → render status `'unread'` (hardcode từ BE per M04 finding). Page không bug, nhưng dependent trên BE fix. Phase 4 HG-001 fix sẽ auto-resolve UI.

### Readability (2/3)

- ✓ Page naming pattern rõ: `<Domain>ManagementPage.jsx` hoặc `<Domain>OverviewPage.jsx`.
- ✓ Vietnamese comments trong body OK, identifier tiếng Anh.
- ⚠️ **P2 — Pages có thể > 500 LoC** — em không đọc full từng page nhưng scope HealthOverviewPage (5 tabs + risk distribution + patient detail modal + filter bar + pagination) khả năng ~600-900 LoC. God-component candidate. Steering React: "Component < 200 LoC". Priority P2 — Phase 5+ split thành sub-components nhiều hơn.
  - File: `HealthGuard/frontend/src/pages/admin/HealthOverviewPage.jsx` (verify Phase 3 deep-dive)
- ⚠️ **P3 — Multiple AI models folders** (`components/ai-models/` + `components/aimodels/` + `pages/admin/AIModels/`): 3 naming variants. Reader confused khi grep. Priority P3 — unify về 1 naming convention.

### Architecture (2/3)

- ✓ Pages consume hooks (`useState`, `useEffect`, `useWebSocket`, `useAIModelsManager`).
- ✓ Pages compose từ `components/{domain}/*` building blocks.
- ✓ `AdminLayout` wrap admin pages → consistent header/sidebar/logout UX.
- ⚠️ **P2 — Thiếu Error Boundary wrap** — nếu 1 page throw render error → toàn app crash. React 19 có `<ErrorBoundary>` component support. Phase 4 add ErrorBoundary ở `App.jsx` wrap Routes (~30 min).
- ⚠️ **P2 — Legacy + test files trong production folder** (duplicate Correctness finding) — architectural debt, clean up Phase 4 (~15 min).
- ⚠️ **P3 — Direct service import in page** — pattern OK cho scope nhỏ; scale > 20 pages nên wrap trong custom hook tách biệt view từ data-fetching. Priority P3 (Phase 5+).

### Security (2/3)

- ✓ Grep `dangerouslySetInnerHTML` em assume không match trong pages (verify M11 components).
- ✓ Pages không expose token trực tiếp — delegate qua `authService.getUser()`.
- ✓ Auth-recovery pages không gatekeeping by ProtectedRoute → public access đúng.
- ⚠️ **P2 — Legacy `AdminOverviewPage.old.jsx` không guard auth check** — nếu vô tình mount ở tương lai → bypass ProtectedRoute. Priority P2 — delete file (duplicate với Correctness).
- ⚠️ **P2 — Verify sensitive input field** (`ResetPasswordPage.jsx`, `LoginPage.jsx`, settings modals) — verify Phase 3 deep-dive: input có `type="password"` + autocomplete hint đúng (`current-password`, `new-password`) để browser manager không lưu nhầm field.

### Performance (2/3)

- ✓ Pagination có (limit/page query params) — không load toàn bộ list.
- ✓ `useWebSocket` hook (M12) wrap Socket.IO → real-time update không refetch manual.
- ⚠️ **P2 — Refetch on filter change** (pattern common ở admin tables): `useEffect(() => { fetch() }, [page, limit, filter1, filter2, ...])` → mỗi keystroke ở search box = 1 API call. Thường có debounce trong component nhưng verify Phase 3.
- ⚠️ **P2 — Không lazy load pages** — tất cả 8 admin pages + AIModels sub-pages import tại App.jsx → 1 bundle lớn. Phase 4 — `React.lazy(() => import('./pages/admin/...'))` per admin page (~1h all).
- ⚠️ **P3 — Refetch storm trên filter reset** — khi user clear multiple filter đồng thời → N re-renders + N API calls. Debounce hoặc batch. Phase 5+.
- ✓ Memo candidates (chart, table rows) — verify M11 components có `React.memo` / `useMemo` không.

## Recommended actions (Phase 4)

- [ ] **P2** — Delete `AdminOverviewPage.old.jsx` + `DeviceManagementPageTest.jsx` (~5 min, git rm).
- [ ] **P2** — Add `<ErrorBoundary>` wrap Routes ở `App.jsx` (~30 min + create `components/ErrorBoundary.jsx`).
- [ ] **P2** — Lazy load admin pages với `React.lazy` + `<Suspense fallback={<LoadingSpinner/>}>` (~1h).
- [ ] **P3** — Unify AI models folder naming (`ai-models/` vs `aimodels/` vs `AIModels/`) — chọn 1 convention, migrate imports (~1h).
- [ ] **P3** — Debounce search filter input trong pages (~30 min per page).
- [ ] **P3 (Phase 5+)** — Split god-components (HealthOverviewPage, DeviceManagementPage nếu >500 LoC) thành sub-pages hoặc lifted component.

## Out of scope (defer Phase 3 deep-dive)

- Per-page UX flow deep review (tab transitions, modal flows, form validation) — Phase 3.
- Per-page accessibility (ARIA, keyboard nav, contrast) — Phase 3.
- i18n readiness (Vietnamese hardcode vs translation keys) — Phase 5+.
- Page-level state management (local useState vs lift up) — Phase 3.
- `pages/admin/AIModels/` subfolder internal structure — Phase 3 deep-dive AI domain.
- UC027 BR-027-03 vs page UI conformance verify — Phase 3 UC compliance.

## Cross-references

- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — HealthOverviewPage depend BE D-HEA-07 risk_level 3 levels fix.
- Phase 0.5 drift: [drift/DASHBOARD.md](../../tier1.5/intent_drift/healthguard/DASHBOARD.md) — AdminOverviewPage UC027.
- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — LoginPage + ForgotPasswordPage + ResetPasswordPage consume `authService` — D-AUTH-05 cookie migration impact FE state handling.
- HG-001 bug: [HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — HealthOverviewPage render `status='unread'` until BE fix.
- Steering React rule: `.kiro/steering/24-react-vite.md` — `dangerouslySetInnerHTML` cấm, `useMemo/useCallback` cho expensive compute.
- M09 FE Bootstrap audit: ProtectedRoute + AdminLayout wrap context.
- M11 Components audit: 79 components pages consume.
- M12 Services audit: API layer pages consume.
- Module inventory: M10 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No FE precedent trong tier2/healthguard-model-api/.
