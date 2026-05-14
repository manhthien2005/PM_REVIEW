# UC025 - QUẢN LÝ THIẾT BỊ IOT (v2 — confirmed Phase 0.5)

> **Version:** v2 (Phase 0.5 wave HealthGuard, 2026-05-12)
> **Supersedes:** `UC025_Manage_Devices.md` (v1)
> **Status:** 🟢 Confirmed (anh react 2026-05-12)

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|---|---|
| **Mã UC** | UC025 |
| **Tên UC** | Quản lý thiết bị IoT |
| **Tác nhân chính** | Quản trị viên |
| **Mô tả** | Admin quản lý IoT devices: list, view detail (enriched), assign/unassign user, lock/unlock với push+email notify, bulk operations, transfer history. **Scope:** Admin only. User pair thiết bị riêng tại UC040. |
| **Trigger** | Admin truy cập "Quản lý thiết bị" trên Admin Dashboard |
| **Tiền điều kiện** | Đã đăng nhập với role `ADMIN` |
| **Hậu điều kiện** | Danh sách devices cập nhật, user nhận push/email notify khi device bị lock, mọi action ghi audit log |

---

## Luồng chính (Main Flow) - Xem danh sách thiết bị

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 1 | Admin | Truy cập "Quản lý thiết bị" |
| 2 | Hệ thống | Hiển thị table với:<br>- Checkbox (bulk select)<br>- Tên, Loại, Owner email, Status (active/locked/unassigned/deleted)<br>- Battery %, Last seen (với badge "Offline" red nếu > 1h)<br>- Action buttons (Assign/Lock/Detail) |
| 3 | Hệ thống | Pagination 20/page |
| 4 | Hệ thống | Search bar + filter panel + sort options |

---

## Luồng thay thế (Alternative Flows)

### 4.a - Gán thiết bị cho user

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.a.1 | Admin | Chọn device chưa có chủ → click "Gán cho user" |
| 4.a.2 | Hệ thống | Hiển thị user picker với search email/code |
| 4.a.3 | Admin | Chọn user + xác nhận |
| 4.a.4 | Hệ thống | `PATCH /devices/:id/assign` body `{ userId }` |
| 4.a.5 | Hệ thống | Update `devices.user_id`, ghi audit log `action='device.assign'` với before_user_id + after_user_id |
| 4.a.6 | Hệ thống | "Đã gán thành công" |

### 4.b - Khóa/Mở khóa thiết bị

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.b.1 | Admin | Click "Khóa" hoặc "Mở khóa" trên device |
| 4.b.2 | Hệ thống | Popup xác nhận |
| 4.b.3 | Admin | Xác nhận |
| 4.b.4 | Hệ thống | `PATCH /devices/:id/lock` toggle `is_active` |
| 4.b.5 | Hệ thống | **Notify user (NEW Phase 0.5):**<br>- Nếu device.user_id NOT NULL + user có FCM token → gửi FCM push<br>- Fallback email nếu không có FCM<br>- Template: "Thiết bị [name] đã bị [khóa/mở khóa] bởi quản trị viên." |
| 4.b.6 | Hệ thống | Ghi audit log `action='device.lock'` hoặc `device.unlock` |
| 4.b.7 | Hệ thống | "Đã [khóa/mở khóa] thiết bị" |

### 4.c - Xem chi tiết thiết bị (enriched, NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.c.1 | Admin | Click vào device trong table |
| 4.c.2 | Hệ thống | `GET /devices/:id?include=owner,activity,transfers,alerts` |
| 4.c.3 | Hệ thống | Hiển thị detail page với **FE grouping (gom nhóm) — anh's design guideline:**<br>**Group A - Device Settings:**<br>- device_name, type, model, firmware, MAC, serial, calibration_data, status<br>**Group B - Owner Info** (nếu assigned):<br>- User name, email, phone, last login<br>**Group C - Activity:**<br>- last_seen_at (với color-code offline)<br>- Battery history graph (last 30 days)<br>- Last 10 vitals submission timeline<br>**Group D - Transfer History:**<br>- Audit log assign/unassign events<br>**Group E - Active Alerts** (nếu có) |
| 4.c.4 | Admin | Click vào tab/section để xem chi tiết từng nhóm (collapsible UI) |

### 4.d - Thêm thiết bị thủ công (Admin nhập kho)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.d.1 | Admin | Click "Thêm thiết bị mới" |
| 4.d.2 | Hệ thống | Form: device_name, device_type, model, firmware_version, mac_address, serial_number |
| 4.d.3 | Admin | Điền thông tin + Lưu (không cần chọn user) |
| 4.d.4 | Hệ thống | Validate (mac_address + serial_number unique) |
| 4.d.5 | Hệ thống | Insert với `user_id = NULL` (status `unassigned`) |
| 4.d.6 | Hệ thống | Ghi audit log `action='device.create'` |

### 4.e - Import thiết bị hàng loạt (DEFER Phase 5+)

> **Status:** Defer Phase 5+ (D-DEV-01)
> **Lý do:** Đồ án 2 scope manual đủ. MVP không implement.
> **Spec dự kiến cho Phase 5+:**
> - Endpoint `POST /devices/import` với multipart/form-data
> - Parse CSV/Excel, validate row (unique MAC/Serial), batch insert
> - Trả về report row errors

### 4.f - Bỏ gán thiết bị (NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.f.1 | Admin | Click "Bỏ gán" trong device detail hoặc list action |
| 4.f.2 | Hệ thống | Popup xác nhận "Bỏ gán thiết bị khỏi [user name]?" |
| 4.f.3 | Admin | Xác nhận |
| 4.f.4 | Hệ thống | `PATCH /devices/:id/unassign` set `user_id = NULL` |
| 4.f.5 | Hệ thống | Ghi audit log `action='device.unassign'` với before_user_id |
| 4.f.6 | Hệ thống | (Optional) Notify previous owner via push/email |
| 4.f.7 | Hệ thống | "Đã bỏ gán thành công" |

### 4.g - Bulk Lock/Unlock + Unassign (NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.g.1 | Admin | Chọn nhiều devices qua checkbox |
| 4.g.2 | Admin | Click action bar "Bulk Lock", "Bulk Unlock", hoặc "Bulk Unassign" |
| 4.g.3 | Hệ thống | Popup xác nhận với số lượng selected |
| 4.g.4 | Admin | Xác nhận |
| 4.g.5 | Hệ thống | Endpoint:<br>- `PATCH /devices/bulk-lock` body `{ device_ids: [], lock: true/false }`<br>- `PATCH /devices/bulk-unassign` body `{ device_ids: [] }` |
| 4.g.6 | Hệ thống | Loop devices, apply action + send notify (nếu lock) + audit log từng device |
| 4.g.7 | Hệ thống | Summary "Đã [khóa/mở khóa/bỏ gán] N devices" |

> **Note:** Bulk delete KHÔNG support — force individual confirm cho safety.

### 4.h - Xem Transfer History (NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 4.h.1 | Admin | Trong device detail page → tab "Transfer History" (Group D) |
| 4.h.2 | Hệ thống | `GET /devices/:id/history?limit=20` |
| 4.h.3 | Hệ thống | Query `audit_logs` với `entity_type='device' AND entity_id=:id AND action IN ('device.assign', 'device.unassign')` |
| 4.h.4 | Hệ thống | Hiển thị timeline: `[date] [admin_name] [action] [before_user → after_user]` |

### 4.i - Search + Filter expanded (UPDATED Phase 0.5)

| Action | Spec |
|---|---|
| **Search** | LIKE %query% trên `device_name`, `serial_number`, `mac_address`, `owner_email` (sanitize input) |
| **Filter Status** | active / locked / unassigned / deleted / all |
| **Filter Type** | Device type dropdown (TBD list — smartwatch/sensor/etc) |
| **Filter Battery** | all / < 20% (low) / < 50% (med) / > 50% (high) |
| **Filter Last seen** | all / < 1h / < 1 day / > 1 week (offline detection) |
| **Sort** | last_seen_at DESC (default) / created_at / battery_level |
| **Pagination** | 20/page |

---

## Business Rules

- **BR-025-01**: 1 device chỉ assign cho tối đa 1 user tại 1 thời điểm. Khi mới tạo: `user_id = NULL` (status `unassigned`).
- **BR-025-02**: KHÔNG hard delete nếu device đã từng phát sinh data trong `vitals`/`motion_data`. Chỉ soft delete (`deleted_at`) hoặc set `is_active=false`.
- **BR-025-03**: Audit log mọi action (`device.create`, `device.update`, `device.assign`, `device.unassign`, `device.lock`, `device.unlock`, `device.delete`, `device.bulk_*`)
- **BR-025-04** (NEW Phase 0.5): REST convention — chỉ `PATCH` cho update partial, `DELETE` cho remove. KHÔNG có PUT duplicate routes.
- **BR-025-05** (NEW Phase 0.5): Khi lock device → notify owner (push primary, email fallback). Khi unlock → tương tự.
- **BR-025-06** (NEW Phase 0.5): Search input phải sanitize (chống injection). Filter `Last seen > 1h` được dùng cho offline detection (badge UI).

---

## API Endpoints (REST clean — Phase 0.5)

```
GET    /api/v1/devices                       list (search + filter + sort + paginate)
GET    /api/v1/devices/:id                   detail basic
GET    /api/v1/devices/:id?include=...       detail enriched (owner, activity, transfers, alerts)
GET    /api/v1/devices/:id/history           transfer history (audit logs)
POST   /api/v1/devices                       create manual (Alt 4.d)
PATCH  /api/v1/devices/:id                   update partial
PATCH  /api/v1/devices/:id/assign            assign user
PATCH  /api/v1/devices/:id/unassign          unassign user (Alt 4.f)
PATCH  /api/v1/devices/:id/lock              toggle lock + notify user
PATCH  /api/v1/devices/bulk-lock             bulk lock/unlock (NEW)
PATCH  /api/v1/devices/bulk-unassign         bulk unassign (NEW)
DELETE /api/v1/devices/:id                   soft delete
```

**Dropped (Phase 0.5):**
- ~~`PUT /api/v1/devices/:id`~~ (duplicate of PATCH)
- ~~`PUT /api/v1/devices/:id/assign`~~
- ~~`PUT /api/v1/devices/:id/unassign`~~
- ~~`PUT /api/v1/devices/:id/lock`~~

**Deferred (Phase 5+):**
- `POST /api/v1/devices/import` (Alt 4.e CSV/Excel import)

---

## Yêu cầu phi chức năng

- **Security**:
  - Chỉ ADMIN truy cập (middleware `authenticate + requireAdmin`)
  - Audit log đầy đủ với before/after value cho sensitive operations
  - Search input sanitize chống injection
- **Performance**:
  - List load < 2s với 10,000 devices (pagination + index trên `deleted_at`, `last_seen_at`, `user_id`)
  - Search < 500ms (index trên `device_name`, `serial_number`, `mac_address`)
- **Notification**:
  - Push notify priority, email fallback (async send không block API)
- **Usability — FE design guideline (anh's Q6 add):**
  - DeviceDetail page **gom nhóm rõ ràng**:
    - Group A: Device settings (config)
    - Group B: Owner info
    - Group C: Activity (last seen, battery, vitals timeline)
    - Group D: Transfer history
    - Group E: Active alerts
  - UI implementation: collapsible sections hoặc tabs
  - Mục đích: admin scan nhanh từng nhóm thông tin mà không bị overwhelm
- **Offline detection MVP**:
  - Badge "Offline" (red) trong list nếu `last_seen_at < NOW() - 1h`
  - Detail view color-code last_seen timestamp
  - KHÔNG cron job, dashboard widget (defer Phase 5+)

---

## Phase 0.5 Decisions Log

| Decision ID | Detail | Date |
|---|---|---|
| D-DEV-01 | Import CSV/Excel: defer Phase 5+ | 2026-05-12 |
| D-DEV-02 | Drop PUT duplicate routes (REST clean) | 2026-05-12 |
| D-DEV-03 | UC v2 add Alt 4.f unassign explicit | 2026-05-12 |
| D-DEV-04 | Bulk lock + unassign (NOT bulk delete) | 2026-05-12 |
| D-DEV-05 | Push + email fallback notify on lock | 2026-05-12 |
| D-DEV-06 | Enriched detail + FE grouping (anh's design guideline) | 2026-05-12 |
| D-DEV-07 | Search/filter expanded | 2026-05-12 |
| D-DEV-08 | Transfer history endpoint + FE tab | 2026-05-12 |
| D-DEV-09 | Offline detection MVP badge only | 2026-05-12 |

---

## Implementation Reference (Admin BE)

- Routes: `device.routes.js`
- Controller: `device.controller.js`
- Service: `device.service.js`
- Notification: `email.js` + FCM integration (UC031 cross-ref)
- FE: `DeviceList`, `DeviceDetail` (with grouping refactor cho Phase 4)
- Tests: `__tests__/controllers/device.controller.test.js`, `__tests__/services/device.service.test.js`
