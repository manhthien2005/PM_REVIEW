---
inclusion: manual
---

# Workflow: Fix Issue (End-to-End)

> **Invoke:** `#72-workflow-fix-issue` hoac "fix issue", "fix bug end-to-end".

Targeted issue resolution: analyze -> plan minimal fix -> implement -> test.

## Pre-flight

1. Get issue details: repro steps, stack trace, affected repo
2. Check bug log: `PM_REVIEW/BUGS/<BUG-ID>.md` — DO NOT retry failed approaches
3. Branch: `fix/<short-desc>` tu trunk

## Step 1 — Understand the issue

- Read full issue description + stack trace
- Reproduce locally
- DO NOT fix an issue you can't reproduce (unless stack trace clearly identifies root cause)

## Step 2 — Root cause analysis

Apply debug workflow (Phase 1-3): read errors -> reproduce -> check recent changes -> trace data flow -> form hypothesis.

## Step 3 — Plan minimal fix

Karpathy: surgical changes.
- Identify minimal change to address root cause
- DON'T bundle refactors or other bug fixes
- If big (multi-file, architectural) -> discuss with anh first

## Step 4 — Implement (TDD)

1. Write failing test reproducing bug
2. Verify FAIL with right symptom
3. Minimal fix
4. Verify PASS
5. Revert fix -> verify FAIL again (proof)
6. Restore -> verify PASS
7. Commit fix + regression test

## Step 5 — Verify end-to-end

Beyond unit tests:
- Mobile: run on real device, repro original steps
- Backend: hit endpoint locally, check logs
- Admin FE: manually click through affected page

## Step 6 — Commit

```
fix(<scope>): <mo ta tieng Viet>

Root cause: <goc van de>
Fix: <approach>
Test: regression test trong <test file>
Bug log: PM_REVIEW/BUGS/<BUG-ID>.md
```

Update bug log: mark attempt `successful` + link fix commit.

## Anti-patterns

- Fix without reproducing -> might fix wrong thing
- Fix multiple issues in one commit -> can't revert granularly
- Skip regression test -> bug can recur
- Fix symptom, not root cause -> similar issues appear elsewhere
