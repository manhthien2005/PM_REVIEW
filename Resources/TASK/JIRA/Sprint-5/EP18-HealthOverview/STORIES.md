# EP18-HealthOverview — Stories

## S01: [Admin BE] API Lấy danh sách bệnh nhân rủi ro & cảnh báo
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** High | **Component:** Admin-BE
- **Labels:** Backend, Monitoring, Sprint-5

**Description:** GET /api/admin/health-overview/alerts và GET /api/admin/health-overview/risks. Trả về danh sách cảnh báo vi phạm ngưỡng 24h và phân bố Risk Scores. Query bắt buộc sử dụng `vitals_5min`, `vitals_hourly`, `vitals_daily` và không truy vấn `vitals` raw.

**Acceptance Criteria:**
- [ ] Phân biệt rõ các mức độ cảnh báo (LOW, MEDIUM, HIGH, CRITICAL)
- [ ] Trả về danh sách bệnh nhân dựa theo logic `vitals_hourly/daily`
- [ ] Trả về đủ các field phục vụ Chart và danh sách
- [ ] Lọc được theo điều kiện (Chỉ số, mức độ, Risk Level)
- [ ] Ghi audit log khi truy cập chi tiết bệnh nhân (`admin.view_patient_health`)

---

## S02: [Admin FE] Giao diện Giám sát sức khỏe & Đánh giá rủi ro
- **Assignee:** Admin FE Dev | **SP:** 5 | **Priority:** High | **Component:** Admin-FE
- **Labels:** Frontend, Monitoring, Sprint-5

**Description:** Xây dựng giao diện với 2 tab: Cảnh báo ngưỡng và Phân bố Risk. Hiển thị Summary cards, biểu đồ Donut cho phân bố Risk và Trend Vitals (Line chart). Tích hợp chức năng lọc dữ liệu.

**Acceptance Criteria:**
- [ ] Chuyển đổi qua lại giữa các Tabs mượt mà
- [ ] Hiển thị đủ Summary Cards và Biểu đồ
- [ ] Filter theo Loại chỉ số, Mức độ, Thời gian, Risk Level hoạt động chuẩn xác
- [ ] Drill-down màn hình chi tiết sức khỏe bệnh nhân khi click vào table row
- [ ] Color coding chính xác cho mức độ cảnh báo: Xanh/Vàng/Cam/Đỏ

---

## S03: [Admin BE] API Xuất CSV danh sách cảnh báo
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Admin-BE
- **Labels:** Backend, Export, Sprint-5

**Description:** GET /api/admin/health-overview/export. Xuất dữ liệu trả về theo định dạng CSV để người dùng có thể tải về.

**Acceptance Criteria:**
- [ ] API trả về file CSV hợp lệ
- [ ] File tải về áp dụng đúng bộ lọc như hiện tại trên FE
- [ ] Encode UTF-8, Header Cột rõ ràng (Bệnh nhân, Chỉ số, Thời gian, Mức độ)

---

## S04: [QA] Kiểm thử Giám sát sức khỏe
- **Assignee:** QA Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Monitoring, Sprint-5

**Description:** Thực hiện kiểm thử toàn bộ tính năng liên quan đến hiển thị và filter sức khỏe tổng quan. Kiểm tra query performance và khả năng export.

**Acceptance Criteria:**
- [ ] API Performance < 2 giây với dataset có phân trang (20 items/page)
- [ ] Export file tải về kiểm tra cấu trúc cột
- [ ] Kiểm chứng biểu đồ vẽ đúng với time frame chọn lọc
---
