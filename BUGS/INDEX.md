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
| [XR-001](./XR-001-topology-steering-endpoint-prefix-drift.md) | Cross-repo (5) | Steering / docs | Topology steering claim `/api/internal/*` cho IoT sim → BE sai so với code (reality `/mobile/*`) | Medium | 2026-05-13 | _(pending chore branch)_ | 🔴 Open |
| [HS-008](../AUDIT_2026/tier2/health_system/BE_M09_utils_audit.md) | health_system | utils/rate_limiter | In-memory `defaultdict` rate limiter — multi-worker bypass + restart reset counter + check-then-act TOCTOU race | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M09 audit Phase 1)_ | 🔴 Open |
| [HS-019](../AUDIT_2026/tier2/health_system/BE_M02_routes_audit.md) | health_system | routes/risk | Router risk.py execute SQL text() trực tiếp 5 endpoint helper — vi phạm layer separation steering 22-fastapi.md (business logic phải ở service, không ở router) | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M02 audit Phase 1)_ | 🔴 Open |
| [HS-022](../AUDIT_2026/tier2/health_system/BE_M03_services_audit.md) | health_system | services/relationship_service | 4 instance except Exception default empty/None KHÔNG logger.exception line 480 547 575; caregiver dashboard render incomplete data without warning, vi phạm steering 22-fastapi.md anti-pattern | Medium | 2026-05-13 | _(Phase 4 scheduled — flagged BE-M03 audit Phase 1)_ | 🔴 Open |
| [HS-024](./HS-024-risk-inference-silent-default-fill.md) | health_system | services/risk_alert_service + adapters/model_api_health_adapter | Risk inference fill default silently khi vitals/profile NULL → score giả; 2 layer adapter fill độc lập + drift HRV value (40 vs 50); _fetch_latest_vitals chỉ reject khi cả HR+SpO2 NULL | High | 2026-05-14 | _(Phase 4 — flagged Phase 3 deep-dive BE-M03/M07)_ | 🔴 Open |
| [XR-003](./XR-003-model-api-input-validation-contract.md) | Cross-repo (HS+MA) | Cross-service contract | Contract chưa định nghĩa cách handle missing vitals giữa mobile BE và model API; thiếu flag `is_synthetic_default` + structured error code; consumer không phân biệt record real vs default-fill | Medium | 2026-05-14 | _(blocked by HS-024 + cần ADR mới — flagged Phase 3 deep-dive)_ | 🔴 Open |
| [IS-005](./IS-005-m07-cleanup-cluster.md) | Iot_Simulator_clean | pre_model_trigger (M07) | Cleanup cluster — dead code (orchestrator `_extract_vitals_snapshot`), dead config (rules_config pending_baseline_drift), dup severity rank consts | Low | 2026-05-13 | _(Phase 4 cleanup)_ | 🔴 Open |
| [IS-008](./IS-008-list-active-devices-n-plus-one.md) | Iot_Simulator_clean | api_server/sim_admin_service | `list_active_devices` N+1 query pattern (1 + N roundtrips per admin list poll) | Medium | 2026-05-13 | _(Phase 4)_ | 🔴 Open |
| [IS-009](./IS-009-activate-device-missing-rollback.md) | Iot_Simulator_clean | api_server/sim_admin_service | `activate_device` raises ValueError without prior `db.rollback()` — session dirty risk | Low | 2026-05-13 | _(Phase 4/5 defer)_ | 🔴 Open |
| [IS-012](./IS-012-etl-silent-skip-masks-data-loss.md) | Iot_Simulator_clean | etl_pipeline/normalize | ETL silent skip mask data loss — pipeline exits success với 0 rows nếu tất cả subject fail | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |
| [IS-013](./IS-013-etl-uses-vitaldb-private-method.md) | Iot_Simulator_clean | etl_pipeline/normalize + dataset_adapters/vitaldb | ETL truy cập `vitaldb._resolve_track` private method — encapsulation violation | Low | 2026-05-13 | _(Phase 5 hygiene)_ | 🔴 Open |
| [HS-025](./HS-025-test-fixture-mock-drift.md) | health_system | backend/tests (multi-file) | 21 tests fail mock chain/fixture drift voi service impl - pre-existing test debt | Low | 2026-05-14 | _(defer Phase 5+ test cleanup)_ | 🔴 Open |
| [HS-026](./HS-026-telemetry-tests-missing-internal-header.md) | health_system | backend/tests telemetry | 14 telemetry tests fail thieu X-Internal-Service header sau Phase 4 BLOCK 3 | Medium | 2026-05-14 | _(must fix truoc Phase 5)_ | 🔴 Open |
| [HS-027](./HS-027-device-settings-schema-still-exposes-calibration.md) | health_system | schemas/device | DeviceSettingsRequest van expose 3 calibration field sau HS-003 partial fix | Medium | 2026-05-14 | _(must fix cung HS-026 batch)_ | 🔴 Open |

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
| [HS-001](./HS-001-devices-schema-drift-canonical.md) | health_system | device | Devices schema drift — user_id NOT NULL/CASCADE vs nullable/SET NULL | 2026-05-14 | `6ce10f1` (PM_REVIEW) + `0a0b0c1` (HS BE) |
| [HS-002](./HS-002-device-unique-mac-cross-user-bypass.md) | health_system | device | Cross-user MAC duplicate bypass — BR-040-01 violation | 2026-05-14 | `6ce10f1` + `0a0b0c1` |
| [HS-003](./HS-003-calibration-offsets-never-consumed.md) | health_system | device | Device calibration offsets never consumed | 2026-05-14 | `6ce10f1` + `0a0b0c1` (mobile FE consumer deferred Phase 5+) |
| HS-004 | health_system | telemetry | Telemetry endpoints /sleep, /sleep-risk, /imu-window thiếu auth guard | 2026-05-14 | PR #46 (Session A BLOCK 3) |
| HS-005 | health_system | main_bootstrap | CORS wildcard + allow_credentials | 2026-05-14 | PR #47 (Session A BLOCK 2) |
| HS-006 | health_system | core/dependencies | require_internal_service fail-open | 2026-05-14 | PR #47 (Session A BLOCK 2) |
| HS-007 | health_system | utils/jwt | JWT TTL hardcoded 30 days | 2026-05-14 | PR #47 (Session A BLOCK 2) |
| HS-009 | health_system | models/push_token | `UserPushToken` table name canonical drift (fcm_tokens → push_tokens) | 2026-05-14 | `6ce10f1` (canonical rename + ADR-016) |
| HS-010 | health_system | models/alert | Alert ORM 7 missing canonical fields + alert_type CHECK | 2026-05-14 | `782ac61` (BLOCK 3) |
| HS-011 | health_system | models/audit_log | AuditLog FK + INET + CHECK status canonical | 2026-05-14 | `782ac61` |
| HS-012 | health_system | models/relationship | UserRelationship default permission False vs canonical True | 2026-05-14 | `782ac61` + ADR-017 + migration `20260514_relationship_default_permission.sql` |
| HS-013 | health_system | models/risk_alert_response | RiskAlertResponse Integer/Float vs canonical BigInteger/Numeric precision | 2026-05-14 | `782ac61` |
| HS-014 | health_system | schemas/family+relationship | Duplicate FamilyProfileSnapshot 19 vs 21 field | 2026-05-14 | `0d832a4` (BLOCK 4 - mobile FE consumer task deferred) |
| HS-015 | health_system | schemas (Request) | Missing extra=forbid on Request schemas | 2026-05-14 | `0d832a4` |
| HS-016 | health_system | schemas/auth | Password min_length inconsistency 6 vs 8 | 2026-05-14 | `0d832a4` |
| HS-017 | health_system | schemas/emergency | PatientInfo.date_of_birth Optional[str] vs Optional[date] | 2026-05-14 | `0d832a4` |
| HS-018 | health_system | routes/auth | XSS deep_link_redirect HTML f-string interpolation | 2026-05-14 | PR #45 (Session A BLOCK 1) |
| HS-020 | health_system | db/memory_db | Plaintext admin credential orphan file | 2026-05-14 | PR #45 (Session A BLOCK 1) |
| HS-021 | health_system | services/model_api_client | model_api_client missing X-Internal-Secret outbound | 2026-05-14 | PR #47 (Session A BLOCK 2) — grace removal deferred |
| HS-023 | health_system | scripts | 4 hardcoded plaintext credential in seed scripts | 2026-05-14 | PR #45 (Session A BLOCK 1) |
| XR-002 | Cross-repo | models/sos_event_model | SQLAlchemy severity CheckConstraint drift vs canonical | 2026-05-14 | PR #46 (Session A BLOCK 3) |
| IS-001 | Iot_Simulator_clean | sleep_ai_client | Sleep AI client wrong path + probe + headers + schema | 2026-05-14 | PR #11 (Session A BLOCK 5) |
| IS-002 | Iot_Simulator_clean | sleep_service | SleepService missing internal auth headers | 2026-05-14 | PR #11 (Session A BLOCK 5) |
| IS-003 | Iot_Simulator_clean | sleep_service | _sleep_session_exists swallow DB error | 2026-05-14 | PR #11 (Session A BLOCK 5) |
| IS-004 | Iot_Simulator_clean | sleep_service | Module-level scenario globals state leak | 2026-05-14 | PR #11 (Session A BLOCK 5) |
| IS-010 | Iot_Simulator_clean | http_publisher | HttpPublisher no auto internal secret | 2026-05-14 | PR #12 (Session A BLOCK 6) |
| IS-011 | Iot_Simulator_clean | http_publisher | HttpPublisher no retry logic | 2026-05-14 | PR #12 (Session A BLOCK 6) |
| D-013 | healthguard-model-api | predict endpoints | Missing verify_internal_secret | 2026-05-14 | PR #7 (Session A BLOCK 4) |
| D-014 | healthguard-model-api | system | /health collide with /api/v1/health/* | 2026-05-14 | PR #7 (Session A BLOCK 4) |
| D-015 | Iot_Simulator_clean | routers | 9 admin routers missing require_admin_key | 2026-05-14 | PR #12 (Session A BLOCK 6) |
| D-020 | Iot_Simulator_clean | fall_ai_client | Fall AI client missing internal headers | 2026-05-14 | PR #11 (Session A BLOCK 5) |

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
| [XR-002](./XR-002-be-sqlalchemy-severity-checkconstraint-drift.md) | BE SQLAlchemy severity CheckConstraint drift | health_system + HealthGuard (Prisma canonical) | ✅ Resolved | References ADR-015 |
| [XR-003](./XR-003-model-api-input-validation-contract.md) | Model API input validation contract gap (missing vitals signaling) | health_system (backend) + healthguard-model-api | 🔴 Open | Cần ADR-018 (proposed) |

---

## Quick stats

- Total open: 15 (HG-001, XR-001, XR-003, HS-008, HS-019, HS-022, HS-024, HS-025, HS-026, HS-027, IS-005, IS-008, IS-009, IS-012, IS-013)
- Total in progress: 0
- Total resolved: 30 (Session B: 12 + Session A: 18)
- Avg attempts to resolve: 1
- Phase 4 reverify 2026-05-14 surface 3 follow-up bugs (HS-025, HS-026, HS-027) - chi tiet xem section Open

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
