# `.kiro-template/` — VSmartwatch Kiro Workflow

Source-of-truth cho `.kiro/` config của 5 repo trong workspace VSmartwatch.

**Location:** `PM_REVIEW/tooling/.kiro-template/` (committed vào PM_REVIEW repo).
**Sync entrypoint:** `.\sync-kiro.ps1`

## Kiến trúc Kiro (khác Windsurf)

Kiro có 3 cơ chế chính:
1. **Steering files** (`.kiro/steering/*.md`) — luật + context, load theo inclusion mode
2. **Skills** (`.kiro/skills/*.md`) — invocable knowledge, load khi relevant
3. **Hooks** (`.kiro/hooks/*.json`) — event-driven automation (preToolUse, fileEdited, etc.)

Kiro KHÔNG có slash commands. Thay vào đó:
- Workflows được embed vào steering files (auto-load khi context match)
- Hoặc anh nói tự nhiên: "debug bug này", "review code", "plan feature" — Kiro tự load steering phù hợp

## Cấu trúc

```
.kiro-template/
├── README.md                    # File này
├── sync-kiro.ps1                # Deploy script
├── shared/
│   ├── steering/                # Rules + workflows (merged)
│   │   ├── 00-operating-mode.md       # always
│   │   ├── 10-project-context.md      # always
│   │   ├── 11-cross-repo-topology.md  # always
│   │   ├── 20-stack-conventions.md    # always
│   │   ├── 30-testing-discipline.md   # always
│   │   ├── 40-security-guardrails.md  # always
│   │   ├── 50-context-continuity.md   # always
│   │   ├── 60-workflow-start.md       # manual
│   │   ├── 61-workflow-build.md       # manual
│   │   ├── 62-workflow-debug.md       # manual
│   │   ├── 63-workflow-review.md      # manual
│   │   ├── 64-workflow-stuck.md       # manual
│   │   ├── 65-workflow-spec-plan.md   # manual
│   │   ├── 66-workflow-close-task.md  # manual
│   │   ├── 67-workflow-audit.md       # manual
│   │   ├── 68-workflow-refactor-module.md # manual
│   │   ├── 69-workflow-cross-repo-feature.md # manual
│   │   ├── 70-workflow-sync-spec.md   # manual
│   │   ├── 71-workflow-test.md        # manual
│   │   ├── 72-workflow-fix-issue.md   # manual
│   │   └── 73-workflow-deploy.md      # manual
│   ├── skills/                  # Invocable knowledge (22 skills)
│   │   ├── tdd.md
│   │   ├── systematic-debugging.md
│   │   ├── karpathy-guidelines.md
│   │   ├── code-review-five-axis.md
│   │   ├── bug-log.md
│   │   ├── decision-log.md
│   │   ├── verification-before-completion.md
│   │   ├── writing-plans.md
│   │   ├── flutter-mobile-patterns.md
│   │   ├── fastapi-patterns.md
│   │   ├── express-prisma-patterns.md
│   │   ├── brainstorming.md
│   │   ├── caveman-vi.md
│   │   ├── uc-audit.md
│   │   ├── test-case-gen.md
│   │   ├── task-manager.md
│   │   ├── backlog-auditor.md
│   │   ├── detailed-feature-review.md
│   │   ├── doc-gen.md
│   │   ├── mobile-agent.md
│   │   ├── tong-quan.md
│   │   └── project-check.md
│   └── hooks/                   # Event-driven guards
│       ├── block-dangerous-commands.json
│       ├── protect-secrets-write.json
│       ├── trunk-guard.json
│       └── verify-before-done.json
└── overlays/                    # Per-stack steering
    ├── flutter/
    │   └── steering/21-flutter.md
    ├── fastapi/
    │   └── steering/22-fastapi.md
    ├── express-prisma/
    │   └── steering/23-express-prisma.md
    ├── react-vite/
    │   └── steering/24-react-vite.md
    └── docs-sql/
        └── steering/25-docs-sql.md
```

## Mapping Windsurf → Kiro

| Windsurf | Kiro | Lý do |
|---|---|---|
| `rules/` (always_on) | `steering/` + `inclusion: always` | 1:1 |
| `rules/` (model_decision) | `steering/` + `inclusion: auto` | Kiro auto-detect relevance |
| `rules/` (glob) | `steering/` + `inclusion: fileMatch` | Trigger khi file match |
| `skills/` (22 folders) | `skills/` (flat .md files) | Kiro skills = flat markdown |
| `workflows/` (14 slash commands) | `steering/` (auto-load) | Kiro không có slash commands |
| `hooks.json` + Python scripts | `hooks/*.json` (declarative) | Kiro hooks = event-based |

## Ưu điểm Kiro so với Windsurf

1. **Hooks mạnh hơn** — event-based (preToolUse, postToolUse, fileEdited, agentStop)
2. **Steering auto-load** — không cần nhớ slash commands
3. **Specs native** — Requirements → Design → Tasks pipeline built-in
4. **Skills manual invoke** — anh dùng `#skill-name` trong chat để load

## Sync

```pwsh
# Từ bất kỳ đâu
& 'd:\DoAn2\VSmartwatch\PM_REVIEW\tooling\.kiro-template\sync-kiro.ps1'

# 1 repo
.\sync-kiro.ps1 -Repo health_system

# Preview
.\sync-kiro.ps1 -DryRun

# Clean sync
.\sync-kiro.ps1 -Mirror
```

## Coexistence với Windsurf

`.kiro/` và `.windsurf/` hoàn toàn tách biệt. Dùng song song không conflict.
