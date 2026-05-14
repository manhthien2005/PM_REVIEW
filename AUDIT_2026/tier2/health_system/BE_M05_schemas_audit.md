# Audit: BE-M05 — schemas (Pydantic v2 boundary validation)

**Module:** `health_system/backend/app/schemas/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module schemas chứa Pydantic v2 model định nghĩa request/response shape cho mọi router. Scope audit = 11 file Python (`__init__.py` empty + 10 file thực, ~1,500 LoC). Focus: input validation coverage tại router boundary (constraints, regex, range), response_model leak check (PII/PHI exposure), Pydantic v2 best practice (`model_config = ConfigDict(...)`, `field_validator`), `extra=forbid` policy, naming convention, deprecated field handling. Phạm vi loại trừ: Pydantic v1 → v2 migration history, router consumption (BE-M02), service-layer DTO conversion (BE-M03), model attribute mirror (BE-M04).

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `__init__.py` | 0 | Package marker | Empty. |
| `auth.py` | ~165 | 9 schema cho register/login/refresh/verify/forgot/reset/change | `field_validator` toàn bộ flow, regex VI diacritic. |
| `device.py` | ~145 | 8 schema cho create/update/scan-pair/settings/list device | HS-003 reference (3 offset field dead). |
| `emergency.py` | ~165 | 12 schema SOS/risk-alert response/resolve | `Literal[]` enum-like consistent. |
| `fall_telemetry.py` | ~265 | 10 schema IMU window + fall_event response/dismiss/survey | Best comment quality + cross-ref model-api. |
| `family.py` | ~30 | 2 schema family profile snapshot + linked contact detail | Field overlap với `relationship.py` — duplication. |
| `general_settings.py` | ~25 | 2 schema general settings R/W | Strict `pattern` cho theme. |
| `monitoring.py` | ~270 | 14 schema vitals/sleep/risk-report (deprecated alias chain) | Phase 1-6 deprecation field documented. |
| `notification.py` | ~55 | 6 schema notification list/read/push token | OK. |
| `profile.py` | ~165 | 3 schema profile R/W + delete account | `field_validator` tốt + i18n gender mapping. |
| `relationship.py` | ~120 | 11 schema relationship + linked contact medical info | **Field overlap với `family.py` `FamilyProfileSnapshot`** (duplicate). |
| `sleep_telemetry.py` | ~110 | 3 schema sleep risk request/response | Mirror model-api SleepRecord verbatim. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Validators chính xác, regex VI diacritic OK, `Literal` enum hợp lý. Trừ điểm: schema bypass model CHECK (BE-M04 missing CHECK), `PatientInfo.date_of_birth: Optional[str]` không validate format, HS-003 schema vẫn expose 3 dead field. |
| Readability | 3/3 | Comment best-in-class trong `fall_telemetry.py`, `monitoring.py` deprecation, `profile.py` DB constraint rationale. Cross-ref tới model-api source rõ. |
| Architecture | 1/3 | **Duplicate schema** `FamilyProfileSnapshot` (HS-014) family.py vs relationship.py shape khác. `LinkedContactDetailResponse` cũng duplicate. Một số schema thiếu `extra="forbid"` (HS-015). Mix v1 `class Config:` vs v2 `model_config={...}` style. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Trừ điểm: password policy inconsistent (HS-016) register min=8 vs reset/change min=6. PHI exposure `LinkedContactMedicalInfoResponse` cần audit log mandate. |
| Performance | 3/3 | Schema validation O(N) per field count. SleepRecord 40+ field bulk validate 1 lần. Không blocking I/O. Không N+1. Regex compile inline mỗi instance — micro-perf gap, không bug. |
| **Total** | **11/15** | Band: **🟡 Healthy** — Architecture rớt mạnh do duplicate schema; không Security=0 override. |

## Findings

### Correctness

- `backend/app/schemas/device.py:84-101` — `DeviceSettingsRequest` vẫn expose 3 field `heart_rate_offset`, `spo2_calibration`, `temperature_offset` với constraint range. Đây là dead field per HS-003 (governed ADR-012). Khi Phase 4 fix HS-003 sub-task 1 "drop 3 offset field", schema này phải remove field. Reference only, không re-flag.
- `backend/app/schemas/emergency.py:35-42` — `PatientInfo.date_of_birth: Optional[str] = None`. Type là `str` không phải `date` → validator không coerce ISO format, không reject "2026-13-45". Inconsistent với `RegisterRequest.date_of_birth: Optional[date]` (auth.py) + `ProfileResponse.date_of_birth: date | None` (profile.py). Hiện chỉ dùng response model, nhưng nếu future endpoint nhận làm input, accept invalid date. Allocate **HS-017** (Low).
- `backend/app/schemas/auth.py:24-31` — `RegisterRequest.email` validator dùng simple regex `r"^[^@]+@[^@]+\.[^@]+$"`. Pass valid email cơ bản. Inconsistent với `relationship.RelationshipRequestCreate.email: Optional[EmailStr]` Pydantic-native. Nên align lên `EmailStr`. P2.
- `backend/app/schemas/profile.py:65-80` — `ProfileUpdateRequest.height_cm: int | None = Field(default=None, ge=50, le=250)`. ORM model BE-M04 không có CHECK ở height_cm → schema là sole defense. Confirm: schema bypass (raw SQL) nguy hiểm. Pattern lặp 5 lần trong `User` profile (gộp HS-010 batch BE-M04 fix CHECK).
- `backend/app/schemas/profile.py:83` — `weight_kg: float | None = Field(default=None, ge=2, lt=500)`. Match canonical CHECK. `ge=2` strict hơn canonical `> 0` cho sanity check.
- `backend/app/schemas/family.py:24-25` — `health_score_7_days: Optional[int] = None` + `health_score_level: str = "Trung bình"`. Comment giải thích semantics: "None = no health report data; int (incl. 0) = real score". Nullable handling explicit.
- `backend/app/schemas/relationship.py:114-118` — `health_score_level: str = "Tốt"` (default Vietnamese label). Inconsistent với `family.py` `default="Trung bình"`. 2 schema cùng entity nhưng default khác (gộp HS-014).
- `backend/app/schemas/sleep_telemetry.py:14-58` — `SleepRecord` mirror model-api verbatim (40+ field). Comment: "Most have no safe default; silently filling 0.0 would bias the model toward perfect sleep". Defensive design — caller phải populate. Pydantic raise validation error nếu missing.
- `backend/app/schemas/fall_telemetry.py:62-75` — `ImuWindowRequest.data: list[SensorSample] = Field(..., min_length=20)`. Comment giải thích: backend min loose 20 vs model-api min strict 50 → low-power mobile vẫn reach upstream, để upstream reject với 4xx. Defensive design rõ trade-off.
- `backend/app/schemas/auth.py:90-95` — `VerifyEmailRequest.code: str = Field(min_length=6, max_length=6)` + `field_validator` check `isdigit()`. Cùng pattern `ResetPasswordRequest.code` + `VerifyResetOtpRequest.code`. Consistent.
- `backend/app/schemas/auth.py:120-138` — `ResetPasswordRequest.new_password: str = Field(min_length=6, max_length=64)`. **Min 6 ký tự cho RESET PASSWORD nhưng REGISTER min 8** (line 8). Inconsistent password policy. Cộng `validate_password_strength` ở `utils/password.py` (BE-M09) check length ≥ 8 + complexity → register rule + util rule mismatch reset/change schema rule. Allocate **HS-016** (Low).
- `backend/app/schemas/auth.py:5` — `re` import + 4 validator dùng inline `re.compile(...)` mỗi class instantiation. Micro-perf gap. Module-level cache pattern khuyến nghị. P2.

### Readability

- `backend/app/schemas/fall_telemetry.py:1-12` — module docstring giải thích relationship với upstream `healthguard-model-api/app/schemas/fall.py` + WHY mirror verbatim ("no per-field translation in either direction"). Reader hiểu cross-repo contract trong 30 giây.
- `backend/app/schemas/fall_telemetry.py:80-105` — `FallEventResponse` field comment block rõ trust boundary ("location_accuracy is internal — the address string is enough for the user") + lifecycle ("Phase 4B-full slice 2c"). Best-in-class.
- `backend/app/schemas/fall_telemetry.py:125-136` — `status: str` derived field comment giải thích state machine logic: "detected/dismissed/confirmed/escalated derived from workflow timestamps". Reader không cần trace BE-M03 service code.
- `backend/app/schemas/fall_telemetry.py:158-167` — `model_config = {"protected_namespaces": ()}` comment giải thích lý do (`model_version` field name conflict). Captures past gotcha.
- `backend/app/schemas/monitoring.py:104-127` — `RiskReportResponse` deprecation block rõ ràng: "Phase 1 canonicalisation + score is canonical; risk_score is deprecated alias. Removal scheduled for Phase 6." `Field(deprecated="...")` machine-readable.
- `backend/app/schemas/monitoring.py:163-171` — `RiskReportClinicianResponse` extends `RiskReportDetailResponse` với 2 field clinician-only. Module docstring: "Phase 5 leaves the patient ``RiskReportDetailResponse`` shape unchanged". Codegen-safe extension pattern.
- `backend/app/schemas/profile.py:9-17` — block comment `GENDER_VI_TO_EN`: "DB CHECK constraint only accepts canonical English values. UI/API speaks Vietnamese; we map at the schema/service boundary." Schema-DB-UI translation layer documented.
- `backend/app/schemas/profile.py:62-66` — comment `height_cm: int | None`: "DB column is `smallint`; only whole-cm values are persistable. We accept ints (and silently reject floats with a helpful message) rather than rounding behind the user's back." Best-in-class regression-prevention.
- `backend/app/schemas/sleep_telemetry.py:12-18` — module docstring giải thích `db_device_id`/`db_user_id` rationale: "without trusting the unauthenticated string user_id that the model-api uses internally". Trust boundary captured.
- `backend/app/schemas/general_settings.py` — concise. 2 schema R/W ngắn. Pattern `theme = Field(pattern="^(light|dark|system)$")` reflexive validation.
- `backend/app/schemas/notification.py:36-42` — `PushTokenUpsertRequest.token: str = Field(min_length=20, max_length=1024)`. Min 20 chars defense FCM token format permissive.
- `backend/app/schemas/family.py` — schema duplicate với `relationship.py` (HS-014). Comment line 23 explain `health_score_7_days` semantics.
- `backend/app/schemas/relationship.py:1-3` — module docstring thiếu. Schema có 11 model + nested medical info → cần module docstring giới thiệu. Minor P2.

### Architecture

- **HS-014 — Duplicate schema `FamilyProfileSnapshot`**: định nghĩa 2 lần với field set khác:
  - `family.py:5-26` — 19 field.
  - `relationship.py:101-119` — 21 field (= family.py + `has_vitals_data: bool = True` + `vitals_data_message: Optional[str] = None`, default `sleep_quality="Tốt"` thay vì "Trung bình").
  
  Hệ quả:
  - Router import `from app.schemas.family import FamilyProfileSnapshot` vs `from app.schemas.relationship import FamilyProfileSnapshot` → 2 endpoint cùng response_model name, shape khác nhau → mobile client parser break tuỳ endpoint.
  - 1 source of truth bị vi phạm. Schema layer là "DTO contract" nên sole definition mandatory.
  
  Allocate **HS-014** (High).

- **HS-015 — Missing `extra="forbid"` policy**: Pydantic v2 default `extra="ignore"` → silently drop unknown field từ client. Nếu mobile gửi `{"email": "x@y.z", "passwoord": "secret"}` (typo "passwoord"), backend ignore + register fail vì missing `password` → reject với 422 cuối cùng nhưng không cho biết "passwoord" typo. Audit grep:
  - 0 file dùng `extra="forbid"`.
  - 12+ Request schema vulnerable to silent drop.
  
  UX dev experience kém + future-proof khi DTO contract change. Allocate **HS-015** (Low).

- **Pydantic v1/v2 mix**: 
  - `class Config: from_attributes = True` (v1 style): `emergency.py:23,38,68,82,99,108`, `family.py`, `notification.py:23,33`, `relationship.py:81-82`.
  - `model_config = {"from_attributes": True, ...}` (v2 style): `fall_telemetry.py:158-167`.
  - `model_config = ConfigDict(...)` (v2 explicit): không có file nào.
  
  Pydantic v2 recommend `model_config = ConfigDict(...)`. Mix style trong cùng codebase = inconsistent. P1 chuẩn hoá.

- **Schema vs ORM field divergence**:
  - `auth.RegisterRequest.role: str` (no enum) vs `User.role: String(20)` no CHECK → cả 2 layer không enforce. DB CHECK canonical reject `role NOT IN ('user', 'admin')` là defense cuối.
  - `device.DeviceCreateRequest.device_type` validator enum match canonical CHECK.
  - `profile.ProfileUpdateRequest.height_cm: int ge=50, le=250` strict hơn canonical CHECK 0-300.
  - `profile.ProfileUpdateRequest.medical_conditions` whitelist 5 key — defense lớp schema vì DB column `text[]` không CHECK enum.

- **`Literal[]` consistent dùng đúng cho enum-like**: `emergency.py:130-141` (TriggerSOSRequest.trigger_type Literal["auto", "manual"], action Literal[...], source Literal[...]). Pattern v2-native, type-safe, codegen-friendly.

- **Family vs Relationship coupling**: 2 schema file có overlap context. Recommend refactor:
  - `family.py` chỉ giữ family-specific schema.
  - `relationship.py` chỉ giữ relationship lifecycle.
  - Move `FamilyProfileSnapshot` (canonical version) sang `family.py`, drop khỏi `relationship.py`.

- **`monitoring.py` đa schema chained inheritance** (`RiskReportClinicianResponse(RiskReportDetailResponse)`): correct OOP DTO extension pattern. Codegen-friendly.

### Security

- **Anti-pattern auto-flag scan**: 0 hit. Không `eval/exec`, không SQL concat, không CORS, không SSL disable, không hardcoded secret, không token storage anti-pattern. **Security=0 override KHÔNG áp dụng.**

- **HS-016 — Password policy inconsistent**:
  - `RegisterRequest.password: min_length=8, max_length=64` (auth.py:8).
  - `ResetPasswordRequest.new_password: min_length=6, max_length=64` (auth.py:115).
  - `ChangePasswordRequest.new_password: min_length=6, max_length=64` (auth.py:155).
  - `LoginRequest.password: min_length=1, max_length=64` (auth.py:71).
  
  Login min=1 acceptable (legacy account). Reset/Change min=6 vs Register min=8 = **logic gap**: user register với password 8 chars, sau đó reset/change xuống 6 chars. Policy yếu hơn original.
  
  Service-side `validate_password_strength` ở `utils/password.py` (BE-M09) check length ≥ 8 → nếu service Phase 4 gọi cho reset/change thì runtime đúng policy bất chấp schema. Verify BE-M03. Allocate **HS-016** (Low).

- `backend/app/schemas/relationship.py:101-110` — `LinkedContactMedicalInfoResponse` expose `medications`, `allergies`, `medical_conditions` plaintext string list. Đúng spec UC P-4 caregiver xem medical info. NHƯNG schema không có comment cảnh báo PHI exposure → reader BE-M02 router code có thể vô tình expose endpoint không có audit log (steering `40-security-guardrails.md` mandate audit log cho PHI access). P1 add docstring cảnh báo + reference UC P-4.

- `backend/app/schemas/auth.py:110` — `verification_code: Optional[str]` trong `AuthResponse` — comment "Only returned in DEV for testing". Service Phase 4 cần verify `ENVIRONMENT == "production"` → nullify field. Hiện schema cho phép → service-layer trust. Service review BE-M03.

- `backend/app/schemas/sleep_telemetry.py:62-66` — `SleepRiskRequest.db_user_id: int`. Comment: "the unauthenticated string user_id that the model-api uses internally" → backend phải override `db_user_id` từ `current_user.id` bất kể client gửi gì. Verify BE-M02 routes (Task 6).

- `backend/app/schemas/fall_telemetry.py:62-66` — `ImuWindowRequest.db_device_id: int` tương tự. Backend phải verify ownership. Schema-side accept; router-side enforce.

- `backend/app/schemas/relationship.py:21-29` — `RelationshipRequestCreate` accept `email`, `phone`, `target_user_id` cùng lúc. Schema không enforce mutual exclusivity (`@model_validator` v2). Recommend P2: `model_validator(mode="after")` enforce exactly one identifier.

### Performance

- Schema validation O(N) per field count. Tổng 100+ schema, mỗi schema 2-40 field. Validation thực thi tại request boundary 1 lần per request. Không hot path scale lớn.
- `SleepRecord` 40+ field → validation cost ~200μs. Acceptable mobile request rate.
- Regex compile inline mỗi instantiation — micro-perf gap (auth.py 4 validator). Module-level cache pattern khuyến nghị nhưng ko bug. P2.
- `ProfileUpdateRequest.medical_conditions` validator: list comprehension O(N×M) với M=5. Acceptable.
- Không có blocking I/O trong validator (không DB query, không HTTP). Validator pure-function.
- `from_attributes = True` cho ORM-to-schema serialize: SQLAlchemy lazy load relationship có thể fire query khi schema access. Service-layer phải eager load trước khi pass tới `model_validate()`. BE-M03 + BE-M06 review.

## Positive findings

- `backend/app/schemas/fall_telemetry.py` — best-in-class module quality:
  - Module docstring + cross-reference upstream model-api source.
  - Field-level comment giải thích trust boundary (`db_device_id` rationale).
  - Defensive design `min_length=20` loose vs upstream strict 50 với comment trade-off.
  - `model_config = {"protected_namespaces": ()}` comment workaround `model_version` conflict.
  - `status` derived field comment state machine logic giúp client không recompute.
- `backend/app/schemas/monitoring.py` Phase 1 deprecation:
  - `Field(deprecated="...")` machine-readable (Pydantic v2 native).
  - Phase 6 removal scheduled trong comment.
  - Cross-reference `backend/docs/risk-contract-baseline.md`.
  - Snapshot test reference.
  - Codegen-safe migration path (dual-emit canonical + deprecated).
- `backend/app/schemas/profile.py`:
  - i18n gender mapping VI ↔ EN tại schema boundary.
  - `height_cm` int comment giải thích DB smallint constraint + WHY reject float thay vì silent round.
  - `medical_conditions` whitelist 5 key — defense schema-layer vì DB column `text[]` no CHECK.
  - `validate_age` shared helper từ `utils/age_validator.py` reuse → register + profile update consistent.
- `backend/app/schemas/sleep_telemetry.py`:
  - `SleepRecord` mirror verbatim model-api. Comment "no safe default; silently filling 0.0 would bias model toward perfect sleep".
- `backend/app/schemas/auth.py`:
  - VI diacritic regex `r"^[a-zA-ZÀ-ỿ\s]+$"` cho `full_name` validation.
  - `field_validator("phone")` strip space + dash, then digit-only check.
  - 6-digit PIN `code` validation với `isdigit()` check (3 schema verify/reset/forgot consistent).
- `backend/app/schemas/emergency.py`:
  - `Literal[]` cho enum-like field. Type-safe + codegen-friendly + Pydantic v2 native.
- `backend/app/schemas/general_settings.py`:
  - `pattern="^(light|dark|system)$"` cho theme — schema-layer enum substitute.
  - `session_timeout_minutes: ge=5, le=43200` reasonable bound.
- `backend/app/schemas/notification.py`:
  - `PushTokenUpsertRequest.token: min_length=20` defense FCM format.
- Pydantic v2 `field_validator` decorator usage consistent across files.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-014 | High | `FamilyProfileSnapshot` định nghĩa 2 lần với field set khác (family.py 19 field vs relationship.py 21 field + default `sleep_quality` khác); router import → 2 endpoint cùng response_model name shape khác nhau, mobile client parser break | `backend/app/schemas/family.py:5-26` + `relationship.py:101-119` | Architecture |
| HS-015 | Low | Missing `model_config = ConfigDict(extra="forbid")` cho 12+ Request schema → silent drop unknown field, UX dev experience kém khi typo field name | toàn bộ `schemas/*.py` Request classes | Architecture |
| HS-016 | Low | Password policy inconsistent: `RegisterRequest.password min_length=8` vs `ResetPasswordRequest.new_password min_length=6` vs `ChangePasswordRequest.new_password min_length=6`; reset/change cho phép password yếu hơn original register | `backend/app/schemas/auth.py:8,115,155` | Security |
| HS-017 | Low | `PatientInfo.date_of_birth: Optional[str]` thay vì `date` → no format coercion/validation, accept "2026-13-45" hay "abcdef"; inconsistent với `RegisterRequest.date_of_birth: Optional[date]` | `backend/app/schemas/emergency.py:39` | Correctness |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-014**: Resolve duplicate `FamilyProfileSnapshot` + `LinkedContactDetailResponse`. Flow:
  1. Identify canonical version. Recommend `relationship.py:101` version (21 field, có `has_vitals_data`+`vitals_data_message` cho UC P-3 fallback message).
  2. Drop `family.py:5-26` `FamilyProfileSnapshot`. Migrate import callers.
  3. Drop `family.py:28-30` `LinkedContactDetailResponse` (3-field summary). Migrate import sang `relationship.py` (11-field detailed).
  4. Default `sleep_quality`: pick "Trung bình" (neutral default).
  5. Regression test: snapshot ensure 2 endpoint emit cùng shape.
  6. Cross-check BE-M02 router (Task 6) imports.

### P1

- [ ] **HS-016**: Align password policy 3 endpoint `min_length=8` (match register). Verify `auth_service.py` consume `validate_password_strength` cho reset/change → nếu có, schema-layer là duplicate validation; nếu không, schema chỉ chỗ duy nhất → bug runtime.
- [ ] **Pydantic v1 → v2 config style migration**: chuẩn hoá `class Config: from_attributes = True` → `model_config = ConfigDict(from_attributes=True)` toàn bộ files.
- [ ] **HS-015**: Add `model_config = ConfigDict(extra="forbid")` cho mọi Request schema. Defense layer chống typo field name. Verify mobile codegen contract trước khi enable production.
- [ ] **`RelationshipRequestCreate` mutual exclusivity**: thêm `@model_validator(mode="after")` enforce exactly one of `(email, phone, target_user_id)`.
- [ ] **PHI exposure docstring**: `LinkedContactMedicalInfoResponse` thêm docstring cảnh báo PHI + reference UC P-4 + steering audit log requirement.
- [ ] **`HS-003` reference**: `DeviceSettingsRequest` drop 3 offset field khi Phase 4 fix HS-003 sub-task 1.

### P2

- [ ] **HS-017**: Fix `PatientInfo.date_of_birth: Optional[str]` → `Optional[date]`. Coerce ISO format Pydantic native.
- [ ] **Email validator consistency**: chuẩn hoá tất cả `email` field dùng `Pydantic.EmailStr` thay vì regex tay (`auth.py` 4 validator manual regex).
- [ ] **Module-level regex cache**: `auth.py` 4 validator compile `re.compile(...)` mỗi instance → cache module-level.
- [ ] **`relationship.py` module docstring**: thêm 1 paragraph giới thiệu 11 schema + nested medical info P-4 scope.
- [ ] **schema layer test snapshot**: tạo `tests/contract/test_schema_snapshot.py` snapshot tất cả Pydantic schema JSON Schema export → regression detect breaking change DTO contract trong CI.

## Out of scope

- Pydantic v1 → v2 codebase migration (assume v2 settled).
- Service-layer DTO conversion + ORM-to-schema serialize (BE-M03 services).
- Router consumer của schema (BE-M02 routes — Task 6).
- Model attribute mirror với schema (BE-M04 fix CHECK constraints — đã capture HS-010/HS-011).
- Mobile codegen contract verify (cross-repo, Flutter side scope).
- API contract baseline doc — referenced không re-audit.
- Defer Phase 3: per-screen widget validation rule (mobile-side), e2e test coverage cho schema validation flow.
- Schema vs canonical SQL gap detection tooling — gộp với BE-M04 P2 schema drift script.

## Cross-references

- BUGS INDEX (new):
  - HS-014 — Duplicate `FamilyProfileSnapshot` family.py vs relationship.py (High)
  - HS-015 — Missing `extra="forbid"` 12+ Request schema (Low)
  - HS-016 — Password policy inconsistent register/reset/change (Low)
  - HS-017 — `PatientInfo.date_of_birth` str thay vì date (Low)
- BUGS INDEX (reference, không re-flag):
  - [HS-003](../../../BUGS/HS-003-calibration-offsets-never-consumed.md) — `DeviceSettingsRequest` 3 offset field dead (governed ADR-012, sub-task 1 drop).
  - [HS-010](../../../BUGS/INDEX.md) — `Alert` ORM thiếu field; schema layer compensate (BE-M04 scope).
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md) — Internal service auth strategy. `db_device_id`/`db_user_id` field design rationale.
  - [ADR-009](../../../ADR/INDEX.md) — Avatar storage Supabase. `ProfileResponse.avatar_url` reference.
  - [ADR-012](../../../ADR/INDEX.md) — Drop calibration offsets. `DeviceSettingsRequest` 3 field.
- Intent drift (reference only):
  - Không khớp drift ID nào trong blacklist (D-012/D-019/D-021/D1/D3).
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — middleware order trước khi reach schema validation.
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md) — schema vs ORM field divergence.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — `core/audience.py` AudienceEnum used by `RiskReportClinicianResponse`.
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md) — `utils/age_validator.py` consumed by `ProfileUpdateRequest`; `utils/password.py:validate_password_strength` consumed by service.
  - `BE_M02_routes_audit.md` (Task 6 pending) — router consume schema as `response_model` + Body validation.
  - `BE_M03_services_audit.md` (Task 9 pending) — service convert ORM → schema via `model_validate`.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Risk contract baseline: `health_system/backend/docs/risk-contract-baseline.md`.
