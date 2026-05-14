# UC017 - XEM CHI TIẾT BÁO CÁO RỦI RO SỨC KHỎE (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Minor update với 3 BR mới clarify pipeline:
> - BR-017-03 clarify explanation source (model-api SHAP template + adapter fallback hierarchy).
> - BR-017-05 recommendations source hierarchy.
> - BR-017-06 clinician audience additional fields (raw SHAP + model_request_id).
>
> Core flow không đổi vì code đã aligned với UC v1.

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC017 |
| **Tên UC** | Xem chi tiết báo cáo đánh giá rủi ro |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc, Clinician (role-based, Phase 5) |
| **Mô tả** | User xem chi tiết 1 risk assessment cụ thể với top factors + explanation + recommendations + SHAP breakdown |
| **Trigger** | Tap 1 report trong UC016 list hoặc risk history (UC008). |
| **Tiền điều kiện** | - Đã tồn tại ít nhất 1 risk_scores row cho patient.<br>- User có quyền xem (`can_view_vitals` hoặc self hoặc clinician role). |
| **Hậu điều kiện** | User hiểu rõ nguyên nhân risk level + action cần làm. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Từ UC016 hoặc UC008, tap 1 report. |
| 2 | Client | `GET /mobile/analysis/risk-reports/{id}?target_profile_id=<id>&audience=<patient or clinician>`. |
| 3 | Hệ thống (BE) | Audience gate: nếu `clinician` query param + user role in CLINICIAN_ROLES thì trả `RiskReportClinicianResponse` (có shap_details + model_request_id). Otherwise trả `RiskReportDetailResponse` (patient, lean). |
| 4 | Client | Render detail screen:<br>- Score + level với màu (BR-017-02)<br>- Timestamp evaluation<br>- Breakdown 5-7 factors với feature_value + direction + reason + impact % (BR-016-06 inherit)<br>- explanation text (ngôn ngữ tự nhiên, BR-017-03)<br>- Recommendations list (max 5, BR-017-04)<br>- Snapshot vitals tại thời điểm evaluation<br>- Trend 7d mini<br>- Disclaimer y khoa footer<br>- (Clinician only) SHAP waterfall link + model_request_id |
| 5 | Người dùng | (Optional) Tap "Xem lịch sử rủi ro tương tự" sang UC008 filter by risk_type. |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Risk explanation row missing (legacy data)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống (BE) | `risk_explanations` không có row cho `risk_score_id`. |
| 2.a.2 | Hệ thống (BE) | Return 404 hoặc return report với `top_factors=[]`, `breakdown=[]`, `recommendations=[]`. |
| 2.a.3 | Client | Render báo cáo tối giản chỉ với score + level + timestamp + message "Chưa có dữ liệu giải thích chi tiết cho lần đánh giá này". |

### 3.a - Caregiver xem báo cáo patient

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Caregiver | Từ access profile chọn patient thì risk report list. |
| 3.a.2 | Hệ thống (BE) | `get_target_profile_id` verify `user_relationships.can_view_vitals = TRUE`. |
| 3.a.3 | Hệ thống (BE) | Nếu không permit: 403 Forbidden. |

### 4.a - Clinician audience gate

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Clinician user | Gọi endpoint với `?audience=clinician`. |
| 4.a.2 | Hệ thống (BE) | `require_clinician_audience` check user role in CLINICIAN_ROLES. Nếu không: 403. |
| 4.a.3 | Hệ thống (BE) | Return `RiskReportClinicianResponse` kế thừa `RiskReportDetailResponse` + `shap_details` (raw waterfall) + `model_request_id` (upstream log correlation). |

---

## Business Rules

- **BR-017-01:** Dữ liệu detail là snapshot đúng thời điểm evaluation (dựa vào `features` lưu trong `risk_scores.features`), KHÔNG tính lại theo vitals hiện tại. User xem lại report cũ thấy đúng context khi đó.

- **BR-017-02:** Level HIGH/CRITICAL phải hiển thị cảnh báo nổi bật (màu cam/đỏ, icon cảnh báo).

- **BR-017-03 (explanation source, clarify v2):** `explanation_text` có thứ tự ưu tiên nguồn:
  1. Model-api `ai_explanation.short_text` (primary, generated từ SHAP + template Vietnamese).
  2. Adapter fallback text nếu model-api trả empty: `f"Mô hình risk dự báo score {score}/100 (nguy cơ ở mức {risk_level})."`
  3. Local `infer_risk()` rule_based nếu model-api down hoàn toàn (generic Vietnamese per band).
  Ngôn ngữ tự nhiên, tránh thuật ngữ kỹ thuật (VD "HRV thấp" thay vì "Heart rate variability standard deviation dropped below 25th percentile").

- **BR-017-04:** Recommendations max 5 items. Mỗi item gạch đầu dòng.

- **BR-017-05 (recommendations source, clarify v2):** Thứ tự ưu tiên:
  1. Model-api `ai_explanation.recommended_actions` (template theo risk_level band).
  2. Adapter `_default_recommendations(risk_level)` fallback (hardcode Vietnamese per level trong `model_api_health_adapter.py`).
  3. Rule_based local nếu fallback trigger.
  Phase 5+ enhance: SHAP-driven personalized actions thay vì template band (VD "HR cao 120 BPM thì giảm hoạt động 30 phút" thay vì "Theo dõi thêm").

- **BR-017-06 (clinician audience fields, new v2):** Clinician response thêm:
  - `shap_details`: raw SHAP waterfall (base_value + per-feature contributions JSON).
  - `model_request_id`: upstream model-api log correlation ID.
  - Mục đích: Clinician investigate false positive / false negative, correlate với model deployment version.
  - Patient response KHÔNG có 2 field này (lean + không gây confusion).

## Business Rules - Phân quyền

- **BR-Auth-01:** Caregiver xem nếu `can_view_vitals = TRUE` trong `user_relationships`.
- **BR-Auth-02:** Clinician audience qua `?audience=clinician` + role in CLINICIAN_ROLES.

## Yêu cầu phi chức năng

- **Transparency**: Luôn hiển thị "Công cụ hỗ trợ, không thay thế chẩn đoán y khoa" (BR-016-04 inherit + BR-016-07).
- **Performance**: Detail load < 1 giây (data đã có trong DB, không tính lại).
- **Privacy**: Share/export Phase 5+ (admin web đã có, mobile drop D-AI-01).

---

## Implementation references

### Code paths

Backend:
- `health_system/backend/app/api/routes/monitoring.py`, `get_risk_report_detail` (audience switch)
- `health_system/backend/app/services/monitoring_service.py`, `get_risk_report_detail` + `get_risk_report_clinician_detail`
- `health_system/backend/app/core/audience.py`, `require_clinician_audience` + `CLINICIAN_ROLES`

Schemas:
- `health_system/backend/app/schemas/monitoring.py`, `RiskReportDetailResponse` (patient) + `RiskReportClinicianResponse` (subclass)

Mobile FE:
- `health_system/lib/features/analysis/presentation/screens/risk_report_detail_screen.dart`, main detail
- `health_system/lib/features/analysis/presentation/screens/risk_shap_detail_screen.dart`, SHAP waterfall (clinician only route)

### Related UCs

- UC016 (list entry point, inherited BR-016-05/06/07 UX rules)
- UC008 (risk history entry)
