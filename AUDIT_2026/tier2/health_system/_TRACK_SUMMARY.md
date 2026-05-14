# Track 2+3 Summary — health_system

**Phase:** Phase 1 macro audit
**Tracks covered:** Track 2 (backend FullMode) + Track 3 (mobile SkimMode)
**Date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework:** [00_audit_framework.md](../../00_audit_framework.md) v1
**Inventory BE:** [02_health_system_backend.md](../../module_inventory/02_health_system_backend.md)
**Inventory Mobile:** [03_health_system_mobile.md](../../module_inventory/03_health_system_mobile.md)

## TL;DR

23/23 module audit complete + preflight context. Backend track 11 module với 4 file Critical (BE-M01 CORS wildcard HS-005, BE-M02 XSS HS-018, BE-M06 plaintext credential HS-020, BE-M11 hardcoded credential scripts HS-023) — 4 Security=0 anti-pattern auto-flag hit. Mobile track 12 module band Healthy — không hit anti-pattern, token storage `flutter_secure_storage` đúng convention. **19 bugs mới flagged** (HS-005 → HS-023). **Top blocker Phase 4**: pydantic-settings migration (root cause cho 5+ Critical/High bugs), repository pattern coverage gap, hardcoded credential cleanup. Post-Phase-4 expected band: 80% Healthy → 50% Mature.

## Module scores

| Module | Track | Depth | Correct. | Read. | Arch. | Sec. | Perf. | Total | Band |
|---|---|---|---|---|---|---|---|---|---|
| [BE_M01 main_bootstrap](./BE_M01_main_bootstrap_audit.md) | BE | Full | 2 | 3 | 2 | 0 | 3 | 10/15 | 🔴 |
| [BE_M02 routes](./BE_M02_routes_audit.md) | BE | Full | 1 | 3 | 2 | 0 | 3 | 9/15 | 🔴 |
| [BE_M03 services](./BE_M03_services_audit.md) | BE | Full | 2 | 2 | 1 | 1 | 2 | 8/15 | 🟠 |
| [BE_M04 models](./BE_M04_models_audit.md) | BE | Full | 1 | 2 | 2 | 2 | 3 | 10/15 | 🟡 |
| [BE_M05 schemas](./BE_M05_schemas_audit.md) | BE | Full | 2 | 3 | 1 | 2 | 3 | 11/15 | 🟡 |
| [BE_M06 repositories_db](./BE_M06_repositories_db_audit.md) | BE | Full | 2 | 3 | 1 | 0 | 2 | 8/15 | 🔴 |
| [BE_M07 adapters](./BE_M07_adapters_audit.md) | BE | Full | 3 | 3 | 3 | 2 | 3 | 14/15 | 🟢 |
| [BE_M08 core](./BE_M08_core_audit.md) | BE | Full | 2 | 3 | 2 | 2 | 3 | 12/15 | 🟡 |
| [BE_M09 utils](./BE_M09_utils_audit.md) | BE | Full | 1 | 2 | 1 | 2 | 3 | 9/15 | 🟠 |
| [BE_M10 observability](./BE_M10_observability_audit.md) | BE | Full | 3 | 3 | 2 | 2 | 3 | 13/15 | 🟢 |
| [BE_M11 scripts](./BE_M11_scripts_audit.md) | BE | Full | 2 | 2 | 2 | 0 | 3 | 9/15 | 🔴 |
| [MOB_M01 bootstrap](./MOB_M01_bootstrap_audit.md) | MOB | Skim | 2 | 2 | 2 | 2 | 3 | 11/15 | 🟡 |
| [MOB_M02 core](./MOB_M02_core_audit.md) | MOB | Skim | 2 | 2 | 2 | 2 | 3 | 11/15 | 🟡 |
| [MOB_M03 shared](./MOB_M03_shared_audit.md) | MOB | Skim | 2 | 3 | 2 | 3 | 3 | 13/15 | 🟢 |
| [MOB_M04 auth](./MOB_M04_auth_audit.md) | MOB | Skim+Full | 2 | 2 | 3 | 3 | 3 | 13/15 | 🟢 |
| [MOB_M05 device](./MOB_M05_device_audit.md) | MOB | Skim | 2 | 2 | 3 | 2 | 3 | 12/15 | 🟡 |
| [MOB_M06 family](./MOB_M06_family_audit.md) | MOB | Skim+Full | 2 | 2 | 3 | 2 | 3 | 12/15 | 🟡 |
| [MOB_M07 health_monitoring](./MOB_M07_health_monitoring_audit.md) | MOB | Skim | 2 | 2 | 3 | 2 | 2 | 11/15 | 🟡 |
| [MOB_M08 notifications](./MOB_M08_notifications_audit.md) | MOB | Skim+Full | 2 | 2 | 2 | 2 | 3 | 11/15 | 🟡 |
| [MOB_M09 emergency_fall](./MOB_M09_emergency_fall_audit.md) | MOB | Skim+Full | 2 | 2 | 2 | 2 | 3 | 11/15 | 🟡 |
| [MOB_M10 analysis](./MOB_M10_analysis_audit.md) | MOB | Skim | 2 | 2 | 3 | 2 | 2 | 11/15 | 🟡 |
| [MOB_M11 sleep_analysis](./MOB_M11_sleep_analysis_audit.md) | MOB | Skim | 2 | 3 | 3 | 2 | 2 | 12/15 | 🟡 |
| [MOB_M12 home_profile_onboarding](./MOB_M12_home_profile_onboarding_audit.md) | MOB | Skim+Full | 2 | 2 | 3 | 2 | 3 | 12/15 | 🟡 |
| **Track 2 average (BE 11 module)** | — | — | 1.91 | 2.64 | 1.73 | 1.18 | 2.82 | **10.27/15** | 🟡 |
| **Track 3 average (MOB 12 module)** | — | — | 2.00 | 2.25 | 2.58 | 2.25 | 2.75 | **11.67/15** | 🟡 |
| **Track average toàn repo (23 module)** | — | — | 1.96 | 2.43 | 2.17 | 1.74 | 2.78 | **11.00/15** | 🟡 |

## Top 5 risks

1. **BE_M01 / Security** — CORS wildcard `allow_origins=["*"]` cộng `allow_credentials=True` trong main.py — anti-pattern Security=0 force Critical. Combo cho phép mọi origin gửi credentialed request mang JWT → CSRF/XSS-exfiltration risk. (Critical, **HS-005**)

2. **BE_M02 / Security** — XSS reflected qua HTML f-string interpolation user query param trong `auth.deep_link_redirect` → attacker craft email link execute JS trên BE domain → cookie/JWT exfiltration. Anti-pattern auto-flag hit. (Critical, **HS-018**)

3. **BE_M06 / Security** — Plaintext admin credential committed git tại `db/memory_db.py`; no DEV ONLY annotation + unclear consumer. Compound với HS-023. (Critical, **HS-020**)

4. **BE_M11 / Security** — 4 instance hardcoded plaintext password literal trong seed/test scripts committed git. Compound với HS-020. (Critical, **HS-023**)

5. **BE_M03 / Security** — `model_api_client.py:101` outbound chỉ set `X-Internal-Service` — KHÔNG set `X-Internal-Secret` mandate per ADR-005; production deploy với model-api enforce → 401/403 silent fall back; với fail-open → cross-service auth contract bypass. Compound với HS-006. (Critical, **HS-021**)

## Cross-module patterns

### Anti-pattern 1: Pydantic-settings migration blocker (5+ files)

Codebase đọc env trực tiếp qua `os.getenv(...)` thay vì `pydantic-settings BaseSettings`:
- `backend/app/core/config.py` — plain class với `os.getenv` + manual int cast.
- `backend/app/core/dependencies.py:139` — module-level snapshot.
- `backend/app/core/alert_constants.py:95` — `os.getenv` cooldown.
- `backend/app/db/database.py:6-9` — DB pool config.
- `backend/app/utils/email_service.py` — class-body SMTP snapshot.
- `backend/app/utils/rate_limiter.py` — module-level singleton.
- `backend/app/services/auth_service.py:38` — testing flag.
- `backend/app/services/model_api_client.py` — model-api URL/timeout.

**Affected modules**: BE-M01, M02, M03, M06, M08, M09. **Root cause** cho fix HS-005, HS-006, HS-007, HS-015, HS-021.

**Phase 4 P0 batch action**: pydantic-settings migration toàn `Settings` class.

### Anti-pattern 2: Service vi phạm Repository boundary (6+ files)

6 service trực tiếp `db.query(Model)` thay vì gọi repository:
- `monitoring_service.py`, `risk_alert_service.py`, `push_notification_service.py`, `notification_service.py`, `device_service.py`, `admin_device_service.py`.

Cộng `api/routes/risk.py` 5 endpoint helper execute SQL trực tiếp (HS-019).

**Affected modules**: BE-M02, M03, M06. **Root cause**: 6/10 model thiếu repository.

**Phase 4 P1 batch action**: tạo missing repositories (`device_repository`, `risk_repository`, `notification_repository`, `push_token_repository`, `alert_repository`, `fall_event_repository`).

### Anti-pattern 3: ORM ↔ Canonical SQL drift (5 instance)

ORM model layer drift với canonical:
- HS-009 — `user_push_tokens` vs `user_fcm_tokens` tablename.
- HS-010 — `Alert` ORM thiếu 7 field.
- HS-011 — `AuditLog` ORM drift FK + field + INET type + CHECK status.
- HS-012 — `UserRelationship` default permission flip.
- HS-013 — `RiskAlertResponse` type drift Integer/Float.

**Affected modules**: BE-M04. **Root cause**: process gap — không có CI gate verify schema sync.

**Phase 4 P0 tooling action**: tạo `scripts/check_schema_drift.py`.

### Anti-pattern 4: Hardcoded credential committed git (HS-020 + HS-023)

5 instance plaintext credential committed:
- `db/memory_db.py` — admin account (HS-020).
- `app/scripts/create_caregiver_user.py` — caregiver test account (HS-023).
- `backend/scripts/seed_home_dashboard_e2e.py` — 3 seed accounts (HS-023).

**Affected modules**: BE-M06, M11. **Root cause**: dev fixture pattern không annotate + không guard production.

**Phase 4 P0 batch action**: env-driven seed + DEV ONLY annotation + production guard + ADR.

### Anti-pattern 5: Silent error swallow (HS-022)

`relationship_service.py` 4 instance `except Exception:` default empty/None mà KHÔNG `logger.exception`. Compound với existing instance trong các service khác (justified với comment).

**Affected modules**: BE-M03. **Phase 4 P1**: add `logger.exception` mỗi swallow.

## Phase 4 backlog roll-up

### P0 — Critical blockers (5 actions)

- [ ] **HS-005**: Replace CORS allow_origins wildcard với env-driven allowlist (BE-M01 + pydantic-settings migration).
- [ ] **HS-018**: Fix XSS trong `deep_link_redirect` — Jinja2 template auto-escape (BE-M02).
- [ ] **HS-020**: Fix plaintext admin credential committed — verify consumer + xoá hoặc migrate sang tests/fixtures (BE-M06).
- [ ] **HS-021**: Add `X-Internal-Secret` outbound header trong model_api_client (BE-M03 + cross-repo verify).
- [ ] **HS-023**: Fix 4 hardcoded plaintext credential trong seed/test scripts — env-driven + DEV ONLY annotation (BE-M11). Coordinate với HS-020.

### P1 — High priority (15+ actions)

- [ ] **Pydantic-settings migration batch**: dời 8+ env consume sang Settings class. Unblock HS-005, HS-006, HS-007, HS-015, HS-021.
- [ ] **HS-006**: `require_internal_service` fail-closed trong production env (BE-M08).
- [ ] **HS-007**: Consume `settings.ACCESS_TOKEN_EXPIRE_DAYS` (BE-M09).
- [ ] **HS-008**: Migrate rate limiter sang Redis backend (BE-M09).
- [ ] **HS-009**: Resolve `user_push_tokens` vs `user_fcm_tokens` tablename + ADR (BE-M04).
- [ ] **HS-010**: Add 7 missing field vào `Alert` ORM + CHECK alert_type (BE-M04).
- [ ] **HS-011**: Fix `AuditLog` ORM drift (BE-M04).
- [ ] **HS-012**: ADR-016 proposed UserRelationship default permission posture (BE-M04).
- [ ] **HS-013**: Align `RiskAlertResponse` types BigInteger + DOUBLE_PRECISION (BE-M04).
- [ ] **HS-014**: Resolve duplicate `FamilyProfileSnapshot` schema (BE-M05) + mobile parser update (MOB-M06).
- [ ] **HS-019**: Refactor `risk.py` SQL helpers sang service/repository (BE-M02).
- [ ] **HS-022**: Add `logger.exception` cho 4 silent swallow trong `relationship_service` (BE-M03).
- [ ] **Repository pattern coverage**: tạo 6 missing repositories — unblock HS-019 + HS-022.
- [ ] **Fat service split**: monitoring_service (1417), auth_service (1031), relationship_service (746), push_notification_service (609).
- [ ] **PHI logging filter**: configure logging filter mask sensitive field (BE-M03 + BE-M10).
- [ ] **WebSocket token_version check**: invalidate khi user logout-all (BE-M02).
- [ ] **N+1 dashboard fetch**: relationship_service batch fetch contacts (BE-M03).
- [ ] **PHI access audit log**: per-method audit_log (BE-M03).

### P2 — Defer or opportunistic (20+ actions)

- [ ] **HS-015**: Add `extra="forbid"` cho 12+ Request schema (BE-M05).
- [ ] **HS-016**: Align password policy 3 endpoint min_length=8 (BE-M05).
- [ ] **HS-017**: Fix `PatientInfo.date_of_birth` Optional[date] (BE-M05).
- [ ] **Pydantic v1 → v2 config style migration** (BE-M05).
- [ ] **Email validator consistency**: chuẩn hoá EmailStr (BE-M05 + BE-M03).
- [ ] **Schema drift CI check**: `scripts/check_schema_drift.py` (BE-M04 P0 tooling).
- [ ] **`MobileRiskDtoAdapter` placement**: move risk_report_builder sang adapters (BE-M07).
- [ ] **Adapter consume repository pattern** (BE-M07 P2).
- [ ] **Migrate `http` → `dio`**: interceptor pipeline mobile (MOB-M02).
- [ ] **Deep link arg validation mobile**: defense-in-depth HS-018 (MOB-M02 + MOB-M01).
- [ ] **Certificate pinning**: forward-looking (MOB-M02).
- [ ] **MAC address encryption ADR**: cross-cutting PHI (MOB-M05 + BE-M04).
- [ ] **Local cache encryption**: PHI display feature (MOB-M07 + MOB-M11 + MOB-M12).
- [ ] **Defer Phase 3 widget tests**: per-screen test 12 mobile module.
- [ ] **WebSocket polling pivot**: Postgres LISTEN/NOTIFY (BE-M02).
- [ ] **`debugPrint` guard kReleaseMode** (MOB-M01 + MOB-M02).

## Cross-repo coordination

| XR BugID | Scope | Affected repos | Fix sequence |
|---|---|---|---|
| HS-021 (potential XR) | model_api_client outbound auth header | health_system + healthguard-model-api | (1) Verify cross-repo enforce → (2) BE-M08 HS-006 fix + (3) BE-M03 HS-021 fix outbound + (4) Cross-repo regression test. |
| HS-014 (mobile consumer) | FamilyProfileSnapshot duplicate schema | health_system (BE + Mobile) | (1) BE-M05 fix duplicate canonical → (2) MOB-M06 mobile parser update + regression test. |
| HS-009 (potential XR) | user_fcm_tokens table name cross-repo | health_system + HealthGuard admin BE | (1) Verify HealthGuard reference → (2) Decide rename ORM hoặc canonical → (3) ADR document. |
| D1 / ADR-015 | Severity vocab drift | health_system + healthguard + iot-sim | Governed (Phase 4 fix coordinate cross-repo). |
| D-019 / ADR-004 | API prefix root_path hack | health_system | Governed (Phase 4 fix). |
| D-021 / ADR-005 | Telemetry endpoints internal guard | health_system + iot-sim | Governed (HS-004 + IS-002 batch fix). |

## Phase 3 deep-dive candidates

Roll-up từ per-module Out of scope / Defer Phase 3 markers:

- [ ] BE-M03 services individual file deep-dive (monitoring_service 1417, auth_service 1031, relationship_service 746, risk_inference_service 637, emergency_service 641, push_notification_service 609, device_service 500).
- [ ] BE-M02 routes individual endpoint deep-dive (telemetry.py 570, risk.py 530).
- [ ] BE-M07 adapters method-level unit test coverage.
- [ ] BE-M06 query plan analysis (EXPLAIN ANALYZE), connection pool tuning under load test.
- [ ] BE-M04 ORM JSONB GIN index strategy when scale > analytics.
- [ ] Mobile per-screen widget test coverage (12 module ~ 200+ screen).
- [ ] Mobile per-feature integration test (BLE pairing, FCM payload, fall detection state machine).
- [ ] Cross-repo contract test snapshot (mobile DTO ↔ BE response schema).
- [ ] Performance load test: WebSocket /ws/notifications scale > 1000 concurrent.
- [ ] Circuit breaker integration test (model_api_client breaker state machine).
- [ ] Audit log retention policy + PHI access query dashboard.

## Definition of Done

- [x] 23 per-module file tạo xong với đúng skeleton.
- [x] 1 aggregate file (this file) hoàn thành với 23 row Module scores + Top 5 risks + Cross-module patterns + Phase 4 backlog + XR coordination + Phase 3 candidates.
- [x] Mọi new BugID xuất hiện trong BUGS INDEX.
- [ ] Self-check 16 properties pass (Task 25 pending).
- [ ] ThienPDM review.
- [ ] Commit branch chore/audit-2026-phase-1-health-system (Task 25 prep, user commits).
- [ ] PR opened.

---

**Total bugs flagged Phase 1 audit health_system**: 19 (HS-005 → HS-023).

**Critical bugs (Security=0 anti-pattern hit)**: 5 (HS-005 CORS wildcard, HS-018 XSS, HS-020 + HS-023 hardcoded credential committed, HS-021 outbound auth header missing).

**High bugs**: 4 (HS-006 internal secret fail-open, HS-007 JWT TTL drift, HS-010 Alert ORM thiếu 7 field, HS-011 AuditLog ORM drift, HS-014 FamilyProfileSnapshot duplicate).

**Medium bugs**: 5 (HS-008 rate limiter bypass, HS-012 UserRelationship default flip, HS-013 RiskAlertResponse type drift, HS-019 router SQL bypass, HS-022 silent error swallow).

**Low bugs**: 3 (HS-015 missing extra=forbid, HS-016 password policy inconsistent, HS-017 PatientInfo.date_of_birth str).

**Pre-existing bugs referenced (không re-flag)**: HS-001, HS-002, HS-003, HS-004, XR-001, XR-002.

**D-series drift referenced (không re-flag, blacklist confirmed)**: D-012, D-019, D-021, D1, D3.

**Cross-cutting patterns**: Pydantic-settings migration (5+ files), Repository pattern coverage gap (6 model), ORM-canonical drift (5 instance), Hardcoded credential (5 file), Silent error swallow (1 service file).

**Phase 4 expected outcome**: 80% Healthy → 50% Mature post-fix. 5 Critical bugs unblock production deploy gate.
