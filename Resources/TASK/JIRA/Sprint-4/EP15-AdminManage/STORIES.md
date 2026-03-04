# EP15-AdminManage — Stories

## S01: [Admin BE] API CRUD Người dùng
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** Medium | **Component:** Admin-BE
- **Labels:** Backend, Admin, Sprint-4

**Description:** GET /api/admin/users (danh sách tìm kiếm lọc phân trang). POST tạo. GET chi tiết. PUT cập nhật. DELETE xoá mềm. POST khoá/mở khoá. Phân quyền ADMIN. Ghi audit log.

**Acceptance Criteria:**
- [ ] GET /api/admin/users (list + search + filter + pagination)
- [ ] POST create user
- [ ] GET user detail
- [ ] PUT update user
- [ ] DELETE soft delete
- [ ] POST lock/unlock
- [ ] ADMIN permission required
- [ ] Audit log

---

## S02: [Admin BE] API CRUD Thiết bị
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Admin-BE
- **Labels:** Backend, Admin, Sprint-4

**Description:** GET /api/admin/devices (danh sách). GET chi tiết. PUT cập nhật. POST gán cho user. POST khoá/mở khoá. Phân quyền ADMIN.

**Acceptance Criteria:**
- [ ] GET /api/admin/devices (list)
- [ ] GET device detail
- [ ] PUT update device
- [ ] POST assign to user
- [ ] POST lock/unlock
- [ ] ADMIN permission required

---

## S03: [Admin FE] Trang Quản lý Người dùng
- **Assignee:** Admin FE Dev | **SP:** 3 | **Priority:** Medium | **Component:** Admin-FE
- **Labels:** Frontend, Admin, Sprint-4

**Description:** Trang Quản lý Users: bảng tìm kiếm lọc phân trang. Modal Thêm/Sửa user. Xác nhận Xoá. Nút Khoá/Mở khoá.

**Acceptance Criteria:**
- [ ] Users table with search + filter + pagination
- [ ] Add/Edit user modal
- [ ] Delete confirmation
- [ ] Lock/Unlock button

---

## S04: [Admin FE] Trang Quản lý Thiết bị
- **Assignee:** Admin FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Admin-FE
- **Labels:** Frontend, Admin, Sprint-4

**Description:** Trang Quản lý Devices: bảng tìm kiếm lọc. Chi tiết thiết bị. Gán cho user. Khoá/Mở khoá.

**Acceptance Criteria:**
- [ ] Devices table with search + filter
- [ ] Device detail view
- [ ] Assign to user
- [ ] Lock/Unlock

---

## S05: [QA] Kiểm thử CRUD Admin Users & Devices
- **Assignee:** Tester | **SP:** 2 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Admin, Sprint-4

**Description:** Test CRUD users: danh sách tìm kiếm lọc phân trang tạo sửa xoá khoá. Test CRUD devices: danh sách cập nhật gán khoá. Test phân quyền ADMIN. Test audit logs.

**Acceptance Criteria:**
- [ ] Users CRUD: list/search/filter/paginate/create/edit/delete/lock
- [ ] Devices CRUD: list/update/assign/lock
- [ ] ADMIN permission enforced
- [ ] Audit logs recorded correctly
