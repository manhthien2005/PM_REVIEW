# 🔬 MODULE SUMMARY: INFRA (Mobile)

> **Module**: INFRA — Mobile Backend Setup + Data Ingestion  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 1 (Setup) + Sprint 2 (Data Ingestion)  
> **Trello Cards**: Sprint 1 Card 2B (FastAPI Setup), Sprint 2 Card 3 (Data Ingestion)  
> **UC References**: N/A (infrastructure)

---

## 📋 SRS Requirements (Extracted)

### Architecture (SRS §2.1, §2.4)
- **Mobile Backend**: Python / FastAPI / SQLAlchemy
- **Database**: PostgreSQL + TimescaleDB (shared with Admin BE)
- **Schema**: Introspect from existing DB (SQL SCRIPTS/ is source of truth)
- **Data Protocol**: MQTT (Eclipse Mosquitto) + HTTP for device telemetry
- **JWT_SECRET**: Shared with Admin Backend

### Data Ingestion (SRS §4.2)
- HG-FUNC-01: Collect HR, SpO2, BP, temperature every **1 minute** from simulator
- HG-FUNC-10: Handle streaming data from multiple devices concurrently
- HG-FUNC-11: Store historical data in PostgreSQL for replay and AI retraining
- Validation ranges: HR 40-200, SpO2 70-100%, Temp 35-42°C, Accel -20 to 20 m/s²

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 2B — FastAPI Setup (Mobile BE Dev)
- [ ] FastAPI project with structure: `app/{api, core, models, schemas, services, utils}`
- [ ] Dependencies: fastapi, uvicorn, sqlalchemy, psycopg2-binary, python-jose, passlib, python-multipart
- [ ] SQLAlchemy + PostgreSQL connection
- [ ] CORS middleware (Mobile App origins)
- [ ] Logging (file + console)
- [ ] .env: `DB_URL`, `JWT_SECRET` (shared), `PORT`
- [ ] Health check: `GET /health` → 200
- [ ] Auto-generated docs at `/docs`
- [ ] Port: 8000 (different from Admin 3001)

### Card 3 — Data Ingestion (Mobile BE Dev)
- [ ] Setup MQTT broker (Mosquitto) or cloud MQTT
- [ ] MQTT subscriber/listener service
- [ ] `POST /api/mobile/telemetry/ingest` — HTTP fallback
  - Req: `{device_id, vital_signs: {...}, motion_data: {...}, timestamp}`
- [ ] Validate data ranges (HR, SpO2, Temp, Accel)
- [ ] Authenticate device (JWT or device token)
- [ ] Write to `vitals` + `motion_data` tables (TimescaleDB)
- [ ] Update `devices.last_seen_at`
- [ ] Log ingestion rate to `system_metrics`

---

## 📂 Source Code Files

### Backend (`health_system/backend/`)
| File Path | Role |
|-----------|------|
| `app/main.py` | FastAPI entry point (648 bytes) |
| `app/core/` | Config, security (2 files) |
| `app/db/` | Database connection, session (3 files) |
| `app/models/` | SQLAlchemy models (3 files) |
| `app/utils/` | Helper functions (6 files) |
| `requirements.txt` | Dependencies |
| `run.py` | Start server script |
| `.env` | Environment variables |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §2.1 (Multi-Backend), §2.4 (Environment), §3.3 (MQTT/HTTP) |
| SQL Scripts | `SQL SCRIPTS/` (shared with Admin) |
| Data Flow | Simulator → MQTT/HTTP → Data Ingestion → `vitals` + `motion_data` → AI |
| Related Admin INFRA | `REVIEW_ADMIN/summaries/INFRA_summary.md` |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
