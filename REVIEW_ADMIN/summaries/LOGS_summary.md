# LOGS (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC026

## Purpose & Technique
- Admin can view system audit logs with filtering (date range, user, action, status, resource_type, search) and pagination
- Export filtered logs to CSV or JSON format
- Data source: `audit_logs` table; rate limited 100 req/min

## API Index
| Endpoint                    | Method | Note                            |
| --------------------------- | ------ | ------------------------------- |
| /api/v1/logs                | GET    | List logs; filter + paginate    |
| /api/v1/logs/:id            | GET    | Log detail by ID                |
| /api/v1/logs/export/csv     | GET    | Export filtered logs as CSV     |
| /api/v1/logs/export/json    | GET    | Export filtered logs as JSON    |

## File Index
| Path                                                     | Role                                |
| -------------------------------------------------------- | ----------------------------------- |
| backend/src/controllers/logs.controller.js               | Logs route handlers (2996B)         |
| backend/src/services/logs.service.js                     | Logs query + export logic (6256B)   |
| backend/src/routes/logs.routes.js                        | Route definitions + validation (2491B) |
| backend/src/__tests__/controllers/logs.controller.test.js | Controller tests (5925B)           |
| backend/src/__tests__/services/logs.service.test.js      | Service tests (11724B)              |
| frontend/src/pages/admin/SystemLogsPage.jsx              | Logs management page (7948B)        |
| frontend/src/components/logs/LogDetailModal.jsx          | Log detail modal (6217B)            |
| frontend/src/components/logs/LogsConstants.js            | Logs constants (555B)               |
| frontend/src/components/logs/LogsPagination.jsx          | Pagination component (3908B)        |
| frontend/src/components/logs/LogsTable.jsx               | Logs data table (9277B)             |
| frontend/src/components/logs/LogsToolbar.jsx             | Toolbar, filters, export (7427B)    |
| frontend/src/services/logsService.js                     | Frontend logs API calls (4039B)     |

## Cross-References
| Type      | Ref                                    |
| --------- | -------------------------------------- |
| DB Tables | audit_logs                             |
| UC Files  | BA/UC/Admin/UC026_ViewSystemLogs.md    |
