# MASTER INDEX — HealthGuard Project Review

> **Last Updated**: 2026-03-05  
> **Purpose**: AI navigation map — READ THIS FIRST before any review task  
> **Usage**: AI reads this file → identifies target module → reads only the relevant summary file

---

## Project Overview

| Property       | Value                                                                                  |
| -------------- | -------------------------------------------------------------------------------------- |
| **Project**    | HealthGuard — IoT Health Monitoring System                                             |
| **Admin App**  | React + Vite + TS (Frontend) / Node.js + Express + Prisma (Backend)                    |
| **Mobile App** | Flutter/Dart (Frontend) / FastAPI + SQLAlchemy (Backend)                               |
| **Database**   | PostgreSQL + TimescaleDB (shared), schema summary at `PM_REVIEW/SQL SCRIPTS/README.md` |
| **Actors**     | Patient, Caregiver, Admin, AI Module                                                   |
| **Sprints**    | 4 sprints total                                                                        |

---

## MODULE INDEX — ADMIN (HealthGuard/)

| #   | Module                                                                    | Sprint | UC Refs            | Summary File                                                            | Review Status | Score  | Quality     | Review File                         | Last Review |
| --- | ------------------------------------------------------------------------- | ------ | ------------------ | ----------------------------------------------------------------------- | ------------- | ------ | ----------- | ----------------------------------- | ----------- |
| 1   | **AUTH** — Login, Register, Forgot/Reset/Change Password, Profile, Logout | S1     | UC001-UC005, UC009 | [AUTH_summary.md](REVIEW_ADMIN/summaries/AUTH_summary.md)               | ✅ Done        | 92/100 | ✅ Pass | [View](REVIEW_ADMIN/AUTH_review.md) | 2026-03-08  |
| 2   | **ADMIN_USERS** — CRUD Users, Lock/Unlock                                 | S4     | UC022              | [ADMIN_USERS_summary.md](REVIEW_ADMIN/summaries/ADMIN_USERS_summary.md) | ⬜ Pending     | —      | —           | —                                   | —           |
| 3   | **DEVICES** — List, Detail, Update, Assign, Lock Devices                  | S4     | UC025              | [DEVICES_summary.md](REVIEW_ADMIN/summaries/DEVICES_summary.md)         | ⬜ Not built   | —      | —           | —                                   | —           |
| 4   | **CONFIG** — System Settings (Thresholds, AI config)                      | S4     | UC024              | [CONFIG_summary.md](REVIEW_ADMIN/summaries/CONFIG_summary.md)           | ⬜ Not built   | —      | —           | —                                   | —           |
| 5   | **LOGS** — View/Export System Logs                                        | S4     | UC026              | [LOGS_summary.md](REVIEW_ADMIN/summaries/LOGS_summary.md)               | ⬜ Not built   | —      | —           | —                                   | —           |
| 6   | **INFRA** — DB Setup, Express Project, CORS, Health Check, Swagger        | S1     | N/A                | [INFRA_summary.md](REVIEW_ADMIN/summaries/INFRA_summary.md)             | ⬜ Pending     | —      | —           | —                                   | —           |

---

## MODULE INDEX — MOBILE (health_system/)

| #   | Module                                                                    | Sprint | UC Refs            | Summary File                                                               | Review Status | Score  | Quality | Review File                                   | Last Review |
| --- | ------------------------------------------------------------------------- | ------ | ------------------ | -------------------------------------------------------------------------- | ------------- | ------ | ------- | --------------------------------------------- | ----------- |
| 1   | **AUTH** — Login, Register, Forgot/Reset/Change Password, Profile, Logout | S1     | UC001-UC005, UC009 | [AUTH_summary.md](REVIEW_MOBILE/summaries/AUTH_summary.md)                 | ✅ Done        | 84/100 | ✅ Pass  | [View](REVIEW_MOBILE/AUTH_LOGIN_review_v2.md) | 2026-03-04  |
| 2   | **DEVICE** — Connect, List, Unbind, Status                                | S2     | UC040-UC042        | [DEVICE_summary.md](REVIEW_MOBILE/summaries/DEVICE_summary.md)             | ⬜ Not built   | —      | —       | —                                             | —           |
| 3   | **INFRA** — FastAPI Setup, Data Ingestion (MQTT/HTTP)                     | S1-S2  | N/A                | [INFRA_summary.md](REVIEW_MOBILE/summaries/INFRA_summary.md)               | ⬜ Partial     | —      | —       | —                                             | —           |
| 4   | **MONITORING** — View Vitals, Detail, History                             | S2     | UC006-UC008        | [MONITORING_summary.md](REVIEW_MOBILE/summaries/MONITORING_summary.md)     | ⬜ Not built   | —      | —       | —                                             | —           |
| 5   | **EMERGENCY** — Fall Detection, SOS (Manual/Auto), Response               | S3     | UC010-UC015        | [EMERGENCY_summary.md](REVIEW_MOBILE/summaries/EMERGENCY_summary.md)       | ⬜ Not built   | —      | —       | —                                             | —           |
| 6   | **NOTIFICATION** — Emergency Contacts, Alerts, Settings                   | S3     | UC030-UC031        | [NOTIFICATION_summary.md](REVIEW_MOBILE/summaries/NOTIFICATION_summary.md) | ⬜ Not built   | —      | —       | —                                             | —           |
| 7   | **ANALYSIS** — Risk Score, XAI Explainer                                  | S4     | UC016-UC017        | [ANALYSIS_summary.md](REVIEW_MOBILE/summaries/ANALYSIS_summary.md)         | ⬜ Not built   | —      | —       | —                                             | —           |
| 8   | **SLEEP** — Sleep Analysis, Sleep Report                                  | S4     | UC020-UC021        | [SLEEP_summary.md](REVIEW_MOBILE/summaries/SLEEP_summary.md)               | ⬜ Not built   | —      | —       | —                                             | —           |

---

## REFERENCE FILES

| Type             | Path                                                                        | Lines | Description                                 |
| ---------------- | --------------------------------------------------------------------------- | ----- | ------------------------------------------- |
| SRS              | `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` | 346   | Full SRS document                           |
| JIRA Index       | `PM_REVIEW/Resources/TASK/JIRA/README.md`                                   | 137   | 16 Epics, 61 Stories — AI quick lookup      |
| JIRA CSV         | `PM_REVIEW/Resources/TASK/JIRA/JIRA_IMPORT_ALL.csv`                         | —     | Full CSV for Jira import                    |
| Admin Structure  | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md`                               | ~160  | Admin project module map                    |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md`                              | ~230  | Mobile project module map                   |
| Use Cases        | `BA/UC/`                                                                    | —     | Detailed use case specs per module          |
| SQL Scripts      | `PM_REVIEW/SQL SCRIPTS/`                                                    | —     | Database schema directory                   |
| DB Summary       | `PM_REVIEW/SQL SCRIPTS/README.md`                                           | 513   | Database overview, tables, and architecture |

---

## SKILLS INDEX

| #   | Skill              | Path                               | Purpose                                                  |
| --- | ------------------ | ---------------------------------- | -------------------------------------------------------- |
| 1   | **CHECK**          | `PM_REVIEW/SKILLS/CHECK/`          | Quick module summary scan & update                       |
| 2   | **TongQuan**       | `PM_REVIEW/SKILLS/TongQuan/`       | Overview review of project modules                       |
| 3   | **DanhGiaChiTiet** | `PM_REVIEW/SKILLS/DanhGiaChiTiet/` | Detailed code review per module                          |
| 4   | **SRS_AGENT**      | `PM_REVIEW/SKILLS/SRS_AGENT/`      | SRS analysis and requirement tracing                     |
| 5   | **UC_AUDIT**       | `PM_REVIEW/SKILLS/UC_AUDIT/`       | Batch audit UCs, cross-check UC↔SQL↔JIRA                 |
| 6   | **TEST_CASE_GEN**  | `PM_REVIEW/SKILLS/TEST_CASE_GEN/`  | Generate test cases from UC/SRS/SQL/API; execute & track |

---

## HOW TO USE THIS INDEX

### For TongQuan (Overview Review)

1. AI reads this `MASTER_INDEX.md`
2. AI reads the relevant `Project_Structure.md`
3. AI scans actual source code structure (folder/file listing only)
4. AI produces overview report — NO need to read full SRS or JIRA CSV

### For DanhGiaChiTiet (Detailed Review)

1. AI reads this `MASTER_INDEX.md` → finds the target module row
2. AI reads the corresponding `summaries/[MODULE]_summary.md` (contains pre-digested context)
3. AI reads actual source code files listed in the summary
4. AI produces detailed report — NO need to read full SRS or JIRA CSV

### Rules for AI

- **Read `SRS_INDEX.md` first** for system-level context — read full SRS only when specific detail is missing
- **NEVER read all JIRA CSV** — use JIRA Index (`JIRA/README.md`) for Epic lookup
- **ALWAYS start from this index** — do not browse the filesystem blindly
- **Read source code progressively**: outline first → key functions → full file only if needed

---

## Update History

| Date       | Version | Changes                                                                                              |
| ---------- | ------- | ---------------------------------------------------------------------------------------------------- |
| 2026-03-07 | v2.3    | CHECK ADMIN: +generated/, +scripts/, +validators.ts, +GET /me, exact byte sizes, 3 summaries updated |
| 2026-03-05 | v2.2    | CHECK ADMIN: corrected routes, folder structure, Trello→JIRA, summaries → new template               |
| 2026-03-04 | v2.1    | Added Quality Status + Review File columns; score classification (≥76 Pass)                          |
| 2026-03-04 | v2.0    | CHECK scan: Trello→JIRA, MOBILE 7/8 modules confirmed NOT built, AUTH 82/100                         |
| 2026-03-03 | v1.0    | Initial creation with 14 module summaries                                                            |
