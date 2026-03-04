# EP14-Sleep — Stories

## S01: [AI] Xây dựng Thuật toán Phân tích Giấc ngủ
- **Assignee:** AI Dev | **SP:** 3 | **Priority:** Medium | **Component:** AI-Models
- **Labels:** AI, Sleep, Sprint-4

**Description:** Phân tích giấc ngủ: Input HR HRV motion_data cửa sổ 8-10h. Phát hiện giai đoạn Thức/Nông/Sâu/REM. Tính thời lượng hiệu suất điểm chất lượng. Chạy mỗi sáng.

**Acceptance Criteria:**
- [ ] Input: HR + HRV + motion_data (8-10h window)
- [ ] Stage detection: Awake/Light/Deep/REM
- [ ] Calculate: duration, efficiency, quality score
- [ ] Schedule: run every morning

---

## S02: [Mobile BE] API Báo cáo Giấc ngủ (Mới nhất + Lịch sử)
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-BE
- **Labels:** Backend, Sleep, Sprint-4

**Description:** GET phiên giấc ngủ mới nhất. GET lịch sử giấc ngủ (từ/đến). Tạo bảng sleep_sessions nếu chưa có. Triển khai dịch vụ phân tích (gọi thuật toán AI).

**Acceptance Criteria:**
- [ ] GET latest sleep session
- [ ] GET sleep history (from/to)
- [ ] sleep_sessions table created
- [ ] Analysis service calls AI algorithm

---

## S03: [Mobile FE] Giao diện Báo cáo Giấc ngủ
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-FE
- **Labels:** Mobile, Sleep, Sprint-4

**Description:** Màn hình báo cáo giấc ngủ: biểu đồ timeline giai đoạn. Hiển thị thời lượng hiệu suất điểm chất lượng. Lịch sử với lịch.

**Acceptance Criteria:**
- [ ] Stage timeline chart
- [ ] Duration + efficiency + quality score display
- [ ] History with calendar view

---

## S04: [QA] Kiểm thử Phân tích Giấc ngủ
- **Assignee:** Tester | **SP:** 1 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Sleep, Sprint-4

**Description:** Test kết quả phân tích giấc ngủ. Test phát hiện giai đoạn. Test lịch sử. Test lịch trình chạy hàng ngày.

**Acceptance Criteria:**
- [ ] Sleep analysis results correct
- [ ] Stage detection accuracy
- [ ] History display ok
- [ ] Daily schedule runs
