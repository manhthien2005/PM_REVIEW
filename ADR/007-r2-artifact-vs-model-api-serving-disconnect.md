# ADR-007: AI model artifact storage decouples from model serving — defer R2-to-runtime integration

**Status:** Accepted
**Date:** 2026-05-12
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, ai-models, healthguard, model-api, cross-repo, scope]

## Context

VSmartwatch HealthGuard có 2 module liên quan đến AI model nhưng **không kết nối với nhau**:

**Module 1: HealthGuard admin `AI_MODELS`**
- Admin upload artifact (`.pt`, `.joblib`, `.pkl`, ...) lên Cloudflare R2
- Path convention: `ai-models/{model.key}/{version}/artifact.{ext}`
- DB metadata: `ai_models`, `ai_model_versions`, `active_version_id`
- Status state machine: draft → published → deprecated
- Soft delete với R2 cleanup transaction

**Module 2: `healthguard-model-api`**
- Stateless FastAPI service serve 3 endpoints predict (fall, health, sleep)
- Model load từ **LOCAL filesystem** khi startup:
  - `models/fall/fall_bundle.joblib`
  - `models/healthguard/healthguard_bundle.joblib`
  - `models/Sleep/sleep_score_bundle.joblib`
- Cached in-memory sau load đầu tiên
- KHÔNG biết về R2, không biết về `active_version_id`

**Disconnect implications:**

- Admin "publish version 2.0.0" trong admin web → R2 upload thành công → `active_version_id` updated → **model API vẫn serve version local cũ**
- Admin "switch active version" → 0 effect runtime
- Module AI_MODELS hiện tại = **catalog UI demo only**, không control model serving thực sự
- Hệ thống effectively là: developer manually copy artifact vào `models/` directory → restart model API → serve new version

Phase 1.5 intent drift review phát hiện disconnect này (AI_MODELS Q4). Câu hỏi: implement integration Phase 4 hay defer?

## Decision

**Chose:** Option A — Defer R2-to-runtime integration cho Phase 5+, document disconnect rõ trong UC031 + ADR-007.

**Why:** Cross-repo integration cần:
- Model API thêm endpoint `POST /admin/reload-model` (load từ R2, swap in-memory cache)
- Model API thêm dependency `boto3` / `@aws-sdk` cho R2 client
- HealthGuard AI_MODELS service trigger reload sau `published` status set
- Internal service auth (ADR-005) coordination
- Concurrent access handling (model swap while serving requests)
- Failure rollback nếu new model load fail

Effort estimate: 6-10h. Cross-repo coordination + testing 2 services + production-grade error handling. Đồ án 2 timeline không proportional với benefit (1 admin, không có production load).

Defer cho phép Phase 4 focus on critical issues (LOGS, CONFIG, DASHBOARD, INTERNAL) đã có concrete bugs. Phase 5+ production scale có thể revisit khi cần.

## Options considered

### Option A (chosen): Defer + document

**Description:**
- KHÔNG implement R2-to-runtime integration Phase 4.
- ADR-007 record disconnect explicit.
- UC031 + UC032 document module hiện tại là "metadata catalog Phase 1".
- Phase 5+ trigger conditions ghi rõ.
- Admin workflow hiện tại: upload R2 (catalog tracking) + manually deploy model API (separate flow).

**Pros:**
- Zero Phase 4 effort cho integration.
- Phase 4 effort dồn cho concrete bugs (LOGS, CONFIG, etc).
- Decision reversible — implement sau khi cần.

**Cons:**
- Workflow lệch (admin tưởng "publish = deploy" nhưng không phải).
- UX confusion → mitigation: UI hint "Catalog only — model serving requires manual deployment" hoặc UC document.

**Effort:** 0h Phase 4. ADR + UC documentation.

### Option B (rejected): Implement R2-to-runtime integration Phase 4

**Description:**
- Model API thêm endpoint `POST /admin/reload-model` với body `{ model_key, version, r2_path }`.
- Endpoint:
  1. Authenticate internal secret (ADR-005)
  2. Download artifact từ R2 to temp file
  3. Load model bằng joblib/torch.load
  4. Swap in-memory cache (atomic pointer swap)
  5. Delete temp file
  6. Return success
- AI_MODELS service trigger reload sau `versionRecord.status = 'published'`:
  - HTTP POST to model API `/admin/reload-model`
  - Retry on failure (3x exponential backoff)
  - Audit log result
- Model API startup: load latest published version từ R2 thay vì local file.

**Pros:**
- True production-grade model lifecycle.
- Admin "publish" → instant serve.
- A/B test capability (Q4 add-on enabled).

**Cons:**
- **Cross-repo coordination** — 2 PRs đồng thời (HealthGuard + model-api).
- **Effort 6-10h** vs ~1-2h cho concrete bugs khác.
- **New failure modes:** model load fail mid-request, network timeout, R2 quota exceeded.
- **Concurrency complexity** — model swap atomic, queue requests during swap, hoặc serve stale during swap?
- **Test infrastructure** — integration test 2 services + R2 stub khó setup.

**Why rejected:** Effort/benefit không proportional cho đồ án 2 scale. Production scope nếu adopt VSmartwatch commercial.

### Option C (rejected): R2 startup-load only (no runtime reload)

**Description:**
- Model API startup: download artifact từ R2 (active_version_id matched) thay vì local file.
- KHÔNG có runtime reload — admin "publish" mới = phải restart model API.
- Restart manual / cron / health check trigger.

**Pros:**
- Halfway giải pháp — R2 = single source of truth.
- Effort ~2-3h.

**Cons:**
- Restart latency (model load 1-2s + service downtime).
- Vẫn cần coordination cross-repo.
- Admin UX vẫn confused ("phải restart manually").
- Production deployment vẫn cần orchestration (K8s rolling update, etc).

**Why rejected:** Halfway không add enough value vs Option A. Production sẽ cần Option B anyway.

### Option D (rejected): Keep local filesystem entirely

**Description:**
- Drop R2 storage hoàn toàn từ AI_MODELS module.
- Admin upload artifact vào local `models/` directory.
- DB chỉ store metadata + file path local.

**Pros:**
- Removes disconnect (single storage layer).
- Simpler code (no R2 client, no signed URL).

**Cons:**
- **Single point of failure** — local disk full → service down.
- Multi-instance deployment khó (shared filesystem NFS phức tạp).
- Backup/disaster recovery khó.
- Local upload security risk (path traversal, disk fill).
- Sunk cost: R2 service code đã invested.

**Why rejected:** R2 là correct long-term architecture cho cloud-native. Drop = regress.

---

## Consequences

### Positive

- **Phase 4 effort dồn cho concrete bugs** (LOGS, CONFIG, DASHBOARD, INTERNAL fixes có user-facing impact).
- **R2 architecture preserved** — Phase 5+ implement integration straightforward.
- **Honest documentation** — UC031 ghi rõ "catalog only, not control runtime", admin không confused.
- **Reversible** — implement sau với clear blueprint (Option B documented).

### Negative / Trade-offs accepted

- **UX inconsistency** — admin "publish" trong web không match "model deployed" runtime. Mitigation: UI badge "Catalog version" thay vì "Active version" (FE change), UC031 explicit ghi expectation.
- **Manual deployment workflow** — dev/admin phải copy artifact local + restart model API. Em accept và mitigate bằng script `scripts/deploy-model.sh` (Phase 4 optional, ~30min) tự động download R2 → copy local → restart container/process.
- **Tech debt** — disconnect tồn tại trong codebase. Mitigation: ADR-007 explicit + UC reference + Phase 5+ trigger conditions clear.

### Follow-up actions required

- [ ] **HealthGuard Phase 4 (optional, ~30min):** Add UI badge/label trên active version "Catalog version (manual deployment required)" để admin không confused về effect.
- [ ] **HealthGuard Phase 4 (optional, ~30min):** Add code comment header ở `ai-models.service.js` line 1: `// CATALOG ONLY: Active version concept không tự động sync với model API serving. See ADR-007.`
- [ ] **PM_REVIEW Phase 4:** UC031 explicit section "Scope Limitations" reference ADR-007.
- [ ] **Optional script Phase 4 (~30min):** `scripts/deploy-model.sh` để semi-automate workflow: download R2 by active_version_id → copy to model API container → restart.
- [ ] **Phase 5+ trigger (defer):** Re-evaluate khi production conditions met (see Reverse decision triggers).

## Reverse decision triggers

Conditions để reconsider quyết định này:

- **Multiple users deploy model API** (>1 dev triệu environment) → manual deployment chaos → Option B integration.
- **Auto-retrain pipeline real** (ADR-006 reverse) → cần model API consume new versions automatically.
- **A/B testing requirement** → cần dual-version serving → Option B endpoint + traffic splitter.
- **Compliance audit** đòi hỏi version traceability "model serving exact version X at time T" → cần R2 = source of truth runtime.
- **Production deployment with rollback SLA** → cần fast version switch không restart.
- **Model API container immutable** (K8s pattern) → cần R2 mount thay vì local file → Option C hoặc B.

## Related

- UC: **UC031** Manage AI Models (catalog) — pending creation
- ADR: ADR-005 (internal service secret — auth for cross-repo reload endpoint), ADR-006 (MLOps mock — sister scope decision)
- Bug: triggered by Phase 1.5 intent drift review AI_MODELS finding (Q4)
- Code:
  - `HealthGuard/backend/src/services/ai-models.service.js:277-303` (R2 upload during version create)
  - `HealthGuard/backend/src/services/r2.service.js` (R2 client)
  - `healthguard-model-api/app/main.py` + services (local model load)
  - `healthguard-model-api/app/config.py:53-55` (model path config)
- Spec: pending `UC031_Manage_AI_Models.md` (Section "Scope Limitations")
- Intent drift review: `AUDIT_2026/tier1.5/intent_drift/healthguard/AI_MODELS.md`

## Notes

- **Why R2 chứ không local disk?** R2 chọn vì:
  - Cloud-native storage (Cloudflare free tier sufficient cho đồ án)
  - S3-compatible (industry standard)
  - Backup/durability built-in
  - Multi-instance ready (Phase 5+)
- **Why model-api dùng local file?** Pre-existing design — model API thiết kế stateless với pre-baked model artifact trong container image / bind mount. Đây là common pattern cho ML serving (TFX, BentoML, Triton).
- **Compatibility check:** R2 path `ai-models/{model.key}/{version}/artifact.{ext}` map sang local path `models/{task}/...` không trực tiếp. Phase 5+ implement cần convention mapping.
- **Why not move model-api to load from R2 directly always?** Cold start latency. R2 download mỗi startup = 1-2s overhead. Local file = instant. Phase 5+ có thể cache R2 → local với version check on startup.
