# Audit: M06 — simulator_core (AI clients + sim engine)

**Module:** `Iot_Simulator_clean/simulator_core/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 5A (IoT sim Pass A — security focus)

## Scope

Pass A focus: AI clients (consumer side cho model-api). Other simulator_core files (dataset_registry, generators, session, sleep_vitals_enricher) defer Pass B.

| File | LoC | Role |
|---|---|---|
| `simulator_core/fall_ai_client.py` | 530 | Fall AI HTTP client → model-api `/api/v1/fall/*` (stdlib urllib) |
| `simulator_core/sleep_ai_client.py` | 68 | Sleep AI HTTP client → model-api (stdlib urllib) — **IS-001 location** |

**Total Pass A scope:** ~600 LoC

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | **IS-001: sleep_ai_client posts to /predict (404)**. Fall client recently fixed. |
| Readability | 3/3 | Excellent docstrings, design notes in fall_ai_client (Architecture context). |
| Architecture | 2/3 | Two clients should share common base. stdlib urllib vs httpx mixed (M05 uses httpx). |
| **Security** | **1/3** | Missing X-Internal-Service header on BOTH clients (D-020). No auth → DDoS risk. |
| Performance | 2/3 | Circuit breaker simple ✓. Re-probe cooldown 30s on fall ✓. Sleep client no self-heal. |
| **Total** | **9/15** | Band: **🟠 Needs attention** (would be 🔴 if Security=0 enforced strictly but partial header coverage saves point) |

## Findings

### Correctness (1/3) — IS-001 critical

**fall_ai_client.py:**
- ✓ POST `/api/v1/fall/predict` (line 375) — **path correct**
- ✓ GET `/api/v1/fall/model-info` for availability probe (line 292) — **path correct** (recently fixed per comment line 282-291: "earlier `/api/v1/fall/info` was a copy-paste from the SleepAIClient pattern that doesn't exist on the fall router")
- ✓ Min window check `len(samples) < MIN_WINDOW_SAMPLES` (line 357-363)
- ✓ Truncate to exact capacity `samples[:MIN_WINDOW_SAMPLES]` (line 366) — deterministic payload
- ✓ Per-variant context map `FALL_VARIANT_CONTEXT` (line 80-91) — controls environment signal injection
- ✓ Self-heal: re-probe after `_RECHECK_COOLDOWN_SEC = 30.0` (line 264, 345-350)
- ✓ Exception hierarchy: HTTPError + URLError + TimeoutError → log + set `_available=False`
- ✓ `normalise_verdict` (line 438-519) converts model output to FE-friendly shape with fallback for field rename tolerance (`feature` or `name` or `feature_name`, line 461-466)

**sleep_ai_client.py — 🚨 IS-001:**
- 🚨 **POST `/predict` (line 53) — 404 ENDPOINT!**
- 🚨 Should be `/api/v1/sleep/predict` (model-api router prefix `/api/v1/sleep` + endpoint `/predict`)
- 🚨 GET `/health` (line 33) — works (system endpoint) but misleads `_available=True` after probe
- ⚠️ No self-heal cooldown (sleep client missing pattern that fall client uses) — once `_available=False`, stays False forever
- ⚠️ Exception handler too broad: `except (HTTPError, URLError, TimeoutError, json.JSONDecodeError, Exception)` (line 41, 64) — `Exception` catches everything including KeyboardInterrupt (bad practice in Python 3)
- ⚠️ Hardcoded `{"backend": "onnx", "records": [sleep_record]}` payload shape (line 51) — verify Phase 3 matches `SleepPredictionRequest` schema (em đã thấy schema expects `records` only, no `backend` field)

**Comment cho IS-001:** Already logged as bug [IS-001](../../../BUGS/IS-001-sleep-ai-client-wrong-path.md) Phase -1.C. Fix Phase 4.

### Readability (3/3)

**fall_ai_client.py outstanding:**
- ✓ **Architecture context block** docstring (line 11-19) — explains port 8001 vs port 8000 separation. Onboarding-friendly.
- ✓ **Input/output contract** in module docstring (line 21-53) — JSON shape documented at point of use
- ✓ **Comment for `_RECHECK_COOLDOWN_SEC`** (line 261-264) explains why self-heal exists
- ✓ **Comment for `check_availability` URL choice** (line 282-291) — historical context for fix
- ✓ Per-variant context dict with comments (line 80-91) explaining each variant's intent

**sleep_ai_client.py:**
- ✓ Brief module docstring (line 1-11) — explains dual endpoint design (port 8001 AI vs port 8000 DB)
- ✓ Class docstring "Small stdlib-only client with a simple circuit breaker" (line 24)
- ⚠️ NO docstring on `predict()` explaining wrong path bug (it's the bug location, but no audit trail)

### Architecture (2/3)

**Pros:**
- ✓ Both clients use stdlib `urllib.request` (no extra dep)
- ✓ Simple circuit breaker via `_available: bool | None` (None=unprobed, T/F = state)
- ✓ Fall client `normalise_verdict` separates raw model output from FE consumption shape — clear concern split
- ✓ `motion_window_to_samples` helper (fall_ai_client.py:160-244) → reusable converter

**Cons:**
- ⚠️ **Two clients duplicate circuit breaker logic** — should share base class `AIClient` or mixin
- ⚠️ Different default URLs: fall = `http://127.0.0.1:8001`, sleep = `http://localhost:8001` — should consolidate via shared constant
- ⚠️ Different probe paths: fall = `/api/v1/fall/model-info`, sleep = `/health` — inconsistent. Sleep should use `/api/v1/sleep/model-info` (Phase -1.C [D-022](../../tier1/topology_v2.md))
- ⚠️ M05 (backend_admin_client) uses **httpx** but M06 (AI clients) uses **stdlib urllib** — mixed transport. Reason valid (stdlib = no extra dep) but cross-file inconsistency makes future refactor harder.
- ⚠️ `_GEMINI_MODEL` and `_TIMEOUT_SECONDS` hardcoded (line 264) — should be configurable

### Security (1/3) — D-020

**🚨 D-020 (Phase -1.C):** BOTH clients missing `X-Internal-Service: iot-simulator` header:

```python
# fall_ai_client.py:374-379
request = Request(
    f"{self.base_url}/api/v1/fall/predict",
    data=payload,
    method="POST",
    headers={"Content-Type": "application/json"},   # ← missing X-Internal-Service
)

# sleep_ai_client.py:52-57
request = Request(
    f"{self.base_url}/predict",
    data=payload,
    method="POST",
    headers={"Content-Type": "application/json"},   # ← missing X-Internal-Service
)
```

**Impact:**
- Currently model-api accepts all (D-013 Phase -1.B)
- Phase 4 D-013 fix (add `verify_internal_secret`) → IoT sim AI calls **break unless header added simultaneously**

**Score 1/3 rationale:** Public network → DDoS risk. But IoT sim runs locally (port 8001 → 8001) typically, low real-world exposure. Score 1 (not 0) because no critical bypass enable.

**Other security positives:**
- ✓ No PHI leak in logs (logs use `device_id` not raw vitals)
- ✓ No hardcoded secrets
- ✓ Exception handlers don't leak internal state via response (returns None silently)

### Performance (2/3)

**Positives:**
- ✓ stdlib urllib zero-overhead (no httpx async setup cost)
- ✓ Fall client self-heal cooldown 30s prevents thundering retry
- ✓ Timeout enforced (5s default, line 269)
- ✓ Min sample check before HTTP call (avoid network round-trip với invalid payload)

**Concerns:**
- ⚠️ stdlib `urlopen` — synchronous blocking. If called from async context (em verify Phase 3 caller), blocks event loop.
- ⚠️ No connection reuse — each `urlopen` creates new TCP connection (stdlib doesn't pool). httpx.Client would pool, save SSL handshake. Acceptable cho low traffic dev tooling.
- ⚠️ Sleep client `predict()` no self-heal — slower recovery sau transient error
- ⚠️ Payload converted via `json.dumps` then `.encode("utf-8")` — minor overhead vs httpx `json=` arg

## Recommended actions (Phase 4)

### P0 — Critical bug fix
- [ ] **IS-001:** Fix `sleep_ai_client.py:53` POST path: `"/predict"` → `"/api/v1/sleep/predict"`
- [ ] **D-020:** Add `X-Internal-Service: iot-simulator` header to BOTH AI client POST requests (simultaneous với model-api D-013 fix)

### P1 — Consistency
- [ ] **D-022:** Change sleep client probe `/health` → `/api/v1/sleep/model-info` (mirror fall client pattern, fall did same fix earlier)
- [ ] Add self-heal cooldown to sleep client (mirror fall pattern)
- [ ] Consolidate default base URL constant — both clients reference same value
- [ ] Fix overly-broad `except Exception` in sleep client (line 41, 64) — keep narrow `(HTTPError, URLError, TimeoutError, JSONDecodeError)` only

### P2 — Architecture cleanup
- [ ] Extract common `AIClient` base class with circuit breaker + self-heal
- [ ] Consider migration stdlib urllib → httpx (consistency with M05) — defer unless other reason

### P3 — Defense
- [ ] Add request_id to outbound calls (correlation with model-api logs)
- [ ] Log probability + verdict on successful prediction (audit trail)

## Out of scope (defer Pass B + Phase 3)

- Other simulator_core files (dataset_registry, generators, session, sleep_vitals_enricher) — Pass B
- `normalise_verdict` field mapping correctness (em scan high-level, Phase 3 verify each FE field)
- `motion_window_to_samples` math validation (orientation derivation)
- Per-variant context tuning (FALL_VARIANT_CONTEXT)

## Cross-references

- **Bug:** [IS-001](../../../BUGS/IS-001-sleep-ai-client-wrong-path.md) — sleep AI client wrong path
- Phase -1.B: [D-013](../../tier1/api_contract_v1.md) — model-api needs `verify_internal_secret` (PAIR fix with M06 header add)
- Phase -1.C: [D-018](../../tier1/topology_v2.md) — IS-001 finding source
- Phase -1.C: [D-020](../../tier1/topology_v2.md) — missing X-Internal-Service header (THIS module)
- Phase -1.C: [D-022](../../tier1/topology_v2.md) — sleep probe URL inconsistency
- Phase 0: Module M06 in [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)
- Consumer side: `healthguard-model-api/app/routers/{fall,sleep}.py` — auditied [M01 Track 4](../healthguard-model-api/M01_routers_audit.md)
