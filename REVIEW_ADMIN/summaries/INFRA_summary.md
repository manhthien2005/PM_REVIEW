# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express + Prisma ORM + TypeScript; port 5000; Prisma connects to shared PostgreSQL + TimescaleDB
- SQL SCRIPTS/ (9 files, 01→09) is single source of truth for DB schema — backends do NOT run migrations directly
- Swagger docs at `/api-docs`; health check at `/api/health`; CORS restricted to FRONTEND_URL

## File Index
| Path                                     | Role                                         |
| ---------------------------------------- | -------------------------------------------- |
| backend/src/index.ts                     | App entry (CORS, routes, 1363B)              |
| backend/src/config/swagger.ts            | Swagger spec (3383B)                         |
| backend/src/lib/prisma.ts                | Prisma client singleton (935B)               |
| backend/src/utils/jwt.ts                 | JWT sign/verify helper (1088B)               |
| backend/src/utils/validators.ts          | Input validators (1890B)                     |
| backend/src/middleware/authMiddleware.ts | JWT + role middleware (2452B)                |
| backend/src/middleware/rateLimiter.ts    | Rate limiter (1382B)                         |
| backend/prisma/schema.prisma             | Prisma schema (4621B)                        |
| backend/src/scripts/seedTestUsers.ts     | Test data seeding script (3276B)             |
| backend/src/generated/client/            | Prisma auto-generated client                 |
| backend/.env                             | DB_URL, JWT_SECRET, PORT, SMTP, FRONTEND_URL |
| SQL SCRIPTS/01-09                        | DB schema (9 files, source of truth)         |

## Cross-References
| Type           | Ref                                      |
| -------------- | ---------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/ (9 files)         |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |
