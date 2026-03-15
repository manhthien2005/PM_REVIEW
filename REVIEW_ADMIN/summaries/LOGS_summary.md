# LOGS (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC026

## Purpose & Technique
- Admin can view system audit logs with filtering (date range, user, action, status, resource_type, search) and pagination
- Export filtered logs to CSV or JSON format
- Data source: `audit_logs` table; rate limited 100 req/min

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/logs | GET | Filter, paginate, validate |
| /api/v1/logs/:id | GET |  |
| /api/v1/logs/export/csv | GET | With same filter validation |
| /api/v1/logs/export/json | GET | With same filter validation |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/logs.controller.js | Component (2996 bytes) |
| backend/src/services/logs.service.js | Component (6256 bytes) |
| backend/src/routes/logs.routes.js | Component (2491 bytes) |
| backend/src/__tests__/controllers/logs.controller.test.js | Component (5925 bytes) |
| backend/src/__tests__/services/logs.service.test.js | Component (11724 bytes) |
| frontend/src/pages/admin/SystemLogsPage.jsx | Component (7948 bytes) |
| frontend/src/components/logs/LogDetailModal.jsx | Component (6217 bytes) |
| LogsConstants.js | Component (555 bytes) |
| LogsPagination.jsx | Component (3908 bytes) |
| LogsTable.jsx | Component (9277 bytes) |
| LogsToolbar.jsx | Component (7427 bytes) |
| frontend/src/services/logsService.js | Component (4039 bytes) |
## Cross-References
| Type      | Ref                                    |
| --------- | -------------------------------------- |
| DB Tables | audit_logs                             |
| UC Files  | BA/UC/Admin/UC026_ViewSystemLogs.md    |
