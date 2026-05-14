# Intent Drift Review — `health_system / AUTH`

**Status:** ✅ Confirmed Phase 0.5 (2026-05-13) — Q1-Q3 finalized, UC001/009 mobile confirmed
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE)
**Module:** AUTH (Authentication — login, register, password management, email verification)
**Related UCs (old):** UC001 Login v2, UC002 Register, UC003 Forgot Password, UC004 Change Password, UC009 Logout v2
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13
**Question count:** 3 (Q1 UC001 mobile, Q2 UC009 mobile, Q3 UC003 OTP+link)

---

## 🎯 Mục tiêu

Capture intent cho AUTH module. 5 UCs cover login/register/forgot/change/logout. UC001+UC009 đã có v2 từ HealthGuard wave (admin confirmed). Phase 0.5 confirm mobile sections + update UC003 pattern. Output = UC mobile confirmed + decisions log.

---

## 📚 UC summary

- **UC001 Login v2:** Admin 🟢, Mobile → **Confirmed now**. Lockout + JWT + audit.
- **UC002 Register:** Email + password + profile. Email verification PIN 6 digits.
- **UC003 Forgot Password:** OTP 6 digits + deep link (both patterns supported).
- **UC004 Change Password:** Verify current → new → invalidate sessions.
- **UC009 Logout v2:** Admin 🟢, Mobile → **Confirmed now**. token_version + FCM unregister.

---

## 🔧 Code state — verified

### Routes (`auth.py`) — 10 endpoints

```
POST /auth/register, /auth/verify-email, /auth/resend-verification
POST /auth/login, /auth/refresh
POST /auth/forgot-password, /auth/verify-reset-otp, /auth/reset-password
POST /auth/change-password
GET  /auth/deep-link/:action/:code/:email
```

### Service — 10 methods covering all 5 UCs

### FE — 9 screens (login, register, email_verification, forgot_password, reset_otp_verification, reset_password, change_password, start, auth_pages)

### Key alignment verified:
- Bcrypt hash ✓, lockout 5x ✓, audit log ✓, generic error ✓
- Email verification PIN 6 digits ✓
- OTP + deep link dual pattern ✓
- Change password invalidates sessions ✓
- Role `user` = patient/caregiver combined ✓

---

## 💬 Decisions

### Q1: UC001 mobile — Confirm
✅ **A1** — Role `user` = combined. Verify issuer + expiry Phase 4.

### Q2: UC009 mobile — Confirm
✅ **A2** — FCM unregister endpoint exists. Verify token_version + popup Phase 4.

### Q3: UC003 — Both OTP + deep link
✅ **A3** — Update UC003 reflect both patterns (anh confirms cả 2 đều có).

---

## 🎯 Decisions table

| ID | Item | Decision | Effort Phase 4 |
|---|---|---|---|
| **D-AUTH-M01** | UC001 mobile | **Confirm, note role=user combined** | ~15min verify |
| **D-AUTH-M02** | UC009 mobile | **Confirm, verify token_version** | ~15min verify |
| **D-AUTH-M03** | UC003 pattern | **Update UC — OTP + deep link dual** | ~10min doc |

---

## 📊 Phase 4 effort: ~40min (verify/doc only, no code change)

### UC delta

| UC | Status |
|---|---|
| UC001 v2 | Mobile section → Confirmed |
| UC002 | No change |
| UC003 | Update v2: OTP + deep link dual pattern |
| UC004 | No change |
| UC009 v2 | Mobile section → Confirmed |

---

## 📝 Decisions log

| ID | Decision | Rationale |
|---|---|---|
| **D-AUTH-M01** | Confirm UC001 mobile | Code implements full login flow; role `user` = combined (permission via relationships) |
| **D-AUTH-M02** | Confirm UC009 mobile | FCM unregister exists; token_version in place |
| **D-AUTH-M03** | UC003 both patterns | Code has OTP + deep link; anh confirms both active |

---

## Cross-references

- `PM_REVIEW/Resources/UC/Authentication/UC001_Login_v2.md` — UPDATE mobile confirmed
- `PM_REVIEW/Resources/UC/Authentication/UC003_ForgotPassword.md` — UPDATE v2 dual pattern
- `PM_REVIEW/Resources/UC/Authentication/UC009_Logout_v2.md` — UPDATE mobile confirmed
- `health_system/backend/app/api/routes/auth.py` — 10 endpoints
- `health_system/backend/app/services/auth_service.py` — business logic
- `health_system/lib/features/auth/screens/` — 9 screens
