# Intent Drift Review — `HealthGuard / AUTH`

**Status:** 🟢 Confirmed (anh react 2026-05-12)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** AUTH (login, logout, forgot pwd, reset pwd, change pwd, profile)
**Related UCs (old):** UC001 (Login), UC009 (Logout), [UC003 (ForgotPwd), UC004 (ChangePwd) — see Q1]
**Phase 1 audit ref:** `tier2/healthguard/M01-M07_audit.md` (AUTH-related findings tổng hợp)
**Date prepared:** 2026-05-12

---

## 🎯 Mục tiêu doc này

Capture anh-now's intent cho HealthGuard AUTH module. UC cũ là memory aid. Output = new UC001 + UC009 (admin variants) + decisions log.

---

## 📚 Memory aid — UC cũ summary

### UC001 - Login (cũ, 5 dòng)

- **Actor:** Patient, Caregiver, Admin (multi-platform)
- **Flow:** email/pwd → check DB → tạo JWT + session → redirect dashboard theo role
- **BR-001-04:** lockout **5 lần/15 phút PER IP** (UC nói IP-based)
- **BR-001-02:** Admin token 8h, Mobile 30d + refresh 90d rotation
- **BR-001-05:** min password 8 chars

### UC009 - Logout (cũ, 5 dòng)

- **Actor:** Patient, Caregiver, Admin (multi-platform)
- **Flow:** chọn logout → popup confirm → hủy FCM token → invalidate token → clear local → redirect login
- **BR-009-01:** Hủy FCM token (mobile-specific)
- **BR-009-03:** Admin: **blacklist access token** (UC nói)
- **Alt 4.a:** "Logout all devices" — hủy mọi refresh + FCM tokens của user
- **Alt 5.a:** Pending logout (offline) — đánh dấu, lần login sau hủy

### UC003 / UC004 (forgot pwd / change pwd) — Mobile-scoped per MASTER_INDEX

**Nhưng:** HealthGuard admin BE thực tế có endpoints `/forgot-password`, `/reset-password`, `/password` (M03 audit confirmed). Conflict với UC scope.

---

## 🔧 Code state — what currently exists (HealthGuard admin BE)

**Endpoints (M02 audit):**

```
POST /api/v1/admin/auth/login        ✅ working
POST /api/v1/admin/auth/logout       ✅ audit log only, no token invalidation server-side
POST /api/v1/admin/auth/register     ✅ admin tạo user (role=user only)
POST /api/v1/admin/auth/forgot-password   ✅ send email reset token
POST /api/v1/admin/auth/reset-password    ✅ verify token + new pwd
PUT  /api/v1/admin/auth/password     ✅ change pwd (logged in)
GET  /api/v1/admin/auth/me           ✅ get current user
```

**Behavior summary (M04 audit auth.service.js):**

- bcrypt salt 10 ✅
- Lockout 5x/15 phút **PER USER** (`failed_login_attempts` field) — KHÁC UC (UC nói per-IP)
- Audit log every attempt (success + fail) ✅
- JWT có `token_version` field — logout = không tăng version (chỉ log) → token cũ vẫn valid đến hết expiry 8h ⚠️
- Session frontend: localStorage (M01 audit)
- Email regex + phone regex + Vietnamese name regex validation
- Account check: `is_active`, `is_verified`, `locked_until`
- Password validator: 8 chars min ✅

**Phase 1 audit verdict:**
- M01 Bootstrap 🟡 (CORS reflection — security gap)
- M02 Routes 🟡 (D-007 /users conflict, ko rate limit some routes)
- M03 Controllers 🟢 (style debt only)
- M04 Services 🟢 R3 reference pattern (lockout + audit log)
- M05 Middlewares 🟢 R1 reference pattern (JWT + token_version + DB roundtrip)

---

## 💬 Anh react block

> Anh trả lời inline. Em đề xuất default — anh tick override nếu khác.

---

### Q1: Scope UC003/UC004 cho admin

**Vấn đề:** MASTER_INDEX nói UC003/UC004 = Mobile-only. Nhưng HealthGuard admin BE có cả 3 endpoints (forgot/reset/change password).

**Options:**
- **A.** Admin KHÔNG có forgot/change password — chỉ admin reset thông qua DB. Drop endpoints.
- **B.** Admin có forgot/change password — em rewrite UC003/UC004 thành multi-platform (admin + mobile).
- **C.** Tách: UC003a (mobile forgot), UC003b (admin forgot) riêng vì flow khác (admin có email corp, mobile có SMS/email user).

**Em recommend:** **B** — admin user cũng cần đổi password tự, không thể chỉ root admin reset DB cho mọi người. UC003/UC004 rewrite thành "User-self forgot/change password" scope-wide.

**Anh decision:** ☑ **A. Drop admin endpoints** — admin reset password thông qua DB manual, UC003/UC004 keep mobile-only scope.

**Impact:**
- REMOVE 3 endpoints khỏi `auth.routes.js` + `auth.controller.js` + `auth.service.js`:
  - `POST /forgot-password`
  - `POST /reset-password`
  - `PUT /password`
- REMOVE `email.js sendPasswordResetEmail` nếu không dùng cho ai khác
- DB seed/migration: cung cấp script `npm run admin:reset-pwd <email>` thay thế

---

### Q2: Lockout granularity — per USER vs per IP

**UC cũ (BR-001-04):** lockout PER IP (5 fail/15 phút/IP)
**Code thực tế:** lockout PER USER (`failed_login_attempts` trong user row)

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| Per USER | Đơn giản, chống credential stuffing target 1 account | Attacker test 10000 accounts từ 1 IP → no rate limit |
| Per IP | Chống bruteforce từ 1 IP | Nhiều user chung NAT (corp/edu) bị lock false positive |
| **Cả 2** | Best protection | Implementation phức tạp |

**Em recommend:** **Cả 2** — per USER (như hiện tại) **+ rate limit per IP** ở route level (đã có `authLimiter` trong M02 audit). Update UC để mô tả 2 layers.

**Anh decision:** ☑ **Em recommend** — cả 2 layers (per USER lỗi + IP rate limit ở route level).

**Impact:** Code hiện tại có `failed_login_attempts` per user (giữ) + `authLimiter` per IP (giữ). UC001 v2 cập nhật BR-001-04 mô tả cả 2.

---

### Q3: Token invalidation on logout

**UC cũ (BR-009-03):** Admin "blacklist access token"
**Code thực tế:** Logout chỉ ghi audit log, KHÔNG invalidate token server-side. Token cũ vẫn valid đến hết 8h expiry.

**Implications:**
- Nếu user logout vì nghi ngờ bị lộ token → token vẫn dùng được tới 8h
- Reference pattern R1 (M05 F1) có `token_version` check — em recommend **tăng `token_version` on logout** → invalidate cả refresh + access ngay lập tức

**Em recommend:** Implement **`token_version` increment on logout** → align với UC + tận dụng pattern đã có.

**Anh decision:** ☑ **Em recommend** — increment `token_version` on logout → immediate token invalidation.

**Impact:**
- `auth.service.js logoutUser()` thêm `await prisma.users.update({ where:{id}, data:{ token_version: { increment: 1 } } })`
- M05 F1 middleware đã check token_version match → tự động reject token cũ
- UC009 v2 update BR-009-03

---

### Q4: "Logout all devices" feature

**UC cũ (Alt 4.a UC009):** Có flow "logout all devices" — hủy mọi tokens của user
**Code thực tế:** KHÔNG có endpoint này

**Use case:** User nghi ngờ tài khoản bị lộ, muốn force logout mọi nơi
**Implementation:** Tăng `token_version` → mọi token cũ invalid

**Em recommend:** Implement `POST /auth/logout-all` cho admin (đơn giản với pattern R1)

**Anh decision:** ☑ **Em recommend** — add `POST /auth/logout-all` endpoint.

**Impact:**
- Same logic as Q3 (token_version increment), khi admin nghi ngờ tài khoản bị lộ
- UC009 v2 add Alt flow 4.a as confirmed

---

### Q5: Session storage frontend (localStorage vs cookie)

**Hiện tại:** localStorage (M01 audit)
**Em recommend:** httpOnly cookie (XSS protection) — security guardrails rule

**Trade-off:**

| Storage | XSS | CSRF | Complexity |
|---|---|---|---|
| localStorage | 🔴 Vulnerable | 🟢 Safe | Đơn giản |
| httpOnly cookie | 🟢 Safe | 🔴 Vulnerable | Cần CSRF token (M05 F5 đã flag) |

**Em recommend:** **Cookie + CSRF** vì admin web có ACL elevated (admin role) — bảo vệ XSS quan trọng hơn.

**Anh decision:** ☑ **Em recommend** — httpOnly cookie + CSRF token.

**Impact:**
- BE: refactor JWT response từ body → `Set-Cookie: token=...; HttpOnly; Secure; SameSite=Strict`
- BE: thêm CSRF middleware (vd `csurf` hoặc double-submit cookie pattern)
- FE: remove `localStorage.setItem('token', ...)`, dependency trên cookie auto-send
- FE: include CSRF header in mutating requests
- M05 F5 đã flag CSRF gap → elevate to P1 (depends on cookie migration)

---

### Q6: Register endpoint — role enum

**UC cũ:** Không nói rõ admin có thể tạo role gì
**Code thực tế:** Admin có thể tạo user role = `'user'` only (M03 F6 — controller check). Nhưng `validate()` enum cho phép `'admin'` (route allows).

**Question:** Anh có muốn admin tạo admin khác qua API không?

**Em recommend:** **Không** — admin chỉ tạo qua DB seed/manual. UC + validate phải align: role enum = `['user']` only.

**Anh decision (clarified 2026-05-12):** 🔄 **Override** — `POST /auth/register` là **dev tool / bootstrap**, không phải production user-creation. Dùng để admin tạo admin khác qua Swagger.

**Implication:**
- Endpoint đã có `authenticate + requireAdmin` middleware → chỉ admin existing call được → security đủ
- Code hiện tại (`auth.controller.js:46-48`) hardcode `if role === 'admin' throw forbidden` → **OVER-PROTECTION**, sai intent
- Phase 4: **REMOVE** hardcoded block trong controller
- Validate enum keep `['user', 'admin']` (UC cho phép admin tạo cả 2)
- Production user creation thuộc UC022 scope (qua endpoint `POST /admin/users`), không qua `/auth/register`

**Impact trên Phase 1 audit:**
- M03 F6 finding ("register block admin") **REVERT** — code nên cho phép, em đã sai đề xuất
- Thêm Phase 4 task: REMOVE hardcoded role check trong `auth.controller.js:46-48`

---

### Q7: Password reset email — token in URL

**Hiện tại:** Reset link contains token in URL query string (em assume từ pattern email service)
**Risk:** URL trong email server log, browser history, referer header

**Em recommend:** **Keep** với conditions: TTL ≤ 1h + single-use (verify trong DB). Phase 4 audit verify.

**Anh decision:** ☑ **KEEP** — reset URL token pattern.

**Note:** Q1 đã chốt drop admin forgot-pwd, nên Q7 chỉ áp dụng cho mobile (UC003 mobile wave).

**Impact:** Phase 4 verify TTL ≤ 1h + single-use cho mobile flow only. Admin BE remove email logic.

---

### Q8: Hide/show password icon (UC001 NFR)

**UC cũ:** Hiển thị/ẩn pwd khi click icon "con mắt"
**Code thực tế:** Frontend behavior — Track 1B chưa audit. Em assume có (standard pattern).

**Em recommend:** Keep — common UX, low effort.

**Anh decision:** ☑ **KEEP** — hide/show password icon. Track 1B (FE audit) confirm code có.

---

### Q9: 2FA / MFA cho admin

**UC cũ:** Không mention
**Industry standard 2026:** Admin panel cần 2FA (TOTP via Google Authenticator)

**Em recommend:** **Add UC mới** (UC0XX_Admin_2FA) — defer Phase 5 / out-of-scope đồ án 2

**Anh decision:** ☑ **SKIP** — out of scope đồ án 2. KHÔNG tạo UC stub.

**Impact:** No new UC. AUTH module HealthGuard scope cuối = UC001 v2 + UC009 v2 only.

---

## 🆕 Features anh nghĩ ra

_(anh không add thêm gì trong wave AUTH)_

---

## ❌ Features anh muốn DROP

- **Admin forgot/reset/change password endpoints** (Q1 Option A) — admin password reset qua DB manual.
- **2FA** (Q9) — out of scope đồ án 2.

---

## 📊 Drift summary (em fill sau anh decide)

### UC delta (CONFIRMED)

| UC cũ | Status | UC mới |
|---|---|---|
| UC001 Login | **Update** Q2 (lockout layers), Q5 (cookie admin), confirm BR-001-01..05 | UC001 v2 |
| UC009 Logout | **Update** Q3 (token version), Q4 (logout-all) | UC009 v2 |
| UC003 ForgotPwd | **NO CHANGE** Q1 keep mobile-only | (no update) |
| UC004 ChangePwd | **NO CHANGE** Q1 keep mobile-only | (no update) |
| UC005 Profile | Defer (mobile-scoped, wave 5) | — |
| UC-NEW Admin 2FA | **REJECTED** Q9 SKIP | (none) |

### Code impact (CONFIRMED)

| Phase 1 finding | After Phase 0.5 | Phase 4 task |
|---|---|---|
| M01 F1 CORS reflection | ✅ Still valid | P0 (~30 min) |
| M01 F2 No helmet | ✅ Still valid | P1 (~30 min) |
| M03 F6 Register admin enum | Q6 **REVERT** — finding sai, register ALLOW admin (dev tool) | Remove hardcode block in controller (~5 min) |
| M03 F7 Auth no validate() | ✅ Still valid | P2 (~30 min) |
| M04 F1 HG-001 | Separate (HEALTH module) | P0 (~4h) |
| M05 F5 CSRF gap | **Q5 elevates** → P1 (cookie migration depends) | P1 (~2h CSRF middleware) |
| **NEW** Q1 Drop 3 admin pwd endpoints | **REMOVE** code | P2 (~1h cleanup) |
| **NEW** Q3 token_version increment on logout | Add to logoutUser() | P1 (~30 min) |
| **NEW** Q4 logout-all endpoint | Implement | P2 (~2h) |
| **NEW** Q5 cookie + CSRF migration (BE+FE) | Refactor JWT response | P1 (~6-8h coord) |
| **NEW** Admin pwd reset script | `npm run admin:reset-pwd` | P3 (~1h) |

---

## 📝 Anh's decisions log (CONFIRMED 2026-05-12)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-AUTH-01 | UC003/UC004 scope admin | **A. Drop admin endpoints** | Admin reset qua DB manual, giảm attack surface email |
| D-AUTH-02 | Lockout granularity | **Cả 2** (per USER + IP rate limit) | Defense-in-depth |
| D-AUTH-03 | Token version on logout | **Em recommend** (increment) | Immediate invalidation, leverage R1 pattern |
| D-AUTH-04 | Logout-all endpoint | **Em recommend** (add) | User control khi nghi ngờ lộ token |
| D-AUTH-05 | Cookie + CSRF | **Em recommend** (cookie httpOnly + CSRF) | XSS protection > CSRF complexity |
| D-AUTH-06 | Register endpoint scope | **Override**: Register là dev/bootstrap tool, allow admin tạo admin (đã protect bằng requireAdmin middleware) | Production user-creation thuộc UC022 PATCH; register chỉ dùng cho dev/admin bootstrap |
| D-AUTH-07 | Password reset URL | **Keep** (mobile only) | Q1 đã drop admin, scope còn lại ở mobile |
| D-AUTH-08 | Hide/show password icon | **Keep** | Standard UX |
| D-AUTH-09 | 2FA scope | **SKIP** | Out of scope đồ án 2 |

---

## 🔁 Impact on Phase 4 fix plan (CONFIRMED)

### Phase 4 AUTH backlog

| # | Task | Priority | Effort |
|---|---|---|---|
| 1 | M01 F1 CORS fix (Track 1A finding) | P0 | 30 min |
| 2 | M01 F2 add helmet | P1 | 30 min |
| 3 | Cookie + CSRF migration BE+FE (D-AUTH-05) | P1 | 6-8h |
| 4 | token_version increment on logout (D-AUTH-03) | P1 | 30 min |
| 5 | M03 F7 auth.routes use validate() | P2 | 30 min |
| 6 | M03 F6 REVERT: remove hardcoded block `role==='admin'` in auth.controller.js (Q6) | P2 | 5 min |
| 7 | Drop admin forgot/reset/change endpoints (D-AUTH-01) | P2 | 1h cleanup |
| 8 | logout-all endpoint (D-AUTH-04) | P2 | 2h |
| 9 | Admin pwd reset CLI script (D-AUTH-01) | P3 | 1h |
| 10 | Update UC001 + UC009 v2 | P3 doc | 1h |

**AUTH module total Phase 4 effort:** ~13-15h.

### Tasks REJECTED (Phase 0.5 strip ra khỏi backlog)

- ~~UC003/UC004 multi-platform rewrite~~ (Q1 → mobile-only)
- ~~Admin 2FA implementation~~ (Q9 → SKIP)

---

## Cross-references

- UC001 cũ: `Resources/UC/Authentication/UC001_Login.md`
- UC009 cũ: `Resources/UC/Authentication/UC009_Logout.md`
- Phase 1 audit: `tier2/healthguard/M01_bootstrap_audit.md`, `M03_controllers_audit.md`, `M04_services_audit.md`, `M05_middlewares_audit.md`
- ADR-004: API prefix standardization
- Bug HG-001: separate from AUTH but in same Phase 4 sprint
