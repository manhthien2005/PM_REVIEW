---
inclusion: manual
---

# Skill: Systematic Debugging

## Core principle

**Always find root cause before attempting fix. Symptom fixes are failure.**

## 4 Phases

### Phase 1 — Root cause investigation

1. Read error message carefully. Full stack trace.
2. Reproduce reliably. If flaky → gather data, don't guess.
3. Check recent changes: `git log -n 10 --oneline`
4. Trace data flow backwards from symptom to source.
5. Multi-component: log at each boundary, run once to find WHERE.

### Phase 2 — Pattern analysis

1. Find similar working code. Compare.
2. List every difference (no matter how small).
3. Understand dependencies (config, env, version).

### Phase 3 — Hypothesis & test

1. Form ONE specific hypothesis.
2. Test with minimal change — one variable, not five.
3. Wrong → NEW hypothesis. Don't stack fixes.

### Phase 4 — Implementation

1. Write failing reproduction test.
2. Fix root cause only.
3. Verify: test passes + other tests pass + bug actually gone.
4. < 3 attempts: back to Phase 1. **≥ 3: STOP → Stuck workflow.**

## Red flags — STOP and go back to Phase 1

- "Quick fix now, investigate later"
- "Let me try changing X and see"
- "I don't fully understand it, but this might work"
- Proposing fix without tracing data flow
- 3+ fix attempts and bug still there

## VSmartwatch entry points

- Flutter widget doesn't rebuild → trace build → provider → notifier → repo
- FastAPI 422 → Pydantic schema first, then router signature
- Prisma empty result → where clause type coercion, soft-delete filter
- FCM not received → token → topic → payload → fg/bg state
- Cross-repo broken → add request_id, trace through each repo's logs
