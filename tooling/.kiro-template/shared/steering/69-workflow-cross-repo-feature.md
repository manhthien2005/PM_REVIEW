---
inclusion: manual
---

# Workflow: Cross-Repo Feature Orchestration

> **Invoke:** `#69-workflow-cross-repo-feature` hoac "cross-repo feature", "feature nhieu repo".

"Producer ships before consumer." VSmartwatch la distributed system — feature thuong touch 2-4 repos.

## Pre-flight

- UC ID phai ton tai trong `PM_REVIEW/Resources/UC/`
- Read `topology.md` — boundary contracts

## Phase 1 — Map repo impact

| Role | Question |
|---|---|
| Spec owner | Where is canonical UC/SQL? (PM_REVIEW) |
| Schema owner | Who owns DB migration? (HealthGuard Prisma) |
| Producer | Who exposes new contract? |
| Consumer | Who calls new contract? |

Output: matrix table (Repo | Role | Files affected | Notes)

## Phase 2 — Build dependency DAG

```
PM_REVIEW (spec) -> DB migration -> Producer -> Consumer -> E2E test -> Tag
```

Rule: producer ships + verified BEFORE consumer migrates.

## Phase 3 — Define cross-repo contract

Document in `PM_REVIEW/CONTRACTS/<feature>-<version>.md`:
- Endpoint, Request/Response schema, Errors, Producer/Consumer refs, Versioning

## Phase 4 — Branch strategy

Same branch name in each affected repo: `feat/<feature-name>`

## Phase 5 — Sequenced execution

1. Spec/UC update (PM_REVIEW)
2. DB migration (Prisma + canonical SQL)
3. Producer side (TDD per build workflow)
4. Consumer side (test against running producer)
5. E2E smoke test
6. Tag release across repos

## Phase 6 — Merge order

1. PM_REVIEW (no runtime impact)
2. HealthGuard (migration)
3. Producer repos
4. Consumer repos

KHONG merge consumer before producer is live.

## Anti-patterns

- Consumer ships before producer -> crash on launch
- Skip contract doc -> drift silently
- Different branch names per repo -> hard to track
- Skip E2E smoke test -> integration bugs discovered by users
