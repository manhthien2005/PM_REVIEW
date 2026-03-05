# Test Cases: AUTH — CHANGE_PASSWORD

| Property     | Value           |
| ------------ | --------------- |
| **Module**   | AUTH            |
| **Function** | CHANGE_PASSWORD |
| **UC Refs**  | UC004           |
| **Platform** | ADMIN           |
| **Sprint**   | S1              |
| **Version**  | v1.0            |
| **Created**  | 2026-03-05      |
| **Author**   | AI_AGENT        |
| **Status**   | READY           |

> **Note**: Requires authenticated user. Endpoint: `PUT /api/auth/password` with `authenticate` middleware + `changePasswordLimiter`.

---

## Test Data

> **Instruction**: Fill in the `Value` column before running tests.

### Accounts

| #   | Material               | Purpose                     | Value            | Status |
| --- | ---------------------- | --------------------------- | ---------------- | ------ |
| 1   | User email             | Login to get JWT            | ⬜ PENDING        | ⬜      |
| 2   | User current password  | Change password test        | ⬜ PENDING        | ⬜      |
| 3   | New valid password     | Change password test        | `NewSecure@2026` | ✅      |
| 4   | Wrong current password | Wrong current password test | `WrongOld@123`   | ✅      |

### Environment

| #   | Material       | Purpose       | Value     | Status |
| --- | -------------- | ------------- | --------- | ------ |
| 1   | Admin Base URL | All admin API | ⬜ PENDING | ⬜      |

### Tokens & Keys

| #   | Material          | Purpose                  | Value            | Status |
| --- | ----------------- | ------------------------ | ---------------- | ------ |
| 1   | Valid JWT token   | Auth for change password | ⬜ AUTO-GENERATED | ⬜      |
| 2   | Expired JWT token | Expired token test       | ⬜ PENDING        | ⬜      |

---

## Summary

| Total | NOT_RUN | PASS | FAIL | BLOCKED | SKIP |
| ----- | ------- | ---- | ---- | ------- | ---- |
| 19    | 19      | 0    | 0    | 0       | 0    |

---

## Happy Path (Main Flow)

| ID                | UC    | Platform | Severity | Title                                               | Preconditions                                              | Steps                                                                                                         | Expected                                                                                                                                                             | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | --------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC04-ADMIN-001 | UC004 | ADMIN    | CRITICAL | Change password with valid current and new password | 1. User logged in with valid JWT; 2. Know current password | 1. PUT `{BASE_URL}/api/auth/password` with `{currentPassword, newPassword}` and `Authorization: Bearer {JWT}` | 1. HTTP 200; 2. Success message; 3. New JWT token returned with updated tokenVersion; 4. Password updated in DB (bcrypt hash changed); 5. `tokenVersion` incremented | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-002 | UC004 | ADMIN    | CRITICAL | User can login with new password after change       | 1. Password changed via TC-UC04-ADMIN-001                  | 1. POST `{BASE_URL}/api/auth/sessions` with email and new password                                            | 1. HTTP 200; 2. JWT token issued; 3. Login successful                                                                                                                | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-003 | UC004 | ADMIN    | CRITICAL | Old password no longer works after change           | 1. Password changed via TC-UC04-ADMIN-001                  | 1. POST `{BASE_URL}/api/auth/sessions` with email and old password                                            | 1. HTTP 401; 2. Error: INVALID_CREDENTIALS; 3. Cannot login with old password                                                                                        | —      | NOT_RUN | —      | —        |

---

## Alternative Flows

| ID                | UC    | Platform | Severity | Title                                                           | Preconditions     | Steps                                                                    | Expected                                                                                          | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | --------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC04-ADMIN-020 | UC004 | ADMIN    | HIGH     | Change fails — wrong current password                           | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` with wrong currentPassword         | 1. HTTP 401; 2. Error: current password incorrect; 3. Password NOT changed                        | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-021 | UC004 | ADMIN    | HIGH     | Change fails — new password same as current                     | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` with newPassword = currentPassword | 1. HTTP 400; 2. Error: new password must be different from current                                | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-022 | UC004 | ADMIN    | HIGH     | Change fails — new password too weak (<8 chars)                 | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` with newPassword=`short`           | 1. HTTP 400; 2. Validation error: password too short                                              | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-023 | UC004 | ADMIN    | HIGH     | Change fails — no authentication (no JWT)                       | None              | 1. PUT `{BASE_URL}/api/auth/password` without Authorization header       | 1. HTTP 401; 2. Error: unauthorized                                                               | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-024 | UC004 | ADMIN    | HIGH     | Rate limit — change password blocked after 5 attempts in 15 min | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` 6 times within 15 minutes          | 1. First 5 return 200/400/401; 2. 6th attempt returns HTTP 429; 3. Error code `TOO_MANY_ATTEMPTS` | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-025 | UC004 | ADMIN    | MEDIUM   | Change fails — missing currentPassword field                    | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` without currentPassword            | 1. HTTP 400; 2. Validation error: currentPassword required                                        | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-026 | UC004 | ADMIN    | MEDIUM   | Change fails — missing newPassword field                        | 1. User logged in | 1. PUT `{BASE_URL}/api/auth/password` without newPassword                | 1. HTTP 400; 2. Validation error: newPassword required                                            | —      | NOT_RUN | —      | —        |

---

## Validation & Business Rules

| ID                | UC    | Platform | Severity | Title                                          | Preconditions                                                | Steps                                                             | Expected                                                                                                        | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC04-ADMIN-050 | UC004 | ADMIN    | HIGH     | tokenVersion incremented after password change | 1. Note user's tokenVersion before change; 2. User logged in | 1. PUT change password; 2. Query user DB record                   | 1. `tokenVersion` = previous value + 1                                                                          | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-051 | UC004 | ADMIN    | HIGH     | New JWT returned with updated tokenVersion     | 1. User logged in                                            | 1. PUT change password; 2. Decode returned JWT                    | 1. Response includes a new JWT; 2. JWT `tokenVersion` = DB `tokenVersion`; 3. Current session continues working | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-052 | UC004 | ADMIN    | HIGH     | New password stored as bcrypt hash             | 1. User logged in                                            | 1. PUT change password; 2. Query `users.password_hash`            | 1. `password_hash` changed; 2. New hash starts with `$2b$`; 3. Old hash ≠ new hash                              | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-053 | UC004 | ADMIN    | MEDIUM   | New password must meet complexity requirements | 1. User logged in                                            | 1. PUT with newPassword=`onlylower` (no uppercase/special/number) | 1. HTTP 400; 2. Validation error: password does not meet complexity requirements                                | —      | NOT_RUN | —      | —        |

---

## Security Tests

| ID                | UC    | Platform | Severity | Title                                          | Preconditions                                                                     | Steps                                                  | Expected                                                                               | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC04-ADMIN-070 | UC004 | ADMIN    | HIGH     | Old sessions invalidated after password change | 1. User logged in on device A (JWT_A); 2. Change password on device A → get JWT_B | 1. Use JWT_A to call authenticated endpoint            | 1. HTTP 401; 2. Error: SESSION_EXPIRED; 3. JWT_A rejected due to tokenVersion mismatch | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-071 | UC004 | ADMIN    | HIGH     | Current session continues with new JWT         | 1. Changed password → received new JWT                                            | 1. Use new JWT to call authenticated endpoint          | 1. HTTP 200; 2. Request accepted; 3. New JWT has correct tokenVersion                  | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-072 | UC004 | ADMIN    | HIGH     | Expired JWT rejected for password change       | 1. Expired JWT                                                                    | 1. PUT `{BASE_URL}/api/auth/password` with expired JWT | 1. HTTP 401; 2. Token expired error                                                    | —      | NOT_RUN | —      | —        |

---

## Edge Cases & Boundary Values

| ID                | UC    | Platform | Severity | Title                                                | Preconditions                                              | Steps                                                                              | Expected                                                                                                  | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC04-ADMIN-080 | UC004 | ADMIN    | MEDIUM   | New password exactly 8 characters (minimum boundary) | 1. User logged in                                          | 1. PUT with newPassword=`Aa1!aaaa` (exactly 8 chars, meets complexity)             | 1. HTTP 200; 2. Password changed successfully                                                             | —      | NOT_RUN | —      | —        |
| TC-UC04-ADMIN-081 | UC004 | ADMIN    | MEDIUM   | Change password immediately after previous change    | 1. User just changed password; 2. Within rate limit window | 1. PUT change password again with newest current password and another new password | 1. If within rate limit: success; 2. tokenVersion incremented again; 3. Previous new JWT also invalidated | —      | NOT_RUN | —      | —        |
