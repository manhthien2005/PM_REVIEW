# Audit: M13 — Frontend Support (mocks + styles + types + assets)

**Module:** `HealthGuard/frontend/src/{mocks, styles, types, assets}/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1B (HealthGuard frontend)

## Scope

- `mocks/aiModels.mock.js` — frontend AI models mock data (dev/demo)
- `styles/animations.css` — Tailwind CSS custom animation keyframes
- `types/ai-models.js` — JSDoc typedef stub cho AI models
- `assets/react.svg` — Vite default logo

**Out of scope:** `App.css` + `index.css` (M09 scope), TypeScript migration (đồ án 2 JS only).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Support files là data-only hoặc static asset, không có logic để bug. Mocks structure match consumer expectation (Phase 3 verify). |
| Readability | 3/3 | Files ngắn, naming clear, purpose-driven folder structure. |
| Architecture | 3/3 | 4 folder đúng vai trò: mocks (test/demo data), styles (custom CSS), types (JSDoc typedef), assets (static resources). Single responsibility. |
| Security | 3/3 | Static assets + mock data không có security concern. |
| Performance | 3/3 | Mock data nhỏ, styles không có expensive animation, assets minimal. |
| **Total** | **15/15** | Band: **🟢 Mature** |

## Findings

### Correctness (3/3)

- ✓ `mocks/aiModels.mock.js` — mock data cho AI models domain, data-only, không có logic.
- ✓ `styles/animations.css` — CSS keyframes, declarative.
- ✓ `types/ai-models.js` — JSDoc typedef stub, không có runtime logic.
- ✓ `assets/react.svg` — static SVG file.
- ⚠️ **P3 — `mocks/aiModels.mock.js` vs `components/aimodels/AIModelsConstants.js`** — cả 2 file có thể overlap data về AI models. Verify Phase 3 deep-dive: có duplicate field hay không. Priority P3.
- ⚠️ **P3 — `types/ai-models.js` JSDoc only** — repo JS không phải TypeScript. Phase 5+ cân nhắc TypeScript migration. Priority P3.

### Readability (3/3)

- ✓ Folder naming clear: `mocks/` (test data), `styles/` (CSS), `types/` (type stub), `assets/` (static resources).
- ✓ File count minimal: 1 file per folder → không clutter.
- ✓ Naming pattern match convention (`{domain}.mock.js`, `{domain}.js` for types).

### Architecture (3/3)

- ✓ **Single responsibility** mỗi folder: mocks tách khỏi production code, styles tách khỏi JSX, types tách khỏi logic, assets tách khỏi CSS.
- ✓ `mocks/aiModels.mock.js` — nếu consumer guard `if (import.meta.env.DEV)` → Vite tree-shake khỏi production. Verify Phase 3.
- ✓ `styles/animations.css` — custom keyframes bổ sung Tailwind defaults.
- ⚠️ **P3 — `mocks/` vs `components/aimodels/AIModelsConstants.js`** duplicate risk — Phase 3 deep-dive verify. Priority P3.

### Security (3/3)

- ✓ Mock data không chứa sensitive value hoặc PII thật — em assume, verify Phase 3.
- ✓ Assets + styles không có external URL (fonts, analytics) → no 3rd party tracking.
- ✓ SVG default Vite logo không có embedded script.

### Performance (3/3)

- ✓ 4 file support total — negligible bundle impact.
- ✓ `animations.css` keyframes — browser GPU accelerated khi dùng `transform` + `opacity`.
- ✓ `react.svg` SVG inline-friendly, lazy load default.

## Recommended actions (Phase 4)

- [ ] **P3** — Verify `mocks/aiModels.mock.js` không ship production bundle (guard với `import.meta.env.DEV` trong consumer) (~10 min).
- [ ] **P3** — Deduplicate `mocks/aiModels.mock.js` vs `components/aimodels/AIModelsConstants.js` nếu overlap (~30 min Phase 3).
- [ ] **P3 (Phase 5+)** — Migrate `types/ai-models.js` JSDoc → TypeScript `.d.ts` nếu team TypeScript-ready.
- [ ] **P3** — Verify `styles/animations.css` keyframes dùng GPU-accelerated properties (~10 min Phase 3).

## Out of scope (defer Phase 3 deep-dive)

- CSS tokens + design system formalization — Phase 5+.
- TypeScript migration strategy — Phase 5+.
- Mock data regeneration script — Phase 5+.
- Image optimization — Phase 5+.
- Tailwind custom config audit — Phase 3 deep-dive.

## Cross-references

- Phase 0.5 drift: [drift/AI_MODELS.md](../../tier1.5/intent_drift/healthguard/AI_MODELS.md) — mocks/aiModels.mock.js related.
- ADR-006: [006-mlops-mock-vs-real-integration.md](../../../ADR/006-mlops-mock-vs-real-integration.md) — MLOps mock mandate (FE side).
- M09 FE Bootstrap audit: `App.css` + `index.css` covered.
- M11 Components audit: `components/aimodels/AIModelsConstants.js` similar scope.
- Module inventory: M13 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No FE precedent trong tier2/healthguard-model-api/.
