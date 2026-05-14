# Intent Drift Review — `health_system / SETTINGS`

**Status:** ✅ Confirmed Option A (Phase 0.5 reverify 2026-05-12 — Q1-Q4 cũ superseded; endpoint là DEAD API, drop hoàn toàn Phase 4)
**Repo:** `health_system/backend` (mobile FastAPI BE)
**Module:** SETTINGS (Global system settings + user prefs mixed)
**Related UCs (old):** **NONE** — module orphan; UC024 admin BE đã đủ source of truth
**Phase 1 audit ref:** N/A (Phase 1 chưa audit health_system, Track 2 pending)
**Date prepared:** 2026-05-12
**Date revised:** 2026-05-12 (Phase 0.5 reverify — Option A finalized, Q1-Q4 marked OVERRIDDEN)
**Question count (history):** 4 (Q1-Q4 — all OVERRIDDEN bởi Option A)

---

## 🔄 Phase 0.5 Reverify — Option A overrides Q1-Q4 cũ

> **Override reason:** Q1-Q4 cũ assume endpoint có FE consumer + cross-repo write-conflict cần split-fix. Phase 0.5 verify code thực tế (grep mobile FE + admin web) phát hiện:
>
> 1. **0 client gọi `/mobile/settings/general`** — endpoint là **DEAD API**, không phải "shared write conflict"
> 2. **5 orphan keys** (không phải 2 như Q1 cũ nói): `app_language`, `app_theme`, `default_timezone`, `maintenance_mode` (scalar), `jwt_access_expiry_minutes`
> 3. **Split-brain read priority REAL** — mobile BE đọc scalar mobile-only trước → admin BE update qua `system_security` JSON không reach mobile (đây là bug active, không "potential")
> 4. **User-pref Flutter local hợp lý hơn BE persist** — `ThemeMode`, `flutter_localizations`, device timezone không cần backend round-trip
>
> **Decision Option A:** DROP toàn bộ endpoint mobile BE (route + schema + 4 service methods). Admin BE UC024 v2 là single source of truth. Mobile BE consume internal qua `SettingsService.get_setting()` cho vitals thresholds (`telemetry.py:349`).
>
> **Detailed reasoning + verify evidence:** xem section "Em verified Phase 0.5" + "Anh's decision Option A" dưới đây. Q1-Q4 giữ lại làm audit trail (status: OVERRIDDEN).

---

## 🎯 Mục tiêu

Capture intent cho SETTINGS module mobile BE. Phase 0.5 reverify phát hiện endpoint là **dead API** (0 FE consumer) — anh chốt Option A: DROP hoàn toàn thay cho split-endpoint approach cũ.

---

## 📚 UC tham chiếu — KHÔNG CÓ

Không có UC mobile cho settings. **UC024 CONFIG đã có** cho HealthGuard admin web nhưng scope khác:
- UC024 admin: `login_attempts`, ML config, vitals thresholds (admin-only)
- Mobile BE settings: language, theme, timezone, push_notifications, maintenance_mode, session_timeout_minutes

→ **Overlap fields cross-repo:** `maintenance_mode` + `session_timeout_minutes` xuất hiện ở cả 2.

---

## 🔧 Code state — verified

### Routes (`settings.py`) — 2 endpoints

```
prefix=/settings, tags=[mobile-settings]

GET  /settings/general          Lấy global settings (any authenticated user)
PUT  /settings/general          Update settings (admin role required cho maintenance_mode)
```

### Service (`settings_service.py`) findings

**✅ Strengths:**
- Global system-level storage (table `system_settings` KEY-VALUE format)
- `updated_by=user_id` field cho trace
- In-memory cache với invalidation
- Default values fallback

**🔴 Drift findings:**

1. **NO audit_logs.create() call** trong `update_general_settings` — không thấy explicit audit log
2. **Mixed concerns endpoint:**
   - Endpoint trả/nhận CẢ user-pref (language, theme, timezone) **+** global admin (maintenance_mode, session_timeout_minutes)
   - 1 endpoint mix 2 scope khác authorization
3. **Authorization partial:** Route check `current_user.role == 'admin'` CHỈ cho `maintenance_mode`. Các field admin khác (`session_timeout_minutes`) **không có check role** → non-admin user có thể update?

### ⚠️ Cross-repo conflict với UC024 CONFIG

| Field | UC024 admin (HealthGuard) | health_system mobile BE |
|---|---|---|
| `maintenance_mode` | ❓ Em chưa verify trong UC024 | ✅ Có (admin-only) |
| `session_timeout_minutes` | ❓ Em chưa verify trong UC024 | ✅ Có (no role check?!) |
| `language` | ❌ Không có (admin scope) | ✅ Có (user-pref) |
| `theme` | ❌ Không có | ✅ Có (user-pref) |
| `timezone` | ❌ Không có | ✅ Có (user-pref) |
| `push_notifications_enabled` | ❌ Không có | ✅ Có (user-pref) |

→ **2 BEs cùng quản lý overlap fields → potential data inconsistency.**

---

## � Em verified Phase 0.5 — drift findings extended

> Sau khi anh chốt Q1-Q4 sáng 2026-05-12, em re-verify code thực tế (grep mobile FE + admin web + SQL canonical) và phát hiện thêm 3 drift quan trọng làm Q1-Q4 không đủ scope. Findings này dẫn tới Option A.

### 1. ❌ Endpoint là DEAD API (không phải shared write conflict)

- **Mobile FE grep `/settings/general` + `generalSettings` + `general_settings` trong `health_system/lib`** → **0 match**
- `lib/features/profile/screens/profile_settings_screen.dart` chỉ có toggle local "Chế độ chuyên môn" qua `secure_storage` — không gọi backend settings
- **Admin web FE cũng không gọi `/mobile/settings/general`** (admin gọi `/api/v1/settings` riêng của admin BE)

→ Endpoint mobile BE là **dead API**, không có client nào dùng. Q1-Q4 cũ implicit assume có FE consumer → assumption sai.

### 2. 🔴 5 orphan keys (không phải 2 như Q1 cũ nói)

Mobile BE `update_general_settings` upsert 5 keys không có trong `init_full_setup.sql:744-749` canonical:

| Key mobile BE upsert | Trong canonical? | Admin BE biết? | Consumer mobile BE? |
|---|---|---|---|
| `app_language` | ❌ | ❌ | **0 — dead** |
| `app_theme` | ❌ | ❌ | **0 — dead** |
| `default_timezone` | ❌ | ❌ | **0 — dead** |
| `maintenance_mode` (scalar bool) | ❌ | ❌ | Self read line 156 — split-brain |
| `jwt_access_expiry_minutes` (scalar int) | ❌ | ❌ | Self read line 165 — split-brain |

→ Mobile BE tự tạo nhiễu trên shared table. 3 keys dead (no consumer anywhere) + 2 keys split-brain với canonical JSON.

### 3. 🔴 Split-brain read priority REAL (active bug, không "potential")

`settings_service.py:165-176`:

```python
jwt_expiry_minutes = cls.get_setting("jwt_access_expiry_minutes", db, None)
session_timeout = int(
    jwt_expiry_minutes
    if isinstance(jwt_expiry_minutes, (int, float))
    else system_security.get("session_timeout_minutes", 60)
)
# Same pattern cho maintenance_mode line 172-176
```

→ Mobile BE đọc scalar mobile-only **trước**, JSON nested canonical **sau**. Sau khi mobile BE PUT 1 lần → tạo `jwt_access_expiry_minutes` scalar → từ đó về sau admin BE update `system_security.session_timeout_minutes` **không reach mobile** vì priority blocks.

→ Đây là **active bug**, không chỉ "potential conflict".

### 4. ⚠️ User-pref Flutter local hợp lý hơn BE persist

Flutter có sẵn:
- `ThemeMode.system/light/dark` qua `MaterialApp` + `SharedPreferences`
- `flutter_localizations` + `intl` cho language
- `DateTime.now().timeZoneName` cho device timezone

→ User-pref BE persist không có roadmap rõ (multi-device sync chưa scope đồ án 2). YAGNI → không cần endpoint BE.

### 5. ✅ Admin BE đã đúng UC024 v2 — không cần coordinate change

`HealthGuard/backend/src/services/settings.service.js`:
- Line 78-87 + 138-150: audit log (success + failure) với old/new values
- Line 74-89: re-auth password (`BR-024-01`)
- Line 96-109: validate `is_editable` flag (`BR-024-04`)
- Line 117-124: validate vitals threshold shape (`BR-024-05`)
- Route line 17-31: `authenticate + requireAdmin` middleware

→ Admin BE = **single source of truth đúng UC024 v2**. Mobile BE đang tạo nhiễu. Sửa mobile BE = drop, không phải sync.

---

## � Anh react block (history — Q1-Q4 OVERRIDDEN bởi Option A)

> 4 câu cũ — module nhỏ nhưng có cross-repo concern critical.
> **Status:** ⚠️ Q1-Q4 OVERRIDDEN bởi Option A sau Phase 0.5 reverify. Giữ lại làm audit trail.

---

### Q1: ⚠️ OVERRIDDEN — Cross-repo conflict — overlap với UC024 CONFIG admin

**Issue:**
- HealthGuard admin web có UC024 CONFIG quản lý system settings
- Mobile BE settings cũng có `maintenance_mode` + `session_timeout_minutes`
- 2 BEs ghi vào CÙNG bảng `system_settings`? Hay 2 bảng khác nhau?

**Em verified 2026-05-12:**
- DB `system_settings`: **SHARED 1 table** cross-repo (`SQL SCRIPTS/13_create_system_settings.sql` + populated trong `init_full_setup.sql:744-749`)
- UC024 v2: `maintenance_mode` + `session_timeout_minutes` đã chốt **admin-only** (BR-024-06)
- Code mobile BE: `settings.py:32-36` chỉ check role cho `maintenance_mode`, **KHÔNG** check role cho `session_timeout_minutes` → 🔴 **SECURITY HOLE confirmed**

**Em recommend:**
- **HealthGuard admin = source of truth** cho admin fields (UC024 v2 confirmed)
- **Mobile BE settings = READ-ONLY** cho admin fields, write CHỌN user-pref (language/theme/timezone/push)
- **Phase 4 fix security hole:** Mobile BE remove write access cho `maintenance_mode` + `session_timeout_minutes` trong PUT body (~30min)
- Q2 split endpoint sẽ tự nhiên fix hố này

**Anh decision:**
- ✅ **Em recommend (HealthGuard source of truth, mobile READ-ONLY admin fields)** ← anh CHỌN; verified shared table + security hole confirmed
- ☐ Keep both BEs write (accept duplicate risk, đồng bộ qua sync job)
- ☐ Mobile BE drop maintenance_mode + session_timeout (admin web only)
- ☐ Khác: ___

---

### Q2: ⚠️ OVERRIDDEN — Mixed concerns endpoint — split user-pref vs admin-global?

**Current:** 1 endpoint `PUT /settings/general` chứa CẢ user-pref + admin-global.

**Risk:**
- Authorization complexity (route check only `maintenance_mode`, miss `session_timeout`)
- API contract confused (FE phải biết field nào admin-only)

**Em recommend:**
- **Split thành 2 endpoints:**
  - `PUT /settings/user-prefs` — language, theme, timezone, push_notifications (any user)
  - `PUT /settings/system` — maintenance_mode, session_timeout (admin role required, có thể DROP nếu Q1 chọn READ-ONLY)
- Effort ~1h refactor + FE update

**Anh decision:**
- ✅ **Em recommend (split 2 endpoints)** ← anh CHỌN
- ☐ Keep mixed endpoint, fix authorization holes (add role check cho session_timeout)
- ☐ Khác: ___

**Phase 4 implementation:**
- `GET /settings/user-prefs` (any user) — language, theme, timezone, push_notifications
- `PUT /settings/user-prefs` (any user) — only user-pref fields
- `GET /settings/system` (admin only, hoặc READ-ONLY cho user) — maintenance_mode, session_timeout
- DROP write access admin fields cho non-admin (Q1 decision applied)

---

### Q3: ⚠️ OVERRIDDEN — Audit log missing

**Current:** `update_general_settings` không có `audit_logs.create()` call.

**Risk:** Settings changes không trace được. UC024 v2 BR-024 yêu cầu audit cho HealthGuard admin updates — cần consistent mobile BE.

**Em recommend:**
- **Add audit log** trong service: action `system.settings_updated` với `before/after` diff
- Effort ~30min

**Anh decision:**
- ✅ **Em recommend (add audit log)** ← anh CHỌN

---

### Q4: ⚠️ OVERRIDDEN — UC mapping — create UC hay sub-feature?

**Context:** Module orphan, 2 endpoints (hoặc 2 sau Q2 split).

**Em recommend (depend Q1):**
- **Nếu Q1 chọn shared table + mobile READ-ONLY admin fields:** UC024 v2 extend với section "Mobile read access" (no new UC)
- **Nếu Q1 chọn separate:** Tạo UC mobile-side cho user-pref management (UC005 Manage Profile có thể extend, hoặc UC035 mới)
- **Em prefer:** UC024 v2 extend + UC005 brief section user-pref settings

**Anh decision (OVERRIDDEN):**
- ✅ **Em recommend (UC024 v2 extend + UC005 brief user-pref)** ← anh CHỌN sáng 2026-05-12
- ⚠️ **OVERRIDDEN bởi Option A:** Không tạo/extend UC nào — admin BE UC024 v2 đủ; user-pref Flutter local không cần BE
- ☐ Create UC035 standalone Mobile Settings
- ☐ Skip UC, ADR only
- ☐ Khác: ___

---

## 🎯 Anh's decision Option A — Phase 0.5 reverify 2026-05-12

### Decision

**DROP toàn bộ endpoint mobile BE settings** (route + schema + 4 service methods). Admin BE UC024 v2 là single source of truth cho system settings. Mobile BE consume internal qua `SettingsService.get_setting()` cho vitals thresholds (`telemetry.py:349`).

### Lý do override Q1-Q4 cũ

1. **Q1-Q4 cũ assume endpoint có FE consumer** → assumption sai (0 match grep mobile FE + admin web)
2. **Phase 0.5 verify** phát hiện 5 orphan keys (không phải 2) + split-brain active (không phải potential)
3. **YAGNI cho đồ án 2:** không có roadmap multi-device sync user-pref → không cần BE persist
4. **Surgical (Karpathy):** code không trace về requirement nào → drop > rebuild
5. **Eliminate split-brain root cause:** drop write → không tạo orphan keys nữa → admin BE updates reach đúng qua `system_security` JSON

### Scope DROP cụ thể (Phase 4 backlog)

**File DELETE:**
- `health_system/backend/app/api/routes/settings.py` (whole file, 48 lines)
- `health_system/backend/app/schemas/general_settings.py` (whole file, 22 lines)

**File `settings_service.py` partial DELETE (4 methods, KEEP rest):**
- DROP `get_general_settings()` line 145-185
- DROP `update_general_settings()` line 187-298
- DROP `upsert_setting()` line 91-143 (orphan sau drop `update_general_settings`)
- DROP `invalidate_cache()` line 300-305 (orphan sau drop `upsert_setting`)
- **KEEP** `get_setting()`, `get_vitals_sleep_thresholds()`, `get_vitals_daytime_thresholds()`, `_normalize_thresholds()`, defaults dicts, `_cache`, `_CACHE_TTL_SEC` — internal consumer cho `telemetry.py:349`

**File `app/api/router.py` 2 line DELETE:**
- Line 14: `from app.api.routes.settings import router as settings_router`
- Line 26: `api_router.include_router(settings_router)`

**DB cleanup migration (separate Phase 4 task):**
- `PM_REVIEW/SQL SCRIPTS/migrations/20260512_drop_orphan_mobile_settings.sql` CREATE
- DELETE 5 orphan keys từ `system_settings` table

### Effort estimate

- Code drop: ~30min
- Migration SQL: ~5min  
- PM_REVIEW docs sync (BUILD_PHASES_API, api_contract_v1): ~10min
- **Total Phase 4:** ~45min (vs ~2h của Q1-Q4 cũ)

### Out-of-scope flag (em không lan scope)

- `SettingsService.get_vitals_daytime_thresholds()` hiện có 0 consumer (em grep verified). KEEP trong Option A vì pair với `get_vitals_sleep_thresholds` (telemetry consume). Audit riêng Phase 2 nếu cần.
- `notification_gateways` schema canonical 4-field (`sms_enabled, call_enabled, push_enabled, max_sms_per_user_daily`) vs UC024 v2 1-field (`push_notification_enabled`) — drift riêng, không trong scope SETTINGS intent doc này.
- `vitals_default_thresholds.bp_dia_warning` UC024 v2 = 100 nhưng SQL canonical (17_sleep_threshold_settings.sql) không reference → drift riêng, audit Phase 2.

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Settings export/import** — Phase 5+ enhancement
- ❌ **Settings versioning** — Phase 5+ complex
- ❌ **i18n admin templates** — overkill đồ án 2

---

## 🆕 Features mới em recommend

**Không có** — Option A drop endpoint, không add feature mới.

---

## ❌ Features em recommend DROP (Option A)

- **`GET /mobile/settings/general`** — dead API, 0 FE consumer
- **`PUT /mobile/settings/general`** — dead API + active split-brain bug
- **User-pref BE persist** (language/theme/timezone) — thay bằng Flutter local (`SharedPreferences` + `flutter_localizations`)
- **`SettingsService.update_general_settings()`** + **`upsert_setting()`** + **`invalidate_cache()`** — chỉ phục vụ endpoint dead, drop cascade
- **5 orphan keys trong DB:** `app_language`, `app_theme`, `default_timezone`, `maintenance_mode` (scalar), `jwt_access_expiry_minutes` — migration cleanup Phase 4

---

## 📊 Drift summary — Option A (Phase 0.5 reverify)

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| **NONE — orphan mobile module** | Resolved (Option A) | **Không tạo/extend UC mới.** Admin BE UC024 v2 đủ source of truth. User-pref Flutter local không cần UC. |

### Code impact (Phase 4 backlog — Option A)

| Phase 0.5 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| Dead API + 5 orphan keys + split-brain (D-SET-A) | DROP endpoint mobile BE | `refactor(mobile-be): drop dead settings endpoint + 4 service methods + router register` (~30min) | 🔴 Critical (active bug) |
| 5 orphan keys trong DB (D-SET-B) | Migration cleanup | `chore(db): migration drop 5 orphan keys từ system_settings (run staging trước)` (~5min) | 🟡 Medium |
| Internal helpers retention (D-SET-C) | KEEP `get_setting`, `get_vitals_*` | N/A — no code change | � None |
| UC mapping (D-SET-D) | Không tạo/extend UC | N/A — admin BE UC024 v2 đủ | 🟢 None |
| PM_REVIEW docs sync (D-SET-E) | Update build phase docs + API contract | `docs: remove dead settings endpoint refs trong BUILD_PHASES_API + api_contract_v1` (~10min) | 🟢 Doc |

**Estimated Phase 4 effort:** ~45min total (vs ~2h của Q1-Q4 cũ — tiết kiệm 1h15min nhờ surgical scope)

### Cross-repo coordination required

- **HealthGuard admin BE:** ✅ No change — đã đúng UC024 v2 source of truth
- **health_system mobile BE:** Phase 4 drop endpoint + 4 service methods + router register
- **Mobile FE:** ✅ No change — chưa từng dùng endpoint này (0 grep match)
- **DB:** Phase 4 migration cleanup 5 orphan keys (run staging → production)

---

## 📝 Anh's decisions log

### Active decisions — Option A (Phase 0.5 reverify 2026-05-12)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| **D-SET-A** | Mobile BE settings endpoint | **DROP hoàn toàn (Option A)** | Endpoint dead API (0 FE consumer verified); admin BE UC024 v2 đã source of truth; YAGNI đồ án 2 |
| **D-SET-B** | 5 orphan keys cleanup | **Migration SQL drop Phase 4** | `app_language`, `app_theme`, `default_timezone`, `maintenance_mode` (scalar), `jwt_access_expiry_minutes` không có trong canonical, split-brain active |
| **D-SET-C** | Internal helpers retention | **KEEP** `get_setting`, `get_vitals_sleep_thresholds`, `get_vitals_daytime_thresholds` | Consumer thực tế: `telemetry.py:349` (sleep thresholds); pair daytime giữ defensive |
| **D-SET-D** | UC mapping | **Không tạo/extend UC mới** | Admin BE UC024 v2 đủ; user-pref Flutter local (`ThemeMode`, `flutter_localizations`, device timezone) không cần BE |
| **D-SET-E** | PM_REVIEW docs sync | **Update Phase 4: BUILD_PHASES_API + api_contract_v1** | Remove dead endpoint refs sau khi code drop |

### Superseded decisions — Q1-Q4 (giữ làm audit trail)

| ID | Item | Decision cũ | Status |
|---|---|---|---|
| ~~D-SET-01~~ | Cross-repo overlap với UC024 | ~~HealthGuard source of truth, mobile READ-ONLY admin fields~~ | ⚠️ **SUPERSEDED bởi D-SET-A** — endpoint dead, drop hoàn toàn thay vì read-only |
| ~~D-SET-02~~ | Split user-pref vs admin-global endpoint | ~~Split 2 endpoints~~ | ⚠️ **SUPERSEDED bởi D-SET-A** — over-engineering cho dead API |
| ~~D-SET-03~~ | Audit log | ~~Add `audit_logs.create()` per update~~ | ⚠️ **SUPERSEDED bởi D-SET-A** — moot khi drop write endpoint |
| ~~D-SET-04~~ | UC mapping | ~~UC024 v2 extend + UC005 brief user-pref~~ | ⚠️ **SUPERSEDED bởi D-SET-D** — không cần UC user-pref |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Settings export/import | ❌ Drop (Phase 5+) |
| Settings versioning | ❌ Drop (Phase 5+ complex) |
| i18n admin templates | ❌ Drop (overkill) |

**All 3 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

### Code paths (mobile BE — Phase 4 actions)

- `health_system/backend/app/api/routes/settings.py` → **DELETE whole file Phase 4**
- `health_system/backend/app/schemas/general_settings.py` → **DELETE whole file Phase 4**
- `health_system/backend/app/services/settings_service.py` → **PARTIAL DELETE Phase 4** (4 methods, KEEP `get_setting` + `get_vitals_*`)
- `health_system/backend/app/api/router.py:14, :26` → **DELETE 2 lines Phase 4**

### Code paths (admin BE — source of truth, no change)

- `HealthGuard/backend/src/routes/settings.routes.js` — confirmed UC024 v2 compliant
- `HealthGuard/backend/src/services/settings.service.js` — confirmed audit log + re-auth + validate shapes
- `HealthGuard/backend/src/controllers/settings.controller.js`

### Mobile FE (no change — chưa từng dùng endpoint)

- `health_system/lib/features/profile/screens/profile_settings_screen.dart` — chỉ toggle clinician mode local

### DB schema

- `PM_REVIEW/SQL SCRIPTS/13_create_system_settings.sql` — canonical table def
- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:744-749` — 4 default seed keys
- `PM_REVIEW/SQL SCRIPTS/17_sleep_threshold_settings.sql` — thread `vitals_sleep_thresholds`
- `PM_REVIEW/SQL SCRIPTS/migrations/20260512_drop_orphan_mobile_settings.sql` → **CREATE Phase 4** (cleanup 5 orphan keys)

### Related UC

- `PM_REVIEW/Resources/UC/Admin/UC024_Configure_System_v2.md` — admin BE source of truth, no change
- ~~UC005 v2 extend~~ — **CANCELLED** bởi Option A

### Related ADR

- `PM_REVIEW/ADR/008-mobile-be-no-system-settings-write.md` ✅ **CREATED 2026-05-12** (cross-session memory for decision)

### Related PM_REVIEW docs (Phase 4 sync)

- `PM_REVIEW/REVIEW_MOBILE/BUILD_PHASES_API/01_CORE_AND_NOTIFICATIONS.md:28-31` → **REMOVE Section 4 Phase 4**
- `PM_REVIEW/REVIEW_MOBILE/BUILD_PHASES_API/README.md:19-20` → **REMOVE 2 checklist items Phase 4**
- `PM_REVIEW/AUDIT_2026/tier1/api_contract_v1.md:308-309` → **MARK REMOVED Phase 4**
