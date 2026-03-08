# AUTH (Admin)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC005, UC009

## Purpose & Technique
- Admin authentication: login → JWT (iss `healthguard-admin`, 8h), register (admin-only), forgot/reset/change password
- Email verification flow (verify token + resend); rate-limiting on login (5/15min per IP) and password operations
- Core logic centralized in `auth.service.js` under MVC pattern

## API Index
| Endpoint                  | Method | Note                                 |
| ------------------------- | ------ | ------------------------------------ |
| /api/auth/sessions        | POST   | Login; rate limited 5/15min          |
| /api/auth/me              | GET    | Get current user (JWT required)      |
| /api/auth/users           | POST   | Register (ADMIN JWT required)        |
| /api/auth/email/verify    | POST   | Verify email token                   |
| /api/auth/email/resend    | POST   | Resend verification email            |
| /api/auth/password/forgot | POST   | Send reset token, rate limit 3/15min |
| /api/auth/password/reset  | POST   | Reset password (one-time token)      |
| /api/auth/password        | PUT    | Change password (JWT required)       |

## File Index
| Path                                                  | Role                             |
| ----------------------------------------------------- | -------------------------------- |
| backend/src/controllers/auth.controller.js            | All auth route handlers (4009B)  |
| backend/src/services/auth.service.js                  | Auth + JWT + Mail logic (15731B) |
| backend/src/middlewares/auth.js                       | JWT verify + role check (3502B)  |
| backend/src/middlewares/validate.js                   | Input validators (1942B)         |
| backend/src/routes/auth.routes.js                     | Route definitions (2149B)        |
| frontend/src/pages/LoginPage.jsx                      | Login UI (12326B)                |
| frontend/src/pages/ForgotPasswordPage.jsx             | Forgot password UI (9603B)       |
| frontend/src/pages/ResetPasswordPage.jsx              | Reset password UI (14907B)       |
| frontend/src/components/admin/ChangePasswordModal.jsx | Change password UI (12602B)      |
| frontend/src/services/authService.js                  | Frontend auth API calls (3922B)  |

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
| 2026-03-07 | 71/100 | REVIEW_ADMIN/AUTH_review.md |
