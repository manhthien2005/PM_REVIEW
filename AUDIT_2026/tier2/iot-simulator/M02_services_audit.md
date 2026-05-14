# Audit: M02 — api_server/services/

**Module:** `Iot_Simulator_clean/api_server/services/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 1 Track 5 Pass B — IoT sim core business logic

## Scope

Service layer extracted from SimulatorRuntime God Object (comment nêu rõ "Task 3.x extraction").

| File | LoC | Role |
|---|---|---|
| `__init__.py` | 10 | Public exports |
| `alert_service.py` | 234 | Alert push (retry + backoff), event recording, event history deque |
| `device_service.py` | 408 | Device CRUD, bind/unbind, DB-device lifecycle (activate/deactivate/delete) |
| `session_service.py` | 213 | Session CRUD + lifecycle (create/list/start/stop) |
| `sleep_service.py` | 1,315 | Sleep session construction, AI scoring, sleep backend push, phase advancement, backfill |
| `vitals_service.py` | 245 | Vitals retrieval, BP staleness, severity classification |
| **Total** | **~2,425** | |

**Excluded:** Service callers (routers → audited in M01) + `dependencies.py` (M03) + orchestration layer in `runtime_state.py` / `dependencies.py`.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Good error handling in alert_service; broad `except Exception` in sleep helpers; retry logic solid; dual import anti-pattern risk. |
| Readability | 2/3 | `sleep_service.py` 1,315 LoC = way over 500 split threshold; naming clear; module docstrings ok. |
| Architecture | 2/3 | Extraction from God Object is net-positive nhưng services share mutable state via injected refs -> still tight coupling; SleepService holds module-level globals. |
| Security | 1/3 | D-021 confirmed: `_push_sleep_to_backend` sends NO auth headers to `/mobile/telemetry/sleep`; no input trust boundary between services and raw payload dicts. |
| Performance | 2/3 | CRITICAL #2 fix (shared httpx.Client) applied in SleepService; alert push thread pool; `sleep_service._sleep_history_from_registry` uses `_random.sample` full pool iter. |
| **Total** | **9/15** | Band: **Needs attention** |

## Findings

### Correctness (2/3)

**alert_service.py (strong):**
- Retry with exponential backoff 1/2/4s (`_ALERT_PUSH_BACKOFF_BASE = 1`, `2 ** (attempt - 1)`) — documented
- Dedicated `ThreadPoolExecutor(max_workers=2, thread_name_prefix="alert-push")` de khong block tick thread — comment "CRITICAL #1 fix"
- In-flight signature dedup via `_alert_pushes_in_flight` set + cooldown via `_last_alert_pushes` dict
- `finally`-style cleanup: `discard(signature)` in both success + failure branches
- `_prepare_alert_push_locked` returns `None` khi device chua bind -> upstream no-op
- HTTP sender status code check `200 <= status_code < 300` correctly handles 201/202/204

**session_service.py (ok):**
- `_require_session` raises `KeyError` — consistent with device
- `stop_session` reverts device state to `bound` or `bindable` dua tren `bound_db_device_id` — correct state machine
- Minor: `create_session` can `raise KeyError(f"subject_id=... not found")` nhung khong rollback partial `contexts` list — khong co cleanup (in-memory only, low risk)

**device_service.py (ok):**
- HIGH #6 fix cleanup tracker dicts on delete (sleep_phase_tracker, bp_last_observed, last_alert_pushes by device_id prefix) — good discipline
- `_ensure_sim_session_for_db_device` stops same-user other-device sessions TRUOC KHI create new session — correct exclusive policy
- Minor: `_find_sim_id_for_db_device` linear scan `self.devices.items()` — O(n) acceptable cho dev sim, but documented nowhere
- Risk: `admin_activate_db_device` returns `result` from admin client THEN calls `_ensure_sim_session_for_db_device` — if latter raises, admin DB state already mutated -> partial-failure chain not atomic

**sleep_service.py (weak areas):**
- Multiple broad `except Exception:` silently:
  - `_phase_minutes_from_segments` (line 197) — `except Exception: logger.warning(...); continue` for phase segment parse failure — acceptable (best-effort parsing)
  - `_select_session_for_scenario` filter_fn (line 950) — acceptable (defensive)
  - `_sleep_session_exists` (line 657-660) — swallows DB error, returns False -> silent failure: backfill may double-write if exists-check fails temporarily
  - `_resolve_bound_device_user_id` (line 687) — swallows -> returns None -> caller logs "no owner" even if DB just blipped
  - `_push_sleep_to_backend` (line 651-658) — catches all exc, logs `{exc}` to publish_device_log -> loses stack trace context
- Dual import path try/except in every file (`try: from Iot_Simulator.api_server... except ModuleNotFoundError: from api_server...`) -> cargo-cult fragility: if module raises `ModuleNotFoundError` for an unrelated nested import, fallback path masks real bug
- `_build_sleep_segments` generates segments sequentially from pattern with `_random.randint(0, 90)` for start offset — seed not controlled, non-deterministic for tests
- `_fallback_sleep_session` hardcodes magic numbers `score=84, efficiency=92.6, avgHeartRate=58.0, minSpo2=95.0` — same data every call, breaks variance expectations

**vitals_service.py (ok):**
- `to_vitals` handles `replay` vs `synthetic` mode distinction, provenance tracking, BP stale masking — thoughtful
- Dual threshold dict (`DAYTIME_THRESHOLDS` vs `SLEEP_THRESHOLDS`) based on `is_sleeping` — context-aware severity
- `fall_variant` override to force `critical` (line 102-104) — safety-critical fallback
- Minor: `latest_vitals` nested iteration `for record in sessions.values(): for payload in reversed(record.last_tick_outputs)` — returns FIRST match across all sessions -> if device in multiple sessions (shouldn't happen but possible), undefined order
- Dead config: `"osa_alert_spo2_threshold": 88.0`, `"nocturnal_tachy_hr": 120.0` defined in SLEEP_THRESHOLDS but grep scan shows NOT consumed trong `to_vitals`

### Readability (2/3)

**Strengths:**
- Module-level docstrings clearly state extraction task + thread safety contract
- `AlertService.__init__` explicitly names all shared state params — reader sees coupling surface
- Dual import comment explains WHY (line 4-9 pattern across all files) — good discipline
- Section headers `# --- ... ---` divide responsibilities in long files

**Concerns (per file):**

| File | LoC | Judgment |
|---|---|---|
| `sleep_service.py` | 1,315 | violates `File > 500 lines = split candidate` anti-pattern. Clearly doing 5-6 different things: window computation, scoring, AI record building, backend push, DB history, phase advancement. Split candidate priority P1. |
| `device_service.py` | 408 | Under 500 but CRUD + admin lifecycle + cache rebuild mixed — 2 responsibilities visible. Acceptable. |
| `alert_service.py` | 234 | Focused. |
| `session_service.py` | 213 | Focused. |
| `vitals_service.py` | 245 | Focused. |

**Sleep service function size:**
- `push_sleep_session_for_date` (line 890-1050) — approx 160 LoC function mixing: device-require -> summary build -> payload assemble -> HTTP push -> return dict. Violates "<= 50 lines" goal. Candidate for extraction (build_payload, post_payload, format_result).

**Naming:**
- `_compute_sleep_score_with_ai` vs `_calc_sleep_score` vs `_compute_sleep_score_from_summary` — 3 names for overlapping concept (redirects internally). Consolidate.
- `_run_session_side_effects_fn` param name has `_fn` suffix (callback) but stored as `self._run_session_side_effects` — inconsistency with other callbacks that drop `_fn`.
- `_alert_executor` (inst attr) vs `_alert_pushes_in_flight` (set) vs `_last_alert_pushes` (dict) — inconsistent naming pattern cho alert-related state.

**Dead-code concerns:**
- `SLEEP_THRESHOLDS["osa_alert_spo2_threshold"]` + `["nocturnal_tachy_hr"]` + `["apnea_rr_threshold"]` — defined but NOT consumed in `to_vitals` (em grep searched). Either dead config or feature-flagged elsewhere.
- Scenario defaults in `_build_sleep_ai_record` hardcoded per-scenario dict of 4 profiles (line 497-530 in sleep_service) — should be config/YAML, currently 100+ LoC inline constants.

### Architecture (2/3)

**Positive (extraction effort):**
- `SimulatorRuntime` God Object decomposition ongoing — 5 services cover Device, Vitals, Alert, Session, Sleep. Clear single-responsibility intent.
- Services accept injected callbacks for cross-service operations (`record_event_fn`, `publish_device_log_fn`, `http_sender`) — avoids direct service-to-service import
- `_RuntimeSessionOps` Protocol trong `device_service.py` + `set_runtime_session_ops()` post-init injection breaks circular dep between DeviceService + Runtime
- `dashboard_cache_ref` passed as 1-element list (mutable container) — idiomatic Python pattern for shared-mutable-reference

**Concerns:**

1. **Shared mutable state anti-pattern**: Every service receives the SAME dicts (`self.devices`, `self.sessions`) + SAME `RLock`. Services mutate each other's data through shared refs. True decomposition would own data + expose queries. Currently: data ownership diffuse, lock acquired redundantly, services form implicit graph.

2. **SleepService global mutation**: Lines 69-70 have module-level mutable globals `SLEEP_SCENARIO_PHASES: dict = {}` and `SLEEP_SCENARIO_PROFILES: dict = {}` populated from __init__. If 2 SleepService instances init with different scenarios, second overwrites first. Flag as risk if tests init multiple runtimes.

3. **_ensure_sim_session_for_db_device complexity**: Method (line 256-317 in device_service) crosses 3 layers: admin client -> session_scope DB query -> runtime session ops. Transaction boundary unclear — if session start fails after admin activate returned 200, state divergence between DB + sim. No compensating action.

4. **Cross-service callback wiring**: AlertService uses `telemetry_alert_endpoint_fn`, `http_sender`, `publish_device_log_fn` — 3 injected callables from `dependencies.py`. Means `dependencies.py` is the only place that knows all endpoints. This centralizes routing wiring nhung also means dependencies.py (already 3,266 LoC per M03 audit) becomes further bottleneck.

5. **Import style inconsistency** (light):
   - Module-level imports at top: all files
   - Deferred `from Iot_Simulator.api_server.dependencies import DeviceRecord` INSIDE methods (e.g. `_prepare_alert_push_locked`, `_record_event`, `delete_device`) — breaks mental model, happens 8+ times across services. Justified as "avoid circular import" but signals dependencies.py has taken on too many roles.

### Security (1/3)

**Critical: D-021 confirmed in code (scope: M02 owns the push path):**

`sleep_service.py` line 608-670 `_push_sleep_to_backend` + line 700-725 `_post_sleep_payload`:

```python
endpoint = f"{self._health_backend_url}/mobile/telemetry/sleep"
client = self._get_http_client()
resp = client.post(
    endpoint,
    content=_json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},   # <- ONLY Content-Type
)
```

- NO `X-Internal-Service` header
- NO `X-Internal-Secret` header (despite `alert_service` having `self._internal_secret` param + adding it to alert pushes)
- Endpoint is a mobile user-facing route (`/mobile/telemetry/sleep`) per steering topology. Either:
  - (a) backend accepts from IoT sim without auth -> HS-004-style leak (confirmed open per BUGS INDEX), OR
  - (b) backend rejects IoT sim sleep pushes silently -> feature broken

AlertService line 138-145 DOES add internal headers:

```python
_iot_headers: dict[str, str] = {"X-Internal-Service": "iot-simulator"}
if self._internal_secret:
    _iot_headers["X-Internal-Secret"] = self._internal_secret
```

SleepService does NOT. Drift between services.

**Other security findings:**

- `_push_sleep_to_backend` logs `f"Sleep push failed: {exc}"` to `publish_device_log` — exception might contain URL with credentials or stack-leak in production. Current dev URLs are local nhung production risk.
- `_post_sleep_payload` parses backend response body via `_json.loads(raw_body)` and uses `errors` field directly in raised `RuntimeError` — if backend leaks PHI/internal IDs in error payload, gets rethrown to caller + potentially logged. Minor.
- Raw SQL in SleepService uses parameterized `text()` — no SQL injection (`:user_id`, `:device_id`, `:sleep_date`, `:cutoff_date` all bound).
- No eval/exec, no hardcoded secrets, no CORS issue (out-of-scope for services).
- AlertService uses cooldown + in-flight dedup -> resists inadvertent DoS on backend.

### Performance (2/3)

**Strengths:**
- `SleepService._get_http_client` lazy init + reuse: `if self._http_client is None or self._http_client.is_closed: self._http_client = httpx.Client(timeout=5)` — fixes CRITICAL #2 (per comment)
- AlertService `ThreadPoolExecutor(max_workers=2)` isolates retry sleep(delay) from tick thread
- AlertService cooldown `max(float(self._push_interval), 10.0)` prevents alert flood — good rate limiter
- `recent_events(limit=10)` slices deque at query time — O(k) not O(n)
- VitalsService `latest_vitals` iterates `reversed(record.last_tick_outputs)` -> returns most recent first -> O(1) for hot path

**Concerns:**

- `_rebuild_db_device_active_cache_locked` called on bind/unbind/delete — does full rebuild `for record in sessions.values(): for sim_id in record.device_ids:` — O(sessions x device_per_session). For dev sim fine; if >100 active sessions it becomes measurable. Incremental update possible.
- `_sleep_history_from_registry` line 1060 uses `_random.sample(all_sessions, sample_size)` — creates full list copy `list(getattr(self.registry, "_sleep_sessions", []) or [])`. If registry caches thousands of sessions, copies all. Acceptable if registry < 10k entries.
- `sleep_db_history` LIMIT 90 + per-row coerce loop creates DbSleepHistoryRow Pydantic models in Python — for 90 rows fine. Good.
- SleepService `_get_http_client` timeout=5 fixed — NOT parameterized. Sleep push can be slow on cold backend startup; 5s might cause false failures in test env.
- AlertService uses `_http_sender` CALLBACK (sync) — means alert push stack path is sync-only. If tick thread runs alerts, bottleneck. Mitigated by ThreadPoolExecutor.
- Dashboard cache invalidation (line 193 `if self._dashboard_cache_ref: self._dashboard_cache_ref[0] = None`) — correct pattern, prevents stale reads.

## New findings / bugs (not in BUGS INDEX)

### IS-002 (NEW) — SleepService `_push_sleep_to_backend` missing internal auth headers

**Severity:** Critical
**Status:** Proposed (draft — anh decide open ngay hay defer)

**Summary:** `sleep_service.py` sends sleep session pushes to `/mobile/telemetry/sleep` with ONLY `Content-Type` header. AlertService same-flow adds `X-Internal-Service` + `X-Internal-Secret`. Inconsistent with ADR-005 (internal service auth strategy).

**Impact:** Either (a) backend must leave telemetry sleep endpoint open = HS-004 scope, or (b) feature silently broken. Either way, P0 fix.

**Fix:** Mirror `AlertService` pattern — accept `internal_secret` + inject via `_iot_headers` dict to both `_push_sleep_to_backend` + `_post_sleep_payload`.

**Related:** HS-004 (BE missing auth), ADR-005 (internal secret).

### IS-003 (NEW) — `_sleep_session_exists` silent DB failure -> double-write risk

**Severity:** Medium
**Status:** Proposed

**Summary:** `except Exception: logger.warning(...); return False` in `_sleep_session_exists` (line 657-660). If DB transient fails, function returns `False` -> caller believes no existing session -> calls `_post_sleep_payload` which INSERTs -> duplicate rows possible.

**Fix:** Propagate DB error OR surface `None` + caller treats as "unknown, skip".

### IS-004 (NEW) — SleepService module-level globals `SLEEP_SCENARIO_PHASES` / `SLEEP_SCENARIO_PROFILES`

**Severity:** Low (scope-limited — only 1 runtime today)
**Status:** Proposed (defer)

**Summary:** Module-level dicts populated on __init__. Second instance overwrites. Not thread-safe. Per test with patched scenarios, state leaks.

**Fix:** Move to instance attributes `self._scenario_phases` / `self._scenario_profiles`. Remove `global` declaration.

## Positive findings (transfer to other modules)

- **Callback injection pattern** (all services) — avoids circular deps, clean DI boundary. Apply to remaining extractions in dependencies.py.
- **Protocol class `_RuntimeSessionOps`** (device_service) — correct Python solution for "depend on subset of a larger interface". Reusable pattern.
- **`dashboard_cache_ref` mutable container trick** — idiomatic Python for shared-mutable-reference without dedicated wrapper class.
- **Dual threshold dicts `DAYTIME_THRESHOLDS` / `SLEEP_THRESHOLDS`** in VitalsService — context-aware decision logic. Similar pattern might apply to `pre_model_trigger/` rule engine (M07).
- **HIGH #6 fix cleanup discipline** in `DeviceService.delete_device` — explicit tracker/observation dict cleanup. Documents what state existed.
- **AlertService retry + cooldown + in-flight dedup** triple safeguard — reference implementation for future push paths. Sleep push should inherit.

## Recommended actions (Phase 4)

### P0 — blocks Phase 4 release
- [ ] **IS-002 fix**: Add `X-Internal-Service` + `X-Internal-Secret` headers to `_push_sleep_to_backend` + `_post_sleep_payload`. Coordinate with HS-004 fix (BE side enforcement).
- [ ] **IS-003 fix**: Stop silent `return False` in `_sleep_session_exists`. Either raise or return sentinel.

### P1 — recommended for Phase 4
- [ ] Split `sleep_service.py` (1,315 LoC) -> Phase 3 deep-dive. Candidate carve: `sleep_window.py` (window/phase helpers), `sleep_scoring.py` (score + AI integration), `sleep_push.py` (backend push), `sleep_history.py` (DB history). Keep `SleepService` as facade.
- [ ] Extract `sleep_service._build_sleep_ai_record` scenario_defaults dict -> config YAML (reuse pattern of `sleep_scenarios.yaml` already in `api_server/config/`).
- [ ] Unify sleep score computation: pick one of `_calc_sleep_score` / `_compute_sleep_score_from_summary` / `_compute_sleep_score_with_ai` -> delete other callsite wrappers.
- [ ] Remove dead threshold keys `osa_alert_spo2_threshold`, `nocturnal_tachy_hr`, `apnea_rr_threshold` from SLEEP_THRESHOLDS or implement their consumer in `to_vitals`.

### P2 — Phase 5+ or defer
- [ ] **IS-004 fix**: Move SLEEP_SCENARIO_PHASES/PROFILES from module global -> instance attr.
- [ ] Narrow broad `except Exception:` sites in `sleep_service.py` to specific exc types (sqlalchemy.exc, httpx.HTTPError, ValueError).
- [ ] Replace deferred-inside-method imports (`delete_device`, `_prepare_alert_push_locked`, etc.) with top-of-file imports once dependencies.py split resolves circular risk (Phase 3 deep-dive on dependencies.py).
- [ ] Parameterize `SleepService._get_http_client` timeout (pass via `__init__`).
- [ ] Eliminate `_build_sleep_segments` non-deterministic `_random.randint` — accept seeded RNG injection.

## Out of scope (defer Phase 3 deep-dive)

- **sleep_service.py line-by-line** rewrite — too large for macro audit, needs its own Phase 3 work item.
- Transaction boundary audit for `_ensure_sim_session_for_db_device` / `admin_activate_db_device` (atomic fail-safe).
- Test coverage matrix (separate report).
- SleepService scenario default heuristic accuracy (domain-specific, needs medical input).

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Inventory: [M02 entry](../../module_inventory/05_iot_simulator.md#m02-api_serverservices--sim-runtime-business-logic)
- Related modules: [M01 routers audit](./M01_routers_audit.md), [M03 middleware+deps audit](./M03_middleware_dependencies_audit.md), [M05 backend clients audit](./M05_backend_clients_audit.md)
- Open bug: [HS-004](../../../BUGS/HS-004-telemetry-sleep-endpoints-no-auth.md) (BE-side mirror of IS-002)
- ADR: [ADR-005 internal-service-secret-strategy](../../../ADR/005-internal-service-secret-strategy.md) — IS-002 violates this
- Intent drift: [iot_simulator_clean/](../../tier1.5/intent_drift/iot_simulator_clean/) — re-check if SLEEP scope changes modify M02 responsibilities
