# Intent Drift Review — `HealthGuard / VITAL_ALERT_ADMIN`

**Status:** � Confirmed (anh chọn theo em recommend Q1-Q4; Q3 verified KHÔNG có `user_vital_thresholds` table + FE 0 consume → drop SAFE; 4 add-ons drop)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** VITAL_ALERT_ADMIN (Background vital→alert processor management + thresholds)
**Related UCs (old):** **NONE** — module orphan, UC028 có mention threshold-alerts view
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 4 (LEGACY scope decision + duplicate routes)

---

## 🎯 Mục tiêu

Capture intent cho VITAL_ALERT module. **Đặc thù:** code có comment explicit "ĐÃ TẮT THEO YÊU CẦU SẾP" → toàn bộ module là legacy. Architecture đã shift sang **real-time alerts** (mobile BE submit vitals → tạo alert ngay → WebSocket emit).

---

## 📚 UC tham chiếu — KHÔNG CÓ trực tiếp

- UC028 Health Overview mention "Threshold alerts" view (read-only display)
- UC024 CONFIG có **global thresholds** (HR/SpO₂/BP/Temp ranges)
- UC029 Emergency cover SOS/Fall (khác scope với vital threshold alerts)

**Không có UC riêng** cho:
- Background processor management (bật/tắt, status)
- Per-user thresholds (override global)
- Testing endpoints process single/range vital

---

## 🔧 Code state — verified

### 🚨 Background processor — ĐÃ TẮT

`jobs/vital-processor.js:1-110`:
```js
class VitalProcessor {
  constructor() {
    this.enabled = false; // TẮT - Dùng real-time alerts thay thế
  }
}
```
- Comment line 7: **"ĐÃ TẮT THEO YÊU CẦU SẾPF"** (typo "SẾPF" trong code)
- Default `enabled = false`
- Designed: chạy mỗi 5 phút, query vitals 5min window → process thành alerts → WebSocket emit
- Singleton instance — never auto-start

### 2 routes files — DUPLICATE scope

**File 1 `vital-alert.routes.js`** (mount `/api/v1/admin/vital-alerts`):
```
authenticate + requireAdmin + vitalAlertLimiter (30/min)

POST /process                    Manual batch process range {startTime, endTime}
GET  /processor/status           Get processor enabled/isRunning state
POST /processor/toggle           Enable/disable processor {enabled: bool}
GET  /thresholds                 Get GLOBAL thresholds (from CONFIG)
```
→ Admin tool: lifecycle management cho disabled background processor.

**File 2 `vital-alerts.js`** (mount `/api/v1/vital-alerts`):
```
authenticate + requireAdmin (per-route, không globally)

GET  /thresholds/:userId         PER-USER thresholds
PUT  /thresholds/:userId         Update per-user thresholds
GET  /vital/:deviceId/:timestamp Get alerts for specific vital reading
POST /process                    Single vital process (Swagger: "Testing endpoint")
POST /process-range              Batch process range (Swagger: "Testing endpoint")
```
→ Mostly testing/dev tool + per-user feature.

### ⚠️ Drift issues

1. **Duplicate `POST /process` endpoint** ở 2 files với **khác signature**:
   - File 1: `{startTime, endTime}` (range)
   - File 2: `{vitalData, deviceId}` (single)
   - Khác mount path nên không conflict, NHƯNG confusing semantics.

2. **Per-user thresholds (File 2)** override global từ CONFIG (UC024):
   - UC024 chỉ có global thresholds
   - Code có per-user table/field nhưng UC missing
   - Cross-module impact: UC028 BR-028-02 nói thresholds từ UC024 (global). Per-user thresholds chưa được spec.

3. **Testing endpoints production-exposed:** File 2 Swagger ghi rõ "Testing endpoint" nhưng route active với admin auth → production-accessible.

4. **Validation pattern inconsistent:**
   - File 1: controller-side ad-hoc validation
   - File 2: custom middleware (`validateUserId`, `validateDeviceId`, `validateTimestamp`)
   - Codebase pattern: `validate(rules)` middleware (như AUTH, EMERGENCY)

5. **No UC mapping** cho processor lifecycle + per-user thresholds.

---

## 💬 Anh react block

> 4 câu — module phần lớn legacy, focus scope decision.

---

### Q1: 🟡 Module scope — LEGACY drop hay maintenance keep?

**Context:**
- Background processor `enabled = false` mặc định + comment "TẮT theo yêu cầu sếp"
- Architecture đã shift sang real-time alerts (mobile BE → alert ngay → WebSocket)
- 4 endpoints File 1 + 5 endpoints File 2 = **9 endpoints serving disabled feature**

**Options:**

| Approach | Pros | Cons |
|---|---|---|
| **A. Keep all 9 endpoints (maintenance)** | Admin debug/manual reprocess khi cần | Code maintain 200+ lines dead-ish; confusion về architecture |
| **B. Drop File 2 + keep File 1 minimal (status only)** | Clean codebase; keep status visibility | Lose per-user thresholds + manual process; cần migration UC024 |
| **C. Drop entire module** | Cleanest | Lose debug capability; risky nếu real-time alerts fail |
| **D. Hybrid: Keep `GET /processor/status` + drop rest** | Minimal maintenance; status visible | Lose manual reprocess capability |

**Em recommend:**
- **Option B — Drop File 2 + keep File 1 minimal**
  - File 1 keep: `GET /processor/status`, `POST /processor/toggle` (admin can re-enable nếu real-time fails)
  - File 1 keep: `GET /thresholds` (global thresholds reference, alias cho CONFIG)
  - File 1 drop: `POST /process` (manual batch reprocess — risky duplicate alerts)
  - File 2 drop hoàn toàn (testing endpoints + per-user thresholds → see Q3)
- ADR record: "VITAL_ALERT_ADMIN module status post-shift to real-time alerts"
- Effort: ~2h cleanup + 1 UC ratification

**Anh decision:**
- ✅ **Em recommend (Option B — minimal maintenance)** ← anh CHỌN
- ☐ Option A (keep all 9, code maintenance burden)
- ☐ Option C (drop entire module, risky)
- ☐ Option D (status-only, more aggressive than B)
- ☐ Khác: ___

---

### Q2: Duplicate routes file — merge hay drop one?

**Current:** 2 files cùng scope `/vital-alerts`:
- `vital-alert.routes.js` — admin processor lifecycle
- `vital-alerts.js` — testing + per-user thresholds

**Em recommend (depend Q1):**
- **Nếu Q1 chọn Option B:** Keep File 1 only (renamed `vital-alerts.routes.js` consistent với codebase pattern), drop File 2 entirely
- **Nếu Q1 chọn Option A:** Merge File 2 endpoints vào File 1 → 1 file `vital-alerts.routes.js`

**Anh decision:**
- ✅ **Em recommend (Q1 Option B → drop File 2, keep File 1)** ← anh CHỌN
- ☐ Merge 2 files thành 1 (Option A path)
- ☐ Khác: ___

---

### Q3: Per-user thresholds (File 2) — keep hay drop?

**Conflict:** UC024 CONFIG chốt **global thresholds** (HR/SpO₂/BP/Temp ranges chung). File 2 có endpoints per-user thresholds override.

**Em verified 2026-05-12:**
- DB schema: `user_vital_thresholds` table **KHÔNG tồn tại** trong Prisma schema + SQL canonical
- FE: **0 references** tới `/vital-alerts/thresholds/:userId`, `/vital-alerts/process`, `/vital-alerts/vital/:deviceId/:timestamp`
- → **Drop SAFE**: không có data dependency, không có FE dependency

**Em recommend:**
- **Drop per-user thresholds endpoints** (Q1 Option B sẽ drop File 2 = drop tự nhiên)
- Lý do:
  - UC024 chốt global; per-user override = scope creep
  - Đồ án 2 không cần granular per-user customization (admin có thể sửa global cho all)
  - Verified safe: KHO data + FE

**Anh decision:**
- ✅ **Em recommend (drop per-user thresholds, keep global từ CONFIG)** ← anh CHỌN; verified safe drop
- ☐ Keep per-user thresholds (Phase 4 verify DB schema + create UC)
- ☐ Khác: ___

---

### Q4: UC mapping — orphan module

**Context:** Module orphan, không có UC. Nhưng Q1 chọn Option B → còn 3 endpoints cần spec.

**Em recommend:**
- **NO new UC standalone** (3 endpoints quá nhỏ cho 1 UC)
- **Add brief section trong UC028 Health Overview** "Background Processor Reference" (status-only, không user-facing main flow)
- **ADR (optional):** "Vital alerts shift sang real-time architecture" — document decision của sếp
  - Nếu anh muốn em tạo ADR-008

**Anh decision:**
- ✅ **Em recommend (UC028 brief section + optional ADR-008)** ← anh CHỌN
- ☐ Create UC033 Vital Alert Admin (standalone UC for 3 endpoints)
- ☐ No doc (chỉ code comment đủ)
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Alert dedup** — real-time pipeline (mobile BE → emit) handle scope; production hardening Phase 5+
- ❌ **Alert severity rule engine** — out of scope Phase 5+
- ❌ **Webhook notification** — Phase 5+ external integration
- ❌ **Threshold profile templates** — complex Phase 5+ feature

---

## 🆕 Features mới em recommend

**Không có** — Q1 Option B đã định scope rõ. Module chỉ cần minimal maintenance.

---

## ❌ Features em recommend DROP

Tổng hợp từ Q1+Q2+Q3 nếu chọn em recommend:

- ❌ `POST /admin/vital-alerts/process` (manual batch reprocess, risky)
- ❌ `GET /vital-alerts/thresholds/:userId` (per-user, conflict UC024 global)
- ❌ `PUT /vital-alerts/thresholds/:userId` (per-user write)
- ❌ `GET /vital-alerts/vital/:deviceId/:timestamp` (testing endpoint)
- ❌ `POST /vital-alerts/process` (testing endpoint)
- ❌ `POST /vital-alerts/process-range` (testing endpoint)
- ❌ File `vital-alerts.js` toàn bộ
- ❌ Custom validation middleware (`validateUserId`, etc.) trong File 2

→ **6 endpoints + 1 file** drop. Service `processVitalsInTimeRange` keep (vital-processor.js có thể re-enable).

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| **NONE — orphan module** | Resolved | Brief section trong **UC028 Health Overview** v2 ("Background Processor Reference") + **ADR-008** (optional, document architecture shift sang real-time) |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| Module scope decision (Q1) | Option B minimal maintenance (D-VAA-01) | `chore: drop 6 vital-alert endpoints + File vital-alerts.js` (~1.5h) | 🟡 Cleanup |
| Duplicate routes (Q2) | Drop File 2 (D-VAA-02) | Same task as Q1 | 🟡 Cleanup |
| Per-user thresholds (Q3) | Drop verified safe (D-VAA-03) | Same task as Q1 (no DB migration nên không cần cleanup data) | 🟢 Safe |
| UC mapping (Q4) | UC028 brief + ADR-008 (D-VAA-04) | UC028 v2 update + create ADR-008 | 🟢 Doc |

**Estimated Phase 4 effort:** ~1.5h code cleanup + UC028 v2 brief section + 1 ADR

### Endpoints drop summary (Phase 4)

**File `vital-alerts.js` drop ENTIRELY** (5 endpoints):
- `GET /vital-alerts/thresholds/:userId`
- `PUT /vital-alerts/thresholds/:userId`
- `GET /vital-alerts/vital/:deviceId/:timestamp`
- `POST /vital-alerts/process`
- `POST /vital-alerts/process-range`

**File `vital-alert.routes.js` drop 1 endpoint** (keep 3):
- ❌ `POST /admin/vital-alerts/process` (manual batch reprocess, risky duplicates)
- ✅ KEEP `GET /admin/vital-alerts/processor/status`
- ✅ KEEP `POST /admin/vital-alerts/processor/toggle`
- ✅ KEEP `GET /admin/vital-alerts/thresholds`

**Service code:** `processVitalsInTimeRange` keep (vital-processor.js có thể re-enable). Controller/service code liên quan endpoints drop → cleanup.

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-VAA-01 | Module scope (legacy) | **Option B — minimal maintenance (3/9 endpoints)** | Architecture shifted real-time; processor disabled; keep status visibility cho admin debug |
| D-VAA-02 | Duplicate routes | **Drop File 2 `vital-alerts.js` entirely** | File 2 = testing endpoints + per-user thresholds (verified safe drop) |
| D-VAA-03 | Per-user thresholds | **Drop (verified KHÔNG có data + FE 0 consume)** | UC024 chốt global; per-user override = scope creep; safe verified |
| D-VAA-04 | UC mapping | **UC028 brief section + optional ADR-008** | 3 endpoints quá nhỏ cho UC riêng; ADR document architecture shift quan trọng |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Alert dedup | ❌ Drop (Phase 5+ hardening) |
| Severity rule engine | ❌ Drop (Phase 5+) |
| Webhook notification | ❌ Drop (Phase 5+) |
| Threshold profile templates | ❌ Drop (Phase 5+ complex) |

**All 4 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

- Routes: `HealthGuard/backend/src/routes/vital-alert.routes.js`, `vital-alerts.js`
- Controller: `HealthGuard/backend/src/controllers/vital-alert.controller.js`
- Service: `HealthGuard/backend/src/services/vital-alert.service.js`
- Job: `HealthGuard/backend/src/jobs/vital-processor.js` (DISABLED by default)
- Related modules:
  - UC024 CONFIG — global thresholds (BR-024-XX)
  - UC028 Health Overview — threshold-alerts view (BR-028-02 ref UC024)
  - INTERNAL — WebSocket emit-alert
- Architecture shift: Real-time alerts pipeline (mobile BE → alert → WebSocket) replaced batch processor
