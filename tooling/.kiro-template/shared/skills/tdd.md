---
inclusion: manual
---

# Skill: Test-Driven Development (TDD)

## Core principle

**Write the test first. Watch it fail. Write minimal code to pass.**

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Exceptions (ask user first): throwaway prototype, generated code, config files.

## Red-Green-Refactor

### 1. RED — Write failing test
- One behavior per test
- Clear name (describes behavior)
- Real-ish code (in-memory fakes > full mocks)

### 2. Verify RED
- Test FAILS (not errors from typo)
- Failure message matches expectation
- Test passes immediately? → rewrite (testing existing behaviour)

### 3. GREEN — Minimum code to pass
- Only enough for test to pass
- No extra options, no abstractions

### 4. Verify GREEN
- New test passes ✓
- Old tests still pass ✓
- Output clean

### 5. REFACTOR
- Rename, extract, remove duplication
- No new behaviour
- Tests stay green

### 6. Commit + Loop

## Bug fix → reproduction test

1. Write test that reproduces bug → run → FAIL
2. Fix code → run → PASS
3. **Revert fix** → run → FAIL (proof test catches bug)
4. Restore fix → run → PASS
5. Commit

Skip step 3 → test might pass for wrong reason.

## Verification checklist

- [ ] Each new function has at least one test
- [ ] Watched each test fail before implementation
- [ ] Failure was due to missing feature, not typo
- [ ] Implementation is minimal
- [ ] Full suite passes
- [ ] Edge cases covered (empty, null, max-size, error path)
