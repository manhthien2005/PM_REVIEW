---
inclusion: manual
---

# Skill: Bug Log (Anti-Loop Cross-Session Memory)

## Iron Law

```
NO FIX PROPOSAL WITHOUT READING THE BUG LOG FIRST
```

If `PM_REVIEW/BUGS/<BUG-ID>.md` exists → MUST read all prior attempts. Approach marked `failed` is OFF-LIMITS.

## When to invoke

- `/debug` or `/fix-issue` starts
- User says "this bug again", "still broken", "tried that"
- 2nd+ session on same bug
- Non-trivial bug expected to span multiple sessions

## Bug ID: `<REPO-PREFIX>-<NUM>` (3-digit)

HG = HealthGuard, HS = health_system, IS = Iot_Simulator, MA = model-api, XR = Cross-repo

## Workflow

### Starting a bug
1. Check if log exists: `PM_REVIEW/BUGS/<BUG-ID>.md`
2. Read all prior attempts
3. If no log + non-trivial → create from `_TEMPLATE.md`

### Per attempt
Append:
```markdown
### Attempt N — YYYY-MM-DD HH:MM
**Hypothesis:** ...
**Approach:** ...
**Files touched:** ...
**Verification:** ...
**Result:** ✅ successful / ❌ failed
**Reason (if failed):** ...
**Next step:** ...
```

### When resolved
- Update status → ✅ Resolved
- Link fix commit
- Update `PM_REVIEW/BUGS/INDEX.md`

### When stuck (3+ failed)
- STOP → Stuck workflow
- Re-read entire log
- Question: is this the right bug?
