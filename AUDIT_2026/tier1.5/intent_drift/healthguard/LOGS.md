# Intent Drift Review — `HealthGuard / LOGS`

**Status:** � Confirmed (anh chọn theo em recommend Q1-Q5; add-ons defer)
**Repo:** `HealthGuard/` (admin web fullstack)
**Module:** LOGS (Audit log viewer for admin)
**Related UCs (old):** UC026 (View System Logs)
**Phase 1 audit ref:** `tier2/healthguard/M02_routes_audit.md`, `M04_services_audit.md`
**Date prepared:** 2026-05-12
**Question count:** 5 (module surface nhỏ, drift moderate)

---

## 🎯 Mục tiêu

Capture intent cho LOGS module. UC026 cũ + audit_logs schema là input.

---

## 📚 UC026 cũ summary

- Actor: Admin
- Main: render default 24h gần nhất → filter time/user/action → click log → detail
- Alt: 2.a empty state, 4.a export CSV/JSON
- BR-026-01 Append-only, BR-026-02 Retention 2 năm, BR-026-03 Sanitize password/token
- NFR: Pagination, view log self-audit ("admin.view_logs"), security admin-only

---

## 🔧 Code state

**Routes (`logs.routes.js`):**

```
authenticate + requireAdmin + rateLimit 100/min — all routes

GET    /api/v1/logs              list (filters: action, status, user_id, resource_type, start_date, end_date, search)
GET    /api/v1/logs/:id          detail with sanitization
GET    /api/v1/logs/export/csv   CSV export (max 10000 records, no details column)
GET    /api/v1/logs/export/json  JSON export (max 10000 records, sanitized details)
```

**Service highlights (`logs.service.js`):**
- ✅ Pagination + filters match UC026 Main Flow
- ✅ Default date range 24h (matches UC bước 2)
- ✅ Sanitize sensitive fields (`password`, `password_hash`, `token`, `access_token`, `refresh_token`) — BR-026-03 ✓
- ✅ Include users + devices relation (enriched view)
- ✅ BigInt → string serialize (Prisma audit_logs id)
- ✅ Append-only via code (no UPDATE/DELETE route) — BR-026-01 partial
- ⚠️ `writeLog` helper swallow error với `console.warn` — không throw (defensive against blocking main ops, nhưng audit miss silently)

**Phase 1 audit findings (relevant):**
- M02 Routes 🟢 clean pattern (auth + admin + rate limit composed)
- M04 Services 🟡 `writeLog` swallow error pattern questionable cho audit compliance

**Missing vs UC026:**
- Self-audit `admin.view_logs` action (NFR Auditability)
- Retention policy 2 năm enforcement (BR-026-02 — no cleanup job)
- DB-level append-only constraint (chỉ code-level, nếu ai bypass qua raw SQL → có thể edit)

---

## 💬 Anh react block

> Em chỉ hỏi câu thực sự cần decide. Industry standard add-ons em flag riêng cuối doc.

---

### Q1: Self-audit `admin.view_logs`?

**UC NFR:** "Chính màn hình xem log cũng nên ghi log lại (VD: `admin.view_logs`)"
**Code:** KHÔNG thấy `logsController.getAll` hoặc `getById` gọi `writeLog`

**Implications:**
- Implement → mỗi GET /logs ghi 1 audit entry → log table tăng nhanh (1 admin xem 100 lần = 100 entry)
- Có thể giới hạn: chỉ log `getById` (xem detail = action có ý nghĩa) thay vì cả `getAll` (browsing không phải intent)
- Hoặc: throttle 1 entry / 5 min / admin (không log spam)

**Em recommend:**
- **Implement chỉ cho `getById` + `export/*`** (3 endpoint có "intent" rõ ràng)
- `getAll` browsing không log để tránh noise
- Action names: `admin.view_log_detail`, `admin.export_logs_csv`, `admin.export_logs_json`

**Anh decision:**
- ✅ **Em recommend (log getById + exports, skip getAll)** ← anh CHỌN
- ☐ Log tất cả (cả getAll, accept noise)
- ☐ Skip toàn bộ (UC NFR drop)
- ☐ Khác: ___

---

### Q2: Retention policy 2 năm (BR-026-02)

**UC BR-026-02:** "Dữ liệu log lưu tối thiểu 2 năm"
**Code:** KHÔNG có cleanup job, không có DB partition

**Implications:**
- Đồ án 2 demo: data < vài trăm entries, không impact.
- Production scale: log table tăng vô hạn → query chậm sau 6-12 tháng.
- 2 năm retention nghĩa là KHÔNG xóa trong 2 năm. Sau 2 năm: có thể xóa, cảnh lưu trữ archive, hoặc giữ vô hạn.

**Em recommend:**
- **Defer Phase 5+** cho đồ án 2. Chỉ document policy intent trong UC026 v2.
- Phase 5+: thêm cron job `cleanupOldLogs` (xóa logs > 2 năm) + DB partition theo tháng.
- ADR record decision (defer + lý do).

**Anh decision:**
- ✅ **Em recommend (defer Phase 5+, document only)** ← anh CHỌN
- ☐ Implement now (cron job ~2h)
- ☐ Drop policy (giữ vô hạn forever)
- ☐ Khác: ___

---

### Q3: Append-only DB-level constraint (BR-026-01)

**UC BR-026-01:** "Không được chỉnh sửa sau khi ghi"
**Code:** Chỉ enforce qua absence của UPDATE/DELETE route. Prisma client có thể `prisma.audit_logs.update()` từ bất kỳ service nào.

**Implications:**
- Code discipline đủ cho đồ án 2 (chỉ logs.service.js touch audit_logs ngoài writeLog).
- Production: Postgres trigger `BEFORE UPDATE` raise exception, hoặc revoke UPDATE/DELETE permission cho `prisma_user` (chỉ allow INSERT + SELECT).
- ADR document trade-off.

**Em recommend:**
- **Defer trigger Phase 5+**, document trong UC026 v2 + ADR.
- Phase 4 thêm comment top of `audit_logs` Prisma model: `/// APPEND-ONLY — không gọi update/delete trừ logs.service`
- Add lint rule hoặc grep CI check: `prisma.audit_logs.(update|delete)` outside `logs.service.js` → fail.

**Anh decision:**
- ✅ **Em recommend (defer trigger, add CI grep check ~30min)** ← anh CHỌN
- ☐ Implement Postgres trigger now (~1h SQL + migration)
- ☐ Skip (trust code discipline)
- ☐ Khác: ___

---

### Q4: `writeLog` swallow error (current code behavior)

**Code:**
```js
async writeLog({...}) {
  try {
    return await prisma.audit_logs.create({...});
  } catch (err) {
    console.warn(`[WARN] Audit log write failed:`, err.message);
    return null;  // KHÔNG throw
  }
}
```

**Trade-off:**
- ✅ Pro: Audit failure không block main operation (vd user login thành công, audit ghi fail → user vẫn login OK)
- ❌ Con: Audit silently miss → security/compliance gap (BR-026-01 audit obligation)

**Em recommend:**
- **Keep swallow + add alerting**:
  - Keep `try-catch` không throw (preserve UX)
  - Thay `console.warn` bằng structured log (logger.error với metadata) → để monitoring (Sentry/CloudWatch) catch
  - Phase 5+: thêm metric `audit_log_write_failures_total` để alert ops

**Anh decision:**
- ✅ **Em recommend (keep swallow + add structured logger)** ← anh CHỌN
- ☐ Throw error (fail-safe: main op rollback nếu audit fail)
- ☐ Keep as-is (đồ án 2 không cần monitoring)
- ☐ Khác: ___

---

### Q5: Export max 10000 hardcoded

**Code:** `findAll({ ...filters, limit: 10000 })` cho cả CSV + JSON export
**UC:** Không spec limit

**Trade-off:**
- 10000 records JSON ~5-10 MB → acceptable cho download
- > 10000 records: silently truncated, admin không biết
- Streaming approach: Node.js stream CSV/JSON, không cap → memory-friendly

**Em recommend:**
- **Phase 4: Keep 10000 cap + WARN response header `X-Export-Truncated: true`** nếu hit cap
- FE hiển thị warning "Kết quả bị giới hạn 10000 bản ghi. Vui lòng thu hẹp khoảng thời gian."
- Phase 5+: streaming export cho large datasets

**Anh decision:**
- ✅ **Em recommend (keep 10000 + warning header)** ← anh CHỌN
- ☐ Increase cap (vd 50000)
- ☐ Streaming Phase 4 (heavy: ~4h refactor)
- ☐ Remove cap (memory risk)
- ☐ Khác: ___

---

## 🆕 Industry standard add-ons (em flag, anh quick scan — KHÔNG ép vào Q)

Anh tick nếu muốn thêm vào UC v2 + Phase 4 backlog:

- ☐ **Saved filter presets** — admin save common queries ("All failures last 7d", "User X login attempts")
- ☐ **Log severity highlighting** — UI tô màu theo `status` (success xanh, failure đỏ, pending vàng)
- ☐ **Bulk log purge** — admin nút "Clear logs older than X" (sau retention period, dangerous nên password re-auth)
- ☐ **Alert rules** — admin define rule "Báo cho tôi nếu có > 5 failed logins trong 1 giờ" (Phase 5+ scope)
- ☐ **Search across details JSON** — full-text search trong details object (Postgres `jsonb_path_ops` index)

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
| UC026 View System Logs | Moderate updates | `UC026_View_System_Logs_v2.md` |

Key changes UC v2:
- Add NFR Auditability clarify scope: self-audit chỉ `getById` + `export/*` (skip `getAll` browsing)
- BR-026-02 retention policy: state intent 2 năm, enforcement Phase 5+ note
- BR-026-01 append-only: code-level + CI grep check (formalize), DB trigger Phase 5+ note
- Add BR-026-04 writeLog error handling: keep swallow, route qua structured logger
- Add Main Flow note: export response header `X-Export-Truncated` khi hit cap 10000
- Section out-of-scope: streaming export, full-text search jsonb, alert rules

### Code impact (Phase 4 backlog adds)

| Phase 1 finding | Decision | Phase 4 task |
|---|---|---|
| Self-audit missing | Implement getById + exports (D-LOGS-01) | `feat: self-audit logsController` (~1h) |
| Retention not enforced | Defer (D-LOGS-02) | None Phase 4; document intent UC v2 |
| Append-only DB-level | Defer trigger, add CI grep (D-LOGS-03) | `chore: CI grep check audit_logs mutations` (~30min) |
| writeLog swallow error | Keep + structured logger (D-LOGS-04) | `refactor: writeLog use logger.error instead console.warn` (~1h) |
| Export 10000 cap | Keep + warning header (D-LOGS-05) | `feat: X-Export-Truncated header` (~30min) |

**Estimated Phase 4 effort:** ~3h total

---

## 📝 Anh's decisions log

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-LOGS-01 | Self-audit view logs | **Implement getById + exports only** | Tránh noise từ browsing; intent rõ ràng ở detail + export |
| D-LOGS-02 | Retention 2 năm enforcement | **Defer Phase 5+** | Đồ án 2 demo data < vài trăm entries; document intent UC v2 |
| D-LOGS-03 | Append-only DB-level | **Defer trigger, add CI grep** | Code discipline đủ đồ án 2; CI grep bảo vệ regression |
| D-LOGS-04 | writeLog swallow error | **Keep swallow + structured logger** | Pro: không block main op; Con mitigate qua monitoring |
| D-LOGS-05 | Export max 10000 cap | **Keep + X-Export-Truncated header** | Memory safe; user transparency via header |

### Add-ons anh chọn

Không tick add-on nào → defer tất cả:
- Saved filter presets ❌ defer
- Log severity highlighting ❌ defer (FE design đơn giản có thể tự làm)
- Bulk log purge ❌ defer
- Alert rules ❌ defer Phase 5+
- Search across details JSON ❌ defer

---

## Cross-references

- UC026 cũ: `Resources/UC/Admin/UC026_View_System_Logs.md`
- Phase 1 audit: M02 Routes, M04 Services
- Audit_Log_Specification: `PM_REVIEW/Audit_Log_Specification.md`
- Schema: `audit_logs` table (canonical SQL)
