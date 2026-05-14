# Skill: Test Case Generator & Executor

Generate structured test case files from UC/SRS/SQL/API sources, execute existing test cases, or create AI-executable test plans.

## Modes

### Mode A — GENERATE
"Sinh test case cho chuc nang {FUNCTION}"
- Read target UC -> extract main/alt flows, BRs, NFRs
- Generate test cases covering: happy path, alt flows, boundary values, security
- Output: `PM_REVIEW/{PLATFORM}/TESTING/{MODULE}/{FUNCTION}_testcases.md`

### Mode B — EXECUTE
"Thuc hien test theo file {FILE}"
- Read existing test case file
- Classify: L1 (API/curl), L2 (UI smoke), L3 (Manual/skip)
- Execute L1+L2, update Status/Actual/Tester/DateTime

### Mode C — TEST_PLAN
"Tao test plan cho module {MODULE}"
- Scan all test case files in module
- Generate execution plan with order, tool mapping, duration estimate

## Coverage Rules

| UC Element | Min Test Cases | Severity |
|---|---|---|
| Main Flow | 1 per flow | CRITICAL |
| Alt Flow | 1 per alt flow | HIGH |
| Business Rule | 1-2 per BR | HIGH/MEDIUM |
| NFR | 1 per NFR | MEDIUM |
| Boundary values | 2 per field | MEDIUM |
| Security | 1-2 per UC | HIGH |

## ID Format

`TC-UC{XX}-{PLATFORM}-{NNN}` (e.g., TC-UC01-ADMIN-001)
