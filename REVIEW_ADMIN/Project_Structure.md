# PROJECT STRUCTURE - ADMIN WEBSITE (HealthGuard)

> **Project**: HealthGuard Admin Dashboard  
> **Tech Stack**: Node.js / Express.js / Prisma ORM / TypeScript (Backend) + React / Vite / TypeScript (Frontend)  
> **Purpose**: Admin system management for HealthGuard  
> **Last Updated**: 2026-03-07

---

## Architecture Overview

```
HealthGuard/
├── backend/                    # Admin Backend (Node.js + Express + Prisma)
│   ├── prisma/                 # Prisma ORM schema (1 file: schema.prisma)
│   ├── src/
│   │   ├── config/             # swagger.ts — Swagger spec config
│   │   ├── controllers/        # authController.ts, userController.ts
│   │   ├── lib/                # prisma.ts — Prisma client singleton
│   │   ├── middleware/         # authMiddleware.ts, rateLimiter.ts
│   │   ├── routes/             # authRoutes.ts, userRoutes.ts
│   │   ├── services/           # 7 service files (see AUTH module)
│   │   ├── utils/              # jwt.ts — JWT helper
│   │   └── index.ts            # App entry point (port 5000)
│   ├── .env                    # DB_URL, JWT_SECRET, PORT, SMTP config
│   ├── package.json
│   ├── prisma.config.ts
│   └── tsconfig.json
│
├── frontend/                   # Admin Frontend (React + Vite)
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── admin/          # AdminHeader.tsx, AdminLayout.tsx, AdminSidebar.tsx
│   │   │   ├── ui/             # HighlightText.tsx, Modal.tsx, Toast.tsx
│   │   │   └── users/          # UserTable.tsx, UserFormModal.tsx, DeleteConfirmModal.tsx, LockConfirmModal.tsx
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   ├── DashboardPage.tsx
│   │   │   └── admin/
│   │   │       ├── AdminOverviewPage.tsx
│   │   │       └── UserManagementPage.tsx
│   │   ├── services/           # api.ts, authService.ts, userService.ts
│   │   ├── types/              # auth.ts, user.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── index.html
│   ├── vite.config.ts
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
| Register (Admin) | `POST /api/auth/users`           | ✅ Reviewed     | Require ADMIN JWT, `is_verified=true`   |
| Verify Email     | `POST /api/auth/email/verify`    | ⬜ Not reviewed | Email verification token                |
| Resend Verify    | `POST /api/auth/email/resend`    | ⬜ Not reviewed | Resend verification email               |
| Forgot Password  | `POST /api/auth/password/forgot` | ⬜ Not reviewed | Token 15min, rate limit 3/15min         |
| Reset Password   | `POST /api/auth/password/reset`  | ⬜ Not reviewed | Token one-time use                      |
| Change Password  | `PUT /api/auth/password`         | ⬜ Not reviewed | Require JWT, rate limit 5/15min         |

**Files:**
- `backend/src/controllers/authController.ts` (34127 bytes)
- `backend/src/services/authService.ts`, `registerService.ts`, `changePasswordService.ts`, `passwordResetService.ts`, `emailService.ts`, `verifyEmailService.ts`
- `backend/src/middleware/authMiddleware.ts`, `rateLimiter.ts`
- `frontend/src/pages/LoginPage.tsx` (13071 bytes)
- `frontend/src/services/authService.ts`

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
- `backend/src/controllers/userController.ts` (14986 bytes)
- `backend/src/services/userService.ts` (11339 bytes)
- `backend/src/routes/userRoutes.ts`
- `frontend/src/pages/admin/UserManagementPage.tsx` (15090 bytes)
- `frontend/src/components/users/UserTable.tsx`, `UserFormModal.tsx`, `DeleteConfirmModal.tsx`, `LockConfirmModal.tsx`
- `frontend/src/services/userService.ts`

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
| Express + TypeScript project | ✅ Built        | Prisma ORM, port 5000            |
| CORS middleware              | ✅ Built        | Using cors() globally            |
| Logging (file + console)     | ⬜ Not reviewed |                                  |
| Environment variables        | ✅ Built        | .env present                     |
| Health check endpoint        | ✅ Built        | `GET /api/health`                |
| Swagger docs                 | ✅ Built        | `/api-docs` — swagger-ui-express |

**Files:**
- `backend/src/index.ts` (993 bytes)
- `backend/src/config/swagger.ts` (3287 bytes)
- `backend/src/lib/prisma.ts` (621 bytes)
- `backend/src/utils/jwt.ts` (502 bytes)
- `backend/src/middleware/authMiddleware.ts`, `rateLimiter.ts`
- `backend/prisma/` (schema.prisma)

---

## Update History

| Date       | Version | Changes                                                            |
| ---------- | ------- | ------------------------------------------------------------------ |
| 2026-03-07 | v2.1    | CHECK scan: updated byte sizes, verified endpoints                 |
| 2026-03-05 | v2.0    | CHECK scan: actual folder structure, routes corrected, Trello→JIRA |
| 2026-03-03 | v1.0    | Initial structure based on Sprint 1-4 planning                     |
