# Module Inventory — Iot_Simulator_clean

**Repo:** `Iot_Simulator_clean/`
**Stack:** FastAPI (api_server) + simulator_core (Python) + simulator-web (React)
**Role:** IoT device + sensor data simulator. Pushes vitals/sleep/fall events tới health_system BE.
**Total LoC scope:** ~8,000 (large surface)
**Phase 1 track suggestion:** Track 5 (parallel with other repos)

---

## Overview

IoT Simulator có 2 sub-systems:
- `api_server/` — FastAPI HTTP server (port 8002) cho admin UI control simulator
- `simulator_core/` — pure Python sim engine (no HTTP)
- `simulator-web/` — React dashboard (control + visualize)
- `transport/`, `pre_model_trigger/`, `dataset_adapters/`, `etl_pipeline/` — support modules

**Known issues từ Phase -1:**
- [IS-001](../../BUGS/IS-001-sleep-ai-client-wrong-path.md): Sleep AI client POST sai path → P0 Phase 4
- [D-015](../tier1/api_contract_v1.md): No visible auth on sim endpoints → P1 Phase 4 verify
- [D-018, D-020, D-022](../tier1/topology_v2.md): Sleep AI client multiple issues
- [D-019](../tier1/topology_v2.md) → Resolved by [ADR-004](../../ADR/004-api-prefix-standardization.md): API prefix standardize
- [D-021](../tier1/topology_v2.md): IoT sleep push to backend no auth verify → P0 Phase 4

---

## Modules

### M01: `api_server/routers/` — HTTP layer

**Path:** `Iot_Simulator_clean/api_server/routers/`
**Files:** 10 (analytics, dashboard, devices, events, registry, scenarios, sessions, settings, verification, vitals)
**LoC:** ~1,200
**Effort:** M (~6h)
**Priority:** P0 (entry point + D-015 auth concern)
**Dependencies:**
- Upstream callers: simulator-web React app
- Downstream: `services/`, `runtime_state.py`, `dependencies.py`

**Audit focus:**
- Security: auth coverage (verify middleware applied), D-015 status
- Correctness: input validation, error handling per endpoint
- Architecture: thin routers calling services

### M02: `api_server/services/` — Sim runtime business logic

**Path:** `Iot_Simulator_clean/api_server/services/`
**Files:** 5 (alert_service, device_service, session_service, sleep_service, vitals_service)
**LoC:** ~2,000
**Effort:** L (~10h)
**Priority:** P0 (core business + D-021 related sleep push)
**Dependencies:**
- Upstream: `routers/`, `runtime_state.py`
- Downstream: `simulator_core/`, `backend_admin_client.py`, `transport/`

**Audit focus:**
- Architecture: service decomposition (sleep_service was extracted from God object per code comment)
- Correctness: thread safety (RLock usage), state mutation
- Security: sleep push auth (D-021)
- Performance: shared httpx.Client (CRITICAL #2 fix referenced)

### M03: `api_server/middleware/` + `dependencies.py`

**Path:** `Iot_Simulator_clean/api_server/{middleware/, dependencies.py}`
**Files:** 3 (auth.py, rate_limit.py, dependencies.py)
**LoC:** ~600
**Effort:** S (~3h)
**Priority:** P0 (auth verification per D-015)
**Dependencies:** runtime singletons

**Audit focus:**
- Security: auth middleware enforcement, rate limit thresholds
- Architecture: singleton pattern thread safety
- Correctness: dependency injection, override hooks for tests

### M04: `api_server/repositories/` + DB

**Path:** `Iot_Simulator_clean/api_server/{repositories/, db.py}`
**Files:** 2 (device_repository.py, db.py)
**LoC:** ~300
**Effort:** S (~2h)
**Priority:** P1 (shared DB writes to `devices`, `users` read)
**Dependencies:** SQLAlchemy, shared Postgres

**Audit focus:**
- Security: SQL injection (raw `text()` usage seen trong `sim_admin_service.py`)
- Correctness: transaction boundaries
- Performance: connection pool sizing

### M05: `api_server/backend_admin_client.py` + `sim_admin_service.py`

**Path:** `Iot_Simulator_clean/api_server/`
**Files:** 2 files
**LoC:** ~600
**Effort:** S (~3h)
**Priority:** P0 (ADR-004 impacts client base URL)
**Dependencies:** httpx, health_system BE

**Audit focus:**
- Security: X-Internal-Service header (verified ✓), retry logic
- Correctness: error handling, status code mapping
- Architecture: dual sync/async client (BackendAdminClient pattern)

### M06: `simulator_core/` — Pure sim engine

**Path:** `Iot_Simulator_clean/simulator_core/`
**Files:** 11 (fall_ai_client, sleep_ai_client, dataset_registry, generators, sleep_vitals_enricher, ...)
**LoC:** ~2,000
**Effort:** L (~10h)
**Priority:** P0 (IS-001 bug location)
**Dependencies:** dataset_adapters, model-api (port 8001)

**Audit focus:**
- Correctness: IS-001 fix point (sleep_ai_client path)
- Security: D-020 (missing X-Internal-Service header)
- Architecture: AI client pattern consistency (fall_ai_client vs sleep_ai_client)
- Performance: stdlib urllib vs httpx tradeoff

### M07: `pre_model_trigger/` — Rule engine

**Path:** `Iot_Simulator_clean/pre_model_trigger/`
**Files:** 17 (rules_config.json + Python rule engine)
**LoC:** ~1,000
**Effort:** M (~6h)
**Priority:** P1 (alerting fast path before ML)
**Dependencies:** simulator_core

**Audit focus:**
- Architecture: config-driven rules (rules_config.json)
- Correctness: threshold logic, edge cases per vital
- Readability: rule naming, traceability config → engine code

### M08: `transport/` — Publisher

**Path:** `Iot_Simulator_clean/transport/`
**Files:** 6 (http_publisher, mqtt_publisher, base_publisher, json_utils)
**LoC:** ~400
**Effort:** S (~2h)
**Priority:** P1
**Dependencies:** —

**Audit focus:**
- Architecture: publisher abstraction (HTTP vs MQTT swappable)
- Correctness: backpressure, retry, ack count tracking
- Security: payload size limits

### M09: `dataset_adapters/` + `etl_pipeline/`

**Path:** `Iot_Simulator_clean/{dataset_adapters/, etl_pipeline/}`
**LoC:** ~800
**Effort:** M (~5h)
**Priority:** P2 (dev tooling for dataset ingestion)
**Dependencies:** raw datasets

**Audit focus:**
- Correctness: parquet schema validation
- Performance: batch read efficiency

### M10: `simulator-web/` — React dashboard

**Path:** `Iot_Simulator_clean/simulator-web/`
**LoC:** ~3,000+ (largest sub-module by LoC)
**Effort:** L (~12h)
**Priority:** P2 (dev tool UI, not user-facing)
**Dependencies:** api_server endpoints

**Audit focus:**
- Architecture: component structure
- Correctness: error boundary, async state mgmt
- Performance: real-time chart rendering, websocket connection
- Security: dev-only access, no auth required acceptable?

---

## Phase 1 macro audit plan

**Track 5 multi-pass approach** (repo too large for single linear pass):

| Pass | Modules | Effort |
|---|---|---|
| Pass A (Security + bugs) | M03, M05, M06, M01 | ~14h — focus auth + IS-001 fix prep |
| Pass B (Core logic) | M02, M07 | ~16h — sim runtime + rule engine |
| Pass C (Data + transport) | M04, M08, M09 | ~9h |
| Pass D (Frontend) | M10 | ~12h (optional, defer if time-constrained) |

**Estimated total:** ~39h core + ~12h optional frontend. Plan to skip M10 in Phase 1 (defer Phase 3 if needed).

---

## Phase 3 deep-dive candidates

- [ ] `simulator_core/sleep_ai_client.py` — IS-001 fix
- [ ] `simulator_core/fall_ai_client.py` — verify path correct, D-020 fix
- [ ] `api_server/services/sleep_service.py` — sleep push flow + D-021
- [ ] `api_server/sim_admin_service.py` — SQL injection review
- [ ] `pre_model_trigger/health_rules/rules_config.json` — alerting threshold validation
- [ ] `api_server/middleware/auth.py` — D-015 verify enforcement

---

## Out of scope

- `simulator-web/` React dashboard (defer P2)
- `datasets/`, `normalized_artifacts/` — data files, not code
- `tests/` (em focus code, test report separately)
- Docker/deployment configs
- `BUGFIX_REPORT.md` historical record (em không re-audit history)
