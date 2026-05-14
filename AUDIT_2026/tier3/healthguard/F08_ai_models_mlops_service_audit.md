# Deep-dive: F08 — ai-models-mlops.service.js (ADR-006 mock orchestration)

**File:** `HealthGuard/backend/src/services/ai-models-mlops.service.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 3 (MLOps + Frontend god-components)

## Scope

Single file `ai-models-mlops.service.js` (~830 LoC):
- Helper functions (~250 LoC): `clone`, `parseDbModelId`, `buildOverlayId`, `getDefaultFeedbackSummary`, `createEmptyPayload`, `createDemoFallPayload`, `getInitialPayload`, `getDbModelOrThrow`, `loadStateRecord`, `saveState`, `getLatestDataset`, `getLatestJob`, `buildCatalogOverlayModel`, `buildFeatureDiffs`, `extractVersionNumber`, `extractDatasetVersionNumber`, `getLatestDatasetByVersion`, `buildCatalogMetrics`, `buildSchemaByTask`, `uploadDatasetSourceFile`, `deleteDatasetFiles`, `buildDatasetSeedByTask`, `buildGenericDataset`, `scheduleRetrainCompletion`, `scheduleQueuedJobStart`, `maybeScheduleAutoRetrain`.
- Public service `aiModelsMLOpsService` (~580 LoC, 14 methods): `listModels`, `createModel`, `getModel`, `getVersions`, `getDatasets`, `getFeedbackSummary`, `getRetrainJobs`, `getDataDiff`, `getModelDiff`, `buildNextDataset`, `retrainModel`, `deployCandidate`.

**Out of scope:** Mock data templates (M07 mocks/ai-models-mlops.mock.js cover), R2 service implementation (`r2.service.js` separate), FE consumer hook (F11 useAIModelsManager).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | ADR-006 mock orchestration đúng intent. JSON state stored trong `ai_model_mlops_states.payload` JSONB. Helper functions defensive (null check, fallback templates). Gap: `setTimeout` based async retrain simulation không persistent (server restart → mất pending jobs); `clone` JSON.parse/stringify lose Date type → string. |
| Readability | 1/3 | 830 LoC trong 1 file, 28+ helper functions + 14 public methods. Reader phải scroll qua nhiều helpers trước khi reach service body. Naming consistent nhưng không có section divider rõ ràng. Vietnamese comment rải rác, một số inline literal mixed. |
| Architecture | 2/3 | ADR-006 mock pattern: state machine trong JSONB payload + DB upsert. Singleton service module. Thin overlay pattern (`buildCatalogOverlayModel` map DB row + payload state → API response). Gap: `setTimeout` lifecycle không integrate với Express graceful shutdown. |
| Security | 3/3 | Prisma parameterized queries. R2 upload qua `r2.service.js` wrapper. Không log sensitive data. Không hit anti-pattern auto-flag. Mock scope không expose real ML training endpoints. |
| Performance | 2/3 | JSONB upsert `ai_model_mlops_states` table — single row per model. Gap: `loadStateRecord` clone toàn bộ payload mỗi call (heavy với feedbackStore 612+ items); `listModels` loop sequential `loadStateRecord` cho mỗi model (N×1 query thay vì 1×N JOIN). |
| **Total** | **10/15** | Band: **🟡 Healthy** |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M04 + M07 findings (all confirmed):**

1. ✅ **ADR-006 mock orchestration** (M04) — confirmed: service không call ML training pipeline thật, dùng `setTimeout` simulate + JSONB state payload. Match ADR-006 mandate đồ án 2 scope.
2. ✅ **mocks/ai-models-mlops.mock.js consumer** (M07) — confirmed lines 1-17 import templates, factory functions từ mock file. Service overlay logic build response từ DB row + payload state.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **`setTimeout` retrain simulation không persistent** (`scheduleRetrainCompletion:289`, `scheduleQueuedJobStart:319`):
   - Pattern: `setTimeout(async () => { ... saveState(...) }, RETRAIN_DELAY)`.
   - Server restart trong 2.2s window → setTimeout cancelled → job stuck status='running' / 'queued' permanently.
   - Production impact thấp (đồ án 2 demo scope, ADR-006 mock), nhưng documented gap.
   - Fix Phase 5+: persist job state với BullMQ hoặc DB poll worker, restore pending trên startup.
   - Priority P3.
4. ⚠️ **`clone` JSON.parse/stringify lose Date** (`clone:18-26`):
   - Convert Date → string → parse back JSON → string (không phải Date object).
   - Downstream code so sánh `Date.parse(item.createdAt)` (line 153) — OK vì parse string back.
   - Nhưng nếu future code dùng `item.createdAt.getTime()` → TypeError.
   - Priority P3 — refactor sử dụng `structuredClone` (Node 17+) để preserve types.
5. ⚠️ **`loadStateRecord` clone toàn bộ payload mỗi call** (line 145-149):
   - Payload chứa `feedbackStore: 612 items × 11 fields` ≈ 50KB JSON parse + stringify.
   - Gọi từ mọi public method (listModels, getVersions, getDatasets, ...).
   - Performance cost: ~5-10ms parse/stringify per call × N requests.
   - Fix: clone chỉ field cần thiết hoặc dùng `structuredClone` faster.
   - Priority P2.
6. ⚠️ **`listModels` N×1 query pattern** (lines 480-498):
   - Loop `for (const dbModel of dbModels) { loadStateRecord(dbModel) }` → N round-trip queries.
   - Với 10 models → 10 sequential queries (`SELECT FROM ai_model_mlops_states WHERE model_id = $1`).
   - Fix: 1 single query với `WHERE model_id IN (...)` rồi map.
   - Priority P2.
7. ⚠️ **Fall mock data demo path** (`createDemoFallPayload:60-91`):
   - Special-case logic cho `task === 'fall_detection' && key === FALL_MODEL_KEY` dùng mock templates.
   - Other tasks (sleep_tracking, health_monitoring) → empty payload.
   - Fix Phase 5+: parametric mock generator cho all 3 tasks.
   - Priority P3.
8. ⚠️ **`scheduleRetrainCompletion` race condition** (lines 289-340):
   - Read `payload.retrainJobs` → modify → saveState (upsert).
   - Nếu 2 admin manual retrain trong window 2.2s → race overwrite (last-write-wins).
   - Đồ án 2 scope OK (single admin), production cần optimistic lock hoặc DB transaction.
   - Priority P3.
9. ⚠️ **`buildCatalogOverlayModel` complex logic** (~120 LoC, lines 167-270):
   - 2 sources of truth: `dbModel.active_version` vs `payload.modelVersions`.
   - Priority logic: DB first, fallback payload (lines 178-189).
   - Logic phức tạp với nhiều branch (running/failed/needRetrain/candidate).
   - Phase 1 M04 không flag (covered general M04 architecture), Phase 3 mới identify.
   - Test khó cover full state space.
   - Priority P2 — extract sub-builder fns + add unit test cho state transitions.
10. ⚠️ **R2 file delete không atomic** (`deleteDatasetFiles:380-395`):
    - Loop sequential `for-of` qua datasets → `r2Service.deleteFile(storageKey)`.
    - Lỗi 1 file → log warn + continue → partial delete.
    - Không có rollback nếu DB rollback (`saveState` failed).
    - Priority P3 — Phase 5+ cleanup orphan R2 objects.
11. ⚠️ **Hardcoded console.warn** (line 392) — emoji prefix `[WARN]` nhưng cũng có line 286 `console.error('[ai-models-mlops] scheduleRetrainCompletion failed:', error.message)`. Inconsistent logging pattern. Priority P3.

### Correctness (2/3)

- ✓ **JSONB state pattern** (line 134-147 `loadStateRecord`): persistent state qua DB column `payload`, tránh in-memory loss.
- ✓ **Defensive null check**: `getDbModelOrThrow:96-115` throw nếu model không tồn tại; `getVersions:516-532` fallback DB versions nếu payload empty.
- ✓ **Atomic upsert** (line 152-164 `saveState`): create or update, không phải 2 separate queries.
- ✓ **Fallback chain** `buildCatalogOverlayModel`:
  - currentVersion: DB active_version → payload.modelVersions[active] → first version → null.
  - lastRetrainedAt: payload.meta → dbModel.updated_at → dbModel.created_at.
- ✓ **Error catch trong setTimeout** (lines 285-287, 322-324) → `console.error` không throw → không crash event loop.
- ⚠️ **P3 — `setTimeout` lifecycle** — server restart mất pending. Documented limitation.
- ⚠️ **P3 — `clone` lose Date type** — JSON cycle. Documented downstream fix nếu cần.

### Readability (1/3)

- ⚠️ **P1 — File 830 LoC** — vượt ngưỡng `>500 LoC = split candidate` per framework rubric. Reader phải scroll qua 28+ helpers trước reach public service body line 478.
  - Split proposal:
    - `ai-models-mlops/state.js` — `loadStateRecord`, `saveState`, `getInitialPayload`, `createEmptyPayload`, `createDemoFallPayload`.
    - `ai-models-mlops/overlay.js` — `buildCatalogOverlayModel`, `buildFeatureDiffs`, `buildCatalogMetrics`, `buildSchemaByTask`.
    - `ai-models-mlops/datasets.js` — `buildGenericDataset`, `buildDatasetSeedByTask`, `uploadDatasetSourceFile`, `deleteDatasetFiles`, `getLatestDatasetByVersion`, `extractDatasetVersionNumber`.
    - `ai-models-mlops/scheduler.js` — `scheduleRetrainCompletion`, `scheduleQueuedJobStart`, `maybeScheduleAutoRetrain`.
    - `ai-models-mlops.service.js` — public 14 methods only.
  - Priority P2 (Phase 5+ refactor).
- ⚠️ **P2 — Section divider thiếu** — không có banner comment chia helpers vs public service. Reader phải dùng IDE outline.
- ⚠️ **P2 — Vietnamese inline literal** (vd lines 215 'Chưa có dataset baseline cho workflow MLOps', 218 'Chờ admin tạo dataset_v1 baseline', 261 'Đang theo dõi, chưa cần auto retrain') — scattered. Extract `constants/mlops-messages.js` giúp i18n future + consistency. Priority P3.
- ✓ Method naming clear (`buildCatalogOverlayModel`, `maybeScheduleAutoRetrain`, `scheduleRetrainCompletion`).
- ✓ Variable naming tự explain (`latestDataset`, `latestJob`, `nextVersionNumber`, `targetDatasetVersion`).

### Architecture (2/3)

- ✓ **JSONB state machine pattern** — đúng cho mock orchestration, không cần dedicated tables cho `retrainJobs`/`modelDiffs`/`datasets`.
- ✓ **Overlay pattern** — `buildCatalogOverlayModel` thin layer map DB row + payload → API response shape, tránh leak internal state.
- ✓ **Singleton service export** (line 478 `const aiModelsMLOpsService = {...}; module.exports = aiModelsMLOpsService;`).
- ✓ **DI-friendly** — inject `prisma`, `r2Service`, mocks templates.
- ⚠️ **P2 — `setTimeout` không integrate Express shutdown** — graceful SIGTERM không cancel pending timeouts → process hang ~2.2s. Priority P3.
- ⚠️ **P2 — File 830 LoC god-service** — 28+ helpers + 14 methods. Split proposal trên Readability section. Priority P2 Phase 5+.
- ⚠️ **P3 — Mock vs production fork** — production sẽ replace toàn file với real ML pipeline. ADR-006 plan: Phase 5+ migration. Priority P3 (Phase 5+).

### Security (3/3)

- ✓ Prisma `findFirst`, `findMany`, `upsert` — parameterized queries.
- ✓ R2 file upload qua `r2Service.uploadFile(buffer, key)` wrapper — sanitize key naming (line 367 `ai-model-datasets/{key}/{version}/source.{ext}`).
- ✓ R2 file delete check storageKey null/undefined (`deleteDatasetFiles:382-385`).
- ✓ Không log sensitive data raw.
- ✓ Input `modelId` từ `parseDbModelId` (line 28) — prefix strip + Number() validate, throw nếu NaN.
- ✓ Mock scope không expose real ML training endpoints — đồ án 2 safe.

### Performance (2/3)

- ✓ **JSONB upsert** — 1 round-trip cho persist state.
- ✓ **`prisma.findMany` với `include` + `select`** (lines 478-489): batched fetch models + active_version + mlops_states trong 1 query.
- ⚠️ **P2 — `loadStateRecord` clone full payload** (line 145-149) — 50KB JSON parse/stringify per call. Recommendation: structuredClone hoặc selective clone field.
- ⚠️ **P2 — `listModels` N×1 query** (lines 480-498) — 10 sequential queries với 10 models. Refactor 1 query với `WHERE model_id IN (...)` rồi map. Priority P2.
- ⚠️ **P3 — `setTimeout` block-time 2.2s + 1.2s** (`RETRAIN_DELAY = 2200`, `RETRAIN_QUEUE_DELAY = 1200`) — mock simulation latency. Acceptable cho demo, không phải production concern.
- ✓ R2 upload async — không block main flow.

## Recommended actions (Phase 4)

### P2 — performance + readability

- [ ] **P2** — Refactor `listModels` 1 query với `WHERE model_id IN (...)` thay vì loop sequential (~30 min).
- [ ] **P2** — `loadStateRecord` dùng `structuredClone` thay JSON.parse/stringify (~10 min).
- [ ] **P2 (Phase 5+)** — Split file thành 5 sub-modules (state, overlay, datasets, scheduler, service public).
- [ ] **P2** — Extract `buildCatalogOverlayModel` complex logic thành sub-builder fns + unit test state transitions.

### P3 — defensive + cleanup

- [ ] **P3** — Add section divider comments (helpers vs public methods) (~15 min).
- [ ] **P3** — Replace inline Vietnamese literals → `constants/mlops-messages.js` (~30 min).
- [ ] **P3** — Replace `clone` JSON.parse/stringify với `structuredClone` để preserve Date types (~10 min).
- [ ] **P3** — Standardize logging: replace inline emoji với text prefix `[INFO]`, `[WARN]`, `[ERROR]` (~10 min).
- [ ] **P3 (Phase 5+)** — Persist `setTimeout` retrain jobs với BullMQ hoặc DB poll worker.
- [ ] **P3 (Phase 5+)** — Optimistic lock `payload.retrainJobs` để tránh race condition.
- [ ] **P3 (Phase 5+)** — Mock generator cho all 3 tasks (sleep_tracking, health_monitoring, fall_detection).

### Phase 5+ — production migration

- [ ] **(Phase 5+)** — Replace mock orchestration với real ML pipeline integration per ADR-006 future plan.
- [ ] **(Phase 5+)** — Cleanup orphan R2 objects nếu saveState rollback (background reconciliation worker).
- [ ] **(Phase 5+)** — Graceful shutdown integration: cancel pending setTimeout on SIGTERM.

## Out of scope (defer)

- Real ML training pipeline integration — ADR-006 mock mandate đồ án 2.
- Model artifact format validation (ONNX, joblib, pickle) — Phase 5+ contract testing.
- Cross-repo MLOps state sync với Mobile BE — out of admin scope.
- Distributed retrain queue (multi-instance worker) — Phase 5+ ops.
- A/B testing model deploy — Phase 5+ feature.

## Cross-references

- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — ADR-006 mock service flagged.
- Phase 1 M07 audit: [tier2/healthguard/M07_jobs_utils_config_audit.md](../../tier2/healthguard/M07_jobs_utils_config_audit.md) — `mocks/ai-models-mlops.mock.js` parametric tunable Phase 4 #6.
- Phase 1 M11 audit: [tier2/healthguard/M11_frontend_components_audit.md](../../tier2/healthguard/M11_frontend_components_audit.md) — `components/ai-models/` + `aimodels/` duplicate folders.
- ADR-006: [ADR/006-mlops-mock-vs-real-integration.md](../../../ADR/006-mlops-mock-vs-real-integration.md) — mandate mock cho đồ án 2 scope.
- ADR-007: [ADR/007-r2-artifact-vs-model-api-serving-disconnect.md](../../../ADR/007-r2-artifact-vs-model-api-serving-disconnect.md) — R2 upload scope decision.
- F11 `useAIModelsManager.js` deep-dive — FE consumer hook gọi service.
- Cross-repo: model API `tier2/healthguard-model-api/M02_services_audit.md` + tier3 F1-F9 — model serving side.
- Mock templates: `HealthGuard/backend/src/mocks/ai-models-mlops.mock.js`.
- Storage wrapper: `HealthGuard/backend/src/services/r2.service.js`.
- Precedent format: [tier3/healthguard-model-api/F1_fall_service_audit.md](../healthguard-model-api/F1_fall_service_audit.md) — tier3 deep-dive format.

---

**Verdict:** ADR-006 mock orchestration functional cho đồ án 2 — 10/15 Healthy band. Main gaps: file size 830 LoC (god-service candidate Phase 5+ split), `listModels` N×1 query pattern (P2 refactor), `loadStateRecord` clone full payload performance overhead (P2). Sau Phase 4 P2 refactors → 12/15 Healthy. Phase 5+ migration sang real ML pipeline integration là next major milestone.
