---
name: DetailedReview
description: "Detailed evaluation of a specific feature in the HealthGuard project. Integrates Architecture Best Practices + MASTER_INDEX + Summary + Progressive Deepening."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-03"
references:
  - architect-review
  - software-architecture
  - backend-architect
  - architecture-patterns
  - architecture-decision-records
---

# 🔬 Skill: Detailed Feature Review (DanhGiaChiTiet)

## Objective

Conduct a **detailed evaluation** of a specific system feature — analyzing the actual code against industry architecture standards, verifying SRS compliance, checking implementation quality, and cross-referencing Trello tasks.

---

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to **optimize token limits** and **ensure accuracy**.

### Tier 1: Navigate (ALWAYS first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** → Find the corresponding module row.
2. Note down: Sprint, UC refs, summary file path.

### Tier 2: Load Context (Read ONE summary)
3. **Read the corresponding summary file** (e.g.: `summaries/AUTH_summary.md`).
   - The summary already contains: extracted SRS requirements, extracted Trello checklists, and code file mappings.
4. **DO NOT read the full SRS, DO NOT read the full Trello Sprints.**

### Tier 3: Deep Dive (Progressive — code only)
5. **Scan**: List files in the related folder → verify files exist.
6. **Surface**: Read file outlines (function names, class names, LOC).
7. **Deep**: Read detailed contents ONLY for the files requiring evaluation.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS → use the summary instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read the full Trello Sprint file → checklists are in the summary.
- ❌ **DO NOT** read files unrelated to the module currently under review.
- ❌ **DO NOT** read all source code at once → read file by file selectively.

---

## When to Use

- To review code quality for a specific module before merge/release.
- When there's suspicion a feature does not comply with the SRS.
- To verify acceptance criteria from a Trello card.

**Trigger**: `@DetailedReview [Feature Name]`
or `@DanhGiaChiTiet [Feature Name]`

**Examples**:
- `@DetailedReview AUTH Login`
- `@DanhGiaChiTiet EMERGENCY Fall detection`
- `@DetailedReview MONITORING View Health Metrics`

---

## Evaluation Process

### Step 1: Load Context (Follow the Protocol above)

### Step 2: Code Analysis (8 Criteria)

| # | Criterion | Weight | Description |
|---|-----------|--------|-------------|
| 1 | **Feature Correctness** | /15 | Output matches SRS, correct UC flows (main/alt/exception) |
| 2 | **API Design** | /10 | RESTful conventions, error formatting, versioning (see checklist) |
| 3 | **Architecture & Patterns** | /15 | Clean Architecture, separation of concerns, DDD (see checklist) |
| 4 | **Validation & Error Handling** | /12 | Input validation, error classification, defensive coding |
| 5 | **Security** | /12 | OWASP-aligned checklist (see checklist) |
| 6 | **Code Quality** | /12 | SOLID, clean code, anti-patterns (see checklist) |
| 7 | **Testing** | /12 | Multi-level testing strategy (see checklist) |
| 8 | **Documentation** | /12 | API docs, inline code comments, ADRs |

**Total Score: /100**

> [!NOTE]
> Criterion #3 (Architecture & Patterns) encompasses both business logic evaluation and architecture assessment.

---

## 🏗️ API DESIGN CHECKLIST (Criterion #2 — Details)

> Reference: `backend-architect`

### 2A. RESTful Conventions (/4)

| Check | Pass? | Notes |
|-------|-------|-------|
| Correct HTTP methods (GET=read, POST=create, PUT/PATCH=update, DELETE=delete) | | |
| Standard status codes (200, 201, 400, 401, 403, 404, 500) | | |
| Logical URL resource naming (plural nouns, no verbs) | | |
| Consistent and predictable API paths (`/api/v1/resource`) | | |

### 2B. Error Response Format (/3)

| Check | Pass? | Notes |
|-------|-------|-------|
| Unified error response structure (`{status, message, errors}`) | | |
| Validation errors provide field-level details | | |
| No internal errors/stack traces leaked to the client | | |

### 2C. Data Contract (/3)

| Check | Pass? | Notes |
|-------|-------|-------|
| Clear Request/Response schemas | | |
| Pagination pattern for list endpoints (cursor/offset) | | |
| Consistent date format (ISO 8601) | | |

---

## 📐 ARCHITECTURE & PATTERNS CHECKLIST (Criterion #3 — Details)

> Reference: `architect-review`, `architecture-patterns`, `software-architecture`

### 3A. Clean Architecture Layers (/5)

| Check | Pass? | Notes |
|-------|-------|-------|
| **Route → Controller → Service → Repository/Model** clear separation | | |
| Controller ONLY handles request/response, NO business logic | | |
| Service isolates business logic, DOES NOT access request/response objects | | |
| Repository/Model isolates data access, NO business logic | | |
| Dependency direction: Controller → Service → Repository (never inverted) | | |

### 3B. Domain Logic & Business Rules (/5)

| Check | Pass? | Notes |
|-------|-------|-------|
| Business rules are centralized in the Service layer | | |
| Domain validation is separated from API validation | | |
| Edge cases handled (null, empty, boundary values) | | |
| Business logic can be tested without HTTP/DB | | |
| No duplicated business logic | | |

### 3C. Design Patterns Applied (/5)

| Pattern | Used? | Assessment |
|---------|-------|------------|
| **Middleware** — Auth guard, validation, error handler | | |
| **Repository** — Data access abstraction | | |
| **DTO/Schema** — Data transfer objects for request/response | | |
| **Factory/Builder** — Object creation (if applicable) | | |
| **Strategy** — Handling multiple logic variations (if applicable) | | |

---

## 🔒 SECURITY CHECKLIST (Criterion #5 — Details)

> Reference: `backend-architect`, OWASP Top 10

### 5A. Authentication & Authorization (/4)

| Check | Pass? | Notes |
|-------|-------|-------|
| JWT token properly validated (signature, expiry, issuer) | | |
| Refresh token flow implemented (if applicable) | | |
| Route-level authorization (only authorized users can access) | | |
| Passwords hashed securely: bcrypt/argon2, NO md5/sha1/plaintext | | |

### 5B. Input Security (/4)

| Check | Pass? | Notes |
|-------|-------|-------|
| Input validation AND sanitization on the server-side | | |
| SQL injection prevention (parameterized queries / ORM) | | |
| XSS prevention (output encoding, prevent raw HTML injection) | | |
| File upload validation (if applicable): type, size, content checks | | |

### 5C. Rate Limiting & Abuse Prevention (/4)

| Check | Pass? | Notes |
|-------|-------|-------|
| Rate limiting on login/register/OTP endpoints | | |
| Brute force protection (account lockout / delay) | | |
| CORS appropriately configured (specific origins, no wildcard) | | |
| Secrets kept in `.env`, NEVER hardcoded in the source | | |

---

## 🧹 CODE QUALITY CHECKLIST (Criterion #6 — Details)

> Reference: `software-architecture`, `architect-review`

### 6A. SOLID Principles (/4)

| Principle | Question | Pass? |
|-----------|----------|-------|
| **S** — Single Responsibility | Does each function/class/file have exactly 1 clear purpose? | |
| **O** — Open/Closed | Can new features be added without altering existing code? | |
| **D** — Dependency Inversion | Depends on abstractions (interfaces), rather than concretions? | |
| Overall | Is the code easily extensible and maintainable? | |

### 6B. Clean Code Metrics (/4)

| Metric | Target | Actual | Pass? |
|--------|--------|--------|-------|
| Function length | ≤ 50 lines (max 80) | | |
| File length | ≤ 200 lines | | |
| Nesting depth | ≤ 3 levels | | |
| Early return pattern | Used instead of endless nested if-else | | |

### 6C. Anti-patterns Check (/4)

| Anti-pattern | Detected? | Location |
|--------------|-----------|----------|
| **God Object/Function** — 1 function handling too many things | | |
| **Generic naming** — `utils.js`, `helpers.js`, `common.js` | | |
| **Copy-paste code** — Logic duplicated in ≥ 2 places | | |
| **Magic values** — Hardcoded numbers/strings without constants | | |

---

## 🧪 TESTING CHECKLIST (Criterion #7 — Details)

> Reference: `backend-architect`

### 7A. Test Coverage (/4)

| Test Type | Present? | Coverage estimate |
|-----------|----------|-------------------|
| **Unit tests** — Business logic, services | | |
| **Integration tests** — API endpoints, DB queries | | |
| **Edge case tests** — Boundary values, null, empty inputs | | |
| **Error scenario tests** — Invalid input, unauthorized states | | |

### 7B. Test Quality (/4)

| Check | Pass? | Notes |
|-------|-------|-------|
| Tests have clear descriptive names (describe + it/test) | | |
| Tests are independent — do not rely on execution order | | |
| Proper test data setup/teardown mechanics | | |
| Mocks for external dependencies (DB, API calls) are used | | |

### 7C. Advanced Testing (Bonus) (/4)

| Test Type | Present? | Notes |
|-----------|----------|-------|
| Contract testing (API schema validation) | | |
| Load/Performance testing | | |
| Security testing (OWASP scan) | | |

---

## 📝 DOCUMENTATION CHECKLIST (Criterion #8 — Details)

> Reference: `architecture-decision-records`, `backend-architect`

### 8A. Code Documentation (/4)

| Check | Pass? |
|-------|-------|
| JSDoc/docstring provided for public functions | |
| Complex logic accompanied by inline comments explaining WHY | |
| README available for the module (or included in main README) | |

### 8B. API Documentation (/4)

| Check | Pass? |
|-------|-------|
| API endpoints are documented (route, method, params, response schema) | |
| Request/Response examples provided | |
| Error codes and their meanings defined | |

### 8C. Architecture Decisions (/4)

| Check | Pass? |
|-------|-------|
| Tech stack or pattern choices are documented (via ADRs or README) | |
| Folder structure reasoning is documented | |
| Known limitations and trade-offs are acknowledged | |

---

### Step 3: Trello Task Verification
- Use the checklists extracted in the summary file.
- Status for each item: ✅ Done / ⚠️ Partial / ❌ Missing / 🔄 Deviated.
- Require more details? → ONLY THEN read the full Trello Sprint file.

### Step 4: SRS / Use Case Verification
- Use the SRS requirements extracted in the summary file.
- Verify: Main Flow, Alternative Flows, Exception Flows.
- Verify: Non-functional requirements (performance, security).
- Require more details? → ONLY THEN consult the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`. DO NOT read the full SRS.

---

## Output Restrictions (MANDATORY)

CRITICAL INSTRUCTION: You MUST generate the final report in Vietnamese, exactly matching the markdown template below. Do not generate English text in the final report. The table headers, structure, and template wording must remain exactly as defined below in Vietnamese.

```markdown
# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: [Tên]
- **Module**: [AUTH/DEVICE/MONITORING/EMERGENCY/NOTIFICATION/ANALYSIS/SLEEP/ADMIN/INFRA]
- **Dự án**: [Admin / Mobile / Cả hai]
- **Sprint**: [Sprint N]
- **Trello Card**: [Card name + số]
- **UC Reference**: [UC0XX]
- **Ngày đánh giá**: [ISO date]

---

## 🏆 TỔNG ĐIỂM: XX/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Chức năng đúng yêu cầu | /15 | ... |
| API Design | /10 | ... |
| Architecture & Patterns | /15 | ... |
| Validation & Error Handling | /12 | ... |
| Security | /12 | ... |
| Code Quality | /12 | ... |
| Testing | /12 | ... |
| Documentation | /12 | ... |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Route → Controller → Service → Repo separation | ✅/❌ | ... |
| ... | | |

### Design Patterns (/5)
| Pattern | Có? | Đánh giá |
|---------|-----|---------|
| Middleware | ✅/❌ | ... |
| ... | | |

---

## 📂 FILES ĐÁNH GIÁ
| File | Layer | LOC | Đánh giá tóm tắt |
|------|-------|-----|-------------------|
| `path/to/file` | [Controller/Service/Repo] | [N] | [Tóm tắt] |

---

## 📋 TRELLO TASK TRACKING

### Card: [Tên card] (Sprint X)

#### [Role Name]
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | [Item] | ✅/⚠️/❌/🔄 | [Chi tiết] |

#### Acceptance Criteria
| # | Criteria | Trạng thái | Ghi chú |
|---|---------|------------|---------|
| 1 | [Criteria] | ✅/❌ | [Chi tiết] |

---

## 📊 SRS COMPLIANCE

### Main Flow
| Bước | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| 1 | [Mô tả] | [Thực tế] | ✅/❌ |

### Alternative Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|

### Exception Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|

---

## ✅ ƯU ĐIỂM
1. [Ưu điểm + file/line reference]

## ❌ NHƯỢC ĐIỂM
1. [Nhược điểm + lý do + file/line reference]

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. **[HIGH]** [Mô tả] → Cách sửa: [suggestion]
2. **[MEDIUM]** [Mô tả] → Cách sửa: [suggestion]
3. **[LOW]** [Mô tả] → Cách sửa: [suggestion]

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. [Code/pattern cần loại bỏ + lý do]

## ⚠️ SAI LỆCH VỚI TRELLO / SRS
| Source | Mô tả sai lệch | Mức độ | Đề xuất |
|--------|----------------|--------|---------|
| Trello Card X | [Mô tả] | 🔴/🟡/🟢 | [Đề xuất] |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt:
\```[language]
// file: path/to/file, line X-Y
[code snippet]
\```

### ❌ Code cần sửa:
\```[language]
// HIỆN TẠI:
[current code]
// NÊN SỬA THÀNH:
[suggested code]
\```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
| # | Action | Owner | Priority | Sprint |
|---|--------|-------|----------|--------|
| 1 | [Mô tả] | [Role] | HIGH/MED/LOW | [Sprint N] |
```

---

## Key Principles

1. **Index-first** — ALWAYS start from MASTER_INDEX.md
2. **Summary-based** — Derive SRS and Trello context directly from summaries.
3. **Progressive** — Scan → Surface → Deep (examine file contents selectively). If summary lacks UC details, read the SPECIFIC file in `PM_REVIEW/Resources/UC/`.
4. **Checklist-driven** — Strictly apply criteria tables for an objective evaluation.
5. **Read actual code** — Do NOT base score on assumptions or surface files alone.
6. **Line-level referencing** — Cite file paths and line numbers securely when addressing issues.
7. **Constructive feedback** — Every negative item must have a positive improvement suggestion.

---

## Module → Summary File Mapping Reference

### Admin (HealthGuard/)
| Module | Summary File | UC | Sprint |
|--------|-------------|-----|--------|
| AUTH | `REVIEW_ADMIN/summaries/AUTH_summary.md` | UC001-004 | S1 |
| ADMIN_USERS | `REVIEW_ADMIN/summaries/ADMIN_USERS_summary.md` | UC022 | S4 |
| DEVICES | `REVIEW_ADMIN/summaries/DEVICES_summary.md` | UC025 | S4 |
| CONFIG | `REVIEW_ADMIN/summaries/CONFIG_summary.md` | UC024 | S4 |
| LOGS | `REVIEW_ADMIN/summaries/LOGS_summary.md` | UC026 | S4 |
| INFRA | `REVIEW_ADMIN/summaries/INFRA_summary.md` | N/A | S1 |

### Mobile (health_system/)
| Module | Summary File | UC | Sprint |
|--------|-------------|-----|--------|
| AUTH | `REVIEW_MOBILE/summaries/AUTH_summary.md` | UC001-004 | S1 |
| DEVICE | `REVIEW_MOBILE/summaries/DEVICE_summary.md` | UC040,042 | S2 |
| INFRA | `REVIEW_MOBILE/summaries/INFRA_summary.md` | N/A | S1-S2 |
| MONITORING | `REVIEW_MOBILE/summaries/MONITORING_summary.md` | UC006-008 | S2 |
| EMERGENCY | `REVIEW_MOBILE/summaries/EMERGENCY_summary.md` | UC010-015 | S3 |
| NOTIFICATION | `REVIEW_MOBILE/summaries/NOTIFICATION_summary.md` | UC030-031 | S3 |
| ANALYSIS | `REVIEW_MOBILE/summaries/ANALYSIS_summary.md` | UC016-017 | S4 |
| SLEEP | `REVIEW_MOBILE/summaries/SLEEP_summary.md` | UC020-021 | S4 |

### Database
| Module | Summary File | UC | Sprint |
|--------|-------------|-----|--------|
| SQL/DB | `SQL SCRIPTS/README.md` | N/A | All |

---

## After Review: Update MASTER_INDEX

When the review process concludes, you must modify the corresponding module row in `MASTER_INDEX.md`:
- Set `Review Status` → ✅ Done (or accordingly)
- Set `Score` → XX/100
- Set `Last Review` → [Current date]
