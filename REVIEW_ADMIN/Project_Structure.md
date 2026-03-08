# PROJECT STRUCTURE - ADMIN WEBSITE (HealthGuard)

> **Project**: HealthGuard Admin Dashboard  
> **Tech Stack**: Node.js / Express.js / Prisma ORM / JavaScript (Backend) + React / Vite / JavaScript (Frontend)  
> **Purpose**: Admin system management for HealthGuard  
> **Last Updated**: 2026-03-08 (CHECK v2.4)

---

## Architecture Overview

```
HealthGuard/
├── backend/                    # Admin Backend (Node.js + Express + Prisma)
│   ├── prisma/                 # Prisma ORM schema
│   ├── src/
│   │   ├── __tests__/          # Test files
│   │   ├── config/             # Configuration files
│   │   ├── controllers/        # auth.controller.js, user.controller.js
│   │   ├── middlewares/        # Auth and rate limit middlewares
│   │   ├── routes/             # auth.routes.js, user.routes.js, index.js
│   │   ├── services/           # auth.service.js, user.service.js
│   │   ├── utils/              # Utility functions
│   │   ├── app.js              # Express app setup
│   │   └── server.js           # App entry point
│   ├── .env
│   ├── .env.example
│   ├── API_GUIDE.md
│   ├── package-lock.json
│   ├── package.json
│   ├── prisma.config.ts
│   └── test-user.txt
│
├── frontend/                   # Admin Frontend (React + Vite)
│   ├── public/
│   ├── src/
│   │   ├── assets/             # Static assets
│   │   ├── components/         # React components
│   │   ├── pages/
│   │   │   ├── admin/          # AdminOverviewPage.jsx, UserManagementPage.jsx
│   │   │   ├── ForgotPasswordPage.jsx
│   │   │   ├── LoginPage.jsx
│   │   │   └── ResetPasswordPage.jsx
│   │   ├── services/           # api.js, authService.js
│   │   ├── App.css
│   │   ├── App.jsx
│   │   ├── index.css
│   │   └── main.jsx
│   ├── eslint.config.js
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
│
└── package.json                # Root package.json
```

---

## Modules

### 1. [AUTH] Authentication & Authorization (Sprint 1)
> **SRS Ref**: UC001-UC004 | **JIRA**: EP04-Login, EP05-Register, EP12-Password

| Function         | API Endpoint                 | Status         | Note                                   |
| ---------------- | ---------------------------- | -------------- | -------------------------------------- |
| Login (Admin)    | `POST /auth/login`           | ✅ Reviewed     | JWT login                              |
| Get Current User | `GET /auth/me`               | ⬜ Not reviewed | Require JWT, returns current user info |
| Register (Admin) | `POST /auth/register`        | ✅ Reviewed     | Require ADMIN JWT                      |
| Forgot Password  | `POST /auth/forgot-password` | ⬜ Not reviewed | Send reset token                       |
| Reset Password   | `POST /auth/reset-password`  | ⬜ Not reviewed | Token one-time use                     |
| Change Password  | `PUT /auth/password`         | ⬜ Not reviewed | Require JWT                            |
| Logout           | `POST /auth/logout`          | ⬜ Not reviewed | Logout                                 |

**Files:**
- `backend/src/controllers/auth.controller.js` (4009 bytes)
- `backend/src/services/auth.service.js` (16902 bytes)
- `backend/src/routes/auth.routes.js` (2149 bytes)
- `frontend/src/pages/LoginPage.jsx` (12326 bytes)
- `frontend/src/pages/ForgotPasswordPage.jsx` (9603 bytes)
- `frontend/src/pages/ResetPasswordPage.jsx` (14907 bytes)
- `frontend/src/services/authService.js` (3922 bytes)

---

### 2. [ADMIN_USERS] User Management (Sprint 4)
> **SRS Ref**: UC022 | **JIRA**: EP15-AdminManage

| Function     | API Endpoint        | Status    | Note                     |
| ------------ | ------------------- | --------- | ------------------------ |
| List users   | `GET /users/`       | ⬜ Pending | Search, filter, paginate |
| Create user  | `POST /users/`      | ⬜ Pending | ADMIN role only          |
| User detail  | `GET /users/:id`    | ⬜ Pending |                          |
| Replace user | `PUT /users/:id`    | ⬜ Pending | Replace entire user data |
| Update user  | `PATCH /users/:id`  | ⬜ Pending | Partial update           |
| Delete user  | `DELETE /users/:id` | ⬜ Pending | Soft delete              |

**Files:**
- `backend/src/controllers/user.controller.js` (1746 bytes)
- `backend/src/services/user.service.js` (2426 bytes)
- `backend/src/routes/user.routes.js` (1348 bytes)
- `frontend/src/pages/admin/UserManagementPage.jsx` (23889 bytes)

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

| Function                     | Status         | Note                            |
| ---------------------------- | -------------- | ------------------------------- |
| Database + TimescaleDB setup | ⬜ Not reviewed | SQL SCRIPTS/ is source of truth |
| Express + JavaScript project | ✅ Built        | Prisma ORM, Nodemon             |
| Routes & Middlewares         | ✅ Built        | Configured in app.js            |
| Environment variables        | ✅ Built        | .env present                    |
| Health check endpoint        | ✅ Built        | `GET /health`                   |

**Files:**
- `backend/src/server.js` (296 bytes)
- `backend/src/app.js` (879 bytes)
- `backend/src/routes/index.js` (649 bytes)

---

## Update History

| Date       | Version | Changes                                                                                           |
| ---------- | ------- | ------------------------------------------------------------------------------------------------- |
| 2026-03-08 | v2.4    | CHECK scan: Migrated to JS, refactored backend structure, frontend JSX extensions, updated routes |
| 2026-03-07 | v2.2    | CHECK scan: +generated/, +scripts/, +validators.ts, +frontend utils/assets, +GET /me, byte sizes  |
| 2026-03-07 | v2.1    | CHECK scan: updated byte sizes, verified endpoints                                                |
| 2026-03-05 | v2.0    | CHECK scan: actual folder structure, routes corrected, Trello→JIRA                                |
| 2026-03-03 | v1.0    | Initial structure based on Sprint 1-4 planning                                                    |
