# Test Cases: AUTH — FORGOT_PASSWORD

| Property     | Value                                   |
| ------------ | --------------------------------------- |
| **Module**   | AUTH                                    |
| **Function** | FORGOT_PASSWORD (Request Reset + Reset) |
| **UC Refs**  | UC003                                   |
| **Platform** | ADMIN                                   |
| **Sprint**   | S1                                      |
| **Version**  | v1.0                                    |
| **Created**  | 2026-03-05                              |
| **Author**   | AI_AGENT                                |
| **Status**   | READY                                   |

> **Note**: This covers both phases: Phase 1 (POST /password/forgot — request reset) and Phase 2 (POST /password/reset — set new password with token).

---

## Test Data

> **Instruction**: Fill in the `Value` column before running tests.

### Accounts

| #   | Material              | Purpose                       | Value               | Status |
| --- | --------------------- | ----------------------------- | ------------------- | ------ |
| 1   | Registered user email | Valid forgot password request | ⬜ PENDING           | ⬜      |
| 2   | Non-existent email    | Anti-enumeration test         | `fake@nonexist.com` | ✅      |
| 3   | User current password | Same-password check           | ⬜ PENDING           | ⬜      |
| 4   | New valid password    | Reset password test           | `NewPass@2026`      | ✅      |

### Environment

| #   | Material           | Purpose            | Value     | Status |
| --- | ------------------ | ------------------ | --------- | ------ |
| 1   | Admin Base URL     | All admin API      | ⬜ PENDING | ⬜      |
| 2   | Email inbox access | Verify reset email | ⬜ PENDING | ⬜      |

### Tokens & Keys

| #   | Material            | Purpose             | Value            | Status |
| --- | ------------------- | ------------------- | ---------------- | ------ |
| 1   | Valid reset token   | Reset password test | ⬜ AUTO-GENERATED | ⬜      |
| 2   | Expired reset token | Token expiry test   | ⬜ PENDING        | ⬜      |
| 3   | Used reset token    | One-time use test   | ⬜ AUTO-GENERATED | ⬜      |

---

## Summary

| Total | NOT_RUN | PASS | FAIL | BLOCKED | SKIP |
| ----- | ------- | ---- | ---- | ------- | ---- |
| 21    | 21      | 0    | 0    | 0       | 0    |

---

## Happy Path (Main Flow)

| ID                | UC    | Platform | Severity | Title                                             | Preconditions                                                                | Steps                                                                    | Expected                                                                                                                                                                                                 | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC03-ADMIN-001 | UC003 | ADMIN    | CRITICAL | Phase 1 — Request password reset with valid email | 1. User account exists; 2. Email is active                                   | 1. POST `{BASE_URL}/api/auth/password/forgot` with registered email      | 1. HTTP 200; 2. Success message: "Đã gửi email hướng dẫn"; 3. Email received with reset link; 4. Reset token hash saved in DB (`resetTokenHash` NOT NULL); 5. `resetTokenExpiry` set to NOW + 15 minutes | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-002 | UC003 | ADMIN    | CRITICAL | Phase 2 — Reset password with valid token         | 1. Reset token obtained from email (TC-UC03-ADMIN-001); 2. Token not expired | 1. POST `{BASE_URL}/api/auth/password/reset` with `{token, newPassword}` | 1. HTTP 200; 2. Password updated in DB (bcrypt hash changed); 3. `resetTokenHash` set to NULL; 4. `resetTokenExpiry` set to NULL; 5. `tokenVersion` incremented by 1; 6. All old sessions invalidated    | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-003 | UC003 | ADMIN    | CRITICAL | User can login with new password after reset      | 1. Password reset completed (TC-UC03-ADMIN-002)                              | 1. POST `{BASE_URL}/api/auth/sessions` with email and new password       | 1. HTTP 200; 2. JWT token issued; 3. Login successful with new password                                                                                                                                  | —      | NOT_RUN | —      | —        |

---

## Alternative Flows

| ID                | UC    | Platform | Severity | Title                                                           | Preconditions                                       | Steps                                                                            | Expected                                                                                                  | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | --------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC03-ADMIN-020 | UC003 | ADMIN    | HIGH     | Anti-enumeration — non-existent email returns same success      | None                                                | 1. POST `{BASE_URL}/api/auth/password/forgot` with `fake@nonexist.com`           | 1. HTTP 200; 2. Same success message as valid email; 3. No email actually sent; 4. No information leakage | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-021 | UC003 | ADMIN    | HIGH     | Reset fails — token expired (>15 minutes)                       | 1. Reset token obtained >15 min ago                 | 1. POST `{BASE_URL}/api/auth/password/reset` with expired token                  | 1. HTTP 400; 2. Error: token expired/invalid; 3. Password NOT changed                                     | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-022 | UC003 | ADMIN    | HIGH     | Reset fails — token already used (one-time use)                 | 1. Reset token already consumed (TC-UC03-ADMIN-002) | 1. POST `{BASE_URL}/api/auth/password/reset` with the same token again           | 1. HTTP 400; 2. Error: invalid token; 3. `resetTokenHash` is NULL in DB                                   | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-023 | UC003 | ADMIN    | HIGH     | Reset fails — invalid/malformed token                           | None                                                | 1. POST `{BASE_URL}/api/auth/password/reset` with token=`invalid-random-string`  | 1. HTTP 400; 2. Error: invalid token; 3. No DB changes                                                    | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-024 | UC003 | ADMIN    | HIGH     | Reset fails — new password same as current password             | 1. Valid reset token                                | 1. POST `{BASE_URL}/api/auth/password/reset` with newPassword = current password | 1. HTTP 400; 2. Error: new password must be different from current                                        | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-025 | UC003 | ADMIN    | HIGH     | Rate limit — forgot password blocked after 3 attempts in 15 min | None                                                | 1. POST `{BASE_URL}/api/auth/password/forgot` 4 times within 15 minutes          | 1. First 3 return HTTP 200; 2. 4th attempt returns HTTP 429; 3. Error code `TOO_MANY_ATTEMPTS`            | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-026 | UC003 | ADMIN    | MEDIUM   | Reset fails — empty password                                    | 1. Valid reset token                                | 1. POST `{BASE_URL}/api/auth/password/reset` with newPassword=""                 | 1. HTTP 400; 2. Validation error                                                                          | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-027 | UC003 | ADMIN    | MEDIUM   | Forgot password — empty email field                             | None                                                | 1. POST `{BASE_URL}/api/auth/password/forgot` with email=""                      | 1. HTTP 400; 2. Validation error: email required                                                          | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-028 | UC003 | ADMIN    | MEDIUM   | Forgot password — invalid email format                          | None                                                | 1. POST `{BASE_URL}/api/auth/password/forgot` with email="not-email"             | 1. HTTP 400; 2. Validation error: invalid email format                                                    | —      | NOT_RUN | —      | —        |

---

## Validation & Business Rules

| ID                | UC    | Platform | Severity | Title                                             | Preconditions                                                  | Steps                                                                   | Expected                                                                               | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ------------------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC03-ADMIN-050 | UC003 | ADMIN    | HIGH     | Reset token stored as SHA256 hash (not plaintext) | 1. Forgot password requested                                   | 1. Request forgot password; 2. Query `users` table for `resetTokenHash` | 1. `resetTokenHash` is 64-char hex string (SHA256); 2. NOT the raw token sent in email | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-051 | UC003 | ADMIN    | HIGH     | tokenVersion incremented after password reset     | 1. Note user's tokenVersion before reset; 2. Valid reset token | 1. POST password reset; 2. Query user DB record                         | 1. `tokenVersion` = previous value + 1; 2. All old JWTs invalidated                    | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-052 | UC003 | ADMIN    | MEDIUM   | New password must meet complexity requirements    | 1. Valid reset token                                           | 1. POST reset with password=`weakpw` (no uppercase, no special char)    | 1. HTTP 400; 2. Validation error: password requirements not met                        | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-053 | UC003 | ADMIN    | HIGH     | Reset token expiry is exactly 15 minutes          | 1. Request forgot password; 2. Note `resetTokenExpiry` in DB   | 1. Compare `resetTokenExpiry` with request time                         | 1. `resetTokenExpiry` = request time + 15 minutes (±5 seconds)                         | —      | NOT_RUN | —      | —        |

---

## Security Tests

| ID                | UC    | Platform | Severity | Title                                             | Preconditions                                                                               | Steps                                                                    | Expected                                                                                        | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC03-ADMIN-070 | UC003 | ADMIN    | HIGH     | Brute-force token guessing prevented              | None                                                                                        | 1. POST `{BASE_URL}/api/auth/password/reset` with multiple random tokens | 1. All return 400; 2. SHA256 hash comparison makes brute-force infeasible; 3. No timing leakage | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-071 | UC003 | ADMIN    | HIGH     | Old JWT sessions invalidated after password reset | 1. User logged in with JWT (tokenVersion=N); 2. Password reset completed (tokenVersion=N+1) | 1. Use old JWT to access authenticated endpoint                          | 1. HTTP 401; 2. Error: SESSION_EXPIRED; 3. Old JWT no longer valid                              | —      | NOT_RUN | —      | —        |

---

## Edge Cases & Boundary Values

| ID                | UC    | Platform | Severity | Title                                                      | Preconditions                                   | Steps                                                                                   | Expected                                                                                    | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC03-ADMIN-080 | UC003 | ADMIN    | MEDIUM   | Reset at exactly 15 minutes boundary                       | 1. Reset token requested exactly 15 minutes ago | 1. POST reset with token at exactly the 15-minute mark                                  | 1. Token should be valid if within window; 2. Boundary behavior: `resetTokenExpiry > NOW()` | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-081 | UC003 | ADMIN    | MEDIUM   | New password at exactly 8 characters (minimum boundary)    | 1. Valid reset token                            | 1. POST reset with password=`Aa1!aaaa` (exactly 8 chars, meets complexity)              | 1. HTTP 200; 2. Password updated successfully                                               | —      | NOT_RUN | —      | —        |
| TC-UC03-ADMIN-082 | UC003 | ADMIN    | MEDIUM   | Multiple forgot password requests overwrite previous token | 1. User email exists                            | 1. POST forgot password twice; 2. Use token from 1st email; 3. Use token from 2nd email | 1. 1st token should be invalid (overwritten); 2. 2nd token should work                      | —      | NOT_RUN | —      | —        |
