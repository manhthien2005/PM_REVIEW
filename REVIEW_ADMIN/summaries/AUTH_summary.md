# AUTH (Admin)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC005, UC009

## Purpose & Technique
- Admin authentication: login → JWT (iss `healthguard-admin`, 8h), register (admin-only), forgot/reset/change password
- Rate-limiting on login (5/15min per IP), forgot-password (3/15min), change-password (5/15min)
- Core logic centralized in `auth.service.js` under MVC pattern; logout endpoint clears session

## API Index
| Endpoint                     | Method | Note                                 |
| ---------------------------- | ------ | ------------------------------------ |
| /api/v1/auth/login           | POST   | Login; rate limited 5/15min          |
| /api/v1/auth/me              | GET    | Get current user (JWT required)      |
| /api/v1/auth/register        | POST   | Register (ADMIN JWT required)        |
| /api/v1/auth/forgot-password | POST   | Send reset token, rate limit 3/15min |
| /api/v1/auth/reset-password  | POST   | Reset password (one-time token)      |
| /api/v1/auth/password        | PUT    | Change password (JWT required)       |
| /api/v1/auth/logout          | POST   | Logout (JWT required)                |

## File Index
| Path                                                  | Role                              |
| ----------------------------------------------------- | --------------------------------- |
| backend/src/controllers/auth.controller.js            | All auth route handlers (4670B)   |
| backend/src/services/auth.service.js                  | Auth + JWT + Mail logic (17969B)  |
| backend/src/middlewares/auth.js                       | JWT verify + role check (3502B)   |
| backend/src/middlewares/validate.js                   | Input validators (2553B)          |
| backend/src/routes/auth.routes.js                     | Route definitions (2149B)         |
| backend/src/__tests__/controllers/auth.controller.test.js | Controller tests (10085B)     |
| backend/src/__tests__/services/auth.service.test.js   | Service tests (19007B)            |
| frontend/src/pages/LoginPage.jsx                      | Login UI (12954B)                 |
| frontend/src/pages/ForgotPasswordPage.jsx             | Forgot password UI (9603B)        |
| frontend/src/pages/ResetPasswordPage.jsx              | Reset password UI (14907B)        |
| frontend/src/components/admin/ChangePasswordModal.jsx | Change password UI (12602B)       |
| frontend/src/services/authService.js                  | Frontend auth API calls (3922B)   |

## Known Issues
- 🟡 No email verify/resend endpoints in actual routes (only in service layer)

## Cross-References
| Type           | Ref                                                      |
| -------------- | -------------------------------------------------------- |
| DB Tables      | users, audit_logs                                        |
| UC Files       | BA/UC/Authentication/UC001_Login.md, UC002, UC003, UC004 |
| Related Module | REVIEW_MOBILE/summaries/AUTH_summary.md                  |

## Review
| Date       | Score  | Detail                      |
| ---------- | ------ | --------------------------- |
| 2026-03-08 | 92/100 | REVIEW_ADMIN/AUTH_review.md |
