# Audit: M07 — Jobs + Utils + Config + Mocks

**Module:** `HealthGuard/backend/src/{jobs, utils, config, mocks}/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

- `jobs/risk-score-job.js` (~85 LoC) — cron mỗi 5 phút, gọi `riskCalculatorService.calculateAllRiskScores`, WebSocket emit, cleanup 30d+ old records
- `jobs/vital-processor.js` (~110 LoC) — cron mỗi 5 phút, disabled mặc định (drift VITAL_ALERT_ADMIN D-VAA-01)
- `utils/ApiError.js` (~55 LoC) — error class với factory methods (badRequest/unauthorized/forbidden/notFound/conflict/locked/internal)
- `utils/ApiResponse.js` (~55 LoC) — response helper (success/created/noContent/paginated)
- `utils/catchAsync.js` (~10 LoC) — async error wrapper
- `utils/email.js` (~130 LoC) — Nodemailer + Gmail SMTP, 3 template (reset link, credential-changed notification, account locked)
- `utils/passwordValidator.js` (~125 LoC) — strength check (length/case/digit/special + admin stricter + sequential detect)
- `utils/prisma.js` (~20 LoC) — Prisma singleton với globalThis cache
- `utils/__mocks__/prisma.js` — jest mock stub
- `config/env.js` (covered trong M01)
- `config/swagger.js` (covered trong M01)
- `mocks/ai-models-mlops.mock.js` (~280 LoC) — mock data + helper cho MLOps orchestration (ADR-006)

**Out of scope:** `config/env.js` + `config/swagger.js` (audit in M01), service-side mlops integration (part of M04).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | ApiError + ApiResponse + catchAsync + prisma singleton đúng pattern. passwordValidator cover length/case/digit/special. Nhưng vital-processor.js permanently disabled (drift D-VAA-01 resolve), risk-score-job thiếu lock (concurrent instance race). |
| Readability | 3/3 | Utils ngắn gọn (≤130 LoC mỗi file), JSDoc đầy đủ, factory methods naming clear (`ApiError.badRequest`, `ApiResponse.paginated`). Jobs có banner + comment mỗi step. Mocks có template naming structured. |
| Architecture | 3/3 | Single responsibility mỗi util. prisma singleton đúng pattern, globalThis cache cho hot-reload. Factory methods tránh direct constructor call. Jobs singleton instance + start/stop lifecycle. |
| Security | 2/3 | email.js có config-missing fallback log + skip (không crash), passwordValidator có admin stricter rule + max 128 length (DoS prevention). Gaps: email.js không HTML escape user name (XSS tiềm năng trong email body), admin sequential check có thể false positive. |
| Performance | 3/3 | Prisma singleton chuẩn. passwordValidator O(n) regex. catchAsync O(1) wrapper. Jobs cleanup query scope bị giới hạn (30d+ delete), không bloat. |
| **Total** | **13/15** | Band: **🟢 Mature** |

## Findings

### Correctness (2/3)

- ✓ `ApiError.js:22-46` — 7 factory methods (badRequest/unauthorized/forbidden/notFound/conflict/locked/internal) map đúng HTTP status 400/401/403/404/409/423/500. `isOperational: true` flag phân biệt programming error vs expected error.
- ✓ `ApiResponse.js:18-50` — success/created/noContent/paginated helper đúng status 200/201/204. Paginated tự tính totalPages.
- ✓ `catchAsync.js:13` — wrapper chuẩn `Promise.resolve(fn(req,res,next)).catch(next)` → async error bubble lên errorHandler.
- ✓ `prisma.js:10-17` — singleton pattern với `globalThis.prisma ??` — hot-reload nodemon không tạo nhiều connection pool.
- ✓ `prisma.js:12-13` — log level dev = `['query', 'warn', 'error']`, production = `['error']` → dev debugging đầy đủ, production không leak query content.
- ✓ `passwordValidator.js:18-92` — check `minLength` 8 (user) / 12 (admin), max 128 (DoS prevention), uppercase/lowercase/digit/special char regex. Vietnamese error messages consistent.
- ✓ `email.js:22-47` — config-missing fallback (`if !EMAIL_USER || !EMAIL_PASS`) → log warn + skip, không crash flow. Admin reset flow vẫn thành công dù email fail.
- ✓ `risk-score-job.js:20-32` — defer first run 30s sau start → wait server fully boot trước khi query DB. Interval 5 phút consistent.
- ✓ `risk-score-job.js:59-66` — cleanup query `deleteMany` với `calculated_at: { lt: thirtyDaysAgo }` → retention policy đúng, không bloat.
- ⚠️ **P2 — `risk-score-job.js` không có lock** — nếu deploy multi-instance (PM2 cluster, K8s replica) → mỗi instance chạy cron riêng → `calculateAllRiskScores` chạy N lần/5min → conflicting writes + duplicate WebSocket emits. Đồ án 2 single-instance OK, production cần `node-cron` với distributed lock (Redis + `setnx`) hoặc leader election. Priority P3 (Phase 5+ scale).
- ⚠️ **P2 — `vital-processor.js:7` comment "ĐÃ TẮT THEO YÊU CẦU SẾPF"** — typo "SẾPF" trong production code. `enabled = false` mặc định (drift VITAL_ALERT_ADMIN D-VAA-01). Phase 4 quyết định keep file + keep 3 endpoints manage lifecycle, nhưng file sẽ ít được update → typo persists. Priority P3.
- ⚠️ **P3 — `vital-processor.js:102-108` `setEnabled` gọi `this.start()` / `this.stop()` từ toggle**: nếu admin toggle true → bắt đầu run ngay không đợi check conflict. Nếu 2 admin cùng toggle đồng thời → race condition tạo 2 setInterval. Priority P3.
- ⚠️ **P3 — `mocks/ai-models-mlops.mock.js:280+ LoC` mock data literal values** — ADR-006 quyết định MLOps mock thay real integration cho đồ án 2. OK. Nhưng template naming (`datasetV1Template`, `modelV2CandidateTemplate`) không parametric → mỗi khi demo cần đổi số liệu phải edit file. Priority P3 cosmetic.

### Readability (3/3)

- ✓ Utils files đều ≤130 LoC, mỗi function ≤30 LoC → reader scan 1 lượt hiểu.
- ✓ JSDoc top file (`ApiError.js:3-8`, `ApiResponse.js:4-9`, `catchAsync.js:3-12`, `passwordValidator.js:2-5`) — usage example ngay trong comment.
- ✓ Factory method naming clear (`ApiError.badRequest('msg')` self-documenting) — caller không cần nhớ status code.
- ✓ `risk-score-job.js` + `vital-processor.js` có banner comment + section mỗi method (`start`, `stop`, `run`/`processVitals`, `setEnabled`, `getStatus`).
- ✓ `email.js:35-47, 66-79, 99-111` HTML template Vietnamese inline readable, có color code + padding style rõ.
- ✓ `ai-models-mlops.mock.js:14-24` constants tách riêng top file (`RETRAIN_THRESHOLDS`, `DATA_BALANCING_CONFIG`, `FEATURE_ORDER`) → tunable ở 1 chỗ.
- ⚠️ **P3 — Emoji trong code** (`risk-score-job.js:24, 35, 46, 54, 59, 66, 70` có nhiều emoji literal trong console.log; `vital-processor.js:23, 31, 37, 47, 52, 61, 69, 74, 96, 101, 102` similar; `email.js:27, 58, 89` có emoji trong warn) — rule workspace `00-operating-mode.md` cấm emoji trong code. Priority P3 — replace bằng `[OK]`, `[WARN]`, `[ERROR]` prefix.

### Architecture (3/3)

- ✓ **Single responsibility**: `ApiError` (error), `ApiResponse` (response), `catchAsync` (async wrap), `email` (SMTP), `passwordValidator` (strength check), `prisma` (client singleton). Không overlap.
- ✓ **Factory pattern** (`ApiError.badRequest(...)` vs `new ApiError(400, ...)`) — caller không phải remember status code + factory method semantic naming.
- ✓ `prisma.js:10-17` singleton đúng cho hot-reload — không memory leak do multiple PrismaClient instances.
- ✓ `risk-score-job.js` + `vital-processor.js` là class với singleton instance export — lifecycle methods `start/stop/getStatus` clean.
- ✓ `mocks/ai-models-mlops.mock.js:285+` export factory functions `buildInitialAIModel()`, `buildInitialState()`, `buildFeedbackRecords()` — caller invoke fresh instance, không shared mutable state.
- ✓ `utils/__mocks__/prisma.js` — jest-aware mock separated → test không import production prisma.
- ✓ `email.js` transporter singleton ở top file (`:6-13`) — 1 SMTP connection pool cho toàn process.

### Security (2/3)

- ✓ **passwordValidator.js strict rule:**
  - Min length 8 user / 12 admin (`:20-23`)
  - Max length 128 (`:25-27`) → prevent DoS via bcrypt CPU exhaustion
  - Uppercase + lowercase + digit + special char required (`:30-48`)
  - Admin stricter: ban common patterns (common numeric sequence, common strings like `admin/qwerty/abc123`, identical char repeat) (`:53-66`)
  - Sequential char detect (substring check qua alphabet/digit/qwerty rows) (`:70-87`)
- ✓ `email.js:27-31, 58-62, 89-93` — nếu env missing → `console.warn` + return (không throw, không leak SMTP config). Chấp nhận được.
- ✓ `ApiResponse.js` + `ApiError.js` không leak stack trace ra response body — tầng `errorHandler` handle production vs dev.
- ✓ `prisma.js:12-13` log level production `['error']` → không log query body (tránh leak PII + credential digest từ query params).
- ⚠️ **P2 — `email.js:68, 102` HTML template chứa `${userName}` chưa escape** — nếu `user.full_name` có `<script>` → XSS trong email body. Admin không thể trigger (user name validate Vietnamese regex tại register), nhưng defense-in-depth nên escape (`sanitize-html` hoặc `he.encode`). Priority P2.
  - File: `HealthGuard/backend/src/utils/email.js:68, 102`
- ⚠️ **P3 — `passwordValidator.js:70-87` sequential char detect có thể false positive**: check 3-char substring trong sequences `alphabet/digit/qwerty/asd/zxc`. Nếu user input = `MySafe123Pass!` → chứa `123` → reject. Strict rule OK cho admin security nhưng có thể frustrate legitimate user. Priority P3 — verify UX với test case + cân nhắc hạ độ nghiêm.
- ⚠️ **P3 — `email.js` không có rate limit** — gọi `sendPasswordResetEmail` / `sendAccountLockedEmail` không check rate. Nếu attacker spam `/forgot-password` với valid email → recipient inbox spam. `forgotPasswordLimiter 3/15min` per-IP trong M05 mitigate một phần. Priority P3 — add per-recipient rate limit ở service layer.

### Performance (3/3)

- ✓ `prisma.js` singleton — 1 connection pool toàn process, không leak.
- ✓ `catchAsync.js` — O(1) wrapper, không introduce overhead đáng kể.
- ✓ `ApiError.js` + `ApiResponse.js` — simple class/helper, không hit DB/external.
- ✓ `passwordValidator.js` — 5-6 regex match + 1 substring loop. O(n) với n = input length (≤ 128). Fast.
- ✓ `risk-score-job.js:58-64` cleanup query target 30d+ old rows → scope giới hạn, không table scan full.
- ✓ `email.js` transporter persistent connection — không tạo SMTP handshake mỗi lần send.
- ✓ `mocks/ai-models-mlops.mock.js` builder functions O(n) với n = feedback count (612) — pre-computed, không hot path.

## Recommended actions (Phase 4)

- [ ] **P2** — `email.js` HTML escape `${userName}` và các dynamic fields (~15 min dùng `he` hoặc `sanitize-html`).
- [ ] **P3** — Replace emoji trong `risk-score-job.js` + `vital-processor.js` + `email.js` console.log bằng text prefix `[OK]`, `[WARN]`, `[ERROR]`, `[INFO]` (~20 min).
- [ ] **P3** — Fix typo `SẾPF` → `SẾP` trong `vital-processor.js:7` comment (~1 min).
- [ ] **P3** — `vital-processor.js:102-108` `setEnabled` idempotency: check `this.enabled === enabled` trước khi gọi start/stop để tránh race (~10 min).
- [ ] **P3** — Verify `passwordValidator.js:70-87` sequential char false positive rate với test case thực tế; document trade-off (~30 min research).
- [ ] **P3 (Phase 5+)** — `risk-score-job.js` distributed lock (Redis `setnx` hoặc leader election) khi multi-instance deploy.
- [ ] **P3 (Phase 5+)** — `email.js` per-recipient rate limit để prevent spam abuse.
- [ ] **P3** — `ai-models-mlops.mock.js` parametric via env/config để dev tune demo values without code edit (~1h cosmetic).

## Out of scope (defer Phase 3 deep-dive)

- `riskCalculatorService.calculateAllRiskScores()` implementation deep review — covered M04.
- Job lifecycle during server shutdown (graceful vs forced) — Phase 3 ops audit.
- Email template i18n (English version) — Phase 5+ feature.
- Prisma query log redaction pattern — Phase 3 ops security.
- Jest mock fidelity (mock prisma match production signature) — Phase 3 test quality.
- `ai-models-mlops.mock.js` vs service layer interface — verify service consume mock correctly trong M04 ADR-006 deep-dive.

## Cross-references

- Phase 0.5 drift: [drift/VITAL_ALERT_ADMIN.md](../../tier1.5/intent_drift/healthguard/VITAL_ALERT_ADMIN.md) — D-VAA-01 keep vital-processor.js disabled default, lifecycle management 3 endpoints.
- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-06 register role (service-side depends auth.service.js validation).
- Phase 0.5 drift: [drift/CONFIG.md](../../tier1.5/intent_drift/healthguard/CONFIG.md) — D-CFG-05 validation strength scope.
- Phase 0.5 drift: [drift/AI_MODELS.md](../../tier1.5/intent_drift/healthguard/AI_MODELS.md) — MLOps mock scope (nếu có).
- ADR-006: [006-mlops-mock-vs-real-integration.md](../../../ADR/006-mlops-mock-vs-real-integration.md) — mocks/ai-models-mlops.mock.js mandate cho đồ án 2.
- ADR-007: [007-r2-artifact-vs-model-api-serving-disconnect.md](../../../ADR/007-r2-artifact-vs-model-api-serving-disconnect.md) — R2 wrapper (`r2.service.js` trong M04).
- M01 Bootstrap audit: `env.js` + `swagger.js` covered; `server.js` start jobs.
- M04 Services audit: services consume utils (prisma, ApiError, email, passwordValidator).
- M05 Middlewares audit: `catchAsync` + `validate` + `errorHandler` wire to utils.
- M06 Prisma schema audit: `utils/prisma.js` singleton client gen từ schema.
- Module inventory: M07 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M04_bootstrap_audit.md](../healthguard-model-api/M04_bootstrap_audit.md) — compare Node.js utils vs FastAPI dependencies.
