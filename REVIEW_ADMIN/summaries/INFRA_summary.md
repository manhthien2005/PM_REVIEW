# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express + Prisma ORM + JavaScript; port 5000; Prisma connects to PostgreSQL
- SQL SCRIPTS/ is single source of truth for DB schema
- Swagger docs at `/api-docs`; health check at `/api/health`; CORS restricted to FRONTEND_URL

## File Index
| Path                                     | Role                                         |
| ---------------------------------------- | -------------------------------------------- |
| backend/src/server.js                    | App entry point (port 5000) (296B)           |
| backend/src/app.js                       | Express app setup (CORS, routes) (879B)      |
| backend/src/config/swagger.js            | Swagger spec (6975B)                         |
| backend/src/utils/prisma.js              | Prisma client singleton (447B)               |
| backend/src/middlewares/errorHandler.js  | Global error handler (1660B)                 |
| backend/src/utils/catchAsync.js          | Async wrapper (447B)                         |
| backend/src/middlewares/auth.js          | JWT + role middleware (3502B)                |
| backend/seed-test-data.js                | Test data seeding script (14273B)            |
| backend/prisma/schema.prisma             | Prisma schema                                |
| backend/.env                             | DB_URL, JWT_SECRET, PORT, SMTP, FRONTEND_URL |
| PM_REVIEW/SQL SCRIPTS/01-09              | DB schema (source of truth)                  |

## Cross-References
| Type           | Ref                                      |
| -------------- | ---------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/                   |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |
