# Intent Drift Review — `<REPO> / <MODULE>`

**Status:** 🔴 Draft (chờ anh react) | 🟡 In dialogue | 🟢 Confirmed
**Repo:** `<repo-path>`
**Module:** `<MODULE_NAME>`
**Related UCs (old):** `<UC001, UC009, ...>` or `N/A`
**Phase 1 audit ref:** `<tier2/.../M0X_audit.md>` or `N/A (not audited yet)`
**Date prepared:** YYYY-MM-DD
**Date confirmed:** YYYY-MM-DD

---

## 🎯 Mục tiêu doc này

Capture **anh-now's true intent** cho module này, rebuild UC nếu cần. UC cũ chỉ là **memory aid** (em present summary, anh không bắt đọc full).

Output: New UC file (overwrite cũ) + decisions log dưới đây.

---

## 📚 Memory aid — UC cũ summary

> Em present 5-10 dòng/UC. Anh decide quick: keep / update / drop.

### UC001 - Login (anh đã biết, em ko nhắc lại)

**Cũ định nghĩa (5 dòng tóm tắt):**
- Actor: Patient, Caregiver, Admin
- Main flow: email/pwd → JWT → home
- Lockout: 5 lần fail → 15 phút
- Forgot password link → UC003
- Validation: email format, password ≥ 8 chars

**Status decision:**
- ☐ Keep as-is (UC cũ đủ dùng)
- ☐ Update (chi tiết trong section dưới)
- ☐ Drop
- ☐ Rewrite from scratch

### UC009 - Logout

**Cũ định nghĩa:**
- Actor: Patient, Caregiver, Admin
- Main flow: click logout → invalidate token → redirect login

**Status decision:**
- ☐ Keep / ☐ Update / ☐ Drop / ☐ Rewrite

---

## 🔧 Code state — what currently exists

> Em present từ Phase 1 audit, 5-10 dòng.

**Endpoints (HealthGuard BE):**
- `POST /api/v1/admin/auth/login` ✅
- `POST /api/v1/admin/auth/logout` ✅
- `GET /api/v1/admin/auth/me` ✅
- `POST /api/v1/admin/auth/forgot-password` ✅
- ... (rest)

**Behavior summary:**
- bcrypt salt 10
- Lockout 5x/15min implemented (`auth.service.js:73-75`)
- Audit log every login attempt
- JWT token_version for revocation
- Session: localStorage on frontend

**Phase 1 audit verdict:** M01-M08 avg 11.9/15, AUTH-related modules 🟢 mature

---

## 💬 Anh react block

> Anh trả lời inline. Em đề xuất default rồi — anh chỉ tick override nếu khác.

### Q1: Lockout strategy
**Hiện tại:** 5 fail → 15 phút lock
**Em recommend:** Keep (security best practice + match UC cũ)
**Anh decision:**
- ☑ Keep
- ☐ Override: ___

### Q2: Lockout message detail
**Hiện tại:** "Tài khoản đang bị tạm khóa do nhập sai mật khẩu nhiều lần. Vui lòng thử lại sau."
**Em recommend:** Add time remaining → "Tài khoản đang bị khóa. Thử lại sau X phút."
**Pros:** User experience tốt hơn
**Cons:** Lộ thông tin lockout duration cho attacker (minor)
**Anh decision:**
- ☐ Keep
- ☑ Em recommend (show time)
- ☐ Override: ___

### Q3: Session storage frontend
**Hiện tại:** localStorage
**Em recommend:** httpOnly cookie (XSS protection — security rule)
**Trade-off:** Cookie cần CSRF token (M05 F5 đã flag)
**Anh decision:**
- ☐ Keep localStorage (XSS risk accepted vì admin web ko nhập user content)
- ☑ Em recommend (cookie + CSRF)
- ☐ Override: ___

### Q4: (module-specific question)

---

## 🆕 Features mới anh nghĩ ra (nếu có)

> Mục này anh chủ động list — em không recommend.

- (anh add ở đây)

---

## ❌ Features anh muốn DROP

> Code có nhưng anh không muốn nữa.

- (anh add ở đây)

---

## 📊 Drift summary (em fill sau anh decide)

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC001 Login | Updated (Q2 changes) | UC001 v2 |
| UC009 Logout | Keep | UC009 v1 |
| (new UC if added) | — | UC0XX |

### Code impact

| Phase 1 finding | Re-evaluate? | Phase 4 task |
|---|---|---|
| HG-001 (alerts unread) | Still valid | Confirmed P0 |
| M05 F5 (CSRF gap) | NOW REQUIRED (Q3 decision) | New P1 task |
| M03 F1 (style inconsistency) | Still valid | P3 keep |

---

## 📝 Anh's decisions log

| ID | Item | Decision | Date | Rationale |
|---|---|---|---|---|
| D-AUTH-01 | Lockout time display | Em recommend accepted | YYYY-MM-DD | UX > minor leak |
| D-AUTH-02 | Session cookie | Em recommend accepted | YYYY-MM-DD | XSS protection |
| ... | ... | ... | ... | ... |

---

## 🔁 Impact on Phase 4 fix plan

| Phase 4 task | Status |
|---|---|
| HG-001 fix (4h) | Confirmed |
| D-AUTH-02: cookie migration (6h) | **New task added** |
| (any task dropped) | — |

---

## Cross-references

- UC mới (output): `PM_REVIEW/Resources/UC/Authentication/UC001_Login_v2.md`
- Phase 1 audit: `tier2/healthguard/M0X_audit.md`
- ADR (nếu Phase 0.5 sinh): `ADR/NNN-<topic>.md`
