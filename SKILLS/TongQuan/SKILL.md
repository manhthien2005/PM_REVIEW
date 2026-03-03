---
name: project-overview-assessment
description: "High-level assessment for the HealthGuard project. Triggers on keywords: project structure, project overview, tong quan, review architecture, assess structure. Uses MASTER_INDEX to optimize context."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-03"
---

# 🔍 Skill: Project Overview Assessment (TongQuan)

## Purpose

Evaluate the **holistic structure and progress** of the HealthGuard project to ensure it aligns with the SRS, follows industry-standard architecture, and stays on track with Trello sprint tasks.

## When to Use This Skill

Automatically activates when the user wants to:
- Evaluate the overall project or a specific large section
- Verify if the existing codebase structure reflects the SRS correctly
- Review progress against Trello sprints
- Report the project status to stakeholders

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to optimize token limits and prevent getting lost in context.

### Tier 1: Navigation (ALWAYS read first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** — The overall GPS map of the project.
2. Determine the assessment scope (Admin / Mobile / or both).

### Tier 2: Prepare Integrated Skills
3. **CRITICAL:** Before evaluating, read the internal bundled skills under `skills/` to inherit their high-level structural rules:
   - `skills/architect-review/SKILL.md`
   - `skills/software-architecture/SKILL.md`
   - `skills/backend-architect/SKILL.md`
   - `skills/architecture-patterns/SKILL.md`

### Tier 3: Structure (Read based on scope)
4. **Read the corresponding `Project_Structure.md`** (Admin or Mobile).

### Tier 4: Summaries (Read ONLY relevant summaries)
5. **Read related summary files** from the `summaries/` folder.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS document — use the summary files instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read all Trello Sprint files — checklists are already extracted in the summaries.
- ❌ **DO NOT** read the entire source code — only scan the folder structure for overviews.

## Evaluation Process (Progressive Deepening)

**Step 1:** Complete the Context Loading Protocol.
**Step 2:** Source Code Scan (Surface Level). Browse folder structure without reading file contents, comparing against `Project_Structure.md`.
**Step 3:** Evaluate against 6 Criteria: SRS Compliance, Architecture, Consistency, Progress vs Trello, Code Quality, Security. **READ `references/evaluation-criteria.md` for specific check details.**
**Step 4:** Cross-check with Trello Tasks from the summaries.

## Output Formatting

**MANDATORY:** You must use the Vietnamese markdown reporting template located at `references/report-template.md`. You must not deviate from this template.

## Reference Documents

| Name | Path | When to read |
|------|------|--------------|
| **MASTER INDEX** | `PM_REVIEW/MASTER_INDEX.md` | **ALWAYS** |
| Admin Structure | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md` | When reviewing Admin |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md` | When reviewing Mobile |
| Admin Summaries | `PM_REVIEW/REVIEW_ADMIN/summaries/*.md` | Based on module |
| Mobile Summaries | `PM_REVIEW/REVIEW_MOBILE/summaries/*.md` | Based on module |
| DB Summary | `PM_REVIEW/SQL SCRIPTS/README.md` | When reviewing database design |
| Use Cases (UC) | `PM_REVIEW/Resources/UC/**/*.md` | When explicit detail is missing from summaries |
