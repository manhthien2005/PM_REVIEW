---
inclusion: manual
---

# Workflow: Close Task (Post-Merge Cleanup)

> **Invoke:** `#66-workflow-close-task` hoac "close task", "post-merge", "cleanup branch".

## Step 1 — Verify merge

```pwsh
git -C <repo> fetch origin
git -C <repo> log origin/<trunk> --oneline -n 5
```

Confirm merge commit visible. If revert detected -> STOP, investigate.

## Step 2 — Pull trunk + delete branch

```pwsh
git -C <repo> checkout <trunk>
git -C <repo> pull origin <trunk>
git -C <repo> branch -d <task-branch>
git -C <repo> push origin --delete <task-branch>
git -C <repo> remote prune origin
```

If `branch -d` fails -> DO NOT force-delete. Investigate unmerged commits.

## Step 3 — Update trackers

### Bug log (if bug fix)
- Set `status: resolved` in `PM_REVIEW/BUGS/<BUG-ID>.md`
- Add `resolution_commit`, `resolution_date`, `regression_test`
- Update `BUGS/INDEX.md`: move to Resolved

### ADR (if architectural decision)
- Change status `Proposed` -> `Accepted`
- Add `implementation_commit`
- Update `ADR/INDEX.md`

### JIRA Story
- Update `PM_REVIEW/Resources/TASK/JIRA/Sprint-*/STORIES.md`: status -> Done
- Add `Completed: <date>` + `PR: <url>`

### Plan file (if plan-driven)
- Mark task checkbox `[x]` + add commit ref
- If all tasks done -> archive plan

## Step 4 — Commit tracker updates

```pwsh
git -C PM_REVIEW checkout -b chore/close-<task-id>
git -C PM_REVIEW add BUGS/ ADR/ Resources/TASK/
git -C PM_REVIEW commit -m "chore(trackers): close <task-id> sau khi merge"
git -C PM_REVIEW push -u origin chore/close-<task-id>
```

## Step 5 — Verification

- `git branch` shows no `<task-branch>`
- `git ls-remote --heads origin` shows no `<task-branch>`
- Tracker files updated (diff visible)
- Trunk has merge commit

## Anti-patterns

- Skip tracker update -> future-anh debugs same bug
- Force-delete unmerged branch -> lost work
- Tag every task -> tag noise
