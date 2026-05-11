# Audit Framework — VSmartwatch HealthGuard 2026

**Date:** 2026-05-11
**Scope:** Standardized rubric cho Phase 1 macro audit + Phase 3 module deep-dive
**Use:** Apply same axes cho mọi module cross 5 repos → comparable scores → prioritize refactor backlog

---

## Purpose

Sau Phase -1 đã có **trust-able baseline** (DB diff, API contract, topology), Phase 0 build **measuring stick** để Phase 1+ chấm điểm code thực tế.

**Why rubric thay vì free-form review:**
- Comparable scores cross modules (vd module A=11/15 vs module B=8/15 → B ưu tiên refactor)
- Forces consistent depth (em không skip axis em không biết)
- Anti-bias (em không score 1 module quá cao vì familiar)
- Phase 4 backlog prioritization data-driven

---

## 5 Axes

### 1. Correctness — "Code có làm đúng việc mong muốn?"

**Focus:** Logic, edge cases, error paths, type safety, contract compliance.

**Score:**

| Score | Description |
|---|---|
| 3 | All paths handled (happy + error + edge). Type safe. Validated against spec. Contract test pass. |
| 2 | Main path correct. Some edge cases missing nhưng safe defaults. Có test coverage cơ bản. |
| 1 | Main path works. Multiple edge cases untreated. Error handling minimal. |
| 0 | Logic bugs phát hiện. Crash trên edge case obvious. Khác spec. |

**Stack-specific checks:**

| Stack | Specific checks |
|---|---|
| Express + Prisma | Validate input qua zod/express-validator. Prisma errors caught (P2002, P2025). Try-catch async/await. |
| FastAPI | Pydantic v2 schema validate. HTTP exception handling đúng (4xx vs 5xx). Async correctness. |
| Flutter | `mounted` check sau await. `Either<Failure, T>` ở repository boundary. Null safety. |
| React | Form validation. Error boundary. Loading/error states cho async. |
| SQL | NOT NULL constraints. FK constraints. CHECK constraints. UNIQUE indexes. |

**Anti-patterns auto-deduct:**
- `except Exception: pass` (Python)
- `} catch (e) {}` (JS)
- Missing `mounted` check before `setState` (Flutter)
- Missing input validation at router boundary
- Hardcoded magic numbers/strings

---

### 2. Readability — "Code có dễ hiểu cho future-you sau 6 tháng?"

**Focus:** Naming, structure, comments, function size, complexity.

**Score:**

| Score | Description |
|---|---|
| 3 | Tên biến/func tự explain. Functions ≤ 50 lines. Có comment chỗ tricky. No dead code. Module organized logically. |
| 2 | Hầu hết clear. 1-2 chỗ cần comment thêm. Function vài chỗ > 80 lines. |
| 1 | Tên ambiguous (vd `data`, `result`). Functions > 100 lines. Comment outdated hoặc misleading. |
| 0 | Cargo-cult code. Tên 1 chữ cái. Functions > 200 lines. Comment mâu thuẫn code. |

**Stack-specific:**

| Stack | Specific checks |
|---|---|
| Express | RESTful route naming. Controller thin (≤30 lines). Service layer rõ ràng. |
| FastAPI | Router prefix + tag. Pydantic schema separate (request/response). Service không biết HTTP. |
| Flutter | Widget split khi `build()` > 100 lines. `const` constructors. Theme color (no hardcode). |
| React | Component < 200 lines. Custom hooks extract logic. Props typed. |
| SQL | snake_case. Plural table names. Index naming convention. |

**Anti-patterns:**
- Vietnamese trong identifier names (var, function, class — code phải English)
- Comment kể "what" thay vì "why"
- Mixed naming styles (camelCase + snake_case trong cùng file)
- File > 500 lines (split candidate)

---

### 3. Architecture — "Separation of concerns + dependencies clean?"

**Focus:** Layering, coupling, abstractions, dependency direction.

**Score:**

| Score | Description |
|---|---|
| 3 | Clean layering (router → service → repo). Single responsibility. No cyclic deps. DI ở boundaries. |
| 2 | Mostly layered. 1-2 chỗ shortcut (service gọi service khác directly). |
| 1 | Multiple layer violations (router gọi DB trực tiếp). Service god object. Tight coupling. |
| 0 | Spaghetti. Cross-layer leak. Circular import. |

**Stack-specific:**

| Stack | Specific checks |
|---|---|
| Express | Router → Controller → Service → Prisma. Middleware chained correctly. |
| FastAPI | Router → Service → Repository. Service không nhận `Request`/`JSONResponse`. |
| Flutter | features/ × clean architecture. data/repositories implement domain/repositories. Riverpod providers scoped. |
| React | Pages composed of components. Hooks extract logic. Service layer cho API calls. |
| SQL | Normalized 3NF. FK on delete strategy clear. No store JSON when relational works. |

**Anti-patterns:**
- Router gọi ORM directly (bypass service)
- God service (1 file > 1000 lines, multiple responsibilities)
- Global mutable state without thread safety
- Cross-feature imports trong Flutter (feature A import feature B internals)

---

### 4. Security — "PHI + auth + input handled correctly?"

**Focus:** Authentication, authorization, input validation, secrets, PHI handling, output sanitization.

**Score:**

| Score | Description |
|---|---|
| 3 | Auth middleware mọi protected route. RBAC enforced. Input validated. Secrets ở `.env`. PHI masked trong log. Output sanitized (no stack trace leak). |
| 2 | Auth ok. 1-2 endpoints chưa rate-limit. Logging có sensitive field accidentally. |
| 1 | Auth gap (vd 1 route quên middleware). Hardcoded credential trong test. SQL string concat ít chỗ. |
| 0 | Auth bypass có thể. SQL injection có thể. Secret trong git history. PHI plaintext log. |

**Stack-specific:**

| Stack | Specific checks |
|---|---|
| Express | `authenticate` + `requireAdmin/User` middleware on protected routes. helmet config. CORS allowlist. |
| FastAPI | `Depends(get_current_user)` cho user routes. `Depends(require_internal_service)` cho internal. Pydantic validate at boundary. |
| Flutter | Token storage `flutter_secure_storage` (NOT shared_preferences). HTTPS enforce. No PII in logs. |
| React | No `dangerouslySetInnerHTML` với user input. Token in httpOnly cookie (NOT localStorage). |
| SQL | Parameterized queries only. pgcrypto cho password hash. Row-level security cho PHI. |

**Anti-patterns auto-flag (CRITICAL — score = 0):**
- `eval()`, `exec()` với user input
- SQL string concat với user input
- `dangerouslySetInnerHTML` với user input
- Password trong plaintext (any storage)
- CORS `*` trong production config
- Disabled SSL verify (`verify=False`, `rejectUnauthorized: false`)
- Token nhạy cảm trong localStorage
- Hardcoded API key/secret

---

### 5. Performance — "Hot path có efficient không?"

**Focus:** Database query patterns, caching, async correctness, payload size.

**Score:**

| Score | Description |
|---|---|
| 3 | No N+1 queries. Pagination ở list endpoints. Caching cho hot reads. Async non-blocking. Payload reasonable (< 1MB typical). |
| 2 | Mostly efficient. 1-2 N+1 trong report queries (rare path). No caching nhưng acceptable. |
| 1 | Multiple N+1. Missing pagination. Sync I/O trong async function. Payload bloat. |
| 0 | Query explode. Production crash potential under load. Sync block event loop. |

**Stack-specific:**

| Stack | Specific checks |
|---|---|
| Express + Prisma | `include` + `select` planned. No `findMany` without limit. Connection pool sized. |
| FastAPI | `asyncio.to_thread` cho CPU/sync I/O. SQLAlchemy `eagerload` cho relations. Pydantic exclude defaults từ response. |
| Flutter | `const` constructors. List builder thay vì Column với 100+ items. Image cache. |
| React | `React.memo` cho expensive components. `useMemo` cho derived state. Virtual scroll cho list dài. |
| SQL | Index trên FK + WHERE common cols. Hypertable continuous aggregates cho time-series. |

**Anti-patterns:**
- `SELECT *` trong canonical query
- Prisma `findMany` without `take`
- FastAPI sync endpoint cho I/O work
- Flutter `setState()` trong loop
- React component re-render trên mọi parent update

---

## Total score + verdict bands

**Sum 5 axes = total / 15**

| Band | Score | Verdict | Action |
|---|---|---|---|
| 🟢 Mature | 13-15 | Code shippable, maintainable. Reference quality. | Minor polish, document patterns. |
| 🟡 Healthy | 10-12 | Solid base. Có gap nhỏ nhưng OK production. | Phase 4 targeted improvement. |
| 🟠 Needs attention | 7-9 | Tech debt accumulated. Edge cases + perf issues. | Phase 4 prioritize. |
| 🔴 Critical | 0-6 | Security risk / broken feature / production crash potential. | Phase 4 P0. |

**Special rule:** Security score = 0 → **automatic Critical** regardless of total (anti-pattern hit).

---

## Audit output template (per module)

Mỗi module audit produce 1 file `PM_REVIEW/AUDIT_2026/tier2/<repo>/<module>_audit.md`:

```markdown
# Audit: <module name>

**Module:** `<repo>/<path>`
**Audit date:** YYYY-MM-DD
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1 (this rubric)

## Scope

What's included / excluded.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | X/3 | ... |
| Readability | X/3 | ... |
| Architecture | X/3 | ... |
| Security | X/3 | ... |
| Performance | X/3 | ... |
| **Total** | **XX/15** | Band: 🟢/🟡/🟠/🔴 |

## Findings

### Correctness
- ...

### Readability
- ...

(etc per axis)

## Recommended actions (Phase 4)

- [ ] P0/P1/P2: <action>

## Out of scope (defer Phase 3 deep-dive)

- ...
```

---

## Workflow integration

### When to run audit

- **Phase 1 macro audit:** Apply rubric ở folder-level (vd whole `app/services/` of one repo). Output: 1 file per module group.
- **Phase 3 deep-dive:** Apply rubric ở per-file level cho modules được flag bởi Phase 1 macro. Output: detail file.

### Commit convention

- Branch: `chore/audit-2026-phase-{N}-{repo-slug}` (vd `chore/audit-2026-phase-1-healthguard-backend`)
- Files commit: `PM_REVIEW/AUDIT_2026/tier{2,3}/<repo>/<module>_audit.md`
- 1 PR per macro audit track (5 tracks possible parallel per Phase 1)

### Stack-specific quick reference

Khi audit module:
1. Identify stack (Express / FastAPI / Flutter / React / SQL)
2. Apply 5 axes với stack-specific checklist trong section trên
3. Run anti-pattern flag (auto-deduct nếu hit)
4. Fill output template

---

## Out of scope for rubric

Em consider những axes này nhưng KHÔNG include vì:

- **Test coverage** — measured tự động qua coverage tool, không cần rubric. Sẽ report separately.
- **Documentation** — included in Readability axis (comments score)
- **Accessibility** — Flutter/React specific, em add vào Readability stack-specific
- **i18n** — Vietnamese label + English code đã rule, không cần axis riêng

---

## Reverse decision triggers (rubric stability)

Rubric v1 sẽ revisit nếu:
- Phase 1 macro audit thấy axes overlap (vd Architecture vs Readability blurry)
- Score distribution không phân biệt (all modules 10/15)
- Stack-specific checklist không phù hợp module mới (vd nếu add Go service)
- ThienPDM personal preference shift

Lúc đó tạo `00_audit_framework_v2.md` + ADR document change.
