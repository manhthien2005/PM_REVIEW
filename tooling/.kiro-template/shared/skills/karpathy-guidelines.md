---
inclusion: manual
---

# Skill: Karpathy Guidelines (Surgical Changes)

## 1. Think Before Coding

- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations → present them, don't pick silently.
- Simpler approach exists → say so. Push back when warranted.

## 2. Simplicity First

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" that wasn't requested.
- 200 lines could be 50 → rewrite.

## 3. Surgical Changes

- Don't "improve" adjacent code, comments, formatting.
- Don't refactor things that aren't broken.
- Match existing style.
- Every changed line traces to user's request.
- YOUR changes made something unused → remove it. Pre-existing dead code → mention, don't delete.

## 4. Goal-Driven Execution

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, make them pass"
- "Fix bug" → "Write reproduction test, make it pass"
- "Refactor X" → "Tests pass before and after"

Multi-step: state brief plan with verify step per task.
