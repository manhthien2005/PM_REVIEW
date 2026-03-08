# INFRA (Admin)

> Sprint 1 | JIRA: EP01-Database, EP02-AdminBE | UC: N/A

## Purpose & Technique
- Admin Backend: Node.js + Express + Prisma ORM + JavaScript
- Express endpoints and middleware configured in app.js and server.js
- Prisma connects to shared PostgreSQL + TimescaleDB

## File Index
| Path                        | Role                                |
| --------------------------- | ----------------------------------- |
| backend/src/server.js       | App entry point (296B)              |
| backend/src/app.js          | Express setup, CORS, parsing (879B) |
| backend/src/routes/index.js | Main router (649B)                  |
| backend/prisma/             | Prisma schema directory             |
| backend/.env                | Environment variables               |

## Cross-References
| Type           | Ref                                      |
| -------------- | ---------------------------------------- |
| SQL Scripts    | PM_REVIEW/SQL SCRIPTS/                   |
| Related Module | REVIEW_MOBILE/summaries/INFRA_summary.md |
