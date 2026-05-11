# Module Inventory — healthguard-model-api

**Repo:** `healthguard-model-api/`
**Stack:** FastAPI + onnxruntime + scikit-learn
**Role:** Stateless ML inference service (port 8001)
**Total LoC scope:** ~2,000 (small surface, deep logic)
**Phase 1 track suggestion:** Track 4 (parallel with other repos)

---

## Overview

healthguard-model-api là **leaf service** trong topology — chỉ provide ML inference cho health_system BE + IoT sim. Không call ra ngoài. Không có DB.

**Critical path:**
- POST `/api/v1/health/predict` — health risk score (called by health_system BE)
- POST `/api/v1/fall/predict` — fall detection (called by IoT sim)
- POST `/api/v1/sleep/predict` — sleep score (called by health_system BE)

**Known issues từ Phase -1:**
- [D-013](../tier1/api_contract_v1.md): Predict endpoints không có internal secret check → P0 Phase 4
- [D-014](../tier1/api_contract_v1.md): `/health` semantic collision (system probe vs health risk) → P2 Phase 4

---

## Modules

### M01: `routers/` — HTTP layer

**Path:** `healthguard-model-api/app/routers/`
**Files:** 4 (system.py, fall.py, health.py, sleep.py)
**LoC:** ~250
**Effort:** S (~3h)
**Priority:** P0 (entry point, security gap D-013)
**Dependencies:**
- Upstream callers: health_system BE (`model_api_client.py`), IoT sim (`fall_ai_client.py`, `sleep_ai_client.py`)
- Downstream: `services/` (fall_service, health_service, sleep_service)

**Audit focus per axis:**
- Security: internal secret check (currently missing — D-013)
- Correctness: HTTPException handling, response shape per `prediction_contract.py`
- Performance: blocking sync ML inference trong async endpoint?

### M02: `services/` — ML inference logic

**Path:** `healthguard-model-api/app/services/`
**Files:** 8 (fall_service, fall_featurize, health_service, sleep_service, sleep_features, gemini_explainer, prediction_contract, sklearn_sleep_pickle_compat)
**LoC:** ~1,200 (heaviest module)
**Effort:** L (~12h)
**Priority:** P0 (core business value, also where Sleep AI bug surfaced per IS-001 if path fixed)
**Dependencies:**
- Upstream: `routers/`
- Downstream: model artifacts (`.onnx`, `.pkl` files), gemini API external

**Audit focus per axis:**
- Architecture: service singleton pattern, model load lifecycle, feature pipeline structure
- Correctness: featurize tolerance for missing fields, model compatibility pickle wrapper
- Security: gemini API key handling, model artifact path traversal
- Performance: ML inference latency, batch endpoint optimization, sample case caching

### M03: `schemas/` — Pydantic models

**Path:** `healthguard-model-api/app/schemas/`
**Files:** 4 (common, fall, health, sleep)
**LoC:** ~400
**Effort:** S (~2h)
**Priority:** P1 (contract definitions)
**Dependencies:**
- Upstream: `routers/` use as response_model
- Downstream: none (leaf)

**Audit focus per axis:**
- Correctness: field validators (ge/le/etc), default values reasonable
- Readability: schema documentation (description)
- Architecture: shared types in `common.py`, no cross-import between schemas

### M04: `config.py` + `main.py` — Bootstrap

**Path:** `healthguard-model-api/app/{config.py, main.py}`
**LoC:** ~150
**Effort:** S (~1h)
**Priority:** P1 (initialization correctness)
**Dependencies:** —

**Audit focus per axis:**
- Security: CORS config, env loading via pydantic-settings, secrets handling
- Architecture: lifespan event for model load, exception handler registration
- Performance: model load lazy vs eager

### M05: `scripts/` — Build sample cases (dev only)

**Path:** `healthguard-model-api/scripts/`
**Files:** 7 (build_*_sample_cases, inspect_modelok, write_per_case_json, build_runtime_samples)
**LoC:** ~600
**Effort:** S (~2h)
**Priority:** P2 (dev tooling, not production)
**Dependencies:** model artifacts

**Audit focus per axis:**
- Readability: script comments, CLI args clarity
- Correctness: sample generation deterministic, edge cases coverage

---

## Phase 1 macro audit plan

**Single track 4 covers entire repo:**

| Order | Module | Why this order |
|---|---|---|
| 1 | M04 (Bootstrap) | Start with init flow, understand global state |
| 2 | M03 (Schemas) | Understand contracts before logic |
| 3 | M01 (Routers) | Entry points, security surface |
| 4 | M02 (Services) | Heavy lift — leave for last when context full |
| 5 | M05 (Scripts) | Optional — only if effort budget remaining |

**Estimated total Phase 1 effort:** ~20h (M01+M02+M03+M04). M05 defer if time-constrained.

---

## Phase 3 deep-dive candidates

Based on Phase -1 findings + repo characteristic:

- [ ] `services/fall_service.py` — fall detection critical path, IS-001 fix point
- [ ] `services/sleep_service.py` — sleep AI (related to IS-001)
- [ ] `services/health_service.py` — health risk path (called by mobile flow)
- [ ] `services/gemini_explainer.py` — external API integration, API key handling
- [ ] `services/prediction_contract.py` — shared contract logic, version middleware mentioned

---

## Out of scope

- Model training pipeline (`scripts/` partial — only build_*_sample_cases reviewed)
- Model artifact storage strategy (S3 vs local) — infra concern
- Gemini API integration depth — limited to security/contract review
- ONNX runtime tuning — performance only review surface
- Test coverage matrix — separate report
