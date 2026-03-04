---
name: project-check-update
description: "Scan actual source code and update Project_Structure.md + summaries to stay in sync. Triggers: check project, update structure, check source, sync PM, update summaries."
risk: safe
source: custom
date_added: "2026-03-04"
date_updated: "2026-03-04"
---

# Skill: CHECK — Scan & Update PM_REVIEW

## Purpose

Scan actual project source code → update `Project_Structure.md` and all `summaries/*.md` to ensure PM_REVIEW always reflects the current state. These files are the **project overview map** that allows AI to understand the project without reading every file.

## When to Use

- After significant code changes (new/removed modules, new APIs, refactoring)
- Before starting a new review session to ensure context accuracy
- When migrating task references from Trello → JIRA
- Periodically to keep PM_REVIEW in sync with source code

---

## Project Detection Protocol (MANDATORY)

### Step 1: Detect project folders

| Project   | Path                                 | Target                     |
| --------- | ------------------------------------ | -------------------------- |
| ADMIN WEB | `d:\DoAn2\VSmartwatch\HealthGuard`   | `PM_REVIEW/REVIEW_ADMIN/`  |
| MOBILE    | `d:\DoAn2\VSmartwatch\health_system` | `PM_REVIEW/REVIEW_MOBILE/` |

### Step 2: Handle detection result

| Scenario              | Action                                                            |
| --------------------- | ----------------------------------------------------------------- |
| Only 1 project exists | Proceed with that project                                         |
| Both projects exist   | **MUST ask user to choose one**. NEVER update both simultaneously |
| Neither exists        | Report error, stop                                                |

> [!CAUTION]
> When both projects exist, the AI **MUST** stop and ask: "Both ADMIN and MOBILE projects exist. Which one do you want to check & update?" — NEVER auto-select both.

---

## Context Loading Protocol

### Tier 1: Navigation (ALWAYS)
1. Read `PM_REVIEW/MASTER_INDEX.md`
2. Read `PM_REVIEW/Resources/TASK/JIRA/README.md` (JIRA Index)

### Tier 2: Current State
3. Read current `Project_Structure.md` (ADMIN or MOBILE)
4. Read all current `summaries/*.md`

### Tier 3: Reference
5. Read `references/summary-template.md` — required template for summary files
6. Read `references/update-checklist.md` — checklist for both phases

---

## Phase 1: Update Project_Structure.md

### Process

**Step 1 — Scan actual structure:**
- Use `list_dir` and `find_by_name` to scan the full project folder structure
- Record: new folders, new files, deleted files, LOC changes
- Scan `package.json` / `pubspec.yaml` / `requirements.txt` for dependencies

**Step 2 — Compare with current Project_Structure.md:**
- Compare actual tree vs tree in file
- Compare module/feature list
- Read route files → confirm API endpoints actually exist

**Step 3 — Update the file:**
- Update tree structure to match reality
- Update module statuses (✅ Done / ⬜ Not reviewed / ⚠️ Issues found)
- Replace all "Trello" refs → "JIRA" with correct Epic Names (from JIRA Index)
- Update date + version in changelog section

### Rules for Project_Structure updates
- **Preserve existing format** — only update content
- Tree must match actual folder structure 100%
- Every module must have `SRS Ref` + `JIRA` (replace Trello)
- Review status must match MASTER_INDEX

---

## Phase 2: Update Summaries

### Process

**Step 1 — Read current summary:**
- Read each `summaries/*.md` file
- Note existing content

**Step 2 — Scan corresponding source code:**
- Identify related files from the File Index in summary
- Use `view_file_outline` on key files → confirm functions/classes exist
- Read route files → confirm actual API endpoints
- Check file sizes, LOC

**Step 3 — Cross-reference JIRA:**
- Use JIRA Index (`PM_REVIEW/Resources/TASK/JIRA/README.md`) to map module → Epic Name
- Replace all "Trello Cards" → "JIRA: {Epic Name}"

**Step 4 — Rewrite summary using new template:**

> [!IMPORTANT]
> **MUST** use the template in `references/summary-template.md`. Remove ALL unnecessary content. Keep only essential information.
> **OVERWRITE** the old summary file directly — do NOT create a new file or version.

### What to REMOVE (wastes tokens)

| Section                               | Reason                                                    |
| ------------------------------------- | --------------------------------------------------------- |
| Trello Checklist (Pre-Extracted)      | Duplicates JIRA CSV — AI can query JIRA Index when needed |
| SRS Requirements (verbose extraction) | AI reads UC files when detail is needed                   |
| Emoji in headers                      | Wastes characters, no logical value                       |
| Empty Review Notes                    | Empty section = wasted tokens                             |
| Generic Non-Functional Requirements   | Repeated in every module, provides no new info            |

### What to KEEP (essential)

| Section                         | Value for AI                                     |
| ------------------------------- | ------------------------------------------------ |
| Module identity + JIRA refs     | AI needs to know what module, which JIRA Epic    |
| Purpose & Technique (2-3 lines) | Shortest summary for AI to understand the module |
| API Index (compact)             | Endpoint map — most needed by AI                 |
| File Index (exact paths + LOC)  | AI knows what to read and where                  |
| Known Issues                    | Existing problems to be aware of                 |
| Cross-References                | DB tables, UC files, related modules             |
| Review (if reviewed)            | Score + link to review file                      |

---

## Overwrite Policy

> [!IMPORTANT]
> All updated files **MUST be overwritten in-place**. Do NOT create new versions, copies, or backups.

| File                   | Action                             |
| ---------------------- | ---------------------------------- |
| `Project_Structure.md` | Overwrite directly                 |
| `summaries/*.md`       | Overwrite directly                 |
| `MASTER_INDEX.md`      | Update in-place if modules changed |

---

## Output: Changelog

After completion, the AI MUST produce a summary of changes:

```
## CHECK Report — {PROJECT_NAME} ({DATE})

### Project_Structure.md
- Added: [new files/folders]
- Removed: [deleted files/folders]
- Updated: [modules with changes]
- Trello → JIRA: [number of refs migrated]

### Summaries
- Updated: [list of updated files]
- Format: [files converted to new template]
- Trello → JIRA: [number of refs migrated]
```

Display this changelog directly to the user (do NOT save to file).

---

## Reference Documents

| Name             | Path                                           | When to read         |
| ---------------- | ---------------------------------------------- | -------------------- |
| MASTER INDEX     | `PM_REVIEW/MASTER_INDEX.md`                    | ALWAYS               |
| JIRA Index       | `PM_REVIEW/Resources/TASK/JIRA/README.md`      | ALWAYS               |
| Summary Template | `references/summary-template.md`               | Phase 2              |
| Update Checklist | `references/update-checklist.md`               | Both phases          |
| Admin Structure  | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md`  | When checking ADMIN  |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md` | When checking MOBILE |

---

## Completion Criteria

The CHECK scan is considered **DONE** when ALL of the following are true:

- [ ] `Project_Structure.md` tree matches actual folder structure 100%
- [ ] All `summaries/*.md` files use the new template from `references/summary-template.md`
- [ ] All Trello references replaced with JIRA Epic Names
- [ ] All file paths in summaries point to files that actually exist
- [ ] LOC counts are updated for implemented files
- [ ] MASTER_INDEX.md is updated if modules were added/removed
- [ ] Changelog summary displayed to user

## Edge Cases

| Scenario                                          | Action                                                    |
| ------------------------------------------------- | --------------------------------------------------------- |
| Summary file exists but module has no source code | Rewrite summary noting "⬜ Not built", keep JIRA/UC refs   |
| Source code exists but no summary file            | Create new summary using `references/summary-template.md` |
| Module folder was deleted since last check        | Remove from `Project_Structure.md`, update MASTER_INDEX   |
| `Project_Structure.md` does not exist             | Report error — user must create it first or run TongQuan  |
| JIRA Index has no matching Epic for a module      | Mark as "JIRA: TBD" and flag in changelog                 |

---

## Rules

- **NEVER update both projects simultaneously** — must choose one
- **DO NOT read full SRS** — only read UC files when needed
- **DO NOT read full JIRA CSV** — use JIRA Index
- **Summaries MUST follow the new template** — compact, remove token waste
- **Preserve Project_Structure.md format** — only update content
- **OVERWRITE old files directly** — no versioning, no backups
- After updating summaries → update `MASTER_INDEX.md` if needed (new/removed modules)
