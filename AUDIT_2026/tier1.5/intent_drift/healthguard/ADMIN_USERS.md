# Intent Drift Review — `HealthGuard / ADMIN_USERS`

**Status:** 🟢 Confirmed (anh react 2026-05-12)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** ADMIN_USERS (CRUD users + Lock/unlock + Linked Profiles management)
**Related UCs (old):** UC022 (Manage Users)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M03_controllers_audit.md`
**Date prepared:** 2026-05-12

---

## 🎯 Mục tiêu doc này

Capture intent cho ADMIN_USERS module. UC022 cũ làm memory aid. Output = UC022 v2 + decisions log.

---

## 📚 Memory aid — UC022 cũ summary

**5 dòng:**
- Actor: Admin only
- Main: list users (paginated 20/page, filter, search)
- Alt: 5.a Add, 5.b Edit (no email), 5.c Lock/unlock + email notify, 5.d Delete (admin pwd + archive backup table), 5.e Search
- Alt: 5.f-5.h Linked Profiles management (relationships table — UC includes "tab Quan hệ theo dõi" trong user detail page)
- Business rules: BR-022-01 admin only, BR-022-02 delete need password, BR-022-03 soft delete, BR-022-04 audit log, BR-022-06 max 1 primary linked profile

---

## 🔧 Code state — what currently exists

**Routes (`user.routes.js`):**

```
authenticate + requireAdmin + usersLimiter (100/min) — ALL routes

GET    /api/v1/users           list users (paginated)
GET    /api/v1/users/:id       detail
POST   /api/v1/users           create (role enum allow 'user'+'admin')
PATCH  /api/v1/users/:id       update (role allow update)
PUT    /api/v1/users/:id       update (DUPLICATE of PATCH!)
PATCH  /api/v1/users/:id/lock  toggle lock
PUT    /api/v1/users/:id/lock  toggle lock (DUPLICATE!)
DELETE /api/v1/users/:id       soft delete (require admin password)
POST   /api/v1/users/:id/delete soft delete (DUPLICATE non-REST!)
```

**Relationships (separate routes):**
```
/api/v1/relationships/* — managed in M02 D-007 mount conflict zone
```

**Validation:**
- `createUserRules`: email + password + name + phone + role + dob + blood_type + height + weight
- `updateUserRules`: full_name + phone + **role** + gender + dob + blood_type + height + weight (NO email — match UC) ✅
- `deleteUserRules`: password required ✅

**Phase 1 audit findings (relevant):**
- M02 D-007: `/users` mount conflict với `/relationships` (route ordering)
- M02 F4-F5: Routes có rate limit ✅
- M03 F6: register block admin (REVERTED in AUTH Q6 — same applies here?)

---

## 💬 Anh react block

> Em đã đề xuất default — anh tick override nếu khác.

---

### Q1: Email notify khi lock account

**UC cũ (5.c.4):** "Khóa tài khoản và **gửi email thông báo**"
**Code:** Em chưa verify trong service, nhưng `email.js` chỉ có `sendPasswordResetEmail` + `sendPasswordChangeConfirmation` (M07 audit) — **KHÔNG có** email notify cho lock.

**Implications:**
- Account lock không thông báo user → user tự discover khi thử login → confusion

**Em recommend:**
- **A.** Implement email notify khi lock (per UC) — ~2h thêm template + sendLockNotification
- **B.** DROP requirement vì admin đã có thể inform user qua channel khác (manual) — UC update remove email notify
- **C.** Defer Phase 5+ (post-fix)

**Em đề xuất default:** **A** — small effort, professional admin tool nên có.

**Anh decision:** ☑ **A. Implement email notify on lock** (~2h)

**Impact:**
- Add `email.js sendAccountLockNotification(user, reason, lockedUntil)`
- Trigger trong `user.service.js toggleLock(userId)` khi `is_active` chuyển false hoặc `locked_until` set
- Template tham khảo `sendPasswordChangeConfirmation` pattern (M07 audit)

---

### Q2: Archive backup table khi delete

**UC cũ (5.d.5):** "Archive dữ liệu vào bảng backup"
**Code:** Em assume KHÔNG có (Phase 1 M06 audit không thấy `users_archive` hay backup table). Soft delete chỉ set `deleted_at`.

**Implications:**
- Soft delete đủ khôi phục — set `deleted_at = null` để restore
- Backup table riêng = duplicate data, complicate query (filter deleted_at vs join archive)

**Em recommend:** **DROP requirement** — soft delete đủ. UC update remove "Archive backup table".

**Anh decision:** ☑ **Em recommend** (drop archive backup table, soft delete đủ)

**Impact:**
- UC v2: REMOVE step 5.d.5 ("Archive dữ liệu vào bảng backup")
- Code: KHÔNG cần migration tạo `users_archive` table
- Restore mechanism: SET `deleted_at = NULL` (admin endpoint future, defer Phase 5+)

---

### Q3: Update role qua PATCH /:id (admin promote/demote)

**UC cũ:** Không nói rõ
**Code:** `updateUserRules` cho phép update field `role` với enum `['user', 'admin']`

**Q6 (AUTH wave) đã clarify:** Register endpoint là dev tool. Câu hỏi production:

**Có cho admin promote user → admin qua PATCH /users/:id không?**

**Em recommend:** **CÓ** — admin web cần khả năng này. BR mới:
- Admin có quyền update role (promote/demote)
- KHÔNG cho user tự update role (chỉ admin hit endpoint qua requireAdmin)
- Audit log mọi role change với `before/after` value
- Cấm tự promote bản thân (`req.user.id !== params.id` cho role update)

**Anh decision:** ☑ **Em recommend** (allow role update via PATCH, với constraints)

**Constraints:**
- Mọi route đã có `requireAdmin` middleware → chỉ admin gọi được
- Thêm check trong controller: cấm `req.user.id === params.id` cho role update (no self-promotion)
- Audit log mọi role change với `before/after` value
- New BR-022-09: Role change phải log audit chi tiết

---

### Q4: PATCH vs PUT duplicate routes

**Code:** Có CẢ `router.patch('/:id', ...)` VÀ `router.put('/:id', ...)` cho cùng operation. Same với lock + delete (POST /:id/delete vs DELETE /:id).

**REST convention:** PATCH = partial update, PUT = full replace, DELETE = remove

**Hiện tại:** updateUserRules treat as partial → đúng PATCH semantics. PUT route là **legacy/compat** không cần thiết.

**Em recommend:** **REMOVE** PUT routes + POST /:id/delete. Keep PATCH + DELETE only. UC update note REST compliance.

**Anh decision:** ☑ **Em recommend** (REST clean)

**Impact:**
- REMOVE `router.put('/:id', ...)` (duplicate của PATCH)
- REMOVE `router.put('/:id/lock', ...)` (duplicate của PATCH /:id/lock)
- REMOVE `router.post('/:id/delete', ...)` (anti-REST)
- Keep PATCH + DELETE only
- FE check dùng routes còn lại (M05/Track 1B confirm trong Phase 4)

---

### Q5: Linked Profiles tab — UI integration vs separate /relationships routes

**UC cũ (5.f-5.h):** Linked Profiles QUẢN LÝ TRONG user detail page (tab "Quan hệ theo dõi") của UC022.

**Code:** Routes tách ra `/api/v1/relationships/*` riêng (M02 D-007 conflict).

**Drift:**
- UC implies admin click vào user → tab → manage relationships của user đó
- Code expose relationships independently (FE có thể gọi từ nhiều page)

**Em recommend:**
- **Backend:** Keep `/relationships/*` independent (cleaner architecture, FE flexible)
- **Frontend:** Embed RelationshipManager component trong UserDetail page (UX = UC intended)
- **UC update:** Note "FE behavior" vs "BE endpoint" rõ ràng

**Anh decision:** ☑ **Em recommend** (BE independent, FE embed)

**Impact:**
- BE: Keep `/api/v1/relationships/*` standalone (M02 D-007 fix relate to mount order, không nhất thiết refactor nest)
- FE: `UserDetail` page có tab "Quan hệ theo dõi" embed `RelationshipManager` component
- UC v2 explicitly note: BE expose flat /relationships, FE present nested UX

---

### Q6: Search + Filter scope

**UC cũ (5.e):** "Tìm kiếm và lọc" — không specify trường nào search được hay filter nào.

**Em assume từ M03 audit:**
- Search: name + email (LIKE %query%)
- Filter: role + status (active/locked)

**Em recommend:** Confirm + thêm:
- Search: name + email + phone
- Filter: role (user/admin) + status (active/locked/deleted) + date_of_birth range
- Sort: created_at DESC default, allow toggle by name/email/last_login

**Anh decision:** ☑ **Em recommend** (expanded)

**Spec confirmed:**
- **Search**: name + email + phone (LIKE %query%, sanitize input)
- **Filter**: role (user/admin) + status (active/locked/deleted) + date_of_birth range
- **Sort**: created_at DESC (default), allow toggle by name | email | last_login
- **Pagination**: 20/page (UC đã confirm)

---

### Q7: BR-022-08 (deleted) — role structure

**UC cũ note:** `BR-022-08: (Rule Deleted - Role structure simplified to user/admin)`

**Question:** Anh muốn keep simple `user` / `admin` only? Hay add `clinician` / `caregiver` per SRS actors?

**SRS actors:** Patient, Caregiver, Admin, AI Module
**Mobile UCs hint:** Patient + Caregiver có thể là same role 'user' với linked profile relationship distinguishing

**Em recommend:** **Keep `user` / `admin`** — caregiver/patient distinguished via `user_relationships` table (BR-022-07). Simpler.

**Anh decision:** ☑ **Em recommend** (keep `user` / `admin`)

**Rationale:** Caregiver/Patient distinction qua `user_relationships` table (BR-022-07). Simpler schema, phù hợp đồ án 2 scope.

---

### Q8: User detail — show linked profiles count + audit history?

**Em đề xuất feature mới:** Trong user detail page hiển thị:
- Số lượng linked profiles (incoming + outgoing)
- Audit log gần nhất của user (last 10 actions)
- Last login + IP
- Last vital data submission timestamp (từ devices)

**Em recommend:** **Add** — admin tool cần forensic info quick-glance.

**Anh decision:** ☑ **Em recommend** (enrich user detail)

**Spec confirmed:**
- Show linked profiles count (incoming + outgoing)
- Last 10 audit log entries của user
- Last login timestamp + IP
- Last vital data submission timestamp (từ devices)
- Implementation: separate endpoint `GET /users/:id/detail` hoặc expand existing `GET /users/:id` với `?include=relations,audit,activity`

---

### Q9: Bulk operations (lock multiple, delete multiple)

**UC cũ:** Không mention
**Industry standard:** Admin panel có bulk actions

**Em recommend:** **Add** trong UC v2 + Phase 4+:
- Bulk select (checkbox)
- Actions: bulk lock, bulk unlock
- KHÔNG bulk delete (high risk, require individual confirm)

**Anh decision:** ☑ **Em recommend** (bulk lock/unlock only, NO bulk delete)

**Spec:**
- New endpoint: `PATCH /api/v1/users/bulk-lock` (body: `{ user_ids: [], lock: true/false }`)
- Email notify gửi cho từng user (nếu Q1 implement)
- Audit log mỗi user bulk action
- Frontend: checkbox column trong table + action bar
- Bulk delete: KHÔNG có (force individual confirm cho safety)

---

## 🆕 Features anh nghĩ ra

_(anh không add thêm gì trong wave ADMIN_USERS)_

---

## ❌ Features anh muốn DROP

- **Archive backup table** (Q2) — soft delete `deleted_at` đủ
- **PUT routes duplicates** (Q4) — anti-REST
- **POST /:id/delete** (Q4) — anti-REST
- **Bulk delete** (Q9) — high risk, force individual confirm

---

## 📊 Drift summary (CONFIRMED)

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC022 Manage Users | **Major update** Q1-Q9 (drop 5.d.5, add bulk, role update, search expand) | UC022 v2 |

### Code impact

| Phase 1 finding | Status after Phase 0.5 | Phase 4 task |
|---|---|---|
| M02 D-007 /users mount conflict | Q5: keep BE independent → fix mount order | P1 (~30 min) |
| PUT/PATCH/POST delete duplicates | Q4 confirm: REMOVE | P2 (~15 min) |
| Email lock notify missing | Q1 confirm: IMPLEMENT | P2 (~2h) |
| Archive backup table absent | Q2 drop — not needed | (none) |
| Bulk operations missing | Q9 confirm: ADD bulk lock/unlock | P3 (~3h) |
| Role update via PATCH no constraints | Q3 confirm: add self-promotion check + audit | P2 (~30 min) |
| User detail minimal | Q8: enrich with linked/audit/activity | P3 (~3-4h) |
| Search/filter scope unclear | Q6 spec confirmed | P3 (~2h enhancement) |

---

## 📝 Anh's decisions log (CONFIRMED 2026-05-12)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-USERS-01 | Email notify on lock | **A. Implement** | Professional admin tool feedback mới UX triệt để |
| D-USERS-02 | Archive backup table | **Drop** | Soft delete `deleted_at` đủ, không duplicate data |
| D-USERS-03 | Role update via PATCH | **Allow + constraints** | Admin manage role, cấm self-promote, audit log |
| D-USERS-04 | REST clean | **Drop PUT/POST delete duplicates** | REST convention, giảm surface API |
| D-USERS-05 | Linked Profiles UI integration | **BE independent, FE embed** | Architecture clean, FE flexibility |
| D-USERS-06 | Search/filter expanded | **Em recommend confirmed** | Admin tool bổn phận, expand standard |
| D-USERS-07 | Role structure | **Keep `user` / `admin`** | Simpler, distinguish via relationships |
| D-USERS-08 | User detail enrichment | **Enrich** | Forensic info quick-glance |
| D-USERS-09 | Bulk operations | **Bulk lock/unlock only** | Productivity, NOT bulk delete (safety) |

---

## 🔁 Impact on Phase 4 fix plan (CONFIRMED)

### Phase 4 ADMIN_USERS backlog

| # | Task | Priority | Effort |
|---|---|---|---|
| 1 | M02 D-007 /users mount order fix | P1 | 30 min |
| 2 | Q3 role update self-promote check + audit | P2 | 30 min |
| 3 | Q4 remove PUT/POST delete duplicates | P2 | 15 min |
| 4 | Q1 email notify on lock | P2 | 2h |
| 5 | Q9 bulk lock/unlock endpoint + FE | P3 | 3h |
| 6 | Q6 search/filter expand | P3 | 2h |
| 7 | Q8 user detail enrichment | P3 | 3-4h |
| 8 | Update UC022 v2 doc | P3 doc | 1h (now) |

**ADMIN_USERS module total Phase 4 effort:** ~12-13h.

### Tasks REJECTED (Phase 0.5 strip ra khỏi backlog)

- ~~Archive backup table~~ (Q2 — soft delete đủ)
- ~~Bulk delete~~ (Q9 — safety)
- ~~Add clinician/caregiver roles~~ (Q7 — keep simple)

---

## Cross-references

- UC022 cũ: `Resources/UC/Admin/UC022_Manage_Users.md`
- UC022 v2 (output): `Resources/UC/Admin/UC022_Manage_Users_v2.md`
- Phase 1 audit: `tier2/healthguard/M02_routes_audit.md` (D-007), `M03_controllers_audit.md`
- AUTH wave Q6: register là dev tool — Q3 ở đây là production role update path
- ADR-004: API prefix
