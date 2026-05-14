# Bug Log Index — VSmartwatch HealthGuard

> GPS map của tất cả bug được track. Update mỗi khi tạo bug mới, đổi status, hoặc resolve.

> **Skill:** `bug-log` (chi tiết template + workflow). **Rule:** `60-context-continuity.md` (vì sao log này tồn tại).

## ID convention

Format: `<REPO-PREFIX>-<NUM>` (3-digit zero-padded).

| Prefix | Repo |
|---|---|
| HG | HealthGuard (admin web) |
| HS | health_system (mobile + backend) |
| IS | Iot_Simulator_clean |
| MA | healthguard-model-api |
| PM | PM_REVIEW (rare — docs bugs) |
| XR | Cross-repo (affects ≥ 2 repos) |

Ví dụ: `HG-001`, `HS-005`, `XR-002`.

## Status legend

- 🔴 **Open** — bug active, not yet investigated
- 🟡 **In progress** — investigating, có attempts ghi nhận
- 🔵 **Stuck** — 3+ attempts failed, cần `/stuck` workflow
- ✅ **Resolved** — đã fix, có regression test
- ⛔ **Won't fix** — không phải bug hoặc ngoài scope

## Severity legend

- **Critical** — Crash app / data loss / security breach / fall detection fail
- **High** — Core feature broken (auth, vitals submit, SOS)
- **Medium** — Annoying nhưng workaround tồn tại
- **Low** — Cosmetic / edge case

---

## Open bugs

| ID | Repo | Module | Title | Severity | Created | Last attempt | Status |
|---|---|---|---|---|---|---|---|
| [HG-001](./HG-001-admin-web-alerts-always-unread.md) | HealthGuard | health.service (admin) | Admin web hiển thị tất cả alerts là 'unread' do code wrong assumption | Medium | 2026-05-11 | _(deferred Phase 4)_ | 🔴 Open |
| [IS-001](./IS-001-sleep-ai-client-wrong-path.md) | Iot_Simulator_clean | simulator_core/sleep_ai_client | Sleep AI client POST tới /predict (404) thay vì /api/v1/sleep/predict | Critical | 2026-05-11 | _(deferred Phase 4)_ | 🔴 Open |
| [XR-001](./XR-001-topology-steering-endpoint-prefix-drift.md) | Cross-repo (5) | Steering / docs | Topology steering claim `/api/internal/*` cho IoT sim → BE sai so với code (reality `/mobile/*`) | Medium | 2026-05-13 | _(pending chore branch)_ | 🔴 Open |
| [HS-001](./HS-001-devices-schema-drift-canonical.md) | health_system (+ iot-sim) | device | Devices schema drift — user_id NOT NULL/CASCADE vs nullable/SET NULL | Critical | 2026-05-13 | _(Phase 4 scheduled per ADR-010)_ | 🔴 Open |
| [HS-002](./HS-002-device-unique-mac-cross-user-bypass.md) | health_system | device | Cross-user MAC duplicate bypass — BR-040-01 violation | High | 2026-05-13 | _(Phase 4 scheduled)_ | 🔴 Open |
| [HS-003](./HS-003-calibration-offsets-never-consumed.md) | health_system (+ iot-sim) | device | Device calibration offsets never consumed (dead write-only data) | Medium | 2026-05-13 | _(Phase 4 scheduled per ADR-012)_ | 🔴 Open |
| [HS-004](./HS-004-telemetry-sleep-endpoints-no-auth.md) | health_system (+ iot-sim) | telemetry | Mobile telemetry endpoints (/sleep, /sleep-risk, /imu-window) thiếu auth guard | Critical | 2026-05-13 | _(Phase 4 scheduled per ADR-005)_ | 🔴 Open |
| [HS-005](../AUDIT_2026/tier2/health_system/BE_M01_main_bootstrap_audit.md) | health_system | main_bootstrap | CORS wildcard origins cộng allow_credentials True trong main.py — anti-pattern Security=0 force Critical | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M01 audit Phase 1)_ | 🔴 Open |
| [HS-006](../AUDIT_2026/tier2/health_system/BE_M08_core_audit.md) | health_system | core/dependencies | `require_internal_service` fail-OPEN khi internal service secret env var unset — chỉ còn header match trivially spoofable; không align ADR-005 mandate | High | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M08 audit Phase 1)_ | 🔴 Open |
| [HS-007](../AUDIT_2026/tier2/health_system/BE_M09_utils_audit.md) | health_system | utils/jwt | JWT access TTL hardcoded 30 days, `settings.ACCESS_TOKEN_EXPIRE_DAYS` never consumed — config là dead value, ops không thể rotate TTL qua env | High | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M09 audit Phase 1)_ | 🔴 Open |
| [HS-008](../AUDIT_2026/tier2/health_system/BE_M09_utils_audit.md) | health_system | utils/rate_limiter | In-memory `defaultdict` rate limiter — multi-worker bypass + restart reset counter + check-then-act TOCTOU race | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M09 audit Phase 1)_ | 🔴 Open |
| [HS-009](../AUDIT_2026/tier2/health_system/BE_M04_models_audit.md) | health_system | models/push_token | `UserPushToken` ORM `__tablename__="user_push_tokens"` không match canonical `user_fcm_tokens` — deploy qua canonical SQL → ORM bind tới relation không tồn tại, FCM register/dispatch raise ProgrammingError | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M04 audit Phase 1)_ | 🔴 Open |
| [HS-010](../AUDIT_2026/tier2/health_system/BE_M04_models_audit.md) | health_system | models/alert | `Alert` ORM thiếu 7 field canonical (sos_event_id, sent_at, delivered_at, read_at, acknowledged_at, sent_via, expires_at) + thiếu CHECK alert_type 12 values | High | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M04 audit Phase 1)_ | 🔴 Open |
| [HS-011](../AUDIT_2026/tier2/health_system/BE_M04_models_audit.md) | health_system | models/audit_log | `AuditLog` ORM drift canonical: missing FK user_id+device_id, missing field device_id+error_message, type drift ip_address String(50) vs INET, missing CHECK status | High | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M04 audit Phase 1)_ | 🔴 Open |
| [HS-012](../AUDIT_2026/tier2/health_system/BE_M04_models_audit.md) | health_system | models/relationship | `UserRelationship` default permission flip canonical `true` → ORM `False` cho can_view_vitals+can_receive_alerts; caregiver mới link KHÔNG nhận alert mặc định, mâu thuẫn UC040 | Medium | 2026-05-13 | _(Phase 4 scheduled — ADR-016 proposed)_ | 🔴 Open |
| [HS-013](../AUDIT_2026/tier2/health_system/BE_M04_models_audit.md) | health_system | models/risk_alert_response | `RiskAlertResponse` type drift: risk_score_id+device_id Integer vs BIGINT, latitude+longitude Float (REAL 4-byte) vs DOUBLE PRECISION; precision drift inconsistent với FallEvent.latitude Numeric(10,8) | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M04 audit Phase 1)_ | 🔴 Open |
| [HS-014](../AUDIT_2026/tier2/health_system/BE_M05_schemas_audit.md) | health_system | schemas/family+relationship | Duplicate `FamilyProfileSnapshot` định nghĩa 2 lần với field set khác (family.py 19 field vs relationship.py 21 field + default sleep_quality khác); 2 endpoint cùng response_model name shape khác nhau | High | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M05 audit Phase 1)_ | 🔴 Open |
| [HS-015](../AUDIT_2026/tier2/health_system/BE_M05_schemas_audit.md) | health_system | schemas (all Request) | Missing `model_config = ConfigDict(extra="forbid")` cho 12+ Request schema → silent drop unknown field, UX dev experience kém khi typo field name | Low | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M05 audit Phase 1)_ | 🔴 Open |
| [HS-016](../AUDIT_2026/tier2/health_system/BE_M05_schemas_audit.md) | health_system | schemas/auth | Password policy inconsistent: RegisterRequest min_length=8 vs ResetPasswordRequest+ChangePasswordRequest min_length=6; reset/change cho phép password yếu hơn original register | Low | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M05 audit Phase 1)_ | 🔴 Open |
| [HS-017](../AUDIT_2026/tier2/health_system/BE_M05_schemas_audit.md) | health_system | schemas/emergency | `PatientInfo.date_of_birth: Optional[str]` thay vì `date` → no format coercion/validation, accept "2026-13-45" hay "abcdef"; inconsistent với RegisterRequest.date_of_birth: Optional[date] | Low | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M05 audit Phase 1)_ | 🔴 Open |
| [HS-018](../AUDIT_2026/tier2/health_system/BE_M02_routes_audit.md) | health_system | routes/auth/deep-link-redirect | XSS reflected qua HTML f-string interpolation user query param trong deep_link_redirect; attacker craft email link execute JS trên BE domain → cookie/JWT exfiltration | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M02 audit Phase 1)_ | 🔴 Open |
| [HS-019](../AUDIT_2026/tier2/health_system/BE_M02_routes_audit.md) | health_system | routes/risk | Router risk.py execute SQL text() trực tiếp 5 endpoint helper — vi phạm layer separation steering 22-fastapi.md (business logic phải ở service, không ở router) | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M02 audit Phase 1)_ | 🔴 Open |
| [HS-020](../AUDIT_2026/tier2/health_system/BE_M06_repositories_db_audit.md) | health_system | db/memory_db | Plaintext admin credential committed git (admin email + weak password literal); no `# DEV ONLY` annotation + unclear consumer; auto-flag anti-pattern hardcoded credential committed git | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M06 audit Phase 1)_ | 🔴 Open |
| [HS-021](../AUDIT_2026/tier2/health_system/BE_M03_services_audit.md) | health_system | services/model_api_client | model_api_client outbound httpx.Client chỉ set X-Internal-Service header — KHÔNG set X-Internal-Secret mandate per ADR-005; production deploy với model-api enforce → 401/403 silent fall back; với fail-open → cross-service auth bypass | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M03 audit Phase 1)_ | 🔴 Open |
| [HS-022](../AUDIT_2026/tier2/health_system/BE_M03_services_audit.md) | health_system | services/relationship_service | 4 instance except Exception default empty/None KHÔNG logger.exception line 480 547 575; caregiver dashboard render incomplete data without warning, vi phạm steering 22-fastapi.md anti-pattern | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M03 audit Phase 1)_ | 🔴 Open |
| [HS-023](../AUDIT_2026/tier2/health_system/BE_M11_scripts_audit.md) | health_system | app/scripts + backend/scripts | 4 instance hardcoded plaintext credential literal trong seed/test scripts committed git (create_caregiver_user + seed_home_dashboard_e2e 3 accounts); auto-flag anti-pattern; compound với HS-020 | Critical | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M11 audit Phase 1)_ | 🔴 Open |
| [HS-024](./HS-024-risk-inference-silent-default-fill.md) | health_system | services/risk_alert_service + adapters/model_api_health_adapter | Risk inference fill default silently khi vitals/profile NULL → score giả; 2 layer adapter fill độc lập + drift HRV value (40 vs 50); _fetch_latest_vitals chỉ reject khi cả HR+SpO2 NULL | High | 2026-05-14 | _(Phase 4 — flagged Phase 3 deep-dive BE-M03/M07)_ | 🔴 Open |
| [XR-003](./XR-003-model-api-input-validation-contract.md) | Cross-repo (HS+MA) | Cross-service contract | Contract chưa định nghĩa cách handle missing vitals giữa mobile BE và model API; thiếu flag `is_synthetic_default` + structured error code; consumer không phân biệt record real vs default-fill | Medium | 2026-05-14 | _(blocked by HS-024 + cần ADR mới — flagged Phase 3 deep-dive)_ | 🔴 Open |
| [IS-002](./IS-002-sleep-service-missing-internal-auth-headers.md) | Iot_Simulator_clean | api_server/services/sleep_service | SleepService _push_sleep_to_backend thiếu X-Internal-Service + X-Internal-Secret headers | Critical | 2026-05-13 | _(Phase 4 — batch with HS-004)_ | 🔴 Open |
| [IS-003](./IS-003-sleep-session-exists-silent-db-failure.md) | Iot_Simulator_clean | api_server/services/sleep_service | _sleep_session_exists swallow DB error → potential double-write sleep_sessions row | Medium | 2026-05-13 | _(Phase 4)_ | 🔴 Open |
| [IS-004](./IS-004-sleep-service-module-level-scenario-globals.md) | Iot_Simulator_clean | api_server/services/sleep_service | SLEEP_SCENARIO_PHASES/PROFILES là module-level globals, state leak across instances | Low | 2026-05-13 | _(Phase 4/5 defer)_ | 🔴 Open |
| [IS-005](./IS-005-m07-cleanup-cluster.md) | Iot_Simulator_clean | pre_model_trigger (M07) | Cleanup cluster — dead code (orchestrator `_extract_vitals_snapshot`), dead config (rules_config pending_baseline_drift), dup severity rank consts | Low | 2026-05-13 | _(Phase 4 cleanup)_ | 🔴 Open |
| [IS-008](./IS-008-list-active-devices-n-plus-one.md) | Iot_Simulator_clean | api_server/sim_admin_service | `list_active_devices` N+1 query pattern (1 + N roundtrips per admin list poll) | Medium | 2026-05-13 | _(Phase 4)_ | 🔴 Open |
| [IS-009](./IS-009-activate-device-missing-rollback.md) | Iot_Simulator_clean | api_server/sim_admin_service | `activate_device` raises ValueError without prior `db.rollback()` — session dirty risk | Low | 2026-05-13 | _(Phase 4/5 defer)_ | 🔴 Open |
| [IS-010](./IS-010-http-publisher-no-auto-internal-secret.md) | Iot_Simulator_clean | transport/http_publisher | HttpPublisher không tự inject X-Internal-Service header (caller-owned, drift với M07 pattern) | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |
| [IS-011](./IS-011-http-publisher-no-retry-logic.md) | Iot_Simulator_clean | transport/http_publisher | HttpPublisher single-attempt, không retry khi transient fail (drift AlertService pattern) | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |
| [IS-012](./IS-012-etl-silent-skip-masks-data-loss.md) | Iot_Simulator_clean | etl_pipeline/normalize | ETL silent skip mask data loss — pipeline exits success với 0 rows nếu tất cả subject fail | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |
| [IS-013](./IS-013-etl-uses-vitaldb-private-method.md) | Iot_Simulator_clean | etl_pipeline/normalize + dataset_adapters/vitaldb | ETL truy cập `vitaldb._resolve_track` private method — encapsulation violation | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |

## In progress

| ID | Repo | Module | Title | Severity | Created | Attempts | Last update |
|---|---|---|---|---|---|---|---|
| _(none)_ | | | | | | | |

## Stuck (3+ failed attempts)

| ID | Repo | Module | Title | Attempts | Last update | Action |
|---|---|---|---|---|---|---|
| _(none)_ | | | | | | |

## Resolved

| ID | Repo | Module | Title | Resolved | Fix commit |
|---|---|---|---|---|---|
| _(none yet)_ | | | | | |

## Won't fix

| ID | Repo | Title | Reason | Decided |
|---|---|---|---|---|
| _(none)_ | | | | |

---

## Cross-repo bugs (XR-NNN)

Bugs affecting ≥ 2 repos require special handling. Track repo-impact matrix:

| ID | Title | Affected repos | Status | ADR? |
|---|---|---|---|---|
| [XR-001](./XR-001-topology-steering-endpoint-prefix-drift.md) | Topology steering endpoint prefix drift | All 5 (HealthGuard, health_system, Iot_Simulator_clean, healthguard-model-api, PM_REVIEW) | 🔴 Open | References ADR-004, ADR-013 |
| [XR-002](./XR-002-be-sqlalchemy-severity-checkconstraint-drift.md) | BE SQLAlchemy severity CheckConstraint drift | health_system + HealthGuard (Prisma canonical) | 🔴 Open | References ADR-015 |
| [XR-003](./XR-003-model-api-input-validation-contract.md) | Model API input validation contract gap (missing vitals signaling) | health_system (backend) + healthguard-model-api | 🔴 Open | Cần ADR-018 (proposed) |

---

## Quick stats

- Total open: 24 (HG-001, IS-001, IS-002, IS-003, IS-004, IS-005, IS-008, IS-009, IS-010, IS-011, IS-012, IS-013, XR-001, XR-002, XR-003, HS-001, HS-002, HS-003, HS-004, HS-005, HS-006, HS-007, HS-008, HS-024) — Phase 0.5 + Phase 1 + Phase 3 deep-dive complete
- Total in progress: 1 (PM-001)
- Total resolved: 0
- Avg attempts to resolve: N/A
- Most-affected module: sleep_service (3 bug IS-002/003/004), sim_admin_service (2 bug IS-008/009), http_publisher (2 bug IS-010/011), etl_pipeline (2 bug IS-012/013), device (3 bug), telemetry (1 bug HS-004 Critical), main_bootstrap (1 bug HS-005 Critical), core/dependencies (1 bug HS-006 High), utils (2 bug HS-007 High + HS-008 Medium), pre_model_trigger (1 cluster IS-005)

> Update stats sau mỗi sprint hoặc theo demand.

## How to use

### Tạo bug mới

```pwsh
$bugDir = 'd:\DoAn2\VSmartwatch\PM_REVIEW\BUGS'
$prefix = 'HG'   # hoặc HS, IS, MA, PM, XR
$existing = Get-ChildItem "$bugDir\$prefix-*.md" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
$nextNum = if ($existing) { [int]($existing.BaseName -replace "^$prefix-",'') + 1 } else { 1 }
$newId = "$prefix-$('{0:D3}' -f $nextNum)"
Copy-Item "$bugDir\_TEMPLATE.md" "$bugDir\$newId.md"
Write-Host "Created: $bugDir\$newId.md"
```

Sau đó: edit file + add row vào INDEX.md > Open section.

### Tìm bug bằng symptom keyword

```pwsh
Get-ChildItem 'd:\DoAn2\VSmartwatch\PM_REVIEW\BUGS' -Filter '*.md' -Exclude 'INDEX.md','_TEMPLATE.md' | 
  Select-String -Pattern '<keyword>' -List
```

### Resolve bug

1. Update bug file: status = ✅ Resolved, fill `Fix commit` + `Verification`.
2. Move row trong INDEX.md từ section cũ → Resolved.
3. Add to "Quick stats".
