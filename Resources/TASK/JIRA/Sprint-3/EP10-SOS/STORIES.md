# EP10-SOS — Stories

## S01: [Mobile BE] API SOS Thủ công + Huỷ + Phản hồi + Xử lý
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Emergency, Sprint-3

**Description:** POST kích hoạt SOS (device_id toạ độ). Lấy danh bạ khẩn cấp theo thứ tự ưu tiên. Gửi push + SMS. POST huỷ (trong 5 phút). GET SOS đang hoạt động. POST phản hồi. POST giải quyết.

**Acceptance Criteria:**
- [ ] POST trigger SOS (device_id + GPS)
- [ ] Lấy emergency contacts theo priority
- [ ] Gửi push + SMS
- [ ] POST cancel (within 5 min)
- [ ] GET active SOS
- [ ] POST acknowledge + POST resolve

---

## S02: [Mobile FE] Nút SOS + Giao diện Chế độ Khẩn cấp
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Emergency, Sprint-3

**Description:** Nút SOS (lớn đỏ) giữ 3s. Lấy GPS. Màn hình chế độ khẩn cấp + đếm ngược huỷ. Thông báo SOS + chi tiết (thông tin bệnh nhân bản đồ GPS). Nút Đã nhận + Đã giải quyết.

**Acceptance Criteria:**
- [ ] Nút SOS lớn đỏ, giữ 3s để kích hoạt
- [ ] Lấy GPS location
- [ ] Emergency mode screen + cancel countdown
- [ ] SOS notification + patient info + map
- [ ] Nút "Đã nhận" + "Đã giải quyết"

---

## S03: [QA] Kiểm thử Luồng SOS End-to-End
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Emergency, Sprint-3

**Description:** Test toàn bộ luồng SOS. Test huỷ trong 5 phút. Test gửi push + SMS. Test nhận SOS xác nhận giải quyết. Test với nhiều người chăm sóc.

**Acceptance Criteria:**
- [ ] Full SOS flow end-to-end
- [ ] Cancel within 5 min ok
- [ ] Push + SMS delivery
- [ ] Acknowledge + resolve flow
- [ ] Multiple caregivers scenario
