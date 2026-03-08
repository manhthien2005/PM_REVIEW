# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: Auth Register
- **Module**: AUTH
- **Dự án**: Mobile App (health_system/)
- **Sprint**: Sprint 1
- **Trello Card**: Card 2 — Register (Mobile BE Dev + Mobile FE Dev)
- **UC Reference**: UC002
- **Ngày đánh giá**: 2026-03-05

---

## 🏆 TỔNG ĐIỂM: 71/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Chức năng đúng yêu cầu | 13/15 | Register flow đúng, thiếu role selection (PATIENT/CAREGIVER) |
| API Design | 9/10 | RESTful, POST endpoint, response format rõ ràng |
| Business Logic | 13/15 | Logic đúng, email verification flow tốt, thiếu password strength validation |
| Validation & Error Handling | 11/12 | Validation tốt nhưng frontend thiếu full_name length check |
| Security | 10/12 | bcrypt, email verification flow OK; mật khẩu chỉ check length, không check pattern |
| Code Quality | 10/12 | Clean Architecture (FE), audit logging (BE) tốt; backend thiếu docstring |
| Testing | 4/12 | 4 unit tests cho register, nhưng thiếu integration tests + frontend tests |
| Documentation | 1/12 | Không có API docs (Swagger), thiếu README cho register flow |

---

## 📂 FILES ĐÁNH GIÁ

| File | Vai trò | Đánh giá tóm tắt |
|------|---------|-------------------|
| `backend/app/api/routes/auth.py:43-60` | API Routes (18 LOC) | POST /register, response format tốt, không có rate limiting |
| `backend/app/services/auth_service.py:23-110` | Service Layer (87 LOC) | Email validation + duplicate check + user create + token gen tốt |
| `backend/app/schemas/auth.py:5-8` | Pydantic Request Schema (4 LOC) | RegisterRequest đầy đủ nhưng thiếu validation cho role |
| `backend/app/repositories/user_repository.py:13-30` | Repository Layer (18 LOC) | create_user(), hardcode role="patient", không support ngành caregiver |
| `backend/app/utils/email_service.py:5-50` | Email Service (45 LOC) | send_verification_email() tốt, deep link lên app đúng |
| `backend/tests/test_auth_service.py:37-130` | Unit Tests (93 LOC) | 4 test cases cho register (valid, invalid email, short password, duplicate) |
| `lib/features/auth/screens/register_screen.dart:10-200` | Register UI (190 LOC) | Form đầy đủ (email, fullName, password, confirm), validation đầy đủ |
| `lib/features/auth/providers/auth_provider.dart:71-90` | State Management (20 LOC) | Provider pattern, loading state, error message |
| `lib/features/auth/repositories/auth_repository.dart:20-32` | API Client (12 LOC) | HTTP POST /auth/register với error handling |
| `lib/features/auth/models/user_model.dart:1-12` | User Model (12 LOC) | Mapping full_name → full_name (key conversion) |
| `lib/features/auth/models/auth_response_model.dart` | Response Model | Parse verification_token từ response |

---

## 📋 TRELLO TASK TRACKING

### Card 2 — Register (Sprint 1)

#### Mobile BE Dev
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | `POST /api/auth/register` — Req: `{email, full_name, password}`, Res: `{success, message, verification_token}` | ✅ Done | Endpoint hoạt động đúng, response format chuẩn |
| 2 | Validate email format + check duplicate | ✅ Done | Email regex validation, query DB for existing user |
| 3 | Hash password bằng bcrypt | ✅ Done | `password.py`: `bcrypt.hashpw()` |
| 4 | Create user với role="patient" | ✅ Done | Hardcode role, không hỗ trợ caregiver registration |
| 5 | Generate email verification token (24h expiry) | ✅ Done | JWT token với user_id + email, lifetime 24h |
| 6 | Send verification email với deep link đến app | ✅ Done | Email service có template phù hợp |
| 7 | Log to `audit_logs` (success/failure/error) | ✅ Done | Audit log mọi event (register, email sent) |
| 8 | Check password strength (min 6 chars) | ⚠️ Partial | Chỉ check length, không check pattern (uppercase, number, special char) |
| 9 | Unit tests | ✅ Done | 4 test cases (valid, invalid email, short password, duplicate email) |

#### Mobile FE Dev
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | Register screen (Flutter) | ✅ Done | `register_screen.dart` 190 LOC, form fields: email, fullName, password, confirmPassword |
| 2 | Form validation | ✅ Done | Email regex + empty checks + password length checks |
| 3 | Confirm password validation | ✅ Done | Match password field |
| 4 | API call | ✅ Done | `auth_repository.dart` → `ApiClient.post('/auth/register')` |
| 5 | Show loading indicator | ✅ Done | `CircularProgressIndicator` khi `isLoading` |
| 6 | Error handling | ✅ Done | SnackBar hiển thị error message |
| 7 | Navigate to verification screen | ✅ Done | Pass email to verify-email screen |
| 8 | Clear form on success | ✅ Done | Controllers reset, state cleared |

#### Acceptance Criteria
| # | Criteria | Trạng thái | Ghi chú |
|---|---------|------------|---------|
| 1 | User có thể register với email + password hợp lệ | ✅ Pass | Full flow hoạt động |
| 2 | Duplicate email được reject | ✅ Pass | Email validation check |
| 3 | Short password được reject | ✅ Pass | 6 ký tự minimum |
| 4 | Email verification token được tạo | ✅ Pass | JWT token generation |
| 5 | Verification email được gửi | ✅ Pass | EmailService với deep link |
| 6 | Audit log ghi nhận register attempt | ✅ Pass | Tất cả event (success, error) |

---

## 📊 SRS COMPLIANCE (UC002 - Register)

### Main Flow (đăng ký)
| Bước | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| 1 | User nhập email + password + full_name | `register_screen.dart`: 4 fields (email, fullName, password, confirmPassword) | ✅ |
| 2 | FE validate email format + password length | Email regex + field validators | ✅ |
| 3 | BE validate email hợp lệ | `auth_service.py:29-31`: email_pattern regex | ✅ |
| 4 | BE check email không trùng | `auth_service.py:58-60`: get_by_email() query | ✅ |
| 5 | BE validate mật khẩu >= 6 ký tự | `auth_service.py:63-66`: len(password) check | ⚠️ Chỉ có length check |
| 6 | BE tạo user trong DB với role="patient" | `user_repository.py:18-26`: create_user() | ✅ Nhưng hardcode |
| 7 | BE generate email verification token | `auth_service.py:82-85`: create_email_verification_token() | ✅ |
| 8 | BE gửi verification email | `auth_service.py:88-89`: EmailService.send_verification_email() | ✅ |
| 9 | BE trả verification_token cho FE | `routes/auth.py:52-56`: Response {verification_token, ...} | ✅ |
| 10 | FE navigate sang verify-email screen | `register_screen.dart:49-53`: pushReplacementNamed() | ✅ |
| 11 | BE log audit trail | `auth_service.py:91-98`: AuditLogRepository.log_action() | ✅ |

### Alternative Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| AF1 | Email không hợp lệ → error message | `auth_service.py:29-36` | ✅ |
| AF2 | Email đã tồn tại → error message | `auth_service.py:58-65` | ✅ |
| AF3 | Mật khẩu quá ngắn → error message | `auth_service.py:63-70` | ✅ |
| AF4 | Server error → catch Exception | `auth_service.py:107-113`: try-except block | ✅ |

### Non-Functional Requirements
| NFR | SRS Yêu cầu | Implementation | Match? |
|-----|-------------|---------------|--------|
| Security — bcrypt hashing | Hash password | `password.py`: bcrypt.hashpw() | ✅ |
| Security — Email verification | 24h expiry token | `jwt.py`: 24 hours lifetime | ✅ |
| Audit — Log all attempts | Ghi nhận audit | `AuditLogRepository` mọi case | ✅ |
| Usability — Large fonts | SRS §5.4 cho elderly | FE chưa tối ưu font size | ❌ |

---

## ✅ ƯU ĐIỂM

1. **Email Verification Flow tốt** — Tạo JWT token 24h, send email với deep link, app trigger verify endpoint `(/auth/verify-email)` (`email_service.py` + `auth_service.py`)

2. **Clean Architecture rõ ràng (FE)** — Tách models / providers / repositories / screens / widgets, dễ test và maintain

3. **Audit Logging toàn diện (BE)** — Log mọi event: register success/failure/error với email, IP, user_agent (`auth_service.py`)

4. **Email Validation 2 lớp** — Regex ở FE (form validator) và BE (auth_service.py:29-31 pydantic schema)

5. **User Experience tốt** — Confirm password validation, loading indicator, error SnackBar, navigation rõ ràng

6. **Duplicate Email Prevention** — Query `users` table, reject nếu email tồn tại (`user_repository.py:9`)

7. **Secure Token Storage** — Verification token gửi sang FE, FE lưu và dùng để verify email (security pattern tốt)

8. **Minimal Boilerplate** — register_screen.dart clean, utils extracted, not repetitive code

---

## ❌ NHƯỢC ĐIỂM

1. **Thiếu Role Selection** — Register hardcode `role="patient"`, nhưng SRS hỗ trợ PATIENT + CAREGIVER self-registration
   - User không thể chọn role khi register → không thể register as CAREGIVER
   - File: `user_repository.py:22`, `register_screen.dart`
   - **Impact**: MOD (Medium) — Caregiver có thể register as patient rồi contact admin để change role

2. **Mật khẩu chỉ check length, không check pattern** — Không validate uppercase/number/special char
   - Backend: `auth_service.py:64` chỉ `len(password) < 6`
   - Yêu cầu strong password nhưng accept "aaaaaa", "111111"
   - **Impact**: LOW-MED (Low-Medium) — bcrypt hash đã giúp security, nhưng weak password dễ bị brute force
   
3. **Frontend thiếu full_name length validation** — register_screen.dart có `input.length < 2` check, nhưng không check max length
   - Schema Backend yêu cầu max 100 chars, FE chưa enforce
   - **Impact**: LOW — Backend sẽ reject nếu > 100

4. **Không có Rate Limiting trên Register endpoint** — Có rate limiting cho login (5/15min), nhưng register không
   - Attacker có thể brute force email addresses bằng register requests
   - File: `routes/auth.py:43-60` không check rate limit
   - **Impact**: MED (Medium) — OWASP Brute Force vulnerability

5. **Response thiếu `user` field trong AuthResponse** — Pydantic schema có field `user: Optional[UserData]`, nhưng route không trả về
   - register endpoint (routes/auth.py:52-56) chỉ trả `{success, message, verification_token}`
   - File: Schema supports, nhưng implementation thiếu
   - **Impact**: LOW — FE không cần user data lúc register (chưa verify email), nhưng inconsistent với Login

6. **Không có confirmation email retry logic** — Nếu email gửi fail, không có fallback
   - EmailService return boolean, nhưng auth_service không check và retry
   - File: `auth_service.py:88-89`
   - **Impact**: LOW

7. **Password confirmation không được lưu ở BE** — FE validate, nhưng BE không biết user confirmed mật khẩu
   - User có thể bypass FE validation bằng API call với typo password
   - **Impact**: MED — Better to re-confirm password (ask user to re-enter khi verify email)

8. **Không có Anti-Spam validation (email domain check)** — Accept bất kỳ domain nào
   - RegEx chỉ check format `^[^@]+@[^@]+\.[^@]+$`, không reject disposable emails
   - **Impact**: LOW

9. **Default `is_verified=False` OK, nhưng FE không clear indication** — User tidak biết email chưa verify
   - register_screen navigate sang verify-email screen, OK nhưng message không rõ
   - **Impact**: LOW — UX enhancement

10. **Thiếu Full-Name Required Validation** — Backend không explicit check full_name != ""
    - `user_repository.py:25`: `full_name or email.split("@")[0]` — fallback to email prefix nếu empty
    - **Impact**: LOW — fallback logic hợp lý nhưng UX không rõ

---

## 🔧 ĐIỂM CẦN CẢI THIỆN

### HIGH Priority

1. **[HIGH]** Thêm Rate Limiting cho Register endpoint (prevent email enumeration/brute force):
   ```python
   # routes/auth.py, thêm trước @router.post("/register")
   register_rate_limiter = RateLimiter(max_attempts=5, window=3600)  # 5 attempts per hour
   
   @router.post("/register", response_model=AuthResponse)
   def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
       ip_address = get_client_ip(request)
       
       if register_rate_limiter.is_rate_limited(ip_address):
           raise HTTPException(
               status_code=status.HTTP_429_TOO_MANY_REQUESTS,
               detail="Quá nhiều yêu cầu đăng ký. Vui lòng thử lại sau 1 giờ.",
           )
       # ... existing code ...
       register_rate_limiter.record_attempt(ip_address)
   ```

2. **[HIGH]** Hỗ trợ Role Selection (PATIENT / CAREGIVER) trong Register:
   ```python
   # schemas/auth.py
   class RegisterRequest(BaseModel):
       email: str = Field(min_length=5, max_length=120)
       full_name: str = Field(min_length=2, max_length=100)
       password: str = Field(min_length=6, max_length=64)
       role: str = Field(default="patient")  # patient | caregiver
       
       @field_validator("role")
       @classmethod
       def validate_role(cls, v: str) -> str:
           if v not in ["patient", "caregiver"]:
               raise ValueError("Role must be 'patient' or 'caregiver'")
           return v
   ```
   
   ```dart
   // register_screen.dart — Thêm Dropdown role selection
   DropdownButton<String>(
     value: selectedRole,
     items: ['patient', 'caregiver'].map((role) => 
       DropdownMenuItem(value: role, child: Text(role))
     ).toList(),
     onChanged: (value) => setState(() => selectedRole = value ?? 'patient'),
   )
   ```

3. **[HIGH]** Implement Password Strength Validation (uppercase + number + special char):
   ```python
   # utils/password.py
   import re
   
   def validate_password_strength(password: str) -> tuple[bool, str]:
       """
       Validate password meets requirements:
       - Min 8 characters
       - At least 1 uppercase letter
       - At least 1 lowercase letter
       - At least 1 digit
       - At least 1 special character
       """
       if len(password) < 8:
           return False, "Mật khẩu phải có ít nhất 8 ký tự"
       if not re.search(r"[A-Z]", password):
           return False, "Mật khẩu phải chứa ít nhất 1 ký tự in hoa"
       if not re.search(r"[a-z]", password):
           return False, "Mật khẩu phải chứa ít nhất 1 ký tự in thường"
       if not re.search(r"\d", password):
           return False, "Mật khẩu phải chứa ít nhất 1 chữ số"
       if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
           return False, "Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt"
       return True, "Mật khẩu mạnh"
   
   # auth_service.py — Sử dụng trong register()
   is_strong, strength_message = validate_password_strength(password)
   if not is_strong:
       AuditLogRepository.log_action(...)
       return False, strength_message, None
   ```

### MEDIUM Priority

4. **[MEDIUM]** Thêm `user` field vào Register response (consistency với Login):
   ```python
   # routes/auth.py
   if success and token_data:
       # Create UserData từ user object
       user_obj = UserRepository.get_by_email(db, payload.email)
       user_data = UserData(
           user_id=user_obj.id,
           email=user_obj.email,
           full_name=user_obj.full_name,
           role=user_obj.role
       )
       return AuthResponse(
           success=True,
           message=message,
           verification_token=token_data.get("verification_token"),
           user=user_data  # Thêm field này
       )
   ```

5. **[MEDIUM]** Thêm Email Retry Logic trong Registration:
   ```python
   # auth_service.py
   max_retries = 3
   email_sent = False
   for attempt in range(max_retries):
       email_sent = EmailService.send_verification_email(email, verification_token)
       if email_sent:
           break
       if attempt < max_retries - 1:
           import time
           time.sleep(2 ** attempt)  # Exponential backoff
   
   if not email_sent:
       return False, "Không thể gửi email xác thực. Vui lòng thử lại sau.", None
   ```

6. **[MEDIUM]** Viết Frontend Unit Tests cho Register:
   ```dart
   // test/features/auth/providers/auth_provider_test.dart
   void main() {
     group('AuthProvider.register', () {
       test('successful registration returns true', () async {
         // Mock repository
         final mockRepository = MockAuthRepository();
         // ...
       });
       
       test('invalid email returns false', () async {
         // ...
       });
       
       test('password mismatch shows error', () async {
         // ...
       });
     });
   }
   ```

### LOW Priority

7. **[LOW]** Thêm Full-Name Max Length Validation trên FE:
   ```dart
   // register_screen.dart
   validator: (value) {
     final input = value?.trim() ?? '';
     if (input.isEmpty) return 'Vui lòng nhập họ tên';
     if (input.length < 2) {
       return 'Họ tên phải có ít nhất 2 ký tự';
     }
     if (input.length > 100) {  // Thêm check này
       return 'Họ tên không thể vượt quá 100 ký tự';
     }
     return null;
   },
   ```

8. **[LOW]** Tăng Font Size cho elderly-friendly UI:
   ```dart
   // register_screen.dart
   AuthTextField(
     label: 'Email',
     style: TextStyle(fontSize: 18),  // Tăng từ 14
   )
   ```

9. **[LOW]** Check Disposable Email Domains:
   ```python
   # utils/email_service.py
   DISPOSABLE_DOMAINS = ['tempmail.com', 'guerrillamail.com', '10minutemail.com', ...]
   
   def is_disposable_email(email: str) -> bool:
       domain = email.split('@')[1].lower()
       return domain in DISPOSABLE_DOMAINS
   ```

---

## 🗑️ ĐIỂM CẦN LOẠI BỎ

1. **Leak Server Error Message** — `auth_service.py:112`: `f"Lỗi server: {str(e)}"` trả cho client
   ```python
   # Nên sửa thành:
   logger.error(f"Register error for {email}: {str(e)}")
   return False, "Đã xảy ra lỗi. Vui lòng thử lại sau.", None
   ```

2. **Hardcode Role = Patient** — Should allow role selection (see HIGH priority #2)

---

## ⚠️ SAI LỆCH VỚI TRELLO / SRS

| Source | Mô tả sai lệch | Mức độ | Đề xuất |
|--------|----------------|--------|---------|
| Trello Card 2 | Register không support role selection (CAREGIVER) | 🟡 Medium | Thêm role parameter vào request |
| Trello Card 2 | Không có rate limiting (prevent brute force) | 🔴 High | Implement rate limiter (5/hour) |
| SRS §5.3 | Mật khẩu không check pattern strength | 🟡 Medium | Require uppercase + number + special char |
| SRS §5.4 | UI chưa optimize cho elderly | 🟡 Medium | Tăng font size, nút lớn hơn |
| Implementation | Leak error details to client | 🔴 High | Gửi generic error message |
| API Response | AuthResponse thiếu `user` field | 🟡 Medium | Add user data to response |

---

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt:

```python
# file: backend/app/services/auth_service.py, line 29-36
# Email validation trước query DB → efficient
email = email.strip()
if not cls.email_pattern.match(email):
    AuditLogRepository.log_action(...)
    return False, "Email không hợp lệ", None
```

```dart
// file: lib/features/auth/screens/register_screen.dart, line 127-137
// Confirm password validation
validator: (value) {
    if (value != passwordController.text) {
        return 'Mật khẩu xác nhận không khớp';
    }
    return null;
}
```

```python
# file: backend/app/services/auth_service.py, line 82-89
# Email verification token + send email
verification_token = create_email_verification_token(...)
email_sent = EmailService.send_verification_email(email, verification_token)
AuditLogRepository.log_action(..., details={"email_sent": email_sent})
```

### ❌ Code cần sửa:

```python
# file: backend/app/repositories/user_repository.py, line 22
# HIỆN TẠI — hardcode role:
role="patient",

# NÊN SỬA THÀNH:
role=role,  # Accept parameter từ auth_service
```

```python
# file: backend/app/services/auth_service.py, line 64
# HIỆN TẠI — chỉ check length:
if len(password) < 6:
    return False, "Mật khẩu phải có ít nhất 6 ký tự", None

# NÊN SỬA THÀNH:
is_strong, strength_msg = validate_password_strength(password)
if not is_strong:
    return False, strength_msg, None
```

```python
# file: backend/app/api/routes/auth.py, line 43
# HIỆN TẠI — không có rate limiting:
@router.post("/register", response_model=AuthResponse)
def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    ...

# NÊN SỬA THÀNH:
@router.post("/register", response_model=AuthResponse)
def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    ip_address = get_client_ip(request)
    if register_rate_limiter.is_rate_limited(ip_address):
        raise HTTPException(status_code=429, detail="Quá nhiều yêu cầu...")
    ...
    register_rate_limiter.record_attempt(ip_address)
```

---

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG

| # | Action | Owner | Priority | Sprint |
|---|--------|-------|----------|--------|
| 1 | Thêm rate limiting (5 attempts/hour) cho Register endpoint | Mobile BE Dev | HIGH | S1 (hotfix) |
| 2 | Hỗ trợ role selection (patient/caregiver) trong Register | Mobile BE + FE Dev | HIGH | S1 |
| 3 | Implement password strength validation (uppercase + number + special) | Mobile BE Dev | HIGH | S1 |
| 4 | Viết unit tests cho password strength validator | Mobile BE Dev | HIGH | S1 |
| 5 | Viết frontend unit tests cho register screen | Mobile FE Dev | MEDIUM | S1 |
| 6 | Thêm `user` field vào AuthResponse (consistency) | Mobile BE Dev | MEDIUM | S1 |
| 7 | Implement email retry logic (exponential backoff) | Mobile BE Dev | MEDIUM | S2 |
| 8 | Thêm disposable email domain check | Mobile BE Dev | MEDIUM | S2 |
| 9 | Tối ưu UI cho elderly (font size, button size) | Mobile FE Dev | MEDIUM | S2 |
| 10 | Không leak server error → generic message | Mobile BE Dev | MEDIUM | S1 |
| 11 | Viết API Documentation (Swagger) cho Register endpoint | Mobile BE Dev | LOW | DH |

---

## 📈 COMPARISON WITH LOGIN

| Aspect | Login | Register | Note |
|--------|-------|----------|------|
| Input Validation | 2 layers (FE + BE) | 2 layers (FE + BE) | ✅ Consistent |
| Error Messages | Generic + specific | Specific | Register more detailed |
| Rate Limiting | ✅ 5/15min per IP | ❌ MISSING | Need to add |
| Audit Logging | ✅ Full | ✅ Full | ✅ Consistent |
| Token Generation | Access + Refresh | Verification only | Different flows |
| Email Step | No | ✅ Verification required | Expected |
| Password Strength | Only length check | Only length check | ⚠️ Both weak |
| Role in Response | ✅ Included | Only in next step | AF4 inconsistency |

---

## 🎯 CONCLUSION

### Điểm mạnh:
- **Đầu tiên thực hiện**: Register flow hoàn chỉnh từ request → email verification
- **Architecture tốt**: Backend có service layer + repository layer + audit logging
- **User Experience**: Form validation rõ ràng, navigation smooth, error messages helpful
- **Security foundation**: Bcrypt hashing + email verification + audit logging

### Điểm yếu chính cần khắc phục:
1. **Thiếu Rate Limiting** — Vulnerability OWASP, dễ bị enumerate emails
2. **Thiếu Role Selection** — Caregiver không thể tự register
3. **Mật khẩu yếu** — Chỉ check length, không check pattern
4. **Leak error details** — Server exception message expose to client

### Điểm số chi tiết:
- **Chức năng**: 13/15 (thiếu role selection)
- **Security**: 10/12 (weak password + no rate limit)
- **Code Quality**: 10/12 (missing docstring + tests)
- **Testing**: 4/12 (unit tests OK, missing integration + FE tests)

**TỔNG ĐIỂM: 71/100** → Acceptable với điều kiện khắc phục HIGH priority items trong sprint này.

---

## 📞 CONTACT

- **Reviewer**: AI CodeReview Agent
- **Review Date**: 2026-03-05
- **Next Review**: Sau khi implement HIGH priority actions
