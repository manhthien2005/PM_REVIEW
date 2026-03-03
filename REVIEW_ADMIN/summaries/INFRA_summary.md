# 🔬 MODULE SUMMARY: INFRA (Admin)

> **Module**: INFRA — Infrastructure Setup  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 1  
> **Trello Cards**: Card 1 (Database), Card 2A (Admin BE Setup)  
> **UC References**: N/A (infrastructure)

---

## 📋 SRS Requirements (Extracted)

### Architecture (SRS §2.1, §2.4)
- **Admin Backend**: Node.js / Express.js / Prisma ORM / TypeScript
- **Database**: PostgreSQL + TimescaleDB (shared with Mobile BE)
- **Schema Management**: `SQL SCRIPTS/` is single source of truth — backends do NOT create migrations
- **Frontend**: ReactJS + TailwindCSS (Vite bundler)

### Non-Functional Requirements
- CORS configured for Admin Web origin only
- Logging: file + console
- Environment variables: `DB_URL`, `JWT_SECRET`, `PORT`
- JWT_SECRET shared with Mobile Backend

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 1 — Database Setup (Admin BE Dev)
- [ ] Setup PostgreSQL + TimescaleDB extension on dev environment
- [ ] Run SQL scripts sequentially (01 → 09)
- [ ] Verify all 11 tables created: `users`, `devices`, `vitals`, `motion_data`, `fall_events`, `sos_events`, `alerts`, `risk_scores`, `risk_explanations`, `audit_logs`, `system_metrics`
- [ ] Verify 44 indexes created
- [ ] Verify compression/retention policies active
- [ ] Test insert sample data
- [ ] Document connection string + credentials

### Card 2A — Admin Backend Setup (Admin BE Dev)
- [ ] Express + TypeScript project (in `HealthGuard/backend/`)
- [ ] Prisma Client connects to PostgreSQL
- [ ] Run `npx prisma db pull` to introspect DB schema
- [ ] CORS middleware (allow Admin Web origin)
- [ ] Logging (file + console)
- [ ] Environment variables (.env)
- [ ] Health check: `GET /health` → 200
- [ ] Swagger docs (swagger-jsdoc + swagger-ui-express)
- [ ] API prefix convention: `/api/...`

### Acceptance Criteria
- [ ] All 11 tables created successfully
- [ ] 44 indexes created
- [ ] Admin Backend runs on dedicated port (e.g., 3001)
- [ ] Health check returns 200
- [ ] Prisma Client connects to DB
- [ ] CORS configured correctly
- [ ] Logging works

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/`)
| File Path | Role |
|-----------|------|
| `src/index.ts` | App entry point (910 bytes) |
| `src/config/` | DB config, env vars (1 file) |
| `src/middleware/` | CORS, auth, error handling (2 files) |
| `src/routes/` | Express route definitions (1 file) |
| `src/lib/` | Shared libraries (1 file) |
| `prisma/` | Prisma schema (1 file) |
| `package.json` | Dependencies (1128 bytes) |
| `tsconfig.json` | TypeScript config |

### Database (`SQL SCRIPTS/`)
| File | Purpose |
|------|---------|
| `01_init_timescaledb.sql` | TimescaleDB extension |
| `02_create_tables_user_management.sql` | Users, roles |
| `03_create_tables_devices.sql` | Devices |
| `04_create_tables_timeseries.sql` | Vitals, motion_data (hypertables) |
| `05_create_tables_events_alerts.sql` | Fall events, SOS, alerts |
| `06_create_tables_ai_analytics.sql` | Risk scores, explanations |
| `07_create_tables_system.sql` | Audit logs, system metrics |
| `08_create_indexes.sql` | 44 indexes |
| `09_create_policies.sql` | Compression/retention policies |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §2.1 (Architecture), §2.4 (Environment), §6.2 (Tools) |
| SQL Scripts | `SQL SCRIPTS/` (9 files) |
| Related Mobile INFRA | `REVIEW_MOBILE/summaries/INFRA_summary.md` |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
