# Skill: CHECK — Sync PM_REVIEW Docs with Code Reality

Scan actual source code and update `Project_Structure.md` + `summaries/` to keep PM_REVIEW in sync.

## When to Use

- "check project", "cap nhat cau truc", "kiem tra source", "sync lai PM"

## Process

### Step 0: Project Detection
- ADMIN (`HealthGuard`) or MOBILE (`health_system`)
- If both exist -> ASK user to choose one. NEVER update both simultaneously.

### Step 1: Update Project_Structure.md
- Scan actual folder structure (list_dir)
- Compare with current Project_Structure.md
- Update tree, module statuses, replace Trello refs -> JIRA

### Step 2: Update Summaries
- For each summary file: scan source code, confirm API endpoints, update LOC
- Rewrite using template format
- Remove: Trello checklists, verbose SRS extraction, empty sections
- Keep: Module identity, Purpose, API Index, File Index, Known Issues, Cross-References

### Step 3: Output Changelog
Display summary (do NOT save): Added/Removed/Updated files, Trello->JIRA migrations

## Rules

- NEVER update both projects simultaneously
- Preserve Project_Structure.md format
- OVERWRITE old summaries directly
- All file paths in summaries must point to files that actually exist
