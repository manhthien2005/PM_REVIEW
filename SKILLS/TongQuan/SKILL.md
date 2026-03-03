---
name: ProjectOverview
description: "High-level assessment for the HealthGuard project. Uses MASTER_INDEX + Progressive Deepening + Architecture Best Practices to optimize context."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-03"
references:
  - architect-review
  - software-architecture
  - backend-architect
  - architecture-patterns
---

# 🔍 Skill: Project Overview Assessment (TongQuan)

## Objective

Evaluate the **holistic structure and progress** of the HealthGuard project to ensure it aligns with the SRS, follows industry-standard architecture, and stays on track with Trello sprint tasks.

---

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to **optimize token limits** and **prevent getting lost in context**.

### Tier 1: Navigation (ALWAYS read first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** — The overall GPS map of the project.
2. Determine the assessment scope (Admin / Mobile / or both).

### Tier 2: Structure (Read based on scope)
3. **Read the corresponding `Project_Structure.md`** (Admin or Mobile).

### Tier 3: Summaries (Read ONLY relevant summaries)
4. **Read related summary files** from the `summaries/` folder.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS document — use the summary files instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read all Trello Sprint files — checklists are already extracted in the summaries.
- ❌ **DO NOT** read the entire source code — only scan the folder structure for overviews.

---

## When to Use

- When the PM wants to evaluate the overall project or a specific large section.
- When verifying if the existing codebase structure reflects the SRS correctly.
- When reviewing progress against Trello sprints.
- When reporting the project status to stakeholders.

---

## Inputs

1. **Entire Project Structure** → Full project overview
   - Example: `@ProjectOverview Project_Structure REVIEW_ADMIN`
   - Example: `@ProjectOverview Project_Structure REVIEW_MOBILE`
   
2. **Specific Module** → Module overview
   - Example: `@ProjectOverview AUTH`
   - Example: `@ProjectOverview EMERGENCY`

---

## Evaluation Process (Progressive Deepening)

### Step 1: Load Context (Follow the Protocol above)

### Step 2: Source Code Scan (Surface Level)
- Browse the actual **folder structure** (DO NOT read file contents yet).
- Compare it against the structure described in `Project_Structure.md`.
- Note down: missing files, extra files, naming inconsistencies.

### Step 3: Evaluate against 6 Criteria

| # | Criterion | Weight | Description |
|---|-----------|--------|-------------|
| 1 | **SRS Compliance** | /20 | Are features implemented according to SRS? (use summary file) |
| 2 | **Architecture & Structure** | /20 | Architecture patterns, layers, dependencies (see checklist below) |
| 3 | **Consistency** | /15 | Naming conventions, coding style, API design |
| 4 | **Progress vs Trello** | /20 | Compare against Trello tasks (use summary file) |
| 5 | **Code Quality** | /15 | Clean code, SOLID, design patterns, anti-patterns (see checklist below) |
| 6 | **Security & Best Practices** | /10 | OWASP-aligned security checklist (see checklist below) |

**Total Score: /100**

---

## 📐 ARCHITECTURE CHECKLIST (Criterion #2 — Details)

> Reference: `architect-review`, `architecture-patterns`, `software-architecture`

### 2A. Clean Architecture & Layers (/8)

| Check | Pass? | Notes |
|-------|-------|-------|
| **Separation of Concerns** — Controller ≠ Service ≠ Repository/Model | | |
| **Dependency Direction** — Outer layers depend on inner ones, NOT vice versa | | |
| **Business logic decoupled from framework** — Logic is not inside controllers/routes | | |
| **Database queries** are not directly inside controllers | | |

### 2B. Folder Structure & Organization (/6)

| Check | Pass? | Notes |
|-------|-------|-------|
| Folder structure accurately reflects the modules in the SRS | | |
| Each module has clear boundaries (routes, controllers, services, models) | | |
| No "god folders" containing everything (e.g., all controllers in 1 folder) | | |

### 2C. Design Patterns (/6)

| Check | Pass? | Notes |
|-------|-------|-------|
| **Repository Pattern** — Data access layer is decoupled | | |
| **Middleware Pattern** — Auth, validation, error handling via middlewares | | |
| **Service Pattern** — Business logic is encapsulated in services | | |
| **Dependency Injection** (or proper module imports) is utilized | | |

---

## 🧹 CODE QUALITY CHECKLIST (Criterion #5 — Details)

> Reference: `software-architecture`, `architect-review`

### 5A. SOLID Principles (/5)

| Principle | Check | Pass? |
|-----------|-------|-------|
| **S** — Single Responsibility | Each file/class/function has only 1 responsibility? | |
| **O** — Open/Closed | Can be extended without modifying existing code? | |
| **L** — Liskov Substitution | Subclasses can replace parent classes? | |
| **I** — Interface Segregation | Clients are not forced to depend on unused interfaces? | |
| **D** — Dependency Inversion | Depend on abstractions, not concretions? | |

### 5B. Clean Code (/5)

| Check | Pass? |
|-------|-------|
| Short functions (recommended ≤ 50 lines, max 80 lines) | |
| Short files (recommended ≤ 200 lines) | |
| Max 3 nesting levels (no deep nesting) | |
| Use **early returns** instead of nested if-else statements | |
| No duplicate code (DRY principle) | |

### 5C. Anti-patterns Detection (/5)

| Anti-pattern | Detected? | Description |
|--------------|-----------|-------------|
| **Generic naming** — `utils.js`, `helpers.js`, `common.js` with mixed functions | | |
| **God Object** — 1 class/file handling too many responsibilities | | |
| **Tight Coupling** — Modules are highly dependent on each other | | |
| **NIH Syndrome** — Rewriting what existing good libraries can do | | |
| **Magic Numbers/Strings** — Hardcoded values without using constants | | |

---

## 🔒 SECURITY CHECKLIST (Criterion #6 — Details)

> Reference: `backend-architect`, OWASP Top 10

### 6A. Authentication & Authorization (/4)

| Check | Pass? |
|-------|-------|
| Correct JWT implementation (secret, expiry, refresh token) | |
| Password hashing (bcrypt/argon2, NO md5/sha1) | |
| Role-based Access Control (RBAC) implemented | |
| Protected routes have auth guard middlewares | |

### 6B. Input & API Security (/3)

| Check | Pass? |
|-------|-------|
| Input validation on both client AND server | |
| SQL injection prevention (parameterized queries / ORM) | |
| Rate limiting on sensitive API endpoints (login, register, OTP) | |

### 6C. Configuration Security (/3)

| Check | Pass? |
|-------|-------|
| Secrets in `.env` (NOT hardcoded in source) | |
| `.env` is included in `.gitignore` | |
| CORS is configured correctly (no wildcard `*` in production) | |

---

### Step 4: Cross-check with Trello Tasks
- Use the checklist already extracted in the summary files.
- If more details are needed → ONLY THEN read the corresponding Trello Sprint file.

---

## Output Restrictions (MANDATORY)

CRITICAL INSTRUCTION: You MUST generate the final report in Vietnamese, exactly matching the markdown template below. Do not generate English text in the final report. The table headers, structure, and template wording must remain exactly as defined below in Vietnamese.

```markdown
# 📊 BÁO CÁO ĐÁNH GIÁ TỔNG QUAN

## Thông tin chung
- **Dự án**: [Admin / Mobile]
- **Phạm vi đánh giá**: [Toàn bộ / Module cụ thể]
- **Ngày đánh giá**: [ISO date]
- **Sprint hiện tại**: [Sprint N]

---

## 🏆 TỔNG ĐIỂM: XX/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Bám sát SRS | /20 | ... |
| Kiến trúc & Cấu trúc | /20 | ... |
| Tính nhất quán | /15 | ... |
| Tiến độ vs Trello | /20 | ... |
| Code Quality | /15 | ... |
| Bảo mật & Best Practices | /10 | ... |

---

## 📐 ARCHITECTURE ASSESSMENT
> Chi tiết tiêu chí #2

### Clean Architecture & Layers (/8)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Separation of Concerns | ✅/❌ | ... |
| Dependency Direction | ✅/❌ | ... |
| Business logic tách framework | ✅/❌ | ... |
| DB queries không trong controller | ✅/❌ | ... |

### Folder Structure (/6)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| ... | ✅/❌ | ... |

### Design Patterns (/6)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| ... | ✅/❌ | ... |

---

## ✅ ƯU ĐIỂM
1. [Liệt kê ưu điểm nổi bật]

## ❌ NHƯỢC ĐIỂM
1. [Liệt kê nhược điểm cần cải thiện]

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. [Cải thiện cụ thể + mức độ ưu tiên: HIGH/MEDIUM/LOW]

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. [Code/pattern/dependency cần loại bỏ]

## ⚠️ SAI LỆCH VỚI TRELLO TASKS
> Phần này BẮT BUỘC phải có nếu phát hiện sai lệch

| Trello Card | Sprint | Mô tả sai lệch | Mức độ |
|-------------|--------|----------------|--------|
| [Card name] | [Sprint N] | [Mô tả] | 🔴/🟡/🟢 |

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
1. [Action item + Owner + Deadline khuyến nghị]
```

---

## Key Principles

1. **Index-first** — ALWAYS start with MASTER_INDEX.md.
2. **Summary-based** — Use summary files instead of reading full SRS/Trello.
3. **Progressive** — Scan → Surface → Deep (only when necessary).
4. **Checklist-driven** — Use specific checklists for architecture, code quality, security.
5. **No assumptions** — Only review based on actual code and documentation.
6. **Actionable** — Every improvement point must have a proposed solution.

---

## Reference Documents

| Name | Path | When to read |
|------|------|--------------|
| **MASTER INDEX** | `PM_REVIEW/MASTER_INDEX.md` | **ALWAYS** |
| Admin Structure | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md` | When reviewing Admin |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md` | When reviewing Mobile |
| Admin Summaries | `PM_REVIEW/REVIEW_ADMIN/summaries/*.md` | Based on module |
| Mobile Summaries | `PM_REVIEW/REVIEW_MOBILE/summaries/*.md` | Based on module |
| DB Summary | `PM_REVIEW/SQL SCRIPTS/README.md` | When reviewing database design, schema, or system tables |
| Use Cases (UC) | `PM_REVIEW/Resources/UC/**/*.md` | When detailed feature logic is needed |
| SRS v1.0 | `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` | ❌ DO NOT read unless explicitly needed for detail |
| Trello Sprints | `PM_REVIEW/Resources/TASK/TRELLO_SPRINT*.md` | ❌ DO NOT read unless summary lacks details |
