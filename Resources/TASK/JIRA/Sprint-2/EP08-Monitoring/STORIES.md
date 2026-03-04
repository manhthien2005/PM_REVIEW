# EP08-Monitoring — Stories

## S01: [Mobile BE] API Chỉ số Sức khoẻ (Mới nhất + Chi tiết + Lịch sử)
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Monitoring, Sprint-2

**Description:** GET vital-signs mới nhất. GET chi tiết từng chỉ số (min max avg std). GET lịch sử (ngày/tuần/tháng). Cảnh báo ngưỡng. Phân quyền bệnh nhân/người chăm sóc. Logic is_stale.

**Acceptance Criteria:**
- [ ] GET vital-signs mới nhất
- [ ] GET chi tiết (min/max/avg/std)
- [ ] GET lịch sử (ngày/tuần/tháng)
- [ ] Cảnh báo ngưỡng hoạt động
- [ ] Phân quyền patient/caregiver
- [ ] Logic is_stale

---

## S02: [Mobile FE] Dashboard Chỉ số & Biểu đồ
- **Assignee:** Mobile FE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-FE
- **Labels:** Mobile, Monitoring, Sprint-2

**Description:** Dashboard: Thẻ HR/SpO2/BP/Temp có màu sắc. Biểu đồ đường 1h. Tự làm mới 5s. Chi tiết: thống kê + chọn khoảng thời gian. Lịch sử: lịch + biểu đồ.

**Acceptance Criteria:**
- [ ] Dashboard thẻ HR/SpO2/BP/Temp với color coding
- [ ] Biểu đồ đường 1h
- [ ] Auto refresh 5s
- [ ] Chi tiết: thống kê + time range selector
- [ ] Lịch sử: calendar + chart

---

## S03: [QA] Kiểm thử Hiển thị Chỉ số & Cảnh báo
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Monitoring, Sprint-2

**Description:** Test chỉ số real-time. Test ngưỡng: bình thường(xanh) cảnh báo(vàng) nguy hiểm(đỏ). Test phân quyền bệnh nhân vs người chăm sóc. Test tự làm mới. Test lịch sử.

**Acceptance Criteria:**
- [ ] Real-time chỉ số hiển thị đúng
- [ ] Ngưỡng color: xanh/vàng/đỏ
- [ ] Phân quyền patient vs caregiver
- [ ] Auto refresh hoạt động
- [ ] Lịch sử hiển thị đúng
