---
inclusion: manual
---

# Workflow: Debug (Systematic Root-Cause)

> **Invoke:** `#62-workflow-debug` hoặc "debug", "bug", "lỗi", "broken", "fail", "error".

Khi anh invoke workflow này — em follow quy trình root-cause systematic.

## Iron rule

**NO FIX WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

## Pre-flight

1. **Anti-loop check** — đọc `PM_REVIEW/BUGS/<BUG-ID>.md` nếu có. DO NOT propose approach đã `failed`.
2. Nếu chỉ còn failed approaches → chuyển sang Stuck workflow.
3. Branch: `fix/<short-desc>` từ correct trunk.

## 4 Phases

### Phase 1 — Root cause investigation (BEFORE changing ANY line)

1. Read error message carefully. Full stack trace.
2. Reproduce reliably.
3. Check recent changes: `git log -n 10 --oneline`
4. Trace data flow backwards from symptom to source.
5. Multi-component: add log at each boundary, run once to find WHERE it fails.

### Phase 2 — Pattern analysis

1. Find similar working code. Compare.
2. List every difference between working and broken.
3. Understand dependencies (config, env, version).

### Phase 3 — Hypothesis & test

1. Form ONE specific hypothesis: "Root cause is X because Y."
2. Test with minimal change — change one variable, not five.
3. Wrong → new hypothesis. Don't stack fixes.

### Phase 4 — Implementation

1. Write failing test that reproduces bug.
2. Implement fix — only root cause.
3. Verify: reproduction test passes + other tests still pass.
4. If fix doesn't work:
   - < 3 attempts: back to Phase 1
   - **≥ 3 attempts: STOP → Stuck workflow**

## VSmartwatch-specific entry points

| Symptom | First check |
|---|---|
| Flutter widget doesn't rebuild | Provider `watch` vs `read`? |
| `setState() after dispose` | `mounted` guard after `await` |
| API 401 loop | dio refresh interceptor + token `iss` mismatch |
| FCM not received | Token registration → payload → fg/bg handler |
| FastAPI 500 leaks trace | Exception handler in `app/main.py` |
| Prisma P2002/P2025 | errorHandler middleware mapping |
| Cross-repo contract mismatch | topology + producer schema vs consumer call |

## Commit

```
fix(<scope>): <mô tả tiếng Việt>

Root cause: <gốc vấn đề>
Fix: <approach>
Test: regression test trong <test file>
```

Update bug log: mark attempt `successful` + link fix commit.
