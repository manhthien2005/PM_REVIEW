# Bug <BUG-ID>: <Short title in Vietnamese>

**Status:** 🔴 Open
**Repo(s):** <repo-name>
**Module:** <module>
**Severity:** Critical / High / Medium / Low
**Reporter:** ThienPDM (self) hoặc <name>
**Created:** YYYY-MM-DD
**Resolved:** _(điền khi resolve)_

## Symptom

Mô tả cụ thể, người ngoài đọc cũng hiểu — KHÔNG vague.

❌ Bad: "App crashes sometimes"
✅ Good: "App crashes ngay khi user nhấn 'Tôi vẫn ổn' lần thứ 2 trong cùng session — chỉ trên Android 14, không trên Android 13"

## Repro steps

1. ...
2. ...
3. ...

**Expected:** ...
**Actual:** ...

**Repro rate:** 100% / X out of 10 attempts / intermittent (note conditions)

## Environment

- App version / commit: <e.g., 1.0.3+45 / health_system@a1b2c3d>
- Platform: Android 14 (Pixel 7) / iOS 17.2 (iPhone 14) / Chrome 120 (Win 11)
- Backend version: <e.g., HealthGuard backend@v1.2.0>
- DB state (if relevant): <table count, recent migration>

## Logs / Stack trace

```
<paste relevant log lines>
<REDACT email, phone, raw vital values — medical app PHI>
```

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | <e.g., "Refresh interceptor doesn't await before retry"> | 🔄 Testing |
| H2 | <e.g., "Token storage cache not invalidated on logout"> | ⏸️ Not yet tested |

### Attempts

#### Attempt 1 — YYYY-MM-DD HH:MM

**Hypothesis:** H1
**Approach:** <what you changed — concrete>
**Files touched:**
- `<path>:<line range>` — <change>
- `<path>` — <change>

**Verification:**
- Test command: `<command>`
- Test result: <e.g., "5/6 pass; new test failing">
- Manual repro: <result>

**Result:** ❌ failed / ⚠️ partial / ✅ successful

**Reason (if not successful):**
<Why this didn't fix it. Be specific — useful for future-you and future AI.>

**Next step (if failed):**
<What to investigate next based on what we learned.>

---

#### Attempt 2 — YYYY-MM-DD HH:MM

(repeat structure)

---

## Resolution

_(Fill in when resolved)_

**Fix commit:** <repo>@<sha>
**PR:** <link>
**Approach:** <what worked>
**Test added:** <test file path :: test name>
**Verification:** <how to confirm fix works in production>
**Watch for regression:** <signal that bug came back>

## Related

- UC: UC<XXX> (PM_REVIEW/Resources/UC/<Module>/UC<XXX>.md)
- JIRA: <Story-ID> (nếu có)
- Linked bug: <BUG-ID> (nếu liên quan bug khác)
- ADR: ADR-<NNN> (nếu architectural decision involved)
- Spec: <repo>/docs/specs/<file>.md

## Notes

_(Free-form notes, hypotheses chưa test, ý tưởng cần khám phá sau)_
