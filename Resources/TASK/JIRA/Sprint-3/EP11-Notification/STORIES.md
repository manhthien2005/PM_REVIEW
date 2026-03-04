# EP11-Notification — Stories

## S01: [Mobile BE] CRUD Liên hệ Khẩn cấp + API Thông báo
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** Medium | **Component:** Mobile-BE
- **Labels:** Backend, Notification, Sprint-3

**Description:** CRUD API danh bạ khẩn cấp. Validate SĐT. Ưu tiên 1-5. GET danh sách cảnh báo (lọc theo loại/mức độ/chưa đọc). POST đánh dấu đã đọc. GET/PUT cài đặt thông báo.

**Acceptance Criteria:**
- [ ] CRUD emergency contacts
- [ ] Phone number validation
- [ ] Priority 1-5
- [ ] GET alerts (filter: type/severity/unread)
- [ ] POST mark as read
- [ ] GET/PUT notification settings

---

## S02: [Mobile FE] Giao diện Danh bạ Khẩn cấp & Trung tâm Thông báo
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-FE
- **Labels:** Mobile, Notification, Sprint-3

**Description:** Danh bạ khẩn cấp (Cài đặt): danh sách ưu tiên thêm/sửa/xoá. Trung tâm thông báo: danh sách lọc. Cài đặt thông báo.

**Acceptance Criteria:**
- [ ] Emergency contacts list with priority ordering
- [ ] Add/edit/delete contacts
- [ ] Notification center with filters
- [ ] Notification settings page

---

## S03: [QA] Kiểm thử Thông báo & Danh bạ
- **Assignee:** Tester | **SP:** 1 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Notification, Sprint-3

**Description:** Test CRUD danh bạ. Test sắp xếp ưu tiên. Test validate SĐT. Test trung tâm thông báo lọc. Test cập nhật cài đặt.

**Acceptance Criteria:**
- [ ] CRUD contacts ok
- [ ] Priority ordering ok
- [ ] Phone validation ok
- [ ] Notification center filters
- [ ] Settings update ok
