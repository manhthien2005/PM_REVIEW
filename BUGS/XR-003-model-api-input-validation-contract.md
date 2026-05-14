# Bug XR-003: Cross-repo contract chua dinh nghia cach handle missing vitals giua mobile BE va model API

**Status:** Open
**Repo(s):** health_system (backend) + healthguard-model-api
**Module:** Cross-service contract
**Severity:** Medium
**Reporter:** ThienPDM (self)
**Created:** 2026-05-14
**Resolved:** _(dien khi resolve)_

## Symptom

Hop dong du lieu giua `health_system/backend` va `healthguard-model-api` (`POST /api/v1/health/predict`) hien chi dinh nghia shape cua `VitalsRecord` (field names + types) nhung KHONG dinh nghia:

1. **Cach handle missing fields**: Pydantic schema cho `VitalsRecord` o model API khong reject record co `heart_rate=None` / `spo2=None`. Backend mobile lai fill defaults silently truoc khi gui — model API nhan record "dep" ma thuc ra la synthetic.
2. **Cach signal data quality**: Khong co field `is_synthetic_default: bool` hoac `defaults_applied: list[str]` de model biet input da bi degrade. Model serve prediction voi confidence cao tren data fake — SHAP explanation dua tren feature values fake.
3. **Cach error**: Khi model API muon reject (out-of-range, all-default), khong co error code chuan. Hien tai chi tra 422 generic "Missing required keys" hoac 500.

He qua: bug **HS-024** o backend mobile (silent default fill) khong bi catch o model API boundary. Hai repo cung "lanh manh" ve doc lap nhung ket hop lai tao risk score gia.

## Repro steps

### Setup

1. `health_system/backend` running tai :8000 voi HS-024 chua fix.
2. `healthguard-model-api` running tai :8001.
3. Vitals row co `heart_rate=NULL, spo2=NULL`, profile thieu height/weight.

### Trigger

4. Mobile goi `/risk/recalculate`.

**Expected (intended contract):**
- Mobile BE rejects record vi input quality khong du (HS-024 fix Option A).
- HOAC: Mobile BE gui voi flag `is_synthetic_default=true`, model API serve nhung tag `confidence < 0.5` + log warning.

**Actual:**
- Mobile BE fill default — gui record `{heart_rate: 75, spo2: 98, ...}` dep.
- Model API serve prediction binh thuong, tra `risk_level=low, confidence=0.85`.
- Ket qua persist vao `risk_scores` voi `model_version="model_api_v1"` ma khong co dau hieu data quality issue.

**Repro rate:** 100% (deterministic).

## Environment

- Repo: cross — `health_system/backend` + `healthguard-model-api`
- Branch (HS): `chore/audit-2026-phase-0-5-intent-drift`
- Branch (MA): `master`
- Affected files:
  - `health_system/backend/app/adapters/model_api_health_adapter.py` (`to_record`)
  - `health_system/backend/app/services/model_api_client.py` (`predict_health_risk` payload)
  - `healthguard-model-api/app/schemas/health.py` (`VitalsRecord` Pydantic schema)
  - `healthguard-model-api/app/services/health_service.py` (`prepare_inference_frame`)
  - `healthguard-model-api/app/routers/health.py` (`/predict` endpoint)

## Investigation

### Root cause — contract gap

**Mobile BE side (producer):**
```python
# app/adapters/model_api_health_adapter.py:to_record
"heart_rate": float(payload.get("heart_rate") or 75.0),  # silent fill
"spo2": float(payload.get("spo2") or 98.0),              # silent fill
```

**Model API side (consumer):**
```python
# healthguard-model-api/app/schemas/health.py (can verify)
class VitalsRecord(BaseModel):
    heart_rate: float
    spo2: float
    # ... required fields, khong co constraint range
```

Pydantic chi reject `None` neu field declared `float` (not `Optional`). Nhung vi mobile BE da fill 75/98, model API nhan `float` hop le — pass validation — serve.

Khong co co che nao de model API biet "75.0 nay la default fill tu NULL DB" vs "75.0 that".

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Model API schema thieu range constraint (HR 30-220, SpO2 50-100) | Chua test, can doc `app/schemas/health.py` |
| H2 | Khong co `is_synthetic_default` flag trong contract | Confirmed (chua dinh nghia) |
| H3 | Loi 422 khong co structured error code phan biet validation vs missing data | Chua test, can doc router error handler |

### Attempts

_(Chua attempt — bug moi duoc log)_

## Resolution

_(Fill in when resolved)_

## Recommended fix direction

**Phase 1 — Range validation o model API schema (low risk):**
1. Them `Field(..., ge=20, le=250)` cho `heart_rate`, `Field(..., ge=50, le=100)` cho `spo2`, etc trong `VitalsRecord`.
2. Out-of-range — 422 voi detail ro rang — mobile BE catch va surface.

**Phase 2 — Optional `is_synthetic_default` flag (can ADR):**
1. Mobile BE adapter `to_record` set field `is_synthetic_default: bool` + `defaults_applied: list[str]` khi fill default.
2. Model API schema accept 2 field nay (Optional, default `False` / `[]`).
3. Model API:
   - Log warning khi `is_synthetic_default=True`.
   - Multiply `confidence_value *= 0.5` trong response — backend mobile thay low confidence — tag risk score la "tentative".
   - Hoac reject han neu policy chot fail-closed (ADR can).

**Phase 3 — Structured error codes:**
1. Model API tra `{"error_code": "INSUFFICIENT_VITALS", "missing_fields": [...]}` thay vi error message string.
2. Mobile BE map error_code — user-facing Vietnamese message.

## Cross-repo impact matrix

| Repo | Impact | Action |
|---|---|---|
| `health_system/backend` | Producer — phai gui flag `is_synthetic_default` | Update `ModelApiHealthAdapter.to_record` |
| `healthguard-model-api` | Consumer — phai accept + react toi flag | Update `VitalsRecord` schema + `health_service` logic |
| `Iot_Simulator_clean` | Khong impact direct (khong goi model API) | N/A |
| `HealthGuard` (admin) | Co the display flag trong audit log neu can | Optional |
| `PM_REVIEW` | Can ADR moi: "Health input validation contract" | Tao ADR-NNN khi pick approach |

## Dependencies

- Can fix **HS-024** truoc hoac song song. HS-024 o producer side, XR-003 o contract layer.
- Can ADR moi (tam goi `ADR-018-health-input-validation-contract.md`) de chot:
  - Fail-closed strict (Option A cua HS-024) hay degrade-with-flag (Option B)?
  - Format error code chuan cho model API.

## Related

- Linked bug: **HS-024** (silent default fill o producer)
- UC: UC016 View Risk Report
- Topology: `PM_REVIEW/.kiro/steering/11-cross-repo-topology.md` — section "Boundary contracts" co liet ke BE — Model API qua `/api/v1/{fall,sleep,health}` voi `X-Internal-Secret` header, nhung khong dinh nghia data quality contract.
- Audit reference: chua co audit nao flag contract gap nay — day la blind spot.

## Notes

- XR-003 la follow-up cua XR-001 (endpoint prefix drift) va XR-002 (severity CheckConstraint drift) — cung pattern: cross-repo contract chua duoc formalize.
- Phat hien trong cung session 2026-05-14 khi trace luong "tu tao data ha?".
- Khi fix, can regression test o ca 2 repo:
  - `health_system/backend/tests/test_model_api_client_with_synthetic_flag.py` (moi)
  - `healthguard-model-api/tests/test_vitals_record_synthetic_handling.py` (moi)
