# Audit: BE-M06 — repositories + db (data access layer)

**Module:** `health_system/backend/app/repositories/` + `app/db/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module repositories + db chứa data access layer: SQLAlchemy engine + session factory (`db/database.py`), in-memory dev fixture (`db/memory_db.py`), 4 repository file (audit_log, emergency, relationship, user). ~600 LoC. Focus per-file: session lifecycle, parameterized query, N+1 detection, transaction boundary, deadlock concerns, repository pattern coverage gap. Phạm vi loại trừ: model schema (BE-M04), service-layer business logic (BE-M03), router consumer (BE-M02), config Settings injection (BE-M08).

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `db/__init__.py` | 0 | Package marker | Empty. |
| `db/database.py` | ~30 | Engine + Session factory + `get_db` dependency | Pool config qua `os.getenv` (cùng anti-pattern HS-006/HS-007). |
| `db/memory_db.py` | ~3 | Hardcoded admin credential dict | **CRITICAL anti-pattern**: plaintext password literal trong git tree → HS-020. |
| `repositories/__init__.py` | 0 | Package marker | Empty. |
| `repositories/audit_log_repository.py` | ~80 | `log_action` method | `_coerce_ip` defensive validation cho `inet` type — best practice. |
| `repositories/emergency_repository.py` | ~330 | 13 method cho SOS/alert query với caregiver permission gate | G-3/G-4 fix bugs commented inline; SQLAlchemy ORM only, no raw SQL. |
| `repositories/relationship_repository.py` | ~50 | 6 method cho M:N relationship CRUD | Bare bones — không có method by-pair compound key. |
| `repositories/user_repository.py` | ~95 | 7 method cho user lookup + password update | Tốt — dùng `get_by_email`, `verify_login`, `update_password` consistent. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Session lifecycle đúng (`get_db` yield-finally close). `_coerce_ip` defense tốt. Trừ điểm: HS-020 plaintext credential committed git; repository coverage gap — chỉ 4/10 model có repository, 6 model còn lại data access scattered. |
| Readability | 3/3 | Comment giải thích G-3/G-4 fix inline. `_coerce_ip` docstring chi tiết WHY. `audit_log_repository` Args block đầy đủ. |
| Architecture | 1/3 | **Repository pattern incomplete**: 6/10 model thiếu repository → service + router phải tự query. Vi phạm steering `22-fastapi.md` "Router → Service → Repository → ORM" layering. DB pool config qua `os.getenv` thay vì Settings (cùng anti-pattern import-time snapshot). |
| Security | 0/3 | **CRITICAL anti-pattern auto-flag hit**: `db/memory_db.py` chứa hardcoded admin email + plaintext password literal committed git tree. Force Security=0 + Band Critical override. Không có encryption tại data access layer cho PHI fields. |
| Performance | 2/3 | `pool_pre_ping=True` + `pool_recycle=1800` config OK. `emergency_repository.py:165-180` aggregation query optimized. N+1 risk medium ở `get_user_relationships`/`get_viewable_profiles` không eager-load `User`. |
| **Total** | **8/15** | Band: **🔴 Critical** — Security=0 anti-pattern hit (HS-020 plaintext credential committed) override. |

## Findings

### Correctness

- `backend/app/db/memory_db.py:1-3` — **CRITICAL: Plaintext admin credential committed git**. File chứa module-level `dict[str, str]` mapping admin email tới password literal (cả 2 hardcoded inline). Đây là dev fixture nhưng:
  - File committed vào git tree → password literal lộ public nếu repo open-source/leaked.
  - Không có `# DEV ONLY` comment annotation.
  - Không clear ai consume — grep `from app.db.memory_db import accounts` cần verify.
  - Default admin email pattern phổ biến + password literal là weak (6-digit numeric) → credential stuffing trivial nếu service consume bypass DB lookup.
  
  Allocate **HS-020** (Critical, anti-pattern auto-flag — "Hardcoded credential / API key / secret committed git" per framework v1 anti-pattern list). Force Security=0 override.

- `backend/app/db/database.py:6-9` — Pool config đọc env trực tiếp:
  ```python
  _pool_size = int(os.getenv("DB_POOL_SIZE", "10"))
  _max_overflow = int(os.getenv("DB_MAX_OVERFLOW", "20"))
  _pool_timeout = int(os.getenv("DB_POOL_TIMEOUT", "30"))
  ```
  Cùng anti-pattern import-time env snapshot với HS-006 (`require_internal_service`) + HS-007 (`ACCESS_TOKEN_EXPIRE_DAYS`). Không qua `Settings`. Khi pydantic-settings migrate, 3 env này phải centralize. Không bug runtime, tracked với P1 batch fix.

- `backend/app/db/database.py:24-28` — `get_db` yield-finally close pattern đúng. SQLAlchemy session per-request dependency injection canonical:
  ```python
  def get_db():
      db = SessionLocal()
      try:
          yield db
      finally:
          db.close()
  ```
  Không có rollback on exception trong dependency itself — service-layer phải `try/except + db.rollback()` nếu raise. Hiện service code có pattern này (telemetry.py:284-286, 350-352). OK.

- `backend/app/repositories/audit_log_repository.py:10-25` — `_coerce_ip` defensive validation:
  ```python
  def _coerce_ip(value: Optional[str]) -> Optional[str]:
      if not value:
          return None
      cleaned = value.strip()
      if not cleaned:
          return None
      try:
          ipaddress.ip_address(cleaned)
      except ValueError:
          return None
      return cleaned
  ```
  Comment giải thích Postgres `inet` reject empty string + invalid IP. Defensive coercion biến edge case → NULL thay vì 500. Best-in-class data access defense.
  
  **Mâu thuẫn với BE-M04 finding**: ORM `AuditLog.ip_address: String(50)` thay vì `INET`. Hiện ORM accept invalid string vì SQLAlchemy không validate. Nhờ `_coerce_ip` ở repository layer, runtime an toàn — invalid IP coerce sang NULL trước khi commit. Khi HS-011 fix ORM type → `INET`, defense layer này thừa nhưng vẫn giữ cho test/seed bypass safety.

- `backend/app/repositories/emergency_repository.py:115-180` — `get_sos_alerts_by_caregiver`:
  - Bug fix G-4 documented: `can_receive_alerts` filter để symmetric với push fan-out (`get_alert_recipient_user_ids`). **Positive**: cross-method consistency.
  - Counts query optimized: single aggregation `func.count + case` thay vì 3 separate query. Reduce DB round-trip.
  - Filter logic `caregiver_rel_exists OR patient_rel_exists` đúng cho M:N bidirectional. Status="accepted" + `triggered_at >= relationship.created_at` đúng (chỉ event sau khi link).

- `backend/app/repositories/emergency_repository.py:228-247` — `create_sos_event`:
  ```python
  db.add(sos)
  db.flush()
  if commit:
      db.commit()
      db.refresh(sos)
  ```
  `commit=True` mặc định + `commit=False` cho atomic transaction (caller-managed). Pattern hỗ trợ multi-step service operation đúng. OK.

- `backend/app/repositories/emergency_repository.py:285-307` — `get_alert_recipient_user_ids`:
  ```python
  caregiver_rows = db.query(UserRelationship.caregiver_id).filter(...).all()
  ```
  Tốt: select scalar column thay vì full ORM object → reduce memory + serialization cost. Set comprehension dedupe OK.

- `backend/app/repositories/relationship_repository.py:8-12` — `get_by_id`:
  ```python
  return db.query(UserRelationship).filter(UserRelationship.id == relationship_id).first()
  ```
  Thiếu `deleted_at IS NULL` check — soft-deleted relationship vẫn được trả. Caller phải remember check. P1 add filter consistent với `get_user_relationships`/`get_viewable_profiles`/`get_pending_requests`.

- `backend/app/repositories/relationship_repository.py:30-39` — `get_pending_requests`:
  ```python
  UserRelationship.patient_id == user_id,
  UserRelationship.status == 'pending',
  ```
  Chỉ trả pending request cho patient (incoming). Không có method cho outgoing pending (caregiver gửi request waiting cho patient accept). Service layer (BE-M03) phải tự query → architecture gap. P2.

- `backend/app/repositories/user_repository.py:38-52` — `verify_login`:
  ```python
  if not verify_password(password, user.password_hash):
      return None
  ```
  Comment đúng "Does NOT check is_active flag - that's done in service layer". Separation of concern clear.

- `backend/app/repositories/user_repository.py:64-69` — `update_last_login`:
  ```python
  if user:
      user.last_login_at = get_current_time()
      db.commit()
  ```
  KHÔNG `db.refresh(user)` sau commit. Nếu caller dùng `user` object sau call, `last_login_at` attribute vẫn old value (object stale). Acceptable nếu caller không re-read field. Minor P2.

### Readability

- `backend/app/repositories/audit_log_repository.py:10-30` — `_coerce_ip` docstring chi tiết WHY (Postgres `inet` reject) + reference traceback class `psycopg2.errors.InvalidTextRepresentation`. Reader hiểu past bug + defensive intent.
- `backend/app/repositories/audit_log_repository.py:35-56` — `log_action` Args docstring đầy đủ 8 param với example value. Reader đọc 1 lần dùng được.
- `backend/app/repositories/emergency_repository.py:121-130` — bug fix G-4 inline comment "Bug fix G-4: gate the SOS list by can_receive_alerts so a caregiver who has been revoked from receiving alerts also stops seeing the underlying SOS event in their list. Previously this only filtered the push fan-out". Captures past asymmetric leak + rationale.
- `backend/app/repositories/emergency_repository.py:265-278` — `get_sos_alert_recipients_with_permissions` docstring giải thích G-3 redaction rationale + `OR` semantics khi caregiver có multiple legacy rows. Edge case captured.
- `backend/app/repositories/emergency_repository.py:308-332` — `get_caregiver_view_permissions` docstring "used by SOS read endpoints to gate LocationInfo per viewer". Cross-reference router (BE-M02) consumer.
- `backend/app/repositories/relationship_repository.py` — minimal docstring. 50 LoC simple class. Acceptable.
- `backend/app/repositories/user_repository.py:38-52` — `verify_login` docstring "Does NOT check is_active flag - that's done in service layer". Separation of concern explicit.
- `backend/app/db/database.py` — không có module docstring. 30 LoC trivial setup. Acceptable.

### Architecture

- **Repository pattern incomplete**:
  - 4 repository file: audit_log, emergency, relationship, user.
  - 10 model: User ✓, UserRelationship ✓, Device ✗, FallEvent ✗ (in emergency), Alert ✗ (in emergency), SOSEvent ✓ (in emergency), RiskScore ✗, RiskExplanation ✗, RiskAlertResponse ✗ (in emergency partial), NotificationRead ✗, UserPushToken ✗, AuditLog ✓.
  - 6 model thiếu hoàn toàn repository: Device, RiskScore, RiskExplanation, NotificationRead, UserPushToken, FallEvent (chỉ có get_by_id trong emergency_repository).
  
  Hệ quả: data access cho 6 model nằm rải rác trong:
  - `services/device_service.py` — `db.query(Device)...` direct.
  - `services/notification_service.py` — `db.query(Alert)...` direct.
  - `services/push_notification_service.py` — `db.query(UserPushToken)...` direct.
  - `api/routes/risk.py` — `db.query(RiskScore)...` (HS-019 reference).
  - `services/monitoring_service.py` — `db.query(RiskScore)...` direct.
  - `services/risk_alert_service.py` — `db.query(RiskScore)...` direct.
  
  Vi phạm steering `22-fastapi.md` "Router → Service → Repository → ORM" layering. Service trở thành "fat service" với mixed business logic + data access.
  
  Phase 4 P1: tạo missing repositories `device_repository.py`, `risk_repository.py`, `notification_repository.py`, `push_token_repository.py`. Refactor service consume.

- `backend/app/db/database.py:6-17` — Engine + pool config import-time. Thay vì `Settings` injection, đọc `os.getenv` 3 var trực tiếp. Inconsistent với rest of codebase (`settings.DATABASE_URL` được dùng line 12 nhưng pool_size/overflow/timeout không qua Settings). Migration P1: `Settings.db_pool_size`, `Settings.db_max_overflow`, `Settings.db_pool_timeout`. Cùng batch HS-006/HS-007 pydantic-settings migrate.

- `backend/app/db/memory_db.py` — module-level mutable dict. Không thread-safe + không có lock. Nếu service consume cho admin auth fallback, race condition. Phase 4 P0 (HS-020 fix): xoá file hoặc move sang test fixtures `tests/fixtures/`.

- `backend/app/repositories/audit_log_repository.py:60-78` — `log_action` static method trả `AuditLog` ORM object. Caller có thể access raw field. OK pattern.

- `backend/app/repositories/emergency_repository.py` — repository nặng nhất (330 LoC, 13 method). Mix concern: SOS event CRUD + Alert lookup + RiskAlertResponse + caregiver permission gate. Cohesion borderline OK vì cùng emergency domain. Nếu thêm method, split candidate `sos_repository.py` + `alert_repository.py`.

- `backend/app/repositories/relationship_repository.py:30-49` — bare bones CRUD. Thiếu compound-key methods (e.g., `get_by_pair(patient_id, caregiver_id)` để check duplicate trước create). Service layer phải tự query.

- `backend/app/repositories/user_repository.py:95 LoC` chia 7 method. Coverage tốt cho user-related operations. Nhưng `verify_email` + `update_password` thực ra là update operation chứ không phải query. Trong repository pattern strict, nên tách `UserUpdateRepository` + `UserQueryRepository`. Chấp nhận hiện tại.

### Security

- **Anti-pattern auto-flag scan**:
  - `eval()` / `exec()`? **NO**.
  - SQL string concat? **NO** — toàn ORM `db.query(...)` parameterized; `func.count + case` SQLAlchemy expression đúng pattern.
  - Plaintext credential committed git? **YES** — `db/memory_db.py:1-3` (HS-020 ABOVE). FORCE Security=0.
  - CORS wildcard? scope BE-M01.
  - SSL verify disabled? **NO**.
  - Token in localStorage? **NO**.
  - **Hardcoded credential / API key / secret committed git**? **YES** — `memory_db.py:1-3`.
  - `dangerouslySetInnerHTML`? **NO**.
  
  **Kết luận: 1 hit (HS-020 plaintext credential committed) → Security=0 force override + Band Critical.**

- **HS-020 (Critical) — Plaintext admin credential committed git**:
  - File: `backend/app/db/memory_db.py:1-3`.
  - Severity: Critical (anti-pattern auto-flag).
  - Root cause: dev fixture với hardcoded admin credential dict (admin email + plaintext password literal). Không có `# DEV ONLY` annotation. Không có gitignore. Không clear consumer.
  - Impact: 
    - Nếu repo public hoặc bị leak → password lộ. Weak password literal — credential stuffing trivial.
    - Nếu service consume làm auth fallback → bypass DB lookup, attacker sử dụng credential cố định.
    - Audit trail compliance fail (steering `40-security-guardrails.md` mandate "NEVER hardcode API key, password, JWT secret, DB credential").
  - Mitigation:
    - **Quick fix**: Verify consumer (grep `from app.db.memory_db import`) → nếu không ai dùng, xoá file hoàn toàn. Nếu consumer exist → migrate sang `tests/fixtures/admin_account.py` với `# DEV ONLY` annotation + add `tests/fixtures/` vào `.gitignore` whitelist (nếu cần share dev credential thì sang `.env.example.dev`).
    - **Better**: Service auth flow chỉ qua DB lookup `User` table với bcrypt hash. Admin account seed qua migration script `PM_REVIEW/SQL SCRIPTS/YYYYMMDD_seed_admin.sql` với placeholder password requiring change on first login.
    - **Best**: ADR document admin account provisioning flow (no committed credential, env-driven seed only on local dev).
  - Pre-flight check: `git log --all --full-history -- backend/app/db/memory_db.py` → check ai add file, có commit history nào leak nhiều credential không.

- `backend/app/repositories/emergency_repository.py:108-135` — bug fix G-3/G-4 documented inline:
  - G-3: gate `LocationInfo` per viewer (`can_view_location`).
  - G-4: gate SOS list by `can_receive_alerts` symmetric với push fan-out.
  - Permission check defense-in-depth: relationship status + flag check + soft-delete check.
  Positive — this is the right pattern.

- `backend/app/repositories/audit_log_repository.py:10-25` — `_coerce_ip` defensive validation chống `psycopg2.errors.InvalidTextRepresentation`. Best-in-class.

- `backend/app/repositories/user_repository.py:38-52` — `verify_login`:
  - Dùng `verify_password(password, user.password_hash)` từ `utils/password.py` (BE-M09) — bcrypt timing-safe. Không có timing attack.
  - Trả `None` nếu user không tồn tại HOẶC password sai. Consistent — không leak user enumeration via timing/error message khác nhau.

- `backend/app/repositories/relationship_repository.py:8-12` — `get_by_id` thiếu `deleted_at IS NULL` filter. Soft-deleted relationship vẫn được trả → caller có thể infer về existence của relationship đã bị revoke. Information leak nhỏ. P1 add filter.

- PHI handling: 4 repository không apply encryption layer cho PHI fields (`User.medications`, `User.allergies`, `User.medical_conditions`, `Device.calibration_data`, `FallEvent.features`). Steering `40-security-guardrails.md` mandate "Encrypt at rest". Hiện cross-cutting gap, đã capture trong BE-M04 P2 recommendation. Không re-flag bug ID.

### Performance

- `backend/app/db/database.py:11-17` — Pool config:
  - `pool_size=10`, `max_overflow=20` → effective max 30 concurrent connection.
  - `pool_pre_ping=True` → validate connection alive trước use, prevent stale connection error.
  - `pool_recycle=1800` (30 min) → recycle connection trước Postgres timeout default 8h.
  - `pool_timeout=30` → wait 30s for free connection trước raise.
  - Reasonable defaults cho mobile traffic scale.

- `backend/app/repositories/emergency_repository.py:165-180` — `get_sos_alerts_by_caregiver` aggregation:
  ```python
  counts_row = db.query(
      func.count(SOSEvent.id).label("total"),
      func.sum(case((SOSEvent.status == "active", 1), else_=0)).label("active"),
      func.sum(case((SOSEvent.status == "resolved", 1), else_=0)).label("resolved"),
  ).filter(base_filter).first()
  ```
  Optimized: 1 round-trip thay vì 3. Pattern reusable. **Positive performance finding**.

- `backend/app/repositories/emergency_repository.py:285-307` — `get_alert_recipient_user_ids` select scalar column thay vì full ORM object → reduce memory + lazy load avoidance.

- `backend/app/repositories/relationship_repository.py:14-23` — `get_user_relationships` filter `OR(patient_id, caregiver_id)`:
  Index coverage tốt — BE-M04 confirmed `ix_relationships_patient_status_deleted` + `ix_relationships_caregiver_status_deleted` composite index. Postgres planner sẽ dùng OR + UNION nội bộ. OK.

- `backend/app/repositories/relationship_repository.py:25-37` — `get_viewable_profiles` filter `OR` 3 boolean column. Hiện không có index cho 3 boolean column riêng. Postgres sequential scan trên rows match `caregiver_id + status + deleted_at` rồi filter OR. Acceptable scale hiện tại; partial index `WHERE can_view_vitals OR can_receive_alerts OR can_view_location` forward-looking khi scale > 10k relationship. P2.

- N+1 risk medium:
  - `get_user_relationships` không eager load `User` (patient_user/caregiver_user) → service consume call `r.patient` hoặc `r.caregiver` → fire query mỗi row. Service-layer phải `joinedload(UserRelationship.patient_user)` (BE-M03 review).
  - `get_viewable_profiles` cùng risk.
  - `get_pending_requests` cùng risk.

- `backend/app/repositories/audit_log_repository.py:60-78` — `log_action` mỗi call `db.add + db.commit + db.refresh`. 3 round-trip. Audit log endpoint heavy → P2 batch insert pattern (`bulk_save_objects` hoặc `BackgroundTasks` queue).

- `backend/app/repositories/user_repository.py:60-91` — multiple update method `update_last_login`, `verify_email`, `update_password` — mỗi call get_by_id + commit. Không atomic với caller transaction. Nếu service muốn batch (e.g., login → update_last_login + log_action atomically), pattern hiện tại khó composes. P2 add `commit=False` parameter consistent với `create_sos_event`.

## Positive findings

- `backend/app/repositories/audit_log_repository.py:10-30` — `_coerce_ip` defensive validation. Comment explain Postgres `inet` reject + past bug. Best-in-class data access defense.
- `backend/app/repositories/emergency_repository.py:121-180` — `get_sos_alerts_by_caregiver` G-4 fix + aggregation single-roundtrip + `OR` bidirectional filter. Multi-concern clean.
- `backend/app/repositories/emergency_repository.py:265-332` — G-3 redaction helpers: `get_sos_alert_recipients_with_permissions`, `get_caregiver_view_permissions`, `get_caregiver_location_visibility`. Dedicated permission lookup methods cho service layer. Clean separation.
- `backend/app/repositories/emergency_repository.py:228-247` — `create_sos_event` `commit=True/False` parameter cho atomic transaction support. Good pattern.
- `backend/app/db/database.py:24-28` — `get_db` yield-finally close pattern canonical.
- `backend/app/db/database.py:14-15` — `pool_pre_ping=True` + `pool_recycle=1800` config — defensive defaults.
- `backend/app/repositories/user_repository.py:38-52` — `verify_login` consistent return `None` (no enumeration via timing/error).
- `backend/app/repositories/user_repository.py:21-36` — `create_user` đầy đủ field + role normalize + bcrypt hash via `utils/password.hash_password`.
- `backend/app/repositories/audit_log_repository.py:35-78` — `log_action` 8 param + Args docstring đầy đủ.
- Comment fix-bug inline pattern (`# Bug fix G-3:`, `# Bug fix G-4:`) — preserve historical context cho future debugger.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-020 | Critical | Plaintext admin credential committed git tại `db/memory_db.py:1-3` (admin email + weak password literal); no `# DEV ONLY` annotation + unclear consumer; auto-flag anti-pattern "Hardcoded credential committed git" | `backend/app/db/memory_db.py:1-3` | Security |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-020**: Fix plaintext credential committed git.
  1. Pre-flight: `grep -rn "from app.db.memory_db" backend/` xác định consumer.
  2. Nếu **không có consumer** (likely — file orphan): xoá file `backend/app/db/memory_db.py`. Verify test pass.
  3. Nếu **có consumer**:
     - Migrate sang `tests/fixtures/dev_admin_account.py` với `# DEV ONLY — NOT FOR PRODUCTION` annotation.
     - Add `# noqa: secret-detection` nếu pre-commit hook detect. Annotated dev-only.
     - HOẶC service auth fallback drop entirely → only DB lookup with bcrypt hash.
  4. Audit git history: `git log --all -- backend/app/db/memory_db.py` → log ai commit, có lộ thêm credential khác không.
  5. Recommend: ADR document admin account provisioning (env-driven seed, no committed credential).
  6. Regression test: `tests/test_no_committed_credentials.py::test_memory_db_not_in_git` (hooks check pass).

### P1

- [ ] **Repository pattern coverage**: tạo missing repositories cho 6 model:
  - `device_repository.py` — extract từ `services/device_service.py` + `services/admin_device_service.py`.
  - `risk_repository.py` — extract từ `services/monitoring_service.py` + `services/risk_alert_service.py` + `api/routes/risk.py` (HS-019 fix dependency).
  - `notification_repository.py` — extract từ `services/notification_service.py`.
  - `push_token_repository.py` — extract từ `services/push_notification_service.py` + `services/notification_service.py`.
  - `fall_event_repository.py` (split từ emergency_repository) — extract `FallEvent` queries.
  - `alert_repository.py` (split từ emergency_repository) — extract `Alert` queries.
- [ ] **DB pool config Settings migration**: dời `DB_POOL_SIZE`/`DB_MAX_OVERFLOW`/`DB_POOL_TIMEOUT` từ `os.getenv` sang `Settings` cùng batch pydantic-settings (HS-006 P1).
- [ ] **`get_by_id` soft-delete filter**: `relationship_repository.get_by_id` thêm `UserRelationship.deleted_at.is_(None)` filter consistent với rest.
- [ ] **Atomic update support**: `user_repository` 4 update method (`update_last_login`, `verify_email`, `update_password`) thêm `commit: bool = True` parameter. Service-layer compose multi-step transaction.
- [ ] **`log_action` batch pattern**: cao tải audit log endpoint (auth login spike) → P1 add `log_actions_bulk` với `bulk_save_objects`. Hoặc `BackgroundTasks` queue.

### P2

- [ ] **`update_last_login` refresh**: thêm `db.refresh(user)` sau commit để caller thấy `last_login_at` updated.
- [ ] **Outgoing pending request method**: `relationship_repository.get_outgoing_pending_requests(caregiver_user_id)` để không service-layer query trực tiếp.
- [ ] **Compound key method**: `relationship_repository.get_by_pair(patient_id, caregiver_id)` — check duplicate trước create.
- [ ] **Partial index forward-looking**: `idx_relationships_caregiver_active_perms` partial WHERE — khi scale > 10k relationship.
- [ ] **PHI encryption strategy ADR**: cùng action ADR cross-cutting với BE-M04 P2 (medications/allergies/medical_conditions plaintext).
- [ ] **Repository docstring module-level**: 4 repository file thêm module docstring giới thiệu purpose + cross-reference UC/ADR.

## Out of scope

- Service-layer business logic refactor consume new repositories — BE-M03 services.
- Router consumer của repository — BE-M02 routes.
- Model schema + ORM definition — BE-M04 models (HS-009 → HS-013 capture).
- Pydantic schema validation — BE-M05 schemas.
- TimescaleDB hypertable + compression — canonical SQL maintenance, không phải code.
- Migration script execution — BE-M11 scripts.
- Defer Phase 3: per-method query plan analysis (EXPLAIN ANALYZE), connection pool tuning under load test, transaction isolation level review.
- Cross-repo coordination (cross-cutting): admin BE (HealthGuard) cũng có `accounts` dict tương tự không? Cần grep cross-repo verify.

## Cross-references

- BUGS INDEX (new):
  - HS-020 — Plaintext admin credential committed git (Critical)
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-005](../../../BUGS/INDEX.md) — CORS wildcard (BE-M01); cùng anti-pattern auto-flag class.
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open (BE-M08); cùng env import-time snapshot anti-pattern với DB pool config.
  - [HS-007](../../../BUGS/INDEX.md) — JWT TTL drift (BE-M09); cùng env config drift.
  - [HS-011](../../../BUGS/INDEX.md) — `AuditLog` ORM drift `ip_address String(50)` vs canonical `INET` (BE-M04); `_coerce_ip` defense layer compensate.
  - [HS-019](../../../BUGS/INDEX.md) — Router `risk.py` execute SQL trực tiếp (BE-M02); HS-019 fix dependency lên repository pattern P1 recommendation cho `risk_repository.py`.
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md) — Internal service auth strategy. Repository không trực tiếp consumer, service layer responsibility.
- Intent drift (reference only — không re-flag — blacklist per preflight):
  - Không khớp drift ID nào trong blacklist (D-012/D-019/D-021/D1/D3).
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — `Base.metadata.create_all(bind=engine)` consumer của `db/database.py:engine`.
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md) — ORM definitions consumer của repository; HS-011 `AuditLog.ip_address` type drift cross-link với `_coerce_ip` defense.
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md) — HS-019 router SQL bypass; repository pattern coverage gap fix dependency.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — `core/dependencies.py:get_target_profile_id` inline SQLAlchemy query (line 104-111); refactor candidate `relationship_repository.get_caregiver_view_relationship`.
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md) — `utils/password.py:verify_password` consumer trong `user_repository.verify_login`.
  - `BE_M03_services_audit.md` (Task 9 pending) — service consume repository; coverage gap finding.
  - `BE_M07_adapters_audit.md` (Task 8 pending) — adapter pattern; cross-link với repository pattern.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/22-fastapi.md` (Router → Service → Repository layering rule).
- Steering: `health_system/.kiro/steering/40-security-guardrails.md` (NEVER hardcode credential rule).
