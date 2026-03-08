# EP04-Login — Stories

## S01: [Admin BE] API Đăng nhập cho Web Dashboard
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Highest | **Component:** Admin-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST /api/auth/login. Xác thực bcrypt. JWT iss=healthguard-admin role=ADMIN hạn=8h. Rate limit 5 lần/15 phút. Kiểm tra is_active. Cập nhật last_login_at. Ghi audit log.

**Acceptance Criteria:**
- [ ] POST /api/auth/login hoạt động
- [ ] JWT token iss=healthguard-admin, role=ADMIN, hạn=8h
- [ ] Rate limit 5 lần/15 phút
- [ ] Kiểm tra is_active trước khi cho login
- [ ] Cập nhật last_login_at
- [ ] Ghi audit log

---

## S02: [Mobile BE] API Đăng nhập + Refresh Token
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** Highest | **Component:** Mobile-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST /api/auth/login. Xác thực bcrypt. JWT iss=healthguard-mobile roles=PATIENT/CAREGIVER hạn=30 ngày. Cơ chế refresh token. Rate limit 5 lần/15 phút. Ghi audit log.

**Acceptance Criteria:**
- [ ] POST /api/auth/login hoạt động
- [ ] JWT iss=healthguard-mobile, roles=PATIENT/CAREGIVER, hạn=30 ngày
- [ ] Refresh token mechanism
- [ ] Rate limit 5 lần/15 phút
- [ ] Ghi audit log

---

## S03: [Admin FE] Giao diện Đăng nhập Web
- **Assignee:** Admin FE Dev | **SP:** 2 | **Priority:** High | **Component:** Admin-FE
- **Labels:** Frontend, Auth, Sprint-1

**Description:** Trang login React. Validate form. Gọi API. Lưu JWT. Chuyển hướng dashboard. Hiển thị lỗi. Nút ẩn/hiện mật khẩu. Trạng thái loading.

**Acceptance Criteria:**
- [ ] Trang login React hoàn chỉnh
- [ ] Form validation (email + password)
- [ ] Gọi API + lưu JWT
- [ ] Chuyển hướng dashboard sau login
- [ ] Hiển thị lỗi rõ ràng
- [ ] Nút ẩn/hiện mật khẩu
- [ ] Loading state

---

## S04: [Mobile FE] Giao diện Đăng nhập App
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Auth, Sprint-1

**Description:** Màn hình login Flutter. Validate form. Gọi API. Lưu JWT + refresh token (secure storage). Chuyển đến dashboard. Hiển thị lỗi. Loading indicator.

**Acceptance Criteria:**
- [ ] Màn hình login Flutter hoàn chỉnh
- [ ] Form validation
- [ ] Gọi API + lưu JWT + refresh token (secure storage)
- [ ] Chuyển đến dashboard
- [ ] Hiển thị lỗi
- [ ] Loading indicator

---

## S05: [QA] Kiểm thử Đăng nhập Admin & Mobile
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Auth, Sprint-1

**Description:** Test Admin login: JWT 8h. Test Mobile login: JWT 30 ngày + refresh. Test sai mật khẩu. Test rate limiting 6 lần. Test phân quyền đăng nhập theo role.

**Acceptance Criteria:**
- [ ] Admin login: JWT 8h chính xác
- [ ] Mobile login: JWT 30 ngày + refresh token
- [ ] Sai mật khẩu → lỗi rõ ràng
- [ ] Rate limiting: lần thứ 6 bị chặn
- [ ] Phân quyền role đúng

---

## S06: [Mobile BE+FE] Quản lý Hồ sơ & Cập nhật Y tế (UC005)
- **Assignee:** Fullstack Dev | **SP:** 3 | **Priority:** Medium | **Component:** Mobile
- **Labels:** Mobile, Auth, Sprint-1

**Description:** API GET/PUT profile. Các trường dữ liệu y tế: Chiều cao, cân nặng, nhóm máu, dị ứng. **Tính năng XÓA TÀI KHOẢN (Compliance)**: Soft delete user, insert `users_archive`. Có background worker tự dọn dẹp time-series (vitals/motion) sau 30 ngày.

**Acceptance Criteria:**
- [ ] GET /api/users/profile, PUT /api/users/profile
- [ ] Validate dữ liệu chiều cao, cân nặng, SĐT
- [ ] DELETE /api/users/profile (Account Deletion) — Soft delete + Archive
- [ ] Cronjob/Worker dọn dẹp data y tế sau 30 ngày chạy thành công.

---

## S07: [Mobile+Admin] Đăng xuất hệ thống (UC009)
- **Assignee:** Fullstack Dev | **SP:** 1 | **Priority:** Medium | **Component:** Auth
- **Labels:** Auth, Sprint-1

**Description:** Đăng xuất an toàn. Vô hiệu hóa JWT (nếu có blacklist) hoặc xóa Refresh Token dưới DB. Clear local storage/secure storage trên client. Ghi Audit Log.

**Acceptance Criteria:**
- [ ] GET/POST /api/auth/logout gọi thành công
- [ ] Refresh token bị thu hồi ở backend DB
- [ ] Local state/Secure storage frontend bị xóa sạch
- [ ] Audit log ghi nhận hành động đăng xuất
