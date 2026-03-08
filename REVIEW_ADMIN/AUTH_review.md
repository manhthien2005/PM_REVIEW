# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth — Login, Register, Forgot/Reset/Change Password, Logout, Profile (GET /me)
- **Module**: AUTH
- **Dự án**: Admin
- **Sprint**: Sprint 1
- **JIRA Epic**: EP04-Login, EP05-Register, EP12-Password
- **JIRA Story**: EP04-S01 (Login BE), EP04-S03 (Login FE), EP05-S01 (Register BE), EP12-S01 (Password BE)
- **UC Reference**: UC001, UC002, UC003, UC004, UC005, UC009
- **Ngày đánh giá**: 2026-03-08
- **Lần đánh giá**: 7
- **Ngày đánh giá trước**: 2026-03-08

---

## 🏆 TỔNG ĐIỂM: 91/100

| Tiêu chí                    | Điểm  | Ghi chú                                                                                                                                      |
| --------------------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 15/15 | Main flow hoàn thiện. Account Lockout (E1). Password min=8. Mã hoá cookie đầy đủ. Một token chỉ dùng một lần.                                |
| API Design                  | 9/10  | RESTful chuẩn. Response wrapper thống nhất qua `ApiResponse.js`. Thiếu chi tiết field-level validation errors cho client.                    |
| Architecture & Patterns     | 13/15 | Clean Architecture tốt. Tuy nhiên thiếu tầng Repository và service dùng thẳng ORM. Chưa tận dụng Middleware `validate.js` trong Auth routes. |
| Validation & Error Handling | 10/12 | Validation được xử lý inline trong controller, ném ra lỗi chung thay vì chi tiết từng trường bị lỗi. Error format vẫn chuẩn `ApiError`.      |
| Security                    | 12/12 | Áp dụng `token_version`. One-time reset token qua DB. HttpOnly Cookie cho JWT (Fix XSS). Rate limiting vững vàng.                            |
| Code Quality                | 11/12 | Code JavaScript cực kỳ sạch, không God function, logic rõ ràng mạch lạc. Nguyên lý SOLID được tuân thủ.                                      |
| Testing                     | 11/12 | 100% test coverage cho logic với Jest (10 test files) mock `prisma` rõ ràng bao trọn edge cases.                                             |
| Documentation               | 10/12 | Comment đầy đủ, giải thích code logic trong function, có API_GUIDE.md hỗ trợ.                                                                |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra                                       | Đạt? | Ghi chú                                                                                               |
| ---------------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------- |
| Route → Controller → Service → Repo separation | ⚠️    | Có Route/Controller/Service, nhưng Prisma ORM query trực tiếp tại Service layer.                      |
| Controller CHỈ handle request/response         | ✅    | Controller mỏng, parse req gửi cho authService. Nhưng Controller lại chứa luôn block code Validation. |
| Service chứa business logic, KHÔNG req/res     | ✅    | `authService` xử lý logic, không dính líu đến params của Express.                                     |

### Design Patterns (/5)
| Pattern                      | Có? | Đánh giá                                                                                                         |
| ---------------------------- | --- | ---------------------------------------------------------------------------------------------------------------- |
| Middleware                   | ⚠️   | Đã có `authenticate`, `requireAdmin`, `rateLimit`. Tuy nhiên CHƯA sử dụng `validate` middleware cho Auth routes. |
| Session Invalidation Pattern | ✅   | Dùng biến đếm `token_version` trong JWT payload, cực kỳ an toàn để vô hiệu hóa JWT khi đổi Session.              |

---

## 📂 FILES ĐÁNH GIÁ
| File                                         | Layer      | LOC | Đánh giá tóm tắt                                                                              |
| -------------------------------------------- | ---------- | --- | --------------------------------------------------------------------------------------------- |
| `backend/src/controllers/auth.controller.js` | Controller | 121 | Gọn nhẹ nhưng chứa cả phần IF/ELSE để bắt valid input thay vì dùng middleware validate riêng. |
| `backend/src/services/auth.service.js`       | Service    | 437 | File trung tâm, xử lý validation nghiệp vụ, hashing. Rất dễ nhìn.                             |
| `backend/src/middlewares/auth.js`            | Middleware | 122 | Handle tốt logic lấy JWT cookie/header, verify `token_version`.                               |
| `backend/src/middlewares/validate.js`        | Middleware | 81  | File middleware validate mạnh mẽ nhưng KHÔNG được mapping vào `auth.routes.js`.               |
| `backend/src/routes/auth.routes.js`          | Route      | 31  | Gọn gàng nhưng bỏ sót middleware check scheme input.                                          |

---

## 📋 JIRA STORY TRACKING

### Epic: EP04-Login (Sprint 1)

#### Admin BE
| #   | Checklist Item                    | Trạng thái | Ghi chú                                                      |
| --- | --------------------------------- | ---------- | ------------------------------------------------------------ |
| 1   | POST /api/v1/auth/login hoạt động | ✅          | Route chuẩn RESTful, sử dụng cookie HttpOnly để nhúng Token. |
| 2   | Session Invalidation / DB Lockout | ✅          | Check lock account từ DB, Invalid thông qua token version.   |

#### Acceptance Criteria
| #   | Criteria            | Trạng thái | Ghi chú                                                                       |
| --- | ------------------- | ---------- | ----------------------------------------------------------------------------- |
| 1   | JWT HttpOnly Cookie | ✅          | Cập nhật bảo mật hoàn thiện. Token không exposed qua response thân HTTP tĩnh. |

---

## 📊 SRS COMPLIANCE

### Main Flow
| Bước | SRS Yêu cầu | Implementation                                                  | Match? |
| ---- | ----------- | --------------------------------------------------------------- | ------ |
| 1    | Login Flow  | So sánh password bcrypt, cập nhật last_login_at, tạo Audit Log. | ✅      |

### Alternative Flows
| Flow | SRS Yêu cầu                              | Implementation                                                                            | Match? |
| ---- | ---------------------------------------- | ----------------------------------------------------------------------------------------- | ------ |
| AF1  | Account bị lock do nhập sai MK quá nhiều | Service trả về ApiError.locked('Tài khoản đang bị tạm khóa') nếu `locked_until` chưa qua. | ✅      |
| AF2  | Email chưa verify                        | Service từ chối đăng nhập với lý do chưa xác thực email.                                  | ✅      |

### Exception Flows
| Flow | SRS Yêu cầu                    | Implementation                                                                 | Match? |
| ---- | ------------------------------ | ------------------------------------------------------------------------------ | ------ |
| E1   | Invalidate sessions khi đổi MK | JWT payload mang `token_version`, tăng counter lên +1 để triệt tiêu phiên rác. | ✅      |
| E2   | Reset Password One-Time Token  | Tính trường `used_at` trên `password_reset_tokens`, dùng Hash 256.             | ✅      |

---

## ✅ ƯU ĐIỂM
1. Tái cấu trúc Session theo Token Version (`token_version`), chặn Bypass thông qua Re-play tokens. (Line: `auth.service.js` 328)
2. One-time reset tokens thông qua Tracking Table (`password_reset_tokens`). (Line: `auth.service.js` 332)
3. Có file test cover độ phủ rộng 100% qua Mock ORM. Cực kỳ uy tín.

## ❌ NHƯỢC ĐIỂM
1. Bỏ sót / Chưa dùng middleware validation cho module Auth. Mặc dù file `validate.js` đã tồn tại, file `auth.routes.js` vẫn không map vào. Gây ra hiện tượng Validation Message thô sơ như "Email và mật khẩu là bắt buộc" trực tiếp ở Controller, thiếu đi trường `field` lỗi chi tiết. (Line: `auth.controller.js` 15-18).
2. ORM Prisma bị dính chặt vào Service. (Line: `auth.service.js` 29). Chưa abstract hóa Database Queries làm cho khó mock cho Database test layer.

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. **[MEDIUM]** Bổ sung Middleware `validate.js` vào Route Auth → Cách sửa: Map function middleware ở `auth.routes.js` tương tự như `user.routes.js` và xóa phần If/Else block check null tại `auth.controller.js`.
2. **[LOW]** Thêm 1 layer Repository trung gian bọc ORM Prisma → Cách sửa: Tạo thư mục `src/repositories` đưa truy vấn Data Flow vào đó.

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. Khối IF/ELSE check input (req.body null, exist) tại các Route API `auth.controller.js` → Chuyển việc này về cho Middleware lo liệu. (Tránh code vi phạm Single Responsibility).

## ⚠️ SAI LỆCH VỚI JIRA / SRS
| Source          | Mô tả sai lệch                              | Mức độ | Đề xuất                                                                    |
| --------------- | ------------------------------------------- | ------ | -------------------------------------------------------------------------- |
| JIRA Story EP04 | Sai lệch về field-level Validation response | 🟡      | Áp dụng `validate.js` để map Error Code chính xác như chuẩn Data Contract. |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt:
```javascript
// file: backend/src/services/auth.service.js, line 292-303
    // 4.5. Kiểm tra token đã được theo dõi trong DB và chưa sử dụng
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const resetTokenRecord = await prisma.password_reset_tokens.findFirst({
      where: {
        user_id: decoded.userId,
        token_hash: tokenHash,
      }
    });

    if (!resetTokenRecord || resetTokenRecord.used_at) {
      throw ApiError.badRequest('Link đặt lại mật khẩu không hợp lệ hoặc đã được sử dụng');
    }
```

### ❌ Code cần sửa:
```javascript
// HIỆN TẠI (auth.controller.js, lines 15-18):
    // Validate: email & password không rỗng
    if (!email || !password) {
      throw ApiError.badRequest('Email và mật khẩu là bắt buộc');
    }

// NÊN SỬA THÀNH:
// (Tại auth.routes.js)
const loginRules = { body: { email: { required: true, type: 'string' }, password: { required: true, type: 'string' } } };
router.post('/login', loginLimiter, validate(loginRules), authController.login);
```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
| #   | Action                                                        | Owner  | Priority | Sprint   |
| --- | ------------------------------------------------------------- | ------ | -------- | -------- |
| 1   | Áp dụng Validation Middleware (`validate.js`) vào module Auth | BE Dev | MEDIUM   | Sprint 1 |
| 2   | Tách Data Queries sang Repository                             | BE Dev | LOW      | Sprint 2 |

---

## 🔄 SO SÁNH VỚI LẦN ĐÁNH GIÁ TRƯỚC

> ⚠️ **CHỈ THÊM SECTION NÀY KHI ĐÂY LÀ LẦN ĐÁNH GIÁ THỨ 2 TRỞ LÊN** (tức là đã tìm thấy file review cũ). Nếu là lần đầu tiên → KHÔNG thêm section này.

### Tổng quan thay đổi
- **Điểm cũ**: 93/100 (ngày 2026-03-08)
- **Điểm mới**: 91/100 (ngày 2026-03-08)
- **Thay đổi**: -2 điểm

### So sánh điểm theo tiêu chí
| Tiêu chí                    | Điểm cũ | Điểm mới | Thay đổi | Ghi chú                                                                                                                                                                                                                       |
| --------------------------- | ------- | -------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Chức năng đúng yêu cầu      | 15/15   | 15/15    | 0        | Giữ vững, chuẩn xác.                                                                                                                                                                                                          |
| API Design                  | 9/10    | 9/10     | 0        | Chưa có Field-level lỗi validation.                                                                                                                                                                                           |
| Architecture & Patterns     | 13/15   | 13/15    | 0        | Vẫn thiếu Repository.                                                                                                                                                                                                         |
| Validation & Error Handling | 12/12   | 10/12    | -2       | Quá trình Review Sâu chỉ ra rằng tuy file `validate.js` có tồn tại, nhưng Route AUTH không hề khai báo Middleware này. Các lỗi bị catch cứng bằng IF trực tiếp ở Controller, dẫn tới thiếu cấu trúc mảng Error JSON chi tiết. |
| Security                    | 12/12   | 12/12    | 0        | Vững.                                                                                                                                                                                                                         |
| Code Quality                | 11/12   | 11/12    | 0        | Tuân thủ tốt.                                                                                                                                                                                                                 |
| Testing                     | 11/12   | 11/12    | 0        | Vẫn giữ 100% covers.                                                                                                                                                                                                          |
| Documentation               | 10/12   | 10/12    | 0        | Ổn định.                                                                                                                                                                                                                      |

### ✅ Nhược điểm ĐÃ KHẮC PHỤC (có trong lần trước, không còn trong lần này)
| #   | Nhược điểm cũ                                 | Trạng thái | Chi tiết khắc phục |
| --- | --------------------------------------------- | ---------- | ------------------ |
| N/A | Lần đánh giá sát nhất đã bao phủ các lỗi lớn. | -          | -                  |

### ⚠️ Nhược điểm VẪN TỒN TẠI (có trong cả lần trước và lần này)
| #   | Nhược điểm                             | Mức độ | Ghi chú                                                                   |
| --- | -------------------------------------- | ------ | ------------------------------------------------------------------------- |
| 1   | Thiếu Abstraction (Repository Pattern) | 🟡      | Chưa phân tách hoàn toàn query thành một layer riêng biệt. Vẫn ở Service. |

### 🆕 Nhược điểm MỚI PHÁT SINH (không có trong lần trước, xuất hiện lần này)
| #   | Nhược điểm mới                      | Mức độ | Ghi chú                                                                                                               |
| --- | ----------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Auth Router không map `validate.js` | 🟡      | Controller phải chịu trách nhiệm code IF-ELSE check rỗng, sai nguyên lý Single-Res & mất cấu trúc Error Array Detail. |

### 💬 Nhận xét tổng quan
> Về tổng quan thì tính năng Login hoàn toàn ở trong trạng thái cực kỳ mạnh mẽ để Release. Tuy nhiên, qua quá trình bóc tách Code từng dòng với bộ quy chuẩn Architecture Deep Dive thì đội ngũ Dev đã không map chung Validator Middleware vào Auth (như họ đã mần với Module Admin Users). Sửa chữa khiếm khuyết này chỉ tốn vài phút nhưng sẽ tiết kiệm kỹ thuật Data Interface cho tương lai rất nhiều. Mức điểm 91/100 vẫn trên mức kỳ vọng ✅ Pass.
