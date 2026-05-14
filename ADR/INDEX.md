# ADR Index — VSmartwatch HealthGuard

> Architectural Decision Records (ADR-lite). Mỗi ADR ghi nhận 1 decision với context + options + consequences. Update khi tạo mới, supersede, hoặc reverse decision.

> **Skill:** `decision-log` (chi tiết template + workflow). **Rule:** `60-context-continuity.md` (vì sao log này tồn tại).

## ID convention

Format: `<NNN>-<short-kebab-title>.md` — sequential, system-wide (NOT per repo).

Ví dụ: `001-workspace-tooling-host.md`.

## Status legend

- 🟢 **Accepted** — quyết định active, áp dụng.
- 🟡 **Proposed** — đang chờ user/team approve.
- 🔵 **Superseded by NNN** — bị thay thế bởi ADR khác.
- 🔴 **Deprecated** — không còn áp dụng nhưng giữ lịch sử.

---

## Chronological

| # | Title | Status | Date | Tags |
|---|---|---|---|---|
| 001 | Workspace tooling host | 🟢 Accepted | 2026-05-11 | workspace, tooling |
| 002 | Bug log + ADR centralized in PM_REVIEW | 🟢 Accepted | 2026-05-11 | workspace, anti-loop |
| 003 | HealthGuard trunk = develop (deploy user-owned) | 🟢 Accepted | 2026-05-11 | git, branching, healthguard, workflow |
| 004 | Standardize API prefix `/api/v1/{domain}/*` cho all backend services | 🟢 Accepted | 2026-05-11 | api, cross-repo, backend, refactor, workflow |
| 005 | Internal service-to-service authentication strategy | 🟢 Accepted | 2026-05-12 | security, cross-repo, backend, healthguard, health_system, model-api, iot-sim |
| 006 | MLOps workflow — mock implementation, defer real integration | 🟢 Accepted | 2026-05-12 | scope, mlops, healthguard, ai-models, graduation-project |
| 007 | AI model artifact storage decouples from serving — defer R2-to-runtime integration | 🟢 Accepted | 2026-05-12 | architecture, ai-models, healthguard, model-api, cross-repo, scope |
| 008 | Mobile BE không host system settings write — admin BE là single source of truth | 🟢 Accepted | 2026-05-12 | architecture, mobile-backend, health_system, healthguard, cross-repo, simplification, scope, dead-code |
| 009 | Avatar storage = Supabase (mobile) — intentional cross-repo split với R2 (admin AI) | 🟢 Accepted | 2026-05-12 | architecture, mobile-frontend, health_system, healthguard, cross-repo, storage, scope |
| 010 | Devices schema canonical = PM_REVIEW (user_id nullable, ON DELETE SET NULL) | 🟢 Accepted | 2026-05-13 | database, schema, cross-repo, health_system, iot-sim, canonical |
| 011 | UC040 Connect Device = pair-create only (drop pair-claim flow) | 🟢 Accepted | 2026-05-13 | scope, uc, health_system, mobile, graduation-project |
| 012 | Drop calibration offset fields (heart_rate_offset, spo2_calibration, temperature_offset) | 🟢 Accepted | 2026-05-13 | scope, schema, health_system, mobile, dead-code, graduation-project |
| 013 | IoT Simulator direct-DB write cho vitals tick (bypass BE) | 🟢 Accepted | 2026-05-13 | architecture, iot-sim, health_system, cross-repo, performance, scope |
| 014 | IoT Simulator profile taxonomy - unified HealthProfile | 🟢 Accepted | 2026-05-13 | architecture, iot-sim, persona, scope, simulator-web, phase4-prereq |
| 015 | Alert severity taxonomy - clarify 4 layers + fix BE enum drift | 🟢 Accepted | 2026-05-13 | architecture, severity, cross-repo, health_system, iot-sim, healthguard, database, schema |

## By tag

### workspace
- 001-workspace-tooling-host
- 002-bug-log-centralized

### tooling
- 001-workspace-tooling-host

### anti-loop
- 002-bug-log-centralized

### git
- 003-healthguard-trunk-strategy

### branching
- 003-healthguard-trunk-strategy

### healthguard
- 003-healthguard-trunk-strategy
- 005-internal-service-secret-strategy
- 006-mlops-mock-vs-real-integration
- 007-r2-artifact-vs-model-api-serving-disconnect
- 008-mobile-be-no-system-settings-write
- 009-avatar-storage-supabase-mobile-only

### workflow
- 003-healthguard-trunk-strategy
- 004-api-prefix-standardization

### security
- 005-internal-service-secret-strategy

### mobile
- 011-uc040-pair-create-only
- 012-drop-calibration-offset-fields

### mobile-backend
- 008-mobile-be-no-system-settings-write

### mobile-frontend
- 009-avatar-storage-supabase-mobile-only

### health_system
- 005-internal-service-secret-strategy
- 008-mobile-be-no-system-settings-write
- 009-avatar-storage-supabase-mobile-only
- 010-devices-schema-canonical
- 011-uc040-pair-create-only
- 012-drop-calibration-offset-fields
- 013-iot-sim-direct-db-write-vitals

### backend
- 004-api-prefix-standardization
- 005-internal-service-secret-strategy

### database
- 010-devices-schema-canonical
- 012-drop-calibration-offset-fields

### schema
- 010-devices-schema-canonical
- 012-drop-calibration-offset-fields

### canonical
- 010-devices-schema-canonical
- 015-alert-severity-taxonomy-mapping

### iot-sim
- 005-internal-service-secret-strategy
- 010-devices-schema-canonical
- 013-iot-sim-direct-db-write-vitals
- 014-profile-taxonomy-health-profile-unified
- 015-alert-severity-taxonomy-mapping

### uc
- 011-uc040-pair-create-only

### devices
- 010-devices-schema-canonical

### cross-repo
- 004-api-prefix-standardization
- 005-internal-service-secret-strategy
- 007-r2-artifact-vs-model-api-serving-disconnect
- 008-mobile-be-no-system-settings-write
- 009-avatar-storage-supabase-mobile-only
- 010-devices-schema-canonical
- 013-iot-sim-direct-db-write-vitals
- 015-alert-severity-taxonomy-mapping

### api
- 004-api-prefix-standardization

### refactor
- 004-api-prefix-standardization

### scope
- 006-mlops-mock-vs-real-integration
- 007-r2-artifact-vs-model-api-serving-disconnect
- 008-mobile-be-no-system-settings-write
- 009-avatar-storage-supabase-mobile-only
- 011-uc040-pair-create-only
- 012-drop-calibration-offset-fields
- 013-iot-sim-direct-db-write-vitals
- 014-profile-taxonomy-health-profile-unified

### mlops
- 006-mlops-mock-vs-real-integration

### ai-models
- 006-mlops-mock-vs-real-integration
- 007-r2-artifact-vs-model-api-serving-disconnect

### architecture
- 007-r2-artifact-vs-model-api-serving-disconnect
- 008-mobile-be-no-system-settings-write
- 009-avatar-storage-supabase-mobile-only
- 013-iot-sim-direct-db-write-vitals
- 014-profile-taxonomy-health-profile-unified
- 015-alert-severity-taxonomy-mapping

### severity
- 015-alert-severity-taxonomy-mapping

### persona
- 014-profile-taxonomy-health-profile-unified

### simulator-web
- 014-profile-taxonomy-health-profile-unified

### phase4-prereq
- 014-profile-taxonomy-health-profile-unified
- 015-alert-severity-taxonomy-mapping

### performance
- 013-iot-sim-direct-db-write-vitals

### storage
- 009-avatar-storage-supabase-mobile-only

### simplification
- 008-mobile-be-no-system-settings-write

### dead-code
- 008-mobile-be-no-system-settings-write
- 012-drop-calibration-offset-fields

### model-api
- 007-r2-artifact-vs-model-api-serving-disconnect

### graduation-project
- 006-mlops-mock-vs-real-integration
- 011-uc040-pair-create-only
- 012-drop-calibration-offset-fields

---

## How to use

### Tạo ADR mới

```pwsh
$adrDir = 'd:\DoAn2\VSmartwatch\PM_REVIEW\ADR'
$existing = Get-ChildItem $adrDir -Filter '[0-9]*-*.md' | Sort-Object Name -Descending | Select-Object -First 1
$nextNum = if ($existing) { [int](($existing.BaseName -split '-')[0]) + 1 } else { 1 }
$nextId = '{0:D3}' -f $nextNum
$slug = '<short-kebab-title>'
Copy-Item "$adrDir\_TEMPLATE.md" "$adrDir\$nextId-$slug.md"
Write-Host "Created: $adrDir\$nextId-$slug.md"
```

Sau đó: edit file + add row vào INDEX > Chronological + tag table.

### Tìm ADR liên quan

```pwsh
# Bằng tag
Get-Content 'd:\DoAn2\VSmartwatch\PM_REVIEW\ADR\INDEX.md' | Select-String -Pattern '<tag-name>' -Context 5

# Bằng keyword trong content
Get-ChildItem 'd:\DoAn2\VSmartwatch\PM_REVIEW\ADR' -Filter '*.md' -Exclude 'INDEX.md','_TEMPLATE.md' | 
  Select-String -Pattern '<keyword>' -List
```

### Supersede ADR cũ

1. Tạo ADR mới với status `Accepted`.
2. Trong ADR mới: section `Related` → "Supersedes ADR-NNN".
3. Update ADR cũ: status → `Superseded by NNN`, link sang ADR mới.
4. Update INDEX: ADR cũ → `Superseded by NNN`, ADR mới → `Accepted`.

KHÔNG xóa ADR cũ — lịch sử quan trọng.
