# ADMIN_USERS (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC022

## Purpose & Technique
- Admin can manage all system users: list (search/filter/paginate), create, view detail, update, soft-delete, lock/unlock
- All mutations require ADMIN JWT; soft-delete requires admin password confirmation
- All admin actions logged to audit_logs table

## API Index
| Endpoint   | Method | Note                                 |
| ---------- | ------ | ------------------------------------ |
| /users/    | GET    | List users; search, filter, paginate |
| /users/    | POST   | Create user (ADMIN only)             |
| /users/:id | GET    | User detail                          |
| /users/:id | PUT    | Replace user data                    |
| /users/:id | PATCH  | Partial update user                  |
| /users/:id | DELETE | Soft delete                          |

## File Index
| Path                                            | Role                        |
| ----------------------------------------------- | --------------------------- |
| backend/src/controllers/user.controller.js      | User handlers (1746B)       |
| backend/src/services/user.service.js            | User logic (2426B)          |
| backend/src/routes/user.routes.js               | Route definitions (1348B)   |
| frontend/src/pages/admin/UserManagementPage.jsx | User management UI (23889B) |

## Cross-References
| Type      | Ref                              |
| --------- | -------------------------------- |
| DB Tables | users, audit_logs                |
| UC Files  | BA/UC/Admin/UC022_ManageUsers.md |
