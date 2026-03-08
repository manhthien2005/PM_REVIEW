# ADMIN_USERS (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC022

## Purpose & Technique
- Admin can manage all system users: list (search/filter/paginate), create, view detail, update, soft-delete, lock/unlock
- All routes require ADMIN role JWT; validation rules on create/update/delete
- All admin actions intended to be logged to `audit_logs` table

## API Index
| Endpoint                  | Method | Note                                 |
| ------------------------- | ------ | ------------------------------------ |
| /api/v1/users             | GET    | List users; search, filter, paginate |
| /api/v1/users             | POST   | Create user (ADMIN only, validated)  |
| /api/v1/users/:id         | GET    | User detail                          |
| /api/v1/users/:id         | PATCH  | Update user (full_name, phone, role) |
| /api/v1/users/:id         | DELETE | Soft delete; requires admin password |
| /api/v1/users/:id/lock    | PATCH  | Toggle lock/unlock                   |

## File Index
| Path                                                 | Role                                  |
| ---------------------------------------------------- | ------------------------------------- |
| backend/src/controllers/user.controller.js           | All user route handlers (2450B)       |
| backend/src/services/user.service.js                 | User CRUD + lock logic (9078B)        |
| backend/src/routes/user.routes.js                    | Route definitions + validation (3961B)|
| frontend/src/pages/admin/UserManagementPage.jsx      | User management UI page (12505B)      |
| frontend/src/components/users/UserFormModal.jsx      | Add/Edit user modal (12955B)          |
| frontend/src/components/users/DeleteConfirmModal.jsx | Delete confirmation (3785B)           |
| frontend/src/components/users/LockConfirmModal.jsx   | Lock confirmation modal (2576B)       |
| frontend/src/components/users/UsersConstants.js      | Constants for user module (1598B)     |
| frontend/src/components/users/UsersPagination.jsx    | Pagination component (3911B)          |
| frontend/src/components/users/UsersTable.jsx         | Users data table (9267B)              |
| frontend/src/components/users/UsersToolbar.jsx       | Toolbar and search (6730B)            |
| frontend/src/services/api.js                         | Frontend generic API calls (613B)     |
| frontend/src/services/userService.js                 | Frontend user API calls (2290B)       |

## Cross-References
| Type      | Ref                              |
| --------- | -------------------------------- |
| DB Tables | users, audit_logs                |
| UC Files  | BA/UC/Admin/UC022_ManageUsers.md |
