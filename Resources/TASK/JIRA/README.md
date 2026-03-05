# JIRA INDEX — HealthGuard Project

> Quick-access index for AI/PM. Updated: 04/03/2026 | 16 Epics, 61 Stories, ~125 SP, 4 Sprints (2 weeks each)

Source CSV: `JIRA_IMPORT_ALL.csv` (untouched, for JIRA import)

## Sprint Overview

| Sprint | Theme                | Epics           | SP   | Path        |
| :----- | :------------------- | :-------------- | :--- | :---------- |
| 1      | Nền tảng & Xác thực  | EP01-EP05, EP12 | ~42  | `Sprint-1/` |
| 2      | Thiết bị & Giám sát  | EP06-EP08       | ~26  | `Sprint-2/` |
| 3      | Khẩn cấp & Thông báo | EP09-EP11       | ~23  | `Sprint-3/` |
| 4      | Phân tích & Quản trị | EP13-EP16       | ~36  | `Sprint-4/` |

## Epic Index

| Epic              | Module       | UCs           | Stories | SP   | Priority | Sprint |
| :---------------- | :----------- | :------------ | :------ | :--- | :------- | :----- |
| EP01-Database     | Infra        | —             | 4       | 6    | Highest  | 1      |
| EP02-AdminBE      | Infra        | —             | 2       | 3    | Highest  | 1      |
| EP03-MobileBE     | Infra        | —             | 2       | 3    | Highest  | 1      |
| EP04-Login        | Auth         | UC001         | 5       | 11   | Highest  | 1      |
| EP05-Register     | Auth         | UC002         | 5       | 9    | High     | 1      |
| EP06-Ingestion    | Infra        | —             | 3       | 6    | High     | 2      |
| EP07-Device       | Device       | UC040-042     | 6       | 12   | High     | 2      |
| EP08-Monitoring   | Monitoring   | UC006-008     | 3       | 8    | High     | 2      |
| EP09-FallDetect   | Emergency    | UC010         | 4       | 10   | High     | 3      |
| EP10-SOS          | Emergency    | UC014,015,011 | 3       | 7    | High     | 3      |
| EP11-Notification | Notification | UC030,031     | 3       | 6    | Medium   | 3      |
| EP12-Password     | Auth         | UC003,004     | 5       | 10   | Medium   | 1      |
| EP13-RiskScore    | Analysis     | UC016,017     | 4       | 11   | Medium   | 4      |
| EP14-Sleep        | Sleep        | UC020,021     | 4       | 8    | Medium   | 4      |
| EP15-AdminManage  | Admin        | UC022,025     | 5       | 12   | Medium   | 4      |
| EP16-AdminConfig  | Admin        | UC024,026     | 3       | 5    | Low      | 4      |

## UC → Epic Lookup

| UC    | Epic            | UC    | Epic           | UC    | Epic              |
| :---- | :-------------- | :---- | :------------- | :---- | :---------------- |
| UC001 | EP04-Login      | UC014 | EP10-SOS       | UC022 | EP15-AdminManage  |
| UC002 | EP05-Register   | UC015 | EP10-SOS       | UC024 | EP16-AdminConfig  |
| UC003 | EP12-Password   | UC016 | EP13-RiskScore | UC025 | EP15-AdminManage  |
| UC004 | EP12-Password   | UC017 | EP13-RiskScore | UC026 | EP16-AdminConfig  |
| UC005 | ⚠️ Gap (no Epic) | UC020 | EP14-Sleep     | UC030 | EP11-Notification |
| UC006 | EP08-Monitoring | UC021 | EP14-Sleep     | UC031 | EP11-Notification |
| UC007 | EP08-Monitoring | —     | —              | UC040 | EP07-Device       |
| UC008 | EP08-Monitoring | —     | —              | UC041 | EP07-Device       |
| UC009 | ⚠️ Gap (no Epic) | —     | —              | UC042 | EP07-Device       |
| UC010 | EP09-FallDetect | —     | —              | —     | —                 |
| UC011 | EP10-SOS        | —     | —              | —     | —                 |

## Folder Structure

```
JIRA/
├── README.md              ← This file (AI index)
├── JIRA_IMPORT_ALL.csv    ← Raw CSV for JIRA import (DO NOT EDIT)
├── Sprint-1/              ← _SPRINT.md + 6 Epic folders
├── Sprint-2/              ← _SPRINT.md + 3 Epic folders
├── Sprint-3/              ← _SPRINT.md + 3 Epic folders
└── Sprint-4/              ← _SPRINT.md + 4 Epic folders

Each Epic folder:
├── _EPIC.md               ← Epic metadata (compact)
└── STORIES.md             ← All stories + acceptance criteria checkboxes
```

## AI Agent Protocol

1. **Find tasks by module/UC** → Read this README → find Epic Name in tables above
2. **Get story details** → Open `Sprint-{N}/{EpicName}/STORIES.md`
3. **Track progress** → Check/update `[ ]` checkboxes in `STORIES.md` and `_SPRINT.md`
4. **For JIRA import** → Use `JIRA_IMPORT_ALL.csv` directly (never edit it)
