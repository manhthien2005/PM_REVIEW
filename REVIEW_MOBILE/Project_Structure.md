# 📋 PROJECT STRUCTURE - MOBILE APP (health_system)

> **Dự án**: HealthGuard Mobile App  
> **Tech Stack**: Flutter / Dart (Frontend) + FastAPI / SQLAlchemy / Python (Backend)  
> **Mục đích**: Ứng dụng di động cho Bệnh nhân (Patient) và Người chăm sóc (Caregiver)  
> **Cập nhật lần cuối**: 03/03/2026

---

## 🏗️ Tổng Quan Kiến Trúc

```
health_system/
├── lib/                         # Flutter Mobile App
│   ├── main.dart                # App entry point
│   ├── app.dart                 # App configuration
│   ├── core/                    # Core utilities, constants, themes
│   ├── features/                # Feature modules (Clean Architecture)
│   │   ├── auth/                # Đăng nhập, đăng ký
│   │   ├── device/              # Quản lý thiết bị IoT  
│   │   ├── emergency/           # SOS, phát hiện té ngã
│   │   ├── health_monitoring/   # Theo dõi sức khỏe real-time
│   │   ├── home/                # Màn hình chính
│   │   ├── profile/             # Hồ sơ cá nhân
│   │   └── sleep_analysis/      # Phân tích giấc ngủ
│   └── shared/                  # Shared widgets, models, services
│
├── backend/                     # Mobile Backend (FastAPI + SQLAlchemy)
│   ├── app/
│   │   ├── api/                 # API routes
│   │   ├── core/                # Config, security, dependencies
│   │   ├── db/                  # Database connection, session
│   │   ├── models/              # SQLAlchemy models (reflect từ DB)
│   │   ├── repositories/        # Data access layer
│   │   ├── schemas/             # Pydantic schemas (request/response)
│   │   ├── services/            # Business logic layer
│   │   ├── utils/               # Helper functions
│   │   └── main.py              # FastAPI entry point
│   ├── .env                     # Environment variables
│   ├── requirements.txt
│   └── run.py                   # Start server script
│
├── android/                     # Android platform config
├── ios/                         # iOS platform config
├── test/                        # Unit/widget tests
├── pubspec.yaml                 # Flutter dependencies
└── pubspec.lock
```

---

## 🔧 Chức Năng Theo Module

### 1. [AUTH] Xác thực (Sprint 1)
> **SRS Ref**: UC001-UC004 | **Trello**: Sprint 1 - Cards 3, 4, 5, 6

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| Login (Patient/Caregiver) | `POST /api/auth/login` | ⬜ Chưa đánh giá | JWT issuer: `healthguard-mobile`, expiry 30 ngày + refresh token |
| Self-register | `POST /api/auth/register` | ⬜ Chưa đánh giá | `is_verified=false`, email verification |
| Forgot Password | `POST /api/auth/forgot-password` | ⬜ Chưa đánh giá | Deep link: `app://reset-password?token=xxx` |
| Reset Password | `POST /api/auth/reset-password` | ⬜ Chưa đánh giá | Token 15 phút, one-time use |
| Change Password | `POST /api/auth/change-password` | ⬜ Chưa đánh giá | Require JWT |

**Files liên quan**:
- **Backend**: `backend/app/api/auth/`, `backend/app/services/auth_service.py`
- **Mobile**: `lib/features/auth/`

---

### 2. [DEVICE] Quản lý thiết bị IoT (Sprint 2)
> **SRS Ref**: UC040, UC042 | **Trello**: Sprint 2 - Cards 1, 2

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| Register device | `POST /api/mobile/devices/register` | ⬜ Chưa đánh giá | QR scan hoặc manual input |
| List devices | `GET /api/mobile/devices` | ⬜ Chưa đánh giá | Devices của user (từ JWT) |
| Unbind device | `POST /api/mobile/devices/{id}/unbind` | ⬜ Chưa đánh giá | |
| Device status | `GET /api/mobile/devices/{id}/status` | ⬜ Chưa đánh giá | Online/offline (5 phút threshold) |

**Files liên quan**:
- **Backend**: `backend/app/api/devices/`, `backend/app/services/device_service.py`
- **Mobile**: `lib/features/device/`

---

### 3. [INFRA] Data Ingestion Service (Sprint 2)
> **SRS Ref**: N/A | **Trello**: Sprint 2 - Card 3

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| HTTP Data Ingest | `POST /api/mobile/telemetry/ingest` | ⬜ Chưa đánh giá | Vital signs + motion data |
| MQTT Subscriber | N/A (Service) | ⬜ Chưa đánh giá | Eclipse Mosquitto |
| Data Validation | N/A (Internal) | ⬜ Chưa đánh giá | HR: 40-200, SpO2: 70-100%, Temp: 35-42°C |

**Files liên quan**:
- **Backend**: `backend/app/services/telemetry_service.py`, `backend/app/utils/`

---

### 4. [MONITORING] Theo dõi sức khỏe (Sprint 2)
> **SRS Ref**: UC006, UC007, UC008 | **Trello**: Sprint 2 - Cards 4, 5, 6

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| View latest vitals | `GET /api/mobile/patients/{id}/vital-signs/latest` | ⬜ Chưa đánh giá | Real-time, auto-refresh 5s |
| View metric detail | `GET /api/mobile/patients/{id}/vital-signs/{metric}/detail` | ⬜ Chưa đánh giá | Stats: min/max/avg/std |
| View health history | `GET /api/mobile/patients/{id}/vital-signs/history` | ⬜ Chưa đánh giá | Continuous aggregates |

**Files liên quan**:
- **Backend**: `backend/app/api/vitals/`, `backend/app/services/vitals_service.py`
- **Mobile**: `lib/features/health_monitoring/`

---

### 5. [EMERGENCY] Phát hiện té ngã & SOS (Sprint 3)
> **SRS Ref**: UC010, UC011, UC014, UC015 | **Trello**: Sprint 3 - Cards 2, 3, 4, 5

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| Confirm fall (safe) | `POST /api/mobile/fall-events/{id}/confirm` | ⬜ Chưa đánh giá | User xác nhận an toàn |
| Trigger SOS (auto) | `POST /api/mobile/fall-events/{id}/trigger-sos` | ⬜ Chưa đánh giá | Auto sau 30s countdown |
| Manual SOS | `POST /api/mobile/sos/manual-trigger` | ⬜ Chưa đánh giá | Giữ nút 3s, cancel trong 5 phút |
| Cancel SOS | `POST /api/mobile/sos/{id}/cancel` | ⬜ Chưa đánh giá | Trong 5 phút |
| Active SOS list | `GET /api/mobile/sos/active` | ⬜ Chưa đánh giá | Cho caregiver |
| SOS detail | `GET /api/mobile/sos/{id}` | ⬜ Chưa đánh giá | |
| Respond to SOS | `POST /api/mobile/sos/{id}/respond` | ⬜ Chưa đánh giá | Acknowledged/Resolved |
| Resolve SOS | `POST /api/mobile/sos/{id}/resolve` | ⬜ Chưa đánh giá | |

**Files liên quan**:
- **Backend**: `backend/app/api/emergency/`, `backend/app/services/sos_service.py`
- **Mobile**: `lib/features/emergency/`

---

### 6. [NOTIFICATION] Thông báo & Liên hệ khẩn cấp (Sprint 3)
> **SRS Ref**: UC030, UC031 | **Trello**: Sprint 3 - Cards 1, 6

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| CRUD Emergency Contacts | `GET/POST/PUT/DELETE /api/mobile/emergency-contacts` | ⬜ Chưa đánh giá | Priority 1-5 |
| List alerts | `GET /api/mobile/alerts` | ⬜ Chưa đánh giá | Filter by type/severity/unread |
| Mark read | `POST /api/mobile/alerts/{id}/read` | ⬜ Chưa đánh giá | |
| Acknowledge alert | `POST /api/mobile/alerts/{id}/acknowledge` | ⬜ Chưa đánh giá | |
| Notification settings | `GET/PUT /api/mobile/notification-settings` | ⬜ Chưa đánh giá | |

**Files liên quan**:
- **Backend**: `backend/app/api/notifications/`, `backend/app/services/notification_service.py`
- **Mobile**: `lib/features/` (shared across modules)

---

### 7. [ANALYSIS] Risk Scoring & AI (Sprint 4)
> **SRS Ref**: UC016, UC017 | **Trello**: Sprint 4 - Cards 1, 2

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| Latest risk score | `GET /api/mobile/patients/{id}/risk-score/latest` | ⬜ Chưa đánh giá | Cache 1h, XGBoost model |
| Risk history | `GET /api/mobile/patients/{id}/risk-score/history` | ⬜ Chưa đánh giá | |
| Risk detail | `GET /api/mobile/risk-scores/{id}` | ⬜ Chưa đánh giá | SHAP explainer |
| AI Risk Scoring | `POST /ai/risk-scoring` (internal) | ⬜ Chưa đánh giá | 22 features, score 0-100 |

**Files liên quan**:
- **Backend**: `backend/app/api/analysis/`, `backend/app/services/risk_service.py`
- **Mobile**: `lib/features/` (risk report screens)

---

### 8. [SLEEP] Phân tích giấc ngủ (Sprint 4)
> **SRS Ref**: UC020, UC021 | **Trello**: Sprint 4 - Cards 3, 4

| Chức năng | API Endpoint | Trạng thái | Ghi chú |
|-----------|-------------|------------|---------|
| Latest sleep report | `GET /api/mobile/patients/{id}/sleep/latest` | ⬜ Chưa đánh giá | Stages: Awake/Light/Deep/REM |
| Sleep history | `GET /api/mobile/patients/{id}/sleep/history` | ⬜ Chưa đánh giá | |
| Sleep analysis (job) | N/A (Scheduled) | ⬜ Chưa đánh giá | Chạy mỗi sáng |

**Files liên quan**:
- **Backend**: `backend/app/api/sleep/`, `backend/app/services/sleep_service.py`
- **Mobile**: `lib/features/sleep_analysis/`

---

### 9. [INFRA] Mobile Backend Setup (Sprint 1)
> **SRS Ref**: N/A | **Trello**: Sprint 1 - Card 2B

| Chức năng | Trạng thái | Ghi chú |
|-----------|------------|---------|
| FastAPI project setup | ⬜ Chưa đánh giá | SQLAlchemy + PostgreSQL |
| CORS middleware | ⬜ Chưa đánh giá | Allow Mobile App origins |
| Logging | ⬜ Chưa đánh giá | File + console |
| Environment variables | ⬜ Chưa đánh giá | DB_URL, JWT_SECRET (chung), PORT |
| Health check | ⬜ Chưa đánh giá | `GET /health` |
| Auto-generated docs | ⬜ Chưa đánh giá | FastAPI Swagger at `/docs` |

**Files liên quan**:
- **Backend**: `backend/app/core/`, `backend/app/db/`, `backend/app/main.py`

---

## 📝 Hướng Dẫn Sử Dụng

### Đánh giá tổng quan
Gọi: `@tongquan Project_Structure REVIEW_MOBILE`

### Đánh giá chức năng cụ thể
Gọi: `@danhgiachitiet [Tên chức năng]`

**Ví dụ**:
- `@danhgiachitiet AUTH Login (Patient/Caregiver)`
- `@danhgiachitiet DEVICE Quản lý thiết bị IoT`
- `@danhgiachitiet EMERGENCY Phát hiện té ngã & SOS`
- `@danhgiachitiet MONITORING Theo dõi sức khỏe`
- `@danhgiachitiet SLEEP Phân tích giấc ngủ`

---

## 🔄 Lịch Sử Cập Nhật

| Ngày | Phiên bản | Nội dung |
|------|-----------|----------|
| 03/03/2026 | v1.0 | Khởi tạo Project Structure dựa trên Sprint 1-4 |
