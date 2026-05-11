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

## By tag

### workspace
- 001-workspace-tooling-host
- 002-bug-log-centralized

### tooling
- 001-workspace-tooling-host

### anti-loop
- 002-bug-log-centralized

### security
_(none yet)_

### mobile
_(none yet)_

### backend
_(none yet)_

### database
_(none yet)_

### cross-repo
_(none yet)_

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
