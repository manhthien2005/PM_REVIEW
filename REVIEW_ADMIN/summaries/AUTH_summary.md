# AUTH (Admin)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001, UC002, UC003, UC004

## Purpose & Technique
- Admin authentication: login → JWT (iss `healthguard-admin`, 8h), register (admin-only), forgot/reset/change password
- Email verification flow (verify token + resend); rate-limiting on login (5/15min per IP) and password operations
- Services split by feature: `authService`, `registerService`, `changePasswordService`, `passwordResetService`, `emailService`, `verifyEmailService`

## API Index
| Endpoint                  | Method | Note                                 |
| ------------------------- | ------ | ------------------------------------ |
| /api/auth/sessions        | POST   | Login; rate limited 5/15min          |
| /api/auth/users           | POST   | Register (ADMIN JWT required)        |
| /api/auth/email/verify    | POST   | Verify email token                   |
| /api/auth/email/resend    | POST   | Resend verification email            |
| /api/auth/password/forgot | POST   | Send reset token, rate limit 3/15min |
| /api/auth/password/reset  | POST   | Reset password (one-time token)      |
| /api/auth/password        | PUT    | Change password (JWT required)       |

## File Index
| Path                                          | Role                            |
| --------------------------------------------- | ------------------------------- |
| backend/src/controllers/authController.ts     | All auth route handlers (34KB)  |
| backend/src/services/authService.ts           | Login + JWT logic (4.6KB)       |
| backend/src/services/registerService.ts       | User registration (5.5KB)       |
| backend/src/services/changePasswordService.ts | Change password logic (3.7KB)   |
| backend/src/services/passwordResetService.ts  | Forgot/reset flow (6.8KB)       |
| backend/src/services/emailService.ts          | Email sending (8.8KB)           |
| backend/src/services/verifyEmailService.ts    | Email verification (4.7KB)      |
| backend/src/middleware/authMiddleware.ts      | JWT verify + role check (1.7KB) |
| backend/src/middleware/rateLimiter.ts         | Rate limiter config (0.4KB)     |
| backend/src/routes/authRoutes.ts              | Route definitions (1.0KB)       |
| frontend/src/pages/LoginPage.tsx              | Login UI (13KB)                 |
| frontend/src/services/authService.ts          | Frontend auth API calls (2.1KB) |
| frontend/src/types/auth.ts                    | Auth TypeScript types (0.6KB)   |

## Known Issues
- 🟡 Login route uses `/api/auth/sessions` (not `/api/auth/login`) — deviates from SRS spec

## Cross-References
| Type           | Ref                                                      |
| -------------- | -------------------------------------------------------- |
| DB Tables      | users, audit_logs                                        |
| UC Files       | BA/UC/Authentication/UC001_Login.md, UC002, UC003, UC004 |
| Related Module | REVIEW_MOBILE/summaries/AUTH_summary.md                  |

## Review
| Date       | Score  | Detail                      |
| ---------- | ------ | --------------------------- |
| 2026-03-03 | 58/100 | REVIEW_ADMIN/AUTH_review.md |
