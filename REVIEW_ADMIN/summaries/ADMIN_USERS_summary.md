# 🔬 MODULE SUMMARY: ADMIN_USERS (Admin)

> **Module**: ADMIN_USERS — User Management  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4, Card 5  
> **UC References**: UC022

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Admin can manage all users in the system (CRUD + Lock/Unlock)
- Search, filter, and paginate user list
- Soft delete (not hard delete)
- All admin actions must be logged to `audit_logs`
- Only ADMIN role can access user management

### Non-Functional Requirements
- **Security**: ADMIN role-only access, audit trail for all mutations
- **Usability**: Dashboard with table view, search, filters, pagination

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 5 — Manage Users (Admin BE Dev)
- [ ] `GET /api/admin/users` — list, search, filter, paginate
- [ ] `POST /api/admin/users` — create user
- [ ] `GET /api/admin/users/{id}` — user detail
- [ ] `PUT /api/admin/users/{id}` — update user
- [ ] `DELETE /api/admin/users/{id}` — soft delete
- [ ] `POST /api/admin/users/{id}/lock` — lock/unlock user
- [ ] Permission check: ADMIN role only
- [ ] Audit log: record all actions

### Card 5 — Manage Users (Admin FE Dev)
- [ ] "Manage Users" page: table with search, filters, pagination
- [ ] Add/Edit user modals
- [ ] Delete confirmation dialog
- [ ] Lock/Unlock toggle

### Acceptance Criteria
- [ ] CRUD operations work correctly
- [ ] Search/filter/pagination functional
- [ ] Permission enforced (ADMIN only)
- [ ] Audit logs generated for all mutations

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/src/`)
| File Path | Role |
|-----------|------|
| `controllers/user.controller.ts` | Route handlers for user CRUD |
| `services/user.service.ts` | Business logic for user management |
| `middleware/auth.middleware.ts` | JWT + role check (shared with AUTH) |

### Frontend (`HealthGuard/frontend/src/`)
| File Path | Role |
|-----------|------|
| `pages/ManageUsers.tsx` | User management page |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §2.3 (User types), §4.1 (Actors — Admin role) |
| Use Case Files | `BA/UC/Admin/UC022_ManageUsers.md` |
| DB Tables | `users`, `audit_logs` |
| Trello | Sprint 4, Card 5 |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
