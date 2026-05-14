---
inclusion: manual
---

# Workflow: Sync Spec (Ripple Detection)

> **Invoke:** `#70-workflow-sync-spec` hoac "sync spec", "UC changed", "ripple".

Spec change without ripple = drift = bugs months later.

## When to use

- UC updated (new flow, changed BR, new field)
- SRS section revised
- SQL canonical schema changed
- API contract version bumped

## Phase 1 — Locate spec change

```pwsh
git -C PM_REVIEW diff HEAD~1 -- Resources/UC/ "SQL SCRIPTS/"
```

Classify: Behavioral | Field added | Field renamed | Field removed | NFR change | Cosmetic

## Phase 2 — Trace ripple targets

For each change, list downstream:
- Code repos affected (search UC reference in code)
- Test files referencing UC behaviors
- JIRA Stories
- Related UCs (include/extend chain)
- DB schema (if data field change)

## Phase 3 — Build ripple plan

Actionable todo per affected file:
- Code: file:line -> update what
- Tests: add/update test for new BR
- JIRA: update acceptance criteria
- DB: add column, write migration

## Phase 4 — Execute

If single repo -> plan + build workflow.
If multi-repo -> cross-repo-feature workflow.

## Phase 5 — Verify ripple complete

- All UC references in code updated
- Tests reference new behavior
- JIRA Stories reflect new acceptance
- DB schema matches UC data fields
- No orphan references to old field/flow

## Anti-patterns

- Update UC, skip ripple -> code drifts from spec
- Skip DB schema sync -> production mismatch
- Bundle multiple UC changes in one commit -> hard to revert
