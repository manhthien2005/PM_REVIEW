# Intent Drift Review — `HealthGuard / EMERGENCY`

**Status:** � Confirmed v3 (Q1-Q7 anh chọn theo em recommend; Q7 FINAL VERIFIED 2026-05-12 — Mobile BE OWNS auto-SOS SYNC trong telemetry alert ingest; **Q8 OBSOLETE** — UC024 v2 đã document; 6 add-ons drop)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** EMERGENCY (SOS + Fall event management)
**Related UCs (old):** UC029 Emergency Management
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 8 (Q1, Q2a, Q2b, Q3, Q4, Q5 + Q6 emit-emergency dead code + Q7 auto-SOS cross-repo flow; **Q8 dropped** — UC024 v2 đã document)

---

## 🎯 Mục tiêu

Capture intent cho EMERGENCY module. UC029 cũ làm memory aid. Output = UC029 v2 + decisions log.

**Hướng drift:** Code RICHER than UC v1 (có thêm fall countdown flow + cancelled status). UC v2 cần expand để match code (drift forward direction).

---

## 📚 UC029 cũ summary (memory aid)

- **Actor:** Admin only
- **Main:** Summary bar + Active table + History table với pagination
- **Alt 5.a:** Chi tiết event (patient info, vitals snapshot, GPS, timeline)
- **Alt 5.b:** Update status (notes BẮT BUỘC, BR-029-03)
- **Alt 5.c:** Log emergency contact
- **Alt 5.d:** Filter (Loại/Trạng thái/Time range)
- **Alt 5.e:** Export CSV/PDF
- **BR-029-01:** Auto-refresh 15s
- **BR-029-04:** Append-only (no DELETE/EDIT)
- **BR-029-06:** State machine `active → responded → resolved`, KHÔNG skip

---

## 🔧 Code state — verified

### Routes (`emergency.routes.js`) — 10 endpoints

```
authenticate + requireAdmin + emergencyLimiter (100/min)

GET    /summary              Dashboard stats (SOS active + falls pending + resolved today)
GET    /fall-countdown       Fall events trong 30s window chưa create SOS  ⚠️ NOT IN UC
GET    /active               Active+responded events realtime
GET    /history              Resolved+cancelled events paginated
GET    /export/csv           CSV export
GET    /export/json          JSON export                                    ⚠️ NOT IN UC (UC says PDF)
GET    /:id                  Detail with timeline
PATCH/PUT /:id/status        Update status (notes required, BR-029-03 ✓)
POST   /:id/contact          Log emergency contact (BR-029-05 audit ✓)
```

### Service (`emergency.service.js`) — verified behavior

**✅ State machine ENFORCED (BR-029-06):**
```js
// service line 443-452
if (event.status === 'resolved')
  throw 'Sự cố đã được giải quyết, không thể cập nhật thêm'
if (event.status === 'active' && status === 'resolved')
  throw 'Sự cố chưa được phản hồi, không thể chuyển đổi trực tiếp sang đã giải quyết'
if (event.status === 'responded' && status === 'active')
  throw 'Sự cố đã được phản hồi, không thể lùi trạng thái'
```
→ active → responded → resolved enforced; backward + skip rejected.

**✅ Audit log đầy đủ:**
- `admin.emergency.status_update` (BR-029-05 ✓)
- `admin.emergency.contact` (BR-029-05 ✓)

**✅ History default filter:** `status IN ['resolved', 'cancelled']` (closed events).

**✅ Active default filter:** `status IN ['active', 'responded']` (open events).

**✅ Trigger type mapping:**
- `trigger_type: 'auto'` → từ fall detected (smartwatch IMU + ML model)
- `trigger_type: 'manual'` → user nhấn nút SOS

### ⚠️ Code richer than UC — drift forward

1. **Fall countdown user-side flow** (`fall_events.user_cancelled` BOOLEAN) — schema có 2 cột `user_cancelled` + `cancel_reason` + `user_responded_at`. Mobile BE (`health_system/backend/app/services/fall_event_service.py:74-79`) derive 3 derived status từ raw fields:
   - `user_cancelled=true` → `dismissed` (user tap **"Tôi ổn"**) → SOS KHÔNG tạo
   - `user_responded_at` set (chưa cancel) → `confirmed` (user tap **"Tôi cần trợ giúp"**) → tạo SOS với `trigger_type='auto'` + link `fall_event_id`
   - `sos_triggered=true` (timeout 30s) → `escalated` → tạo SOS auto
   
   UC029 v1 KHÔNG mention button flow + dismiss/confirm/escalated derivation.

2. **`sos_events.status='cancelled'` enum** (KHÁC `fall_events.user_cancelled`) — schema enum `status IN ('active','responded','cancelled','resolved')`. Đây là status SAU KHI SOS event đã được tạo. Có 2 source set status này:
   - **Caregiver mobile**: `POST /sos/{sos_id}/resolve` với `resolution_status='cancelled'` (`health_system/backend/app/api/routes/emergency.py:122-176`)
   - **Admin BE**: `PATCH /:id/status` (`emergency.service.js:435-486`) — state machine CHỈ chặn `resolved→*`, `active→resolved` (skip), `responded→active` (backward). KHÔNG có explicit rule chặn admin set `cancelled` → **lỗ hổng state machine**.

3. **`fall-countdown` endpoint** (admin BE) — UC v1 không mention. Logic: query `fall_events` chưa create SOS / chưa responded / chưa cancelled trong 30s window để admin monitor realtime.

4. **JSON export** — UC v1 nói CSV/PDF, code có CSV+JSON (không có PDF).

5. **Trigger type mapping rules** — UC v1 mention `trigger_type` field nhưng không define mapping Fall→auto, SOS button→manual.

### 🟡 Cross-repo findings (post-cross-repo-verify 2026-05-12):

6. **`/api/v1/internal/websocket/emit-emergency` DEAD CODE in production flow:**
   - Admin BE `internal.routes.js:62-89` expose endpoint với checkInternalSecret middleware
   - Comment code: "Sau khi ghi sos_events (script, pump, thiết bị) — báo admin real-time"
   - **Test script gọi**: `HealthGuard/backend/test-inject-sos.js:28` (dev/test tool, KHÔNG production caller)
   - Search Mobile BE (`health_system/backend/app/`) + IoT Simulator (`Iot_Simulator_clean/api_server/`, `pre_model_trigger/`) **KHÔNG TÌM THẤY** ai gọi endpoint từ production code
   - → Admin web không nhận realtime SOS notification → fallback polling 15s (BR-029-01). Mất ưu thế realtime cho tình huống khẩn cấp.

7. **Auto-SOS trigger — MOBILE BE OWNS SYNC trong `/api/internal/telemetry/alert` (FINAL VERIFIED 2026-05-12):**

   **Em đã hypothesize SAI 2 lần**:
   - ❌ Lần 1: "Mobile BE background timer" — wrong mechanism, không có timer
   - ❌ Lần 2: "IoT Simulator firmware owns" — wrong owner, IoT chỉ gửi telemetry alert
   - ✅ ACTUAL: **Mobile BE telemetry router** sync trigger

   **Verified flow** (`health_system/backend/app/api/routes/telemetry.py:337-482`):
   1. **IoT Simulator/smartwatch** → `POST /api/internal/telemetry/alert` với `event_type='fall_detected'` + metadata (`confidence`, `latitude`, `longitude`, `model_version`)
   2. **Mobile BE telemetry.py:363-378**: insert `fall_events` row
   3. **Threshold gate** (line 381-416): nếu `confidence < _fall_confidence_threshold()` → SOFT alert (UC chưa document), NO SOS
   4. **Threshold pass** (line 418-437): `EmergencyService.trigger_sos(trigger_type='auto', fall_event_id=...)` SYNC → set `fall_event.sos_triggered=True` + `sos_triggered_at=now()` + commit
   5. **Post-fall risk score** (line 443-455): non-fatal, không block SOS
   6. **Push notifications** (line 467-479): patient FullScreen FallAlert FCM data-only + caregivers SOS push

   **Implications cho UC v2**:
   - 30s countdown Flutter (`fall_alert_screen.dart:20-22`) **KHÔNG quyết định SOS escalate** — SOS đã tạo TỪ TRƯỚC. Comment Flutter "backend's auto-SOS workflow takes over" SAI/mơ hồ.
   - User "Tôi ổn" tap trong 30s → set `user_cancelled=true` + `cancel_reason="Tôi ổn"` qua `POST /mobile/fall-events/{id}/dismiss`. Caregivers ALREADY alerted.
   - `derive_status` priority (`fall_event_service.py:74-79`): `sos_triggered` WINS over `user_cancelled` → status vẫn `escalated`.
   - **`enable_auto_sos` config kill-switch**: cần verify `_fall_confidence_threshold()` consume `enable_auto_sos`. Nếu KHÔNG → admin tắt trong UC024 v2 KHÔNG có effect.

   **Soft alert path (line 399-416)** — UC cũ chưa document:
   - `severity='high'`, `alert_type='fall_detection'`, message _"độ tin cậy X% dưới ngưỡng Y%, vui lòng xác nhận trước khi kích hoạt SOS"_
   - Caregiver review qua notifications list, KHÔNG full SOS takeover

**❌ Q8 OBSOLETE — UC024 v2 ALREADY DOCUMENTED:**

Kiểm tra `Resources/UC/Admin/UC024_Configure_System_v2.md:27-33`:
```
### 2.1. AI & Fall Detection
| Setting key | Type | Range | Default | Tooltip |
| confidence_threshold | float | 0.50-0.99 | 0.85 | ... |
| auto_sos_countdown_sec | int | 5-60 | 30 | ... |
| enable_auto_sos | boolean | true/false | true | ... |
```
Cộng với cross-link UC029 line 174:
> UC029 SOS: consume `confidence_threshold`, `auto_sos_countdown_sec`, `enable_auto_sos`

→ **UC024 v2 đã document đầy đủ**. Em SAI khi report missing. Q8 dropped.

**🟢 Cross-repo Good observations:**

- **Mobile BE bug fix G-3** (`emergency_service.py:173-176`): GPS `location` stamped per-recipient based on `can_view_location` flag. → **Good practice** consistent với HEALTH Q5 D-HEA-05 PHI handling + RELATIONSHIP Q4 location-default-false. Em note cross-link.
- **State machine** admin BE consistent với mobile caregiver resolve endpoint (3 status `safe/assisted/cancelled`).
- **Mobile BE NO Q7 enum bug** trong emergency flow.

---

## 💬 Anh react block

> 8 câu (Q6-Q7 add sau post-cross-repo-verify 2026-05-12, Q8 dropped sau verify UC024 v2 đã có) — code align tốt UC, mostly cần expand UC v2 để document features đã có. Q2b phát hiện lỗ hổng state machine `cancelled`. Q6 phát hiện endpoint chỉ có test script caller, Q7 verify auto-SOS trigger LIKELY thuộc IoT Simulator firmware.

---

### Q1: `fall-countdown` endpoint — document trong UC029 v2?

**Context (updated post-cross-repo-verify):**
- Code admin BE có `GET /fall-countdown` trả fall_events chưa create SOS, chưa user_responded, chưa user_cancelled
- Workflow cross-repo (verified):
  - **IoT Simulator** detect fall (ML model) → emit event + cache countdown policy per variant (30s/10s/0s)
  - **Mobile BE** ghi `fall_events` (qua webhook hoặc push từ IoT)
  - **Flutter mobile app** hiển thị countdown timer + 2 button "Tôi ổn"/"Tôi cần trợ giúp"
  - **Sau timeout** (30s) nếu user không tap: **ai auto-create SOS chưa rõ** (xem Q7)
  - **Mobile BE** `create_sos_event(fall_event_id=...)` → set `fall_events.sos_triggered=true`
- UC029 v1 KHÔNG mention flow này

**Em recommend:**
- **Add UC029 v2 section "Alt 5.f — Fall Countdown Monitoring"** document flow
- Define endpoint contract trong UC + behavior FE (countdown timer display, manual override)

**Anh decision:**
- ✅ **Em recommend (document trong UC029 v2)** ← anh CHỌN
- ☐ Drop endpoint (FE không dùng, dead code)
- ☐ Khác: ___

---

### Q2a: Fall countdown user-side flow — document trong UC029 v2?

**Context (anh đã clarify 2026-05-12):**
- Mobile app hiển thị 30s countdown với 2 button + 1 timeout outcome:
  - **"Tôi ổn"** → `fall_events.user_cancelled=true` + `cancel_reason` → derived status `dismissed` → SOS KHÔNG tạo
  - **"Tôi cần trợ giúp"** → `fall_events.user_responded_at` set + `sos_triggered=true` → derived `confirmed` → tạo SOS auto
  - **Không tap (timeout 30s)** → `sos_triggered=true` → derived `escalated` → tạo SOS auto
- UC029 v1 KHÔNG document button flow, derived status, hoặc cancel_reason field.
- Đây là **mobile UX** spec nhưng impact admin BE: `fall_events.user_cancelled` xuất hiện trong admin fall-countdown monitor + history view.

**Em recommend:**
- **Document trong UC029 v2 Alt 5.f "Fall Countdown User Response"**:
  - 3 outcome (dismissed/confirmed/escalated) + DB field mapping
  - Admin role: **read-only**, không can thiệp user response (KHÔNG có endpoint admin set `user_cancelled`)
- Cross-link với UC mobile (Phase 0.5 wave kế tiếp) — nội dung overlap nhưng từ admin lens chỉ cần document data field + display behavior.

**Anh decision:**
- ✅ **Em recommend (document UC029 v2 Alt 5.f, admin read-only)** ← anh CHỌN
- ☐ Document admin có quyền OVERRIDE user_cancelled (admin nghi ngờ false dismiss, reactivate fall event)
- ☐ Khác: ___

---

### Q2b: `sos_events.status='cancelled'` — policy ai được set?

**Context:**
- DB schema enum cho phép: `active | responded | cancelled | resolved`
- 2 source set status này (verified code):
  - **Caregiver mobile** (`POST /sos/{sos_id}/resolve` body `resolution_status='cancelled'`) — family member nhận push, vào app confirm "false alarm, người thân OK".
  - **Admin BE** (`PATCH /emergency/:id/status status='cancelled'`) — state machine không chặn → admin có thể set bất kỳ lúc nào.
- UC029 v1 BR-029-06 chỉ define `active → responded → resolved`, KHÔNG mention `cancelled` flow + ai có quyền.

**Em recommend Option A — caregiver-only:**
- **`cancelled` = caregiver action only**, document trong UC029 v2 BR-029-06 expanded:
  - `active → responded → resolved` (admin path) OR
  - `active → cancelled` (caregiver resolve với false alarm) — terminal
- **Admin BE add rule chặn**: admin PATCH status KHÔNG được set `cancelled` (chỉ resolved). Throw 400 "Admin không được hủy SOS — chỉ family/caregiver được hủy false alarm qua mobile app".
- Effort: ~30 phút Phase 4 add validator rule.

**Trade-off vs Option B (admin có quyền cancel):**
- Option B đơn giản code-side (giữ nguyên state machine), nhưng tạo ambiguity: admin cancel = false alarm? hay admin hủy điều phối? → confuse audit trail.
- Option A clarify ownership: caregiver = closest người biết tình hình thực; admin = monitor + escalate, không phán xét false alarm.

**Anh decision:**
- ✅ **Option A: Caregiver-only cancel (em recommend)** ← anh CHỌN
- ☐ Option B: Cả admin + caregiver được cancel (document explicit cả 2 trong UC v2, admin cancel cần `notes` field bắt buộc)
- ☐ Option C: Drop `cancelled` status hoàn toàn (caregiver resolve với `resolution_status='safe'` thay cho `'cancelled'`, admin chỉ `resolved`) → migration: convert existing `cancelled` rows → `resolved` với note `[converted from cancelled]`
- ☐ Khác: ___

---

### Q3: Trigger type mapping (auto/manual)

**Context:**
- Code: `trigger_type` enum {auto, manual} với mapping:
  - `auto` = từ fall detected (Fall Event)
  - `manual` = user nhấn nút SOS (SOS Event)
- UC v1 mention field nhưng không define mapping rule
- FE filter UC ngụ ý: `type=Fall` → query `trigger_type='auto'`; `type=SOS` → `trigger_type='manual'`

**Em recommend:**
- **Document mapping trong UC029 v2 BR-029-07** rõ Fall=auto, SOS button=manual
- Add column "Trigger source" trong table display

**Anh decision:**
- ✅ **Em recommend (document mapping rule trong UC)** ← anh CHỌN
- ☐ Khác: ___

---

### Q4: Export format — PDF vs JSON

**Drift:**
- UC v1 nói CSV/PDF
- Code có CSV + JSON

**Trade-off:**
- **JSON for developers/integration** (machine-readable, easy parse)
- **PDF for stakeholders** (printable, formatted, presentation)
- Đồ án 2: thầy đánh giá có thể prefer PDF (visual report)

**Em recommend:**
- **Keep JSON** (đã có code, useful cho dev/admin) → document trong UC v2
- **Drop PDF requirement** từ UC v2 (overkill cho đồ án 2, PDF rendering complex)
- Phase 5+ add PDF nếu stakeholder cần

**Anh decision:**
- ✅ **Em recommend (keep CSV+JSON, drop PDF from UC)** ← anh CHỌN
- ☐ Add PDF (~3h implement PDF rendering với puppeteer/pdfkit)
- ☐ Drop JSON (keep only CSV theo UC v1)
- ☐ Khác: ___

---

### Q6: `/emit-emergency` internal endpoint dead code check (NEW post-cross-repo-verify)

**Context:**
- Admin BE `internal.routes.js:62-89` expose endpoint `POST /api/v1/internal/websocket/emit-emergency`
- Check internal secret middleware
- Comment: "Sau khi ghi sos_events (script, pump, thiết bị) — báo admin real-time"
- Search Mobile BE (`health_system/backend/app/`) + IoT Simulator (`Iot_Simulator_clean/`) → **KHÔNG TÌM THẤY CALLER**

**Implications:**
- Admin web không nhận realtime SOS notification khi mobile BE tạo SOS
- Admin fallback polling `/emergency/active` mỗi 15s (BR-029-01)
- Mất up to 15s delay cho tình huống khẩn cấp

**Em recommend Option A:**
- **Phase 4 verify caller** (~30min): grep pump scripts trong các repo + git blame, nếu có legacy caller → keep + add modern caller. Nếu không → drop endpoint.
- Nếu KHÔNG có caller: **Add caller mới tại Mobile BE** sau `create_sos_event` (~1h): HTTP POST cross-repo với internal-secret → admin BE → WebSocket emit. Được giữ lại realtime advantage.

**Trade-off vs Option B (drop endpoint, accept polling):**
- Đồ án 2 demo: polling 15s acceptable
- Production-ready: realtime push mới suitable cho emergency

**Anh decision:**
- ✅ **Option A: Verify caller + add modern caller nếu cần (em recommend)** ← anh CHỌN
- ☐ Option B: Drop endpoint, accept 15s polling fallback
- ☐ Option C: Add caller mới ngay Phase 4 (~1h cần cross-repo HTTP call setup)
- ☐ Khác: ___

---

### Q7: Auto-SOS cross-repo flow document (NEW post-cross-repo-verify)

**Context:**
- 3 sources of truth phân tán:
  1. IoT Simulator countdown policy per variant (`tests/test_fall_ai_module.py:521-524, 632-637`)
  2. IoT Simulator config DB `enable_auto_sos` + `auto_sos_countdown_sec` (`tests/test_settings_provider.py:99-110`)
  3. Mobile BE `EmergencyService.create_sos_event(fall_event_id=...)` (`emergency_service.py:126`)
- Chưa rõ **ai trigger** auto-SOS sau countdown expire.

**Implications:**
- UC029 v2 thiếu document cross-repo flow → maintainer không biết fix bug ai nào
- Risk: 2 sources trigger same SOS → duplicate sos_events (dedup window có trong code: `SOS_DEDUP_WINDOW_SECONDS`)

**Em FINAL recommend Option A** (sau verify Mobile BE telemetry.py 2026-05-12):

- Em RETRACT 2 hypothesize trước đó (timer + IoT Simulator). VERIFIED actual: Mobile BE OWNS sync trigger trong `/api/internal/telemetry/alert`.

- **Option A FINAL — Document UC029 v2 + UC v2 cleanup**:
  - **Document UC029 v2 Alt 5.g "Auto-SOS Trigger Flow"** (đúng architecture):
    - **Telemetry ingest endpoint**: `POST /api/internal/telemetry/alert` (require_internal_service guard)
    - **Threshold gate**: confidence >= `_fall_confidence_threshold()` (consume `confidence_threshold` config UC024)
    - **Auto-SOS sync**: `EmergencyService.trigger_sos(trigger_type='auto')` synchronously trong endpoint, KHÔNG có timer
    - **30s countdown UX role**: chỉ self-acknowledgment cho user dismiss (caregivers đã được alert TRƯỚC)
    - **Soft alert path**: confidence < threshold → high-severity Alert row, NO SOS, caregiver review notification
  - **Verify `_fall_confidence_threshold()` consume `enable_auto_sos` kill-switch** (để admin tắt đúng UC024 v2 chốt)
  - **Update Flutter comment misleading**: `fall_alert_screen.dart:20-22` _"backend's auto-SOS workflow takes over"_ → SAI. Đúng: _"SOS đã được create TỪ TRƯỚC khi countdown begin; 30s countdown là UX warning user kịp dismiss self-acknowledge"_

**Phase 4 effort:**
- ~30min verify `_fall_confidence_threshold()` consume `enable_auto_sos` (nếu không → ~15min fix)
- ~30min update Flutter comment + UC029 v2 doc Alt 5.g
- 0h fix SOS trigger logic (đã work correct)

**Anh decision:**
- ✅ **Option A FINAL: Document UC029 v2 + verify kill-switch + fix Flutter comment (em recommend)** ← anh CHỌN
- ☐ Option B: Implement tính năng "reverse escalation nếu user Tôi ổn trong 30s" (bắt caregivers KHÔNG nhận alert nếu user dismiss kịp — thay đổi UX behavior)
- ☐ Option C: Skip UC update (giữ Flutter comment misleading + UC v2 missing)
- ☐ Khác: ___

---

### ~~Q8: `enable_auto_sos` + `auto_sos_countdown_sec` UC024 CONFIG~~ (DROPPED 2026-05-12)

**Em report SAI khi cho rằng UC024 v2 missing.** Verify UC024 v2 của anh đã document **đầy đủ 3 fields** trong section `2.1. AI & Fall Detection` (line 27-33) với:
- Type, Range, Default, Tooltip Vietnamese
- Cross-link UC029 SOS line 174

→ Q8 OBSOLETE. KHÔNG cần decision.

---

### Q5: GPS location PHI handling

**UC NFR Security:** "GPS location là dữ liệu nhạy cảm, chỉ hiển thị trong context sự cố active"

**Code state:** Em chưa verify hết. Cần check:
- `GET /:id` (detail): trả GPS cho mọi status?
- `GET /history`: list có expose GPS cho resolved events?
- `GET /export/*`: CSV/JSON có chứa GPS cho resolved events?

**Risk:**
- Resolved event = case closed → expose GPS không cần thiết = leak PHI
- Admin có thể download CSV/JSON với GPS coordinate hàng loạt

**Em recommend:**
- **Phase 4 audit verify** GPS field handling per status:
  - `active` status: GPS visible trong detail + active list
  - `responded` status: GPS visible (vẫn ongoing)
  - `resolved`/`cancelled` status: GPS **MASKED** (chỉ admin với explicit "Reveal" action)
- **Document trong UC029 v2** BR-029-08 (PHI handling rule)
- Effort ~1h Phase 4 audit + ~1h add masking logic

**Anh decision:**
- ✅ **Em recommend (Phase 4 audit + mask GPS cho closed events)** ← anh CHỌN
- ☐ Keep GPS visible mọi status (đơn giản, accept risk)
- ☐ Mask GPS cho TẤT CẢ list (chỉ visible khi click "Reveal" + audit log)
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Bulk status update** — conflict BR-029-03 (notes per event required), risky cho emergency workflow
- ❌ **Auto-escalation (SOS > 5min)** — đồ án 2 chỉ 1 role admin, không có second-level
- ❌ **Geofencing alert** — không có "safe zone" feature trong scope
- ❌ **Voice note attach** — audio storage + transcription = overkill
- ❌ **Real-time GPS tracking live** — Phase 5+; WebSocket emit emergency đã có cho realtime status update
- ❌ **AI risk re-classification** — ADR-006 đã chốt MLOps mock-only

---

## 🆕 Features mới em recommend

**Không có.** Em scan module không thấy gap critical. EMERGENCY hiện tại đã cover đầy đủ workflow (active monitoring, history, detail, status update với traceability, fall countdown, emergency contact log).

---

## ❌ Features em recommend DROP

**Không có.** Em scan 10 endpoints + UC Alt flows. Tất cả endpoints có mapping với UC + verify code đang used. Không có dead code/legacy.

---

## 🆕 Features anh nghĩ ra

_(anh không add thêm gì trong wave EMERGENCY)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC029 Emergency Management | **Update v2** | Add fall-countdown admin endpoint (Q1), fall user-flow Alt 5.f (Q2a), state machine `cancelled` policy (Q2b), trigger type rule (Q3), export format JSON (Q4), GPS PHI BR-029-08 (Q5) |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| Fall countdown admin endpoint (Q1) | Document UC029 v2 (D-EMG-01) | 0h code; UC update | 🟢 Doc only |
| Fall countdown user flow (Q2a) | Document UC029 v2 Alt 5.f, admin read-only (D-EMG-02a) | 0h code; UC update | 🟢 Doc only |
| `cancelled` status policy (Q2b) | Option A: Caregiver-only cancel (D-EMG-02b) | `fix(emergency): admin BE validator chặn PATCH status='cancelled'` (~30min) | 🟡 Policy + State machine |
| Trigger type mapping (Q3) | Document BR-029-07 (D-EMG-03) | 0h code; UC update | 🟢 Doc only |
| Export format (Q4) | Keep CSV+JSON, drop PDF (D-EMG-04) | 0h code; UC update | 🟢 Doc only |
| GPS PHI handling (Q5) | Audit + mask cho closed events (D-EMG-05) | `fix(security): mask GPS cho resolved/cancelled events` (~2h: audit ~1h + mask ~1h) | 🔴 Security |
| emit-emergency dead code (Q6) | Verify caller + add modern caller (D-EMG-06) | `verify(internal): emit-emergency caller + Mobile BE add HTTP call` (~30min verify + ~1h add caller nếu cần) | 🟡 Performance |
| Auto-SOS trigger owner (Q7 FINAL) | Document UC029 v2 + verify kill-switch + fix Flutter comment (D-EMG-07) | `verify(emergency): _fall_confidence_threshold() consume enable_auto_sos kill-switch` (~30min verify, ~15min fix nếu KHÔNG) + UC029 v2 Alt 5.g doc + Flutter comment fix | 🟢 Doc + verify |

**Estimated Phase 4 effort:** ~4.5h code (Q2b 30min + Q5 GPS 2h + Q6 verify+caller 1.5h + Q7 verify+fix 30-45min) + 1 UC029 v2 update (Q8 dropped)

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-EMG-01 | Fall countdown admin endpoint UC document | **Document UC029 v2 Alt 5.f** | Admin endpoint hiện có + FE cần monitor, UC v1 missing |
| D-EMG-02a | Fall countdown user flow (button + derived status) | **Document UC029 v2 Alt 5.f + admin read-only** | Anh clarify 2 button flow + timeout; code mobile BE đã derive `dismissed/confirmed/escalated` |
| D-EMG-02b | `sos_events.status='cancelled'` policy | **Option A: Caregiver-only cancel + admin BE add validator chặn** | Caregiver = closest người biết tình hình thực; admin = monitor + escalate, không phán xét false alarm; clarify audit trail |
| D-EMG-03 | Trigger type mapping rule | **Document BR-029-07 Fall=auto, SOS button=manual** | Code-side enforced, UC missing rule |
| D-EMG-04 | Export format | **Keep CSV+JSON, drop PDF** | JSON useful cho dev; PDF rendering complex, defer Phase 5+ |
| D-EMG-05 | GPS PHI handling | **Audit + mask cho resolved/cancelled events** | UC NFR explicit "GPS context-only"; PHI compliance |
| D-EMG-06 | emit-emergency dead code check | **Verify caller + add modern caller nếu cần** | Admin web mất realtime SOS notification; polling 15s fallback mất ưu thế emergency; verify Phase 4 + add modern caller |
| D-EMG-07 (FINAL) | Auto-SOS trigger owner | **Mobile BE OWNS SYNC trong telemetry alert ingest — document UC029 v2 + verify kill-switch + fix Flutter comment** | VERIFIED 2026-05-12 tại `telemetry.py:418-437`: SYNC `EmergencyService.trigger_sos(trigger_type='auto')` khi confidence pass threshold; 30s Flutter countdown chỉ UX self-ack, KHÔNG quyết định escalation; em hypothesize SAI 2 lần trước đó |
| ~~D-EMG-08~~ DROPPED | UC024 auto_sos fields | **UC024 v2 ĐÃ document đầy đủ** (line 27-33) | Em sai khi report missing; UC024 v2 có 3 fields với tooltip + range + default + cross-link UC029 |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Bulk status update | ❌ Drop (conflict BR-029-03) |
| Auto-escalation (SOS > 5min) | ❌ Drop (đồ án 2 single admin) |
| Geofencing alert | ❌ Drop (no safe zone feature) |
| Voice note attach | ❌ Drop (overkill) |
| Real-time GPS tracking live | ❌ Drop (Phase 5+) |
| AI risk re-classification | ❌ Drop (ADR-006 mock) |

**All 6 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

- UC029 cũ: `Resources/UC/Admin/UC029_Emergency_Management.md`
- Routes admin: `HealthGuard/backend/src/routes/emergency.routes.js`
- Service admin: `HealthGuard/backend/src/services/emergency.service.js`
- Service mobile (derived status logic): `health_system/backend/app/services/fall_event_service.py:74-79`
- Service mobile (create_sos_event): `health_system/backend/app/services/emergency_service.py:126-144` (Q7 cross-repo)
- Route mobile resolve SOS: `health_system/backend/app/api/routes/emergency.py:122-176`
- DB tables: `sos_events`, `fall_events`, `emergency_contacts`
- DB schema canonical: `PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql`
- DB `system_settings` (UC024 v2 đã document): `confidence_threshold`, `enable_auto_sos`, `auto_sos_countdown_sec`
- INTERNAL module: WebSocket emit `emit-emergency` cho admin FE realtime — **Q6 verify caller**
- Admin BE internal route: `HealthGuard/backend/src/routes/internal.routes.js:62-89` (Q6)
- **Cross-repo IoT Simulator (Q7)**: 
  - Countdown policies: `Iot_Simulator_clean/api_server/runtime/...` + `tests/test_fall_ai_module.py:521-524, 632-637` (variants: confirmed 30s, fall_brief 10s, false_fall 0s, fall_no_response 30s, fall_from_bed 30s, slip_recovery 0s)
  - Settings provider: `Iot_Simulator_clean/api_server/system_settings_provider.py` + `tests/test_settings_provider.py:99-110`
  - BackendAdminClient: `Iot_Simulator_clean/api_server/backend_admin_client.py` (cross-repo HTTP)
- **Cross-repo Mobile BE telemetry (Q7 FINAL VERIFIED)**:
  - Auto-SOS trigger SYNC: `health_system/backend/app/api/routes/telemetry.py:337-482` (endpoint `POST /api/internal/telemetry/alert`)
  - `EmergencyService.trigger_sos`: `telemetry.py:418-428` với `trigger_type='auto'`
  - Set `fall_event.sos_triggered=True`: `telemetry.py:435-437`
  - Threshold gate: `telemetry.py:381-416` (soft alert nếu confidence < threshold)
  - E2E smoke test: `health_system/backend/scripts/e2e_fall_sos_survey_smoke.py` document full flow
- **Cross-repo Flutter mobile (Q7 verified)**:
  - Fall countdown UI: `health_system/lib/features/fall/screens/fall_alert_screen.dart:20-22` (UI 30s self-ack, comment "backend's auto-SOS workflow takes over" — **MISLEADING**, cần fix)
  - Risk alert overlay: `health_system/lib/features/emergency/widgets/risk_alert_full_screen_overlay.dart:108-122` (HAS auto-trigger callback `onTimeoutEscalated` — KHÁC với fall flow)
  - Manual SOS API: `health_system/lib/features/emergency/repositories/emergency_caregiver_repository.dart:84-87` (`POST /emergency/sos/trigger` với `trigger_type='manual'`)
- **UC024 v2 đã document Q8**: `Resources/UC/Admin/UC024_Configure_System_v2.md:27-33` (3 fields + tooltip + range + default + cross-link UC029 line 174)
- **Cross-link finding G-3** (Mobile BE bug fix): `health_system/backend/app/services/emergency_service.py:173-176` GPS per-recipient based on `can_view_location` flag — consistent với HEALTH Q5 D-HEA-05 + RELATIONSHIP Q4 location-default-false
- UC027 Dashboard: include emergency stats trong summary
- UC024 CONFIG v2: `Resources/UC/Admin/UC024_Configure_System_v2.md` (line 27-33 documented; line 174 cross-link UC029)
- Phase 1 audit: M02, M04 audit reports
- Mobile flow (cross-repo): `health_system/backend` emergency endpoints — Phase 0.5 next track
