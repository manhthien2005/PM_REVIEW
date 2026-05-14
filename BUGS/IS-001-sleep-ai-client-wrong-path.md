# Bug IS-001: Iot sim sleep AI client POST tới /predict (404) thay vì /api/v1/sleep/predict

**Status:** 🔴 Open
**Repo(s):** Iot_Simulator_clean (simulator_core)
**Module:** sleep_ai_client
**Severity:** Critical
**Reporter:** ThienPDM (self) — surfaced trong Phase -1.C audit
**Created:** 2026-05-11
**Resolved:** _(điền khi resolve)_

## Symptom

Sleep AI prediction từ IoT simulator KHÔNG bao giờ thành công trong production. Mọi request fall back về heuristic scoring trong `sleep_service.py`. AI verdict (deep sleep ratio, sleep efficiency, model confidence) never engaged.

## Repro steps

1. Start `healthguard-model-api` ở port 8001
2. Start IoT simulator
3. Trigger sleep scenario (vd `backfill_sleep_history`)
4. Watch logs cho IoT sim

**Expected:**
- `[INFO] Sleep AI predict succeeded for device_id=X`
- DB `sleep_sessions.phases` field có AI-generated breakdown (not heuristic)

**Actual:**
- `[WARNING] Sleep AI predict failed: HTTP Error 404: Not Found`
- Circuit breaker flips `_available=False`
- Sleep score computed heuristically từ vitals means

**Repro rate:** 100% (deterministic — endpoint path sai)

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:53`
- Target: `healthguard-model-api@develop` (port 8001)

## Root cause (đã identify)

### File: `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:46-67`

```python
def predict(self, sleep_record: dict) -> dict | None:
    """Send one sleep record for inference and return the first prediction."""
    if self._available is False:
        return None

    payload = json.dumps({"backend": "onnx", "records": [sleep_record]}).encode("utf-8")
    request = Request(
        f"{self.base_url}/predict",   # ← WRONG PATH
        data=payload,
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    ...
```

`base_url` default = `http://localhost:8001`
Full URL = `http://localhost:8001/predict`

### Model API reality (verified Phase -1.B)

```
healthguard-model-api/app/routers/sleep.py:19
router = APIRouter(prefix="/api/v1/sleep", tags=["Sleep Score"])

@router.post("/predict", ...)  # line 32
```

→ Effective sleep predict endpoint = **`/api/v1/sleep/predict`**

→ `/predict` (root-level) **KHÔNG TỒN TẠI** trên model-api.

### Why bug survives undetected

- `SleepAIClient.check_availability()` probes `/health` (system endpoint) — returns 200 ✓
- → `_available = True` after startup
- → `predict()` runs → 404 → exception caught → `_available = False`
- → Logged at WARNING (easy to miss trong production noise)
- → Caller (`sleep_service.py`) falls back gracefully → no user-visible error
- → Bug invisible unless audit predict path explicitly

### Comparison với fall_ai_client (correct)

`fall_ai_client.py:375` correctly uses `/api/v1/fall/predict`:
```python
request = Request(
    f"{self.base_url}/api/v1/fall/predict",
    ...
)
```

→ Fall AI client đã được fix trước đó (per comment trong fall_ai_client.py:282 mentioning "earlier `/api/v1/fall/info` was a copy-paste from the SleepAIClient pattern that doesn't exist on the fall router").

→ Sleep client KHÔNG được apply cùng fix.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | sleep_ai_client.py copy-paste từ template cũ mà chưa update | ✓ Confirmed |
| H2 | Model API có alias `/predict` → `/api/v1/sleep/predict`? | ❌ Rejected — không có alias trong router |

### Attempts

_(Chưa attempt fix — bug surfaced trong Phase -1.C audit, defer Phase 4 refactor)_

## Resolution

_(Fill in when resolved — Phase 4 target)_

**Fix approach (planned, expanded 2026-05-13 per SLEEP_AI_CLIENT verify C1):**

```python
# Line 53 — change from:
f"{self.base_url}/predict"
# to:
f"{self.base_url}/api/v1/sleep/predict"

# Also fix probe (D-022) — line 33:
# From: GET /health
# To:   GET /api/v1/sleep/model-info  (mirror fall_ai_client pattern)

# Also add (D-020):
headers={
    "Content-Type": "application/json",
    "X-Internal-Service": "iot-simulator",   # ← add this
}

# NEW (verify C1 2026-05-13): Fix response schema parse — line 62:
# From: prediction = body["predictions"][0]
# To:   prediction = body["results"][0]
# Model-api returns SleepPredictionResponse {"results": [...], "total": N},
# NOT {"predictions": [...]}. Without this fix, KeyError fires even after path fix.
```

**Fix scope summary:** 4 changes trong cung 1 commit: path + probe + header + response schema key. Est 35min (revised from 30min v1).

**Test added (planned):**
- `Iot_Simulator_clean/tests/simulator_core/test_sleep_ai_client.py::test_predict_correct_path_and_schema`
- Mock httpx response với `{"results": [{"sleep_score": 82}], "total": 1}` shape, assert request URL contains `/api/v1/sleep/predict` AND `result["sleep_score"] == 82` parsed correctly.

**Verification:**
1. Run IoT sim sleep scenario
2. Watch logs: should see `Sleep AI predict succeeded`
3. DB `sleep_sessions.phases` column has AI-generated structure (not heuristic-only)

## Related

- **Phase -1.C finding:** [topology_v2.md § Path 5](../AUDIT_2026/tier1/topology_v2.md) — Drift D-018
- **Linked drift:**
  - D-020 (missing X-Internal-Service header)
  - D-022 (probe endpoint inconsistency)
- **Parent context:** [PM-001](./PM-001-pm-review-spec-drift.md) — systemic drift
- **Fall AI client (correct reference):** `Iot_Simulator_clean/simulator_core/fall_ai_client.py` — apply same pattern
- **UC:** UC024 — Sleep tracking (likely affected)

## Notes

- Bug surface area: ONLY sleep AI inference path
- Fall AI path unaffected (already correct)
- Heuristic fallback ensures no user-facing crash → low urgency dù severity = Critical
- Fix surgical: 1 line change + 2 header tweaks
- Có thể combine fix với D-020 + D-022 (cùng file)
