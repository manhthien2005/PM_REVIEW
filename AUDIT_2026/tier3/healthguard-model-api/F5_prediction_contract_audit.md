# Audit: F5 — services/prediction_contract.py

**File:** `healthguard-model-api/app/services/prediction_contract.py`
**LoC:** 259 (Phase 1 estimate 300 was slightly high)
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 3 deep-dive (model-api)
**Tier2 ref:** [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md)

## Scope

Shared contract builders used by all 3 domain services (fall/health/sleep). Produces:
- `make_meta` — response metadata block
- `make_input_ref` — input reference block
- `build_shap_payload` — SHAP values with base_value extraction + canonical feature names + direction classification
- `build_top_features` — top-N feature picker with preferred/excluded logic
- `build_explanation` — Gemini-or-fallback Vietnamese explanation router
- `_build_risk_explanation` + `_build_sleep_explanation` — template fallback when Gemini unavailable
- Private helpers: `_build_reason`, `_feature_phrase`, `_reason_value`, `_display_path`, `_canonical_feature_name`, `_json_scalar`, `create_request_id`

Phase 1 M02 left lines 80-300 (SHAP base value handling detail + explanation builder) UNSCANNED — this audit owns.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | SHAP base value extraction correct for XGB N+1 layout; grouped shap prevents double-count; canonical feature name merge smart. |
| Readability | 2/3 | 2 parallel explanation builders with domain-if-else smell; `_canonical_feature_name` heuristic subtle. |
| Architecture | 3/3 | Pure functions, keyword-only args, tightly scoped private helpers, no singleton state. |
| Security | 2/3 | `_display_path` could leak repo paths; PHI passes through to Gemini (cross-ref F4). |
| Performance | 3/3 | All O(N) in features. No allocations outside payload rows. No I/O. |
| **Total** | **13/15** | Band: 🟢 Mature |

## Positive findings

- All public functions use keyword-only args (with star syntax in signatures) — prevents positional confusion across 3 caller services.
- `create_request_id` (line 16) uses `uuid4().hex[:12]` for human-readable short IDs (not full UUID) — good log correlation UX.
- `make_meta` (line 20-38) returns dict with timestamp as `datetime` object (not string) — Pydantic response_model handles serialization at API boundary; no premature string conversion.
- `build_shap_payload` base_value extraction (lines 64-67): detects XGBoost N+1 convention via size check `values.size == len(feature_names) + 1`. If model doesn't return base (LGBM pred_contrib also returns N+1 but different semantics — bias column), code treats last column as base. Semantically correct for both XGB and LGBM bias.
- Feature aggregation via canonical names (lines 70-80): handles sklearn ColumnTransformer prefixed names by calling `_canonical_feature_name` which strips prefix OR matches longest key in `feature_values`. Prevents double-counting when OneHotEncoder expands a single feature to multiple columns.
- Direction assignment (risk_up/risk_down) respects `higher_prediction_means_higher_risk` polarity flag (line 82) — sleep flips this correctly (F3 confirmed).
- SHAP values sorted by absolute impact descending (line 95) — top_features gets highest-impact first.
- `build_top_features` preferred/fallback merge (lines 108-118): preferred_features appear in user-specified order within impact-tied groups (tiebreak by `preferred.get(feature, 999)`). Stable and deterministic.
- `build_explanation` (line 143-162): tries Gemini first, falls back to template on ANY exception. Prediction pipeline never blocked by Gemini SDK issues.
- `_build_risk_explanation` + `_build_sleep_explanation` produce varied Vietnamese text by urgency level (3-tier actions list) — reasonable fallback quality.
- `_display_path` (line 234) attempts to display artifact_path relative to BASE_DIR — reduces clutter, handles cross-drive gracefully with try/except.
- `_json_scalar` (line 252-259) handles datetime/date serialization + numpy scalar item conversion + NaN filtering — defensive against joblib-returned numpy types appearing in raw records.

## Findings per axis

### Correctness (3/3)

- `build_shap_payload` rounds impact to 6 decimals (line 88) — avoids float-precision noise in sorted output.
- `build_top_features` filter `float(item["impact"]) > 0` (line 106) — excludes zero-impact features. If all features have zero impact (degenerate case), returns empty list — downstream handles empty anchors list via fallback "Khong co yeu to noi bat".
- `build_explanation` broad `except Exception: pass` (line 160) — CORRECT pattern for fallback service (must never break caller). Documented intent via Gemini module docstring. Acceptable despite normally flagged anti-pattern.
- `_build_risk_explanation` (line 166-205): different action lists for health vs fall-ish families (default branch). `actions[:3]` truncation consistent.
- `_canonical_feature_name` (line 245-251): handles 3 cases: (1) double-underscore prefix (sklearn), (2) direct key match, (3) longest-prefix match. Case 3 is subtle — correct for ColumnTransformer + sklearn preprocessing pipelines.
- P3 — `_reason_value` (line 229-232) strips trailing zeros AND dot via rstrip. Edge case 0.000 -> "0.000" -> "" after both strips! Returns empty string. Low probability since real feature values rarely exactly 0.000, but SHAP-zeroed features could hit this. See Readability P3.

### Readability (2/3)

- Module docstring short (1 line) — could expand to describe contract conventions.
- `_build_risk_explanation` has nested ternary (lines 188-196) for action selection — 5 levels deep. Readable but dense. Same pattern in `_build_sleep_explanation` (line 215-221). Consider extracting to table.
- P2 — Two parallel explanation functions (`_build_risk_explanation` + `_build_sleep_explanation`) with `model_family == "sleep"` branching in `build_explanation` (line 161-162). Adding new model family requires touching `build_explanation`. Acceptable given current 3 families but flag as growth point.
- P3 — `_reason_value` edge case 0.000 returns empty string (see Correctness). Add explicit handling or unit test.
- P3 — `_canonical_feature_name` heuristic (longest-prefix match) is subtle; needs a comment explaining when it fires.
- Names clear: `preferred`, `filtered`, `fallback_items`, `anchors`.

### Architecture (3/3)

- Pure functions (no class, no singleton state) — easily testable.
- Keyword-only args on all publics — API stability.
- Single file responsibility: response contract assembly + explanation fallback routing. Clean.
- **Zero circular imports** — verified: imports only from `app.config.BASE_DIR` (line 11), numpy, stdlib, and lazy `from app.services.gemini_explainer import generate_explanation` (line 145) inside `build_explanation`. Lazy import intentional to avoid Gemini SDK cost at module load.
- Private helpers prefixed underscore and placed at file bottom.

### Security (2/3)

- **PHI through top_features -> Gemini:** `build_top_features` preserves `feature_value` (the raw numeric PHI) in output dict (line 125), which `build_explanation` hands to `generate_explanation`. Root cause tracked at F4. This file is the transit path, not the leak site.
- P3 NEW — `_display_path` (line 234-238): attempts relative path from BASE_DIR, falls back to full path on exception. Response payload exposes `artifact_path: "models/fall/fall_bundle.joblib"` which is internal filesystem info. Low severity (consumers are trusted internal services), but violates generic output-sanitization principle. Acceptable intent (debug/traceability), flag for production hardening.
- `make_input_ref` copies user_id, device_id, event_timestamp, source_file verbatim — these are consumer-supplied. Echoed back. No additional sanitization (acceptable at this layer; router + schema validate).
- `create_request_id` uses uuid4 — cryptographically random, not predictable. Good.
- `_build_reason` (line 207-217): when direction is risk_up and feature in overrides, uses static Vietnamese string. Otherwise constructs a formatted phrase with feature name reflected to explanation text. If feature name were user-controlled, XSS-like risk on downstream consumer rendering. Feature names come from model bundle (trusted, internal) — safe in practice.

### Performance (3/3)

- All operations O(N) in `len(feature_names)`. Typical N = 14-50 features per prediction -> negligible.
- No network I/O (Gemini call owned by F4).
- No file I/O.
- Dict/list comprehensions, no numpy big-array ops outside `np.asarray(shap_row)` reshape (line 63).
- Sort with lambda key — acceptable for N less than or equal to 50.
- No lazy reloads; everything is pure-function.

## Recommended actions (Phase 4)

- [ ] **P2:** Add docstrings to public builders documenting contract shape + `higher_prediction_means_higher_risk` polarity meaning.
- [ ] **P2:** Extract action-tier dict-of-lists in `_build_risk_explanation` and `_build_sleep_explanation` to reduce nested ternary; improves maintainability when adding a 4th model family.
- [ ] **P3:** Add explanatory comment to `_canonical_feature_name` (line 245-251) — current logic is subtle for readers.
- [ ] **P3:** Fix `_reason_value(0.0)` edge case — currently returns empty string. Add test asserting a sensible non-empty result.
- [ ] **P3:** Guard `_display_path` to strip leading `/app/` or absolute prefixes for production hardening (prevent internal path disclosure). Low priority for đồ án 2.
- [ ] **P3:** Add unit tests for:
  - `build_shap_payload` base_value extraction (N+1 vs N input)
  - `build_top_features` preferred/fallback ordering with ties
  - `_canonical_feature_name` 3-branch cases

## Out of scope

- Gemini integration security/perf — F4 owns.
- Response schema correctness — M03 / F6 owns.
- SHAP algorithm accuracy / model interpretability — ML-ops concern.
- Vietnamese phrasing quality in fallback templates — PM/product review.

## Cross-references

- Phase 1: [M02 Services](../../tier2/healthguard-model-api/M02_services_audit.md) — flagged 300 LoC borderline, lines 80-300 unscanned (now covered).
- Phase 1: [M03 Schemas](../../tier2/healthguard-model-api/M03_schemas_audit.md) — PredictionMeta, InputReference, TopFeature, ShapDetails schemas that these builders populate.
- Phase 0.5: [MODEL_API.md](../../tier1.5/intent_drift/model_api/MODEL_API.md) — "Consistent response structure across 3 domains (StandardPrediction + TopFeature + ShapDetails)" verified correct per this audit.
- Upstream callers: F1 [fall_service](./F1_fall_service_audit.md), F2 [health_service](./F2_health_service_audit.md), F3 [sleep_service](./F3_sleep_service_audit.md).
- Downstream: F4 [gemini_explainer](./F4_gemini_explainer_audit.md) (called via lazy import in `build_explanation`).
