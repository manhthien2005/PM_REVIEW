# Deep-dive: F11 — useAIModelsManager.js (MLOps state machine hook)

**File:** `HealthGuard/frontend/src/hooks/useAIModelsManager.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 3 (MLOps + Frontend god-components)

## Scope

Single hook file `useAIModelsManager.js` (~250 LoC, 1 export `useAIModelsManager()`):
- State management: models, loading, busyAction, selectedModelId, detailTab, detailLoading, detailState (model, versions, datasets, feedbackSummary, jobs, dataDiff, modelDiff, selections).
- Helper `buildDefaultSelections` — pick newest dataset + active version cho default diff selection.
- Fetch functions: `fetchModels`, `getDetailBundle`, `loadModelDetail`.
- useEffect chains: initial fetch on mount, polling 1.5s khi có retraining model.
- Action mutations: `openDetail`, `closeDetail`, `refreshAll`, `uploadDataset`, `createModel`, `updateModel`, `deleteModel`, `retrainModel`, `deployCandidate`, `updateDataDiffSelection`, `updateModelDiffSelection`.

**Out of scope:** `aiModelService` API layer (M12 Phase 1 cover), AIModelsPage consumer (M10 Phase 1 macro), MLOps backend service (F08 deep-dive).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Hook pattern đúng React 19. Polling 1.5s khi có retraining model — match BE F08 setTimeout 2200ms cho complete. Gap: `fetchModels()` không có error handling, `getDetailBundle` Promise.all 5 calls không partial fail handling. |
| Readability | 3/3 | 250 LoC scannable, naming clear (`buildDefaultSelections`, `getDetailBundle`, `loadModelDetail`). State 8 variables grouped logically. useCallback dependencies explicit. |
| Architecture | 3/3 | Custom hook đúng React idiom — encapsulate state + fetch + actions. Action mutations consistent pattern. `detailState` consolidated object thay vì spread state — clean. |
| Security | 3/3 | Service layer pure delegate. Input từ user controlled. Không log sensitive data. Không hit anti-pattern auto-flag. |
| Performance | 2/3 | Polling 1.5s khi retraining → reasonable. `getDetailBundle` Promise.all 5 calls + 2 conditional → tối ưu parallel. Gap: `setTimeout(fetchModels, 0)` trong useEffect không cần thiết, polling poll full detailBundle nếu detailTab khác overview. |
| **Total** | **13/15** | Band: **🟢 Mature** |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M11/M12 findings (all confirmed):**

1. ✅ **Custom hook pattern** — confirmed: `useAIModelsManager` encapsulate state + actions, FE component (`AIModelsPage`) consume qua spread destructure.
2. ✅ **Polling 1.5s khi có retraining** (M11 + M12 implicit) — confirmed lines 99-110.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **No error handling trong fetch functions** (lines 53-59 `fetchModels`):
   - `setLoading(true)` → `await aiModelService.getModels()` → `setModels(response.data || [])` → `setLoading(false)`.
   - Nếu API fail → throw → `setLoading` not called → loader stuck.
   - Pattern tốt: `try { ... } catch (error) { setError(error.message); } finally { setLoading(false); }`.
   - Hook không expose `error` state → component không thể display error UI.
   - Priority P2 — add error state + try/catch.
4. ⚠️ **`getDetailBundle` Promise.all không partial fail handling** (lines 61-90):
   - Promise.all 5 calls song song (model/versions/datasets/feedback/jobs) + 2 conditional (dataDiff/modelDiff).
   - Nếu 1 trong 7 calls fail → toàn bộ Promise.all reject → component thấy nothing.
   - Pattern tốt: Promise.allSettled để partial display.
   - Priority P2 — refactor allSettled.
5. ⚠️ **`setTimeout(fetchModels, 0)` trong useEffect** (lines 90-95):
   - Defer 1 tick để avoid React strict mode double-fire warning.
   - Workaround pattern brittle. React 19 + strict mode: useEffect chạy 2 lần dev mode → cleanup function handle.
   - Pattern đúng: `fetchModels()` trực tiếp.
   - Priority P3 — investigate root cause + remove setTimeout.
6. ⚠️ **Polling fetch detail line 105 unnecessary if detailTab khác** (lines 99-110):
   - Khi `hasRunningRetrain && selectedModelId` → poll fetchModels() + loadModelDetail() mỗi 1.5s.
   - `loadModelDetail` re-fetch detailBundle (5 calls) bất kể `detailTab` đang ở overview/datasets/jobs.
   - Performance: 5 calls/1.5s = 3.3 calls/sec → wasteful.
   - Fix: poll chỉ fields liên quan tới retraining (jobs + model status), không full detailBundle.
   - Priority P3 — Phase 5+ optimize.
7. ⚠️ **`buildDefaultSelections` chỉ dựa trên array index** (lines 4-15):
   - `newestDataset = datasets[0]` — assume datasets sorted newest first.
   - `previousDataset = datasets[1] || datasets[0]` — nếu datasets unsorted → wrong "previous".
   - Priority P3 — sort defensively.
8. ⚠️ **`busyAction` semantic không strict** (lines 19, 167-181):
   - String pattern: `build-${modelId}`, `create-model`, `update-${modelId}`, `delete-${modelId}`, `retrain-${modelId}`, `deploy-${modelId}`.
   - Magic strings rải rác — typo prone.
   - Fix: enum constants.
   - Priority P3 — Phase 5+ refactor.
9. ⚠️ **No abort signal cho long-running fetch** (lines 53-90):
   - `fetchModels`, `getDetailBundle` không pass AbortSignal vào fetch.
   - Component unmount giữa lúc fetch pending → setState on unmounted warning.
   - Priority P3 — F-Phase 5+ AbortController integration với api.js.
10. ⚠️ **Hook export 18 properties** (lines 230-249) — large public API surface. Reader phải scroll xuống bottom. Priority P3 — split sub-hooks (`useAIModelsList`, `useAIModelsDetail`) Phase 5+.

### Correctness (2/3)

- ✓ **`useCallback` đúng pattern** (lines 53, 61, 92, 116, 121, 128, 137, 147, 156, 165, 175, 184, 195, 213) — stable refs cho consumer.
- ✓ **`useMemo` cho `hasRunningRetrain`** (line 99) — derive state, đúng pattern.
- ✓ **Cleanup useEffect** (line 91, 99) — `return () => window.clear*(timer)` mỗi useEffect.
- ✓ **Detail bundle race protection** (lines 61-90 `getDetailBundle`) — single async function.
- ✓ **Polling 1.5s match BE retrain delay 2200ms** — admin thấy status change trong 1.5-3.7s.
- ⚠️ **P2 — No error handling fetch** — loader stuck nếu fail.
- ⚠️ **P2 — Promise.all không partial fail** — all-or-nothing.
- ⚠️ **P3 — `setTimeout(0)` workaround** — brittle.
- ⚠️ **P3 — `buildDefaultSelections` array index assume sorted** — defensive sort.

### Readability (3/3)

- ✓ Naming clear: `fetchModels`, `getDetailBundle`, `loadModelDetail`, `buildDefaultSelections`.
- ✓ State grouped logically: page-level (models, loading, busyAction) + detail-level (selectedModelId, detailTab, detailLoading, detailState).
- ✓ Action functions cohesive: 11 actions với consistent pattern.
- ✓ useCallback dependencies explicit (`[fetchModels]`, `[loadModelDetail]`, `[selectedModelId]`).
- ✓ 250 LoC scannable, không quá dài cho 1 hook quản 11 actions + 5 fetch.
- ⚠️ **P3 — JSDoc absent** — function naming tự explain nhưng JSDoc giúp IDE IntelliSense.

### Architecture (3/3)

- ✓ **Custom hook idiom** đúng React — encapsulate state + side effects + actions.
- ✓ **detailState consolidated object** thay vì spread state — clean, atomic update.
- ✓ **Action mutations consistent** — `setBusyAction(label)` → API → `refreshAll` → `setBusyAction('')`.
- ✓ **Service layer delegate** — không hit fetch trực tiếp.
- ✓ **18 properties export** — large nhưng coherent (state + selection + 11 actions).
- ⚠️ **P3 — Sub-hooks split candidate Phase 5+** — `useAIModelsList` (page-level) + `useAIModelsDetail` (selectedModelId-driven).

### Security (3/3)

- ✓ Service layer pure delegate (line 2 `import aiModelService`).
- ✓ Input `modelId` từ component prop (admin click row → modelId).
- ✓ Không log sensitive data trong hook.
- ✓ Không hit anti-pattern auto-flag.
- ✓ MLOps mock scope (ADR-006) → không expose real ML training endpoints.

### Performance (2/3)

- ✓ **Polling 1.5s conditional** (lines 99-110) — chỉ poll khi `hasRunningRetrain`, không poll mọi lúc.
- ✓ **Promise.all 5+2 conditional calls** (lines 62-83) — parallel fetch detail bundle.
- ✓ **`useMemo` cho derived state** (`hasRunningRetrain` line 99).
- ✓ **`useCallback` stable refs** — child component không re-render unnecessary.
- ⚠️ **P2 — Promise.all all-or-nothing** — 1 fail → all fail UI.
- ⚠️ **P3 — Polling poll full detailBundle** — wasteful nếu admin xem tab khác overview/jobs.
- ⚠️ **P3 — `setTimeout(0)` thừa** — micro-task delay không cần thiết.
- ⚠️ **P3 — No abort signal** — pending fetch sau unmount.

## Recommended actions (Phase 4)

### P2 — error handling

- [ ] **P2** — Add `error` state + try/catch trong `fetchModels` + `loadModelDetail` (~30 min).
- [ ] **P2** — Refactor `getDetailBundle` dùng `Promise.allSettled` thay Promise.all để partial display (~30 min).

### P3 — performance + cleanup

- [ ] **P3** — Investigate root cause `setTimeout(fetchModels, 0)` trong useEffect line 91 + remove (~30 min).
- [ ] **P3** — Polling chỉ poll fields liên quan retraining (jobs + model status), không full detailBundle (~1h).
- [ ] **P3** — Defensive sort `datasets` + `versions` trong `buildDefaultSelections` (~10 min).
- [ ] **P3** — Add JSDoc trên public hook + return shape documentation (~30 min).
- [ ] **P3 (Phase 5+)** — Refactor `busyAction` magic strings → enum constants.
- [ ] **P3 (Phase 5+)** — Add AbortController integration với `api.js` cho long-running fetch.
- [ ] **P3 (Phase 5+)** — Split hook thành `useAIModelsList` + `useAIModelsDetail` sub-hooks.

## Out of scope (defer)

- `aiModelService` API layer — M12 + F08 BE deep-dive cover.
- Component consumer (`AIModelsPage.jsx`) integration — M10 Phase 1 macro.
- Real-time WebSocket cho retrain status updates (currently polling 1.5s) — Phase 5+ feature.
- Optimistic UI updates trên action mutations — Phase 5+.
- Caching strategy (TanStack Query, SWR) — Phase 5+ migration.

## Cross-references

- Phase 1 M11 audit: [tier2/healthguard/M11_frontend_components_audit.md](../../tier2/healthguard/M11_frontend_components_audit.md) — `components/aimodels/` hook consumer flag.
- Phase 1 M12 audit: [tier2/healthguard/M12_frontend_services_hooks_utils_audit.md](../../tier2/healthguard/M12_frontend_services_hooks_utils_audit.md) — `aiModelService` API layer.
- F08 `ai-models-mlops.service.js` deep-dive — BE source orchestration, polling cadence sync.
- ADR-006: [ADR/006-mlops-mock-vs-real-integration.md](../../../ADR/006-mlops-mock-vs-real-integration.md) — mock scope đồ án 2.
- Steering React rule: `.kiro/steering/24-react-vite.md` — useCallback/useMemo cho expensive compute.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** Custom hook well-architected với MLOps state machine — 13/15 Mature band. Best practices: useCallback stable refs, useMemo derived state, conditional polling, consolidated detailState. Main gaps: no error handling (P2), Promise.all all-or-nothing (P2), polling fetch full detailBundle (P3 wasteful). Sau Phase 4 P2 fixes → 14/15 Mature. Phase 5+ split sub-hooks + TanStack Query migration là next major refactor.
