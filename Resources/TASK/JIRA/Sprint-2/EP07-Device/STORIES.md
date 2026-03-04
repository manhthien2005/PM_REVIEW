# EP07-Device — Stories

## S01: [Mobile BE] API Đăng ký/Danh sách/Huỷ/Trạng thái Thiết bị
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Device, Sprint-2

**Description:** POST register device. GET danh sách devices. POST unbind. GET status (pin tín hiệu last_seen). Logic online/offline (last_seen < 5 phút).

**Acceptance Criteria:**
- [ ] POST register device hoạt động
- [ ] GET danh sách devices
- [ ] POST unbind device
- [ ] GET device status (pin, tín hiệu, last_seen)
- [ ] Logic online/offline (last_seen < 5 phút)

---

## S02: [Mobile FE] Giao diện Kết nối & Danh sách Thiết bị
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Device, Sprint-2

**Description:** Màn hình kết nối thiết bị (quét QR hoặc nhập tay). Danh sách thiết bị. Thẻ trạng thái (pin tín hiệu online/offline). Tự làm mới 30s. Huỷ kết nối.

**Acceptance Criteria:**
- [ ] Kết nối thiết bị (QR scan hoặc manual)
- [ ] Danh sách thiết bị với thẻ trạng thái
- [ ] Auto refresh mỗi 30s
- [ ] Huỷ kết nối thiết bị

---

## S03: [QA] Kiểm thử Đăng ký & Trạng thái Thiết bị
- **Assignee:** Tester | **SP:** 1 | **Priority:** High | **Component:** QA
- **Labels:** Test, Device, Sprint-2

**Description:** Test luồng đăng ký thiết bị. Test danh sách + huỷ kết nối. Test với nhiều thiết bị. Test phát hiện offline.

**Acceptance Criteria:**
- [ ] Luồng đăng ký thiết bị ok
- [ ] Danh sách + huỷ kết nối ok
- [ ] Nhiều thiết bị cùng user ok
- [ ] Phát hiện offline chính xác

---

## S04: [Mobile BE] API Cấu hình Thiết bị (UC041)
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-BE
- **Labels:** Backend, Device, Sprint-2

**Description:** GET /api/mobile/devices/{id}/config (lấy cấu hình hiện tại). PUT /api/mobile/devices/{id}/config (cập nhật). Validate giá trị. Gửi lệnh config xuống thiết bị. Xử lý pending sync khi offline. Ghi log.

**Acceptance Criteria:**
- [ ] GET config hoạt động
- [ ] PUT config cập nhật thành công
- [ ] Validate giá trị (tần suất >= ngưỡng)
- [ ] Pending sync khi thiết bị offline
- [ ] Ghi log action=device.config.updated

---

## S05: [Mobile FE] Giao diện Cài đặt Thiết bị (UC041)
- **Assignee:** Mobile FE Dev | **SP:** 1 | **Priority:** Medium | **Component:** Mobile-FE
- **Labels:** Mobile, Device, Sprint-2

**Description:** Màn hình Cài đặt thiết bị: tần suất gửi dữ liệu, bật/tắt rung cảnh báo, bật/tắt theo dõi giấc ngủ. Nhóm Cơ bản/Nâng cao. Validate + nút Lưu. Hiển thị pending sync.

**Acceptance Criteria:**
- [ ] Màn hình cài đặt thiết bị hoàn chỉnh
- [ ] Nhóm Cơ bản/Nâng cao
- [ ] Validate + Lưu
- [ ] Hiển thị pending sync status

---

## S06: [QA] Kiểm thử Cấu hình Thiết bị (UC041)
- **Assignee:** Tester | **SP:** 1 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Device, Sprint-2

**Description:** Test thay đổi cấu hình + lưu thành công. Test validate giá trị ngoài phạm vi. Test pending sync khi thiết bị offline. Test ghi log.

**Acceptance Criteria:**
- [ ] Thay đổi cấu hình + lưu ok
- [ ] Validate reject giá trị ngoài phạm vi
- [ ] Pending sync khi offline ok
- [ ] Log ghi chính xác
