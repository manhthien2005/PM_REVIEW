# Test Cases: AUTH — REGISTER

| Property     | Value                         |
| ------------ | ----------------------------- |
| **Module**   | AUTH                          |
| **Function** | REGISTER (Admin creates user) |
| **UC Refs**  | UC002                         |
| **Platform** | ADMIN                         |
| **Sprint**   | S1                            |
| **Version**  | v1.0                          |
| **Created**  | 2026-03-05                    |
| **Author**   | AI_AGENT                      |
| **Status**   | READY                         |

> **Note**: On Admin platform, Register = Admin creates a new user via `POST /api/auth/users` (requires ADMIN JWT). This is NOT self-registration.

---

## Test Data

> **Instruction**: Fill in the `Value` column before running tests.

### Accounts

| #   | Material            | Purpose                     | Value              | Status |
| --- | ------------------- | --------------------------- | ------------------ | ------ |
| 1   | Admin JWT token     | Auth for all register tests | ⬜ PENDING          | ⬜      |
| 2   | Existing user email | Duplicate email test        | ⬜ PENDING          | ⬜      |
| 3   | New test email      | Valid registration          | `newuser@test.com` | ✅      |
| 4   | Valid password      | Valid registration          | `Test@1234`        | ✅      |
| 5   | Weak password       | Weak password test          | `123`              | ✅      |
| 6   | Non-admin JWT token | Permission check            | ⬜ PENDING          | ⬜      |

### Environment

| #   | Material       | Purpose       | Value     | Status |
| --- | -------------- | ------------- | --------- | ------ |
| 1   | Admin Base URL | All admin API | ⬜ PENDING | ⬜      |

---

## Summary

| Total | NOT_RUN | PASS | FAIL | BLOCKED | SKIP |
| ----- | ------- | ---- | ---- | ------- | ---- |
| 19    | 19      | 0    | 0    | 0       | 0    |

---

## Happy Path (Main Flow)

| ID                | UC    | Platform | Severity | Title                                       | Preconditions                                                                          | Steps                                                                                                                                                  | Expected                                                                                                                                                        | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ------------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC02-ADMIN-001 | UC002 | ADMIN    | CRITICAL | Admin creates user with all required fields | 1. Admin is logged in with valid JWT; 2. Email `newuser@test.com` does not exist in DB | 1. POST `{BASE_URL}/api/auth/users` with headers `Authorization: Bearer {ADMIN_JWT}`; 2. Body: `{email, password, fullName, phone, dateOfBirth, role}` | 1. HTTP 201; 2. Response contains created user object; 3. User has `is_verified=true` (admin-created); 4. Password is bcrypt hashed in DB; 5. Audit log created | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-002 | UC002 | ADMIN    | CRITICAL | Created user can login successfully         | 1. User created via TC-UC02-ADMIN-001                                                  | 1. POST `{BASE_URL}/api/auth/sessions` with the newly created user's email and password                                                                | 1. HTTP 200; 2. JWT token returned; 3. User info matches registration data                                                                                      | —      | NOT_RUN | —      | —        |

---

## Alternative Flows

| ID                | UC    | Platform | Severity | Title                                              | Preconditions                               | Steps                                                            | Expected                                                       | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | -------------------------------------------------- | ------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC02-ADMIN-020 | UC002 | ADMIN    | HIGH     | Register fails — duplicate email                   | 1. Admin JWT; 2. Email already exists in DB | 1. POST `{BASE_URL}/api/auth/users` with existing email          | 1. HTTP 409; 2. Error code `EMAIL_EXISTS`; 3. User not created | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-021 | UC002 | ADMIN    | HIGH     | Register fails — weak password (less than 8 chars) | 1. Admin JWT                                | 1. POST `{BASE_URL}/api/auth/users` with password=`123`          | 1. HTTP 400; 2. Validation error: password too short           | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-022 | UC002 | ADMIN    | HIGH     | Register fails — missing required field (email)    | 1. Admin JWT                                | 1. POST `{BASE_URL}/api/auth/users` without email field          | 1. HTTP 400; 2. Validation error: email required               | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-023 | UC002 | ADMIN    | HIGH     | Register fails — missing required field (fullName) | 1. Admin JWT                                | 1. POST `{BASE_URL}/api/auth/users` without fullName field       | 1. HTTP 400; 2. Validation error: fullName required            | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-024 | UC002 | ADMIN    | HIGH     | Register fails — invalid email format              | 1. Admin JWT                                | 1. POST `{BASE_URL}/api/auth/users` with email=`not-an-email`    | 1. HTTP 400; 2. Validation error: invalid email format         | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-025 | UC002 | ADMIN    | HIGH     | Register fails — no authentication (no JWT)        | None                                        | 1. POST `{BASE_URL}/api/auth/users` without Authorization header | 1. HTTP 401; 2. Error: unauthorized                            | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-026 | UC002 | ADMIN    | HIGH     | Register fails — non-admin role JWT                | 1. JWT with role=PATIENT                    | 1. POST `{BASE_URL}/api/auth/users` with non-admin JWT           | 1. HTTP 403; 2. Error: admin access required                   | —      | NOT_RUN | —      | —        |

---

## Validation & Business Rules

| ID                | UC    | Platform | Severity | Title                                    | Preconditions | Steps                                                                          | Expected                                                                                             | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------- | ------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC02-ADMIN-050 | UC002 | ADMIN    | HIGH     | Password is bcrypt hashed in database    | 1. Admin JWT  | 1. Create user via API; 2. Query `users` table for created user                | 1. `password_hash` is NOT plaintext; 2. Hash starts with `$2b$` (bcrypt prefix); 3. Salt rounds = 10 | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-051 | UC002 | ADMIN    | MEDIUM   | Phone number validation (Vietnam format) | 1. Admin JWT  | 1. POST with phone=`123456` (invalid); 2. POST with phone=`0912345678` (valid) | 1. Invalid: HTTP 400, validation error; 2. Valid: HTTP 201, user created                             | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-052 | UC002 | ADMIN    | MEDIUM   | Full name validation (1-100 chars)       | 1. Admin JWT  | 1. POST with fullName="" (empty); 2. POST with fullName=101 chars              | 1. Empty: HTTP 400; 2. 101 chars: HTTP 400                                                           | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-053 | UC002 | ADMIN    | MEDIUM   | Date of birth must be in the past        | 1. Admin JWT  | 1. POST with dateOfBirth=`2030-01-01` (future date)                            | 1. HTTP 400; 2. Validation error: date of birth must be in the past                                  | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-054 | UC002 | ADMIN    | MEDIUM   | Admin-created user has is_verified=true  | 1. Admin JWT  | 1. POST `{BASE_URL}/api/auth/users` with valid data; 2. Query users table      | 1. `is_verified = true`; 2. No verification email required for admin-created users                   | —      | NOT_RUN | —      | —        |

---

## Security Tests

| ID                | UC    | Platform | Severity | Title                                            | Preconditions        | Steps                                                 | Expected                                                                                     | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ------------------------------------------------ | -------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC02-ADMIN-070 | UC002 | ADMIN    | HIGH     | SQL Injection in email field during registration | 1. Admin JWT         | 1. POST with email=`'; DROP TABLE users; --`          | 1. No SQL injection; 2. Returns 400 (invalid email); 3. Prisma ORM prevents injection        | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-071 | UC002 | ADMIN    | HIGH     | XSS payload in fullName field                    | 1. Admin JWT         | 1. POST with fullName=`<script>alert('xss')</script>` | 1. Input sanitized or stored as-is but not executed; 2. API response does not execute script | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-072 | UC002 | ADMIN    | HIGH     | Expired JWT rejected for user creation           | 1. Expired admin JWT | 1. POST `{BASE_URL}/api/auth/users` with expired JWT  | 1. HTTP 401; 2. Token rejected                                                               | —      | NOT_RUN | —      | —        |

---

## Edge Cases & Boundary Values

| ID                | UC    | Platform | Severity | Title                                    | Preconditions | Steps                                                                | Expected                                                    | Actual | Status  | Tester | DateTime |
| ----------------- | ----- | -------- | -------- | ---------------------------------------- | ------------- | -------------------------------------------------------------------- | ----------------------------------------------------------- | ------ | ------- | ------ | -------- |
| TC-UC02-ADMIN-080 | UC002 | ADMIN    | MEDIUM   | Email at max length (255 chars)          | 1. Admin JWT  | 1. POST with email=`a{240}@example.com` (255 total chars)            | 1. Accepted if valid format; 2. Stored in DB (VARCHAR(255)) | —      | NOT_RUN | —      | —        |
| TC-UC02-ADMIN-081 | UC002 | ADMIN    | MEDIUM   | Password exactly 8 characters (boundary) | 1. Admin JWT  | 1. POST with password=`Aa1!aaaa` (exactly 8 chars, meets complexity) | 1. HTTP 201; 2. User created successfully                   | —      | NOT_RUN | —      | —        |
