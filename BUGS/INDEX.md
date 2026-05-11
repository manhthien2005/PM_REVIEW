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
| _(none yet)_ | | | | |

---

## Quick stats

- Total open: 2 (HG-001, IS-001)
- Total in progress: 1 (PM-001)
- Total resolved: 0
- Avg attempts to resolve: N/A
- Most-affected module: spec drift + admin alerts + IoT sleep AI broken

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
