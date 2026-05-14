---
inclusion: manual
---

# Skill: Writing Plans (Vertical Slice)

## When to use

Feature ≥ 3 tasks + spec approved.

## Output

- `docs/plans/YYYY-MM-DD-<feature>.md` — full plan
- `tasks/todo-<feature>.md` — checkbox list

## Task granularity

Each step = 1 action ~2-5 minutes:
- Write failing test → Run (confirm fail) → Implement minimal → Run (confirm pass) → Commit

## Task structure

```markdown
### Task N: [Component name]

**Files:**
- Create: `<full path>`
- Modify: `<full path>`
- Test: `<full path>`

**Dependencies:** Task X, Y

- [ ] Step 1: Write failing test [exact code]
- [ ] Step 2: Run → confirm FAIL [exact command]
- [ ] Step 3: Implement minimal [exact code]
- [ ] Step 4: Run → confirm PASS [exact command]
- [ ] Step 5: Commit [exact command]
```

## Ordering

```
✅ Vertical: Each task delivers thin end-to-end slice
❌ Horizontal: All DB → All API → All UI
```

Foundation first → Risk-first → Dependencies → Quick wins

## No placeholders

Every step MUST have real content. Banned:
- "TBD", "TODO", "implement later"
- "Add appropriate error handling"
- "Similar to Task N"
- Steps without code blocks

## Self-review

1. Spec coverage: task for each requirement?
2. Placeholder scan
3. Name consistency across tasks
