# Audit: BE-M03 — services (business logic layer, HEAVIEST)

**Module:** `health_system/backend/app/services/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module services chứa business logic + orchestration cho toàn bộ backend. Module nặng nhất Phase 1 audit — 17 file thực + `__init__.py`, ~8,400 LoC total. Focus: single responsibility, layer purity, business logic correctness (alert severity, escalation matrix, fall state machine, push fan-out), PHI handling + audit log, transactional boundary, model-api adapter consumption, circuit breaker integration. Phạm vi loại trừ: router (BE-M02), schema (BE-M05), repository/ORM (BE-M04, BE-M06), adapter detail (BE-M07).

| File | LoC | Purpose | Critical concerns |
|---|---|---|---|
| `__init__.py` | 0 | Package marker | Empty. |
| `monitoring_service.py` | 1417 | Vitals/sleep/risk-report/health-report orchestration | HEAVIEST. Audience cache + projection logic. |
| `auth_service.py` | 1031 | Register/login/refresh/verify/forgot/reset/change | Audit log mọi flow. HS-016 password policy reference. |
| `relationship_service.py` | 746 | M:N relationship lifecycle + family snapshot dashboard | N+1 risk lookup multi contact vitals. |
| `risk_inference_service.py` | 637 | Local rule-based + ONNX + LightGBM fallback inference | Multi-backend dispatch. |
| `emergency_service.py` | 641 | SOS trigger + resolution + fan-out | G-3/G-4 location redaction documented. |
| `push_notification_service.py` | 609 | FCM push fan-out cho SOS/fall/risk | Direct ORM query (HS-019 pattern). |
| `device_service.py` | 500 | Device pair/list/configure | Consumer của HS-001/HS-003 schema drift. |
| `admin_device_service.py` | 448 | Internal admin device CRUD | Consumer ADR-005. |
| `risk_alert_service.py` | 412 | Risk alert dispatch + escalation matrix | Consumer adapter pattern (BE-M07). |
| `fall_event_service.py` | 391 | Fall event list/dismiss/survey state machine | Module FA-2 Option 3-Lite documented. |
| `notification_service.py` | 385 | List/detail/mark-read + push token CRUD | D3 read state truth (notification_reads table-of-truth). |
| `model_api_client.py` | 321 | httpx wrapper cho 3 model-api endpoints | NO X-Internal-Secret outbound (HS-021). |
| `settings_service.py` | 285 | General settings R/W + sleep threshold lookup | ADR-008 mobile BE không host settings write. |
| `circuit_breaker.py` | 216 | Circuit breaker state machine cho model_api_client | Phase 7 Resilience layer. |
| `risk_report_builder.py` | 195 | NormalizedRiskRow → mobile DTO consumer | Read-path adapter (BE-M07 cross-link). |
| `profile_service.py` | 102 | Profile R/W + delete account | Consume `validate_age` shared utility. |
| `normalized_risk_row.py` | 70 | Frozen dataclass cho read path | Producer-consumer cycle break. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Audit log pattern consistent. State machine fall_event đúng. Trừ điểm: HS-021 model_api_client missing X-Internal-Secret outbound; multiple `except Exception:` swallow trong relationship_service (4 chỗ default empty/None); D1 escalation matrix consumer pattern (XR-002 reference). |
| Readability | 2/3 | Best-in-class `model_api_client.py` docstring + circuit breaker integration. Trừ điểm: monitoring_service 1417 LoC fat service; auth_service 1031 LoC; comment pattern inconsistent. |
| Architecture | 1/3 | **Service vi phạm Repository boundary**: 6/17 service trực tiếp `db.query(Model)` (BE-M06 finding compound). Fat services > 500 LoC: monitoring (1417), auth (1031), relationship (746), risk_inference (637), emergency (641), push_notification (609), device (500). |
| Security | 1/3 | KHÔNG hit anti-pattern auto-flag. Trừ điểm: HS-021 outbound auth header missing → cross-repo trust violation; PHI logging risk medium (`logger.exception` có thể leak vital values); audit log scope incomplete (PHI access endpoint thiếu); `_EXPOSE_CODES_FOR_TESTING` env-driven nhưng không centralize qua Settings. |
| Performance | 2/3 | Circuit breaker pattern Phase 7 đúng. StageTimer instrument đầy đủ. BackgroundTasks pattern. Trừ điểm: relationship_service N+1 lookup vitals/health_report cho mỗi contact; audit log mỗi auth flow 3 round-trip; monitoring_service audience cache validate-rebuild loop. |
| **Total** | **8/15** | Band: **🟠 Needs attention** — không Security=0 override (anti-pattern auto-flag không hit hardcoded), nhưng Architecture rớt mạnh + nhiều Medium-severity findings. |

## Findings

### Correctness

- **HS-021 — `model_api_client.py:101` outbound header missing `X-Internal-Secret`**:
  ```python
  self._client = httpx.Client(
      base_url=self._base_url,
      timeout=self._timeout,
      headers={"X-Internal-Service": "health-system-backend"},
  )
  ```
  Chỉ set `X-Internal-Service` (service identifier) — KHÔNG set `X-Internal-Secret` mandate per ADR-005. Nếu model-api side enforce `X-Internal-Secret` (consistent với `core/dependencies.py:require_internal_service`), production deploy → outbound call 401/403 cho cả 3 endpoint health/fall/sleep predict → fall back rule-based local inference. Dev local OK vì cả 2 side fail-open (cùng HS-006 pattern compound).
  - **Verify cross-repo cần thiết**: `healthguard-model-api/app/routers/` `Depends(require_internal_service)` enforce header gì.
  - Nếu cross-repo enforce: outbound fail → silent degradation (rule-based fallback path) → local inference accuracy thấp hơn → false negative risk.
  - Nếu cross-repo không enforce: cả 2 side cùng fail-open → ADR-005 không thực thi.
  - Allocate **HS-021** (Critical, Security axis — cross-repo auth contract violation).

- `backend/app/services/risk_alert_service.py:212-218, 313-316, 368-371` — 3 instance `except Exception:` với `logger.exception` + comment justification:
  ```python
  except Exception:  # noqa: BLE001 - never let caregiver lookup break risk pipeline
      logger.exception(...)
  ```
  Pattern "never break critical pipeline" + log-and-continue đúng. Comment captures intent. Acceptable.

- `backend/app/services/relationship_service.py:480-547, 575-578` — 4 instance `except Exception:` swallow → default `None`/`[]` mà KHÔNG `logger.exception`:
  ```python
  except Exception:
      active_sos_events = []
  ...
  except Exception:
      vitals = None
  ...
  except Exception:
      health_report = None
  ```
  Vi phạm steering `22-fastapi.md` anti-pattern "except Exception: không log + không re-raise". Silent failure → caregiver dashboard render incomplete data without warning. Allocate **HS-022** (Medium).

- `backend/app/services/auth_service.py:962-965, 1051-1054` — 2 instance `except Exception:` với `logger.warning`:
  ```python
  try:
      EmailService.send_password_changed_notification(user.email)
  except Exception:
      logger.warning("Password reset notification email failed for user %s", user.id)
  ```
  Email send failure không nên block password reset success path. `logger.warning` thay vì `logger.exception` minor. Acceptable nhưng P2 upgrade.

- `backend/app/services/auth_service.py:1-200` — register flow:
  - Email pattern regex (line 28) inconsistent với schema layer (BE-M05) regex tay vs `EmailStr` Pydantic-native. Duplicate validation.
  - `validate_password_strength` (utils/password.py BE-M09) gọi sau Pydantic schema validate. Defense-in-depth tốt, runtime password policy strict 8+ even when schema cho phép 6+ (HS-016 reference) → service-side guard runtime đúng.
  - Audit log mỗi failure path (Invalid email/Invalid full_name/Password validation/Age validation/Email exists) — comprehensive.
  - Re-register flow cho unverified user (line 138-180) — race condition nhỏ: nếu 2 concurrent re-register cùng email, last write wins. Acceptable severity Low — UX edge case.

- `backend/app/services/monitoring_service.py:1280-1340` — Audience cache validation + rebuild:
  ```python
  try:
      result = model.model_validate(payload)
  except Exception:  # noqa: BLE001 - fall back to rebuild on any parse error
      logger.exception("Audience cache hit but payload failed validation; rebuilding")
  ```
  Cache hit but contract drift → invalidate + rebuild. Pattern đúng cho cross-version compat.

- `backend/app/services/monitoring_service.py:1336-1340` — Cache write fail silent:
  ```python
  except Exception:  # noqa: BLE001 - cache write must never break the request flow
      db.rollback()
      logger.exception(...)
  ```
  "must never break request flow" comment justified. Pattern OK.

- `backend/app/services/fall_event_service.py:353-358` — Fall follow-up concern fan-out:
  ```python
  except Exception:  # noqa: BLE001
      logger.exception("Failed to fan follow-up concern for fall_event id=%s", row.id)
  ```
  Module FA-2 Option 3-Lite. Failure không block dismiss. Acceptable.

- `backend/app/services/emergency_service.py:399-405` — Risk alert response idempotency:
  ```python
  except Exception:
      db.rollback()
      raise HTTPException(...)
  ```
  Re-raise after rollback — caller sees error. Pattern correct.

### Readability

- `backend/app/services/model_api_client.py:1-50` — module docstring giải thích graceful fallback + 3 env var + Phase 7 circuit breaker integration. Best-in-class.
- `backend/app/services/circuit_breaker.py` — Phase 7 resilience layer documented (chưa đọc full content nhưng module name + import pattern clear).
- `backend/app/services/auth_service.py` — register flow comment per validation step. Khá tốt nhưng 1031 LoC chứa 9 method (register/login/refresh/verify/resend/forgot/reset/change/verify_reset) → reader phải scroll nhiều.
- `backend/app/services/monitoring_service.py` — 1417 LoC fat service. Chứa 12+ method. Comment per method OK nhưng module-level overview thiếu.
- `backend/app/services/relationship_service.py` — 746 LoC chứa dashboard snapshot orchestration + relationship CRUD. Mix concern. Split candidate.
- Comment pattern inconsistent: `risk_alert_service` có `# noqa: BLE001 - never let X break Y` justification → reader hiểu intent. `relationship_service` không có justification → silent swallow ambiguous.
- Vietnamese error message consistent across services. OK.
- Service docstring missing trong `notification_service`, `device_service`, `admin_device_service`. Module-level intent unclear.

### Architecture

- **Service vi phạm Repository boundary**: 6/17 service trực tiếp `db.query(Model)`:
  - `monitoring_service.py` — `db.query(RiskScore)`, `db.query(RiskExplanation)`.
  - `risk_alert_service.py` — `db.query(RiskScore).filter(...).order_by(...).first()`.
  - `push_notification_service.py` — `db.query(UserPushToken).filter(is_active=True)...`.
  - `notification_service.py` — `db.query(Alert)`, `db.query(NotificationRead)`.
  - `device_service.py` — `db.query(Device)` direct.
  - `admin_device_service.py` — `db.query(Device)` direct.
  
  Vi phạm steering `22-fastapi.md` "Router → Service → Repository → ORM" layering. Repository pattern coverage gap (BE-M06 HS-019 reference) compound trong service layer. Phase 4 P1 batch fix với BE-M06 P1.

- **Fat services > 500 LoC**:
  - `monitoring_service.py` 1417 LoC — split candidate `vitals_service.py` + `sleep_service.py` + `risk_report_service.py` + `audience_cache_service.py`.
  - `auth_service.py` 1031 LoC — split `register_service.py` + `login_service.py` + `password_reset_service.py` + `email_verification_service.py`.
  - `relationship_service.py` 746 LoC — split `relationship_lifecycle_service.py` + `family_dashboard_service.py`.
  - `risk_inference_service.py` 637 LoC — multi-backend dispatch acceptable cohesion.
  - `emergency_service.py` 641 LoC — multi-flow OK cohesion.
  - `push_notification_service.py` 609 LoC — split candidate `fcm_dispatch_service.py` + `push_token_lifecycle_service.py`.
  - `device_service.py` 500 LoC — borderline.
  
  P1 refactor batch sau khi repository pattern complete.

- **Adapter consumption clean**: `risk_alert_service.py` consume adapter từ `app.adapters` (BE-M07). `telemetry.py` route consume `FallPersistenceAdapter` + `RiskPersistenceAdapter` + `SleepRiskAdapter` directly. Phase 3b extraction successful — service không re-implement persistence logic.

- **Circuit breaker integration đúng**: `model_api_client.py` 3 breaker independent (health/fall/sleep). Pattern Phase 7 Resilience documented inline. Reader hiểu degradation isolated.

- **`risk_report_builder.py` placement**: 195 LoC ở `services/`. Có thể là `MobileRiskDtoAdapter` per BE-M07 finding — Phase 4 P2 move sang `adapters/`.

- **Producer-consumer cycle**: `normalized_risk_row.py` (services) consumer của `monitoring_service` read path. `NormalizedExplanation` (adapters) producer cho write path. 2 type khác nhau. Architecture cycle-break documented BE-M07. OK.

- **Settings service ADR-008 compliance**: `settings_service.py` chỉ R/W general settings + sleep threshold lookup. Verify trong file content cần — chưa đọc full.

### Security

- **Anti-pattern auto-flag scan**:
  - `eval()` / `exec()`? **NO** — grep confirm 0 hit.
  - SQL string concat? **NO** — toàn ORM `db.query(...)` parameterized.
  - **Plaintext credential / hardcoded secret?** **NO** trong service scope (HS-020 ở BE-M06).
  - CORS wildcard? scope BE-M01.
  - SSL verify disabled? **NO** — `httpx.Client(...)` default verify=True.
  - Token in localStorage? **NO**.
  - `dangerouslySetInnerHTML`? **NO**.
  
  **Kết luận: 0 hit anti-pattern auto-flag. Security=0 override KHÔNG áp dụng.**

- **HS-021 (Critical) — Cross-repo outbound auth header missing**:
  - File: `backend/app/services/model_api_client.py:101`.
  - Severity: Critical (Security axis impact, ADR-005 violation).
  - Root cause: `httpx.Client(...)` set `X-Internal-Service` header nhưng KHÔNG set `X-Internal-Secret`.
  - Impact:
    - Production deploy với model-api enforce X-Internal-Secret: 3 outbound endpoint all return 401/403 → silent fall back to rule-based local inference. Mobile app không nhận model-api accuracy.
    - Production deploy với model-api fail-open (cùng HS-006 pattern compound): cả 2 side không enforce → attacker can spoof header bypass cross-service auth.
  - Mitigation:
    - Add `headers={"X-Internal-Service": "health-system-backend", "X-Internal-Secret": settings.internal_service_secret_outbound}`.
    - Pre-flight: verify cross-repo enforce.
    - Coordinate với HS-006 fix.
    - Consider rotation strategy cho secret per ADR-005.
  - Allocate **HS-021** (Critical).

- **HS-022 — `relationship_service` silent error swallow**:
  - File: `backend/app/services/relationship_service.py:480, 547, 575`.
  - Severity: Medium (Correctness axis).
  - Root cause: 4 instance `except Exception:` default empty/None mà KHÔNG log.
  - Impact:
    - Caregiver dashboard render incomplete data without warning.
    - Production debug khó vì không có audit trail.
  - Mitigation: thêm `logger.exception(...)` cho mỗi swallow.
  - Allocate **HS-022** (Medium).

- `backend/app/services/auth_service.py` — Audit log mỗi failure path comprehensive. Compliance steering. Positive.

- `backend/app/services/auth_service.py:962-965` — Email send failure → `logger.warning` not `logger.exception`. P2 upgrade.

- **PHI logging risk**: `logger.exception(...)` patterns trong service layer có thể leak PHI nếu vital data trong stack frame local variable. Steering `40-security-guardrails.md` mandate "Không log password/token/health vitals raw. Dùng mask". Defense-in-depth: configure logging filter mask sensitive field. P1 cross-cutting.

- `backend/app/services/auth_service.py` — `_EXPOSE_CODES_FOR_TESTING` ref BE-M02. Service consume verify codes → cần guard production.

- `backend/app/services/model_api_client.py:325-340` — Module-level singleton `_model_api_client`. Test hook `set_model_api_client_for_tests` clean. Singleton pattern OK cho httpx Client (thread-safe per docs).

- `backend/app/services/notification_service.py:385 LoC` — D3 read state truth source consumer. Phase 0.5 NOTIFICATIONS.md reverify decided "keep notification_reads table-of-truth, drop inline". Service implement đúng pattern. Reference only.

- `backend/app/services/relationship_service.py` — Family dashboard PHI access (vitals, health report) cho caregiver. Steering mandate audit log mọi access PHI. Verify per-method `audit_log_repository.log_action(action="caregiver.view_vitals", ...)` cần Phase 4 review. P1.

### Performance

- `backend/app/services/model_api_client.py` — Circuit breaker Phase 7 protect outbound model-api timeout. 3 breaker independent. StageTimer instrument đầy đủ. **Best-in-class resilience**.

- `backend/app/services/relationship_service.py:540-580` — N+1 lookup multi contact:
  ```python
  for contact in contacts:
      vitals = MonitoringService.get_latest_vital_signs(contact.id, db)  # 1 query per contact
      health_report = MonitoringService.get_health_report(contact.id, db)  # multi-query per contact
  ```
  Nếu user link 5 contact → 5 × (vitals + health_report) = 10+ query để render dashboard. Scale pain. Phase 4 P1 batch fetch.

- `backend/app/services/monitoring_service.py` — Audience cache hit-rate optimization:
  - Cache hit + contract version match → return cached payload.
  - Cache miss / contract drift → rebuild + write.
  - Pattern đúng nhưng `db.rollback()` on cache write fail (line 1336-1340) impact subsequent transaction.

- `backend/app/services/auth_service.py` — Audit log mỗi auth flow 3 round-trip. Cao tải auth login spike → `BackgroundTasks` queue. P2.

- `backend/app/services/push_notification_service.py:609 LoC` — Push fan-out với BackgroundTasks. KHÔNG block request thread. OK.

- `backend/app/services/risk_inference_service.py:637 LoC` — Multi-backend dispatch. Acceptable cho fallback path.

- `backend/app/services/fall_event_service.py:391 LoC` — State machine fall event với BackgroundTasks fan-out. OK.

- `backend/app/services/circuit_breaker.py:216 LoC` — State machine + threshold logic. Acceptable cho rate-limiting use case.

- Không có async-sync mismatch obvious — toàn service `def` (sync) consistent.

## Positive findings

- `backend/app/services/model_api_client.py:1-50` — module docstring best-in-class với Phase 7 circuit breaker integration + graceful fallback documentation.
- `backend/app/services/model_api_client.py:67-76` — 3 independent circuit breaker (health/fall/sleep) — fail isolation principle. Comment "A failing sleep model must not silence health alerts, and vice versa".
- `backend/app/services/model_api_client.py:130-185` — `predict_health_risk` đầy đủ defense:
  - Disabled flag short-circuit.
  - Breaker open short-circuit + log warning.
  - Network error → record_failure + log + return None.
  - Non-200 status → record_failure.
  - Malformed JSON → KHÔNG record_failure (contract bug not outage).
  - Empty results → return None.
  - Success → record_success.
  
  Pattern reusable cho 3 endpoint. Excellent error handling.
- `backend/app/services/auth_service.py` — Audit log mỗi failure path comprehensive. Compliance steering.
- `backend/app/services/risk_alert_service.py:212-216` — `# noqa: BLE001 - never let X break Y` justification comment.
- `backend/app/services/fall_event_service.py:353-358` — Module FA-2 Option 3-Lite documented inline.
- `backend/app/services/monitoring_service.py:1280-1340` — Audience cache validation + rebuild pattern Phase 7.
- `backend/app/services/auth_service.py:31-33` — `_generate_pin_code` dùng `secrets.randbelow` cryptographically secure (không dùng `random.randint`).
- `backend/app/services/model_api_client.py:325-340` — Test hook `set_model_api_client_for_tests` + module-level singleton lazy-init.
- `backend/app/services/auth_service.py:38-43` — `validate_age` shared utility consume từ `utils/age_validator.py` — register + profile update consistent.
- Service docstring per method consistent với Args/Returns/Raises pattern.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-021 | Critical | `model_api_client.py:101` outbound `httpx.Client` chỉ set `X-Internal-Service` header — KHÔNG set `X-Internal-Secret` mandate per ADR-005; production deploy với model-api enforce → 401/403 silent fall back; với model-api fail-open → cross-service auth contract bypass | `backend/app/services/model_api_client.py:101` | Security |
| HS-022 | Medium | `relationship_service.py` 4 instance `except Exception:` default empty/None KHÔNG `logger.exception` (line 480, 547, 575); caregiver dashboard render incomplete data without warning, vi phạm steering 22-fastapi.md anti-pattern | `backend/app/services/relationship_service.py:480-578` | Correctness |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-021**: Fix outbound auth header missing.
  - Pre-flight: grep cross-repo `healthguard-model-api/app/` xác định header enforce.
  - Add `X-Internal-Secret` header trong `httpx.Client(...)` initialization. Driven từ `Settings.model_api_secret`.
  - Verify model-api accept new header.
  - Regression test: monkeypatch `settings.model_api_secret` + assert outbound header present.
  - Coordinate với HS-006 fix → cả 2 side enforce contract.

### P1

- [ ] **HS-022**: Fix 4 silent error swallow trong `relationship_service.py:480, 547, 575`. Add `logger.exception(...)` mỗi instance + comment justification rationale.
- [ ] **Service-Repository boundary fix**: refactor 6 service consume `db.query(Model)` direct → repository call. Phase 4 batch với BE-M06 P1.
- [ ] **Fat service split**:
  - `monitoring_service.py` (1417 LoC) → 4 file.
  - `auth_service.py` (1031 LoC) → 4 file.
  - `relationship_service.py` (746 LoC) → 2 file.
  - `push_notification_service.py` (609 LoC) → 2 file.
- [ ] **PHI logging filter**: configure logging filter mask sensitive field. Cross-cutting steering compliance.
- [ ] **N+1 dashboard fetch**: `relationship_service.py:540-580` batch fetch contacts vitals + health report.
- [ ] **PHI access audit log**: per-method `audit_log_repository.log_action(action="caregiver.view_vitals", ...)`. Compliance steering.

### P2

- [ ] **`risk_report_builder.py` move sang `adapters/`**: rename → `adapters/mobile_risk_dto_adapter.py`. Match symmetric naming.
- [ ] **`auth_service.py:962-965, 1051-1054` upgrade `logger.warning` → `logger.exception`**.
- [ ] **Audit log batch**: `BackgroundTasks` queue cho audit log mỗi auth flow.
- [ ] **Settings service ADR-008 verify**: cross-check `settings_service.py` không host system settings write.
- [ ] **Service docstring module-level**: thêm cho `notification_service`, `device_service`, `admin_device_service`, `risk_inference_service`.
- [ ] **Email validator consistency**: `auth_service.py:28` regex tay vs Pydantic `EmailStr`. Standardize.

## Out of scope

- Adapter implementation detail — BE-M07.
- Schema definition — BE-M05.
- Repository pattern — BE-M06.
- Router consumer — BE-M02.
- Model schema — BE-M04.
- Cross-repo `healthguard-model-api` enforce header verify — out of scope, ADR-005 governs.
- Defer Phase 3: per-method unit test coverage gap, integration test for circuit breaker, contract test snapshot.
- Pydantic-settings migration toàn codebase — batch P1.
- ADR-016 proposed (UserRelationship default permission posture, BE-M04 HS-012).

## Cross-references

- BUGS INDEX (new):
  - HS-021 — `model_api_client.py` outbound auth header missing X-Internal-Secret (Critical)
  - HS-022 — `relationship_service.py` silent error swallow 4 instance (Medium)
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-002](../../../BUGS/HS-002-device-unique-mac-cross-user-bypass.md) — device service cross-user MAC bypass.
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open; compound với HS-021.
  - [HS-008](../../../BUGS/INDEX.md) — Rate limiter TOCTOU; auth_service consumer.
  - [HS-016](../../../BUGS/INDEX.md) — Password policy inconsistent; service-side `validate_password_strength` defense.
  - [HS-019](../../../BUGS/INDEX.md) — Router SQL bypass; service Repository violation pattern compound.
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md) — Internal service auth strategy. HS-021 violation.
  - [ADR-008](../../../ADR/INDEX.md) — Mobile BE không host system settings write. `settings_service.py` consumer.
  - [ADR-013](../../../ADR/INDEX.md) — IoT Simulator direct-DB write.
  - [ADR-015](../../../ADR/INDEX.md) — Alert severity taxonomy. `risk_alert_service` consumer.
- Intent drift (reference only — không re-flag):
  - `D1` — severity vocab drift. Governed ADR-015. `risk_alert_service.py` consumer.
  - `D3` — notification read state truth source. Governed Phase 0.5. `notification_service.py` implement.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md) — HS-019 router SQL bypass compound trong service.
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md) — ORM consumer trực tiếp trong service.
  - [`BE_M05_schemas_audit.md`](./BE_M05_schemas_audit.md).
  - [`BE_M06_repositories_db_audit.md`](./BE_M06_repositories_db_audit.md) — repository pattern coverage gap.
  - [`BE_M07_adapters_audit.md`](./BE_M07_adapters_audit.md) — adapter consumer pattern.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — HS-006 fail-open compound.
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md) — utils consumer trong auth_service.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/22-fastapi.md`, `40-security-guardrails.md`.
