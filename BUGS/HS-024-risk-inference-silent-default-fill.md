# Bug HS-024: Risk inference fill default silently khi vitals/profile NULL → score gia

**Status:** Open
**Repo(s):** health_system (backend)
**Module:** services/risk_alert_service + adapters/model_api_health_adapter
**Severity:** High
**Reporter:** ThienPDM (self)
**Created:** 2026-05-14
**Resolved:** _(dien khi resolve)_

## Symptom

Khi `vitals` table co row nhung cac cot vitals critical (`heart_rate`, `spo2`, `blood_pressure_sys`, `blood_pressure_dia`) la `NULL`, hoac `users` profile thieu (`weight_kg` / `height_cm` / `date_of_birth`), pipeline danh gia rui ro sinh ton van chay binh thuong va tra ra `risk_score` + `risk_level` "dep" — nhung con so do dua tren defaults hardcode chu khong phai du lieu that cua user.

Mobile app hien thi "Suc khoe on dinh" trong khi backend thuc ra khong co du data de ket luan. Nguy hiem cho nguoi cao tuoi vi co the che giau vital signs bat thuong ngay khi sensor loi / disconnect.

Bad: backend default fill silently — mobile khong biet ket qua la "fake"
Expected: backend phai fail-closed (raise `InsufficientVitalsError`) hoac day `defaults_applied` vao response de mobile canh bao "Can deo thiet bi them de co danh gia chinh xac".

## Repro steps

### Setup

1. Co 1 device gan cho user X.
2. INSERT row vao `vitals` cho device do voi `heart_rate=NULL, spo2=NULL, blood_pressure_sys=NULL, blood_pressure_dia=NULL` (sensor loi gia lap).
3. User X: `users.weight_kg=NULL, users.height_cm=NULL` (profile chua nhap).
4. Dam bao cooldown da het (`RISK_COOLDOWN_SECONDS` mac dinh 60s).

### Trigger

5. Mobile goi `POST /api/v1/mobile/risk/recalculate` (hoac doi periodic risk job).

**Expected:**
- BE tra 422 voi detail "vitals incomplete" hoac 200 voi flag `is_synthetic_default=true` + `defaults_applied=[<list>]` de mobile render empty state.

**Actual:**
- BE tra 200 voi `risk_score`, `risk_level` tinh tu defaults hardcode:
  - `heart_rate=75.0`, `spo2=98.0`, `sys_bp=120.0`, `dia_bp=80.0`
  - `weight_kg=65.0`, `height_cm=165.0`
- Field `defaults_applied` da duoc tracked trong `_build_inference_payload` nhung KHONG duoc surface len response cho mobile.

**Repro rate:** 100% (deterministic — defaults hardcode trong source).

## Environment

- Repo: `health_system/backend`
- Branch: `chore/audit-2026-phase-0-5-intent-drift` tai 2026-05-14
- Backend: FastAPI :8000
- DB: Postgres (shared `healthguard`)
- Affected modules:
  - `app/services/risk_alert_service.py:_build_inference_payload` (lines 155-201)
  - `app/services/risk_alert_service.py:_fetch_latest_vitals` (lines 89-153)
  - `app/adapters/model_api_health_adapter.py:to_record` (lines 51-90)

## Investigation

### Root cause — confirmed

Hai layer fill defaults doc lap, khong synchronize:

#### Layer 1: `risk_alert_service._build_inference_payload`

```python
# app/services/risk_alert_service.py:155-201
def _build_inference_payload(vitals_row, context):
    defaults_applied: list[str] = []
    sys_bp = vitals_row.get("blood_pressure_sys") or 120.0   # default
    dia_bp = vitals_row.get("blood_pressure_dia") or 80.0    # default
    hrv = vitals_row.get("hrv") or 40.0                       # default
    weight_kg = context.get("weight_kg") or 65.0              # default
    height_cm = context.get("height_cm") or 165.0             # default
    inference_payload = {
        "heart_rate": float(vitals_row.get("heart_rate") or 75.0),   # default
        "resp_rate": float(vitals_row.get("respiratory_rate") or 16.0),  # default
        "body_temp": float(vitals_row.get("temperature") or 36.6),   # default
        "spo2": float(vitals_row.get("spo2") or 98.0),               # default
        ...
    }
    return inference_payload, defaults_applied
```

`defaults_applied` duoc track cho 5 fields (sys_bp, dia_bp, hrv, weight_kg, height_cm) nhung KHONG track cho 4 fields critical con lai (heart_rate, resp_rate, body_temp, spo2) — chung dung `or` literal pattern trong dict comprehension.

#### Layer 2: `ModelApiHealthAdapter.to_record`

```python
# app/adapters/model_api_health_adapter.py:51-90
@staticmethod
def to_record(payload):
    sys_bp = float(payload.get("sys_bp") or 120.0)        # default LAN 2
    dia_bp = float(payload.get("dia_bp") or 80.0)         # default LAN 2
    height_cm = float(payload.get("height_cm") or 165.0)  # default LAN 2
    weight_kg = float(payload.get("weight_kg") or 65.0)   # default LAN 2
    hrv = float(payload.get("hrv") or 50.0)               # default LAN 2 (khac Layer 1: 50 vs 40)
    return {
        "heart_rate": float(payload.get("heart_rate") or 75.0),
        "respiratory_rate": float(payload.get("resp_rate") or 16.0),
        "body_temperature": float(payload.get("body_temp") or 36.6),
        "spo2": float(payload.get("spo2") or 98.0),
        ...
    }
```

Drift giua 2 layer: HRV default Layer 1 = `40.0`, Layer 2 = `50.0`. Neu Layer 1 fill 40 thi Layer 2 se pass-through 40 (vi `40.0 or 50.0 == 40.0`). Nhung neu caller goi `to_record` direct thi se fill 50. Inconsistent.

#### Layer 3: `_fetch_latest_vitals` khong filter NULL chac

```python
# app/services/risk_alert_service.py:89-153
# Averaging an empty table yields NULL — treat as no data
if row_dict.get("heart_rate") is None and row_dict.get("spo2") is None:
    return None
```

Chi check khi CA HAI `heart_rate` va `spo2` deu NULL. Neu chi 1 trong 2 NULL (sensor loi 1 channel) row van duoc xem la "co data" — defaults fill cho field con lai.

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Defaults fill silently khong surface len mobile, user khong biet score la fake | Confirmed (doc code path) |
| H2 | Drift giua 2 layer adapter fill defaults voi value khac nhau (HRV 40 vs 50) | Confirmed (grep code) |
| H3 | `_fetch_latest_vitals` chi reject khi ca HR + SpO2 NULL (vs tung field) | Confirmed (doc lines 152-154) |
| H4 | Mobile co endpoint nhan `defaults_applied` de render empty state? | Chua test, can check `risk_repository.get_risk_report_detail` response shape |

### Attempts

_(Chua attempt — bug moi duoc log)_

## Resolution

_(Fill in when resolved)_

## Recommended fix direction

**Option A — Fail-closed (recommended cho production):**
1. `_fetch_latest_vitals`: reject row neu BAT KY field critical (HR / SpO2 / sys_bp / dia_bp) NULL — raise `InsufficientVitalsError`.
2. `_build_inference_payload`: KHONG fill default cho 4 field critical. Chi fill cho field "soft" (HRV / weight / height) voi `defaults_applied` track day du.
3. Endpoint `/risk/recalculate` catch `InsufficientVitalsError` — return 422 voi detail "Can them du lieu vitals; vui long deo thiet bi them 5 phut".
4. Mobile render empty state dung nghia.

**Option B — Degrade-with-flag:**
1. Van fill default nhung push `defaults_applied` + `is_synthetic_default` flag vao response.
2. Mobile render banner "Danh gia co dung du lieu mac dinh cho: HR, SpO2..." neu flag = true.
3. Risk score tag voi `confidence_value < 0.5` de alert escalation logic khong trigger push notification.

**Trade-off:**
- A nghiem khac hon, dung spec ban dau, nhung UX co the frustrating khi sensor loi tam thoi.
- B mem hon, giu continuity, nhung can thay doi UC016 + UC + JIRA story.

Em recommend Option A vi day la medical-grade app, fail-closed > silent degrade.

## Cross-repo impact

- **healthguard-model-api**: hien tai nhan record co default fill nhu that — khong phan biet duoc. Co the bo sung field `is_synthetic_default: bool` trong `VitalsRecord` schema de model log va quyet dinh co serve prediction hay reject. Track rieng o **XR-003**.
- **Iot_Simulator_clean**: KHONG bi anh huong. IoT Sim sinh data day du qua `VitalsGenerator` (real datasets BIDMC/VitalDB/WESAD). Da verify: grep `/api/v1/health|predict_health|model_api` trong `Iot_Simulator_clean/**/*.py` — 0 match.

## Related

- UC: UC016 View Risk Report (`PM_REVIEW/Resources/UC/Analysis/UC016_View_Risk_Report.md`) — BR-016-02 yeu cau >=24h vitals lien tuc, nhung hien tai chi check empty (5 mau gan nhat AVG).
- ADR: chua co ADR cho input validation contract — can ADR moi khi pick Option A vs B.
- Linked bug: **XR-003** (cross-repo contract for missing vitals)
- Audit reference: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/AI_XAI.md` mo ta luong nhung chua flag default-fill.

## Notes

- Phat hien trong session 2026-05-14 khi anh ThienPDM hoi "tu tao data ha?" sau khi nhin flow chart "Luong danh gia rui ro sinh ton ca nhan hoa".
- Can xac minh: `risk_repository.get_risk_report_detail` co expose `defaults_applied` ra mobile response khong? Neu chua thi mobile hien tai dang display risk fake ma khong co cach nao biet.
- Test cases can them khi fix:
  - `test_fail_closed_when_hr_null` (Option A)
  - `test_fail_closed_when_spo2_null` (Option A)
  - `test_defaults_applied_surfaces_in_response` (Option B neu chon)
  - Regression: `test_normal_path_still_works_with_full_vitals`
