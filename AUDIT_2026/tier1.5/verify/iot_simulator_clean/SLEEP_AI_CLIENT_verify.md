# Verification Report - `Iot_Simulator_clean / SLEEP_AI_CLIENT`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SLEEP_AI_CLIENT.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** PASS (good doc) + 1 CRITICAL (NEW bug in IS-001 scope) + 1 MEDIUM + 2 LOW.
**Verdict (resolved 2026-05-13):** PASS v2 - Anh approved F-SA-02/04/05/06. IS-001 bug doc expanded + drift doc v2 rewritten. All doc fixes DONE. Phase 4 code fixes scheduled (35min IS-001 + 30min BE runtime tracking + FE).

---

## TL;DR

- **IS-001 claim fully verified.** Source of truth: `simulator_core/sleep_ai_client.py:52` POST `/predict` (wrong) vs model-api `sleep.py:33` `/api/v1/sleep/predict` (correct). Missing header + probe inconsistency confirmed.
- **Heuristic fallback claim verified.** `sleep_service._compute_sleep_score_with_ai()` returns AI score if available, else heuristic. `_last_sleep_score_source` tracks source ("ai" / "heuristic"). Runtime state already expose `lastScoreSource` in health probe payload (`dependencies.py:2049`).
- **Probe fix target VERIFIED.** `/api/v1/sleep/model-info` endpoint DOES exist in model-api `sleep.py:60`. Pattern mirrors fall pattern. IS-001 resolution plan is correct.
- **NEW finding C1: Response schema mismatch.** Client `predict()` reads `body["predictions"][0]`, model-api returns `{"results": [...], "total": N}`. Even after IS-001 path fix, parse will fail - need verify schema alignment.
- **D-013 internal secret not yet enforced on model-api.** Grep confirmed 0 `require_internal_service` in model-api. Header fix (D-020 part of IS-001) is forward-looking; won't block today.
- **Scope boundary with sleep_service:** `SleepAIClient` la HTTP client (thin). Fallback logic + scoring + push o `sleep_service.py`. Doc mention "sleep_service.py" + "sleep_vitals_enricher.py" trong "Code state" nhung day la MODULES KHAC (SIMULATOR_CORE + SLEEP service), khong phai cua SLEEP_AI_CLIENT module.

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 Module file claims

| Claim | Code location | Verdict |
|---|---|---|
| `sleep_ai_client.py`: stdlib HTTP client, circuit breaker pattern | `simulator_core/sleep_ai_client.py:24-67`. Uses `urllib.request` stdlib. `_available: bool \| None` circuit breaker state. | OK Dung |
| BUG IS-001: POST `/predict` (404) thay vi `/api/v1/sleep/predict` | `sleep_ai_client.py:52` `f"{self.base_url}/predict"` vs model-api `sleep.py:19, 32` prefix `/api/v1/sleep` + endpoint `/predict` | OK Dung, bug reproducible |
| Probe: GET `/health` (generic, khong domain-specific) | `sleep_ai_client.py:32` `f"{self.base_url}/health"` | OK Dung |
| Missing header: `X-Internal-Service: iot-simulator` | `sleep_ai_client.py:55` `headers={"Content-Type": "application/json"}` - no X-Internal-Service | OK Confirmed |
| `sleep_service.py`: Orchestrate sleep session | OUT OF SLEEP_AI_CLIENT module scope. Sleep orchestration la `api_server/services/sleep_service.py`, khong thuoc `simulator_core/sleep_ai_client.py`. | WARN Scope boundary issue (M3) |
| `sleep_vitals_enricher.py`: Enrich sleep record voi HR/SpO2/temp context | OUT OF SLEEP_AI_CLIENT module scope. Thuoc SIMULATOR_CORE module (sleep_vitals_enricher la separate utility). | WARN Scope boundary issue (M3) |

**Module verdict:** Core `sleep_ai_client.py` claims correct. Tangential modules (`sleep_service.py`, `sleep_vitals_enricher.py`) should not be in SLEEP_AI_CLIENT "Code state" list - they belong to other modules.

### 1.2 IS-001 fix plan verification

**Doc IS-001 fix plan (Q1 + IS-001 bug doc):**
```
# Path:  /predict                   -> /api/v1/sleep/predict
# Probe: /health                    -> /api/v1/sleep/model-info
# Header: add X-Internal-Service: iot-simulator
```

**Verification against model-api `sleep.py`:**

| Target endpoint | Exists in model-api? | File:Line |
|---|---|---|
| `/api/v1/sleep/predict` (POST) | OK Yes | `sleep.py:33` |
| `/api/v1/sleep/model-info` (GET) | OK Yes | `sleep.py:60` |
| Also available: `/api/v1/sleep/predict/batch`, `/api/v1/sleep/sample-cases`, `/api/v1/sleep/sample-input` | Yes | - |

**Verification against fall pattern (doc claim "mirror fall_ai_client"):**
- `fall_ai_client.py` POST `/api/v1/fall/predict` OK
- `fall_ai_client.py` GET `/api/v1/fall/model-info` OK
- Fall client also MISSING `X-Internal-Service` header (same D-020 gap, already noted trong PRE_MODEL_TRIGGER verify).

**Verdict:** OK All 3 IS-001 fix targets verified. Fix plan accurate, paths exist, pattern match.

### 1.3 Response schema mismatch (NEW C1)

**sleep_ai_client.py:62:**
```
body = json.loads(response.read().decode("utf-8"))
prediction = body["predictions"][0]
```

**model-api sleep.py:33-45 response_model:**
```
@router.post("/predict", response_model=SleepPredictionResponse, ...)
...
return SleepPredictionResponse(
    results=[SleepPredictionResult(**r) for r in results],
    total=len(results),
)
```

**Response shape mismatch:**
- Client expects: `body["predictions"][0]` (key `predictions`, list)
- Server returns: `{"results": [...], "total": N}` (key `results`, list + scalar `total`)

**Impact:** Even AFTER IS-001 path fix, `predict()` will fail with `KeyError: 'predictions'` on line 62. Circuit breaker flips `_available=False` immediately.

**Verdict:** FAIL IS-001 fix as documented WILL STILL FAIL. Need additional fix: rename `body["predictions"][0]` -> `body["results"][0]`. IS-001 Phase 4 P0 scope has to include this.

### 1.4 Heuristic fallback claim verification (SL3)

**Doc claim SL3:**
> Heuristic fallback: score from vitals means when AI down - Confirmed (permanent fallback)

**Code (`sleep_service.py:386-407`):**
```
def _compute_sleep_score_with_ai(self, sleep_ai_record: dict) -> int:
    client = self._sleep_ai_client
    if client is not None:
        result = client.predict(sleep_ai_record)
        # ... if predicted -> return AI score, set _last_sleep_score_source = "ai"
    fallback_summary = { ... }  # derive from vitals
    fallback_score = self._compute_sleep_score_from_summary(fallback_summary)
    self._last_sleep_score_source = "heuristic"
    logger.warning("Sleep AI unavailable - using heuristic fallback score: %s", fallback_score)
    return fallback_score
```

**Verdict:** OK SL3 claim accurate. Heuristic = permanent fallback when AI returns None.

### 1.5 FE data source verification (Q5 / SL6 / SL7)

**Doc claim Q5:**
> FE show scoring source (AI vs heuristic) + confidence

**Code reality (`dependencies.py:2039-2052`):**
```
# Runtime health block already expose:
{
    "url": ... sleep_ai_client.base_url,
    "lastCheckedAt": model_checked_at,
    "lastScoreSource": last_score_source,  # "ai" | "heuristic"
    "lastError": model_error,
}
```

- `_last_sleep_score_source` tracked per scoring operation.
- `last_score_source` exposed in health probe payload.
- `last_success timestamp` NOT directly tracked - would need `last_ai_success_at` field in `_HealthState`.
- `AI confidence score` NOT tracked - `predict()` returns `body["predictions"][0]` which contains AI result dict, but confidence field (if present) not surfaced into runtime state.

**Verdict:** 
- SL6 (scoring source badge): Data source already available - FE just need to consume `lastScoreSource`.
- SL7 (AI connection status): Data source already available via `lastCheckedAt` + `lastError`.
- "Last success timestamp" (drift doc mentions): NOT available - Phase 4 needs additional runtime tracking.
- "AI confidence score" (drift doc mentions): NOT available - requires inspection of model-api response schema to confirm if field exists, then surface to runtime.

Scope refine: FE SL6/SL7 ~50% already-available data. Additional 2 fields need small BE work.

---

## 2. Issues enumerated (prioritized)

### CRITICAL - Block IS-001 fix

**C1. Response schema parse mismatch - IS-001 fix incomplete without this**
- **Evidence:** Section 1.3. Client reads `body["predictions"][0]`, server returns `{"results": [...], "total": N}`.
- **Impact:** Current Phase 4 P0 plan (30min fix: path + header + probe) LEAVES BUG. Post-fix, `KeyError: 'predictions'` in predict() trong 100% cases.
- **Fix direction:** IS-001 fix MUST include: change `body["predictions"][0]` -> `body["results"][0]`.
- **Effort:** +5min on existing P0 task. Total IS-001 P0 = 35min (not 30min).

### HIGH - none

### MEDIUM - Scope clarity

**M1. Schema fix must be added to IS-001 scope** (see C1). Pair with IS-001 fix commit.

**M2. FE scoring source data surface partial**
- **Evidence:** Section 1.5. `lastScoreSource` + `lastCheckedAt` + `lastError` already exposed; `lastSuccessAt` + AI confidence NOT exposed.
- **Impact:** Phase 4 FE task (SL7 "last successful AI call timestamp") needs BE runtime state extension.
- **Fix direction:** Add field `last_ai_success_at: datetime | None` in `_HealthState` + update on successful `_compute_sleep_score_with_ai()` AI path. Add field trong health probe payload.
- **Effort:** 30min BE + FE consume.

**M3. Scope boundary - sleep_service.py + sleep_vitals_enricher.py khong thuoc SLEEP_AI_CLIENT module**
- **Evidence:** Section 1.1. `sleep_service.py` la `api_server/services/sleep_service.py` - service layer, khong thuoc `simulator_core/`. `sleep_vitals_enricher.py` o simulator_core NHUNG thuoc SIMULATOR_CORE module (verified in SIMULATOR_CORE drift doc).
- **Impact:** Doc "Code state" list misleading - reader tuong module = 3 files, actual = 1 file (`sleep_ai_client.py`).
- **Fix direction:** Update "Code state" section:
  - Primary module: `simulator_core/sleep_ai_client.py` only.
  - Cross-references: sleep_service.py (SLEEP service consumer) + sleep_vitals_enricher.py (SIMULATOR_CORE).
- **Effort:** Doc 10min.

### LOW - Wording

**L1. "Fall AI client (correct reference)" needs D-020 note**
- Fall AI client also thieu `X-Internal-Service` header per PRE_MODEL_TRIGGER verify + topology D-020. Not "100% correct" - just "path correct".
- Effort 5min doc.

**L2. Dual-endpoint port clarification**
- Doc SL4 OK but could add: IoT sim also has own port 8002 for simulator-web BE. 3 ports total (8000 mobile BE, 8001 model AI, 8002 sim BE) - not just "dual" in context of sim topology.
- Effort 5min doc.

---

## 3. Fix backlog (prioritized) — status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-SA-01 | Include response schema fix in IS-001 scope (C1) | P0 | 5min (added to IS-001 35min) | **UNBLOCKED** — Phase 4 scope confirmed |
| F-SA-02 | Doc update IS-001 fix plan - add `body["results"][0]` rename | P0 | 10min | **DONE** — IS-001 bug doc + drift doc v2 updated |
| F-SA-03 | Add `last_ai_success_at` field to `_HealthState` (M2) | P2 | 30min | **SCHEDULED** — Phase 4 code backlog |
| F-SA-04 | Refine Code state scope boundary (M3) | P2 | 10min | **DONE** — drift doc v2 "Cross-reference modules" section |
| F-SA-05 | Note D-020 on fall AI client reference (L1) | P3 | 5min | **DONE** — drift doc v2 Cross-references section |
| F-SA-06 | Port clarification (L2) | P3 | 5min | **DONE** — drift doc v2 Q4 Note section |

**Status summary:** 4/6 DONE, 1/6 UNBLOCKED (Phase 4 P0 scope confirmed), 1/6 SCHEDULED (Phase 4 P2 BE task).

**Total effort spent today:** ~40min (verify report + drift doc v2 rewrite + IS-001 bug doc expand).
**Remaining (Phase 4 code branch):** 35min IS-001 + 1h regression test + 30min BE runtime tracking + 4-5h FE = ~6h.

---

## 4. Cross-repo impact

### Affected docs/specs
- `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md` - update fix scope + add response schema fix step.
- `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - Path 5 (Sleep AI client) already notes D-018. D-020 + D-022 cross-cut.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` - scope boundary reference (sleep_vitals_enricher belongs there).
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/PRE_MODEL_TRIGGER.md` - already notes sleep_dispatch standalone + sleep_ai_client connection.

### Affected code repos
- `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` - IS-001 fix (path + header + probe + schema).
- `Iot_Simulator_clean/api_server/dependencies.py` - SL7 `last_ai_success_at` tracking.
- `Iot_Simulator_clean/api_server/runtime_state.py` - `_HealthState` extension.
- `Iot_Simulator_clean/tests/` - NEW `test_sleep_ai_client.py` regression test (currently 0 tests for this client per grep).

### ADRs needed

None. IS-001 fix + scope refinement are surgical, no architectural decision needed. ADR-015 covers severity (doesn't apply here since sleep scoring returns int score, not severity).

---

## 5. Next steps - em de xuat

1. **Immediate (anh approve):** Em apply doc fixes F-SA-02, F-SA-04, F-SA-05, F-SA-06 (~30min doc) + update IS-001 bug doc với response schema fix step.
2. **Phase 4 backlog update:** IS-001 P0 = 35min + regression test 1h (per drift doc current plan) + schema fix +5min.
3. **Phase 4 code execution:** When anh start IS-001 fix branch, verify all 4 changes at once: path + probe + header + schema key.

**Em khong edit drift doc trong phase verify. Output verify nay la input cho anh decide.**

---

## Appendix - evidence index

- Sleep AI client: `simulator_core/sleep_ai_client.py:24-67` (full file)
- Runtime wiring: `api_server/dependencies.py:611-618` (init + check_availability)
- Scoring + fallback: `api_server/services/sleep_service.py:386-407` (_compute_sleep_score_with_ai)
- Runtime state exposure: `api_server/runtime_state.py:58-59` (_HealthState.last_score_source)
- Health probe payload: `api_server/dependencies.py:2039-2052`
- Model-api sleep router: `healthguard-model-api/app/routers/sleep.py:19, 33, 60` (prefix + predict + model-info)
- Response schema: `healthguard-model-api/app/schemas/sleep.py` (SleepPredictionResponse - results + total)
- Fall AI client reference (correct path, missing header): `simulator_core/fall_ai_client.py` predict + check_availability
- IS-001 bug doc: `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md`
- Topology: `tier1/topology_v2.md` § Path 5, D-018, D-020, D-022
