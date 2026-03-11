# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Cấu hình hệ thống toàn cục (Global System Settings)
- **Module**: CONFIG
- **Dự án**: Admin
- **Sprint**: Sprint 4
- **JIRA Epic**: EP16-AdminConfig
- **JIRA Story**: S01 — API Cài đặt Hệ thống, S02 — Trang Cài đặt FE
- **UC Reference**: UC024
- **Ngày đánh giá**: 2026-03-11
- **Lần đánh giá**: 1
- **Ngày đánh giá trước**: N/A

---

## 🏆 TỔNG ĐIỂM: 78/100

| Tiêu chí                    | Điểm  | Ghi chú                                                            |
| --------------------------- | ----- | ------------------------------------------------------------------ |
| Chức năng đúng yêu cầu      | 12/15 | Main flow ✅, nhưng thiếu Cache Invalidation (BR-024-03) và thông báo propagation delay |
| API Design                  | 8/10  | RESTful chuẩn, error format tốt, thiếu pagination trên GET        |
| Architecture & Patterns     | 12/15 | Clean Architecture OK, thiếu DTO/Schema layer, validation trộn trong service |
| Validation & Error Handling | 10/12 | Server-side validation tốt, thiếu validate toàn diện (chỉ validate vitals) |
| Security                    | 10/12 | Re-auth ✅, JWT + Admin guard ✅, thiếu rate limit trên PUT settings |
| Code Quality                | 10/12 | Code gọn gàng, SRP tốt, có minor anti-pattern (validation trong map callback) |
| Testing                     | 8/12  | 6 unit tests bao phủ các luồng chính, thiếu integration test + FE test |
| Documentation               | 8/12  | Comment code tốt, thiếu JSDoc + API docs (Swagger)                |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra                                       | Đạt? | Ghi chú                                                                            |
| ---------------------------------------------- | ---- | ---------------------------------------------------------------------------------- |
| Route → Controller → Service → Repo separation | ✅    | `settings.routes.js` → `settings.controller.js` → `settings.service.js` → Prisma   |
| Controller ONLY handles request/response       | ✅    | Controller chỉ parse req/res, delegate logic cho service                            |
| Service isolates business logic                | ✅    | Service chứa toàn bộ logic: re-auth, validation, transaction                       |
| Repository/Model isolates data access          | ⚠️   | Không có Repository layer riêng — Prisma gọi trực tiếp trong Service               |
| Dependency direction đúng chiều                | ✅    | Controller → Service → Prisma (không đảo ngược)                                    |

**Điểm:** 4/5

### Design Patterns (/5)
| Pattern    | Có? | Đánh giá                                                                |
| ---------- | --- | ----------------------------------------------------------------------- |
| Middleware | ✅   | `authenticate`, `requireAdmin`, `validate` middleware trên routes       |
| Repository | ❌   | Prisma gọi trực tiếp trong service — không có abstraction layer         |
| DTO/Schema | ❌   | Không có DTO — request body truyền thẳng, response trả raw Prisma data |
| Factory    | N/A | Không cần cho module này                                                |
| Strategy   | N/A | Không áp dụng                                                          |

**Điểm:** 2/5

### Domain Logic & Business Rules (/5)
| Kiểm tra                                 | Đạt? | Ghi chú                                                        |
| ---------------------------------------- | ---- | -------------------------------------------------------------- |
| Business rules tập trung trong Service   | ✅    | Re-auth, validation, audit đều nằm trong `settingsService`     |
| Domain validation tách biệt API valid.   | ⚠️   | Validation logic nằm bên trong `.map()` callback — nên tách ra |
| Edge cases handled                       | ✅    | Empty payload, non-editable, SpO2 logic, HR min > max          |
| Business logic testable without HTTP/DB  | ⚠️   | Prisma coupled trực tiếp — mock cần thiết                      |
| Không duplicate business logic           | ✅    | Logic chỉ có 1 nơi                                             |

**Điểm:** 3.5/5 → làm tròn 4/5

---

## 📂 FILES ĐÁNH GIÁ

| File                                                  | Layer      | LOC | Đánh giá tóm tắt                                                     |
| ----------------------------------------------------- | ---------- | --- | --------------------------------------------------------------------- |
| `backend/src/controllers/settings.controller.js`      | Controller | 29  | ✅ Rất gọn, chỉ parse req/res. Đúng SRP.                              |
| `backend/src/services/settings.service.js`            | Service    | 111 | ⚠️ Logic tốt nhưng hàm `updateSettings` hơi dài (94 dòng effective). |
| `backend/src/routes/settings.routes.js`               | Route      | 34  | ✅ Middleware chain rõ ràng: authenticate → requireAdmin → validate.   |
| `backend/src/__tests__/services/settings.service.test.js` | Test   | 112 | ⚠️ 6 test case cho đủ luồng chính. Thiếu edge cases.                 |
| `frontend/src/pages/admin/SystemSettingsPage.jsx`     | Page       | 144 | ✅ State management rõ ràng, toast notification tự xây.               |
| `frontend/src/components/settings/SettingsForm.jsx`   | Component  | 181 | ✅ Tab-based layout, stepper input cho number fields.                  |
| `frontend/src/components/settings/PasswordConfirmModal.jsx` | Component | 85 | ✅ Modal đúng UC — yêu cầu nhập lại mật khẩu.                  |
| `frontend/src/components/settings/SettingsConstants.js` | Config   | 41  | ✅ Constants tách riêng, dễ maintain. Có help tooltips.               |

---

## 📋 JIRA STORY TRACKING

### Epic: EP16-AdminConfig (Sprint 4)

#### S01: [Admin BE] API Cài đặt Hệ thống
| #   | Checklist Item                                    | Trạng thái | Ghi chú                                                                                |
| --- | ------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------- |
| 1   | Bảng `system_settings` áp dụng kiểu JSONB        | ✅          | Prisma schema sử dụng JSONB cho `setting_value`                                        |
| 2   | GET/PUT `/api/v1/settings` hoạt động              | ✅          | Cả hai endpoint hoạt động qua `settings.routes.js`                                     |
| 3   | Re-authentication khi PUT                         | ✅          | `settings.service.js:L14-L38` — bcrypt.compare password                                |
| 4   | Ghi Audit Logs (old_value, new_value)             | ✅          | `settings.service.js:L91-L101` — audit_logs trong transaction                          |
| 5   | Worker reload cache cấu hình mới                  | ❌          | Chưa implement Redis Pub/Sub hoặc cache invalidation (BR-024-03)                       |

#### S02: [Admin FE] Trang Cài đặt
| #   | Checklist Item                                    | Trạng thái | Ghi chú                                                                                |
| --- | ------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------- |
| 1   | Settings page với 4 Tab (AI, Notification, Vitals, Security) | ✅ | `SettingsConstants.js` định nghĩa 4 tabs, `SettingsForm.jsx` render         |
| 2   | Modal Re-auth popup khi nhấn Lưu                  | ✅          | `PasswordConfirmModal.jsx` hiển thị modal xác nhận password                            |
| 3   | Validate input UI (ranges, boolean)               | ⚠️          | FE có `min/max/step` trên number input, nhưng không có validation message inline khi sai logic |

#### Acceptance Criteria
| #   | Criteria                               | Trạng thái | Ghi chú                                                        |
| --- | -------------------------------------- | ---------- | -------------------------------------------------------------- |
| 1   | JSONB data storage                     | ✅          | Prisma JSONB column                                            |
| 2   | GET/PUT settings with 4 groups         | ✅          | 4 groups: `fall_detection_ai`, `notification_gateways`, `vitals_default_thresholds`, `system_security` |
| 3   | Re-auth password on PUT                | ✅          | Bcrypt compare trong service                                   |
| 4   | Audit logging old/new values           | ✅          | Transaction atomic với settings update                         |
| 5   | Cache invalidation after update        | ❌          | Thiếu hoàn toàn — không có Redis/Event Bus                    |
| 6   | FE 4-tab Settings Page                 | ✅          | UI 4 tab hoàn chỉnh                                           |
| 7   | Password confirm modal                 | ✅          | Modal component riêng biệt                                    |

---

## 📊 SRS COMPLIANCE

### Main Flow
| Bước | SRS Yêu cầu                                          | Implementation                                                  | Match? |
| ---- | ----------------------------------------------------- | --------------------------------------------------------------- | ------ |
| 1    | Admin truy cập menu "Cấu hình hệ thống"               | `SystemSettingsPage.jsx` — route `/admin/settings`               | ✅      |
| 2    | Query `system_settings` → render UI 4 tab             | `fetchSettings()` → GET `/api/v1/settings` + 4 tabs             | ✅      |
| 3    | Admin thay đổi tham số                                | `SettingsForm.jsx` — `handleInputChange()` + stepper UI         | ✅      |
| 4    | Bấm "Lưu Thay Đổi"                                   | `handleSaveClick()` → kiểm tra diff → mở modal                 | ✅      |
| 5    | Hộp thoại xác nhận nhập mật khẩu                     | `PasswordConfirmModal.jsx` hiển thị lý do + input password      | ✅      |
| 6    | Admin nhập mật khẩu xác nhận                          | `handleSubmit()` gửi password về `onConfirm(password)`          | ✅      |
| 7    | Validate mật khẩu + dữ liệu, lưu DB                  | `updateSettings()` — bcrypt compare + business validation + transaction | ✅ |
| 8    | Ghi `audit_logs` + phát sự kiện Cache Invalidation    | Audit log ✅ trong transaction. Cache invalidation ❌ chưa implement | ⚠️     |
| 9    | Thông báo "Cập nhật thành công + propagation delay"   | Toast "Cập nhật cấu hình thành công!" nhưng thiếu thông báo delay 1-2 phút | ⚠️ |

### Alternative Flows
| Flow | SRS Yêu cầu                                              | Implementation                                                | Match? |
| ---- | --------------------------------------------------------- | ------------------------------------------------------------- | ------ |
| 4.a  | Mật khẩu sai → cảnh báo + đóng modal                     | `settingsService.js:L26-L38` — throw error, FE hiển thị toast | ✅      |
| 4.b  | Thông số logic sai (SpO2 > 100, HR min ≥ HR max)         | `settingsService.js:L68-L76` — validate vitals thresholds     | ✅      |

### Exception Flows
| Flow | SRS Yêu cầu                               | Implementation                                                   | Match? |
| ---- | ------------------------------------------ | ---------------------------------------------------------------- | ------ |
| EX1  | DB lỗi giữa chừng → rollback              | `prisma.$transaction()` — atomic, tự rollback nếu fail          | ✅      |
| EX2  | User không phải admin → từ chối            | `requireAdmin` middleware + service-level role check             | ✅      |
| EX3  | Empty payload → bad request                | `settingsService.js:L42-L44` — check `Object.keys().length`     | ✅      |
| EX4  | Non-editable setting → bad request         | `settingsService.js:L54-L56` — check `is_editable` flag         | ✅      |

---

## ✅ ƯU ĐIỂM

1. **Clean Architecture tốt** — Controller chỉ 29 dòng, chỉ parse req/res, toàn bộ business logic nằm trong Service — `settings.controller.js:L6-L25`
2. **Re-authentication tuân thủ BR-024-01** — Password xác nhận qua `bcrypt.compare` trước khi cho phép cập nhật — `settings.service.js:L14-L38`
3. **Audit logging atomic** — Ghi audit_logs cùng transaction với update, đảm bảo consistency — `settings.service.js:L88-L102`
4. **UI component tách biệt rõ ràng** — Constants riêng (`SettingsConstants.js`), Form riêng (`SettingsForm.jsx`), Modal riêng (`PasswordConfirmModal.jsx`)
5. **Input validation business logic** — Kiểm tra SpO2 phi logic và HR min/max — `settings.service.js:L68-L76`
6. **Test coverage cho các luồng chính** — 6 unit tests bao phủ: success, auth fail, password wrong, non-editable, SpO2 invalid, HR invalid — `settings.service.test.js`
7. **FE UX tốt** — Tooltip help text cho mỗi field, stepper +/- cho number inputs, change detection trước khi hiện modal

## ❌ NHƯỢC ĐIỂM

1. **Thiếu Cache Invalidation (BR-024-03)** — UC024 yêu cầu sau khi lưu DB phải phát tín hiệu qua Pub/Sub Redis để workers clear cache. Hiện tại hoàn toàn không có — `settings.service.js:L88-L106` chỉ ghi DB + audit, không emit event — **Vi phạm business rule**
2. **Hàm `updateSettings` quá dài (~94 dòng logic)** — Tập trung re-auth + validate + update + audit trong 1 function, tiệm cận God Function — `settings.service.js:L13-L107`
3. **Validation chỉ áp dụng cho `vitals_default_thresholds`** — Các setting khác (AI `confidence_threshold`, `session_timeout_minutes`, v.v.) không được validate range tại backend — `settings.service.js:L68-L76`
4. **Không có DTO/Response Schema** — API trả raw Prisma objects, exposing internal DB structure (bao gồm `is_editable`, `created_at`, v.v.) ra client — `settings.service.js:L6-L11`
5. **FE gửi toàn bộ formData thay vì chỉ changed fields** — `SystemSettingsPage.jsx:L64` gửi `settings: formData` (toàn bộ), thay vì chỉ diff. Lãng phí bandwidth và audit log ghi thừa
6. **Thông báo sau khi lưu không đề cập propagation delay** — UC yêu cầu hiển thị "Lệnh thay đổi sẽ mất khoảng 1-2 phút để lan toả", nhưng toast chỉ nói "Cập nhật cấu hình thành công!" — `SystemSettingsPage.jsx:L72`
7. **Thiếu rate limiting trên PUT `/api/v1/settings`** — Endpoint nhạy cảm (thay đổi global config) nhưng không có rate limit — `settings.routes.js:L25-L31`
8. **FE không hiển thị validation error inline** khi input number vượt min/max — chỉ dựa vào HTML5 `min/max` attributes — `SettingsForm.jsx:L110-L117`

## 🔧 ĐIỂM CẦN CẢI THIỆN

1. **[HIGH]** Implement Cache Invalidation (BR-024-03) → Cách sửa: Sau transaction thành công, gọi `redis.publish('config:changed', JSON.stringify(validUpdates))` hoặc dùng EventEmitter nội bộ
2. **[HIGH]** Thêm rate limiting trên PUT settings → Cách sửa: Thêm `rateLimit({ windowMs: 60000, max: 5 })` middleware vào route PUT
3. **[HIGH]** Mở rộng validation cho tất cả setting groups → Cách sửa: Tạo validation schema riêng cho mỗi `setting_key` (ai config: confidence_threshold 0.5-0.99, countdown 5-120, v.v.)
4. **[MEDIUM]** Refactor `updateSettings()` thành nhiều hàm nhỏ → Cách sửa: Tách thành `reauthenticateAdmin()`, `validateSettingPayload()`, `applySettingsUpdate()`, `logAuditEntry()`
5. **[MEDIUM]** Thêm DTO layer cho response → Cách sửa: Filter response chỉ gồm `setting_key`, `setting_value`, `setting_group`, `description` — loại bỏ `is_editable`, `created_at`, v.v.
6. **[MEDIUM]** FE chỉ gửi changed fields → Cách sửa: So sánh `formData` vs `initialData` để chỉ gửi diff
7. **[LOW]** Cập nhật toast message có propagation delay → Cách sửa: Đổi thành "Cập nhật cấu hình thành công! Các thay đổi sẽ có hiệu lực trong 1-2 phút."
8. **[LOW]** Thêm FE inline validation messages → Cách sửa: Hiển thị error khi số vượt min/max thay vì chỉ dùng HTML5

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Audit log action `settings.updated` cho cả thành công lẫn thất bại (wrong password)** — Nên dùng action name khác cho failure case, ví dụ `settings.update_failed` — `settings.service.js:L31`

## ⚠️ SAI LỆCH VỚI JIRA / SRS

| Source         | Mô tả sai lệch                                                                                  | Mức độ | Đề xuất                                                     |
| -------------- | ------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------ |
| UC024 Bước 8   | Thiếu Event Bus/Redis cache invalidation. UC yêu cầu "Phát sự kiện để Workers cập nhật cache"   | 🔴     | Implement Redis Pub/Sub hoặc EventEmitter                    |
| UC024 Bước 9   | Thiếu thông báo propagation delay ("1-2 phút lan toả")                                          | 🟡     | Cập nhật toast message                                       |
| BR-024-03      | Cache Invalidation rule không được tuân thủ                                                      | 🔴     | Implement trước khi release                                  |
| S01 Checklist 5 | "Worker reload cache cấu hình mới thành công" — Chưa implement                                  | 🔴     | Blocked — cần implement cache layer trước                    |
| S02 Checklist 3 | "Validate input UI (ranges, boolean)" — Chỉ có HTML5 min/max, không có custom validation message | 🟡     | Thêm validation feedback UX tốt hơn                         |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt — Controller gọn gàng, đúng SRP:
```javascript
// file: backend/src/controllers/settings.controller.js, line 5-26
const settingsController = {
  getSettings: catchAsync(async (req, res) => {
    const settings = await settingsService.getSettings();
    ApiResponse.success(res, settings, 'Lấy cấu hình hệ thống thành công');
  }),

  updateSettings: catchAsync(async (req, res) => {
    const adminId = req.user.id;
    const { password, settings } = req.body;
    const ipAddress = req.ip || req.connection?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    
    const updated = await settingsService.updateSettings(
      adminId, password, settings, ipAddress, userAgent
    );
    ApiResponse.success(res, updated, 'Cập nhật cấu hình thành công');
  })
};
```

### ✅ Code tốt — Audit log atomic trong transaction:
```javascript
// file: backend/src/services/settings.service.js, line 88-102
const transactionResult = await prisma.$transaction([
  ...updatePromises,
  prisma.audit_logs.create({
    data: {
      user_id: adminId,
      action: 'settings.updated',
      resource_type: 'system_settings',
      details: { old_values: oldValues, new_values: validUpdates },
      ip_address: ipAddress,
      user_agent: userAgent,
      status: 'success'
    }
  })
]);
```

### ❌ Code cần sửa — Validation nằm trong `.map()` callback:
```javascript
// HIỆN TẠI: (settings.service.js:L66-L86)
const updatePromises = Object.entries(validUpdates).map(([key, value]) => {
  if (key === 'vitals_default_thresholds') {
    const rules = value;
    if (rules.spo2_min > 100 || rules.spo2_min < 0) {
      throw ApiError.badRequest('...');
    }
    // ... validation mixed with update logic
  }
  return prisma.system_settings.update({...});
});

// NÊN SỬA THÀNH:
function validateSettingValue(key, value) {
  const validators = {
    vitals_default_thresholds: (v) => {
      if (v.spo2_min > 100 || v.spo2_min < 0) throw ApiError.badRequest('...');
      if (v.hr_min >= v.hr_max) throw ApiError.badRequest('...');
    },
    fall_detection_ai: (v) => {
      if (v.confidence_threshold < 0.5 || v.confidence_threshold > 0.99) throw ApiError.badRequest('...');
      if (v.auto_sos_countdown_sec < 5 || v.auto_sos_countdown_sec > 120) throw ApiError.badRequest('...');
    }
  };
  if (validators[key]) validators[key](value);
}

// Gọi validate TRƯỚC khi tạo updatePromises
for (const [key, value] of Object.entries(validUpdates)) {
  validateSettingValue(key, value);
}
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| #   | Action                                                          | Owner         | Priority | Sprint   |
| --- | --------------------------------------------------------------- | ------------- | -------- | -------- |
| 1   | Implement Cache Invalidation (Redis Pub/Sub hoặc EventEmitter) | Backend Dev   | HIGH     | Sprint 4 |
| 2   | Thêm rate limiting trên PUT `/api/v1/settings`                 | Backend Dev   | HIGH     | Sprint 4 |
| 3   | Mở rộng backend validation cho tất cả setting groups           | Backend Dev   | HIGH     | Sprint 4 |
| 4   | Refactor `updateSettings()` → tách thành 4 hàm nhỏ            | Backend Dev   | MEDIUM   | Sprint 4 |
| 5   | Thêm DTO layer cho API response                                | Backend Dev   | MEDIUM   | Sprint 4 |
| 6   | FE chỉ gửi changed fields (diff payload)                      | Frontend Dev  | MEDIUM   | Sprint 4 |
| 7   | Cập nhật toast message có thông tin propagation delay           | Frontend Dev  | LOW      | Sprint 4 |
| 8   | Thêm inline validation feedback trên FE                        | Frontend Dev  | LOW      | Sprint 4 |
| 9   | Thêm integration tests cho API endpoints                       | QA / Backend  | MEDIUM   | Sprint 4 |
| 10  | Thêm JSDoc cho public functions                                | Backend Dev   | LOW      | Sprint 4 |
