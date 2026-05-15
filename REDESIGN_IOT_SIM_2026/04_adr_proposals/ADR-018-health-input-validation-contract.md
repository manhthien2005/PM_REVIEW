# ADR-018: Health Input Validation Contract — Fail-Closed with Synthetic Flag

**Status:** � Approved (Redesign 2026-05-15)
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [validation, contract, cross-repo, mobile, model-api, bug-fix]
**Resolves:** HS-024, XR-003

## Context

Audit 2026-05-13/14 phát hiện 2 bug critical liên quan input validation cho health risk inference:

**HS-024 (Mobile BE):**
- `risk_alert_service._build_inference_payload` silently fill default cho NULL vitals fields (HR=75, SpO2=98, BP=120/80)
- `defaults_applied` chỉ track 5/9 field — 4 critical fields (HR, SpO2, RR, body_temp) dùng `or` literal pattern KHÔNG track
- `_fetch_latest_vitals` chỉ reject khi CẢ HR+SpO2 NULL (per-field check missing)
- Drift giữa 2 adapter layer: HRV default Layer 1 = 40, Layer 2 = 50

**XR-003 (Model-api):**
- `VitalsRecord` Pydantic schema không có `Field(ge=, le=)` constraints
- Out-of-range values pass validation
- Không có `is_synthetic_default` flag để consumer biết input quality
- Error response 422 generic "Missing required keys", không có structured error code

**Combined impact:** Mobile app hiển thị "Sức khỏe ổn định" với risk_score = 0.3 trong khi backend thực sự fill default cho HR/SpO2 NULL → **risk score giả mạo**, nguy hiểm cho người cao tuổi vì che giấu vital signs bất thường.

**Forces:**
- Medical-grade app → fail-closed > silent degrade
- IoT sim với real datasets sinh vitals đầy đủ (ít trigger HS-024), nhưng smartwatch thật có thể intermittent
- Mobile UX phải cảnh báo nếu data quality thấp (không deceive user)
- Cross-repo coordination: mobile BE + model-api + mobile FE đều phải đổi

**References:**
- [Bug HS-024](../../BUGS/HS-024-risk-inference-silent-default-fill.md)
- [Bug XR-003](../../BUGS/XR-003-model-api-input-validation-contract.md)
- [Contract risk_trigger.md](../03_data_contracts/risk_trigger.md)
- UC016 View Risk Report BR-016-02 (≥24h vitals required)

## Decision

**Chose:** Option A — Fail-closed for critical fields + Synthetic flag for soft fields.

**Why:**
1. **Medical-grade safety:** Critical fields (HR, SpO2, RR, body_temp) NULL → reject với 422 `INSUFFICIENT_VITALS`. Không deceive user bằng default fake.
2. **Continuity preserved:** Soft fields (BP, HRV, weight, height) MAY default với flag `is_synthetic_default=true` để user biết.
3. **Cross-repo aligned:** Mobile BE, model-api, mobile FE đều dùng cùng vocabulary `is_synthetic_default` + `defaults_applied`.
4. **Match user expectation:** "Sức khỏe đánh giá chính xác nếu đeo thiết bị đầy đủ" — fail-closed làm rõ điều này.

## Options considered

### Option A (CHOSEN): Fail-closed critical + synthetic flag soft

**Description:**
- Critical fields (HR, SpO2, RR, body_temp): MUST NOT default. NULL → raise `InsufficientVitalsError` → 422 `INSUFFICIENT_VITALS`
- Soft fields (BP_sys, BP_dia, HRV, weight, height): MAY default với tracking `defaults_applied[field]=true`
- Model-api schema add `Field(ge=, le=)` cho mọi vital field
- Model-api response include `is_synthetic_default`, `effective_confidence` (= confidence × 0.5 if synthetic), `data_quality_warning`
- Mobile UX: render warning banner orange "Một số chỉ số được ước tính"

**Pros:**
- Medical-grade safety
- Honest UX (không lừa user)
- Cross-repo formalize contract
- Resolve both HS-024 + XR-003 dứt điểm
- Backward compat: existing client không truyền flag → default `is_synthetic_default=false` (no breaking)

**Cons:**
- UX có thể "frustrating" khi sensor loi tạm thời (user phải đeo 5 phút thêm)
- Cần update 4 file across 3 repo: BE service + adapter, model-api schema, mobile parser + UI

**Effort:** L (~12-16h):
- 2h: ADR review + contract finalize (this doc)
- 3h: Model-api schema update + tests + error codes
- 4h: Mobile BE service refactor + DB migration risk_scores columns
- 3h: Mobile FE parser + UI warning banner
- 2-4h: E2E tests cross-repo

### Option B (rejected): Degrade-with-flag only (no fail-closed)

**Description:** Vẫn fill default cho mọi field, NHƯNG push `is_synthetic_default=true` + warning banner. KHÔNG raise error.

**Pros:**
- UX smooth (no rejection)
- Continuity với sensor loi tạm thời

**Cons:**
- User vẫn nhận risk score → confused về độ tin cậy
- Critical field (HR=null → default 75) là deception, không phải degrade
- Không match medical-grade discipline

**Why rejected:** Critical fields default = lying to user về sức khỏe. Không acceptable cho elderly app.

### Option C (rejected): Reject everything if any field missing

**Description:** Strict — bất kỳ vitals/profile field NULL → reject.

**Pros:**
- Simplest logic
- 100% data integrity

**Cons:**
- Quá strict: user chưa nhập height/weight (soft fields) → không có risk eval forever
- UX painful: BP cuff không đeo → reject
- Real-world sensor có gaps cho field optional → reject hết → app useless

**Why rejected:** YAGNI strict — distinction critical vs soft đủ tốt.

### Option D (rejected): Server-side ML imputation (fill predicted defaults)

**Description:** ML model predict missing field từ available fields (e.g., predict HR từ SpO2 + activity).

**Pros:**
- Sophisticated, modern
- No rejection needed

**Cons:**
- Add ML pipeline complexity cho missing data
- Imputation error compound với prediction error
- Out-of-scope đồ án (em không retrain model)

**Why rejected:** YAGNI, không phải scope.

## Consequences

### Positive
- HS-024 + XR-003 fixed dứt điểm
- Medical-grade discipline established cho cross-repo contract
- Mobile UX honest về data quality
- Audit trail rõ ràng (`defaults_applied` log per record)
- Pattern reusable cho fall/sleep contract sau này

### Negative / Trade-offs accepted
- UX rejection khi sensor loi (user phải đeo thêm)
- 12-16h effort across 3 repo
- DB migration thêm 4 column trong `risk_scores`
- Mobile app version bump (consumer breaking change)

### Follow-up actions required
- [ ] Phase 7 slice 1: Model-api `Field(ge=, le=)` + error codes
- [ ] Phase 7 slice 2: Mobile BE `risk_alert_service` refactor + DB migration
- [ ] Phase 7 slice 3: Mobile FE `RiskReportEntity` parser + warning banner UI
- [ ] Phase 7 slice 4: E2E test cross-repo
- [ ] Phase 7 slice 5: Update UC016 BR-016-02 (vitals completeness rule)
- [ ] Update bug HS-024 + XR-003 → ✅ Resolved

## Reverse decision triggers

- Nếu UX feedback nghiêm trọng (panel chấm phản đối fail-closed) → consider Option B downgrade
- Nếu cross-repo coordination quá phức tạp → phase migration: model-api first, BE later, mobile last
- Nếu medical regulation force strict (GDPR/HIPAA-equiv) → consider Option C

## Related

- ADR-019: IoT sim no direct model-api (related — same predicate validation)
- ADR-022: IMU window persistence (related — fail-closed pattern)
- Bug HS-024, XR-003
- Contract risk_trigger.md (canonical fix spec)
- UC016 View Risk Report
- File `health_system/backend/app/services/risk_alert_service.py:89-201`
- File `health_system/backend/app/adapters/model_api_health_adapter.py:51-90`
- File `healthguard-model-api/app/schemas/health.py`
- File `health_system/lib/features/analysis/repositories/risk_analysis_repository.dart`

## Notes

### Defaults_applied JSON schema

```json
{
  "heart_rate": false,
  "spo2": false,
  "blood_pressure_sys": true,
  "blood_pressure_dia": true,
  "temperature": false,
  "hrv": false,
  "respiratory_rate": false,
  "weight_kg": true,
  "height_cm": true
}
```

### Mobile UX warning banner copy (VI)

- **Soft default only:** "Một số chỉ số ({fields}) được ước tính. Đeo thiết bị đầy đủ để có đánh giá chính xác hơn."
- **Critical missing (rejected):** "Cần thêm dữ liệu sức khỏe — vui lòng đeo thiết bị 5 phút nữa rồi thử lại."
- **Backend offline (degraded):** "Đánh giá dựa trên dữ liệu cũ (cached). Đang cập nhật..."

### Backward compatibility migration

Phase 7 deploy order:
1. Model-api (add Optional `is_synthetic_default` field — old clients default False)
2. Mobile BE (start sending flag — old model-api versions ignore it)
3. Mobile FE (start consuming flag — old BE responses default to no warning)

Each step backward-compat, no big-bang deploy.
