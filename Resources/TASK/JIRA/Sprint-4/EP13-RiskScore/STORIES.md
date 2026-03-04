# EP13-RiskScore — Stories

## S01: [AI] Xây dựng Mô hình Chấm điểm Rủi ro (XGBoost + SHAP)
- **Assignee:** AI Dev | **SP:** 5 | **Priority:** Medium | **Component:** AI-Models
- **Labels:** AI, Analysis, Sprint-4

**Description:** Mô hình XGBoost: 22 features (HRV HR BP SpO2 nhân khẩu học). Output: điểm 0-100 + mức. Trích xuất đặc trưng từ vitals 24h. SHAP explainer top 5 yếu tố. Lịch trình chạy mỗi 6h.

**Acceptance Criteria:**
- [ ] XGBoost model với 22 features
- [ ] Output: score 0-100 + level (LOW/MED/HIGH/CRITICAL)
- [ ] Feature extraction từ vitals 24h
- [ ] SHAP top 5 factors
- [ ] Schedule chạy mỗi 6h

---

## S02: [Mobile BE] API Điểm Rủi ro (Mới nhất + Lịch sử)
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-BE
- **Labels:** Backend, Analysis, Sprint-4

**Description:** GET điểm rủi ro mới nhất. Logic cache: điểm < 1h trả cached ngược lại gọi AI. GET lịch sử điểm rủi ro. Phân quyền. Nếu HIGH/CRITICAL → tạo cảnh báo.

**Acceptance Criteria:**
- [ ] GET latest risk score
- [ ] Cache logic: < 1h → cached, else → call AI
- [ ] GET risk score history
- [ ] Permission check patient/caregiver
- [ ] HIGH/CRITICAL → create alert

---

## S03: [Mobile FE] Giao diện Báo cáo Rủi ro
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-FE
- **Labels:** Mobile, Analysis, Sprint-4

**Description:** Màn hình báo cáo rủi ro: điểm 0-100 đồng hồ đo có màu. Phần XAI (top 5 yếu tố). Biểu đồ xu hướng. Chi tiết: trực quan hoá tầm quan trọng đặc trưng.

**Acceptance Criteria:**
- [ ] Gauge widget 0-100 with color
- [ ] XAI section: top 5 factors
- [ ] Trend chart
- [ ] Feature importance visualization

---

## S04: [QA] Kiểm thử Chấm điểm Rủi ro
- **Assignee:** Tester | **SP:** 2 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Analysis, Sprint-4

**Description:** Test tính toán điểm rủi ro. Test logic cache. Test cảnh báo khi HIGH/CRITICAL. Test lịch sử. Test phân quyền bệnh nhân vs người chăm sóc.

**Acceptance Criteria:**
- [ ] Risk score calculation correct
- [ ] Cache logic works
- [ ] Alert on HIGH/CRITICAL
- [ ] History displays correctly
- [ ] Permission check patient vs caregiver
