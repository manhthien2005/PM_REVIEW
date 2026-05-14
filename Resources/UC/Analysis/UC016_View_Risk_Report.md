# UC016 - XEM BÁO CÁO RỦI RO SỨC KHỎE (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** 5 thay đổi lớn match code canonical:
> 1. BR-016-01 cooldown "1 giờ" sang "1 phút" (RISK_COOLDOWN_SECONDS=60 env default).
> 2. Drop auto 6h trigger (code chỉ trigger qua vitals ingest + manual).
> 3. Drop Alt 7.a PDF export (D-AI-01).
> 4. Alt 7.b "Gọi bác sĩ" update note sang SOS flow (UC010).
> 5. Feature importance example xóa số % hardcode, reference dynamic SHAP.
>
> Thêm 3 BR mới response UX anh flag (2026-05-13 chiều):
> - BR-016-05: FE render timestamp + "Tính lại" button + cooldown countdown.
> - BR-016-06: FE render feature_value + direction + reason (schema đã có).
> - BR-016-07: Disclaimer y khoa visible prominent.

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC016 |
| **Tên UC** | Xem báo cáo đánh giá rủi ro sức khỏe |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem báo cáo risk assessment (health/sleep/fall) với score 0-100 + giải thích SHAP + recommendations |
| **Trigger** | (1) User click "Đánh giá rủi ro" trên app (manual), HOẶC (2) Backend tự động tính sau mỗi vitals ingest batch (implicit, cooldown 60s, xem BR-016-01). Auto 6h trigger UC cũ DROPPED. |
| **Tiền điều kiện** | - Đã đăng nhập.<br>- Device đã pair + đang gửi vitals (`vitals` hypertable có row).<br>- User profile cập nhật (age, gender, medical_conditions) để SHAP input đủ. |
| **Hậu điều kiện** | User xem được risk score + level + explanation + recommendations + timestamp cập nhật rõ ràng. |

---

## Kiến trúc tính toán (v2 add, trả lời câu hỏi "tính như thế nào")

### Pipeline 2 tầng

```
IoT vitals tick (1s interval)
        ↓
health_system/backend/services/risk_alert_service.calculate_device_risk()
        ↓
    [Cache check: RISK_COOLDOWN_SECONDS=60s]
        ↓ (cache miss)
    [Build inference payload: vitals + user context]
        ↓
    POST healthguard-model-api /api/v1/health/predict
        ↓
    [LightGBM inference + SHAP explainer]
        ↓ response: prediction_band + prediction_score + top_features + ai_explanation
        ↓
    ModelApiHealthAdapter.from_response()
        ↓ (fallback: from_local_inference nếu model-api down)
    RiskPersistenceAdapter.persist() sang risk_scores + risk_explanations
        ↓
    dispatch_risk_alerts() nếu HIGH/CRITICAL (cross-UC sang NOTIFICATIONS)
        ↓
    FE poll /analysis/risk-reports lấy report list
```

### Split trách nhiệm (WHO)

| Layer | Repo | Trách nhiệm |
|---|---|---|
| ML inference (SHAP raw) | `healthguard-model-api` | LightGBM predict + SHAP compute + template recommendations |
| Orchestration (cooldown, persist, dispatch) | `health_system/backend` | calculate_device_risk + ModelApiHealthAdapter + RiskPersistenceAdapter |
| Display | `health_system/lib` (mobile FE) | Consume `/analysis/risk-reports` + render factors |

Mobile FE không compute gì cả, pure view layer.

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Tab "Phân tích rủi ro" trên app (hoặc vào từ HOME risk insight card). |
| 2 | Client | `GET /mobile/analysis/risk-reports?limit=10&target_profile_id=<id>`. |
| 3 | Hệ thống (BE) | Trả danh sách risk reports gần nhất từ `risk_scores` (tất cả risk_type), LATERAL JOIN với `risk_explanations` để lấy top_factors + recommendations. |
| 4 | Client | Render:<br>- Hero card: score 0-100 + level (LOW/MEDIUM/HIGH/CRITICAL) + màu theo BR-016-03 table<br>- Timestamp "Cập nhật lúc HH:mm (X phút trước)" (BR-016-05)<br>- Button "Tính lại" với cooldown countdown (BR-016-05)<br>- Top 5 factors list với feature_value + direction + reason (BR-016-06)<br>- Recommendations list max 5<br>- 7-day trend mini chart<br>- Disclaimer footer prominent (BR-016-07) |
| 5 | Người dùng | (Optional) Tap 1 report sang UC017 chi tiết, hoặc tap "Tính lại" (manual refresh). |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Đã có assessment trong cooldown 60s

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Client | User tap "Tính lại" trong cooldown window. |
| 2.a.2 | Hệ thống (BE) | `calculate_device_risk(allow_cached=True)` phát hiện cooldown, trả cached result. |
| 2.a.3 | Client | FE disable button + hiển thị "Thử lại sau Xs" countdown. Snackbar "Đã cập nhật gần đây, hiển thị kết quả mới nhất". |

### 3.a - Không đủ dữ liệu (<24h vitals)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống (BE) | `_fetch_latest_vitals` empty hoặc vitals <24h. |
| 3.a.2 | Hệ thống (BE) | Raise ValueError, route catch, return 404 hoặc empty list. |
| 3.a.3 | Client | Render empty state: "Chưa đủ dữ liệu. Vui lòng đeo thiết bị ít nhất 24 giờ." + progress "Đã có X/24h". |

### 4.a - Model-api down

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống (BE) | `get_model_api_client().predict_health_risk()` trả None (breaker open / 5xx / transport). |
| 4.a.2 | Hệ thống (BE) | Fallback `infer_risk()` local rule_based. `inference.backend_label = "rule_based"`. |
| 4.a.3 | Client | Report vẫn render nhưng có badge nhỏ "Fallback mode" (optional UX hint, Phase 5+). |

### 7.b - Critical risk trigger SOS

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 7.b.1 | Người dùng | Level CRITICAL (85-100) hiện banner "Liên hệ hỗ trợ". |
| 7.b.2 | Client | Button cascade sang UC010 SOS trigger flow (trigger_type='manual'). Không phải dial number điện thoại thủ công như UC cũ. |

---

## Business Rules

- **BR-016-01 (cooldown, update v2):** Re-evaluation cooldown `RISK_COOLDOWN_SECONDS = 60` giây (env default, `.env.prod` có thể override). UC cũ nói "1 giờ" là spec drift đã fix.
  - Lý do chọn 60s: Vitals ingest 1s interval, user không thể chờ 1h để thấy risk update. 60s đủ tránh spam compute nhưng responsive cho UX.
  - Phase 5+ revisit nếu production load cao.
- **BR-016-02:** Cần >=24h vitals liên tục (check `_fetch_latest_vitals` raise ValueError nếu empty).
- **BR-016-03 (levels, UC cũ giữ):**

| Mức độ | Điểm | Màu | Khuyến nghị general |
|---|---|---|---|
| LOW | 0-33 | Xanh | Duy trì lối sống |
| MEDIUM | 34-66 | Vàng | Theo dõi, tham khảo bác sĩ |
| HIGH | 67-84 | Cam | Liên hệ bác sĩ sớm |
| CRITICAL | 85-100 | Đỏ | SOS trigger |

- **BR-016-04:** Luôn hiển thị disclaimer "Công cụ hỗ trợ, không thay thế chẩn đoán y khoa".
- **BR-016-05 (UX timestamp + cooldown, new v2):** FE PHẢI render:
  - `timestamp` của report với format "Cập nhật lúc HH:mm (X phút trước)" prominent (không nhỏ/mờ).
  - Button "Tính lại" với state:
    - Idle: enabled, icon refresh.
    - Cooldown: disabled + countdown "Thử lại sau 42s".
    - Loading: spinner + text "Đang phân tích...".
  - Mục đích: User hiểu rõ khi nào hệ thống tính lại, không bị confuse "data tươi hay cũ".
  
- **BR-016-06 (top factors enrichment, new v2):** FE PHẢI render mỗi top factor với 4 thông tin:
  - `label` (VD "Nhịp tim").
  - `feature_value` (VD "120 BPM"), số thực actual từ vitals.
  - `direction` (VD "tăng cao"), hướng bất thường.
  - `reason` (VD "Bình thường: 60-100 BPM"), ngưỡng tham chiếu.
  - `impact` (VD "30%"), SHAP contribution (dynamic, không hardcode).
  - Schema `TopFactorResponse` đã có 5 field này, FE hiện chưa render đủ — Phase 4 task.

- **BR-016-07 (disclaimer visibility, new v2):** Disclaimer y khoa phải:
  - Hiện ở footer mỗi risk report card.
  - Font >=12sp.
  - Không bị ẩn dưới expandable section.
  - Verify trong Phase 4 FE audit.

- **BR-016-08 (trigger sources, new v2 clarify):** UC016 report được tạo bởi 3 trigger:
  - Implicit: sau mỗi vitals ingest batch (dominant, 1 request/60s max do cooldown).
  - Manual: user tap "Tính lại" gọi `POST /mobile/risk/calculate`.
  - Post-event: sau fall confirmed / critical vital alert (bypass cooldown, `allow_cached=False`).
  - KHÔNG có scheduled job 6h như UC cũ claim.

- **BR-016-09 (feature importance source, new v2):** Top factors + impact % dynamic từ SHAP của LightGBM model, KHÔNG phải fixed %. UC cũ example "HR 30%, HRV 25%..." là illustrative only, không phải BR. Actual values per-request.

## Business Rules - Phân quyền

- **BR-Auth-01:** User A xem report User B nếu `user_relationships.can_view_vitals = TRUE` hoặc self.
- **BR-Auth-02:** Clinician audience (`?audience=clinician` + role in CLINICIAN_ROLES) unlock raw SHAP details + model_request_id (UC017 detail).

## Yêu cầu phi chức năng

- **Accuracy** (aspirational, Phase 5+ benchmark): AUC-ROC > 0.85, Sensitivity > 90%. UC cũ claim số này nhưng đồ án 2 chưa có benchmark pipeline verify. Note aspirational, Phase 5+ task.
- **Performance**:
  - `/analysis/risk-reports` < 1s cho 10 items pagination.
  - `calculate_device_risk` với model-api call < 3s P95.
  - Inline trong `/telemetry/ingest` loop, có concern với 100+ devices concurrent (UC006 NFR latency parking).
- **Transparency**:
  - Hiển thị độ tin cậy dự đoán (`confidence` field).
  - Giải thích ngôn ngữ đơn giản (BR-017-03).
- **Privacy**: Không chia sẻ bên thứ 3.

---

## Dropped features (UC cũ drop trong v2)

- Alt 7.a "Tải báo cáo PDF": Drop (D-AI-01). Admin web HealthGuard đã có export. Mobile = view-only.
- Auto 6h trigger: Drop. Code không có scheduled job. Implicit ingest trigger đủ.
- Feature importance hardcode %: Drop example "HR 30%, HRV 25%...". Reference dynamic SHAP output.
- Alt 7.b dial phone number: Drop direct phone dial. Redirect cascade SOS UC010.

---

## Implementation references

### Code paths

Backend orchestration:
- `health_system/backend/app/services/risk_alert_service.py`:
  - `calculate_device_risk()` line 320-420, orchestrator
  - `_try_cached_risk_result()` line 425-460, cooldown logic (`RISK_COOLDOWN_SECONDS`)
  - `dispatch_risk_alerts()` line 233+, HIGH/CRITICAL push
- `health_system/backend/app/adapters/model_api_health_adapter.py`:
  - `from_response()`, model-api output sang NormalizedExplanation
  - `from_local_inference()`, fallback rule_based
  - `to_record()`, vitals + context sang model-api input
- `health_system/backend/app/adapters/risk_persistence_adapter.py`:
  - `persist()`, NormalizedExplanation sang risk_scores + risk_explanations

Backend routes:
- `health_system/backend/app/api/routes/risk.py`, `POST /risk/calculate`
- `health_system/backend/app/api/routes/monitoring.py`, `GET /analysis/risk-reports`, `GET /risk-reports/{id}`, `GET /risk-history`

Model API:
- `healthguard-model-api/app/routers/health.py`, `POST /api/v1/health/predict`
- `healthguard-model-api/app/services/health_service.py`, LightGBM + SHAP + template recommendations

Mobile FE:
- `health_system/lib/features/analysis/presentation/screens/risk_report_screen.dart`, list
- `health_system/lib/features/analysis/presentation/screens/risk_report_detail_screen.dart`, detail
- `health_system/lib/features/analysis/presentation/screens/risk_history_screen.dart`, history
- `health_system/lib/features/analysis/presentation/screens/risk_shap_detail_screen.dart`, SHAP waterfall

### Schemas

- `health_system/backend/app/schemas/monitoring.py`, `RiskReportResponse`, `RiskReportDetailResponse`, `TopFactorResponse`, `FactorBreakdownResponse`, `AiExplanationResponse`
- `healthguard-model-api/app/schemas/health.py`, `HealthPredictionRequest/Response`

### DB

- `risk_scores` table, main result store
- `risk_explanations` table, SHAP breakdown + recommendations
- ENV: `RISK_COOLDOWN_SECONDS=60` (`.env.prod` có thể override)

### Related UCs

- UC008 (risk history list)
- UC010 (SOS trigger từ critical, cascade)
- UC017 (report detail với breakdown + SHAP + recommendations)
- UC006 (vitals ingest precondition)
