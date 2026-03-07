# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth — Login, Register, Forgot/Reset/Change Password, Email Verification
- **Module**: AUTH
- **Dự án**: Admin Website
- **Sprint**: Sprint 1
- **JIRA Epic**: EP04-Login, EP05-Register, EP12-Password
- **JIRA Story**: S01 (Login BE), S03 (Login FE) | S01 (Register BE) | S01 (Password BE)
- **UC Reference**: UC001, UC002, UC003, UC004
- **Ngày đánh giá**: 2026-03-07
- **Lần đánh giá**: 4
- **Ngày đánh giá trước**: 2026-03-05

---

## 🏆 TỔNG ĐIỂM: 72/100

| Tiêu chí                    | Điểm  | Ghi chú                                                                                                   |
| --------------------------- | ----- | --------------------------------------------------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 14/15 | Hầu hết yêu cầu đạt. Còn thiếu chức năng Account Lockout sau N lần sai mật khẩu                           |
| API Design                  | 8/10  | RESTful tốt, Swagger chi tiết, url `/sessions` vẫn dùng cho login (chấp nhận được)                        |
| Architecture & Patterns     | 11/15 | Vẫn thiếu Repository abstraction. Mất thiết kế Session Invalidation pattern (bị gỡ bỏ) so với bản trước   |
| Validation & Error Handling | 10/12 | Đầy đủ, thống nhất error `{success, error: {code, message}}`. Đã fix Prisma nhưng còn `(req as any).user` |
| Security                    | 9/12  | Tụt điểm! Cơ chế `tokenVersion` (thu hồi token cũ khi đổi mật khẩu) đã BỊ XÓA BỎ hoàn toàn                |
| Code Quality                | 9/12  | Đã dọn dẹp nhiều error type `as any` của Prisma. Controller vẫn quá dài do inline Swagger                 |
| Testing                     | 0/12  | Vẫn 0% test coverage                                                                                      |
| Documentation               | 11/12 | Swagger cực kỳ chi tiết; thiếu module README                                                              |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra                                            | Đạt? | Ghi chú                                                 |
| --------------------------------------------------- | ---- | ------------------------------------------------------- |
| Route → Controller → Service → Repo separation      | ✅    | `authRoutes` → `authController` → services → Prisma ORM |
| Controller CHỈ handle request/response              | ⚠️    | Controller vẫn quá lớn do inline Swagger (950 LOC)      |
| Service chứa business logic, KHÔNG truy cập req/res | ✅    | Services nhận params thuần                              |
| Repository/Model chứa data access                   | ⚠️    | Prisma gọi TRỰC TIẾP trong các Service                  |

### Design Patterns (/5)
| Pattern                      | Có? | Đánh giá                                                      |
| ---------------------------- | --- | ------------------------------------------------------------- |
| Middleware — Auth guard      | ✅   | `authenticate`, `requireAdmin`, `authorizeRoles`              |
| Middleware — Rate limiter    | ✅   | 3 rate limiters cho login, forgot và change password đầy đủ   |
| Session Invalidation Pattern | ❌   | Đã BỊ XÓA BỎ ở phiên bản này (không còn field `tokenVersion`) |
| DTO/Schema                   | ⚠️   | Interface TypeScript đầy đủ nhưng chưa validate bằng Zod/Joi  |

---

## 📂 FILES ĐÁNH GIÁ
| File                                            | Layer      | LOC | Đánh giá tóm tắt                                                  |
| ----------------------------------------------- | ---------- | --- | ----------------------------------------------------------------- |
| `backend/src/controllers/authController.ts`     | Controller | 950 | ⚠️ Quá dài do inline Swagger Docs. Logic ổn định.                  |
| `backend/src/services/authService.ts`           | Service    | 189 | ✅ Đã clean `as any` Prisma. ❌ Mất `tokenVersion`.                 |
| `backend/src/services/passwordResetService.ts`  | Service    | 275 | ✅ Token lưu dạng hash. ❌ Không còn update `tokenVersion`          |
| `backend/src/services/changePasswordService.ts` | Service    | 151 | ✅ Hashing đúng. ❌ Không còn cơ chế invalidate token thiết bị khác |
| `backend/src/middleware/authMiddleware.ts`      | Middleware | 100 | ✅ Decodes JWT tốt. ❌ Không query DB check isActive / tokenVersion |
| `backend/src/utils/jwt.ts`                      | Util       | 44  | ✅ Expiry 8h, issuer chuẩn. ❌ Mất payload `tokenVersion`.          |
| `frontend/src/services/authService.ts`          | Service    | 82  | ⚠️ Vẫn lưu token vào `localStorage`                                |

---

## 📋 JIRA STORY TRACKING

### EP04-Login (Sprint 1)
#### S01: [Admin BE] API Đăng nhập
| #   | Checklist Item                 | Trạng thái | Ghi chú                                               |
| --- | ------------------------------ | ---------- | ----------------------------------------------------- |
| 1   | POST /api/auth/login hoạt động | ⚠️ Deviated | Route thực tế là `/api/auth/sessions` (RESTful-style) |
| 2   | JWT iss, role, hạn 8h          | ✅          | Issuer, Role và Expiry 8h đều chính xác               |
| 3   | Rate limit 5 lần/15 phút       | ✅          | `loginLimiter`                                        |
| 4   | Kiểm tra is_active trước login | ✅          | Code logic có kiểm tra                                |
| 5   | Ghi audit log                  | ✅          | Thành công & Thất bại đều ghi log                     |

### EP12-Password (Sprint 1)
#### S01: [Admin BE] API Quên/Đặt lại/Đổi Mật khẩu
| #   | Checklist Item                 | Trạng thái | Ghi chú                                                 |
| --- | ------------------------------ | ---------- | ------------------------------------------------------- |
| 1   | POST forgot-password gửi email | ✅          | `passwordResetService.ts`                               |
| 2   | Token 15 phút, one-time use    | ✅          | Hashing token lưu vào DB, xóa sau khi dùng              |
| 3   | Invalidate other sessions      | ❌          | Tính năng `tokenVersion` đã bị gỡ ra trên toàn hệ thống |

---

## 📊 SRS COMPLIANCE

### Main Flow
| Bước | SRS Yêu cầu                              | Implementation                              | Match? |
| ---- | ---------------------------------------- | ------------------------------------------- | ------ |
| 1    | User nhập email/password                 | Code thực hiện validation `isValidEmail`    | ✅      |
| 2    | Check accounts tồn tại & active          | `prisma.user.findUnique` & `isActive` check | ✅      |
| 3    | Verify password                          | `bcrypt.compare`                            | ✅      |
| 4    | Generate JWT (iss=healthguard-admin, 8h) | Hàm `generateToken`                         | ✅      |
| 5    | Log audit_logs                           | Được gọi đầy đủ trong mọi trường hợp        | ✅      |

### Alternative Flows
| Flow | SRS Yêu cầu                     | Implementation                            | Match? |
| ---- | ------------------------------- | ----------------------------------------- | ------ |
| A1   | Account locked → 423            | Error status đúng `ACCOUNT_LOCKED`        | ✅      |
| A2   | Lỗi sai credential (email/pass) | Báo generic error (tránh info disclosure) | ✅      |

### Exception Flows
| Flow | SRS Yêu cầu                | Implementation                                            | Match? |
| ---- | -------------------------- | --------------------------------------------------------- | ------ |
| E1   | Khóa account sau N lần sai | rateLimiter chỉ chặn IP chứ chưa khóa `isActive` trong DB | ❌      |

---

## ✅ ƯU ĐIỂM
1. Fixed lỗi TypeScript Prisma Model casting — Toàn bộ API liên quan tới `(prisma.user as any)` đã được xoá sạch, code typed-safe hơn.
2. Các RateLimit middlewares và Single-use Token (Reset MK) vẫn giữ nguyên thiết kế chuẩn.

## ❌ NHƯỢC ĐIỂM
1. Điểm yếu CHÍNH MỚI: Bị mất pattern bảo mật quan trọng — tính năng `tokenVersion` giúp Invalidate sessions (Rất nghiêm trọng với Security).
2. Chưa có Unit Tests (0% coverage).
3. Controller quá khó đọc do dính kèm Swagger descriptions dài 690 dòng.
4. Chưa triển khai DB Account Lockout sau nhiều lần nhập mật khẩu sai.

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. **[CRITICAL]** Gây dựng lại `tokenVersion` → Cách sửa: Thêm field `tokenVersion` vào Prisma User model, cập nhật `generateToken` chứa payload này, `authMiddleware.ts` check DB và payload so khớp, service `changePassword`/`resetPassword` tăng num này lên + 1.
2. **[CRITICAL]** Viết Unit Test → Cách sửa: Jest/Mocha cho `authService.ts` và `passwordResetService.ts`.
3. **[HIGH]** Implement Account Lock trong DB → Cách sửa: Ghi nhận failedLoginAttempts, đạt limit thì set `isActive = false` hoặc set datetime khoá.
4. **[MEDIUM]** Extract Swagger → Cách sửa: Đưa Swagger comments sang file `docs/swagger/auth.ts`.
5. **[MEDIUM]** FE HTTP-Only Cookie → Cách sửa: Ngừng lưu `hg_token` vào localStorage trên `frontend/src/services/authService.ts`.

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. Những Type Cast ngầm (vd: `(req as any).user`) → Define extend interface Request Type cho Express ở `@types/express/index.d.ts`.

## ⚠️ SAI LỆCH VỚI JIRA / SRS
| Source         | Mô tả sai lệch                                           | Mức độ | Đề xuất                             |
| -------------- | -------------------------------------------------------- | ------ | ----------------------------------- |
| SRS UC001 (E2) | Chưa chặn Lockout by Account Level trong CSDL            | 🟡      | Code thêm Lock logic                |
| Security Spec  | Thiếu Logout / Invalidate JWT Session on Password Change | 🔴      | Implement lại cơ chế `tokenVersion` |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ❌ Code cần sửa (Middleware Security Regression):
```typescript
// HIỆN TẠI:
const decoded = verifyToken(token);
// Chỉ đơn giản decode, bỏ qua database check, bỏ qua tokenVersion validity logic
(req as any).user = decoded;

// NÊN SỬA THÀNH:
const decoded = verifyToken(token);
const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
if (!user || user.tokenVersion !== decoded.tokenVersion || !user.isActive) {
  throw new Error('Session is invalid or expired.');
}
req.user = user;
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
| #   | Action                                                | Owner           | Priority | Sprint   |
| --- | ----------------------------------------------------- | --------------- | -------- | -------- |
| 1   | Restore Session Invalidation Pattern (`tokenVersion`) | BE Developer    | HIGH     | Sprint 2 |
| 2   | Thiết lập Test Environment + Viết Unit Test TỐI THIỂU | BE/QA           | CRITICAL | Sprint 2 |
| 3   | Xử lý Storage bảo mật (httpOnly Cookie cho FE)        | FE/BE Developer | MEDIUM   | Sprint 2 |
| 4   | Lockout user account (DB level) sau N attempts        | BE Developer    | MEDIUM   | Sprint 2 |

---

## 🔄 SO SÁNH VỚI LẦN ĐÁNH GIÁ TRƯỚC

> ⚠️ **CHỈ THÊM SECTION NÀY KHI ĐÂY LÀ LẦN ĐÁNH GIÁ THỨ 2 TRỞ LÊN** (tức là đã tìm thấy file review cũ).

### Tổng quan thay đổi
- **Điểm cũ**: 80/100 (ngày 2026-03-05)
- **Điểm mới**: 72/100 (ngày 2026-03-07)
- **Thay đổi**: -8 điểm

### So sánh điểm theo tiêu chí
| Tiêu chí                    | Điểm cũ | Điểm mới | Thay đổi | Ghi chú                                                        |
| --------------------------- | ------- | -------- | -------- | -------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 14/15   | 14/15    | 0        | Không đổi                                                      |
| API Design                  | 8/10    | 8/10     | 0        | Không đổi                                                      |
| Architecture & Patterns     | 12/15   | 11/15    | -1       | Phá vỡ Pattern Invalidation                                    |
| Validation & Error Handling | 10/12   | 10/12    | 0        | Đã dọn Prisma Any                                              |
| Security                    | 12/12   | 9/12     | -3       | Lỗ hổng lớn mất check `tokenVersion`, lộ rủi ro session replay |
| Code Quality                | 8/12    | 9/12     | +1       | Type inference tốt hơn với ORM prisma                          |
| Testing                     | 0/12    | 0/12     | 0        | Vẫn KHÔNG có test                                              |
| Documentation               | 11/12   | 11/12    | 0        | Giữ vững Swagger Doc                                           |

### ✅ Nhược điểm ĐÃ KHẮC PHỤC (có trong lần trước, không còn trong lần này)
| #   | Nhược điểm cũ                     | Trạng thái | Chi tiết khắc phục                                                                             |
| --- | --------------------------------- | ---------- | ---------------------------------------------------------------------------------------------- |
| 1   | `(prisma.user as any)` workaround | ✅ Đã sửa   | Lỗi sinh schema Prisma đã xử lý, dev đã xoá toàn bộ workaround này. Mã nguồn sạch hơn đáng kể. |

### ⚠️ Nhược điểm VẪN TỒN TẠI (có trong cả lần trước và lần này)
| #   | Nhược điểm                    | Mức độ | Ghi chú            |
| --- | ----------------------------- | ------ | ------------------ |
| 1   | 0% test coverage              | 🔴      | Nguy hiểm cao      |
| 2   | Controller ~950 LOC           | 🟡      | Không có cải thiện |
| 3   | JWT lưu localStorage (FE)     | 🟡      | Không có cải thiện |
| 4   | Account lockout chua trong DB | 🟡      | Không có cải thiện |

### 🆕 Nhược điểm MỚI PHÁT SINH (không có trong lần trước, xuất hiện lần này)
| #   | Nhược điểm mới                               | Mức độ | Ghi chú                                                                                                                               |
| --- | -------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Lược bỏ hoàn toàn Code Invalidate Session Cũ | 🔴      | Thuật toán `tokenVersion` trên `jwt`/`middleware` bị xoá sạch khiến Password Change không thể đăng xuất các account từ thiết bị khác. |

### 💬 Nhận xét tổng quan
> Về chất lượng source code typescript đã có điểm sáng rõ rệt: sự phụ thuộc vào type `as any` khi xài ORM giảm xuống 0, mã nguồn chuẩn hơn. Tuy nhiên việc thiết kế session bằng JWT đã LỖI HẸN nghiêm trọng sau khi bị loại bỏ mất flow kiểm soát phi tập trung (`tokenVersion`) khiến rating mảng Security và Arch pattern lao dốc. Team cần bổ sung lại gấp rút chức năng này và dành nguồn lực cho Coverage Test!
