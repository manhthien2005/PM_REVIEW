# EP16-AdminConfig — Stories

## S01: [Admin BE] API Cài đặt Hệ thống + Logs
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Low | **Component:** Admin-BE
- **Labels:** Backend, Admin, Sprint-4

**Description:** GET/PUT /api/admin/settings (ngưỡng sinh tồn cấu hình AI cài đặt thông báo chính sách lưu trữ). GET /api/admin/logs (lọc phân trang). Xuất CSV. Tải cài đặt vào cache.

**Acceptance Criteria:**
- [ ] GET/PUT /api/admin/settings
- [ ] Settings: vital thresholds, AI config, notification, retention
- [ ] GET /api/admin/logs (filter + pagination)
- [ ] Export CSV
- [ ] Settings loaded into cache

---

## S02: [Admin FE] Trang Cài đặt + Trang Logs
- **Assignee:** Admin FE Dev | **SP:** 2 | **Priority:** Low | **Component:** Admin-FE
- **Labels:** Frontend, Admin, Sprint-4

**Description:** Trang Cài đặt Hệ thống: form cho ngưỡng + cấu hình + lưu. Trang System Logs: bảng lọc khoảng ngày. Nút Xuất CSV.

**Acceptance Criteria:**
- [ ] Settings page: threshold + config forms + save
- [ ] System Logs page: table with date range filter
- [ ] Export CSV button

---

## S03: [QA] Kiểm thử Cài đặt & Logs
- **Assignee:** Tester | **SP:** 1 | **Priority:** Low | **Component:** QA
- **Labels:** Test, Admin, Sprint-4

**Description:** Test cập nhật và áp dụng cài đặt. Test hiển thị logs lọc. Test xuất CSV.

**Acceptance Criteria:**
- [ ] Settings update + apply ok
- [ ] Logs display with filters ok
- [ ] CSV export ok
