# PROJECT STRUCTURE - MOBILE APP (health_system)

> **Project**: HealthGuard Mobile App  
> **Tech Stack**: Flutter / Dart (Frontend) + FastAPI / SQLAlchemy / Python (Backend)  
> **Purpose**: Mobile app for Patient and Caregiver health monitoring  
> **Last Updated**: 04/03/2026  
> **Review Progress**: 1/8 modules completed (AUTH: 82/100)

---

## Architecture Overview

```
health_system/
├── lib/                         # Flutter Mobile App
│   ├── main.dart                # App entry point (3 LOC)
│   ├── app.dart                 # App config + Deep link handler (AppLinks)
│   ├── core/                    # Core utilities
│   │   ├── constants/           # App colors, sizes, strings (4 files)
│   │   ├── error/               # Error handling (1 file)
│   │   ├── network/             # API client (3 files)
│   │   ├── routes/              # App routing - AppRouter (1 file)
│   │   ├── theme/               # App theme (1 file)
│   │   └── utils/               # Validators, helpers (2 files)
│   ├── features/                # Feature modules (Clean Architecture)
│   │   ├── auth/                # ✅ Login, Register, Verify, Password (16 files)
│   │   ├── device/              # ⬜ Empty — not implemented
│   │   ├── emergency/           # ⬜ Empty — not implemented
│   │   ├── health_monitoring/   # ⬜ Empty — not implemented
│   │   ├── home/                # ⬜ Dashboard screen only (1 file)
│   │   ├── profile/             # ⬜ Empty — not implemented
│   │   └── sleep_analysis/      # ⬜ Empty — not implemented
│   └── shared/                  # Shared widgets, models (5 files)
│       ├── models/              # Shared data models (1 file)
│       └── widgets/             # Reusable widgets (4 files)
│
├── backend/                     # Mobile Backend (FastAPI + SQLAlchemy)
│   ├── app/
│   │   ├── api/                 # API routes
│   │   │   ├── router.py        # Main router aggregator (6 LOC)
│   │   │   └── routes/          # Route modules
│   │   │       ├── auth.py      # ✅ Auth routes (216 LOC)
│   │   │       └── health.py    # Health check (5 LOC)
│   │   ├── core/                # Config, security, dependencies
│   │   │   ├── config.py        # Settings (30 LOC)
│   │   │   └── dependencies.py  # Auth deps (70 LOC)
│   │   ├── db/                  # Database connection
│   │   │   ├── database.py      # SQLAlchemy session (12 LOC)
│   │   │   └── memory_db.py     # Test DB (3 LOC)
│   │   ├── models/              # SQLAlchemy models
│   │   │   ├── user_model.py    # User (20 LOC)
│   │   │   └── audit_log_model.py # AuditLog (18 LOC)
│   │   ├── repositories/        # Data access layer
│   │   │   ├── user_repository.py      # UserRepo (66 LOC)
│   │   │   └── audit_log_repository.py # AuditLogRepo (45 LOC)
│   │   ├── schemas/             # Pydantic schemas
│   │   │   └── auth.py          # Auth schemas (35 LOC)
│   │   ├── services/            # Business logic
│   │   │   └── auth_service.py  # ✅ AuthService (764 LOC)
│   │   ├── utils/               # Helpers
│   │   │   ├── jwt.py           # JWT utils (112 LOC)
│   │   │   ├── email_service.py # Email sending (141 LOC)
│   │   │   ├── rate_limiter.py  # Rate limiter (61 LOC)
│   │   │   ├── password.py      # Bcrypt (8 LOC)
│   │   │   └── datetime_helper.py # TZ helper (8 LOC)
│   │   └── main.py              # FastAPI entry point (17 LOC)
│   ├── tests/                   # Unit tests
│   │   └── test_auth_service.py # 15 auth tests
│   ├── .env                     # Environment variables
│   ├── requirements.txt         # Dependencies (8 main + 3 test)
│   └── run.py                   # Start server script
│
├── android/                     # Android platform config
│   └── app/src/main/AndroidManifest.xml  # Deep link intent filters
├── ios/                         # iOS platform config
│   └── Runner/Info.plist        # Deep link CFBundleURLTypes
├── assets/images/               # App image assets (5 files)
├── test/                        # Flutter tests (1 file)
├── pubspec.yaml                 # Flutter deps: provider 6.1.5, http 1.1.0, flutter_secure_storage 9.2.2, app_links 6.3.3, jwt_decode 0.3.1
└── pubspec.lock
```

---

## Modules by Feature

### 1. [AUTH] Authentication (Sprint 1)

> **SRS Ref**: UC001-UC004 | **JIRA**: EP04-Login, EP05-Register, EP12-Password  
> **Review Status**: ✅ Reviewed — 82/100 (2026-03-04) | [Detail](AUTH_LOGIN_review_v2.md)

| Feature                   | API Endpoint                         | Status | Note                                                   |
| ------------------------- | ------------------------------------ | ------ | ------------------------------------------------------ |
| Login (Patient/Caregiver) | `POST /api/auth/login`               | ✅ Done | JWT issuer: `healthguard-mobile`, 30d + refresh token  |
| Self-register             | `POST /api/auth/register`            | ✅ Done | `is_verified=false`, email verification with deep link |
| Email Verification        | `POST /api/auth/verify-email`        | ✅ Done | Deep link: `healthguard://verify-email?token=xxx`      |
| Resend Verification       | `POST /api/auth/resend-verification` | ✅ Done | Rate limit 3/15min                                     |
| Forgot Password           | `POST /api/auth/forgot-password`     | ✅ Done | Deep link: `healthguard://reset-password?token=xxx`    |
| Reset Password            | `POST /api/auth/reset-password`      | ✅ Done | Token 15min, one-time use                              |
| Change Password           | `POST /api/auth/change-password`     | ✅ Done | Require JWT, verify current pwd                        |
| Refresh Token             | `POST /api/auth/refresh`             | ✅ Done | Refresh access token mechanism                         |

**Known Issues**:
- 🔴 CORS `allow_origins=["*"]` — security risk
- 🔴 Refresh token rotation not implemented
- 🟡 Rate limiter in-memory (needs Redis)
- 🟡 Swagger UI not explicitly enabled

---

### 2. [DEVICE] IoT Device Management (Sprint 2)

> **SRS Ref**: UC040, UC041, UC042 | **JIRA**: EP07-Device  
> **Review Status**: ⬜ Not implemented

| Feature         | API Endpoint                           | Status      |
| --------------- | -------------------------------------- | ----------- |
| Register device | `POST /api/mobile/devices/register`    | ⬜ Not built |
| List devices    | `GET /api/mobile/devices`              | ⬜ Not built |
| Unbind device   | `POST /api/mobile/devices/{id}/unbind` | ⬜ Not built |
| Device status   | `GET /api/mobile/devices/{id}/status`  | ⬜ Not built |

> ⚠️ Both `lib/features/device/` and backend route files are **empty directories**

---

### 3. [INFRA] Backend Setup + Data Ingestion (Sprint 1-2)

> **SRS Ref**: N/A | **JIRA**: EP01-Database, EP03-MobileBE, EP06-Ingestion  
> **Review Status**: ⬜ Pending (partially working — FastAPI + Auth infra done)

| Feature               | Status      | Note                                |
| --------------------- | ----------- | ----------------------------------- |
| FastAPI project setup | ✅ Done      | SQLAlchemy + PostgreSQL, Clean Arch |
| CORS middleware       | ⚠️ Done      | `allow_origins=["*"]` — needs fix   |
| Logging               | ✅ Done      | Audit logs for auth actions         |
| Environment variables | ✅ Done      | DB_URL, SECRET_KEY, SMTP via .env   |
| Health check          | ✅ Done      | `GET /health` endpoint              |
| JWT Security          | ✅ Done      | Issuer validation, access + refresh |
| Rate Limiting         | ✅ Done      | In-memory (needs Redis migration)   |
| HTTP Data Ingest      | ⬜ Not built | No telemetry route/service exists   |
| MQTT Subscriber       | ⬜ Not built | No MQTT implementation exists       |

---

### 4. [MONITORING] Health Metrics (Sprint 2)

> **SRS Ref**: UC006, UC007, UC008 | **JIRA**: EP08-Monitoring  
> **Review Status**: ⬜ Not implemented

| Feature             | API Endpoint                                                | Status      |
| ------------------- | ----------------------------------------------------------- | ----------- |
| View latest vitals  | `GET /api/mobile/patients/{id}/vital-signs/latest`          | ⬜ Not built |
| View metric detail  | `GET /api/mobile/patients/{id}/vital-signs/{metric}/detail` | ⬜ Not built |
| View health history | `GET /api/mobile/patients/{id}/vital-signs/history`         | ⬜ Not built |

> ⚠️ Both `lib/features/health_monitoring/` and backend are **empty**

---

### 5. [EMERGENCY] Fall Detection & SOS (Sprint 3)

> **SRS Ref**: UC010, UC011, UC014, UC015 | **JIRA**: EP09-FallDetect, EP10-SOS  
> **Review Status**: ⬜ Not implemented

| Feature             | API Endpoint                                    | Status      |
| ------------------- | ----------------------------------------------- | ----------- |
| Confirm fall (safe) | `POST /api/mobile/fall-events/{id}/confirm`     | ⬜ Not built |
| Trigger SOS (auto)  | `POST /api/mobile/fall-events/{id}/trigger-sos` | ⬜ Not built |
| Manual SOS          | `POST /api/mobile/sos/manual-trigger`           | ⬜ Not built |
| Cancel SOS          | `POST /api/mobile/sos/{id}/cancel`              | ⬜ Not built |
| Active SOS list     | `GET /api/mobile/sos/active`                    | ⬜ Not built |
| SOS detail          | `GET /api/mobile/sos/{id}`                      | ⬜ Not built |
| Respond to SOS      | `POST /api/mobile/sos/{id}/respond`             | ⬜ Not built |
| Resolve SOS         | `POST /api/mobile/sos/{id}/resolve`             | ⬜ Not built |

> ⚠️ Both `lib/features/emergency/` and backend are **empty**

---

### 6. [NOTIFICATION] Alerts & Emergency Contacts (Sprint 3)

> **SRS Ref**: UC030, UC031 | **JIRA**: EP11-Notification  
> **Review Status**: ⬜ Not implemented

| Feature                 | API Endpoint                                         | Status      |
| ----------------------- | ---------------------------------------------------- | ----------- |
| CRUD Emergency Contacts | `GET/POST/PUT/DELETE /api/mobile/emergency-contacts` | ⬜ Not built |
| List alerts             | `GET /api/mobile/alerts`                             | ⬜ Not built |
| Mark read               | `POST /api/mobile/alerts/{id}/read`                  | ⬜ Not built |
| Acknowledge alert       | `POST /api/mobile/alerts/{id}/acknowledge`           | ⬜ Not built |
| Notification settings   | `GET/PUT /api/mobile/notification-settings`          | ⬜ Not built |

---

### 7. [ANALYSIS] Risk Scoring & AI (Sprint 4)

> **SRS Ref**: UC016, UC017 | **JIRA**: EP13-RiskScore  
> **Review Status**: ⬜ Not implemented

| Feature           | API Endpoint                                       | Status      |
| ----------------- | -------------------------------------------------- | ----------- |
| Latest risk score | `GET /api/mobile/patients/{id}/risk-score/latest`  | ⬜ Not built |
| Risk history      | `GET /api/mobile/patients/{id}/risk-score/history` | ⬜ Not built |
| Risk detail       | `GET /api/mobile/risk-scores/{id}`                 | ⬜ Not built |
| AI Risk Scoring   | `POST /ai/risk-scoring` (internal)                 | ⬜ Not built |

---

### 8. [SLEEP] Sleep Analysis (Sprint 4)

> **SRS Ref**: UC020, UC021 | **JIRA**: EP14-Sleep  
> **Review Status**: ⬜ Not implemented

| Feature             | API Endpoint                                  | Status      |
| ------------------- | --------------------------------------------- | ----------- |
| Latest sleep report | `GET /api/mobile/patients/{id}/sleep/latest`  | ⬜ Not built |
| Sleep history       | `GET /api/mobile/patients/{id}/sleep/history` | ⬜ Not built |

> ⚠️ `lib/features/sleep_analysis/` and backend are **empty**

## Update History

| Date       | Version | Changes                                                                                    |
| ---------- | ------- | ------------------------------------------------------------------------------------------ |
| 04/03/2026 | v2.0    | CHECK scan: Trello→JIRA, accurate LOC, 7/8 modules confirmed NOT implemented, tree updated |
| 04/03/2026 | v1.2    | AUTH 82/100, Forgot/Reset/Change PWD UI, jwt_decode dependency, 15 tests                   |
| 04/03/2026 | v1.1    | AUTH after review v3 (78/100), deep link integration, rate limiting, audit logging         |
| 03/03/2026 | v1.0    | Initial creation based on Sprint 1-4                                                       |
