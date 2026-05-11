# Module Inventory — health_system backend (FastAPI mobile BE)

**Repo:** `health_system/`
**Stack:** FastAPI + SQLAlchemy (raw + ORM) + JWT
**Role:** Mobile backend, port 8000, serve `/api/v1/mobile/*` (effective via root_path hack — ADR-004 to fix)
**Path:** `health_system/backend/app/`
**Total LoC scope:** ~10,000+ (deep business logic for elderly health monitoring)
**Phase 1 track suggestion:** Track 2 (parallel)

---

## Overview

health_system backend là **mobile BE** — heaviest business logic trong workspace. Multi-role auth (user, caregiver, admin internal), risk inference orchestration, FCM push fanout, fall/SOS dispatch.

**Critical user flows:**
- Auth: register → verify OTP → login → JWT issue (with token_version rotation)
- Telemetry ingest: IoT push vitals/sleep/imu-window → trigger risk calc → push alert
- SOS dispatch: mobile trigger → fanout FCM to linked caregivers
- Risk inference: orchestrate model-api calls (circuit breaker) → store risk_scores → escalate alert

**Known issues từ Phase -1:**
- [D-012](../tier1/api_contract_v1.md): Telemetry endpoints inconsistent internal guard → P1 Phase 4
- [D-021](../tier1/topology_v2.md): `/sleep` + `/imu-window` + `/sleep-risk` no internal guard → **P0 Critical**
- [D-019](../tier1/topology_v2.md) → ADR-004: API prefix fix (root_path hack)
- D1: severity vocab CheckConstraint `normal/high/critical` (wrong) needs fix → P1 Phase 4

---

## Modules

### M01: `app/main.py` — Bootstrap

**Path:** `health_system/backend/app/main.py`
**LoC:** ~120
**Effort:** S (~1h)
**Priority:** P0 (ADR-004 fix entry point — drop `root_path` hack)
**Dependencies:** core/, api/router.py

**Audit focus:**
- Architecture: lifespan event, middleware order, exception handler placement
- Security: CORS allowlist (currently `*`?), TrustedHost middleware
- ADR-004 prep: ready for prefix change

### M02: `app/api/routes/` — HTTP routing

**Path:** `health_system/backend/app/api/routes/`
**Files:** 13 (auth, profile, device, health, emergency, fall_events, risk, notifications, relationships, settings, telemetry, admin, monitoring)
**LoC:** ~2,500
**Effort:** L (~10h)
**Priority:** P0 (entry surface + D-021 fix point)
**Dependencies:** services/, schemas/, core/dependencies

**Audit focus:**
- Security: D-021 add `Depends(require_internal_service)` to telemetry sleep/imu endpoints
- Architecture: APIRouter prefix consistency (post-ADR-004)
- Correctness: HTTP status codes, error response shape
- Readability: route → service delegation thin

### M03: `app/services/` — Business logic (HEAVIEST module)

**Path:** `health_system/backend/app/services/`
**Files:** 18 (auth, device, profile, emergency, fall_event, monitoring, notification, push_notification, relationship, risk_alert, risk_inference, risk_report_builder, settings, admin_device, model_api_client, circuit_breaker, normalized_risk_row)
**LoC:** ~5,000+
**Effort:** L (~20h — largest single audit task)
**Priority:** P0 (core business value)
**Dependencies:** models/, repositories/, adapters/, model-api external

**Critical services:**
- `model_api_client.py` — verified Phase -1.C (circuit breaker pattern good)
- `risk_inference_service.py` — orchestrates model-api calls
- `risk_alert_service.py` — escalation matrix (D1 severity vocab fix)
- `fall_event_service.py` — fall detection persistence
- `push_notification_service.py` — FCM fanout
- `notification_service.py` — read state via `notification_reads` (D3 truth)

**Audit focus:**
- Architecture: service decomposition, no god service
- Correctness: D1 severity vocab in `alert_constants.py` ESCALATION_MATRIX
- Security: D-021 internal guard, PHI handling
- Performance: circuit breaker tuning, async correctness, query patterns

### M04: `app/models/` — SQLAlchemy ORM

**Path:** `health_system/backend/app/models/`
**Files:** 11 (user, device, audit_log, fall_events+alerts+sos_events, notification_read, push_token, relationship, risk_alert_response, risk_explanation, risk_score)
**LoC:** ~1,500
**Effort:** M (~5h)
**Priority:** P0 (DB schema truth — alerts.severity CheckConstraint fix needed)
**Dependencies:** SQLAlchemy, db.py

**Audit focus:**
- Correctness: CheckConstraint match canonical SQL (D1: `severity` fix from `normal/high/critical` → 4 levels)
- Architecture: model relationships, FK strategy
- Readability: `__tablename__` + `__table_args__` clear

### M05: `app/schemas/` — Pydantic models

**Path:** `health_system/backend/app/schemas/`
**Files:** 12 (auth, device, profile, emergency, fall_telemetry, sleep_telemetry, monitoring, notification, relationship, family, general_settings, ...)
**LoC:** ~1,500
**Effort:** M (~5h)
**Priority:** P1 (contract definitions)
**Dependencies:** —

**Audit focus:**
- Correctness: field validators, Pydantic v2 syntax, response model separation
- Architecture: request vs response shape distinct
- Readability: field descriptions, examples

### M06: `app/repositories/` + `app/db/`

**Path:** `health_system/backend/app/{repositories/, db/}`
**Files:** repos 5 + db 3 (database.py, memory_db.py)
**LoC:** ~1,000
**Effort:** M (~4h)
**Priority:** P1 (data access layer)
**Dependencies:** SQLAlchemy

**Audit focus:**
- Security: SQL injection (raw `text()` usage)
- Architecture: repository pattern consistency
- Performance: eager load, N+1 prevention

### M07: `app/adapters/` — Persistence adapters

**Path:** `health_system/backend/app/adapters/`
**Files:** 6 (fall_persistence, risk_persistence, ...)
**LoC:** ~800
**Effort:** M (~4h)
**Priority:** P1 (write-side abstraction)
**Dependencies:** models/, repositories/

**Audit focus:**
- Architecture: adapter pattern, separation of write logic
- Correctness: transaction boundaries

### M08: `app/core/` — Cross-cutting

**Path:** `health_system/backend/app/core/`
**Files:** 6 (alert_constants, config, dependencies, exceptions, security, ...)
**LoC:** ~700
**Effort:** M (~4h)
**Priority:** P0 (auth + constants foundation)
**Dependencies:** —

**Critical files:**
- `core/alert_constants.py` — ESCALATION_MATRIX (D1 severity vocab fix)
- `core/dependencies.py` — `get_current_user`, `require_internal_service`
- `core/config.py` — Settings pydantic-settings

**Audit focus:**
- Security: JWT secret loading, internal_secret rotation, dependencies
- Correctness: ESCALATION_MATRIX values (D1 fix)
- Architecture: dependency injection patterns

### M09: `app/utils/` — Helpers

**Path:** `health_system/backend/app/utils/`
**Files:** 8 (rate_limiter, password, jwt, email_templates, email_service, datetime_helper, age_validator, ...)
**LoC:** ~1,000
**Effort:** M (~4h)
**Priority:** P1
**Dependencies:** —

**Audit focus:**
- Security: password hashing strength, JWT signing, rate limit thresholds
- Correctness: datetime UTC vs local, age validation

### M10: `app/observability/` — Logging + tracing

**Path:** `health_system/backend/app/observability/`
**Files:** 2 (timing.py + __init__)
**LoC:** ~200
**Effort:** S (~1h)
**Priority:** P2 (instrumentation)
**Dependencies:** —

**Audit focus:**
- Architecture: StageTimer pattern (seen in model_api_client)
- Performance: log channel overhead

### M11: `app/scripts/` + `scripts/` (root)

**Path:** `health_system/backend/{app/scripts/, scripts/}`
**Files:** ~10 scripts (mock data, smoke tests, probe tools)
**LoC:** ~1,500
**Effort:** S (~3h — skim)
**Priority:** P2 (dev tooling, not production)
**Dependencies:** services, models

**Audit focus:**
- Readability: script docs, args
- Correctness: idempotency

---

## Phase 1 macro audit plan

**Track 2 sequential** (em một mình):

| Order | Module | Effort | Why |
|---|---|---|---|
| 1 | M01 (Bootstrap) | 1h | Init context |
| 2 | M08 (Core) | 4h | Auth + constants foundation |
| 3 | M09 (Utils) | 4h | JWT/password/rate limit |
| 4 | M04 (Models) | 5h | Schema truth (D1 fix point) |
| 5 | M05 (Schemas) | 5h | Pydantic contracts |
| 6 | M02 (Routes) | 10h | Entry surface — D-021 fix |
| 7 | M06 (Repos + DB) | 4h | Data layer |
| 8 | M07 (Adapters) | 4h | Persistence layer |
| 9 | M03 (Services) | 20h | Core business — D1 escalation matrix |
| 10 | M10 (Observability) | 1h | Instrumentation |
| 11 | M11 (Scripts) | 3h | Skim dev tooling |

**Track 2 total:** ~61h (second largest after mobile)

---

## Phase 3 deep-dive candidates

- [ ] `core/alert_constants.py` — D1 severity vocab fix (escalation matrix)
- [ ] `models/sos_event_model.py:65` — D1 severity CheckConstraint fix
- [ ] `services/model_api_client.py` — already verified Phase -1.C, light review only
- [ ] `services/risk_inference_service.py` — orchestration logic
- [ ] `services/risk_alert_service.py` — escalation logic
- [ ] `services/fall_event_service.py` — fall persistence + dispatch
- [ ] `services/push_notification_service.py` — FCM fanout to caregivers
- [ ] `services/notification_service.py` — D3 read state truth source
- [ ] `api/routes/telemetry.py` — D-021 add internal guard (multiple endpoints)
- [ ] `api/routes/auth.py` — verify 10 auth endpoints flow
- [ ] `repositories/relationship_repository.py` — D-005 user_relationships extra cols
- [ ] `services/relationship_service.py` — family graph logic
- [ ] `utils/jwt.py` — token issuance, refresh rotation correctness
- [ ] `utils/rate_limiter.py` — auth endpoint protection

---

## Out of scope

- `migrations/` — historical schema changes (Phase 4 might touch)
- `venv/` — virtual env files
- `test_smoke.py`, `test_schema.py` (root) — test infra
- Docker/Kubernetes deploy configs
- Email template content (Vietnamese copy review, not tech)
- API key/secret rotation operational procedure
- Email SMTP infra setup
