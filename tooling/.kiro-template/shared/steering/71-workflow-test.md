---
inclusion: manual
---

# Workflow: Test Writing

> **Invoke:** `#71-workflow-test` hoac "write tests", "add tests", "coverage".

Write or extend tests (unit/widget/integration/contract) following TDD.

## When to use

- Adding tests for existing code (legacy area)
- Writing regression test for bug fix
- Auditing coverage and adding tests for gaps

For new feature: use build workflow directly (TDD cycle included).

## Pre-flight

- Identify scope: which file/function/feature needs tests?
- Check current coverage per stack

## Pattern by case

### A. Tests for existing code (none yet)
1. Read code -> understand current behavior
2. List behaviors to test: happy path, edge case, error path
3. Write test per behavior -> PASS = characterization test, FAIL = discovered bug

### B. Regression test for bug fix
1. Write failing test (RED)
2. Apply fix -> PASS
3. Revert fix -> FAIL (proof)
4. Restore fix -> PASS
5. Commit fix + test together

### C. Coverage audit
1. Generate coverage report
2. Focus on business logic (not framework wiring)
3. Prioritize: auth/fall/SOS/vitals (critical) > feature core > utilities

## Test types per stack

| Stack | Unit | Integration | Run |
|---|---|---|---|
| Flutter | Riverpod notifier + repository | widget + integration_test | `flutter test test/<feature>/` |
| FastAPI | service layer | TestClient endpoint | `pytest tests/<file>::<test>` |
| Express | service + Prisma mock | route -> service | `npm test -- <file>` |
| React | hooks, utilities | component render + event | `npm test -- <component>` |

## Naming rules

Good: 'rejects fall event with confidence < 0.5'
Bad: 'test1', 'works', has "and" (split into 2)

## Coverage targets

| Layer | Target |
|---|---|
| Business logic | >= 80% |
| Repository | >= 70% |
| Router/controller | >= 60% |
| UI widget/component | >= 50% |

## Anti-patterns

- Mock everything -> use real impl + real DB for repository tests
- Testing internals -> test public API
- `.skip()` failing tests -> fix root cause or delete
- Test depends on network -> mock HTTP boundary
