# ADMIN_USERS (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC022

## Purpose & Technique
- Admin can manage all system users: list (search/filter/paginate), create, view detail, update, soft-delete, lock/unlock
- All routes require ADMIN role JWT; validation rules on create/update/delete
- All admin actions intended to be logged to `audit_logs` table

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/users | GET | Search, filter, paginate |
| /api/v1/users | POST | ADMIN role only, validation rules |
| /api/v1/users/:id | GET |  |
| /api/v1/users/:id | PATCH | full_name, phone, role |
| /api/v1/users/:id | DELETE | Soft delete, requires admin password |
| /api/v1/users/:id/lock | PATCH | Toggle lock |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/user.controller.js | Component (2839 bytes) |
| backend/src/services/user.service.js | Component (9426 bytes) |
| backend/src/routes/user.routes.js | Component (3874 bytes) |
| backend/src/__tests__/controllers/user.controller.test.js | Component (5847 bytes) |
| backend/src/__tests__/services/user.service.test.js | Component (14442 bytes) |
| frontend/src/pages/admin/UserManagementPage.jsx | Component (12418 bytes) |
| frontend/src/components/users/UserFormModal.jsx | Component (12955 bytes) |
| DeleteConfirmModal.jsx | Component (3785 bytes) |
| LockConfirmModal.jsx | Component (2576 bytes) |
| UsersConstants.js | Component (1438 bytes) |
| UsersPagination.jsx | Component (3911 bytes) |
| UsersTable.jsx | Component (9735 bytes) |
| UsersToolbar.jsx | Component (6730 bytes) |
| frontend/src/services/api.js | Component (613 bytes) |
| frontend/src/services/userService.js | Component (2290 bytes) |
## Cross-References
| Type      | Ref                              |
| --------- | -------------------------------- |
| DB Tables | users, audit_logs                |
| UC Files  | BA/UC/Admin/UC022_ManageUsers.md |
