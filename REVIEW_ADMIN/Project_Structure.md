# 📋 PROJECT STRUCTURE - ADMIN WEBSITE (HealthGuard)

> **Dự án**: HealthGuard Admin Dashboard  
> **Tech Stack**: Node.js / Express.js / Prisma ORM / TypeScript (Backend) + React / Vite / TypeScript (Frontend)  
> **Mục đích**: Quản trị hệ thống HealthGuard cho Admin  
> **Cập nhật lần cuối**: 03/03/2026

---

## 🏗️ Tổng Quan Kiến Trúc

```
HealthGuard/
├── backend/                    # Admin Backend (Node.js + Express + Prisma)
│   ├── prisma/                 # Prisma ORM schema
│   ├── src/
│   │   ├── config/             # Database, environment config
│   │   ├── controllers/        # Route handlers
│   │   ├── lib/                # Shared libraries
│   │   ├── middleware/         # Auth, CORS, error handling middleware
│   │   ├── routes/             # Express route definitions
│   │   ├── services/           # Business logic layer
│   │   ├── utils/              # Helper functions
│   │   └── index.ts            # App entry point
│   ├── package.json
│   └── tsconfig.json
│
├── frontend/                   # Admin Frontend (React + Vite)
│   ├── public/
│   ├── src/
│   │   ├── components/         # Reusable UI components
│   │   ├── pages/              # Page components
│   │   ├── services/           # API service calls
│   │   ├── hooks/              # Custom React hooks
│   │   ├── utils/              # Frontend utilities
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── index.html
│   ├── vite.config.ts
│   └── package.json
│
└── package.json                # Root package.json (workspaces)
```

---

## 🔧 Chức Năng Theo Module

### 1. [AUTH] Xác thực & Phân quyền (Sprint 1)
> **SRS Ref**: UC001-UC004 | **Trello**: Sprint 1 - Cards 3, 4, 5, 6

| Chức năng            | API Endpoint                     | Trạng thái      | Ghi chú                                    |
| -------------------- | -------------------------------- | --------------- | ------------------------------------------ |
| Login (Admin)        | `POST /api/auth/login`           | ⬜ Chưa đánh giá | JWT issuer: `healthguard-admin`, expiry 8h |
| Tạo user (bởi Admin) | `POST /api/users`                | ⬜ Chưa đánh giá | Require ADMIN JWT, `is_verified=true`      |
| Forgot Password      | `POST /api/auth/forgot-password` | ⬜ Chưa đánh giá | Token 15 phút, rate limit 3/15min          |
| Reset Password       | `POST /api/auth/reset-password`  | ⬜ Chưa đánh giá | Token one-time use                         |
| Change Password      | `POST /api/auth/change-password` | ⬜ Chưa đánh giá | Require JWT, rate limit 5/15min            |

**Files liên quan**:
- `backend/src/controllers/auth.controller.ts`
- `backend/src/services/auth.service.ts`
- `backend/src/middleware/auth.middleware.ts`
- `frontend/src/pages/Login.tsx`
- `frontend/src/pages/ForgotPassword.tsx`

---

### 2. [ADMIN] Quản lý Users (Sprint 4)
> **SRS Ref**: UC022 | **Trello**: Sprint 4 - Card 5

| Chức năng   | API Endpoint                      | Trạng thái      | Ghi chú                  |
| ----------- | --------------------------------- | --------------- | ------------------------ |
| List users  | `GET /api/admin/users`            | ⬜ Chưa đánh giá | Search, filter, paginate |
| Create user | `POST /api/admin/users`           | ⬜ Chưa đánh giá | ADMIN role only          |
| User detail | `GET /api/admin/users/{id}`       | ⬜ Chưa đánh giá |                          |
| Update user | `PUT /api/admin/users/{id}`       | ⬜ Chưa đánh giá |                          |
| Delete user | `DELETE /api/admin/users/{id}`    | ⬜ Chưa đánh giá | Soft delete              |
| Lock/Unlock | `POST /api/admin/users/{id}/lock` | ⬜ Chưa đánh giá | Audit log                |

**Files liên quan**:
- `backend/src/controllers/user.controller.ts`
- `backend/src/services/user.service.ts`
- `frontend/src/pages/ManageUsers.tsx`

---

### 3. [ADMIN] Quản lý Devices (Sprint 4)
> **SRS Ref**: UC025 | **Trello**: Sprint 4 - Card 6

| Chức năng     | API Endpoint                          | Trạng thái      | Ghi chú        |
| ------------- | ------------------------------------- | --------------- | -------------- |
| List devices  | `GET /api/admin/devices`              | ⬜ Chưa đánh giá |                |
| Device detail | `GET /api/admin/devices/{id}`         | ⬜ Chưa đánh giá |                |
| Update device | `PUT /api/admin/devices/{id}`         | ⬜ Chưa đánh giá |                |
| Assign device | `POST /api/admin/devices/{id}/assign` | ⬜ Chưa đánh giá | Assign to user |
| Lock device   | `POST /api/admin/devices/{id}/lock`   | ⬜ Chưa đánh giá |                |

**Files liên quan**:
- `backend/src/controllers/device.controller.ts`
- `backend/src/services/device.service.ts`
- `frontend/src/pages/ManageDevices.tsx`

---

### 4. [ADMIN] Cấu hình hệ thống (Sprint 4)
> **SRS Ref**: UC024 | **Trello**: Sprint 4 - Card 7

| Chức năng       | API Endpoint              | Trạng thái      | Ghi chú                     |
| --------------- | ------------------------- | --------------- | --------------------------- |
| Get settings    | `GET /api/admin/settings` | ⬜ Chưa đánh giá | Vital thresholds, AI config |
| Update settings | `PUT /api/admin/settings` | ⬜ Chưa đánh giá | Cache on startup            |

**Files liên quan**:
- `backend/src/controllers/settings.controller.ts`
- `backend/src/services/settings.service.ts`
- `frontend/src/pages/SystemSettings.tsx`

---

### 5. [ADMIN] Xem System Logs (Sprint 4)
> **SRS Ref**: UC026 | **Trello**: Sprint 4 - Card 8

| Chức năng  | API Endpoint                 | Trạng thái      | Ghi chú          |
| ---------- | ---------------------------- | --------------- | ---------------- |
| View logs  | `GET /api/admin/logs`        | ⬜ Chưa đánh giá | Filter, paginate |
| Export CSV | `GET /api/admin/logs/export` | ⬜ Chưa đánh giá |                  |

**Files liên quan**:
- `backend/src/controllers/logs.controller.ts`
- `backend/src/services/logs.service.ts`
- `frontend/src/pages/SystemLogs.tsx`

---

### 6. [INFRA] Infrastructure Setup (Sprint 1)
> **SRS Ref**: N/A | **Trello**: Sprint 1 - Cards 1, 2A

| Chức năng                    | Trạng thái      | Ghi chú                            |
| ---------------------------- | --------------- | ---------------------------------- |
| Database + TimescaleDB setup | ⬜ Chưa đánh giá | SQL SCRIPTS/ là source of truth    |
| Express + TypeScript project | ⬜ Chưa đánh giá | Prisma ORM                         |
| CORS middleware              | ⬜ Chưa đánh giá | Allow Admin Web origin             |
| Logging (file + console)     | ⬜ Chưa đánh giá |                                    |
| Environment variables        | ⬜ Chưa đánh giá | DB_URL, JWT_SECRET, PORT           |
| Health check endpoint        | ⬜ Chưa đánh giá | `GET /health`                      |
| Swagger docs                 | ⬜ Chưa đánh giá | swagger-jsdoc + swagger-ui-express |

**Files liên quan**:
- `backend/src/config/`
- `backend/src/middleware/`
- `backend/src/index.ts`
- `backend/prisma/`

---

## 🔄 Lịch Sử Cập Nhật

| Ngày       | Phiên bản | Nội dung                                       |
| ---------- | --------- | ---------------------------------------------- |
| 03/03/2026 | v1.0      | Khởi tạo Project Structure dựa trên Sprint 1-4 |
