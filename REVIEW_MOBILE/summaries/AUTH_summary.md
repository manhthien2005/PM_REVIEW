# 🔬 MODULE SUMMARY: AUTH (Mobile)

> **Module**: AUTH — Authentication  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 1  
> **Trello Cards**: Card 3 (Login), Card 4 (Register), Card 5 (Forgot Password), Card 6 (Change Password)  
> **UC References**: UC001, UC002, UC003, UC004

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements

- **Login**: Patient/Caregiver login via email+password → JWT (`iss="healthguard-mobile"`, expiry **30 days** + refresh token, roles: PATIENT/CAREGIVER)
- **Register**: Self-registration → `is_verified=false`, email verification required (JWT token, 24h expiry)
- **Forgot Password**: Reset token (15min), rate limit 3/15min, one-time use, deep link: `app://reset-password?token=xxx`
- **Change Password**: Require JWT, verify current password, rate limit 5/15min, email notification

### Non-Functional Requirements

- **Security**: JWT + refresh token, bcrypt/passlib, TLS, rate limiting
- **Usability**: Large fonts, high contrast for elderly users (SRS §5.4)
- **Audit**: Log all login attempts

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 3 — Login (Mobile BE Dev)

- [ ] `POST /api/auth/login` — Req: `{email, password}`, Res: `{access_token, refresh_token, token_type, user: {id, email, role, full_name}}`
- [ ] bcrypt/passlib password verification
- [ ] JWT: `iss="healthguard-mobile"`, roles PATIENT/CAREGIVER, expiry 30 days
- [ ] Implement refresh token mechanism
- [ ] Rate limiting: 5 attempts/15min per IP
- [ ] Check `is_active` flag, update `last_login_at`
- [ ] Log to `audit_logs`
- [ ] Unit tests

### Card 3 — Login (Mobile FE Dev)

- [ ] Login screen (Flutter)
- [ ] Form validation, call API, store JWT + refresh token (secure storage)
- [ ] Navigate to dashboard, error handling, show/hide password, loading indicator

### Card 4 — Register (Mobile BE Dev)

- [ ] `POST /api/auth/register` — self-register for Patient/Caregiver
- [ ] Create user with `is_verified=false`
- [ ] Email verification token (JWT, 24h)
- [ ] Send verification email (SMTP, mockable)
- [ ] Validate: email format, uniqueness, password min 6 chars

### Card 5 — Forgot Password (Mobile BE Dev)

- [ ] `POST /api/auth/forgot-password` + `POST /api/auth/reset-password`
- [ ] Deep link: `app://reset-password?token=xxx`
- [ ] Token 15min, rate limit 3/15min, one-time use

### Card 6 — Change Password (Mobile BE Dev)

- [ ] `POST /api/auth/change-password` (require JWT)
- [ ] Verify current password, validate new, email notification, rate limit 5/15min

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)

| File Path                  | Role                                |
| -------------------------- | ----------------------------------- |
| `api/auth/`                | Auth API routes                     |
| `services/auth_service.py` | Auth business logic                 |
| `core/`                    | Config, security, dependencies      |
| `schemas/`                 | Pydantic schemas (request/response) |

### Mobile (`health_system/lib/features/auth/`)

| File Path        | Role                                                  |
| ---------------- | ----------------------------------------------------- |
| `features/auth/` | Auth feature module (9 children — Clean Architecture) |

---

## 🔗 Cross-References

| Type                 | Reference                                                                                                        |
| -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| SRS Section          | §4.6.1-§4.6.4, §5.3 (Security — JWT independent secret, mobile issuer, refresh token rotation, token revocation) |
| Use Case Files       | `BA/UC/Authentication/UC001-UC004`                                                                               |
| DB Tables            | `users`, `audit_logs`                                                                                            |
| Related Admin Module | `REVIEW_ADMIN/summaries/AUTH_summary.md`                                                                         |

---

## 📊 Review Notes

| Key            | Value                                                                |
| -------------- | -------------------------------------------------------------------- |
| Review Date    | 2026-03-04                                                           |
| Score          | 78/100 (+18 từ review trước)                                         |
| Reviewer Notes | Xem chi tiết: [AUTH_LOGIN_review_v3.md](../ AUTH_LOGIN_review_v3.md) |
