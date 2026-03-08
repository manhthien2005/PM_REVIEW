# EP19-EmergencyMgmt — Stories

## S01: [Admin BE] API Quản lý sự cố khẩn cấp
- **Assignee:** Admin BE Dev | **SP:** 5 | **Priority:** High | **Component:** Admin-BE
- **Labels:** Backend, Emergency, Sprint-5

**Description:** GET /api/admin/emergencies (danh sách), GET /api/admin/emergencies/:id (chi tiết), PATCH /api/admin/emergencies/:id/status (cập nhật trạng thái). Quản lý SOS events và Fall events.

**Acceptance Criteria:**
- [ ] API danh sách sắp xếp theo độ khẩn cấp (urgency) & thời gian
- [ ] Trả về đủ liên kết Timeline, GPS Location, Vitals (từ `alerts.data`) khi xem chi tiết
- [ ] Cập nhật trạng thái tuân thủ luồng: active → responded → resolved
- [ ] Bắt buộc cung cấp notes (ghi chú) khi đổi trạng thái (trả 400 nếu thiếu)
- [ ] Ghi audit log (`admin.contact_emergency` hoặc `admin.update_emergency_status`)

---

## S02: [Admin FE] Giao diện Quản lý sự cố khẩn cấp
- **Assignee:** Admin FE Dev | **SP:** 5 | **Priority:** High | **Component:** Admin-FE
- **Labels:** Frontend, Emergency, Sprint-5

**Description:** Màn hình giám sát SOS realtime với hiệu ứng highlight đỏ nhấp nháy. Mở modal/popup xác nhận khi chuyển Status, yêu cầu field Ghi chú.

**Acceptance Criteria:**
- [ ] Bảng sự cố active auto-refresh 15 giây (incremental)
- [ ] Hiển thị Summary Bar và chia Tab cho "Sự cố đang hoạt động" / "Lịch sử sự cố"
- [ ] Form cập nhật status kèm field [Notes] bắt buộc
- [ ] Hiển thị Timeline sự cố và Bản đồ GPS (nếu có)
- [ ] Hỗ trợ Filter và chức năng xuất báo cáo

---

## S03: [Admin BE] API Xuất báo cáo sự cố & Thống kê
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** Medium | **Component:** Admin-BE
- **Labels:** Backend, Export, Sprint-5

**Description:** GET /api/admin/emergencies/export. Tạo báo cáo CSV thống kê sự cố (thời gian phản hồi TB, tỷ lệ resolved).

**Acceptance Criteria:**
- [ ] API gen CSV theo chuẩn báo cáo
- [ ] Hỗ trợ query theo khoảng thời gian

---

## S04: [Fullstack] Tích hợp tính năng gọi Emergency Contact
- **Assignee:** Fullstack Dev | **SP:** 2 | **Priority:** Medium | **Component:** Fullstack
- **Labels:** Backend, Frontend, Emergency, Sprint-5

**Description:** Hiển thị và ghi log việc liên hệ qua danh bạ ưu tiên `emergency_contacts`. Quản trị viên chỉ cần click ghi nhận "Đã liên hệ".

**Acceptance Criteria:**
- [ ] API lấy danh sách Emergency Contacts theo bệnh nhân
- [ ] Chức năng nút [Đã liên hệ] trên FE
- [ ] Log action thành công vào `audit_logs`

---

## S05: [QA] Kiểm thử Quản lý sự cố khẩn cấp
- **Assignee:** QA Tester | **SP:** 3 | **Priority:** High | **Component:** QA
- **Labels:** Test, Emergency, Sprint-5

**Description:** End-to-end flow từ gửi SOS mô phỏng đến khi xử lý `resolved` trên web để đảm bảo traceability.

**Acceptance Criteria:**
- [ ] Verify luồng chuyển trạng thái không được skip (`active` -> `resolved` phải bị block)
- [ ] Validation field notes phải trigger nếu bỏ trống
- [ ] Realtime refresh đảm bảo không mất event nếu list đang cuộn
---
