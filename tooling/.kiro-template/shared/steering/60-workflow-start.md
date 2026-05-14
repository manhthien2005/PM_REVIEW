---
inclusion: manual
---

# Workflow: Task Kickoff

> **Invoke:** `#60-workflow-start` hoặc "start task", "bắt đầu task", "new task".

Khi anh invoke workflow này hoặc nhắc JIRA Story/UC/Bug ID — em follow quy trình.

## Step 1 — Resolve task reference

- JIRA Story: tìm trong `PM_REVIEW/Resources/TASK/JIRA/Sprint-*/STORIES.md`
- UC: tìm trong `PM_REVIEW/Resources/UC/<Module>/UC<XXX>.md`
- Bug: đọc `PM_REVIEW/BUGS/<BUG-ID>.md`
- Free text: search UC + JIRA by keyword, hỏi nếu multiple match

## Step 2 — Extract acceptance criteria

Từ UC + JIRA Story, build:
- Task name + source (UC + Story)
- Repos affected
- Acceptance criteria (checklist)
- Out-of-scope
- Files to read first (context)
- Files allowed to touch (scope guard)

## Step 3 — Check blockers

- Dependencies (other UC/Story) đã done chưa?
- DB migration đã deploy chưa?
- Nếu blocker open → STOP, report.

## Step 4 — Sync trunk + check working tree

```pwsh
git -C <repo> fetch origin
git -C <repo> status --short
```

Uncommitted changes → hỏi anh: stash or commit first?

## Step 5 — Create branch

Format: `<type>/<short-desc>` từ correct trunk:
- HealthGuard, health_system, Iot_Simulator_clean → `develop`
- healthguard-model-api → `master`
- PM_REVIEW → `main`

## Step 6 — Bug log check (nếu bug fix)

Đọc `PM_REVIEW/BUGS/<BUG-ID>.md`. Note prior failed attempts — DO NOT retry them.

## Step 7 — Summary

Print concise summary với: Task, Source, Repos, Blockers, Branch, Bug log status, Acceptance criteria, Files to read.

Ready → bắt đầu implement (TDD cycle).
