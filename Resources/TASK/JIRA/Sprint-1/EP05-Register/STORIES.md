# EP05-Register — Stories

## S01: [Admin BE] API Tạo User (Admin tạo)
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** High | **Component:** Admin-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST /api/users (yêu cầu ADMIN JWT). Validate email duy nhất. Bcrypt hash. Tạo user is_verified=true. Xử lý lỗi.

**Acceptance Criteria:**
- [ ] POST /api/users yêu cầu ADMIN JWT
- [ ] Validate email unique
- [ ] Bcrypt hash password
- [ ] User tạo với is_verified=true
- [ ] Xử lý lỗi (email trùng, thiếu field)

---

## S02: [Mobile BE] API Tự Đăng ký
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST /api/auth/register. Validate email + mật khẩu tối thiểu 6 ký tự. Bcrypt hash. Tạo user is_verified=false. Gửi email xác thực (mock trong dev).

**Acceptance Criteria:**
- [ ] POST /api/auth/register hoạt động
- [ ] Validate email + password >= 6 ký tự
- [ ] User tạo với is_verified=false
- [ ] Mock email xác thực

---

## S03: [Admin FE] Giao diện Thêm User (Modal)
- **Assignee:** Admin FE Dev | **SP:** 1 | **Priority:** High | **Component:** Admin-FE
- **Labels:** Frontend, Auth, Sprint-1

**Description:** Modal Thêm User trong Admin Dashboard. Form: email mật khẩu họ tên SĐT ngày sinh vai trò. Gọi API POST /api/users. Xử lý lỗi.

**Acceptance Criteria:**
- [ ] Modal thêm user hoàn chỉnh
- [ ] Form fields: email, password, name, phone, DOB, role
- [ ] Gọi API POST /api/users
- [ ] Xử lý lỗi hiển thị rõ ràng

---

## S04: [Mobile FE] Giao diện Đăng ký
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Auth, Sprint-1

**Description:** Màn hình đăng ký Flutter. Validate form. Gọi API. Thông báo thành công + chuyển đến login. Checkbox điều khoản sử dụng.

**Acceptance Criteria:**
- [ ] Màn hình đăng ký Flutter hoàn chỉnh
- [ ] Form validation
- [ ] Thông báo thành công → chuyển đến login
- [ ] Checkbox điều khoản sử dụng

---

## S05: [QA] Kiểm thử Đăng ký Admin & Mobile
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Auth, Sprint-1

**Description:** Test Admin tạo user: chỉ role ADMIN. Test Mobile đăng ký: email trùng → lỗi. Test mật khẩu yếu. Test checkbox điều khoản.

**Acceptance Criteria:**
- [ ] Admin tạo user: chỉ ADMIN role được phép
- [ ] Mobile đăng ký: email trùng → lỗi
- [ ] Mật khẩu yếu → reject
- [ ] Checkbox điều khoản bắt buộc
