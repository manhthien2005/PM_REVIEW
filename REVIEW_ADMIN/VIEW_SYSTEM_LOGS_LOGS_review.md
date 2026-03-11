# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Xem nhật ký hệ thống (View System Logs)
- **Module**: LOGS
- **Dự án**: Admin
- **Sprint**: Sprint 4
- **JIRA Epic**: EP16-AdminConfig
- **JIRA Story**: S01 — API Cài đặt Hệ thống + Logs; S02 — Trang Cài đặt + Trang Logs
- **UC Reference**: UC026
- **Ngày đánh giá**: 2026-03-11
- **Lần đánh giá**: 1
- **Ngày đánh giá trước**: N/A

---

## 🏆 TỔNG ĐIỂM: 85/100

| Tiêu chí                    | Điểm  | Ghi chú                                                              |
| --------------------------- | ----- | -------------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 14/15 | Main flow + alt flow đầy đủ, thiếu audit log cho hành động xem log   |
| API Design                  | 9/10  | RESTful chuẩn, pagination tốt, thiếu validate id param              |
| Architecture & Patterns     | 13/15 | Clean Architecture rõ ràng, thiếu DTO layer                          |
| Validation & Error Handling | 10/12 | Validation middleware tốt, export thiếu try-catch ở controller       |
| Security                    | 11/12 | Auth + rate limit + sanitize tốt, thiếu limit trên param limit       |
| Code Quality                | 10/12 | SOLID tốt, có duplicate code ở filter params giữa export CSV/JSON   |
| Testing                     | 9/12  | Unit test đầy đủ cả controller + service, thiếu edge case tests      |
| Documentation               | 9/12  | JSDoc tốt, có Swagger chung, thiếu ADR                               |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5) — Đạt: 4/5

| Kiểm tra                                       | Đạt? | Ghi chú                                                           |
| ---------------------------------------------- | ---- | ----------------------------------------------------------------- |
| Route → Controller → Service → Repo separation | ✅    | `logs.routes.js` → `logs.controller.js` → `logs.service.js` → Prisma |
| Controller ONLY handles request/response       | ✅    | Controller chỉ parse params + gọi service + trả response          |
| Service isolates business logic                | ✅    | Service chứa toàn bộ logic filter, paginate, export, sanitize     |
| Repository/Model isolates data access          | ⚠️   | Prisma calls nằm trực tiếp trong service, không tách Repository    |
| Dependency direction: Controller → Service     | ✅    | Không có inverted dependency                                       |

### Design Patterns (/5) — Đạt: 4/5

| Pattern    | Có? | Đánh giá                                                          |
| ---------- | --- | ----------------------------------------------------------------- |
| Middleware | ✅   | `authenticate`, `requireAdmin`, `rateLimit`, `validate` — đầy đủ  |
| Repository | ❌   | Prisma calls nằm trong service, không có Repository pattern        |
| DTO/Schema | ⚠️  | Có validation rules trong routes nhưng không có DTO riêng          |
| Strategy   | ✅   | Export strategy (CSV/JSON) tách hàm riêng trong service            |

---

## 📂 FILES ĐÁNH GIÁ

| File                                              | Layer      | LOC | Đánh giá tóm tắt                                           |
| ------------------------------------------------- | ---------- | --- | ----------------------------------------------------------- |
| `backend/src/routes/logs.routes.js`               | Route      | 55  | Chuẩn, rate limit + auth + validate đầy đủ                  |
| `backend/src/controllers/logs.controller.js`      | Controller | 99  | Clean, chỉ parse req/res + gọi service                      |
| `backend/src/services/logs.service.js`            | Service    | 236 | Business logic tốt, sanitize BR-026-03, BigInt handling      |
| `backend/src/__tests__/controllers/logs.controller.test.js` | Test | 212 | 4 test suites, mock đúng, kiểm tra params + audit log        |
| `backend/src/__tests__/services/logs.service.test.js` | Test   | 387 | 6 test suites, 13 test cases, coverage tốt                   |
| `frontend/src/pages/admin/SystemLogsPage.jsx`     | Page       | 244 | Orchestrator tốt, debounce search, toast notification        |
| `frontend/src/components/logs/LogDetailModal.jsx` | Component  | 138 | Modal chi tiết log, hiển thị JSON formatted                  |
| `frontend/src/components/logs/LogsTable.jsx`      | Component  | 178 | Bảng log đầy đủ cột theo UC, loading/empty state             |
| `frontend/src/components/logs/LogsToolbar.jsx`    | Component  | 148 | Toolbar search + filter + export, advanced filters           |
| `frontend/src/components/logs/LogsPagination.jsx` | Component  | 56  | Pagination với ellipsis, first/last page buttons             |
| `frontend/src/components/logs/LogsConstants.js`   | Config     | 17  | Constants tách riêng — clean                                 |
| `frontend/src/services/logsService.js`            | Service    | 127 | API calls + blob download cho export                         |

---

## 📋 JIRA STORY TRACKING

### Epic: EP16-AdminConfig (Sprint 4)

#### S01: [Admin BE] API Cài đặt Hệ thống + Logs

| #   | Checklist Item                              | Trạng thái | Ghi chú                                                |
| --- | ------------------------------------------- | ---------- | ------------------------------------------------------ |
| 1   | GET `/api/admin/logs` (filter + pagination) | ✅          | Implement tại `GET /api/v1/logs` — đầy đủ filter       |
| 2   | Worker reload cache cấu hình                | 🔄          | Thuộc CONFIG module, không liên quan LOGS               |

#### S01 — Acceptance Criteria

| #   | Criteria                                     | Trạng thái | Ghi chú                                              |
| --- | -------------------------------------------- | ---------- | ---------------------------------------------------- |
| 1   | GET `/api/admin/logs` (filter + pagination)  | ✅          | 9 filter params, offset pagination                    |
| 2   | CSV export                                   | ✅          | `GET /api/v1/logs/export/csv` — đầy đủ               |

#### S02: [Admin FE] Trang Cài đặt + Trang Logs

| #   | Checklist Item                            | Trạng thái | Ghi chú                                               |
| --- | ----------------------------------------- | ---------- | ----------------------------------------------------- |
| 1   | System Logs page: table + date range      | ✅          | `SystemLogsPage.jsx` + `LogsToolbar.jsx`               |
| 2   | Nút Xuất CSV tải file thành công          | ✅          | Blob download hoạt động đúng                           |

#### S02 — Acceptance Criteria

| #   | Criteria                                       | Trạng thái | Ghi chú                                          |
| --- | ---------------------------------------------- | ---------- | ------------------------------------------------ |
| 1   | System Logs page: table có date range filter   | ✅          | Advanced filter có start_date + end_date          |
| 2   | Nút Xuất CSV tải file thành công               | ✅          | CSV + JSON export đều hoạt động                   |
| 3   | Validate input UI                              | ✅          | LogsToolbar validate qua state management         |

#### S03: [QA] Kiểm thử Cài đặt & Logs

| #   | Criteria                                      | Trạng thái | Ghi chú                                        |
| --- | --------------------------------------------- | ---------- | ---------------------------------------------- |
| 1   | Logs display with filters hiển thị đúng       | ✅          | Unit tests verify filter params truyền đúng     |
| 2   | CSV export file format chuẩn                  | ✅          | Test verify CSV header + content đúng format    |

---

## 📊 SRS COMPLIANCE

### Main Flow

| Bước | SRS Yêu cầu                                                                                       | Implementation                                                                       | Match? |
| ---- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------ |
| 1    | Admin mở màn "Nhật ký hệ thống"                                                                   | `SystemLogsPage.jsx` — render page với header, toolbar, table                         | ✅      |
| 2    | Hệ thống truy vấn `audit_logs` với khoảng thời gian mặc định (24 giờ gần nhất)                    | `logs.service.js:L48-54` — default 24h filter (`defaultStartDate`)                   | ✅      |
| 3    | Hiển thị bảng log: Thời gian, User, Hành động, Resource, Kết quả                                  | `LogsTable.jsx` — 7 cột: Time, User, Action, Resource, Status, IP, Chi tiết          | ✅      |
| 4    | Dùng ô tìm kiếm/bộ lọc: thời gian, user, loại hành động                                          | `LogsToolbar.jsx` — search + status + resource_type + action + date range filters     | ✅      |
| 5    | Chọn 1 log để xem chi tiết                                                                        | `LogsTable.jsx:L158-164` — nút Eye icon gọi `onViewDetail`                           | ✅      |
| 6    | Hiển thị chi tiết `details` (JSON) dưới dạng format dễ đọc (old/new value, IP, user agent)         | `LogDetailModal.jsx:L113-119` — JSON.stringify(details, null, 2) trong dark terminal  | ✅      |

### Alternative Flows

| Flow  | SRS Yêu cầu                                  | Implementation                                                                 | Match? |
| ----- | --------------------------------------------- | ------------------------------------------------------------------------------ | ------ |
| 2.a   | Không có log trong khoảng thời gian → thông báo | `LogsTable.jsx:L84-95` — empty state "Không tìm thấy dữ liệu"                 | ✅      |
| 4.a   | Xuất CSV hoặc JSON cho khoảng thời gian       | `exportCSV()` + `exportJSON()` trong controller/service + toolbar buttons       | ✅      |

### Exception Flows

| Flow | SRS Yêu cầu         | Implementation                                           | Match? |
| ---- | -------------------- | -------------------------------------------------------- | ------ |
| E1   | Log không tồn tại    | `logs.service.js:L132` — `ApiError.notFound()` khi findById null | ✅      |

### Business Rules

| Rule      | SRS Yêu cầu                                                          | Implementation                                                            | Match? |
| --------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------ |
| BR-026-01 | Nhật ký không được chỉnh sửa (append-only)                           | `writeLog()` chỉ có `create`, không có `update`/`delete` trong service    | ✅      |
| BR-026-02 | Dữ liệu log được lưu tối thiểu 2 năm                                | Logic retention nằm ở DB level, không thấy code xoá log                   | ⚠️      |
| BR-026-03 | Không hiển thị trường nhạy cảm (password, token)                     | `findById()` và `exportToJSON()` sanitize password/token fields            | ✅      |

### Yêu cầu phi chức năng

| Yêu cầu       | SRS                                                        | Implementation                                                       | Match? |
| -------------- | ---------------------------------------------------------- | -------------------------------------------------------------------- | ------ |
| Security       | Chỉ admin có quyền đặc biệt mới truy cập                 | `authenticate + requireAdmin` middleware trên tất cả routes           | ✅      |
| Performance    | Hỗ trợ phân trang, không load tất cả log một lúc          | Offset pagination (skip/take), export giới hạn 10k records           | ✅      |
| Auditability   | Chính màn hình xem log cũng nên ghi log lại               | Export có ghi `log.exported`, nhưng view list/detail không ghi log    | ⚠️      |

---

## ✅ ƯU ĐIỂM

1. **Clean Architecture tuyệt vời** — Tách Route → Controller → Service rất rõ ràng. Controller chỉ parse request, gọi service rồi trả response. — `logs.controller.js:L9-96`
2. **Bảo mật đa lớp** — Có đầy đủ `authenticate`, `requireAdmin`, `rateLimit(100 req/min)`, `validate` middleware trên tất cả routes. — `logs.routes.js:L46`
3. **Sanitize dữ liệu nhạy cảm (BR-026-03)** — Service tự xoá password, token, access_token, refresh_token khỏi details trước khi trả về. — `logs.service.js:L135-143`
4. **Frontend component hóa tốt** — Tách LogsTable, LogsToolbar, LogsPagination, LogDetailModal, LogsConstants thành component riêng biệt. — `frontend/src/components/logs/`
5. **Debounce search** — Search có debounce 400ms tránh gọi API liên tục. — `SystemLogsPage.jsx:L92-101`
6. **BigInt handling** — Xử lý đúng PostgreSQL BigInt bằng `.toString()` conversion trước khi serialize JSON. — `logs.service.js:L94-97`
7. **Export có giới hạn hợp lý** — Export giới hạn tối đa 10,000 records, tránh OOM. — `logs.service.js:L157,186`
8. **Test coverage tốt** — 17 test cases bao phủ cả controller và service, bao gồm filter, search, export, sanitize, error cases, writeLog. — `logs.controller.test.js` + `logs.service.test.js`
9. **Default 24h filter** — Đúng UC026 yêu cầu, mặc định query 24 giờ gần nhất. — `logs.service.js:L48-54`

## ❌ NHƯỢC ĐIỂM

1. **Thiếu audit log cho hành động xem log** — UC026 yêu cầu phi chức năng "Chính màn hình xem log cũng nên ghi log lại (`admin.view_logs`)" nhưng `getAll` và `getById` không ghi audit log (chỉ export mới ghi). — `logs.controller.js:L11-35`
2. **Duplicate filter params code** — Controller `exportCSV` (L39-49) và `exportJSON` (L69-79) có code destructure + transform filter params giống hệt nhau, vi phạm DRY. — `logs.controller.js:L38-49` vs `L68-79`
3. **Thiếu validate param `id` ở route getById** — Route `GET /:id` không có validation middleware, nếu truyền id không hợp lệ sẽ gây lỗi BigInt conversion. — `logs.routes.js:L52`
4. **Thiếu DTO layer** — Không có Response DTO, dữ liệu từ Prisma trả về trực tiếp sau khi map, tight coupling với DB schema. — `logs.service.js`
5. **Frontend `mapLog` function không cần thiết** — Hàm `mapLog()` ở `SystemLogsPage.jsx:L13-28` chỉ copy y nguyên tất cả field, không transform gì — redundant. — `SystemLogsPage.jsx:L13-28`
6. **Thiếu limit validation trên query param `limit`** — User có thể truyền `limit=100000`, service sẽ query toàn bộ database, gây performance issue. — `logs.controller.js:L16`

## 🔧 ĐIỂM CẦN CẢI THIỆN

1. **[HIGH]** Thêm audit log cho `getAll` và `getById` theo yêu cầu phi chức năng UC026 → Cách sửa: gọi `logsService.writeLog({ action: 'log.viewed', ... })` trong controller sau khi query thành công
2. **[HIGH]** Validate param `id` trên route `GET /:id` → Cách sửa: thêm validation rule `params: { id: { type: 'string', pattern: /^\d+$/ } }` trong `logs.routes.js`
3. **[MEDIUM]** Giới hạn query param `limit` (max 100) → Cách sửa: `const safeLimit = Math.min(Number(limit) || 20, 100)` trong controller hoặc service
4. **[MEDIUM]** Extract helper function để parse filter params, tránh duplicate → Cách sửa: tạo `parseFilters(query)` helper function dùng chung cho getAll, exportCSV, exportJSON
5. **[LOW]** Xoá hàm `mapLog()` không cần thiết ở `SystemLogsPage.jsx` → Cách sửa: dùng trực tiếp `res.data` thay vì `.map(mapLog)`
6. **[LOW]** Thêm DTO/Response schema cho log data → Cách sửa: tạo `dtos/logResponse.js` để chuẩn hoá response format

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Hàm `mapLog()` redundant** — Chỉ copy tất cả field mà không transform, nên xoá để giảm code complexity. — `SystemLogsPage.jsx:L13-28`
2. **Duplicate filter destructuring** — Code destructure filter trong `exportCSV` và `exportJSON` giống nhau hoàn toàn, nên extract thành helper. — `logs.controller.js:L39-49` vs `L69-79`

## ⚠️ SAI LỆCH VỚI JIRA / SRS

| Source        | Mô tả sai lệch                                                                                         | Mức độ | Đề xuất                                      |
| ------------- | ------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| UC026 — NFR   | Auditability: "Chính màn hình xem log cũng nên ghi log" — chưa implement cho getAll/getById             | 🟡      | Thêm audit log cho view list + view detail    |
| BR-026-02     | Retention policy 2 năm — chưa thấy mechanism enforce (DB TTL, cron job, etc.)                           | 🟡      | Tạo scheduled job hoặc DB partition by time   |
| Validation    | Route `GET /:id` thiếu validation, có thể gây BigInt error nếu id không phải số                         | 🟡      | Thêm param validation middleware              |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt — Sanitize sensitive data (BR-026-03):
```javascript
// file: backend/src/services/logs.service.js, line 134-143
// Sanitize sensitive fields from details (BR-026-03)
if (log.details && typeof log.details === 'object') {
  const sanitized = { ...log.details };
  delete sanitized.password;
  delete sanitized.password_hash;
  delete sanitized.token;
  delete sanitized.access_token;
  delete sanitized.refresh_token;
  log.details = sanitized;
}
```

### ✅ Code tốt — Default 24h filter đúng UC026:
```javascript
// file: backend/src/services/logs.service.js, line 48-54
// Date range filter (default: last 24 hours)
const now = new Date();
const defaultStartDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);

where.time = {
  gte: start_date ? new Date(start_date) : defaultStartDate,
  lte: end_date ? new Date(end_date) : now,
};
```

### ❌ Code cần sửa — Thiếu limit validation:
```javascript
// HIỆN TẠI (logs.controller.js:L15-16):
const { page, limit, ... } = req.query;
const result = await logsService.findAll({ limit: Number(limit) || 20, ... });

// NÊN SỬA THÀNH:
const { page, limit, ... } = req.query;
const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100); // Min 1, Max 100
const result = await logsService.findAll({ limit: safeLimit, ... });
```

### ❌ Code cần sửa — Duplicate filter params:
```javascript
// HIỆN TẠI (logs.controller.js:L38-49 và L68-79):
// exportCSV và exportJSON có cùng destructure code
exportCSV: catchAsync(async (req, res) => {
  const { action, status, user_id, resource_type, start_date, end_date, search } = req.query;
  // ... duplicate code
});

// NÊN SỬA THÀNH:
const parseExportFilters = (query) => ({
  action: query.action,
  status: query.status,
  user_id: query.user_id ? Number(query.user_id) : undefined,
  resource_type: query.resource_type,
  start_date: query.start_date,
  end_date: query.end_date,
  search: query.search,
});
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| #   | Action                                         | Owner     | Priority | Sprint   |
| --- | ---------------------------------------------- | --------- | -------- | -------- |
| 1   | Thêm audit log cho getAll/getById (UC026 NFR)  | BE Dev    | HIGH     | Sprint 4 |
| 2   | Validate param id trên route GET /:id           | BE Dev    | HIGH     | Sprint 4 |
| 3   | Giới hạn query param limit (max 100)           | BE Dev    | MEDIUM   | Sprint 4 |
| 4   | Extract parseExportFilters helper (DRY)        | BE Dev    | MEDIUM   | Sprint 4 |
| 5   | Implement retention policy mechanism (BR-026-02)| DevOps    | MEDIUM   | Sprint 5 |
| 6   | Xoá mapLog redundant ở frontend               | FE Dev    | LOW      | Sprint 4 |
| 7   | Thêm DTO/Response schema                       | BE Dev    | LOW      | Sprint 5 |
