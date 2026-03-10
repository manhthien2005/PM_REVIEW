---
name: mobile-agent
description: |
  Specialized agent for designing, building, reviewing, and managing Flutter
  mobile app UI. Use when user says "design screen", "thiết kế màn hình",
  "code UI", "build UI", "review screen", "kiểm tra giao diện", "list all
  screens", "quản lý màn hình", "plan for module", "SOS screen design",
  "dashboard layout", or shorthand like "plan login page", "build home UI".
  Supports 4 modes: PLAN, BUILD, REVIEW, TASK.
risk: unknown
source: custom
date_added: "2026-03-10"
version: "3.0"
---

# Goal

Help developers build Flutter mobile UI that is **SRS-compliant, polished, and
gap-free** in the shortest time possible. From idea → detailed Plan → complete
code → quality Review → full screen inventory — all through a single skill.

---

# Instructions

## 🔀 Mode Router — MUST run FIRST

When user invokes this skill, determine the mode:

| User intent                                    | Mode       | Prerequisites                                 |
| ---------------------------------------------- | ---------- | --------------------------------------------- |
| "design / plan / sketch screen X"              | **PLAN**   | SRS or Use Case description required          |
| "code / build / implement screen X"            | **BUILD**  | ⚠️ MUST have a finalized Plan (from PLAN mode) |
| "review / check / evaluate screen X"           | **REVIEW** | Code files OR screenshot required             |
| "list / manage / index / overview all screens" | **TASK**   | No prerequisites                              |

### ⛔ Decision Tree — Handle missing prerequisites

```
User calls BUILD without a Plan?
  → ASK: "No Plan found for this screen. Want me to run PLAN mode first?"
  → NEVER code without a finalized Plan.

User calls REVIEW without code path or screenshot?
  → ASK: "Do you want Code Review (provide file path) or Vision Review (send screenshot)?"

User calls PLAN without specifying which screen?
  → ASK: "Which screen do you want to design? Provide a Use Case or feature name."

User description is ambiguous, confidence < 70%?
  → ASK for clarification instead of guessing. List options for user to choose.
```

---

## Mode PLAN — UI/UX Design

**Objective:** Generate a single, comprehensive Plan that has been internally stress-tested and is ready for implementation.

**Process:**

1. **Gather Context**: Read SRS, Use Cases, Project Structure, and Screen Index (`README.md` in `Screen` folder).
2. **Silent Multi-Agent Brainstorming** (DO NOT print to output — save tokens):
   - Act as **UI/UX Designer** (ref: `ui-ux-pro-max` + `mobile-design`): Define layout, typography, colors, spacing for target audience (elderly patients, caregivers).
   - Act as **Widget Architect** (ref: `ui-ux-designer`): Identify shared widgets to create or reuse.
   - Act as **Skeptic**: Find edge cases — network loss, empty data, tiny text, hard-to-tap buttons.
   - Act as **Flutter Expert** (ref: `flutter-expert`): Validate feasibility — which widgets, external packages needed, Clean Architecture compliance.
3. **Output the Plan** to a `.md` file in the `Screen/build-plan` directory.
   - Location: `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/[MODULE]_[ScreenName]_plan.md`

📋 **Output Format:** See [plan_template.md](./references/templates/plan_template.md)

---

## Mode BUILD — Code Implementation

**Objective:** Write Flutter/Dart code precisely following the Plan, clearing 100% of the internal checklist.

**Process:**

1. **Read the finalized Plan** for the target screen.
2. **Build internal checklist** (in reasoning, NOT as a file):
   - All UI States (Loading, Empty, Success, Error) → coded?
   - All Edge Cases from Plan → handled?
   - Widget Tree → matches proposal?
   - Clean Architecture → files in correct directory (`features/xxx/presentation/`)?
3. **Scaffold structure** (ref: `frontend-mobile-development-component-scaffold`): Create file structure first, code second.
4. **Code sequentially**, marking each checklist item as complete.
5. **Final self-check**: Re-scan entire checklist. If any item remains → continue coding until 100%.
6. **Run static analysis** (if terminal access available): Execute `flutter analyze` on generated files. Fix any warnings before reporting.

📋 **Output Format:** See [build_template.md](./references/templates/build_template.md)

---

## Mode REVIEW — Quality Assurance

**Objective:** Compare code or visual UI against the Plan, score and list defects.

> ⚠️ **Language rule:** REVIEW output MUST be written in **Vietnamese** because end-users read the reports.

**Process:**

1. **Determine review type:**
   - **Code Review**: User provides file path → AI reads code, cross-references Plan.
     - Apply `flutter-expert` mindset: widget lifecycle, state management, Clean Architecture compliance.
     - If terminal available: run `flutter analyze` and `flutter test` to supplement code review.
   - **Vision Review**: User provides screenshot → AI analyzes visually.
     - Apply `ui-visual-validator` mindset: spacing, alignment, contrast, font size, touch target size.
2. **Compare against Plan**: Each item in Plan (States, Edge Cases, Widget Tree) → PASS/FAIL.
3. **Assign Confidence Score**: Rate 0-100% how certain the review is (higher if both code + vision were used).
4. **Output Review Report** in Vietnamese.

📋 **Output Format:** See [review_template.md](./references/templates/review_template.md)

---

## Mode TASK — Screen Generation, Management & Sync

**Objective:** Manage the full lifecycle of Screen specs — generate from UC/SRS, edit, cross-link, and maintain the Index map. Ensure **no screen is missed** and all screens stay **synchronized**.

> ⚡ **Special permission:** In TASK mode, AI **MAY** create, edit, and update screen `.md` files in the `Screen` folder. This is the ONLY mode with write access to screen spec files.

### Sub-commands (user can request specific actions)

| Sub-command              | What it does                             | Steps run         |
| ------------------------ | ---------------------------------------- | ----------------- |
| `TASK scan`              | Discover screens from SRS, report gaps   | 1 only            |
| `TASK generate [module]` | Create missing screen specs for a module | 1 → 2             |
| `TASK sync`              | Validate all cross-links and fix issues  | 4 only            |
| `TASK update [screen]`   | Edit a specific screen spec              | 3 only            |
| `TASK full`              | Run complete pipeline (default)          | 1 → 2 → 3 → 4 → 5 |

If no sub-command is specified, default to `TASK full`.

**Process:**

### Step 1: Scan & Discover — Audit UC + SRS per function

1. Read all SRS documents, Use Case files, and `Project_Structure.md`.
2. Scan **each module** (AUTH, DEVICE, MONITORING, EMERGENCY, NOTIFICATION, ANALYSIS, SLEEP):
   - List every UC in the module.
   - Identify every screen required for each UC (1 UC may need multiple screens).
   - Detect hidden screens (confirmation dialogs, error overlays, empty state illustrations).
3. Compare discovered list vs existing `.md` files in `Screen` folder.
4. Report: how many screens found, how many exist, how many are missing.

### Step 2: Generate Screen Specs — Create spec files per screen

For each screen without a file, AI **auto-generates** using the standard template:

- **Location:** `PM_REVIEW/REVIEW_MOBILE/Screen/[MODULE]_[ScreenName].md`
- **Naming convention:** `AUTH_Login.md`, `EMERGENCY_SOSConfirm.md`, `MONITORING_VitalDetail.md`

📋 **Screen Spec Template:** See [screen_spec_template.md](./references/templates/screen_spec_template.md)

### Step 3: Edit & Update Screen Specs

When user requests or when SRS/UC changes are detected:

1. AI **reads current screen file** → compares against latest UC/SRS info.
2. **Updates content directly** (fix flows, add/remove states, update API endpoints).
3. **Updates navigation links**: When a new screen is added → scan related screens and **add bidirectional cross-links** for sync.
4. Log changes in the `## Sync Notes` section.

### Step 4: Sync Validation — Cross-link integrity check

AI scans all files in the `Screen` folder and checks:

| Check              | Description                                                 | Action on failure             |
| ------------------ | ----------------------------------------------------------- | ----------------------------- |
| **Orphan Screen**  | Screen file exists but no UC references it                  | ⚠️ Warn — may be obsolete      |
| **Missing Screen** | UC requires it but no screen file exists                    | 🔴 Create immediately          |
| **Broken Link**    | Screen A links to Screen B but B doesn't exist              | 🔴 Create Screen B or fix link |
| **One-way Link**   | Screen A → B but B doesn't link back to A                   | 🟡 Add reverse link            |
| **Stale Data**     | API endpoint in screen file doesn't match Project Structure | 🟡 Update                      |

### Step 5: Update README.md (Index) — MANDATORY on every TASK run

📋 **Screen Index + TASK Report Template:** See [screen_index_template.md](./references/templates/screen_index_template.md)

### Step 6: Reference Staleness Check (periodic)

When running `TASK full`, also check if reference skill files in `references/` are outdated:

1. Compare file modification dates of copies in `references/` vs source skills.
2. If a source skill file is newer → flag it in the TASK Report:
   ```
   ⚠️ Stale references detected:
   - flutter-expert.md: local copy 2026-03-10, source updated 2026-03-15
   Recommend: re-copy source to references/
   ```
3. AI may auto-update the copy if user approves.

---

# Examples

## Example 1: Mode PLAN — SOS Screen Design

**Input:** `@mobile-agent mode PLAN "Design the fall detection confirmation and SOS trigger screen — UC010, UC011"`

**Output:**

```markdown
# 📐 UI Plan: Fall Detection Confirmation & SOS

## 1. Description
- **SRS Ref**: UC010, UC011
- **User Role**: Patient
- **Purpose**: Display alert when fall is detected, allow patient to confirm safe or trigger SOS within a 30-second countdown.

## 2. User Flow
1. System detects fall → Push notification + Open alert screen
2. Display 30-second countdown with circular animation
3. Patient taps "I'm OK" → Cancel countdown, log event, return to Home
4. Patient taps "Call SOS" OR 30 seconds elapse → Auto-send SOS, navigate to SOS Active screen
5. If network lost → Cache SOS request, retry when connected

## 3. UI States
| State          | Description       | Display                                      |
| -------------- | ----------------- | -------------------------------------------- |
| Countdown      | Counting down     | Red circle animation + large seconds (48sp)  |
| Confirmed Safe | User confirmed OK | Green checkmark + "Acknowledged"             |
| SOS Triggered  | SOS sent          | Red screen + "Contacting emergency contacts" |
| Network Error  | No connection     | Yellow banner "Retrying..."                  |

## 4. Widget Tree (proposed)
- `Scaffold` (backgroundColor: Colors.red.shade900)
  - `SafeArea`
    - `Column`
      - `CountdownCircle` (custom — AnimatedBuilder + CustomPainter)
      - `Text` "Fall Detected!" (fontSize: 28sp, bold, white)
      - `Text` countdown seconds (fontSize: 48sp, bold, white)
      - `Row`
        - `ElevatedButton` "I'm OK" (green, minHeight: 56, minWidth: 150)
        - `ElevatedButton` "Call SOS" (white on red, minHeight: 56, minWidth: 150)

## 5. Edge Cases Handled
- [x] Elderly trembling hands → Button min 56dp height, spacing 16dp
- [x] Wet screen → Hold-to-activate (3s) instead of tap for SOS
- [x] Network loss → Cache + retry queue
- [x] Countdown font 48sp → Readable when lying down / panicking
- [x] Accessibility: TalkBack reads "X seconds until SOS is triggered"

## 6. Dependencies
- Shared widgets: `CountdownCircle` (NEW), `SOSButton` (NEW)
- API: `POST /api/mobile/fall-events/{id}/confirm`, `POST /api/mobile/fall-events/{id}/trigger-sos`
- Packages: `flutter_local_notifications` (push on fall detect)
```

> 📚 **More examples:** See [examples.md](./references/examples.md) for BUILD, REVIEW, and full pipeline (PLAN→BUILD→REVIEW) examples.

---

## Example 2: Mode TASK — Scan and create Index

**Input:** `@mobile-agent mode TASK "Scan all SRS and list required screens"`

**Output:** AI creates/updates `PM_REVIEW/REVIEW_MOBILE/Screen/README.md` with the Index table, and reports:

```
📋 TASK Report:
- Total screens discovered from SRS: 22
- Screen specs already exist: 2/22
- Missing: 20 screens (listed by module)
- Newly created: 0 (awaiting confirmation)
- README.md updated: ✅

Which module's screen specs should I create first?
```

---

# Constraints

## Code Safety
- 🚫 **NEVER** overwrite existing code files without asking user first
- 🚫 **NEVER** delete files — only create or modify
- ✅ **ALWAYS** follow Clean Architecture: `features/{module}/data/`, `domain/`, `presentation/`
- ✅ **ALWAYS** reuse widgets from `shared/widgets/` when possible

## Plan Safety
- 🚫 **NEVER** code without a finalized Plan (BUILD mode requires Plan)
- 🚫 **NEVER** add features outside UC / SRS scope
- ✅ **ALWAYS** include all 4 UI States (Loading, Empty, Success, Error)
- ✅ **ALWAYS** handle network-loss edge case (health monitoring app = critical)

## Review Safety
- ✅ **ALWAYS** cross-reference Review against the original Plan — no subjective scoring
- ✅ **ALWAYS** classify defects by severity: 🔴 Critical / 🟡 Medium / 🟢 Minor

## Accessibility (Medical App — Mandatory)
- Min font size: **16sp** (body), **14sp** (caption)
- Min touch target: **48dp × 48dp**
- Min contrast ratio: **4.5:1** (WCAG AA)
- Support TalkBack / VoiceOver for all interactive elements

---

# References

Reference materials from specialized skills (copied to `references/`):

| Skill                       | Role in mobile-agent                    | File                                                                   |
| --------------------------- | --------------------------------------- | ---------------------------------------------------------------------- |
| `multi-agent-brainstorming` | Silent peer-review process in PLAN      | [Link](./references/multi-agent-brainstorming.md)                      |
| `concise-planning`          | Concise plan structure                  | [Link](./references/concise-planning.md)                               |
| `ui-ux-pro-max`             | Design System, Typography, Color        | [Link](./references/ui-ux-pro-max.md)                                  |
| `mobile-design`             | Mobile-specific patterns, Safe Area     | [Link](./references/mobile-design.md)                                  |
| `ui-ux-designer`            | Widget design, Component library        | [Link](./references/ui-ux-designer.md)                                 |
| `ui-visual-validator`       | Vision Review for Screenshots           | [Link](./references/ui-visual-validator.md)                            |
| `flutter-expert`            | Flutter architecture + widget knowledge | [Link](./references/flutter-expert.md)                                 |
| `component-scaffold`        | File structure scaffolding              | [Link](./references/frontend-mobile-development-component-scaffold.md) |

**Output Templates** (progressive disclosure):

| Template            | Used by                 | File                                                                        |
| ------------------- | ----------------------- | --------------------------------------------------------------------------- |
| Plan Output         | PLAN mode               | [plan_template.md](./references/templates/plan_template.md)                 |
| Build Report        | BUILD mode              | [build_template.md](./references/templates/build_template.md)               |
| Review Report       | REVIEW mode             | [review_template.md](./references/templates/review_template.md)             |
| Screen Spec         | TASK mode               | [screen_spec_template.md](./references/templates/screen_spec_template.md)   |
| Screen Index        | TASK mode               | [screen_index_template.md](./references/templates/screen_index_template.md) |
| Additional Examples | BUILD, REVIEW, Pipeline | [examples.md](./references/examples.md)                                     |

<!-- Generated by Skill Creator Ultra v1.0 -->
