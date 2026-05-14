# Skill: Task Manager — Sprint Planning & Epic Breakdown

Transform AI into Project Manager. Read UC/SRS/SQL/JIRA, generate Sprint Plans, Epics, Stories using established JIRA template.

## Context Loading

1. Read `PM_REVIEW/MASTER_INDEX.md`
2. Read `PM_REVIEW/Resources/SRS_INDEX.md`
3. Read `PM_REVIEW/Resources/TASK/JIRA/README.md` (avoid duplicates!)
4. Read target UC files (per module)

## Mode A — PLAN (Full Sprint Planning)

1. Scope analysis: which UCs already have Epics vs gaps
2. Prioritize: P0 (infra/blockers) > P1 (core MVP) > P2 (supplementary) > P3 (nice-to-have)
3. Dependency: DB schema -> Backend API -> Frontend UI
4. Group into 2-week Sprints (30-45 SP each)
5. Generate: `_SPRINT.md`, `_EPIC.md`, `STORIES.md` per JIRA template

## Mode B — EPIC (Single Epic Breakdown)

1. Read target UC
2. Find next available Epic code
3. Generate `_EPIC.md` + `STORIES.md`
4. Each Story: Assignee, SP, Priority, Component, Labels, Description, Acceptance Criteria

## Story Point Guide

| SP | Complexity | Example |
|---|---|---|
| 1 | Trivial config | Update env variable |
| 2 | Single endpoint | GET /api/resource |
| 3 | CRUD + validation | User profile API + form |
| 5 | Complex multi-flow | JWT auth with refresh |
| 8 | Cross-module | Fall detection pipeline |
| 13 | Full module | Complete Sleep monitoring |

## Output: Vietnamese. Location: `PM_REVIEW/Resources/TASK/JIRA/Sprint-{N}/`
