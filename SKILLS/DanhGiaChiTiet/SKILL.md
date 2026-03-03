---
name: detailed-feature-review
description: "Detailed evaluation of a specific feature in the project. Triggers on keywords: review code, evaluate feature, check implementation, danh giá chi tiết, detailed review. Integrates architecture standards + progressive deepening."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-03"
---

# 🔬 Skill: Detailed Feature Review (DanhGiaChiTiet)

## Purpose

Conduct a **detailed evaluation** of a specific system feature — analyzing the actual code against industry architecture standards, verifying SRS compliance, checking implementation quality, and cross-referencing Trello tasks.

## When to Use This Skill

Automatically activates when the user wants to:
- Review code quality for a specific module
- Verify if a feature complies with the SRS
- Check acceptance criteria execution from a Trello card
- Evaluate specific implementation details (e.g., Auth, Monitoring, Emergency)

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to optimize token limits and ensure accuracy.

### Tier 1: Navigate (ALWAYS first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** → Find the corresponding module row.
2. Note down: Sprint, UC refs, summary file path.

### Tier 2: Load Context (Read ONE summary)
3. **Read the corresponding summary file** (e.g.: `summaries/AUTH_summary.md`).
4. **DO NOT read the full SRS, DO NOT read the full Trello Sprints.**

### Tier 3: Prepare Integrated Skills
5. **CRITICAL:** Before evaluating, read the internal bundled skills under `skills/` to inherit their constraints:
   - `skills/architect-review/SKILL.md`
   - `skills/software-architecture/SKILL.md`
   - `skills/backend-architect/SKILL.md`
   - `skills/architecture-patterns/SKILL.md`
   - `skills/architecture-decision-records/SKILL.md`

### Tier 4: Deep Dive (Progressive — code only)
6. **Scan**: List files in the related folder → verify files exist.
7. **Surface**: Read file outlines (function names, class names, LOC).
8. **Deep**: Read detailed contents ONLY for the files requiring evaluation.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS → use the summary instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read the full Trello Sprint file → checklists are in the summary.
- ❌ **DO NOT** read files unrelated to the module currently under review.
- ❌ **DO NOT** read all source code at once → read file by file selectively.

## Evaluation Process

**Step 1:** Complete the Context Loading Protocol.
**Step 2:** Code Analysis (8 Criteria). **READ `references/evaluation-criteria.md` for the detailed point breakdown and checks.**
**Step 3:** Use Trello Tasks from the summary to cross-check.
**Step 4:** SRS/Use Case Verification from the summary.

## Output Formatting

**MANDATORY:** You must use the Vietnamese markdown reporting template located at `references/report-template.md`. You must not deviate from this template.

## After Review: Update MASTER_INDEX
When the review process concludes, you must modify the corresponding module row in `MASTER_INDEX.md`:
- Set `Review Status` → ✅ Done (or accordingly)
- Set `Score` → XX/100
- Set `Last Review` → [Current date]
