# Intent Drift Review — `health_system / RELATIONSHIPS`

**Status:** 🟢 Confirmed v2 (anh chọn theo em recommend Q1-Q5; verified findings 2026-05-12; 4 add-ons drop)
**Repo:** `health_system/backend` (mobile FastAPI BE)
**Module:** RELATIONSHIPS (Linked Profiles / Family Sharing — user-to-user)
**Related UCs (old):** **UC SCOPE MISMATCH** — code thực tế là Linked Profiles, KHÔNG match UC030 Emergency Contacts (different concept)
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-12
**Question count:** 5 (UC scope + SQL canonical drift + audit log + UC030 missing + mobile UC documentation)

---

## 🎯 Mục tiêu

Capture intent cho RELATIONSHIPS module mobile BE. **Phát hiện scope mismatch quan trọng:** Code = "Linked Profiles / Family Sharing" (user trong hệ thống), UC030 = "Emergency Contacts" (có thể người ngoài hệ thống). 2 concept riêng biệt, 2 DB tables riêng.

**Cross-repo:** HealthGuard RELATIONSHIP wave (UC022 admin) đã review xong với 6 decisions. Mobile BE tận dụng cross-link.

---

## 📚 UC scope analysis (CRITICAL FINDING)

### 2 DB tables RIÊNG BIỆT — verified canonical SQL

| Table | Purpose | UC scope |
|---|---|---|
| `user_relationships` | Patient ↔ Caregiver linked profiles trong hệ thống (P-1 family sharing) | UC022 admin (HealthGuard wave done) + **mobile self-manage MISSING UC** |
| `emergency_contacts` | Số điện thoại khẩn cấp (CÓ THỂ NGƯỜI NGOÀI HỆ THỐNG) — UC030 | UC030 Emergency Contacts |

→ **Code mobile BE `relationships.py` = `user_relationships`**, KHÔNG phải UC030. Drift gap chí mạng.

### UC030 cũ summary (memory aid — KHÔNG dùng cho code này)

UC030 mention: contact info (phone, name), priority, channels (SMS/Call/Push), location permission. → **Cho table `emergency_contacts`**, NOT `user_relationships`.

### UC022 cũ summary (memory aid — partially apply)

UC022 admin scope (HealthGuard) đã có 6 decisions Phase 4:
- D-REL-01: Route nested pattern
- D-REL-02: PATCH alias
- D-REL-03: relationship_type enum `[family, friend, doctor, nurse, other]`
- D-REL-04: Permission defaults `vitals=true, alerts=true, location=false`
- D-REL-05: Schema dư columns (status/label/tags) Phase 5+
- D-REL-06: BR-022-07 admin bypass clarify

→ UC022 v2 **scope admin**. Mobile BE user self-manage cần UC riêng.

---

## 🔧 Code state — verified

### Routes (`relationships.py`) — 9 endpoints

```
tags=[mobile-relationships]

GET    /relationships/dashboard                    Family monitoring snapshots
GET    /relationships                              List all relationships
GET    /relationships/search?query=                Search user by email/phone/name
GET    /relationships/{id}/detail                  Linked contact health detail
GET    /relationships/{id}/medical-info            P-4 medical info (gated)
GET    /access-profiles                            Profiles user có quyền xem
POST   /relationships/request                      Send relationship request
POST   /relationships/accept                       Accept incoming request
PUT    /relationships/{id}                         Update permissions/tags
DELETE /relationships/{id}                         Cancel/revoke
```

### DB schema findings

**✅ `user_relationships` table (canonical SQL `02_create_tables_user_management.sql`):**
- `id, patient_id, caregiver_id, is_primary, relationship_type, tags`
- Permissions: `can_view_vitals`, `can_receive_alerts`, `can_view_location`
- Status fields: `status, primary_relationship_label, tags` (Phase 5+ per HealthGuard D-REL-05)

**🔴 `can_view_medical_info` field — SQL canonical drift:**
- Field added via migration `20260430_relationship_view_medical_info.sql` (mobile BE migrations folder)
- Migration: `ALTER TABLE user_relationships ADD COLUMN can_view_medical_info BOOLEAN NOT NULL DEFAULT FALSE`
- **`PM_REVIEW/SQL SCRIPTS/02_create_tables_user_management.sql` CHƯA UPDATE** → SQL canonical out of sync
- Mobile BE code defensive với `getattr(rel, "can_view_medical_info", False)` cho legacy DBs

### Service quality (em note)

**✅ P-4 medical info implementation rất chất lượng:**
- Asymmetry guard (granter=patient, grantee=caregiver direction-aware)
- Privacy-by-default (mặc định FALSE, opt-in per partner)
- Defensive `getattr` cho legacy compat
- 5 test cases trong `test_relationship_service_contract.py:264-505` cover happy path + denial + asymmetry + permission off

**🟡 Audit log MISSING:**
- `relationship_service.py`: ZERO audit log calls cho create/update/accept/delete
- Inconsistent với:
  - UC022 admin BE đã có (HealthGuard wave verified)
  - PROFILE module mobile BE đã có
  - SETTINGS module Q3 quyết định ADD audit log
- BR-022-04 (UC022) yêu cầu audit log mọi relationship change

### Mobile-specific endpoints (KHÔNG có ở admin BE)

| Endpoint | Purpose | UC document? |
|---|---|---|
| `/relationships/dashboard` | Family monitoring snapshot list | ❌ Missing |
| `/relationships/{id}/detail` | Health detail per linked contact | ❌ Missing |
| `/relationships/{id}/medical-info` | P-4 gated medical info | ❌ Missing |
| `/access-profiles` | List profiles user xem được | ❌ Missing |
| `/relationships/search` | Search by email/phone | ❌ Missing |

---

## 💬 Anh react block

> 5 câu — phát hiện UC scope mismatch + SQL canonical drift + audit log gap + UC030 endpoint missing.

---

### Q1: 🔴 SQL canonical drift — `can_view_medical_info` field

**Drift:**
- Mobile BE migration `20260430_relationship_view_medical_info.sql` ADD column `can_view_medical_info`
- Canonical SQL `PM_REVIEW/SQL SCRIPTS/02_create_tables_user_management.sql` CHƯA UPDATE
- → DB instance fresh init từ canonical SQL **thiếu column** → mobile BE fall back `getattr(..., False)` → tất cả medical-info request return 403 silently

**Em recommend:**
- **Update canonical SQL** `02_create_tables_user_management.sql` add column trong CREATE TABLE statement
- **Update `init_full_setup.sql`** synced
- Mobile BE giữ `getattr` defensive (anti-fragility)
- Phase 4 task ~30min: SQL update + verify init scripts

**Anh decision:**
- ✅ **Em recommend (update canonical SQL + init scripts)** ← anh CHỌN
- ☐ Keep migration-only approach (canonical SQL không touch, init script chỉ run migrations)
- ☐ Khác: ___

---

### Q2: 🟡 Audit log missing in relationship_service

**Drift:**
- `relationship_service.py` ZERO audit log calls cho create/update/accept/delete
- Inconsistent với:
  - HealthGuard admin BE (UC022 D-REL có audit log)
  - PROFILE mobile BE (verified)
  - SETTINGS mobile BE Q3 quyết định ADD audit log
- BR-022-04 yêu cầu audit log

**Em recommend:**
- **Add audit log** consistent với PROFILE pattern:
  - `relationship.requested` — create request
  - `relationship.accepted` — accept incoming
  - `relationship.permissions_updated` — update permissions/tags với diff
  - `relationship.deleted` — cancel/revoke
- Effort ~1h: 4 service methods + IP/UA tracking từ Request

**Anh decision:**
- ✅ **Em recommend (add audit log 4 actions)** ← anh CHỌN
- ☐ Defer Phase 5+ (đồ án 2 mobile audit không critical)
- ☐ Khác: ___

---

### Q3: 🔴 UC scope mismatch — Mobile linked profiles MISSING UC

**Issue:**
- Code mobile BE `relationships.py` = self-manage linked profiles (P-1 + P-4)
- UC022 admin scope (HealthGuard) khác — admin manage all relationships system-wide
- Mobile UC để user self-manage **không tồn tại trong Resources/UC/**

**Options:**
- **A. Tạo UC mới `UC005A` Manage Linked Profiles** (sub-UC của UC005 Manage Profile)
  - Document 9 endpoints + 5 mobile-specific features
  - Cross-link UC022 admin BR + UC030 Emergency Contacts
- **B. Extend UC005 v2 (Manage Profile)** với section "Linked Profiles & Family Sharing"
  - Tận dụng UC005 đang được update (PROFILE wave)
  - Risk: UC005 quá dài, dilute scope chính
- **C. Tạo UC035 Manage Linked Profiles standalone** (số mới)
  - Sạch sẽ scope; risk: phải maintain cross-link nhiều
- **D. Skip UC documentation** (legacy code)
  - Không document; risk: code drift incrementally

**Em recommend Option A:** Tạo `UC005A_Manage_Linked_Profiles.md` sub-UC của UC005:
- File path: `Resources/UC/Authentication/UC005A_Manage_Linked_Profiles.md`
- Cross-ref: parent UC005 (profile self), sibling UC030 (emergency contacts), admin counterpart UC022
- Effort ~1h doc

**Anh decision:**
- ✅ **Em recommend (Option A — UC005A sub-UC)** ← anh CHỌN
- ☐ Option B (extend UC005 v2)
- ☐ Option C (UC035 standalone)
- ☐ Option D (skip documentation)
- ☐ Khác: ___

---

### Q4: 🟡 UC030 Emergency Contacts endpoint MISSING

**Drift:**
- DB table `emergency_contacts` exist (canonical SQL)
- UC030 spec đầy đủ
- Code mobile BE: KHÔNG có route `/emergency-contacts`
- UC030 BR-030-02 nói "Khi gửi SOS, hệ thống sử dụng priority để quyết định thứ tự gọi/gửi SMS" → SOS service phải dùng table này

**Implications:**
- User KHÔNG cấu hình được người liên hệ khẩn cấp ngoài hệ thống (vd: bác sĩ riêng, người thân chưa register)
- SOS notification chỉ gửi cho linked profiles trong hệ thống → giảm reach khẩn cấp

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| **A. Implement Phase 4** (~3h) | UC030 functional; SOS reach rộng hơn | Effort + integrate với SOS dispatcher |
| **B. Defer Phase 5+** | Phase 4 focus core fixes | Compliance gap với UC v1 |
| **C. Drop UC030** (use linked profiles only) | Simplify scope; 1 source of truth | Mất feature contact người ngoài |

**Em recommend Option B (Defer Phase 5+):**
- Đồ án 2 demo scope: linked profiles đủ cho family sharing
- UC030 emergency contacts thường used khi production scale (bác sĩ riêng, gia đình ngoài)
- Phase 5+ implement khi có user feedback thực

**Anh decision:**
- ✅ **Em recommend (Option B — Defer Phase 5+)** ← anh CHỌN
- ☐ Option A (implement Phase 4 ~3h)
- ☐ Option C (drop UC030, use linked profiles)
- ☐ Khác: ___

---

### Q5: Mobile-specific endpoints — UC documentation strategy

**Endpoints chỉ có ở mobile (5 endpoints):**
- `/relationships/dashboard` — family monitoring snapshot list
- `/relationships/{id}/detail` — health detail per linked
- `/relationships/{id}/medical-info` — P-4 gated medical
- `/access-profiles` — profiles user xem được
- `/relationships/search` — search user

**Em recommend (depend Q3 Option A path):**
- **Document trong UC005A** với section "Mobile-specific features" cover 5 endpoints
- Cross-link với:
  - UC022 (admin counterpart)
  - UC028 (HEALTH — `/detail` consume vitals data)
  - UC005 (medical-info field source)
- Audit log integration (Q2 decisions): mọi action audit logged

**Anh decision:**
- ✅ **Em recommend (document trong UC005A — depend Q3 Option A)** ← anh CHỌN (single-option theo Q3)

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Relationship invitation expiry** — Phase 5+ housekeeping
- ❌ **Bulk permission templates** (Family/Doctor/Spouse presets) — Phase 5+ UX
- ❌ **Permission change audit log visible to user** — Phase 5+ transparency
- ❌ **Multi-step relationship setup wizard** — Phase 5+ UX

---

## 🆕 Features mới em recommend

**Không có** — code đã rich, Q1-Q5 cover gap.

---

## ❌ Features em recommend DROP

**Không có** — 9 endpoints đều functional và có test coverage P-4.

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC005A Manage Linked Profiles (NEW) | **Create v1** | Sub-UC của UC005, document 9 endpoints + 5 mobile-specific features (dashboard/detail/medical-info/access-profiles/search), cross-link UC022 admin + UC030 emergency contacts |
| UC030 Emergency Contacts | **Defer Phase 5+** | UC030 v1 keep; code implementation defer cho đồ án 2 |
| UC022 admin (HealthGuard) | Already done | Cross-link added trong UC005A |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| SQL canonical drift can_view_medical_info (Q1) | Update canonical + init scripts (D-REL-MB-01) | `fix(sql): canonical SQL add can_view_medical_info column + sync init_full_setup.sql` (~30min) | 🔴 Cross-repo SQL drift |
| Audit log missing (Q2) | Add 4 audit actions (D-REL-MB-02) | `feat(relationships): audit log relationship.requested/accepted/permissions_updated/deleted với IP+UA` (~1h) | 🟡 Compliance |
| UC scope mismatch (Q3) | Create UC005A sub-UC (D-REL-MB-03) | `docs(uc): create UC005A_Manage_Linked_Profiles.md sub-UC of UC005` (~1h) | 🟢 Doc only |
| UC030 Emergency Contacts (Q4) | Defer Phase 5+ (D-REL-MB-04) | 0h Phase 4; document defer trong PM_REVIEW backlog | 🟢 Defer |
| Mobile UC documentation (Q5) | Document trong UC005A (D-REL-MB-05) | Bundle với Q3 UC005A creation | 🟢 Doc only |

**Estimated Phase 4 effort:** ~2.5h code (Q1 30min + Q2 1h + Q3+Q5 doc 1h) + UC005A v1 creation

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-REL-MB-01 | SQL canonical drift can_view_medical_info | **Update canonical SQL + init scripts** | Fresh DB init phải có đủ schema; mobile BE giữ `getattr` defensive cho legacy compat |
| D-REL-MB-02 | Audit log relationship service | **Add 4 audit actions (requested/accepted/permissions_updated/deleted)** | BR-022-04 explicit; consistency với PROFILE + HealthGuard admin BE; compliance |
| D-REL-MB-03 | UC scope linked profiles mobile | **Option A — tạo UC005A sub-UC của UC005** | Linked profiles đủ scope để tách, không dilute UC005 main; cross-link UC022/UC030 rõ ràng |
| D-REL-MB-04 | UC030 Emergency Contacts implementation | **Option B — Defer Phase 5+** | Đồ án 2 linked profiles đủ cho family sharing; UC030 contact ngoài hệ thống cho production scale |
| D-REL-MB-05 | Mobile-specific endpoints UC docs | **Document trong UC005A (Q3 Option A path)** | Bundle với Q3 để single source of truth; cross-link UC022/UC028/UC005 |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Relationship invitation expiry | ❌ Drop (Phase 5+ housekeeping) |
| Bulk permission templates | ❌ Drop (Phase 5+ UX) |
| Permission audit log visible to user | ❌ Drop (Phase 5+ transparency) |
| Multi-step setup wizard | ❌ Drop (Phase 5+ UX) |

**All 4 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

- Routes: `health_system/backend/app/api/routes/relationships.py`
- Service: `app/services/relationship_service.py` (P-4 medical info implementation)
- Schemas: `app/schemas/relationship.py`
- Migration: `health_system/backend/migrations/20260430_relationship_view_medical_info.sql`
- DB tables:
  - `user_relationships` (canonical SQL `02_create_tables_user_management.sql:62-88`) — **canonical drift can_view_medical_info**
  - `emergency_contacts` (canonical SQL `02_create_tables_user_management.sql:98+`) — UC030 not implemented
- Cross-repo:
  - **HealthGuard UC022 wave (DONE):** D-REL-01..06 cho admin BE
  - **HEALTH module Q5 D-HEA-05** PHI handling (admin bypass + audit log) — consistent với mobile P-4 design
  - **NOTIFICATIONS module Q4** expire worker pattern — reusable cho relationship invitation expiry add-on
- Test coverage: `tests/test_relationship_service_contract.py` 5 P-4 test cases (asymmetry, denial, happy path, permission off, granter direction)
