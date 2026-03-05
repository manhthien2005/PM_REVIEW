# Test Cases: AUTH — LOGIN

| Property     | Value      |
| ------------ | ---------- |
| **Module**   | AUTH       |
| **Function** | LOGIN      |
| **UC Refs**  | UC001      |
| **Platform** | ADMIN      |
| **Sprint**   | S1         |
| **Version**  | v1.0       |
| **Created**  | 2026-03-05 |
| **Author**   | AI_AGENT   |
| **Status**   | READY      |

---

## Test Data

> **Instruction**: Fill in the `Value` column before running tests. AI will use these during EXECUTE mode.
> Items marked ⬜ PENDING are required. Items marked ✅ are filled.

### Accounts

| #   | Material                 | Purpose                   | Value                    | Status |
| --- | ------------------------ | ------------------------- | ------------------------ | ------ |
| 1   | Admin email (valid)      | Happy path login          | `letandatk16@siu.edu.vn` | ⬜      |
| 2   | Admin password (valid)   | Happy path login          | `123456`                 | ⬜      |
| 3   | Non-existent email       | Wrong email test          | `notexist@test.com`      | ✅      |
| 4   | Wrong password           | Wrong password test       | `WrongPass123!`          | ✅      |
| 5   | Locked account email     | Account locked test       | ⬜ PENDING                | ⬜      |
| 6   | Unverified account email | Account not verified test | ⬜ PENDING                | ⬜      |

### Environment

| #   | Material       | Purpose       | Value     | Status |
| --- | -------------- | ------------- | --------- | ------ |
| 1   | Admin Base URL | All admin API | ⬜ PENDING | ⬜      |
| 2   | Frontend URL   | UI tests      | ⬜ PENDING | ⬜      |

---

## Summary

| Total | NOT_RUN | PASS | FAIL | BLOCKED | SKIP |
| ----- | ------- | ---- | ---- | ------- | ---- |
| 22    | 22      | 0    | 0    | 0       | 0    |

---

## Happy Path (Main Flow)

| ID                | UC    | Platform | Severity | Title                                               | Preconditions                                                                                                   | Steps                                                                                       | Expected                                                                                                                                                                                           | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC01-ADMIN-001 | UC001 | ADMIN    | CRITICAL | Valid login with correct email and password         | 1. Admin account exists in DB; 2. Account is active (is_active=true); 3. Account is verified (is_verified=true) | 1. POST `{BASE_URL}/api/auth/sessions` with valid email and password                        | 1. HTTP 200; 2. Response contains `{token, user}` ; 3. JWT has `iss=healthguard-admin`, role=ADMIN, tokenVersion; 4. `last_login_at` updated in DB; 5. Audit log created with action=LOGIN_SUCCESS | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-002 | UC001 | ADMIN    | CRITICAL | JWT token contains correct claims                   | 1. Successful login via TC-UC01-ADMIN-001                                                                       | 1. Decode JWT from login response; 2. Verify claims                                         | 1. JWT contains `userId`, `email`, `role=ADMIN`; 2. `iss=healthguard-admin`; 3. Expiry = 8 hours from issuance; 4. `tokenVersion` matches DB value                                                 | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-003 | UC001 | ADMIN    | CRITICAL | Frontend LoginPage renders and submits successfully | 1. Admin app running; 2. Valid admin account                                                                    | 1. Navigate to /login; 2. Enter valid email; 3. Enter valid password; 4. Click Login button | 1. Redirect to /dashboard; 2. JWT stored in localStorage as `hg_token`; 3. User info displayed on dashboard                                                                                        | —      | NOT_RUN | —      | —        |

---

## Alternative Flows

| ID                | UC    | Platform | Severity | Title                                                       | Preconditions                              | Steps                                                                                             | Expected                                                                                                                                 | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ----------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC01-ADMIN-020 | UC001 | ADMIN    | HIGH     | Login fails — email not found in DB                         | None                                       | 1. POST `{BASE_URL}/api/auth/sessions` with email=`notexist@test.com` and a valid-format password | 1. HTTP 401; 2. Error code `INVALID_CREDENTIALS`; 3. Generic message (no email enumeration leak); 4. Audit log with action=LOGIN_FAILURE | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-021 | UC001 | ADMIN    | HIGH     | Login fails — wrong password                                | 1. Admin account exists                    | 1. POST `{BASE_URL}/api/auth/sessions` with valid email and wrong password                        | 1. HTTP 401; 2. Error code `INVALID_CREDENTIALS`; 3. Same generic message as wrong email; 4. Audit log with LOGIN_FAILURE                | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-022 | UC001 | ADMIN    | HIGH     | Login fails — account locked (is_active=false)              | 1. Account exists with `is_active=false`   | 1. POST `{BASE_URL}/api/auth/sessions` with locked account credentials                            | 1. HTTP 423; 2. Error code `ACCOUNT_LOCKED`; 3. Message instructs user to contact admin                                                  | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-023 | UC001 | ADMIN    | HIGH     | Login fails — account not verified                          | 1. Account exists with `is_verified=false` | 1. POST `{BASE_URL}/api/auth/sessions` with unverified account credentials                        | 1. HTTP 403; 2. Error code `ACCOUNT_NOT_VERIFIED`                                                                                        | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-024 | UC001 | ADMIN    | HIGH     | Login blocked — rate limit exceeded (>5 attempts in 15 min) | None                                       | 1. POST `{BASE_URL}/api/auth/sessions` with wrong credentials 6 times within 15 minutes           | 1. First 5 attempts return 401; 2. 6th attempt returns HTTP 429; 3. Error code `TOO_MANY_ATTEMPTS`; 4. `Retry-After` header present      | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-025 | UC001 | ADMIN    | MEDIUM   | Login fails — empty email field                             | None                                       | 1. POST `{BASE_URL}/api/auth/sessions` with email="" and valid password                           | 1. HTTP 400; 2. Validation error for email field                                                                                         | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-026 | UC001 | ADMIN    | MEDIUM   | Login fails — empty password field                          | None                                       | 1. POST `{BASE_URL}/api/auth/sessions` with valid email and password=""                           | 1. HTTP 400; 2. Validation error for password field                                                                                      | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-027 | UC001 | ADMIN    | MEDIUM   | Login fails — invalid email format                          | None                                       | 1. POST `{BASE_URL}/api/auth/sessions` with email="not-an-email" and valid password               | 1. HTTP 400; 2. Validation error: invalid email format                                                                                   | —      | NOT_RUN | —      | —        |

---

## Validation & Business Rules

| ID                | UC    | Platform | Severity | Title                                                            | Preconditions                                            | Steps                                                                                                       | Expected                                                                                                                              | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC01-ADMIN-050 | UC001 | ADMIN    | HIGH     | Audit log recorded on successful login                           | 1. Admin account exists                                  | 1. POST `{BASE_URL}/api/auth/sessions` with valid credentials; 2. Query audit_logs table                    | 1. Audit log entry with: user_id, action=LOGIN_SUCCESS, IP address, user-agent, timestamp                                             | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-051 | UC001 | ADMIN    | HIGH     | Audit log recorded on failed login                               | None                                                     | 1. POST `{BASE_URL}/api/auth/sessions` with wrong credentials; 2. Query audit_logs table                    | 1. Audit log entry with: attempted email, action=LOGIN_FAILURE, IP address, user-agent                                                | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-052 | UC001 | ADMIN    | HIGH     | last_login_at is updated after successful login                  | 1. Admin account exists; 2. Note current `last_login_at` | 1. POST `{BASE_URL}/api/auth/sessions` with valid credentials; 2. Query users table                         | 1. `last_login_at` is updated to current timestamp (within 5 seconds)                                                                 | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-053 | UC001 | ADMIN    | MEDIUM   | Anti-enumeration — same error for wrong email and wrong password | None                                                     | 1. POST with non-existent email; 2. POST with existing email but wrong password; 3. Compare error responses | 1. Both return identical error code `INVALID_CREDENTIALS`; 2. Both return same HTTP 401; 3. Response body and structure are identical | —      | NOT_RUN | —      | —        |

---

## Security Tests

| ID                | UC    | Platform | Severity | Title                                                           | Preconditions                                             | Steps                                                                               | Expected                                                                                                                            | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | --------------------------------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC01-ADMIN-070 | UC001 | ADMIN    | HIGH     | SQL Injection in email field                                    | None                                                      | 1. POST `{BASE_URL}/api/auth/sessions` with email=`' OR '1'='1` and password=`test` | 1. No SQL injection; 2. Returns 400 or 401; 3. No data leakage; 4. Parameterized query via Prisma ORM                               | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-071 | UC001 | ADMIN    | HIGH     | XSS payload in email field                                      | None                                                      | 1. POST `{BASE_URL}/api/auth/sessions` with email=`<script>alert('xss')</script>`   | 1. No XSS execution; 2. Returns 400 (invalid email format); 3. Payload not reflected in response                                    | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-072 | UC001 | ADMIN    | HIGH     | CORS blocks request from unauthorized origin                    | None                                                      | 1. Send login request with `Origin: http://evil.com` header                         | 1. CORS error; 2. No `Access-Control-Allow-Origin: http://evil.com` in response; 3. Only `FRONTEND_URL` or `localhost:5173` allowed | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-073 | UC001 | ADMIN    | HIGH     | Session invalidation — token rejected after tokenVersion change | 1. Login and get JWT; 2. Change password (tokenVersion++) | 1. Use old JWT token from step 1; 2. Call any authenticated endpoint                | 1. HTTP 401; 2. Error code `SESSION_EXPIRED`; 3. Token rejected due to tokenVersion mismatch                                        | —      | NOT_RUN | —      | —        |

---

## Edge Cases & Boundary Values

| ID                | UC    | Platform | Severity | Title                                              | Preconditions | Steps                                                                   | Expected                                                                          | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | -------------------------------------------------- | ------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC01-ADMIN-080 | UC001 | ADMIN    | MEDIUM   | Login with email containing max length (255 chars) | None          | 1. POST `{BASE_URL}/api/auth/sessions` with 255-char valid email format | 1. Processed without error; 2. Returns 401 (user not found) or 200 if user exists | —      | NOT_RUN | —      | —        |
| TC-UC01-ADMIN-081 | UC001 | ADMIN    | MEDIUM   | Login with email containing special characters     | None          | 1. POST with email=`user+tag@example.com`                               | 1. Email passes validation if format is valid; 2. Returns 401 if user not found   | —      | NOT_RUN | —      | —        |
