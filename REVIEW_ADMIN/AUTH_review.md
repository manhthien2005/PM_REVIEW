# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth — Login, Register, Forgot/Reset/Change Password, Email Verification
- **Module**: AUTH
- **Dự án**: Admin Website (HealthGuard/)
- **Sprint**: Sprint 1
- **Trello Card**: Card 3 (Login), Card 4 (Register), Card 5 (Forgot Password), Card 6 (Change Password)
- **UC Reference**: UC001, UC002, UC003, UC004
- **Ngày đánh giá**: 2026-03-03

---

## 🏆 TỔNG ĐIỂM: 58/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Chức năng đúng yêu cầu | 10/15 | Đủ endpoints nhưng register sai lệch SRS, JWT thiếu `iss`+`role` |
| API Design | 7/10 | RESTful tốt, Swagger chi tiết, nhưng URL routing sai lệch so với SRS |
| Architecture & Patterns | 10/15 | Clean separation Route→Controller→Service, nhưng nhiều code duplication |
| Validation & Error Handling | 9/12 | Validation đầy đủ, error format thống nhất, nhưng thiếu try-catch ở controller |
| Security | 6/12 | bcrypt ✅, nhưng JWT thiếu `iss`, hardcoded fallback secret, CORS wildcard, thiếu rate limit trên nhiều endpoints |
| Code Quality | 8/12 | Readable, TypeScript typed, nhưng duplication cao và controller quá dài |
| Testing | 0/12 | KHÔNG có unit tests nào |
| Documentation | 8/12 | Swagger docs rất chi tiết, nhưng thiếu ADR và README module |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (3.5/5)

| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Route → Controller → Service → Repo separation | ✅ | `authRoutes` → `authController` → `authService`/`registerService`/etc → Prisma ORM |
| Controller CHỈ handle request/response | ⚠️ | Phần lớn đúng, nhưng validation nằm cả ở controller + service (trùng lặp) |
| Service chứa business logic, KHÔNG truy cập req/res | ✅ | Services nhận params thuần, không phụ thuộc Express |
| Repository/Model chứa data access | ⚠️ | Dùng Prisma trực tiếp trong Service thay vì qua Repository layer |
| Dependency direction đúng | ✅ | Controller → Service → Prisma (không ngược) |

### Domain Logic & Business Rules (3/5)

| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Business rules tập trung trong Service | ✅ | Login logic, password validation, audit logging đều trong services |
| Domain validation tách khỏi API validation | ❌ | `isValidEmail`, `isValidPassword` duplicate cả ở service lẫn controller |
| Edge cases được handle | ⚠️ | Account locked, not verified ✅; brute force lockout incomplete ❌ |
| Business logic testable mà không cần HTTP/DB | ⚠️ | Services phụ thuộc trực tiếp Prisma, khó mock |
| Không duplicate business logic | ❌ | `isValidEmail()` copy-paste ở 3 files, `isValidPassword()` ở 3 files |

### Design Patterns (3/5)

| Pattern | Có? | Đánh giá |
|---------|-----|---------|
| Middleware — Auth guard | ✅ | `authMiddleware.ts` verify JWT, gắn user vào request |
| Middleware — Rate limiter | ⚠️ | Chỉ áp dụng cho `/login`, thiếu cho forgot-password, change-password |
| Repository pattern | ❌ | Prisma dùng trực tiếp trong Service, không có abstract layer |
| DTO/Schema | ⚠️ | Interface `LoginResult`, `RegisterData` có, nhưng không dùng validation library (Zod/Joi) |
| Error response pattern | ✅ | Thống nhất `{success, error: {code, message}}` hoặc `{success, data}` |

---

## 🔒 SECURITY DEEP DIVE

### Authentication & Authorization (3/4)

| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| JWT validated đúng (signature, expiry) | ⚠️ | Verify signature + expiry ✅, nhưng THIẾU `iss` claim → không phân biệt Admin vs Mobile token per SRS §5.3 |
| Refresh token flow | ❌ | Không có refresh token. Admin token SRS yêu cầu 8h, code set 24h |
| Route-level authorization | ⚠️ | `authenticate` middleware chỉ verify JWT, KHÔNG kiểm tra role. Register route mở cho mọi người |
| Password: bcrypt | ✅ | `bcrypt.hash(password, 10)` — saltRounds=10 OK |

### Input Security (3/4)

| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Server-side input validation | ✅ | Email format, password length, phone regex, DOB validated |
| SQL injection prevention | ✅ | Prisma ORM parameterized queries |
| XSS prevention | ✅ | JSON API, không render HTML từ user input |
| File upload validation | N/A | Không có file upload trong auth module |

### Rate Limiting & Abuse Prevention (1.5/4)

| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Rate limiting trên login | ✅ | `loginLimiter`: 5 attempts/15min per IP |
| Rate limiting trên forgot-password | ❌ | THIẾU — SRS yêu cầu 3/15min. Có thể bị spam email |
| Rate limiting trên change-password | ❌ | THIẾU — SRS yêu cầu 5/15min |
| CORS configured đúng | ❌ | `app.use(cors())` = wildcard `*`, cho phép mọi origin |
| Secrets trong `.env` | ⚠️ | Dùng `.env` ✅ NHƯNG có fallback `'your-secret-key'` hardcoded ở 3 files |

---

## 📂 FILES ĐÁNH GIÁ

| File | Layer | LOC | Đánh giá tóm tắt |
|------|-------|-----|-------------------|
| [`authRoutes.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/routes/authRoutes.ts) | Route | 39 | Tốt, clean, 7 routes. Thiếu rate limiter trên password endpoints |
| [`authController.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/controllers/authController.ts) | Controller | 854 | Quá dài! ~700 dòng Swagger + 150 dòng logic. Import giữa file |
| [`authService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/authService.ts) | Service | 194 | Tốt. Login logic rõ ràng, audit log chi tiết |
| [`registerService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/registerService.ts) | Service | 220 | Tốt. Validation chi tiết, email verification flow |
| [`passwordResetService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/passwordResetService.ts) | Service | 285 | Reset token tạo bằng JWT nhưng KHÔNG lưu DB → không one-time use |
| [`changePasswordService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/changePasswordService.ts) | Service | 155 | Tốt. Verify current password, check same password, audit log |
| [`verifyEmailService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/verifyEmailService.ts) | Service | 208 | Tốt. Token type validation, already-verified check |
| [`emailService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/emailService.ts) | Service | 251 | Tốt. HTML + text templates, transporter verify on start |
| [`authMiddleware.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/middleware/authMiddleware.ts) | Middleware | 44 | OK nhưng thiếu role-based check |
| [`rateLimiter.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/middleware/rateLimiter.ts) | Middleware | 16 | Chỉ có `loginLimiter`, thiếu `forgotPasswordLimiter`, `changePasswordLimiter` |
| [`jwt.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/utils/jwt.ts) | Util | 21 | **CRITICAL**: Thiếu `iss`, `role` trong payload. Fallback secret hardcoded |
| [`LoginPage.tsx`](file:///d:/DoAn2/VSmartwatch/HealthGuard/frontend/src/pages/LoginPage.tsx) | Page | 342 | Tốt. UX chi tiết, error icons, loading state, show/hide password |
| [`authService.ts`](file:///d:/DoAn2/VSmartwatch/HealthGuard/frontend/src/services/authService.ts) (FE) | Service | 68 | OK. Token lưu localStorage (nên dùng httpOnly cookie) |

---

## 📋 TRELLO TASK TRACKING

### Card 3 — Login (Admin BE Dev)

| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/auth/login` — Req/Res format | ✅ Done | Có, format đúng `{success, data: {token, user}}` |
| 2 | bcrypt password verification | ✅ Done | `bcrypt.compare()` trong `authService.ts:128` |
| 3 | JWT: `iss="healthguard-admin"`, roles, expiry 8h | ❌ Missing | `jwt.ts` KHÔNG set `iss`, KHÔNG include `role`, expiry = 24h thay vì 8h |
| 4 | Rate limiting: 5 attempts/15min per IP | ✅ Done | `rateLimiter.ts` configures 5/15min |
| 5 | Check `is_active` flag | ✅ Done | `authService.ts:84` checks `user.isActive` |
| 6 | Update `last_login_at` | ✅ Done | `authService.ts:152-155` |
| 7 | Log to `audit_logs` | ✅ Done | Cả success và failure đều logged |
| 8 | Error handling: wrong email/password, locked | ✅ Done | `INVALID_CREDENTIALS`, `ACCOUNT_LOCKED`, `ACCOUNT_NOT_VERIFIED` |
| 9 | Unit tests | ❌ Missing | Không tìm thấy file test nào |

### Card 3 — Login (Admin FE Dev)

| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | Login page (React + TailwindCSS) | ✅ Done | `LoginPage.tsx` — thiết kế đẹp, responsive |
| 2 | Form validation (email format, required) | ✅ Done | Client-side validation on blur + submit |
| 3 | Store JWT (localStorage) | ✅ Done | `authService.ts` FE lưu vào `hg_token` |
| 4 | Redirect to dashboard | ✅ Done | `onLoginSuccess()` callback |
| 5 | Error messages, show/hide password, loading | ✅ Done | Error banner với icons, toggle password, spinner |

### Card 4 — Register (Admin BE Dev)

| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/users` (require ADMIN JWT) | 🔄 Deviated | Route = `POST /api/auth/users`. **KHÔNG require ADMIN JWT** — open endpoint! |
| 2 | Validate email format + uniqueness | ✅ Done | Email regex + `findUnique` check |
| 3 | Hash password | ✅ Done | `bcrypt.hash(password, 10)` |
| 4 | Create user with `is_verified=true` | 🔄 Deviated | User tạo với `is_verified=false` (cần email verify) — khác SRS cho Admin |
| 5 | Unit tests | ❌ Missing | Không có |

### Card 5 — Forgot Password (Admin BE Dev)

| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/auth/forgot-password` | 🔄 Deviated | Route thực tế: `POST /api/auth/password/forgot` |
| 2 | Reset token JWT 15min | ✅ Done | JWT với expiry '15m' |
| 3 | Rate limit 3/15min | ❌ Missing | Không có rate limiter trên endpoint này |
| 4 | One-time use token | ❌ Missing | Token không lưu DB, không track used/unused |

### Card 6 — Change Password (Admin BE Dev)

| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/auth/change-password` (require JWT) | 🔄 Deviated | Route: `PUT /api/auth/password`, require `authenticate` ✅ |
| 2 | Verify current password | ✅ Done | `bcrypt.compare` trước khi đổi |
| 3 | Validate new password | ✅ Done | Min 6 chars + check same password |
| 4 | Email notification | ✅ Done | `sendPasswordChangeNotificationEmail()` |
| 5 | Rate limit 5/15min | ❌ Missing | Không có rate limiter |

### Acceptance Criteria

| # | Criteria | Trạng thái | Ghi chú |
|---|---------|------------|---------|
| 1 | Admin login + Mobile login operate independently | ⚠️ Partial | Dùng chung JWT secret nhưng token KHÔNG có `iss` để phân biệt |
| 2 | JWT tokens have different issuers | ❌ Missing | `jwt.ts` không set `iss` claim |
| 3 | Redirect correct dashboard per role | ⚠️ Partial | Frontend redirect, nhưng backend không check role khi login |
| 4 | Error messages display correctly | ✅ Done | Error code mapping + UI icons |
| 5 | Rate limiting works | ⚠️ Partial | Chỉ login, thiếu forgot/change |
| 6 | Audit log recorded | ✅ Done | Tất cả actions đều log |

---

## 📊 SRS COMPLIANCE

### Main Flow — Login (UC001)

| Bước | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| 1 | User nhập email + password | ✅ `LoginPage.tsx` form | ✅ |
| 2 | Validate email format | ✅ Client + server validation | ✅ |
| 3 | Check tài khoản tồn tại | ✅ `prisma.user.findUnique` | ✅ |
| 4 | Check `is_active` | ✅ `authService.ts:84` | ✅ |
| 5 | Verify password bằng bcrypt | ✅ `bcrypt.compare` | ✅ |
| 6 | Generate JWT (`iss=healthguard-admin`, 8h) | ❌ JWT không có `iss`, expiry 24h | ❌ |
| 7 | Update `last_login_at` | ✅ `prisma.user.update` | ✅ |
| 8 | Log vào `audit_logs` | ✅ cả success và failure | ✅ |
| 9 | Return `{token, user: {id, email, role, name}}` | ✅ đúng format | ✅ |

### Alternative Flows

| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| A1 | Email không tồn tại → generic error | ✅ `INVALID_CREDENTIALS` (không leak) | ✅ |
| A2 | Password sai → generic error | ✅ `INVALID_CREDENTIALS` | ✅ |
| A3 | Account locked → 423 | ✅ `ACCOUNT_LOCKED` + status 423 | ✅ |
| A4 | Account not verified → error | ✅ `ACCOUNT_NOT_VERIFIED` | ✅ |
| A5 | Rate limit exceeded → 429 | ✅ `loginLimiter` middleware | ✅ |

### Exception Flows

| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| E1 | Internal error → 500 | ✅ try-catch → `INTERNAL_ERROR` | ✅ |
| E2 | Account lockout after 5 failed attempts | ❌ Rate limit chỉ per IP, KHÔNG lock account trong DB | ❌ |

### Non-Functional Requirements (SRS §5.3)

| Yêu cầu | Implementation | Match? |
|----------|---------------|--------|
| JWT issuer `healthguard-admin` | ❌ Không set `iss` | ❌ |
| Token expiry 8h | ❌ Default 24h | ❌ |
| Role: ADMIN | ⚠️ Token không chứa `role` | ❌ |
| JWT secret riêng biệt (independent) | ⚠️ Dùng env var, nhưng có fallback hardcode | ⚠️ |
| Thu hồi token khi đổi MK/khóa TK | ❌ Không có cơ chế invalidate | ❌ |
| Password min 6 ký tự, bcrypt hash | ✅ bcrypt ✅, min 6 ✅ | ✅ |
| TLS/SSL | N/A | Development environment |

---

## ✅ ƯU ĐIỂM

1. **Clean Architecture separation** — Routes → Controllers → Services → Prisma ORM rõ ràng. Services không phụ thuộc Express objects.

2. **Audit logging xuất sắc** — Mọi action (login success/fail, register, password reset/change, email verify) đều logged với IP, User-Agent, details. [authService.ts:64-72](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/authService.ts#L64-L72)

3. **Swagger documentation rất chi tiết** — Mỗi endpoint có đầy đủ request/response schema, error codes, examples với giải thích tiếng Việt. [authController.ts:6-163](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/controllers/authController.ts#L6-L163)

4. **Error response format thống nhất** — `{success: boolean, data/error}` xuyên suốt cả backend và frontend.

5. **Email service production-ready** — HTML + plain text templates, transporter verify on startup, 3 email types (verify, reset, notification). [emailService.ts](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/emailService.ts)

6. **Frontend Login UX tốt** — Field-level validation on blur, error icons theo error code, show/hide password, loading spinner, responsive design. [LoginPage.tsx](file:///d:/DoAn2/VSmartwatch/HealthGuard/frontend/src/pages/LoginPage.tsx)

7. **Anti-enumeration attack** — Forgot password luôn trả success dù email có tồn tại hay không. [passwordResetService.ts:66-86](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/passwordResetService.ts#L66-L86)

8. **Service tách nhỏ theo domain** — 6 service files riêng biệt thay vì 1 god file, mỗi file single responsibility.

---

## ❌ NHƯỢC ĐIỂM

1. **JWT token thiếu `iss` và `role`** — SRS §5.3 yêu cầu `iss="healthguard-admin"` để phân biệt với Mobile token. Token hiện tại chỉ chứa `{userId, email}`, không có `role`. [jwt.ts:6-11](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/utils/jwt.ts#L6-L11)

2. **JWT expiry sai — 24h thay vì 8h** — SRS §5.3 quy định Admin token expiry 8 giờ. Code default là `'24h'`. [jwt.ts:4](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/utils/jwt.ts#L4)

3. **Hardcoded fallback JWT secret** — `'your-secret-key'` xuất hiện ở 3 files (`jwt.ts`, `registerService.ts`, `passwordResetService.ts`, `verifyEmailService.ts`). Nếu `.env` thiếu `JWT_SECRET`, ứng dụng sẽ chạy với secret yếu. [jwt.ts:3](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/utils/jwt.ts#L3)

4. **Register endpoint OPEN — không require ADMIN JWT** — SRS yêu cầu chỉ ADMIN mới tạo user cho Admin panel. Route hiện tại `POST /api/auth/users` không có middleware `authenticate`. [authRoutes.ts:27](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/routes/authRoutes.ts#L27)

5. **CORS wildcard** — `app.use(cors())` cho phép mọi origin. Production PHẢI restrict về Admin frontend URL. [index.ts:16](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/index.ts#L16)

6. **Reset token KHÔNG truly one-time use** — Token JWT chỉ verify expiry, không lưu DB để track used/unused. Token có thể dùng nhiều lần trong 15 phút. [passwordResetService.ts:96-103](file:///d:/DoAn2/VSmartwatch/HealthGuard/backend/src/services/passwordResetService.ts#L96-L103)

7. **Code duplication nghiêm trọng** — `isValidEmail()` copy-paste ở 3 files: `authService.ts:6-9`, `registerService.ts:9-12`, `passwordResetService.ts:11-14`. `isValidPassword()` duplicate ở `registerService.ts:15-17`, `passwordResetService.ts:17-19`, `changePasswordService.ts:6-8`.

8. **0% test coverage** — Không có bất kỳ unit test nào cho toàn bộ auth module. Đây là Sprint 1 deliverable.

9. **Controller 854 LOC** — `authController.ts` quá dài do inline Swagger docs (~690 dòng Swagger + 160 dòng logic). Import statements nằm giữa file (line 379, 687).

10. **Token lưu localStorage** — Frontend lưu JWT vào `localStorage` thay vì `httpOnly cookie`, dễ bị XSS attack. [authService.ts FE:23](file:///d:/DoAn2/VSmartwatch/HealthGuard/frontend/src/services/authService.ts#L23)

---

## 🔧 ĐIỂM CẦN CẢI THIỆN

1. **[HIGH]** JWT phải thêm `iss` + `role` + sửa expiry → Sửa `jwt.ts`:
```typescript
// jwt.ts — SUGGESTED FIX
export const generateToken = (userId: number, email: string, role: string): string => {
  return jwt.sign(
    { userId, email, role, iss: 'healthguard-admin' },
    JWT_SECRET,
    { expiresIn: '8h' }
  );
};
```

2. **[HIGH]** Register endpoint phải require ADMIN JWT → Sửa `authRoutes.ts`:
```typescript
router.post('/users', authenticate, authorizeRoles('admin'), register);
```

3. **[HIGH]** Thêm rate limiters cho forgot-password và change-password:
```typescript
export const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3, // SRS: 3 requests/15min
  // ...
});

export const changePasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // SRS: 5 attempts/15min  
  // ...
});
```

4. **[HIGH]** Loại bỏ fallback JWT secret — throw error nếu thiếu:
```typescript
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET must be defined');
```

5. **[HIGH]** Viết unit tests — Ít nhất cho `authService.loginUser()`, `registerService.registerUser()`, `passwordResetService`, `changePasswordService`.

6. **[MEDIUM]** Implement password reset token one-time use — tạo bảng `password_reset_tokens` riêng hoặc lưu token hash vào DB.

7. **[MEDIUM]** CORS restrict — chỉ cho phép frontend Admin URL:
```typescript
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }));
```

8. **[MEDIUM]** Extract validation utils — tạo `utils/validators.ts` chứa `isValidEmail`, `isValidPassword`, `isValidPhone` dùng chung.

9. **[MEDIUM]** Thêm role-based authorization middleware:
```typescript
export const authorizeRoles = (...roles: string[]) => (req, res, next) => {
  if (!roles.includes(req.user?.role)) {
    return res.status(403).json({ success: false, error: { code: 'FORBIDDEN' } });
  }
  next();
};
```

10. **[LOW]** Tách Swagger docs ra file riêng (VD: `swagger/auth.yaml`) để giảm LOC controller.

11. **[LOW]** Cân nhắc chuyển JWT storage sang httpOnly cookie cho frontend.

---

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Hardcoded fallback secret** `'your-secret-key'` — xuất hiện ở `jwt.ts:3`, `registerService.ts:6`, `passwordResetService.ts:7`, `verifyEmailService.ts:4`. Nguy cơ security cao.

2. **Duplicate `isValidEmail()`** — giữ 1 bản duy nhất ở `utils/validators.ts`, xóa ở 3 service files.

3. **Duplicate `isValidPassword()`** — tương tự, giữ 1 bản duy nhất.

4. **Import giữa file** — `authController.ts:379` và `authController.ts:687` import services giữa file thay vì đầu file. Nên move tất cả lên đầu.

---

## ⚠️ SAI LỆCH VỚI TRELLO / SRS

| Source | Mô tả sai lệch | Mức độ | Đề xuất |
|--------|----------------|--------|---------|
| SRS §5.3 | JWT thiếu `iss="healthguard-admin"` → Mobile token có thể dùng cho Admin | 🔴 Critical | Thêm `iss` vào `generateToken()` |
| SRS §5.3 | Token expiry 24h thay vì 8h | 🟡 Medium | Sửa `JWT_EXPIRES_IN` = `'8h'` |
| Trello Card 4 | Register KHÔNG require ADMIN JWT (SRS quy định Admin-only) | 🔴 Critical | Thêm `authenticate` + `authorizeRoles('admin')` middleware |
| Trello Card 4 | User tạo với `is_verified=false` (SRS yêu cầu Admin tạo → `is_verified=true`) | 🟡 Medium | Admin tạo user nên set `is_verified=true` tự động |
| Trello Card 5 | URL path `password/forgot` thay vì `forgot-password` | 🟢 Low | URL semantics tốt hơn nhưng khác Trello spec |
| Trello Card 5 | Thiếu rate limit 3/15min cho forgot-password | 🔴 Critical | Thêm `forgotPasswordLimiter` |
| Trello Card 5 | Reset token NOT one-time use | 🔴 Critical | Lưu token hash vào DB, invalidate sau khi dùng |
| Trello Card 6 | URL path `PUT /password` thay vì `POST /change-password` | 🟢 Low | RESTful hơn nhưng khác Trello |
| Trello Card 6 | Thiếu rate limit 5/15min cho change-password | 🟡 Medium | Thêm `changePasswordLimiter` |

---

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt — Anti-enumeration trong forgot password:
```typescript
// file: services/passwordResetService.ts, line 66-86
// BR-005: Don't reveal if email exists (prevent enumeration attack)
if (!user) {
  await prisma.auditLog.create({ ... });
  return {
    success: true,  // ← Always return success
    data: { message: 'Đã gửi email hướng dẫn...' },
  };
}
```

### ✅ Code tốt — Structured audit logging:
```typescript
// file: services/authService.ts, line 64-72
await prisma.auditLog.create({
  data: {
    action: 'LOGIN_FAILED',
    ipAddress,
    userAgent,
    details: { email, reason: 'USER_NOT_FOUND' },
    status: 'failure',
  },
});
```

### ❌ Code cần sửa — JWT token generation:
```typescript
// HIỆN TẠI (jwt.ts:6-11):
export const generateToken = (userId: number, email: string): string => {
  return jwt.sign(
    { userId, email },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }  // default '24h'
  );
};

// NÊN SỬA THÀNH:
export const generateToken = (userId: number, email: string, role: string): string => {
  return jwt.sign(
    { userId, email, role, iss: 'healthguard-admin' },
    JWT_SECRET,
    { expiresIn: '8h' }
  );
};
```

### ❌ Code cần sửa — CORS wildcard:
```typescript
// HIỆN TẠI (index.ts:16):
app.use(cors());

// NÊN SỬA THÀNH:
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true,
}));
```

---

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| # | Action | Owner | Priority | Sprint |
|---|--------|-------|----------|--------|
| 1 | Sửa `jwt.ts`: thêm `iss`, `role`, expiry 8h | Admin BE Dev | HIGH | S1 hotfix |
| 2 | Register endpoint: thêm ADMIN JWT guard + `is_verified=true` | Admin BE Dev | HIGH | S1 hotfix |
| 3 | Thêm rate limiter cho forgot-password (3/15min) + change-password (5/15min) | Admin BE Dev | HIGH | S1 hotfix |
| 4 | Loại bỏ hardcoded JWT_SECRET fallback ở 4 files | Admin BE Dev | HIGH | S1 hotfix |
| 5 | Implement reset token one-time use (DB table) | Admin BE Dev | HIGH | S2 |
| 6 | Viết unit tests cho tất cả services (target ≥ 80% coverage) | Admin BE Dev | HIGH | S2 |
| 7 | Configure CORS restrict (specific origin) | Admin BE Dev | MEDIUM | S1 hotfix |
| 8 | Extract shared validation utils (`validators.ts`) | Admin BE Dev | MEDIUM | S2 |
| 9 | Thêm `authorizeRoles` middleware cho role-based access | Admin BE Dev | MEDIUM | S2 |
| 10 | Tách Swagger docs ra files riêng, fix imports position | Admin BE Dev | LOW | S2 |
| 11 | Cân nhắc httpOnly cookie cho JWT storage | Admin FE Dev | LOW | S3 |
| 12 | Thêm ForgotPassword page cho frontend Admin | Admin FE Dev | MEDIUM | S2 |
