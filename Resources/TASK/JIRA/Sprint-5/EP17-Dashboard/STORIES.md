# EP17-Dashboard — Stories

## S01: [Admin BE] API Dashboard Analytics
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** High | **Component:** Admin-BE
- **Labels:** Backend, Dashboard, Sprint-5

**Description:** GET /api/admin/dashboard. Trả về thống kê tổng hợp KPIs, xu hướng 7 ngày, danh sách 5 sự cố mới nhất và 5 bệnh nhân rủi ro cao. Khai thác dữ liệu từ các view `vitals_daily`, `vitals_hourly`.

**Acceptance Criteria:**
- [ ] GET /api/admin/dashboard hoạt động
- [ ] Trả về đúng schema KPIs (Tổng Users, Devices, Alerts, SOS, Risk High/Critical)
- [ ] Truy vấn danh sách sự cố gần nhất và bệnh nhân cần chú ý hợp lệ
- [ ] Ghi audit log với action `admin.view_dashboard`

---

## S02: [Admin FE] Giao diện Dashboard tổng quan
- **Assignee:** Admin FE Dev | **SP:** 5 | **Priority:** High | **Component:** Admin-FE
- **Labels:** Frontend, Dashboard, Sprint-5

**Description:** Thiết kế và tích hợp giao diện màn hình Dashboard. Hiển thị KPI cards, biểu đồ xu hướng (bar, pie, line charts), bảng Sự cố gần đây và Bệnh nhân cần chú ý.

**Acceptance Criteria:**
- [ ] Giao diện KPI cards hiển thị đúng số liệu
- [ ] Render 3 loại biểu đồ theo dữ liệu API
- [ ] Hỗ trợ thay đổi khoảng thời gian lọc (bộ lọc time range)
- [ ] Drill-down navigation: Click vào dòng sự cố/bệnh nhân để chuyển trang
- [ ] Auto-refresh mỗi 60 giây theo rule BR-027-01

---

## S03: [QA] Kiểm thử Dashboard
- **Assignee:** QA Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Dashboard, Sprint-5

**Description:** Kiểm thử đầy đủ chức năng và giao diện của màn hình Dashboard, kiểm tra API performance theo chuẩn dưới 2 giây.

**Acceptance Criteria:**
- [ ] Dashboard load lần đầu < 2 giây
- [ ] Biểu đồ vẽ đúng theo số lượng trả về
- [ ] Quyền truy cập: Chỉ Admin mới có thể xem (các role khác bị chặn 403)
- [ ] Auto-refresh hoạt động ổn định không crash
---
