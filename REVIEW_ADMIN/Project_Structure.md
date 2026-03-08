# PROJECT STRUCTURE - ADMIN WEBSITE (HealthGuard)

> **Project**: HealthGuard Admin Dashboard  
> **Tech Stack**: Node.js / Express.js / Prisma ORM / JavaScript (Backend) + React / Vite / JavaScript (Frontend)  
> **Purpose**: Admin system management for HealthGuard  
> **Last Updated**: 2026-03-08 (CHECK Phase 1)

---

## Architecture Overview

```text
HealthGuard/
├── backend/                    # Admin Backend (Node.js + Express + Prisma)
│   ├── prisma/                 # Prisma ORM schema (1 file: schema.prisma)
│   ├── src/
│   │   ├── __tests__/          # Unit tests (controllers, middlewares, services, utils)
│   │   ├── config/             # env.js, swagger.js
│   │   ├── controllers/        # auth.controller.js, user.controller.js
│   │   ├── middlewares/        # auth.js, errorHandler.js, validate.js
│   │   ├── routes/             # auth.routes.js, index.js, user.routes.js
│   │   ├── services/           # auth.service.js, user.service.js
│   │   ├── utils/              # ApiError.js, ApiResponse.js, catchAsync.js, email.js, prisma.js
│   │   ├── app.js              # Express app setup
│   │   └── server.js           # App entry point (port 5000)
│   ├── .env                    # Environment variables
│   ├── package.json
│   ├── prisma.config.ts
│   └── seed-test-data.js       # Test data seeding
│
├── frontend/                   # Admin Frontend (React + Vite)
│   ├── public/                 # vite.svg
│   ├── src/
│   │   ├── assets/             # react.svg
│   │   ├── components/
│   │   │   ├── admin/          # AdminHeader.jsx, AdminLayout.jsx, AdminSidebar.jsx, ChangePasswordModal.jsx
│   │   │   ├── ui/             # AlertModal.jsx, ConfirmModal.jsx, Modal.jsx
│   │   │   └── users/          # DeleteConfirmModal.jsx, LockConfirmModal.jsx, UserFormModal.jsx
│   │   ├── pages/
│   │   │   ├── ForgotPasswordPage.jsx
│   │   │   ├── LoginPage.jsx
│   │   │   ├── ResetPasswordPage.jsx
│   │   │   └── admin/          # AdminOverviewPage.jsx, UserManagementPage.jsx
│   │   ├── services/           # api.js, authService.js
│   │   ├── App.css
│   │   ├── App.jsx
│   │   ├── index.css
│   │   └── main.jsx
│   ├── index.html
│   ├── eslint.config.js
│   ├── vite.config.js
│   └── package.json
│
└── package.json                # Root package.json (workspaces)
```

---

## Modules

### 1. [AUTH] Authentication & Authorization (Sprint 1)
> **SRS Ref**: UC001-UC004 | **JIRA**: EP04-Login, EP05-Register, EP12-Password

| Function         | API Endpoint                     | Status         | Note                                    |
| ---------------- | -------------------------------- | -------------- | --------------------------------------- |
| Login (Admin)    | `POST /api/auth/sessions`        | ✅ Reviewed     | JWT iss: `healthguard-admin`, expiry 8h |
| Get Current User | `GET /api/auth/me`               | ⬜ Not reviewed | Require JWT, returns current user info  |
| Register (Admin) | `POST /api/auth/users`           | ✅ Reviewed     | Require ADMIN JWT, `is_verified=true`   |
| Verify Email     | `POST /api/auth/email/verify`    | ⬜ Not reviewed | Email verification token                |
| Resend Verify    | `POST /api/auth/email/resend`    | ⬜ Not reviewed | Resend verification email               |
| Forgot Password  | `POST /api/auth/password/forgot` | ⬜ Not reviewed | Token 15min, rate limit 3/15min         |
| Reset Password   | `POST /api/auth/password/reset`  | ⬜ Not reviewed | Token one-time use                      |
| Change Password  | `PUT /api/auth/password`         | ⬜ Not reviewed | Require JWT, rate limit 5/15min         |

**Files:**
- `backend/src/controllers/auth.controller.js` (4009 bytes)
- `backend/src/services/auth.service.js` (15731 bytes)
- `backend/src/middlewares/auth.js` (3502 bytes), `validate.js` (1942 bytes)
- `backend/src/routes/auth.routes.js` (2149 bytes)
- `frontend/src/pages/LoginPage.jsx` (12326 bytes)
- `frontend/src/pages/ForgotPasswordPage.jsx` (9603 bytes)
- `frontend/src/pages/ResetPasswordPage.jsx` (14907 bytes)
- `frontend/src/components/admin/ChangePasswordModal.jsx` (12602 bytes)
- `frontend/src/services/authService.js` (3922 bytes)

---

### 2. [ADMIN_USERS] User Management (Sprint 4)
> **SRS Ref**: UC022 | **JIRA**: EP15-AdminManage

| Function    | API Endpoint                 | Status    | Note                                 |
| ----------- | ---------------------------- | --------- | ------------------------------------ |
| List users  | `GET /api/users`             | ⬜ Pending | Search, filter, paginate             |
| Create user | `POST /api/users`            | ⬜ Pending | ADMIN role only                      |
| User detail | `GET /api/users/{id}`        | ⬜ Pending |                                      |
| Update user | `PUT /api/users/{id}`        | ⬜ Pending |                                      |
| Delete user | `DELETE /api/users/{id}`     | ⬜ Pending | Soft delete, requires admin password |
| Lock/Unlock | `PATCH /api/users/{id}/lock` | ⬜ Pending | Toggle, audit log                    |

**Files:**
- `backend/src/controllers/user.controller.js` (1746 bytes)
- `backend/src/services/user.service.js` (2426 bytes)
- `backend/src/routes/user.routes.js` (1348 bytes)
- `frontend/src/pages/admin/UserManagementPage.jsx` (23889 bytes)
- `frontend/src/components/users/UserFormModal.jsx` (12955 bytes), `DeleteConfirmModal.jsx` (3785 bytes), `LockConfirmModal.jsx` (2576 bytes)
- `frontend/src/services/api.js` (613 bytes)

---

### 3. [DEVICES] Device Management (Sprint 4)
> **SRS Ref**: UC025 | **JIRA**: EP15-AdminManage
> **Status**: ⬜ Not built — no controller/service/route exists yet

| Function      | API Endpoint                          | Status    | Note |
| ------------- | ------------------------------------- | --------- | ---- |
| List devices  | `GET /api/admin/devices`              | ⬜ Planned |      |
| Device detail | `GET /api/admin/devices/{id}`         | ⬜ Planned |      |
| Update device | `PUT /api/admin/devices/{id}`         | ⬜ Planned |      |
| Assign device | `POST /api/admin/devices/{id}/assign` | ⬜ Planned |      |
| Lock device   | `POST /api/admin/devices/{id}/lock`   | ⬜ Planned |      |

---

### 4. [CONFIG] System Configuration (Sprint 4)
> **SRS Ref**: UC024 | **JIRA**: EP16-AdminConfig
> **Status**: ⬜ Not built — no controller/service/route exists yet

| Function        | API Endpoint              | Status    | Note                        |
| --------------- | ------------------------- | --------- | --------------------------- |
| Get settings    | `GET /api/admin/settings` | ⬜ Planned | Vital thresholds, AI config |
| Update settings | `PUT /api/admin/settings` | ⬜ Planned | Cache on startup            |

---

### 5. [LOGS] System Logs (Sprint 4)
> **SRS Ref**: UC026 | **JIRA**: EP16-AdminConfig
> **Status**: ⬜ Not built — no controller/service/route exists yet

| Function   | API Endpoint                 | Status    | Note             |
| ---------- | ---------------------------- | --------- | ---------------- |
| View logs  | `GET /api/admin/logs`        | ⬜ Planned | Filter, paginate |
| Export CSV | `GET /api/admin/logs/export` | ⬜ Planned |                  |

---

### 6. [INFRA] Infrastructure Setup (Sprint 1)
> **SRS Ref**: N/A | **JIRA**: EP01-Database, EP02-AdminBE

| Function                     | Status         | Note                             |
| ---------------------------- | -------------- | -------------------------------- |
| Database + TimescaleDB setup | ⬜ Not reviewed | SQL SCRIPTS/ is source of truth  |
| Express + JavaScript project | ✅ Built        | Prisma ORM, port 5000            |
| CORS middleware              | ✅ Built        | Using cors() globally            |
| Logging (file + console)     | ⬜ Not reviewed |                                  |
| Environment variables        | ✅ Built        | .env present                     |
| Health check endpoint        | ✅ Built        | `GET /api/health`                |
| Swagger docs                 | ✅ Built        | `/api-docs` — swagger-ui-express |

**Files:**
- `backend/src/app.js` (879 bytes)
- `backend/src/server.js` (296 bytes)
- `backend/src/config/swagger.js` (6975 bytes)
- `backend/src/utils/prisma.js` (447 bytes)
- `backend/src/middlewares/errorHandler.js` (1660 bytes), `validate.js` (1942 bytes)
- `backend/prisma/schema.prisma`
- `backend/seed-test-data.js` (14273 bytes)

---

## Update History

| Date       | Version | Changes                                                                                          |
| ---------- | ------- | ------------------------------------------------------------------------------------------------ |
| 2026-03-08 | v2.3    | CHECK scan: corrected paths, extensions to JS/JSX, added test files, updated LOC and file sizes  |
| 2026-03-07 | v2.2    | CHECK scan: +generated/, +scripts/, +validators.ts, +frontend utils/assets, +GET /me, byte sizes |
| 2026-03-07 | v2.1    | CHECK scan: updated byte sizes, verified endpoints                                               |
| 2026-03-05 | v2.0    | CHECK scan: actual folder structure, routes corrected, Trello→JIRA                               |
| 2026-03-03 | v1.0    | Initial structure based on Sprint 1-4 planning                                                   |
