---
inclusion: manual
---

# Workflow: Stuck (Anti-Loop Force Re-Evaluation)

> **Invoke:** `#64-workflow-stuck` hoặc "stuck", "vòng lặp", "tried that", "still broken" lần 3+.

Khi em detect 3+ failed attempts hoặc anh invoke — em STOP và follow quy trình.

## Iron rule

**This workflow does NOT propose a fix. It re-evaluates whether the fix-target is correct.**

## Phase 1 — Stop

- DO NOT propose attempt #4.
- DO NOT suggest "let me try one more thing".

## Phase 2 — Read entire bug log

Build summary table:

| # | Hypothesis | Approach | Why failed |
|---|---|---|---|

Look for patterns:
- Same hypothesis, different approaches → hypothesis is wrong
- Different hypotheses, same outcome → root cause is upstream
- Each fix breaks something else → architecture incompatible

## Phase 3 — Re-frame questions

1. Is this the right bug to fix? (symptom vs upstream root cause?)
2. Is the bug well-defined? (deterministic repro?)
3. Is the architecture wrong for this requirement?
4. Is the spec wrong? (UC outdated?)
5. Are constraints making it unsolvable in current shape?

## Phase 4 — Choose path

| Path | When |
|---|---|
| A: Re-frame bug | Visible bug is symptom of upstream |
| B: Refactor first | Architecture incompatible |
| C: Update spec | Spec wrong/outdated |
| D: New approach | Genuinely different hypothesis (document WHY different) |
| E: Defer | Cost > value right now |

## Phase 5 — Discuss with anh

Report BEFORE attempt #4:
- All prior attempts + why failed
- Pattern identified
- Recommended path + reasoning
- Ask anh to choose

Wait for decision. Don't ghost forward.

## Phase 6 — Update

- Bug log: add "Stuck Analysis" section
- INDEX.md: update status
- ADR: write if path is architectural (B, C, or A)
