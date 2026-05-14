# Audit: M08 — Backend tests

**Module:** `HealthGuard/backend/src/__tests__/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

21 test files trong 4 thư mục:
- `controllers/` (6 files): auth, dashboard, device, health, logs, user
- `middlewares/` (3 files): auth, errorHandler, validate
- `services/` (9 files): auth, ai-models, dashboard, device, emergency, health, logs, settings, user
- `utils/` (3 files): ApiError, ApiResponse, catchAsync

**Framework:** Jest 30 + jest-mock-extended, Node env, testMatch `**/src/__tests__/**/*.test.js`. Script `npm test` (verbose + forceExit) và `npm run test:coverage`.

**Out of scope:** Frontend tests (M17-M19 scope), integration tests (no `integration/` folder trong current structure), e2e tests (defer Phase 3 / PM_REVIEW scripts).

**Important note:** Framework v1 rubric KHÔNG include Testing axis trong 15-point total. Audit này report cho visibility, **KHÔNG tính vào score matrix**. Scope chấm = theo framework rubric 5 axes áp dụng lên file test như code bình thường.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Tests cover happy path + key error branches (user not found, unauthorized, conflict). Jest mock `prisma + bcrypt + jwt + email` đủ boundary. Nhưng có test mock data outdated (Q7 enum `'high'`, `'moderate'` — drift D-HEA-07 flag). |
| Readability | 2/3 | `describe` grouping theo method, `it` describe behavior Vietnamese/English mix. Section comment với `═════` separator đẹp. Nhưng một số test file (user, logs, auth) dài 300+ LoC, nested describes deep. |
| Architecture | 2/3 | Unit test isolation đúng (mock Prisma + external). 1 file mock prisma duy nhất ở `utils/__mocks__/prisma.js`. Thiếu integration test layer (controller → service → Prisma với test DB). Service test mock quá aggressive → verify cả implementation detail thay vì boundary. |
| Security | 3/3 | Không hard-code production credential trong test fixtures. JWT secret + email config mock ở test-local scope. Không commit test DB credentials. |
| Performance | 3/3 | Jest `--forceExit` đảm bảo không hanging. Mock Prisma eliminate DB roundtrip → fast suite. |
| **Total (out of 15 per framework)** | **12/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (2/3)

- ✓ **Jest config** (`package.json:15-25`): `testMatch` scoped đúng path, `modulePathIgnorePatterns: ['node_modules']` — không scan dev dependencies.
- ✓ **Mock setup consistent** ở đầu file test (vd `auth.service.test.js:1-29`):
  - `jest.mock('bcryptjs')`, `jest.mock('jsonwebtoken')`, `jest.mock('../../utils/prisma')`, `jest.mock('../../utils/email')`, `jest.mock('../../config/env', () => ({ ... }))`.
  - → Test isolate khỏi external dependencies + env.
- ✓ **Happy path + error branches** covered (vd `auth.service.test.js:36-55`):
  - `should throw 400 for invalid email format`
  - `should throw 401 if user not found`
  - `should throw 403 if account locked`
  - etc.
- ✓ **`describe` nested theo method** — `describe('authService') > describe('loginUser') > it('...')`. Scan structure rõ.
- ✓ **`afterEach jest.clearAllMocks()`** pattern ở `health.service.test.js:10`, `settings.service.test.js:12`, `logs.service.test.js:11`, `emergency.service.test.js:33`, `device.service.test.js:10`, `user.service.test.js:14` — reset mock state giữa tests, tránh bleed.
- ⚠️ **P1 — Test mock data outdated vs drift D-HEA-07** (`health.service.test.js:134`, `dashboard.service.test.js:134`): mock Prisma return với risk_level value `'high'` hoặc `'moderate'` — không match 3-level schema (LOW/MEDIUM/CRITICAL). Khi Phase 4 fix Q7, test sẽ false positive / negative. Priority P1 cùng group với D-HEA-07 fix.
  - File: `HealthGuard/backend/src/__tests__/services/health.service.test.js:134`, `dashboard.service.test.js:134`
- ⚠️ **P2 — Test mock "implementation detail" thay vì boundary** (vd `user.service.test.js:22-30`): test mock `prisma.users.findMany.mockResolvedValue([...])` rồi verify service trả pagination `totalPages`. Nếu service refactor đổi internal query pattern (findMany → $queryRaw) → test fail mặc dù boundary output đúng. Test pyramid steering nói "test ở boundary, không test internal implementation". Priority P2 — Phase 3 deep-dive rewrite test dùng in-memory Prisma (hoặc test DB) cho integration layer.
- ⚠️ **P2 — Không có test cho `vital-alert.controller.js` P0 bug** (M03 audit): `ApiResponse.success` signature bug. Test controller `vital-alert.controller.test.js` không tồn tại trong 6 controller tests → bug không catch được qua test suite. Drift D-VAA-01 drop 6 method → bug self-resolve, không cần thêm test. Priority P3.
- ⚠️ **P3 — Không có test cho `risk-calculator.service.js`** (Q7 INSERT fail) — service file không có test file tương ứng. Test suite không catch được constraint violation. Priority P2 per drift D-HEA-07 (thêm test sau khi fix).
  - File: `HealthGuard/backend/src/services/risk-calculator.service.js` (no test)

### Readability (2/3)

- ✓ **Section separator comment** (vd `user.service.test.js:18-20, 108-110, 128-130, 188-190, 214-216, 260-262`): banner với `═════` dài 55 chars chia mỗi method group → scan nhanh.
- ✓ **`it` statement Vietnamese/English mix consistent** — `it('should throw 404 if user not found', ...)` (English + specific behavior). Match convention dự án (code English, chat Vietnamese).
- ✓ **Comment ở top mỗi describe** giải thích scope (vd `user.service.test.js:12-17` comment `// UserService - Unit tests`).
- ⚠️ **P2 — Một số test file dài** (`user.service.test.js` ~350 LoC, `logs.service.test.js` ~370 LoC, `auth.service.test.js` ~500+ LoC): nested describes 2-3 level → scan khó, khó grep. Priority P3 — split thành multiple files theo method nếu >300 LoC (`user.service.findAll.test.js`, `user.service.create.test.js`, etc.).
- ⚠️ **P3 — Nested describes deep** (vd `ApiResponse.test.js`: `describe('ApiResponse') > describe('constructor') > it(...)`, `describe('success()') > it(...)`): 2-3 level nested OK nhưng gần ngưỡng readability. Priority P3.

### Architecture (2/3)

- ✓ **Unit test isolation** đúng: mock Prisma + external → test logic thuần service/controller.
- ✓ **Single mock source** — `utils/__mocks__/prisma.js` dùng chung → consistent signature across test files.
- ✓ **Controller test + Service test tách riêng** (`__tests__/controllers/` vs `__tests__/services/`) — test pyramid đúng layer.
- ⚠️ **P1 — Thiếu integration test layer** — chỉ có unit tests với full mock. Không có test `controller → service → real Prisma (test DB)` để verify contract layer. Steering test discipline nói Integration: FastAPI `with test DB`, Express `API route → service → mock Prisma`. Current state: mock Prisma → không catch được Prisma query syntax bug hoặc transaction isolation issue. Priority P2 — Phase 5+ setup integration test với Docker postgres test DB.
- ⚠️ **P2 — Mock quá aggressive** (user.service.test.js verify `prisma.users.findMany.mock.calls[0][0]` args thay vì output shape): coupling test với implementation detail. Nếu service dùng `$queryRaw` + hand-written SQL (per drift D-HEA-01 fix) → test không thể verify. Priority P2 — rewrite towards behavior-driven assertion.
- ⚠️ **P3 — Không có test coverage metric threshold** — `npm run test:coverage` có nhưng không enforce minimum. Steering nói "60-70% cho code mới". Priority P3 — add `coverageThreshold` trong jest config `:15-25`.
- ⚠️ `jest-mock-extended` dependency trong devDependencies — tận dụng type-safe mock (if TypeScript). Hiện repo JS → value hạn chế. Priority P3 cosmetic.

### Security (3/3)

- ✓ **Không hard-code production credential** — `auth.service.test.js:5-9` mock env với placeholder values (fake JWT secret string, fake FRONTEND_URL). Không leak real JWT secret hoặc DB URL.
- ✓ **Test fixture credentials là obvious placeholder** — không có pattern giống production (không dùng realistic employee email hoặc production user name).
- ✓ **Mock bcrypt + jwt** — không dùng real crypto trong test → fast + no `crypto.createHash` overhead.
- ✓ **Không commit `.env.test`** — `.env.example` committed, `.env*` gitignored (per `.gitignore`).
- ✓ **Mock `utils/email.js`** — không accidentally gửi email test ra SMTP thật.

### Performance (3/3)

- ✓ **`--forceExit`** flag trong `npm test` — Jest không hanging khi open handles tồn tại (vd lingering DB connection từ mock). Fast CI feedback.
- ✓ **Mock Prisma** eliminate DB roundtrip → test suite chạy nhanh (<5s cho 21 files).
- ✓ `afterEach jest.clearAllMocks()` — reset mock state O(1).
- ✓ Không có `beforeAll` với heavy setup (startup DB/server).
- ✓ `--verbose` flag cho visibility — CI log mỗi `it` block, debug dễ.

## Recommended actions (Phase 4)

- [ ] **P1** — Per drift/HEALTH.md D-HEA-07: Update test mock data trong `health.service.test.js:134` + `dashboard.service.test.js:134` từ `'high'/'moderate'` sang `'medium'/'critical'` (~30 min, combine với Q7 service fix).
- [ ] **P2** — Add test cho `risk-calculator.service.js` (service file hiện không có test) — cover `calculateAllRiskScores` + level boundary values (LOW 0-33 / MEDIUM 34-66 / CRITICAL 67-100) (~2h).
- [ ] **P2** — Setup integration test layer với Docker postgres test DB cho `/api/v1/admin/*` endpoints: boot Express app + hit endpoint + verify real DB state (~6-8h Phase 5+).
- [ ] **P2** — Refactor unit test từ implementation-detail assertion (`mock.calls[0][0] args check`) sang behavior-driven (return shape + side-effect check) (~4h cross-file).
- [ ] **P3** — Add `coverageThreshold` trong `package.json:jest` block — enforce 60% cho `src/services/`, `src/middlewares/`, `src/controllers/` (~15 min).
- [ ] **P3** — Split test files >300 LoC thành nhiều files theo method (user.service.test.js, logs.service.test.js, auth.service.test.js) (~1h per file).
- [ ] **P3** — Document test pyramid trong README: unit (current) vs integration (future) layer boundary (~30 min).

## Out of scope (defer Phase 3 deep-dive)

- Test coverage percentage (chạy `npm run test:coverage` + report PR comment) — Phase 3 / CI config.
- Test flakiness metric (test rerun stability, parallel execution safety) — Phase 3 test quality audit.
- Mutation testing (Stryker) — Phase 5+ test rigor.
- Frontend test coverage (`HealthGuard/frontend/`) — M18 audit scope.
- E2E test framework (Playwright, Cypress) — out of đồ án 2 scope.
- Property-based testing (fast-check) — Phase 5+ rigor.
- Snapshot testing (Jest `toMatchSnapshot`) — không hiện diện trong suite hiện tại.
- `jest-mock-extended` vs `jest.fn()` disambiguation usage — Phase 3 test quality.

## Cross-references

- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-07 risk_level 3 levels require test mock update.
- Phase 0.5 drift: [drift/VITAL_ALERT_ADMIN.md](../../tier1.5/intent_drift/healthguard/VITAL_ALERT_ADMIN.md) — D-VAA-01 không cần viết test vital-alert.controller.js (drop endpoints).
- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — pattern R3 test cover lockout + reset token + email mock.
- Steering test discipline: `.kiro/steering/30-testing-discipline.md` — test pyramid + coverage target 60-70%.
- HG-001 bug: test suite không catch được vì mock `prisma.alerts.findMany` không verify `read_at` column usage.
- M02 Routes audit: controller endpoint definitions feed vào controller test (`controllers/*.test.js`).
- M03 Controllers audit: controller test coverage matrix.
- M04 Services audit: service test coverage matrix + mock fidelity concern.
- M05 Middlewares audit: middleware tests cover `authenticate` / `validate` / `errorHandler`.
- M06 Prisma schema audit: Prisma mock signature sync với real client gen.
- M07 Jobs+Utils audit: utils test covered (3/3 files: ApiError, ApiResponse, catchAsync).
- Module inventory: M08 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: No direct precedent trong tier2/healthguard-model-api/ (model-api audit không có M08 tests). Compare via steering `.kiro/steering/30-testing-discipline.md`.
