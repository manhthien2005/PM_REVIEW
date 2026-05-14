# Intent Drift Review — `HealthGuard / AI_MODELS`

**Status:** � Confirmed (anh chọn theo em recommend Q1-Q7; tất cả 7 add-ons drop)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** AI_MODELS (Catalog + Version management + MLOps overlay)
**Related UCs (old):** **NONE** — module orphan, không có UC mapping
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 7 (large surface area + 1 CRITICAL scope decision về MLOps mock)

---

## 🎯 Mục tiêu

Capture intent cho AI_MODELS module — module lớn nhất hiện tại với 22 endpoints + R2 storage. **Bao gồm 1 critical scope decision: MLOps endpoints hiện tại HOÀN TOÀN là mock/demo, không kết nối với pipeline thật.**

---

## 📚 UC tham chiếu — KHÔNG CÓ

Em đã verify: KHÔNG có UC031/UC032 hoặc bất kỳ UC nào mention `ai_model`/MLOps trong `PM_REVIEW/Resources/UC/`. Cross-reference duy nhất là UC027 Dashboard mention `aiModelsActive` count.

**Em đề xuất Approach:**
- **Approach A (em recommend):** Tạo 2 UC mới:
  - `UC031_Manage_AI_Models.md` (CRUD models + version)
  - `UC032_AI_Model_MLOps.md` (retrain pipeline, dataset management) — **tùy decision Q2**
- **Approach B:** Tạo 1 UC tổng `UC031_AI_Model_Lifecycle.md` cover cả 2 phần
- **Approach C:** Drop MLOps khỏi scope → chỉ cần UC031 cho CRUD

→ Decision phụ thuộc Q2 (MLOps scope).

---

## 🔧 Code state

### Routes (`ai-models.routes.js`) — 22 endpoints (lớn nhất system)

```
authenticate + requireAdmin + multer 500MB upload limit

# Core CRUD (10 endpoints)
GET    /api/v1/ai-models                       List với pagination + search + filter task
GET    /api/v1/ai-models/:id                   Detail + active_version + versions
POST   /api/v1/ai-models                       Create (key, display_name, task, description)
PATCH  /api/v1/ai-models/:id                   Update
PUT    /api/v1/ai-models/:id                   Update (alias)
DELETE /api/v1/ai-models/:id                   Soft delete + R2 cleanup transaction

# Version management (5 endpoints)
GET    /api/v1/ai-models/:id/versions           List versions
GET    /api/v1/ai-models/:id/versions/next      Get next semver version (auto-calculated)
POST   /api/v1/ai-models/:id/versions           Upload artifact (multipart, max 500MB → R2)
PATCH  /api/v1/ai-models/:id/versions/:vId      Update status (state machine)
PUT    /api/v1/ai-models/:id/versions/:vId      Update (alias)
DELETE /api/v1/ai-models/:id/versions/:vId      Soft delete + R2 cleanup

# MLOps overlay (12 endpoints) — TẤT CẢ MOCK
GET    /api/v1/ai-models/mlops/models                          List với MLOps metadata overlay
POST   /api/v1/ai-models/mlops/models                          Create
GET    /api/v1/ai-models/mlops/models/:id                      Detail
GET    /api/v1/ai-models/mlops/models/:id/versions             Versions
GET    /api/v1/ai-models/mlops/models/:id/datasets             Datasets
GET    /api/v1/ai-models/mlops/models/:id/data-diff            Data drift comparison
GET    /api/v1/ai-models/mlops/models/:id/model-diff           Model metrics comparison
GET    /api/v1/ai-models/mlops/models/:id/feedback-summary     Feedback aggregation
GET    /api/v1/ai-models/mlops/models/:id/retrain-jobs         Retrain job history
POST   /api/v1/ai-models/mlops/models/:id/datasets/build-next  Build new dataset (multipart)
POST   /api/v1/ai-models/mlops/models/:id/retrain              Trigger retrain (mock setTimeout)
POST   /api/v1/ai-models/mlops/models/:id/deploy-candidate     Deploy candidate (state update only)
```

### Service highlights (`ai-models.service.js` 415 lines + `ai-models-mlops.service.js` 832 lines)

**✅ Strengths:**
- **Audit log đầy đủ** mọi action: created, updated, deleted, version.uploaded, version.activated, version.deprecated, version.reverted, version.deleted (✓ pattern consistent với LOGS module)
- **SHA256 hash + size tracking** cho artifact (integrity)
- **Soft delete** + R2 cleanup + transaction wrapping
- **Status state machine** rõ ràng: draft → published → deprecated → draft
- **Active version concept** (1 published per model, auto-deprecate previous)
- **R2 upload với @aws-sdk/lib-storage** (multipart support cho file lớn)
- **Multer memoryStorage** với 500MB limit (matches model size budgets)

**🔴 CRITICAL findings:**

1. **MLOps service 832 lines = ENTIRELY MOCK/DEMO**
   - Imports template từ `mocks/ai-models-mlops.mock.js`
   - `retrainModel`: dùng `setTimeout(..., 2200)` để fake retrain → trả candidate version từ template
   - `buildGenericDataset`: hard-coded numbers (`numSamples: 8600`, `drift: 0.12`)
   - KHÔNG có integration với MLflow / DVC / Kubeflow / SageMaker / bất kỳ MLOps platform thật nào
   - **Storage:** dataset upload thật vào R2 nhưng metadata + retrain results đều mock

2. **Disconnect: R2 artifact ↔ model API serving**
   - Admin upload model lên R2: `ai-models/{model.key}/{version}/artifact.{ext}`
   - **NHƯNG** `healthguard-model-api` load model từ **LOCAL FILESYSTEM** path: `models/healthguard/healthguard_bundle.joblib`
   - → Active version concept trong AI_MODELS module HOÀN TOÀN không ảnh hưởng đến model serving runtime
   - → Admin "switch active version" trong admin web KHÔNG thay đổi model nào đang serve

3. **Strict semver MAJOR-only enforcement** (line 17-35, 254-262)
   ```js
   return `${maxMajor + 1}.0.0`;  // 1.0.0 → 2.0.0 → 3.0.0 → ...
   ```
   - KHÔNG cho phép minor (1.1.0) hoặc patch (1.0.1) bumps
   - Validate `version !== expectedVersion` → reject
   - Logic không hợp lý cho ML versioning convention

4. **R2 upload BEFORE DB record create** (line 279-293)
   ```js
   await r2Service.uploadFile(buffer, r2Key);  // R2 first
   const versionRecord = await prisma.ai_model_versions.create({...});  // DB second
   ```
   - Nếu DB create fail → orphan file ở R2 (cost waste, không cleanup)
   - Race condition: 2 admin upload cùng version → 1 R2 upload thắng + 1 DB create fail → orphan

5. **R2 config error message expose env var names** (`r2.service.js:11-13`)
   ```js
   throw ApiError.badRequest('R2 chưa được cấu hình. Vui lòng thiết lập R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME.');
   ```
   - Error response leak env var names (security info leak nhỏ, accept với admin-only endpoints)

**🟡 Medium findings:**
- Schema validation thiếu cho some endpoints MLOps (chỉ Core CRUD có `validate()` middleware)
- `format` enum: pt, pth, onnx, tflite, h5, keras, pb, pkl, joblib, zip — đầy đủ nhưng không có per-format validation (vd .pt phải có magic bytes match)
- Routes ordering: MLOps routes trước Core routes — OK nhưng `/mlops/models` có thể conflict với potential `/:id`. Currently safe vì Core routes định nghĩa sau và Express route `/mlops/...` match trước `/:id`.

---

## 💬 Anh react block

> 7 câu — module lớn nhất, không pad. Q2 là CRITICAL scope decision.

---

### Q1: UC scope cho AI_MODELS module

**Context:** Module orphan, 22 endpoints. Cần UC mới hoặc ADR.

**Em recommend:**
- **Approach A:** 2 UCs riêng:
  - **UC031 Manage AI Models** (CRUD models + version) — core feature
  - **UC032 AI Model MLOps** (retrain, dataset, drift) — phụ thuộc Q2
- Ngoài ra ADR record disconnect issue (Q4)

**Anh decision:**
- ✅ **Em recommend (2 UCs riêng, UC032 phụ thuộc Q2)** ← anh CHỌN
- ☐ 1 UC tổng `UC031_AI_Model_Lifecycle.md`
- ☐ Skip UC, chỉ ADR (technical contract)
- ☐ Khác: ___

---

### Q2: 🔴 CRITICAL — MLOps scope (mock vs real)

**Context:**
- 12/22 endpoints là MLOps overlay
- 832 lines service code dùng template mock + setTimeout fake delays
- KHÔNG có MLOps platform integration (MLflow / DVC / Kubeflow)
- Dataset upload có lưu R2 thật nhưng metadata mock

**Trade-off:**
- **Keep MLOps mock (hiện trạng):** demo capability cho đồ án 2 (5 phút show admin "trigger retrain"). Effort 0h. Risk: examiner hỏi "retrain pipeline đâu?" → unimpressed.
- **Drop MLOps endpoints + UI:** clean codebase, focus on Core CRUD. Effort ~2h xóa code. Risk: mất feature đã có (sunk cost).
- **Real MLOps integration:** integrate MLflow / DVC. Effort 40-80h. Out of scope đồ án 2.

**Em recommend:**
- **Keep mock + document rõ trong UC032** rằng đây là "demo MLOps workflow, retrain pipeline được mock cho mục đích demonstration. Production sẽ integrate MLflow ở Phase 5+"
- **ADR record:** "MLOps mock acceptable cho đồ án 2 demo, future production cần real integration"
- KHÔNG xóa code (sunk cost + đã có FE consume)
- Phase 4 KHÔNG thêm gì cho MLOps (chỉ document)

**Anh decision:**
- ✅ **Em recommend (keep mock + UC document + ADR future)** ← anh CHỌN
- ☐ Drop MLOps hoàn toàn (xóa 12 endpoints + 832 lines service + FE pages)
- ☐ Real MLOps integration Phase 4+ (out of scope)
- ☐ Khác: ___

---

### Q3: Strict semver MAJOR-only — relax cho minor/patch?

**Code current behavior:**
```
v1 model → upload version "2.0.0" (forced)
v2 model retrain → upload version "3.0.0" (forced major bump)
```

**Issue:**
- ML convention: major = architecture change (LightGBM → XGBoost), minor = retrain với new data, patch = preprocessing tweak
- Code force major bump cho mọi upload → version number explode (10 retrains = v10.0.0)
- KHÔNG match với MLOps `model-version-{id}-v{n}` (mock dùng `vN.0.0` only — consistent với strict semver)

**Em recommend:**
- **Relax thành flexible semver** với constraint:
  - Bất kỳ X.Y.Z hợp lệ
  - Validate "không trùng version đã tồn tại"
  - Validate "phải lớn hơn version cao nhất hiện tại" (so sánh semver)
- Auto-suggest next version vẫn dùng `getNextVersion()` nhưng default minor bump (1.0.0 → 1.1.0) thay vì major
- Major bump cho explicit user request (vd UI dropdown: minor/major/patch)

**Anh decision:**
- ✅ **Em recommend (flexible semver, default minor bump)** ← anh CHỌN
- ☐ Keep strict major-only (less complex, đồ án 2 demo OK)
- ☐ Khác: ___

---

### Q4: Disconnect R2 artifact ↔ model API serving

**Context:**
- AI_MODELS module: admin upload `.pt` / `.joblib` lên R2, set active_version
- `healthguard-model-api`: load model từ **LOCAL filesystem** (`models/fall/fall_bundle.joblib`)
- → Admin "switch active version" KHÔNG có effect runtime

**Implications:**
- Admin module hiện tại = **catalog UI demo only**, không control model serving thực sự
- Để có effect: model API cần endpoint `POST /admin/reload-model` (load từ R2) hoặc startup load từ R2 thay vì local

**Em recommend:**
- **Document rõ trong UC031 + ADR** rằng module hiện tại là "metadata catalog" giai đoạn 1, model serving stays local file Phase 4
- **Phase 5+ enhancement (defer):** model API thêm endpoint reload-from-R2 + active_version_id param. AI_MODELS Service trigger reload sau khi `published` status set.
- KHÔNG implement Phase 4 (out of scope đồ án 2 + cross-repo coord)

**Anh decision:**
- ✅ **Em recommend (document disconnect, defer model serving integration)** ← anh CHỌN
- ☐ Implement Phase 4 (~6h cross-repo: model API reload endpoint + AI_MODELS service trigger)
- ☐ Khác: ___

---

### Q5: R2 upload BEFORE DB record create — fix orphan file risk

**Code current:**
```js
await r2Service.uploadFile(buffer, r2Key);  // R2 success
const versionRecord = await prisma.ai_model_versions.create({...});  // DB might fail → orphan R2 file
```

**Em recommend:**
- **Phase 4 fix (~30min):** Reverse ordering với rollback compensation:
  ```js
  // 1. DB record draft (artifact_path placeholder)
  // 2. R2 upload
  // 3. DB update artifact_path
  // Failure handling: if R2 upload fail → DB delete (rollback)
  ```
- HOẶC **simpler:** Try-catch quanh DB create, on failure → R2 delete:
  ```js
  await r2Service.uploadFile(...);
  try {
    await prisma.ai_model_versions.create({...});
  } catch (err) {
    await r2Service.deleteFile(r2Key).catch(() => {}); // best-effort cleanup
    throw err;
  }
  ```
- Em prefer **Option B (try-catch)** cho đơn giản, low effort.

**Anh decision:**
- ✅ **Em recommend (try-catch compensation, ~30min)** ← anh CHỌN
- ☐ Reverse ordering với 2-phase commit (~1h, more robust)
- ☐ Skip (low probability, accept risk)
- ☐ Khác: ___

---

### Q6: Schema validation cho MLOps endpoints

**Current state:**
- Core CRUD endpoints có `validate(createModelRules)` / `validate(updateModelRules)` / `validate(updateVersionRules)` middleware
- 12 MLOps endpoints KHÔNG có schema validation (chỉ check controller-side ad-hoc)

**Em recommend:**
- **Phase 4 add validation cho 3 POST MLOps endpoints** (write operations):
  - `/mlops/models/:id/datasets/build-next`: validate file mimetype/size
  - `/mlops/models/:id/retrain`: validate `baselineModelVersion`, `datasetVersion`
  - `/mlops/models/:id/deploy-candidate`: validate `candidateModelVersion`
- GET endpoints không cần validation (read-only)
- Effort ~1h

**Anh decision:**
- ✅ **Em recommend (add validation cho 3 POST endpoints)** ← anh CHỌN
- ☐ Skip (Q2 keep mock, mock không cần strict validation)
- ☐ Add cho TẤT CẢ 12 endpoints
- ☐ Khác: ___

---

### Q7: Audit log scope verify

**Current state:** Service đã có audit log đầy đủ:
- `ai_model.created/updated/deleted`
- `ai_model_version.uploaded/activated/deprecated/reverted/deleted`

**Missing:**
- MLOps actions: `ai_model.retrain_triggered`, `ai_model.candidate_deployed`, `ai_model.dataset_built`
- Read actions (như LOGS module D-LOGS-01) — có cần log "ai_model.viewed" không?

**Em recommend:**
- **Add audit log cho MLOps write actions** (retrain, deploy candidate, build dataset) — consistent với pattern hiện tại
- **KHÔNG log read actions** (consistent với LOGS D-LOGS-01: skip browsing)
- Effort ~30min add 3 audit log calls

**Anh decision:**
- ✅ **Em recommend (add MLOps write actions, skip read)** ← anh CHỌN
- ☐ Add cho cả read actions (full audit trail)
- ☐ Skip nếu Q2 drop MLOps
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope (anh đã yêu cầu rõ "cắt giảm những cái không thật sự cần thiết"):

- ❌ **Model artifact integrity check** — Q4 defer model serving → chưa load lại artifact, verify chưa relevant
- ❌ **Model card export** — Google Model Cards standard nhưng overkill đồ án 2
- ❌ **Versioning UI helpers** — FE concern; BE `getNextVersion` endpoint đã có sẵn
- ❌ **Artifact format auto-detect** — user explicit select đủ
- ❌ **Webhook notification** — Phase 5+ external integration scope
- ❌ **Model A/B testing** — chỉ relevant nếu Q4 implement (defer)
- ❌ **Concurrent upload protection** — Q5 try-catch đã defense + single admin, race unlikely

**Rationale:** Q1-Q7 đã cover essentials. Đồ án 2 scope đã đủ lớn với 22 endpoints + R2 + MLOps mock.

---

## 🆕 Features anh nghĩ ra

_(anh add nếu có)_

---

## ❌ Features anh muốn DROP

_(anh add nếu có — ví dụ drop MLOps theo Q2)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC/ADR mới |
|---|---|---|
| **NONE — orphan module lớn** | Resolved | **UC031 Manage AI Models** (CRUD + version, em tạo sau) + **UC032 AI Model MLOps** (mock workflow, document rõ là demo) + ADR-006 MLOps mock + ADR-007 R2 disconnect |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| MLOps mock scope (Q2) | Keep mock + document (D-AIM-02) | 0h code; chỉ UC032 + ADR-006 doc | 🔴 Scope decision |
| Strict semver (Q3) | Relax flexible semver default minor (D-AIM-03) | `feat: relax semver validation, default minor bump` (~1h) | 🟡 Medium |
| Disconnect R2 ↔ model API (Q4) | Defer Phase 5+ (D-AIM-04) | 0h HealthGuard; ADR-007 document | Defer |
| R2 upload-before-DB orphan (Q5) | Try-catch compensation (D-AIM-05) | `fix: rollback R2 upload on DB create failure` (~30min) | 🟡 Medium |
| Schema validation MLOps (Q6) | Add 3 POST endpoints (D-AIM-06) | `feat: validate() middleware for 3 MLOps write endpoints` (~1h) | 🟡 Medium |
| MLOps audit log (Q7) | Add 3 write actions (D-AIM-07) | `feat: audit log for MLOps retrain/deploy/dataset` (~30min) | 🟢 Low |

**Estimated Phase 4 effort:** ~3h HealthGuard code + 2 UC + 2 ADR

### Cross-repo deferred for Phase 5+

- **R2 ↔ model API integration** (Q4): model API thêm endpoint `POST /admin/reload-model` + active_version_id param. AI_MODELS service trigger reload sau `published` status set. Out of scope đồ án 2.

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-AIM-01 | UC scope | **2 UCs riêng: UC031 (CRUD) + UC032 (MLOps mock)** | Tách concerns; UC032 document rõ là demo workflow |
| D-AIM-02 | MLOps mock scope | **Keep mock + document trong UC032 + ADR-006** | Sunk cost; demo capability đồ án 2; KHÔNG xóa code; KHÔNG real integration (out of scope) |
| D-AIM-03 | Strict semver | **Relax flexible semver, default minor bump** | ML convention: major = architecture change, minor = retrain new data, patch = fix |
| D-AIM-04 | R2 ↔ model API disconnect | **Defer Phase 5+, document trong ADR-007** | Cross-repo coord + out of scope đồ án 2; module là catalog UI Phase 1 |
| D-AIM-05 | R2 upload ordering fix | **Try-catch compensation rollback** | Đơn giản, low effort, cover failure case orphan file |
| D-AIM-06 | Schema validation MLOps | **Add cho 3 POST write endpoints** | Defense-in-depth; consistent với Core CRUD pattern |
| D-AIM-07 | MLOps audit log | **Add 3 write actions (retrain/deploy/dataset)** | Consistent với existing audit pattern; skip read (LOGS D-LOGS-01 alignment) |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Model artifact integrity check | ❌ Drop (Q4 defer) |
| Model card export | ❌ Drop (overkill) |
| Versioning UI helpers | ❌ Drop (FE concern) |
| Artifact format auto-detect | ❌ Drop |
| Webhook notification | ❌ Drop (Phase 5+) |
| Model A/B testing | ❌ Drop (Q4 defer) |
| Concurrent upload protection | ❌ Drop (Q5 try-catch đủ) |

**All 7 add-ons dropped** — anh ưu tiên tránh scope creep.

---

## Cross-references

- Routes: `HealthGuard/backend/src/routes/ai-models.routes.js`
- Services: `HealthGuard/backend/src/services/ai-models.service.js` (415 lines), `ai-models-mlops.service.js` (832 lines), `r2.service.js` (78 lines)
- Mocks: `HealthGuard/backend/src/mocks/ai-models-mlops.mock.js`
- DB tables: `ai_models`, `ai_model_versions`, `ai_model_mlops_states`
- Storage: Cloudflare R2 (S3-compatible)
- Phase 1 audit: M02 Routes, M04 Services
- Cross-repo:
  - `healthguard-model-api`: model serving (disconnect Q4)
  - Reference paths: `models/fall/fall_bundle.joblib`, `models/healthguard/healthguard_bundle.joblib`, `models/Sleep/sleep_score_bundle.joblib`
- ADR candidate: `<NNN>-mlops-mock-vs-real-decision.md` (depending Q2)
- ADR candidate: `<NNN>-r2-storage-strategy.md` (cross-cutting với potential model serving integration)
- UC027 v2: mention `aiModelsActive` count (cross-ref)
