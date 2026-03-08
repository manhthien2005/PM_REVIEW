# Test Plan: AUTH — ADMIN

| Property       | Value           |
| -------------- | --------------- |
| **Module**     | AUTH            |
| **Platform**   | ADMIN           |
| **Scope**      | LOGIN, LOGOUT   |
| **Test Files** | 2 files, 15 TCs |
| **Created**    | 2026-03-08      |
| **Author**     | AI_AGENT        |

## Environment Setup

### Prerequisites
- [ ] Backend running at `{BE_URL}` (default: http://localhost:5000)
- [ ] Frontend running at `{FE_URL}` (default: http://localhost:5173/admin)
- [ ] Database accessible and seeded with at least one admin account
- [x] All `⬜ PENDING` materials filled in test case files

### Start Commands
| Service  | Command                      | Expected                 |
| -------- | ---------------------------- | ------------------------ |
| Backend  | `cd backend && npm run dev`  | "Server on 5000"         |
| Frontend | `cd frontend && npm run dev` | "Vite server running..." |

## Execution Order

> Execute in this order. Dependencies flow top-down.

| #   | Test File                | Layer | Tool           | Depends On | Est. Time |
| --- | ------------------------ | ----- | -------------- | ---------- | --------- |
| 1   | AUTH/LOGIN_testcases.md  | L1+L2 | curl + browser | —          | ~3m       |
| 2   | AUTH/LOGOUT_testcases.md | L1+L2 | curl + browser | #1         | ~2m       |

## Test Layers

| Layer | Name        | Tool                 | What It Tests                                 |
| ----- | ----------- | -------------------- | --------------------------------------------- |
| L1    | API Tests   | `run_command` + curl | HTTP status, response JSON, set-cookie        |
| L2    | UI Smoke    | `browser_subagent`   | Form submit, redirect, auth state persistence |
| L3    | Manual Flag | Human tester         | Edge cases requiring visual inspection        |

## Execution Instructions

### L1: API Tests (via curl)
Use curl commands to verify `POST /api/v1/auth/login` and `POST /api/v1/auth/logout`. Remember to capture cookies using `-c ./cookie.txt` and passing them via `-b ./cookie.txt` for logout and secured routes.

### L2: UI Smoke Tests (via browser)
Use browser_subagent to navigate to the admin `/login` page, fill the form, click Login, and observe redirect. Then click logout and confirm.

### L3: Manual Required
Test cases marked `MANUAL_REQUIRED` in Status column or deemed too complex for automated agents — skip during AI execution. Log as `SKIP` with note: "Requires manual testing".

## Post-Execution

1. Update each test case file with results (per execution-tracker.md)
2. Generate summary below:

### Execution Summary
| Metric          | Value                        |
| --------------- | ---------------------------- |
| **Total TCs**   | 15                           |
| **L1 (API)**    | 12 executed, 12 pass, 0 fail |
| **L2 (UI)**     | 3 executed, 3 pass, 0 fail   |
| **L3 (Manual)** | 0 skipped                    |
| **Pass Rate**   | 100% (Overall)               |
| **Duration**    | ~20m                         |

### Issues Found
- *No critical issues found.*

### Recommendations
- *No further action required.*
