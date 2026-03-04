# 🗺️ MASTER INDEX — HealthGuard Project Review

> **Last Updated**: 2026-03-03  
> **Purpose**: AI navigation map — READ THIS FIRST before any review task  
> **Usage**: AI reads this file → identifies target module → reads only the relevant summary file

---

## 📊 Project Overview

| Property       | Value                                                                                  |
| -------------- | -------------------------------------------------------------------------------------- |
| **Project**    | HealthGuard — IoT Health Monitoring System                                             |
| **Admin App**  | React + Vite + TS (Frontend) / Node.js + Express + Prisma (Backend)                    |
| **Mobile App** | Flutter/Dart (Frontend) / FastAPI + SQLAlchemy (Backend)                               |
| **Database**   | PostgreSQL + TimescaleDB (shared), schema summary at `PM_REVIEW/SQL SCRIPTS/README.md` |
| **Actors**     | Patient, Caregiver, Admin, AI Module                                                   |
| **Sprints**    | 4 sprints total                                                                        |

---

## 🔍 MODULE INDEX — ADMIN (HealthGuard/)

| #   | Module                                                                      | Sprint | UC Refs     | Summary File                                                            | Review Status | Score  | Last Review |
| --- | --------------------------------------------------------------------------- | ------ | ----------- | ----------------------------------------------------------------------- | ------------- | ------ | ----------- |
| 1   | **AUTH** — Login, Register, Forgot/Reset/Change Password                    | S1     | UC001-UC004 | [AUTH_summary.md](REVIEW_ADMIN/summaries/AUTH_summary.md)               | ✅ Done       | 58/100 | 2026-03-03  |
| 2   | **ADMIN_USERS** — CRUD Users, Lock/Unlock                                   | S4     | UC022       | [ADMIN_USERS_summary.md](REVIEW_ADMIN/summaries/ADMIN_USERS_summary.md) | ⬜ Pending    | —      | —           |
| 3   | **DEVICES** — List, Detail, Update, Assign, Lock Devices                    | S4     | UC025       | [DEVICES_summary.md](REVIEW_ADMIN/summaries/DEVICES_summary.md)         | ⬜ Pending    | —      | —           |
| 4   | **CONFIG** — System Settings (Thresholds, AI config)                        | S4     | UC024       | [CONFIG_summary.md](REVIEW_ADMIN/summaries/CONFIG_summary.md)           | ⬜ Pending    | —      | —           |
| 5   | **LOGS** — View/Export System Logs                                          | S4     | UC026       | [LOGS_summary.md](REVIEW_ADMIN/summaries/LOGS_summary.md)               | ⬜ Pending    | —      | —           |
| 6   | **INFRA** — DB Setup, Express Project, CORS, Logging, Health Check, Swagger | S1     | N/A         | [INFRA_summary.md](REVIEW_ADMIN/summaries/INFRA_summary.md)             | ⬜ Pending    | —      | —           |

---

## 🔍 MODULE INDEX — MOBILE (health_system/)

| #   | Module                                                      | Sprint | UC Refs      | Summary File                                                               | Review Status | Score  | Last Review |
| --- | ----------------------------------------------------------- | ------ | ------------ | -------------------------------------------------------------------------- | ------------- | ------ | ----------- |
| 1   | **AUTH** — Login, Register, Forgot/Reset/Change Password    | S1     | UC001-UC004  | [AUTH_summary.md](REVIEW_MOBILE/summaries/AUTH_summary.md)                 | ✅ Done       | 82/100 | 2026-03-04  |
| 2   | **DEVICE** — Connect, List, Unbind, Status                  | S2     | UC040, UC042 | [DEVICE_summary.md](REVIEW_MOBILE/summaries/DEVICE_summary.md)             | ⬜ Pending    | —      | —           |
| 3   | **INFRA** — FastAPI Setup, Data Ingestion (MQTT/HTTP)       | S1-S2  | N/A          | [INFRA_summary.md](REVIEW_MOBILE/summaries/INFRA_summary.md)               | ⬜ Pending    | —      | —           |
| 4   | **MONITORING** — View Vitals, Detail, History               | S2     | UC006-UC008  | [MONITORING_summary.md](REVIEW_MOBILE/summaries/MONITORING_summary.md)     | ⬜ Pending    | —      | —           |
| 5   | **EMERGENCY** — Fall Detection, SOS (Manual/Auto), Response | S3     | UC010-UC015  | [EMERGENCY_summary.md](REVIEW_MOBILE/summaries/EMERGENCY_summary.md)       | ⬜ Pending    | —      | —           |
| 6   | **NOTIFICATION** — Emergency Contacts, Alerts, Settings     | S3     | UC030-UC031  | [NOTIFICATION_summary.md](REVIEW_MOBILE/summaries/NOTIFICATION_summary.md) | ⬜ Pending    | —      | —           |
| 7   | **ANALYSIS** — Risk Score, XAI Explainer                    | S4     | UC016-UC017  | [ANALYSIS_summary.md](REVIEW_MOBILE/summaries/ANALYSIS_summary.md)         | ⬜ Pending    | —      | —           |
| 8   | **SLEEP** — Sleep Analysis, Sleep Report                    | S4     | UC020-UC021  | [SLEEP_summary.md](REVIEW_MOBILE/summaries/SLEEP_summary.md)               | ⬜ Pending    | —      | —           |

---

## 📎 REFERENCE FILES

| Type             | Path                                                                        | Lines | Description                                                               |
| ---------------- | --------------------------------------------------------------------------- | ----- | ------------------------------------------------------------------------- |
| SRS              | `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` | 346   | Full SRS document                                                         |
| Trello S1        | `PM_REVIEW/Resources/TASK/TRELLO_SPRINT1.md`                                | 513   | 7 cards: DB + 2 BE setup + Auth (Login/Register/Forgot/Change)            |
| Trello S2        | `PM_REVIEW/Resources/TASK/TRELLO_SPRINT2.md`                                | 262   | 6 cards: Device + Data Ingestion + Monitoring (100% Mobile BE)            |
| Trello S3        | `PM_REVIEW/Resources/TASK/TRELLO_SPRINT3.md`                                | 188   | 6 cards: Emergency Contacts + Fall + SOS + Notifications (100% Mobile BE) |
| Trello S4        | `PM_REVIEW/Resources/TASK/TRELLO_SPRINT4.md`                                | 203   | 8 cards: Risk/AI + Sleep (Mobile BE) + Admin CRUD (Admin BE)              |
| Admin Structure  | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md`                               | 177   | Admin project module map                                                  |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md`                              | 223   | Mobile project module map                                                 |
| Use Cases        | `BA/UC/`                                                                    | —     | Detailed use case specs per module                                        |
| SQL Scripts      | `PM_REVIEW/SQL SCRIPTS/`                                                    | —     | Database schema directory                                                 |
| DB Summary       | `PM_REVIEW/SQL SCRIPTS/README.md`                                           | 513   | Database overview, tables, and architecture                               |

---

## 🧭 HOW TO USE THIS INDEX

### For TongQuan (Overview Review)

1. AI reads this `MASTER_INDEX.md`
2. AI reads the relevant `Project_Structure.md`
3. AI scans actual source code structure (folder/file listing only)
4. AI produces overview report — NO need to read full SRS or Trello

### For DanhGiaChiTiet (Detailed Review)

1. AI reads this `MASTER_INDEX.md` → finds the target module row
2. AI reads the corresponding `summaries/[MODULE]_summary.md` (contains pre-digested SRS + Trello)
3. AI reads actual source code files listed in the summary
4. AI produces detailed report — NO need to read full SRS or Trello

### ⚠️ Rules for AI

- **NEVER read full SRS** unless specifically asked — use summary files instead
- **NEVER read all Trello files** — the relevant checklist items are pre-extracted in summaries
- **ALWAYS start from this index** — do not browse the filesystem blindly
- **Read source code progressively**: outline first → key functions → full file only if needed

---

## 🔄 Update History

| Date       | Version | Changes                                   |
| ---------- | ------- | ----------------------------------------- |
| 2026-03-03 | v1.0    | Initial creation with 14 module summaries |
