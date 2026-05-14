# ADR-006: MLOps workflow — mock implementation for graduation project, defer real integration

**Status:** Accepted
**Date:** 2026-05-12
**Decision-maker:** ThienPDM (solo)
**Tags:** [scope, mlops, healthguard, ai-models, graduation-project]

## Context

HealthGuard admin web có module `AI_MODELS` với 22 endpoints + 1247 lines service code. Trong đó 12/22 endpoints (`/api/v1/ai-models/mlops/*`) + 832/1247 lines service code là **MLOps overlay**:

- `GET /mlops/models/:id/datasets` — list dataset versions
- `GET /mlops/models/:id/data-diff` — data drift comparison
- `GET /mlops/models/:id/model-diff` — model metrics comparison
- `GET /mlops/models/:id/feedback-summary` — feedback aggregation
- `GET /mlops/models/:id/retrain-jobs` — retrain job history
- `POST /mlops/models/:id/datasets/build-next` — build new dataset
- `POST /mlops/models/:id/retrain` — trigger retrain pipeline
- `POST /mlops/models/:id/deploy-candidate` — promote candidate to active
- (plus 4 GET helpers)

**Tất cả MLOps endpoints là MOCK/DEMO** sau khi audit code:

- `retrainModel`: dùng `setTimeout(2200)` để fake retrain latency. Sau timeout, append candidate version từ `modelV2CandidateTemplate` (hard-coded mock).
- `buildGenericDataset`: hard-coded numbers (`numSamples: 8600`, `drift: 0.12`, growth `1400-2500`). Drift summary từ `datasetV1Template` / `datasetV2Template` template.
- `scheduleRetrainCompletion`: setTimeout-based progression queue → running → completed, không phải pipeline thật.
- `buildCatalogMetrics`: tính accuracy/precision/recall/f1/auc bằng arithmetic formula (`taskBase + lift`), không đo từ training thật.

**Storage có thực:** dataset upload file vào R2 (Cloudflare R2 / S3-compatible) đúng kiểu BLOB. **Metadata bao quanh là mock.**

**Cross-repo:** `healthguard-model-api` (model serving) hoàn toàn không biết về MLOps state này. `active_version_id` trong admin DB → 0 effect on model serving (see ADR-007).

Phase 1 audit Phase 1.5 intent drift review phát hiện scope discrepancy: anh đã invest 832 lines code cho MLOps mock UI/state — sunk cost. Câu hỏi: keep, drop, hay invest more để real integrate?

## Decision

**Chose:** Option A — Keep mock implementation cho đồ án 2, document rõ trong UC032 là demo workflow, defer real integration cho Phase 5+ production scope.

**Why:** Đồ án 2 mục tiêu là **demonstrate capability** (admin UI cho MLOps workflow) chứ không phải production MLOps platform. Real integration (MLflow, DVC, Kubeflow) cần 40-80h + infra (GPU server, S3, orchestration). Sunk cost 832 lines code đã có working UI/FE consume — xóa = waste. Risk: examiner hỏi "retrain pipeline đâu?" → response thẳng "đây là demo MLOps workflow, production sẽ integrate MLflow ở giai đoạn sau" (transparent + defensible).

## Options considered

### Option A (chosen): Keep mock + UC document + ADR future

**Description:**
- KHÔNG xóa 832 lines MLOps service code.
- KHÔNG real integrate (MLflow/DVC).
- **Document rõ trong UC032** rằng đây là "demo MLOps workflow để minh họa khả năng quản lý lifecycle model. Retrain pipeline được mock với delays nhân tạo cho mục đích demonstration."
- ADR-006 này record decision + Phase 5+ future trigger.
- Phase 4: add 3 validation middlewares + 3 audit log calls cho MLOps write endpoints (D-AIM-06, D-AIM-07).
- Phase 4: KHÔNG thêm real MLOps integration.

**Pros:**
- Tận dụng sunk cost code + FE.
- Demo capability cho examiner.
- Honest documentation (không lie về production-ready).
- Effort 0h xóa, ~1.5h cleanup (validation + audit log).
- Transparent với reviewer: "demo, not production" trong UC.

**Cons:**
- Code complexity: maintain 832 lines mock có thể confuse contributors tương lai.
- Tech debt: real MLOps eventually needed nếu scale.

**Effort:** ~1.5h Phase 4 (Q6 validation + Q7 audit log). 0h cho MLOps code itself.

### Option B (rejected): Drop MLOps hoàn toàn

**Description:**
- Xóa 12 MLOps endpoints + 832 lines service code + `ai-models-mlops.mock.js` + `ai_model_mlops_states` table.
- Focus on Core CRUD only (10 endpoints).
- FE pages tương ứng drop.

**Pros:**
- Cleaner codebase, easier review.
- Less maintenance burden.
- Honest: "we don't do MLOps".

**Cons:**
- **Sunk cost waste** — 832 lines + FE pages đã invest.
- Loss of demo capability (examiner thấy MLOps UI = bonus point).
- Decision asymmetry: easy to drop, hard to re-add later.

**Why rejected:** Sunk cost recovery + demo value cao hơn maintenance cost của mock code. Drop = burn working feature.

### Option C (rejected): Real MLOps integration Phase 4

**Description:**
- Replace mock với MLflow integration:
  - MLflow Tracking Server cho experiment tracking
  - DVC cho dataset versioning
  - Airflow / Prefect cho retrain orchestration
- Effort 40-80h.

**Pros:**
- Production-ready MLOps.
- Real metric tracking.
- Standard tooling.

**Cons:**
- **Out of scope đồ án 2** — 40-80h trên 2-3 tháng timeline = không feasible.
- Infrastructure cost (MLflow server, DVC remote storage, orchestration runner).
- Learning curve.
- Other modules đang chờ Phase 4 fix (LOGS, CONFIG, DASHBOARD, INTERNAL).

**Why rejected:** Time/effort không proportional với scope đồ án 2. Phase 5+ production scale có thể revisit.

### Option D (rejected): Hybrid — mock UI + simple Python script retrain

**Description:**
- Keep mock UI/endpoints.
- Add CLI script `scripts/retrain.py` thật retrain model local, save lên R2.
- UI chỉ trigger script qua subprocess.

**Pros:**
- Partial real implementation.
- Demo "can retrain thật" capability.

**Cons:**
- Complexity hybrid (UI mock + CLI real).
- Maintenance 2 codebases.
- Effort ~10-15h cho retrain script + tích hợp.

**Why rejected:** Kéo scope không đủ benefit. Phase 5+ nếu invest, đầu tư hẳn MLflow thay vì hybrid.

---

## Consequences

### Positive

- **Sunk cost preserved** — 832 lines + FE pages tiếp tục có giá trị demo.
- **Honest scope** — UC032 document rõ MLOps là demo, không over-promise.
- **Effort budget freed** — ~1.5h Phase 4 thay vì 40-80h, dồn cho LOGS/CONFIG/DASHBOARD/INTERNAL.
- **Reversible** — Phase 5+ có thể replace mock với real MLflow integration mà không break UI.

### Negative / Trade-offs accepted

- **Tech debt** — 832 lines mock code phải maintain. Mitigation: code clear, naming explicit (`buildGenericDataset` chứ không `runDatasetPipeline`), template files separated trong `mocks/`.
- **Potential reviewer confusion** — examiner đọc code có thể nghĩ là production-ready. Mitigation: UC032 + ADR-006 + comment header ở top `ai-models-mlops.service.js` explicit "DEMO MODE - SEE ADR-006".
- **Mock numbers thiếu realistic** — drift score, F1 lift đều tính từ arithmetic. Em accept và mitigate bằng UC032 explicit ghi "Mock data dùng template values for demonstration".

### Follow-up actions required

- [ ] **HealthGuard Phase 4 — D-AIM-06:** Add `validate()` middleware cho 3 MLOps POST endpoints (`/datasets/build-next`, `/retrain`, `/deploy-candidate`). (~1h)
- [ ] **HealthGuard Phase 4 — D-AIM-07:** Add audit log calls cho `ai_model.retrain_triggered`, `ai_model.candidate_deployed`, `ai_model.dataset_built`. (~30min)
- [ ] **HealthGuard Phase 4 (optional):** Add code comment header ở `ai-models-mlops.service.js` line 1: `// DEMO MODE: MLOps workflow is mock-based per ADR-006. Real integration deferred to Phase 5+.`
- [ ] **PM_REVIEW Phase 4:** Tạo `UC032_AI_Model_MLOps.md` với explicit section "Mock Implementation Note" reference ADR-006.
- [ ] **PM_REVIEW Phase 4:** Tạo `UC031_Manage_AI_Models.md` (Core CRUD + version).

## Reverse decision triggers

Conditions để reconsider quyết định này:

- **Production deployment với real users** → cần real retrain pipeline → Option C MLflow integration.
- **Model performance issues observed** in production → cần data drift detection thật + retrain automation → reconsider.
- **Team grows beyond solo** → có capacity cho 40-80h MLOps work → revisit.
- **Compliance requirement** (FDA AI/ML guidance, EU AI Act) → cần auditable retrain trail → real platform needed.
- **External grant / commercial customer** → cần production-grade MLOps story → real integration.
- **Mock code burden exceeds maintenance threshold** (vd: bug khó trace do mock leak) → đánh giá Option B drop.

## Related

- UC: **UC031** Manage AI Models (CRUD), **UC032** AI Model MLOps (mock workflow) — pending creation Phase 4
- ADR: standalone — coordinated với ADR-007 (R2 disconnect)
- Bug: triggered by Phase 1.5 intent drift review AI_MODELS finding (Q2)
- Code:
  - `HealthGuard/backend/src/services/ai-models-mlops.service.js` (832 lines)
  - `HealthGuard/backend/src/mocks/ai-models-mlops.mock.js` (templates)
  - `HealthGuard/backend/src/routes/ai-models.routes.js:41-52` (MLOps routes)
  - DB table `ai_model_mlops_states` (JSON payload column)
- Spec: pending `UC032_AI_Model_MLOps.md`
- Intent drift review: `AUDIT_2026/tier1.5/intent_drift/healthguard/AI_MODELS.md`

## Notes

- **Why không dùng feature flag để toggle mock vs real?** Phase 5+ replace mock implementation entirely — không cần feature flag at code level. Toggling sẽ thêm complexity (2 code paths) không benefit.
- **Why không invest minimum real MLOps (vd chỉ MLflow tracking, không retrain)?** Half-measure không demonstrably better than mock cho đồ án 2 demo. Reviewer either accept mock (Option A) hoặc demand full (Option C); intermediate không strong story.
- **Mock-vs-real boundary:** Dataset file upload **thật** vào R2 (đã verify code). Metadata mock. Boundary này clear trong code — `uploadDatasetSourceFile` là real R2 call, `buildGenericDataset` là template-based mock.
