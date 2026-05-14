# Pre-flight Context — hs-phase1-code-audit (Task 0)

**Phase:** Phase 1 macro audit — Track 2 (backend FullMode) + Track 3 (mobile SkimMode)
**Repo under audit:** `health_system/` (Flutter mobile + FastAPI backend)
**Output dir:** `PM_REVIEW/AUDIT_2026/tier2/health_system/`
**Framework:** [`00_audit_framework.md`](../../00_audit_framework.md) v1
**Prepared:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Purpose:** Single source of context cho 23 per-module audit tasks + 1 aggregate task. Các task kế thừa context này thay vì re-load framework/inventory/INDEX mỗi lần.

**Hard constraint:** KHÔNG sửa source trong `health_system/backend/app/` hoặc `health_system/lib/`. Chỉ ghi markdown trong OutputDir + append rows vào `PM_REVIEW/BUGS/INDEX.md`.

---

## 1. Output directory status

- `PM_REVIEW/AUDIT_2026/tier2/health_system/` — được tạo cùng file này (bằng `fs_write` tạo intermediate dir).
- Anchor file duy nhất hiện có: `_PREFLIGHT_CONTEXT.md` (file này).
- Siblings reference (precedent): [`../iot-simulator/`](../iot-simulator/) — 9 per-module + 2 track summary (Pass A + Pass B_C) + 1 Phase 3 prep.

---

## 2. Framework rubric v1 — quick reference

### 2.1 5 axes + score range

Mỗi axis integer score trong `{0, 1, 2, 3}`. `Total = sum 5 axes ∈ [0, 15]`.

| Axis | Focus tóm tắt |
|---|---|
| Correctness | Logic, edge cases, error paths, type safety, contract compliance. |
| Readability | Naming, structure, comment, function size, complexity. |
| Architecture | Layering, coupling, abstractions, dependency direction. |
| Security | Auth, authz, input validation, secrets, PHI handling, output sanitization. |
| Performance | DB query patterns, caching, async correctness, payload size. |

### 2.2 Band rule (verdict)

| Band | Marker | TotalScore range |
|---|---|---|
| Mature | 🟢 | 13–15 |
| Healthy | 🟡 | 10–12 |
| Needs attention | 🟠 | 7–9 |
| Critical | 🔴 | 0–6 |

**Override rule (Requirement 1.5):** IF `Security == 0` → Band = 🔴 Critical bất kể Total.

### 2.3 Anti-pattern auto-flag (Security = 0 + Severity = Critical)

Hit bất kỳ 1 → force `Security = 0` + bug `Severity = Critical`:

- `eval()` / `exec()` với user input.
- SQL string concat với user input (cấm, dùng parameterized / ORM).
- `dangerouslySetInnerHTML` với user input (React only — không áp dụng repo này).
- Password / credential plaintext (any storage).
- CORS wildcard `*` trong production config.
- SSL verify disabled (verify flag = False, rejectUnauthorized false).
- Token nhạy cảm trong `localStorage` (web) hoặc `SharedPreferences` (Flutter — phải `flutter_secure_storage`).
- Hardcoded API key / JWT secret / DB credential commit git.

### 2.4 Stack-specific checklist (trích áp dụng repo)

**FastAPI (backend track):**
- Pydantic v2 schema validate tại router boundary (input + response_model).
- `Depends(get_current_user)` cho user-facing routes, `Depends(require_internal_service)` cho internal (IoT sim).
- Async correctness (`asyncio.to_thread` cho sync I/O, không block event loop).
- HTTP exception handling đúng (4xx vs 5xx, không leak stack trace).
- SQLAlchemy: parameterized query 100%, eager loading (`selectin`/`joined`) tránh N+1.

**Flutter (mobile track):**
- `mounted` check sau mọi `await` trước `setState`.
- `flutter_secure_storage` cho token, KHÔNG `SharedPreferences`.
- HTTPS enforce, no PII/PHI log.
- `const` constructors. `ListView.builder` thay vì `Column` với list dài.
- Clean architecture per feature: `data/domain/presentation`, feature A không import internals feature B.

### 2.5 Out of scope for rubric (framework v1)

- Test coverage → report section riêng, không axis 6.
- Documentation → gộp vào Readability.
- Accessibility → gộp vào Readability stack-specific cho Flutter/React.
- i18n → đã có convention (VI copy + EN code), không cần axis.

---

## 3. Bug ID allocation — next unused sequence

Parse `PM_REVIEW/BUGS/INDEX.md` (snapshot date 2026-05-13):

### 3.1 HS-* sequence

Open HS bugs: `HS-001`, `HS-002`, `HS-003`, `HS-004`. Không có HS bug nào đã resolved hoặc closed.

- **Next unused HS:** **`HS-005`**.
- Allocate sequentially `HS-005, HS-006, HS-007, ...` — NEVER reuse retired number (Requirement 6.3).

### 3.2 XR-* sequence

Open XR bugs: `XR-001` (topology steering endpoint prefix drift), `XR-002` (BE SQLAlchemy severity CheckConstraint drift). Không có XR bug resolved/closed.

- **Next unused XR:** **`XR-003`**.
- Allocate sequentially `XR-003, XR-004, ...`.

### 3.3 Open bugs trong scope audit (candidate dedupe targets)

Các bug dưới đây đã có trong BUGS INDEX — **KHÔNG tạo bug mới** nếu finding trùng, chỉ reference:

| BugID | Severity | Summary | File:Line anchor | Module tracks |
|---|---|---|---|---|
| `HS-001` | Critical | Devices schema drift — user_id NOT NULL/CASCADE vs nullable/SET NULL | `backend/app/models/device.py` (expected) | BE-M04 models |
| `HS-002` | High | Cross-user MAC duplicate bypass — BR-040-01 violation | `backend/app/services/device_service.py` (expected) | BE-M03 services |
| `HS-003` | Medium | Device calibration offsets never consumed (dead write-only data) | `backend/app/models/device.py` + services | BE-M04 + M03 |
| `HS-004` | Critical | Mobile telemetry endpoints `/sleep, /sleep-risk, /imu-window` thiếu auth guard | `backend/app/api/routes/telemetry.py` | BE-M02 routes |
| `XR-001` | Medium | Topology steering endpoint prefix drift (`/api/internal/*` vs real `/mobile/*`) | Steering docs + `backend/app/main.py` | BE-M01 bootstrap |
| `XR-002` | — | BE SQLAlchemy severity CheckConstraint drift (D1 fix point) | `backend/app/models/{sos_event, alert}_model.py` + `core/alert_constants.py` | BE-M04 + M08 core + M03 services |

Dedupe rule: IF finding mới khớp 1 trong 6 bugs trên theo (file path + symptom keyword + root cause) → reference BugID đó trong `## Cross-references`, KHÔNG tạo bug mới.

---

## 4. Accepted ADRs ảnh hưởng `health_system`

Parse `PM_REVIEW/ADR/INDEX.md` — filter status 🟢 Accepted + tag touching health_system (tag `health_system`, `mobile`, `mobile-backend`, `mobile-frontend`, `cross-repo` có health_system scope, `security` internal-secret, `api` prefix):

| ADR ID | Title | Tags | Áp dụng audit module |
|---|---|---|---|
| `ADR-004` | Standardize API prefix `/api/v1/{domain}/*` cho all backend services | api, cross-repo, backend, refactor, workflow | BE-M01 bootstrap (root_path hack drop), BE-M02 routes (prefix consistency) |
| `ADR-005` | Internal service-to-service authentication strategy | security, cross-repo, backend, health_system, model-api, iot-sim | BE-M02 routes (`require_internal_service` telemetry), BE-M07 adapters (`X-Internal-Secret` outbound), BE-M08 core/dependencies |
| `ADR-008` | Mobile BE không host system settings write — admin BE là single source of truth | architecture, mobile-backend, health_system, healthguard, cross-repo, simplification, scope, dead-code | BE-M02 routes (settings write dead-code check), BE-M03 services (settings_service scope) |
| `ADR-009` | Avatar storage = Supabase (mobile) — intentional cross-repo split với R2 (admin AI) | architecture, mobile-frontend, health_system, storage, scope | MOB-M12 profile (avatar upload flow) |
| `ADR-010` | Devices schema canonical = PM_REVIEW (user_id nullable, ON DELETE SET NULL) | database, schema, cross-repo, health_system, iot-sim, canonical | BE-M04 models (HS-001 Phase 4 scheduled reference) |
| `ADR-011` | UC040 Connect Device = pair-create only (drop pair-claim flow) | scope, uc, health_system, mobile, graduation-project | MOB-M05 device (pair flow scope) |
| `ADR-012` | Drop calibration offset fields (heart_rate_offset, spo2_calibration, temperature_offset) | scope, schema, health_system, mobile, dead-code, graduation-project | BE-M04 models + MOB-M05 device (HS-003 reference) |
| `ADR-013` | IoT Simulator direct-DB write cho vitals tick (bypass BE) | architecture, iot-sim, health_system, cross-repo, performance, scope | BE-M02 telemetry routes (vitals ingest path relation) |
| `ADR-015` | Alert severity taxonomy — clarify 4 layers + fix BE enum drift | architecture, severity, cross-repo, health_system, iot-sim, healthguard, database, schema | BE-M04 models (XR-002 CheckConstraint fix), BE-M08 core/alert_constants (ESCALATION_MATRIX), BE-M03 services/risk_alert_service (D1 escalation) |

Áp dụng rule (Requirement 5.4): WHEN finding khớp scope ADR Accepted → cite ADR ID trong `## Findings`, KHÔNG re-debate. ADR-010, ADR-012, ADR-015 đặc biệt quan trọng vì đã có Phase 4 schedule mapping sang HS-001/HS-003/XR-002.

---

## 5. Intent drift registry — health_system scope

### 5.1 Registry location

- Parent: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/`
- Repo folder: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/`
- Template: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/TEMPLATE.md`

### 5.2 Existing drift files (per-module, format `D-<MODULE>-<LETTER>` nội bộ)

10 files hiện có tại `tier1.5/intent_drift/health_system/`:

| File | Module | Status ghi nhận |
|---|---|---|
| `AI_XAI.md` | AI / XAI | — |
| `AUTH.md` | Auth | — |
| `DEVICE.md` | Device | Ref HS-001, HS-002, HS-003 — self-correction `last_sync_at` flagged |
| `INGESTION.md` | Ingestion (telemetry) | v2 confirmed — drop D-ING-01 (overlap HS-004), drop D-ING-02 (overlap XR-001), keep D-ING-03 + D-ING-04 doc-only |
| `MONITORING.md` | Monitoring | — |
| `NOTIFICATIONS.md` | Notifications | Phase 0.5 reverify ✅ — D-NOT-A..E decisions (C1 drop acknowledge, A2a drop BE filter, A2b implement mark-all, C3 drop preferences, Keep expire worker) |
| `PROFILE.md` | Profile | — |
| `RELATIONSHIPS.md` | Relationships (family) | — |
| `SETTINGS.md` | Settings | — |
| `SLEEP.md` | Sleep | — |

Mapping module audit task → drift file cross-reference candidate:

- BE-M02 routes → `INGESTION.md` (telemetry), `AUTH.md`, `NOTIFICATIONS.md`, `RELATIONSHIPS.md`, `SETTINGS.md`
- BE-M03 services → `DEVICE.md`, `MONITORING.md`, `NOTIFICATIONS.md`, `AI_XAI.md`, `RELATIONSHIPS.md`
- BE-M04 models → `DEVICE.md` (HS-001/HS-003), `AUTH.md`, `PROFILE.md`
- BE-M08 core → `NOTIFICATIONS.md` (severity), `MONITORING.md`
- MOB-M04 auth → `AUTH.md`
- MOB-M05 device → `DEVICE.md`
- MOB-M06 family → `RELATIONSHIPS.md`
- MOB-M07 health_monitoring → `MONITORING.md`
- MOB-M08 notifications → `NOTIFICATIONS.md`
- MOB-M10 analysis → `AI_XAI.md`
- MOB-M11 sleep_analysis → `SLEEP.md`
- MOB-M12 profile/home/onboarding → `PROFILE.md`, `SETTINGS.md`

### 5.3 Blacklist — reference only, KHÔNG re-flag (Requirement 5.6)

Các ID `D-012`, `D-019`, `D-021`, `D1`, `D3` có nguồn gốc **tier1 documents** (`tier1/api_contract_v1.md`, `tier1/topology_v2.md`) — NOT tier1.5 per-module drift files. Mapping chi tiết:

| Drift ID | Nguồn | Scope | Governing ADR / Bug |
|---|---|---|---|
| `D-012` | `tier1/api_contract_v1.md` | Telemetry endpoints inconsistent internal guard | Resolved via HS-004 (Phase 4 per ADR-005) |
| `D-019` | `tier1/topology_v2.md` | API prefix `root_path` hack (BE mobile) | Governed by ADR-004 (accepted, Phase 4 refactor) |
| `D-021` | `tier1/topology_v2.md` | `/sleep` + `/imu-window` + `/sleep-risk` no internal guard (P0 Critical) | Resolved via HS-004 (Phase 4 per ADR-005) |
| `D1` | Severity vocab drift (alerts/sos_events CheckConstraint + escalation matrix) | BE `core/alert_constants.py` + models `*_model.py` | Governed by ADR-015, tracked as XR-002 |
| `D3` | Notification read state truth source (notification_reads table vs inline flag) | BE `services/notification_service.py` + mobile `features/notifications/` | Governed by NOTIFICATIONS.md Phase 0.5 reverify |

Rule áp dụng mọi module task:
- IF finding match D-012 / D-019 / D-021 / D1 / D3 → reference trong `## Cross-references` **only**, KHÔNG liệt kê trong `## New bugs`.
- Các D-series mới (nếu auditor discover — Requirement 7.4) → propose trong `_TRACK_SUMMARY.md` `## Cross-module patterns`, KHÔNG tự tạo file trong `tier1.5/intent_drift/health_system/` Phase 1.

---

## 6. Module inventory — BE track (FullMode, 11 modules)

Source: `PM_REVIEW/AUDIT_2026/module_inventory/02_health_system_backend.md`.

| Order | ModuleID | Slug | Path | Est. files | Est. LoC | Effort | Priority | Ghi chú audit |
|---|---|---|---|---|---|---|---|---|
| 1 | M01 | `main_bootstrap` | `backend/app/main.py` | 1 | ~120 | S (~1h) | P0 | ADR-004 entry point, middleware order |
| 2 | M08 | `core` | `backend/app/core/` | 6 | ~700 | M (~4h) | P0 | `alert_constants` (D1), `dependencies`, `security`, `config` — ADR-005 auth |
| 3 | M09 | `utils` | `backend/app/utils/` | 8 | ~1,000 | M (~4h) | P1 | `jwt`, `password`, `rate_limiter`, email, datetime |
| 4 | M04 | `models` | `backend/app/models/` | 11 | ~1,500 | M (~5h) | P0 | CheckConstraint coverage (D1 ref), HS-001/HS-003 context |
| 5 | M05 | `schemas` | `backend/app/schemas/` | 12 | ~1,500 | M (~5h) | P1 | Pydantic v2 input/response separation |
| 6 | M02 | `routes` | `backend/app/api/routes/` | 13 | ~2,500 | L (~10h) | P0 | Per-endpoint security; HS-004 telemetry guard; D-021 ref |
| 7 | M06 | `repositories_db` | `backend/app/{repositories,db}/` | 5 + 3 | ~1,000 | M (~4h) | P1 | SQL injection (raw `text()`), N+1 detection |
| 8 | M07 | `adapters` | `backend/app/adapters/` | 6 | ~800 | M (~4h) | P1 | Model-api client `X-Internal-Secret`, circuit breaker |
| 9 | M03 | `services` | `backend/app/services/` | 18 | ~5,000+ | L (~20h) | P0 | HEAVIEST. D1 escalation matrix, PHI handling |
| 10 | M10 | `observability` | `backend/app/observability/` | 2 | ~200 | S (~1h) | P2 | StageTimer, PHI masking log |
| 11 | M11 | `scripts` | `backend/{app/scripts, scripts}/` | ~10 | ~1,500 | S (~3h) | P2 | Idempotency, destructive safety, no-credential-echo |

**Track 2 total effort:** ~61h FullMode.

**Phase 3 deep-dive candidates (pre-flagged):**
- `core/alert_constants.py` — D1 escalation matrix fix
- `models/sos_event_model.py:65` — D1 severity CheckConstraint
- `services/risk_inference_service.py` — orchestration
- `services/risk_alert_service.py` — escalation
- `services/fall_event_service.py` — fall persistence + dispatch
- `services/push_notification_service.py` — FCM fanout
- `services/notification_service.py` — D3 read state truth
- `api/routes/telemetry.py` — D-021 internal guard
- `api/routes/auth.py` — 10 auth endpoints flow
- `utils/jwt.py` — token issuance / refresh rotation
- `utils/rate_limiter.py` — auth endpoint protection
- `repositories/relationship_repository.py` — D-005 extra cols
- `services/relationship_service.py` — family graph logic

---

## 7. Module inventory — Mobile track (SkimMode, 12 modules)

Source: `PM_REVIEW/AUDIT_2026/module_inventory/03_health_system_mobile.md`.

| Order | ModuleID | Slug | Path | Est. files | Est. LoC | Effort | Priority | Ghi chú audit |
|---|---|---|---|---|---|---|---|---|
| 1 | M01 | `bootstrap` | `lib/{app, main}.dart` | 2 | ~300 | S (~1h) | P1 | ProviderScope, router, dotenv, crash reporting |
| 2 | M02 | `core` | `lib/core/` | 14 | ~3,000 | L (~10h) | P0 | Network client, token interceptor, route guard, deep link |
| 3 | M03 | `shared` | `lib/shared/` | 15 | ~2,000 | M (~5h) | P1 | Widgets, utils, theme centralization |
| 4 | M04 | `auth` | `lib/features/auth/` | 22 | ~2,500 | M (~6h) | P0 | **Full on token storage** — secure storage enforce |
| 5 | M05 | `device` | `lib/features/device/` | 35 | ~3,500 | L (~8h) | P0 | BLE permission, MAC PII handling, command whitelist |
| 6 | M08 | `notifications` | `lib/features/notifications/` | 18 | ~2,500 | M (~6h) | P0 | **Full on FCM payload handler** — D1+D3 ref |
| 7 | M09 | `emergency_fall` | `lib/features/{emergency, fall}/` | 17 + 8 = 25 | ~2,500 | L (~8h) | P0 | **Full on SOS + fall handlers** — life-critical |
| 8 | M07 | `health_monitoring` | `lib/features/health_monitoring/` | 23 | ~3,000 | L (~8h) | P0 | PHI local cache, offline handling |
| 9 | M06 | `family` | `lib/features/family/` | 45 | ~4,500 | L (~12h) | P0 | LARGEST. **Full on deep link routing** |
| 10 | M10 | `analysis` | `lib/features/analysis/` | 34 | ~3,500 | L (~8h) | P1 | XAI display, model-api consumer |
| 11 | M11 | `sleep_analysis` | `lib/features/sleep_analysis/` | 18 | ~2,000 | M (~5h) | P1 | Sleep PHI, history virtualization |
| 12 | M12 | `home_profile_onboarding` | `lib/features/{home, profile, onboarding}/` | 14 + 11 + 1 = 26 | ~2,000 | M (~5h) | P1 | **Full on profile PHI display** |

**Track 3 total effort:** ~40–50h SkimMode (realistic, per inventory note — 82h pessimistic nếu full).

**SkimMode reminder:** Architecture + Security full detail; Correctness/Readability/Performance feature-level (1–3 bullet per axis OK). Defer per-screen widget review → Phase 3 với `Defer Phase 3` label trong `## Out of scope`.

**Mixed-mode files (SkimMode + FullMode on specific file, Requirement 8.8):**

| Module | File(s) cần FullMode | Lý do |
|---|---|---|
| MOB-M04 auth | `<token_repository.dart>` / `<secure_storage_service.dart>` | Token storage — auto-flag nếu dùng `SharedPreferences` |
| MOB-M08 notifications | `<fcm_handler_file>` | FCM payload parse, deep link whitelist |
| MOB-M09 emergency_fall | `<sos_handler>`, `<fall_detector>` | Life-critical fail-safe + idempotency |
| MOB-M06 family | `<family_routes.dart>`, `<deep_link_handler.dart>` | Deep link param sanitization, role RBAC |
| MOB-M12 home/profile/onboarding | `<profile_screen>` | PHI masking, audit log |

Header `Depth mode` khi mixed: `Skim + Full on <comma-separated paths>`.

---

## 8. Filename convention reminder (Requirement 9)

Per-module file: `{TRACK}_{ModuleID}_{slug}_audit.md`

- `TRACK` ∈ `{BE, MOB}` (track prefix bắt buộc vì BE + Mobile trùng ModuleID M01..M11).
- `ModuleID` ∈ `M01..M11` (BE) hoặc `M01..M12` (Mobile).
- `slug` = kebab-case ngắn mô tả scope.

Output list dự kiến (24 file):

```
PM_REVIEW/AUDIT_2026/tier2/health_system/
├── _PREFLIGHT_CONTEXT.md                       # this file
├── _TRACK_SUMMARY.md                           # aggregate (Task 24)
├── BE_M01_main_bootstrap_audit.md              # Task 1
├── BE_M02_routes_audit.md                      # Task 6
├── BE_M03_services_audit.md                    # Task 9
├── BE_M04_models_audit.md                      # Task 4
├── BE_M05_schemas_audit.md                     # Task 5
├── BE_M06_repositories_db_audit.md             # Task 7
├── BE_M07_adapters_audit.md                    # Task 8
├── BE_M08_core_audit.md                        # Task 2
├── BE_M09_utils_audit.md                       # Task 3
├── BE_M10_observability_audit.md               # Task 10
├── BE_M11_scripts_audit.md                     # Task 11
├── MOB_M01_bootstrap_audit.md                  # Task 12
├── MOB_M02_core_audit.md                       # Task 13
├── MOB_M03_shared_audit.md                     # Task 14
├── MOB_M04_auth_audit.md                       # Task 15
├── MOB_M05_device_audit.md                     # Task 16
├── MOB_M06_family_audit.md                     # Task 20
├── MOB_M07_health_monitoring_audit.md          # Task 19
├── MOB_M08_notifications_audit.md              # Task 17
├── MOB_M09_emergency_fall_audit.md             # Task 18
├── MOB_M10_analysis_audit.md                   # Task 21
├── MOB_M11_sleep_analysis_audit.md             # Task 22
└── MOB_M12_home_profile_onboarding_audit.md    # Task 23
```

---

## 9. Language + style reminder (Requirement 10)

- Body: tiếng Việt. Technical terms (`endpoint`, `router`, `middleware`, `service`, `repository`, `dependency injection`, `async`, `N+1`, `JWT`, `CORS`, `FCM`, `circuit breaker`, axis names, Band labels) giữ English.
- Code identifiers, file paths, command examples — English, trong fenced code blocks.
- Emoji chỉ cho Band markers (🟢 🟡 🟠 🔴) + verdict summary prose. KHÔNG emoji trong code block / inline code span.
- No filler ("it is worth noting", "as we can see"). Recommendation-first.

---

## 10. Self-check properties reminder (Requirement 12)

Trước khi commit mỗi deliverable, verify mental:

1. Score cells ∈ `{0, 1, 2, 3}` cho 5 axis, `Total ∈ [0, 15]`.
2. `Total` = sum 5 axes (arithmetic).
3. Band label đúng range + Security=0 override hợp lệ.
4. Top 5 risks trace ngược được về finding thực trong per-module file.
5. Mỗi BugID mới xuất hiện exactly 1 lần trong BUGS INDEX sau commit.
6. Cross-reference links resolve đến file / heading tồn tại.
7. Mọi module trong inventory có per-module file (coverage completeness 23/23).
8. Aggregate `Track average` = mean 23 Total, round 2 decimal places.

---

## 11. Trạng thái Task 0

- [x] OutputDir created (this file).
- [x] Framework v1 rubric loaded + tóm tắt ở section 2.
- [x] BUGS INDEX parsed — next unused IDs: **HS-005**, **XR-003**. 6 candidate dedupe bugs liệt kê.
- [x] ADR INDEX parsed — 9 Accepted ADRs trong scope (ADR-004, 005, 008, 009, 010, 011, 012, 013, 015) mapped to modules.
- [x] Intent drift registry — 10 per-module drift files listed; blacklist D-012/D-019/D-021/D1/D3 mapped sang governing ADR/Bug.
- [x] Module inventory BE (11) + Mobile (12) đọc + tóm tắt bảng path/LoC/priority.
- [x] Constraint "no source modification" reaffirmed — chỉ tạo markdown trong OutputDir + append BUGS INDEX.

**Task 0 DONE.** Task 1 (BE-M01 main bootstrap) ready to start với context này.

---

## 12. Cross-references

- Framework: [`PM_REVIEW/AUDIT_2026/00_audit_framework.md`](../../00_audit_framework.md)
- Inventory BE: [`PM_REVIEW/AUDIT_2026/module_inventory/02_health_system_backend.md`](../../module_inventory/02_health_system_backend.md)
- Inventory Mobile: [`PM_REVIEW/AUDIT_2026/module_inventory/03_health_system_mobile.md`](../../module_inventory/03_health_system_mobile.md)
- BUGS INDEX: [`PM_REVIEW/BUGS/INDEX.md`](../../../BUGS/INDEX.md)
- ADR INDEX: [`PM_REVIEW/ADR/INDEX.md`](../../../ADR/INDEX.md)
- Intent drift registry: [`PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/`](../../tier1.5/intent_drift/health_system/)
- Precedent track: [`PM_REVIEW/AUDIT_2026/tier2/iot-simulator/`](../iot-simulator/) (9 per-module + 2 track summary + 1 Phase 3 prep).
- Spec: `health_system/.kiro/specs/hs-phase1-code-audit/` — requirements / design / tasks.
