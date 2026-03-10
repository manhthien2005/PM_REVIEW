# PROJECT STRUCTURE - MOBILE APP (health_system)

> **Project**: HealthGuard Mobile App  
> **Tech Stack**: Flutter / Dart (Frontend) + FastAPI / SQLAlchemy / Python (Backend)  
> **Purpose**: Mobile app for Patient and Caregiver health monitoring  
> **Last Updated**: 10/03/2026  
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
│   │   ├── home/                # 🔵 Navigation shell (2 files)
│   │   │   └── screens/         # main_screen.dart (bottom nav), dashboard_screen.dart
│   │   ├── device/              # ⬜ Placeholder — Clean Arch folders + 1 screen (25 LOC)
│   │   │   ├── models/          # Empty (only .gitkeep)
│   │   │   ├── providers/       # Empty (only .gitkeep)
│   │   │   ├── repositories/    # Empty (only .gitkeep)
│   │   │   ├── screens/         # device_screen.dart (placeholder)
│   │   │   └── widgets/         # Empty (only .gitkeep)
│   │   ├── emergency/           # ⬜ Placeholder — Clean Arch folders + 1 screen (25 LOC)
│   │   │   ├── models/          # Empty (only .gitkeep)
│   │   │   ├── providers/       # Empty (only .gitkeep)
│   │   │   ├── repositories/    # Empty (only .gitkeep)
│   │   │   ├── screens/         # warning_screen.dart (placeholder)
│   │   │   └── widgets/         # Empty (only .gitkeep)
│   │   ├── health_monitoring/   # ⬜ Placeholder — Clean Arch folders + 1 screen (25 LOC)
│   │   │   ├── models/          # Empty (only .gitkeep)
│   │   │   ├── providers/       # Empty (only .gitkeep)
│   │   │   ├── repositories/    # Empty (only .gitkeep)
│   │   │   ├── screens/         # health_monitoring_screen.dart (placeholder)
│   │   │   └── widgets/         # Empty (only .gitkeep)
│   │   ├── profile/             # ⬜ Placeholder — Clean Arch folders + 1 screen (40 LOC, has logout)
│   │   │   ├── models/          # Empty (only .gitkeep)
│   │   │   ├── providers/       # Empty (only .gitkeep)
│   │   │   ├── repositories/    # Empty (only .gitkeep)
│   │   │   ├── screens/         # profile_screen.dart (placeholder with logout button)
│   │   │   └── widgets/         # Empty (only .gitkeep)
│   │   └── sleep_analysis/      # ⬜ Placeholder — Clean Arch folders + 1 screen (25 LOC)
│   │       ├── models/          # Empty (only .gitkeep)
│   │       ├── providers/       # Empty (only .gitkeep)
│   │       ├── repositories/    # Empty (only .gitkeep)
│   │       ├── screens/         # sleep_screen.dart (placeholder)
│   │       └── widgets/         # Empty (only .gitkeep)
│   └── shared/                  # Shared widgets, models (5 files)
│       ├── models/              # Shared data models (1 file)
│       └── widgets/             # Reusable widgets (4 files)
│
├── backend/                     # Mobile Backend (FastAPI + SQLAlchemy)
│   ├── app/
│   │   ├── api/                 # API routes
│   │   │   ├── router.py        # Main router aggregator (6 LOC)
│   │   │   └── routes/          # Route modules
│   │       ├── auth.py      # ✅ Auth routes (260 LOC)
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
│   │   │   └── auth_service.py  # ✅ AuthService (779 LOC)
│   │   ├── utils/               # Helpers
│   │   │   ├── jwt.py           # JWT utils (121 LOC)
│   │   │   ├── email_service.py # Email sending (190 LOC)
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

| Feature                   | API Endpoint                         | Status  | Note                                                   |
| ------------------------- | ------------------------------------ | ------- | ------------------------------------------------------ |
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

### 2. [HOME] Main Navigation Shell (Sprint 1-2)

> **SRS Ref**: N/A (UI Infrastructure) | **JIRA**: N/A  
> **Review Status**: 🔵 Scaffolding done — placeholder screens

| Feature                  | Screen File                          | Status         | Note                                         |
| ------------------------ | ------------------------------------ | -------------- | -------------------------------------------- |
| Bottom Navigation Bar    | `home/screens/main_screen.dart`      | ✅ Done        | 5 tabs with gradient blue design, custom nav |
| Dashboard (patient view) | `home/screens/dashboard_screen.dart` | ⬜ Placeholder | Simple screen with centered text             |

**Navigation Structure**:

- **Tab 1**: Sức khỏe (Health Monitoring) → `health_monitoring_screen.dart`
- **Tab 2**: Giấc ngủ (Sleep Analysis) → `sleep_screen.dart`
- **Tab 3**: Cảnh báo (Emergency/Warning) → `warning_screen.dart`
- **Tab 4**: Thiết bị (Device) → `device_screen.dart`
- **Tab 5**: Cá nhân (Profile) → `profile_screen.dart`

**Implementation Details**:

- Custom navigation bar (replaced default `BottomNavigationBar` due to overflow issues)
- Gradient blue theme (`Colors.blue.shade800` → `Colors.blue.shade600`)
- Selected tab: glow effect with larger icon (28px vs 24px)
- Height: 70px with 12px border radius
- Smooth animations (300ms duration)

**Known Issues**:

- Dashboard screen is placeholder only — no actual content
- All feature screens are placeholders (simple centered text)
- No data flow between screens yet

---

### 3. [DEVICE] IoT Device Management (Sprint 2)

> **SRS Ref**: UC040, UC041, UC042 | **JIRA**: EP07-Device  
> **Review Status**: ⬜ Placeholder screen only — no logic

| Feature         | API Endpoint                           | Status       | Screen Status                                |
| --------------- | -------------------------------------- | ------------ | -------------------------------------------- |
| Register device | `POST /api/mobile/devices/register`    | ⬜ Not built | ⬜ `device_screen.dart` placeholder (25 LOC) |
| List devices    | `GET /api/mobile/devices`              | ⬜ Not built | —                                            |
| Unbind device   | `POST /api/mobile/devices/{id}/unbind` | ⬜ Not built | —                                            |
| Device status   | `GET /api/mobile/devices/{id}/status`  | ⬜ Not built | —                                            |

> ⚠️ Clean Architecture folders created but empty (models/, providers/, repositories/, widgets/ have only .gitkeep)

---

### 4. [INFRA] Backend Setup + Data Ingestion (Sprint 1-2)

> **SRS Ref**: N/A | **JIRA**: EP01-Database, EP03-MobileBE, EP06-Ingestion  
> **Review Status**: ⬜ Pending (partially working — FastAPI + Auth infra done)

| Feature               | Status       | Note                                |
| --------------------- | ------------ | ----------------------------------- |
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

### 5. [MONITORING] Health Metrics (Sprint 2)

> **SRS Ref**: UC006, UC007, UC008 | **JIRA**: EP08-Monitoring  
> **Review Status**: ⬜ Placeholder screen only — no logic

| Feature             | API Endpoint                                                | Status       | Screen Status                                           |
| ------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------- |
| View latest vitals  | `GET /api/mobile/patients/{id}/vital-signs/latest`          | ⬜ Not built | ⬜ `health_monitoring_screen.dart` placeholder (25 LOC) |
| View metric detail  | `GET /api/mobile/patients/{id}/vital-signs/{metric}/detail` | ⬜ Not built | —                                                       |
| View health history | `GET /api/mobile/patients/{id}/vital-signs/history`         | ⬜ Not built | —                                                       |

> ⚠️ Clean Architecture folders created but empty (models/, providers/, repositories/, widgets/ have only .gitkeep)

---

### 6. [EMERGENCY] Fall Detection & SOS (Sprint 3)

> **SRS Ref**: UC010, UC011, UC014, UC015 | **JIRA**: EP09-FallDetect, EP10-SOS  
> **Review Status**: ⬜ Placeholder screen only — no logic

| Feature             | API Endpoint                                    | Status       | Screen Status                                 |
| ------------------- | ----------------------------------------------- | ------------ | --------------------------------------------- |
| Confirm fall (safe) | `POST /api/mobile/fall-events/{id}/confirm`     | ⬜ Not built | ⬜ `warning_screen.dart` placeholder (25 LOC) |
| Trigger SOS (auto)  | `POST /api/mobile/fall-events/{id}/trigger-sos` | ⬜ Not built | —                                             |
| Manual SOS          | `POST /api/mobile/sos/manual-trigger`           | ⬜ Not built | —                                             |
| Cancel SOS          | `POST /api/mobile/sos/{id}/cancel`              | ⬜ Not built | —                                             |
| Active SOS list     | `GET /api/mobile/sos/active`                    | ⬜ Not built | —                                             |
| SOS detail          | `GET /api/mobile/sos/{id}`                      | ⬜ Not built | —                                             |
| Respond to SOS      | `POST /api/mobile/sos/{id}/respond`             | ⬜ Not built | —                                             |
| Resolve SOS         | `POST /api/mobile/sos/{id}/resolve`             | ⬜ Not built | —                                             |

> ⚠️ Clean Architecture folders created but empty (models/, providers/, repositories/, widgets/ have only .gitkeep)

---

### 7. [NOTIFICATION] Alerts & Emergency Contacts (Sprint 3)

> **SRS Ref**: UC030, UC031 | **JIRA**: EP11-Notification  
> **Review Status**: ⬜ Not implemented — no screen created

| Feature                 | API Endpoint                                         | Status       |
| ----------------------- | ---------------------------------------------------- | ------------ |
| CRUD Emergency Contacts | `GET/POST/PUT/DELETE /api/mobile/emergency-contacts` | ⬜ Not built |
| List alerts             | `GET /api/mobile/alerts`                             | ⬜ Not built |
| Mark read               | `POST /api/mobile/alerts/{id}/read`                  | ⬜ Not built |
| Acknowledge alert       | `POST /api/mobile/alerts/{id}/acknowledge`           | ⬜ Not built |
| Notification settings   | `GET/PUT /api/mobile/notification-settings`          | ⬜ Not built |

> ⚠️ No feature folder created for notification module yet

---

### 8. [ANALYSIS] Risk Scoring & AI (Sprint 4)

> **SRS Ref**: UC016, UC017 | **JIRA**: EP13-RiskScore  
> **Review Status**: ⬜ Not implemented

| Feature           | API Endpoint                                       | Status       |
| ----------------- | -------------------------------------------------- | ------------ |
| Latest risk score | `GET /api/mobile/patients/{id}/risk-score/latest`  | ⬜ Not built |
| Risk history      | `GET /api/mobile/patients/{id}/risk-score/history` | ⬜ Not built |
| Risk detail       | `GET /api/mobile/risk-scores/{id}`                 | ⬜ Not built |
| AI Risk Scoring   | `POST /ai/risk-scoring` (internal)                 | ⬜ Not built |

---

### 8. [ANALYSIS] Risk Scoring & AI (Sprint 4)

> **SRS Ref**: UC016, UC017 | **JIRA**: EP13-RiskScore  
> **Review Status**: ⬜ Not implemented — no screen created

| Feature           | API Endpoint                                       | Status       |
| ----------------- | -------------------------------------------------- | ------------ |
| Latest risk score | `GET /api/mobile/patients/{id}/risk-score/latest`  | ⬜ Not built |
| Risk history      | `GET /api/mobile/patients/{id}/risk-score/history` | ⬜ Not built |
| Risk detail       | `GET /api/mobile/risk-scores/{id}`                 | ⬜ Not built |
| AI Risk Scoring   | `POST /ai/risk-scoring` (internal)                 | ⬜ Not built |

> ⚠️ No feature folder created for analysis module yet

---

### 9. [SLEEP] Sleep Analysis (Sprint 4)

> **SRS Ref**: UC020, UC021 | **JIRA**: EP14-Sleep  
> **Review Status**: ⬜ Placeholder screen only — no logic

| Feature             | API Endpoint                                  | Status       | Screen Status                               |
| ------------------- | --------------------------------------------- | ------------ | ------------------------------------------- |
| Latest sleep report | `GET /api/mobile/patients/{id}/sleep/latest`  | ⬜ Not built | ⬜ `sleep_screen.dart` placeholder (25 LOC) |
| Sleep history       | `GET /api/mobile/patients/{id}/sleep/history` | ⬜ Not built | —                                           |

> ⚠️ Clean Architecture folders created but empty (models/, providers/, repositories/, widgets/ have only .gitkeep)

### 10. [PROFILE] User Profile & Settings (Sprint 1-2)

> **SRS Ref**: UC009 | **JIRA**: EP04-Login (Profile view), EP05-Register  
> **Review Status**: ⬜ Placeholder screen with logout only

| Feature      | Screen File                           | Status         | Note                                      |
| ------------ | ------------------------------------- | -------------- | ----------------------------------------- |
| View profile | `profile/screens/profile_screen.dart` | ⬜ Placeholder | Simple screen with logout button (40 LOC) |
| Edit profile | —                                     | ⬜ Not built   | No edit UI yet                            |
| Logout       | `profile/screens/profile_screen.dart` | ✅ Done        | Uses AuthProvider to clear session        |

**Implementation Details**:

- Profile screen connected to `AuthProvider` for logout functionality
- Logout button triggers `authProvider.logout()` → clears JWT → navigates to login
- Screen accessible via bottom navigation Tab 5

**Known Issues**:

- No profile data display — placeholder only
- No edit profile functionality
- Clean Architecture folders empty (models/, providers/, repositories/, widgets/ have only .gitkeep)

## Update History

| Date       | Version | Changes                                                                                                                                    |
| ---------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 10/03/2026 | v2.2    | CHECK scan: Added HOME navigation (main_screen.dart), all features now have Clean Arch folders + placeholder screens, added PROFILE module |
| 04/03/2026 | v2.1    | CHECK scan: Updated LOC for auth.py (260), auth_service.py (779), jwt.py (121), email_service.py (190)                                     |
| 04/03/2026 | v2.0    | CHECK scan: Trello→JIRA, accurate LOC, 7/8 modules confirmed NOT implemented, tree updated                                                 |
| 04/03/2026 | v1.2    | AUTH 82/100, Forgot/Reset/Change PWD UI, jwt_decode dependency, 15 tests                                                                   |
| 04/03/2026 | v1.1    | AUTH after review v3 (78/100), deep link integration, rate limiting, audit logging                                                         |
| 03/03/2026 | v1.0    | Initial creation based on Sprint 1-4                                                                                                       |
