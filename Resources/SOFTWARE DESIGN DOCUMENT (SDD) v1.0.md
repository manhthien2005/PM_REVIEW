# SOFTWARE DESIGN DOCUMENT (SDD) v1.0

## HealthGuard — IoT Health Monitoring & Alert System

| Thuộc tính | Giá trị |
|---|---|
| **Tên dự án** | HealthGuard |
| **Phiên bản SDD** | 1.0 |
| **Ngày tạo** | 12/03/2026 |
| **Cập nhật lần cuối** | 12/03/2026 |
| **Tác giả** | HealthGuard Development Team |
| **Tài liệu tham chiếu** | SRS v1.0, SRS_INDEX.md |

---

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
2. [Kiến trúc hệ thống tổng quan](#2-kiến-trúc-hệ-thống-tổng-quan)
3. [Kiến trúc chi tiết từng thành phần](#3-kiến-trúc-chi-tiết-từng-thành-phần)
4. [Thiết kế cơ sở dữ liệu](#4-thiết-kế-cơ-sở-dữ-liệu)
5. [Thiết kế API & API Gateway](#5-thiết-kế-api--api-gateway)
6. [Kĩ thuật và công nghệ sử dụng](#6-kĩ-thuật-và-công-nghệ-sử-dụng)
7. [Docker Build & Containerization](#7-docker-build--containerization)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Heroku Deployment](#9-heroku-deployment)
10. [Cloudflare Tunnels](#10-cloudflare-tunnels)
11. [Database Hosting trên VPS](#11-database-hosting-trên-vps)
12. [Bảo mật hệ thống](#12-bảo-mật-hệ-thống)
13. [Monitoring & Logging](#13-monitoring--logging)
14. [Phụ lục](#14-phụ-lục)

---

## 1. Giới thiệu

### 1.1. Mục đích tài liệu

Tài liệu SDD (Software Design Document) mô tả **chi tiết thiết kế kiến trúc, kĩ thuật, hạ tầng triển khai** của hệ thống HealthGuard. Đây là tài liệu kĩ thuật cốt lõi phục vụ cho:

- **Đội phát triển**: Hiểu rõ kiến trúc, quy ước code, luồng dữ liệu
- **Đội vận hành**: Triển khai, bảo trì, troubleshoot hạ tầng
- **Giảng viên/Reviewer**: Đánh giá năng lực kĩ thuật của dự án

### 1.2. Phạm vi hệ thống

HealthGuard là hệ thống **IoT giám sát sức khỏe** gồm 4 thành phần chính:

| # | Thành phần | Vai trò |
|---|---|---|
| 1 | **Mobile App** (Flutter) | Ứng dụng cho bệnh nhân/người thân — xem vitals, nhận cảnh báo, SOS |
| 2 | **Mobile Backend** (FastAPI) | Xử lý dữ liệu IoT, AI fall detection, risk scoring, push notification |
| 3 | **Admin Web** (React) | Bảng quản trị cho admin — dashboard, quản lý user, cấu hình hệ thống |
| 4 | **Admin Backend** (Express) | API phục vụ Admin Web — CRUD users, audit logs, system settings |

### 1.3. Thuật ngữ & Viết tắt

| Viết tắt | Ý nghĩa |
|---|---|
| **BE** | Backend |
| **FE** | Frontend |
| **TSDB** | TimescaleDB (time-series extension cho PostgreSQL) |
| **XAI** | Explainable AI — AI có khả năng giải thích kết quả |
| **HRV** | Heart Rate Variability — Biến thiên nhịp tim |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **ORM** | Object-Relational Mapping |
| **JWT** | JSON Web Token |

---

## 2. Kiến trúc hệ thống tổng quan

### 2.1. Sơ đồ kiến trúc hệ thống (System Architecture Diagram)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DEVICE LAYER (IoT Simulator)                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Python Simulator — phát sinh dữ liệu vitals mỗi 60 giây      │    │
│  │  (Heart Rate, SpO₂, Blood Pressure, Temperature, Accelerometer) │    │
│  └────────────────────────────┬────────────────────────────────────┘    │
└───────────────────────────────┼─────────────────────────────────────────┘
                                │ HTTP/MQTT (streaming)
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     CONNECTIVITY & SECURITY LAYER                       │
│  ┌──────────────────┐  ┌───────────────────┐  ┌──────────────────────┐ │
│  │ Cloudflare Tunnel │  │   HTTPS/TLS 1.3   │  │ API Gateway (Nginx)  │ │
│  │ (expose VPS DB)   │  │   (end-to-end)    │  │ Proxy & OpenAPI Docs │ │
│  └──────────────────┘  └───────────────────┘  └──────────────────────┘ │
└───────────────────────────────┼─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER (Multi-Backend)                     │
│                                                                         │
│  ┌─────────────────────────┐     ┌─────────────────────────────────┐   │
│  │  MOBILE BACKEND          │     │   ADMIN BACKEND                  │   │
│  │  ─────────────────────── │     │   ─────────────────────────────  │   │
│  │  Runtime: Python 3.11    │     │   Runtime: Node.js 20            │   │
│  │  Framework: FastAPI      │     │   Framework: Express 5           │   │
│  │  ORM: SQLAlchemy 2.0     │     │   ORM: Prisma 6                 │   │
│  │  Server: Gunicorn+Uvicorn│     │   Process: dumb-init + node     │   │
│  │  ─────────────────────── │     │   ─────────────────────────────  │   │
│  │  Services:               │     │   Services:                      │   │
│  │  • Auth (JWT 30d)        │     │   • Auth (JWT 8h)                │   │
│  │  • Vitals Ingestion      │     │   • User Management (CRUD)       │   │
│  │  • Health Monitoring     │     │   • Dashboard Analytics          │   │
│  │  • AI Fall Detection     │     │   • System Config                │   │
│  │  • Risk Scoring + XAI    │     │   • Audit Logs                   │   │
│  │  • Push Notification     │     │   ─────────────────────────────  │   │
│  │  • Sleep Tracking        │     │   Serves: React SPA (static)     │   │
│  │  • Device Management     │     │                                  │   │
│  └────────────┬─────────────┘     └───────────────┬─────────────────┘   │
│               │                                   │                     │
│               └──────────┬────────────────────────┘                     │
│                          │                                              │
└──────────────────────────┼──────────────────────────────────────────────┘
                           │  SQL Queries (TCP/IP)
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA LAYER (Shared Database)                      │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  PostgreSQL 17 + TimescaleDB                                    │    │
│  │  ─────────────────────────────────────────────────────────────  │    │
│  │  • 15+ tables (users, devices, vitals, alerts, risk_scores...) │    │
│  │  • Hypertables: vitals, motion_data, audit_logs                │    │
│  │  • Continuous Aggregates: vitals_5min, vitals_hourly, daily    │    │
│  │  • Retention Policies: tự động xóa data cũ                    │    │
│  │  ─────────────────────────────────────────────────────────────  │    │
│  │  Hosting: VPS (qua Cloudflare Tunnel) hoặc Heroku Postgres     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER (Clients)                        │
│                                                                         │
│  ┌──────────────────────────┐    ┌──────────────────────────────────┐   │
│  │  MOBILE APP (Flutter)     │    │   ADMIN WEB (React + Vite)       │   │
│  │  ─────────────────────── │    │   ──────────────────────────────  │   │
│  │  State: Provider          │    │   State: TanStack React Query    │   │
│  │  Auth: flutter_secure_    │    │   Styling: TailwindCSS 4         │   │
│  │        storage            │    │   Routing: React Router 7        │   │
│  │  Platform: Android 28+   │    │   Build: Vite 7                  │   │
│  │  Features:                │    │   Features:                      │   │
│  │  • Real-time vitals       │    │   • Dashboard with charts        │   │
│  │  • Fall alert + SOS       │    │   • User CRUD + search           │   │
│  │  • Sleep tracking         │    │   • Device management            │   │
│  │  • Health history charts  │    │   • Alert history                │   │
│  │  • Emergency contacts     │    │   • Audit log viewer             │   │
│  └──────────────────────────┘    └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2. Nguyên tắc kiến trúc (Architecture Principles)

| Nguyên tắc | Mô tả | Áp dụng |
|---|---|---|
| **Separation of Concerns** | Tách biệt Mobile BE và Admin BE thành 2 service độc lập | Mỗi backend chạy trên Heroku dyno riêng |
| **Shared Database** | Cả 2 backend dùng chung 1 PostgreSQL instance | Đảm bảo data consistency, giảm chi phí |
| **API-First** | Mọi giao tiếp qua RESTful API chuẩn | Swagger/OpenAPI documentation |
| **Containerization** | Docker image cho mỗi service | Multi-stage build, tối ưu size |
| **Infrastructure as Code** | CI/CD pipeline tự động | GitHub Actions → Heroku Container Registry |

### 2.3. Luồng dữ liệu chính (Data Flow)

```
Simulator ──(HTTP POST)──▶ Mobile BE ──(INSERT)──▶ PostgreSQL
                               │                      │
                               ├── AI Processing ◀────┘ (SELECT vitals history)
                               │     │
                               │     ├── Fall Detection → Alert
                               │     └── Risk Scoring  → Risk Score + XAI
                               │
                               ├──(Push Notification)──▶ Mobile App
                               │
Mobile App ◀──(GET vitals)──── Mobile BE ◀──(SELECT)── PostgreSQL
                                                            │
Admin Web ──(GET/POST/PUT)──▶ Admin BE ──(Prisma)──────────┘
```

---

## 3. Kiến trúc chi tiết từng thành phần

### 3.1. Mobile Backend — FastAPI (Python)

#### 3.1.1. Cấu trúc thư mục

```
health_system/backend/
├── app/
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Environment configuration
│   ├── database.py             # SQLAlchemy engine & session
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── user.py
│   │   ├── device.py
│   │   ├── vital.py
│   │   └── ...
│   ├── schemas/                # Pydantic request/response schemas
│   │   ├── user.py
│   │   ├── auth.py
│   │   └── ...
│   ├── repositories/           # Data access layer (Repository Pattern)
│   │   ├── user_repository.py
│   │   ├── audit_log_repository.py
│   │   └── ...
│   ├── services/               # Business logic layer
│   │   ├── auth_service.py
│   │   └── ...
│   └── routers/                # API route handlers
│       ├── auth.py
│       ├── vitals.py
│       └── ...
├── tests/                      # Pytest test suite
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Multi-stage Docker build
├── Procfile                    # Heroku process definition
└── run.py                      # Local development runner
```

#### 3.1.2. Design Pattern — Layered Architecture

```
┌─────────────────────────────────────────────────────┐
│  Routers (API Layer)                                 │
│  ─ Nhận HTTP request, validate input, trả response   │
│  ─ Gọi xuống Service layer                           │
├─────────────────────────────────────────────────────┤
│  Services (Business Logic Layer)                     │
│  ─ Xử lý logic nghiệp vụ: auth, AI, risk scoring    │
│  ─ Gọi xuống Repository layer                        │
├─────────────────────────────────────────────────────┤
│  Repositories (Data Access Layer)                    │
│  ─ CRUD operations qua SQLAlchemy                    │
│  ─ Truy vấn database, trả về domain objects          │
├─────────────────────────────────────────────────────┤
│  Models + Schemas                                    │
│  ─ SQLAlchemy Models: mapping Python class ↔ DB table │
│  ─ Pydantic Schemas: validation & serialization       │
├─────────────────────────────────────────────────────┤
│  Database (PostgreSQL + TimescaleDB)                 │
└─────────────────────────────────────────────────────┘
```

#### 3.1.3. Công nghệ chi tiết

| Thành phần | Công nghệ | Phiên bản | Vai trò |
|---|---|---|---|
| Web Framework | FastAPI | 0.116.1 | Async REST API, auto-generate OpenAPI docs |
| ASGI Server | Uvicorn | 0.35.0 | Async server cho FastAPI |
| WSGI Manager | Gunicorn | 21.2.0 | Process manager, multi-worker |
| ORM | SQLAlchemy | 2.0.26 | Object-Relational Mapping, query builder |
| Validation | Pydantic | 2.11.7 | Request/Response schema validation |
| DB Driver | psycopg2-binary | 2.9.9 | PostgreSQL adapter cho Python |
| Auth | python-jose | 3.3.0 | JWT encode/decode |
| Hashing | bcrypt | 4.1.2 | Password hashing |

### 3.2. Admin Backend — Express (Node.js)

#### 3.2.1. Cấu trúc thư mục

```
HealthGuard/backend/
├── src/
│   ├── server.js               # Express app entry point
│   ├── config/                 # Environment & app config
│   ├── controllers/            # Request handlers
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   └── ...
│   ├── services/               # Business logic
│   │   ├── auth.service.js
│   │   ├── user.service.js
│   │   └── ...
│   ├── middleware/              # Express middleware
│   │   ├── auth.js             # JWT verification
│   │   ├── errorHandler.js     # Global error handler
│   │   └── validation.js       # Input sanitization
│   ├── routes/                 # Route definitions
│   ├── utils/                  # Helper utilities
│   └── __tests__/              # Jest test suite
├── prisma/
│   └── schema.prisma           # Database schema definition
├── package.json                # Node.js dependencies
└── (served from HealthGuard/Dockerfile)
```

#### 3.2.2. Design Pattern — MVC + Service Layer

```
┌──────────────────────────────────────────────────────┐
│  Routes (Routing Layer)                               │
│  ─ Định nghĩa endpoint paths, HTTP methods            │
│  ─ Attach middleware (auth, validation)                │
├──────────────────────────────────────────────────────┤
│  Controllers (Controller Layer)                       │
│  ─ Parse request, gọi Service, format response         │
│  ─ Error handling per-endpoint                         │
├──────────────────────────────────────────────────────┤
│  Services (Business Logic Layer)                      │
│  ─ Core logic: authentication, user management         │
│  ─ Gọi Prisma Client để truy vấn DB                   │
├──────────────────────────────────────────────────────┤
│  Prisma ORM (Data Access Layer)                       │
│  ─ Type-safe database queries                          │
│  ─ Auto-generated client từ schema.prisma              │
├──────────────────────────────────────────────────────┤
│  Middleware                                           │
│  ─ auth.js: verify JWT, attach user to req             │
│  ─ errorHandler.js: catch-all error formatting         │
│  ─ express-rate-limit: API rate limiting               │
│  ─ sanitize-html: XSS prevention                      │
└──────────────────────────────────────────────────────┘
```

#### 3.2.3. Công nghệ chi tiết

| Thành phần | Công nghệ | Phiên bản | Vai trò |
|---|---|---|---|
| Web Framework | Express | 5.2.1 | HTTP server, middleware pipeline |
| ORM | Prisma | 6.19.2 | Type-safe DB access, migration, schema |
| Auth | jsonwebtoken | 9.0.3 | JWT sign/verify |
| Hashing | bcryptjs | 3.0.3 | Password hashing (pure JS) |
| Email | nodemailer | 8.0.1 | SMTP email sending |
| Security | sanitize-html | 2.17.1 | XSS prevention |
| Rate Limit | express-rate-limit | 8.3.0 | API rate limiting |
| API Docs | swagger-ui-express | 5.0.1 | Interactive API documentation |
| Testing | Jest | 30.2.0 | Unit & integration tests |

### 3.3. Mobile App — Flutter

#### 3.3.1. Cấu trúc thư mục (Feature-First)

```
health_system/lib/
├── main.dart                   # App entry point
├── app/
│   ├── app.dart                # MaterialApp configuration
│   └── routes.dart             # Navigation routes
├── core/
│   ├── constants/              # App-wide constants
│   ├── theme/                  # ThemeData, colors, typography
│   └── utils/                  # Shared utilities
├── features/
│   ├── auth/                   # Login, Register, Forgot Password
│   │   ├── models/
│   │   ├── providers/          # ChangeNotifier (Provider)
│   │   ├── repositories/       # API calls
│   │   ├── screens/
│   │   └── widgets/
│   ├── home/                   # Home dashboard
│   ├── device/                 # Device pairing & management
│   ├── health_monitoring/      # Real-time vitals display
│   ├── emergency/              # SOS, fall alert, contacts
│   └── ...
└── shared/
    ├── widgets/                # Reusable UI components
    └── services/               # Shared services (HTTP, storage)
```

#### 3.3.2. State Management — Provider Pattern

```
┌──────────────────────────────────────────────┐
│  Screen (Widget)                              │
│  ─ Consumer<T> / context.watch<T>()           │
│  ─ Lắng nghe thay đổi từ Provider             │
├──────────────────────────────────────────────┤
│  Provider (ChangeNotifier)                    │
│  ─ Quản lý state: loading, data, error        │
│  ─ Gọi Repository để fetch/push data          │
│  ─ notifyListeners() khi state thay đổi       │
├──────────────────────────────────────────────┤
│  Repository                                   │
│  ─ HTTP calls đến Mobile Backend               │
│  ─ Parse JSON → Model objects                   │
├──────────────────────────────────────────────┤
│  Model                                        │
│  ─ Dart class đại diện cho domain entity       │
│  ─ fromJson() / toJson() serialization         │
└──────────────────────────────────────────────┘
```

### 3.4. Admin Frontend — React

#### 3.4.1. Công nghệ

| Thành phần | Công nghệ | Phiên bản | Vai trò |
|---|---|---|---|
| UI Library | React | 19 | Component-based UI |
| Build Tool | Vite | 7 | Lightning-fast HMR, optimized bundling |
| Styling | TailwindCSS | 4 | Utility-first CSS framework |
| Routing | React Router | 7 | Client-side routing |
| Server State | TanStack React Query | - | Data fetching, caching, sync |

#### 3.4.2. Deployment Model

Admin Frontend được **build thành static files** (HTML/CSS/JS) bằng Vite, sau đó:

- Được **served trực tiếp bởi Admin Backend** (Express) qua `express.static()`
- Frontend build output nằm ở `/app/frontend/dist/` trong Docker container
- **Không cần web server riêng** (Nginx, Apache) — Express xử lý cả API lẫn static files

---

## 4. Thiết kế cơ sở dữ liệu

### 4.1. Tổng quan

| Thuộc tính | Giá trị |
|---|---|
| **DBMS** | PostgreSQL 17 |
| **Extension** | TimescaleDB (time-series optimization) |
| **Schema management** | SQL Scripts (thủ công) + Prisma (Admin BE) |
| **Shared access** | Mobile BE (SQLAlchemy) + Admin BE (Prisma) cùng truy cập |

### 4.2. Entity-Relationship Diagram (ERD)

```
┌──────────────┐     1:N     ┌─────────────────┐     1:N     ┌──────────────┐
│    users      │────────────▶│    devices        │────────────▶│   vitals      │
│──────────────│             │─────────────────│             │──────────────│
│ id (PK)      │             │ id (PK)          │             │ id (PK)      │
│ uuid         │             │ uuid             │             │ time (PK)    │
│ email        │             │ user_id (FK)     │             │ device_id(FK)│
│ full_name    │             │ device_name      │             │ heart_rate   │
│ password_hash│             │ device_type      │             │ spo2         │
│ role         │             │ model            │             │ systolic_bp  │
│ date_of_birth│             │ firmware_version │             │ diastolic_bp │
│ gender       │             │ mac_address      │             │ temperature  │
│ phone        │             │ is_active        │             │ hrv          │
│ is_active    │             │ battery_level    │             │ steps        │
│ created_at   │             │ last_seen_at     │             │ is_anomaly   │
└──────┬───────┘             │ mqtt_client_id   │             └──────────────┘
       │                     └────────┬─────────┘                  ▲
       │                              │                            │
       │ 1:N                          │ 1:N                  *Hypertable*
       ▼                              ▼
┌──────────────────┐          ┌──────────────────┐
│emergency_contacts │          │  fall_events      │
│──────────────────│          │──────────────────│
│ id (PK)          │          │ id (PK)          │
│ user_id (FK)     │          │ uuid             │
│ name             │          │ device_id (FK)   │
│ phone            │          │ detected_at      │
│ relationship     │          │ confidence       │
│ priority         │          │ latitude         │
│ notify_via_sms   │          │ longitude        │
│ notify_via_call  │          │ user_cancelled   │
└──────────────────┘          │ sos_triggered    │
                              └────────┬─────────┘
       │                               │ 1:N
       │ 1:N                           ▼
       ▼                        ┌──────────────┐        ┌─────────────────┐
┌────────────────────┐          │  sos_events   │        │  risk_scores    │
│ user_relationships  │          │──────────────│        │─────────────────│
│────────────────────│          │ id (PK)      │        │ id (PK)         │
│ id (PK)            │          │ uuid         │        │ device_id (FK)  │
│ user_id (FK)       │          │ device_id(FK)│        │ score           │
│ related_user_id(FK)│          │ triggered_at │        │ level           │
│ relationship_type  │          │ latitude     │        │ model_version   │
│ is_approved        │          │ longitude    │        │ features        │
└────────────────────┘          │ status       │        │ created_at      │
                                │ resolved_at  │        └─────────────────┘
                                └──────────────┘               │ 1:N
                                                               ▼
┌──────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   alerts          │     │  motion_data      │     │  risk_explanations   │
│──────────────────│     │──────────────────│     │─────────────────────│
│ id (PK)          │     │ id (PK)          │     │ id (PK)             │
│ uuid             │     │ time (PK)        │     │ risk_score_id (FK)  │
│ user_id (FK)     │     │ device_id (FK)   │     │ factor_name         │
│ alert_type       │     │ accel_x/y/z      │     │ factor_value        │
│ title            │     │ gyro_x/y/z       │     │ contribution        │
│ severity         │     │ fall_detected    │     │ explanation         │
│ sent_at          │     │ activity_type    │     └─────────────────────┘
│ read_at          │     └──────────────────┘
│ sent_via[]       │           ▲
└──────────────────┘      *Hypertable*

┌──────────────────┐     ┌──────────────────┐
│   audit_logs      │     │ system_settings   │
│──────────────────│     │──────────────────│
│ id (PK)          │     │ id (PK)          │
│ time (PK)        │     │ key              │
│ user_id (FK)     │     │ value            │
│ action           │     │ category         │
│ resource_type    │     │ updated_by       │
│ details (JSON)   │     │ updated_at       │
│ ip_address       │     └──────────────────┘
│ status           │
└──────────────────┘
       ▲
  *Hypertable*
```

### 4.3. TimescaleDB — Hypertable & Continuous Aggregates

**Hypertables** tự động phân vùng (chunk) dữ liệu time-series theo thời gian, tối ưu cho:
- **Ghi nhanh**: INSERT hàng triệu rows/ngày từ IoT sensors
- **Truy vấn nhanh**: Tự động chỉ scan chunks cần thiết
- **Retention policies**: Tự động xóa data cũ

| Hypertable | Chunk Interval | Retention | Mô tả |
|---|---|---|---|
| `vitals` | 1 ngày | 90 ngày | Dữ liệu sinh hiệu mỗi phút |
| `motion_data` | 1 ngày | 30 ngày | Accelerometer + Gyroscope |
| `audit_logs` | 7 ngày | 365 ngày | Log thao tác hệ thống |

**Continuous Aggregates** — View tự động cập nhật:

| Aggregate | Source | Interval | Mục đích |
|---|---|---|---|
| `vitals_5min` | vitals | 5 phút | Biểu đồ real-time |
| `vitals_hourly` | vitals | 1 giờ | Biểu đồ 24h |
| `vitals_daily` | vitals | 1 ngày | Biểu đồ tuần/tháng |

### 4.4. Indexing Strategy

```sql
-- Performance-critical indexes
CREATE INDEX idx_vitals_device_time ON vitals (device_id, time DESC);
CREATE INDEX idx_alerts_user        ON alerts (user_id, created_at DESC);
CREATE INDEX idx_alerts_type        ON alerts (alert_type, created_at DESC);
CREATE INDEX idx_devices_user       ON devices (user_id);
CREATE INDEX idx_devices_uuid       ON devices (uuid);
CREATE INDEX idx_devices_mqtt       ON devices (mqtt_client_id);
CREATE INDEX idx_fall_events_device ON fall_events (device_id, detected_at DESC);
CREATE INDEX idx_audit_logs_user    ON audit_logs (user_id, time DESC);
CREATE INDEX idx_audit_logs_action  ON audit_logs (action, time DESC);
```

---

## 5. Thiết kế API & API Gateway

### 5.1. API Architecture Overview

Hệ thống sử dụng mô hình **Dual-Backend API** được định tuyến qua một **API Gateway (Nginx Container)** giúp tập trung quản lý CORS, Proxy và OpenAPI Docs:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY LAYER (NGINX)                       │
│  (Nginx Container - Port 80, routing to Heroku / Upstream)             │
│                                                                        │
│                  ┌──────── /api/v1/mobile/* ───────┐                   │
│                  ├──────── /mobile-docs     ───────┤                   │
│                  │                                 │                   │
│                  │       ┌─ /api/v1/admin/* ─┐     │                   │
│                  │       ├─ /admin-docs     ─┤     │                   │
│                  ▼                           ▼                         │
│  ┌────────────────────────────┐  ┌──────────────────────────────────┐  │
│  │ mobile-be.herokuapp.com    │  │ admin-be.herokuapp.com           │  │
│  │ (FastAPI Mobile Backend)   │  │ (Express + React SPA)            │  │
│  │ ───────────────────────────│  │ ─────────────────────────────────│  │
│  │ /api/v1/mobile/...         │  │ /api/v1/admin/...                │  │
│  │ /mobile-docs               │  │ /admin-docs                      │  │
│  │ /api/v1/mobile-openapi.json│  │ /health                          │  │
│  │                            │  │ /* (React SPA fallback)          │  │
│  └────────────────────────────┘  └──────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.2. API Versioning

- **Prefix**: `/api/v1/` cho tất cả endpoints
- **Strategy**: URL-based versioning (dễ maintain, dễ routing)
- **Breaking changes**: Tạo `/api/v2/` mới, giữ `/api/v1/` backward-compatible

### 5.3. Authentication Flow

```
┌────────┐                    ┌──────────┐                  ┌────────┐
│ Client  │                    │ Backend   │                  │   DB   │
└───┬────┘                    └────┬─────┘                  └───┬────┘
    │  POST /api/v1/auth/login     │                            │
    │  { email, password }         │                            │
    │─────────────────────────────▶│                            │
    │                              │  SELECT user WHERE email   │
    │                              │───────────────────────────▶│
    │                              │  user record               │
    │                              │◀───────────────────────────│
    │                              │                            │
    │                              │  bcrypt.compare(password)  │
    │                              │  jwt.sign({ user_id,       │
    │                              │    role, issuer })          │
    │                              │                            │
    │  { access_token, user }      │                            │
    │◀─────────────────────────────│                            │
    │                              │                            │
    │  GET /api/v1/vitals          │                            │
    │  Authorization: Bearer <jwt> │                            │
    │─────────────────────────────▶│                            │
    │                              │  jwt.verify(token)         │
    │                              │  → extract user_id, role   │
    │                              │  SELECT vitals...          │
    │                              │───────────────────────────▶│
    │  { vitals_data }             │                            │
    │◀─────────────────────────────│◀───────────────────────────│
```

**JWT Configuration:**

| Thuộc tính | Mobile BE | Admin BE |
|---|---|---|
| **Issuer** | `healthguard-mobile` | `healthguard-admin` |
| **Expiry** | 30 ngày (access) + refresh | 8 giờ |
| **Algorithm** | HS256 | HS256 |
| **Storage (client)** | `flutter_secure_storage` | `httpOnly cookie` |

### 5.4. API Response Format

**Success Response:**

```json
{
  "status": "ok",
  "data": { ... },
  "message": "Operation successful"
}
```

**Error Response:**

```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [...]
  }
}
```

### 5.5. Rate Limiting

| Endpoint Group | Limit | Window |
|---|---|---|
| Auth (login/register) | 10 requests | 15 phút |
| General API | 100 requests | 1 phút |
| Vitals ingestion | 60 requests | 1 phút |

---

## 6. Kĩ thuật và công nghệ sử dụng

### 6.1. Tổng hợp Tech Stack

| Layer | Công nghệ | Phiên bản | Ghi chú |
|---|---|---|---|
| **Mobile App** | Flutter / Dart | SDK ^3.11.0 | Cross-platform (Android 28+) |
| **Mobile State** | Provider | - | ChangeNotifier pattern |
| **Mobile Auth** | flutter_secure_storage | - | Lưu JWT an toàn trên device |
| **Mobile Backend** | Python + FastAPI | 3.11 / 0.116.1 | Async REST API |
| **Mobile ORM** | SQLAlchemy | 2.0.26 | Mature Python ORM |
| **Mobile Server** | Gunicorn + Uvicorn | 21.2.0 / 0.35.0 | Multi-worker ASGI |
| **Admin Frontend** | React + Vite | 19 / 7 | SPA, HMR, optimized build |
| **Admin Styling** | TailwindCSS | 4 | Utility-first CSS |
| **Admin State** | TanStack React Query | - | Server state management |
| **API Gateway** | Nginx | Alpine | Reverse proxy, routing & CORS |
| **Admin Backend** | Node.js + Express | 20 / 5.2.1 | Lightweight HTTP server |
| **Admin ORM** | Prisma | 6.19.2 | Type-safe, auto-generated |
| **Database** | PostgreSQL | 17 | ACID-compliant RDBMS |
| **Time-series** | TimescaleDB | - | Hypertables, aggregates |
| **Containerization** | Docker | Multi-stage | Lightweight production images |
| **CI/CD** | GitHub Actions | v4 | Automated test + deploy |
| **Cloud Hosting** | Heroku | Container Stack | Docker-based deployment |
| **Tunneling** | Cloudflare Tunnel | - | Expose VPS services securely |
| **API Docs** | Swagger / OpenAPI | 3.0 | Auto-generated documentation |
| **Testing (Python)** | pytest | 8.0.0 | Unit + integration tests |
| **Testing (Node)** | Jest | 30.2.0 | Unit + integration tests |
| **Code Quality** | black, flake8, isort, mypy | - | Python linting & formatting |

### 6.2. Quyết định kĩ thuật quan trọng (Key Technical Decisions)

#### Tại sao **2 backend riêng biệt** thay vì monolith?

| Tiêu chí | Monolith | Dual-Backend (chọn) |
|---|---|---|
| **Separation of Concerns** | ❌ Code admin lẫn mobile | ✅ Tách biệt hoàn toàn |
| **Deploy independence** | ❌ Deploy 1 = ảnh hưởng cả 2 | ✅ Deploy riêng, rollback riêng |
| **Tech stack flexibility** | ❌ Buộc 1 ngôn ngữ | ✅ Python (AI) + Node.js (CRUD) |
| **Scaling** | ❌ Scale cả khối | ✅ Scale từng service |
| **Team ownership** | ❌ Conflict merge | ✅ Repo riêng, team riêng |

#### Tại sao **Shared Database** thay vì DB riêng?

| Tiêu chí | Separate DB | Shared DB (chọn) |
|---|---|---|
| **Data consistency** | ❌ Cần sync mechanism | ✅ Single source of truth |
| **Chi phí** | ❌ 2× cost | ✅ 1 instance |
| **Complexity** | ❌ Data replication, events | ✅ Simple |
| **Trade-off** | Isolation tốt hơn | Chấp nhận schema coupling |

#### Tại sao **TimescaleDB** cho IoT data?

- **10-100× faster** queries trên time-series data so với vanilla PostgreSQL
- **Hypertable compression**: giảm 90%+ storage cho vitals data
- **Continuous aggregates**: pre-computed rollups, zero application code
- **Retention policies**: tự động garbage collection
- **Fully SQL-compatible**: không cần học query language mới

---

## 7. Docker Build & Containerization

### 7.1. Chiến lược Docker Build

Cả 2 backend đều sử dụng **Multi-stage Docker Build** để tối ưu image size và bảo mật:

#### 7.1.1. Mobile Backend — Dockerfile

```dockerfile
# ── Stage 1: Builder ──────────────────────────────
FROM python:3.11-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install \
    --only-binary=:all: -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ ./app/
COPY run.py .
CMD gunicorn app.main:app \
    -w 2 -k uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:${PORT:-8080} \
    --timeout 120 --access-logfile - --error-logfile -
```

**Giải thích từng kĩ thuật:**

| Kĩ thuật | Mục đích |
|---|---|
| `python:3.11-slim` | Base image nhẹ (~150MB thay vì ~900MB full) |
| `--prefix=/install` | Cài deps vào thư mục riêng, chỉ copy artifacts |
| `--only-binary=:all:` | Dùng pre-built wheels, skip compile from source |
| `PYTHONDONTWRITEBYTECODE=1` | Không tạo `.pyc` files, giảm image size |
| `PYTHONUNBUFFERED=1` | Log output real-time (không buffer) |
| `2 workers` | Phù hợp Heroku Eco dyno (512MB RAM) |
| `${PORT:-8080}` | Heroku inject `$PORT` runtime, fallback 8080 local |

#### 7.1.2. Admin System — Dockerfile (3-Stage)

```dockerfile
# ── Stage 1: Build Frontend (React + Vite) ────────
FROM node:20-alpine AS build-frontend
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build     # → Output: /build/frontend/dist/

# ── Stage 2: Build Backend (Express + Prisma) ─────
FROM node:20-alpine AS build-backend
RUN apk add --no-cache openssl
WORKDIR /build/backend
COPY backend/package.json backend/package-lock.json ./
RUN npm ci
COPY backend/prisma/ ./prisma/
RUN DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy" \
    npx prisma generate
RUN npm prune --omit=dev   # Xóa devDependencies

# ── Stage 3: Production ───────────────────────────
FROM node:20-alpine AS production
RUN apk add --no-cache openssl dumb-init
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build-frontend /build/frontend/dist/ ./frontend/dist/
COPY --from=build-backend  /build/backend/node_modules/ ./backend/node_modules/
COPY --from=build-backend  /build/backend/prisma/ ./backend/prisma/
COPY --from=build-backend  /build/backend/src/ ./backend/src/
COPY --from=build-backend  /build/backend/package.json ./backend/package.json
WORKDIR /app/backend
USER node
CMD ["dumb-init", "node", "src/server.js"]
```

**Giải thích kĩ thuật:**

| Kĩ thuật | Mục đích |
|---|---|
| **3-stage build** | Frontend build tools + backend devDeps không vào final image |
| `node:20-alpine` | Alpine Linux (~5MB) thay vì Debian (~150MB) |
| `npm ci` | Deterministic install từ lockfile (CI/CD best practice) |
| `npm prune --omit=dev` | Xóa Prisma CLI, Jest, Nodemon khỏi production |
| `dumb-init` | PID 1 process manager — graceful shutdown, signal forwarding |
| `USER node` | **Non-root** container — security best practice |
| Dummy `DATABASE_URL` | Prisma generate chỉ cần schema, không cần real DB |
| Monorepo path structure | `frontend/dist/` + `backend/src/` giữ relative path hoạt động |

### 7.2. Docker Image Size Comparison

| Image | Unoptimized (est.) | Optimized (Multi-stage) | Giảm |
|---|---|---|---|
| Mobile BE | ~1.2 GB | ~250 MB | **~80%** |
| Admin System | ~1.5 GB | ~300 MB | **~80%** |

---

## 8. CI/CD Pipeline

### 8.1. Tổng quan Pipeline

```
┌─────────┐    push/merge     ┌──────────┐     ┌────────────┐     ┌────────────┐
│  GitHub  │──────────────────▶│   Test    │────▶│   Build    │────▶│   Deploy   │
│  (code)  │  to `deploy`     │  (pytest/ │     │  (Docker   │     │  (Heroku   │
│          │  branch           │   jest)   │     │   build)   │     │   release) │
└─────────┘                    └──────────┘     └────────────┘     └─────┬──────┘
                                                                        │
                                                                        ▼
                                                                  ┌────────────┐
                                                                  │ Smoke Test │
                                                                  │ (curl API  │
                                                                  │  endpoints)│
                                                                  └────────────┘
```

### 8.2. Mobile Backend — CD Pipeline

**Trigger:** Push to `deploy` branch hoặc merged PR to `deploy`

| Job | Steps | Mô tả |
|---|---|---|
| **🧪 Test** | `pytest tests/ -v` | Chạy test suite với PostgreSQL 17 service container |
| **🚀 Build & Deploy** | Docker build → push → release | Build image, push lên Heroku Container Registry, release |
| **🔥 Smoke Test** | curl `/api/v1/health`, `/docs` | Verify deployed API responds correctly |

**CI Services:**

```yaml
services:
  postgres:
    image: postgres:17
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: test_db
    ports: ["5432:5432"]
```

### 8.3. Admin System — CD Pipeline

**Trigger:** Push to `deploy` branch

| Job | Steps | Mô tả |
|---|---|---|
| **🚀 Build & Deploy** | Docker build → push → release | 3-stage build, push to registry |
| **🔥 Smoke Test** | curl `/health`, `/api/v1`, `/`, `/api-docs` | Verify API + Frontend + Swagger |

### 8.4. Deployment Flow (Heroku Container Registry)

```
1. docker build -t registry.heroku.com/$APP/web .
2. docker push registry.heroku.com/$APP/web
3. curl -X PATCH heroku.com/apps/$APP/formation
   → { "updates": [{ "type": "web", "docker_image": "$IMAGE_ID" }] }
4. Heroku pulls image → starts container → routes traffic
```

**Secrets (GitHub Actions):**

| Secret | Mô tả |
|---|---|
| `HEROKU_API_KEY` | Heroku account API key (Settings → Reveal) |
| `HEROKU_APP_NAME` | Tên Heroku app (e.g., `healthguard-mobile-be`) |
| `HEROKU_APP_URL` | URL đầy đủ (e.g., `https://healthguard-mobile-be-xxx.herokuapp.com`) |

---

## 9. Heroku Deployment

### 9.1. Kiến trúc Heroku

```
┌─────────────────────────────────────────────────────────────┐
│                     HEROKU PLATFORM                          │
│                                                              │
│  ┌──────────────────────┐    ┌────────────────────────────┐  │
│  │ App: mobile-backend   │    │ App: admin-system          │  │
│  │ ────────────────────  │    │ ──────────────────────────│  │
│  │ Stack: Container      │    │ Stack: Container           │  │
│  │ Dyno: Eco (512MB)    │    │ Dyno: Eco (512MB)          │  │
│  │ Process: web          │    │ Process: web               │  │
│  │ ────────────────────  │    │ ──────────────────────────│  │
│  │ Runtime:              │    │ Runtime:                   │  │
│  │  gunicorn + uvicorn   │    │  dumb-init + node          │  │
│  │  2 workers            │    │  1 process                 │  │
│  │ ────────────────────  │    │ ──────────────────────────│  │
│  │ Add-ons:              │    │ Add-ons:                   │  │
│  │  heroku-postgresql    │    │  (shares DB with mobile)   │  │
│  │  (mini / essential-0) │    │                            │  │
│  └──────────────────────┘    └────────────────────────────┘  │
│                                                              │
│  Environment Variables (Config Vars):                        │
│  ─ DATABASE_URL (auto-set by Heroku Postgres add-on)         │
│  ─ SECRET_KEY                                                │
│  ─ ALGORITHM=HS256                                           │
│  ─ ACCESS_TOKEN_EXPIRE_DAYS=30                               │
└─────────────────────────────────────────────────────────────┘
```

### 9.2. Heroku-specific Configurations

| Cấu hình | Giá trị | Lý do |
|---|---|---|
| **Stack** | Container (Docker) | Custom runtime, multi-stage build |
| **Dyno type** | Eco ($5/month) | Development/staging tier |
| **Workers** | 2 (Mobile BE) | Fit trong 512MB RAM limit |
| **Port** | `$PORT` (runtime injected) | Heroku không dùng fixed port |
| **Procfile** | `web: gunicorn ...` | Fallback nếu không dùng Docker |
| **Sleep** | 30 phút không traffic | Eco dyno tự sleep, cold start ~10s |

### 9.3. Heroku Postgres

| Thuộc tính | Giá trị |
|---|---|
| **Plan** | Mini ($5/mo) hoặc Essential-0 ($7/mo) |
| **Max connections** | 20 (Mini) / 20 (Essential-0) |
| **Storage** | 1 GB (Mini) / 1 GB (Essential-0) |
| **Connection string** | Auto-set via `DATABASE_URL` config var |
| **SSL** | Required (Heroku enforces) |

---

## 10. Cloudflare Tunnels

### 10.1. Tổng quan

**Cloudflare Tunnel** (trước đây là Argo Tunnel) cho phép **expose service trên VPS ra internet** mà **không cần mở port, không cần public IP, không cần firewall rules**.

### 10.2. Kiến trúc Cloudflare Tunnel

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Client (Mobile App / Browser)                             │  │
│  │  → https://db.healthguard.example.com                      │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │ HTTPS                               │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Cloudflare Edge Network                                   │  │
│  │  ─ DDoS protection                                        │  │
│  │  ─ WAF (Web Application Firewall)                         │  │
│  │  ─ SSL termination                                        │  │
│  │  ─ DNS routing (CNAME → tunnel)                           │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │ Encrypted Tunnel                    │
│                            │ (outbound-only from VPS)            │
└────────────────────────────┼────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                        VPS (Private)                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  cloudflared daemon                                       │  │
│  │  ─ Maintains persistent tunnel to Cloudflare Edge         │  │
│  │  ─ Routes incoming requests to local services             │  │
│  │  ─ Zero inbound ports required                            │  │
│  └───────────────────────┬──────────────────────────────────┘  │
│                          │ localhost:5432                       │
│                          ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PostgreSQL 17 + TimescaleDB                              │  │
│  │  ─ Chỉ listen trên 127.0.0.1 (localhost)                 │  │
│  │  ─ Không expose bất kỳ port nào ra ngoài                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### 10.3. Ưu điểm của Cloudflare Tunnel

| Ưu điểm | Mô tả |
|---|---|
| **Zero inbound ports** | VPS không cần mở port 5432 ra internet |
| **DDoS protection** | Cloudflare Edge chặn DDoS attacks miễn phí |
| **Auto SSL/TLS** | HTTPS tự động, không cần quản lý certificates |
| **WAF** | Web Application Firewall lọc malicious requests |
| **No public IP required** | VPS có thể nằm sau NAT/firewall |
| **Miễn phí** | Free tier đủ cho development/staging |

### 10.4. Cấu hình Cloudflare Tunnel

```yaml
# config.yml (cloudflared)
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: db.healthguard.example.com
    service: tcp://localhost:5432
  - service: http_status:404
```

**Lệnh setup:**

```bash
# 1. Cài cloudflared trên VPS
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# 2. Login & tạo tunnel
cloudflared tunnel login
cloudflared tunnel create healthguard-db

# 3. Cấu hình DNS
cloudflared tunnel route dns healthguard-db db.healthguard.example.com

# 4. Chạy tunnel (systemd service)
cloudflared service install
systemctl start cloudflared
```

---

## 11. Database Hosting trên VPS

### 11.1. Kiến trúc VPS Database

```
┌──────────────────────────────────────────────────────────────┐
│  VPS (Ubuntu 22.04 LTS)                                      │
│  ─ RAM: 2GB+ (recommended 4GB)                               │
│  ─ Disk: SSD 40GB+                                           │
│  ─ CPU: 2 vCPU+                                              │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL 17                                            │ │
│  │  ─ Listen: 127.0.0.1:5432 (localhost only)               │ │
│  │  ─ max_connections: 100                                   │ │
│  │  ─ shared_buffers: 512MB                                  │ │
│  │  ─ effective_cache_size: 1.5GB                            │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │  TimescaleDB Extension                                    │ │
│  │  ─ Hypertables: vitals, motion_data, audit_logs          │ │
│  │  ─ Continuous Aggregates: vitals_5min/hourly/daily       │ │
│  │  ─ Compression: enabled (7-day policy)                   │ │
│  │  ─ Retention: 30d motion, 90d vitals, 365d audit         │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │  Backup Strategy                                          │ │
│  │  ─ pg_dump daily (cron 02:00 UTC)                        │ │
│  │  ─ WAL archiving for point-in-time recovery              │ │
│  │  ─ Backup upload to cloud storage                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  cloudflared                                              │ │
│  │  ─ Tunnel PostgreSQL port qua Cloudflare                 │ │
│  │  ─ Systemd managed service                               │ │
│  │  ─ Auto-restart on failure                               │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Security Hardening                                       │ │
│  │  ─ UFW: deny all inbound (chỉ SSH 22)                   │ │
│  │  ─ fail2ban: brute-force protection                      │ │
│  │  ─ unattended-upgrades: auto security patches            │ │
│  │  ─ PostgreSQL: md5/scram-sha-256 auth                    │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 11.2. PostgreSQL Configuration (Tuning)

```ini
# postgresql.conf — optimized for IoT workload

# Memory
shared_buffers = 512MB              # 25% of RAM
effective_cache_size = 1536MB       # 75% of RAM
work_mem = 16MB
maintenance_work_mem = 128MB

# WAL & Checkpoint
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB

# Query Planner
random_page_cost = 1.1              # SSD optimization
effective_io_concurrency = 200      # SSD parallel reads

# Connections
max_connections = 100
```

### 11.3. So sánh: VPS DB vs Heroku Postgres

| Tiêu chí | VPS + Cloudflare Tunnel | Heroku Postgres |
|---|---|---|
| **Chi phí** | ~$5-10/mo (VPS) + free tunnel | $5-7/mo (Mini/Essential) |
| **Storage** | 40GB+ SSD | 1 GB (Mini) |
| **Connections** | 100+ (configurable) | 20 (hard limit) |
| **TimescaleDB** | ✅ Full support | ❌ Không hỗ trợ extension |
| **Control** | ✅ Full (tuning, backup) | ❌ Managed, limited config |
| **Uptime** | Phụ thuộc VPS provider | 99.5% SLA |
| **Setup** | Thủ công (cài đặt, bảo mật) | 1 click |
| **Use case** | *Production với IoT data lớn* | *Prototype/staging* |

---

## 12. Bảo mật hệ thống

### 12.1. Authentication & Authorization

| Layer | Mechanism | Chi tiết |
|---|---|---|
| **Password storage** | bcrypt (cost factor 10) | Salted hash, timing-attack resistant |
| **Token-based auth** | JWT (HS256) | Stateless, signed tokens |
| **Token storage** | `flutter_secure_storage` (mobile), `httpOnly cookie` (web) | Chống XSS token theft |
| **Role-based access** | `role` field trong JWT payload | `patient`, `caregiver`, `admin` |

### 12.2. Transport Security

| Layer | Mechanism |
|---|---|
| **HTTPS** | TLS 1.3 (enforced by Heroku & Cloudflare) |
| **Database connection** | SSL required (Heroku Postgres) |
| **Cloudflare Tunnel** | Encrypted tunnel (no exposed ports) |

### 12.3. Input Validation & Sanitization

| Layer | Tool | Mục đích |
|---|---|---|
| Mobile BE | Pydantic V2 | Type validation, schema enforcement |
| Admin BE | sanitize-html | Strip malicious HTML/JS |
| Admin BE | express-rate-limit | Rate limiting (brute force prevention) |
| Database | CHECK constraints | Data integrity at DB level |

### 12.4. Security Headers & Policies

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
```

---

## 13. Monitoring & Logging

### 13.1. Health Check Endpoints

| Backend | Endpoint | Response |
|---|---|---|
| Mobile BE | `GET /api/v1/health` | `{ "status": "ok" }` |
| Admin BE | `GET /health` | `{ "status": "ok" }` |

### 13.2. Logging Strategy

| Layer | Tool | Output |
|---|---|---|
| Mobile BE | Gunicorn access log | stdout (Heroku Logplex captures) |
| Mobile BE | Python `logging` | Application-level events |
| Admin BE | Node.js `console` | stdout → Heroku Logplex |
| Database | `audit_logs` table | User actions, API calls, errors |

### 13.3. Audit Log Schema

Mọi thao tác quan trọng đều được ghi vào bảng `audit_logs`:

```json
{
  "time": "2026-03-12T10:30:00Z",
  "user_id": 42,
  "action": "USER_LOGIN",
  "resource_type": "auth",
  "details": { "ip": "103.x.x.x", "method": "password" },
  "ip_address": "103.x.x.x",
  "user_agent": "Flutter/3.11",
  "status": "success"
}
```

---

## 14. Phụ lục

### 14.1. Danh sách tài liệu liên quan

| Tài liệu | Đường dẫn |
|---|---|
| **SRS v1.0** | `PM_REVIEW/Resources/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (2).md` |
| **SRS Index** | `PM_REVIEW/Resources/SRS_INDEX.md` |
| **Use Cases** | `PM_REVIEW/Resources/UC/` |
| **JIRA Tasks** | `PM_REVIEW/Resources/TASK/JIRA/` |
| **SQL Scripts** | `PM_REVIEW/SQL SCRIPTS/`, `health_system/SQL SCRIPTS/` |
| **Deploy Guide (Mobile)** | `health_system/DEPLOY_HEROKU.md` |
| **Deploy Guide (Admin)** | `HealthGuard/DEPLOY_GUIDE.md` |

### 14.2. Environment Variables

#### Mobile Backend

| Variable | Required | Mô tả |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SECRET_KEY` | ✅ | JWT signing secret |
| `ALGORITHM` | ✅ | JWT algorithm (HS256) |
| `ACCESS_TOKEN_EXPIRE_DAYS` | ✅ | JWT expiry (default: 30) |
| `PORT` | Auto | Heroku injects at runtime |

#### Admin Backend

| Variable | Required | Mô tả |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `JWT_SECRET` | ✅ | JWT signing secret |
| `NODE_ENV` | ✅ | `production` / `development` |
| `PORT` | Auto | Heroku injects at runtime |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` | Optional | Email notifications |

### 14.3. Lịch sử phiên bản tài liệu

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| **1.0** | 12/03/2026 | Bản đầu tiên — đầy đủ kiến trúc, kĩ thuật, deployment |

---

> *Tài liệu này được duy trì bởi HealthGuard Development Team. Mọi thay đổi kiến trúc cần được cập nhật vào SDD trước khi triển khai.*
