---
inclusion: manual
---

# Workflow: Module Health Audit

> **Invoke:** `#67-workflow-audit` hoac "audit module", "kiem tra module".

## Pre-flight

1. Identify module + scope (repo, cross-repo?)
2. Branch: `chore/audit-<module>` tu trunk. Read-only — khong sua code.
3. Read `topology.md` de biet module cham repo nao.

## Phase 1 — Spec coverage

- Locate UC trong `PM_REVIEW/Resources/UC/{Module}/`
- Match UC -> code: main flow steps, alt flows, business rules, NFR
- Match UC -> JIRA Story
- Cross-check voi SQL schema

Output: Spec coverage table (UC | Main Flow | Alt Flows | BR | NFR | Status)

## Phase 2 — Code health

- File inventory: LOC, last modified
- Dead code: function khong duoc import
- TODO/FIXME audit
- Naming consistency
- Per-stack: `flutter analyze` / `pytest --collect-only` / `npm run lint`

## Phase 3 — Test coverage

- List test files cho module
- Run tests scoped (per stack)
- Identify gaps: happy path, edge case, boundary, security

## Phase 4 — Cross-repo integration

- List endpoints module goi sang repo khac
- Verify contract (producer schema vs consumer call)
- E2E test status

## Phase 5 — Security audit

Per `40-security-guardrails.md`: hardcode secret? SQL injection? Missing auth? PHI logging?

## Phase 6 — Debt log

Compile issues: Critical (block release) | High (next sprint) | Medium/Low (track)

## Phase 7 — Output report

Save: `PM_REVIEW/Task/Audit_<Module>_<YYYY-MM-DD>.md`

## Anti-patterns

- Fix code trong khi audit -> sai workflow. Audit chi la read + analyze.
- Skip spec coverage -> code co the "dung ky thuat" nhung sai requirement.
