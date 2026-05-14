# ADR-005: Internal service-to-service authentication strategy

**Status:** Accepted
**Date:** 2026-05-12
**Decision-maker:** ThienPDM (solo)
**Tags:** [security, cross-repo, backend, healthguard, health_system, model-api, iot-sim]

## Context

Hệ thống VSmartwatch có nhiều service Backend giao tiếp nội bộ (không qua user JWT):

- **HealthGuard BE** (Express admin web) expose `/api/v1/internal/websocket/*` cho pump scripts emit WebSocket events ra admin FE.
- **health_system BE** (FastAPI mobile BE) expose `/mobile/admin/*` cho IoT sim ingest devices/users data.
- **healthguard-model-api** (FastAPI stateless) expose `/fall/predict`, `/health/predict`, `/sleep/predict` cho health_system BE gọi.
- **Iot_Simulator_clean** (FastAPI sim) gọi health_system BE để register devices/sessions.

Phase 1 audit phát hiện inconsistency + critical vulnerability:

- **HealthGuard `/api/v1/internal/*`:** Có middleware `checkInternalSecret` check `X-Internal-Secret` header. NHƯNG có fallback hardcoded `'internal-secret-key'` nếu env không set → 🔴 production deploy quên env = trivial bypass (D-010).
- **health_system `/mobile/admin/*`:** Dependency `require_internal_service` check dual header `X-Internal-Service: iot-simulator` + `X-Internal-Secret`. Mặc dù schema dual, IoT sim client (`backend_admin_client.py`) hiện chỉ gửi `X-Internal-Service` mà KHÔNG gửi `X-Internal-Secret` — flag finding chờ Phase 0.5 health_system audit.
- **model-api:** Phase 1 Track 4 phát hiện missing `verify_internal_secret` dependency ở các predict endpoints (M04 bootstrap audit).
- **IoT sim API:** Track 5A M03 phát hiện partial auth enforcement (router subset).

Không có ADR thống nhất pattern, dẫn tới:
- Mỗi repo tự code middleware riêng (drift)
- Fallback hardcoded ở nhiều nơi
- Không có rotation policy
- Không có audit trail cho internal calls

## Decision

**Chose:** Option A — Centralized policy "Required env, no fallback, fail-fast, single shared secret per environment".

**Why:** Đơn giản, đúng cho monolith small-team / solo dev (đồ án 2). Fallback hardcoded là CRITICAL trong production (D-010) — không thể keep. Single shared secret OK vì 4 repos cùng trust boundary (cùng infra deploy). Per-service secrets tăng complexity (key mgmt, rotation) không proportional với threat model hiện tại. Phase 5+ nếu cần granular per-service identity → revisit qua mTLS hoặc service mesh.

## Options considered

### Option A (chosen): Required env, no fallback, fail-fast, single shared `INTERNAL_SECRET`

**Description:**
- Mỗi service load `INTERNAL_SECRET` từ env var (no fallback).
- Startup check: nếu env missing → `throw new Error()` (Node) / `raise RuntimeError()` (Python) → fail-fast.
- Tất cả 4 repos dùng **CÙNG MỘT secret value** per environment (dev/staging/prod).
- Caller (script, IoT sim, BE-to-BE) gửi header `X-Internal-Secret: <value>` mỗi request.
- Middleware constant-time compare (`crypto.timingSafeEqual` Node / `hmac.compare_digest` Python).
- Generate command standard: `openssl rand -hex 32`.
- Rotate quarterly bằng cách deploy đồng thời với env var update (downtime ~30s).

**Pros:**
- Đơn giản, ít moving parts.
- Fail-fast tránh ai bypass do quên env.
- 1 env var để rotate cho cả 4 repos.
- Phù hợp solo dev / đồ án scope.

**Cons:**
- Single secret → leak = compromise tất cả services.
- Không phân biệt được caller identity (chỉ biết "internal" hay "không internal").
- Rotate downtime nhỏ.

**Effort:** S (~3-4h tổng cross-repo: HealthGuard + health_system + model-api + IoT sim mỗi cái ~30-45min)

### Option B (rejected): Per-service secrets

**Description:**
- Mỗi service có secret riêng: `HEALTHGUARD_INTERNAL_SECRET`, `HEALTH_SYSTEM_INTERNAL_SECRET`, `MODEL_API_INTERNAL_SECRET`, `IOT_SIM_INTERNAL_SECRET`.
- Service A gọi B phải biết B's secret.
- Caller identity trackable qua secret used.

**Pros:**
- Granular: leak 1 secret không compromise tất cả.
- Audit trail có caller identity.

**Cons:**
- Key management complexity: 4 secrets × 3 envs = 12 secrets cần manage.
- Service A cần update env khi B rotate.
- Đồ án 2 không có infra (HashiCorp Vault, AWS Secrets Manager) để manage.
- ROI thấp cho threat model hiện tại (4 services cùng trust boundary).

**Why rejected:** Complexity > benefit cho solo dev đồ án 2. Phase 5+ production scale có thể revisit.

### Option C (rejected): mTLS / Service mesh

**Description:**
- Certificate-based auth (mTLS).
- Service mesh (Istio, Linkerd, Consul Connect) làm sidecar.

**Pros:**
- Industry standard cho microservices production.
- Identity + auth + encryption built-in.
- No shared secrets.

**Cons:**
- Heavy infrastructure (K8s + service mesh).
- Effort 20-40h chỉ riêng setup.
- Overkill cho 4 services đồ án 2 deploy single VPS.

**Why rejected:** Vượt scope đồ án 2. Note as future option khi production scale.

### Option D (rejected): API Gateway centralized auth

**Description:**
- Kong / Tyk / nginx + lua module xử lý auth cho tất cả internal endpoints.

**Pros:**
- Centralized policy.
- Logging + rate limit + metrics built-in.

**Cons:**
- Thêm 1 service (gateway) phải maintain.
- Overhead network hop cho mỗi call.
- Đồ án 2 không cần.

**Why rejected:** Same as Option C — overkill cho scope.

---

## Consequences

### Positive

- **Eliminates D-010 vulnerability** (hardcoded fallback) cross-repo.
- **Fail-fast startup** giúp catch misconfig sớm (development + CI).
- **Single source of truth** cho secret value (1 env var để rotate).
- **Defense-in-depth** với rate limit + IP allowlist (Phase 5+) tăng cường security khi secret leak.

### Negative / Trade-offs accepted

- **Single secret compromise = full system compromise** — Em accept rủi ro này vì threat model đồ án 2 (production scope chưa cần granular identity). Mitigations: store secret trong env file gitignored + `.env.example` placeholder + rotate quarterly.
- **Caller identity blind** — không track được "ai gọi" qua secret. Em accept và mitigate bằng audit log `details.user_agent` + IP per call (D-INT-03).
- **Rotate downtime** ~30s mỗi quarter — acceptable cho VSmartwatch (no SLA strict).

### Follow-up actions required

- [ ] **HealthGuard BE** (Phase 4): remove fallback `|| 'internal-secret-key'`, add startup check, update `.env.example`. (~30min)
- [ ] **health_system BE** (Phase 0.5 audit + Phase 4): verify `require_internal_service` không có fallback; coordinate Phase 4 fix nếu có. (~30min audit + ~30min fix)
- [ ] **healthguard-model-api** (Phase 4): add `verify_internal_secret` dependency cho predict endpoints (Track 4 M04 finding); remove fallback nếu có. (~45min)
- [ ] **Iot_Simulator_clean** (Phase 4): coverage check `require_internal_service` cross routers (Track 5A M03 finding); add `X-Internal-Secret` header trong `backend_admin_client.py` khi gọi health_system. (~45min)
- [ ] **PM_REVIEW** (Phase 4): document trong `Authentication_Spec.md` hoặc tạo `Internal_Service_Auth.md` với example .env.
- [ ] **All repos**: align `.env.example` với placeholder `INTERNAL_SECRET=<openssl rand -hex 32>`.
- [ ] **Phase 5+ defer**: IP allowlist middleware per service.

## Reverse decision triggers

Conditions để reconsider quyết định này:

- **Service scaling beyond 4 repos** → Per-service secrets hoặc service mesh.
- **Multi-tenant requirement** (vd hệ thống serve nhiều bệnh viện) → granular per-tenant identity.
- **Compliance requirement** (HIPAA, GDPR audit) → cần caller identity track per call → Option B hoặc C.
- **Secret leak incident** → đánh giá lại single-secret model.
- **Service mesh available trong infra** (vd team adopt Istio cho lý do khác) → switch sang mTLS để consolidate.

## Related

- UC: KHÔNG có UC trực tiếp (technical contract); cross-ref `UC027_Admin_Dashboard_v2.md` brief section
- ADR: standalone (chưa supersede gì)
- Bug: triggered by Phase 1 audit findings:
  - HealthGuard M02 D-010 (internal secret fallback)
  - model-api Track 4 M04 (missing verify_internal_secret)
  - IoT sim Track 5A M03 (partial auth enforcement)
- Code: enforces in
  - `HealthGuard/backend/src/routes/internal.routes.js:11-22` (middleware)
  - `health_system/backend/app/core/dependencies.py:147-153` (require_internal_service)
  - `healthguard-model-api/app/main.py` + routers (Phase 4 add)
  - `Iot_Simulator_clean/api_server/middleware/auth.py` + `backend_admin_client.py:50-51`
- Spec: pending `PM_REVIEW/Internal_Service_Auth.md` (Phase 4)
- Intent drift review: `AUDIT_2026/tier1.5/intent_drift/healthguard/INTERNAL.md`

## Notes

- **Why không dùng Bearer JWT (machine-to-machine)?** JWT cần token rotation (refresh) + service identity claims. Cho đồ án 2 single-secret đủ + simpler.
- **Why không bind `X-Internal-Service` + `X-Internal-Secret` (health_system pattern)?** Dual header có benefit (caller identity in plaintext + auth secret) nhưng implementation hiện tại không consistent (IoT sim chỉ gửi 1 header). Quyết định: chấp nhận pattern `X-Internal-Secret` only như HealthGuard hiện dùng. health_system có thể keep dual header (backward compat) nhưng audit log nên dùng IP + User-Agent thay vì trust `X-Internal-Service` (client có thể spoof).
- **Cross-repo coord:** ADR này yêu cầu 3-4 repo PRs cùng Phase 4 sprint. Risk: PR merge order — em recommend deploy theo thứ tự (1) health_system (cập nhật .env first), (2) HealthGuard, (3) model-api, (4) IoT sim (caller cuối cùng).
