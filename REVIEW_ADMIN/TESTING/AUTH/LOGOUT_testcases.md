# Test Cases: AUTH — LOGOUT

| Property     | Value      |
| ------------ | ---------- |
| **Module**   | AUTH       |
| **Function** | LOGOUT     |
| **UC Refs**  | UC009      |
| **Platform** | ADMIN      |
| **Sprint**   | S1         |
| **Version**  | v1.0       |
| **Created**  | 2026-03-08 |
| **Author**   | AI_AGENT   |
| **Status**   | READY      |

## Test Data

> **Instruction**: Fill in the `Value` column before running tests. AI will use these during EXECUTE mode.
> Items marked ⬜ PENDING are required. Items marked ✅ are filled.

### Environment

| #   | Material       | Purpose         | Value                   | Status |
| --- | -------------- | --------------- | ----------------------- | ------ |
| 1   | Admin Base URL | All admin tests | `http://localhost:5000` | ✅      |

### Tokens & Keys

| #   | Material          | Purpose             | Value            | Status |
| --- | ----------------- | ------------------- | ---------------- | ------ |
| 1   | Valid auth cookie | Auth endpoint tests | ⬜ AUTO-GENERATED | ⬜      |

## Happy Path (Main Flow)

| ID                | UC    | Platform | Severity | Title                                | Preconditions                                          | Steps                                                                        | Expected                                                                                            | Actual                                                                | Status | Tester   | DateTime         |
| ----------------- | ----- | -------- | -------- | ------------------------------------ | ------------------------------------------------------ | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------ | -------- | ---------------- |
| TC-UC09-ADMIN-001 | UC009 | ADMIN    | CRITICAL | Valid logout API call                | 1. User is authenticated (has valid `hg_token` cookie) | 1. POST `/api/v1/auth/logout` with valid cookie                              | 1. HTTP 200; 2. `Set-Cookie` header clears the `hg_token` cookie; 3. "Đăng xuất thành công" message | HTTP 200. Cookie cleared successfully                                 | PASS   | AI_AGENT | 2026-03-08 14:32 |
| TC-UC09-ADMIN-002 | UC009 | ADMIN    | CRITICAL | UI - Valid logout redirects to login | 1. User is logged in                                   | 1. Navigate to admin dashboard; 2. Click Settings > Logout; 3. Confirm popup | 1. Local session cleared; 2. Requested server logout; 3. Redirected to /login                       | Clicked logout icon, successfully logged out and redirected to login. | PASS   | AI_AGENT | 2026-03-08 15:35 |

## Alternative Flows

| ID                | UC    | Platform | Severity | Title                                    | Preconditions                    | Steps                                                  | Expected                                                           | Actual                                                     | Status | Tester   | DateTime         |
| ----------------- | ----- | -------- | -------- | ---------------------------------------- | -------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------------------------- | ------ | -------- | ---------------- |
| TC-UC09-ADMIN-020 | UC009 | ADMIN    | HIGH     | Cannot access secured routes post-logout | 1. User has just logged out      | 1. Attempt GET `/api/v1/auth/me` without cookie        | 1. HTTP 401 Unauthorized; 2. Access denied                         | HTTP 401. Unauthorized access blocked                      | PASS   | AI_AGENT | 2026-03-08 14:32 |
| TC-UC09-ADMIN-021 | UC009 | ADMIN    | MEDIUM   | Logout without being logged in           | 1. No valid token cookie present | 1. POST `/api/v1/auth/logout` without cookie           | 1. HTTP 200 or 401; 2. System handles gracefully without crashing  | HTTP 200. Gracefully handled                               | PASS   | AI_AGENT | 2026-03-08 14:32 |
| TC-UC09-ADMIN-022 | UC009 | ADMIN    | MEDIUM   | UI - Cancel logout                       | 1. User is logged in             | 1. Click Settings > Logout; 2. Click "Cancel" on popup | 1. Popup closes; 2. User remains on dashboard, session kept active | No popup appears. Immediate logout on clicking the button. | FAIL   | AI_AGENT | 2026-03-08 15:35 |

---

## Execution Log

### Session: 2026-03-08 15:35

| Metric        | Value    |
| ------------- | -------- |
| **Executed**  | 5        |
| **PASS**      | 4        |
| **FAIL**      | 1        |
| **BLOCKED**   | 0        |
| **SKIP**      | 0        |
| **NOT_RUN**   | 0        |
| **Pass Rate** | 80%      |
| **Tester**    | AI_AGENT |
| **Duration**  | ~3m      |

#### Failed Tests
- `TC-UC09-ADMIN-022`: No confirmation dialog appears when logging out from the UI. User is immediately logged out.

#### Notes
- L2 UI Tests (002, 022) were executed via automated browser subagent.
