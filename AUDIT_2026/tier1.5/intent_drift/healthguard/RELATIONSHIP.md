# Intent Drift Review — `HealthGuard / RELATIONSHIP`

**Status:** � Confirmed v3 (Q1-Q6 anh chọn theo em recommend; Q5+Q6 NEW post-cross-repo-verify 2026-05-12 — schema dư columns + BR-022-07 admin bypass clarify; 4 add-ons drop; cross-doc impact: UC022 v2 cần update 6 điểm: D-USERS-05 nested + BR-022-12/13/14 new + BR-022-07 wording update)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** RELATIONSHIP (Linked Profiles — quan hệ chăm sóc giữa patient + caregiver)
**Related UCs (old):** UC022 v2 Manage Users (Alt 5.f, 5.g, 5.h linked profiles)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md` (D-007 mount conflict)
**Date prepared:** 2026-05-12
**Question count:** 6 (route convention drift + UC missing rules + Q5 schema dư columns + Q6 BR-022-07 admin bypass clarify)

---

## 🎯 Mục tiêu

Capture intent cho RELATIONSHIP module. UC riêng KHÔNG CÓ, nhưng UC022 v2 đã mention sub-flows (Alt 5.f, 5.g, 5.h). Module hiện như sub-feature của ADMIN_USERS, nhưng có routes file riêng + service riêng.

---

## 📚 UC tham chiếu (UC022 v2 sub-flows)

- **Alt 5.f Linked Profiles management** (tab "Quan hệ theo dõi" trong user detail page)
- **Alt 5.g Set Primary**: `PATCH /api/v1/relationships/:id` set `is_primary=true`, unset primary cũ
- **Alt 5.h Delete relationship**: `DELETE /api/v1/relationships/:id` + audit log
- **BR-022-06**: Mỗi patient chỉ tối đa 1 `is_primary=true` (auto unset primary cũ khi set mới)
- **BR-022-07**: User chỉ xem được sức khỏe của user khác nếu có `user_relationships` link
- **D-USERS-05**: Linked Profiles BE independent endpoints + FE embed nested UX

**UC022 v2 endpoint pattern (D-USERS-05):**
```
GET    /api/v1/relationships?user_id=X       (flat, query param)
POST   /api/v1/relationships                 (flat)
PATCH  /api/v1/relationships/:id             (flat)
DELETE /api/v1/relationships/:id             (flat)
```

---

## 🔧 Code state — verified

### Routes (`relationship.routes.js`) — 5 endpoints

```
authenticate + requireAdmin + relationshipsLimiter (100/min)

# Mount path: /api/v1/users/* (sub-path của users!)

GET    /api/v1/users/relationships/search                Tìm user để link
GET    /api/v1/users/:userId/relationships               List relationships của user
POST   /api/v1/users/:userId/relationships               Create
PUT    /api/v1/users/:userId/relationships/:id           Update (verb PUT, không PATCH)
DELETE /api/v1/users/:userId/relationships/:id           Delete
```

### Validation rules
- `target_user_id`: required number
- `relationship_type`: enum `[family, friend, doctor, nurse, other]`
- `is_primary`, `can_view_vitals`, `can_receive_alerts`, `can_view_location`: boolean

### Service highlights (verified)

**✅ BR-022-06 ENFORCED:** unset primary cũ khi set mới (line 102-108 create, 145-151 update).

**✅ Audit log đầy đủ:**
- `relationship.created` với patient_id + caregiver_id + relationship_type
- `relationship.updated` với changes diff
- `relationship.deleted` với patient_id + caregiver_id

**✅ Validation:**
- Self-link prevention (patientId === caregiverId throw error)
- Duplicate relationship check (existing row throw conflict)

**✅ Permission defaults (line 116-118 create):**
- `can_view_vitals: true` (mặc định cho phép xem vitals)
- `can_receive_alerts: true` (mặc định nhận alerts)
- `can_view_location: false` (mặc định KHÔNG xem location — privacy stricter)

### 🟡 Drift vs UC022 v2

1. **Route pattern drift (D-USERS-05 conflict):**
   - UC v2 chốt **flat** pattern: `GET /api/v1/relationships?user_id=X`, `PATCH /api/v1/relationships/:id`
   - Code có **nested** pattern: `GET /api/v1/users/:userId/relationships`, `PUT /api/v1/users/:userId/relationships/:id`
   - → 2 dimensions drift: path nested vs flat + verb PUT vs PATCH

2. **HTTP verb:** UC v2 dùng `PATCH` cho update, code dùng `PUT` (cũng style của HealthGuard codebase nhìn chung — DEVICES.md cũng có duplicate PUT).

3. **`relationship_type` enum:** UC v2 không define list enum. Code có `[family, friend, doctor, nurse, other]` → drift forward.

4. **Permission defaults:** UC v2 không define defaults. Code có:
   - `can_view_vitals: true`
   - `can_receive_alerts: true`
   - `can_view_location: false` (privacy-stricter)

### 🟡 Post-cross-repo-verify findings (2026-05-12):

5. **Schema dư 3 columns admin BE không sử dụng** (`02_create_tables_user_management.sql:67-77`):
   - **`status` VARCHAR(20) DEFAULT 'pending'** — implies workflow approval (pending→active), nhưng admin BE service không set field. Kết quả: relationship admin tạo = `status='pending'` (DB default) mặc dù logic intent là `active`. **Dead code path**.
   - **`primary_relationship_label` VARCHAR(100)** — labelled primary ("Vợ", "Con trai") — admin BE không expose.
   - **`tags` JSONB** — flexible tagging system — admin BE không expose.
   - → UC v2 quyết định: keep schema + document Phase 5+ planned features, hay drop columns trong migration v3?

6. **BR-022-07 admin BE KHÔNG enforce (NOT a bug — clarify needed):**
   - UC cũ BR-022-07: "User chỉ xem được sức khỏe của user khác nếu có `user_relationships` link"
   - Mobile BE (`health_system`) ENFORCE: `check_user_has_access(...) and current_user.role != 'admin'` → caregiver phải có relationship; admin bypass.
   - Admin BE `health.service.js getPatientHealthDetail` KHÔNG check relationship — admin role bypass design intent.
   - → UC v2 cần clarify BR-022-07 áp dụng non-admin only; admin bypass với audit log (consistent với HEALTH Q5 D-HEA-05).

**🟢 Minor observations:**

- **`relationship_type` default `'other'`** (line 114): nếu admin không truyền type → 'other'. UC v2 BR-022-12 cần add default value.
- **KHÔNG check `is_active`** khi create (line 88-91 chỉ check `deleted_at: null`): admin có thể tạo relationship với locked user. Minor UX concern.

**✅ Cross-repo verify GOOD:**

- **Mobile BE `relationship_service.py:580-625`** dùng `risk_level == "critical"` / `"medium"` — **3 levels chuẩn**, KHÔNG có Q7 enum bug (khác HEALTH/DASHBOARD).
- **EMERGENCY `emergency.service.js:395-401`** join `user_relationships` cho `linkedContacts` — cross-module dependency clean.

---

## 💬 Anh react block

> 6 câu (Q5+Q6 add sau post-cross-repo-verify 2026-05-12) — module nhỏ với route convention drift + schema dư columns + admin bypass clarify.

---

### Q1: Route pattern drift — flat (UC v2) vs nested (code)

**Conflict:**
| | Pattern | Example |
|---|---|---|
| **UC022 v2 D-USERS-05** | Flat | `GET /api/v1/relationships?user_id=X`<br>`PATCH /api/v1/relationships/:id` |
| **Code hiện tại** | Nested | `GET /api/v1/users/:userId/relationships`<br>`PUT /api/v1/users/:userId/relationships/:id` |

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| **A. Refactor code → flat (UC v2)** | Tuân spec; cleaner REST | Cross-file change BE+FE; risky regression; effort ~3h |
| **B. Update UC v2 → nested (code-current)** | Zero code change; nested REST cũng valid | Đi ngược spec chốt 1 giờ trước; phải re-edit UC022 v2 |
| **C. Keep both (BE expose both endpoints)** | Backward compat | Code complexity tăng; duplicate logic |

**Em recommend:**
- **Option B — Update UC022 v2 D-USERS-05 sang nested pattern** + flag note. Lý do:
  - Code already deployed + FE consume nested URL
  - Refactor sang flat = risky regression cho 1 module nhỏ
  - Nested pattern cũng valid REST (sub-resource semantics): "relationships của user X"
  - UC vừa chốt 1 ngày trước → cập nhật UC dễ hơn refactor code

**Anh decision:**
- ✅ **Em recommend (Option B — update UC v2 sang nested)** ← anh CHỌN
- ☐ Option A — refactor code sang flat (~3h cross-file)
- ☐ Option C — keep both endpoints (zero break + cleaner future migration)
- ☐ Khác: ___

**Cross-doc impact:** UC022 v2 D-USERS-05 cần update sang nested pattern + UC022 v2 Alt 5.f/5.g/5.h phải ghi nested URLs. Em sẽ flag trong follow-up actions.

---

### Q2: HTTP verb — PUT vs PATCH

**Drift:** UC v2 ghi `PATCH`, code dùng `PUT`. Đây là pattern chung của HealthGuard codebase (DEVICES, ADMIN_USERS cũng có PUT + PATCH duplicate).

**Em recommend:**
- **Add PATCH alias** (giữ PUT cho backward compat) + document UC v2 verb chấp nhận cả 2
- **Phase 4 future cleanup**: REST clean adopt PATCH-only (cross-module convention, không riêng RELATIONSHIP)
- Hoặc: nếu Q1 chọn Option B → UC v2 cũng align với PUT current → no drift

**Anh decision:**
- ✅ **Em recommend (add PATCH alias, document UC v2 chấp nhận cả 2 verbs)** ← anh CHỌN
- ☐ Migrate sang PATCH-only Phase 4 (cross-module cleanup, ~1h)
- ☐ Keep PUT-only (BR-022-11 REST clean conflict)
- ☐ Khác: ___

---

### Q3: `relationship_type` enum scope

**Current:** Code có `[family, friend, doctor, nurse, other]`. UC v2 không define list.

**Question:** Anh có muốn add/remove relationship types không?

**Use cases:**
- `family` — gia đình
- `friend` — bạn bè
- `doctor` — bác sĩ riêng
- `nurse` — y tá / điều dưỡng
- `other` — khác

**Em recommend:**
- **Keep current enum + document trong UC v2 BR-022-12** "relationship_type enum: family/friend/doctor/nurse/other"
- Phase 5+ có thể add `caregiver`, `spouse`, `child` nếu UX feedback cần

**Anh decision:**
- ✅ **Em recommend (keep current enum, document UC v2)** ← anh CHỌN
- ☐ Add types: `caregiver`, `spouse`, `child` (granular relations)
- ☐ Remove types: `friend` (không relevant cho health monitoring)
- ☐ Khác: ___

---

### Q4: Permission defaults

**Code defaults (when create relationship):**
- `can_view_vitals: true` (mặc định CHO PHÉP xem)
- `can_receive_alerts: true` (mặc định nhận alerts)
- `can_view_location: false` (mặc định **KHÔNG** xem location — privacy stricter)

**Question:** UC v2 ratify defaults này hay anh muốn defaults khác?

**Em recommend:**
- **Keep current** + document trong UC v2 BR-022-13 "Permission defaults khi create: vitals=true, alerts=true, location=false (privacy default-deny cho location vì GPS sensitive)"
- Admin manual toggle nếu muốn override

**Anh decision:**
- ✅ **Em recommend (keep current defaults, document UC v2)** ← anh CHỌN
- ☐ Stricter: vitals + alerts + location ALL default-false (admin explicit grant)
- ☐ Looser: tất cả default-true (admin explicit revoke)
- ☐ Khác: ___

---

### Q5: Schema dư 3 columns (`status`, `primary_relationship_label`, `tags`) — UC document hay drop?

**Context (post-cross-repo-verify 2026-05-12):**
- DB schema `user_relationships` có 3 columns admin BE service KHÔNG dùng:
  - `status` DEFAULT 'pending' (workflow approval implied)
  - `primary_relationship_label` VARCHAR(100) (labelled primary)
  - `tags` JSONB (flexible tagging)
- Admin BE create relationship → DB ghi `status='pending'` (default), nhưng admin BE logic intent là `active`. → **Inconsistency state**.

**Trade-off:**

| Option | Pros | Cons |
|---|---|---|
| **A. Document UC v2 BR-022-14 Phase 5+ planned** | Keep schema flexibility; future-proof | Cần update service set `status='active'` hoặc drop default 'pending' để fix state inconsistency |
| **B. Drop 3 columns trong migration v3** | Clean schema; no dead code | Inconsistent với UC v2 (drop trong UC đã chốt); migration risky nếu có data; mất future flexibility |
| **C. Phase 4 expose `primary_relationship_label`** (UX value), 2 fields khác defer | Keep useful field; clean dead-code partial | Effort ~1h add controller + validation; UC v2 update mở rộng |

**Em recommend Option A** + service fix:
- **Document UC v2 BR-022-14**: `status`, `primary_relationship_label`, `tags` là Phase 5+ planned features
- **Phase 4 service fix**: `relationship.service.js` set `status: 'active'` khi create (~5min) để fix DB state inconsistency với default 'pending'
- Lý do: schema flexibility tốt cho expand feature tương lai; drop columns risky + mất value

**Anh decision:**
- ✅ **Option A: Document Phase 5+ + service fix `status='active'`** ← anh CHỌN
- ☐ Option B: Drop 3 columns migration v3 (clean schema, risk migration)
- ☐ Option C: Phase 4 expose `primary_relationship_label` UX
- ☐ Khác: ___

---

### Q6: BR-022-07 admin bypass clarify UC v2

**Context (post-cross-repo-verify 2026-05-12):**
- UC cũ BR-022-07: "User chỉ xem được sức khỏe của user khác nếu có user_relationships link"
- Mobile BE ENFORCE check; Admin BE KHÔNG ENFORCE (admin bypass với audit log).
- Cross-check HEALTH Q5: D-HEA-05 đã chốt "Audit log đủ, no mask cho admin" — consistent với admin bypass intent.

**Question:** UC v2 BR-022-07 cần update wording để reflect admin bypass?

**Em recommend Option A:**
- **Update UC v2 BR-022-07**: "User với role `user`/`caregiver` chỉ xem được sức khỏe của user khác nếu có user_relationships link. User với role `admin` bypass rule này — có quyền xem tất cả patients với audit log ghi `admin.view_patient_health` (BR-028-04, HEALTH Q5)."
- Cross-link explicit với UC028 BR-028-04 + UC022 v2 BR-022-07.

**Trade-off vs Option B (strict, admin cũng bị check):**
- Option B = security harder; admin cần have at least 1 relationship với every patient → unmanageable với 100+ patients.
- Option B = super-admin role bổ sung → scope creep.

**Anh decision:**
- ✅ **Option A: Document UC v2 admin bypass + audit (em recommend)** ← anh CHỌN
- ☐ Option B: Strict admin must have relationship (security harder, scope creep)
- ☐ Option C: Skip UC update (giữ BR-022-07 wording mập mờ, rủi ro audit ambiguity)
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Consent workflow** — Phase 5+ patient-driven scope; đồ án 2 admin-only
- ❌ **Time-bound relationships** — scope nở (expire/auto-renew complex)
- ❌ **Audit access trail** — đã có trong HEALTH module BR-028-04, dup
- ❌ **Relationship request workflow** — Phase 5+ mobile patient-initiated scope

---

## 🆕 Features mới em recommend

**Không có** — module hiện tại cover đầy đủ admin workflow. Consent/request workflow là Phase 5+ patient-driven scope.

---

## ❌ Features em recommend DROP

**Không có** — 5 endpoints đều có purpose + verified used.

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC022 v2 Alt 5.f/5.g/5.h | **Update v2 sub-flows** | Q1 nested pattern (D-USERS-05 reverse), Q2 PATCH alias add, Q3 enum BR-022-12, Q4 defaults BR-022-13, **Q5 BR-022-14 schema fields Phase 5+**, **Q6 BR-022-07 wording update admin bypass** |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| Route pattern flat vs nested (Q1) | Update UC v2 sang nested (D-REL-01) | 0h code; UC update | 🟢 Doc only |
| HTTP verb PUT vs PATCH (Q2) | Add PATCH alias (D-REL-02) | `feat: add PATCH /:userId/relationships/:id alias` (~15min) | 🟢 Low |
| relationship_type enum (Q3) | Document UC v2 BR-022-12 (D-REL-03) | 0h code; UC update | 🟢 Doc only |
| Permission defaults (Q4) | Document UC v2 BR-022-13 (D-REL-04) | 0h code; UC update | 🟢 Doc only |
| Schema dư columns (Q5) | Document Phase 5+ + service fix status='active' (D-REL-05) | `fix: relationship.service.js set status='active'` (~5min) + UC v2 BR-022-14 doc | 🟡 Inconsistency |
| BR-022-07 admin bypass clarify (Q6) | Update UC v2 BR-022-07 cross-link HEALTH Q5 (D-REL-06) | 0h code; UC update + cross-link | 🟢 Doc only |

**Estimated Phase 4 effort:** ~20min code + 1 UC v2 update (Q5+Q6 doc)

### Cross-doc updates required

- **UC022 v2 D-USERS-05:** Update endpoint pattern từ flat sang nested (`GET /api/v1/users/:userId/relationships`)
- **UC022 v2 Alt 5.f/5.g/5.h:** Update endpoint URLs tương ứng
- **UC022 v2 BR-022-12 (new):** `relationship_type` enum `[family, friend, doctor, nurse, other]` + default `'other'`
- **UC022 v2 BR-022-13 (new):** Permission defaults `vitals=true, alerts=true, location=false`
- **UC022 v2 BR-022-07 (update wording)**: Admin role bypass + audit log cross-link UC028 BR-028-04 (HEALTH Q5)
- **UC022 v2 BR-022-14 (new)**: Schema fields `status`/`primary_relationship_label`/`tags` là Phase 5+ planned, service set `status='active'` Phase 4

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-REL-01 | Route pattern (flat vs nested) | **Update UC v2 sang nested pattern** | Code deployed + FE consume; refactor risky; nested valid REST (sub-resource semantics) |
| D-REL-02 | HTTP verb (PUT vs PATCH) | **Add PATCH alias + document UC v2 chấp nhận cả 2** | Backward compat + REST consistency; cross-module cleanup Phase 5+ |
| D-REL-03 | relationship_type enum | **Keep current `[family, friend, doctor, nurse, other]`** | Đủ cover use case đồ án 2; UC v2 cần document enum rõ |
| D-REL-04 | Permission defaults | **Keep `vitals=true, alerts=true, location=false`** | Privacy default-deny cho GPS sensitive (BR-029 PHI handling principle) |
| D-REL-05 | Schema dư columns (status/label/tags) | **Document Phase 5+ + service fix `status='active'`** | Schema flexibility tốt cho future; drop risky; service fix đồng bộ DB state với logic intent (admin tạo = active, không pending) |
| D-REL-06 | BR-022-07 admin bypass clarify | **Update UC v2 wording cross-link HEALTH Q5** | Mobile BE enforce, admin BE bypass design intent; clarify UC để audit ambiguity; cross-link UC028 BR-028-04 |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Consent workflow (HIPAA) | ❌ Drop (Phase 5+ patient-driven) |
| Time-bound relationships | ❌ Drop (scope nở) |
| Audit access trail | ❌ Drop (dup HEALTH BR-028-04) |
| Relationship request workflow | ❌ Drop (Phase 5+ mobile) |

**All 4 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

- UC022 v2: `Resources/UC/Admin/UC022_Manage_Users_v2.md` (Alt 5.f, 5.g, 5.h)
- Routes: `HealthGuard/backend/src/routes/relationship.routes.js`
- Service admin: `HealthGuard/backend/src/services/relationship.service.js`
- DB schema: `PM_REVIEW/SQL SCRIPTS/02_create_tables_user_management.sql:62-88` (table `user_relationships` 11 cols + 3 constraints)
- DB tables: `user_relationships` (patient_id, caregiver_id, is_primary, can_view_*, relationship_type, **status**, **primary_relationship_label**, **tags**)
- BR-022-06 (1 primary per patient), BR-022-07 (relationship required cho view PHI cross-user — NON-ADMIN only sau Q6)
- Cross-module: HEALTH module Q5 D-HEA-05 PHI handling — admin bypass + audit log (consistent với Q6)
- **Cross-repo Mobile BE**: `health_system/backend/app/services/relationship_service.py:580-625` — dùng 3-level risk_level (✅ NO Q7 enum bug)
- **Cross-repo EMERGENCY**: `HealthGuard/backend/src/services/emergency.service.js:395-401` — join `user_relationships` cho linkedContacts (caregiver list khi SOS event)
- Phase 1 audit: M02 routes (D-007 /users mount order conflict — resolved)
