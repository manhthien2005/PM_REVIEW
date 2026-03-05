# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express + Prisma ORM + TypeScript; port 5000; Prisma connects to shared PostgreSQL + TimescaleDB
- SQL SCRIPTS/ (9 files, 01→09) is single source of truth for DB schema — backends do NOT run migrations directly
- Swagger docs at `/api-docs`; health check at `/api/health`

## File Index
| Path                              | Role                            |
| --------------------------------- | ------------------------------- |
| backend/src/index.ts              | App entry (CORS, routes, 993B)  |
| backend/src/config/swagger.ts     | Swagger spec (3.3KB)            |
| backend/src/lib/prisma.ts         | Prisma client singleton (621B)  |
| backend/src/utils/jwt.ts          | JWT sign/verify helper (502B)   |
| backend/src/middleware/authMiddleware.ts | JWT + role middleware (1.7KB)|
| backend/src/middleware/rateLimiter.ts   | Rate limiter (374B)         |
| backend/prisma/                   | schema.prisma                   |
| backend/.env                      | DB_URL, JWT_SECRET, PORT, SMTP  |
| SQL SCRIPTS/01-09                 | DB schema (9 files, source of truth)|

## Cross-References
| Type           | Ref                                    |
| -------------- | -------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/ (9 files)       |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |
