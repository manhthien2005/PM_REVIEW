---
inclusion: always
---

# Project Context — VSmartwatch HealthGuard

Hệ thống smartwatch giám sát sức khỏe người cao tuổi. Đồ án 2 (capstone), solo dev.

## 5 Repo chính

| Repo | Path | Vai trò | Stack | Trunk |
|---|---|---|---|---|
| HealthGuard | `d:\DoAn2\VSmartwatch\HealthGuard` | Admin web | Express + Prisma + Vite | `develop` |
| health_system | `d:\DoAn2\VSmartwatch\health_system` | Mobile + Backend | Flutter 3.11 / FastAPI | `develop` |
| Iot_Simulator_clean | `d:\DoAn2\VSmartwatch\Iot_Simulator_clean` | IoT giả lập | Python FastAPI | `develop` |
| healthguard-model-api | `d:\DoAn2\VSmartwatch\healthguard-model-api` | Model API | Python FastAPI + ML | `master` |
| PM_REVIEW | `d:\DoAn2\VSmartwatch\PM_REVIEW` | Docs + SQL + PM | Markdown + SQL | `main` |

## Domain context

- **End user:** Người cao tuổi đeo smartwatch + người thân theo dõi qua mobile app + admin/clinician xem qua web.
- **Core features:** Vital signs monitoring, Fall detection + SOS, Risk analysis (ML), Emergency response, Family sharing, Health dashboard (admin).

## Spec source-of-truth

- **UC + SRS + DB schema + JIRA backlog**: tất cả ở `PM_REVIEW/`
- **MASTER_INDEX**: `PM_REVIEW/MASTER_INDEX.md`
- **Use Cases**: `PM_REVIEW/Resources/UC/{Module}/UC{XXX}.md` (26 UCs)
- **SQL schema**: `PM_REVIEW/SQL SCRIPTS/`
- **JIRA backlog**: `PM_REVIEW/Resources/TASK/JIRA/Sprint-{N}/`
- Khi cần verify yêu cầu → đọc UC trước, không guess.

## Khi anh request feature/bug fix

### Domain feature / behavior bug
1. Locate UC trong `PM_REVIEW/Resources/UC/`
2. Check cross-repo impact (xem topology steering)
3. Identify acceptance criteria từ UC + JIRA story
4. Đề xuất implementation plan

### Infra / tooling bug
1. Locate ADR trong `PM_REVIEW/ADR/` nếu có
2. Skip UC requirement — UC là cho domain behavior
3. Direct fix nếu trivial, plan nếu structural
