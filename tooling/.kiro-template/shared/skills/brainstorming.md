# Skill: Brainstorming Ideas Into Designs

Use BEFORE writing spec or code for new features. Explores user intent, constraints, and 2-3 design approaches through one-question-at-a-time dialogue.

## Hard Gate

DO NOT write code, scaffold, or take implementation action until design is presented and approved.

## Checklist

1. Explore project context (read existing files, recent commits)
2. Ask clarifying questions — one at a time, prefer multiple-choice
3. Propose 2-3 approaches with tradeoffs + recommendation
4. Present design section by section, get approval per section
5. Write design doc: `docs/specs/YYYY-MM-DD-<topic>.md`
6. Spec self-review (placeholders? contradictions? ambiguity?)
7. User reviews final spec
8. Transition -> writing-plans skill

## Key Principles

- One question at a time
- Multiple choice preferred
- YAGNI ruthlessly
- Explore alternatives (always 2-3 approaches)
- Incremental validation
- Design for isolation (small units, explicit interfaces, < 300 lines)
- Follow existing patterns in codebase
