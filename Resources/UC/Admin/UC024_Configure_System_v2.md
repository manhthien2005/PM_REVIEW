# UC024 v2 - CẤU HÌNH HỆ THỐNG TOÀN CỤC

> **Phiên bản:** v2 (rebuild Phase 0.5 — 2026-05-12)
> **Thay thế:** UC024 v1 (`UC024_Configure_System.md`)
> **Quyết định nguồn:** `AUDIT_2026/tier1.5/intent_drift/healthguard/CONFIG.md`

## 1. Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC024                                                                                                                                                                                             |
| **Tên UC**         | Cấu hình hệ thống toàn cục (Global System Settings)                                                                                                                                               |
| **Tác nhân chính** | Quản trị viên (Admin)                                                                                                                                                                             |
| **Mô tả**          | Cung cấp cho Admin quyền tinh chỉnh hoạt động cốt lõi của hệ thống, gồm cấu hình AI ngừa false alarm, ngưỡng sinh tồn mặc định, kênh push notification, và bật chế độ bảo trì.                  |
| **Trigger**        | Admin truy cập "Cấu hình hệ thống" trên Admin Dashboard.                                                                                                                                          |
| **Tiền điều kiện** | Admin đã đăng nhập (`role = 'admin'`).                                                                                                                                                            |
| **Hậu điều kiện**  | Cấu hình mới ghi vào DB; cache in-memory được invalidate; audit log ghi nhận chi tiết old/new values; mọi service consume settings tự reload từ cache lần truy cập kế tiếp.                       |

> **Thay đổi v2:** Drop "Super Admin" distinction (D-CFG-01). Đồ án 2 chỉ có 2 role `user`/`admin`. Defense-in-depth qua re-auth password + audit log + per-setting `is_editable` flag.

---

## 2. Các Nhóm Cấu Hình (Configuration Domains)

4 nhóm chính tương ứng `system_settings` table, FE chia thành 4 tab:

### 2.1. AI & Fall Detection
| Setting key | Type | Range | Default | Tooltip Vietnamese |
|---|---|---|---|---|
| `confidence_threshold` | float | 0.50 - 0.99 | 0.85 | Ngưỡng tự tin AI. Tăng nếu AI báo động sai nhiều, giảm nếu AI bỏ lọt sự cố. |
| `auto_sos_countdown_sec` | int | 5 - 60 | 30 | Thời gian đếm ngược trước khi hệ thống tự động gửi SOS. Cho user thời gian bấm CANCEL. |
| `enable_auto_sos` | boolean | true / false | true | Kill-switch toàn hệ thống cho tự động SOS. Tắt khi Call Center quá tải. |

### 2.2. Communication Channels
| Setting key | Type | Default | Tooltip |
|---|---|---|---|
| `push_notification_enabled` | boolean | true | Push notification qua app di động — kênh duy nhất hệ thống dùng để báo cảnh báo. |

> SMS / Voice Call **đã loại bỏ** (xem ADR `XX-notification-channel-strategy.md`). Lý do: tối ưu chi phí + đảm bảo tức thời.

### 2.3. Clinical Defaults (Sinh tồn mặc định)
| Setting key | Type | Range | Default | Tooltip |
|---|---|---|---|---|
| `vitals_default_thresholds.spo2_critical` | int | 0 - 100 | 90 | SpO2 critical (%). User chưa thiết lập sẽ dùng giá trị này. |
| `vitals_default_thresholds.spo2_warning` | int | 0 - 100 | 92 | SpO2 warning (%). Phải >= spo2_critical. |
| `vitals_default_thresholds.hr_critical_min` | int | 30 - 220 | 40 | Nhịp tim critical min (bpm). |
| `vitals_default_thresholds.hr_critical_max` | int | 30 - 220 | 180 | Nhịp tim critical max (bpm). |
| `vitals_default_thresholds.hr_warning_min` | int | 30 - 220 | 50 | Nhịp tim warning min (bpm). Phải >= hr_critical_min. |
| `vitals_default_thresholds.hr_warning_max` | int | 30 - 220 | 120 | Nhịp tim warning max (bpm). Phải <= hr_critical_max. |
| `vitals_default_thresholds.rr_critical_min` | int | 5 - 60 | 8 | Nhịp thở critical min. |
| `vitals_default_thresholds.rr_critical_max` | int | 5 - 60 | 30 | Nhịp thở critical max. |
| `vitals_default_thresholds.bp_sys_critical` | int | 60 - 250 | 180 | Huyết áp tâm thu critical (mmHg). |
| `vitals_default_thresholds.bp_sys_warning` | int | 60 - 250 | 160 | Huyết áp tâm thu warning. Phải <= bp_sys_critical. |
| `vitals_default_thresholds.bp_dia_critical` | int | 30 - 200 | 110 | Huyết áp tâm trương critical. |
| `vitals_default_thresholds.bp_dia_warning` | int | 30 - 200 | 100 | Huyết áp tâm trương warning. Phải <= bp_dia_critical. |
| `vitals_sleep_thresholds.osa_alert_spo2_threshold` | int | 0 - 100 | 88 | Ngưỡng SpO2 cảnh báo OSA (sleep apnea) ban đêm. |
| `vitals_sleep_thresholds.nocturnal_tachy_hr` | int | 40 - 220 | 100 | Ngưỡng HR cảnh báo nhịp nhanh ban đêm. |
| `vitals_sleep_thresholds.apnea_rr_threshold` | int | 0 - 40 | 6 | Ngưỡng nhịp thở cảnh báo apnea. |

### 2.4. Security & Maintenance
| Setting key | Type | Range | Default | Tooltip |
|---|---|---|---|---|
| `maintenance_mode` | boolean | true / false | false | Bật → tất cả user ngoài admin nhận response 503. Admin bypass để test. |
| `session_timeout_minutes` | int | 5 - 1440 | 60 | Thời gian rảnh phiên đăng nhập trước khi logout tự động (phút). Max 24h. |

---

## 3. Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                            |
| ---- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập menu "Cấu hình hệ thống".                                                                                                                                   |
| 2    | Hệ thống        | `GET /api/v1/settings` — query `system_settings` (cache in-memory nếu hit, fallback DB) → render UI form chia 4 tab.                                                 |
| 3    | Admin           | Thay đổi tham số. Hover input field → tooltip giải thích ý nghĩa + range cho phép.                                                                                   |
| 4    | Admin           | Bấm "Lưu Thay Đổi".                                                                                                                                                  |
| 5    | Hệ thống        | **Diff preview modal:** hiển thị side-by-side bảng `[Field] [Giá trị cũ] [Giá trị mới]` highlighted (D-CFG-08).                                                      |
| 6    | Admin           | Review diff → bấm "Tiếp tục" (hoặc "Hủy" → đóng modal, không lưu).                                                                                                   |
| 7    | Hệ thống        | Modal password: "Bạn đang thay đổi cấu hình lõi của hệ thống. Nhập lại mật khẩu để tiếp tục."                                                                        |
| 8    | Admin           | Nhập mật khẩu, bấm "Xác nhận".                                                                                                                                       |
| 9    | Hệ thống        | `PUT /api/v1/settings` body `{ password, settings: { key1: val1, ... } }`. Service: re-auth bcrypt → validate ranges + logic → transaction update + audit log ghi.    |
| 10   | Hệ thống        | Sau commit DB: invalidate cache in-memory key `system_settings`. Service consume settings sẽ DB read lần kế tiếp (cache repopulate).                                 |
| 11   | Hệ thống        | Hiển thị toast "Cập nhật thành công." Reload form từ DB để admin thấy state mới.                                                                                     |

> **Thay đổi v2:**
> - Add bước 5-6 (diff preview modal — D-CFG-08).
> - Bước 10: in-memory cache invalidate (D-CFG-03), thay cho Pub/Sub Redis (defer D-CFG-02).
> - Bỏ "1-2 phút lan tỏa" — cache invalidate ngay lập tức single-instance.

---

## 4. Luồng thay thế (Alternative Flows)

### 4.a Xác nhận mật khẩu sai
| Bước  | Người thực hiện | Hành động                                                                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 9.a.1 | Hệ thống        | `bcrypt.compare` fail. Audit log `action='settings.updated', status='failure', details.reason='invalid_password'`.                     |
| 9.a.2 | Hệ thống        | Response 401 "Mật khẩu xác nhận không đúng".                                                                                           |
| 9.a.3 | Admin           | Modal password đóng. Click "Lưu Thay Đổi" lần nữa kích hoạt lại bước 5 (diff preview).                                                 |

### 4.b Validate logic kinh doanh sai
| Bước  | Người thực hiện | Hành động                                                                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 9.b.1 | Hệ thống        | Validate logic detect: SpO2 > 100, HR Min > Max, hr_warning_min < hr_critical_min, etc. Response 400 với chi tiết field + lý do.       |
| 9.b.2 | Hệ thống        | FE tô đỏ input field lỗi, hiển thị inline error message.                                                                               |
| 9.b.3 | Admin           | Sửa value, bấm "Lưu Thay Đổi" lại.                                                                                                     |

### 4.c Restore defaults (D-CFG-06 — NEW)
| Bước  | Người thực hiện | Hành động                                                                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 4.c.1 | Admin           | Mỗi tab có nút "Khôi phục mặc định" (per-group restore).                                                                               |
| 4.c.2 | Hệ thống        | Confirm modal "Bạn sẽ khôi phục [AI / Clinical / Maintenance / All] về giá trị mặc định. Hành động này không thể hoàn tác."          |
| 4.c.3 | Admin           | Bấm "Tiếp tục" → password modal (giống bước 7).                                                                                        |
| 4.c.4 | Hệ thống        | `POST /api/v1/settings/restore-defaults` body `{ password, group? }`. Service đọc defaults từ `system_settings_defaults` table → update. |
| 4.c.5 | Hệ thống        | Audit log `action='settings.restore_defaults', details.group=<group>`. Cache invalidate. Reload form.                                  |

### 4.d Maintenance mode active (D-CFG-04 — NEW)
| Bước  | Người thực hiện | Hành động                                                                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 4.d.1 | User thường     | Truy cập bất kỳ endpoint không thuộc whitelist (`/auth/login`, `/health`).                                                             |
| 4.d.2 | Hệ thống        | Middleware `maintenanceCheck` đọc `system_settings.maintenance_mode` (cache).                                                          |
| 4.d.3 | Hệ thống        | Nếu `maintenance_mode === true` AND `req.user?.role !== 'admin'` → response 503 `{ message: "Hệ thống đang bảo trì, vui lòng thử lại sau" }`. |
| 4.d.4 | Admin           | Vẫn bypass được — tiếp tục test bình thường.                                                                                           |

---

## 5. Settings History (UI Tab — D-CFG-07 — NEW)

Admin Dashboard config page có tab "Lịch sử thay đổi" (Settings History):

- **Endpoint:** `GET /api/v1/settings/history?limit=50&setting_key=&from=&to=`
- **Backend:** Query `audit_logs` với `action='settings.updated' AND status='success'` (+ optional filters).
- **Response:** List entries `[{ timestamp, admin_id, admin_username, setting_keys: [...], old_values, new_values, ip_address }]`.
- **UI:** Timeline view, click entry → detail modal hiển thị JSON diff old → new.

---

## 6. Business Rules (Quy tắc nghiệp vụ)

- **BR-024-01 (Strict Auth):** Mọi PUT `/settings` + POST `/settings/restore-defaults` đều phải re-authenticate password (bcrypt.compare).
- **BR-024-02 (Auditability):** Mọi thay đổi (success + failure) ghi vào `audit_logs` với `old_values + new_values`. KHÔNG được log password.
- **BR-024-03 (Cache Invalidation):** Sau commit DB transaction, in-memory cache key `system_settings` phải invalidate ngay. Service consume settings DB read kế tiếp → cache repopulate.
- **BR-024-04 (Per-setting Editability):** Mỗi setting có flag `is_editable`. Nếu `false` → reject update (defense-in-depth chống misconfig hardcoded settings).
- **BR-024-05 (Validation Logic):** Service validate range + logic constraints trước khi update. Constraints xem Section 2.3 (vitals).
- **BR-024-06 (Maintenance Bypass):** `maintenance_mode === true` block user thường nhưng admin bypass. Whitelist endpoints luôn accessible: `/auth/login`, `/health`.

> **Thay đổi v2:**
> - BR-024-03 thay Pub/Sub Redis bằng in-memory cache invalidation (D-CFG-02 + D-CFG-03).
> - Add BR-024-04 (per-setting editability) — đã có trong code, formalize trong UC.
> - Add BR-024-05 (validation logic explicit) — code đã có, formalize.
> - Add BR-024-06 (maintenance bypass) — D-CFG-04 NEW.

---

## 7. Yêu cầu phi chức năng (NFR)

- **Performance:** GET `/settings` < 50ms (in-memory cache hit). Cache miss DB read < 100ms acceptable cho lần đầu.
- **Reliability:** PUT `/settings` dùng `prisma.$transaction` — DB lỗi rollback toàn bộ, không invalidate cache.
- **Usability:** Mỗi input field có tooltip Vietnamese (xem Section 2 reference table). FE consume table này để render tooltip + validation hint.
- **Security:** Re-auth password mỗi lần save; audit log mọi action; password KHÔNG log.
- **Auditability:** History view (Section 5) cho phép admin trace mọi change.

---

## 8. Cross-references

- **Code paths:**
  - Routes: `HealthGuard/backend/src/routes/settings.routes.js`
  - Service: `HealthGuard/backend/src/services/settings.service.js`
  - Controller: `HealthGuard/backend/src/controllers/settings.controller.js`
  - Middleware (mới): `HealthGuard/backend/src/middlewares/maintenanceCheck.js` (Phase 4)
  - Cache util (mới): `HealthGuard/backend/src/utils/settingsCache.js` (Phase 4)
- **Schema:** `system_settings` table (canonical: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`)
- **Cross-UC:**
  - UC029 SOS: consume `confidence_threshold`, `auto_sos_countdown_sec`, `enable_auto_sos`
  - UC028 Health monitoring: consume `vitals_default_thresholds`, `vitals_sleep_thresholds`
  - UC011 Notification: consume `push_notification_enabled`
  - UC001 Login: consume `session_timeout_minutes`
- **Phase 4 backlog:** xem `AUDIT_2026/tier1.5/intent_drift/healthguard/CONFIG.md` Drift Summary section.

---

## 9. Out of scope (defer Phase 5+)

- **Pub/Sub Redis cache invalidation** (D-CFG-02): cần thiết khi scale ra worker pool / multi-instance.
- **Setting versioning + rollback** (industry standard): admin chọn revert về snapshot 1 ngày trước.
- **Setting templates** (admin save preset cho dev/staging/prod).
- **Super admin role separation** (D-CFG-01): nếu sau này cần phân quyền tinh hơn.
