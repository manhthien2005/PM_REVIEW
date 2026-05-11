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
│   ├── rules/               # 00-50: operating mode, context, conventions, testing, security, token
│   ├── skills/              # 19 skills (10 từ Meep + 9 custom của anh)
│   ├── workflows/           # 9 slash commands (/plan /build /test ...)
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

| Command | Tác dụng |
|---|---|
| `/plan` | Decompose spec → ordered tasks với TDD |
| `/build` | Execute plan task-by-task |
| `/test` | Run + verify tests |
| `/debug` | Systematic root-cause debugging |
| `/fix-issue` | End-to-end fix với regression test |
| `/review` | Self code review |
| `/spec` | Write/refine feature spec |
| `/deploy` | Deploy checklist |
| `/start` | Bootstrap new feature |

Xem `<repo>/.windsurf/workflows/<command>.md` cho detailed steps.

## Skills (invocable)

Em sẽ auto-invoke skill khi gặp keyword tương ứng. Anh cũng có thể explicit:

**Engineering skills (từ Meep):**
- `tdd` — Test-first development
- `systematic-debugging` — 4-phase root-cause
- `writing-plans` — Vertical slice planning
- `verification-before-completion` — Pre-claim-done checklist
- `karpathy-guidelines` — Surgical changes
- `code-review-five-axis` — 5-axis review framework
- `brainstorming` — Multi-perspective ideation
- `caveman-vi` — Ultra-compressed Vietnamese mode
- `flutter-mobile-patterns` — Riverpod + dio + GoRouter + FCM (VSmartwatch native)
- `express-prisma-patterns` — Prisma + JWT + Postgres + Socket.IO (HealthGuard admin)
- `fastapi-patterns` — FastAPI + Pydantic v2 + asyncpg (3 Python BE repos)

**PM/QA skills (custom của anh):**
- `UC_AUDIT` — Audit Use Cases vs SQL vs JIRA
- `TEST_CASE_GEN` — Generate/execute test cases
- `task-manager` — Sprint planning + Epic breakdown
- `backlog-auditor` — Sprint progress audit
- `detailed-feature-review` — 8-criteria code review
- `doc-gen` — Generate SRS/SDD
- `mobile-agent` — Flutter UI design/build/review
- `TongQuan` — Project overview assessment
- `CHECK` — Project structure sync

## Verification sau sync

```pwsh
# Check 1 repo có đầy đủ .windsurf/ chưa
Get-ChildItem d:\DoAn2\VSmartwatch\HealthGuard\.windsurf -Recurse -Directory | Select-Object FullName
```

Expected per repo:
- `.windsurf/rules/` — 7 shared + 1-2 overlay rules
- `.windsurf/skills/` — 19 skills
- `.windsurf/workflows/` — 9 workflows
- `.windsurf/hooks/` — 2 Python scripts
- `.windsurf/hooks.json`
- `.windsurf/topology.md`
- `.windsurf/repo-context.md`
