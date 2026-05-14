# Intent Drift Review — Iot_Simulator_clean / SLEEP_AI_CLIENT

**Status:** Confirmed v2 (2026-05-13) — IS-001 scope expanded (NEW C1 schema fix), Code state refined, L1/L2 wording fixed
**Repo:** `Iot_Simulator_clean`
**Module:** SLEEP_AI_CLIENT
**Related UCs (old):** N/A (internal tooling — no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Bug ref:** IS-001 (Critical, Open) — expanded scope per verify C1
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/SLEEP_AI_CLIENT_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** Q1-Q5 confirmed, IS-001 fix plan = path + header + probe.
- **v2 (2026-05-13 afternoon):** Verify pass phat hien:
  - C1 Response schema parse mismatch (`body["predictions"]` vs model-api `{"results": ..., "total": ...}`) -> IS-001 P0 fix scope expanded.
  - M3 Scope boundary - `sleep_service.py` + `sleep_vitals_enricher.py` khong thuoc SLEEP_AI_CLIENT module, thuoc SLEEP service + SIMULATOR_CORE.
  - L1 Fall AI client reference thieu D-020 note (cung missing X-Internal-Service header).
  - L2 Port clarification - 3 ports total (not just dual).
- Doc rewritten per verify findings.

---

## Muc tieu doc nay

Capture intent cho Sleep AI Client — HTTP client goi model-api de classify sleep stages.
Co bug IS-001 (wrong path + wrong response schema key) can fix Phase 4.

---

## Code state — what currently exists (v2 refined)

**Primary module file:**
- `simulator_core/sleep_ai_client.py`: stdlib HTTP client (urllib.request), circuit breaker pattern (`_available: bool | None`).
  - **BUG IS-001 (expanded v2):**
    - Path: POST toi `/predict` (404) thay vi `/api/v1/sleep/predict`
    - Probe: GET `/health` (generic, not domain-specific) thay vi `/api/v1/sleep/model-info`
    - Missing header: `X-Internal-Service: iot-simulator`
    - **NEW Schema key: parse `body["predictions"][0]` thay vi `body["results"][0]`** (model-api response schema `SleepPredictionResponse` has `results` + `total`, not `predictions`)

**Cross-reference modules (NOT part of SLEEP_AI_CLIENT module scope):**
- `api_server/services/sleep_service.py` — SLEEP service layer. Owns scoring + heuristic fallback + push to BE. Consumes `SleepAIClient.predict()` via `_compute_sleep_score_with_ai()`.
- `simulator_core/sleep_vitals_enricher.py` — SIMULATOR_CORE module. Feeds enriched sleep records into SleepAIClient input.

**Runtime state tracking (available):**
- `api_server/runtime_state.py:_HealthState.last_score_source: Literal["ai", "heuristic"]` - tracks last scoring source.
- `api_server/dependencies.py:2039-2052` expose health probe block `{url, lastCheckedAt, lastScoreSource, lastError}` to FE.
- **NOT tracked yet:** `last_ai_success_at` timestamp + AI confidence score (Phase 4 F-SA-03 task).

**Bug IS-001 impact:** Sleep AI NEVER succeeds in production. 100% heuristic fallback. AI verdict (deep sleep ratio, efficiency, confidence) never engaged. Invisible to users (graceful degradation via fallback), visible only in WARNING logs.

---

## Anh's decisions

### Q1: IS-001 fix timing + scope (**REVISED v2**)

**Decision:** Phase 4 P0 fix. Phase 0.5 = doc-only.

**Scope v1:** path + header + probe (30min).
**Scope v2 (per verify C1):** **path + header + probe + response schema key** (35min).

**Rationale:** Verify pass phat hien response schema mismatch - client doc `body["predictions"][0]` nhung server tra `{"results": [...], "total": N}`. Neu chi fix path ma khong fix schema -> `KeyError: 'predictions'` fire 100%, circuit breaker flip `_available=False` immediately. Ca 4 changes phai trong cung 1 commit.

### Q2: Heuristic fallback — keep?

**Decision (unchanged):** Keep heuristic as permanent fallback.

**Rationale:** Production resilience. Model-api co the down (maintenance, crash, overload). Fallback = graceful degradation, sleep scoring khong bi block.

### Q3: Circuit breaker probe endpoint?

**Decision (unchanged):** Fix probe tu `/health` sang `/api/v1/sleep/model-info` (part of IS-001 fix).

**Rationale:** `/health` chi check server alive. Domain-specific probe = accurate availability check. Model-api co endpoint `/api/v1/sleep/model-info` (verified `healthguard-model-api/app/routers/sleep.py:60`). Mirror fall_ai_client pattern.

### Q4: Dual-endpoint design? (**WORDING REFINED v2 per L2**)

**Decision:** Keep dual-endpoint separation for sleep data lifecycle.

**Rationale:** 
- **Port 8001** = model-api AI inference (`/api/v1/sleep/predict`).
- **Port 8000** = health_system BE DB persistence (`/mobile/telemetry/sleep`).
- Separation of concerns. Independent scaling + failure isolation.

**Note:** Context of IoT simulator stack topology has 3 services total (mobile BE :8000, model-api :8001, sim api :8002). "Dual-endpoint" refers to AI inference vs DB persistence split FOR SLEEP DATA LIFECYCLE, not overall sim ecosystem.

### Q5: FE scoring source display? (**DATA SOURCE CLARIFIED v2**)

**Decision:** FE show scoring source (AI vs heuristic) + connection status.

**Rationale:** Operator can verify AI dang hoat dong sau khi IS-001 fixed. Transparency — biet data quality.

**FE display scope (v2 refined per verify M2):**

| Field | Data source available? | Phase 4 work |
|---|---|---|
| Scoring source badge (AI / Heuristic) | OK `lastScoreSource` already exposed `dependencies.py:2049` | FE consume only |
| AI connection status | OK `lastCheckedAt` + `lastError` already exposed | FE consume only |
| Last successful AI call timestamp | MISSING `last_ai_success_at` chua track | BE +30min (F-SA-03) + FE consume |
| AI confidence score | MISSING - chua inspect model-api response shape + not surfaced | Phase 4 backlog, requires schema check first |

---

## Features moi

Khong co feature moi. Fix bug (path + header + probe + schema key) + surface existing info on FE.

---

## Features DROP

Khong co.

---

## Confirmed Intent Statement (v2)

> Sleep AI Client (module `simulator_core/sleep_ai_client.py`) goi model-api (port 8001, `/api/v1/sleep/predict`) de classify sleep stages (wake/light/deep/REM). Circuit breaker pattern voi domain-specific probe (`/api/v1/sleep/model-info`). Khi AI unavailable, SLEEP service fallback to heuristic scoring (o `sleep_service.py`).
>
> **Bug IS-001 PHAI fix Phase 4 P0 voi 4 changes:** path + probe + header + response schema key. Fix scope v2 = 35min (not 30min per v1).
>
> FE PHAI show scoring source (AI/heuristic) + connection status + last successful call timestamp de operator verify AI hoat dong. 2/4 fields da co data source san (lastScoreSource + lastCheckedAt/lastError), 1/4 can BE task them (lastSuccessAt), 1/4 can inspect response schema truoc (AI confidence).

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status |
|---|---|---|
| SL1 | AI predict: POST sleep record -> model-api -> stage classification | Confirmed (blocked by IS-001 path + schema key) |
| SL2 | Circuit breaker: probe `/api/v1/sleep/model-info` -> available/unavailable state | Phase 4 P0 per IS-001 fix |
| SL3 | Heuristic fallback: score from vitals means when AI down - logic in SLEEP service, NOT in this module | Confirmed (permanent fallback) |
| SL4 | Dual-endpoint for sleep data lifecycle: 8001=AI inference, 8000=DB persistence | Confirmed |
| SL5 | IS-001 fix: path `/api/v1/sleep/predict` + header `X-Internal-Service` + probe `/api/v1/sleep/model-info` + **schema key `results`** | Phase 4 P0 (expanded v2) |
| SL6 | FE: scoring source badge (AI/Heuristic) - data source already exposed | Phase 4 P2 (FE only) |
| SL7 | FE: AI connection status + last success timestamp - partial data ready, need BE task | Phase 4 P2 (FE + small BE) |

---

## Impact on Phase 4 fix plan (v2)

| Phase 4 task | Status | Priority | Effort |
|---|---|---|---|
| IS-001 fix: path + header + probe + **schema key** | Confirmed v2 | P0 | 35min (not 30min v1) |
| Regression test: mock predict, assert URL + schema key parse | Confirmed | P0 | 1h |
| Add `last_ai_success_at` field to `_HealthState` (F-SA-03) | New v2 | P2 | 30min BE |
| FE: scoring source badge (AI vs Heuristic) - consume `lastScoreSource` | Confirmed | P2 | 2-3h |
| FE: AI connection status + last success indicator | Confirmed | P2 | 2h |

**Total Phase 4 effort:** ~6h (IS-001 35min + test 1h + BE 30min + FE 4-5h).

---

## Cross-references

- **Bug:** `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md` (scope expanded per verify C1).
- **Fall AI client (path-correct reference):** `simulator_core/fall_ai_client.py` — same pattern, BUT also missing `X-Internal-Service` header per D-020 (PRE_MODEL_TRIGGER verify finding M4). Pair fix when D-013 enforced.
- **Phase -1 finding:** `topology_v2.md` § Path 5, Drift D-018 (path), D-020 (header), D-022 (probe inconsistency).
- **SLEEP service:** `api_server/services/sleep_service.py` — consumer. Owns heuristic fallback logic (`_compute_sleep_score_with_ai` line 386-407).
- **SIMULATOR_CORE:** `simulator_core/sleep_vitals_enricher.py` — separate utility feeding enriched records.
- **PRE_MODEL_TRIGGER:** `sleep_dispatch.py` (`SleepRiskDispatcher`) — standalone utility, NOT wired in orchestrator (per PRE_MODEL_TRIGGER verify H3).
- **Runtime state:** `api_server/runtime_state.py:_HealthState.last_score_source` + health probe payload `dependencies.py:2039-2052`.
- **ADRs:** No ADR needed for this module. IS-001 fix = surgical code fix. ADR-015 (severity mapping) does not apply here (sleep scoring = int score, not severity enum).

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 Q1-Q5 confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 1 CRITICAL (schema key) + 1 MEDIUM (scope boundary) + 2 LOW | Em |
| 2026-05-13 afternoon | Anh approved F-SA-02/04/05/06 doc fixes | Anh |
| 2026-05-13 afternoon | v2 rewrite + IS-001 bug doc expanded | Em (doc) |
