# Audit: M04 — repositories/ + db.py + sim_admin_service.py (DB-layer aspect)

**Module:** `Iot_Simulator_clean/api_server/{db.py, repositories/, sim_admin_service.py}`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 1 Track 5 Pass C — IoT sim DB access layer

## Scope

DB-access primitives. `db.py` owns engine + session factory. `repositories/device_repository.py` owns typed queries for `devices` table. `sim_admin_service.py` owns raw SQL for device lifecycle ops (activate/deactivate/assign) + delegates CRUD to DeviceRepository.

| File | LoC | Role |
|---|---|---|
| `db.py` | 97 | Engine init (env-driven DATABASE_URL), session factory, `session_scope` context mgr |
| `repositories/__init__.py` | 0 | Empty (no re-exports) |
| `repositories/device_repository.py` | 255 | Typed `DeviceRepository` (fetch / list / create / soft-delete) returning `AdminDeviceResponse` |
| `sim_admin_service.py` | 345 | Device lifecycle (activate/deactivate/assign/heartbeat/find-user), raw SQL for UPDATE flows + TTL cache on admin list |
| **Total** | **~697** | |

**Note:** Original inventory pegged M04 at ~300 LoC. Actual surface ~697 LoC because `sim_admin_service.py` overlaps both M04 (DB) and M05 (client wrapper). M05 audit covered the admin client + user-facing API, M04 audit focuses on DB-layer concerns (SQL safety, transaction boundary, cache coherency).

**Excluded:** Consumers (router layer, services) — audited in M01/M02.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | All SQL parameterized; soft-delete consistent; rollback on failure; commit explicit. Transaction boundary in activate_device multi-statement but atomic. |
| Readability | 3/3 | SQL constants named; functions <50 LoC; clear layering repo <- service. |
| Architecture | 2/3 | DeviceRepository delegation pattern clean; SimAdminService half-migrated (some ops still raw SQL directly); empty `repositories/__init__.py`. |
| Security | 3/3 | Parameterized queries 100%; lowercase email comparison; soft-delete respected in all WHERE clauses; DATABASE_URL env-driven fail-fast. |
| Performance | 2/3 | TTL cache (30s) on admin list; `list_active_devices` fetches detail per ID = N+1 pattern; pool_size=3 may be too small. |
| **Total** | **13/15** | Band: **Mature** |

## Findings

### Correctness (3/3)

**db.py (solid):**
- `_get_database_url()` raises `RuntimeError` voi clear message neu env missing — fail-fast at startup (line 32-38)
- `session_scope()` context manager pattern: try/except rollback + finally close (line 80-91)
- `pool_pre_ping=True` handles connection drops gracefully (line 43)
- Dual .env search: repo root + parent (line 18-26) — covers both dev + test layout
- `_engine` + `_SessionLocal` module globals with lazy init check — singleton pattern OK in ASGI single-init context

**DeviceRepository (solid):**
- 100% parameterized SQL — all `:param` bind vars, no f-string SQL concat
- `create_device` validates `device_name.strip()` empty -> raises ValueError (line 192-193)
- Duplicate check before insert via `_CHECK_DUPLICATE_SQL` (line 196-212) — uses parameterized `IS NOT NULL AND column = :param` pattern — CORRECT handling of NULL-equality semantics
- `create_device` reloads via `fetch_device` after commit — ensures caller sees persisted state (line 234-237)
- Soft-delete uses `RETURNING id` to confirm row affected (line 244-248)
- `AdminDeviceResponse.model_validate(dict(row))` — Pydantic guards shape

**sim_admin_service (mostly solid):**
- `activate_device` is 2-step: step 1 deactivate other user's devices, step 2 activate target. Both trong cung session -> atomic on commit (line 180-230)
- `find_user_by_email` normalizes via `email.strip().lower()` + `lower(email) =` in WHERE — consistent case-folding
- `update_heartbeat` rolls back on Exception + logs WARNING (line 275-300) — non-raising per docstring contract
- `list_active_devices` queries id-list then fetches detail per ID — N+1 pattern (line 302-316), flagged Performance

**Minor concerns:**
- `db.py` line 52-58: Pool config `pool_size=3, max_overflow=5` -> max 8 concurrent connections. If simulator-web makes burst requests (list devices x 10 tabs) + IoT sim background heartbeat -> pool saturation possible. No documentation of why 3 was chosen.
- `DeviceRepository.create_device` uses `_norm_str = lambda v: ...` inline lambda (line 195) — pointless nested def. Replace with named helper or inline expression.
- `activate_device` line 215-226 raises `ValueError` BEFORE rollback call — if caller catches ValueError, session stays dirty with uncommitted updates from line 201-211. Callers must rollback explicitly.
- `list_active_devices` line 302: `"SELECT id FROM devices"` uses concat inline (line 305-306) — not f-string concat (it's string literal concat `"a" "b"`) -> STILL SAFE, but visual pattern ambiguity.

### Readability (3/3)

**Strengths:**
- SQL extracted to module-level constants at top of `device_repository.py` (line 30-111) — reader sees all queries in one place before reading methods
- Consistent comment blocks: `# SQL constants`, `# Read`, `# Write`, `# ... cache`
- Variable names domain-specific: `normalized_mqtt`, `bound_db_device_id`, `sim_id`, `admin_list_cache_lock`
- Docstrings precise: "Soft-delete a device. Returns True if a row was affected." (line 242)
- HIGH #4 fix comment (line 32, 52) explains WHY `_DEVICE_DETAIL_SQL` removed from SimAdminService (delegated to repo)
- "Removed dead code" notes (line 33-34) — audit trail of dead code removal

**Function sizes:**
- All methods under 50 LoC. `DeviceRepository.create_device` (42 LoC) longest — mixes validation + dup-check + insert + reload. Could split but readable as-is.

**Concerns:**
- `SimAdminService.find_user_by_email` staticmethod vs classmethod inconsistency: cache-related methods (`invalidate_admin_list_cache`, `list_admin_devices`) are `classmethod`, CRUD ones are `staticmethod` — minor, reflects stateful cache vs stateless query.
- Comment "HIGH #4 fix: removed duplicate _DEVICE_DETAIL_SQL" (line 32-34) references fix number without pointer to origin bug/commit. Future reader can't trace.

### Architecture (2/3)

**Positive:**
- Repository pattern correctly introduced — `DeviceRepository` owns SQL, returns Pydantic
- Session injected per method (no global session) — thread-safe
- `session_scope()` context mgr separates request-scoped (`get_db()`) from background-scoped (runtime heartbeat)
- Delegation pattern: `SimAdminService.delete_device` -> `DeviceRepository.delete_device` — SimAdminService adds cache invalidation, repo does pure DB op

**Concerns:**

1. **Half-migrated repository pattern:** 
   - `DeviceRepository.fetch/list/create/delete` delegated from SimAdminService OK
   - BUT `SimAdminService.list_all_devices` (line 55-99) — 45 LoC raw SQL, NOT in DeviceRepository. Why? Uses `user_id` filter — could easily extend repo.
   - `SimAdminService.assign_device` / `activate_device` / `deactivate_device` — UPDATE flows, NOT in repo.
   - `SimAdminService.find_user_by_email` — queries `users` table, needs `UserRepository` that doesn't exist.
   - `SimAdminService.update_heartbeat` — UPDATE flow, inline SQL.
   
   **Pattern drift:** Repository only covers happy-path reads + simple inserts. Complex UPDATE flows stay in service = inconsistent. Either: complete migration (Phase 3 task) OR document decision "repo for CRUD, service for business UPDATE flows" in ADR.

2. **Empty `repositories/__init__.py`** (0 bytes) — no re-exports. Callers import `from api_server.repositories.device_repository import DeviceRepository` directly. Works, but convention is `from api_server.repositories import DeviceRepository`. Minor.

3. **Engine singleton via module globals** (`_engine`, `_SessionLocal`):
   - Thread-safety of `_init_db()` not explicit — if 2 threads call `get_session_factory()` concurrently during startup, double-init possible. SQLAlchemy create_engine is idempotent safe but sessionmaker replacement could race.
   - Acceptable for single-process ASGI but document limitation.

4. **`_admin_list_cache` pattern:**
   - Class-level mutable state (`_admin_list_cache_rows: tuple[...] | None = None`, `_admin_list_cache_expires_at = 0.0`) — shared across instances (there's only 1 SimAdminService but pattern is fragile).
   - RLock (`_admin_list_cache_lock`) acquires twice in `list_admin_devices` (first for read, second for write). If 2 requests race past read-check both miss cache -> both query DB -> last-writer-wins cache. Minor wasted work.
   - No cache-invalidation on `update_heartbeat` — battery_level / signal_strength updates don't bust list cache. Fine if UI doesn't need fresh heartbeat data via admin list.

5. **`DeviceRepository` is static methods only.** Stateless -> OK. But test doubles must monkeypatch at class level, not substitute instance. For future richer repo (user/session) consider instance pattern.

### Security (3/3)

**Parameterized queries 100%:**
- `DeviceRepository`: 5 queries, all use `text() + :param` bind vars
- `SimAdminService`: 7 queries, all parameterized
- No f-string SQL, no `.format()` SQL, no `%` SQL
- `list_active_devices` uses `"SELECT id FROM devices WHERE is_active = TRUE"` — static literal, no user input

**Email handling:**
- `find_user_by_email` normalizes `email.strip().lower()` + SQL compares `lower(email) = :email` — case-insensitive + LDAP-injection-safe (SQL bind)

**Soft-delete discipline:**
- ALL queries include `AND deleted_at IS NULL` — prevents accidental read of soft-deleted rows
- Create/update include `updated_at = NOW()` — auditability baseline

**Env handling:**
- `DATABASE_URL` env-driven, dual `.env` search via `python-dotenv`
- Fail-fast `RuntimeError` if URL missing — prevents silent fallback to default credential

**Transaction discipline:**
- `session_scope()` wraps rollback on exception
- Explicit `db.rollback()` calls in DeviceRepository methods when row not returned
- `update_heartbeat` catches Exception + rollback + log — non-raising by contract

**Minor concerns:**
- `update_heartbeat` line 276-299: `except Exception: logger.warning(...); db.rollback()` — broad exception. If `db.rollback()` itself raises (extremely rare), re-raises unhandled. Acceptable.
- No audit log for admin ops (activate/deactivate/assign) — steering 40 requires "every PHI access logged". Activate/deactivate flow mutates `devices.user_id` (PII link) — missing audit log. Flag for Phase 4 (not strictly M04 scope since audit infra is cross-cutting).

### Performance (2/3)

**Strengths:**
- Connection pool via `pool_pre_ping=True` -> handles dropped connections
- `LIMIT 200` on admin list prevents unbounded query
- `_admin_list_cache` 30s TTL reduces DB load for frequent admin panel polls
- Single-row `RETURNING id` for UPDATE flows -> no extra SELECT round-trip

**Concerns:**

1. **`list_active_devices` N+1 query:**
   ```python
   rows = db.execute(text("SELECT id FROM devices WHERE is_active=TRUE...")).mappings().all()
   for row in rows:
       info = SimAdminService._fetch_device(int(row["id"]), db)   # N+1
   ```
   
   If 50 active devices -> 51 queries. Should replace with JOIN on `list_all_devices` equivalent filtered by `is_active=TRUE`. **P1 Phase 4 fix**.

2. **Pool size too small?** `pool_size=3, max_overflow=5` -> max 8 concurrent. If (a) admin UI polls list every 5s + (b) IoT sim has heartbeat thread + (c) request handlers overlap -> easy to hit 8 with 2-3 simultaneous users. No overflow timeout set -> default 30s wait. Consider bumping to `pool_size=10, max_overflow=20` for dev ergonomics.

3. **No indexes audit:**
   - `find_user_by_email` queries `WHERE lower(email) = :email` — requires `CREATE INDEX idx_users_email_lower ON users (lower(email))` to avoid seq scan. Em chua verify `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` has this.
   - `list_all_devices` ORDER BY `is_active DESC, registered_at DESC` — composite index recommended.
   - `_CHECK_DUPLICATE_SQL` WHERE on `serial_number` OR `mqtt_client_id` — need index on both.

4. **`_admin_list_cache` race condition:**
   - Thread A reads cache (miss), acquires lock, queries DB, releases lock
   - Thread B reads cache (miss during A's query), acquires lock (A released), queries DB again
   - Solution: double-check pattern inside write-lock. Minor, 30s window rare.

5. **`session_scope` creates new session per call** — no session reuse. Each call = 1 socket from pool. For bulk ops (`list_active_devices` loop), should pass single session instead of multiple `session_scope()` calls. Actual code does pass single session OK.

6. **No query timeout.** Long-running accidental query (e.g., missing WHERE) could hold connection. SQLAlchemy / psycopg2 default is no timeout. Consider `statement_timeout` DB session setting.

## New findings / bugs (not in BUGS INDEX)

### IS-008 (NEW, Medium) — `list_active_devices` N+1 query pattern

**Severity:** Medium
**Status:** Proposed (Phase 4)

**Summary:** `SimAdminService.list_active_devices` (line 302-316) executes `SELECT id` then calls `_fetch_device(id)` per row -> N+1 queries per request.

**Impact:** For 50 active devices = 51 DB roundtrips. Admin UI polls could saturate pool. Measurable latency at scale.

**Fix:** Add `DeviceRepository.list_admin_devices(db, is_active_only=True)` variant OR use `list_all_devices` with `is_active=TRUE` filter. Single query.

**Est:** 20 min.

### IS-009 (NEW, Low) — `activate_device` ValueError leaks uncommitted session

**Severity:** Low
**Status:** Proposed

**Summary:** `sim_admin_service.activate_device` line 215-226: if target has `user_id IS NULL`, raises `ValueError` WITHOUT rollback. Caller's session may have uncommitted state from prior queries in same session.

**Impact:** Depends on caller. Current caller (`M02.DeviceService.admin_activate_db_device`) catches exception chain up -> FastAPI returns 500 -> session closes -> rollback implicit. Low production risk.

**Fix:** Call `db.rollback()` before raising ValueError, OR wrap entire activate sequence in try/except.

**Est:** 5 min.

## Positive findings (transfer to other modules)

- **SQL constants extracted to module-level named vars** (device_repository line 30-111) — readable, searchable, diff-friendly. Apply to any future repo.
- **`RETURNING id` pattern on UPDATE/DELETE** — confirms row affected without extra SELECT. Idiomatic PostgreSQL.
- **Dual .env search path** (db.py line 18-26) — supports multiple project layouts without touching code. Useful for test vs runtime.
- **Delegation pattern service -> repository** — SimAdminService adds business concerns (cache invalidation), repo does pure data op. Clean separation when migrated fully.
- **Parameterized `:param IS NOT NULL AND column = :param`** (line 107-110) — correct NULL-aware dup check. Reuse pattern.
- **`session_scope` + `get_db` split** — request vs background DB access pattern. Apply to other repos.

## Recommended actions (Phase 4)

### P1 — Phase 4 recommended
- [ ] **IS-008 fix**: Eliminate N+1 in `list_active_devices`. Add `DeviceRepository.list_admin_devices(db, active_only=True)` or modify existing filter.
- [ ] Verify + add indexes: `idx_users_email_lower`, `idx_devices_active_registered`, `idx_devices_serial_mqtt`. Cross-check with `init_full_setup.sql`.
- [ ] Bump pool config: `pool_size=10, max_overflow=20` (document rationale in db.py docstring).
- [ ] Complete repository migration: move `assign_device`, `activate_device`, `deactivate_device`, `update_heartbeat` into DeviceRepository (Phase 3 refactor task candidate).

### P2 — Phase 5+ or defer
- [ ] **IS-009 fix**: Rollback before raise ValueError in activate_device.
- [ ] Create `UserRepository` for `find_user_by_email` — currently lives in SimAdminService, violates repo pattern.
- [ ] Populate `repositories/__init__.py` with re-exports for ergonomic imports.
- [ ] Add audit log middleware for admin ops (activate/deactivate/assign) per steering 40.
- [ ] Add query timeout via `connect_args={"options": "-c statement_timeout=5000"}`.
- [ ] Thread-safe `_init_db` via double-check lock (defensive).
- [ ] Document `pool_size` rationale in `db.py` docstring.

## Out of scope (defer Phase 3 deep-dive)

- **Full repository migration** for all sim_admin_service UPDATE flows — restructure task, not macro audit.
- DB schema audit for referenced tables (`users`, `devices`, `vitals`) — cross-repo schema owned by `PM_REVIEW/SQL SCRIPTS/` + Prisma.
- Test coverage matrix for DB access layer.
- Deadlock analysis under concurrent admin ops.

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Inventory: [M04 entry](../../module_inventory/05_iot_simulator.md#m04-api_serverrepositories--db)
- Related modules: [M02 services](./M02_services_audit.md) (consumer), [M05 backend clients](./M05_backend_clients_audit.md) (SimAdminService client-side)
- Canonical schema: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` — need index verification
- Cross-repo: Prisma schema at `HealthGuard/backend/prisma/schema.prisma` (owns `users` + `devices` tables shared)
- Related bugs: HS-001 (devices schema drift), HS-002 (cross-user MAC bypass) — BOTH involve `devices` table schema, M04 consumes this schema
