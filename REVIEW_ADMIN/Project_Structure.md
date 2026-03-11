# PROJECT STRUCTURE - ADMIN WEBSITE (HealthGuard)

> **Project**: HealthGuard Admin Dashboard  
> **Tech Stack**: Node.js / Express.js / Prisma ORM / JavaScript (Backend) + React / Vite / JavaScript (Frontend)  
> **Purpose**: Admin system management for HealthGuard  
> **Last Updated**: 2026-03-11 (CHECK Phase 1)

---

## Architecture Overview

```text
HealthGuard/
├── backend/                    # Admin Backend (Node.js + Express + Prisma)
│   ├── generated/
│   │   └── prisma/            # Prisma generated client
│   ├── prisma/                 # Prisma ORM schema (1 file: schema.prisma)
│   ├── src/
│   │   ├── __tests__/          # Unit tests
│   │   │   ├── controllers/   # auth.controller.test.js, user.controller.test.js, device.controller.test.js, logs.controller.test.js
│   │   │   ├── middlewares/   # auth.middleware.test.js, errorHandler.test.js, validate.test.js
│   │   │   ├── services/      # auth.service.test.js, user.service.test.js, device.service.test.js, emergency.service.test.js, logs.service.test.js, settings.service.test.js
│   │   │   └── utils/         # ApiError.test.js, ApiResponse.test.js, catchAsync.test.js
│   │   ├── config/             # env.js, swagger.js
│   │   ├── controllers/        # auth.controller.js, user.controller.js, device.controller.js, emergency.controller.js, logs.controller.js, settings.controller.js
│   │   ├── middlewares/        # auth.js, errorHandler.js, validate.js
│   │   ├── routes/             # auth.routes.js, index.js, user.routes.js, device.routes.js, emergency.routes.js, logs.routes.js, settings.routes.js
│   │   ├── services/           # auth.service.js, user.service.js, device.service.js, emergency.service.js, logs.service.js, settings.service.js
│   │   ├── utils/              # ApiError.js, ApiResponse.js, catchAsync.js, email.js, prisma.js
│   │   │   └── __mocks__/     # prisma.js (Jest mock)
│   │   ├── app.js              # Express app setup
│   │   └── server.js           # App entry point (port 5000)
│   ├── .env                    # Environment variables
│   ├── .env.example            # Environment template
│   ├── API_GUIDE.md            # API documentation guide
│   ├── package.json
│   ├── prisma.config.ts
│   └── test-user.txt           # Test user data
│
├── frontend/                   # Admin Frontend (React + Vite)
│   ├── public/                 # vite.svg
│   ├── src/
│   │   ├── assets/             # react.svg
│   │   ├── components/
│   │   │   ├── admin/          # AdminHeader.jsx, AdminLayout.jsx, AdminSidebar.jsx, ChangePasswordModal.jsx
│   │   │   ├── common/         # (empty)
│   │   │   ├── devices/        # AssignDeviceModal.jsx, DeviceFormModal.jsx, DevicesConstants.js, DevicesPagination.jsx, DevicesTable.jsx, DevicesToolbar.jsx, LockDeviceModal.jsx, UnassignDeviceModal.jsx
│   │   │   ├── emergency/      # EmergencyConstants.js, EmergencyDetailModal.jsx, EmergencyPagination.jsx, EmergencyStatusPrompt.jsx, EmergencySummaryBar.jsx, EmergencyTable.jsx, EmergencyToolbar.jsx
│   │   │   ├── logs/           # LogDetailModal.jsx, LogsConstants.js, LogsPagination.jsx, LogsTable.jsx, LogsToolbar.jsx
│   │   │   ├── settings/       # PasswordConfirmModal.jsx, SettingsConstants.js, SettingsForm.jsx
│   │   │   ├── ui/             # AlertModal.jsx, ConfirmModal.jsx, Modal.jsx
│   │   │   └── users/          # DeleteConfirmModal.jsx, LockConfirmModal.jsx, UserFormModal.jsx, UsersConstants.js, UsersPagination.jsx, UsersTable.jsx, UsersToolbar.jsx
│   │   ├── pages/
│   │   │   ├── ForgotPasswordPage.jsx
│   │   │   ├── LoginPage.jsx
│   │   │   ├── ResetPasswordPage.jsx
│   │   │   └── admin/          # AdminOverviewPage.jsx, UserManagementPage.jsx, DeviceManagementPage.jsx, DeviceManagementPageTest.jsx, EmergencyPage.jsx, SystemLogsPage.jsx, SystemSettingsPage.jsx
│   │   ├── services/           # api.js, authService.js, userService.js, deviceService.js, emergencyService.js, logsService.js
│   │   ├── App.css
│   │   ├── App.jsx
│   │   ├── index.css
│   │   └── main.jsx
│   ├── FRONTEND_DEV_GUIDE.md   # Frontend development guide
│   ├── README.md               # Frontend README
│   ├── index.html
│   ├── eslint.config.js
│   ├── vite.config.js
│   └── package.json
```

---

## Modules

### 1. [AUTH] Authentication & Authorization (Sprint 1)
> **SRS Ref**: UC001-UC004 | **JIRA**: EP04-Login, EP05-Register, EP12-Password

| Function         | API Endpoint                        | Status         | Note                                    |
| ---------------- | ----------------------------------- | -------------- | --------------------------------------- |
| Login (Admin)    | `POST /api/v1/auth/login`           | ✅ Reviewed     | JWT iss: `healthguard-admin`, expiry 8h |
| Get Current User | `GET /api/v1/auth/me`               | ⬜ Not reviewed | Require JWT, returns current user info  |
| Register (Admin) | `POST /api/v1/auth/register`        | ✅ Reviewed     | Require ADMIN JWT, `is_verified=true`   |
| Forgot Password  | `POST /api/v1/auth/forgot-password` | ⬜ Not reviewed | Token 15min, rate limit 3/15min         |
| Reset Password   | `POST /api/v1/auth/reset-password`  | ⬜ Not reviewed | Token one-time use                      |
| Change Password  | `PUT /api/v1/auth/password`         | ⬜ Not reviewed | Require JWT, rate limit 5/15min         |
| Logout           | `POST /api/v1/auth/logout`          | ⬜ Not reviewed | Require JWT                             |

**Files:**
- `backend/src/controllers/auth.controller.js` (4670 bytes)
- `backend/src/services/auth.service.js` (17969 bytes)
- `backend/src/middlewares/auth.js` (3502 bytes), `validate.js` (2553 bytes)
- `backend/src/routes/auth.routes.js` (2149 bytes)
- `backend/src/__tests__/controllers/auth.controller.test.js` (10085 bytes)
- `backend/src/__tests__/services/auth.service.test.js` (19007 bytes)
- `frontend/src/pages/LoginPage.jsx` (12954 bytes)
- `frontend/src/pages/ForgotPasswordPage.jsx` (9603 bytes)
- `frontend/src/pages/ResetPasswordPage.jsx` (14907 bytes)
- `frontend/src/components/admin/ChangePasswordModal.jsx` (12602 bytes)
- `frontend/src/services/authService.js` (3922 bytes)

---

### 2. [ADMIN_USERS] User Management (Sprint 4)
> **SRS Ref**: UC022 | **JIRA**: EP15-AdminManage

| Function    | API Endpoint                   | Status    | Note                                 |
| ----------- | ------------------------------ | --------- | ------------------------------------ |
| List users  | `GET /api/v1/users`            | ⬜ Pending | Search, filter, paginate             |
| Create user | `POST /api/v1/users`           | ⬜ Pending | ADMIN role only, validation rules    |
| User detail | `GET /api/v1/users/:id`        | ⬜ Pending |                                      |
| Update user | `PATCH /api/v1/users/:id`      | ⬜ Pending | full_name, phone, role               |
| Delete user | `DELETE /api/v1/users/:id`     | ⬜ Pending | Soft delete, requires admin password |
| Lock/Unlock | `PATCH /api/v1/users/:id/lock` | ⬜ Pending | Toggle lock                          |

**Files:**
- `backend/src/controllers/user.controller.js` (2839 bytes)
- `backend/src/services/user.service.js` (9426 bytes)
- `backend/src/routes/user.routes.js` (3874 bytes)
- `backend/src/__tests__/controllers/user.controller.test.js` (5847 bytes)
- `backend/src/__tests__/services/user.service.test.js` (14442 bytes)
- `frontend/src/pages/admin/UserManagementPage.jsx` (12418 bytes)
- `frontend/src/components/users/UserFormModal.jsx` (12955 bytes), `DeleteConfirmModal.jsx` (3785 bytes), `LockConfirmModal.jsx` (2576 bytes), `UsersConstants.js` (1598 bytes), `UsersPagination.jsx` (3911 bytes), `UsersTable.jsx` (9267 bytes), `UsersToolbar.jsx` (6730 bytes)
- `frontend/src/services/api.js` (613 bytes)
- `frontend/src/services/userService.js` (2290 bytes)

---

### 3. [DEVICES] Device Management (Sprint 4)
> **SRS Ref**: UC025 | **JIRA**: EP15-AdminManage
> **Status**: ✅ Built — controller, service, routes, tests, frontend all exist

| Function        | API Endpoint                         | Status    | Note                              |
| --------------- | ------------------------------------ | --------- | --------------------------------- |
| Create device   | `POST /api/v1/devices`               | ⬜ Pending | Auth+Admin, rate limit 100/min    |
| List devices    | `GET /api/v1/devices`                | ⬜ Pending | Paginated, auth required          |
| Device detail   | `GET /api/v1/devices/:id`            | ⬜ Pending |                                   |
| Update device   | `PATCH /api/v1/devices/:id`          | ⬜ Pending | name, type, model, firmware, cal. |
| Assign device   | `PATCH /api/v1/devices/:id/assign`   | ⬜ Pending | Requires userId in body           |
| Unassign device | `PATCH /api/v1/devices/:id/unassign` | ⬜ Pending |                                   |
| Lock/Unlock     | `PATCH /api/v1/devices/:id/lock`     | ⬜ Pending | Toggle lock                       |

**Files:**
- `backend/src/controllers/device.controller.js` (3101 bytes)
- `backend/src/services/device.service.js` (7781 bytes)
- `backend/src/routes/device.routes.js` (3174 bytes)
- `backend/src/__tests__/controllers/device.controller.test.js` (4258 bytes)
- `backend/src/__tests__/services/device.service.test.js` (9806 bytes)
- `frontend/src/pages/admin/DeviceManagementPage.jsx` (10887 bytes)
- `frontend/src/components/devices/AssignDeviceModal.jsx` (6841 bytes), `DeviceFormModal.jsx` (9403 bytes), `DevicesConstants.js` (1483 bytes), `DevicesPagination.jsx` (3450 bytes), `DevicesTable.jsx` (11054 bytes), `DevicesToolbar.jsx` (3699 bytes), `LockDeviceModal.jsx` (845 bytes), `UnassignDeviceModal.jsx` (685 bytes)
- `frontend/src/services/deviceService.js` (2374 bytes)

---

### 4. [CONFIG] System Configuration (Sprint 4)
> **SRS Ref**: UC024 | **JIRA**: EP16-AdminConfig
> **Status**: ✅ Built — controller, service, routes, tests, frontend all exist

| Function        | API Endpoint             | Status    | Note                            |
| --------------- | ------------------------ | --------- | ------------------------------- |
| Get settings    | `GET /api/v1/settings`   | ⬜ Pending | Vital thresholds, AI config     |
| Update settings | `PUT /api/v1/settings`   | ⬜ Pending | Requires admin password + body  |

**Files:**
- `backend/src/controllers/settings.controller.js` (920 bytes)
- `backend/src/services/settings.service.js` (3750 bytes)
- `backend/src/routes/settings.routes.js` (849 bytes)
- `backend/src/__tests__/services/settings.service.test.js` (4950 bytes)
- `frontend/src/pages/admin/SystemSettingsPage.jsx` (5155 bytes)
- `frontend/src/components/settings/PasswordConfirmModal.jsx` (3504 bytes), `SettingsConstants.js` (2641 bytes), `SettingsForm.jsx` (9454 bytes)

---

### 5. [LOGS] System Logs (Sprint 4)
> **SRS Ref**: UC026 | **JIRA**: EP16-AdminConfig
> **Status**: ✅ Built — controller, service, routes, tests, frontend all exist

| Function    | API Endpoint                    | Status    | Note                        |
| ----------- | ------------------------------- | --------- | --------------------------- |
| View logs   | `GET /api/v1/logs`              | ⬜ Pending | Filter, paginate, validate  |
| Log detail  | `GET /api/v1/logs/:id`          | ⬜ Pending |                             |
| Export CSV  | `GET /api/v1/logs/export/csv`   | ⬜ Pending | With same filter validation |
| Export JSON | `GET /api/v1/logs/export/json`  | ⬜ Pending | With same filter validation |

**Files:**
- `backend/src/controllers/logs.controller.js` (2996 bytes)
- `backend/src/services/logs.service.js` (6256 bytes)
- `backend/src/routes/logs.routes.js` (2491 bytes)
- `backend/src/__tests__/controllers/logs.controller.test.js` (5925 bytes)
- `backend/src/__tests__/services/logs.service.test.js` (11724 bytes)
- `frontend/src/pages/admin/SystemLogsPage.jsx` (7948 bytes)
- `frontend/src/components/logs/LogDetailModal.jsx` (6217 bytes), `LogsConstants.js` (555 bytes), `LogsPagination.jsx` (3908 bytes), `LogsTable.jsx` (9277 bytes), `LogsToolbar.jsx` (7427 bytes)
- `frontend/src/services/logsService.js` (4039 bytes)

---

### 6. [INFRA] Infrastructure Setup (Sprint 1)
> **SRS Ref**: N/A | **JIRA**: EP01-Database, EP02-AdminBE

| Function                     | Status         | Note                              |
| ---------------------------- | -------------- | --------------------------------- |
| Database + TimescaleDB setup | ⬜ Not reviewed | SQL SCRIPTS/ is source of truth   |
| Express + JavaScript project | ✅ Built        | Prisma ORM, port 5000             |
| CORS middleware              | ✅ Built        | Using cors() globally             |
| Logging (file + console)     | ⬜ Not reviewed |                                   |
| Environment variables        | ✅ Built        | .env present                      |
| Health check endpoint        | ✅ Built        | `GET /api/v1/health`              |
| Swagger docs                 | ✅ Built        | `/api-docs` — swagger-ui-express  |
| Unit tests (Jest)            | ✅ Built        | 16 test files in `src/__tests__/` |

**Files:**
- `backend/src/app.js` (1287 bytes)
- `backend/src/server.js` (296 bytes)
- `backend/src/config/env.js` (1094 bytes)
- `backend/src/config/swagger.js` (41534 bytes)
- `backend/src/utils/prisma.js` (447 bytes)
- `backend/src/utils/ApiError.js` (1523 bytes)
- `backend/src/utils/ApiResponse.js` (1596 bytes)
- `backend/src/utils/catchAsync.js` (447 bytes)
- `backend/src/utils/email.js` (4274 bytes)
- `backend/src/utils/__mocks__/prisma.js` (218 bytes)
- `backend/src/middlewares/errorHandler.js` (1660 bytes), `validate.js` (2553 bytes)
- `backend/prisma/schema.prisma` (22588 bytes)
- `backend/API_GUIDE.md` (11161 bytes)

---

### 7. [EMERGENCY] Emergency Management (Sprint 3-4)
> **SRS Ref**: UC010-UC015 (mapped from Mobile Emergency) | **JIRA**: EP09-FallDetect, EP10-SOS
> **Status**: ✅ Reviewed — Full implementation complete with Export, Filter, and Audit

| Function       | API Endpoint                         | Status      | Note                               |
| -------------- | ------------------------------------ | ----------- | ---------------------------------- |
| Summary        | `GET /api/v1/emergencies/summary`    | ✅ Reviewed | Dashboard summary data             |
| Active events  | `GET /api/v1/emergencies/active`     | ✅ Reviewed | Currently active emergencies       |
| History events | `GET /api/v1/emergencies/history`    | ✅ Reviewed | Past events + date range filter    |
| Export CSV     | `GET /api/v1/emergencies/export/csv` | ✅ Reviewed | Export with filters (BR-029-05)    |
| Export JSON    | `GET /api/v1/emergencies/export/json`| ✅ Reviewed | Export with filters (BR-029-05)    |
| Event details  | `GET /api/v1/emergencies/:id`        | ✅ Reviewed | Refactored with timeline & vitals |
| Update status  | `PATCH /api/v1/emergencies/:id/status`| ✅ Reviewed | PATCH per REST conventions        |
| Log contact    | `POST /api/v1/emergencies/:id/contact`| ✅ Reviewed | Log notification to contacts       |

**Files:**
- `backend/src/controllers/emergency.controller.js` (3509 bytes)
- `backend/src/services/emergency.service.js` (11732 bytes)
- `backend/src/routes/emergency.routes.js` (3501 bytes)
- `backend/src/__tests__/services/emergency.service.test.js` (8528 bytes)
- `frontend/src/pages/admin/EmergencyPage.jsx` (11671 bytes)
- `frontend/src/components/emergency/EmergencyConstants.js` (781 bytes), `EmergencyDetailModal.jsx` (12329 bytes), `EmergencyPagination.jsx` (1964 bytes), `EmergencyStatusPrompt.jsx` (3460 bytes), `EmergencySummaryBar.jsx` (2496 bytes), `EmergencyTable.jsx` (5673 bytes), `EmergencyToolbar.jsx` (5383 bytes)
- `frontend/src/services/emergencyService.js` (2977 bytes)

---

## Update History

| Date       | Version | Changes                                                                                                                                                                                                                                               |
| ---------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-03-11 | v2.8    | CHECK scan: Update EMERGENCY module (UC029 full implementation), updated 9 file sizes, added Export CSV/JSON endpoints, changed PUT→PATCH for status, added DeviceManagementPageTest.jsx |
| 2026-03-11 | v2.7    | CHECK scan: +EMERGENCY module (#7), DEVICES/CONFIG/LOGS now ✅ Built, +device/emergency/logs/settings controllers+services+routes+tests, +8 device components, +7 emergency components, +5 logs components, +3 settings components, +3 frontend services, +5 admin pages, 16 test files, updated all byte sizes |
| 2026-03-08 | v2.6    | CHECK scan: updated byte sizes for auth.controller.js, user.service.js, schema.prisma                                                                                                                                                                 |
| 2026-03-08 | v2.5    | CHECK scan: split UserManagementPage into components, updated file sizes, `validate.js` size updated                                                                                                                                                  |
| 2026-03-08 | v2.4    | CHECK scan: corrected API prefix /api/v1/, Users PATCH not PUT, +userService.js, +__mocks__, +logout endpoint, expanded __tests__ (10 files), removed seed-test-data.js, +API_GUIDE.md, +test-user.txt, updated 12 file sizes, +AdminOverviewPage.jsx |
| 2026-03-08 | v2.3    | CHECK scan: corrected paths, extensions to JS/JSX, added test files, updated LOC and file sizes                                                                                                                                                       |
| 2026-03-07 | v2.2    | CHECK scan: +generated/, +scripts/, +validators.ts, +frontend utils/assets, +GET /me, byte sizes                                                                                                                                                      |
| 2026-03-07 | v2.1    | CHECK scan: updated byte sizes, verified endpoints                                                                                                                                                                                                    |
| 2026-03-05 | v2.0    | CHECK scan: actual folder structure, routes corrected, Trello→JIRA                                                                                                                                                                                    |
| 2026-03-03 | v1.0    | Initial structure based on Sprint 1-4 planning                                                                                                                                                                                                        |
