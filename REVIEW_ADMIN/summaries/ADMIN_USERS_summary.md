# ADMIN_USERS (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC022

## Purpose & Technique
- Admin can manage all system users: list (search/filter/paginate), create, view detail, update, soft-delete, lock/unlock
- All mutations require ADMIN role JS JWT; soft-delete, toggle lock/unlock
- All admin actions intended to be logged to `audit_logs` table

## API Index
| Endpoint             | Method | Note                                 |
| -------------------- | ------ | ------------------------------------ |
| /api/users           | GET    | List users; search, filter, paginate |
| /api/users           | POST   | Create user (ADMIN only)             |
| /api/users/{id}      | GET    | User detail                          |
| /api/users/{id}      | PUT    | Update user (email not changeable)   |
| /api/users/{id}      | DELETE | Soft delete; requires admin password |
| /api/users/{id}/lock | PATCH  | Toggle lock/unlock; cannot lock self |

## File Index
| Path                                                 | Role                                  |
| ---------------------------------------------------- | ------------------------------------- |
| backend/src/controllers/user.controller.js           | All user route handlers (1746B)       |
| backend/src/services/user.service.js                 | User CRUD + lock logic (2426B)        |
| backend/src/routes/user.routes.js                    | Route definitions (1348B)             |
| frontend/src/pages/admin/UserManagementPage.jsx      | User management UI page (23889B)      |
| frontend/src/components/users/UserFormModal.jsx      | Add/Edit user modal (12955B)          |
| frontend/src/components/users/DeleteConfirmModal.jsx | Delete confirmation (3785B)           |
| frontend/src/components/users/LockConfirmModal.jsx   | Lock confirmation modal (2576B)       |
| frontend/src/services/api.js                         | Frontend generic API calls (613B)     |

## Cross-References
| Type      | Ref                              |
| --------- | -------------------------------- |
| DB Tables | users, audit_logs                |
| UC Files  | BA/UC/Admin/UC022_ManageUsers.md |
