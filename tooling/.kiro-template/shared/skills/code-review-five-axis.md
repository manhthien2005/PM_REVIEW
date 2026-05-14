---
inclusion: manual
---

# Skill: Code Review — Five-Axis Framework

## 5 Axes

### 1. Correctness
- Logic matches spec/acceptance criteria
- Edge cases: empty, null, max-size, boundary
- Error paths handled, async/concurrency safe
- State management: clear source of truth

### 2. Readability
- Naming describes intent
- Functions ≤ 50 lines, single-responsibility
- Magic numbers → named constants
- Comments explain WHY

### 3. Architecture
- Clear layering (data → application → presentation)
- Dependency direction correct
- Reuses existing patterns
- No premature abstraction

### 4. Security
- No hardcoded secrets
- Input validated at boundary
- Auth + authorization enforced
- PII not logged
- No SQL concat, no XSS

### 5. Performance
- No N+1 queries
- Pagination on large lists
- Resources disposed (streams, controllers)
- Const constructors (Flutter)

## Output format

- 🔴 Critical — must fix before merge
- 🟡 Important — should fix
- 🟢 Suggestion — nice-to-have
- ✅ Good — highlight good patterns

## Quick checklist (per commit)

- [ ] Tests pass
- [ ] Lint clean
- [ ] Diff focused
- [ ] No debug logs
- [ ] No dead code
- [ ] Commit message conventional + WHY
