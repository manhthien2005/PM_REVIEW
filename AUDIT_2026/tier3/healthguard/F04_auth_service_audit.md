# Deep-dive: F04 — auth.service.js (R3 pattern + cookie migration readiness)

**File:** `HealthGuard/backend/src/services/auth.service.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 2 (Security foundation)

## Scope

Single file `auth.service.js` (~360 LoC, 6 public methods + 1 private helper):
- `loginUser({email, ...}, ipAddress, userAgent)` — lines 24-141. R3 reference pattern: email validate → user lookup → lockout check → bcrypt compare → audit log → JWT sign với token_version.
- `logoutUser(userId, ipAddress, userAgent)` — lines 143-152. Audit log only, không increment token_version (drift D-AUTH-03 Phase 4 fix).
- `registerUser({...}, adminId, ipAddress, userAgent)` — lines 159-199. Admin-only user creation, role enum restricted (drift D-AUTH-06 revert pending).
- `requestPasswordReset({email}, ipAddress, userAgent)` — lines 205-271. Email enumeration protection + JWT reset token 15min + hash stored.
- `resetPassword({token, newPassword, confirmPassword}, ipAddress, userAgent)` — lines 277-318. Transaction atomic (users + password_reset_tokens).
- `changePassword({userId, ...}, ipAddress, userAgent)` — lines 325-371. Stricter admin rule + token_version increment.
- `_logAudit({user_id, action, ...})` — lines 380-398. Helper DRY.

**Out of scope:** JWT middleware consumer (`middlewares/auth.js` F05), controller validation layer (M03 Phase 1), route-level rate limiter (M05 Phase 1), email template (M07 Phase 1 covered).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | R3 reference pattern complete: email regex, lockout 5×15min per-user, bcrypt salt 10, transaction atomic reset, token_version increment on credential change (reset + change). 6 methods đều có defensive null check + input validate boundary. |
| Readability | 3/3 | Section divider comments per method, centralized regex top file (EMAIL_REGEX/PHONE_REGEX/VIETNAMESE_NAME_REGEX), _logAudit helper DRY. 360 LoC với 6 methods → average 60 LoC/method scannable. |
| Architecture | 3/3 | Separation of concern đúng: service layer pure business logic, không import Express req/res. Regex patterns centralized top file. Helper `_logAudit` internal wrap try/catch swallow audit log error (không block flow chính). |
| Security | 2/3 | R3 pattern mature. Gap: logoutUser KHÔNG increment token_version (drift D-AUTH-03), register role restriction quá strict (drift D-AUTH-06). |
| Performance | 3/3 | DB query indexed (email unique, user_id PK). Bcrypt salt 10 ~100ms acceptable. Transaction atomic 2 queries reset. Sequential await cần thiết (lookup → compare → update). |
| **Total** | **14/15** | Band: **🟢 Mature** (R3 reference quality) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M04 findings (all confirmed):**

1. ✅ **R3 reference pattern** — confirmed lines 24-141 login flow: 5-fail lockout 15min per-user (auth.service.js:79-101), audit log every success + failure branch, email regex check boundary, bcrypt.compare hashed input. Match drift D-AUTH-02 layer 1 design.
2. ✅ **Email enumeration protection** (line 264-268) — `requestPasswordReset` return same success message bất kể user tồn tại hay không.
3. ✅ **Token version increment on credential change** (lines 308-314, 362-368) — invalidate active sessions ngay khi credential đổi.
4. ✅ **Register role restriction** (lines 176-178) — `allowedRoles = ['user']` reject 'admin'. Drift D-AUTH-06 quyết định REVERT.

**Phase 1 M04 gaps confirmed:**

5. ✅ **logoutUser không increment token_version** (lines 143-152) — drift D-AUTH-03 Phase 4 fix (~5 min).

**Phase 3 new findings (beyond Phase 1 macro):**

6. ⚠️ **Reset token JWT chứa sensitive payload** (line 233-239) — JWT encode `{userId, email, type: 'password_reset'}` với 15 min expiry. Email trong token payload plaintext (base64 encoded JWT). Mitigation hiện có: token hash stored DB → 1-time-use enforced. Priority P3 — consider opaque token Phase 5+.
7. ⚠️ **Race condition `failed_login_attempts`** (lines 79-91) — read user row → bcrypt compare → update. Giữa read + update có window. Minor probability nhưng possible under load. Priority P3.
8. ⚠️ **`logoutUser` không verify user exists** (line 148) — `_logAudit({ user_id: userId })` trusted cho userId từ JWT decoded. Defensive check sẽ tránh audit log với ghost user_id. Priority P3.
9. ⚠️ **Reset token TTL 15 min không tunable** (line 236) — hardcode string `'15m'`. Should env variable `RESET_TOKEN_TTL`. Priority P3.
10. ⚠️ **Hardcoded bcrypt salt rounds = 10** (lines 158, 295, 367) — fixed 3 chỗ. Should constant top file. Priority P3.
11. ⚠️ **`registerUser` set `is_verified: true`** (line 194) — admin-created users tự động verified (skip email verification). Chấp nhận được cho admin tool nhưng khác flow mobile self-register. Priority P3 doc.

### Correctness (3/3)

- ✓ **Email format validate** (line 25-27, 164-166, 209-211) — regex check trước mọi flow; reject malformed email → 400.
- ✓ **Email normalize** (line 31, 169, 212, 305) — `toLowerCase().trim()` trước DB lookup → case-insensitive + no trailing whitespace.
- ✓ **Lockout mechanism** (lines 79-91):
  - Read `user.failed_login_attempts` + `user.locked_until`.
  - Check `locked_until > now` → throw 423 Locked.
  - Invalid compare → increment `failed_login_attempts`, nếu >=5 → set `locked_until = now + 15min`.
  - Success login → reset counter + unlock.
- ✓ **Transaction atomic reset** (lines 306-318) — `prisma.$transaction([users.update, password_reset_tokens.update])` — atomic.
- ✓ **Confirm check** (lines 252-255, 328-331) — defense tại service layer.
- ✓ **New ≠ old check** (lines 285-288, 355-358) — prevent reuse exact same value.
- ✓ **Stricter admin rule** (lines 346-349) — `validatePasswordStrength(newPassword, isAdmin=true)`.
- ✓ **Token version increment on reset + change** (lines 308-314, 362-368) — invalidate active sessions.
- ✓ **`_logAudit` swallow error** (line 393-397) — audit log failure không throw.

### Readability (3/3)

- ✓ Section divider comments đẹp (`// ═══════════════════════════════════════════════════════` + title) → reader scan 6 flows dễ.
- ✓ Regex centralized top file (lines 8-11) — `EMAIL_REGEX`, `PHONE_REGEX`, `VIETNAMESE_NAME_REGEX`.
- ✓ Vietnamese error messages match convention.
- ✓ JSDoc top file + method headers — intent rõ.
- ✓ `_logAudit` helper DRY — 10+ call sites.
- ⚠️ **P3 — Emoji trong audit log** (`_logAudit:394`) — rule cấm emoji trong code.

### Architecture (3/3)

- ✓ **Separation of concern**: service layer pure business.
- ✓ **Regex top file**: validation logic centralized.
- ✓ **`_logAudit` helper internal**: DRY pattern.
- ✓ **Transaction pattern**: atomic guarantee.
- ✓ **DI-friendly**: inject `prisma`, `env`, `bcrypt`, `jwt`, `sendPasswordResetEmail`.
- ⚠️ **P2 — Sensitive data handling centralized** — `password_hash`, `verification_code`, `reset_code` đều thao tác trong file này. Raw `verification_code` + `reset_code` store plaintext VARCHAR(6) trong schema (M06 flag). Service đóng vai trò defensive nhưng depend schema hash migration. Priority P2 per M06 finding.

### Security (2/3)

- ✓ **Bcrypt salt 10** — industry-standard cost 2026.
- ✓ **Lockout 5×15min per-user**.
- ✓ **Audit log every auth branch**.
- ✓ **Token version increment on credential change**.
- ✓ **Reset token hash stored**.
- ✓ **Email enumeration protection**.
- ✓ **Confirm check + new ≠ old + stricter admin rule** — defense-in-depth.
- ✓ **`_logAudit` swallow error**.
- ⚠️ **P1 — `logoutUser` KHÔNG increment token_version** (lines 143-152):
  - Pattern R1 middleware (F05) ready check token_version mismatch → nếu admin bump version on logout → token cũ invalid ngay.
  - Hiện tại: logout chỉ audit log, token cũ vẫn valid đến JWT expiry (8h).
  - Use case: user nghi ngờ tài khoản bị lộ → logout → token cũ vẫn dùng được 8h → attacker có thời gian.
  - Fix (per drift D-AUTH-03): thêm `await prisma.users.update({ where: { id: userId }, data: { token_version: { increment: 1 } } })` trước `_logAudit`. ~5 min fix.
  - Priority P1 per drift.
- ⚠️ **P2 — Register role restriction quá strict** (lines 176-178):
  - `allowedRoles = ['user']` reject 'admin'.
  - Drift AUTH D-AUTH-06 quyết định REVERT.
  - Controller `auth.controller.js:46-48` inline block.
  - Fix (per drift D-AUTH-06): remove restriction ở cả service + controller. ~5 min cả 2 chỗ.
  - Priority P2 per drift.
- ⚠️ **P3 — JWT reset token payload leak email** — Priority P3 opaque token Phase 5+.
- ⚠️ **P3 — Race condition `failed_login_attempts`** — Priority P3.

### Performance (3/3)

- ✓ **DB query indexed**: `users.email` unique, `users.id` PK → O(log n) lookup.
- ✓ **Bcrypt salt 10** ~100ms hash/verify — acceptable 2026.
- ✓ **Transaction 2-query** reset flow — 1 roundtrip commit.
- ✓ **Sequential await** cần thiết (lookup → compare → update).
- ✓ **_logAudit swallow error** không block main flow.
- ⚠️ **P3 — Bcrypt cost 10 Phase 5+ upgrade** — khi scale >1000 concurrent login/min → consider cost 12 + queue.

## Recommended actions (Phase 4)

### P1 — drift D-AUTH-03

- [ ] **P1** — `logoutUser` (lines 143-152): thêm increment token_version trước `_logAudit` (~5 min).

### P2 — drift D-AUTH-06 + M06 depend

- [ ] **P2** — `registerUser` (lines 176-178): remove `allowedRoles = ['user']` restriction. Combine với controller remove (~5 min cả 2).
- [ ] **P2** — Depend M06 fix: hash `verification_code` + `reset_code` trước store.

### P3 — hardening

- [ ] **P3** — Extract `BCRYPT_SALT_ROUNDS = 10` constant top file (3 chỗ dùng) (~5 min).
- [ ] **P3** — Reset token TTL env `RESET_TOKEN_TTL='15m'` default (~10 min).
- [ ] **P3** — Replace emoji trong `_logAudit:394` (~2 min).
- [ ] **P3** — Opaque reset token Phase 5+ (~2h refactor).
- [ ] **P3** — Document UC001 v2 admin-created user vs mobile self-register distinction (~30 min doc).
- [ ] **P3** — `logoutUser` verify user exists trước audit log (~5 min defensive).

## Out of scope (defer)

- 2FA / MFA cho admin — drift AUTH D-AUTH-09 SKIP cho đồ án 2.
- Cookie migration BE side — drift D-AUTH-05, cross-file effort (~6-8h), cover trong F05 + F09 + F12 + M01 CORS.
- Phone number regex update cho +84 prefix — Phase 5+ i18n.
- Email send retry logic — Phase 5+ ops.

## Cross-references

- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — R3 reference + 2 gaps flagged (D-AUTH-03, D-AUTH-06).
- Phase 1 M05 audit: [tier2/healthguard/M05_middlewares_audit.md](../../tier2/healthguard/M05_middlewares_audit.md) — F05 middleware consume JWT từ F04 sign.
- Phase 1 M06 audit: [tier2/healthguard/M06_prisma_schema_audit.md](../../tier2/healthguard/M06_prisma_schema_audit.md) — verification_code + reset_code schema flag.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — D-AUTH-01..09 full decisions matrix.
- ADR-005: [ADR/005-internal-service-secret-strategy.md](../../../ADR/005-internal-service-secret-strategy.md) — cross-repo internal auth contract.
- F05 `middlewares/auth.js` deep-dive — JWT verify consumer, token_version mismatch check.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** R3 reference pattern file — 14/15 Mature band. Chỉ 1 P1 gap (D-AUTH-03 token_version on logout, ~5 min fix) + 1 P2 gap (D-AUTH-06 register role, ~5 min fix). Cookie migration (D-AUTH-05) cross-file effort cover bên ngoài. Post Phase 4 fix → 15/15.
