# EP09-FallDetect — Stories

## S01: [AI] Xây dựng Mô hình Phát hiện Té ngã
- **Assignee:** AI Dev | **SP:** 3 | **Priority:** High | **Component:** AI-Models
- **Labels:** AI, Emergency, Sprint-3

**Description:** Dịch vụ AI Fall Detection. Input: cửa sổ motion_data 6 giây 50Hz = 300 mẫu. Output: xác suất té ngã + độ tin cậy. Ngưỡng > 0.85 kích hoạt. Giải thích XAI timeline.

**Acceptance Criteria:**
- [ ] Model nhận input motion_data 6s/50Hz = 300 samples
- [ ] Output: probability + confidence
- [ ] Threshold > 0.85 trigger alert
- [ ] XAI timeline explanation

---

## S02: [Mobile BE] Tích hợp AI + API Sự kiện Té ngã
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Emergency, Sprint-3

**Description:** Dữ liệu chuyển động → kích hoạt AI suy luận. Phát hiện té ngã → tạo bản ghi fall_events. POST xác nhận (an toàn). POST kích hoạt SOS (tự động sau 30s). Tạo cảnh báo + push FCM.

**Acceptance Criteria:**
- [ ] Motion data → AI inference trigger
- [ ] Fall detected → create fall_events record
- [ ] POST confirm safe
- [ ] Auto SOS after 30s no response
- [ ] Push notification via FCM

---

## S03: [Mobile FE] Giao diện Cảnh báo Té ngã (Đếm ngược + Nút)
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Emergency, Sprint-3

**Description:** Cảnh báo toàn màn hình: đếm ngược 30s. Nút TÔI KHÔNG SAO + GỌI CỨU HỘ. Lắng nghe push notification. Rung + âm thanh cảnh báo.

**Acceptance Criteria:**
- [ ] Full-screen alert with 30s countdown
- [ ] Nút "TÔI KHÔNG SAO" + "GỌI CỨU HỘ"
- [ ] Push notification listener
- [ ] Vibration + alert sound

---

## S04: [QA] Kiểm thử Phát hiện Té ngã End-to-End
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Emergency, Sprint-3

**Description:** Test: Phát hiện té ngã → Cảnh báo → Xác nhận an toàn → Huỷ. Test: Không phản hồi 30s → Tự động SOS. Test ngưỡng AI. Test push notification.

**Acceptance Criteria:**
- [ ] Fall detect → alert → confirm safe → cancel
- [ ] No response 30s → auto SOS
- [ ] AI threshold testing
- [ ] Push notification delivery
