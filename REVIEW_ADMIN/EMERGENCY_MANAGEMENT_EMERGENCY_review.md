# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Quản lý sự cố khẩn cấp (Emergency Management)
- **Module**: EMERGENCY
- **Dự án**: Admin
- **Sprint**: Sprint 3-4
- **JIRA Epic**: EP09-FallDetect, EP10-SOS
- **JIRA Story**: EP09/S01-S04 (Fall Detection), EP10/S01-S03 (SOS)
- **UC Reference**: UC029
- **Ngày đánh giá**: 2026-03-11
- **Lần đánh giá**: 1
- **Ngày đánh giá trước**: N/A

---

## 🏆 TỔNG ĐIỂM: 74/100

| Tiêu chí                    | Điểm  | Ghi chú                                                     |
| --------------------------- | ----- | ------------------------------------------------------------ |
| Chức năng đúng yêu cầu      | 11/15 | Main flow OK; thiếu export CSV/PDF (5.e) và date range filter |
| API Design                  | 8/10  | RESTful chuẩn, pagination có; PUT thay vì PATCH cho status   |
| Architecture & Patterns     | 12/15 | Clean Arch tốt; thiếu DTO layer, service hơi dài            |
| Validation & Error Handling | 9/12  | Validation cơ bản có; thiếu sanitize cho params, query       |
| Security                    | 9/12  | JWT+Admin OK; thiếu rate limiting, GPS sensitivity control   |
| Code Quality                | 9/12  | SOLID tốt; `getEventDetails` dài 77 dòng, magic values      |
| Testing                     | 7/12  | 10 unit test cases có; thiếu integration test, edge cases    |
| Documentation               | 9/12  | Summary có; thiếu JSDoc, API docs chưa có Swagger            |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5) — **4/5**
| Kiểm tra                                            | Đạt? | Ghi chú                                                             |
| --------------------------------------------------- | ---- | ------------------------------------------------------------------- |
| Route → Controller → Service → Repo separation      | ✅    | `emergency.routes.js` → `emergency.controller.js` → `emergency.service.js` → Prisma |
| Controller ONLY handles request/response, NO BL      | ✅    | Controller chỉ parse request, delegate cho service                  |
| Service isolates business logic                      | ✅    | Mọi business logic nằm trong service                                |
| Repository/Model isolates data access                | ⚠️   | Service truy cập Prisma trực tiếp, thiếu repository layer riêng    |
| Dependency direction never inverted                  | ✅    | Controller → Service → Prisma (1 chiều)                             |

### Design Patterns (/5) — **3/5**
| Pattern    | Có? | Đánh giá                                                     |
| ---------- | --- | ------------------------------------------------------------ |
| Middleware | ✅   | `authenticate` + `requireAdmin` + `validate` trên routes     |
| Repository | ❌   | Prisma calls trực tiếp trong service, không có abstraction    |
| DTO/Schema | ❌   | Không có response DTO, API trả trực tiếp Prisma + mapping    |
| Factory    | N/A | Không cần                                                     |
| Strategy   | ✅   | Status transition logic dùng guard clauses rõ ràng            |

---

## 📂 FILES ĐÁNH GIÁ

| File                                   | Layer             | LOC | Đánh giá tóm tắt                                            |
| -------------------------------------- | ----------------- | --- | ------------------------------------------------------------ |
| `emergency.controller.js`             | Controller        | 71  | Clean, mỗi method < 15 dòng, delegate đúng cho service      |
| `emergency.service.js`                | Service           | 291 | Đủ chức năng, `getEventDetails` dài 77 dòng cần tách         |
| `emergency.routes.js`                 | Route             | 31  | Gọn, validation rules inline, auth middleware đúng           |
| `emergency.service.test.js`           | Test              | 143 | 10 test cases, mock tốt, thiếu edge cases                   |
| `EmergencyPage.jsx`                   | Page (Frontend)   | 275 | Tổ chức rõ ràng, auto-refresh 15s, filter + toast + modals   |
| `EmergencyDetailModal.jsx`            | Component         | 215 | UI đầy đủ: patient, vitals, GPS, timeline, contacts          |
| `EmergencyTable.jsx`                  | Component         | 116 | Highlight search, sticky header column, status badge          |
| `EmergencyToolbar.jsx`                | Component         | 90  | Search + type/status filter + export button                  |
| `EmergencyStatusPrompt.jsx`           | Component         | 79  | Modal confirm + textarea notes (bắt buộc), form validation   |
| `EmergencySummaryBar.jsx`             | Component         | 52  | 4 summary cards: SOS active, falls pending, resolved, 7 days |
| `EmergencyPagination.jsx`             | Component         | 58  | Pagination cho history tab                                   |
| `EmergencyConstants.js`               | Constants         | 21  | STATUS_OPTIONS, TYPE_OPTIONS, STATUS_COLORS, PAGE_SIZE       |
| `emergencyService.js` (FE)            | Service (Frontend)| 31  | API wrapper, 6 methods khớp với backend endpoints            |

---

## 📋 JIRA STORY TRACKING

### Epic: EP09-FallDetect (Sprint 3)

#### Checklist — Admin-relevant items
| #   | Checklist Item                    | Trạng thái | Ghi chú                                              |
| --- | --------------------------------- | ---------- | ---------------------------------------------------- |
| 1   | Fall events hiển thị trên Admin   | ✅          | `getActiveEvents` map `trigger_type=auto` → "Fall"    |
| 2   | Fall detection detail + timeline  | ✅          | `getEventDetails` fetch `fall_events` + build timeline |
| 3   | Confidence score hiển thị         | ✅          | `eventInfo.confidence` từ `fall_events.confidence`     |

### Epic: EP10-SOS (Sprint 3)

#### Checklist — Admin-relevant items
| #   | Checklist Item                          | Trạng thái | Ghi chú                                                |
| --- | --------------------------------------- | ---------- | ------------------------------------------------------ |
| 1   | GET active SOS                          | ✅          | `GET /api/v1/emergencies/active`                        |
| 2   | SOS event detail + GPS                  | ✅          | `GET /api/v1/emergencies/:id` — latitude/longitude      |
| 3   | Emergency contacts theo priority        | ✅          | `emergency_contacts.findMany` orderBy priority asc      |
| 4   | POST acknowledge (responded)            | ✅          | `PUT /api/v1/emergencies/:id/status` + notes            |
| 5   | POST resolve                            | ✅          | Status flow `active→responded→resolved` enforced        |

#### Acceptance Criteria
| #   | Criteria                                | Trạng thái | Ghi chú                                                |
| --- | --------------------------------------- | ---------- | ------------------------------------------------------ |
| 1   | Admin xem danh sách SOS active          | ✅          | Real-time active events tab                             |
| 2   | Admin xem lịch sử + phân trang          | ✅          | History tab + pagination (offset-based)                 |
| 3   | Admin cập nhật status + ghi chú bắt buộc | ✅          | `EmergencyStatusPrompt` + validation notes required     |
| 4   | Admin ghi nhận liên hệ emergency        | ✅          | `POST /:id/contact` + audit log                         |
| 5   | Audit log cho mọi hành động             | ✅          | `audit_logs.create` trong `updateEventStatus` và `logEmergencyContact` |

---

## 📊 SRS COMPLIANCE

### Main Flow (UC029)
| Bước | SRS Yêu cầu                                       | Implementation                                             | Match? |
| ---- | -------------------------------------------------- | ---------------------------------------------------------- | ------ |
| 1    | Admin truy cập "Quản lý sự cố khẩn cấp"            | `EmergencyPage.jsx` — route tương ứng                       | ✅      |
| 2    | Hiển thị Summary Bar (SOS active, Falls, Resolved)  | `EmergencySummaryBar.jsx` — 4 cards khớp requirement        | ✅      |
| 3    | Bảng sự cố đang hoạt động (realtime, urgency sort)  | `EmergencyTable` + auto-refresh 15s, orderBy triggered_at   | ✅      |
| 4    | Bảng lịch sử sự cố (tab riêng, phân trang)          | History tab + `EmergencyPagination` (10/page)               | ✅      |
| 5    | Admin xem tổng quan và quyết định hành động          | Summary + Table + Detail modal + Status buttons             | ✅      |

### Alternative Flows
| Flow | SRS Yêu cầu                            | Implementation                                             | Match? |
| ---- | --------------------------------------- | ---------------------------------------------------------- | ------ |
| 5.a  | Xem chi tiết sự cố (patient, vitals, GPS, timeline) | `EmergencyDetailModal.jsx` — đầy đủ thông tin              | ✅      |
| 5.b  | Cập nhật trạng thái sự cố (active→responded→resolved) | `updateEventStatus` + `EmergencyStatusPrompt` — notes bắt buộc | ✅      |
| 5.c  | Liên hệ khẩn cấp từ Dashboard          | `logEmergencyContact` + contacts list trong DetailModal     | ✅      |
| 5.d  | Lọc sự cố (Type/Status/Search)         | `EmergencyToolbar` — filter type, status (history), search  | ⚠️ Thiếu date range filter |
| 5.e  | Xuất báo cáo sự cố (CSV/PDF)           | Nút "Xuất báo cáo" có UI nhưng **chưa có logic**            | ❌      |

### Exception Flows / Business Rules
| Rule      | SRS Yêu cầu                                       | Implementation                                             | Match? |
| --------- | -------------------------------------------------- | ---------------------------------------------------------- | ------ |
| BR-029-01 | Auto-refresh mỗi 15 giây                           | `setInterval(15000)` trong `EmergencyPage` useEffect        | ✅      |
| BR-029-02 | SOS active highlight đỏ + nhấp nháy                | `bg-rose-50/30` row + `animate-pulse` dot                   | ✅      |
| BR-029-03 | Notes BẮT BUỘC khi update status                   | `if (!notes || notes.trim() === '')` → ApiError.badRequest  | ✅      |
| BR-029-04 | Append-only workflow (không xóa/chỉnh sửa)         | Chỉ có PUT status, không có DELETE endpoint                  | ✅      |
| BR-029-05 | Mọi hành động ghi audit_logs                       | `audit_logs.create` trong updateEventStatus + logContact    | ⚠️ Thiếu log cho getEventDetails (xem chi tiết) |
| BR-029-06 | Flow active→responded→resolved (không skip bước)    | Guard clauses L219-L227 service, đúng logic                 | ✅      |

---

## ✅ ƯU ĐIỂM

1. **Clean Architecture rõ ràng** — Route → Controller → Service phân tách tốt, controller chỉ 71 dòng, mỗi method < 15 dòng — `emergency.controller.js`
2. **Business rule enforcement xuất sắc** — Status flow `active→responded→resolved` được validate chặt chẽ với 4 guard clauses tại `emergency.service.js:L218-L227`, không thể skip bước
3. **Frontend component decomposition tốt** — 7 components riêng biệt, mỗi component có trách nhiệm rõ ràng (Summary, Table, Toolbar, Modal, Prompt, Pagination, Constants)
4. **Auto-refresh implementation đúng** — 15s interval cho active tab, silent fetch (no loading indicator) để tránh flicker — `EmergencyPage.jsx:L79-L91`
5. **SOS highlight + animation** — Active SOS rows có `bg-rose-50/30` background + `animate-pulse` dot, khớp BR-029-02 — `EmergencyTable.jsx:L61,L83`
6. **Audit logging đầy đủ cho mutation** — `updateEventStatus` và `logEmergencyContact` đều ghi audit_logs với details JSON — `emergency.service.js:L245-L258,L271-L284`
7. **Timeline sự kiện tự xây dựng** — Build timeline từ fall detection → SOS trigger → admin responded → resolved, với audit_logs lookup — `emergency.service.js:L170-L186`
8. **Debounced search** — 400ms debounce cho search input để tránh gọi API quá nhiều — `EmergencyPage.jsx:L94-L102`

## ❌ NHƯỢC ĐIỂM

1. **Nút "Xuất báo cáo" chưa có logic** — `EmergencyToolbar.jsx:L80-L83` — Button render trên UI nhưng không có `onClick` handler, không có backend endpoint hỗ trợ export → Vi phạm UC029 flow 5.e
2. **Thiếu date range filter** — UC029 flow 5.d yêu cầu bộ lọc "Khoảng thời gian" nhưng `EmergencyToolbar.jsx` chỉ có type + status filter → Thiếu tính năng
3. **`getEventDetails` function dài 77 dòng** — `emergency.service.js:L131-L207` — Vượt ngưỡng 50 dòng, chứa DB queries + timeline build + data transform → nên tách
4. **Thiếu audit log cho xem chi tiết** — BR-029-05 yêu cầu ghi log cho "xem chi tiết" nhưng `getEventDetails` trong service không ghi audit_logs — `emergency.controller.js:L33-L41`
5. **Service truy cập Prisma trực tiếp** — `emergency.service.js` gọi `prisma.sos_events.findMany(...)` trực tiếp thay vì qua repository/DAO layer → tight coupling với Prisma ORM
6. **PUT thay vì PATCH cho status update** — `emergency.routes.js:L27` dùng `PUT` nhưng chỉ cập nhật partial (status + notes), nên dùng `PATCH` theo RESTful convention
7. **Frontend filtering client-side cho active events** — `EmergencyPage.jsx:L55-L56` filter trên client thay vì server → không scale với số lượng events lớn
8. **Thiếu connection loss warning** — UC029 Reliability yêu cầu hiển thị warning "Dữ liệu có thể không cập nhật" khi mất kết nối, chưa implement — `EmergencyPage.jsx`
9. **Thiếu sticky header cho table** — UC029 Usability yêu cầu "sticky header khi scroll" nhưng `EmergencyTable.jsx` thead không có `position: sticky` CSS

## 🔧 ĐIỂM CẦN CẢI THIỆN

1. **[HIGH]** Implement export CSV/PDF → Cách sửa: Tạo `GET /api/v1/emergencies/export?format=csv&from=&to=` endpoint trong backend, thêm logic CSV/PDF generation dùng `csv-stringify` hoặc `pdfkit`; wire "Xuất báo cáo" button trong `EmergencyToolbar.jsx`
2. **[HIGH]** Thêm date range filter → Cách sửa: Thêm date picker (from/to) vào `EmergencyToolbar.jsx`, truyền tham số `from/to` qua `getHistoryEvents` API query params, thêm `where: { triggered_at: { gte, lte } }` trong service
3. **[HIGH]** Thêm audit log cho xem chi tiết (BR-029-05) → Cách sửa: Thêm `audit_logs.create({ action: 'admin.emergency.view_detail', ... })` vào `getEventDetails` trong service hoặc controller
4. **[MEDIUM]** Tách `getEventDetails` → Cách sửa: Extract `buildTimeline(event)`, `fetchVitalsSnapshot(eventId)`, `fetchEmergencyContacts(userId)` thành private helper functions
5. **[MEDIUM]** Thêm connection loss warning → Cách sửa: Wrap fetch trong try/catch, set state `isDisconnected`, hiển thị banner warning khi fetch liên tục fail
6. **[MEDIUM]** Dùng PATCH thay PUT cho status update → Cách sửa: Đổi `router.put` → `router.patch` tại `emergency.routes.js:L27`, cập nhật frontend `emergencyService.js` method
7. **[LOW]** Thêm sticky header cho table → Cách sửa: Thêm `className="sticky top-0 z-10"` cho thead trong `EmergencyTable.jsx:L46`
8. **[LOW]** Tách repository layer → Cách sửa: Tạo `emergency.repository.js` chứa Prisma queries, service chỉ gọi repository methods

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Nút "Xuất báo cáo" rỗng** — `EmergencyToolbar.jsx:L80-L83` — Nút hiển thị nhưng không hoạt động tạo confusion cho user. Nên ẩn hoặc disable cho đến khi implement xong feature

## ⚠️ SAI LỆCH VỚI JIRA / SRS

| Source  | Mô tả sai lệch                                          | Mức độ | Đề xuất                                                  |
| ------- | -------------------------------------------------------- | ------ | -------------------------------------------------------- |
| UC029   | Flow 5.e (Xuất báo cáo CSV/PDF) chưa implement          | 🔴     | Implement backend export endpoint + wire frontend button  |
| UC029   | Flow 5.d thiếu date range filter                         | 🟡     | Thêm from/to date picker vào toolbar                     |
| BR-029-05 | Thiếu audit log cho xem chi tiết sự cố                 | 🟡     | Thêm audit_logs.create vào getEventDetails               |
| UC029   | Reliability: Thiếu connection loss warning               | 🟡     | Implement reconnection banner UI                          |
| UC029   | Usability: Thiếu sticky header                           | 🟢     | CSS fix đơn giản                                          |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt — Status flow enforcement:
```javascript
// file: backend/src/services/emergency.service.js, line 218-227
// BR-029-06: Valid flow active -> responded -> resolved
if (event.status === 'resolved') {
  throw ApiError.badRequest('Sự cố đã được giải quyết, không thể cập nhật thêm');
}
if (event.status === 'active' && status === 'resolved') {
  throw ApiError.badRequest('Sự cố chưa được phản hồi, không thể chuyển đổi trực tiếp sang đã giải quyết');
}
if (event.status === 'responded' && status === 'active') {
  throw ApiError.badRequest('Sự cố đã được phản hồi, không thể lùi trạng thái');
}
```

### ✅ Code tốt — Auto-refresh 15s (BR-029-01):
```javascript
// file: frontend/src/pages/admin/EmergencyPage.jsx, line 79-91
// BR-029-01: Auto-refresh every 15s
useEffect(() => {
  fetchSummary();
  fetchEvents();
  if (activeTab === 'active') {
    const interval = setInterval(() => {
      fetchSummary();
      fetchEvents(true); // silent = no loading indicator → no flicker
    }, 15000);
    return () => clearInterval(interval);
  }
}, [fetchSummary, fetchEvents, activeTab]);
```

### ❌ Code cần sửa — Export button placeholder:
```javascript
// HIỆN TẠI — file: frontend/src/components/emergency/EmergencyToolbar.jsx, line 80-83
<button className="flex items-center gap-2 px-4 py-2.5 ...">
  <Download size={16} />
  Xuất báo cáo
</button>

// NÊN SỬA THÀNH:
<button
  onClick={onExportReport}
  disabled={isExporting}
  className="flex items-center gap-2 px-4 py-2.5 ..."
>
  {isExporting ? <Spinner /> : <Download size={16} />}
  Xuất báo cáo
</button>
```

### ❌ Code cần sửa — PUT → PATCH:
```javascript
// HIỆN TẠI — file: backend/src/routes/emergency.routes.js, line 27
router.put('/:id/status', validate(updateStatusRules), emergencyController.updateEventStatus);

// NÊN SỬA THÀNH:
router.patch('/:id/status', validate(updateStatusRules), emergencyController.updateEventStatus);
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| #   | Action                                        | Owner     | Priority | Sprint     |
| --- | --------------------------------------------- | --------- | -------- | ---------- |
| 1   | Implement export CSV/PDF (UC029 flow 5.e)     | BE + FE   | HIGH     | Sprint 4   |
| 2   | Thêm date range filter (UC029 flow 5.d)       | FE Dev    | HIGH     | Sprint 4   |
| 3   | Thêm audit log cho xem chi tiết (BR-029-05)   | BE Dev    | HIGH     | Sprint 4   |
| 4   | Tách `getEventDetails` thành helper functions  | BE Dev    | MEDIUM   | Sprint 4   |
| 5   | Implement connection loss warning              | FE Dev    | MEDIUM   | Sprint 4   |
| 6   | Đổi PUT → PATCH cho status update              | BE + FE   | MEDIUM   | Sprint 4   |
| 7   | Thêm sticky header cho table                   | FE Dev    | LOW      | Sprint 4   |
| 8   | Tách repository layer (refactor)               | BE Dev    | LOW      | Backlog    |
