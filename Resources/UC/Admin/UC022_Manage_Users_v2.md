# UC022 - QUẢN LÝ NGƯỜI DÙNG (v2 — confirmed Phase 0.5)

> **Version:** v2 (Phase 0.5 wave HealthGuard, 2026-05-12)
> **Supersedes:** `UC022_Manage_Users.md` (v1)
> **Status:** 🟢 Confirmed (anh react 2026-05-12)

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|---|---|
| **Mã UC** | UC022 |
| **Tên UC** | Quản lý người dùng |
| **Tác nhân chính** | Quản trị viên |
| **Mô tả** | Admin quản lý danh sách users: xem, thêm, sửa, khóa/mở khóa, xóa, role management, linked profiles. Hỗ trợ bulk operations. |
| **Trigger** | Admin truy cập "Quản lý người dùng" trên Admin Dashboard |
| **Tiền điều kiện** | Đã đăng nhập với role `ADMIN` |
| **Hậu điều kiện** | Danh sách users cập nhật, mọi thay đổi được audit log với before/after value |

---

## Luồng chính (Main Flow) - Xem danh sách

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 1 | Admin | Truy cập "Quản lý người dùng" |
| 2 | Hệ thống | Middleware: authenticate + requireAdmin |
| 3 | Hệ thống | Hiển thị bảng users với:<br>- Checkbox (bulk select)<br>- ID, Họ tên, Email, Phone<br>- Role (user/admin)<br>- Status (Active/Locked/Deleted)<br>- Ngày đăng ký, Last login<br>- Nút Sửa/Khóa/Xóa |
| 4 | Hệ thống | Pagination 20 users/page |
| 5 | Hệ thống | Search bar + filter panel + sort options |

---

## Luồng thay thế (Alternative Flows)

### 5.a - Thêm người dùng mới

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.a.1 | Admin | Click "Thêm người dùng" |
| 5.a.2 | Hệ thống | Hiển thị form: Email, Password, Họ tên, Phone, Role (user/admin), Gender, DOB, Blood type, Height, Weight |
| 5.a.3 | Admin | Nhập thông tin + Submit |
| 5.a.4 | Hệ thống | Validate (email format, password ≥ 8 chars, unique email) |
| 5.a.5 | Hệ thống | Hash password (bcrypt), insert user, ghi audit log `action='user.create'` |
| 5.a.6 | Hệ thống | "Thêm thành công", reload danh sách |

### 5.b - Sửa thông tin người dùng

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.b.1 | Admin | Click "Sửa" tại hàng user |
| 5.b.2 | Hệ thống | Hiển thị form (KHÔNG cho sửa email) |
| 5.b.3 | Admin | Chỉnh sửa (full_name, phone, role, gender, DOB, blood, height, weight) |
| 5.b.4 | Hệ thống | Validate input + check `req.user.id !== params.id` cho role update (no self-promote) |
| 5.b.5 | Hệ thống | Update DB, ghi audit log với before/after value (đặc biệt role change) |
| 5.b.6 | Hệ thống | "Cập nhật thành công" |

### 5.c - Khóa/Mở khóa tài khoản

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.c.1 | Admin | Click "Khóa" hoặc "Mở khóa" |
| 5.c.2 | Hệ thống | Popup xác nhận |
| 5.c.3 | Admin | Xác nhận |
| 5.c.4 | Hệ thống | Update `is_active` hoặc `locked_until` |
| 5.c.5 | Hệ thống | **Gửi email thông báo cho user** (NEW Phase 0.5):<br>- Lock: "Tài khoản của bạn đã bị khóa bởi quản trị viên"<br>- Unlock: "Tài khoản đã được mở khóa, bạn có thể đăng nhập lại" |
| 5.c.6 | Hệ thống | Ghi audit log `action='user.lock'` hoặc `user.unlock` |
| 5.c.7 | Hệ thống | "Đã khóa/mở khóa tài khoản" |

### 5.d - Xóa người dùng

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.d.1 | Admin | Click "Xóa" |
| 5.d.2 | Hệ thống | Popup "⚠️ Xóa người dùng? Dữ liệu sẽ được giữ lại (soft delete)" |
| 5.d.3 | Admin | Nhập mật khẩu admin để xác nhận |
| 5.d.4 | Hệ thống | Verify admin password (bcrypt compare) |
| 5.d.5 | Hệ thống | Soft delete (set `deleted_at = NOW()`) |
| 5.d.6 | Hệ thống | Ghi audit log `action='user.delete'` |
| 5.d.7 | Hệ thống | "Đã xóa người dùng" |

> **Note (Phase 0.5):** Đã DROP requirement "Archive vào backup table" — soft delete `deleted_at` đủ để restore.

### 5.e - Tìm kiếm và lọc (expanded Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.e.1 | Admin | Nhập search query hoặc chọn filter |
| 5.e.2 | Hệ thống | **Search**: LIKE %query% trên các field `full_name`, `email`, `phone` (sanitize input) |
| 5.e.3 | Hệ thống | **Filter**:<br>- Role: user / admin / all<br>- Status: active / locked / deleted / all<br>- Date of birth range (from / to) |
| 5.e.4 | Hệ thống | **Sort**: created_at DESC (default), toggle by name / email / last_login |
| 5.e.5 | Hệ thống | Hiển thị kết quả với pagination 20/page |

### 5.f - Quản lý quan hệ Theo dõi sức khỏe (Linked Profiles)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.f.1 | Admin | Click vào user → tab "Quan hệ theo dõi" |
| 5.f.2 | Hệ thống | FE component `RelationshipManager` gọi `GET /api/v1/relationships?user_id=X` (BE expose flat, FE embed nested UX) |
| 5.f.3 | Hệ thống | Hiển thị danh sách Người theo dõi đang map (tên, email, is_primary, permissions) |
| 5.f.4 | Admin | Click "Thêm Liên Kết" → Chọn user → Xác nhận |
| 5.f.5 | Hệ thống | `POST /api/v1/relationships` tạo record, ghi audit log |

### 5.g - Gán/Đổi Primary Emergency Contact

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.g.1 | Admin | Trong tab Quan hệ → click "Set Primary" |
| 5.g.2 | Hệ thống | `PATCH /api/v1/relationships/:id` set `is_primary=true`, đồng thời unset primary cũ |
| 5.g.3 | Hệ thống | Audit log |

### 5.h - Xóa quan hệ chăm sóc

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.h.1 | Admin | Click "Xóa" tại hàng liên kết |
| 5.h.2 | Hệ thống | Popup xác nhận |
| 5.h.3 | Admin | Xác nhận |
| 5.h.4 | Hệ thống | `DELETE /api/v1/relationships/:id`, audit log |

### 5.i - Bulk Lock/Unlock (NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.i.1 | Admin | Chọn nhiều users qua checkbox |
| 5.i.2 | Admin | Click action bar "Bulk Lock" hoặc "Bulk Unlock" |
| 5.i.3 | Hệ thống | Popup xác nhận với số lượng users selected |
| 5.i.4 | Admin | Xác nhận |
| 5.i.5 | Hệ thống | `PATCH /api/v1/users/bulk-lock` body `{ user_ids: [...], lock: true/false }` |
| 5.i.6 | Hệ thống | Loop through users, lock/unlock + send email notify + audit log từng user |
| 5.i.7 | Hệ thống | Hiển thị summary "Đã khóa N users" |

> **Note:** Bulk delete KHÔNG support — high risk, force individual confirm với password.

### 5.j - Xem chi tiết user (enriched, NEW Phase 0.5)

| Bước | Người thực hiện | Hành động |
|---|---|---|
| 5.j.1 | Admin | Click vào user trong table |
| 5.j.2 | Hệ thống | `GET /api/v1/users/:id?include=relations,audit,activity` |
| 5.j.3 | Hệ thống | Hiển thị user detail với:<br>- Basic info<br>- Linked profiles count (incoming + outgoing)<br>- Last 10 audit log entries<br>- Last login timestamp + IP<br>- Last vital data submission timestamp |

---

## Business Rules

- **BR-022-01**: Chỉ ADMIN truy cập (mọi route có `authenticate + requireAdmin`)
- **BR-022-02**: Xóa user cần verify password của admin (re-authentication)
- **BR-022-03**: Soft delete (set `deleted_at`), KHÔNG archive backup table riêng
- **BR-022-04**: Audit log mọi action (`user.create`, `user.update`, `user.lock`, `user.unlock`, `user.delete`, `user.bulk_lock`)
- **BR-022-05**: Email phải unique khi tạo user mới
- **BR-022-06**: Mỗi user chỉ có tối đa 1 `is_primary=true` relationship — khi set primary mới, primary cũ tự động unset
- **BR-022-07**: User chỉ xem được dữ liệu sức khỏe của user khác nếu có `user_relationships` link (ràng buộc bảo mật cốt lõi)
- **BR-022-09** (NEW Phase 0.5): Role change phải log audit với `before_value` + `after_value`. Admin KHÔNG được tự update role của mình (`req.user.id !== params.id` check trong controller)
- **BR-022-10** (NEW Phase 0.5): Email notify cho user khi tài khoản bị lock/unlock (template trong `email.js sendAccountLockNotification`)
- **BR-022-11** (NEW Phase 0.5): REST convention — chỉ `PATCH` cho update partial, `DELETE` cho remove (drop `PUT` và `POST /:id/delete` duplicate routes)

---

## API Endpoints (REST clean — Phase 0.5)

```
GET    /api/v1/users               list (search + filter + sort + paginate)
GET    /api/v1/users/:id           detail (basic)
GET    /api/v1/users/:id?include=relations,audit,activity   enriched detail
POST   /api/v1/users               create
PATCH  /api/v1/users/:id           update partial (full_name, phone, role, ...)
PATCH  /api/v1/users/:id/lock      toggle lock single
PATCH  /api/v1/users/bulk-lock     bulk lock/unlock (NEW)
DELETE /api/v1/users/:id           soft delete (require admin password)
```

**Dropped (Phase 0.5 cleanup):**
- ~~`PUT /api/v1/users/:id`~~ (duplicate of PATCH)
- ~~`PUT /api/v1/users/:id/lock`~~ (duplicate of PATCH)
- ~~`POST /api/v1/users/:id/delete`~~ (anti-REST)

---

## Yêu cầu phi chức năng

- **Security**:
  - Chỉ ADMIN truy cập (middleware enforce)
  - Delete cần re-authenticate password
  - Audit log đầy đủ với before/after value cho sensitive field (role, is_active)
  - Self-promotion prevention (admin không tự update role mình)
- **Performance**:
  - Load danh sách < 1 giây (pagination + index trên `deleted_at`, `created_at`)
  - Search < 500ms (cần index trên `full_name`, `email`, `phone`)
- **Data Integrity**: Soft delete preserves all data
- **Usability**:
  - Pagination, search, filter, sort
  - Bulk lock/unlock với checkbox
  - User detail enriched view (1-click info)
- **Email**:
  - Async send (không block API response)
  - Template Việt + English

---

## Phase 0.5 Decisions Log

| Decision ID | Detail | Date |
|---|---|---|
| D-USERS-01 | Email notify on lock/unlock | 2026-05-12 |
| D-USERS-02 | Drop archive backup table | 2026-05-12 |
| D-USERS-03 | Allow role update via PATCH + self-promote prevention + audit | 2026-05-12 |
| D-USERS-04 | REST clean — drop PUT/POST delete duplicates | 2026-05-12 |
| D-USERS-05 | Linked Profiles: BE independent + FE embed | 2026-05-12 |
| D-USERS-06 | Search/filter expanded scope | 2026-05-12 |
| D-USERS-07 | Keep role structure `user`/`admin` | 2026-05-12 |
| D-USERS-08 | User detail enriched | 2026-05-12 |
| D-USERS-09 | Bulk lock/unlock (NOT bulk delete) | 2026-05-12 |

---

## Implementation Reference (Admin BE)

- Routes: `user.routes.js`
- Controller: `user.controller.js`
- Service: `user.service.js`
- Validation: `createUserRules`, `updateUserRules`, `deleteUserRules` trong route file
- Email: `email.js sendAccountLockNotification` (Phase 4 task)
- Linked Profiles: separate `relationship.routes.js` + `RelationshipManager` FE component
