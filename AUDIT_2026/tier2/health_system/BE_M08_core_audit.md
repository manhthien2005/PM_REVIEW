# Audit: BE-M08 — core (dependencies, config, alert constants, audience, risk contract)

**Module:** `health_system/backend/app/core/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module core chứa shared primitives cho toàn bộ backend mobile: config settings, dependency injection (auth + ownership + internal service), alert escalation matrix, audience RBAC gate, mobile risk contract versioning. Scope audit = 6 file Python (`__init__.py` empty + 5 file thực). Phạm vi loại trừ: JWT encode/decode primitives (BE-M09 utils/jwt.py), rate limiter (BE-M09 utils/rate_limiter.py), middleware wiring (BE-M01 main bootstrap), per-endpoint usage của `Depends(get_current_user)` / `Depends(require_internal_service)` (BE-M02 routes). Audit focus per Phase 1 macro plan — ADR-005 internal service auth + ADR-015 severity taxonomy.

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `backend/app/core/__init__.py` | 0 | Package marker | Empty — no audit surface. |
| `backend/app/core/alert_constants.py` | ~120 | Alert type IDs, escalation matrix, cooldown window | Liên hệ XR-002 (severity CheckConstraint drift); governed ADR-015. |
| `backend/app/core/audience.py` | ~90 | `AudienceEnum` + `require_clinician_audience` RBAC gate | Phase 5 risk-report detail clinician profile. Fail-closed. |
| `backend/app/core/config.py` | ~40 | Settings (DB URL, signing key, TTL, SMTP, deep link) | Plain class + `os.getenv`, không pydantic-settings. |
| `backend/app/core/dependencies.py` | ~165 | `get_current_user`, `get_optional_current_user`, `get_target_profile_id`, `require_internal_service` | ADR-005 entry point; fail-open khi env unset (HS-006 candidate). |
| `backend/app/core/risk_contract.py` | ~85 | Contract version header + `applies_to_path` route prefix gate | Phase 6 baseline version sync với mobile client. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Happy path đúng. Escalation matrix thiếu key `"high"` (governed XR-002 reference only), internal secret capture tại import-time không hot-reload, signing key validation raise `ValueError` tại class body tạo side-effect khi import. |
| Readability | 3/3 | `audience.py`, `risk_contract.py`, `alert_constants.py` docstring giải thích context + trust boundary + bumping rules — reader không cần đoán. `dependencies.py` VI error messages nhất quán, `WWW-Authenticate` header đúng chuẩn. |
| Architecture | 2/3 | `config.py` dùng plain `os.getenv` + class attributes thay vì pydantic-settings (steering `22-fastapi.md` violation). Cooldown + internal secret đọc env trực tiếp thay vì đi qua `Settings` — 3 source-of-truth khác nhau cho env var. |
| Security | 2/3 | JWT flow đầy đủ (refresh-type reject + `token_version` rotation + `is_active` check), signing key reject empty + placeholder, `audience` RBAC fail-closed. Trừ điểm: `require_internal_service` fail-OPEN khi env var unset (HS-006) + access token TTL 30 ngày dài bất thường. Không hit anti-pattern auto-flag list. |
| Performance | 3/3 | Sync Session consistent với stack backend. Không blocking I/O trong dependency. `get_target_profile_id` 1 relationship query per request OK. Không N+1. |
| **Total** | **12/15** | Band: **🟡 Healthy** — không có Security=0 override vì không hit anti-pattern auto-flag (CORS wildcard / eval / SQL concat / plaintext credential / SSL disabled / hardcoded secret). |

## Findings

### Correctness

- `backend/app/core/alert_constants.py:44-78` — `ESCALATION_MATRIX` chỉ định nghĩa 3 key: `"low"`, `"medium"`, `"critical"`. Key `"high"` bị thiếu. Nếu upstream service (ví dụ risk_inference) từng emit `risk_level="high"`, `get_escalation_rule` trả `None` → alert bị skip âm thầm. Hiện caller `services/risk_alert_service.py:244` và `api/routes/risk.py:23` đều dùng trực tiếp kết quả model-api, không normalize. Contract giữa 2 vocabulary (`risk_level` domain ∈ {low, medium, critical} vs DB `severity` ∈ {normal, high, critical}) đang drift — thuộc D1 / ADR-015. Reference only, không re-flag (governed by XR-002).
- `backend/app/core/config.py:18-23` — signing key validation chạy tại class body: `raise ValueError` nếu empty hoặc bằng placeholder. Fail-fast là đúng spirit nhưng vị trí ở class body có 2 effect: (a) test collection import `app.core.config` sẽ ImportError nếu dev quên export env var — acceptable; (b) không thể `import` module để introspect settings trong script mà không có env var set — minor inconvenience, nên dùng pydantic-settings với validation tách khỏi import.
- `backend/app/core/dependencies.py:139` — `_INTERNAL_SERVICE_SECRET: str = os.getenv(...)` đọc env TẠI MODULE IMPORT TIME. Nghĩa là: (a) setting env sau khi worker start không có hiệu lực; (b) test override qua `monkeypatch.setenv` PHẢI kết hợp `importlib.reload(app.core.dependencies)` — dễ lộ test flake. Cần dời vào `Settings` class lazy property hoặc hàm getter.
- `backend/app/core/dependencies.py:100-126` — `get_target_profile_id` có early-return `if not x_target_profile_id or x_target_profile_id == current_user.id: return current_user.id`. Điều kiện `not x_target_profile_id` treat `0` như absent. Nếu client gửi `X-Target-Profile-Id: 0` (có thể do Dart null-coalesce `?? 0`), sẽ fall back về `current_user.id` thay vì raise 400. Edge case hiếm, không expose data trái phép (vì fallback về chính owner), nhưng là silent mis-behavior. Suggest: `if x_target_profile_id is None or x_target_profile_id == current_user.id`.
- `backend/app/core/dependencies.py:56-77` — ownership check sequence đúng: `is_active=False → 403` trước `token_version mismatch → 401`. Semantic OK. Integer compare nên không có timing leak risk.
- `backend/app/core/audience.py:62-80` — fail-closed đúng. Patient audience default, clinician đòi role whitelist. Không có drift.

### Readability

- `backend/app/core/alert_constants.py:1-8` — module docstring cite `plans/alert-threshold-architecture-plan.md §4.2` + trust-boundary comment ở DB CHECK constraint. Traceable.
- `backend/app/core/audience.py:1-30` — module docstring là best-in-class trong toàn backend: giải thích WHY query param + dependency thay vì 2 route riêng, nêu plan acceptance criteria, note về future RBAC migration. Reader hiểu design intent trong 30 giây.
- `backend/app/core/risk_contract.py:1-37` — bumping rules (patch / minor / major) tài liệu hoá rõ ràng + checklist khi bump version (update doc + snapshot test + mobile constant). Đây là developer experience tốt cho contract versioning.
- `backend/app/core/dependencies.py:87-98` — docstring `get_current_user` mô tả Args/Returns/Raises đầy đủ. `get_optional_current_user` và `require_internal_service` thiếu docstring — minor gap.
- `backend/app/core/config.py` — thiếu module-level docstring + class-level docstring. 40 LoC nhỏ nên chấp nhận được, nhưng nếu refactor sang pydantic-settings thì nên thêm.
- `backend/app/core/dependencies.py:30-75` — `_resolve_user_from_credentials` có 5 HTTPException branch, mỗi branch có VI message clear + `WWW-Authenticate: Bearer` header đúng semantics HTTP 401. Error surface consistent cho client.

### Architecture

- `backend/app/core/config.py:9-40` — dùng plain class `Settings` với class attributes + `os.getenv`. Vi phạm steering `22-fastapi.md` ("pydantic-settings cho config"). Hệ quả: (a) không có type validation ngoài int cast thủ công cho `SMTP_PORT`, `ACCESS_TOKEN_EXPIRE_DAYS`; (b) không có `BaseSettings` khả năng nested model / env file switching (`.env.dev` vs `.env.prod`); (c) không support list/set/URL type natively (`cors_allowed_origins` cần khi fix HS-005 sẽ buộc tự parse CSV string); (d) `Settings()` là instance module-level singleton — test override cần reload. Refactor P1.
- `backend/app/core/alert_constants.py:95-100` — `RISK_ALERT_COOLDOWN_SECONDS: int = int(os.getenv("RISK_ALERT_COOLDOWN_SECONDS", "300"))` đọc env trực tiếp thay vì đi qua `Settings`. Tương tự `dependencies._INTERNAL_SERVICE_SECRET`. Có 3 source-of-truth cho env var trong backend:
  1. `core/config.py::settings.*`
  2. `core/dependencies.py::_INTERNAL_SERVICE_SECRET`
  3. `core/alert_constants.py::RISK_ALERT_COOLDOWN_SECONDS`
  
  Drift risk: nếu team đổi sang pydantic-settings, dễ sót 2 điểm này. Centralize trong Settings P1.
- `backend/app/core/dependencies.py:100-126` — `get_target_profile_id` `from app.models.relationship_model import UserRelationship` inline import. Thường là workaround circular import. Acceptable nếu circular import thực sự tồn tại (models ↔ dependencies), nhưng không có comment giải thích. Nếu không phải circular, move lên top-level.
- `backend/app/core/dependencies.py:104-111` — inline SQLAlchemy query trong dependency function: `db.query(UserRelationship).filter(...).first()`. Đang trộn data access vào dependency layer. Idiomatic pattern nên gọi qua `RelationshipRepository.get_caregiver_view_relationship(db, caregiver_id, patient_id)` — consistent với pattern `UserRepository.get_by_id` dùng ngay phía trên (line 54). Minor coupling leak — P2.
- `backend/app/core/audience.py:57-61` — `CLINICIAN_ROLES = frozenset({"clinician", "admin"})` hardcoded inline. Chấp nhận cho small allow-list; plan §I.1 open question đã note tương lai có thể migrate sang full RBAC table. OK.
- `backend/app/core/risk_contract.py:53-65` — `RISK_CONTRACT_ROUTE_PREFIXES` chứa cả bản có prefix `/api/v1/` và không prefix `/mobile/...`. Coupling với D-019 `root_path` hack (tier1 topology drift) — governed ADR-004. Reference only, sẽ drop sau khi ADR-004 Phase 4 execute.

### Security

- **KHÔNG hit anti-pattern auto-flag list**: không có CORS wildcard (scope `main.py`), không có `eval/exec`, không có SQL string concat, không có plaintext credential, không có SSL verify disabled, không có hardcoded secret (signing key đọc từ env + reject empty/placeholder).
- `backend/app/core/config.py:18-23` — signing key startup validation REJECT empty string + REJECT placeholder string + suggest `openssl rand -hex 32` trong error message. Đây là security hygiene tốt — fail-fast tại startup thay vì deploy với default secret. Positive.
- `backend/app/core/dependencies.py:150-162` — `require_internal_service` có 2 check: (a) `x_internal_service == "iot-simulator"` (header match), (b) `if _INTERNAL_SERVICE_SECRET and x_internal_secret != _INTERNAL_SERVICE_SECRET`. **Logic bug fail-OPEN**: nếu `INTERNAL_SERVICE_SECRET` env var không set, biến module-level = `""`, condition `if _INTERNAL_SERVICE_SECRET and ...` → `False` → secret check bị SKIP hoàn toàn. Runtime còn lại duy nhất là header-match trivially spoofable bằng `curl -H "X-Internal-Service: iot-simulator"`.
  - Logger warning tại line 141-146 chỉ emit 1 lần tại import-time, dễ miss trong production log aggregator. Không có startup crash hoặc health-check fail.
  - ADR-005 (Accepted) mandate `X-Internal-Secret` là mandatory cho internal service auth. Impl hiện tại là "best-effort" không align với ADR intent.
  - Correct behavior theo ADR-005: nếu `ENV=production` và secret unset → crash startup; nếu `ENV=development` → allow fail-open với loud warning.
  - Impact: kết hợp với HS-004 (telemetry endpoints hiện chưa có guard này), khi HS-004 được fix bằng cách add `Depends(require_internal_service)` mà env var không set ở production deploy → guard thành no-op → bug chỉ fix được UX không fix được security boundary.
  - Scope bug: guard itself (HS-006), khác HS-004 (routes missing guard) + IS-002 (sleep service missing outbound headers).
  - Allocate **HS-006** (xem New bugs).
- `backend/app/core/config.py:27` — `ACCESS_TOKEN_EXPIRE_DAYS = 30` (30 ngày, 43200 phút). Mobile app pattern có thể là "access token dài + refresh token dài hơn", nhưng 30 ngày access token là unusual. OWASP / standard guidance thường đề xuất access TTL ngắn (15 phút – 1 giờ) + refresh TTL dài (7–90 ngày). Impact: nếu token leak (log, debug capture, malware trên device), window of exposure = 30 ngày thay vì phút. `utils/jwt.py:create_refresh_token` đã có 90-day refresh — access không cần dài vậy. Verify với UC-auth (BE-M09 scope) xem đây là ADR hay accident. P1 recommendation.
- `backend/app/core/dependencies.py:59-73` — `token_version` rotation check rất tốt: khi user đổi password / logout-all, `User.token_version` tăng → mọi access token cũ bị reject. Sound.
- `backend/app/core/dependencies.py:37-44` — reject refresh token khi dùng cho non-refresh endpoint (`if payload.get("type") == "refresh"`). Sound.
- `backend/app/core/audience.py:82-91` — clinician gate raise 403 tại dependency boundary, trước khi handler chạy. Raw SHAP data không leak tới patient client. Trust boundary đúng như plan.
- `backend/app/core/risk_contract.py` — chỉ inject response header, không có security surface.

### Performance

- `backend/app/core/dependencies.py` — tất cả dependency function đều sync + I/O-bound (DB query). Consistent với stack sync `Session` của backend mobile (không phải async). Không có mismatch gây block event loop.
- `backend/app/core/dependencies.py:55` — `UserRepository.get_by_id(db, user_id)` gọi 1 query per authenticated request. Đây là cost cố định cho mọi route có `Depends(get_current_user)`. Acceptable cho mobile traffic scale; khi scale lên 100+ QPS có thể cân nhắc thêm identity cache (Redis TTL 30s) — không phải P0.
- `backend/app/core/dependencies.py:104-111` — `get_target_profile_id` thêm 1 query khi `X-Target-Profile-Id` khác owner. Chỉ fire khi family view → low frequency. OK.
- `backend/app/core/alert_constants.py:44-78` — `ESCALATION_MATRIX` là module-level dict constant → O(1) lookup. OK.
- `backend/app/core/risk_contract.py:84-91` — `applies_to_path` dùng `str.startswith(tuple)` — O(k) với k = số prefix (6). Middleware hot path — cost negligible.
- Không có N+1, không có blocking sync I/O trong async context, không có caching concern.

## Positive findings

- `backend/app/core/config.py:18-23` — signing key startup validation reject empty + reject placeholder string + suggest cách generate key. Đây là security-first pattern nên template hoá cho các settings khác (internal service secret nên được validate tương tự khi env=production).
- `backend/app/core/audience.py:1-30` — module docstring giải thích trust boundary + plan acceptance criteria + future RBAC migration path. Reader mới vào không cần đọc plan doc vẫn hiểu intent.
- `backend/app/core/risk_contract.py:23-40` — bumping rules (patch / minor / major) documented với checklist (update baseline doc + snapshot tests + mobile constant). Versioning discipline để cross-repo contract không drift.
- `backend/app/core/dependencies.py:59-73` — `token_version` rotation check là defense-in-depth tốt. Password change / logout-all invalidate mọi access token cũ mà không cần blocklist.
- `backend/app/core/dependencies.py:141-146` — mặc dù secret-check fail-open là bug, logger warning có message rõ ràng chỉ action để fix (set env var). Giúp ops debug nhanh khi phát hiện.
- `backend/app/core/alert_constants.py:58-67` — `EscalationRule` dùng `@dataclass(frozen=True)` → immutable config. Không thể accidentally mutate ở service layer.
- `backend/app/core/audience.py:62-80` — fail-closed default (`patient`) + 403 khi role không đủ. Không có bypass branch.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-006 | High | `require_internal_service` fail-OPEN khi `INTERNAL_SERVICE_SECRET` env unset — chỉ còn header match trivially spoofable; không align ADR-005 mandate; khi combine với HS-004 fix sẽ thành no-op guard | `backend/app/core/dependencies.py:139-162` | Security |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-006**: Chuyển `require_internal_service` sang fail-closed trong production. Đề xuất:
  - Thêm `ENVIRONMENT: str = "development"` vào `Settings`.
  - Startup check: nếu `ENVIRONMENT == "production"` và `INTERNAL_SERVICE_SECRET` rỗng → `raise ValueError` (tương tự signing key pattern tại `config.py:18-23`).
  - Giữ fail-open với warning ở `development` để dev local không cần set env.
  - Dời `_INTERNAL_SERVICE_SECRET` capture từ module-level sang `Settings.internal_service_secret` để hot-reload + test override dễ dàng.
  - Đồng thời update `.env.dev.example` + `.env.prod` template + CI/CD deploy checklist để secret được set.
  - Cross-check với IS-002 (IoT sim thiếu outbound headers) — fix phải đồng bộ giữa 2 side.

### P1

- [ ] Migrate `core/config.py` sang `pydantic-settings` (BaseSettings):
  - Type coercion tự động cho int/list/URL → bỏ `int(os.getenv(...))` manual cast.
  - Support nested model cho email/SMTP config.
  - Support `.env` file switching qua `model_config = SettingsConfigDict(env_file=...)`.
  - Tạo chỗ cho `cors_allowed_origins: list[str]` (HS-005 P0 fix cần), `internal_service_secret` (HS-006 fix cần), `environment: Literal["development", "staging", "production"]`.
  - Align với steering `22-fastapi.md` convention.
- [ ] Centralize env reads: dời `RISK_ALERT_COOLDOWN_SECONDS` (alert_constants.py:95) + `_INTERNAL_SERVICE_SECRET` (dependencies.py:139) vào `Settings`. Giữ 1 source-of-truth cho env var.
- [ ] Verify `ACCESS_TOKEN_EXPIRE_DAYS = 30` với UC-auth + ADR. Nếu không có ADR justify, đề xuất ADR mới: "Mobile access token TTL = 1 hour (backed by 90-day refresh)". Nếu đã có justification (offline-first mobile UX), document ADR để future dev không question. Scope ADR, không phải code fix.
- [ ] Bổ sung docstring cho `get_optional_current_user` + `require_internal_service` + `Settings` class. Tỉnh nhỏ nhưng đồng bộ với pattern của `get_current_user`.

### P2

- [ ] Refactor `get_target_profile_id` inline SQLAlchemy query → gọi qua `RelationshipRepository.get_caregiver_view_relationship(db, caregiver_id, patient_id)` method. Match pattern `UserRepository.get_by_id` cùng file. Thêm unit test cho ownership check.
- [ ] Fix edge case `get_target_profile_id`: đổi `if not x_target_profile_id` → `if x_target_profile_id is None` để không silently treat `0` như absent header.
- [ ] Xoá prefix không-root_path khỏi `RISK_CONTRACT_ROUTE_PREFIXES` (`/mobile/analysis/...`, `/mobile/metrics/...`) sau khi ADR-004 Phase 4 execute xong — liên hệ BE-M01 hành động gỡ `root_path` hack.
- [ ] Giải quyết inline import `from app.models.relationship_model import UserRelationship` (dependencies.py:103): verify có thật circular import không — nếu có, document comment; nếu không, dời lên top-level.

## Out of scope

- JWT `create_access_token` / `create_refresh_token` / `decode_token` / password reset + email verification token primitives — BE-M09 utils/jwt.py.
- Rate limiter cho auth endpoint → BE-M09 utils/rate_limiter.py.
- Actual usage của `Depends(require_internal_service)` trong telemetry routes + HS-004 fix plan — BE-M02 routes.
- `cors_allowed_origins` concrete list cho HS-005 (fix chính thực thi ở main.py + settings injection) — BE-M01 + section settings này chỉ chuẩn bị chỗ chứa.
- `UserRelationship` model + repository — BE-M04 models + BE-M06 repositories.
- `RiskScore` / `RiskExplanation` model consumed bởi `alert_constants` caller — BE-M04 models.
- Escalation matrix downstream execution (cooldown Redis, push dispatch) — BE-M03 services (risk_alert_service, push_notification_service).
- D1 severity vocabulary normalization logic — BE-M03 services (risk_inference_service output format), governed ADR-015 + tracked XR-002, reference only.

## Cross-references

- BUGS INDEX:
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open when `INTERNAL_SERVICE_SECRET` unset (new, allocated this audit)
  - [HS-004](../../../BUGS/HS-004-telemetry-sleep-endpoints-no-auth.md) — telemetry endpoints missing `Depends(require_internal_service)` (BE-M02 scope, reference — combo với HS-006 tạo no-op guard risk)
  - [HS-005](../../../BUGS/INDEX.md) — CORS wildcard (BE-M01 scope, reference — sẽ cần settings chỗ chứa `cors_allowed_origins` tại P1 pydantic-settings migration)
  - [XR-002](../../../BUGS/XR-002-be-sqlalchemy-severity-checkconstraint-drift.md) — SQLAlchemy severity CheckConstraint drift (liên hệ `ESCALATION_MATRIX` thiếu key `"high"`, governed ADR-015 — reference only)
  - [IS-002](../../../BUGS/IS-002-sleep-service-missing-internal-auth-headers.md) — IoT sim không gửi `X-Internal-Service` + `X-Internal-Secret` headers (Iot_Simulator_clean scope, reference — fix HS-006 + IS-002 phải đồng bộ)
- ADR INDEX:
  - [ADR-005 — Internal service-to-service authentication strategy](../../../ADR/INDEX.md) — governs `require_internal_service`; HS-006 là implementation gap vs ADR intent.
  - [ADR-015 — Alert severity taxonomy — clarify 4 layers + fix BE enum drift](../../../ADR/INDEX.md) — governs `ESCALATION_MATRIX` + severity column CHECK; D1 drift tracked qua XR-002.
  - [ADR-004 — Standardize API prefix `/api/v1/{domain}/*`](../../../ADR/INDEX.md) — context cho `RISK_CONTRACT_ROUTE_PREFIXES` duplicate prefix list (D-019 liên đới, governed by ADR-004).
- Intent drift (reference only, không re-flag — blacklist per preflight):
  - `D1` — severity vocab drift (severity ∈ {normal, high, critical} vs risk_level ∈ {low, medium, critical}). Governed ADR-015, tracked XR-002.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — Task 1 HS-005 CORS + settings injection hook (pydantic-settings migration cần đồng bộ).
  - `BE_M02_routes_audit.md` — Task 6 HS-004 telemetry auth guard (combo với HS-006).
  - `BE_M03_services_audit.md` — Task 9 escalation matrix downstream + D1 vocabulary normalization.
  - `BE_M04_models_audit.md` — Task 4 severity CHECK constraint enforcement (XR-002).
  - `BE_M09_utils_audit.md` — Task 3 JWT primitives + rate limiter (`ACCESS_TOKEN_EXPIRE_DAYS` usage).
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
