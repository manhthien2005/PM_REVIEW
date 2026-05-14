---
inclusion: manual
---

# Skill: Verification Before Completion

## Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run a verification command in this message, you cannot claim it passes.

## Gate function

1. IDENTIFY: which command proves this claim?
2. RUN: run the full command (fresh)
3. READ: read full output, check exit code
4. VERIFY: does output confirm the claim?
5. ONLY THEN: speak the claim

## Mapping claim → evidence

| Claim | Required |
|---|---|
| "Tests pass" | Test command output: 0 failures |
| "Lint clean" | Lint output: 0 errors |
| "Build OK" | Build command exit 0 |
| "Bug fixed" | Red-green-red cycle verified |
| "Spec met" | Line-by-line checklist vs spec |

## Red flags — STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification
- About to commit/push before verifying
- Partial verification

## VSmartwatch verification commands

| Claim | Command |
|---|---|
| Flutter feature done | `flutter test test/<feature>/` + `flutter analyze` |
| FastAPI endpoint done | `pytest tests/test_<feature>.py` + manual curl |
| Express endpoint done | `npm test -- <file>` + `npm run lint` |
| React feature done | `npm test -- <component>` + manual click-through |
| Bug fixed | Regression test: red → fix → green → revert → red → restore → green |
