---
name: detailed-feature-review
description: "Detailed evaluation of a specific feature in the project. Triggers on keywords: review code, evaluate feature, check implementation, danh giá chi tiết, detailed review. Integrates architecture standards + progressive deepening."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-04"
---

# Skill: Detailed Feature Review (DanhGiaChiTiet)

## Purpose

Conduct a **detailed evaluation** of a specific system feature — analyzing the actual code against industry architecture standards, verifying SRS compliance, checking implementation quality, and cross-referencing JIRA Epics/Stories.

## When to Use This Skill

Automatically activates when the user wants to:
- Review code quality for a specific module
- Verify if a feature complies with the SRS
- Check acceptance criteria execution from a JIRA Story
- Evaluate specific implementation details (e.g., Auth, Monitoring, Emergency)

## Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to optimize token limits and ensure accuracy.

### Tier 1: Navigate (ALWAYS first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** → Find the corresponding module row.
2. Note down: Sprint, UC refs, summary file path.

### Tier 2: Load Context (Read ONE summary)
3. **Read the corresponding summary file** (e.g.: `summaries/AUTH_summary.md`).
4. **Read `PM_REVIEW/Resources/SRS_INDEX.md`** for system-level context (thresholds, architecture, feature mapping).
5. **DO NOT read the full SRS, DO NOT read the full JIRA CSV.** Instead, read `PM_REVIEW/Resources/TASK/JIRA/README.md` (JIRA Index) to quickly locate the relevant Epic/Stories.

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
- ❌ **DO NOT** read the full JIRA CSV → use `JIRA/README.md` index to find the relevant Epic, then read only the matching Stories in the CSV.
- ❌ **DO NOT** read files unrelated to the module currently under review.
- ❌ **DO NOT** read all source code at once → read file by file selectively.

## Evaluation Process

**Step 1:** Complete the Context Loading Protocol.
**Step 2:** Code Analysis (8 Criteria). **READ `references/evaluation-criteria.md` for the detailed point breakdown and checks.**
**Step 3:** Use JIRA Stories (from JIRA Index → CSV) to cross-check acceptance criteria.
**Step 4:** SRS/Use Case Verification from the summary.

## Output File Protocol (MANDATORY)

### File Naming Convention
The review file MUST follow this naming pattern:
```
{FEATURE}_{MODULE}_review.md
```
- **FEATURE**: The feature name requested for review, UPPERCASE, spaces → `_` (e.g., `AUTH_LOGIN`, `DEVICE_CONNECT`)
- **MODULE**: Module name from MASTER_INDEX, UPPERCASE (e.g., `AUTH`, `DEVICE`, `MONITORING`)
- If the feature name matches the module name (reviewing the entire module) → use `{MODULE}_review.md` only

### Output Location
- Admin project → `PM_REVIEW/REVIEW_ADMIN/{filename}`
- Mobile project → `PM_REVIEW/REVIEW_MOBILE/{filename}`

### Examples
| User Request                                           | File Output                              |
| ------------------------------------------------------ | ---------------------------------------- |
| "Review Login feature, AUTH module, Admin project"     | `REVIEW_ADMIN/AUTH_LOGIN_review.md`      |
| "Review AUTH module, Admin project"                    | `REVIEW_ADMIN/AUTH_review.md`            |
| "Review Device Connect feature, DEVICE module, Mobile" | `REVIEW_MOBILE/DEVICE_CONNECT_review.md` |

## Re-review Protocol (2nd review and beyond)

> [!IMPORTANT]
> Before starting a review, the AI MUST check if a previous review file already exists. If found → perform comparison.

### Step 1: Find previous review file
1. Determine the filename using the **Output File Protocol** above.
2. Check if the file exists in `REVIEW_ADMIN/` or `REVIEW_MOBILE/`.

### Step 2: Read previous review file (if exists)
3. Read the old review file and extract:
   - **Old score**: Total score + score per criterion.
   - **Old weaknesses**: List of all weaknesses.
   - **Old recommendations**: List of action recommendations.
   - **Old review date**: From the "Thông tin chung" section.
   - **Old review count**: From the "Thông tin chung" section (if present).

### Step 3: Perform new review as normal
4. Execute the review following the Evaluation Process above (Step 1–4).

### Step 4: Compare and evaluate changes
5. Compare new results with data extracted from the old file:
   - Score increase/decrease per criterion.
   - Weaknesses that have been **fixed** (present in old, absent in new).
   - Weaknesses that **still exist** (present in both old and new).
   - Weaknesses that are **newly introduced** (absent in old, present in new).

### Step 5: Overwrite old file
6. **OVERWRITE** the old review file with the complete new report, including the "🔄 SO SÁNH VỚI LẦN ĐÁNH GIÁ TRƯỚC" section (per template `references/report-template.md`).
7. Increment the **Lần đánh giá** counter by 1.

### Important Notes
- If **NO previous file found** → this is the first review → do NOT add comparison section, set `Lần đánh giá: 1`.
- If **previous file found** → MUST add comparison section and increment `Lần đánh giá`.

## Output Formatting

**MANDATORY:** You must use the Vietnamese markdown reporting template located at `references/report-template.md`. You must not deviate from this template.

## After Review: Update MASTER_INDEX (MANDATORY)

When the review process concludes, you **MUST** modify the corresponding module row in `MASTER_INDEX.md`:

1. Set `Review Status` → ✅ Done
2. Set `Score` → XX/100
3. Set `Quality` → Determined by score (see `references/evaluation-criteria.md` → Score Classification):
   - **76–100** → ✅ Pass
   - **51–75** → ⚠️ Needs Fix
   - **0–50** → ❌ Fail
4. Set `Review File` → Relative link to the review output file (e.g., `[View](REVIEW_ADMIN/AUTH_review.md)`)
5. Set `Last Review` → Current date (ISO format)

## Reference Documents

| Name             | Path                                                | When to read                                   |
| ---------------- | --------------------------------------------------- | ---------------------------------------------- |
| **MASTER INDEX** | `PM_REVIEW/MASTER_INDEX.md`                         | **ALWAYS**                                     |
| **SRS Index**    | `PM_REVIEW/Resources/SRS_INDEX.md`                  | **ALWAYS** — System-level context              |
| Admin Structure  | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md`       | When reviewing Admin                           |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md`      | When reviewing Mobile                          |
| Admin Summaries  | `PM_REVIEW/REVIEW_ADMIN/summaries/*.md`             | Based on module                                |
| Mobile Summaries | `PM_REVIEW/REVIEW_MOBILE/summaries/*.md`            | Based on module                                |
| Use Cases (UC)   | `PM_REVIEW/Resources/UC/**/*.md`                    | When explicit detail is missing from summaries |
| **JIRA Index**   | `PM_REVIEW/Resources/TASK/JIRA/README.md`           | **ALWAYS** — Quick lookup for Epics/Stories    |
| JIRA Full CSV    | `PM_REVIEW/Resources/TASK/JIRA/JIRA_IMPORT_ALL.csv` | Only when need full Story details              |
