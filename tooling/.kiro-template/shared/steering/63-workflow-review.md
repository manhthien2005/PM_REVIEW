---
inclusion: manual
---

# Workflow: Code Review (Five-Axis)

> **Invoke:** `#63-workflow-review` hoặc "review", "check code", "self-review", "trước khi merge".

Khi anh invoke workflow này — em follow framework 5-axis.

## 5 Axes

### 1. Correctness
- Logic matches spec/UC acceptance criteria?
- Edge cases: empty, null, max-size, boundary, negative?
- Error paths handled? Async/concurrency safe?

### 2. Readability
- Naming describes intent?
- Functions ≤ 50 lines, single-responsibility?
- Comments explain WHY (not WHAT)?
- Files < 300 lines?

### 3. Architecture
- Clear layering (data → application → presentation)?
- Dependency direction correct?
- Reuses existing patterns?
- No premature abstraction?

### 4. Security
- No hardcoded secrets?
- Input validated at boundary?
- Auth + authorization on every protected endpoint?
- PII not logged?
- No SQL concat, no XSS vectors?

### 5. Performance
- No N+1 queries?
- Pagination on large lists?
- `const` constructors (Flutter)?
- Stream subscriptions disposed?

## Output format

- 🔴 **Critical** — must fix before merge
- 🟡 **Important** — should fix before merge
- 🟢 **Suggestion** — nice-to-have
- ✅ **Good** — highlight good patterns

## VSmartwatch-specific flags

- PHI in logs (email, phone, heartRate, vital)
- Cross-repo contract change without updating consumer
- Audit log missing for PHI access
- `setState()` after `await` without `mounted` check
- `Dio()` inline (bypasses JWT interceptor)
- Touch target < 48dp (accessibility)
- Pydantic v1 syntax (must be v2)
- `io.emit` broadcast all sockets (use rooms)

## Quick checklist (mini-review per commit)

- [ ] Tests pass (ran command, read output)
- [ ] Lint clean
- [ ] Diff focused — only changes for this task
- [ ] No debug logs left
- [ ] No commented-out dead code
- [ ] Commit message conventional + describes WHY
