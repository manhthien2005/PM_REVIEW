# `.windsurf-template/` — VSmartwatch Workflow Template

Source-of-truth cho `.windsurf/` config của 5 repo trong workspace VSmartwatch.

**Location:** `PM_REVIEW/tooling/.windsurf-template/` (committed vào PM_REVIEW repo).
**Sync entrypoint:** `.\sync.ps1` (portable — uses `$PSScriptRoot`).

## Cấu trúc

```
.windsurf-template/
├── README.md                # File này
├── topology.md              # Cross-repo data flow reference
├── sync.ps1                 # Deploy script (template -> repos)
├── shared/                  # Áp dụng cho mọi repo
│   ├── NOTICE.md            # Do-not-edit notice for deployed copies
│   ├── rules/               # 8 shared rules (00, 10, 11, 20, 30, 40, 50, 60)
│   ├── skills/              # 22 skills (engineering + stack patterns + PM/QA + anti-loop)
│   ├── workflows/           # 14 slash commands
│   └── hooks/               # Python pre-command hooks (security)
│   └── hooks.json
└── overlays/                # Áp dụng theo stack
    ├── flutter/             # → health_system (mobile UI)
    ├── fastapi/             # → health_system (BE), iot, model-api
    ├── express-prisma/      # → HealthGuard (BE)
    ├── react-vite/          # → HealthGuard (FE)
    └── docs-sql/            # → PM_REVIEW
```

## Workspace strategy

Anh dùng **multi-workspace** trong Windsurf:
- Mỗi repo là 1 workspace riêng có `.windsurf/` riêng (committed vào repo đó).
- Windsurf load `.windsurf/` từ workspace root → đảm bảo context đúng per repo.
- `d:\DoAn2\VSmartwatch\.windsurf-template/` là **template trung gian** — không phải workspace, chỉ là nguồn để sync.

### Khi nào dùng workspace cha?

Khi sửa template, anh có thể:
- **Open thêm** `d:\DoAn2\VSmartwatch\` làm workspace mới
- Hoặc edit template từ bất kỳ workspace nào (file path absolute)
- Sau khi sửa, chạy `sync.ps1` để propagate xuống 5 repo

## Cách sync

```pwsh
# Cd to template (or use absolute path)
cd d:\DoAn2\VSmartwatch\PM_REVIEW\tooling\.windsurf-template

# Sync tất cả repo, update mode (preserve extras)
.\sync.ps1

# Sync 1 repo cụ thể
.\sync.ps1 -Repo HealthGuard

# Mirror mode (clean sync, delete files trong dest không có ở source)
.\sync.ps1 -Mirror

# Preview only, không thực sự copy
.\sync.ps1 -DryRun

# Combine
.\sync.ps1 -Repo health_system -Mirror -DryRun
```

## Repo → overlay mapping

| Repo | Shared | Overlays | Stack |
|---|---|---|---|
| HealthGuard | ✅ | `express-prisma`, `react-vite` | Admin BE + FE |
| health_system | ✅ | `flutter`, `fastapi` | Mobile + BE |
| Iot_Simulator_clean | ✅ | `fastapi` | IoT sim |
| healthguard-model-api | ✅ | `fastapi` | Model API |
| PM_REVIEW | ✅ | `docs-sql` | Docs + SQL |

## Workflow khi update template

1. Edit file trong `.windsurf-template/shared/` hoặc `.windsurf-template/overlays/`
2. Test locally: open file Windsurf load chính file template để verify markdown đúng
3. Run `.\sync.ps1 -DryRun` để preview changes
4. Run `.\sync.ps1` để apply
5. Mỗi repo: `git status` xem changes, commit với message `chore(.windsurf): sync template <desc>`
6. Push từng repo

## Per-repo customization

Nếu 1 repo cần rule custom không có trong template:
- Tạo file mới trong `<repo>/.windsurf/rules/<custom>.md`
- Default `sync.ps1` (update mode) **không xóa** file đó — preserve.
- Lưu ý: nếu chạy `-Mirror`, custom rules sẽ bị xóa. Document custom rules để khôi phục được.

## Slash commands (workflows)

Sau khi sync, từ bất kỳ repo nào anh có thể invoke:

### Per-task lifecycle

| Command | Tác dụng |
|---|---|
| `/start` | Bootstrap new task — load context, check blockers, create branch |
| `/spec` | Write/refine feature spec — UC-driven, propose 2-3 approaches |
| `/plan` | Decompose spec → ordered vertical-slice tasks |
| `/build` | Execute plan task-by-task with TDD |
| `/test` | Write/extend tests (unit/widget/integration/contract) |
| `/review` | Self code review — 5 axes |
| `/close-task` | Post-merge cleanup — pull trunk, delete branches, update trackers |

### Diagnostic / fix

| Command | Tác dụng |
|---|---|
| `/debug` | Systematic root-cause debugging |
| `/fix-issue` | End-to-end fix with regression test |
| `/stuck` | Anti-loop force re-evaluation when 3+ failed attempts |

### Refactor / scope

| Command | Tác dụng |
|---|---|
| `/audit` | Audit module's current state before refactoring |
| `/refactor-module` | Convert audit findings to actionable refactor plan |
| `/cross-repo-feature` | Orchestrate feature spanning multiple repos |
| `/sync-spec` | Ripple UC/SRS/SQL changes to code/tests/JIRA |

### Documentation

| Command | Tác dụng |
|---|---|
| `/deploy` | Deploy checklist (documentation only — anh runs commands manually) |

Xem `<repo>/.windsurf/workflows/<command>.md` cho detailed steps.

## Skills (invocable)

Em sẽ auto-invoke skill khi gặp keyword tương ứng. Anh cũng có thể explicit:

**Engineering core (universal):**
- `tdd` — Test-first development
- `systematic-debugging` — 4-phase root-cause
- `writing-plans` — Vertical slice planning
- `verification-before-completion` — Pre-claim-done checklist
- `karpathy-guidelines` — Surgical changes
- `code-review-five-axis` — 5-axis review framework
- `brainstorming` — Multi-perspective ideation
- `caveman-vi` — Ultra-compressed Vietnamese mode

**Stack patterns (codebase-specific):**
- `flutter-mobile-patterns` — Riverpod + dio + GoRouter + FCM (health_system mobile)
- `express-prisma-patterns` — Prisma + JWT + Postgres + Socket.IO (HealthGuard admin)
- `fastapi-patterns` — FastAPI + Pydantic v2 + asyncpg (3 Python BE repos)

**Anti-loop infrastructure:**
- `bug-log` — Track every fix attempt to prevent retry of failed approaches
- `decision-log` — ADR-lite for cross-session architectural decisions

**PM/QA skills (project-specific):**
- `UC_AUDIT` — Audit Use Cases vs SQL vs JIRA
- `TEST_CASE_GEN` — Generate/execute test cases
- `task-manager` — Sprint planning + Epic breakdown
- `backlog-auditor` — Sprint progress audit
- `detailed-feature-review` — 8-criteria deep audit (Vietnamese report)
- `doc-gen` — Generate SRS/SDD
- `mobile-agent` — Manage screen spec lifecycle (TASK mode only)
- `TongQuan` — Project-level overview assessment
- `CHECK` — Sync PM_REVIEW docs with code reality

## Verification sau sync

```pwsh
# Check 1 repo có đầy đủ .windsurf/ chưa
Get-ChildItem d:\DoAn2\VSmartwatch\HealthGuard\.windsurf -Recurse -Directory | Select-Object FullName
```

Expected per repo:
- `.windsurf/NOTICE.md` — do-not-edit notice (deployed copy)
- `.windsurf/rules/` — 8 shared + 1-2 overlay rules
- `.windsurf/skills/` — 22 skills
- `.windsurf/workflows/` — 14 workflows (or 15 with /close-task after R2)
- `.windsurf/hooks/` — 2 Python scripts (block_dangerous_commands, protect_secrets)
- `.windsurf/hooks.json`
- `.windsurf/topology.md`
- `.windsurf/repo-context.md` — auto-generated per sync

## Rule activation modes (Windsurf)

Rules use 4 trigger types per Windsurf docs:

| Mode | When loaded | Used for |
|---|---|---|
| `always_on` | Every message (full content in prompt) | Foundational behavior — `00-operating-mode`, `40-security-guardrails`, `60-context-continuity` |
| `model_decision` | When AI deems relevant (description-based) | Reference info — `10-project-context`, `11-cross-repo-topology`, `20-stack-conventions`, `30-testing-discipline`, `50-token-discipline` |
| `glob` | When file matching pattern is read/edited | Stack overlays — `21-flutter`, `22-fastapi`, `23-express-prisma`, `24-react-vite`, `25-docs-sql` |
| `manual` | Explicit @mention | (none currently) |

Reducing always_on count = less context bloat per message but rules still available when needed.
