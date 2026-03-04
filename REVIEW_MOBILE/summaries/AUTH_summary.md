# AUTH (Mobile)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC004

## Purpose & Technique

- Login/Register/Forgot/Reset/Change Password for Patient & Caregiver roles
- JWT auth (issuer: `healthguard-mobile`, access 30d + refresh token), bcrypt via passlib
- Email verification via deep link (`healthguard://verify-email?token=xxx`), rate limiting (in-memory)

## API Index

| Endpoint                      | Method | Note                             |
| ----------------------------- | ------ | -------------------------------- |
| /api/auth/register            | POST   | Self-register, is_verified=false |
| /api/auth/verify-email        | POST   | Deep link token verification     |
| /api/auth/resend-verification | POST   | Rate limit 3/15min               |
| /api/auth/login               | POST   | JWT + refresh token              |
| /api/auth/refresh             | POST   | Refresh access token             |
| /api/auth/forgot-password     | POST   | Reset token 15min, deep link     |
| /api/auth/reset-password      | POST   | One-time use token               |
| /api/auth/change-password     | POST   | Requires JWT, verify current pwd |

## File Index

| Path                                                       | Role                           |
| ---------------------------------------------------------- | ------------------------------ |
| backend/app/api/routes/auth.py                             | Auth routes (260 LOC)          |
| backend/app/services/auth_service.py                       | AuthService class (779 LOC)    |
| backend/app/schemas/auth.py                                | Pydantic schemas (35 LOC)      |
| backend/app/models/user_model.py                           | User SQLAlchemy model (20 LOC) |
| backend/app/models/audit_log_model.py                      | AuditLog model (18 LOC)        |
| backend/app/repositories/user_repository.py                | UserRepository (66 LOC)        |
| backend/app/repositories/audit_log_repository.py           | AuditLogRepository (45 LOC)    |
| backend/app/utils/jwt.py                                   | JWT utils (121 LOC)            |
| backend/app/utils/email_service.py                         | Email service (190 LOC)        |
| backend/app/utils/password.py                              | Password hashing (8 LOC)       |
| backend/app/utils/rate_limiter.py                          | Rate limiter (61 LOC)          |
| backend/app/core/config.py                                 | Settings config (30 LOC)       |
| backend/app/core/dependencies.py                           | Auth dependencies (70 LOC)     |
| backend/tests/test_auth_service.py                         | Unit tests (15 tests)          |
| lib/features/auth/screens/login_screen.dart                | Login UI (242 LOC)             |
| lib/features/auth/screens/register_screen.dart             | Register UI (168 LOC)          |
| lib/features/auth/screens/verify_email_screen.dart         | Verify email UI (322 LOC)      |
| lib/features/auth/screens/forgot_password_screen.dart      | Forgot pwd UI (171 LOC)        |
| lib/features/auth/screens/reset_password_screen.dart       | Reset pwd UI (461 LOC)         |
| lib/features/auth/screens/change_password_screen.dart      | Change pwd UI (241 LOC)        |
| lib/features/auth/screens/start_screen.dart                | Start/splash screen (179 LOC)  |
| lib/features/auth/screens/email_verification_screen.dart   | Email verify UI (167 LOC)      |
| lib/features/auth/screens/debug_verify_screen.dart         | Debug verify (244 LOC)         |
| lib/features/auth/screens/debug_reset_password_screen.dart | Debug reset (228 LOC)          |
| lib/features/auth/providers/auth_provider.dart             | Auth state mgmt (137 LOC)      |
| lib/features/auth/repositories/auth_repository.dart        | API calls (110 LOC)            |
| lib/features/auth/services/token_storage_service.dart      | Secure storage (25 LOC)        |
| lib/features/auth/models/auth_response_model.dart          | Response model (54 LOC)        |
| lib/features/auth/models/user_model.dart                   | User model (9 LOC)             |
| lib/features/auth/widgets/auth_text_field.dart             | Custom text field (60 LOC)     |

## Known Issues

- 🔴 CORS: `allow_origins=["*"]` — security risk, must restrict
- 🔴 Refresh token rotation not implemented
- � Rate limiter is in-memory — needs Redis migration for production
- 🟡 Swagger UI not explicitly enabled in docs config

## Cross-References

| Type           | Ref                                    |
| -------------- | -------------------------------------- |
| DB Tables      | users, audit_logs                      |
| UC Files       | BA/UC/Authentication/UC001-UC004       |
| Related Module | REVIEW_ADMIN/summaries/AUTH_summary.md |

## Review

| Date       | Score  | Detail                  |
| ---------- | ------ | ----------------------- |
| 2026-03-04 | 84/100 | AUTH_LOGIN_review_v2.md |
