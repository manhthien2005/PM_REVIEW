# Intent Drift Review — `health_system / NOTIFICATIONS`

**Status:** ✅ **Phase 0.5 reverify COMPLETED** (2026-05-12 chiều) — Q1-Q4 cũ REVISED: 3/4 endpoints proposed đều **DEAD** từ FE perspective → scope reduce
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE consumer)
**Module:** NOTIFICATIONS (Mobile notification center + push token + WebSocket)
**Related UCs (old):** UC031 Manage Notifications
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-12 (Q1-Q4 cũ sáng) + 2026-05-12 chiều (Phase 0.5 reverify với code verify)
**Question count:** 4 cũ + 5 revised (Q1 Acknowledge DROP, Q2 Mark-all KEEP đổi UX reasoning, Q2 Severity filter DROP, Q3 Preferences DROP OS-level, Q4 Expire worker KEEP)

---

## ⚠️ Phase 0.5 reverify notice

> **Lý do reverify:** Q1-Q4 cũ được quyết sáng 2026-05-12 dựa UC spec + DB field existence, KHÔNG verify mobile FE consumer. Reverify chiều 2026-05-12 phát hiện:
> 1. **Q1 Acknowledge endpoint** → **DEAD** — FE chưa có UI button "Xác nhận đã xem". Em recommend chuyển C1 Drop UC Alt 5.a.
> 2. **Q2 Severity filter (BE query param)** → **DEAD** — FE filter 100% client-side (verified `notifications_screen.dart:263-268` comment "purely client-side"). Em recommend A2a Drop BE filter param.
> 3. **Q3 Notification preferences** → **DEAD + heavier** — 0 FE consumer, dispatcher SCATTERED 4 methods (`send_sos_push_alerts` + `send_risk_push_alerts` + `send_fall_critical_alert` + `send_fall_followup_concern`), DB chưa có table/column → real effort ~4-5h, không phải ~2h em estimate cũ. Em recommend C3 Drop UC Alt 1.a, dùng OS-level FCM channel.
> 4. **Q2 Mark-all as read** → FE chưa có button nhưng **anh quyết implement A2b để UX tốt hơn** (BE endpoint + FE UI button cùng Phase 4).
> 5. **Q4 Expire worker** → vẫn valid — Keep implement.
> 
> **Anh quyết Phase 0.5 (chiều 2026-05-12):**
> - **D-NOT-A** (Q1): **C1 Drop UC Alt 5.a** (acknowledge endpoint) — read_at = acknowledge implicit, đồ án 2 không cần caregiver accountability formal
> - **D-NOT-B** (Q2 severity filter): **A2a Drop BE filter** (FE local đủ)
> - **D-NOT-C** (Q2 mark-all): **A2b Implement BE + FE UI button** (UX tốt hơn, ~1h)
> - **D-NOT-D** (Q3 preferences): **C3 Drop UC Alt 1.a** (OS-level FCM channel pattern industry standard)
> - **D-NOT-E** (Q4 expire worker): **Keep Implement** (APScheduler 90-day + service filter)
> 
> **Net Phase 4 effort:** ~2.5h (giảm từ ~5.5h Q1-Q4 cũ → tiết kiệm ~3h surgical scope reduce).

---

## 🎯 Mục tiêu

Capture intent cho NOTIFICATIONS module mobile BE + mobile FE consumer. UC031 spec đầy đủ Alt flows, code implement Main flow + push token + WebSocket + FE filter client-side. Phase 0.5 reverify pattern **drop dead UC requirements** dựa FE consumer reality, giữ lại UC yêu cầu có giá trị UX (mark-all as read). Output = UC031 v2 updated + D-NOT-A..E decisions log + Phase 4 backlog revised.

---

## 📚 UC031 cũ summary (memory aid)

- **Actor:** Bệnh nhân, Người chăm sóc
- **Main:** View list, mark as read on tap (Alt 1-6) ✓ code implemented
- **Alt 3.a:** Filter severity (Tất cả / Critical / Chưa đọc) ❓ Partial (code chỉ unread_only)
- **Alt 5.a:** Acknowledge "Xác nhận đã xem" cho critical/high ❌ Missing
- **Alt 6.a:** Mark all as read ❌ Missing
- **Alt 1.a:** Configure notification types (per `alert_type`) ❌ Missing
- **BR-031-01:** Critical luôn push (config-side enforce)
- **BR-031-02:** 90-day auto expire (`expires_at`) ❌ Missing worker
- **BR-031-03:** Quick filter "Critical only" = severity high+critical

---

## 🔧 Code state — verified

### Routes (`notifications.py`) — 5 REST + 1 WebSocket

```
tags=[mobile-notifications]

GET    /notifications                       List paginated (limit/offset + unread_only flag)
GET    /notifications/{id}                  Detail
PUT    /notifications/{id}/read             Mark as read
POST   /notifications/push-token            Register FCM token
POST   /notifications/push-token/unregister Unregister
WS     /ws/notifications                    Stream updates (polling DB mỗi 5s, send_json when signature change)
```

### DB schema (`alerts` table) — verified

**✅ Fields đã exist trong DB:**
- `alert_type VARCHAR(50)` CHECK constraint với 12 types: `vital_abnormal, vitals_threshold, fall_detected, fall_detection, sos, sos_triggered, device_offline, low_battery, high_risk_score, risk_high, risk_critical, generic_alert`
- `severity` enum low/medium/high/critical
- `read_at TIMESTAMPTZ` ✓ implemented
- **`acknowledged_at TIMESTAMPTZ`** ✓ exist nhưng KHÔNG có code update
- **`expires_at TIMESTAMPTZ`** ✓ exist nhưng KHÔNG có worker auto-cleanup
- `sent_via TEXT[]` (push/sms/email channels)
- `delivered_at`, `sent_at` (FCM/APNs delivery tracking)

### 🟡 Drift findings (cũ — Phase 0.5 reverify annotated)

1. **⚠️ REVISED — Alt 5.a Acknowledge endpoint MISSING:**
   - UC: "Xác nhận đã xem" cho critical/high → set `acknowledged_at` (khác `read_at`)
   - DB field `acknowledged_at` đã exist
   - Code: chỉ có `mark_notification_as_read` (set `read_at`)
   - ~~→ Endpoint `PUT /notifications/{id}/acknowledge` missing~~
   - **Phase 0.5:** FE KHÔNG có UI button → DEAD endpoint nếu implement → anh chốt **C1 Drop UC Alt 5.a** (D-NOT-A)

2. **✅ KEEP (UX reasoning) — Alt 6.a Mark all as read MISSING:**
   - UC: bulk action
   - Code: chỉ mark individual
   - → Endpoint `PUT /notifications/read-all` missing
   - **Phase 0.5:** FE chưa có button, nhưng anh chốt **A2b Implement BE + FE UI** cùng Phase 4 để UX tốt hơn (D-NOT-C)

3. **⚠️ REVISED — Alt 1.a Notification preferences MISSING:**
   - UC: user toggle từng `alert_type` (vital_abnormal, fall_detected, sos_triggered, etc.)
   - BR-031-01: critical types không tắt được (force push)
   - Code: KHÔNG có preferences table + endpoint
   - DB: chưa thấy table `notification_preferences` hoặc field JSONB trong users
   - **Phase 0.5:** 0 FE consumer + dispatcher SCATTERED 4 methods + DB chưa có table → real effort ~4-5h (không ~2h) → anh chốt **C3 Drop UC Alt 1.a, dùng OS-level FCM channel** (D-NOT-D)

4. **⚠️ REVISED — Alt 3.a Severity filter MISSING:**
   - UC: filter Critical only / Chưa đọc (BR-031-03)
   - Code: chỉ `unread_only` flag
   - ~~→ Add query param `severity_in` accept multi values~~
   - **Phase 0.5:** FE đã filter 100% client-side (verified `notifications_screen.dart:263-268` comment "purely client-side filter so we just rebuild over the already-loaded items; no API round-trip needed") → BE query param DEAD → anh chốt **A2a Drop BE filter** (D-NOT-B)

5. **✅ KEEP — BR-031-02 90-day expire worker MISSING:**
   - UC: Alert > 90 ngày → auto expire + ẩn UI
   - DB field `expires_at` exist
   - Code: KHÔNG có worker set `expires_at`, KHÔNG có UI filter mặc định ẩn expired
   - **Phase 0.5 confirm:** Keep implement (D-NOT-E) — worker + service filter `expires_at`, reuse APScheduler pattern với PROFILE Q2 GDPR worker

6. **WebSocket polling pattern** (note, không hỏi):
   - Code WS poll DB mỗi 5s (`notifications.py:180` `await asyncio.sleep(5)`)
   - Pattern OK cho mobile (mỗi user 1 connection), nhưng N users = N polling queries × 12/min
   - Cross-repo concern: Admin BE có `emit-emergency` endpoint (em verified DEAD CODE trong EMERGENCY Q6). Mobile WS có pub/sub?
   - → Out of scope drift review; flag cho Phase 4 performance audit nếu cần

---

## D-AI-11 Parking Resolution (2026-05-13 chiều)

**Caregiver risk alert dispatch VERIFIED:**

- `dispatch_risk_alerts()` gọi `_resolve_risk_alert_recipients(db, patient_user_id)`.
- `EmergencyRepository.get_alert_recipient_user_ids()` query `user_relationships` WHERE `patient_id=X AND status='accepted' AND can_receive_alerts=TRUE AND deleted_at IS NULL`.
- Return caregiver_ids dedup, patient + caregivers list, `PushNotificationService.send_risk_push_alerts()` FCM push all.
- Defensive: caregiver lookup fail thì fallback patient-only (try/except, log warning).
- Alert cooldown riêng: `RISK_ALERT_COOLDOWN_SECONDS=300` (5 phút, khác risk calc cooldown 60s).
- **BR-016-03 "HIGH/CRITICAL notify caregiver" = IMPLEMENTED OK.** D-AI-11 parking RESOLVED.

---

### 1. Mobile FE filter — 100% CLIENT-SIDE, KHÔNG call BE

Verified `@d:\DoAn2\VSmartwatch\health_system\lib\features\notifications\screens\notifications_screen.dart`:

- **Line 162-171:** GET `/notifications` chỉ truyền `unread_only` flag (không severity/alert_type)
- **Line 187-218:** `_filteredItems` filter LOCAL bằng `_typeFilter` + `_searchQuery` qua `Iterable.where()`
- **Line 263-268:** `_changeTypeFilter` comment "Type is a purely client-side filter so we just rebuild over the already-loaded items; no API round-trip needed"
- **Line 80-83:** Search query cũng LOCAL, comment "Search runs purely client-side over already-loaded items, so a setState is enough — no need to round-trip the API"

→ **Q2 severity/alert_type BE filter = DEAD requirement** (D-NOT-B Drop)

### 2. Mobile FE chỉ call 2 notification endpoints

Verified grep trong `health_system/lib` toàn module:

```
GET  /notifications?unread_only=...     (_fetchPage, line 165)
PUT  /notifications/{id}/read           (_markAsRead, line 275)
```

**0 match cho:**
- `/notifications/{id}/acknowledge` (Q1) → **DEAD**
- `/notifications/read-all` (Q2 mark-all) → **DEAD** (nhưng anh chốt A2b implement cùng FE button Phase 4)
- `/notifications/preferences` (Q3) → **DEAD**

### 3. Push dispatch SCATTERED — không có centralized `NotificationDispatcher`

Verified `@d:\DoAn2\VSmartwatch\health_system\backend\app\services\push_notification_service.py`:

| Method | Line | Use case | Channel |
|---|---|---|---|
| `send_sos_push_alerts` | 136-256 | SOS/fall takeover (data-only FCM) | `sos_fullscreen_alerts` |
| `send_risk_push_alerts` | 262-403 | Risk alerts (configurable channel) | `risk_alerts` |
| `send_fall_critical_alert` | 409-542 | Fall fullscreen takeover | `sos_fullscreen_alerts` |
| `send_fall_followup_concern` | 548-691 | Caregiver soft push (non-takeover) | default |

**0 match cho `NotificationDispatcher|notification_dispatcher|dispatch_alert`** → KHÔNG có centralized dispatcher class.

**Implication cho Q3 (cũ ~2h estimate):** Preference check phải **spread 4 methods** (effort +1h) hoặc refactor trước (effort +2h) → real effort ~4-5h, không ~2h. Plus 0 FE consumer + DB chưa có column → ROI thấp → D-NOT-D Drop.

### 4. `notification_preferences` DB — KHÔNG TỒN TẠI

Verified grep `PM_REVIEW/SQL SCRIPTS/`:

- 0 match `notification_preferences|notification_settings|notification_pref`
- → Q3 implement cần migration mới (column JSONB hoặc table riêng) → thêm effort

### 5. DB fields existing (BR-031-02 vs acknowledged_at)

Verified `PM_REVIEW/SQL SCRIPTS/`:

- ✅ `alerts.acknowledged_at TIMESTAMPTZ` — `init_full_setup.sql:457` + `05_create_tables_events_alerts.sql:145`
- ✅ `alerts.expires_at TIMESTAMPTZ` — `init_full_setup.sql:153` + comment "Auto-cleanup old alerts"

→ Q4 (D-NOT-E Keep Implement) có sẵn field, chỉ cần worker + service filter. Q1 cũ có field `acknowledged_at` unused nếu C1 Drop — field sẽ stay as potential future use (không migrate drop column để simplify có thể tiết kiệm DB risk).

### 6. Mobile FE notification feature RICH — không phải module dead

18 files trong `features/notifications/`:
- `notifications_screen.dart` 68 matches — full list screen
- `notification_severity.dart` 79 matches — severity mapping FE-side
- `notification_filter_chips.dart` 32 matches — filter UI (both row types)
- `notification_event_mapper.dart` 39 matches — FCM event → local notification handler
- `notification_vital_insight.dart` 51 matches — inline insight widget
- Plus 13 files khác (detail, search, empty state, runtime)

→ Module ACTIVE, differs đối với SETTINGS (dead API). Phase 0.5 pattern MIXED: drop DEAD endpoint (C1, C3), keep active feature + UX improvement (A2b mark-all), keep compliance (E expire worker).

---

## ✅ Code state đúng spec (Phase 0.5 reverify confirmed)

- Main flow view + mark as read (UC031 Main) ✅
- Push token register/unregister (outside UC031 nhưng cần cho FCM) ✅
- WebSocket stream updates (5s polling pattern) ✅ OK cho đồ án 2 scale < 100 users
- FE client-side filter (severity/type/search) ✅ pattern intentional, dataset nhỏ
- FCM channel separation (`sos_fullscreen_alerts`, `risk_alerts`) ✅ match BR-031-01 OS-level control
- DB schema (`alerts` table với 12 alert_types + acknowledged_at + expires_at) ✅ overprovisioned nhưng match UC intent

---

## 💬 Anh react block (history — Q1-Q4 REVISED bởi Phase 0.5 reverify)

> 4 câu cũ — UC spec đủ Alt flows, code mới implement Main flow. Mọi gap đều có DB field sẵn.
> **Status:** ⚠️ 3/4 Q có assumption SAI (FE consumer gap + dispatcher scattered) → REVISED. Q2 mark-all anh keep đổi UX reasoning. Q4 keep.

---

### Q1: ⚠️ REVISED — Alt 5.a Acknowledge endpoint cho critical/high

**Context:**
- UC031 Alt 5.a: User tap "Xác nhận đã xem" trên notification critical/high → set `acknowledged_at` (khác read_at)
- DB `alerts.acknowledged_at` exist
- Code chưa có endpoint

**Use case business:**
- Critical SOS/fall_detected: caregiver cần acknowledge để confirm họ thấy (audit responsibility)
- High vital_abnormal: optional acknowledge
- Khác `read_at` (passive — auto khi mở detail): `acknowledged_at` = chủ động xác nhận trách nhiệm

**Em recommend:**
- **Implement** `PUT /notifications/{id}/acknowledge`:
  - Validate severity `IN ('high', 'critical')` (BR-031 acknowledge chỉ cho important)
  - Set `acknowledged_at = NOW()` (idempotent — nếu đã ack thì return existing timestamp)
  - Audit log `notification.acknowledged` với severity field
- Effort ~45min: route + service method + Pydantic schema + audit log

**Anh decision (REVISED):**
- ✅ **Em recommend (implement acknowledge cho critical/high)** ← anh CHỌN sáng 2026-05-12
- ⚠️ **Phase 0.5 reverify (chiều 2026-05-12):** FE KHÔNG có UI button "Xác nhận đã xem" → implement sẽ dead endpoint. Anh chốt **C1 Drop UC Alt 5.a** — read_at = acknowledge implicit, đồ án 2 không cần caregiver accountability formal. Phase 5+ revisit nếu deploy production cần audit trail.
- ☐ Defer Phase 5+ (đồ án 2 read_at đủ)
- ☐ Drop UC Alt 5.a hoàn toàn (simplify scope, read_at = acknowledge implicit)
- ☐ Khác: ___

---

### Q2: ⚠️ REVISED (split) — Alt 6.a Mark all as read + Alt 3.a Severity filter

**Context:**
- Alt 6.a: bulk mark all read (UX convenience)
- Alt 3.a: filter Critical/Unread (BR-031-03 quick filter)
- Code: cả 2 missing

**Em recommend (bundle 2 vì similar effort):**
- **Implement cả 2:**
  - `PUT /notifications/read-all` — service `mark_all_as_read(user_id)` set `read_at=NOW()` WHERE read_at IS NULL
  - Add query params cho `GET /notifications`:
    - `severity_in: list[str]` (vd `?severity_in=high&severity_in=critical`)
    - `alert_type_in: list[str]` (vd `?alert_type_in=sos_triggered&alert_type_in=fall_detected`)
- Effort ~1h total (~30min mark-all + ~30min filters + tests)

**Anh decision (REVISED — split 2 phases):**
- ✅ **Em recommend (implement cả 2)** ← anh CHỌN sáng 2026-05-12
- ⚠️ **Phase 0.5 reverify split:**
  - **Alt 3.a Severity filter (D-NOT-B):** FE đã filter 100% client-side → BE param DEAD → anh chốt **A2a Drop BE filter**. UC update: note client-side pattern intentional cho dataset nhỏ.
  - **Alt 6.a Mark-all (D-NOT-C):** FE chưa có button nhưng anh chốt **A2b Implement BE + FE UI button** cùng Phase 4 để UX tốt hơn (~1h BE + ~30min FE = ~1.5h total). UC Alt 6.a giaĩ nguyên.
- ☐ Implement chỉ Alt 3.a severity filter (mark-all dùng FE-side bulk call individual endpoint)
- ☐ Defer cả 2 Phase 5+
- ☐ Khác: ___

---

### Q3: ⚠️ REVISED — Alt 1.a Notification preferences (toggle per alert_type)

**Context:**
- UC: user toggle từng alert_type (6 types mention: vital_abnormal, fall_detected, sos_triggered, high_risk_score, device_offline, low_battery)
- BR-031-01: critical types (sos_triggered, fall_detected) force push, user không tắt được
- Code + DB: KHÔNG có preferences storage

**Em recommend:**
- **Phase 4 implement minimal:**
  - DB add column `users.notification_preferences JSONB DEFAULT '{}'::jsonb` (hoặc table riêng nếu cần normalize)
  - Default schema: `{"vital_abnormal": true, "high_risk_score": true, "device_offline": true, "low_battery": true}` — sos/fall **NOT in preferences** (forced)
  - Endpoint `GET /notifications/preferences` + `PUT /notifications/preferences`
  - Notification dispatcher check preferences trước khi gửi (skip nếu user tắt)
  - BR-031-01 enforce: sos/fall không trong schema → luôn gửi
- Effort ~2h (migration + endpoint + service + dispatcher integration)

**Em note:** Feature này impact dispatcher logic. Em chưa verify dispatcher trong codebase — có thể có dispatcher service riêng cần cross-check.

**Anh decision (REVISED):**
- ✅ **Em recommend (implement minimal preferences)** ← anh CHỌN sáng 2026-05-12
- ⚠️ **Phase 0.5 reverify:** Em estimate cũ ~2h SAI — real effort ~4-5h do:
  - 0 FE consumer (phải build UI screen từ đầu)
  - Dispatcher SCATTERED 4 methods → preference check spread hoặc refactor centralized
  - DB chưa có column/table → migration mới
  
  Anh chốt **C3 Drop UC Alt 1.a, dùng OS-level FCM channel** — pattern industry standard (Android Settings > Apps > HealthGuard > Notifications > per-channel). Mobile FE đã setup FCM channels riêng (`sos_fullscreen_alerts`, `risk_alerts`) → user disable channel cụ thể OS-level đã đủ replace in-app preferences cho đồ án 2.
- ☐ Defer Phase 5+ (đồ án 2 nhận hết, không cần filter)
- ☐ Drop UC Alt 1.a hoàn toàn (simplify — user OS-level disable push từ phone settings)
- ☐ Khác: ___

---

### Q4: ✅ KEEP — BR-031-02 90-day expire worker

**Context:**
- BR-031-02: Alert > 90 ngày → `expires_at` set + ẩn UI mặc định
- DB field `expires_at` exist
- Code: KHÔNG có worker; UI list query không filter expired

**Em recommend (consistent với PROFILE Q2 Option C minimal worker pattern):**
- **APScheduler worker daily** `app/jobs/notification_expire_worker.py`:
  - Set `expires_at = created_at + INTERVAL '90 days'` cho rows missing expires_at
  - Hard delete rows với `expires_at < NOW() - INTERVAL '30 days'` (grace period)
- **Service `list_notifications`** default WHERE `expires_at IS NULL OR expires_at > NOW()` (ẩn expired)
- Add query param `include_expired: bool = False` cho debug/audit
- Effort ~1.5h (worker + service filter + tests)

**Anh decision (KEEP):**
- ✅ **Em recommend (implement worker + service filter)** ← anh CHỌN, Phase 0.5 reverify confirm — spec BR-031-02 explicit, DB field `expires_at` đã exist, reuse APScheduler pattern với PROFILE Q2 GDPR worker
- ☐ Defer Phase 5+ (đồ án 2 lượng alert nhỏ, không cần expire)
- ☐ Drop BR-031-02 hoàn toàn (giữ forever, user tự xóa qua bulk delete — không có endpoint)
- ☐ Khác: ___

---

## 🎯 Anh's revised decisions Phase 0.5 — reverify 2026-05-12 (chiều)

### Decisions revised

| ID | Item | Decision Phase 0.5 | Effort Phase 4 |
|---|---|---|---|
| **D-NOT-A** | Q1 Acknowledge endpoint | **C1 Drop UC Alt 5.a** — read_at = acknowledge implicit | ~10min Phase 0.5 (UC update đã làm) |
| **D-NOT-B** | Q2 Severity/alert_type BE filter | **A2a Drop BE filter** — FE client-side đủ (intentional pattern) | ~5min Phase 0.5 (UC note ghi) |
| **D-NOT-C** | Q2 Mark-all as read | **A2b Implement BE + FE UI button** — UX improvement | ~1h BE + ~30min FE = **~1.5h Phase 4** |
| **D-NOT-D** | Q3 Notification preferences | **C3 Drop UC Alt 1.a** — OS-level FCM channel dợc u user | ~10min Phase 0.5 (UC update đã làm) |
| **D-NOT-E** | Q4 Expire worker | **Keep Implement** — APScheduler 90-day + service filter `expires_at` | **~1.5h Phase 4** |

### Lý do override Q1-Q3 cũ

1. **Q1 cũ implement acknowledge** → verify FE không có UI button → dead endpoint. `acknowledged_at` column DB giữ lại as potential future use (không drop column để simplify DB risk).
2. **Q2 severity filter cũ add BE param** → verify FE 100% client-side (comment code explicit) → BE param DEAD. FE pattern intentional cho dataset nhỏ <100 notif/user.
3. **Q2 mark-all cũ implement BE only** → anh chọn A2b thêm FE UI button để UX đầy đủ (khác SETTINGS/PROFILE Phase 0.5 — A2b KEEP scope).
4. **Q3 cũ implement minimal ~2h** → verify dispatcher SCATTERED (4 methods) + 0 FE + DB gap → real effort ~4-5h. OS-level FCM channel là industry pattern consumer mobile — replace in-app preferences OK đồ án 2.
5. **Q4 keep** — spec BR-031-02 clear, DB field sẵn, worker pattern reuse.

### Out-of-scope flag (em không lan scope)

- **WebSocket polling 5s pattern** — OK đồ án 2 scale < 100 users. Phase 5+ revisit nếu scale > 500 concurrent (upgrade pub/sub Redis).
- **Cross-repo admin BE `emit-emergency` dead code** — scope EMERGENCY module, không NOTIFICATIONS. Đã flag ở EMERGENCY intent doc Q6.
- **UC024 `notification_gateways` setting (SMS/email enabled flags)** — admin CONFIG scope, không impact NOTIFICATIONS core flows vi `sent_via` hiện tại default `['push']` chỉ.
- **WS poll query performance** — 1 query / 5s / user cho 100 users ≈ 1200 queries/min — OK đồ án 2. Phase 4 performance audit nếu deploy production > 500 users.
- **FCM channel documentation** (OS-level disable UX guide) — Phase 5+ user onboarding doc, không block đồ án 2 submission.

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **In-app banner toast** — FE-side, BE đã có WS push
- ❌ **Quiet hours config** — Phase 5+ feature
- ❌ **Notification grouping** — Phase 5+ UX
- ❌ **Read receipts cross-user** — Phase 5+ caregiver complexity

---

## 🆕 Features mới em recommend

**Không có** — UC031 đã chi tiết, Q1-Q4 cũ + Phase 0.5 reverify cover gap.

---

## ❌ Features em recommend DROP (Phase 0.5 reverify)

- **Acknowledge endpoint** (Q1 → D-NOT-A → C1): Drop UC Alt 5.a — read_at = acknowledge implicit, FE không có UI button.
- **Severity/alert_type BE filter params** (Q2 → D-NOT-B → A2a): Drop BE param — FE client-side filter đủ + intentional.
- **Notification preferences in-app UI** (Q3 → D-NOT-D → C3): Drop UC Alt 1.a — OS-level FCM channel pattern industry standard cho consumer mobile.
- **5 REST endpoints + 1 WS củ KHÔNG drop** — active feature, FE consume verify đầy đủ (khác SETTINGS dead API).

---

## 📊 Drift summary — Phase 0.5 reverify

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC031 Manage Notifications | **Update v2 (Phase 0.5 đã làm)** | Drop Alt 5.a (acknowledge), Drop Alt 1.a (preferences). Keep Alt 3.a with client-side note (D-NOT-B). Keep Alt 6.a (D-NOT-C implement). BR-031-01 rewrite với OS-level FCM channel. BR-031-02 vẫn valid. BR-031-03 explicit client-side. |

### Code impact (Phase 4 backlog — revised Phase 0.5)

| Phase 0.5 finding | Decision | Phase 4 task | Severity | Effort |
|---|---|---|---|---|
| Acknowledge endpoint (Q1 → D-NOT-A) | Drop UC Alt 5.a | `docs(uc): UC031 Alt 5.a remove acknowledge requirement` (đã làm Phase 0.5) | 🟢 Doc | ✅ Done Phase 0.5 |
| Severity/alert_type BE filter (Q2 → D-NOT-B) | Drop BE filter (FE client-side) | `docs(uc): UC031 Alt 3.a note client-side intentional` (đã làm Phase 0.5) | � Doc | ✅ Done Phase 0.5 |
| Mark-all as read (Q2 → D-NOT-C) | Implement BE + FE UI button | `feat(notifications): PUT /notifications/read-all + FE UI button` | 🟡 UX feature | **~1.5h Phase 4** |
| Notification preferences (Q3 → D-NOT-D) | Drop UC Alt 1.a | `docs(uc): UC031 remove Alt 1.a + BR-031-01 rewrite OS-level` (đã làm Phase 0.5) | 🟢 Doc | ✅ Done Phase 0.5 |
| Expire worker (Q4 → D-NOT-E) | Implement | `feat(notifications): APScheduler 90-day worker + service filter expires_at` | 🟡 Compliance | **~1.5h Phase 4** |

**Estimated Phase 0.5 effort (now):** ✅ Done (UC031 updated + intent doc đang làm)
**Estimated Phase 4 effort:** **~3h** (Q2 mark-all + Q4 worker), giảm từ ~5.5h cũ → tiết kiệm ~2.5h surgical

### Cross-repo coordination required

- **HealthGuard admin BE:** ✅ No change — không có push notification cross-feature. `emit-emergency` dead code tracked EMERGENCY module.
- **health_system mobile BE:** Phase 4 implement D-NOT-C (mark-all endpoint) + D-NOT-E (expire worker).
- **Mobile FE:** Phase 4 thêm "Mark all as read" UI button trong `notifications_screen.dart` (D-NOT-C consumer).
- **DB:** Phase 4 KHÔNG migrate — `acknowledged_at` column giữ luắy (unused sau Q1 drop); `expires_at` column đã sẵn.
- **UC031 spec:** ✅ Done Phase 0.5 — remove Alt 5.a + Alt 1.a, update Alt 3.a/6.a/BR-031-01..03.
- **UC024 CONFIG (admin):** Không impact — `notification_gateways` setting vẫn valid cho admin scope. FCM channel OS-level orthogonal.

### Dependencies note

- **D-NOT-E worker reuse APScheduler pattern với PROFILE Q2 GDPR worker** (D-PRO-B) — Phase 4 share scheduler instance trong `app/jobs/__init__.py` tết kiệm boilerplate.
- **D-NOT-C FE UI button** cần emit refresh event cho FE notification list sau khi call BE success → counter + list update.

---

## 📝 Anh's decisions log

### Active decisions — Phase 0.5 reverify (chiều 2026-05-12)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| **D-NOT-A** | Q1 Acknowledge endpoint | **C1 Drop UC Alt 5.a** | FE KHÔNG có UI button "Xác nhận đã xem" → dead endpoint; read_at = acknowledge implicit OK đồ án 2; caregiver accountability formal defer Phase 5+ nếu deploy production |
| **D-NOT-B** | Q2 Severity/alert_type BE filter | **A2a Drop BE filter** | FE 100% client-side (verified `notifications_screen.dart:263-268`); dataset nhỏ < 100 notif/user; intentional pattern; BE param DEAD |
| **D-NOT-C** | Q2 Mark-all as read | **A2b Implement BE + FE UI button** | UX improvement đáng đầu tư; UC Alt 6.a match; effort reasonable ~1.5h; khác SETTINGS/PROFILE Phase 0.5 drop-heavy pattern — đây keep UX value |
| **D-NOT-D** | Q3 Notification preferences | **C3 Drop UC Alt 1.a** | 0 FE consumer + dispatcher SCATTERED 4 methods + DB gap → real effort ~4-5h ROI thấp; OS-level FCM channel (Android Settings per-channel) pattern industry standard consumer mobile; Mobile FE đã setup channels riêng (`sos_fullscreen_alerts`, `risk_alerts`) |
| **D-NOT-E** | Q4 Expire worker | **Keep Implement APScheduler 90-day + service filter** | BR-031-02 explicit; `expires_at` DB field exist; reuse pattern với PROFILE Q2 GDPR worker (D-PRO-B); share scheduler instance |

### Superseded decisions — Q1-Q4 cũ sáng 2026-05-12 (giữ làm audit trail)

| ID | Item | Decision cũ | Status |
|---|---|---|---|
| ~~D-NOT-01~~ | Acknowledge endpoint | ~~Implement cho critical/high (~45min)~~ | ⚠️ **SUPERSEDED bởi D-NOT-A** — FE không có UI button → dead endpoint, Drop UC Alt 5.a |
| ~~D-NOT-02~~ | Mark-all + severity filter (bundle) | ~~Implement cả 2 (~1h)~~ | ⚠️ **SPLIT 2 decisions:** <br>• D-NOT-B Drop severity filter (FE client-side) <br>• D-NOT-C Keep mark-all + upgrade FE button (~1.5h) |
| ~~D-NOT-03~~ | Notification preferences | ~~Implement minimal JSONB ~2h~~ | ⚠️ **SUPERSEDED bởi D-NOT-D** — real effort ~4-5h + 0 FE consumer + dispatcher scattered → Drop UC Alt 1.a, dùng OS-level |
| D-NOT-04 | Expire worker | Implement APScheduler 90-day + service filter | ✅ **KEEP** — rất khớp với D-NOT-E (chỉ rename ID cho consistent) |

### Add-ons selection

| Add-on | Decision |
|---|---|
| In-app banner toast | ❌ Drop (FE-side) |
| Quiet hours config | ❌ Drop (Phase 5+) |
| Notification grouping | ❌ Drop (Phase 5+ UX) |
| Read receipts cross-user | ❌ Drop (Phase 5+ caregiver) |

**All 4 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

### UC + Specs

- `PM_REVIEW/Resources/UC/Notification/UC031_Manage_Notifications.md` — **UPDATED Phase 0.5** (Drop Alt 5.a + Alt 1.a, update Alt 3.a client-side note + Alt 6.a BE endpoint, BR-031-01 rewrite OS-level FCM channel)
- `PM_REVIEW/Resources/UC/Admin/UC024_Configure_System_v2.md` — admin CONFIG scope, không impact NOTIFICATIONS (orthogonal)

### Code paths (mobile BE — Phase 4 actions)

- `health_system/backend/app/api/routes/notifications.py` — **Phase 4: add `PUT /notifications/read-all` endpoint** (D-NOT-C)
- `health_system/backend/app/services/notification_service.py` — **Phase 4: add `mark_all_as_read(user_id)` service method + service filter `expires_at IS NULL OR expires_at > NOW()`** (D-NOT-C + D-NOT-E)
- `health_system/backend/app/schemas/notification.py` — **Phase 4: add `MarkAllReadResponse` schema** (D-NOT-C)
- `health_system/backend/app/jobs/notification_expire_worker.py` — **CREATE Phase 4** APScheduler worker (D-NOT-E), share scheduler với PROFILE D-PRO-B
- `health_system/backend/app/api/routes/notifications.py:180` — WS polling 5s pattern kept (out-of-scope)
- `health_system/backend/app/services/push_notification_service.py:136-691` — 4 push methods scattered (D-NOT-D skip — không refactor)

### Code paths (mobile FE — Phase 4 action cho D-NOT-C)

- `health_system/lib/features/notifications/screens/notifications_screen.dart` — **Phase 4: add "Đánh dấu tất cả là đã đọc" button** (AppBar action hoặc context menu) + call `_apiClient.put('/notifications/read-all', body: const {})` + update `_items` + `_unreadCount = 0`
- `health_system/lib/features/notifications/widgets/notification_filter_chips.dart` — no change (D-NOT-B confirm client-side pattern)

### DB schema

- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:454-460` — `alerts.acknowledged_at` stays as potential future use (D-NOT-A drop UC spec, giữ column)
- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:153` — `alerts.expires_at` sẵn cho D-NOT-E
- `PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql:142-155` — canonical table def, no migration needed
- **Không migration `notification_preferences`** — D-NOT-D drop → không cần column/table mới

### Related ADR

- **Không tạo ADR riêng cho NOTIFICATIONS** — decisions đều là scope reduce/UX tuning dựa UC reality, không có architectural implication mới. SETTINGS (ADR-008) đã cover "mobile BE drop dead API" pattern, PROFILE (ADR-009) đã cover "cross-repo storage split". Nếu anh muốn formalize "OS-level FCM channel thay in-app preferences" thành ADR-010, em tạo thêm.
- `PM_REVIEW/ADR/008-mobile-be-no-system-settings-write.md` — cross-reference pattern mobile BE drop dead API
- `PM_REVIEW/ADR/009-avatar-storage-supabase-mobile-only.md` — cross-reference Phase 0.5 reverify methodology

### Cross-repo concern (out-of-scope flag)

- **Admin BE `emit-emergency` dead code** (EMERGENCY Q6) → Mobile WS polling 5s pattern vẫn OK đồ án 2, không cần pub/sub upgrade
- **UC024 CONFIG `notification_gateways`** → admin scope (SMS/email enabled flags), không interact direct NOTIFICATIONS mobile vi `sent_via` default `['push']` only
