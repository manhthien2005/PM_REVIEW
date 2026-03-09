# EP16-AdminConfig — Stories

## S01: [Admin BE] API Cài đặt Hệ thống + Logs
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** High | **Component:** Admin-BE
- **Labels:** Backend, Admin, Sprint-4

**Description:** Xây dựng bảng `system_settings` (JSONB) và API GET/PUT `/api/admin/settings` cho 4 nhóm cấu hình cốt lõi (AI, Notification, Vitals, Security). Yêu cầu middleware check mật khẩu re-auth trước khi cho phép lưu và phải ghi `audit_logs` chi tiết thay đổi. Invalidate cache (Redis) khi settings đổi. Bổ sung API GET `/api/admin/logs` (lọc phân trang) và xuất CSV.

**Acceptance Criteria:**
- [ ] Bảng `system_settings` áp dụng kiểu dữ liệu JSONB
- [ ] GET/PUT `/api/admin/settings` hoạt động (4 nhóm chức năng)
- [ ] Yêu cầu Re-authentication (nhập lại mật khẩu) khi PUT
- [ ] Ghi Audit Logs (old_value, new_value) mỗi khi đổi config
- [ ] GET `/api/admin/logs` (filter + pagination)
- [ ] Worker reload cache cấu hình mới thành công

---

## S02: [Admin FE] Trang Cài đặt + Trang Logs
- **Assignee:** Admin FE Dev | **SP:** 3 | **Priority:** Medium | **Component:** Admin-FE
- **Labels:** Frontend, Admin, Sprint-4

**Description:** Xây dựng màn hình "Cấu hình hệ thống" với 4 tab (AI, Kênh thông báo/Cước phí, Ngưỡng sinh tồn, Bảo trì). Hiển thị Modal yêu cầu nhập mật khẩu xác nhận khi lưu. Tích hợp màn hình System Logs với bảng lọc khoảng khoảng ngày và nút Xuất CSV.

**Acceptance Criteria:**
- [ ] Settings page với 4 Tab (AI, Notification, Vitals, Security)
- [ ] Modal Re-auth popup hiển thị khi nhấn Lưu
- [ ] System Logs page: table có tính năng date range filter
- [ ] Nút Xuất CSV tải file thành công
- [ ] Validate input UI (ranges, boolean)

---

## S03: [QA] Kiểm thử Cài đặt & Logs
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Admin, Sprint-4

**Description:** Test luồng BE+FE lưu settings (JSONB), kiểm thử bảo mật quá trình Re-Auth Password, test auto clear cache background worker. Test khả năng hiển thị logs lọc trên UI và việc xuất dữ liệu CSV.

**Acceptance Criteria:**
- [ ] Test Settings update từ UI xuống DB thành công
- [ ] Verification Re-auth (Nhập sai pass bị chặn, đúng pass mới lưu)
- [ ] Logs display with filters hiển thị đúng dòng logs
- [ ] CSV export file format chuẩn
