# 📋 TRELLO CARDS - SPRINT 1: NỀN TẢNG & AUTH

> **Sprint 1**: 22/01 - 05/02  
> **Mục tiêu**: Setup infrastructure, database, authentication cơ bản  
> **Kiến trúc BE**: Admin (Node.js/Express + Prisma) + Mobile (FastAPI + SQLAlchemy), shared PostgreSQL

---

## 🎯 CARD 1: [Infra] Setup Database & TimescaleDB

**TITLE**: `[Infra] Setup Database & TimescaleDB`

**DESCRIPTION**:
```
Setup PostgreSQL + TimescaleDB extension, chạy tất cả SQL scripts từ SQL SCRIPTS/
- 01_init_timescaledb.sql
- 02_create_tables_user_management.sql
- 03_create_tables_devices.sql
- 04_create_tables_timeseries.sql
- 05_create_tables_events_alerts.sql
- 06_create_tables_ai_analytics.sql
- 07_create_tables_system.sql
- 08_create_indexes.sql
- 09_create_policies.sql

Verify: Tất cả tables, indexes, policies đã được tạo thành công.
```

**LABELS**:
- Module: `Infra`
- Role: `Backend`
- Priority: `High`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review SQL scripts đã đúng với SRS & Technical Spec
- [ ] Verify schema mapping với UC requirements

✅ **Admin BE Dev ([Admin BE Dev])**
- [ ] Setup PostgreSQL + TimescaleDB extension trên dev environment
- [ ] Chạy tuần tự các file SQL scripts (01 → 09)
- [ ] Verify tất cả tables đã tạo: `users`, `devices`, `vitals`, `motion_data`, `fall_events`, `sos_events`, `alerts`, `risk_scores`, `risk_explanations`, `audit_logs`, `system_metrics`
- [ ] Verify indexes đã tạo (44 indexes)
- [ ] Verify compression/retention policies đã active
- [ ] Test insert sample data vào mỗi table
- [ ] Document connection string, credentials (cho team)

✅ **Mobile BE Dev ([Mobile BE Dev])**
- [ ] Review database schema để hiểu structure
- [ ] Test kết nối PostgreSQL từ FastAPI (SQLAlchemy)
- [ ] Chuẩn bị SQLAlchemy models reflect từ DB

✅ **AI Dev ([AI Dev])**
- [ ] Review schema cho `vitals`, `motion_data`, `risk_scores` (sẽ dùng cho AI)
- [ ] Verify TimescaleDB hypertables hoạt động đúng

✅ **Tester ([Tester Name])**
- [ ] Verify database connection từ cả 2 backend
- [ ] Test CRUD operations trên sample tables
- [ ] Verify TimescaleDB continuous aggregates refresh đúng

**ACCEPTANCE CRITERIA**:
- [ ] Tất cả 11 tables đã được tạo thành công
- [ ] 44 indexes đã được tạo
- [ ] Compression/retention policies đã active
- [ ] Sample data insert thành công
- [ ] Cả Admin BE và Mobile BE đều connect và query được

**NOTES**:
- Cần setup trên cả local dev và staging environment
- Document connection string cho team
- SQL SCRIPTS/ là **single source of truth** cho DB schema — cả 2 BE KHÔNG tự tạo migration

---

## 🎯 CARD 2A: [Infra] Setup Admin Backend (Node.js)

**TITLE**: `[Infra] Setup Admin Backend - Node.js/Express + Prisma`

**DESCRIPTION**:
```
Setup Admin Backend project structure cho Web Admin Dashboard.
Tech: Node.js, Express.js, Prisma ORM, TypeScript.
Phục vụ: Admin Web (ReactJS).
```

**LABELS**:
- Module: `Infra`
- Role: `Admin Backend`
- Priority: `High`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Approve project structure

✅ **Admin BE Dev ([Admin BE Dev])**
- [ ] Setup Express + TypeScript project (đã có cơ bản trong `HealthGuard/backend/`)
- [ ] Verify Prisma Client connect tới PostgreSQL
- [ ] Chạy `npx prisma db pull` để introspect DB schema
- [ ] Setup CORS middleware (allow Admin Web origin)
- [ ] Setup logging (file + console)
- [ ] Setup environment variables (.env): DB_URL, JWT_SECRET, PORT
- [ ] Create basic health check endpoint: `GET /health`
- [ ] Setup Swagger docs (swagger-jsdoc + swagger-ui-express)
- [ ] Document API prefix convention: `/api/...`

✅ **Tester ([Tester Name])**
- [ ] Test health check endpoint
- [ ] Verify CORS hoạt động đúng

**ACCEPTANCE CRITERIA**:
- [ ] Admin Backend chạy được trên port riêng (VD: 3001)
- [ ] Health check endpoint trả về 200
- [ ] Prisma Client connect DB thành công
- [ ] CORS config đúng cho Admin Web
- [ ] Logging hoạt động

---

## 🎯 CARD 2B: [Infra] Setup Mobile Backend (FastAPI)

**TITLE**: `[Infra] Setup Mobile Backend - FastAPI + SQLAlchemy`

**DESCRIPTION**:
```
Setup Mobile Backend project structure cho Mobile App (Flutter).
Tech: Python, FastAPI, SQLAlchemy, Pydantic.
Phục vụ: Mobile App (Flutter), Data Ingestion, AI Integration.
```

**LABELS**:
- Module: `Infra`
- Role: `Mobile Backend`
- Priority: `High`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Approve project structure

✅ **Mobile BE Dev ([Mobile BE Dev])**
- [ ] Setup FastAPI project với structure:
  ```
  mobile-backend/
  ├── app/
  │   ├── api/          # API routes
  │   ├── core/         # Config, security, dependencies
  │   ├── models/       # SQLAlchemy models (reflect từ DB)
  │   ├── schemas/      # Pydantic schemas
  │   ├── services/     # Business logic
  │   └── utils/        # Utilities
  ├── tests/
  └── requirements.txt
  ```
- [ ] Install dependencies: `fastapi`, `uvicorn`, `sqlalchemy`, `psycopg2-binary`, `python-jose[cryptography]`, `passlib[bcrypt]`, `python-multipart`
- [ ] Setup database connection (SQLAlchemy + PostgreSQL)
- [ ] Setup CORS middleware (allow Mobile App origins)
- [ ] Setup logging (file + console)
- [ ] Setup environment variables (.env): DB_URL, JWT_SECRET (riêng biệt cho Mobile BE), PORT
- [ ] Create basic health check endpoint: `GET /health`
- [ ] Setup auto-generated docs (FastAPI built-in Swagger)
- [ ] Document API prefix convention: `/api/...`
- [ ] Setup Docker (Dockerfile + docker-compose.yml) - optional nhưng recommend

✅ **Tester ([Tester Name])**
- [ ] Test health check endpoint
- [ ] Verify CORS hoạt động đúng
- [ ] Test với Postman

**ACCEPTANCE CRITERIA**:
- [ ] Mobile Backend chạy được trên port riêng (VD: 8000)
- [ ] Health check endpoint trả về 200
- [ ] SQLAlchemy connect DB thành công
- [ ] CORS config đúng
- [ ] Logging hoạt động
- [ ] Swagger docs accessible tại `/docs`

**NOTES**:
- JWT_SECRET **riêng biệt** với Admin Backend — mỗi backend dùng secret key độc lập
- Port khác Admin Backend (VD: Admin=3001, Mobile=8000)

---

## 🎯 CARD 3: [Auth] UC001 - Login

**TITLE**: `[Auth] UC001 - Login`

**DESCRIPTION**:
```
UC: BA/UC/Authentication/UC001_Login.md
Mục tiêu: Người dùng đăng nhập bằng email/password, nhận JWT token.
⚠️ TÁCH RIÊNG: Admin login (Node.js) và Mobile login (FastAPI)
```

**LABELS**:
- Module: `Auth`
- Role: `Admin Backend`, `Mobile Backend`, `Frontend`, `Mobile`
- Priority: `High`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC001 đã final
- [ ] Verify business rules: JWT expiry khác nhau cho Admin vs Mobile

✅ **Admin BE Dev ([Admin BE Dev])** — Login cho Admin
- [ ] Implement API: `POST /api/auth/login`
  - Request: `{email, password}`
  - Response: `{access_token, token_type, user: {id, email, role, full_name}}`
- [ ] Hash password verification (bcrypt)
- [ ] Generate JWT token: `iss="healthguard-admin"`, role: ADMIN, expiry **8h**
- [ ] Rate limiting: 5 attempts/15 minutes per IP
- [ ] Check `is_active` flag trong `users` table
- [ ] Update `last_login_at` trong database
- [ ] Log login attempt vào `audit_logs`
- [ ] Error handling: wrong email/password, account locked
- [ ] Unit tests cho login service

✅ **Mobile BE Dev ([Mobile BE Dev])** — Login cho Patient/Caregiver
- [ ] Implement API: `POST /api/auth/login`
  - Request: `{email, password}`
  - Response: `{access_token, refresh_token, token_type, user: {id, email, role, full_name}}`
- [ ] Hash password verification (bcrypt / passlib)
- [ ] Generate JWT token: `iss="healthguard-mobile"`, roles: PATIENT/CAREGIVER, expiry **30 ngày**
- [ ] Implement refresh token mechanism
- [ ] Rate limiting: 5 attempts/15 minutes per IP
- [ ] Check `is_active` flag
- [ ] Update `last_login_at`
- [ ] Log login attempt vào `audit_logs`
- [ ] Error handling: wrong email/password, account locked
- [ ] Unit tests

✅ **Admin FE Dev ([Admin FE Dev])**
- [ ] Design login page (React + TailwindCSS)
- [ ] Form validation (email format, required fields)
- [ ] Call API `POST /api/auth/login`
- [ ] Store JWT token (localStorage hoặc httpOnly cookie)
- [ ] Redirect to dashboard sau khi login thành công
- [ ] Handle error messages (wrong password, account locked)
- [ ] Show/hide password toggle
- [ ] Loading state khi đang login

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design login screen (Flutter)
- [ ] Form validation
- [ ] Call API `POST /api/auth/login`
- [ ] Store JWT + refresh token (secure storage)
- [ ] Navigate to dashboard sau login
- [ ] Handle error messages
- [ ] Show/hide password toggle
- [ ] Loading indicator

✅ **Tester ([Tester Name])**
- [ ] Test cases cho **Admin Login** (Web):
  - ✅ Main Flow: Login thành công → JWT 8h
  - ✅ Alt Flow: Wrong email/password
  - ✅ Rate limiting: 6 lần sai → block
- [ ] Test cases cho **Mobile Login** (App):
  - ✅ Main Flow: Login thành công → JWT 30d + refresh token
  - ✅ Alt Flow: Wrong email/password
  - ✅ Rate limiting
- [ ] Test JWT token expiry khác nhau (Admin: 8h, Mobile: 30d)
- [ ] Test role-based: Admin chỉ login bên Admin, Patient chỉ login bên Mobile

**ACCEPTANCE CRITERIA**:
- [ ] Admin login và Mobile login hoạt động **độc lập**
- [ ] JWT tokens có issuer khác nhau
- [ ] Redirect đúng dashboard theo role
- [ ] Error messages hiển thị đúng
- [ ] Rate limiting hoạt động trên cả 2
- [ ] Audit log được ghi ở cả 2

**NOTES**:
- JWT_SECRET **riêng biệt** cho mỗi backend — không dùng chung
- API prefix khác nhau: `/api/...` vs `/api/...`

---

## 🎯 CARD 4: [Auth] UC002 - Register

**TITLE**: `[Auth] UC002 - Register`

**DESCRIPTION**:
```
UC: BA/UC/Authentication/UC002_Register.md
Mục tiêu: Người dùng tạo tài khoản mới.
⚠️ Admin: Chỉ admin tạo user (không self-register)
⚠️ Mobile: Self-register cho patient/caregiver
```

**LABELS**:
- Module: `Auth`
- Role: `Admin Backend`, `Mobile Backend`, `Frontend`, `Mobile`
- Priority: `High`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC002 đã final
- [ ] Verify data requirements: email, password, full_name, phone, date_of_birth, role

✅ **Admin BE Dev ([Admin BE Dev])** — Tạo user bởi Admin
- [ ] Implement API: `POST /api/users` (require ADMIN JWT)
  - Request: `{email, password, full_name, phone, date_of_birth, role}`
  - Response: `{message, user_id}`
- [ ] Validate email format, uniqueness
- [ ] Hash password (bcrypt)
- [ ] Create user trong `users` table với `is_verified=true` (admin tạo = verified)
- [ ] Error handling: email exists, invalid data
- [ ] Unit tests

✅ **Mobile BE Dev ([Mobile BE Dev])** — Self-register Patient/Caregiver
- [ ] Implement API: `POST /api/auth/register`
  - Request: `{email, password, full_name, phone, date_of_birth, role}`
  - Response: `{message, user_id}`
- [ ] Validate email format, uniqueness
- [ ] Validate password (min 6 chars)
- [ ] Hash password (bcrypt / passlib)
- [ ] Create user với `is_verified=false`
- [ ] Generate email verification token (JWT, 24h expiry)
- [ ] Send verification email (SMTP - có thể mock trong dev)
- [ ] Error handling: email exists, invalid data
- [ ] Unit tests

✅ **Admin FE Dev ([Admin FE Dev])**
- [ ] Design "Add User" modal trong Admin Dashboard (KHÔNG phải register page riêng)
- [ ] Form fields: email, password, full_name, phone, date_of_birth, role (dropdown)
- [ ] Call API `POST /api/users`
- [ ] Show success message
- [ ] Handle errors (email exists)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design register screen
- [ ] Form với validation
- [ ] Call API `POST /api/auth/register`
- [ ] Success message + navigate to login
- [ ] Handle errors
- [ ] Terms & conditions checkbox

✅ **Tester ([Tester Name])**
- [ ] Test cases **Admin tạo user**:
  - ✅ Main Flow: Admin tạo user thành công
  - ✅ Chỉ ADMIN role mới tạo được
  - ✅ Email đã tồn tại → error
- [ ] Test cases **Mobile self-register**:
  - ✅ Main Flow: Register thành công
  - ✅ Email đã tồn tại → error
  - ✅ Password không đủ mạnh
  - ✅ Chưa chấp nhận terms
- [ ] Verify email được gửi (Mobile register)

**ACCEPTANCE CRITERIA**:
- [ ] Admin tạo user → `is_verified=true`
- [ ] Mobile register → `is_verified=false` + verification email
- [ ] Validation errors hiển thị đúng ở cả 2

---

## 🎯 CARD 5: [Auth] UC003 - Forgot Password

**TITLE**: `[Auth] UC003 - Forgot Password`

**DESCRIPTION**:
```
UC: BA/UC/Authentication/UC003_ForgotPassword.md
Mục tiêu: Người dùng reset mật khẩu qua email khi quên.
⚠️ Implement trên CẢ 2 BE (Admin và Mobile)
```

**LABELS**:
- Module: `Auth`
- Role: `Admin Backend`, `Mobile Backend`, `Frontend`, `Mobile`
- Priority: `Medium`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC003
- [ ] Verify business rules: token 15 phút, rate limit 3 lần/15 phút

✅ **Admin BE Dev ([Admin BE Dev])**
- [ ] Implement `POST /api/auth/forgot-password`
- [ ] Implement `POST /api/auth/reset-password`
- [ ] Generate reset token (JWT, 15 phút expiry)
- [ ] Rate limiting: 3 requests/15 phút per email
- [ ] Token one-time use
- [ ] Error handling: token expired, invalid token

✅ **Mobile BE Dev ([Mobile BE Dev])**
- [ ] Implement `POST /api/auth/forgot-password`
- [ ] Implement `POST /api/auth/reset-password`
- [ ] Generate reset token (JWT, 15 phút expiry)
- [ ] Rate limiting: 3 requests/15 phút per email
- [ ] Token one-time use
- [ ] Send reset email với deep link: `app://reset-password?token=xxx`
- [ ] Error handling

✅ **Admin FE Dev ([Admin FE Dev])**
- [ ] Design forgot password + reset password pages
- [ ] Call Admin API

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design forgot password + reset password screens
- [ ] Handle deep link: `app://reset-password?token=xxx`
- [ ] Call Mobile API

✅ **Tester ([Tester Name])**
- [ ] Test forgot/reset flow trên cả Admin Web và Mobile App
- [ ] Test token expiry (15 phút)
- [ ] Test rate limiting
- [ ] Test token one-time use

**ACCEPTANCE CRITERIA**:
- [ ] Reset password flow hoạt động trên cả 2 platforms
- [ ] Token expiry 15 phút
- [ ] Rate limiting hoạt động
- [ ] Token chỉ dùng 1 lần

---

## 🎯 CARD 6: [Auth] UC004 - Change Password

**TITLE**: `[Auth] UC004 - Change Password`

**DESCRIPTION**:
```
UC: BA/UC/Authentication/UC004_ChangePassword.md
Mục tiêu: Người dùng đã login thay đổi mật khẩu.
⚠️ Implement trên CẢ 2 BE
```

**LABELS**:
- Module: `Auth`
- Role: `Admin Backend`, `Mobile Backend`, `Frontend`, `Mobile`
- Priority: `Medium`
- Sprint: `Sprint 1`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC004

✅ **Admin BE Dev ([Admin BE Dev])**
- [ ] Implement `POST /api/auth/change-password` (require JWT)
- [ ] Verify current password
- [ ] Validate new password, update DB
- [ ] Send email notification
- [ ] Rate limiting: 5 attempts/15 phút

✅ **Mobile BE Dev ([Mobile BE Dev])**
- [ ] Implement `POST /api/auth/change-password` (require JWT)
- [ ] Verify current password
- [ ] Validate new password, update DB
- [ ] Send email notification
- [ ] Rate limiting: 5 attempts/15 phút

✅ **Admin FE Dev ([Admin FE Dev])**
- [ ] Design change password page (Settings > Security)
- [ ] Call Admin API

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design change password screen (Settings)
- [ ] Call Mobile API

✅ **Tester ([Tester Name])**
- [ ] Test change password trên cả 2 platforms
- [ ] Test wrong current password
- [ ] Test new password = current password → reject
- [ ] Test rate limiting

**ACCEPTANCE CRITERIA**:
- [ ] Change password hoạt động trên cả 2
- [ ] Email notification được gửi
- [ ] Rate limiting hoạt động

---

## 📊 SPRINT 1 SUMMARY

**Total Cards**: 7 (Card 2 tách thành 2A + 2B)  
**Priority**: High (Cards 1, 2A, 2B, 3, 4), Medium (Cards 5, 6)

**Dependencies**:
- Card 1 (Database) → Card 2A + 2B (Backends) → Cards 3-6 (Auth)

**Estimated Effort**:

| Card | Admin BE Dev | Mobile BE Dev |
|------|-------------|--------------|
| Card 1 | 1-2 days | 0.5 day |
| Card 2A | 1-2 days | — |
| Card 2B | — | 1-2 days |
| Card 3 | 1 day | 1 day |
| Card 4 | 1 day | 1.5 days |
| Card 5 | 1 day | 1 day |
| Card 6 | 0.5 day | 0.5 day |
| **Total** | **~5-7 days** | **~5-6 days** |

**Total Sprint**: ~10-14 days (fit trong Sprint 1: 2 tuần)

---

**Cập nhật lần cuối**: 02/03/2026  
**Version**: 2.0 — Restructured for 2-BE architecture (Node.js Admin + FastAPI Mobile)
