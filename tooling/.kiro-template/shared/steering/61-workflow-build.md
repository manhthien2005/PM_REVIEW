---
inclusion: manual
---

# Workflow: Build (Incremental Implementation)

> **Invoke:** `#61-workflow-build` hoặc "build", "implement", "code", "làm task".

Khi anh invoke workflow này — em follow TDD cycle.

## Pre-flight

1. Detect stack → load patterns tương ứng
2. Verify task source (plan/JIRA/bug/ad-hoc)
3. **Verify branch** — NEVER commit on trunk. Nếu đang trên trunk → STOP, tạo branch.
4. **Infra-file guard** — `.kiro/`, `.github/`, `PM_REVIEW/ADR/` trên feat branch → STOP, dùng chore branch.

## Per-task TDD cycle

### RED — Write failing test
- One behavior per test
- Clear name (describes behavior, not implementation)
- Run test → confirm FAIL (not error due to typo)

### GREEN — Minimum code to pass
- Only enough code for test to pass
- No extra options, no abstractions, no "for later"

### REFACTOR — Clean up while green
- Rename, extract helpers, remove duplication
- No new behaviour during refactor
- Tests stay green

### Commit
```
<type>(<scope>): <mô tả tiếng Việt>
```

## Commands per stack

| Stack | Test | Lint |
|---|---|---|
| Flutter | `flutter test test/<feature>/` | `flutter analyze` |
| FastAPI | `pytest tests/<file>::<test>` | `black . ; isort .` |
| Express | `npm test -- <file>` | `npm run lint` |
| React | `npm test -- <component>` | `npm run lint` |

## Final verify (before claiming done)

- Test command output: 0 fail, exit 0
- Lint output: 0 error
- Bug fix: reproduction test red → fix → green → revert → red → restore → green
- Spec met: line-by-line checklist vs UC/spec

## Boundaries (Karpathy)

- ≤ 100 lines per increment
- Touch only what's needed
- Keep it building after every commit
- Each commit revertable
- No skipped/disabled tests
