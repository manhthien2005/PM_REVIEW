# Audit: BE-M01 — Main bootstrap (FastAPI app factory)

**Module:** `health_system/backend/app/main.py`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module bootstrap single-file cho mobile backend FastAPI — `backend/app/main.py` (~78 LoC). Scope audit = entry point app factory, middleware stack, router mounting, startup side-effects (SQLAlchemy `metadata.create_all`), root redirect. Phạm vi loại trừ: `api/router.py` aggregate (thuộc BE-M02 routes), core dependencies / settings (BE-M08 core), observability module wiring chi tiết (BE-M10), model metadata schema (BE-M04 models). Audit focus per Phase 1 macro plan — ADR-004 entry point + middleware security order.

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `backend/app/main.py` | 78 | FastAPI app factory, CORS + risk contract middleware, router mount, root redirect | Single file, linear bootstrap — D-019 root_path hack observed (governed ADR-004). |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Happy path runs. `metadata.create_all` at import-time + root redirect không honor `root_path` là 2 edge cases chưa xử lý. |
| Readability | 3/3 | 78 LoC linear, comment giải thích `expose_headers`, `noqa: F401` annotated rõ ràng, docstring trên middleware custom. |
| Architecture | 2/3 | Layering ổn nhưng schema bootstrap pattern lỗi thời (create_all vs migration), thiếu `lifespan`, exception handler, và wiring observability (M10). |
| Security | 0/3 | Auto-flag CORS wildcard origins + credentials combo trong bootstrap production config. |
| Performance | 3/3 | Middleware async dispatch đúng, `applies_to_path` gate tránh inject header mọi response, không có blocking I/O trong hot path. |
| **Total** | **10/15** | Band: **Critical** — Security=0 override regardless of Total (bình thường 10/15 = Healthy). |

## Findings

### Correctness

- `backend/app/main.py:24` — `Base.metadata.create_all(bind=engine)` chạy tại module-level, nghĩa là mọi `import app.main` (test collection, alembic stub, dev script) đều trigger DDL round-trip. Không có error handling nếu DB offline leading to ImportError gián tiếp, khó debug. Contract implicit: DB phải up trước khi import app. Nên dời vào `lifespan` startup phase hoặc xoá hẳn và dùng migration tool (canonical `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`).
- `backend/app/main.py:69-72` — `root_redirect` trả về `RedirectResponse(url="/mobile-docs")`. URL tuyệt đối này KHÔNG honor `root_path="/api/v1"`. Khi deploy sau reverse proxy strip prefix, browser sẽ bị redirect tới `/mobile-docs` ngoài scope proxy (404). Fix: dùng `request.url_for("swagger_ui_html")` hoặc compose từ `app.docs_url` đã resolve.
- Không có `@app.exception_handler(HTTPException)` / generic handler → mọi exception fall-through FastAPI default. Rủi ro leak stack trace trong production nếu service layer raise raw `Exception`. Tương ứng steering `22-fastapi.md` "str(exc) leaked to client response" anti-pattern.

### Readability

- File 78 LoC, flow tuyến tính: imports → table creation → FastAPI init → middleware → router mount → root redirect. Không có branching phức tạp, reader scan dưới 2 phút.
- `backend/app/main.py:41-45` — comment giải thích rõ WHY `expose_headers` cần thiết cho Swagger UI browser client — đúng spirit "explain why, not what".
- `backend/app/main.py:15-21` — 7 model imports với `noqa: F401` + comment "needed for table creation" — side-effect import pattern của SQLAlchemy được annotate đầy đủ, không leaving reader đoán.
- `RiskContractVersionMiddleware` có docstring mô tả Phase 6 context + reference `app.core.risk_contract.RISK_CONTRACT_ROUTE_PREFIXES` — traceable.
- Thiếu module-level docstring tóm tắt bootstrap contract (middleware order, startup contract) — minor, không deduct.

### Architecture

- `backend/app/main.py:24` — coupling bootstrap vào DB schema (create_all) = layering shortcut. Canonical pattern: migration script là single source of truth (`PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`). Create_all sẽ silently drift từ canonical schema (không apply CHECK constraint, index partial, trigger), dẫn tới XR-002 class bug (severity CheckConstraint drift đã được ghi nhận ở scope BE-M04/M08). Giữ create_all = sanction future drift.
- Thiếu `lifespan` context manager — FastAPI 0.93+ khuyến nghị `lifespan` thay `@app.on_event("startup"/"shutdown")`. Hiện tại không có startup hook nào (adapter warmup, FCM credential check, model-api ping), cũng không có shutdown hook (flush push token queue, close circuit breaker). Khi M07 adapters hoặc M03 services cần resource lifecycle, bootstrap này không có khung sẵn.
- Middleware stack chỉ 2 layer: `CORSMiddleware` + `RiskContractVersionMiddleware`. Thiếu: (a) request-ID / correlation-ID middleware để gắn trace xuyên service, BE-M10 observability có infra nhưng chưa wire ở main.py; (b) request-size limit middleware; (c) structured logging binding. Auth middleware global KHÔNG cần vì pattern per-endpoint `Depends(get_current_user)` là idiomatic FastAPI — OK.
- Middleware order đúng tại runtime: Starlette stack LIFO nên CORS (add đầu) wrap ngoài cùng → Risk (add sau) → app. Inbound request đi CORS preflight trước (OK). Nhưng thứ tự "auth sau CORS, rate limit sau auth" không verifyable ở bootstrap vì cả hai đều per-endpoint `Depends` thay vì middleware global — phải check ở BE-M02 routes.
- `backend/app/main.py:28-35` — `root_path="/api/v1"` + `servers=[{"url": "/api/v1", ...}]` + docs URL không prefix = D-019 hack (tier1 topology drift). Governed by ADR-004 (API prefix standardization). Reference only, không re-flag — xem Cross-references.
- `root_redirect` hardcode `/mobile-docs` thay vì đọc `app.docs_url` — coupling thay vì injection của config đã tồn tại.

### Security

- Auto-flag: CORS wildcard prod config — `backend/app/main.py:37-46`. Cấu hình set `allow_origins=["*"]`, `allow_credentials=True`, `allow_methods=["*"]`, `allow_headers=["*"]` — hit framework v1 anti-pattern list entry "CORS wildcard trong production config". Force Security=0 + Band=Critical + bug severity=Critical. Chi tiết impact:
  - Combo wildcard origins + `allow_credentials=True`: Starlette `CORSMiddleware` xử lý đặc biệt — echo lại request `Origin` header, effective tương đương `allow_origin_regex=".*"`. Nghĩa là: mọi origin (kể cả `https://attacker.example`) được phép gửi credentialed request mang JWT `Authorization` header. CSRF-class attack với cookie-bound session hoặc XSS-exfiltrated token trên web context khả thi.
  - Mobile Flutter client gọi qua native HTTP stack, không bị CORS enforce. Bị ảnh hưởng là browser-based callers (Swagger UI `/mobile-docs`, khả năng admin web hoặc tooling JS). Production endpoint expose cho browser thì attacker browser cũng gọi được.
  - Không có env-based differentiation (`.env.dev` vs `.env.prod`). `app/core/config.py` (BE-M08) chưa inject allowlist qua settings nên main.py không có cơ chế override.
  - `allow_methods=["*"]` + `allow_headers=["*"]` permissive compound thêm rủi ro; `expose_headers=[RISK_CONTRACT_VERSION_HEADER]` bản thân OK.
  - Fix Phase 4 (P0): driver allowlist từ `Settings.cors_allowed_origins: list[str]` (pydantic-settings), prod giá trị cụ thể (admin web origin, staging origin), dev giá trị localhost + emulator. Giữ `allow_credentials=True` chỉ khi allowlist finite; ngược lại drop credentials flag.
  - Allocate **HS-005** (xem New bugs).
- Thiếu security headers middleware (HSTS, X-Content-Type-Options, Referrer-Policy) — acceptable nếu terminate TLS + set header ở reverse proxy layer (nginx/cloudflare), nhưng chưa có ADR xác nhận contract — cần document deploy runbook (Phase 4 P1).
- Không có auth middleware global là có chủ ý (pattern per-endpoint `Depends`). Verify coverage sẽ làm ở BE-M02 routes — HS-004 đã được allocated cho telemetry gap (out of scope module này).

### Performance

- Middleware custom `RiskContractVersionMiddleware` dùng `BaseHTTPMiddleware` — overhead cao hơn raw ASGI middleware (Starlette docs note `BaseHTTPMiddleware` wrap request/response thành buffered object). Với conditional gate `applies_to_path(request.url.path)`, chỉ mutate header cho subset route nên thực tế negligible. Không cần refactor.
- `Base.metadata.create_all(bind=engine)` one-time cost tại startup, không block request path.
- `CORSMiddleware` và `include_router(api_router)` cost constant, không scale theo request.
- Không có N+1 / caching concern ở bootstrap scope — N/A.

## Positive findings

- `backend/app/main.py:41-45` — comment giải thích WHY `expose_headers` cần cho browser Swagger client. Reader context được preserve, không phải đoán.
- `backend/app/main.py:15-21` — pattern `noqa: F401` + comment "needed for table creation" cho 7 model import — annotate side-effect SQLAlchemy metadata một cách explicit, tránh reader misread và `isort` xoá nhầm.
- `RiskContractVersionMiddleware.dispatch` — docstring reference Phase 6 context + `RISK_CONTRACT_ROUTE_PREFIXES` giúp tracing back sang `app/core/risk_contract.py`. Good practice cho cross-module glue code.
- Conditional header injection qua `applies_to_path` — không spam header cho mọi response, chỉ gắn khi thuộc mobile risk surface. Thoughtful.
- Root redirect `/` -> `/mobile-docs` — micro-UX tốt cho dev (không gặp 404 ở `/`). Đánh dấu `include_in_schema=False` đúng, không pollute OpenAPI spec.
- Middleware order đúng semantics (CORS ngoài, custom middleware trong) — vô tình đúng nhờ LIFO Starlette stack nhưng không document. Khuyến nghị thêm comment khi refactor P1.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-005 | Critical | CORS wildcard allow_origins cộng allow_credentials True trong app bootstrap — cho phép mọi origin gửi credentialed request mang JWT, không có env-based allowlist | `backend/app/main.py:37-46` | Security |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-005**: Thay allow_origins wildcard bằng allowlist finite driven từ `Settings.cors_allowed_origins` (pydantic-settings, `.env.dev` + `.env.prod` tách biệt). Production = danh sách cụ thể (admin web origin, staging web); dev = localhost + mobile emulator origins. Nếu phải giữ `allow_credentials=True`, allowlist PHẢI finite. Ngược lại drop credentials flag.
- [ ] Remove `Base.metadata.create_all(bind=engine)` khỏi main.py — coupling bootstrap vào DDL side-effect. Chuyển sang migration script canonical (`PM_REVIEW/SQL SCRIPTS/`) chạy qua Alembic hoặc `psql` trong deploy pipeline. Tránh silent drift so với canonical schema (liên hệ XR-002 severity CheckConstraint drift).

### P1

- [ ] Convert startup sang FastAPI `lifespan` context manager — deprecate `@app.on_event` pattern (FastAPI 0.93+). Đặt chỗ cho future resource lifecycle: FCM credential warm-up, model-api adapter ping, push token queue flush on shutdown.
- [ ] Đăng ký global exception handler: `@app.exception_handler(HTTPException)` + `@app.exception_handler(Exception)` generic — guarantee không leak `str(exc)` hay stack trace ra client. Align steering `22-fastapi.md` anti-pattern list.
- [ ] Wire BE-M10 observability: request-ID middleware (Correlation-ID header), structured logger binding, PHI masking. Đảm bảo log line có `request_id` để tracing cross-service.
- [ ] Document deploy contract cho security headers (HSTS, X-Content-Type-Options, Referrer-Policy) — hoặc set ở reverse proxy, hoặc thêm middleware app-level. ADR ghi lại quyết định.
- [ ] Follow-up ADR-004 Phase 4 execution — xoá D-019 `root_path` + `servers` hack khi consumer client (Flutter `ApiClient`) đã migrate sang resolve qua settings.

### P2

- [ ] `root_redirect` dùng `app.docs_url` (resolved) thay vì hardcode `/mobile-docs` — giảm drift risk khi đổi docs_url path.
- [ ] Thêm module-level docstring ở `main.py` tóm tắt middleware order + startup contract — giúp future contributor đọc nhanh.
- [ ] Cân nhắc thêm request-size limit middleware (Starlette `add_middleware`) để bảo vệ trước malformed large payload DoS — priority thấp vì reverse proxy thường limit upstream.

## Out of scope

- Per-endpoint auth coverage, internal-secret guard, Pydantic schema at boundary — BE-M02 routes (HS-004 telemetry gap đã allocated).
- `CORSMiddleware` origin allowlist definition + pydantic-settings model — BE-M08 core (settings schema module).
- Observability middleware implementation detail (request-ID generator, structured logger) — BE-M10 observability.
- Model metadata schema consistency với canonical SQL — BE-M04 models (XR-002 CheckConstraint drift, HS-001/HS-003 device schema).
- `api/router.py` aggregate routing / prefix composition — BE-M02 routes.
- D-019 root_path hack deep remediation plan — governed by ADR-004, tracked trong Phase 4 ADR execution (ngoài scope Phase 1 audit).

## Cross-references

- BUGS INDEX:
  - [HS-005](../../../BUGS/INDEX.md) — CORS wildcard + credentials combo (new, allocated this audit)
  - [XR-001](../../../BUGS/XR-001-topology-steering-endpoint-prefix-drift.md) — topology steering endpoint prefix drift (liên hệ `root_path` + `servers` D-019 hack)
  - [HS-004](../../../BUGS/HS-004-telemetry-sleep-endpoints-no-auth.md) — telemetry auth gap (out of scope module này, reference để không re-flag)
  - [XR-002](../../../BUGS/XR-002-be-sqlalchemy-severity-checkconstraint-drift.md) — SQLAlchemy severity CheckConstraint drift (liên hệ `create_all` silent drift rationale)
- ADR INDEX:
  - [ADR-004 — Standardize API prefix /api/v1/{domain}/*](../../../ADR/INDEX.md) — governs `root_path` + `servers` hack; Phase 4 drop scheduled.
  - [ADR-005 — Internal service-to-service authentication strategy](../../../ADR/INDEX.md) — context cho auth pattern per-endpoint thay vì global middleware (out of scope module này, reference).
- Intent drift (reference only, không re-flag — blacklist per preflight):
  - `D-019` — API prefix `root_path` hack (nguồn `tier1/topology_v2.md`). Governed by ADR-004.
- Related audit files (pending):
  - `BE_M02_routes_audit.md` — per-endpoint security review (Task 6)
  - `BE_M08_core_audit.md` — settings model cho CORS allowlist (Task 2)
  - `BE_M10_observability_audit.md` — middleware wiring gap (Task 10)
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent template: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
