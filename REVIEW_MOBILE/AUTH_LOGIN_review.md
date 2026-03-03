# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth Login
- **Module**: AUTH
- **Dự án**: Mobile App (health_system/)
- **Sprint**: Sprint 1
- **Trello Card**: Card 3 — Login (Mobile BE Dev + Mobile FE Dev)
- **UC Reference**: UC001
- **Ngày đánh giá**: 2026-03-03

---

## 🏆 TỔNG ĐIỂM: 62/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Chức năng đúng yêu cầu | 11/15 | Login flow đúng SRS main flow, thiếu forgot/change password |
| API Design | 8/10 | RESTful, đúng endpoint design, response format nhất quán |
| Business Logic | 12/15 | Logic đúng, thiếu `is_verified` check khi login |
| Validation & Error Handling | 9/12 | Validation tốt cả BE lẫn FE, error messages rõ ràng |
| Security | 8/12 | JWT + bcrypt + rate limiting OK; in-memory rate limiter không persist; SECRET_KEY default yếu |
| Code Quality | 8/12 | Clean Architecture ở FE, tách layer rõ; BE thiếu type hints ở response, AuthResponse thiếu `user` field |
| Testing | 2/12 | Chỉ có 1 widget test cơ bản, không có unit test cho backend |
| Documentation | 4/12 | Docstrings đầy đủ ở BE service/utils, thiếu API docs (Swagger), thiếu README cho auth module |

---

## 📂 FILES ĐÁNH GIÁ

| File | Vai trò | Đánh giá tóm tắt |
|------|---------|-------------------|
| `backend/app/services/auth_service.py` | Service Layer (397 LOC) | Logic tốt, audit logging đầy đủ, nhưng thiếu `is_verified` check |
| `backend/app/api/routes/auth.py` | API Routes (134 LOC) | RESTful, rate limiting OK, IP extraction tốt |
| `backend/app/schemas/auth.py` | Pydantic Schemas (37 LOC) | Đầy đủ nhưng `AuthResponse` thiếu `user` field trong schema |
| `backend/app/utils/jwt.py` | JWT Utils (98 LOC) | Đúng spec: `iss="healthguard-mobile"`, access 30d, refresh 90d |
| `backend/app/utils/rate_limiter.py` | Rate Limiter (64 LOC) | Logic đúng 5/15min, nhưng in-memory → mất khi restart |
| `backend/app/utils/password.py` | Password Utils (13 LOC) | bcrypt, đúng SRS |
| `backend/app/repositories/user_repository.py` | Repository Layer (65 LOC) | CRUD + verify_login separation of concerns tốt |
| `backend/app/utils/email_service.py` | Email Service (136 LOC) | SMTP với fallback dev mode, password reset email đã chuẩn bị sẵn |
| `backend/app/core/config.py` | Configuration (24 LOC) | Env-based, nhưng SECRET_KEY default quá yếu |
| `lib/features/auth/screens/login_screen.dart` | Login UI (198 LOC) | UI đầy đủ, gradient, form validation |
| `lib/features/auth/providers/auth_provider.dart` | State Management (149 LOC) | Provider pattern, token storage tích hợp tốt |
| `lib/features/auth/repositories/auth_repository.dart` | API Client (50 LOC) | Error handling tốt, gọn gàng |
| `lib/features/auth/services/token_storage_service.dart` | Secure Storage (32 LOC) | `flutter_secure_storage`, đúng best practice |
| `lib/features/auth/models/auth_response_model.dart` | Response Model (61 LOC) | Parse JSON đầy đủ, UserData class |
| `lib/features/auth/models/user_model.dart` | User Model (12 LOC) | Lightweight, đủ dùng |
| `lib/features/auth/widgets/auth_text_field.dart` | Reusable Widget (67 LOC) | Show/hide password toggle, border style |
| `test/widget_test.dart` | Flutter Test (20 LOC) | Chỉ test app hiển thị LOGIN text |

---

## 📋 TRELLO TASK TRACKING

### Card 3 — Login (Sprint 1)

#### Mobile BE Dev
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/auth/login` — Req: `{email, password}`, Res: `{access_token, refresh_token, token_type, user}` | ⚠️ Partial | Endpoint hoạt động, nhưng response **thiếu `token_type`** field |
| 2 | bcrypt/passlib password verification | ✅ Done | `password.py` dùng `bcrypt` đúng spec |
| 3 | JWT: `iss="healthguard-mobile"`, roles PATIENT/CAREGIVER, expiry 30 days | ✅ Done | `jwt.py` line 30: `iss: "healthguard-mobile"`, line 25: 30 days |
| 4 | Implement refresh token mechanism | ✅ Done | `create_refresh_token()` 90 days, `/auth/refresh` endpoint |
| 5 | Rate limiting: 5 attempts/15min per IP | ✅ Done | `rate_limiter.py`: max_attempts=5, window=15min |
| 6 | Check `is_active` flag, update `last_login_at` | ✅ Done | `auth_service.py` line 153 + line 168 |
| 7 | Log to `audit_logs` | ✅ Done | `AuditLogRepository.log_action()` trên mọi case |
| 8 | Unit tests | ❌ Missing | **Không có unit test nào cho backend auth** |

#### Mobile FE Dev
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | Login screen (Flutter) | ✅ Done | `login_screen.dart` 198 LOC, gradient background |
| 2 | Form validation | ✅ Done | Email regex + empty password check |
| 3 | Call API | ✅ Done | `auth_repository.dart` → `ApiClient.post('/auth/login')` |
| 4 | Store JWT + refresh token (secure storage) | ✅ Done | `flutter_secure_storage` trong `token_storage_service.dart` |
| 5 | Navigate to dashboard | ✅ Done | `Navigator.pushNamedAndRemoveUntil` → dashboard |
| 6 | Error handling | ✅ Done | SnackBar hiển thị error message |
| 7 | Show/hide password | ✅ Done | `auth_text_field.dart` toggle visibility |
| 8 | Loading indicator | ✅ Done | `CircularProgressIndicator` khi `isLoading` |

#### Acceptance Criteria
| # | Criteria | Trạng thái | Ghi chú |
|---|---------|------------|---------|
| 1 | User có thể login bằng email + password | ✅ Pass | Full flow hoạt động |
| 2 | JWT token được trả về đúng format | ⚠️ Partial | Thiếu `token_type: "bearer"` |
| 3 | Rate limiting bảo vệ brute force | ✅ Pass | 5 attempts/15min |
| 4 | Audit log ghi nhận mọi login attempt | ✅ Pass | Cả success, failure, error |
| 5 | Token được lưu an toàn trên device | ✅ Pass | `flutter_secure_storage` |

---

## 📊 SRS COMPLIANCE

### Main Flow (UC001 — Login)
| Bước | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| 1 | User nhập email + password | `login_screen.dart`: 2 `AuthTextField` với validator | ✅ |
| 2 | Hệ thống verify credentials | `auth_service.py:139`: `UserRepository.verify_login()` | ✅ |
| 3 | Check `is_active` flag | `auth_service.py:153`: `if not user.is_active` | ✅ |
| 4 | Generate JWT (iss="healthguard-mobile", 30 days) | `jwt.py:27-31`: đúng iss + 30 days expiry | ✅ |
| 5 | Generate refresh token | `jwt.py:37-58`: 90 days, type="refresh" | ✅ |
| 6 | Update `last_login_at` | `user_repository.py:48-53`: `update_last_login()` | ✅ |
| 7 | Return tokens + user info | `auth_service.py:194-203`: access + refresh + user | ✅ |
| 8 | Log to audit_logs | `auth_service.py:182-192`: `AuditLogRepository.log_action()` | ✅ |

### Alternative Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| AF1 | Email không hợp lệ → thông báo lỗi | `auth_service.py:127-136` + FE validator | ✅ |
| AF2 | Sai password → "Sai email hoặc mật khẩu" | `auth_service.py:141-150` | ✅ |
| AF3 | Account bị khóa → "Tài khoản đã bị khóa" | `auth_service.py:153-165` | ✅ |

### Exception Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| EF1 | Rate limiting: 5 attempts/15min | `routes/auth.py:83-87` + `rate_limiter.py` | ✅ |
| EF2 | Server error → catch Exception | `auth_service.py:207-216` | ✅ |
| EF3 | Network error (FE) → hiển thị thông báo | `auth_repository.dart:12-17` catch | ✅ |

### Non-Functional Requirements
| NFR | SRS Yêu cầu | Implementation | Match? |
|-----|-------------|---------------|--------|
| Security — bcrypt/passlib | Hash password | `password.py`: `bcrypt.hashpw()` | ✅ |
| Security — JWT shared secret | HS256 + SECRET_KEY | `config.py` + `jwt.py` | ⚠️ Default key quá yếu |
| Security — Rate limiting | 5/15min | `rate_limiter.py` in-memory | ⚠️ Không persist qua restart |
| Usability — Large fonts | SRS §5.4 cho elderly | FE chưa tối ưu font size cho elderly | ❌ |
| Audit — Log all attempts | Ghi nhận audit | `AuditLogRepository` mọi case | ✅ |

---

## ✅ ƯU ĐIỂM

1. **Clean Architecture rõ ràng (FE)** — Tách biệt models / providers / repositories / services / screens / widgets theo Clean Architecture, dễ maintain và test (`lib/features/auth/`)
2. **Audit Logging toàn diện (BE)** — Mọi action (login success/failure/error, register, verify_email) đều được log với IP, user_agent, details (`auth_service.py`, tất cả method)
3. **Rate Limiting đúng spec** — 5 attempts/15min per IP, reset khi login thành công, record chỉ khi thất bại (`routes/auth.py:83-99`, `rate_limiter.py`)
4. **JWT Implementation đúng SRS** — `iss="healthguard-mobile"`, access token 30 days, refresh token 90 days, type field phân biệt token (`jwt.py:27-58`)
5. **Secure Token Storage (FE)** — Sử dụng `flutter_secure_storage` thay vì `shared_preferences` để lưu token (`token_storage_service.dart`)
6. **Error handling nhất quán** — Cả BE và FE đều có try-catch, FE hiển thị SnackBar, BE trả về (success, message, data) tuple
7. **Input validation 2 lớp** — Validation ở cả Pydantic schema (BE) và Form widget (FE) (`schemas/auth.py` + `login_screen.dart:129-137`)
8. **Email verification flow** — Register → email verification token → verify endpoint, đúng SRS flow
9. **Password show/hide toggle** — `auth_text_field.dart:48-56` hỗ trợ người dùng lớn tuổi

---

## ❌ NHƯỢC ĐIỂM

1. **Thiếu `is_verified` check khi login** — User chưa xác thực email vẫn có thể login thành công. SRS yêu cầu register → `is_verified=false`, nhưng `auth_service.py:110-216` không kiểm tra flag này
   - File: `auth_service.py`, line 138-205

2. **In-memory Rate Limiter** — `rate_limiter.py` dùng `defaultdict` trong memory → data mất khi server restart, không hoạt động khi scale ra nhiều instance
   - File: `rate_limiter.py`, line 14

3. **AuthResponse schema thiếu `user` field** — Pydantic schema `AuthResponse` không có `user: Optional[UserData]`, nhưng route handler lại truyền `user=UserData(...)`. Điều này có thể gây lỗi serialization hoặc user data bị bỏ qua
   - File: `schemas/auth.py`, line 31-37 vs `routes/auth.py`, line 107

4. **SECRET_KEY default quá yếu** — `"your-secret-key-change-in-production"` → nếu deploy mà quên set env, token có thể bị forge
   - File: `config.py`, line 10

5. **Không có unit tests cho backend** — Zero test files cho auth service, routes, JWT utils, rate limiter
   - File: Không có `tests/` folder trong backend

6. **Response thiếu `token_type`** — SRS Trello yêu cầu response chứa `token_type: "bearer"`, implementation không trả về field này
   - File: `auth_service.py`, line 194-203

7. **Forgot Password / Change Password chưa implement** — Trello Card 5 và Card 6 yêu cầu các endpoint này, `auth_service.py` không có method tương ứng (chỉ có `email_service.py` đã chuẩn bị `send_password_reset_email`)

8. **Register mặc định role `patient`** — `user_repository.py:24` hardcode `role="patient"`, nhưng SRS hỗ trợ cả PATIENT và CAREGIVER self-registration

9. **Font size chưa tối ưu cho elderly** — SRS §5.4 yêu cầu hỗ trợ người cao tuổi (large fonts, high contrast), login screen dùng font 24px cho title nhưng input text dùng default size

---

## 🔧 ĐIỂM CẦN CẢI THIỆN

1. **[HIGH]** Thêm `is_verified` check trong login flow → Sau khi verify credentials và check `is_active`, thêm:
   ```python
   # auth_service.py, after line 165
   if not user.is_verified:
       AuditLogRepository.log_action(...)
       return False, "Vui lòng xác thực email trước khi đăng nhập", None
   ```

2. **[HIGH]** Thêm `user` field vào `AuthResponse` schema:
   ```python
   # schemas/auth.py
   class AuthResponse(BaseModel):
       success: bool
       message: str
       access_token: Optional[str] = None
       refresh_token: Optional[str] = None
       verification_token: Optional[str] = None
       token_type: Optional[str] = None  # Thêm
       user: Optional[UserData] = None    # Thêm
   ```

3. **[HIGH]** Viết unit tests cho backend auth:
   - Test login success/failure/locked account
   - Test rate limiter logic
   - Test JWT creation/decode
   - Test register + email verification flow

4. **[MEDIUM]** Chuyển Rate Limiter sang Redis:
   ```python
   # Thay in-memory dict bằng Redis
   import redis
   class RedisRateLimiter:
       def __init__(self, redis_client, max_attempts=5, window=900):
           ...
   ```

5. **[MEDIUM]** Implement Forgot Password + Change Password (Card 5, Card 6):
   - `POST /api/auth/forgot-password`
   - `POST /api/auth/reset-password`
   - `POST /api/auth/change-password` (require JWT)

6. **[MEDIUM]** Thêm `role` parameter cho Register endpoint để hỗ trợ CAREGIVER:
   ```python
   class RegisterRequest(BaseModel):
       email: str
       full_name: str
       password: str
       role: str = "patient"  # patient | caregiver
   ```

7. **[LOW]** Tăng font size cho elderly-friendly UI:
   ```dart
   // login_screen.dart
   AuthTextField(
     label: 'Email',
     style: TextStyle(fontSize: 18),  // Tăng từ default 14
   )
   ```

8. **[LOW]** Thêm `token_type: "bearer"` vào login response

---

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Default SECRET_KEY** — `config.py:10`: `"your-secret-key-change-in-production"` → Nên raise error nếu SECRET_KEY chưa set thay vì dùng default yếu
   ```python
   SECRET_KEY: str = os.getenv("SECRET_KEY")
   if not SECRET_KEY:
       raise ValueError("SECRET_KEY must be set in environment")
   ```

2. **Leak server error details** — `auth_service.py:108,216`: `f"Lỗi server: {str(e)}"` trả về exception message cho client → risk information disclosure
   ```python
   # Nên trả message generic
   return False, "Đã xảy ra lỗi. Vui lòng thử lại sau.", None
   ```

---

## ⚠️ SAI LỆCH VỚI TRELLO / SRS

| Source | Mô tả sai lệch | Mức độ | Đề xuất |
|--------|----------------|--------|---------|
| Trello Card 3 | Response thiếu `token_type: "bearer"` | 🟡 Medium | Thêm field vào AuthResponse |
| Trello Card 3 | Thiếu unit tests cho BE | 🔴 High | Viết tests trước khi merge |
| Trello Card 5 | Forgot Password chưa implement | 🔴 High | Implement theo SRS §4.6.3 |
| Trello Card 6 | Change Password chưa implement | 🔴 High | Implement theo SRS §4.6.4 |
| SRS §4.6.1 | Login không check `is_verified` | 🔴 High | Thêm check trong auth_service.py |
| SRS §5.3 | Rate limiter in-memory, không persistent | 🟡 Medium | Chuyển sang Redis |
| SRS §5.4 | UI chưa tối ưu font cho elderly | 🟡 Medium | Tăng font size, contrast |
| SRS Req | Register hardcode role=patient, thiếu caregiver | 🟡 Medium | Thêm role parameter |
| SRS Req | AuthResponse Pydantic thiếu `user` field | 🔴 High | Schema không khớp actual response |

---

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt:

```python
# file: backend/app/api/routes/auth.py, line 89-99
# Rate limiting logic: record chỉ khi thất bại, reset khi thành công
# Đây là pattern đúng — tránh count login thành công
if not success:
    login_rate_limiter.record_attempt(ip_address)
else:
    login_rate_limiter.reset(ip_address)
```

```python
# file: backend/app/services/auth_service.py, line 128-136
# Validate email trước khi query DB → tránh unnecessary DB call
email = email.strip()
if not cls.email_pattern.match(email):
    AuditLogRepository.log_action(...)
    return False, "Email không hợp lệ", None
```

```dart
// file: lib/features/auth/services/token_storage_service.dart
// Dùng flutter_secure_storage thay vì SharedPreferences
// → Token được mã hóa bằng Keychain (iOS) / KeyStore (Android)
final FlutterSecureStorage _storage = const FlutterSecureStorage();
```

### ❌ Code cần sửa:

```python
# file: backend/app/schemas/auth.py, line 31-37
# HIỆN TẠI — thiếu user và token_type field:
class AuthResponse(BaseModel):
    success: bool
    message: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    verification_token: Optional[str] = None

# NÊN SỬA THÀNH:
class AuthResponse(BaseModel):
    success: bool
    message: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: Optional[str] = None
    verification_token: Optional[str] = None
    user: Optional[UserData] = None
```

```python
# file: backend/app/services/auth_service.py, line 138-205
# HIỆN TẠI — thiếu is_verified check:
user = UserRepository.verify_login(db, email, password)
if not user:
    return False, "Sai email hoặc mật khẩu", None
if not user.is_active:
    return False, "Tài khoản đã bị khóa", None
# → Thiếu: if not user.is_verified: ...

# NÊN THÊM (sau line 165):
if not user.is_verified:
    AuditLogRepository.log_action(
        db, action="user.login", status="failure",
        user_id=user.id, ip_address=ip_address, user_agent=user_agent,
        details={"email": email, "reason": "Email not verified"},
    )
    return False, "Vui lòng xác thực email trước khi đăng nhập", None
```

```python
# file: backend/app/core/config.py, line 10
# HIỆN TẠI:
SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")

# NÊN SỬA THÀNH:
SECRET_KEY: str = os.getenv("SECRET_KEY", "")
# Và thêm validation:
if not SECRET_KEY:
    import warnings
    warnings.warn("SECRET_KEY not set! Using insecure default for development only.")
    SECRET_KEY = "dev-only-insecure-key-do-not-use-in-production"
```

---

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| # | Action | Owner | Priority | Sprint |
|---|--------|-------|----------|--------|
| 1 | Thêm `is_verified` check trong login flow | Mobile BE Dev | HIGH | S1 (hotfix) |
| 2 | Fix AuthResponse schema: thêm `user` + `token_type` | Mobile BE Dev | HIGH | S1 (hotfix) |
| 3 | Viết unit tests cho auth_service, routes, jwt, rate_limiter | Mobile BE Dev | HIGH | S1 |
| 4 | Implement Forgot Password (Card 5) | Mobile BE Dev | HIGH | S1 |
| 5 | Implement Change Password (Card 6) | Mobile BE Dev | HIGH | S1 |
| 6 | Chuyển rate limiter từ in-memory sang Redis | Mobile BE Dev | MEDIUM | S2 |
| 7 | Thêm role selection cho Register (patient/caregiver) | Mobile BE + FE Dev | MEDIUM | S1 |
| 8 | Tối ưu UI cho elderly (font size, contrast) | Mobile FE Dev | MEDIUM | S2 |
| 9 | Không leak server error message → trả generic message | Mobile BE Dev | MEDIUM | S1 |
| 10 | Bảo vệ SECRET_KEY — raise error nếu chưa set | Mobile BE Dev | LOW | S1 |
