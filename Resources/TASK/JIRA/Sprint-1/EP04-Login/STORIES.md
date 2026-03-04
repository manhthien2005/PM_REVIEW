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
