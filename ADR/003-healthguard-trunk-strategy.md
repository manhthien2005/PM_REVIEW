---
id: 003
title: HealthGuard trunk = develop (deploy is user-owned release branch)
status: Accepted
date: 2026-05-11
deciders: anh + Cascade
tags: [git, branching, healthguard, workflow]
supersedes: null
superseded_by: null
---

# Context

`HealthGuard` repo có 3 branches: `main`, `develop`, `deploy`. Phase 4 review phát hiện trunk reference mâu thuẫn:

- `sync.ps1` ghi trunk = `deploy`
- Rule 10 (project context) ghi trunk = `deploy`
- Workflow `topology.md`, `start.md`, `debug.md` ghi trunk = `deploy`
- PR Phase 3 thực tế merge vào `develop` (không phải `deploy`)
- PR Phase 4 cũng merge vào `develop`

Mâu thuẫn này khiến AI có thể tạo branch từ outdated `deploy` → branch không có changes mới nhất → `.windsurf/` config thiếu file → hook fail (đã xảy ra trong Phase 4 M6).

Anh confirm: deploy = production release branch, anh manual promote khi muốn release. AI không touch `deploy`.

# Options

## Option A: Single trunk = `develop`, drop `deploy` reference từ AI workflow
- AI làm việc exclusively trên `develop` (integration trunk)
- `deploy` invisible to AI — anh manage qua git CLI hoặc GitHub UI
- Rule + workflow + sync.ps1 đều ghi trunk = `develop`
- Pro: Simple, no AI confusion
- Con: AI không có concept of "release branch" → anh phải tự handle promotion

## Option B: Dual-trunk model — develop = integration, deploy = release
- Rule document cả 2 trunks với explicit role
- AI vẫn branch từ `develop`, nhưng aware về `deploy` for context
- Pro: Reflects actual git topology
- Con: AI có thể confused "PR vào đâu?" — rule phải clear "always develop"

## Option C: Rename `deploy` → `release`
- Chuẩn hơn về semantics
- Pro: Clearer intent
- Con: Breaking change cho existing CI/CD if any, requires repo rename

# Decision

**Choose Option A** — single trunk = `develop` for AI workflow.

Rationale:
- Solo dev đồ án 2 — dual-trunk model là over-engineering cho scale hiện tại
- Anh prefer keeping `deploy` ownership entirely manual (per anh's statement: "deploy là of anh, em không cần care")
- AI workflow simpler: 1 trunk concept, no special-case for HealthGuard
- Future: nếu cần promote, anh có thể merge `develop` → `deploy` via GitHub UI hoặc local CLI

# Consequences

## Positive
- AI never works on/touches `deploy` branch
- Sync.ps1 + rules + workflows aligned (single source of truth)
- No more "wrong trunk" branching errors

## Negative / Trade-offs
- AI không có visibility on release schedule (intentional — that's anh's domain)
- Workflows like `/deploy` are documentation-only — em không tự run

## Side-effects (apply during implementation)
- Update `sync.ps1` HealthGuard.Trunk = `develop` (DONE in chore/workspace-fixes)
- Update rule 10 trunk column to `develop` (DONE in chore/workspace-fixes)
- Replace `deploy` references in `topology.md`, `start.md`, `debug.md` (THIS COMMIT)
- Update `repo-context.md` auto-gen via sync.ps1

# Reverse Triggers

Reconsider this ADR if:
- Project moves from solo dev → team → dual-trunk model justified by parallel release/dev streams
- CI/CD pipeline locked to specific branch name `deploy`
- Anh wants AI to manage release promotion automatically

# Related

- ADR-001: Workspace tooling host
- ADR-002: Bug log + ADR centralized
- Rule `10-project-context.md` (trunk table)
- Phase 4 M6 incident: PR Phase 3 merged to `develop`, AI branched from outdated `deploy`
