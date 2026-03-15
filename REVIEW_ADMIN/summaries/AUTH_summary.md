# AUTH (Admin)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC005, UC009

## Purpose & Technique
- Admin authentication: login → JWT (iss `healthguard-admin`, 8h), register (admin-only), forgot/reset/change password
- Rate-limiting on login (5/15min per IP), forgot-password (3/15min), change-password (5/15min)
- Core logic centralized in `auth.service.js` under MVC pattern; logout endpoint clears session

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/auth/login | POST | JWT iss: `healthguard-admin`, expiry 8h |
| /api/v1/auth/me | GET | Require JWT, returns current user info |
| /api/v1/auth/register | POST | Require ADMIN JWT, `is_verified=true` |
| /api/v1/auth/forgot-password | POST | Token 15min, rate limit 3/15min |
| /api/v1/auth/reset-password | POST | Token one-time use |
| /api/v1/auth/password | PUT | Require JWT, rate limit 5/15min |
| /api/v1/auth/logout | POST | Require JWT |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/auth.controller.js | Component (4670 bytes) |
| backend/src/services/auth.service.js | Component (17969 bytes) |
| backend/src/middlewares/auth.js | Component (3502 bytes) |
| validate.js | Component (2538 bytes) |
| backend/src/routes/auth.routes.js | Component (2149 bytes) |
| backend/src/__tests__/controllers/auth.controller.test.js | Component (10085 bytes) |
| backend/src/__tests__/services/auth.service.test.js | Component (19007 bytes) |
| frontend/src/pages/LoginPage.jsx | Component (12954 bytes) |
| frontend/src/pages/ForgotPasswordPage.jsx | Component (9603 bytes) |
| frontend/src/pages/ResetPasswordPage.jsx | Component (14907 bytes) |
| frontend/src/components/admin/ChangePasswordModal.jsx | Component (12602 bytes) |
| frontend/src/services/authService.js | Component (3922 bytes) |
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
