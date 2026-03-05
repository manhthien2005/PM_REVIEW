# SRS INDEX — HealthGuard (AI Quick-Reference)

> **Source**: `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` (382 lines)
> **Purpose**: AI reads this first for system-level context. Read full SRS only when detail is missing.
> **Updated**: 2026-03-05

---

## System Identity

| Property      | Value                                                              |
| ------------- | ------------------------------------------------------------------ |
| **Name**      | HealthGuard — IoT Health Monitoring & Alert System                 |
| **Goal**      | Monitor, analyze, and early-warn health risks for elderly/patients |
| **Scope**     | End-to-End: Simulator → Backend → Mobile App + Admin Web           |
| **NOT scope** | Does NOT replace medical diagnosis                                 |

### Actors

| Actor                | Role                                         | Platform   |
| -------------------- | -------------------------------------------- | ---------- |
| Patient/Elderly      | Wears device, views vitals, receives alerts  | Mobile App |
| Caregiver/Family     | Monitors patient, receives SOS notifications | Mobile App |
| Admin                | Manages users, config, dashboard, logs       | Web Admin  |
| AI Module (internal) | Fall detection, risk scoring, XAI            | Backend    |

---

## Architecture Overview

```
Device Layer (Python Simulator)
    │  MQTT/HTTP (streaming, 1-min interval)
    ▼
Data & Logic Layer (Multi-Backend, shared PostgreSQL + TimescaleDB)
    ├── Mobile BE (Python/FastAPI + SQLAlchemy)
    │     Services: Auth, Ingestion, Monitoring, AI/XAI, Notification, Sleep, Device
    └── Admin BE (Node.js/Express + Prisma + TypeScript)
          Services: Auth (Admin), Dashboard, Config, Logs
    │
    ▼
Application Layer
    ├── Mobile App (Flutter/Dart) — Patient & Caregiver
    └── Web Admin (React + Vite + TailwindCSS) — Admin
```

**Key**: Both backends share 1 PostgreSQL DB. Schema managed via `SQL SCRIPTS/`.

---

## Feature → Functional Requirement Mapping

| Feature                 | HG-FUNC    | Description                                               |
| ----------------------- | ---------- | --------------------------------------------------------- |
| Vital Signs Monitoring  | HG-FUNC-01 | Collect HR, SpO₂, BP, temp every 1 min from simulator     |
|                         | HG-FUNC-02 | Display on Mobile App with ≤5s latency                    |
|                         | HG-FUNC-03 | Alert if thresholds exceeded (see table below)            |
| Fall Detection          | HG-FUNC-04 | Combine accelerometer + HR/BP for fall confirmation       |
|                         | HG-FUNC-05 | AI triggers "Fall Alert" state (confidence > threshold)   |
|                         | HG-FUNC-06 | App: vibrate + sound + 30s countdown                      |
|                         | HG-FUNC-07 | Auto-SOS with GPS if no user response in 30s              |
| Risk Assessment & XAI   | HG-FUNC-08 | Risk Score = f(HRV, SpO₂, HR, BP history)                 |
|                         | HG-FUNC-09 | XAI explanation for HIGH risk alerts                      |
| Data Pipeline & Storage | HG-FUNC-10 | Stream processing from multiple simultaneous simulators   |
|                         | HG-FUNC-11 | Store history in PostgreSQL for review & model retraining |

---

## Medical Threshold Constants

| Metric       | Alert Condition         | Unit |
| ------------ | ----------------------- | ---- |
| SpO₂         | < 92%                   | %    |
| Body Temp    | > 37.8°C                | °C   |
| Heart Rate   | > 100 bpm OR < 60 bpm   | bpm  |
| Blood Press. | > 140 mmHg OR < 90 mmHg | mmHg |

### Risk Score Classification

| Range  | Level    | Action                     |
| ------ | -------- | -------------------------- |
| 0–33   | LOW      | Normal                     |
| 34–66  | MEDIUM   | Monitor closely            |
| 67–84  | HIGH     | Auto-notify caregiver      |
| 85–100 | CRITICAL | Urgent alert + auto-notify |

Risk assessment runs every 6 hours or on-demand.

---

## Tech Stack (Compact)

| Component     | Stack                                           |
| ------------- | ----------------------------------------------- |
| Mobile App    | Flutter/Dart, Android API 28+                   |
| Mobile BE     | Python, FastAPI, SQLAlchemy                     |
| Admin Web FE  | React, Vite, TailwindCSS, TypeScript            |
| Admin BE      | Node.js, Express, Prisma ORM, TypeScript        |
| Database      | PostgreSQL + TimescaleDB (shared)               |
| Schema Mgmt   | SQL Scripts (centralized, version-controlled)   |
| AI/ML         | Python, TensorFlow, scikit-learn, numpy, pandas |
| Simulator     | Python script (PC-based)                        |
| Push Notif.   | Firebase Cloud Messaging (FCM)                  |
| Communication | MQTT/HTTP (device→server), TLS/SSL encryption   |

---

## Security & Auth Summary

| Property            | Admin BE            | Mobile BE                            |
| ------------------- | ------------------- | ------------------------------------ |
| Auth method         | JWT                 | JWT                                  |
| Issuer              | `healthguard-admin` | `healthguard-mobile`                 |
| Token expiry        | 8 hours             | Access: 30d, Refresh: 90d (rotation) |
| Roles               | ADMIN               | PATIENT, CAREGIVER                   |
| Password hash       | bcrypt              | passlib + bcrypt                     |
| Min password length | 8 chars             | 8 chars                              |

---

## Business Processes (Summary)

| Process                   | Key Steps                                                      |
| ------------------------- | -------------------------------------------------------------- |
| Continuous Monitoring     | Device→MQTT→Server→threshold check→alert→store in TimescaleDB  |
| Fall Detection & Response | AI detect→30s countdown→user cancel OR auto-SOS with GPS       |
| Health Risk Assessment    | Every 6h or on-demand→Risk Score 0-100→XAI explanation→notify  |
| Manual SOS                | Hold 3s→confirm→GPS + Push/SMS/Email to all emergency contacts |

---

## Cross-References

| Resource         | Path                                                                        | Purpose                     |
| ---------------- | --------------------------------------------------------------------------- | --------------------------- |
| **Full SRS**     | `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` | Source of truth (382 lines) |
| **UC Index**     | `PM_REVIEW/Resources/UC/README.md`                                          | Use Case overview & list    |
| **JIRA Index**   | `PM_REVIEW/Resources/TASK/JIRA/README.md`                                   | 16 Epics, 61 Stories        |
| **DB Summary**   | `PM_REVIEW/SQL SCRIPTS/README.md`                                           | Database schema overview    |
| **MASTER INDEX** | `PM_REVIEW/MASTER_INDEX.md`                                                 | Project navigation map      |
