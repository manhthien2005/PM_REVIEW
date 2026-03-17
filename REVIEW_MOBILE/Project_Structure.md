# PROJECT STRUCTURE - MOBILE APP (health_system)

> **Project**: HealthGuard Mobile App
> **Tech Stack**: Flutter / Dart (Frontend) + FastAPI / SQLAlchemy / Python (Backend)
> **Purpose**: Mobile app for Patient and Caregiver health monitoring
> **Last Updated**: 2026-03-17

---

## Architecture Overview

`
health_system/
├── lib/                         # Flutter Mobile App
│   ├── main.dart                # App entry point
│   ├── app.dart                 # App config + Deep link handler
│   ├── core/                    # Core utilities
│   ├── features/                # Feature modules (Clean Architecture)
│   │   ├── auth/                # ✅ Done (3748 LOC)
│   │   ├── device/              # ✅ Built (1026 LOC)
│   │   ├── emergency/           # ✅ Built (2540 LOC)
│   │   ├── family/              # ✅ Built (1990 LOC)
│   │   ├── health_monitoring/   # ✅ Built (2420 LOC)
│   │   ├── home/                # ✅ Built (152 LOC)
│   │   ├── profile/             # ✅ Built (1472 LOC)
│   │   └── sleep_analysis/      # ✅ Built (2679 LOC)
│   └── shared/                  # Shared widgets, models
├── backend/                     # Mobile Backend (FastAPI + SQLAlchemy)
│   ├── app/
│   │   ├── api/                 
│   │   │   └── routes/          
│   │   │       ├── auth.py          # ✅ 366 LOC
│   │   │       ├── device.py        # ✅ 102 LOC
│   │   │       ├── emergency.py     # ✅ 149 LOC
│   │   │       ├── relationships.py # ✅ 106 LOC
│   │   │       ├── monitoring.py    # ✅ 35 LOC
│   │   │       ├── profile.py       # ✅ 39 LOC
│   │   │       └── health.py        # ✅ 8 LOC
│   │   ├── services/            
│   │   │   ├── auth_service.py         # 1047 LOC
│   │   │   ├── device_service.py       # 334 LOC
│   │   │   ├── emergency_service.py    # 191 LOC
│   │   │   ├── monitoring_service.py   # 134 LOC
│   │   │   ├── profile_service.py      # 99 LOC
│   │   │   └── relationship_service.py # 171 LOC
│   └── main.py                  
`

---

## Modules by Feature

### 1. [AUTH] Authentication (Sprint 1)
> **SRS Ref**: UC001-UC004 | **JIRA**: EP04-Login, EP05-Register, EP12-Password
> **Review Status**: ✅ Reviewed — 82/100
| Feature | Endpoint | Status |
|---|---|---|
| Login/Reg/Verify/PW | /api/auth/* | ✅ Done |

### 2. [HOME] Main Navigation Shell (Sprint 1-2)
> **SRS Ref**: N/A (UI Infrastructure) | **JIRA**: N/A
> **Review Status**: ✅ Built (152 LOC)
| Feature | Screen File | Status |
|---|---|---|
| Bottom Navigation | home/screens/main_screen.dart | ✅ Done |

### 3. [DEVICE] IoT Device Management (Sprint 2)
> **SRS Ref**: UC040, UC041, UC042 | **JIRA**: EP07-Device
> **Review Status**: ✅ Built (1026 LOC Frontend, 334 LOC Backend)
| Feature | API Endpoint | Status |
|---|---|---|
| Device actions | /api/mobile/devices/* | ✅ Done |

### 4. [FAMILY] User Relationships (Sprint 3)
> **SRS Ref**: N/A | **JIRA**: N/A
> **Review Status**: ✅ Built (1990 LOC)
| Feature | API Endpoint | Status |
|---|---|---|
| Relationships | /api/mobile/relationships/* | ✅ Done |

### 5. [MONITORING] Health Metrics (Sprint 2)
> **SRS Ref**: UC006, UC007, UC008 | **JIRA**: EP08-Monitoring
> **Review Status**: ✅ Built (2420 LOC Frontend)
| Feature | API Endpoint | Status |
|---|---|---|
| Vitals | /api/mobile/monitoring/* | ✅ Done |

### 6. [EMERGENCY] Fall Detection & SOS (Sprint 3)
> **SRS Ref**: UC010, UC011, UC014, UC015 | **JIRA**: EP09-FallDetect, EP10-SOS
> **Review Status**: ✅ Built (2540 LOC Frontend)
| Feature | API Endpoint | Status |
|---|---|---|
| SOS & Events | /api/mobile/emergency/* | ✅ Done |

### 7. [PROFILE] User Profile & Settings (Sprint 1-2)
> **SRS Ref**: UC009 | **JIRA**: EP04-Login, EP05-Register
> **Review Status**: ✅ Built (1472 LOC)
| Feature | Endpoint | Status |
|---|---|---|
| Profile | /api/mobile/profile/* | ✅ Done |

### 8. [SLEEP] Sleep Analysis (Sprint 4)
> **SRS Ref**: UC020, UC021 | **JIRA**: EP14-Sleep
> **Review Status**: ✅ Built (2679 LOC Frontend)
| Feature | Endpoint | Status |
|---|---|---|
| Sleep UI | /api/mobile/sleep/* | ✅ Done |

---

## Update History
| Date       | Version | Changes |
| ---------- | ------- | ------- |
| 2026-03-17 | v3.0    | CHECK scan: Comprehensive overhaul. All placeholder modules (DEVICE, EMERGENCY, HEALTH_MONITORING, SLEEP, PROFILE) are fully implemented. Added FAMILY module. Updated vast LOC differences. |
