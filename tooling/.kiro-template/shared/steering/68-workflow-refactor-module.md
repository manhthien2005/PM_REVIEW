---
inclusion: manual
---

# Workflow: Refactor Module

> **Invoke:** `#68-workflow-refactor-module` hoac "refactor module", "plan refactor".

Bridge tu "audit findings" sang "executable task list". Dam bao refactor co scope ro rang.

## Pre-flight

- Input: Audit report path (output cua `/audit`)
- Branch: `refactor/<module>-<short-desc>` tu trunk

## Phase 1 — Triage findings

| Tier | Definition | Action |
|---|---|---|
| P0 Critical | Bug, security hole, broken contract | MUST fix |
| P1 Important | Tech debt blocking next feature | Fix if scope allows |
| P2 Nice-to-have | Code style, naming | DEFER |

Rule: khong bundle P2 vao refactor scope. Karpathy: surgical.

## Phase 2 — Group into vertical slices

Each task = vertical slice delivering working improvement.
KHONG horizontal ("rename all variables").

## Phase 3 — Define each task

Per task: files in scope, out of scope, behavior preservation tests, risk assessment, verification command.

## Phase 4 — Risk-first ordering

1. Safety net tests first
2. Foundation extractions
3. Risk-first (fail-fast)
4. Independent slices (parallel)
5. Quick wins last

## Phase 5 — Output

- `docs/plans/refactor-<module>-YYYY-MM-DD.md` — full plan
- `tasks/todo-refactor-<module>.md` — checkbox list

## Phase 6 — Execute

Run build workflow task-by-task. Each commit: `refactor(<scope>): <mo ta>`

## Anti-patterns

- Bundle P2 findings -> scope creep
- Skip baseline tests -> can't tell if refactor preserved behavior
- Refactor + add feature in same task -> hard to review/revert
