# Skill: Backlog Auditor — Sprint Review & Tracking

Scan JIRA backlog files to calculate completion metrics, identify blocked/at-risk items, generate progress report.

## Context Loading

1. Read `PM_REVIEW/MASTER_INDEX.md`
2. Read `PM_REVIEW/Resources/TASK/JIRA/README.md`
3. Scan `_SPRINT.md` files: count `[x]` vs `[ ]` Epic boxes
4. Scan `STORIES.md` files: tally Acceptance Criteria checkboxes

## Output

File: `PM_REVIEW/Task/Backlog_Review_{YYYY-MM-DD}.md` (Vietnamese)

Sections:
- Tong Quan table (Sprint | Total EP | Hoan thanh | Ti le)
- Muc Co Rui Ro (items stalled or blocked)
- Phan Tich Stories Noi Bat

## Rules

- READ-ONLY for JIRA directory
- Only write to `PM_REVIEW/Task/` report directory
- Check every checkbox in every loaded STORIES.md for accurate tally
