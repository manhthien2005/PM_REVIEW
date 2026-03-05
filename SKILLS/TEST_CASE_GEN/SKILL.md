---
name: test-case-generator
description: "Generate structured test case files from UC/SRS/SQL/API sources, or execute existing test cases with timestamp tracking. Triggers: generate test case, test case, testing, TC generation, sinh test case, test function, test module, run test, execute test, test tracking, QA test."
category: project-management
risk: safe
source: custom
date_added: "2026-03-05"
---

# Skill: TEST_CASE_GEN — Test Case Generator & Executor

## Purpose

Generate **complete, structured test case files** from project sources (UC, SRS, SQL schema, API code), or **execute existing test cases** and track results with precise timestamps. All output is optimized for AI agent consumption.

## When to Use

### Mode A — GENERATE

User says: "Sinh ra bộ test case cho chức năng {FUNCTION}" or similar.

- Generate test cases for a specific module/function
- Create test case file from UC main flows, alt flows, business rules, and NFRs
- Cover both positive and negative scenarios
- Output: new `.md` file in `TESTING/{MODULE}/` folder

### Mode B — EXECUTE

User says: "Thực hiện test theo file {FILE}" or similar.

- Read an existing test case file
- Execute each test case (browser/API/manual)
- Update: Status, Actual result, Tester, DateTime
- Append execution log with session summary

---

## Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> Follow this strict tiered protocol. DO NOT skip tiers. DO NOT read sources not needed.

Read `references/context-loading.md` for detailed per-tier instructions.

### Quick Summary

| Tier | Source                        | When          | Purpose                            |
| ---- | ----------------------------- | ------------- | ---------------------------------- |
| 1    | `MASTER_INDEX.md`             | ALWAYS        | Project GPS, module lookup         |
| 2    | `SRS_INDEX.md`                | ALWAYS        | System requirements, HG-FUNC refs  |
| 3    | Target UC file(s)             | GENERATE mode | Main/Alt flows, BRs, NFRs          |
| 4    | SQL schema for module         | GENERATE mode | Table structure, constraints       |
| 5    | API code (routes/controllers) | GENERATE mode | Endpoints, validators, error codes |

### ⛔ WHAT NOT TO DO
- ❌ DO NOT read the full SRS — use SRS_INDEX
- ❌ DO NOT read all SQL files — only the relevant layer
- ❌ DO NOT read all UC files — only the target function's UCs
- ❌ DO NOT generate test cases without reading the UC first

---

## Phase 1: GENERATE — Test Case Generation

### Step 1 — Identify Target

1. Parse user request → extract: **Module** (e.g., AUTH) and **Function** (e.g., LOGIN)
2. Look up in `MASTER_INDEX.md` → find UC Refs (e.g., UC001)
3. Determine **Platform**: ADMIN / MOBILE / BOTH

### Step 2 — Load Context

Follow Context Loading Protocol (Tiers 1–5). For each UC:

| Extract From UC     | Use For                                |
| ------------------- | -------------------------------------- |
| Main Flow steps     | Positive test cases (happy path)       |
| Alternative Flows   | Negative test cases, edge cases        |
| Business Rules (BR) | Validation test cases, boundary values |
| NFR Requirements    | Performance, security, usability tests |
| Preconditions       | Test preconditions column              |
| Postconditions      | Expected results verification          |

From SQL schema:
- Column constraints (NOT NULL, UNIQUE, CHECK) → validation test cases
- Data types → boundary value test cases
- Foreign keys → referential integrity test cases

From API code (if available):
- Route definitions → endpoint test cases
- Validators → input validation test cases
- Error responses → error handling test cases

### Step 3 — Generate Test Data (Materials)

Before writing test cases, generate the **Test Data** section listing all materials needed for execution. See `references/testcase-template.md` → "Test Data — Materials" for format.

- Analyze UC preconditions → identify required accounts, roles, device data
- Analyze API endpoints → identify required URLs, tokens, keys
- Set all sensitive values to `⬜ PENDING` — user fills in before EXECUTE
- Pre-fill obvious mock data (e.g., `notexist@test.com` for invalid email tests)

### Step 4 — Generate Test Cases

Read `references/testcase-template.md` for the MANDATORY output format.
Read `references/naming-convention.md` for ID and file naming rules.

**Coverage Rules (MANDATORY):**

| UC Element        | Min Test Cases | Severity Default |
| ----------------- | -------------- | ---------------- |
| Main Flow (happy) | 1 per flow     | CRITICAL         |
| Alt Flow (error)  | 1 per alt flow | HIGH             |
| Business Rule     | 1-2 per BR     | HIGH / MEDIUM    |
| NFR (performance) | 1 per NFR      | MEDIUM           |
| Boundary values   | 2 per field    | MEDIUM           |
| Security checks   | 1--2 per UC    | HIGH             |

### Step 5 — Write Output File

**File location:**
```
PM_REVIEW/{PLATFORM_FOLDER}/TESTING/{MODULE}/{FUNCTION}_testcases.md
```

Where:
- `{PLATFORM_FOLDER}` = `REVIEW_ADMIN` or `REVIEW_MOBILE`
- `{MODULE}` = Module name (AUTH, DEVICES, MONITORING, etc.)
- `{FUNCTION}` = Function name (LOGIN, REGISTER, LIST, etc.)

**Example:**
```
PM_REVIEW/REVIEW_ADMIN/TESTING/AUTH/LOGIN_testcases.md
PM_REVIEW/REVIEW_MOBILE/TESTING/AUTH/LOGIN_testcases.md
```

If platform = BOTH → generate **two separate files** (one per platform folder).

---

## Phase 2: EXECUTE — Test Execution & Tracking

### Step 1 — Load Test File & Validate Materials

1. Read the existing test case file from `TESTING/{MODULE}/{FUNCTION}_testcases.md`
2. **Check Test Data section** — if any `⬜ PENDING` materials exist → **ASK the user** to provide values before proceeding
3. Parse all test case rows
4. Identify test cases with Status = `NOT_RUN` or `FAIL` (for re-test)

### Step 2 — Execute Tests

For each test case:

1. Follow the Steps column exactly
2. Compare actual result with Expected column
3. Record:

| Field    | Value                                |
| -------- | ------------------------------------ |
| Status   | `PASS` / `FAIL` / `BLOCKED` / `SKIP` |
| Actual   | Describe what actually happened      |
| Tester   | `AI_AGENT` or user-specified name    |
| DateTime | ISO 8601: `YYYY-MM-DD HH:MM` (local) |

### Step 3 — Update File

Read `references/execution-tracker.md` for the detailed update protocol.

Key actions:
1. Update each test case row in-place (Status, Actual, Tester, DateTime)
2. Append **Execution Log** section at file bottom
3. Update **Summary** counts (PASS/FAIL/BLOCKED/SKIP/NOT_RUN)

---

## Output Protocol (MANDATORY)

| Rule                 | Detail                                                                |
| -------------------- | --------------------------------------------------------------------- |
| **Format**           | Markdown table — read `references/testcase-template.md`               |
| **Language**         | English for all fields (AI-optimized parsing)                         |
| **ID Format**        | `TC-UC{XX}-{PLATFORM}-{NNN}` — read `references/naming-convention.md` |
| **File Naming**      | `{FUNCTION}_testcases.md`                                             |
| **Folder**           | `{REVIEW_ADMIN\|REVIEW_MOBILE}/TESTING/{MODULE}/`                     |
| **Overwrite**        | If file exists in GENERATE mode → ask user before overwrite           |
| **Execution Update** | In EXECUTE mode → update in-place, never create a new file            |

---

## Reference Documents

| Name               | Path                               | When to Read              |
| ------------------ | ---------------------------------- | ------------------------- |
| **MASTER INDEX**   | `PM_REVIEW/MASTER_INDEX.md`        | **ALWAYS**                |
| **SRS Index**      | `PM_REVIEW/Resources/SRS_INDEX.md` | **ALWAYS**                |
| UC Files           | `PM_REVIEW/Resources/UC/{Module}/` | GENERATE — target UC only |
| SQL README         | `PM_REVIEW/SQL SCRIPTS/README.md`  | GENERATE — schema lookup  |
| SQL Files          | `PM_REVIEW/SQL SCRIPTS/0{N}_*.sql` | GENERATE — detail only    |
| Test Case Template | `references/testcase-template.md`  | GENERATE — output format  |
| Naming Convention  | `references/naming-convention.md`  | GENERATE — ID/file names  |
| Execution Tracker  | `references/execution-tracker.md`  | EXECUTE — update protocol |
| Context Loading    | `references/context-loading.md`    | GENERATE — source loading |

## Integrated Skills (Bundled)

> **CRITICAL:** Before executing, read the relevant bundled skill to inherit its analysis methodology.

| Bundled Skill           | Path                                      | Use in Phase                                    |
| ----------------------- | ----------------------------------------- | ----------------------------------------------- |
| Business Analyst        | `skills/business-analyst/SKILL.md`        | GENERATE (requirement → test case derivation)   |
| Product Manager Toolkit | `skills/product-manager-toolkit/SKILL.md` | GENERATE (coverage prioritization, risk matrix) |

---

## Rules

- **Read UC BEFORE generating** — never generate test cases from assumptions
- **One function per file** — do not combine multiple functions in one test case file
- **English only** — all test case content in English for AI parsing
- **Cover all UC flows** — main flow + every alt flow must have at least one test case
- **Include boundary values** — for every input field, include min/max/invalid tests
- **Security test cases** — every auth-related UC must have security tests (SQL injection, XSS, token expiry)
- **Timestamp precision** — always use `YYYY-MM-DD HH:MM` format with local timezone
- **Never skip NOT_RUN** — in EXECUTE mode, attempt every NOT_RUN test case
- **Progressive context** — read source files progressively, not all at once
- **Overwrite protection** — in GENERATE mode, confirm with user before overwriting existing files
