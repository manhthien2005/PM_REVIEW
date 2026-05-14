# Audit: BE-M09 — utils (jwt, rate_limiter, password, email, datetime, age_validator)

**Module:** `health_system/backend/app/utils/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module utils chứa helper primitives dùng chung cho toàn backend: JWT issue + decode, rate limiter in-memory, bcrypt password hashing, SMTP email sender, email HTML templates, age validation, UTC datetime helper. Scope audit = 7 file Python thực (+ `__init__.py` empty). Focus per Phase 1 macro plan: `jwt.py` (algorithm + claims + verify), `rate_limiter.py` (storage + key strategy), `password.py` (cost factor + timing-safe compare) + anti-pattern scan cho plaintext credential / weak hash / eval-exec. Cross-check với BE-M08 `security.py` overlap → file không tồn tại, không có coupling. Phạm vi loại trừ: dependency wiring (BE-M08 `core/dependencies.py`), rate limiter usage tại endpoint (BE-M02 routes/auth.py), consumer side password/email flow (BE-M03 services/auth_service.py + profile_service.py).

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `backend/app/utils/__init__.py` | 0 | Package marker | Empty — no audit surface. |
| `backend/app/utils/jwt.py` | ~110 | `create_access_token`, `create_refresh_token`, `create_email_verification_token`, `create_password_reset_token`, `decode_token` | TTL drift (HS-007 candidate) — `settings.ACCESS_TOKEN_EXPIRE_DAYS` ignored. `iss="healthguard-mobile"` consistent. |
| `backend/app/utils/rate_limiter.py` | ~80 | `RateLimiter` class + 5 module-level singletons (login/register/forgot/change/resend) | In-memory `defaultdict` — multi-worker bypass + restart reset + thread-race (HS-008 candidate). |
| `backend/app/utils/password.py` | ~45 | `hash_password`, `verify_password`, `validate_password_strength` | bcrypt `gensalt()` default cost 12 ✓, `checkpw` timing-safe ✓. Missing 72-byte truncation guard. |
| `backend/app/utils/email_service.py` | ~130 | `EmailService` class method: send verification / reset / password-changed | Class-level settings snapshot tại import-time (cùng anti-pattern HS-006). `starttls` OK. |
| `backend/app/utils/email_templates.py` | ~80 | HTML template builder cho 3 email type | Server-generated input (PIN + URL) → no XSS surface, nhưng không defensive escape. |
| `backend/app/utils/age_validator.py` | ~40 | `validate_age(date_of_birth)` — shared BR validation | Day-based age calc (off-by-one risk khi năm nhuận). |
| `backend/app/utils/datetime_helper.py` | ~10 | `get_current_time()` UTC-aware | Correct. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | HS-007 JWT access TTL hardcoded 30 days bất chấp `settings.ACCESS_TOKEN_EXPIRE_DAYS` — config là dead value. `decode_token` flatten mọi `JWTError` → `None` (lose granularity expiry vs tampering). `age_validator` dùng `days / 365` thay vì year arithmetic → off-by-one tại ranh giới sinh nhật. Rate limiter read-modify-write trên `self._attempts[identifier]` không thread-safe. |
| Readability | 2/3 | Docstring jwt + password đầy đủ Args/Returns. Rate limiter class docstring gọn. Email service có docstring mọi method. Trừ điểm: comment `# Default: 30 days (43200 minutes)` conflate unit, docstring `create_access_token` claim "default: 30 days" khớp hardcode accidental (không expose drift với settings). `RateLimiter` class docstring thiếu mention bounded memory + thread safety assumption. |
| Architecture | 1/3 | `jwt.py` đọc `settings.SECRET_KEY` + `settings.ALGORITHM` đúng pattern, nhưng TTL hardcode thay vì consume `settings.ACCESS_TOKEN_EXPIRE_DAYS` → 4th source-of-truth cho TTL. `email_service.EmailService` class-body snapshot `settings.*` → same import-time anti-pattern như `core/dependencies._INTERNAL_SERVICE_SECRET` (HS-006 reference). Rate limiter 5 module-level singleton `RateLimiter(...)` khởi tạo tại import — không DI-able, test override phải monkey-patch. Không có storage backend abstraction (in-memory only, không pluggable sang Redis). |
| Security | 2/3 | Anti-pattern auto-flag scan PASS: không có plaintext credential, không có weak hash (bcrypt-only), không có `eval/exec`, không có SQL concat, không có SSL disable, không có hardcoded secret. bcrypt `gensalt()` cost factor default = 12 ✓ (NIST/OWASP 2026 recommendation ≥ 10). `bcrypt.checkpw` internally dùng constant-time compare ✓. HS256 với single-backend-issuer-verifier = acceptable. Trừ điểm: HS-007 (TTL drift = silent misconfig hoặc compliance gap), HS-008 (in-memory rate limiter bypass khi multi-worker uvicorn deploy), `hash_password` không guard password length > 72 bytes (bcrypt silently truncate — collision risk với attack prefix variants). |
| Performance | 3/3 | JWT encode/decode pure CPU O(1). bcrypt cost 12 ≈ 150ms/op — intentional security tradeoff (đúng). Rate limiter `O(n)` linear filter với `n ≤ max_attempts=5` → hiệu năng thực tế O(1). Email service dùng `timeout=10` trên SMTP connection, consumer `auth_service.py` wrap bằng `BackgroundTasks` → không block request thread. Không N+1, không blocking sync I/O trong async context. |
| **Total** | **9/15** | Band: **🟠 Needs attention** — không Security=0 override vì không hit anti-pattern auto-flag. |

## Findings

### Correctness

- `backend/app/utils/jwt.py:15-26` — `create_access_token` body: `if expires_delta: expire = now + expires_delta else: expire = now + timedelta(days=30)`. **Config `settings.ACCESS_TOKEN_EXPIRE_DAYS` KHÔNG BAO GIỜ được đọc**. Grep toàn repo backend: `ACCESS_TOKEN_EXPIRE_DAYS` chỉ xuất hiện tại `config.py:25` (định nghĩa) — zero reader. README.md và CI workflow set env var này nhưng runtime không consume. Hệ quả: nếu ops đổi `.env.prod` `ACCESS_TOKEN_EXPIRE_DAYS=1` (hotfix rút ngắn TTL sau security incident), không có effect — token vẫn sống 30 ngày. Declared config ≠ actual behavior = compliance + audit gap. Caller duy nhất trong `services/auth_service.py:368,473` gọi không truyền `expires_delta` → đi branch hardcode. Allocate **HS-007**.
- `backend/app/utils/jwt.py:82-89` — `decode_token` catch `JWTError` flatten thành `return None`. Caller (`core/dependencies.py:35`) không thể phân biệt `ExpiredSignatureError` (user needs refresh) vs `JWTClaimsError` / `JWTError` (tampered / wrong signature). Hiện tại cả 2 trả "Token không hợp lệ" + 401 — UX OK nhưng audit log mất detail. Minor P2, không phải bug runtime.
- `backend/app/utils/rate_limiter.py:19-37` + `:51-66` — `is_rate_limited` và `get_remaining_attempts` đều thực hiện read-modify-write trên `self._attempts[identifier]`:
  1. Đọc `self._attempts[identifier]` (autovivification trong `defaultdict`).
  2. Filter entries trong window.
  3. Write `self._attempts[identifier] = recent` hoặc `self._attempts.pop(identifier)`.
  
  Giữa step 1-3, nếu có request concurrent `record_attempt` append → bị ghi đè / lost update. GIL không bảo vệ multi-step transaction. Thực tế tại endpoint login, `is_rate_limited` gọi trước `record_attempt` là pattern "check-then-act" classic TOCTOU — 2 request đồng thời có thể cùng pass `is_rate_limited` check, cùng `record_attempt`, bypass limit by 1-2 attempts. Under uvicorn single-worker asyncio event loop với handler sync-style (backend này dùng sync `Session`), thread pool workers cũng reproduce. Severity: Low (race window hẹp, bypass margin nhỏ). Không flag bug mới — gộp vào HS-008 context.
- `backend/app/utils/age_validator.py:27-30` — `days_old < 16 * 365` treat 1 year = 365 days, bỏ qua năm nhuận. Edge case thực: user sinh 2008-03-01, check ngày 2024-02-29 (leap year): days_old = 5843 < 5840 → FAIL nhưng user thực đã tròn 16 tuổi 2024-03-01 — chỉ sớm 1 ngày. Minor UX off-by-one, không security impact. P2.
- `backend/app/utils/password.py:8-11` — `bcrypt.hashpw(password.encode(), salt)`. Nếu `password` > 72 bytes, bcrypt **silently truncate**. User đặt mật khẩu 80 ký tự, attacker đoán 72 ký tự đầu + random 8 ký tự cuối → hash khớp. Cổ điển bcrypt pitfall. `validate_password_strength` không enforce max length. P2 defense-in-depth: add `if len(password.encode()) > 72` guard hoặc pre-hash SHA-256 rồi bcrypt (argon2id preferred nếu migrate).
- `backend/app/utils/jwt.py:73` — `decode_token` gọi `jwt.decode(token, key, algorithms=[settings.ALGORITHM])` **không pass `issuer` hoặc `audience` param**. `python-jose` mặc định chỉ verify signature + `exp` + `iat`. Token với `iss="attacker-forged"` vẫn pass decode nếu signature hợp lệ (cần key) — ít rủi ro vì cần cùng HS256 key. Nhưng nếu tương lai cross-repo dùng chung SECRET_KEY pattern → mobile token có thể verify tại repo khác. Sound trong single-issuer pattern hiện tại, nhưng P2: bổ sung `options={"verify_iss": True}, issuer="healthguard-mobile"`.

### Readability

- `backend/app/utils/jwt.py:10-19` — `create_access_token` docstring nêu "Token expiry duration (default: 30 days)" + comment line 22 `# Default: 30 days (43200 minutes)`. Cả 2 đúng với hardcode nhưng accidental match — không expose drift với `settings.ACCESS_TOKEN_EXPIRE_DAYS`. Reader không biết config tồn tại mà không consume. Docstring nên là "default: `settings.ACCESS_TOKEN_EXPIRE_DAYS`" sau fix HS-007.
- `backend/app/utils/jwt.py:23-25` — comment `# Default: 30 days (43200 minutes)` conflate đơn vị (43200 phút = 30 ngày, không phải "30 ngày / 43200 phút"). Minor.
- `backend/app/utils/rate_limiter.py:1-11` — class docstring chỉ 1 dòng `"""In-memory rate limiter for login attempts."""`. Không nêu: (a) không thread-safe, (b) reset khi restart, (c) không multi-worker safe, (d) identifier semantic (IP vs email vs user_id). Reader mới phải đọc caller để suy luận semantics. P1 docstring gap.
- `backend/app/utils/rate_limiter.py:70-76` — 5 module-level singleton (`login_rate_limiter`, `register_rate_limiter`, ...) không có comment giải thích tại sao 5 instance riêng biệt (mỗi flow cần window + max riêng) — câu trả lời trong config số liệu nhưng intent (isolate attack surface between flows) không tài liệu hoá.
- `backend/app/utils/password.py:17-45` — docstring `validate_password_strength` liệt kê đủ 5 rule + Return tuple. Đọc 1 lượt hiểu intent. Message VI consistent. OK.
- `backend/app/utils/password.py:6-15` — `hash_password` + `verify_password` docstring 1 dòng. Đủ cho function trivial nhưng thiếu note về 72-byte truncation + bcrypt cost factor rationale. Minor P2.
- `backend/app/utils/email_service.py:18-22` — class attribute line `SMTP_SERVER = settings.SMTP_SERVER or "smtp.gmail.com"` có fallback inline nhưng không comment "evaluated at class body → import-time snapshot, env change requires restart". Implicit behavior.
- `backend/app/utils/email_service.py:110-127` — `_send_email` logic `if not cls.SENDER_PASSWORD: logger.warning(...); return True` là dev-mode skip. Positive: explicit log + return True (không block test). Nhưng `return True` lied về "sent successfully" — caller thấy True rồi `log_action` success, khó debug khi ops quên set SENDER_PASSWORD ở production. Nên `return False` + tầng cao decide. Minor P2.
- `backend/app/utils/age_validator.py:1-15` — module docstring giải thích rõ WHY (shared giữa register + profile update). Reader hiểu pattern trong 10s. Positive.
- `backend/app/utils/email_templates.py` — 3 function HTML builder với f-string. Không docstring per function. OK cho template — Steam-inspired style intent không carryover vào code comment.

### Architecture

- `backend/app/utils/jwt.py:22-23` — TTL hardcode `timedelta(days=30)` thay vì `timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)`. Kết quả: **4 source-of-truth cho access token TTL**:
  1. `backend/app/utils/jwt.py:23` (hardcode — effective runtime)
  2. `backend/app/core/config.py:25` (env-sourced — never consumed)
  3. `health_system/README.md:96` (documented default)
  4. `health_system/.github/workflows/cd-backend.yml:67` (CI env)
  
  Ops assume #2 drives #1 → false. Governance drift + audit paper trail gap. Fix = consume Settings (P0 HS-007 fix).
- `backend/app/utils/email_service.py:18-22` — `class EmailService:` có class-body attribute `SMTP_SERVER = settings.SMTP_SERVER or ...`. Python evaluate expression tại import-time class creation, không mỗi call. Hệ quả: (a) env set sau worker start không effect, (b) test override qua `monkeypatch.setenv("SMTP_PASSWORD", ...)` phải `importlib.reload(app.utils.email_service)`. Cùng anti-pattern với `core/dependencies._INTERNAL_SERVICE_SECRET` tại HS-006. Fix = chuyển sang `@classmethod` property hoặc đọc `settings.*` inline trong `_send_email`.
- `backend/app/utils/rate_limiter.py:70-76` — 5 module-level singleton `RateLimiter(...)` khởi tạo tại import time:
  - Không DI-able — route handler `api/routes/auth.py` import trực tiếp module singleton.
  - Test: file `tests/test_auth_route_contract.py:31,47` phải `patch("app.api.routes.auth.login_rate_limiter.is_rate_limited")` — awkward mocking.
  - Không pluggable storage backend. Muốn migrate sang Redis, phải rewrite class hoặc thêm adapter layer.
  - State module-level → multi-worker uvicorn deploy, mỗi worker có dict riêng (HS-008 root cause).
  
  Fix = abstract `RateLimiterBackend` interface (Protocol) với `InMemoryBackend` + `RedisBackend` impl, inject qua `Depends(get_rate_limiter(...))`. P1.
- Không có `backend/app/core/security.py` — task brief mention overlap check: file không tồn tại trong repo. Auth/RBAC primitives nằm tại `core/dependencies.py` (BE-M08 scope), không duplicate trong utils. Clean separation: `utils/` = stateless helpers, `core/` = DI entry points. Positive.
- `backend/app/utils/password.py` — 3 function pure + stateless. Không import Settings, không global state. Dễ test, dễ reuse. Positive — đây là pattern đúng cho utility layer.
- `backend/app/utils/datetime_helper.py:1-10` — single function 3 dòng. Warranted extraction vì `get_current_time()` dùng > 50 nơi trong backend (jwt, rate_limiter, services, models default). Central TZ handling → swap sang app-level frozen clock cho test chỉ cần 1 patch point. Positive.
- `backend/app/utils/email_templates.py` — separate từ `email_service.py` — renderer vs transport split. Dễ test template output không cần SMTP mock. Positive.
- `backend/app/utils/age_validator.py:1-7` — module docstring khẳng định reuse rationale. Extract đúng lúc (register + profile update). Positive DRY.

### Security

- **Anti-pattern auto-flag scan:**
  - Plaintext credential storage? **NO** — `hash_password` bcrypt-only.
  - Weak hash (MD5/SHA1)? **NO** — chỉ bcrypt.
  - `eval()` / `exec()` với user input? **NO** — không hiện diện.
  - SQL string concat? **NO** — utils không chạm DB.
  - CORS wildcard? **NO** — scope BE-M01.
  - SSL verify disabled? **NO** — `smtplib.SMTP` dùng stdlib default, `starttls()` gọi không override ctx = default secure context.
  - Hardcoded secret? **NO** — `settings.SECRET_KEY` / `settings.SENDER_PASSWORD` qua env.
  
  **Kết luận: 0 hit → Security=0 override KHÔNG áp dụng.**
- `backend/app/utils/password.py:6-11` — `bcrypt.gensalt()` dùng default cost factor **12** (bcrypt library default kể từ v4.0). Computation ≈ 150-250ms / hash trên CPU hiện đại. Phù hợp khuyến nghị OWASP 2026 (min work factor 10). Positive.
- `backend/app/utils/password.py:12-15` — `bcrypt.checkpw` internally dùng `hmac.compare_digest` → constant-time compare, timing-safe. Không cho phép timing attack trên hash compare. Positive.
- `backend/app/utils/password.py:8-11` — **Missing 72-byte truncation guard**. bcrypt spec giới hạn 72 bytes input; bcrypt library silently truncate. Password > 72 ký tự (unusual nhưng valid với passphrase), hash chỉ cover 72 bytes đầu → attacker biết 72 bytes đầu có thể auth bypass cho variant có suffix khác. Không phải critical vì UI mobile không gợi ý passphrase dài; nhưng hygiene-wise nên `validate_password_strength` enforce max length (ví dụ 64 để an toàn). P2.
- `backend/app/utils/jwt.py:8-34` — `create_access_token`:
  - Algorithm: `settings.ALGORITHM` = `HS256` (symmetric). Acceptable cho single-issuer-verifier pattern (mobile BE issues + verifies). Nếu tương lai model-api hoặc admin BE cần verify mobile JWT, phải migrate sang RS256/ES256 (asymmetric). Không phải vấn đề hiện tại.
  - Claims: `exp` ✓, `iat` ✓, `iss="healthguard-mobile"` ✓. Thiếu `nbf` (not-before), `jti` (unique JWT ID cho blocklist), `aud` (audience). `jti` đáng cân nhắc khi implement refresh rotation (review cũ `PM_REVIEW/REVIEW_MOBILE/AUTH_LOGIN_review_v2.md` đã flag) — P2.
  - Signature: `jwt.encode(..., settings.SECRET_KEY, algorithm=...)` — standard, không có bypass path.
- `backend/app/utils/jwt.py:70-89` — `decode_token`:
  - `jwt.decode(token, key, algorithms=[settings.ALGORITHM])` — explicit algorithms list → chặn algorithm-confusion attack (attacker forge token với `alg=none` không work, `alg=HS256` với RSA public key as HMAC key cũng chặn vì key type consistent).
  - Default verify: signature ✓ + `exp` ✓ + `iat` ✓.
  - **Không verify `iss`** — khuyến nghị P2 add `issuer="healthguard-mobile"`.
  - Catch-all `except JWTError: return None` — lose granularity nhưng không expose detail.
- `backend/app/utils/jwt.py:36-47` + `:49-62` — `create_refresh_token` 90 days, `create_email_verification_token` 24h, `create_password_reset_token` 15 min. TTL tiered hợp lý:
  - Reset token 15 min ✓ (OWASP recommend 5-30 min).
  - Email verify 24h ✓.
  - Refresh 90 days — aggressive nhưng mobile pattern. Không refresh token rotation (flagged ở review cũ, OOS audit này).
- **HS-007 / HS-008 detail:** xem "New bugs" bên dưới.
- `backend/app/utils/rate_limiter.py:70-76` — Key strategy mixed:
  - `login_rate_limiter`: IP-based (`ip_address` từ `request.client.host`).
  - `register_rate_limiter`: IP-based.
  - `forgot_password_rate_limiter`: IP-based.
  - `resend_verification_rate_limiter`: email-based (`f"resend_{payload.email.strip()}"`).
  - `change_password_rate_limiter`: user_id-based (`f"change_pwd_{current_user.id}"`).
  
  Mixed strategy hợp lý per-flow (login + register + forgot pre-auth → IP; resend + change có auth hoặc email context → identity-based). NHƯNG IP-based cho mobile app: tất cả user sau NAT carrier mobile Việt Nam chia sẻ IP → rate limit 5/15min trigger false-positive khi legit traffic cao + bypass khi attacker rotate IP (VPN / tor). Tradeoff documented ở review cũ. Không actionable trong audit này (cần architecture decision Redis + device-id + IP composite key).
- `backend/app/utils/email_service.py:66` + `:83` — deep-link redirect URL build: `f"{settings.BACKEND_URL}/api/v1/mobile/auth/deep-link-redirect?action=verify-email&code={verification_code}&email={to_email}"`. `verification_code` là 6-digit PIN server-generated (safe). `to_email` user-controlled (pass Pydantic EmailStr). RFC 5322 cho phép một số ký tự trong local-part email — nếu lọt vào URL raw → query string corrupt. Nên `urllib.parse.quote_plus(to_email)`. Minor P2.
- `backend/app/utils/email_templates.py` — HTML build với f-string. Input `token` (6-digit PIN, server) + `link` (URL, server) — cả 2 server-generated, không XSS surface. Tuy nhiên defensive coding nên `html.escape()` cho `link` để chống future regression nếu có input chứa quote. P2 hygiene.
- `backend/app/utils/email_service.py:114` — `logger.warning(f"SMTP not configured. Skipping email to {to_email}")` — log recipient email (PII). Steering `40-security-guardrails.md` cấm log PII/PHI raw. Minor — production ops có thể aggregate log; masked form an toàn hơn. P2.

### Performance

- `backend/app/utils/jwt.py` — `jwt.encode/decode` pure CPU HMAC-SHA256. Negligible. O(1) per call.
- `backend/app/utils/password.py:8-15` — `bcrypt.gensalt()` + `bcrypt.hashpw` cost 12 ≈ 150-250ms. **Intentionally slow** — cost factor design là security-vs-perf tradeoff. Acceptable cho register / change-password / login (low QPS, user-facing). Nếu scale > 100 login/s, cost 12 sẽ dominate CPU — cân nhắc offload thread pool (đã có trong FastAPI sync route, OK). Không phải perf concern trong scope hiện tại.
- `backend/app/utils/rate_limiter.py:20-37` — `is_rate_limited`: list comprehension filter trên `self._attempts[identifier]` với `n ≤ max_attempts=5`. O(1) effectively. Prune empty entries mỗi call → dict bounded by unique identifier trong window. Attacker rotate IP có thể inflate dict size, nhưng mỗi entry sống tối đa `window_minutes` → memory bounded. OK.
- `backend/app/utils/email_service.py:104-118` — `smtplib.SMTP(..., timeout=10)` synchronous. Consumer (`auth_service.py:166,211,678,762`) wrap bằng `background_tasks.add_task` — không block request thread. OK pattern.
- `backend/app/utils/datetime_helper.py` — `datetime.now(timezone.utc)` C-extension fast path. OK.
- Không N+1, không blocking I/O trong async context, không unbounded memory, không payload bloat.

## Positive findings

- `backend/app/utils/password.py:8-15` — bcrypt default cost 12 + `checkpw` timing-safe compare — textbook correct primitives. Không reinvent.
- `backend/app/utils/password.py:17-45` — `validate_password_strength` 5 rule (length + upper + lower + digit + special) với VI message specific per violation → UX hướng dẫn user fix. Không dumb "password not strong" generic.
- `backend/app/utils/jwt.py` — 4 token type tiered TTL (access 30d / refresh 90d / email_verify 24h / password_reset 15min) với `type` claim phân biệt. BE-M08 `dependencies.py:37-44` check `type != "refresh"` cho access-only endpoint → defense-in-depth đúng.
- `backend/app/utils/rate_limiter.py:30-37` — prune empty entries logic tránh unbounded dict growth. Mặc dù overall architecture có vấn đề (HS-008), micro-level cleanup đúng.
- `backend/app/utils/age_validator.py:1-7` — module docstring explain reuse rationale (register + profile update share logic để message consistent). Shared-util extract đúng timing, không premature abstraction.
- `backend/app/utils/datetime_helper.py` — 1-function helper cho UTC-aware `datetime.now`. Extract đúng vì dùng >50 nơi trong backend — swap clock cho test = 1 patch point duy nhất.
- `backend/app/utils/email_service.py:104-118` — `with smtplib.SMTP(..., timeout=10) as server:` context manager auto-close + explicit timeout. Không resource leak, không infinite hang khi SMTP server unreachable.
- `backend/app/utils/email_templates.py` — separate renderer từ transport → template render testable không cần SMTP mock. Clean separation.
- BE-M09 scope **không** có `core/security.py` overlap → không có coupling / duplication với BE-M08.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-007 | High | JWT access token TTL hardcoded `timedelta(days=30)` trong `create_access_token`, `settings.ACCESS_TOKEN_EXPIRE_DAYS` không bao giờ được consume → config là dead value, ops không thể rotate TTL qua env var, declared config ≠ runtime behavior | `backend/app/utils/jwt.py:22-23` | Correctness + Security + Architecture |
| HS-008 | Medium | `RateLimiter` in-memory `defaultdict` module-level → (a) multi-worker uvicorn deploy mỗi worker có dict riêng biệt, attacker bypass limit by 5x số workers; (b) container restart reset counter; (c) check-then-act TOCTOU race giữa `is_rate_limited` + `record_attempt` | `backend/app/utils/rate_limiter.py:11-75` | Security + Architecture |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-007**: Consume `settings.ACCESS_TOKEN_EXPIRE_DAYS` trong `create_access_token`. Diff tối thiểu:
  ```python
  # jwt.py:22-23 (current)
  expire = get_current_time() + timedelta(days=30)
  # after fix
  expire = get_current_time() + timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)
  ```
  Đồng bộ verify:
  - Update docstring `create_access_token` "default: `settings.ACCESS_TOKEN_EXPIRE_DAYS` days".
  - Check cross-repo: admin BE (Express) KHÔNG chia sẻ `SECRET_KEY` → mobile token không verify tại admin. Fix standalone OK.
  - Thêm unit test `tests/test_jwt_access_ttl.py`: monkeypatch `settings.ACCESS_TOKEN_EXPIRE_DAYS=1`, assert decoded `exp` within 1 day ± 1 phút.
  - Kết hợp với BE-M08 recommendation review 30 ngày TTL → nếu ADR thống nhất rút xuống 1h, `.env.prod` chỉ cần đổi `ACCESS_TOKEN_EXPIRE_DAYS=0.04` (hours-compatible cần signature đổi sang minutes → decision point).

### P1

- [ ] **HS-008**: Migrate rate limiter sang pluggable backend với Redis default cho production:
  - Tạo `backend/app/utils/rate_limiter_backend.py` với `Protocol` interface: `is_limited(key) -> bool`, `record(key) -> None`, `remaining(key) -> int`, `reset(key) -> None`.
  - `InMemoryBackend` cho dev / test.
  - `RedisBackend` dùng `INCR` + `EXPIRE` pattern (Redis single-cmd atomic, no TOCTOU).
  - Config `RATE_LIMITER_BACKEND=redis|memory` qua Settings (chờ pydantic-settings P1 migration từ BE-M08).
  - Factory `get_rate_limiter_backend()` trả singleton instance, inject qua `Depends(...)` trong routes.
  - Startup health-check: nếu backend=redis và connection fail → log error + fall back memory hoặc crash (tuỳ `ENVIRONMENT`, theo pattern HS-006 fix).
  - Regression test: simulate 2 workers → đảm bảo cross-worker visibility.
  - Phụ thuộc: cần Redis instance sẵn (admin BE HealthGuard đã dùng Redis session? — cross-check cần).
- [ ] Rate limiter class docstring: document thread-safety assumption, storage limitations, identifier semantics per singleton. Reader nên biết in-memory = dev-only từ docstring.
- [ ] Email service `EmailService` class: dời `SMTP_SERVER / SMTP_PORT / SENDER_EMAIL / SENDER_PASSWORD` từ class-body sang `_send_email` body (inline `settings.SMTP_SERVER` đọc mỗi call) hoặc dùng `@classmethod` property pattern. Loại bỏ import-time snapshot. Align với HS-006 pattern fix.
- [ ] `decode_token`: consider phân biệt `ExpiredSignatureError` vs other `JWTError` để caller log audit detail (ví dụ: expiry vs tampering). Wrap với try-except cụ thể, return typed result `(status, payload)` hoặc raise custom exception.
- [ ] `decode_token`: add `issuer="healthguard-mobile"` + `options={"verify_iss": True}` cho defense-in-depth.

### P2

- [ ] `hash_password`: enforce max password length 64 hoặc 72 bytes trước khi bcrypt hash. Add vào `validate_password_strength` rule 6: "Mật khẩu không quá 64 ký tự". Regression test password 80 ký tự → reject.
- [ ] `age_validator`: switch từ `days_old / 365` sang `dateutil.relativedelta.relativedelta(today, dob).years` để không off-by-one năm nhuận. Dep có sẵn không? Check `backend/requirements.txt` — nếu chưa, dùng pure-stdlib: `(today.year - dob.year) - ((today.month, today.day) < (dob.month, dob.day))`.
- [ ] `email_service`: `urllib.parse.quote_plus(to_email)` khi build verification/reset link. Chống RFC 5322 local-part corrupt URL query string.
- [ ] `email_service._send_email:114`: mask recipient email trong log warning (`{email[:2]}***@{domain}`) per steering `40-security-guardrails.md`.
- [ ] `email_service._send_email:111-115`: `return True` khi `SENDER_PASSWORD` empty là dev-mode convention nhưng lied về "sent successfully". Cân nhắc return `EmailResult.skipped` enum hoặc tạo flag `ENVIRONMENT=development` gate thay vì fail-by-missing-config.
- [ ] `email_templates`: `html.escape()` cho `link` input — defense-in-depth chống future regression.
- [ ] `jwt.py`: consider thêm `jti` claim (uuid4) + lưu revocation list tại refresh rotation — P2 scope khi implement refresh token rotation (issue review cũ).
- [ ] `rate_limiter`: comment rationale 5 flow riêng biệt tại module docstring (max/window per flow bảo vệ attack surface cụ thể).

## Out of scope

- `settings.ACCESS_TOKEN_EXPIRE_DAYS` value review (30 days unusual) — BE-M08 core config scope + ADR-level decision (chờ ADR justify hoặc đổi).
- Refresh token rotation — đã flag tại review cũ `PM_REVIEW/REVIEW_MOBILE/AUTH_LOGIN_review_v2.md`, scope BE-M03 services/auth_service.py.
- Rate limiter usage tại endpoint (`api/routes/auth.py:67,135,167,230,293`) — BE-M02 routes scope.
- Consumer side password flow (`services/auth_service.py:328,1028` verify, `:151,895,1011` hash) — BE-M03 services scope.
- Email consumer (`services/auth_service.py:166,211,678,762,962,1051`) + `BackgroundTasks` wiring — BE-M03 services scope.
- `AuditLogRepository.log_action` — BE-M06 repositories scope.
- `settings.SECRET_KEY` generation / rotation policy — BE-M08 core scope + deployment ops (không phải code).
- Pydantic-settings migration cho Settings — BE-M08 core P1 recommendation, sẽ làm cùng batch với HS-006 + HS-007 fix.
- Cross-repo SECRET_KEY sharing (nếu admin BE verify mobile token) — cross-repo / HealthGuard scope, hiện tại không có shared secret.

## Cross-references

- BUGS INDEX:
  - [HS-007](../../../BUGS/INDEX.md) — JWT access TTL drift, `settings.ACCESS_TOKEN_EXPIRE_DAYS` never consumed (new, allocated this audit)
  - [HS-008](../../../BUGS/INDEX.md) — In-memory rate limiter multi-worker bypass + restart reset + TOCTOU race (new, allocated this audit)
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open (BE-M08 scope, reference — cùng anti-pattern import-time env snapshot với `email_service.EmailService` class-body `settings.*` + `rate_limiter` module-level singletons)
  - [HS-005](../../../BUGS/INDEX.md) — CORS wildcard (BE-M01 scope, reference — cùng root cause pydantic-settings chưa migrate)
- ADR INDEX:
  - [ADR-005 — Internal service-to-service authentication strategy](../../../ADR/INDEX.md) — governs internal secret + JWT verify pattern; không trực tiếp impact utils nhưng cùng hệ thống auth boundary.
- Intent drift (reference only — không re-flag):
  - Không khớp drift ID nào trong blacklist (D-012/D-019/D-021/D1/D3).
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — HS-005 CORS + pydantic-settings migration dependency (settings injection prerequisite cho HS-007/HS-008 fix clean).
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — HS-006 `require_internal_service` fail-open + `ACCESS_TOKEN_EXPIRE_DAYS` TTL review (BE-M09 là consumer drift point). Cùng batch pydantic-settings migration.
  - `BE_M02_routes_audit.md` — Task 6, consumer rate limiter tại auth endpoints.
  - `BE_M03_services_audit.md` — Task 9, consumer password + email + JWT tại auth_service + profile_service.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Legacy review (reference only): [`PM_REVIEW/REVIEW_MOBILE/AUTH_LOGIN_review_v2.md`](../../../REVIEW_MOBILE/AUTH_LOGIN_review_v2.md) — pre-dated review flagged rate limiter in-memory + refresh rotation gaps (now formalized HS-008 + OOS refresh rotation).
