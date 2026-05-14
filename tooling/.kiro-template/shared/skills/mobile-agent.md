# Skill: Mobile Agent — Screen Spec Lifecycle

Manage screen spec lifecycle for VSmartwatch mobile app. Generate from UC/SRS, edit, cross-link, maintain Screen Index.

## Sub-commands

| Command | What |
|---|---|
| TASK scan | Discover screens from SRS, report gaps |
| TASK generate [module] | Create missing screen specs |
| TASK update [screen] | Edit specific screen spec |
| TASK sync | Validate cross-links, fix issues |
| TASK full | Complete pipeline |

## Process

### Step 1: Scan & Discover
- Read MASTER_INDEX, SRS_INDEX, UC list
- For each module: identify every screen required
- Compare vs existing files in `PM_REVIEW/REVIEW_MOBILE/Screen/`

### Step 2: Generate Screen Specs
- Path: `PM_REVIEW/REVIEW_MOBILE/Screen/[MODULE]_[ScreenName].md`
- Include: 4 UI States (Loading, Empty, Success, Error), network-loss edge case
- Accessibility: min 16sp font, 48dp touch target, 4.5:1 contrast

### Step 3: Edit & Update
- Compare against latest UC/SRS
- Update navigation links (bidirectional cross-links)

### Step 4: Sync Validation
- Orphan Screen (no UC references) -> warn
- Missing Screen (UC requires but no file) -> create
- Broken Link (A -> B but B missing) -> create B or fix
- One-way Link (A -> B but B !-> A) -> add reverse

### Step 5: Update Screen Index README

## Architecture Rule
Use unified `User` role + `Linked Profiles` (Profile Switcher). NEVER use deprecated `patient`/`caregiver` terminology.
