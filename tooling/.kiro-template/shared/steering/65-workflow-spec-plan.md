---
inclusion: manual
---

# Workflow: Spec & Plan

> **Invoke:** `#65-workflow-spec-plan` hoặc "spec", "plan", "thiết kế", "phân tích feature", "break down".

Khi anh invoke workflow này — em follow Spec Phase → Plan Phase.

## Spec Phase (trước Plan)

### Discovery
- User pain point? Primary actor?
- Smallest MVP scope? Out-of-scope?
- Cross-repo impact?
- DB changes? API contract change? PHI handling?

### Propose 2-3 approaches
Lead with recommendation:
- Approach A (recommended): pros, cons, effort, cross-repo impact
- Approach B: pros, cons, effort
- Wait for anh chọn.

### Write UC + spec doc
- UC: `PM_REVIEW/Resources/UC/<Module>/UC<XXX>.md`
- Design: `<repo>/docs/specs/YYYY-MM-DD-<feature>.md`
- Include: goal, scope, technical approach, API contract, security, testing strategy

### Gate
Commit spec → notify anh → wait for approval.

## Plan Phase (sau Spec approved)

### Vertical slice ordering
```
❌ Horizontal: All DB → All API → All UI
✅ Vertical: Each task delivers thin end-to-end slice
```

Order: Foundation first → Risk-first → Dependencies → Quick wins

### Task structure
Each task = 1 Red-Green-Refactor cycle:
- Files to create/modify
- Failing test (exact code)
- Minimal implementation (exact code)
- Verify command + expected output
- Commit command

### Output files
- `docs/plans/YYYY-MM-DD-<feature>.md` — full plan
- `tasks/todo-<feature>.md` — checkbox list

### Self-review
- Spec coverage: task for each requirement?
- No placeholders ("TBD", "implement later")
- Name consistency across tasks

### Handoff
"Plan done. X tasks, Y checkpoints. Start Task 1, or review first?"

## Kiro Spec Integration

Kiro có native spec workflow (`.kiro/specs/`). Khi feature phức tạp, em có thể dùng Kiro spec system:
- Requirements → Design → Tasks
- Mỗi task có status tracking
- Auto-execute qua task runner

Anh chọn: dùng Kiro native specs hay manual plan files.
