# AUTH (Admin)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC005, UC009

## Purpose & Technique
- Admin authentication: login → JWT, register (admin-only), forgot/reset/change password
- Email verification flow; rate-limiting on login and password operations
- Services consolidated into auth.service.js handling all auth flows

## API Index
| Endpoint              | Method | Note                            |
| --------------------- | ------ | ------------------------------- |
| /auth/login           | POST   | Login; rate limited             |
| /auth/me              | GET    | Get current user (JWT required) |
| /auth/register        | POST   | Register (ADMIN JWT required)   |
| /auth/forgot-password | POST   | Send reset token, rate limited  |
| /auth/reset-password  | POST   | Reset password (one-time token) |
| /auth/password        | PUT    | Change password (JWT required)  |
| /auth/logout          | POST   | Logout                          |

## File Index
| Path                                       | Role                         |
| ------------------------------------------ | ---------------------------- |
| backend/src/controllers/auth.controller.js | Auth route handlers (4009B)  |
| backend/src/services/auth.service.js       | Auth business logic (16902B) |
| backend/src/routes/auth.routes.js          | Route definitions (2149B)    |
| frontend/src/pages/LoginPage.jsx           | Login UI (12326B)            |
| frontend/src/pages/ForgotPasswordPage.jsx  | Forgot password UI (9603B)   |
| frontend/src/pages/ResetPasswordPage.jsx   | Reset password UI (14907B)   |
| frontend/src/services/authService.js       | Frontend auth API (3922B)    |

## Known Issues
- 🔴 No email verification or resend routes found in auth.routes.js despite previous SRS plan

## Cross-References
| Type           | Ref                                                      |
| -------------- | -------------------------------------------------------- |
| DB Tables      | users, audit_logs                                        |
| UC Files       | BA/UC/Authentication/UC001_Login.md, UC002, UC003, UC004 |
| Related Module | REVIEW_MOBILE/summaries/AUTH_summary.md                  |

## Review
| Date       | Score  | Detail                      |
| ---------- | ------ | --------------------------- |
| 2026-03-07 | 71/100 | REVIEW_ADMIN/AUTH_review.md |
