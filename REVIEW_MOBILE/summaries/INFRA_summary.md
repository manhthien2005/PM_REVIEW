# INFRA (Mobile)

> Sprint 1-2 | JIRA: EP01-Database, EP03-MobileBE, EP06-Ingestion | UC: N/A

## Purpose & Technique

- FastAPI + SQLAlchemy backend setup, PostgreSQL + TimescaleDB connection
- Data ingestion via HTTP (`POST /api/mobile/telemetry/ingest`) and MQTT (Mosquitto)
- Clean Architecture: Route → Service → Repository, JWT auth, rate limiting

## API Index

| Endpoint                     | Method | Note                          |
| ---------------------------- | ------ | ----------------------------- |
| /health                      | GET    | Health check (200 OK)         |
| /api/mobile/telemetry/ingest | POST   | HTTP data ingestion (planned) |

## File Index

| Path                                  | Role                            |
| ------------------------------------- | ------------------------------- |
| backend/app/main.py                   | FastAPI entry point (17 LOC)    |
| backend/app/api/router.py             | Main router aggregator (6 LOC)  |
| backend/app/api/routes/health.py      | Health check endpoint (5 LOC)   |
| backend/app/core/config.py            | Settings/env config (30 LOC)    |
| backend/app/core/dependencies.py      | Auth dependencies (70 LOC)      |
| backend/app/db/database.py            | DB connection/session (12 LOC)  |
| backend/app/db/memory_db.py           | In-memory DB for tests (3 LOC)  |
| backend/app/models/user_model.py      | User model (20 LOC)             |
| backend/app/models/audit_log_model.py | AuditLog model (18 LOC)         |
| backend/app/utils/jwt.py              | JWT utils (121 LOC)             |
| backend/app/utils/email_service.py    | Email sending (190 LOC)         |
| backend/app/utils/password.py         | Bcrypt hashing (8 LOC)          |
| backend/app/utils/rate_limiter.py     | In-memory rate limiter (61 LOC) |
| backend/app/utils/datetime_helper.py  | TZ-aware datetime (8 LOC)       |
| backend/requirements.txt              | 8 deps + 3 test deps            |
| backend/.env                          | DB_URL, SECRET_KEY, SMTP config |
| backend/run.py                        | Server start script             |

## Known Issues

- 🔴 CORS: `allow_origins=["*"]` — must restrict to mobile app origins
- 🔴 Data ingestion (MQTT/HTTP) NOT implemented — no telemetry route or service
- 🟡 Rate limiter in-memory — needs Redis for production
- 🟡 Swagger UI not explicitly enabled

## Cross-References

| Type           | Ref                                         |
| -------------- | ------------------------------------------- |
| DB Tables      | users, audit_logs (only tables used so far) |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/                      |
| Related Module | REVIEW_ADMIN/summaries/INFRA_summary.md     |
| Data Flow      | Simulator → MQTT/HTTP → Ingestion → vitals  |
