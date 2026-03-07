# ADMIN_USERS (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC022

## Purpose & Technique
- Admin can manage all system users: list (search/filter/paginate), create, view detail, update, soft-delete, lock/unlock
- All mutations require ADMIN JWT; soft-delete requires admin password confirmation; lock is toggle (cannot lock self)
- All admin actions logged to `audit_logs` table

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
| backend/src/controllers/userController.ts            | All user route handlers (14986B)      |
| backend/src/services/userService.ts                  | User CRUD + lock logic (11339B)       |
| backend/src/routes/userRoutes.ts                     | Route definitions (647B)              |
| frontend/src/pages/admin/UserManagementPage.tsx      | User management UI page (15090B)      |
| frontend/src/components/users/UserTable.tsx          | Table with search/pagination (10809B) |
| frontend/src/components/users/UserFormModal.tsx      | Add/Edit user modal (21000B)          |
| frontend/src/components/users/DeleteConfirmModal.tsx | Delete confirmation (4477B)           |
| frontend/src/components/users/LockConfirmModal.tsx   | Lock confirmation modal (3186B)       |
| frontend/src/services/userService.ts                 | Frontend user API calls (2589B)       |
| frontend/src/types/user.ts                           | User TypeScript types (1881B)         |

## Cross-References
| Type      | Ref                              |
| --------- | -------------------------------- |
| DB Tables | users, audit_logs                |
| UC Files  | BA/UC/Admin/UC022_ManageUsers.md |
