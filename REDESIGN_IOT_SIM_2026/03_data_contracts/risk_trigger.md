# Contract — Risk Trigger (Internal Flow)

> **Type:** Internal flow contract (NOT a single endpoint — describes BE's auto-trigger pipeline after `/telemetry/ingest`)  
> **Producer:** Mobile BE (`risk_alert_service.calculate_device_risk`)  
> **Consumer:** Model API (`/api/v1/health/predict`) + DB (`risk_scores`) + Mobile app (poll)  
> **Critical changes:** HS-024 silent default fill fix, OQ5 auto-trigger, XR-003 validation flag

---

## 1. Flow overview

```
Step 1: /telemetry/ingest receives vitals batch
   ↓
Step 2: For each unique device_id in batch:
   ↓
Step 3: calculate_device_risk(device_id, user_id, allow_cached=True)
   ↓
Step 4: Cooldown check (default 60s per device)
   ├─ If cached → return cached risk_score (no model call)
   └─ If cooldown OK → continue
   ↓
Step 5: Fetch latest vitals (5-sample average) + user profile
   ↓
Step 6: Validation gate (HS-024 fix)
   ├─ If critical fields NULL → raise InsufficientVitalsError
   └─ If complete → continue
   ↓
Step 7: Build inference_payload + track defaults_applied
   ↓
Step 8: Call model-api /api/v1/health/predict
   ↓
Step 9: INSERT risk_scores with is_synthetic_default + defaults_applied
   ↓
Step 10: Dispatch alerts if severity ≥ medium
   ├─ Build FCM payload (data-only)
   ├─ Fanout to patient + caregivers (linked profile)
   └─ Send via firebase-admin
```

---

## 2. Mobile BE internal contract — `calculate_device_risk`

### 2.1 Function signature (target after HS-024 fix)

```python
# health_system/backend/app/services/risk_alert_service.py (Phase 7 update)
class RiskAlertService:
    @classmethod
    def calculate_device_risk(
        cls,
        db: Session,
        *,
        device_id: int,
        user_id: int,
        allow_cached: bool = True,
        dispatch_alerts: bool = True,
        force_recalc: bool = False,
    ) -> RiskCalculationResult:
        """Calculate risk score for a device.
        
        Returns RiskCalculationResult with structured outcome including
        defaults_applied tracking (HS-024 fix).
        
        Raises:
            InsufficientVitalsError: When critical fields NULL.
            ModelApiUnavailableError: When model-api down (after retry).
        """
```

### 2.2 Return type

```python
@dataclass
class RiskCalculationResult:
    risk_score_id: int | None        # None if used cache
    risk_level: Literal["low", "medium", "high", "critical"]
    confidence: float                 # 0.0-1.0
    is_synthetic_default: bool        # True if any default fill happened
    defaults_applied: dict[str, bool] # per-field tracking
    top_features: list[dict]          # SHAP top contributors
    model_version: str
    used_cache: bool
    alerts_dispatched: list[int]      # FCM recipient user_ids
    request_id: str
```

### 2.3 Defaults_applied schema

```json
{
  "heart_rate": false,           // real value used
  "spo2": false,
  "blood_pressure_sys": true,    // default filled (real was NULL)
  "blood_pressure_dia": true,
  "temperature": false,
  "hrv": false,
  "respiratory_rate": false,
  "weight_kg": true,             // user profile missing
  "height_cm": true
}
```

**Rule (HS-024 fix):**
- **Critical fields:** `heart_rate`, `spo2`, `temperature`, `respiratory_rate` — MUST NOT default. If NULL → raise `InsufficientVitalsError`.
- **Soft fields:** `blood_pressure_sys`, `blood_pressure_dia`, `hrv`, `weight_kg`, `height_cm` — MAY default with track.
- **`is_synthetic_default = any(defaults_applied.values())`** — true if any field defaulted.

### 2.4 InsufficientVitalsError handling

```python
class InsufficientVitalsError(Exception):
    def __init__(self, missing_fields: list[str], device_id: int):
        self.missing_fields = missing_fields
        self.device_id = device_id
        super().__init__(f"Critical vitals missing: {missing_fields}")

# In /telemetry/ingest handler:
try:
    result = calculate_device_risk(...)
except InsufficientVitalsError as exc:
    logger.warning("Risk eval skipped device=%s: %s", exc.device_id, exc)
    errors.append({
        "device_id": exc.device_id,
        "error_code": "INSUFFICIENT_VITALS",
        "missing_fields": exc.missing_fields,
    })
    continue  # do not abort entire batch

# In /risk/recalculate handler (user-facing):
try:
    result = calculate_device_risk(...)
except InsufficientVitalsError as exc:
    raise HTTPException(
        status_code=422,
        detail={
            "error": {
                "code": "INSUFFICIENT_VITALS",
                "message": "Cần đeo thiết bị thêm 5 phút để có đánh giá chính xác",
                "details": {"missing_fields": exc.missing_fields}
            }
        }
    )
```

---

## 3. Model API contract — `POST /api/v1/health/predict` (consumer)

### 3.1 Request schema (XR-003 fix)

```typescript
interface HealthPredictionRequest {
  records: VitalsRecord[];      // batch up to 10
}

interface VitalsRecord {
  // Required fields with range validation (XR-003 fix)
  heart_rate: number;            // Field(ge=20, le=250)
  spo2: number;                  // Field(ge=50, le=100)
  body_temperature: number;      // Field(ge=30, le=45)
  respiratory_rate: number;      // Field(ge=5, le=60)
  sys_bp: number;                // Field(ge=60, le=260)
  dia_bp: number;                // Field(ge=30, le=180)
  hrv: number;                   // Field(ge=0, le=300)
  weight_kg: number;             // Field(ge=20, le=300)
  height_cm: number;             // Field(ge=100, le=250)
  age_years: number;             // Field(ge=1, le=120)
  
  // NEW fields (XR-003)
  is_synthetic_default: boolean; // Optional, default False
  defaults_applied: string[];    // Optional, list of field names defaulted
}
```

### 3.2 Response schema

```typescript
interface HealthPredictionResponse {
  predictions: PredictionResult[];
  model_version: string;
  request_id: string;
}

interface PredictionResult {
  risk_level: "low" | "medium" | "high" | "critical";
  confidence: number;            // 0.0-1.0
  
  // NEW (XR-003): degrade confidence if input synthetic
  effective_confidence: number;  // confidence × (0.5 if is_synthetic_default else 1.0)
  
  top_features: SHAPFeature[];
  predicted_at: string;
  
  // NEW (XR-003): explicit warning
  data_quality_warning: string | null;
  // e.g., "Some vitals (blood_pressure_sys, blood_pressure_dia) were defaulted"
}

interface SHAPFeature {
  feature: string;
  impact: number;                // -1.0 to 1.0
  value: number | string;
}
```

### 3.3 Error response (XR-003 fix — structured)

```json
{
  "error": {
    "code": "VITALS_OUT_OF_RANGE",
    "message": "heart_rate=500 exceeds max=250",
    "details": {
      "field": "heart_rate",
      "value": 500,
      "min": 20,
      "max": 250,
      "record_index": 0
    }
  },
  "request_id": "abc-123"
}
```

**Error codes:**
- `VITALS_OUT_OF_RANGE` (422) — field violates Field constraint
- `MISSING_REQUIRED_FIELD` (400) — Pydantic missing field
- `MODEL_UNAVAILABLE` (503) — ONNX model not loaded
- `INTERNAL_ERROR` (500) — sanitized unexpected error

---

## 4. DB persistence (target schema after HS-024 fix)

### 4.1 risk_scores table additions

```sql
-- Phase 4 migration: 20260515_risk_scores_synthetic_flag.sql
ALTER TABLE risk_scores 
    ADD COLUMN is_synthetic_default BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN defaults_applied JSONB,
    ADD COLUMN effective_confidence NUMERIC(4, 3),
    ADD COLUMN data_quality_warning TEXT;

COMMENT ON COLUMN risk_scores.is_synthetic_default IS 
    'TRUE if any input vitals/profile field was defaulted (HS-024 fix)';
COMMENT ON COLUMN risk_scores.defaults_applied IS 
    'JSON object {field_name: bool} per-field tracking';
COMMENT ON COLUMN risk_scores.effective_confidence IS 
    'confidence × 0.5 if synthetic_default, else = confidence';

CREATE INDEX idx_risk_scores_synthetic 
    ON risk_scores (is_synthetic_default) 
    WHERE is_synthetic_default = TRUE;
```

### 4.2 Mobile BE response shape addition

```python
# health_system/backend/app/schemas/risk.py (Phase 7 extend)
class RiskScoreResponse(BaseModel):
    id: int
    user_id: int
    device_id: int
    risk_level: str
    confidence: float
    effective_confidence: float                     # NEW
    is_synthetic_default: bool                      # NEW
    defaults_applied: dict[str, bool] | None        # NEW
    data_quality_warning: str | None                # NEW
    top_features: list[dict]
    model_version: str
    calculated_at: datetime
```

---

## 5. Mobile app consumer (XR-003 visualization)

### 5.1 Risk Report Detail screen — UX target

```
┌─────────────────────────────────────────────┐
│  Báo cáo rủi ro chi tiết                     │
├─────────────────────────────────────────────┤
│  Mức độ: MEDIUM (62%)                        │
│                                              │
│  ⚠️ Cảnh báo chất lượng dữ liệu              │
│  Một số chỉ số (huyết áp) được ước tính.    │
│  Hãy đeo thiết bị đầy đủ để có đánh giá     │
│  chính xác hơn.                              │
│                                              │
│  Top yếu tố ảnh hưởng:                       │
│  • Nhịp tim: 95 bpm (+15%)                   │
│  • SpO2: 96% (+8%)                           │
│  • Huyết áp tâm thu: 120 mmHg (mặc định) ⚠️  │
└─────────────────────────────────────────────┘
```

### 5.2 Risk Report Repository (Phase 7 update)

```dart
// health_system/lib/features/analysis/repositories/risk_analysis_repository.dart
class RiskReportEntity {
  final int id;
  final String riskLevel;
  final double confidence;
  final double effectiveConfidence;       // NEW
  final bool isSyntheticDefault;          // NEW
  final Map<String, bool>? defaultsApplied; // NEW
  final String? dataQualityWarning;        // NEW
  final List<SHAPFeature> topFeatures;
  final DateTime calculatedAt;
  
  factory RiskReportEntity.fromJson(Map<String, dynamic> json) {
    return RiskReportEntity(
      // ...
      effectiveConfidence: (json['effective_confidence'] as num?)?.toDouble() ?? confidence,
      isSyntheticDefault: json['is_synthetic_default'] as bool? ?? false,
      defaultsApplied: (json['defaults_applied'] as Map?)?.cast<String, bool>(),
      dataQualityWarning: json['data_quality_warning'] as String?,
      // ...
    );
  }
}
```

### 5.3 Widget render warning banner

```dart
// risk_report_detail_screen.dart (Phase 7 extend)
class RiskReportDetailScreen extends StatelessWidget {
  Widget build(BuildContext context, RiskReportEntity report) {
    return Column(
      children: [
        // ... existing risk level + confidence
        
        if (report.isSyntheticDefault) ...[
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.dataQualityWarning ?? 
                    'Một số chỉ số được ước tính. '
                    'Hãy đeo thiết bị đầy đủ để có đánh giá chính xác hơn.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Top features list with default marker
        ...report.topFeatures.map((feature) => ListTile(
          title: Text(feature.label),
          subtitle: Text('${feature.value} ${_isDefault(report, feature) ? "⚠️ mặc định" : ""}'),
          trailing: Text('${(feature.impact * 100).toStringAsFixed(0)}%'),
        )),
      ],
    );
  }
}
```

---

## 6. IoT sim implication (B2 unified pattern)

IoT sim **không trực tiếp trigger** risk inference. Sau B1 + OQ5:
- IoT sim push vitals batch → `/api/v1/mobile/telemetry/ingest`
- Mobile BE auto-trigger `calculate_device_risk` per device
- IoT sim chỉ nhận `risk_evaluated_devices: number[]` trong response ingest
- Simulator-web FE WS `/ws/flow/{session_id}` emit flow event step `risk_eval`

**Dispose:**
- `_trigger_risk_inference` method (lines 1206-1237 in `dependencies.py`)
- `_risk_calculate_endpoint` method (lines 921-923)
- Orchestrator R3 wire

---

## 7. Cooldown + caching strategy

### 7.1 Per-device cooldown

```python
RISK_COOLDOWN_SECONDS = int(os.getenv("RISK_COOLDOWN_SECONDS", "60"))

# Cache key: f"risk:device:{device_id}:last_calculated_at"
# Cache value: RiskCalculationResult JSON
# TTL: RISK_COOLDOWN_SECONDS

def calculate_device_risk(..., allow_cached: bool = True):
    cache_key = f"risk:device:{device_id}:last"
    if allow_cached:
        cached = cache.get(cache_key)
        if cached:
            return RiskCalculationResult(**cached, used_cache=True)
    
    # ... actual calculation
    
    cache.set(cache_key, result.dict(), ttl=RISK_COOLDOWN_SECONDS)
    return result
```

### 7.2 Force recalc (mobile on-demand)

`POST /api/v1/mobile/risk/recalculate` set `force_recalc=True` → skip cache.

---

## 8. Test cases (Phase 6)

```python
# HS-024 fix verification
def test_reject_when_critical_vitals_null():
    vitals = build_vitals(heart_rate=None, spo2=None)
    insert_vitals(device_id=42, vitals=vitals)
    with pytest.raises(InsufficientVitalsError) as exc_info:
        calculate_device_risk(device_id=42, user_id=7)
    assert "heart_rate" in exc_info.value.missing_fields
    assert "spo2" in exc_info.value.missing_fields

def test_tracks_defaults_applied_for_soft_fields():
    vitals = build_vitals(
        heart_rate=72, spo2=98, temperature=36.5,
        blood_pressure_sys=None, blood_pressure_dia=None,
    )
    insert_vitals(device_id=42, vitals=vitals)
    user = setup_user_no_weight_height(user_id=7)
    result = calculate_device_risk(device_id=42, user_id=7)
    assert result.is_synthetic_default is True
    assert result.defaults_applied["blood_pressure_sys"] is True
    assert result.defaults_applied["weight_kg"] is True
    assert result.defaults_applied["heart_rate"] is False

# XR-003 fix verification
def test_model_api_rejects_out_of_range():
    payload = build_predict_request(heart_rate=500)
    response = requests.post("http://localhost:8001/api/v1/health/predict", json=payload)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VITALS_OUT_OF_RANGE"

def test_effective_confidence_degraded_for_synthetic():
    payload = build_predict_request(is_synthetic_default=True)
    response = requests.post(..., json=payload)
    result = response.json()["predictions"][0]
    assert result["effective_confidence"] < result["confidence"]
    assert result["data_quality_warning"] is not None

# Cooldown verification
def test_cooldown_returns_cached_within_60s():
    result1 = calculate_device_risk(device_id=42, user_id=7)
    result2 = calculate_device_risk(device_id=42, user_id=7)  # within cooldown
    assert result2.used_cache is True
    assert result2.risk_score_id == result1.risk_score_id
```

---

## 9. Related

- ADR-018: Health input validation contract (resolves HS-024 + XR-003)
- ADR-023: Mobile streaming pattern (FCM)
- Bug HS-024: Silent default fill (this contract is the canonical fix)
- Bug XR-003: Model-api validation gap (this contract is the canonical fix)
- OQ5: BE auto-trigger risk inference
- File `health_system/backend/app/services/risk_alert_service.py` (to update)
- File `health_system/backend/app/adapters/model_api_health_adapter.py` (to update)
- File `healthguard-model-api/app/schemas/health.py` (to add Field constraints)
