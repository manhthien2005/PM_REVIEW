# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express 5 + Prisma ORM + JavaScript; port 5000; Prisma connects to PostgreSQL
- SQL SCRIPTS/ is single source of truth for DB schema
- Swagger docs at `/api-docs`; health check at `GET /api/v1/health`; CORS restricted to FRONTEND_URL
- Unit tests via Jest (10 test files); cookie-parser + express-rate-limit included

## File Index
| Path                                    | Role                                         |
| --------------------------------------- | -------------------------------------------- |
| backend/src/server.js                   | App entry point (port 5000) (296B)           |
| backend/src/app.js                      | Express app setup (CORS, routes) (879B)      |
| backend/src/config/env.js               | Environment config (1094B)                   |
| backend/src/config/swagger.js           | Swagger spec (11468B)                        |
| backend/src/utils/prisma.js             | Prisma client singleton (447B)               |
| backend/src/utils/ApiError.js           | Custom error class (1523B)                   |
| backend/src/utils/ApiResponse.js        | Standardized response (1596B)                |
| backend/src/utils/catchAsync.js         | Async wrapper (447B)                         |
| backend/src/utils/email.js              | Email sending via Nodemailer (4274B)         |
| backend/src/utils/__mocks__/prisma.js   | Jest mock for Prisma (218B)                  |
| backend/src/middlewares/errorHandler.js | Global error handler (1660B)                 |
| backend/src/middlewares/validate.js     | Input validation middleware (2553B)          |
| backend/prisma/schema.prisma            | Prisma schema (22048B)                       |
| backend/prisma.config.ts                | Prisma config (408B)                         |
| backend/.env                            | DB_URL, JWT_SECRET, PORT, SMTP, FRONTEND_URL |
| backend/API_GUIDE.md                    | API documentation guide (11161B)             |
| backend/test-user.txt                   | Test user data (7509B)                       |
| PM_REVIEW/SQL SCRIPTS/01-09             | DB schema (source of truth)                  |

## Cross-References
| Type           | Ref                                      |
| -------------- | ---------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/                   |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |
