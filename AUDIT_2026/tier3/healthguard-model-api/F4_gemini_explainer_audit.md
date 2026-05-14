# Audit: F4 — services/gemini_explainer.py

**File:** `healthguard-model-api/app/services/gemini_explainer.py`
**LoC:** 183 (Phase 1 estimate 215 was high)
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Gemini client for generating Vietnamese explanation of risk/sleep predictions. Replaces rule-based templates. Fire-and-forget with silent fallback. Lazy client init, threading lock protection, hard timeout via daemon thread join.

Phase 1 M02 left lines 80-215 (prompt template) UNSCANNED for PHI check — this audit owns that verification.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Timeout via thread join + fallback, BUT daemon thread orphaned on timeout. |
| Readability | 3/3 | Clear module docstring with design principles, separated constants. |
| Architecture | 2/3 | Threading hack around sync SDK, hardcoded config not Settings-exposed. |
| Security | 1/3 | **P1 NEW: PHI values embedded in outbound prompt to external LLM service.** |
| Performance | 1/3 | **P1 NEW: thread join blocks event loop up to 12s per prediction.** |
| **Total** | **9/15** | Band: 🟠 Needs attention |

## Positive findings

- Module docstring (lines 1-14) documents 4 design principles: fire-and-forget, sync-only, single-client reuse, hard timeout. Clear authorial intent.
- `load_dotenv()` wrapped in try/except ImportError (lines 46-49) — works without python-dotenv installed.
- External service credential fetched from environment variable (line 51), stripped, empty value triggers early return with warning log — no literal credential in source.
- Client lazy-init behind threading lock (double-checked locking pattern, lines 37-42) — safe under concurrent first-request race.
- **Markdown fence stripping** (lines 136-140): detects triple-backtick then optionally strips language marker. Handles model output ignoring `response_mime_type`.
- `response_mime_type="application/json"` (line 129) requests structured output.
- `thinking_budget=512` (lines 130-132) caps reasoning tokens -> bounds cost + latency.
- `recommended_actions` list comprehension (line 147) filters empty strings + truncates to 3 -> stable contract shape.
- `temperature=0.3` (line 127) -> low randomness -> consistent outputs across similar inputs.
- `_RISK_LEVEL_VI` + `_MODEL_FAMILY_VI` dict (lines 66-77) — extendable translation tables.

## Findings per axis

### Correctness (2/3)

- Silent fallback semantics consistent: any error (SDK missing, credential missing, timeout, JSON parse error) -> returns None -> caller falls back to rule-based template in prediction_contract.py.
- **P1 NEW — Orphaned daemon thread on timeout (lines 164-170):**
  - `threading.Thread(target=_call, daemon=True)` started, `t.join(timeout=_TIMEOUT_SECONDS)` blocks 12s.
  - If `t.is_alive()` after 12s, function returns None — but daemon thread KEEPS RUNNING. Outbound HTTP call continues, response arrives eventually, stored in closure state which is discarded.
  - **Impact:** under burst load, thread count grows unbounded; uvicorn worker memory creeps.
  - **Mitigation hint:** use httpx Timeout or SDK-level socket timeout instead of Python-thread timeout. SDK internally uses httpx; timeout belongs at client config.
- P2 — `raw = response.text.strip()` (line 134) assumes `response.text` never None. SDK can return None if safety blocked. A None strip would raise AttributeError caught by broad except (line 150) -> returns None via exc_holder, falls back. Safe but implicit.
- P3 — JSON parse uses `json.loads` directly (line 141). If output is malformed JSON (fence stripped but invalid), caught by broad except. OK.
- P3 — `parsed.get("recommended_actions") or []` (line 145) accepts non-list silently. List comprehension over a string would iterate chars. Minor.

### Readability (3/3)

- Module docstring + sectioning comments (Model selection, Prompt builder, Public API) — easy navigation.
- `_format_features` (lines 79-87) compact, clear — arrow unicode for direction marker.
- `_build_prompt` returns triple-quoted f-string (lines 96-120) — readable template. Vietnamese + English mixed (intent: Vietnamese output, English for schema instruction).
- Type hints precise (`Sequence[Mapping[str, Any]]`) — caller contract clear.
- `nonlocal result` pattern in `_call` inner function (line 142) — Python idiomatic.

### Architecture (2/3)

- Lazy singleton client pattern — correct for thread-safe init.
- Import hidden inside `_get_client` (line 55) — intentional to allow module load without SDK installed. Good.
- Per-call SDK subimport (line 119) — defers SDK loading but repeated dict lookup on every call -> minor perf hit.
- Hardcoded config (`_GEMINI_MODEL`, `_TIMEOUT_SECONDS`, `_MAX_OUTPUT_TOKENS`, `_THINKING_BUDGET`) at lines 21-24 — NOT exposed to Settings. Already flagged Phase 1 M02 (P1 backlog). Re-ref, not new.
- Threading-as-timeout is a well-known Python anti-pattern for async web servers; the file honestly admits "Sync-only: the rest of the prediction pipeline is sync". But the prediction pipeline IS called from async routes (M01), so this file's assumption is upstream-dependent.
- No retry logic — single attempt. Acceptable for non-critical fallback.

### Security (1/3)

- **P1 NEW — PHI data leak to external LLM service (F-MA-P3-01):**
  - `_format_features` (lines 79-87) embeds raw `feature_value` into prompt body.
  - Upstream callers (health_service + sleep_service, confirmed F2/F3 audits) pass vital signs + sleep metrics:
    - Health: heart_rate, spo2, body_temperature, systolic_blood_pressure, diastolic_blood_pressure, respiratory_rate, derived_map
    - Sleep: sleep_efficiency_pct, stress_score, spo2_mean_pct, heart_rate_mean_bpm, sleep_latency_minutes, wake_after_sleep_onset_minutes
  - These values are PHI under HIPAA-class health data per `40-security-guardrails.md`.
  - Prompt ships to external service over HTTPS. Consumer-grade API path retains prompts for model improvement unless Workspace/BAA contract used.
  - **Risk scale:** low for đồ án 2 (synthetic IoT sim data, no real patients). HIGH for production with real users.
  - **Mitigation options for Phase 4:**
    1. Replace values with banded labels: spo2 tagged as "low" instead of numeric 92.5. Lossless for explanation purpose.
    2. Send only feature names + direction, no numeric value.
    3. Gate explainer on env flag in production (default off).
    4. Route through Google Cloud Vertex AI with signed BAA (production-only, cost+effort).
- **Credential protection:**
  - Fetched from environment variable (line 51) — good.
  - Not echoed in any log statement — verified search for credential variable name in log format strings: no leak.
  - Value stripped of whitespace (line 51) — prevents trivial env-var injection.
- **Prompt injection risk:**
  - Feature names come from model bundle (`feature_names_out`) — internal, trusted.
  - Feature values come from upstream payload (consumer-controlled). A malicious consumer could inject special instructions via vital sign fields — but Pydantic schema coerces these to float, so text injection via numeric fields blocked. Via feature name: names from model bundle only, safe.
  - Verdict: prompt injection surface = very low.
- **Not re-flagged (Phase 1):** explainer config hardcoded (P1 M02 backlog).

### Performance (1/3)

- **P1 NEW — Thread join blocks predict_api for up to 12s:**
  - `t.join(timeout=12)` (line 168) called synchronously from `build_explanation` -> `predict_api` -> FastAPI async route (M01).
  - Since prediction pipeline is sync (upstream call from awaited endpoint), the 12s blocks the event loop for the uvicorn worker.
  - For fall detection (life-safety path, P1 latency), 12s worst-case blocks ALL concurrent requests on that worker. Single worker = total outage.
  - Even happy path (~1-3s typical Flash-tier latency) ties up the event loop.
  - **M01 audit already dinged sync ML inference; explainer adds another blocker of larger magnitude.**
  - **Mitigation options:**
    1. Run explainer in background task after response returned (FastAPI BackgroundTasks), attach to prediction via cache/webhook.
    2. Move explainer call to a separate `/explain` endpoint that consumer calls async after predict completes.
    3. Short-circuit explainer entirely for life-safety paths (fall), keep for sleep + health low-urgency flow.
- **Orphaned daemon threads:** see Correctness P1 — memory growth concern under load.
- Repeated inline SDK subimport (line 119) per call — negligible but dirty.
- SDK network timeout NOT configured at client level — only Python-thread timeout. HTTP-level timeout would be cleaner.

## Recommended actions (Phase 4)

- [ ] **P1:** PHI redaction in prompt — replace raw values with bands or strip values entirely. Modify `_format_features` + update schema for a banded feature-value field.
- [ ] **P1:** Decouple explainer from predict_api critical path — use FastAPI BackgroundTasks or separate `/explain` endpoint. Eliminates 12s event-loop block.
- [ ] **P1:** Replace thread-join timeout with SDK-native socket timeout (httpx Timeout config on the SDK client) to avoid orphaned threads.
- [ ] **P2:** Expose `_GEMINI_MODEL`, `_TIMEOUT_SECONDS`, `_MAX_OUTPUT_TOKENS`, `_THINKING_BUDGET`, and new enable-flag via Settings (cross-ref Phase 1 M02 P1 backlog).
- [ ] **P2:** Add unit test for prompt content — assert no raw numeric vital value present when redaction enabled.
- [ ] **P3:** Move SDK subimport to module level (behind try/except) to avoid per-call dict lookup.
- [ ] **P3:** Handle `response.text is None` explicitly (safety-blocked output) before the strip call.

## Out of scope

- Prompt engineering quality (is explanation useful?) — PM/product review, not code audit.
- Pricing model / cost budgeting — business concern.
- Non-English prompt LLM accuracy benchmarking — ML evaluation.
- Alternative LLM providers evaluation (OpenAI, Claude, local) — architecture decision for Phase 5+.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) — noted explainer config hardcoded + lines 80-215 unscanned for PHI (now covered).
- Phase 0.5: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — explainer noted "optional, graceful fallback". PHI leak to third-party NOT discussed. Flag for intent drift doc revision.
- Security rule: `40-security-guardrails.md` PHI section — contradiction between "HTTPS mandatory production" rule and current explainer behavior (meets HTTPS but still third-party data processor).
- Consumer audits: F2 [health_service](./F2_health_service_audit.md) + F3 [sleep_service](./F3_sleep_service_audit.md) + F1 [fall_service](./F1_fall_service_audit.md) — all feed data into this explainer. F1 fall is least PHI-risky (IMU sensors), F2 health most risky (raw vitals), F3 sleep middle.
- Upstream integration point: [F5 prediction_contract.py audit](./F5_prediction_contract_audit.md) — `build_explanation` is the function that calls `generate_explanation`.
