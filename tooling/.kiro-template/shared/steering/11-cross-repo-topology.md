---
inclusion: always
---

# Cross-Repo Topology — Data Flow

Hệ thống VSmartwatch là **distributed** — 4 repo runtime + 1 repo docs.

## Data flow

```
Smartwatch (BLE) → Mobile App (Flutter) → Mobile BE (FastAPI :8000)
                                                    ↓
                                          ┌─────────┴──────────┐
                                          ↓                    ↓
                                   Shared Postgres      Model API (:8001)
                                          ↓
                                   Admin BE (Express :5000) ← IoT Sim (:8002)
                                          ↓
                                   Admin FE (Vite :5173)
```

## Boundary contracts

| From → To | Protocol | Auth |
|---|---|---|
| Mobile → Backend | REST `/api/mobile/*` | JWT user (`iss=healthguard-mobile`) |
| Backend → Model API | REST `/api/v1/{fall,sleep,health}` | `X-Internal-Secret` header |
| IoT sim → Backend | REST `/api/internal/*` | Internal auth header |
| Admin Web → Admin BE | REST `/api/admin/*` | JWT admin (`iss=healthguard-admin`) |
| All → Postgres | Prisma (admin) / asyncpg (mobile BE) | DB credentials |

## Risk hot-spots

- Sửa `health_system/backend/app/routers/` → impact Mobile app + IoT sim
- Sửa `healthguard-model-api/app/routers/` → impact cả 2 backend
- Sửa Prisma schema → impact Postgres → cả 2 backend
- Sửa `PM_REVIEW/SQL SCRIPTS/` → canonical schema, impact toàn hệ thống

## Khi thay đổi cross-repo

1. Identify ripple effect — list tất cả repo bị ảnh hưởng
2. Update spec trước (UC/SRS/SQL trong PM_REVIEW)
3. Update producer (BE endpoint)
4. Update consumer(s) (mobile/admin/IoT)
5. Cross-repo test (E2E smoke: `Iot_Simulator_clean/scripts/e2e_*.ps1`)
6. Document deviation trong commit message

## Localhost dev ports

| Service | Port | Repo |
|---|---|---|
| Admin Backend | 5000 | HealthGuard/backend |
| Admin Frontend | 5173 | HealthGuard/frontend |
| Mobile Backend | 8000 | health_system/backend |
| Model API | 8001 | healthguard-model-api |
| IoT Sim API | 8002 | Iot_Simulator_clean |
| Postgres | 5432 | (shared) |
