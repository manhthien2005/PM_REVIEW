# LOGS (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC026

## Purpose & Technique
- Admin can view system audit logs with filtering (date range, user, action type, severity) and pagination
- Export filtered logs to CSV
- Data source: `audit_logs` table; optionally `system_metrics` for health data

## API Index
| Endpoint                  | Method | Note                          |
| ------------------------- | ------ | ----------------------------- |
| /api/admin/logs           | GET    | List logs; filter + paginate  |
| /api/admin/logs/export    | GET    | Export filtered logs as CSV   |

## File Index
| Path                                         | Role               |
| -------------------------------------------- | ------------------ |
| backend/src/controllers/logs.controller.ts   | ⬜ Not built yet  |
| backend/src/services/logs.service.ts         | ⬜ Not built yet  |
| frontend/src/pages/SystemLogs.tsx            | ⬜ Not built yet  |

## Known Issues
- 🔴 No source code exists — controller, service, route, and frontend page all unbuilt

## Cross-References
| Type      | Ref                                    |
| --------- | -------------------------------------- |
| DB Tables | audit_logs, system_metrics             |
| UC Files  | BA/UC/Admin/UC026_ViewSystemLogs.md    |
