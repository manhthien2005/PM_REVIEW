# Intent Drift Review — `HealthGuard / INTERNAL`

**Status:** � Confirmed (anh chọn theo em recommend Q1-Q5; Q5 verified cross-repo; add-on Sanitize errors keep)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** INTERNAL (Service-to-service WebSocket emit endpoints)
**Related UCs (old):** **NONE** — module orphan, không có UC mapping
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md` (finding D-010 internal secret fallback)
**Date prepared:** 2026-05-12
**Question count:** 5 (3 critical security + 2 architecture)

---

## 🎯 Mục tiêu

Capture intent cho INTERNAL module — chưa có UC. Module này là contract giữa các services (scripts, pump, model API, IoT sim) gọi BE để emit WebSocket events ra Admin FE realtime.

**Cần tạo UC mới hoặc formalize trong ADR cross-repo contract.**

---

## 📚 UC tham chiếu — KHÔNG CÓ

INTERNAL không có UC v1. **Approach C chốt** (ADR + brief section trong UC027):
- **ADR** `<NNN>-internal-service-secret-strategy.md` (cross-repo contract)
- **Brief section** trong `UC027_Admin_Dashboard_v2.md` (vì WebSocket emit phục vụ dashboard real-time)

## 🔍 Q5 Verification result (em verify cross-repo)

**Architecture thực tế đã verify:**
```
Mobile app (Flutter)  ──┐
                         ├──→ health_system/backend ──→ model API (stateless)
IoT sim (FastAPI)  ─────┘            │
                                      ├──→ Postgres (write)
                                      └──→ HealthGuard BE /api/v1/internal/websocket/*
```

**Cross-repo references đã verify:**
- `Iot_Simulator_clean/api_server/backend_admin_client.py` → gọi `health_system/backend` `/mobile/admin/*` endpoints. Auth: chỉ `X-Internal-Service: iot-simulator` header (KHÔNG kèm `X-Internal-Secret` — flag finding cho Phase 0.5 health_system audit).
- `health_system/backend/app/core/dependencies.py:147-153` `require_internal_service` check dual header `X-Internal-Service` + `X-Internal-Secret`.
- `healthguard-model-api/app/*`: stateless ML predict, không gọi cross-repo, không ghi DB.

**Kết luận:** HealthGuard `/api/v1/internal/*` hiện tại CHỈ phục vụ pump scripts nội bộ HealthGuard. Cross-repo ingestion thực sự xảy ra ở **health_system BE** — em sẽ audit kỹ khi Phase 0.5 module đó.

---

## 🔧 Code state

**Routes (`internal.routes.js`):** 3 endpoints

```
checkInternalSecret middleware (X-Internal-Secret header) — TẤT CẢ routes

POST  /api/v1/internal/websocket/emit-alert       Emit alert mới ra Admin FE
POST  /api/v1/internal/websocket/emit-emergency   Emit SOS/fall ra Admin FE
POST  /api/v1/internal/websocket/emit-risk        Emit risk score update ra Admin FE
```

**Middleware critical issue:**

```js
const expectedSecret = process.env.INTERNAL_SECRET || 'internal-secret-key';
```

→ **CRITICAL:** Nếu `INTERNAL_SECRET` env không set → secret = hardcoded `'internal-secret-key'` → bất kỳ ai biết string này = bypass auth.

**Body validation:**
- emit-alert: chỉ check `alert.id` exists
- emit-emergency: chỉ check `emergency.id` exists
- emit-risk: chỉ check `riskScore.userId` exists
- KHÔNG có schema validation đầy đủ (severity enum, timestamp format, etc)

**Other observations:**
- KHÔNG rate limit
- KHÔNG IP allowlist
- KHÔNG audit log cho internal calls
- KHÔNG idempotency key support
- Error response 500 expose `error.message` (leak risk)
- 1 endpoint duplicate definition: `emit-risk` được define trên 2 dòng khác nhau (line 91 sau emit-emergency line 65) — code organization mess nhưng không bug functional

**Phase 1 audit findings (relevant):**
- M02 Routes 🔴 **D-010 critical** — internal secret fallback hardcoded. Reproduces ở model API + IoT sim cùng pattern → cross-repo issue.
- ADR candidate: `<NNN>-internal-service-secret-strategy.md`

---

## 💬 Anh react block

> 5 câu — không pad. Q1 là blocker security cần fix Phase 4 ngay.

---

### Q1: 🔴 CRITICAL — Internal secret hardcoded fallback

**Code:**
```js
const expectedSecret = process.env.INTERNAL_SECRET || 'internal-secret-key';
```

**Severity:** 🔴 **HIGH** (production deploy quên env → trivial auth bypass)

**Cross-repo:** Cùng pattern đã thấy ở:
- `healthguard-model-api` (M04 bootstrap audit — internal secret check missing)
- `Iot_Simulator_clean` (M03 middleware audit — partial enforcement)

**Em recommend:**
- **Phase 4 fix ngay (~30min):**
  - Remove fallback: `const expectedSecret = process.env.INTERNAL_SECRET;`
  - At app startup (`index.js` hoặc `bootstrap.js`): nếu `!process.env.INTERNAL_SECRET` → `throw new Error('INTERNAL_SECRET env var is required')` → fail fast
  - `.env.example` document cách generate secret: `openssl rand -hex 32`
  - **Cross-repo coordination:** apply cùng pattern cho model API + IoT sim cùng Phase 4 sprint
- **ADR record:** `<NNN>-internal-service-secret-strategy.md` — single shared secret per env, rotated quarterly, never log

**Anh decision:**
- ✅ **Em recommend (remove fallback, fail-fast startup, cross-repo coordinate)** ← anh CHỌN
- ☐ Keep fallback nhưng warn loud (compromise: dev convenience + warning)
- ☐ Khác: ___

---

### Q2: Rate limit + IP allowlist

**Current state:** KHÔNG có gì ngoài secret check.

**Trade-off:**
- **Rate limit:** Bảo vệ nếu secret leak (attacker không thể flood). Đơn giản (~30min với existing `express-rate-limit`).
- **IP allowlist:** Production restrict tới IPs của model API + IoT sim + cron servers. Dev local localhost. Cần env config + middleware (~1h).

**Em recommend:**
- **Phase 4 add rate limit** (essential, low effort):
  - 1000 req/min per IP cho internal endpoints (cao hơn admin 60/min vì service spam khả thi)
  - Existing pattern từ logs/dashboard reuse
- **Phase 5+ defer IP allowlist** (production scope):
  - Đồ án 2 deploy single VPS không cần
  - Production K8s/docker cần
  - ADR record approach: `IP allowlist via env IP_ALLOWLIST_INTERNAL=10.0.0.5,10.0.0.6` middleware

**Anh decision:**
- ✅ **Em recommend (rate limit Phase 4, IP allowlist Phase 5+)** ← anh CHỌN
- ☐ Both Phase 4 (~1.5h total)
- ☐ Skip both (chỉ secret đủ cho đồ án 2)
- ☐ Khác: ___

---

### Q3: Audit log cho internal calls

**Current state:** Internal endpoints KHÔNG ghi `audit_logs`.

**Use case:**
- Script/pump emit alert → admin thấy notification → admin investigate "ai gọi endpoint này, từ đâu, khi nào?"
- Currently: chỉ có `console.log`, mất khi process restart.

**Em recommend:**
- **Add audit log per internal call** với schema:
  - `action='internal.emit_alert' / 'internal.emit_emergency' / 'internal.emit_risk'`
  - `user_id=null` (system action)
  - `details={ payload_id, ip_address, user_agent || 'internal' }`
  - `status='success' / 'failure'`
- Reuse `logsService.writeLog()` helper (BR-026-04 swallow error pattern)
- Effort ~30min

**Anh decision:**
- ✅ **Em recommend (add audit log per internal call ~30min)** ← anh CHỌN
- ☐ Skip (internal calls trust scripts đã đủ)
- ☐ Khác: ___

---

### Q4: Request schema validation

**Current state:** Chỉ check `id` field exists trên body. Không validate schema chi tiết.

**Risk:**
- Pump script bug → gửi alert với `severity: 'unknown'` → BE emit ra FE → FE crash render
- Defense-in-depth: validate ở boundary

**Em recommend:**
- **Add `validate()` middleware schema** cho 3 endpoints:
  - emit-alert: `alert: { id, user_id, severity (enum), message, created_at, ... }`
  - emit-emergency: `emergency: { id, type (FALL/SOS), user_id, ... }`
  - emit-risk: `riskScore: { userId, score, riskLevel (enum), calculatedAt }`
- Reuse pattern từ `middlewares/validate.js` đã có
- Effort ~1h

**Anh decision:**
- ✅ **Em recommend (add schema validation ~1h)** ← anh CHỌN
- ☐ Skip (internal calls trust caller, BE proxy passthrough)
- ☐ Khác: ___

---

### Q5: Endpoint scope — model API / IoT sim ingestion pattern

**Current state:** INTERNAL chỉ có **outbound** WebSocket emit endpoints (BE → admin FE). KHÔNG có **inbound** ingestion từ model API hoặc IoT sim.

**Câu hỏi cross-repo:** Hiện tại model API + IoT sim ghi DB như thế nào?
- **Option A:** Direct DB connect (Postgres connection string) → bypass HealthGuard BE → fast nhưng tight coupling
- **Option B:** HTTP POST tới HealthGuard BE public API (`/api/v1/alerts`, `/api/v1/vitals`, etc) với auth admin JWT
- **Option C:** Internal API endpoints `POST /api/v1/internal/ingest/alert` với secret + Validate strict

**Phân tích cần verify:**
- Em chưa đọc code IoT sim + model API DB layer trong session này
- Phase 1 audit Track 4 (model API) + Track 5A (IoT sim) đã review, em cần cross-ref

**Em recommend (preliminary):**
- **Phase 0.5 ratify hiện trạng** (em verify trong Phase 0.5 cho health_system + IoT sim)
- **Defer decision** cho khi audit health_system BE + IoT sim xong (Phase 0.5 next modules)
- **Câu hỏi cho anh tạm thời:** anh có muốn em **ratify whatever pattern hiện tại** hay **proactive enforce Option C** (clean cross-repo contract)?

**Anh decision:** ✅ anh yêu cầu em **verify trước** → em đã verify cross-repo (xem section trên):
- HealthGuard INTERNAL chỉ phục vụ internal pump scripts → **ratify hiện trạng cho HealthGuard**
- Cross-repo ingestion (IoT sim/model API) thực sự diễn ra ở health_system/backend `/mobile/admin/*` → **defer Phase 0.5 health_system audit**
- IoT sim auth pattern (`X-Internal-Service` only, missing `X-Internal-Secret`) → **flag finding cho Phase 0.5**

---

## 🆕 Industry standard add-ons — anh's selection

**Keep (security cross-cutting):**
- ✅ **Sanitize error responses** — `error.message` leak trong 500 response là security finding cross-cutting với D-010. Effort ~30min map sang generic `'Internal service error'` + kèm `requestId` trace trong logs (không leak chi tiết).

**Drop (không cần thiết, tránh scope creep):**
- ❌ Health check endpoint (Phase 5+ K8s deploy)
- ❌ Idempotency-Key header (Phase 5+; current scripts single-fire)
- ❌ API versioning split `/internal/v1/*` (minor, defer)
- ❌ Metrics Prometheus endpoint (Phase 5+ ops)

---

## 🆕 Features anh nghĩ ra

_(anh add nếu có)_

---

## ❌ Features anh muốn DROP

_(anh add nếu có — ví dụ: drop emit-risk nếu không dùng)_

---

## 📊 Drift summary

### UC delta

| UC cũ | Status | UC/ADR mới |
|---|---|---|
| **NONE — orphan module** | Resolved | ADR `<NNN>-internal-service-secret-strategy.md` (cross-repo) + brief section trong `UC027_Admin_Dashboard_v2.md` |

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task | Severity |
|---|---|---|---|
| Internal secret hardcoded fallback (D-010) | Remove fallback (D-INT-01) | `fix(security): require INTERNAL_SECRET env, fail-fast startup` (~30min) + cross-repo coord | 🔴 CRITICAL |
| Rate limit | Add Phase 4 (D-INT-02) | `feat: rate limit internal routes 1000/min` (~30min) | 🟡 Medium |
| IP allowlist | Defer Phase 5+ (D-INT-02) | None Phase 4 | Defer |
| Audit log internal calls | Add (D-INT-03) | `feat: audit log internal emit calls` (~30min) | 🟡 Medium |
| Schema validation | Add (D-INT-04) | `feat: validate() middleware internal endpoints` (~1h) | 🟡 Medium |
| Cross-repo ingestion | Ratify HealthGuard, defer Phase 0.5 health_system (D-INT-05) | None HealthGuard | Defer |
| Sanitize error responses | Add (Add-on) | `fix: sanitize internal route 500 errors` (~30min) | 🔴 Security |

**Estimated Phase 4 effort:** ~3h HealthGuard + cross-repo coord ~1h (ADR + 3 PRs sync)

### Cross-repo flagged for future audit

- **health_system/backend `/mobile/admin/*`** — audit auth pattern (IoT sim chỉ gửi `X-Internal-Service`, không kèm `X-Internal-Secret`). Phase 0.5 health_system.

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-INT-01 | Internal secret fallback | **Remove fallback, fail-fast startup, ADR + cross-repo coord** | CRITICAL security; production deploy quên env = trivial bypass |
| D-INT-02 | Rate limit + IP allowlist | **Rate limit Phase 4, IP allowlist Phase 5+** | Rate limit defense if secret leak; IP allowlist production scope |
| D-INT-03 | Audit log internal calls | **Add per call** | Audit trail cho internal trigger, reuse `writeLog` swallow pattern |
| D-INT-04 | Schema validation | **Add `validate()` middleware** | Defense-in-depth ngay cả cho trusted internal calls |
| D-INT-05 | Cross-repo ingestion | **Ratify HealthGuard hiện trạng + flag health_system Phase 0.5** | Verified: HealthGuard INTERNAL chỉ phục vụ internal pump; cross-repo ingestion thuộc health_system/backend `/mobile/admin/*` |
| D-INT-06 (add-on) | Sanitize error responses | **Add** | Cross-cutting D-010 security; low effort |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Health check `/internal/health` | ❌ Drop (Phase 5+ K8s) |
| Idempotency-Key header | ❌ Drop (Phase 5+) |
| API versioning split | ❌ Drop (minor) |
| **Sanitize error responses** | ✅ **Keep** (security cross-cutting) |
| Metrics Prometheus | ❌ Drop (Phase 5+ ops) |

---

## Cross-references

- INTERNAL routes: `HealthGuard/backend/src/routes/internal.routes.js`
- WebSocket service: `HealthGuard/backend/src/services/websocket.service.js`
- Phase 1 audit: M02 Routes (D-010 finding)
- Cross-repo similar pattern:
  - `healthguard-model-api/app/main.py` (CORS reflection bug — Phase 1 Track 4 M04)
  - `Iot_Simulator_clean/api_server` (partial auth enforcement — Phase 1 Track 5A M03)
- ADR candidate: `<NNN>-internal-service-secret-strategy.md`
- Pending Phase 0.5 decisions:
  - health_system BE: ingestion pattern (next track)
  - IoT sim: how does it talk to BE? (Track 5A intent)
- LOGS D-LOGS-04: writeLog swallow error pattern → reuse cho audit
