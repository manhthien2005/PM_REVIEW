# Intent Drift Review — `HealthGuard / CONFIG`

**Status:** � Confirmed (anh chọn theo em recommend toàn bộ)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** CONFIG (System global settings — AI, Notification, Clinical Defaults, Maintenance)
**Related UCs (old):** UC024 (Configure System)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12

---

## 🎯 Mục tiêu doc này

Capture intent cho CONFIG module. UC024 cũ làm memory aid. Output = UC024 v2.

---

## 📚 Memory aid — UC024 cũ summary

**5 dòng:**
- Actor: **Super Admin** (UC nói super_admin role separate, hoặc permission tương đương)
- Main: 9 bước (truy cập → render 4 tabs → edit → save → re-auth password → validate → save DB + Pub/Sub Redis cache invalidate → notify "1-2 phút lan tỏa")
- 4 tab nhóm config:
  1. **AI & Fall Detection**: confidence_threshold, auto_sos_countdown_sec, enable_auto_sos
  2. **Communication**: Push only (đã DROP SMS/Voice)
  3. **Clinical Defaults**: SpO2 Min, HR Min/Max
  4. **Maintenance**: maintenance_mode (admin bypass), session_timeout_minutes
- Alt: 4.a Sai password, 4.b Logic invalid (SpO2 > 100, HR Min > Max)
- BR-024-01 Re-auth password, BR-024-02 Audit log, BR-024-03 Pub/Sub Redis cache invalidate
- NFR: Read < 50ms (cache memory), DB rollback nếu lỗi, Tooltip giải thích params

---

## 🔧 Code state — what currently exists

**Routes (`settings.routes.js`):**

```
authenticate + requireAdmin — both routes (NO super_admin separate)

GET    /api/v1/settings    list all settings (orderBy setting_group ASC)
PUT    /api/v1/settings    update settings (body: { password, settings })
```

**Validation (route-level):**
- `password` required string
- `settings` required object (free-form, validated trong service)

**Service (`settings.service.js`):**

- ✅ Re-auth password (BR-024-01) với `bcrypt.compare`
- ✅ Audit log success + failure (BR-024-02) với `old_values + new_values`
- ✅ Transaction wrapping (BR-024-02 + atomicity)
- ✅ Per-setting `is_editable` flag check (defense-in-depth)
- ✅ Logic validation **richer than UC**:
  - `vitals_default_thresholds`: HR critical/warning min/max, SpO2 0-100, BP sys/dia, ranges hợp lý
  - `vitals_sleep_thresholds`: osa_alert_spo2, nocturnal_tachy_hr, apnea_rr (ranges)
- ❌ **NO cache layer** — mỗi GET = DB query (NFR < 50ms violated)
- ❌ **NO Pub/Sub Redis** publish on update (BR-024-03 violated)

**Phase 1 audit findings (relevant):**
- M04 Services 🟢 R3 reference pattern (re-auth + audit log)
- M02 Routes: PUT semantics correct cho CONFIG (full replace settings object)

**Missing vs UC024:**
- Super Admin role separate
- Pub/Sub Redis cache invalidation
- Cache layer for read performance
- Maintenance mode middleware (admin bypass)
- Some fields: confidence_threshold, auto_sos_countdown_sec, enable_auto_sos, session_timeout_minutes (UC mention nhưng không thấy validate explicit)

---

## 💬 Anh react block

> Em đề xuất default — anh tick override nếu khác.

---

### Q1: Super Admin role separate?

**UC cũ (Actor):** "Quản trị viên cấp cao (Super Admin)" — implies role `super_admin` separate
**Code:** Chỉ có `user` / `admin` (per ADMIN_USERS D-USERS-07 quyết định giữ simple)

**Implications:**
- Nếu add super_admin → schema migration + middleware `requireSuperAdmin` + permission system
- Nếu giữ admin only → mọi admin đều có quyền config (rủi ro nếu admin compromised)

**Em recommend:**
- **Giữ admin only** (consistent ADMIN_USERS) cho đồ án 2 scope
- Defense-in-depth alternatives:
  - Re-auth password mỗi lần save (đã có ✓)
  - Audit log mọi change (đã có ✓)
  - Setting `is_editable` flag per-setting (đã có ✓)
- UC v2 update Actor: "Quản trị viên (Admin)" (drop super_admin distinction)

**Anh decision:**
- ✅ **Em recommend (admin only, consistent)** ← anh CHỌN
- ☐ Add super_admin role (schema + middleware change)
- ☐ Khác: ___

---

### Q2: Cache invalidation Pub/Sub Redis (BR-024-03)

**UC cũ (BR-024-03):** "Phát tín hiệu Pub/Sub Redis để clear cache cho Workers"
**Code:** KHÔNG có Redis publish. Mọi service đọc settings từ DB direct.

**Implications:**
- Workers (vital processor, SOS detector, notification) nếu cache settings local → không biết update → dùng config cũ tới khi restart
- HealthGuard scope đồ án 2: chỉ admin web (không có separate worker process), nên impact thấp

**Em recommend:**
- **Defer Phase 5+** cho production scale. Đồ án 2 không có worker pool, mỗi request DB read settings cũng OK.
- Phase 4: chỉ implement cache layer (Q3 sau) cho NFR < 50ms.
- Phase 5+: Pub/Sub Redis khi scale ra worker pool.

**Anh decision:**
- ✅ **Em recommend (defer Pub/Sub Phase 5+)** ← anh CHỌN
- ☐ Implement now (~3-4h Redis setup + publish)
- ☐ Drop entirely (UC update remove BR-024-03)
- ☐ Khác: ___

---

### Q3: Cache layer for read performance (NFR < 50ms)

**UC NFR:** Đọc cấu hình < 50ms (cache ở memory backend)
**Code:** Mỗi GET = DB query (Postgres roundtrip ~10-50ms tùy network)

**Em recommend:**
- **In-memory cache** đơn giản với TTL 5 phút (node-cache hoặc Map<setting_key, value>)
- Invalidate khi PUT `/settings` complete
- KHÔNG cần Redis cho đồ án 2 (single instance)

**Implementation:**
- `settings.service.js getCachedSettings()` check cache first, fallback DB
- `settings.service.js updateSettings()` clear cache after transaction commit
- TTL 5 phút (nếu cache stale, FE retry vẫn lấy fresh)

**Anh decision:**
- ✅ **Em recommend (in-memory cache, simple)** ← anh CHỌN
- ☐ Skip cache (DB fast enough đồ án 2 demo)
- ☐ Implement Redis cache (heavy, defer Phase 5+)
- ☐ Khác: ___

---

### Q4: Maintenance mode middleware

**UC cũ:** `maintenance_mode = true` → user thường thấy "Đang bảo trì", admin bypass để test
**Code:** Setting field có thể tồn tại trong DB (em chưa verify), nhưng KHÔNG có middleware enforce

**Em recommend:**
- Add middleware `maintenanceCheck` ở app.js trước routes:
  - Check `system_settings.maintenance_mode === true`
  - Nếu admin (req.user.role === 'admin') → bypass
  - Nếu user thường → response 503 "Đang bảo trì"
- Whitelist endpoints luôn accessible: `/auth/login` (admin login để bypass), `/health` (health check)

**Anh decision:**
- ✅ **Em recommend (add middleware ~1h)** ← anh CHỌN
- ☐ Skip (đồ án 2 demo không cần)
- ☐ Khác: ___

---

### Q5: Settings schema completeness

**UC cũ mention các fields:**
- AI: confidence_threshold, auto_sos_countdown_sec, enable_auto_sos
- Clinical: SpO2 Min, HR Min/Max
- Maintenance: maintenance_mode, session_timeout_minutes
- Push notification config

**Code validate (em verify từ service):**
- ✅ vitals_default_thresholds (rich: HR/SpO2/RR/BP critical+warning)
- ✅ vitals_sleep_thresholds (OSA, nocturnal tachy, apnea RR)
- ❓ confidence_threshold, auto_sos_countdown_sec, enable_auto_sos — em chưa verify trong DB seed
- ❓ maintenance_mode, session_timeout_minutes
- ❓ Push notification settings

**Em recommend:**
- Phase 4 verify DB seed `system_settings` table có đầy đủ keys per UC
- Add validation cho các fields còn thiếu trong service:
  - `confidence_threshold`: number 0.0-1.0
  - `auto_sos_countdown_sec`: integer 5-60
  - `enable_auto_sos`: boolean
  - `maintenance_mode`: boolean
  - `session_timeout_minutes`: integer 5-1440 (max 24h)
- UC v2 list explicit tất cả setting keys với type + range

**Anh decision:**
- ✅ **Em recommend (verify + add validations)** ← anh CHỌN
- ☐ Defer (chỉ keep current vitals validation)
- ☐ Khác: ___

---

### Q6: Restore defaults feature

**UC cũ:** Không mention
**Industry standard:** Admin panel có "Restore defaults" nếu admin lỡ tay set sai

**Em recommend:**
- Add endpoint `POST /api/v1/settings/restore-defaults` body `{ password, group? }`
- Restore từ `system_settings_defaults` table (seed values) hoặc hardcoded constants
- Optional `group`: chỉ restore 1 group (AI / Clinical / Maintenance / All)
- Audit log `action='settings.restore_defaults'`
- Re-auth password required

**Em đề xuất default:** **Add** — admin tool safety net.

**Anh decision:**
- ✅ **Em recommend (add restore defaults endpoint)** ← anh CHỌN
- ☐ Skip (admin manual fix nếu lỡ)
- ☐ Khác: ___

---

### Q7: Settings change history view

**UC cũ (BR-024-02):** Audit log mọi change. UC không nói explicit về UI để admin xem history.
**Code:** Audit log có `old_values + new_values` ✓

**Em recommend:**
- Add UI tab "Settings History" trong Admin Dashboard config page
- Endpoint `GET /api/v1/settings/history?limit=50` query audit_logs với `action='settings.updated' AND status='success'`
- Hiển thị timeline: `[date] [admin] thay đổi [keys] từ [old] → [new]`
- Filter by setting_key + date range

**Anh decision:**
- ✅ **Em recommend (settings history view)** ← anh CHỌN
- ☐ Skip (admin tự query audit_logs nếu cần)
- ☐ Khác: ___

---

### Q8: Diff preview before save

**UC cũ:** Admin click "Lưu Thay Đổi" → password modal → save
**Em đề xuất thêm bước:** Show diff modal trước password modal

**Flow proposed:**
1. Admin edit fields trong form
2. Click "Lưu Thay Đổi"
3. **NEW:** Modal "Xem trước thay đổi" hiển thị side-by-side:
   - Field name | Old value | New value (highlighted)
4. Admin confirm → password modal
5. Password modal → save

**Em recommend:**
- **Add** — giảm rủi ro admin lỡ tay save nhầm
- BE không thay đổi (FE-only feature)
- UC v2 update flow

**Anh decision:**
- ✅ **Em recommend (add diff preview modal)** ← anh CHỌN
- ☐ Skip (current flow đủ)
- ☐ Khác: ___

---

### Q9: Tooltips UI giải thích params

**UC NFR:** Tooltip hover bên cạnh từng input field
**Code:** FE responsibility, BE không liên quan
**Em đề xuất content:** UC v2 cung cấp danh sách tooltip text (Vietnamese) cho từng setting

**Em recommend:**
- UC v2 thêm bảng "Setting field reference" với:
  - setting_key | type | range | default | tooltip Vietnamese
- FE consume bảng này để render tooltip + validation hint

**Anh decision:**
- ✅ **Em recommend (UC v2 đính kèm setting field reference)** ← anh CHỌN
- ☐ Skip (FE tự viết tooltip)
- ☐ Khác: ___

---

## 🆕 Features anh nghĩ ra

_(anh add nếu có)_

---

## ❌ Features anh muốn DROP

_(anh add nếu có)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC024 Configure System | Major updates | `UC024_Configure_System_v2.md` |

Key changes UC v2:
- Drop Super Admin distinction (Actor = Admin)
- BR-024-03 modified: Pub/Sub Redis defer Phase 5+, replaced by in-memory cache invalidation
- Add detailed setting field reference table (key, type, range, default, tooltip Vietnamese)
- Add Alt Flow 4.c Restore defaults
- Add Alt Flow 4.d Diff preview modal
- Add Main Flow step pre-7: Diff preview modal
- Add Section 7: Settings history view UI requirement
- Add NFR Maintenance mode middleware enforcement

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task |
|---|---|---|
| Super admin role missing | Drop UC mention (D-CFG-01) | UC024 v2 update Actor |
| Pub/Sub Redis invalidation missing (BR-024-03) | Defer (D-CFG-02) | None Phase 4; Phase 5+ stub |
| Cache layer missing (NFR < 50ms) | Add in-memory (D-CFG-03) | `feat: settings cache layer` (~3h) |
| Maintenance mode middleware missing | Add (D-CFG-04) | `feat: maintenance mode middleware` (~1h) |
| Settings schema incomplete | Verify + extend (D-CFG-05) | `feat: complete settings validation` (~3h) |
| Restore defaults feature missing | Add (D-CFG-06) | `feat: settings restore defaults endpoint` (~2h) |
| Settings history view missing | Add (D-CFG-07) | `feat: settings history endpoint + UI` (~3h) |
| Diff preview modal missing | Add FE (D-CFG-08) | `feat: settings diff preview modal` (FE only ~2h) |
| Setting field tooltips missing | Add UC v2 reference (D-CFG-09) | `docs: setting field reference table in UC024 v2` (done in UC v2) |

**Estimated Phase 4 effort:** ~14h (BE 12h + FE 2h)

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-CFG-01 | Super admin role separate | **Drop — admin only** | Consistent ADMIN_USERS D-USERS-07; defense-in-depth qua re-auth + audit + is_editable |
| D-CFG-02 | Pub/Sub Redis cache invalidation | **Defer Phase 5+** | Đồ án 2 không có worker pool; mỗi service đọc DB direct OK |
| D-CFG-03 | In-memory cache layer | **Add (TTL 5min)** | NFR < 50ms; simple Map + TTL invalidate on update |
| D-CFG-04 | Maintenance mode middleware | **Add** | Trải nghiệm tốt hơn 503 response thay vì lỗi từng endpoint |
| D-CFG-05 | Settings schema completeness | **Verify + extend** | Add validate cho confidence_threshold, auto_sos_countdown_sec, enable_auto_sos, session_timeout_minutes, maintenance_mode |
| D-CFG-06 | Restore defaults endpoint | **Add** | Admin tool safety net; re-auth + audit + per-group |
| D-CFG-07 | Settings history view | **Add** | Tận dụng audit_logs đã có; UI tab + filter endpoint |
| D-CFG-08 | Diff preview modal | **Add (FE only)** | Giảm rủi ro lỡ tay; BE không thay đổi |
| D-CFG-09 | Setting field reference tooltip | **Add UC v2 attached table** | FE consume; UX rõ ràng |

---

## Cross-references

- UC024 cũ: `Resources/UC/Admin/UC024_Configure_System.md`
- Phase 1 audit: M02 Routes, M04 Services (R3 reference pattern)
- ADMIN_USERS D-USERS-07: keep `user`/`admin` only — Q1 consistent
- EMERGENCY UC029: cross-ref `enable_auto_sos`, `auto_sos_countdown_sec`, `confidence_threshold`
- HEALTH UC028: cross-ref `vitals_default_thresholds` clinical defaults
