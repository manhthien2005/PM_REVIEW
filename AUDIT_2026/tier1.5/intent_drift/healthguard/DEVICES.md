# Intent Drift Review — `HealthGuard / DEVICES`

**Status:** � Confirmed v3 (Q1-Q9 confirmed v1 + Q10-Q14 cross-repo confirmed v2 2026-05-12; anh chọn theo em recommend)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** DEVICES (Admin quản lý IoT devices)
**Related UCs (old):** UC025 (Manage Devices) — admin scope, KHÔNG phải UC040/041/042 (mobile user)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md` (D-007), `M03_controllers_audit.md`
**Date prepared:** 2026-05-12

---

## 🎯 Mục tiêu doc này

Capture intent cho DEVICES admin module. UC025 cũ làm memory aid. Output = UC025 v2.

---

## 📚 Memory aid — UC025 cũ summary

**5 dòng:**
- Actor: Admin only (UC040/041/042 cho mobile user)
- Main: List devices (search name/serial/user, filter active/inactive, có chủ/rảnh)
- Alt: 4.a Assign device→user, 4.b Lock/unlock, 4.c View detail, 4.d Add manual, 4.e **Import CSV/Excel hàng loạt**
- Fields: device_name, type, model, firmware, MAC, serial, user_id, is_active, battery, last_seen_at, calibration_data
- BR-025-01: 1 device ↔ max 1 user
- BR-025-02: No hard delete nếu có data
- BR-025-03: Audit log mọi assign/lock change
- NFR: Pagination load < 2s với 10,000 devices

---

## 🔧 Code state — what currently exists

**Routes (`device.routes.js`):**

```
authenticate + requireAdmin + devicesLimiter (100/min) — ALL routes

POST   /api/v1/devices                create (admin add device to kho)
GET    /api/v1/devices                list (paginated)
GET    /api/v1/devices/:id            detail
PATCH  /api/v1/devices/:id            update fields
PUT    /api/v1/devices/:id            DUPLICATE of PATCH
PATCH  /api/v1/devices/:id/assign     assign user (body: { userId })
PUT    /api/v1/devices/:id/assign     DUPLICATE
PATCH  /api/v1/devices/:id/unassign   unassign user
PUT    /api/v1/devices/:id/unassign   DUPLICATE
PATCH  /api/v1/devices/:id/lock       toggle lock (is_active)
PUT    /api/v1/devices/:id/lock       DUPLICATE
DELETE /api/v1/devices/:id            soft delete
```

**Validation:**
- `createDeviceRules`: device_name + device_type + serial_number + mac_address + model? + firmware_version?
- `assignDeviceRules`: userId required
- `updateDeviceRules`: device_name + device_type + model + firmware_version + calibration_data

**Phase 1 audit findings:**
- M02 D-007: routes order conflict với /users (resolved during review)
- M02: PUT duplicates everywhere (NEW — em note for Q2)
- Code có unassign explicit (UC không mention — em note for Q3)

**Missing vs UC025:**
- Alt 4.e (Import CSV/Excel) → **KHÔNG có** endpoint
- Email notify khi lock device → **KHÔNG có**
- Bulk operations → **KHÔNG có**

### 🟡 Cross-repo findings (post-cross-repo-verify 2026-05-12):

**3 độc lập device CRUD tracks** (verified):

| Track | Caller | Endpoint | Auth | UC ref |
|---|---|---|---|---|
| **Admin web** | Admin browser | `/api/v1/devices/*` (HealthGuard BE) | admin JWT | UC025 đây |
| **Mobile BE admin** | IoT SIM provisioning | `/mobile/admin/devices/*` | internal-secret | UC chưa cover (devops scope?) |
| **Mobile BE user** | Flutter user | `/mobile/devices/*` | user JWT | UC040-042 mobile pair |

Cả 3 tracks viết vào **CÙNG DB `devices` table**, **KHÔNG sync**, **KHÔNG share validation/audit logic**.

**Mobile BE admin track endpoints** (`health_system/backend/app/api/routes/admin.py`):

```
POST   /mobile/admin/devices                  body { device_name, device_type, serial_number, mqtt_client_id?, mac_address?, model?, user_email? }
GET    /mobile/admin/devices?user_id=X        list, filter
PATCH  /mobile/admin/devices/:id              update firmware, battery, signal
DELETE /mobile/admin/devices/:id              delete
POST   /mobile/admin/devices/:id/assign       body { user_email }
POST   /mobile/admin/devices/:id/activate     activate lifecycle
POST   /mobile/admin/devices/:id/deactivate   deactivate lifecycle
POST   /mobile/admin/devices/:id/heartbeat    body { battery_level, signal_strength } → update last_seen_at
```

**Mobile BE user track endpoints** (`health_system/backend/app/api/routes/device.py`):

```
GET    /mobile/devices                        list user's devices
GET    /mobile/devices/:id                    detail
POST   /mobile/devices                        register manual (user)
PATCH  /mobile/devices/:id                    update (user-owned)
DELETE /mobile/devices/:id                    delete (user-owned)
POST   /mobile/devices/scan/pair              QR code pair (Flutter)
PUT    /mobile/devices/:id/settings           update device settings
```

**Cross-repo HTTP client** (`Iot_Simulator_clean/api_server/backend_admin_client.py:45`):
```python
self._base = f"{self._backend_root}/mobile/admin"  # MATCH Mobile BE current
```

→ IoT SIM client contract **đúng với current Mobile BE state** (không stale).

**Assign contract MISMATCH cross-track:**

| Track | Verb | Path | Body |
|---|---|---|---|
| HealthGuard admin BE | `PATCH` | `/api/v1/devices/:id/assign` | `{ userId: number }` |
| Mobile BE admin | `POST` | `/mobile/admin/devices/:id/assign` | `{ user_email: string }` |

→ 2 tracks với 3 inconsistencies: HTTP verb (PATCH vs POST) + payload key (`userId` vs `user_email`) + payload type (number vs string).

**Activate/Deactivate vs Lock/Unlock**:

- Mobile BE admin: `activate/deactivate` (lifecycle semantic, có thể liên quan provisioning state)
- HealthGuard admin BE: `lock` (toggle `is_active`, admin moderation)
- DB `devices.is_active` BOOLEAN — **2 tracks ghi cùng field** với semantics khác

**Heartbeat owner verified**:

- IoT SIM `backend_admin_client.py:252` comment _"Removed dead code: update_heartbeat"_ — client method removed
- Mobile BE admin endpoint `POST /mobile/admin/devices/:id/heartbeat` **STILL EXISTS** (`admin.py:243`)
- IoT SIM **likely gọi qua khac path** hoặc heartbeat-via-telemetry (verify Phase 4)

---

## 💬 Anh react block

> Em đề xuất default — anh tick override nếu khác.

---

### Q1: Import CSV/Excel hàng loạt (UC Alt 4.e)

**UC cũ (Alt 4.e):** Admin upload CSV/Excel để bulk-add devices vào kho
**Code:** KHÔNG có

**Implications:**
- Admin có hàng nghìn devices (per NFR 10,000) → manual add từng cái không feasible
- Use case thực: Khi vendor giao lô hàng IoT mới với CSV info

**Em recommend:**
- **A.** Implement endpoint `POST /api/v1/devices/import` với multipart/form-data — parse CSV, validate row, batch insert. ~4-6h.
- **B.** Defer Phase 5+ — admin manual nhập từng cái cho đồ án 2 demo.
- **C.** Drop requirement — không cần cho đồ án 2.

**Em đề xuất default:** **B Defer** — đồ án 2 scope nhỏ, manual đủ. Phase 5+ implement khi production.

**Anh decision:** ☑ **B. Defer Phase 5+**

**Impact:**
- UC v2 vẫn keep Alt 4.e (Import CSV) nhưng note "Để Phase 5+, MVP mặc định manual add"
- KHÔNG tạo endpoint `/import` trong Phase 4 backlog
- KHÔNG add các dependency csv-parser/xlsx (giữ dưới `engines` config Node minimal)

---

### Q2: PUT duplicates (giống ADMIN_USERS Q4)

**Code:** PATCH + PUT duplicate cho assign, unassign, lock, update — tổng 4 cặp

**Em recommend:** **REMOVE PUT routes**, keep PATCH only (REST clean, consistent với ADMIN_USERS decision).

**Anh decision:** ☑ **Em recommend** — drop PUT duplicates

**Impact:**
- REMOVE 4 PUT routes trong `device.routes.js`:
  - `router.put('/:id', ...)`
  - `router.put('/:id/assign', ...)`
  - `router.put('/:id/unassign', ...)`
  - `router.put('/:id/lock', ...)`
- Keep PATCH + DELETE only
- Consistent với ADMIN_USERS D-USERS-04

---

### Q3: Unassign endpoint — UC chưa cover

**UC cũ:** Chỉ nói "Gán cho user" (Alt 4.a), KHÔNG nói explicit "Bỏ gán"
**Code:** Có `PATCH /:id/unassign` set user_id = NULL

**Em interpret:** UC implicit cover — re-assign từ user A → user B cần unassign trước, hoặc admin muốn return device về kho.

**Em recommend:** **Keep endpoint + UC update** explicit Alt 4.f "Bỏ gán thiết bị" để UC khớp code.

**Anh decision:** ☑ **Em recommend** — UC v2 add Alt 4.f explicit "Bỏ gán thiết bị"

**Impact:**
- UC025 v2 thêm Alt 4.f flow
- Endpoint `PATCH /:id/unassign` keep
- Audit log với action `device.unassign` + before_user_id

---

### Q4: Bulk operations (giống ADMIN_USERS Q9)

**UC cũ:** Không mention
**Industry standard:** Admin có bulk lock/assign

**Em recommend:**
- Add `PATCH /api/v1/devices/bulk-lock` (lock/unlock nhiều devices)
- Add `PATCH /api/v1/devices/bulk-unassign` (return về kho)
- KHÔNG bulk delete (safety, giống users)

**Anh decision:** ☑ **Em recommend** — bulk lock + unassign, NO bulk delete

**Impact:**
- Add endpoints:
  - `PATCH /api/v1/devices/bulk-lock` body `{ device_ids: [], lock: true/false }`
  - `PATCH /api/v1/devices/bulk-unassign` body `{ device_ids: [] }`
- FE: checkbox column + action bar
- Audit log mỗi device
- KHÔNG bulk delete (safety)

---

### Q5: Email notify khi lock device

**Use case:** User đang dùng smartwatch, admin lock device → user không nhận được vitals → confused

**Em recommend:**
- **Push notification** (qua FCM) cho user nếu device đang assigned + user có FCM token
- **Email fallback** nếu không có FCM token
- Content: "Thiết bị [name] đã bị khóa bởi quản trị viên. Liên hệ support nếu cần."

**Anh decision:** ☑ **Em recommend** — Push notify + email fallback

**Impact:**
- Nếu device.user_id NOT NULL và user có FCM token → gửi FCM push
- Fallback email nếu không có FCM token
- Template:
  - Push: "Thiết bị [name] đã bị khóa bởi quản trị viên. Liên hệ support nếu cần."
  - Email: tương tự với support contact
- Async send (không block API response)
- Cross-ref UC031 notification module

---

### Q6: View detail enriched (giống ADMIN_USERS Q8)

**UC cũ (Alt 4.c):** Detail hiển thị: model, firmware, MAC, pin, signal, last_seen_at, calibration_data

**Em đề xuất thêm:**
- Owner user info (name + email + phone) nếu assigned
- Last 10 vitals submission timestamps
- Battery history graph (last 30 days)
- Assignment history (audit log mọi assign/unassign event)
- Active alerts (nếu có)

**Em recommend:** **Add enriched detail** — admin diagnostic info.

**Anh decision:** ☑ **Em recommend** — enriched detail

**Anh add (FE design guideline):**
- FE thiết kế detail page **gom nhóm hợp lý**:
  - **Group A**: Thiết bị settings (device_name, type, model, firmware, MAC, calibration_data, status)
  - **Group B**: Owner info (nếu assigned: user name, email, phone, last login)
  - **Group C**: Activity (last_seen_at, battery history graph, vitals submission timeline)
  - **Group D**: Transfer history (assign/unassign audit logs)
  - **Group E**: Active alerts (nếu có)
- UI: collapsible sections hoặc tabs
- UC v2 reflect grouping trong NFR section

**Impact:**
- BE endpoint: `GET /api/v1/devices/:id?include=owner,activity,transfers,alerts`
- FE: refactor DeviceDetail page theo grouping schema

---

### Q7: Search + Filter expanded

**UC cũ (Main + NFR):**
- Search: name, serial, user (email/code)
- Filter: Active/Inactive, Có chủ/Chưa có chủ

**Em recommend confirm + thêm:**
- Search: device_name + serial_number + mac_address + owner_email
- Filter:
  - Status: active / locked / unassigned / deleted
  - Device type (smartwatch/sensor/etc — dropdown)
  - Battery range (< 20% — battery low alert)
  - Last seen: < 1h / < 1 ngày / > 1 tuần (offline detection)
- Sort: last_seen_at DESC (default), created_at, battery_level

**Anh decision:** ☑ **Em recommend** — expanded search/filter

**Spec confirmed:**
- **Search**: `device_name` + `serial_number` + `mac_address` + `owner_email` (LIKE %query%, sanitize)
- **Filter**:
  - Status: active / locked / unassigned / deleted / all
  - Device type: dropdown (smartwatch/sensor/etc — TBD list trong UC v2)
  - Battery range: all / < 20% (low) / < 50% (med) / > 50% (high)
  - Last seen: all / < 1h / < 1 day / > 1 week (offline)
- **Sort**: last_seen_at DESC (default), created_at, battery_level
- **Pagination**: 20/page

---

### Q8: Device transfer history

**UC cũ (BR-025-03):** Audit log mọi assign/unassign
**Code:** Em assume có (consistent với pattern), nhưng UC chưa note explicit về transfer history view

**Em recommend:**
- Add UI tab "Transfer History" trong device detail page
- Endpoint `GET /devices/:id/history` → trả về audit logs filtered cho device
- Format: `[date] [admin] assigned to [user]` hoặc `[date] [admin] unassigned from [user]`

**Anh decision:** ☑ **Em recommend** — transfer history view

**Impact:**
- BE endpoint: `GET /api/v1/devices/:id/history?limit=20`
- Service query `audit_logs` với `entity_type='device' AND entity_id=:id AND action IN ('device.assign', 'device.unassign')`
- Response format: `[{ date, admin_name, action, before_user, after_user, ... }]`
- FE: Tab "Transfer History" trong DeviceDetail page (Group D theo Q6 grouping)

---

### Q9: Auto-detect offline devices

**Industry standard:** IoT admin panel có alert khi device offline lâu

**Em đề xuất:**
- Background job (cron mỗi 5 phút) check `last_seen_at < NOW() - 1h` → flag "offline"
- Admin dashboard widget "Offline devices: N"
- Email/push admin nếu > 10% devices offline đồng thời (system-wide issue)

**Em recommend:**
- **MVP đồ án 2:** Chỉ flag offline trong list view (badge "Offline" nếu last_seen > 1h). Không cron job, không alert system-wide.
- **Phase 5+:** Cron + dashboard widget + admin alert.

**Anh decision:** ☑ **Em recommend** — MVP badge only

**Impact:**
- **MVP (Phase 4):**
  - List view: badge "Offline" (red) nếu `last_seen_at < NOW() - 1 hour`
  - Detail view: hiển thị "Last seen: X ago" với color-code
  - KHÔNG tạo cron job
  - KHÔNG dashboard widget
  - KHÔNG admin alert system
- **Defer Phase 5+:**
  - Cron mor 5 phút scan offline
  - Dashboard widget "Offline devices: N"
  - Alert system-wide nếu > 10% offline đồng thời

---

## 🆕 Features anh nghĩ ra

- **FE design guideline cho DeviceDetail** (Q6 anh add):
  - Gom nhóm các thiết bị settings (config) → 1 group
  - Gom nhóm thong tin user (owner) → 1 group
  - Activity, history, alerts → các groups riêng
  - Implementation: collapsible sections hoặc tabs
  - UC v2 add vào NFR Usability + dedicated FE Design Guideline section

---

## ❌ Features anh muốn DROP

- **Bulk delete** (Q4 — safety, force individual confirm)
- **PUT routes duplicates** (Q2 — anti-REST)
- **Cron job offline detection** (Q9 — defer Phase 5+)
- **Dashboard widget offline count** (Q9 — defer Phase 5+)

---

---

### Q10: Dual-track Mobile BE admin CRUD — strategy?

**Context (post-cross-repo-verify):**
- HealthGuard admin BE `/api/v1/devices/*` (UC025 admin web flow)
- Mobile BE admin `/mobile/admin/devices/*` (IoT SIM provisioning, internal-only)
- Both write cùng DB `devices` table, no sync, no shared validation/audit

**Risk:**
- IoT SIM provision device → admin web KHÔNG biết (audit log rời rạc)
- Admin web lock device → IoT SIM không nhận signal (provisioning bị bỏ qua state)
- Bug: 2 admins (web + IoT SIM) cùng sửa 1 device same time → race condition

**Em recommend Option A:**
- **Phase 4 keep separate tracks** (không unify Phase 4 vì migration risky)
- **Document UC025 v2** clear scope: UC025 admin web track only; Mobile BE admin track là "DevOps internal" (IoT SIM/firmware provisioning), không thuộc admin scope
- **Phase 5+ unify**: cả 2 tracks merge thành 1 track admin BE (HealthGuard) + admin BE expose internal endpoints `/api/v1/internal/devices/*` cho IoT SIM — tương đồng với current `/api/v1/internal/websocket/emit-emergency` pattern

**Trade-off vs Option B (unify ngay Phase 4):**
- Option B = ~6h migration: rewrite IoT SIM client + add HealthGuard internal device endpoints + retest e2e
- Option B = risk break IoT SIM → fall flow bị ảnh hưởng
- Option A = scope minimal Phase 4, document clear chỉ cho Phase 5+

**Anh decision:**
- ✅ **Option A: Keep separate Phase 4 + document UC025 v2 scope clear (em recommend)** ← anh CHỌN
- ☐ Option B: Unify Phase 4 (rewrite IoT SIM client + admin BE internal endpoints, ~6h)
- ☐ Option C: Drop Mobile BE admin track (move IoT SIM gọi qua HealthGuard admin BE direct)
- ☐ Khác: ___

---

### Q11: Assign contract mismatch (admin web vs Mobile BE admin)

**Inconsistency cross-track:**

| Track | Verb | Path | Body |
|---|---|---|---|
| HealthGuard admin BE | `PATCH` | `/api/v1/devices/:id/assign` | `{ userId: number }` |
| Mobile BE admin | `POST` | `/mobile/admin/devices/:id/assign` | `{ user_email: string }` |

**Em recommend Option A:**
- **Document UC025 v2** explicit: HealthGuard admin BE track `userId` (admin web search user qua autocomplete → có ID); Mobile BE admin track `user_email` (IoT SIM chỉ có email reference)
- **Keep contracts separate** Phase 4 (không force-unify, 2 tracks designed cho 2 use case khác nhau)
- **Phase 5+ unify** khi merge 2 tracks (Q10 Phase 5+)

**Anh decision:**
- ✅ **Option A: Document Phase 4 + unify Phase 5+ (em recommend)** ← anh CHỌN
- ☐ Option B: Force-unify Phase 4 (rewrite client — break IoT SIM)
- ☐ Khác: ___

---

### Q12: Activate/Deactivate vs Lock/Unlock semantics

**Inconsistency:**
- Mobile BE admin: `POST /mobile/admin/devices/:id/activate` + `/deactivate` (lifecycle, có thể liên quan provisioning state)
- HealthGuard admin BE: `PATCH /api/v1/devices/:id/lock` (toggle `is_active` boolean)
- Cả 2 ghi cùng `devices.is_active` field nhưng semantics khác.

**Risk:**
- IoT SIM deactivate device for testing → admin web thấy "locked" (true/false toggle nhưng hiểu nhầm action)
- Confusion semantic: admin lật thấy "locked" → unlock → IoT SIM chức giờ activated trở lại (không phai user-aware action)

**Em recommend Option A:**
- **UC025 v2 Alt 4.b update wording**: "Khóa thiết bị (admin moderation, lời với user)" — distinguishing với IoT SIM activate (provisioning lifecycle).
- **Document `is_active` field 2 semantics**: provisioning state (IoT SIM) + admin moderation flag (admin web). Cả 2 conflict.
- **Phase 4 fix**: Add `is_locked` BOOLEAN tracking admin moderation separately; `is_active` chỉ dành cho provisioning lifecycle (~2h: schema + migration + service updates)
- **Phase 5+** rationalize hoàn toàn khi unify 2 tracks (Q10)

**Anh decision:**
- ✅ **Option A: Add `is_locked` field separation Phase 4 (em recommend)** ← anh CHỌN
- ☐ Option B: Document UC025 v2 clarify only (no schema change Phase 4) — keep semantics mập mờ, accept risk
- ☐ Option C: Force-unify Phase 4 (lock = deactivate, drop activate hoặc lock concept) — break IoT SIM provisioning flow
- ☐ Khác: ___

---

### Q13: UC025 v2 mention Mobile BE `/mobile/admin/*` track + IoT SIM scope

**Hiện tại UC025 v2 chỉ mention HealthGuard admin BE track**, KHÔNG document:
- IoT SIM provisioning track
- Mobile BE admin namespace existence + scope (DevOps-only)
- Contract differences (Q11)
- Semantic differences (Q12)

**Em recommend Option A:**
- **UC025 v2 add section "Cross-repo Device CRUD Architecture"**:
  - 3 tracks list (admin web, Mobile BE admin, Mobile BE user)
  - Scope clarification: UC025 only HealthGuard admin BE track
  - IoT SIM provisioning Track = DevOps internal scope, không thuộc admin role
  - Mobile BE user track = UC040-042 (mobile pair)
- **Add NFR cross-track sync**: design intent là keep separate, accept rare race condition (Phase 4); unify Phase 5+

**Anh decision:**
- ✅ **Option A: UC025 v2 add cross-repo architecture section (em recommend)** ← anh CHỌN
- ☐ Option B: Skip UC update (DevOps scope khong liên quan admin role)
- ☐ Khác: ___

---

### Q14: Heartbeat endpoint owner verify

**Context:**
- Mobile BE admin endpoint `POST /mobile/admin/devices/:id/heartbeat` ĐÃ EXIST
- IoT SIM client `update_heartbeat` method REMOVED dead code (`backend_admin_client.py:252`)
- IoT SIM hiện tại không gọi heartbeat endpoint qua client class
- Last_seen_at field update qua đâu? Telemetry path? Other?

**Phase 4 task**:
- Verify ai update `devices.last_seen_at` actual current state (~30min grep)
- Nếu KHÔNG ai update → last_seen_at always NULL → admin offline detection (UC025 v2 Q9 badge) BROKEN
- Có thể telemetry alert/vitals push update (verify)

**Em recommend Option A:**
- **Phase 4 verify** (~30min): grep `last_seen_at` write paths trong Mobile BE
- **Nếu broken**: add update path (telemetry alert ingest update last_seen_at, ~30min fix)
- **Document UC025 v2 BR-025-04 (NEW)**: `last_seen_at` updated via telemetry/heartbeat path X

**Anh decision:**
- ✅ **Option A: Phase 4 verify + fix nếu broken (em recommend)** ← anh CHỌN
- ☐ Option B: Skip verify (assume work) — risk broken offline detection
- ☐ Khác: ___

---

## 📊 Drift summary (CONFIRMED)

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC025 Manage Devices | **Major update** Q1-Q9 + Q10-Q14 cross-repo (add bulk, unassign explicit, push notify, enriched detail, expand search, transfer history, offline MVP, **3-tracks scope clarify, contract mismatch document, lock vs activate semantic, heartbeat verify**) | UC025 v2 (cross-repo cleanup section NEW) |

### Code impact (CONFIRMED)

| Phase 1 finding | Status after Phase 0.5 | Phase 4 task |
|---|---|---|
| PUT duplicates 4 cặp | Q2: REMOVE | P2 (~15 min) |
| Import CSV missing | Q1: **DEFER Phase 5+** | (none) |
| Unassign UC unclear | Q3: UC v2 add Alt 4.f | (doc only) |
| Email/push notify on lock | Q5: implement push + email fallback | P2 (~3h coord UC031) |
| Bulk operations missing | Q4: bulk-lock + bulk-unassign | P3 (~3h) |
| Detail view minimal | Q6: enriched + FE grouping | P3 (~4-5h BE+FE) |
| Search/filter narrow | Q7: expanded scope | P3 (~2h) |
| Transfer history view | Q8: endpoint + FE tab | P3 (~2h) |
| Offline detection | Q9: MVP badge | P3 (~1h) |
| 3-tracks Mobile BE admin (Q10) | Document UC025 v2 + Phase 5+ unify (D-DEV-10) | 0h Phase 4 + UC update | 🟢 Doc only |
| Assign contract mismatch (Q11) | Document UC025 v2 + Phase 5+ unify (D-DEV-11) | 0h Phase 4 + UC update | 🟢 Doc only |
| Activate/Lock semantic conflict (Q12) | Add `is_locked` field separation Phase 4 (D-DEV-12) | `feat(devices): add is_locked field separate moderation from lifecycle is_active` (~2h: schema + migration + service updates) | 🟡 Schema |
| UC025 v2 cross-repo architecture (Q13) | Add section UC025 v2 (D-DEV-13) | 0h code + UC update | 🟢 Doc only |
| Heartbeat owner verify (Q14) | Phase 4 verify + fix nếu broken (D-DEV-14) | `verify(devices): last_seen_at update path Mobile BE` (~30min verify, ~30min fix nếu broken) | 🟡 Bug |

---

## 📝 Anh's decisions log (CONFIRMED 2026-05-12, Q10-Q14 anh chọn theo em recommend sau cross-repo verify)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-DEV-01 | Import CSV/Excel | **B. Defer Phase 5+** | Đồ án 2 manual đủ, tiết kiệm effort |
| D-DEV-02 | PUT duplicates | **Drop** | REST clean, consistent ADMIN_USERS |
| D-DEV-03 | Unassign UC coverage | **UC v2 add Alt 4.f** | UC khop code |
| D-DEV-04 | Bulk operations | **Bulk lock + unassign, NOT delete** | Productivity, safety |
| D-DEV-05 | Notify on lock | **Push + email fallback** | UX consistent UC031 |
| D-DEV-06 | Detail enriched + FE grouping | **Enrich + FE thiết kế gom nhóm** | Forensic info; UX clear |
| D-DEV-07 | Search/filter expanded | **Em recommend** | Admin productivity |
| D-DEV-08 | Transfer history view | **Add endpoint + FE tab** | Audit trail visibility |
| D-DEV-09 | Offline detection | **MVP badge only** | YAGNI; defer cron Phase 5+ |
| D-DEV-10 | 3-tracks Mobile BE admin | **Keep separate Phase 4 + document UC025 v2 scope; Phase 5+ unify** | Migration risky Phase 4; document scope cho UC025 admin only; IoT SIM provisioning track = DevOps |
| D-DEV-11 | Assign contract mismatch | **Document UC025 v2 + Phase 5+ unify** | 2 tracks designed cho 2 use case khác; force-unify break IoT SIM |
| D-DEV-12 | Activate/Lock semantic conflict | **Add `is_locked` field separation Phase 4** | Cả 2 tracks ghi cùng `is_active` với semantics khác → confusion; separate field cleaner |
| D-DEV-13 | UC025 v2 cross-repo architecture section | **Add section UC025 v2** | UC chưa document 3 tracks; maintainer không biết scope; necessary clarity |
| D-DEV-14 | Heartbeat owner verify | **Phase 4 verify + fix nếu broken** | last_seen_at field cần update path; admin offline detection (Q9) phụ thuộc; verify Phase 4 |

---

## 🔁 Impact on Phase 4 fix plan (CONFIRMED)

### Phase 4 DEVICES backlog

| # | Task | Priority | Effort |
|---|---|---|---|
| 1 | Q2 remove PUT duplicates (4 routes) | P2 | 15 min |
| 2 | Q5 push notify + email fallback on lock | P2 | 3h |
| 3 | Q4 bulk-lock + bulk-unassign endpoint + FE | P3 | 3h |
| 4 | Q6 enriched detail (BE include + FE grouping) | P3 | 4-5h |
| 5 | Q7 search/filter expand | P3 | 2h |
| 6 | Q8 transfer history endpoint + FE tab | P3 | 2h |
| 7 | Q9 offline badge MVP | P3 | 1h |
| 8 | Update UC025 v2 doc | P3 doc | done now |

**DEVICES module total Phase 4 effort:** ~15-17h.

### Tasks REJECTED / DEFERRED

- ~~Import CSV/Excel endpoint~~ (Q1 → defer Phase 5+)
- ~~Bulk delete~~ (Q4 → safety)
- ~~Cron offline detection~~ (Q9 → defer Phase 5+)
- ~~Dashboard widget offline count~~ (Q9 → defer Phase 5+)

---

## Cross-references

- UC025 cũ: `Resources/UC/Admin/UC025_Manage_Devices.md`
- UC025 v2 (output): `Resources/UC/Admin/UC025_Manage_Devices_v2.md`
- UC040/041/042 (mobile user pair) — wave 5 mobile review
- Phase 1 audit: M02, M03
- ADMIN_USERS Q4/Q9: same REST clean + bulk pattern (D-USERS-04, D-USERS-09)
- Notification UC031: cross-ref cho Q5 (push notification)
- **Cross-repo Mobile BE admin track (Q10-Q12, NEW)**:
  - Routes: `health_system/backend/app/api/routes/admin.py:14-281` (prefix `/admin` mount under `/mobile`)
  - Service: `health_system/backend/app/services/admin_device_service.py`
  - Resolved path: `/mobile/admin/devices/*` (admin.py prefix `/admin` + api/router.py prefix `/mobile`)
  - Auth: `require_internal_service` (internal-secret header, không JWT)
- **Cross-repo Mobile BE user track (Q10, NEW)**:
  - Routes: `health_system/backend/app/api/routes/device.py:20-185` (prefix `/devices`, NO admin namespace)
  - Resolved path: `/mobile/devices/*` (api/router.py prefix `/mobile`)
  - Auth: user JWT (`get_current_user`)
  - UC ref: UC040-042 mobile pair flows
- **Cross-repo IoT SIM client (Q10, verified)**:
  - HTTP client: `Iot_Simulator_clean/api_server/backend_admin_client.py:43-258` (sync + async modes)
  - Base URL resolve: `HEALTH_BACKEND_URL` env var (default `http://localhost:8000`) + path `/mobile/admin`
  - Methods: `list_devices`, `create_device`, `delete_device`, `assign_device(email)`, `activate_device`, `deactivate_device`, `find_user_by_email`
  - Removed dead code: `update_heartbeat` (Q14 verify Phase 4)
- **Cross-repo Mobile BE Heartbeat endpoint (Q14)**:
  - Endpoint exists: `health_system/backend/app/api/routes/admin.py:243-281` (`POST /mobile/admin/devices/:id/heartbeat` body `{battery_level, signal_strength}`)
  - Có thể caller đã chuyển sang telemetry path — verify Phase 4
