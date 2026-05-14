# Audit: BE-M11 — scripts (seed + migration helpers + ops smoke)

**Module:** `health_system/backend/app/scripts/` + `backend/scripts/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module scripts chứa seed + migration helpers + ops smoke scripts. Scope audit = 2 file trong `app/scripts/` + 10 file trong `backend/scripts/`. ~1,500 LoC. Focus: idempotency, destructive safety, secret handling, argparse input validation, dev-only annotation. Phạm vi loại trừ: production migration scripts trong PM_REVIEW canonical, CI/CD deploy script.

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `app/scripts/__init__.py` | 0 | Package marker | Empty. |
| `app/scripts/create_caregiver_user.py` | ~78 | Seed test caregiver user | **CRITICAL: hardcoded plaintext credential** (HS-023). |
| `app/scripts/create_mock_sos_data.py` | ~120 | Seed mock SOS events | Idempotent check missing. |
| `backend/scripts/seed_home_dashboard_e2e.py` | ~230 | E2E seed: patient + caregiver + relationship + devices | **CRITICAL: 3 hardcoded plaintext credentials** (HS-023). |
| `backend/scripts/check_e2e_users.py` | ~70 | Verify seeded E2E users exist | Read-only OK. |
| `backend/scripts/check_alert_type_constraint.py` | ~30 | DB schema check | Read-only OK. |
| `backend/scripts/check_fall_rows.py` | ~30 | DB row check | Read-only OK. |
| `backend/scripts/probe_test_data.py` | ~100 | Test data probe | Read-only OK. |
| `backend/scripts/apply_survey_migration.py` | ~50 | Apply Module FA-2 survey_answers column migration | Idempotent IF NOT EXISTS. |
| `backend/scripts/smoke_model_api_e2e.py` | ~150 | E2E smoke test model-api integration | Read-only DB query + HTTP POST. |
| `backend/scripts/smoke_caregiver_fanout_e2e.py` | ~200 | E2E smoke caregiver push fanout | Test data dependent. |
| `backend/scripts/smoke_fall_threshold_e2e.py` | ~180 | E2E smoke fall confidence threshold | Test data dependent. |
| `backend/scripts/e2e_fall_sos_survey_smoke.py` | ~250 | E2E fall+SOS+survey full flow smoke | Most comprehensive. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | E2E smoke có structure tốt với try/finally cleanup. Idempotent check (existing user, IF NOT EXISTS). Trừ điểm: create_mock_sos_data không guard duplicate run; Base.metadata.create_all (line 32) cùng anti-pattern HS-009 BE-M01. |
| Readability | 2/3 | Top docstring với "Run this with" command help. Trừ điểm: Vietnamese-English mix; ops scripts thiếu argparse. |
| Architecture | 2/3 | Scripts độc lập từng file. create_caregiver_user consume AuthService đúng layer. create_mock_sos_data direct ORM bypass service. Mix pattern. |
| Security | 0/3 | **CRITICAL anti-pattern auto-flag hit**: 4 hardcoded plaintext password literal trong scripts committed git (HS-023). Force Security=0 + Band Critical override. Compound với HS-020. |
| Performance | 3/3 | Scripts ad-hoc, không hot path. IF NOT EXISTS migration idempotent. Read-only DB query không impact production. |
| **Total** | **9/15** | Band: **🔴 Critical** — Security=0 anti-pattern hit (HS-023 hardcoded credential committed). |

## Findings

### Correctness

- `backend/app/scripts/create_caregiver_user.py:25-30` — Idempotent check existing user. Pattern đúng — script chạy nhiều lần không tạo duplicate.

- `backend/app/scripts/create_mock_sos_data.py:32-39` — `Base.metadata.create_all(bind=engine)` trong script — cùng anti-pattern HS-009 BE-M01 (`main.py:24`). Script context less critical (dev fixture only) nhưng vẫn drift risk.

- `backend/app/scripts/create_mock_sos_data.py:75-104` — Tạo 3 mock SOS event mỗi lần script chạy KHÔNG check existing. Consecutive run → 9 mock event sau 3 lần chạy. DB pollution. P2 add idempotent check.

- `backend/scripts/apply_survey_migration.py` — Idempotent migration với IF NOT EXISTS. SQL DDL safe. OK.

- `backend/scripts/smoke_model_api_e2e.py` — POST telemetry vitals → query risk_scores latest → assert model-api persisted. Test pattern correct.

- `backend/scripts/check_e2e_users.py` — Verify seeded users + relationship + devices. Read-only. OK.

- E2E smoke scripts — comprehensive flow test. Phụ thuộc seed script chạy trước. Không có dependency check. P2 add precondition validation.

### Readability

- Each script có top docstring "Run this with: python -m app.scripts.X" — reader execute trực tiếp được.
- Vietnamese error message consistent với app convention.
- `create_caregiver_user.py` print statement Vietnamese + English mix. Inconsistent. Minor P2.
- Ops scripts thiếu argparse → không có `--help`/`--dry-run` flag.
- `create_mock_sos_data.py:55-104` mock data inline trong code thay vì JSON fixture file. P2.

### Architecture

- `app/scripts/create_caregiver_user.py:53` — Consume `AuthService.register` đúng layer. Service-side validation flow.
- `app/scripts/create_mock_sos_data.py:78-95` — Direct ORM `SOSEvent(...)` + `db.add(sos)` bypass service layer. Vi phạm `services/emergency_service.py:trigger_sos` flow (skip audit log + skip push fanout). Acceptable cho mock data scope nhưng P2 align consistent.
- E2E smoke scripts phụ thuộc seed script — implicit ordering. Document trong README. P2.
- `backend/scripts/` (ngoài app package) vs `app/scripts/` — split by purpose:
  - `app/scripts/` package-level seed (consume AuthService).
  - `backend/scripts/` ops-level smoke + check (raw SQL/ORM).
  
  Boundary clear nhưng không document.

### Security

- **Anti-pattern auto-flag scan**:
  - `eval()` / `exec()`? **NO**.
  - SQL string concat? **NO**.
  - **Plaintext credential committed git**? **YES** — 4 instance (HS-023). FORCE Security=0.
  - CORS wildcard? scope BE-M01.
  - SSL verify disabled? **NO**.
  - Hardcoded secret? **YES** — same as plaintext credential (HS-023).
  
  **Kết luận: 1 hit (HS-023 hardcoded credential committed) → Security=0 force override + Band Critical.**

- **HS-023 (Critical) — Hardcoded plaintext credential trong scripts committed git**:
  - File 1: `backend/app/scripts/create_caregiver_user.py` — caregiver test account credential literal repeated.
  - File 2: `backend/scripts/seed_home_dashboard_e2e.py` — 3 seed account credentials (PATIENT, CAREGIVER, EMPTY_SLEEP) với plaintext password literal trong dataclass.
  - Severity: Critical (anti-pattern auto-flag).
  - Root cause: Test seed scripts với hardcoded credential committed git tree.
  - Impact:
    - Repo public hoặc bị leak → 4 password lộ. Weak password pattern → credential stuffing trivial.
    - Nếu seed script chạy production accidental → tạo test account với weak password → attacker exploit ngay.
    - Audit trail compliance fail (steering `40-security-guardrails.md` mandate "NEVER hardcode password").
  - Mitigation:
    - **Quick fix**: Move credential sang env var hoặc `.env.dev.example` placeholder + script đọc env var. Add `# DEV ONLY — NOT FOR PRODUCTION` annotation. Add precondition `if os.getenv("ENVIRONMENT") == "production": exit(1)`.
    - **Better**: Generate random password mỗi lần script chạy + print to stdout.
    - **Best**: Migrate sang `tests/fixtures/` với `.env.test.example` placeholder, integrate pytest fixture.
  - Compound với HS-020 (BE-M06 `memory_db.py`) — same anti-pattern class.
  - Allocate **HS-023** (Critical).

- `backend/scripts/seed_home_dashboard_e2e.py:90-95` — Create 3 seed user với plaintext password trong dataclass field. Defense gap.

- E2E smoke scripts (`smoke_*_e2e.py`) — không hardcode credential, query DB by email + verify state. OK.

- Ops scripts (`check_*.py`, `probe_*.py`) read-only DB query — không touch credential. OK.

### Performance

- Script chạy ad-hoc CLI. Không hot path.
- IF NOT EXISTS migration idempotent → safe re-run.
- E2E smoke test có sleep + timing assertion. Acceptable.
- Read-only check scripts O(N) row scan. Acceptable cho dev DB scale.

## Positive findings

- `backend/app/scripts/create_caregiver_user.py:53-62` — Consume `AuthService.register` đúng service layer (audit log + validation flow).
- `backend/app/scripts/create_caregiver_user.py:25-30` — Idempotent check existing caregiver — no duplicate insert.
- `backend/scripts/apply_survey_migration.py` — IF NOT EXISTS migration idempotent.
- E2E smoke scripts có comprehensive flow test (telemetry → risk persist → caregiver fanout → push notification).
- Top docstring với "Run this with" command help.
- `backend/scripts/check_e2e_users.py` — read-only verification script.
- E2E smoke scripts dùng `httpx` library consistent với `model_api_client.py`.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-023 | Critical | 4 instance hardcoded plaintext password literal trong seed/test scripts committed git: app/scripts/create_caregiver_user.py (caregiver test account) + backend/scripts/seed_home_dashboard_e2e.py (3 seed accounts: PATIENT, CAREGIVER, EMPTY_SLEEP); auto-flag anti-pattern hardcoded credential committed; compound với HS-020 | `app/scripts/create_caregiver_user.py` + `backend/scripts/seed_home_dashboard_e2e.py` | Security |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-023**: Fix 4 hardcoded plaintext credential trong scripts.
  - Pre-flight: `git log --all -- backend/app/scripts/ backend/scripts/` audit history.
  - Migrate sang env-driven seed:
    ```python
    PATIENT_PASSWORD = os.getenv("E2E_PATIENT_PASSWORD")
    if not PATIENT_PASSWORD:
        print("ERROR: E2E_PATIENT_PASSWORD env var required")
        exit(1)
    ```
  - Add `.env.test.example` placeholder file checked-in (no real password).
  - Add `# DEV ONLY — NOT FOR PRODUCTION` annotation tất cả 4 file.
  - Add precondition guard `if os.getenv("ENVIRONMENT") == "production": exit(1)`.
  - Compound fix với HS-020 (BE-M06): coordinate ADR document admin/test account provisioning.

### P1

- [ ] **`create_mock_sos_data.py` idempotent check**: existing event count > 0 → skip hoặc TRUNCATE flag.
- [ ] **Drop `create_all` từ scripts**: `create_mock_sos_data.py:32` — same pattern HS-009 BE-M01 fix dependency.
- [ ] **E2E precondition validation**: smoke scripts add `_assert_seed_data_exists()` check.

### P2

- [ ] **argparse + `--dry-run` flag**: ops scripts add `--dry-run` cho destructive flow.
- [ ] **Move mock data sang JSON fixture**: `create_mock_sos_data.py` 3 SOS event inline → `tests/fixtures/mock_sos.json`.
- [ ] **Vietnamese-English consistency**: print statement standardize.
- [ ] **README.md trong scripts/**: document execution order.
- [ ] **`create_mock_sos_data.py` consume service**: `EmergencyService.trigger_sos` thay vì direct ORM.

## Out of scope

- Production migration scripts trong `PM_REVIEW/SQL SCRIPTS/` — canonical schema maintenance.
- CI/CD deploy script — DevOps scope.
- Test fixture lifecycle — out of scope, BE-M03 service-test scope.
- ADR document admin/test account provisioning — out of scope (HS-020 + HS-023 cross-link).
- Defer Phase 3: per-script test coverage.

## Cross-references

- BUGS INDEX (new):
  - HS-023 — 4 hardcoded plaintext credential trong seed/test scripts committed git (Critical)
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-020](../../../BUGS/INDEX.md) — Plaintext admin credential committed (BE-M06 `memory_db.py`); same anti-pattern class. Coordinate fix.
- ADR INDEX:
  - Không khớp ADR cho scripts scope hiện tại. Recommend tạo ADR mới: "Test/seed account credential management" (HS-020 + HS-023 govern).
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — `Base.metadata.create_all` HS-009 reference.
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md) — `AuthService.register` consumer.
  - [`BE_M06_repositories_db_audit.md`](./BE_M06_repositories_db_audit.md) — HS-020 plaintext credential committed.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/40-security-guardrails.md` (NEVER hardcode credential rule).
