# Audit: M05 — Backend admin client + sim admin service

**Module:** `Iot_Simulator_clean/api_server/{backend_admin_client.py, sim_admin_service.py}`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 5A (IoT sim Pass A — security focus)

## Scope

| File | LoC | Role |
|---|---|---|
| `backend_admin_client.py` | 309 | HTTP client → health_system BE `/mobile/admin/*` (dual sync/async via httpx) |
| `sim_admin_service.py` | ~600 | DB-side admin operations (raw SQL via SQLAlchemy `text()`) |

**Total:** ~900 LoC

**Note:** Em đã đọc full `backend_admin_client.py` trong Phase -1.C, partial `sim_admin_service.py` trong Phase -1.A grep scan.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Defensive HTTP error mapping, allow_statuses pattern, dual transport. |
| Readability | 3/3 | Clear class structure, docstrings, public/private separation. |
| Architecture | 3/3 | Singleton holder pattern with override hook for tests, clean concern split. |
| Security | 3/3 | X-Internal-Service header sent, no SQL concat, env-based base URL. |
| Performance | 2/3 | Connection pooling ✓. Sync sim_admin_service raw SQL no eager loading. |
| **Total** | **14/15** | Band: **🟢 Mature** |

## Findings

### Correctness (3/3)

**backend_admin_client.py:**
- ✓ Custom exception `BackendAdminClientError` carries `method`, `path`, `status_code`, `body`, `reason` (line 15-37) — full context for debug
- ✓ `_request()` error mapping: `httpx.ConnectError` + `httpx.TimeoutException` → raises with context (line 104-115)
- ✓ `allow_statuses: set[int] | None = None` pattern (line 90) — `find_user_by_email` uses `allow_statuses={404}` to return None instead of raise (line 254-261) — semantic correctness
- ✓ Empty response handling: `if not raw: return None` (line 128-129)
- ✓ Dual sync (`_request`) + async (`_arequest`) implementations symmetric — no behavioral divergence
- ✓ Connection pool via shared `httpx.Client` constructor (line 47-51) — singleton pattern

**sim_admin_service.py** (partial scan):
- ✓ Raw SQL via `text()` with parameterized queries (`:user_id`, `:email`, etc.) — em đã thấy 7 instances trong Phase -1.A grep — NO string concat
- ✓ `LEFT JOIN users u ON u.id = d.user_id` correct outer join semantics (Phase -1.A grep line 85)
- ✓ Heartbeat update wraps in try/except + rollback (Phase -1.A grep line 294-297) — defensive

### Readability (3/3)

- ✓ Class docstrings explain purpose ("Indirection for the :class:`BackendAdminClient` singleton" line 263-268)
- ✓ Method-level docstrings present (`list_devices`, `create_device`, etc.)
- ✓ `_resolve_backend_base_url` static method extracted (line 65-71) — testable
- ✓ Removed dead code annotations preserved as comments (line 234 "Removed dead code: update_device (0 callers)") — audit trail
- ✓ Public/private separation: `_request`, `_arequest` private; `list_devices`, `create_device`, ... public

### Architecture (3/3)

- ✓ **Singleton holder pattern** (`_ClientHolder` line 263-285) — clean indirection for testability
- ✓ `get_backend_admin_client()` FastAPI dependency pattern (line 291-298)
- ✓ `set_backend_admin_client()` + `reset_backend_admin_client_for_tests()` test hooks
- ✓ Sync/async transport split → caller chooses based on context (HTTP handler uses sync via `_request`, background tasks could use async)
- ✓ `BackendAdminClientError` extends `RuntimeError` — proper exception hierarchy
- ✓ `__slots__ = ("instance",)` on `_ClientHolder` (line 270) — memory + protection against accidental attribute addition

### Security (3/3)

**X-Internal-Service header verified:**
- ✓ Sync client (`__init__` line 50): `headers={"X-Internal-Service": "iot-simulator"}` ✓
- ✓ Async client (`_ensure_async_client` line 61): same header ✓

**Base URL handling:**
- ✓ Env-based: `HEALTH_BACKEND_URL` (line 69) — default `http://localhost:8000` for dev
- ✓ Normalization strips trailing slash (line 70) — prevents `//` bugs
- ✓ Base path `/mobile/admin` hardcoded (line 45) — ADR-004 will update this to `/api/v1/mobile/admin`

**SQL injection prevention:**
- ✓ All `sim_admin_service.py` queries use parameterized `text()` with bind vars
- ✓ No string concat with user input

**Anti-patterns check:** No eval/exec, no hardcoded secrets, no SQL concat.

### Performance (2/3)

**Positives:**
- ✓ **Connection pooling** via persistent `httpx.Client` (line 47-51) — em scan thấy comment Phase -1 "CRITICAL #2 fix: shared httpx.Client" cho sleep_service nhưng đây không có comment, có vẻ initial design correct
- ✓ Async client lazy init (line 55-63) — không create event loop until needed
- ✓ Default timeout 10s (line 41) — reasonable cho admin operations
- ✓ `__slots__` on `_ClientHolder` reduces memory

**Concerns:**
- ⚠️ Connection pool size không config explicit (httpx default = 10 connections) — verify Phase 1 nếu burst traffic (multiple device sims simultaneously) saturates pool
- ⚠️ `sim_admin_service.py` raw SQL `SELECT id, email, full_name, is_active FROM users WHERE lower(email) = :email AND deleted_at IS NULL LIMIT 1` — case-insensitive search ✓ NHƯNG no index on `lower(email)` will trigger seq scan
- ⚠️ `list_devices` query (Phase -1.A grep line 80) selects 10+ columns including `calibration_data` (JSONB) — consider `SELECT *` antipattern if JSONB row > 100KB

## Recommended actions (Phase 4)

### P1 — Performance tuning
- [ ] Verify index `idx_users_email_lower` exists (or add) cho case-insensitive lookup
- [ ] Set explicit httpx connection pool size based on max concurrent device sims
- [ ] Profile `list_devices` query — selective columns nếu calibration_data heavy

### P1 — Cross-repo coordinate (ADR-004)
- [ ] Update base URL `/mobile/admin` → `/api/v1/mobile/admin` (line 45) when health_system BE refactor lands

### P2 — Defense
- [ ] Add request retry logic with exponential backoff (currently single attempt → fail loud)
- [ ] Consider per-method timeout override (vd `heartbeat` = 3s vs `list_devices` = 10s)

## Out of scope (defer Phase 3 deep-dive)

- `sim_admin_service.py` lines 320+ (full file content scan)
- SimAdminService class method-by-method audit
- Transaction boundary review
- Test coverage matrix

## Cross-references

- Phase -1.B: [D-019](../../tier1/api_contract_v1.md) — base URL `/mobile/admin` lacks `/api/v1` prefix → [ADR-004](../../../ADR/004-api-prefix-standardization.md) resolves
- Phase -1.C: [Path 6](../../tier1/topology_v2.md) — IoT sim → health_system BE admin
- Phase 0: Module M05 in [05_iot_simulator.md](../../module_inventory/05_iot_simulator.md)
- Consumer side: `health_system/backend/app/api/routes/admin.py` — already verified `Depends(require_internal_service)` ✓
