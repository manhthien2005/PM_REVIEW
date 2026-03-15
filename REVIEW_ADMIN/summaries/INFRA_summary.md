# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express 5 + Prisma ORM + JavaScript; port 5000; Prisma connects to PostgreSQL
- SQL SCRIPTS/ is single source of truth for DB schema
- Swagger docs at `/api-docs`; health check at `GET /api/v1/health`; CORS restricted to FRONTEND_URL
- Unit tests via Jest (16 test files); cookie-parser + express-rate-limit included

## File Index
| Path | Role |
| ---- | ---- |
| backend/src/app.js | Component (1287 bytes) |
| backend/src/server.js | Component (296 bytes) |
| backend/src/config/env.js | Component (1094 bytes) |
| backend/src/config/swagger.js | Component (41534 bytes) |
| backend/src/utils/prisma.js | Component (447 bytes) |
| backend/src/utils/ApiError.js | Component (1523 bytes) |
| backend/src/utils/ApiResponse.js | Component (1596 bytes) |
| backend/src/utils/catchAsync.js | Component (447 bytes) |
| backend/src/utils/email.js | Component (4274 bytes) |
| backend/src/utils/__mocks__/prisma.js | Component (218 bytes) |
| backend/src/middlewares/errorHandler.js | Component (1660 bytes) |
| validate.js | Component (2538 bytes) |
| backend/prisma/schema.prisma | Component (22588 bytes) |
| backend/API_GUIDE.md | Component (11161 bytes) |
## Cross-References
| Type           | Ref                                      |
| -------------- | ---------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/                   |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| ⬜ Not reviewed | GET |  |
| ✅ Built | GET |  |
| ✅ Built | GET |  |
| ⬜ Not reviewed | GET |  |
| ✅ Built | GET |  |
| ✅ Built | GET |  |
| ✅ Built | GET |  |
| ✅ Built | GET |  |
