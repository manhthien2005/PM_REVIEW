# UC026 v2 - XEM NHẬT KÝ HỆ THỐNG

> **Phiên bản:** v2 (rebuild Phase 0.5 — 2026-05-12)
> **Thay thế:** UC026 v1 (`UC026_View_System_Logs.md`)
> **Quyết định nguồn:** `AUDIT_2026/tier1.5/intent_drift/healthguard/LOGS.md`

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC026 |
| **Tên UC** | Xem nhật ký hệ thống (View System Audit Logs) |
| **Tác nhân chính** | Quản trị viên (Admin) |
| **Mô tả** | Admin xem nhật ký hoạt động hệ thống (audit logs) để kiểm tra bảo mật, điều tra sự cố hoặc compliance audit. Hỗ trợ filter, search, paginate, export CSV/JSON. |
| **Trigger** | Admin truy cập mục "Nhật ký hệ thống" trên Admin Dashboard. |
| **Tiền điều kiện** | Admin đã đăng nhập (`role = 'admin'`). |
| **Hậu điều kiện** | Admin xem được danh sách log với filter, có thể xem chi tiết 1 log, hoặc export ra file. Mỗi lần xem chi tiết hoặc export đều ghi self-audit entry. |

---

## 1. Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Admin | Mở màn "Nhật ký hệ thống". |
| 2 | Hệ thống | `GET /api/v1/logs` với default range 24h gần nhất, page=1, limit=20. Render bảng với cột: Thời gian, User, Hành động, Resource, Status (success/failure/pending), IP. |
| 3 | Admin | (Optional) Dùng filter: thời gian (start_date / end_date), user_id, action (substring match), resource_type, status (success/failure/pending), search (OR query action + resource_type + error_message). |
| 4 | Hệ thống | Re-query với filters mới, render results paginated. |
| 5 | Admin | Click vào 1 row → xem chi tiết. |
| 6 | Hệ thống | `GET /api/v1/logs/:id` → trả full log + sanitize sensitive fields (BR-026-03). **Self-audit:** ghi audit entry `action='admin.view_log_detail'`. |
| 7 | Hệ thống | Hiển thị modal/page chi tiết với `details` JSON format đẹp (old/new values, IP, user agent). |

---

## 2. Luồng thay thế (Alternative Flows)

### 2.a Không có log trong khoảng thời gian
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Response `{ data: [], total: 0 }`. |
| 2.a.2 | FE | Hiển thị empty state "Không có sự kiện nào trong khoảng thời gian đã chọn". |

### 2.b Export logs ra CSV/JSON
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.b.1 | Admin | Click "Xuất CSV" hoặc "Xuất JSON". |
| 2.b.2 | Hệ thống | `GET /api/v1/logs/export/csv` hoặc `/export/json` với current filters. **Cap: max 10000 records**. |
| 2.b.3 | Hệ thống | Nếu kết quả hit cap 10000 → response header `X-Export-Truncated: true`. **Self-audit:** ghi `action='admin.export_logs_csv'` hoặc `action='admin.export_logs_json'`. |
| 2.b.4 | FE | Trigger download file. Nếu header `X-Export-Truncated: true` → toast warning "Kết quả bị giới hạn 10000 bản ghi. Vui lòng thu hẹp khoảng thời gian." |

---

## 3. Business Rules

- **BR-026-01 (Append-only):** Audit logs không được UPDATE/DELETE sau khi tạo. Enforce:
  - **Code-level (Phase 4):** Chỉ `logs.service.js#writeLog` có quyền `prisma.audit_logs.create`. Các service khác gọi qua helper này.
  - **CI grep check (Phase 4):** Lint rule fail nếu phát hiện `prisma.audit_logs.(update|delete|deleteMany|updateMany)` ngoài `logs.service.js`.
  - **DB-level (Phase 5+):** Postgres trigger `BEFORE UPDATE OR DELETE ON audit_logs` raise exception. (Defer cho production scale.)

- **BR-026-02 (Retention):** Audit logs lưu **tối thiểu 2 năm** trước khi cho phép archive/delete.
  - **Phase 4:** Document intent only, no enforcement (đồ án 2 data nhỏ).
  - **Phase 5+:** Cron job `cleanupOldLogs` xóa logs > 2 năm + DB partition theo tháng cho query performance.

- **BR-026-03 (Sensitive Fields Sanitization):** Trước khi trả response detail / export JSON, sanitize keys khỏi `details`:
  - `password`, `password_hash`
  - `token`, `access_token`, `refresh_token`
  - (Có thể mở rộng: `api_key`, `secret`, `private_key` nếu cần)
  - CSV export: chỉ include columns explicit (ID, Time, User, Action, Resource Type, Resource ID, Status, IP) — KHÔNG include `details` column → safe by design.

- **BR-026-04 (Write-Failure Resilience):** `logs.service.js#writeLog` swallow exception (không throw) để audit failure KHÔNG block main operation. Trade-off mitigate bằng:
  - Log failure qua structured logger (`logger.error` với metadata) thay vì `console.warn`.
  - Phase 5+: metric `audit_log_write_failures_total` để alert ops khi spike.

---

## 4. Yêu cầu phi chức năng (NFR)

- **Security:**
  - Tất cả endpoints `authenticate + requireAdmin` (admin only).
  - Rate limit 100 req/min để chống abuse / scraping.
  - Sanitize sensitive fields per BR-026-03.

- **Performance:**
  - Pagination default `limit=20`, max `limit=100` (FE force).
  - Default date range 24h để tránh full-table scan.
  - Index trên `audit_logs.time DESC`, `audit_logs.action`, `audit_logs.user_id` (verify Prisma schema Phase 4).

- **Auditability (self-audit):**
  - `GET /api/v1/logs/:id` → ghi audit `action='admin.view_log_detail'`, `resource_type='audit_log'`, `resource_id=<log_id viewed>`.
  - `GET /api/v1/logs/export/csv` → ghi audit `action='admin.export_logs_csv'`, `details={filters: {...}, count: <result count>}`.
  - `GET /api/v1/logs/export/json` → ghi audit `action='admin.export_logs_json'`, `details={filters: {...}, count: <result count>}`.
  - `GET /api/v1/logs` (browsing list): **KHÔNG self-audit** (tránh noise, không có intent rõ ràng).

- **Usability:**
  - FE hỗ trợ saved date presets ("Today", "Last 7 days", "Last 30 days", "Custom").
  - Export truncated warning hiển thị toast nếu hit cap.

---

## 5. Cross-references

- **Code paths:**
  - Routes: `HealthGuard/backend/src/routes/logs.routes.js`
  - Controller: `HealthGuard/backend/src/controllers/logs.controller.js`
  - Service: `HealthGuard/backend/src/services/logs.service.js`
- **Schema:** `audit_logs` table (canonical: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`)
- **Helper used by other services:** `logsService.writeLog({...})` — mọi service ghi audit phải gọi helper này, không trực tiếp `prisma.audit_logs.create`.
- **Cross-UC:**
  - UC024 Configure System: ghi audit `settings.updated`, `settings.restore_defaults`
  - UC022 Manage Users: ghi audit `users.created`, `users.updated`, `users.deleted`
  - UC025 Manage Devices: ghi audit `devices.assigned`, `devices.revoked`, etc.
  - UC001 Login: ghi audit `auth.login`, `auth.login_failed`
  - UC009 Logout: ghi audit `auth.logout`
- **Specification:** `PM_REVIEW/Audit_Log_Specification.md` (canonical action names, schema)

---

## 6. Out of scope (defer Phase 5+)

- **Postgres trigger DB-level append-only** (D-LOGS-03): cần khi nhiều service direct access DB ngoài Prisma.
- **Cron job retention cleanup** (D-LOGS-02): cần khi log table > 1M rows hoặc 6+ tháng data.
- **DB partition** `audit_logs` theo tháng: query performance optimization.
- **Streaming export** cho > 10000 records: refactor controllers dùng Node.js stream.
- **Audit log alert rules** (admin define "Alert me when X failures in Y minutes"): Phase 5+ ops monitoring scope.
- **Full-text search trong `details` JSON:** Postgres `jsonb_path_ops` index + advanced query DSL.
- **Saved filter presets** (admin save common queries): UX enhancement.
- **Bulk log purge** sau retention period: dangerous action, cần password re-auth + audit.
- **Log severity color highlighting:** FE design enhancement (không impact BE).

---

## 7. Decisions log reference

Xem `AUDIT_2026/tier1.5/intent_drift/healthguard/LOGS.md` Section "Anh's decisions log" cho rationale của:
- D-LOGS-01: Self-audit scope
- D-LOGS-02: Retention defer
- D-LOGS-03: Append-only enforcement strategy
- D-LOGS-04: writeLog error handling
- D-LOGS-05: Export cap policy
