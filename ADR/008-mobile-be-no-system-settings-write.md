# ADR-008: Mobile BE không host system settings write — admin BE là single source of truth

**Status:** Accepted
**Date:** 2026-05-12
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, mobile-backend, health_system, healthguard, cross-repo, simplification, scope, dead-code]

## Context

Hệ thống VSmartwatch có 2 backend cùng quản lý system settings qua shared DB table `system_settings`:

- **HealthGuard admin BE** (Express + Prisma) — endpoints `GET/PUT /api/v1/settings` với re-auth password, audit log, validate vitals threshold shapes, `requireAdmin` middleware. Đã đúng UC024 v2 (BR-024-01..06).
- **health_system mobile BE** (FastAPI) — endpoints `GET/PUT /mobile/settings/general` cho phép update language/theme/timezone/push_notifications/maintenance_mode/session_timeout_minutes.

Phase 0.5 audit (`AUDIT_2026/tier1.5/intent_drift/health_system/SETTINGS.md`) ban đầu chốt Q1-Q4 với hướng "split endpoints + READ-ONLY admin fields + add audit log". Em re-verify code thực tế phát hiện:

### Findings drift cross-repo

1. **Endpoint mobile BE là DEAD API:**
   - Grep `health_system/lib` cho `/settings/general`, `generalSettings`, `general_settings` → **0 match**
   - Mobile FE settings screen (`profile_settings_screen.dart`) chỉ có toggle local "Chế độ chuyên môn" qua `secure_storage` — không gọi backend
   - Admin web FE cũng không gọi `/mobile/settings/general` (admin gọi `/api/v1/settings` riêng)

2. **5 orphan keys** mobile BE upsert vào shared table không có trong canonical (`init_full_setup.sql:744-749`):
   - `app_language`, `app_theme`, `default_timezone` — 0 consumer anywhere (dead user-pref)
   - `maintenance_mode` (scalar bool) — duplicate với `system_security.maintenance_mode` JSON
   - `jwt_access_expiry_minutes` (scalar int) — duplicate với `system_security.session_timeout_minutes` JSON

3. **Split-brain read priority REAL** (`settings_service.py:165-176`):
   - Mobile BE đọc scalar mobile-only **trước**, JSON nested canonical **sau**
   - Sau khi mobile BE PUT 1 lần → tạo `jwt_access_expiry_minutes` scalar → admin BE update qua `system_security.session_timeout_minutes` **không reach mobile** vì priority blocks
   - Đây là **active bug**, không chỉ "potential conflict"

4. **Authorization partial** (`settings.py:32-36`): chỉ check `role == 'admin'` cho `maintenance_mode`, miss `session_timeout_minutes` → non-admin update được admin field (nhưng moot vì dead API).

### Forces

- **Solo dev, đồ án 2 scope** — không có nhu cầu multi-device sync user-pref (Flutter local đủ).
- **Karpathy surgical** — mỗi line code phải trace về requirement, code không trace → drop.
- **YAGNI** — feature dead, không build feature future-hypothetical.
- **Admin BE đã đúng UC024 v2** — không cần coordinate change cross-repo.
- **Flutter ecosystem** đã có `ThemeMode`, `flutter_localizations`, `DateTime.timeZoneName` cho user-pref local không cần BE round-trip.

### Constraints

- KHÔNG được drop service helpers `get_setting()`, `get_vitals_sleep_thresholds()`, `get_vitals_daytime_thresholds()` — `telemetry.py:349` consume cho sleep context detection.
- KHÔNG được drop admin BE settings (UC024 v2 là source of truth, FE admin dashboard đang dùng).
- Phải có migration cleanup 5 orphan keys để DB state khớp canonical sau khi drop endpoint.

## Decision

**Chose:** Option A — DROP toàn bộ endpoint mobile BE settings (route + schema + 4 service methods). Admin BE UC024 v2 là single source of truth. Mobile BE consume internal qua `SettingsService.get_setting()` cho vitals thresholds.

**Why:** Endpoint mobile BE là dead API verified (0 client) + tạo active bug split-brain. Q1-Q4 cũ assume có FE consumer là sai. Surgical drop > rebuild dead feature. YAGNI cho đồ án 2 (không có multi-device sync user-pref roadmap). Eliminate split-brain root cause (drop write → không tạo orphan keys → admin BE updates reach đúng qua `system_security` JSON).

## Options considered

### Option A (chosen): DROP toàn bộ endpoint mobile BE

**Description:**

Phase 4 actions:

- DELETE `health_system/backend/app/api/routes/settings.py` (whole file, 48 lines)
- DELETE `health_system/backend/app/schemas/general_settings.py` (whole file, 22 lines)
- DELETE 4 methods trong `app/services/settings_service.py`:
  - `get_general_settings()` line 145-185
  - `update_general_settings()` line 187-298
  - `upsert_setting()` line 91-143 (orphan cascade)
  - `invalidate_cache()` line 300-305 (orphan cascade)
- KEEP `get_setting()`, `get_vitals_sleep_thresholds()`, `get_vitals_daytime_thresholds()`, `_normalize_thresholds()`, defaults dicts — internal consumer cho `telemetry.py:349`
- DELETE 2 lines trong `app/api/router.py:14, :26` (import + include)
- CREATE migration `PM_REVIEW/SQL SCRIPTS/migrations/20260512_drop_orphan_mobile_settings.sql` cleanup 5 orphan keys

**Pros:**
- Eliminate dead API + active split-brain bug root cause
- Surgical scope (~45min total Phase 4)
- Admin BE UC024 v2 đã đúng, không cần coordinate cross-repo change
- User-pref Flutter local (`ThemeMode`, `SharedPreferences`) hợp lý hơn BE persist
- Reduce attack surface (dead endpoint with auth = vector tiềm tàng)

**Cons:**
- Mất khả năng future multi-device sync user-pref (acceptable — không có roadmap)
- Mobile FE chưa từng dùng nhưng plan doc `BUILD_PHASES_API/README.md:19-20` có liệt kê → cần update doc

**Effort:** S (~45min total: 30min code + 5min migration + 10min PM_REVIEW docs sync)

### Option B (rejected): GET-only — keep `GET /settings/general`, drop `PUT`

**Description:**
- Giữ `GET /mobile/settings/general` nhưng response shape mới: chỉ `push_notification_enabled`, `maintenance_mode`, `session_timeout_minutes` đọc từ `system_security` JSON (admin canonical).
- DROP `PUT` hoàn toàn.
- DROP language/theme/timezone khỏi response (Flutter local).

**Pros:**
- Phòng future case mobile FE cần đọc settings global (vd banner "hệ thống đang bảo trì")
- Vẫn eliminate split-brain (drop write)

**Cons:**
- Build feature không có consumer thực tế hiện tại (vẫn YAGNI violation)
- Maintenance burden cho endpoint không ai gọi
- Nếu future thực sự cần GET, có thể tạo lại 5min không loss

**Why rejected:** YAGNI + Karpathy surgical. Future case có thể re-add nhanh khi thực sự cần.

### Option C (rejected): Giữ intent doc Q1-Q4 cũ — split 2 endpoints + audit log + UC005 extend

**Description:**
- Split `PUT /settings/user-prefs` (any user) + `PUT /settings/system` (admin only)
- Add `audit_logs.create()` per update
- DROP write access admin fields cho non-admin
- Migrate 5 orphan keys → JSON nested canonical
- UC024 v2 extend "Mobile read access" + UC005 brief user-pref

**Pros:**
- Clean architecture cho future multi-device sync
- Authorization explicit cho từng scope
- Audit trail consistent với admin BE

**Cons:**
- Build feature không có FE consumer hiện tại (Q1-Q4 cũ assume sai)
- Effort ~2h+ cho dead feature
- Maintenance burden 2 endpoints không ai gọi
- UC005 noise với user-pref scope không liên quan profile management
- Vẫn không address root cause "endpoint không có client"

**Why rejected:** Over-engineering cho dead API. Q1-Q4 chốt trước khi verify FE consumer → assumption sai dẫn tới decision sai. Phase 0.5 reverify override.

---

## Consequences

### Positive

- **Eliminates active split-brain bug** — mobile BE không còn write tạo orphan scalar keys → admin BE update qua `system_security` JSON sẽ reach mobile consumer (`telemetry.py:349` cho vitals thresholds)
- **Surgical scope** — Phase 4 effort ~45min vs ~2h+ của Q1-Q4 cũ
- **Single source of truth clarity** — admin BE UC024 v2 unambiguous owner cho system settings
- **Reduce attack surface** — không còn dead endpoint với auth check buggy potential
- **DB state khớp canonical** sau migration cleanup
- **Consistent với Karpathy surgical principle** — code không trace về requirement → drop

### Negative / Trade-offs accepted

- **Mất khả năng multi-device sync user-pref** — em accept vì không có roadmap đồ án 2. Future case → revisit qua UC mới (`UC035 User Preferences Sync` chẳng hạn) + new endpoint design.
- **Mobile FE phải dùng Flutter local cho user-pref** — em accept vì Flutter ecosystem đã có sẵn (`ThemeMode`, `flutter_localizations`, `SharedPreferences`, `DateTime.timeZoneName`).
- **Plan doc `BUILD_PHASES_API/README.md` phải update** — em accept Phase 4 task ~10min.
- **`get_vitals_daytime_thresholds()` hiện 0 consumer** — em accept giữ defensive (pair với sleep, có thể được dùng future). Audit riêng Phase 2 nếu cần drop.

### Follow-up actions required

- [ ] **health_system mobile BE** (Phase 4): Drop endpoint + 4 service methods + 2 router lines. (~30min)
- [ ] **DB migration** (Phase 4): Create `PM_REVIEW/SQL SCRIPTS/migrations/20260512_drop_orphan_mobile_settings.sql` — DELETE 5 orphan keys. Run staging trước, production sau. (~5min)
- [ ] **PM_REVIEW docs sync** (Phase 4):
  - `REVIEW_MOBILE/BUILD_PHASES_API/01_CORE_AND_NOTIFICATIONS.md:28-31` — REMOVE Section 4 Settings General
  - `REVIEW_MOBILE/BUILD_PHASES_API/README.md:19-20` — REMOVE 2 checklist items
  - `AUDIT_2026/tier1/api_contract_v1.md:308-309` — MARK 2 entries `REMOVED 2026-05-12`
- [ ] **Update INDEX.md** (Phase 0.5): Add ADR-008 entry chronological + tag tables.

## Reverse decision triggers

Conditions để reconsider quyết định này:

- **Roadmap multi-device sync user-pref** xuất hiện (vd family sharing đa thiết bị có theme/language riêng per-account đồng bộ qua BE) → revisit qua UC mới + dedicated endpoint design.
- **Compliance audit yêu cầu trace mọi user-pref change** → BE persist cần audit log → revisit.
- **Mobile FE thực sự cần đọc admin settings global** (vd banner maintenance mode, push_notification_enabled flag) → có thể add `GET` only endpoint (Option B partial revival), không cần revert toàn bộ.
- **Phase 0.5 audit phát hiện ADR-008 này conflict với UC khác** chưa biết → re-evaluate.

## Related

- **UC:** UC024 v2 (admin BE settings — source of truth, no change). Cancelled UC005 v2 extend.
- **ADR:** standalone (chưa supersede gì). Có thể link tương lai với ADR cross-repo data ownership pattern.
- **Bug:** Phase 0.5 audit findings (chưa có Bug ID — phát sinh từ intent drift review, không phải runtime bug report).
- **Code (Phase 4 actions):**
  - `health_system/backend/app/api/routes/settings.py` (DELETE whole)
  - `health_system/backend/app/schemas/general_settings.py` (DELETE whole)
  - `health_system/backend/app/services/settings_service.py` (4 methods DROP, rest KEEP)
  - `health_system/backend/app/api/router.py:14, :26` (DELETE 2 lines)
  - `HealthGuard/backend/src/routes/settings.routes.js` (no change — source of truth)
  - `health_system/lib/features/profile/screens/profile_settings_screen.dart` (no change — local only)
- **Spec:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/SETTINGS.md` (Option A finalized)
- **DB migration:** `PM_REVIEW/SQL SCRIPTS/migrations/20260512_drop_orphan_mobile_settings.sql` (CREATE Phase 4)
- **PM_REVIEW docs** (Phase 4 sync): xem Follow-up actions

## Notes

- **Why không là Bug log thay vì ADR?** Đây là **architectural decision** (cross-repo ownership pattern, drop vs keep endpoint, source of truth assignment) — không phải runtime bug. Bug log dùng cho debug attempts. ADR đúng phạm trù.
- **Why không tạo UC mới cho "mobile read settings"?** Mobile BE consume settings qua internal `SettingsService.get_setting()` (DB read direct), không qua HTTP endpoint → không có UC actor mobile user thao tác. Admin BE UC024 v2 đã cover write flow đầy đủ.
- **Why giữ `get_vitals_daytime_thresholds()` mặc dù 0 consumer hiện tại?** Pair với `get_vitals_sleep_thresholds()` (consumer xác định). Defensive keep — drop sẽ tạo asymmetry confusing maintainer tương lai. Cost giữ = 4 lines code, ROI cao.
- **Why Phase 0.5 override Q1-Q4 cũ chốt cùng ngày?** Q1-Q4 chốt trước khi em verify FE consumer (grep `health_system/lib`). Sau verify phát hiện 0 match → assumption foundational sai → mọi decision build trên đó đều sai. Phase 0.5 reverify discipline = re-question assumptions trước khi commit Phase 4. Audit trail Q1-Q4 giữ trong intent doc với status SUPERSEDED.
- **Migration cleanup edge case:** Nếu production DB đã có user-pref data từ mobile BE writes (unlikely vì endpoint dead, nhưng có thể test data) → migration DELETE sẽ wipe. Em chấp nhận vì data dead-end (không ai đọc), không loss giá trị. Backup table trước migration nếu anh muốn safety net.
