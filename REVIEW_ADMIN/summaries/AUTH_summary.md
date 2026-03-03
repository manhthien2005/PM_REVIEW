# 🔬 MODULE SUMMARY: AUTH (Admin)

> **Module**: AUTH — Authentication & Authorization  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 1  
> **Trello Cards**: Card 3 (Login), Card 4 (Register), Card 5 (Forgot Password), Card 6 (Change Password)  
> **UC References**: UC001, UC002, UC003, UC004

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- **Login**: Admin login via email+password → JWT token (`iss="healthguard-admin"`, expiry **8h**, role: ADMIN)
- **Register**: Admin-only creates users via `POST /api/users` (NOT self-register). New user gets `is_verified=true`
- **Forgot Password**: Generate reset token (JWT, **15min** expiry), rate limit **3 requests/15min** per email, token one-time use
- **Change Password**: Require valid JWT, verify current password, rate limit **5 attempts/15min**, send email notification

### Non-Functional Requirements
- **Security**: JWT auth, bcrypt password hashing, TLS/SSL, rate limiting
- **Performance**: Login response < 2s
- **Audit**: Log all login attempts to `audit_logs` table

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 3 — Login (Admin BE Dev)
- [ ] `POST /api/auth/login` — Req: `{email, password}`, Res: `{access_token, token_type, user: {id, email, role, full_name}}`
- [ ] bcrypt password verification
- [ ] JWT: `iss="healthguard-admin"`, role ADMIN, expiry 8h
- [ ] Rate limiting: 5 attempts/15min per IP
- [ ] Check `is_active` flag
- [ ] Update `last_login_at`
- [ ] Log to `audit_logs`
- [ ] Error handling: wrong email/password, account locked
- [ ] Unit tests

### Card 3 — Login (Admin FE Dev)
- [ ] Login page (React + TailwindCSS)
- [ ] Form validation (email format, required)
- [ ] Store JWT (localStorage or httpOnly cookie)
- [ ] Redirect to dashboard
- [ ] Error messages, show/hide password, loading state

### Card 4 — Register (Admin BE Dev)
- [ ] `POST /api/users` (require ADMIN JWT)
- [ ] Validate email format + uniqueness, hash password
- [ ] Create user with `is_verified=true`
- [ ] Unit tests

### Card 5 — Forgot Password (Admin BE Dev)
- [ ] `POST /api/auth/forgot-password` + `POST /api/auth/reset-password`
- [ ] Reset token JWT 15min, rate limit 3/15min, one-time use

### Card 6 — Change Password (Admin BE Dev)
- [ ] `POST /api/auth/change-password` (require JWT)
- [ ] Verify current password, validate new, update DB
- [ ] Email notification, rate limit 5/15min

### Acceptance Criteria
- [ ] Admin login + Mobile login operate independently
- [ ] JWT tokens have different issuers
- [ ] Redirect correct dashboard per role
- [ ] Error messages display correctly
- [ ] Rate limiting works on both
- [ ] Audit log recorded on both

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/src/`)
| File Path | Role | Expected Content |
|-----------|------|-----------------|
| `controllers/auth.controller.ts` | Route handler | Login, forgot-password, reset-password, change-password endpoints |
| `services/auth.service.ts` | Business logic | JWT generation, password verification, rate limiting |
| `middleware/auth.middleware.ts` | Middleware | JWT verification, role-based access control |
| `config/` | Config | DB connection, JWT secret, env vars |
| `utils/` | Helpers | Password hashing, token generation |

### Frontend (`HealthGuard/frontend/src/`)
| File Path | Role | Expected Content |
|-----------|------|-----------------|
| `pages/Login.tsx` | Page | Login form + API call |
| `pages/ForgotPassword.tsx` | Page | Forgot/Reset password flow |
| `services/` | API layer | Auth API service calls |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §4.6.1 (Login), §4.6.2 (Register), §4.6.3 (Forgot), §4.6.4 (Change) |
| SRS Security | §5.3 — JWT (independent secret), bcrypt, TLS, token revocation, password policy |
| Use Case Files | `BA/UC/Authentication/UC001_Login.md`, `UC002_Register.md`, `UC003_ForgotPassword.md`, `UC004_ChangePassword.md` |
| DB Tables | `users`, `audit_logs` |
| Related Mobile Module | `REVIEW_MOBILE/summaries/AUTH_summary.md` |

---

## 📊 Review Notes
<!-- Updated after review -->
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
