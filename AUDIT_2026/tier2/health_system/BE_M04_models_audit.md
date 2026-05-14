# Audit: BE-M04 — models (SQLAlchemy ORM declarative)

**Module:** `health_system/backend/app/models/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module models chứa SQLAlchemy 2.0 declarative ORM cho toàn bộ backend mobile: 10 model class trải 10 file Python (+ `__init__.py` re-export). Scope audit = (a) cross-check field-by-field với canonical schema `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` (1,300+ LoC), (b) CheckConstraint coverage, (c) FK `ondelete` strategy match canonical, (d) index presence cho query hot path, (e) nullable consistency, (f) snake_case + plural table naming. Phạm vi loại trừ: Pydantic schemas (BE-M05), repository/session lifecycle (BE-M06), service-layer consumer của model (BE-M03 services), migration scripts production (BE-M11 + canonical SQL maintenance).

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `__init__.py` | ~25 | Re-export 10 model + side-effect import (BE-M01 dependency) | OK. |
| `user_model.py` | ~95 | `User` — auth + medical profile + verification/reset codes | Drift: thiếu CheckConstraints (gender/role/blood_type/height/weight) hiện diện canonical. |
| `device_model.py` | ~55 | `Device` — IoT device registry | HS-001 reference (user_id NOT NULL/CASCADE drift); HS-003 reference (calibration_data dead data). |
| `relationship_model.py` | ~45 | `UserRelationship` — patient ↔ caregiver M:N | Default value drift (`can_view_vitals=False` vs canonical `true`); 4 extra fields (`status`, `primary_relationship_label`, `tags`, `can_view_medical_info`) chưa có migration script trong canonical. |
| `sos_event_model.py` | ~110 | `FallEvent`, `Alert`, `SOSEvent` (3 class trong 1 file) | XR-002 reference (`Alert.severity` CheckConstraint drift); `Alert` ORM **thiếu 7 field** canonical define. |
| `risk_score_model.py` | ~60 | `RiskScore` — orchestration result | OK match canonical, có composite index hữu ích. |
| `risk_explanation_model.py` | ~75 | `RiskExplanation` — XAI payload + audience cache | OK match canonical. |
| `risk_alert_response_model.py` | ~60 | `RiskAlertResponse` — terminal response cho overlay/push_tap | Type drift: `Integer` vs canonical `BIGINT`, `Float` vs canonical `DOUBLE PRECISION`; missing FK trên `risk_score_id`/`device_id`. |
| `notification_read_model.py` | ~25 | `NotificationRead` — per-user read state cho alerts | OK match canonical (D3 read state truth — reference only). |
| `push_token_model.py` | ~35 | `UserPushToken` — FCM token registry | **CRITICAL drift**: tablename `user_push_tokens` mismatch canonical `user_fcm_tokens`. |
| `audit_log_model.py` | ~30 | `AuditLog` — TimescaleDB hypertable | Drift nhiều: FK missing, thiếu `device_id`/`error_message`, `ip_address` type mismatch (`String(50)` vs canonical `INET`). |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | Multiple silent drifts canonical SQL: tablename mismatch (HS-009), Alert thiếu 7 field (HS-010), audit_logs thiếu FK + thiếu field + type mismatch (HS-011), CheckConstraints missing. ORM read/write subset của canonical schema. |
| Readability | 2/3 | Comment trong `user_model.py` regression-prevention best-in-class (height_cm SmallInteger rationale). Trừ điểm: 3 class trong cùng 1 file `sos_event_model.py`; `risk_alert_response_model.py` field comment minimal. |
| Architecture | 2/3 | Pattern `__init__.py` re-export đúng. Snake_case + plural naming consistent. Trừ điểm: ORM drift canonical, không có CI gate verify schema sync — process gap. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Trừ điểm: `UserRelationship` default permission flip (HS-012); `AuditLog` missing FK orphan log; PHI plaintext array (cross-cutting). |
| Performance | 3/3 | Composite index hợp lý cover query hot path. JSONB GIN forward-looking acceptable. Hypertable PK đúng. |
| **Total** | **10/15** | Band: **🟡 Healthy** — không Security=0 override (không hit anti-pattern). |

## Findings

### Correctness

- `backend/app/models/push_token_model.py:14` — `__tablename__ = "user_push_tokens"`. **Canonical schema SECTION 16 (`init_full_setup.sql:832`) định nghĩa table name = `user_fcm_tokens`** (different name entirely). Field set cũng khác:
  - Canonical `user_fcm_tokens`: `id, user_id, token (TEXT), platform CHECK IN (android/ios/web), is_active, created_at, updated_at, UNIQUE(user_id, token)`.
  - ORM `user_push_tokens`: `id, user_id, token (String 512), platform (no CHECK), device_id (extra), is_active, created_at, updated_at, last_seen_at (extra), UNIQUE(token)` — thiếu CHECK constraint, UNIQUE key khác (token-only vs user_id+token).
  
  Hệ quả deploy:
  - Nếu deploy DB qua canonical `init_full_setup.sql` → ORM model bind tới table KHÔNG TỒN TẠI (`user_push_tokens`). Mọi service push token (FCM register/dispatch) sẽ raise `ProgrammingError: relation "user_push_tokens" does not exist`.
  - Nếu deploy qua migration ad-hoc tạo `user_push_tokens` → ORM hoạt động nhưng admin BE (HealthGuard) reading từ canonical name `user_fcm_tokens` sẽ thấy table rỗng.
  
  Đây là **MAJOR cross-repo drift**. Không có ADR justify. Allocate **HS-009** (Critical).

- `backend/app/models/sos_event_model.py:60-100` — `Alert` ORM define 11 field: `id, uuid, device_id, user_id, fall_event_id, alert_type, severity, title, message, details (mapped to "data"), created_at, updated_at`. **Canonical `init_full_setup.sql:429` định nghĩa thêm 7 field nữa**: `sos_event_id`, `sent_at`, `delivered_at`, `read_at`, `acknowledged_at`, `sent_via TEXT[]`, `expires_at`. Đồng thời canonical có `alert_type CHECK IN (12 values)` — ORM hoàn toàn không define CHECK cho `alert_type`.
  
  Hệ quả:
  - Service layer (BE-M03 `risk_alert_service`, `notification_service`) muốn track `read_at`/`acknowledged_at`/`expires_at` PHẢI raw SQL hoặc thêm column qua `Column(...)` runtime — ORM không expose.
  - Phase 4 implement notification expire/delivery tracking phải bypass ORM.
  - `D3` drift (notification read state truth source) liên quan: canonical có CẢ HAI cơ chế (`alerts.read_at` + `notification_reads`); ORM chỉ expose `notification_reads` table → service tier viết theo `notification_reads`-only path. Decision đã đúng nhưng ORM gap khiến field `read_at` thành dead column.
  
  Allocate **HS-010** (High).

- `backend/app/models/audit_log_model.py:13-25` — Multiple drift điểm với canonical `init_full_setup.sql:556`:
  - **Missing FK**: ORM declare `user_id: Integer nullable=True` không có `ForeignKey("users.id")`. Canonical: `user_id INT REFERENCES users(id) ON DELETE SET NULL`. Hệ quả: ORM cho phép insert `user_id=999` không tồn tại; DB layer constraint sẽ reject — runtime IntegrityError thay vì validation tại boundary.
  - **Missing field `device_id`**: canonical có `device_id INT REFERENCES devices(id) ON DELETE SET NULL`. ORM thiếu hoàn toàn.
  - **Missing field `error_message`**: canonical có `error_message TEXT`. ORM thiếu.
  - **Type drift `ip_address`**: ORM `String(50)`, canonical `INET` (Postgres native type với validation IPv4/IPv6 + functions). String(50) accept invalid IP, không có DB-layer validation.
  - **Missing CHECK `status`**: canonical `CHECK (status IN ('success', 'failure', 'pending'))`. ORM `String(20)` no CHECK.
  
  Allocate **HS-011** (High).

- `backend/app/models/sos_event_model.py:65` — `Alert.__table_args__` CheckConstraint `severity IN ('normal', 'high', 'critical')` — **đã document XR-002**, governed by ADR-015. Reference only, không re-flag.

- `backend/app/models/device_model.py:31` — `user_id: ForeignKey("users.id", ondelete="CASCADE")` + implicit `Mapped[int]` (NOT NULL). Canonical `init_full_setup.sql:195`: `user_id INT REFERENCES users(id) ON DELETE SET NULL` (nullable). **Đã document HS-001**, governed by ADR-010. Reference only, không re-flag.

- `backend/app/models/device_model.py:51` — `calibration_data: JSONB nullable`. Match canonical, schema-level OK. Service-layer dead-data issue đã document **HS-003**, governed by ADR-012. Reference only, không re-flag.

- `backend/app/models/relationship_model.py:18-22` — 4 field CÓ trong ORM nhưng KHÔNG có trong canonical `init_full_setup.sql:111`: `status`, `primary_relationship_label`, `tags`, `can_view_medical_info`. Đây là forward drift — ORM ahead of canonical. Có migration script sau `init_full_setup.sql` chưa incorporated, hoặc dev đã thêm column qua raw SQL ad-hoc. Anyway: canonical out-of-sync. Đây không phải bug ORM (ORM correct), mà là canonical SQL needs update. Tracked như P1 recommendation, không bug ID.

- `backend/app/models/relationship_model.py:25-29` — Default value drift: ORM `can_view_vitals=False, can_receive_alerts=False, can_view_location=False`. Canonical `init_full_setup.sql:121-123`: `can_view_vitals BOOLEAN DEFAULT true`, `can_receive_alerts BOOLEAN DEFAULT true`, `can_view_location BOOLEAN DEFAULT false`. ORM flip 2/3 default từ true → false. Caregiver mới được link sẽ KHÔNG nhận alert mặc định (`can_receive_alerts=False`) — break UX expectation UC040. Allocate **HS-012** (Medium, Security axis vì impact privacy posture default).

- `backend/app/models/risk_alert_response_model.py:33-40` — Type drift với canonical:
  - ORM `risk_score_id: Integer nullable=True` no FK. Canonical `init_full_setup.sql:526`: `risk_score_id BIGINT NULL`.
  - ORM `device_id: Integer nullable=True` no FK. Canonical: `device_id BIGINT NULL`.
  - ORM `latitude: Float`, ORM `longitude: Float`. Canonical: `latitude DOUBLE PRECISION NULL`, `longitude DOUBLE PRECISION NULL`. SQLAlchemy `Float` map sang `REAL` (4-byte) trên Postgres → precision drift cho geo coordinate. Real precision 6-7 decimal digits — inconsistent với `Numeric(10,8)` cho `FallEvent.latitude` (8 decimal digits).
  
  Allocate **HS-013** (Medium, Correctness axis).

- `backend/app/models/user_model.py` — Missing CheckConstraints canonical define:
  - Canonical `:80`: `gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other'))`. ORM no CHECK.
  - Canonical `:83`: `role VARCHAR(20) CHECK (role IN ('user', 'admin'))`. ORM no CHECK.
  - Canonical `:88`: `blood_type CHECK (blood_type IN ('A+', 'A-', ...))`. ORM no CHECK.
  - Canonical `:89`: `height_cm CHECK (height_cm > 0 AND height_cm < 300)`. ORM no CHECK.
  - Canonical `:90`: `weight_kg DECIMAL(5,2) CHECK (weight_kg > 0 AND weight_kg < 500)`. ORM `Float nullable` no CHECK + type drift.
  
  Validation tại Pydantic schema (BE-M05) là single defense layer. Nếu schema bypass (script seed, raw SQL, internal endpoint không qua Pydantic) → invalid data lọt vào DB. Gộp vào HS-010 P1 batch fix.

- `backend/app/models/sos_event_model.py:34` — `confidence: Numeric(4, 3)` (ORM) match canonical về type, **thiếu CHECK** `confidence >= 0 AND confidence <= 1`. Range validation chỉ ở DB layer.

- `backend/app/models/sos_event_model.py:48-50` — Field `survey_answers: JSONB nullable` — canonical `init_full_setup.sql:384` (fall_events) KHÔNG có field này. Forward drift. Không phải bug ORM.

### Readability

- `backend/app/models/user_model.py:24-30` — comment giải thích `gen_random_uuid()` server-side default + WHY: "INSERTs without an explicit value still populate the column". Reader hiểu pattern không phải đoán ORM behavior.
- `backend/app/models/user_model.py:34-37` — comment giải thích WHY `height_cm` dùng `SmallInteger` thay vì `Float`: "DB column is `smallint`; storing floats here previously caused silent rounding (175.5 -> 176)". Đây là regression-prevention comment best-in-class — explicitly ghi nhận past bug + lý do constraint.
- `backend/app/models/user_model.py:60-71` — comment giải thích token_version, failed_login_attempts, locked_until "Authentication state (auth-internal; not exposed via the mobile profile API on purpose)" — clarify trust boundary giữa auth surface và profile surface.
- `backend/app/models/user_model.py:76-78` — comment "Stored as VARCHAR(6) to preserve leading zeros (e.g. '012345')" — type choice rationale clear.
- `backend/app/models/relationship_model.py:34-37` — comment giải thích `can_view_medical_info` default False: "privacy posture is opt-in; the patient must explicitly toggle this on per linked contact". Privacy decision documented.
- `backend/app/models/sos_event_model.py:54-58` — comment block giải thích `survey_answers` schema + WHY NULL khi user không reach step 2. Reader hiểu data lifecycle.
- `backend/app/models/risk_explanation_model.py:38-49` — comment block giải thích `audience_payload_json` Phase 7 cache pattern + invalidation rule (`contract_version + RISK_CONTRACT_VERSION` mismatch → rebuild). Cross-reference BE-M08 risk_contract.py.
- `backend/app/models/sos_event_model.py:60-100` — **Trừ điểm**: 3 class (`FallEvent`, `Alert`, `SOSEvent`) trong cùng 1 file. Naming `sos_event_model.py` không reflect content. File >100 LoC chứa 3 unrelated entity. Refactor split sang `fall_event_model.py`, `alert_model.py`, `sos_event_model.py`. P1.
- `backend/app/models/audit_log_model.py:7` — import `Column` from sqlalchemy không sử dụng. Dead import. Minor lint.
- `backend/app/models/risk_alert_response_model.py` — docstring "Terminal response row for a single risk alert notification" 1 dòng. Đủ nhưng thiếu reference plan như các file khác.

### Architecture

- `backend/app/models/__init__.py` — Re-export 10 model + side-effect import. Đây là pattern bắt buộc cho SQLAlchemy `Base.metadata.create_all` (BE-M01 main.py dependency). Comment line 2 giải thích đúng intent. OK.
- **ORM ≠ canonical schema source-of-truth**. Steering rule: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` là canonical. Hiện tại ORM drift điểm sau canonical (HS-009 đến HS-013) + drift điểm trước canonical (relationship_model 4 extra fields, fall_events.survey_answers). Không có process gate verify sync — ko CI check, ko pre-commit hook, ko schema diff tool. Đây là **process gap** lớn nhất audit module này. Recommend P0 (Phase 4): tạo `scripts/check_schema_drift.py`.
- **Single source of truth confusion**: BE-M01 `main.py:24` `Base.metadata.create_all(bind=engine)` mỗi import → nếu DB rỗng, ORM tự tạo table theo ORM definition (drift state). Nếu DB đã có table từ canonical → `create_all` no-op (OK). Đây là race điều kiện deploy: dev local từ scratch sẽ có schema khác production. Ref BE-M01 P0 recommendation drop `create_all` đã cover.
- `relationship_model.py` 4 extra field + `fall_events.survey_answers` field — forward drift confirmed có migration sau `init_full_setup.sql` chưa merge vào canonical file. Cần update canonical file (PM_REVIEW maintenance).
- **Layering tốt**: model layer không import service/router. Không có circular import. `risk_explanation` ↔ `risk_score` relationship one-to-many với `cascade="all, delete-orphan"` consistent với canonical.
- `sos_event_model.py` 3 class trong 1 file (Architecture cohesion gap). File-level cohesion không match — Alert là generic alert table, không strict liên hệ FallEvent/SOSEvent. Refactor P1.
- **No model-level validation**: Pydantic là sole validation layer (BE-M05 schemas). Khi schema bypass (raw SQL seed, internal admin script), data invalid chỉ catch tại DB CHECK. Hiện CHECK lại không đầy đủ ở 2 tables. Defense-in-depth gap.

### Security

- **Anti-pattern auto-flag scan**: 0 hit. Không `eval/exec`, không SQL string concat (toàn parameterized), không plaintext credential, không CORS, không SSL disable, không hardcoded secret. **Security=0 override KHÔNG áp dụng.**

- `backend/app/models/relationship_model.py:25-29` — Default permission flip canonical → ORM:
  - Canonical default: `can_view_vitals=true`, `can_receive_alerts=true`, `can_view_location=false`.
  - ORM default: `can_view_vitals=False`, `can_receive_alerts=False`, `can_view_location=False`.
  
  Khi caregiver link patient mới, row insert qua ORM → 2 flag `False` (vitals + alerts). Patient không tự động cấp quyền view vitals + receive alerts. Hệ quả UX/business:
  - Caregiver chấp nhận invite → vẫn KHÔNG nhận alert SOS/fall của patient cho đến khi patient (thường là người cao tuổi) toggle on permission.
  - Đây là bug-class "default-deny" hợp lý từ privacy POV nhưng MÂU THUẪN với UC040 (link caregiver = grant alert receive). Ko có ADR document decision flip.
  
  Cần clarification ADR. Allocate **HS-012**.

- `backend/app/models/audit_log_model.py:18-19` — `user_id Integer nullable` không có FK + không CHECK → orphan audit log row có thể tồn tại với `user_id` invalid. Đây là gap audit trail integrity. Canonical `ON DELETE SET NULL` → audit log giữ orphan với user_id=NULL (đúng spec compliance — không mất audit history). Gộp vào HS-011.

- `backend/app/models/user_model.py:88-93` — `medications`, `allergies`, `medical_conditions: ARRAY(String)`. Đây là PHI nhạy cảm. Model layer không có encryption. Canonical schema cũng không (TEXT[] plaintext). Steering `40-security-guardrails.md` mandate "Encrypt at rest". Hiện chưa apply cả 2 tier. Cross-cutting concern — tracked như P1 recommendation, không bug ID.

- `backend/app/models/user_model.py:75-87` — `verification_code` + `reset_code: String(6)` plaintext PIN 6 số. 6-digit PIN có entropy log2(10^6) ≈ 20 bit. Hiện đã có rate limiter (BE-M09) + TTL 15min/24h. Defense layer ngoài DB OK, tradeoff security vs UX acceptable cho mobile auth. Document trong ADR.

- `backend/app/models/risk_alert_response_model.py` — `latitude/longitude DOUBLE PRECISION NULL` (canonical) vs `Float` (ORM). Geo coordinate = location PHI khi SOS. Type drift Float (REAL 4-byte ~6-7 digit precision) limit precision đủ ~10m accuracy ở Việt Nam. Acceptable cho life-emergency use case.

### Performance

- Composite index coverage tốt. Query hot path đều có index:
  - `Device.user_id + is_active + deleted_at` — list active device per user.
  - `UserRelationship.caregiver_id + status + deleted_at` — list pending relationship per caregiver.
  - `UserRelationship.patient_id + status + deleted_at` — list link per patient.
  - `Alert.device_id + alert_type + created_at` — query alert history per device per type.
  - `SOSEvent.user_id + status + triggered_at` — list active SOS per user.
  - `FallEvent.device_id + detected_at` — fall history.
  - `RiskScore.user_id + calculated_at` — risk timeline per user.
  - `UserPushToken.user_id + is_active` — fanout active tokens per user.
- `backend/app/models/audit_log_model.py:13` — TimescaleDB hypertable composite PK `(id, time)` match canonical. OK.
- JSONB GIN index thiếu cho `Device.calibration_data`, `FallEvent.features`, `Alert.details`, `RiskScore.features`, `RiskExplanation.feature_importance`, `RiskExplanation.audience_payload_json`. Query pattern hiện tại chưa scan JSONB nên acceptable. Forward-looking P2.
- Không thấy missing index trên FK. OK.
- `risk_explanations.model_request_id` có partial index canonical `WHERE model_request_id IS NOT NULL`. ORM declare `index=True` thường là full index. Drift performance minor, P2.
- `Alert.user_id + read_at` — canonical có `idx_alerts_unread` partial WHERE `read_at IS NULL`. ORM không có (vì ORM không expose `read_at` field — gộp HS-010).
- Không có N+1 risk model layer — relationship lazy loading default. Service layer cần explicit `selectinload`/`joinedload` (BE-M03 + BE-M06 scope).

## Positive findings

- `backend/app/models/user_model.py:34-37` — comment regression-prevention "DB column is `smallint`; storing floats here previously caused silent rounding (175.5 -> 176)". Best-in-class: capture past bug + rationale ngay tại declaration.
- `backend/app/models/user_model.py:24-30` + `:43-50` — server_default dùng `text("gen_random_uuid()")` + ARRAY mirror DB default `'{}'`. Pattern đúng cho schema-DB-truth.
- `backend/app/models/sos_event_model.py:54-58` — `survey_answers JSONB nullable` comment block rõ schema + lifecycle. JSONB field self-documenting.
- `backend/app/models/risk_explanation_model.py:38-49` — comment Phase 7 audience cache + invalidation rule. Cross-reference BE-M08 risk_contract.py.
- Composite index naming convention `ix_<table>_<col1>_<col2>_<col3>` consistent across files. Reader trace index ↔ query path dễ.
- `backend/app/models/__init__.py` re-export pattern đúng cho SQLAlchemy `Base.metadata.create_all` semantics.
- Snake_case + plural table naming consistent ở 100% models.
- Soft-delete pattern (`deleted_at: nullable timestamp`) consistent ở `User`, `Device`, `UserRelationship`. Match steering `25-docs-sql.md`.
- `backend/app/models/relationship_model.py:34-37` — privacy decision documented inline cho `can_view_medical_info`.
- `RiskScore.explanations` cascade="all, delete-orphan" match canonical `ON DELETE CASCADE`.
- `UserRelationship.patient_id != caregiver_id` CheckConstraint match canonical — chống self-referencing relationship row.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-009 | Critical | `UserPushToken` ORM `__tablename__="user_push_tokens"` không match canonical `user_fcm_tokens`; deploy qua canonical SQL → ORM bind tới relation không tồn tại, FCM register/dispatch raise ProgrammingError | `backend/app/models/push_token_model.py:14` | Correctness |
| HS-010 | High | `Alert` ORM thiếu 7 field canonical (`sos_event_id`, `sent_at`, `delivered_at`, `read_at`, `acknowledged_at`, `sent_via TEXT[]`, `expires_at`) + thiếu CHECK alert_type 12 values; service Phase 4 implement notification tracking phải bypass ORM | `backend/app/models/sos_event_model.py:60-100` | Correctness |
| HS-011 | High | `AuditLog` ORM drift canonical: missing FK `user_id`/`device_id`, missing field `device_id`+`error_message`, type drift `ip_address String(50)` vs canonical `INET`, missing CHECK status | `backend/app/models/audit_log_model.py:13-25` | Correctness + Security |
| HS-012 | Medium | `UserRelationship` default permission flip canonical `true` → ORM `False` cho `can_view_vitals`+`can_receive_alerts`; caregiver mới link KHÔNG nhận alert mặc định, mâu thuẫn UC040 | `backend/app/models/relationship_model.py:25-29` | Security |
| HS-013 | Medium | `RiskAlertResponse` type drift: `risk_score_id`+`device_id` Integer vs BIGINT, `latitude`+`longitude` Float (REAL 4-byte) vs DOUBLE PRECISION; precision drift inconsistent với `FallEvent.latitude Numeric(10,8)` | `backend/app/models/risk_alert_response_model.py:33-40` | Correctness |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-009**: Resolve `user_push_tokens` vs `user_fcm_tokens` tablename mismatch. 2 option:
  - **Option A** (recommend): Rename ORM `__tablename__` → `user_fcm_tokens`. Update `UNIQUE(token)` → `UNIQUE(user_id, token)`. Add CHECK platform IN (android, ios, web). Drop hoặc bổ sung `device_id`/`last_seen_at` extra fields.
  - **Option B**: Update canonical → `user_push_tokens` (break HealthGuard admin BE nếu cross-repo reference).
  - Decision require ADR (table name = cross-repo contract).
  - Pre-flight: `SELECT to_regclass('user_fcm_tokens'), to_regclass('user_push_tokens');`
  - Regression test `tests/test_push_token_schema.py::test_orm_table_matches_canonical`.

### P1

- [ ] **HS-010**: Add 7 missing field vào `Alert` ORM + CHECK alert_type. Đồng thời align partial index `idx_alerts_unread`.
- [ ] **HS-011**: Fix `AuditLog` ORM. Add FK + missing fields + type INET + CHECK status. Cleanup unused `Column` import.
- [ ] **HS-012**: ADR-016 proposed quyết định privacy posture. Recommend Option 1 (canonical đúng): ORM revert `default=True` cho `can_view_vitals` và `can_receive_alerts`. Migration update existing rows.
- [ ] **HS-013**: Align `RiskAlertResponse` types: `Integer → BigInteger`, `Float → DOUBLE_PRECISION`, add FK `device_id`.
- [ ] **users CheckConstraints batch**: Add `__table_args__` cho `User`: gender, role, blood_type, height_cm, weight_kg + change `weight_kg Float → Numeric(5, 2)`.
- [ ] **Refactor split** `sos_event_model.py` → 3 file riêng. Update `__init__.py` re-export.
- [ ] **Update canonical SQL** với 4 extra field `UserRelationship` + `FallEvent.survey_answers`. Migration script `PM_REVIEW/SQL SCRIPTS/YYYYMMDD_relationship_status_extra_fields.sql`.
- [ ] **CheckConstraint `confidence` cho FallEvent**: add `CheckConstraint("confidence >= 0 AND confidence <= 1", name="check_fall_confidence")`.

### P2

- [ ] Schema drift CI check: `scripts/check_schema_drift.py` parse canonical → compare với ORM `Base.metadata.tables`. Run trong GitHub Actions.
- [ ] Cleanup unused import `Column` từ `audit_log_model.py:7`.
- [ ] Add docstring + plan reference cho `RiskAlertResponse`.
- [ ] JSONB GIN index forward-looking khi service scan JSONB filter.
- [ ] Align partial index `idx_risk_explanations_model_request_id` ORM-side với canonical partial form.
- [ ] PHI encryption strategy ADR (cross-cutting): `medications`, `allergies`, `medical_conditions` plaintext. Cân nhắc pgcrypto hoặc app-layer envelope encryption.

## Out of scope

- Pydantic schema field-by-field validation — BE-M05 schemas.
- Repository pattern + session management — BE-M06 repositories.
- Migration script execution + canonical SQL maintenance — BE-M11 + PM_REVIEW maintenance.
- Service-layer consumer của model field — BE-M03 services.
- TimescaleDB hypertable + compression + retention policy — canonical SQL maintenance.
- ADR-016 proposed (privacy posture) — ADR scope.
- Defer Phase 3: per-relationship deep audit của `RiskExplanation.audience_payload_json` cache invalidation.
- D3 (notification read state truth) — reference only, governed by Phase 0.5 NOTIFICATIONS.md reverify.
- Cross-repo impact của HS-009 với HealthGuard admin BE — flag XR-* nếu fix Option A break consumer.

## Cross-references

- BUGS INDEX (new):
  - HS-009 — `user_push_tokens` vs `user_fcm_tokens` tablename mismatch (Critical)
  - HS-010 — `Alert` ORM thiếu 7 field canonical (High)
  - HS-011 — `AuditLog` ORM drift FK + field + type (High)
  - HS-012 — `UserRelationship` default permission flip canonical (Medium)
  - HS-013 — `RiskAlertResponse` type drift Integer/Float (Medium)
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-001](../../../BUGS/HS-001-devices-schema-drift-canonical.md) — devices `user_id` ondelete CASCADE vs canonical SET NULL (governed ADR-010).
  - [HS-003](../../../BUGS/HS-003-calibration-offsets-never-consumed.md) — `Device.calibration_data` 3 offset key dead (governed ADR-012).
  - [XR-002](../../../BUGS/XR-002-be-sqlalchemy-severity-checkconstraint-drift.md) — `Alert.severity` CheckConstraint drift (governed ADR-015, batch với HS-010).
- ADR INDEX:
  - [ADR-010](../../../ADR/INDEX.md) — Devices schema canonical (HS-001 governs).
  - [ADR-012](../../../ADR/INDEX.md) — Drop calibration offset (HS-003 governs).
  - [ADR-015](../../../ADR/INDEX.md) — Alert severity taxonomy (XR-002 + HS-010 alert_type CHECK).
  - **ADR-016 proposed** (HS-012 driver): UserRelationship default permission posture.
- Intent drift (reference only — không re-flag):
  - `D1` — severity vocabulary drift. Governed ADR-015.
  - `D3` — notification read state truth source. Governed Phase 0.5 NOTIFICATIONS.md reverify. HS-010 P1 add `read_at` field nhưng implement chỉ persist via `notification_reads` table.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — `Base.metadata.create_all` drop scheduled.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — `core/alert_constants.py` ESCALATION_MATRIX vs `Alert.severity`/`RiskScore.risk_level` vocabulary.
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md) — utility layer không touch model.
  - `BE_M05_schemas_audit.md` (Task 5 pending) — Pydantic mirror của model field.
  - `BE_M02_routes_audit.md` (Task 6 pending) — endpoint serialize model qua response_model.
  - `BE_M03_services_audit.md` (Task 9 pending) — service consume Alert.expires_at + UserRelationship permission flag.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Canonical schema: [`PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`](../../../SQL%20SCRIPTS/init_full_setup.sql)
