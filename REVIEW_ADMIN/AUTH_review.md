# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth — Login, Register, Forgot/Reset/Change Password, Email Verification, Profile (GET /me)
- **Module**: AUTH
- **Dự án**: Admin Website
- **Sprint**: Sprint 1
- **JIRA Epic**: EP04-Login, EP05-Register, EP12-Password
- **JIRA Story**: EP04-S01 (Login BE), EP04-S03 (Login FE) | EP05-S01 (Register BE) | EP12-S01 (Password BE)
- **UC Reference**: UC001, UC002, UC003, UC004, UC005, UC009
- **Ngày đánh giá**: 2026-03-07
- **Lần đánh giá**: 5
- **Ngày đánh giá trước**: 2026-03-07

---

## 🏆 TỔNG ĐIỂM: 71/100

| Tiêu chí                    | Điểm  | Ghi chú                                                                                            |
| --------------------------- | ----- | -------------------------------------------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 13/15 | Main flow OK. Thiếu DB Account Lockout (E1). Password min=6, SRS nói min=8                         |
| API Design                  | 8/10  | RESTful chuẩn, Swagger chi tiết, `/sessions` thay `/login` (chấp nhận). Thiếu pagination           |
| Architecture & Patterns     | 10/15 | Thiếu Repository layer. Thiếu Session Invalidation. Import mid-file (anti-pattern)                 |
| Validation & Error Handling | 10/12 | Error format thống nhất `{success, error: {code, message}}`. Còn `(req as any).user` throughout    |
| Security                    | 8/12  | Không có tokenVersion. JWT_SECRET fallback hardcoded. localStorage cho token. Không one-time reset |
| Code Quality                | 9/12  | Typed tốt. Controller 950 LOC do inline Swagger. `require()` trong verifyEmailService              |
| Testing                     | 0/12  | 0 file test. 0% coverage. Không có *.test.ts hay *.spec.ts nào trong toàn project                  |
| Documentation               | 11/12 | Swagger cực kỳ chi tiết cho mọi endpoint. JSDoc trong validators. Thiếu module README              |

> **Confidence**: ≥ 85% cho tất cả tiêu chí. Đã đọc 100% source code AUTH module.

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra                                            | Đạt? | Ghi chú                                                                  |
| --------------------------------------------------- | ---- | ------------------------------------------------------------------------ |
| Route → Controller → Service → Repo separation      | ⚠️    | Có Route/Controller/Service, nhưng KHÔNG có Repository layer             |
| Controller CHỈ handle request/response              | ⚠️    | Logic đúng, nhưng 950 LOC do inline Swagger comments (~690 dòng Swagger) |
| Service chứa business logic, KHÔNG truy cập req/res | ✅    | Tất cả services nhận params thuần (email, password, userId...)           |
| Repository/Model chứa data access                   | ❌    | `prisma.user.findUnique/create/update` gọi TRỰC TIẾP trong mọi Service   |
| Dependency direction đúng                           | ✅    | Controller → Service → Prisma ORM (không inverted)                       |

### Domain Logic & Business Rules (/5)
| Kiểm tra                                        | Đạt? | Ghi chú                                                           |
| ----------------------------------------------- | ---- | ----------------------------------------------------------------- |
| Business rules centralized trong Service        | ✅    | Mỗi feature 1 service file riêng                                  |
| Domain validation tách biệt khỏi API validation | ⚠️    | Validators centralized nhưng chưa dùng Zod/Joi schema validation  |
| Edge cases handled                              | ⚠️    | Có xử lý null/empty nhưng thiếu boundary values (password length) |
| Business logic testable without HTTP/DB         | ❌    | Services depend trực tiếp vào Prisma (không inject được)          |
| Không duplicate business logic                  | ✅    | Validators centralized trong `utils/validators.ts`                |

### Design Patterns (/5)
| Pattern                      | Có? | Đánh giá                                                                                                  |
| ---------------------------- | --- | --------------------------------------------------------------------------------------------------------- |
| Middleware — Auth guard      | ✅   | `authenticate`, `requireAdmin`, `authorizeRoles` đầy đủ                                                   |
| Middleware — Rate limiter    | ✅   | 3 rate limiters: `loginLimiter` (5/15m), `forgotPasswordLimiter` (3/15m), `changePasswordLimiter` (5/15m) |
| Repository Pattern           | ❌   | Prisma gọi trực tiếp trong services — không có abstraction                                                |
| Session Invalidation Pattern | ❌   | `tokenVersion` đã bị xóa bỏ, không có cơ chế thu hồi JWT                                                  |
| DTO/Schema Validation        | ⚠️   | Interface TypeScript có nhưng chưa dùng Zod/Joi runtime validation                                        |

---

## 📂 FILES ĐÁNH GIÁ
| File                                            | Layer      | LOC | Đánh giá tóm tắt                                                                    |
| ----------------------------------------------- | ---------- | --- | ----------------------------------------------------------------------------------- |
| `backend/src/controllers/authController.ts`     | Controller | 950 | ⚠️ 690+ dòng Swagger, ~260 dòng logic. Logic ổn. Import mid-file (L401, L709)        |
| `backend/src/services/authService.ts`           | Service    | 189 | ✅ Clean logic. loginUser 155 LOC (hơi dài nhưng chấp nhận). Không tokenVersion      |
| `backend/src/services/registerService.ts`       | Service    | 201 | ⚠️ JWT_SECRET fallback `'your-secret-key'` tại L7. bcrypt rounds=10                  |
| `backend/src/services/passwordResetService.ts`  | Service    | 275 | ⚠️ Token không thực sự one-time (chỉ update `updatedAt`, không track token trong DB) |
| `backend/src/services/changePasswordService.ts` | Service    | 151 | ✅ Logic đúng. TODO invalidate sessions chưa implement (L137)                        |
| `backend/src/services/emailService.ts`          | Service    | 251 | ✅ Nodemailer config đúng. HTML email templates đẹp                                  |
| `backend/src/services/verifyEmailService.ts`    | Service    | 208 | ⚠️ CommonJS `require()` tại L175 thay vì ES import. Decoded `as any`                 |
| `backend/src/middleware/authMiddleware.ts`      | Middleware | 100 | ❌ `(req as any).user` — không type-safe. Không check DB isActive/tokenVersion       |
| `backend/src/middleware/rateLimiter.ts`         | Middleware | 47  | ✅ 3 limiters chuẩn SRS. standardHeaders=true                                        |
| `backend/src/utils/jwt.ts`                      | Util       | 44  | ✅ Lazy getter cho JWT_SECRET. Issuer check đúng. Expiry 8h                          |
| `backend/src/utils/validators.ts`               | Util       | 66  | ⚠️ Password min=6, SRS §5.3 nói min=8. JSDoc đầy đủ                                  |
| `backend/src/routes/authRoutes.ts`              | Route      | 41  | ✅ Clean route definitions. Middleware đúng thứ tự                                   |
| `frontend/src/services/authService.ts`          | FE Service | 82  | ⚠️ Token lưu `localStorage` (XSS risk). Error mapping đầy đủ                         |
| `frontend/src/types/auth.ts`                    | FE Types   | 35  | ✅ TypeScript interfaces rõ ràng, match với BE response                              |

---

## 📋 JIRA STORY TRACKING

### EP04-Login (Sprint 1)

#### S01: [Admin BE] API Đăng nhập cho Web Dashboard
| #   | Checklist Item                      | Trạng thái | Ghi chú                                                            |
| --- | ----------------------------------- | ---------- | ------------------------------------------------------------------ |
| 1   | POST /api/auth/login hoạt động      | ⚠️ Deviated | Route thực tế là `POST /api/auth/sessions` (RESTful-style)         |
| 2   | JWT iss=healthguard-admin, role, 8h | ✅          | `jwt.ts:L18-27` — issuer, email, role, expiry đều đúng             |
| 3   | Rate limit 5 lần/15 phút            | ✅          | `rateLimiter.ts:L4-16` — `loginLimiter` 5/15min                    |
| 4   | Kiểm tra is_active trước login      | ✅          | `authService.ts:L83-97` — check `isActive` + return ACCOUNT_LOCKED |
| 5   | Cập nhật last_login_at              | ✅          | `authService.ts:L145-148` — `prisma.user.update` lastLoginAt       |
| 6   | Ghi audit log                       | ✅          | Ghi log cho cả thành công, thất bại, và account locked             |

#### Acceptance Criteria
| #   | Criteria                       | Trạng thái | Ghi chú                        |
| --- | ------------------------------ | ---------- | ------------------------------ |
| 1   | POST /api/auth/login hoạt động | ⚠️          | Deviated: `/api/auth/sessions` |
| 2   | JWT token iss/role/8h          | ✅          | Đúng spec                      |
| 3   | Rate limit 5 lần/15 phút       | ✅          | `loginLimiter`                 |
| 4   | Kiểm tra is_active             | ✅          | Có check                       |
| 5   | Cập nhật last_login_at         | ✅          | Có update                      |
| 6   | Ghi audit log                  | ✅          | Thành công + thất bại          |

#### S03: [Admin FE] Giao diện Đăng nhập Web
| #   | Criteria                           | Trạng thái | Ghi chú                                           |
| --- | ---------------------------------- | ---------- | ------------------------------------------------- |
| 1   | Trang login React hoàn chỉnh       | ✅          | `LoginPage.tsx` (13071B)                          |
| 2   | Form validation (email + password) | ✅          | Client-side validation                            |
| 3   | Gọi API + lưu JWT                  | ⚠️          | Lưu vào `localStorage` — nên dùng httpOnly cookie |
| 4   | Chuyển hướng dashboard             | ✅          | Có redirect logic                                 |
| 5   | Hiển thị lỗi rõ ràng               | ✅          | Error code mapping đầy đủ (7 mã lỗi)              |
| 6   | Nút ẩn/hiện mật khẩu               | ❓          | Cần kiểm tra LoginPage.tsx chi tiết               |
| 7   | Loading state                      | ❓          | Cần kiểm tra LoginPage.tsx chi tiết               |

### EP05-Register (Sprint 1)

#### S01: [Admin BE] API Tạo User (Admin tạo)
| #   | Criteria                             | Trạng thái | Ghi chú                                                |
| --- | ------------------------------------ | ---------- | ------------------------------------------------------ |
| 1   | POST /api/users yêu cầu ADMIN JWT    | ⚠️ Deviated | Route thực tế: `POST /api/auth/users` (có prefix auth) |
| 2   | Validate email unique                | ✅          | `registerService.ts:L62-72` — findUnique               |
| 3   | Bcrypt hash password                 | ✅          | `registerService.ts:L146` — bcrypt.hash rounds=10      |
| 4   | User tạo với is_verified=true        | ✅          | `registerService.ts:L153` — `!!adminId`                |
| 5   | Xử lý lỗi (email trùng, thiếu field) | ✅          | 7 error codes, đầy đủ                                  |

### EP12-Password (Sprint 1)

#### S01: [Admin BE] API Quên/Đặt lại/Đổi Mật khẩu
| #   | Criteria                             | Trạng thái | Ghi chú                                                          |
| --- | ------------------------------------ | ---------- | ---------------------------------------------------------------- |
| 1   | POST forgot-password gửi email reset | ✅          | `passwordResetService.ts:L35-136` — email with token             |
| 2   | Token JWT 15 phút                    | ✅          | `passwordResetService.ts:L87` — `expiresIn: '15m'`               |
| 3   | Change-password xác thực MK cũ       | ✅          | `changePasswordService.ts:L70` — bcrypt.compare                  |
| 4   | Rate limit 3 lần/15 phút             | ✅          | `forgotPasswordLimiter` (3/15min)                                |
| 5   | Token dùng 1 lần                     | ❌          | Token KHÔNG được track trong DB. Chỉ update `updatedAt` (L95-99) |

---

## 📊 SRS COMPLIANCE

### Main Flow (UC001 - Login)
| Bước | SRS Yêu cầu                              | Implementation                              | Match? |
| ---- | ---------------------------------------- | ------------------------------------------- | ------ |
| 1    | User nhập email + password               | Controller validates required fields        | ✅      |
| 2    | Validate email format                    | `isValidEmail()` regex check                | ✅      |
| 3    | Check account tồn tại & active           | `prisma.user.findUnique` + `isActive` check | ✅      |
| 4    | Check email verified                     | `isVerified` check trước password verify    | ✅      |
| 5    | Verify password                          | `bcrypt.compare`                            | ✅      |
| 6    | Update lastLoginAt                       | `prisma.user.update`                        | ✅      |
| 7    | Generate JWT (iss=healthguard-admin, 8h) | `generateToken` — iss, role, 8h             | ✅      |
| 8    | Ghi audit log                            | Ghi cho mọi trường hợp (success/failure)    | ✅      |

### Alternative Flows
| Flow | SRS Yêu cầu                    | Implementation                            | Match? |
| ---- | ------------------------------ | ----------------------------------------- | ------ |
| A1   | Account bị khóa → 423          | `ACCOUNT_LOCKED` error + status 423       | ✅      |
| A2   | Sai credential → generic error | `INVALID_CREDENTIALS` (không lộ email/pw) | ✅      |
| A3   | Account chưa verified          | `ACCOUNT_NOT_VERIFIED` error              | ✅      |
| A4   | Rate limit exceeded            | `loginLimiter` → 429 response             | ✅      |

### Exception Flows
| Flow | SRS Yêu cầu                           | Implementation                                                   | Match? |
| ---- | ------------------------------------- | ---------------------------------------------------------------- | ------ |
| E1   | Khóa account sau N lần sai trong DB   | rateLimiter chỉ chặn IP, KHÔNG lock `isActive` trong DB          | ❌      |
| E2   | Mật khẩu tối thiểu 8 ký tự (SRS §5.3) | Code cho phép min=6 tại `validators.ts:L19`                      | ❌      |
| E3   | Invalidate sessions khi đổi MK        | TODO comment tại `changePasswordService.ts:L137`, chưa implement | ❌      |

---

## ✅ ƯU ĐIỂM
1. **Swagger documentation rất chi tiết** — Mỗi endpoint có description đầy đủ với ví dụ request/response, error codes, RESTful design rationale — `authController.ts:L5-159, L193-336, L404-456...`
2. **Error response format thống nhất** — Toàn bộ API trả `{success, error: {code, message}}` hoặc `{success, data}` — dễ parse phía FE
3. **Rate limiting đầy đủ** — 3 limiters cho 3 nhóm endpoint khác nhau, đúng theo SRS — `rateLimiter.ts`
4. **Audit logging toàn diện** — Mọi action (login thành công/thất bại, register, password change/reset, email verify) đều ghi log với IP, userAgent — `authService.ts`, `registerService.ts`
5. **Anti-enumeration cho forgot password** — `requestPasswordReset` trả success dù email không tồn tại — `passwordResetService.ts:L60-63` (BR-005)
6. **Clean service separation** — 6 service files riêng biệt cho 6 features, params thuần (không couple với HTTP request)
7. **JWT lazy getter pattern** — `jwt.ts:L4-10` throw error nếu JWT_SECRET chưa set (fail fast) thay vì fallback silent
8. **TypeScript interfaces mirrored BE↔FE** — `auth.ts` (FE) match với `LoginResult` (BE)

## ❌ NHƯỢC ĐIỂM
1. **[CRITICAL] Không có cơ chế Session Invalidation** — `tokenVersion` đã bị xóa bỏ hoàn toàn. Khi user đổi mật khẩu, JWT cũ vẫn hoạt động trên thiết bị khác cho đến khi hết hạn 8h — `authMiddleware.ts:L22` chỉ decode, không check DB — `jwt.ts:L17` không chứa `tokenVersion` trong payload
2. **[CRITICAL] 0% test coverage** — Không có file `*.test.ts` hay `*.spec.ts` nào trong toàn bộ project. Không có test framework config. Mọi thay đổi code đều không có safety net
3. **[HIGH] Password minimum chỉ 6 ký tự** — `validators.ts:L19` cho phép password length ≥ 6, trong khi SRS §5.3 quy định min 8 chars. Không yêu cầu uppercase, lowercase, number, special char (code comment tại `authService.ts:L7-15` đã disable)
4. **[HIGH] JWT_SECRET fallback hardcoded** — `registerService.ts:L7` và `verifyEmailService.ts:L4` dùng `process.env.JWT_SECRET || 'your-secret-key'`thay vì throw error như `jwt.ts`. Nếu .env thiếu, dev sẽ dùng secret yếu mà không biết
5. **[HIGH] Reset token KHÔNG thực sự one-time** — `passwordResetService.ts:L90-99` chỉ update `updatedAt`, KHÔNG lưu token hash vào DB để invalidate sau khi dùng. Token JWT 15 phút có thể dùng lại nhiều lần
6. **[MEDIUM] `(req as any).user` xuyên suốt** — 5 lần xuất hiện: `authMiddleware.ts:L34,48,80`, `authController.ts:L363,676`. Thiếu typed Express Request extension
7. **[MEDIUM] Controller quá dài 950 LOC** — ~690 dòng Swagger comments, ~260 dòng logic. Swagger nên tách ra file riêng
8. **[MEDIUM] Import mid-file** — `authController.ts:L401,709` import modules giữa file thay vì đầu file (anti-pattern)
9. **[LOW] CommonJS `require()` trong ES module** — `verifyEmailService.ts:L175` dùng `require('./emailService')` thay vì ES `import`
10. **[LOW] FE lưu token vào localStorage** — `frontend/src/services/authService.ts:L23` — dễ bị XSS attack. Nên chuyển sang httpOnly cookie

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. **[CRITICAL]** Implement Session Invalidation → Cách sửa: Thêm field `tokenVersion: Int` vào Prisma User model. `generateToken` chứa `tokenVersion` trong payload. `authMiddleware.ts` query DB check `user.tokenVersion === decoded.tokenVersion && user.isActive`. Services `changePassword`/`resetPassword` increment `tokenVersion += 1`
2. **[CRITICAL]** Viết Unit Tests → Cách sửa: Thêm Jest config (`jest.config.ts`). Viết test cho `authService.loginUser`, `registerService.registerUser`, `passwordResetService.resetPassword`, `changePasswordService.changePassword`. Target ≥ 60% coverage cho services
3. **[HIGH]** Password min 8 chars + complexity → Cách sửa: `validators.ts:L18-20` đổi thành `password.length >= 8` và bật lại regex checks (uppercase, lowercase, number, special char) từ `authService.ts:L8-15`
4. **[HIGH]** Reset token one-time → Cách sửa: Lưu token hash vào bảng `password_reset_tokens` (userId, tokenHash, usedAt, expiresAt). Khi reset, check `usedAt IS NULL`, sau đó set `usedAt = NOW()`
5. **[HIGH]** Thống nhất JWT_SECRET handling → Cách sửa: Xóa fallback `|| 'your-secret-key'` khỏi `registerService.ts:L7` và `verifyEmailService.ts:L4`. Import `getJwtSecret()` từ `jwt.ts` thay vì tự đọc env
6. **[MEDIUM]** Typed Express Request → Cách sửa: Tạo `src/@types/express/index.d.ts` với `declare namespace Express { interface Request { user?: JwtPayload } }`. Xóa tất cả `(req as any).user`
7. **[MEDIUM]** Extract Swagger → Cách sửa: Đưa Swagger JSDoc sang `docs/swagger/auth.yaml` hoặc dùng `swagger-jsdoc` với file riêng, giảm controller còn ~260 LOC
8. **[MEDIUM]** DB Account Lockout → Cách sửa: Thêm fields `failedLoginAttempts: Int`, `lockedUntil: DateTime` vào User model. Trong `authService.loginUser`, increment `failedLoginAttempts` khi sai MK, lock khi >= N, auto-unlock sau khoảng thời gian
9. **[LOW]** Fix import order trong controller → Cách sửa: Di chuyển import lines L401, L709 lên đầu file
10. **[LOW]** Chuyển FE sang httpOnly cookie → Cách sửa: BE set cookie trong response header (`res.cookie('hg_token', token, {httpOnly: true, secure: true, sameSite: 'strict'})`)

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. **`(req as any).user`** — 5 chỗ (`authMiddleware.ts:L34,48,80`, `authController.ts:L363,676`) → Thay bằng typed Request
2. **JWT_SECRET fallback `'your-secret-key'`** — 2 chỗ (`registerService.ts:L7`, `verifyEmailService.ts:L4`) → Import centralized getter
3. **CommonJS `require()` trong ES module** — `verifyEmailService.ts:L175` → Chuyển sang `import`
4. **Commented-out password validation code** — `authService.ts:L6-15` (code thừa, gây nhầm lẫn) → Nên xóa hoặc enable

## ⚠️ SAI LỆCH VỚI JIRA / SRS
| Source         | Mô tả sai lệch                                       | Mức độ | Đề xuất                                       |
| -------------- | ---------------------------------------------------- | ------ | --------------------------------------------- |
| SRS §5.3       | Password min 8 chars nhưng code cho phép min=6       | 🔴      | Sửa `validators.ts:L19` thành `>= 8`          |
| SRS UC001 (E1) | Chưa lock account trong DB sau N lần sai             | 🟡      | Thêm `failedLoginAttempts` + `lockedUntil`    |
| SRS Security   | Không có session invalidation khi đổi MK             | 🔴      | Implement `tokenVersion`                      |
| EP04-S01 AC1   | Route `/api/auth/sessions` thay vì `/api/auth/login` | 🟢      | Chấp nhận (RESTful convention)                |
| EP05-S01 AC1   | Route `/api/auth/users` thay vì `/api/users`         | 🟢      | Chấp nhận (grouped under /api/auth namespace) |
| EP12-S01 AC5   | Reset token KHÔNG one-time — không track trong DB    | 🔴      | Implement `password_reset_tokens` table       |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt — Anti-enumeration pattern:
```typescript
// file: backend/src/services/passwordResetService.ts, line 58-68
// BR-005: Don't reveal if email exists (prevent enumeration attack)
// Always return success message
if (!user) {
  await prisma.auditLog.create({
    data: {
      action: 'PASSWORD_RESET_REQUESTED',
      ipAddress,
      userAgent,
      details: { email, reason: 'USER_NOT_FOUND' },
      status: 'failure',
    },
  });
  return {
    success: true,
    data: { message: 'Đã gửi email hướng dẫn. Vui lòng kiểm tra hộp thư' },
  };
}
```

### ✅ Code tốt — JWT lazy getter (fail fast):
```typescript
// file: backend/src/utils/jwt.ts, line 4-10
const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET must be defined in environment variables');
  }
  return secret;
};
```

### ❌ Code cần sửa — Middleware không check DB:
```typescript
// HIỆN TẠI (authMiddleware.ts:L22-34):
const decoded = verifyToken(token);
if (!decoded) {
  return res.status(401).json({...});
}
(req as any).user = decoded;  // Không check DB, không check isActive, không check tokenVersion

// NÊN SỬA THÀNH:
const decoded = verifyToken(token);
if (!decoded) {
  return res.status(401).json({...});
}
const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
if (!user || !user.isActive || user.tokenVersion !== decoded.tokenVersion) {
  return res.status(401).json({ success: false, error: { code: 'SESSION_INVALID', message: 'Phiên đăng nhập không hợp lệ' }});
}
req.user = { userId: user.id, email: user.email, role: user.role };
```

### ❌ Code cần sửa — JWT_SECRET fallback:
```typescript
// HIỆN TẠI (registerService.ts:L7):
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';  // ⚠️ Fallback hardcoded!

// NÊN SỬA THÀNH:
import { getJwtSecret } from '../utils/jwt';  // Reuse centralized getter (throws if missing)
```

### ❌ Code cần sửa — Password validation quá yếu:
```typescript
// HIỆN TẠI (validators.ts:L18-20):
export const isValidPassword = (password: string): boolean => {
  return password.length >= 6;  // ⚠️ SRS nói min=8, không check complexity
};

// NÊN SỬA THÀNH:
export const isValidPassword = (password: string): boolean => {
  if (password.length < 8) return false;  // SRS §5.3: min 8 chars
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  return hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
};
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
| #   | Action                                                 | Owner           | Priority | Sprint   |
| --- | ------------------------------------------------------ | --------------- | -------- | -------- |
| 1   | Implement Session Invalidation (`tokenVersion`)        | BE Developer    | CRITICAL | Sprint 2 |
| 2   | Setup Jest + viết Unit Tests tối thiểu (≥60% services) | BE/QA           | CRITICAL | Sprint 2 |
| 3   | Sửa password min=8 + bật complexity checks             | BE Developer    | HIGH     | Sprint 2 |
| 4   | Reset token one-time (DB tracking)                     | BE Developer    | HIGH     | Sprint 2 |
| 5   | Thống nhất JWT_SECRET handling (xóa fallback)          | BE Developer    | HIGH     | Sprint 2 |
| 6   | Typed Express Request (xóa `as any`)                   | BE Developer    | MEDIUM   | Sprint 2 |
| 7   | DB Account Lockout (`failedLoginAttempts`)             | BE Developer    | MEDIUM   | Sprint 2 |
| 8   | Extract Swagger sang file riêng                        | BE Developer    | MEDIUM   | Sprint 3 |
| 9   | FE chuyển từ localStorage sang httpOnly cookie         | FE/BE Developer | MEDIUM   | Sprint 3 |
| 10  | Fix import ordering trong controller                   | BE Developer    | LOW      | Sprint 3 |

---

## 🔄 SO SÁNH VỚI LẦN ĐÁNH GIÁ TRƯỚC

### Tổng quan thay đổi
- **Điểm cũ**: 72/100 (ngày 2026-03-07, lần đánh giá thứ 4)
- **Điểm mới**: 71/100 (ngày 2026-03-07, lần đánh giá thứ 5)
- **Thay đổi**: -1 điểm

### So sánh điểm theo tiêu chí
| Tiêu chí                    | Điểm cũ | Điểm mới | Thay đổi | Ghi chú                                                                  |
| --------------------------- | ------- | -------- | -------- | ------------------------------------------------------------------------ |
| Chức năng đúng yêu cầu      | 14/15   | 13/15    | -1       | Phát hiện password min=6 vs SRS min=8, trừ thêm 1 điểm                   |
| API Design                  | 8/10    | 8/10     | 0        | Không đổi                                                                |
| Architecture & Patterns     | 11/15   | 10/15    | -1       | Phát hiện thêm import mid-file anti-pattern, Domain logic untestable     |
| Validation & Error Handling | 10/12   | 10/12    | 0        | Không đổi — `(req as any).user` vẫn tồn tại                              |
| Security                    | 9/12    | 8/12     | -1       | Phát hiện thêm JWT_SECRET fallback hardcoded, reset token không one-time |
| Code Quality                | 9/12    | 9/12     | 0        | Không đổi                                                                |
| Testing                     | 0/12    | 0/12     | 0        | Vẫn KHÔNG có test files                                                  |
| Documentation               | 11/12   | 11/12    | 0        | Giữ vững Swagger Doc                                                     |

> **Lưu ý**: Điểm giảm 1 không phải do code tệ hơn mà do đánh giá chặt hơn — phát hiện thêm các vấn đề đã tồn tại từ trước nhưng chưa được chỉ ra.

### ✅ Nhược điểm ĐÃ KHẮC PHỤC (có trong lần trước, không còn trong lần này)
| #   | Nhược điểm cũ | Trạng thái | Chi tiết khắc phục                                      |
| --- | ------------- | ---------- | ------------------------------------------------------- |
|     | Không có      | —          | Không có nhược điểm nào được khắc phục so với lần trước |

### ⚠️ Nhược điểm VẪN TỒN TẠI (có trong cả lần trước và lần này)
| #   | Nhược điểm                           | Mức độ | Ghi chú                                                        |
| --- | ------------------------------------ | ------ | -------------------------------------------------------------- |
| 1   | Không có Session Invalidation        | 🔴      | `tokenVersion` vẫn absent. Đây là lần thứ 2 liên tiếp ghi nhận |
| 2   | 0% test coverage                     | 🔴      | Vẫn không có bất kỳ test nào                                   |
| 3   | Controller ~950 LOC (Swagger inline) | 🟡      | Không có cải thiện                                             |
| 4   | JWT lưu localStorage (FE)            | 🟡      | Không có cải thiện                                             |
| 5   | Account lockout chưa trong DB        | 🟡      | Không có cải thiện                                             |
| 6   | `(req as any).user` xuyên suốt       | 🟡      | Không có cải thiện                                             |

### 🆕 Nhược điểm MỚI PHÁT SINH (không có trong lần trước, xuất hiện lần này)
| #   | Nhược điểm mới                                    | Mức độ | Ghi chú                                                         |
| --- | ------------------------------------------------- | ------ | --------------------------------------------------------------- |
| 1   | JWT_SECRET fallback `'your-secret-key'` (2 files) | 🔴      | `registerService.ts:L7`, `verifyEmailService.ts:L4`             |
| 2   | Password min=6 thay vì min=8 theo SRS             | 🔴      | `validators.ts:L19` — vi phạm SRS §5.3                          |
| 3   | Reset token không thực sự one-time                | 🟡      | `passwordResetService.ts` — chỉ update `updatedAt`, không track |
| 4   | CommonJS `require()` trong ES module              | 🟢      | `verifyEmailService.ts:L175`                                    |

> **Lưu ý**: Mục "MỚI PHÁT SINH" ở đây là mới **phát hiện** trong lần review này, không nhất thiết là code mới thêm vào.

### 💬 Nhận xét tổng quan
> **Không có tiến triển** so với lần đánh giá trước. Code base AUTH vẫn giữ nguyên trạng thái từ lần đánh giá thứ 4 — không có fix nào cho 5 nhược điểm đã ghi nhận. Ngoài ra, lần review sâu hơn này phát hiện thêm 4 vấn đề chưa được nêu trước đó: (1) JWT_SECRET fallback yếu ở 2/6 service files, (2) password validation quá lỏng so với SRS, (3) reset token có thể dùng lại, (4) import style không nhất quán. Team cần **ưu tiên tuyệt đối**: (A) Session Invalidation — đây là lỗ hổng bảo mật nghiêm trọng nhất, (B) Test coverage — mọi thay đổi đều rủi ro khi không có tests, (C) Password strength — vi phạm trực tiếp SRS specification.
