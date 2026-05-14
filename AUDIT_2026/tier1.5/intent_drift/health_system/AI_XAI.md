# Intent Drift Review — `health_system / AI_XAI` (v2)

**Status:** ✅ Confirmed Phase 0.5 v2 (2026-05-13 chiều) — deep verification rewrite, 1 CRITICAL + 4 drift + 3 UX BR mới
**Repo:** `health_system/backend` (orchestration) + `healthguard-model-api` (inference) + `health_system/lib` (display)
**Module:** AI/XAI (ML risk inference + explainability + recommendations)
**Related UCs:** UC016 v2 View Risk Report, UC017 v2 View Risk Report Detail
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13

---

## 🎯 Mục tiêu v2

Rewrite v1 (3 Q) sau khi anh flag 2 vấn đề UX lớn:
1. "Không biết khi nào hệ thống tính risk", UX timing poor.
2. "Giải thích + recommendations kém", XAI shallow.

Deep-verify phát hiện:
- 1 CRITICAL spec drift: BR-016-01 cooldown UC cũ "1 giờ" vs code `RISK_COOLDOWN_SECONDS=60` (60x drift).
- 4 drift MISS v1: auto 6h trigger không có code, AUC NFR aspirational, feature % hardcode misleading, caregiver notify verify defer.
- 3 BR UX mới trả lời câu hỏi anh: timestamp/countdown UX, top factors enrichment, disclaimer visibility.

v2 rewrite UC016 v2 full, UC017 v2 minor update, AI_XAI.md v2 comprehensive.

---

## 📚 UC cũ summary (deprecated post-v2)

### UC016 v1 DEPRECATED
- Cooldown 1h (BR-016-01), auto 6h trigger, PDF export, feature % hardcode, call doctor phone dial.

### UC017 v1 DEPRECATED
- Basic snapshot detail, BR-017-03 explanation natural language (vague source).

---

## 🔧 Code state — verified deep

### Pipeline 2-tier architecture

```
[IoT sim vitals tick 1s]
        ↓
[health_system/backend /telemetry/ingest] (require_internal_service)
        ↓ inline loop per device
[risk_alert_service.calculate_device_risk(allow_cached=True, dispatch_alerts=True)]
        ↓
[_try_cached_risk_result] (RISK_COOLDOWN_SECONDS=60s default)
        ↓ (cache miss)
[load_device_owner_context] sang vitals_row + context (age/gender/medical)
        ↓
[_build_inference_payload + ModelApiHealthAdapter.to_record]
        ↓
[ModelApiClient.predict_health_risk] (breaker-wrapped httpx)
        ↓ POST
[healthguard-model-api /api/v1/health/predict]
        ↓ [LightGBM inference + SHAP]
[HealthPredictionResponse: prediction_band + prediction_score + top_features + ai_explanation]
        ↓ return
[ModelApiHealthAdapter.from_response sang NormalizedExplanation]
        ↓ (fallback: from_local_inference với infer_risk rule_based nếu model-api down)
[RiskPersistenceAdapter.persist sang risk_scores + risk_explanations]
        ↓
[dispatch_risk_alerts if HIGH/CRITICAL] (cross-UC sang NOTIFICATIONS)
        ↓
[FE GET /analysis/risk-reports list + risk-reports/{id} detail]
```

### Split responsibilities (WHERE)

| Khâu | Repo | File | Đóng góp gì |
|---|---|---|---|
| **Tính raw score + SHAP** | `healthguard-model-api` | `routers/health.py`, `services/health_service.py` | LightGBM + SHAP explainer, template recommendations Vietnamese per band |
| **Cooldown + persist** | `health_system/backend` | `services/risk_alert_service.py` | Quyết định khi nào gọi model-api (cooldown 60s), persist DB |
| **Adapter normalize** | `health_system/backend` | `adapters/model_api_health_adapter.py` | Shape model-api response thành NormalizedExplanation + fallback |
| **Dispatch alert** | `health_system/backend` | `services/risk_alert_service.dispatch_risk_alerts()` + `push_notification_service.py` | Push FCM tới user + caregiver (cross-UC Notifications) |
| **Display** | `health_system/lib` | `features/analysis/presentation/screens/*.dart` | Consume `/analysis/risk-reports` + render cards + factors + recommendations |

Mobile FE không tính gì cả, pure view layer. Mọi logic nằm ở BE + model-api.

### Code files verified

**health_system/backend:**
- `services/risk_alert_service.py`:
  - `RISK_COOLDOWN_SECONDS = int(os.getenv("RISK_COOLDOWN_SECONDS", "60"))` line 30
  - `calculate_device_risk()` line 320-420 orchestrator
  - `_try_cached_risk_result()` line 425-470 cooldown check
  - `dispatch_risk_alerts()` line 233+ push caregiver
- `adapters/model_api_health_adapter.py`, from_response + from_local_inference + to_record
- `adapters/risk_persistence_adapter.py`, persist sang risk_scores + risk_explanations
- `services/model_api_client.py`, predict_health_risk + predict_fall + predict_sleep (3 breakers độc lập)
- `api/routes/risk.py`, POST /risk/calculate (manual trigger)
- `api/routes/monitoring.py`, GET /analysis/risk-reports, /risk-reports/{id}, /risk-history

**healthguard-model-api:**
- `routers/health.py`, POST /api/v1/health/predict
- `services/health_service.py`, LightGBM predict + SHAP + recommendations template
- `schemas/health.py`, HealthPredictionRequest/Response

**Mobile FE:**
- `lib/features/analysis/presentation/screens/risk_report_screen.dart`, list
- `lib/features/analysis/presentation/screens/risk_report_detail_screen.dart`, detail
- `lib/features/analysis/presentation/screens/risk_history_screen.dart`, history với filter type
- `lib/features/analysis/presentation/screens/risk_shap_detail_screen.dart`, SHAP waterfall (clinician)

### Cooldown verified

```python
# risk_alert_service.py line 30
RISK_COOLDOWN_SECONDS = int(os.getenv("RISK_COOLDOWN_SECONDS", "60"))

# _try_cached_risk_result line 425-470
last_calc = db.query(func.max(RiskScore.calculated_at))...
elapsed = (get_current_time() - last_calc).total_seconds()
if elapsed >= RISK_COOLDOWN_SECONDS:
    return None  # cache expired, recompute
# else return cached result
```

`.env.prod`: không set explicit, dùng default 60s. README.md:114 ghi `RISK_COOLDOWN_SECONDS=60` là example.

---

## 🚨 Drift findings v2 (verified)

### A. Claim đúng từ v1 (6)

1. ✅ `ModelApiClient` 3 predict methods + per-endpoint breakers.
2. ✅ 5 adapter files + orchestration layer.
3. ✅ Calculate_device_risk orchestrator verified.
4. ✅ 4 FE screens active.
5. ✅ Audience gate clinician (`require_clinician_audience`).
6. ✅ Fallback rule_based khi model-api down.

### B. Claim SAI CRITICAL (1)

#### 🚨 B.1 CRITICAL: BR-016-01 "Cooldown 1 giờ" SAI, thực tế 60 giây (1 phút)

v1 Q2/D-AI-02 chỉ là "verify TTL", không phát hiện drift factual.

Evidence:
- `risk_alert_service.py:30`: `RISK_COOLDOWN_SECONDS = int(os.getenv("RISK_COOLDOWN_SECONDS", "60"))`
- README `health_system/README.md:114`: `RISK_COOLDOWN_SECONDS=60`
- Test `test_e2e_risk_notification.py:92`: disable via `RISK_COOLDOWN_SECONDS=0`

60x drift (3600s vs 60s) giữa UC spec và code canonical.

Hệ quả UX:
- User đọc UC expect "1h cooldown" nhưng backend recalc mỗi 60s, compute load cao hơn dự kiến.
- Tuy nhiên 60s thực tế phù hợp cho UX (user không thể chờ 1h), nên fix = update UC v2 match code.

Fix: UC016 v2 BR-016-01 update "60s canonical". AI_XAI.md v2 decision D-AI-01.

### C. Drift MISS v1 (4)

#### C.1 🟠 HIGH: Caregiver notification dispatch chưa verify

UC016 BR-016-03: "HIGH/CRITICAL thì thông báo người giám sát."

v1 không verify code path `dispatch_risk_alerts` gọi `PushNotificationService.send_risk_push_alerts` có:
- Resolve caregiver list qua `user_relationships` (where `can_receive_alerts=TRUE`)?
- Dedup recipients?
- Handle offline caregivers (FCM retry)?

Fix v2: Defer sang NOTIFICATIONS module deep-verify session. AI_XAI.md v2 parking flag.

#### C.2 🟡 MEDIUM: UC016 "Accuracy AUC-ROC >0.85, Sensitivity >90%" aspirational

UC016 NFR khẳng định threshold accuracy nhưng:
- Đồ án 2 scope không có benchmark pipeline.
- Không có test verify model performance met threshold.
- SRS số liệu từ research paper, không phải kết quả thật.

Fix v2: UC016 v2 note aspirational, Phase 5+ benchmark.

#### C.3 🟡 MEDIUM: Auto 6h trigger KHÔNG tồn tại trong code

UC016 v1 Trigger: "Hệ thống tự động đánh giá mỗi 6 giờ."

Thực tế:
- Grep `6 hour|cron|schedule|APScheduler` trong `risk_alert_service.py` trả 0 match.
- `calculate_device_risk()` chỉ trigger qua vitals ingest loop + manual `/risk/calculate` + post-fall snapshot.

Fix v2: UC016 v2 drop auto 6h. Trigger field update "(1) manual (2) implicit post-ingest (3) post-event bypass cooldown".

#### C.4 🟡 MEDIUM: Feature importance %: UC cũ hardcode

UC016 example "HR 30%, HRV 25%, SpO2 20%..." là illustrative, không phải BR. SHAP values dynamic per-request từ LightGBM.

Fix v2: UC016 v2 drop hardcode example, reference dynamic SHAP. Add BR-016-09 clarify.

### D. UX BR mới (3), trả lời câu hỏi anh

#### D.1 BR-016-05: FE timestamp + "Tính lại" button + countdown UX

Anh hỏi: "User không biết khi nào hệ thống tính."

Fix: UC016 v2 BR-016-05 mandate FE render:
- `timestamp` prominent "Cập nhật lúc HH:mm (X phút trước)".
- Button "Tính lại" với state machine: idle / cooldown (disabled + countdown) / loading (spinner).
- Không ẩn timestamp dưới expandable.

Phase 4 FE task ~2h.

#### D.2 BR-016-06: Top factors enrichment

Anh hỏi: "User không biết tính dựa vào đâu."

Code schema `TopFactorResponse` đã có 5 field:
- `key` (internal identifier)
- `label` (display name VD "Nhịp tim")
- `impact` (SHAP %)
- `direction` (VD "tăng cao", "dưới ngưỡng")
- `reason` (VD "Bình thường: 60-100 BPM")
- `feature_value` (VD "120 BPM")

FE hiện chưa render đủ 5 field (chỉ label + impact %). Phase 4 FE enrich.

Fix: UC016 v2 BR-016-06 + UC017 v2 (inherit) mandate FE render 5 field.

#### D.3 BR-016-07: Disclaimer visibility

Anh hỏi: "Giải thích kém."

UC cũ BR-016-04 đã có "công cụ hỗ trợ, không thay thế chẩn đoán" nhưng:
- FE có render không? Font size, position?
- Có bị ẩn dưới collapsible?

Fix: UC016 v2 BR-016-07 mandate:
- Footer mỗi risk card.
- Font >=12sp.
- Không ẩn dưới expandable.

Phase 4 FE audit.

---

## 🎯 Anh's decisions Phase 0.5 v2

Anh chọn "theo em default" (2026-05-13 chiều):

| ID | Item | Decision | Phase 4 effort |
|---|---|---|---|
| D-AI-01 (v1 carry) | PDF export | Drop UC016 Alt 7.a | 0h (doc) |
| D-AI-02 (v1 carry, updated) | Cooldown | Update UC BR-016-01 "60s" (not "1h"), SAI drift fix | 0h (doc) |
| D-AI-03 (v1 carry) | Call doctor | SOS UC010 cascade | 0h (doc) |
| **D-AI-04 new** | Auto 6h trigger | Drop UC016 claim | 0h (doc) |
| **D-AI-05 new** | AUC NFR aspirational | UC016 note Phase 5+ | 0h (doc) |
| **D-AI-06 new** | Feature % hardcode | Drop UC example, dynamic SHAP | 0h (doc) |
| **D-AI-07 new** | FE timestamp + cooldown UX | UC016 BR-016-05 new | **~2h Phase 4 FE** |
| **D-AI-08 new** | FE top factors enrichment | UC016 BR-016-06 + UC017 inherit | **~1h Phase 4 FE** |
| **D-AI-09 new** | Disclaimer visibility audit | UC016 BR-016-07 | ~30min Phase 4 FE audit |
| **D-AI-10 new** | Explanation source hierarchy | UC017 BR-017-03/05 clarify | 0h (doc) |
| **D-AI-11 parking** | Caregiver notify verify | Defer NOTIFICATIONS module | N/A session khác |
| **D-AI-12 parking** | SHAP-driven personalized recommendations | Phase 5+ (thay template band) | N/A Phase 5+ |

### Phase 4 total

| Task | Effort |
|---|---|
| D-AI-07: FE timestamp + countdown UX | ~2h |
| D-AI-08: FE top factors enrichment | ~1h |
| D-AI-09: Disclaimer visibility audit + fix | ~30min |
| Doc updates UC016 + UC017 | ~45min (Phase 0.5 now) |

Estimated Phase 4 code effort: ~3h30min (FE only, không touch BE/model-api).

---

## 📊 UC delta v2

| UC cũ | Status v2 | v2 changes |
|---|---|---|
| UC016 View Risk Report | **Overwrite** | Cooldown 60s, drop auto 6h trigger, drop PDF, drop phone dial, drop feature % hardcode. Add pipeline architecture section. Add BR-016-05/06/07/08/09 UX + trigger source + feature source clarify. |
| UC017 View Detail | **Minor update** | Add BR-017-03 explanation source hierarchy, BR-017-05 recommendations hierarchy, BR-017-06 clinician audience fields. Core flow không đổi. |

---

## 🆕 Industry standard add-ons — drop

- ❌ Share risk report qua social, Privacy concern, Phase 5+
- ❌ Export PDF mobile, D-AI-01 drop, admin đã có
- ❌ Scheduled 6h trigger, D-AI-04 drop, implicit ingest đủ
- ❌ Custom risk threshold per user, Phase 5+

---

## 📝 Anh's decisions log v2

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-AI-01 | PDF export | Drop | Admin đã có; mobile view-only |
| D-AI-02 | Cooldown spec | Update 60s canonical | Code canonical; 1h quá aggressive UX |
| D-AI-03 | Call doctor | SOS UC010 cascade | UC010 already covers emergency |
| D-AI-04 | Auto 6h | Drop | Code không có scheduled job |
| D-AI-05 | AUC NFR | Aspirational | Đồ án 2 không có benchmark |
| D-AI-06 | Feature % hardcode | Dynamic SHAP | LightGBM per-request |
| **D-AI-07** | FE UX timestamp | BR-016-05 mandate | User không biết khi nào tính, anh flag |
| **D-AI-08** | FE top factors enrich | BR-016-06 mandate | User không biết tính dựa vào đâu, anh flag |
| **D-AI-09** | Disclaimer visibility | BR-016-07 verify | Medical compliance |
| **D-AI-10** | Explanation source | BR-017-03/05 hierarchy | Dev transparency model-api vs adapter vs rule_based |
| **D-AI-11** | Caregiver notify | Parking NOTIFICATIONS | Scope module khác |
| **D-AI-12** | SHAP personalized | Parking Phase 5+ | Template đủ đồ án 2 |

### Add-ons dropped

| Add-on | Decision |
|---|---|
| Share social | ❌ Drop Privacy |
| Export PDF mobile | ❌ Drop (D-AI-01) |
| Scheduled 6h | ❌ Drop (D-AI-04) |
| Custom threshold | ❌ Drop Phase 5+ |

---

## Cross-references

### UC v2 (committed Phase 0.5 chiều)

- `PM_REVIEW/Resources/UC/Analysis/UC016_View_Risk_Report.md`, v2 overwrite
- `PM_REVIEW/Resources/UC/Analysis/UC017_View_Risk_Report_Detail.md`, v2 minor update

### Code paths (Phase 4)

**Mobile FE (D-AI-07/08/09):**
- `lib/features/analysis/presentation/screens/risk_report_screen.dart`, timestamp + countdown button
- `lib/features/analysis/presentation/screens/risk_report_detail_screen.dart`, top factors enrichment + disclaimer
- `lib/features/analysis/providers/risk_provider.dart` (nếu chưa có, tạo), cooldown state machine

**Backend (no change):**
- `services/risk_alert_service.py`, cooldown 60s OK
- `adapters/*.py`, OK
- `routes/risk.py` + `routes/monitoring.py`, OK

**Model-api (no change):**
- `routers/health.py`, OK
- `services/health_service.py`, template recommendations OK cho đồ án 2; Phase 5+ enhance SHAP-driven personalized

### Schemas (no change)

- `RiskReportResponse`, `RiskReportDetailResponse`, `TopFactorResponse`, đã có 5 field, FE chỉ cần render
- `RiskReportClinicianResponse`, audience gate

### DB (no change)

- `risk_scores` + `risk_explanations` tables
- ENV `RISK_COOLDOWN_SECONDS=60` default

### Related bugs

- Không tạo bug mới, tất cả fix là doc alignment + FE UX enhancement. Phase 4 tạo JIRA story cho FE UX fix (D-AI-07/08/09).

### Related ADR

- Không tạo ADR, no architectural change, chỉ spec align + UX mandate.

### Related UCs

- UC006 (vitals ingest precondition)
- UC008 (risk history cascade)
- UC010 (SOS trigger cascade từ critical)
- UC017 (detail screen)
- NOTIFICATIONS module (caregiver dispatch, D-AI-11 parking)

---

## Changelog

| Version | Date | Note |
|---|---|---|
| v1 | 2026-05-13 sáng | 3 Q drift review (D-AI-01/02/03) |
| v2 | 2026-05-13 chiều | Deep verify: fix D-AI-02 CRITICAL (60s not 1h), add D-AI-04/05/06 drift miss, add D-AI-07/08/09 UX BR mới (trả lời anh câu UX + XAI), parking D-AI-11/12 |
