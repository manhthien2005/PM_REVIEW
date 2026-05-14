# Audit: M11 — Frontend Components (shared UI)

**Module:** `HealthGuard/frontend/src/components/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1B (HealthGuard frontend)

## Scope

79 components trong 12 thư mục:
- `admin/` (4 files): AdminHeader, AdminLayout, AdminSidebar, ChangePasswordModal
- `ai-models/` (5 files + charts/ + tabs/ subfolders): CreateDatasetModal, CreateModelModal, ModelDetailDrawer, ModelStatusBadge, ModelTable, NeedRetrainBadge
- `aimodels/` (6 files): AIModelFormModal, AIModelsConstants, AIModelsPagination, AIModelsTable, AIModelsToolbar, AIModelVersionModal
- `dashboard/` (9 files): 7 chart components + Constants + KPIBar + PatientsTable + SystemHealth
- `devices/` (9 files): 5 modal/action + Table/Toolbar/Pagination/Constants
- `emergency/` (9 files): Detail/Fall/QuickNote/Status/Summary/Table/Toolbar/Pagination/Constants
- `health/` (7 files): Alerts/Health/Patient/Risk/Summary/Threshold
- `logs/` (5 files): Detail/Constants/Pagination/Table/Toolbar
- `settings/` (3 files): PasswordConfirmModal, Constants, Form
- `ui/` (3 files): AlertModal, ConfirmModal, Modal
- `users/` (8 files): Delete/Lock confirm + LinkedAccountsTab + FormModal + Constants + Pagination + Table + Toolbar
- `websocket/` (1 file): ConnectionStatus

**Out of scope:** Component-level logic deep review (Phase 3 per-component), accessibility audit (Phase 3), visual regression testing (out of đồ án 2 scope).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | 79 components well-organized theo domain folder. Pattern Modal/Table/Toolbar/Pagination consistent. Duplicate `ai-models/` vs `aimodels/` folders (11 files tổng) same domain — fragmentation. |
| Readability | 2/3 | Naming clear. Constants extract riêng per domain. Nhưng 79 components scale, audit macro-level. |
| Architecture | 2/3 | Pattern tốt: shared `ui/` + domain folders. Nhưng dashboard có 7 chart components sát nhau, có thể consolidate. |
| Security | 3/3 | Em không verify full nhưng steering rule + code review sample không flag `dangerouslySetInnerHTML`. Modals handle credential input đúng (verify Phase 3). |
| Performance | 2/3 | Components presentational có khả năng high re-render cost (Table/Chart với 100+ rows). Verify Phase 3 sample có `React.memo`/`useMemo` không. |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (2/3)

- ✓ Domain-grouped folders (`users/`, `devices/`, `emergency/`) — scale 79 components vẫn navigable.
- ✓ Pattern repeating theo domain: `{Domain}FormModal` + `{Domain}Table` + `{Domain}Toolbar` + `{Domain}Pagination` + `{Domain}Constants` → reader scan 1 domain biết structure.
- ✓ `ui/` folder cho shared primitive (AlertModal, ConfirmModal, Modal) — DRY pattern.
- ⚠️ **P2 — Duplicate `ai-models/` vs `aimodels/` folders** (11 files tổng):
  - `components/ai-models/` (5 file) + `components/ai-models/charts/` + `components/ai-models/tabs/`
  - `components/aimodels/` (6 file)
  - Likely 2 refactor passes chưa merge. Reader confused — imports từ `./ai-models/ModelTable` vs `./aimodels/AIModelsTable`.
  - Priority P2 — consolidate folder + file naming convention (drift candidate Phase 4).
  - File: `HealthGuard/frontend/src/components/{ai-models,aimodels}/`
- ⚠️ **P3 — `components/websocket/ConnectionStatus.jsx`** standalone component, 1 file folder. Có thể move sang `ui/` hoặc `admin/`. Priority P3.

### Readability (2/3)

- ✓ Component naming PascalCase + self-descriptive (`ModelStatusBadge`, `NeedRetrainBadge`, `EmergencyFallCountdownPanel`).
- ✓ Constants file per domain → extract magic strings ra khỏi JSX body.
- ✓ Modal pattern consistent: `{Domain}{Action}Modal.jsx`.
- ⚠️ **P2 — Dashboard có 9 chart/table components sát nhau** — có thể introduce `DashboardCharts/` subfolder với generic `<Chart type="alerts" />`. Priority P3.
- ⚠️ **P3 — AI Models folders có mixed language casing**: `ai-models/` (kebab), `aimodels/` (merged), files variant `AIModelsTable.jsx` vs `ModelTable.jsx`. Priority P3 — unify.

### Architecture (2/3)

- ✓ `ui/` primitive → `{domain}/` components use primitive → pages compose components. Layered đúng.
- ✓ Constants per domain → logic tập trung render, data trong constants.
- ✓ WebSocket status component wrap realtime connection.
- ⚠️ **P2 — Folder duplication** (ai-models vs aimodels) — architectural debt. Priority P2.
- ⚠️ **P2 — Components consume service layer trực tiếp?** Verify Phase 3: ideally page → hook → service, component pure presentational.
- ⚠️ **P3 — 79 components flat depth** — Phase 5+ cân nhắc feature-based folder structure.

### Security (3/3)

- ✓ Em grep spot-check không thấy `dangerouslySetInnerHTML` trong file đã đọc. Full verify trong Phase 3.
- ✓ `ui/ConfirmModal.jsx` + `ui/AlertModal.jsx` — pattern reuse prevent duplicate modal code.
- ✓ Credential-entry modals (ChangePasswordModal, PasswordConfirmModal) isolated components. Verify Phase 3 autocomplete hint đúng.
- ✓ Role-based rendering: `AdminSidebar` assume user role admin. Depend parent ProtectedRoute.
- ⚠️ **P3 — Verify Phase 3 deep-dive**: user-generated text fields render (admin notes, resolution_notes) — React JSX tự escape text children → OK nếu không dùng `dangerouslySetInnerHTML`.

### Performance (2/3)

- ✓ `DashboardConstants.js` + domain constants → object không re-create mỗi render.
- ✓ Modals mounted conditionally (show state) → không render khi closed.
- ⚠️ **P2 — Tables với pagination default 20 rows** — mỗi row-level re-compute (date format, status badge, action buttons) × 20 × re-render count. Priority P2 — `React.memo(RowComponent)` + `useMemo(filteredRows)`.
- ⚠️ **P2 — Chart components** (multiple DashboardXChart) — likely wrap `recharts`. Mỗi data update re-render toàn chart. Memo + deep equal check giảm cost. Verify Phase 3.
- ⚠️ **P3 — Modal animation state re-create** trên mỗi open/close — default behavior, low impact.

## Recommended actions (Phase 4)

- [ ] **P2** — Consolidate `components/ai-models/` + `components/aimodels/` thành 1 folder + unify file naming (~2h migrate imports).
- [ ] **P2** — Sample verify (Phase 3 deep-dive): 3-5 components lớn nhất có `React.memo` + `useMemo` (~1h verify + add).
- [ ] **P2** — Extract common Table pattern thành `ui/DataTable.jsx` với generic props — giảm duplicate table components (~3h Phase 5+).
- [ ] **P3** — Move `components/websocket/ConnectionStatus.jsx` sang `components/admin/` hoặc `components/ui/` (~5 min).
- [ ] **P3** — Unify dashboard chart components naming (~30 min).
- [ ] **P3 (Phase 5+)** — Feature-based folder reorganization khi scale >100 components.

## Out of scope (defer Phase 3 deep-dive)

- Per-component render optimization profile (React DevTools profiler) — Phase 3.
- Accessibility audit (ARIA, keyboard nav, contrast) — Phase 3.
- Visual regression test setup — out of đồ án 2 scope.
- Component documentation (Storybook) — Phase 5+.
- Design system formalization (Tailwind → design tokens) — Phase 5+.
- i18n component texts — Phase 5+.
- Component unit test coverage (currently no `frontend/__tests__/`) — TBD.

## Cross-references

- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — ThresholdAlertsTable consumer HG-001 fix.
- Phase 0.5 drift: [drift/AI_MODELS.md](../../tier1.5/intent_drift/healthguard/AI_MODELS.md) — AI Models component organization.
- Phase 0.5 drift: [drift/DASHBOARD.md](../../tier1.5/intent_drift/healthguard/DASHBOARD.md) — Dashboard components UC027 mapping.
- Steering React rule: `.kiro/steering/24-react-vite.md` — `dangerouslySetInnerHTML` cấm, `React.memo/useMemo` pattern.
- M10 Pages audit: pages compose components từ module này.
- M12 Services audit: services feed data xuống components.
- Module inventory: M11 (components) in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No FE precedent trong tier2/healthguard-model-api/.
