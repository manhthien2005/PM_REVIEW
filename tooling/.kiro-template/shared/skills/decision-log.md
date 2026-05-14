---
inclusion: manual
---

# Skill: Decision Log (ADR-lite)

## When to log

- Choosing approach A over B (≥ 2 options)
- Adopting new library/framework/pattern
- Changing project-wide convention
- Defining cross-repo contract
- Reversing previous decision

## ADR ID: `<NNN>-<short-kebab-title>.md` (sequential, system-wide)

Location: `PM_REVIEW/ADR/`

## Template

```markdown
# ADR-<NNN>: <Short title>

**Status:** Proposed / Accepted / Superseded by <NNN>
**Date:** YYYY-MM-DD
**Tags:** [workspace, tooling, mobile, backend, security, ...]

## Context
What's the situation? What forces?

## Decision
**Chose:** <Option name>
**Why:** <reasoning>

## Options considered
### Option A (chosen): <name>
- Pros / Cons / Effort

### Option B (rejected): <name>
- Pros / Cons / **Why rejected**

## Consequences
- Positive: ...
- Negative / Trade-offs: ...
- Follow-up actions: ...

## Reverse decision triggers
- If <X> changes → reconsider
```

## INDEX.md maintenance

Update `PM_REVIEW/ADR/INDEX.md` whenever:
- New ADR created → add to chronological + tag tables
- Status changes → update row
