# Audit: M08 — transport/

**Module:** `Iot_Simulator_clean/transport/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Kiro)
**Framework version:** v1
**Track:** Phase 1 Track 5 Pass C — IoT sim transport layer

## Scope

Publisher abstraction (HTTP / MQTT) + router for runtime message dispatch. Small surface area.

| File | LoC | Role |
|---|---|---|
| `__init__.py` | 14 | Public exports |
| `base_publisher.py` | 22 | Abstract `Publisher` + `PublishResult` dataclass |
| `http_publisher.py` | 70 | HTTP POST publisher with injectable sender |
| `mqtt_publisher.py` | 127 | MQTT publisher via paho-mqtt (optional dep) |
| `json_utils.py` | 20 | Safe JSON dumps for datetime/ndarray fallback |
| `router.py` | 38 | MQTT-primary / HTTP-fallback routing |
| **Total** | **~290** | |

**Excluded:** Consumers (dependencies.py tick loop), test doubles.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Result object propagates full context (ok/count/ack/error); MQTT optional dep handled with explicit fallback; HTTP sender injectable. |
| Readability | 3/3 | Small files, focused classes, dataclass for result. |
| Architecture | 3/3 | Clean ABC + 2 concretes; router decides fallback; injectable sender for testing. |
| Security | 2/3 | HTTP sender accepts arbitrary headers from caller but no built-in secret injection (caller must pass); MQTT no TLS config visible. |
| Performance | 2/3 | `connect_async` + `loop_start` OK; no connection pooling for HTTP (1 urlopen per batch); no retry logic in publishers. |
| **Total** | **13/15** | Band: **Mature** |

## Findings

### Correctness (3/3)

- `PublishResult` dataclass carries full context (ok, transport_mode, target, message_count, ack_count, error) — caller decides action based on fields
- `HttpPublisher._default_sender` catches `HTTPError` and returns status code — exception-safe
- `MqttPublisher` handles 3 states: publish callback injected / mqtt module missing / client unavailable — each returns structured PublishResult not crash
- `TransportRouter.publish`: MQTT primary; if fail -> HTTP fallback. RoutedPublishResult has both results for caller visibility
- `mode.strip().lower()` in router — defensive against whitespace/case
- JSON utils handles `datetime`, `date`, numpy `tolist`, `item()` — covers common serialization pitfalls

**Minor concerns:**
- `HttpPublisher.publish` line 24: `except Exception as exc:` broad catch with `pragma: no cover - network path` — acceptable for runtime but loses exception type info. Could narrow to `(urllib.error.URLError, TimeoutError, ConnectionError)`.
- `MqttPublisher` line 51-57: `except Exception as exc: self._connect_error = str(exc)` — swallows connect failure, subsequent `publish()` returns error from stored string. Good pattern.
- `MqttPublisher.publish` line 103: `getattr(result, "rc", 1) == 0` — duck-type check for paho MQTT publish result. If paho changes API (unlikely, stable lib), this breaks silently. Acceptable given pinned dep but document in comment.
- `TransportRouter.publish` only supports `mode="mqtt"` or `mode="http"`. Anything else silently treated as `mqtt` (default). Minor — doc the valid values.

### Readability (3/3)

- Module files all under 130 LoC
- Abstract base `Publisher` with `mode: str` class attr + `publish()` abstractmethod — clean contract
- `PublishResult` dataclass with clear field names
- `HttpPublisher.__init__` args have type annotations
- MQTT module-level `try: import paho.mqtt.client as mqtt except ImportError: mqtt = None` pattern — idiomatic for optional dep

**Concerns:**
- `MqttPublisher.__init__` has 9 params — boundary of acceptable. Most have defaults. Split into config dataclass maybe overkill for this simple surface.
- `json_utils._json_default` has 3 isinstance branches + 2 hasattr branches + fallback `str(value)`. Last fallback loses type info silently. Document or raise.

### Architecture (3/3)

- ABC + 2 concrete impls is textbook Strategy pattern — clean
- `sender: Callable[[str, str], int] | None = None` injection in HttpPublisher — trivial test double
- `client: Callable[[str, str], bool] | None = None` similarly in MqttPublisher for tests
- `TransportRouter` composition over inheritance — correct
- Optional dep `paho.mqtt` + `pandas`/`pyarrow` (per artifact_writer M09 pattern) both use `try: import; except: = None` idiom

**Minor concern:**
- `json_utils` is tiny stand-alone module. Could be inline utility in publishers if not reused elsewhere. Grep shows consumption: `http_publisher`, `mqtt_publisher`. If widely used, justify separate module; if only transport, inline.

### Security (2/3)

**Positives:**
- No hardcoded credentials
- No `verify=False` for HTTPS (uses default urllib verification)
- `HttpPublisher` `headers={}` default — caller provides auth headers explicitly
- MQTT default port 1883 (unencrypted) — dev-friendly. TLS config absent = production-unready BUT within dev-sim scope.

**Concerns:**

1. **HTTP sender header passthrough:** caller must know to add `X-Internal-Service` + `X-Internal-Secret`. If consumer forgets, publisher sends unauthenticated. No safety net.
   - Reference good pattern: `pre_model_trigger/healthguard_client.py` adds headers itself via `internal_secret` param.
   - Consider: `HttpPublisher` accepts `internal_secret: str | None` + auto-injects, mirror M07 pattern.

2. **MQTT no TLS:** `host/port/keepalive` config but no `tls_set()` call. Production MQTT should use mTLS. Currently dev sim only, acceptable. Flag for Phase 4 deployment.

3. **MQTT no username/password auth:** `client_factory` defaults to `paho.mqtt.client.Client()` — no auth. Any network peer can publish. Dev-only.

4. **JSON fallback `str(value)`** — if value is an object with `__str__` that includes secrets (unlikely but possible custom type), serialized into payload. Low risk.

### Performance (2/3)

**Positives:**
- MQTT `connect_async` + `loop_start` — non-blocking connect
- HTTP `urlopen(request, timeout=10)` — explicit timeout

**Concerns:**

1. **`urllib.request.urlopen` per batch**: no keep-alive, no connection pool. Each publish = new TCP connection. Contrast with `pre_model_trigger/mobile_telemetry_client` using `httpx.Client` (pool-aware) + `api_server/backend_admin_client` sharing `httpx.Client` singleton. Drift: transport layer uses stdlib lower-level API.

2. **No retry logic in publishers**: single attempt, fail on first error. `AlertService` in M02 has retry+backoff — similar push flow but here no retries. If HTTP backend transient hiccup, messages lost.

3. **MQTT QoS default = 0** (`qos: int = 0`). QoS 0 = fire-and-forget, no delivery guarantee. For telemetry sync from IoT sim -> broker this may be OK (messages replayable from sim) but doc the choice.

4. **No batch size limit in HTTP publisher**: `publish(messages=[...])` sends entire list in one payload. If 10k messages queued, 1 huge POST. Should chunk or enforce upstream caller-side chunking.

5. **`json_utils` fallback check order**: `hasattr(value, "tolist")` before `hasattr(value, "item")` — numpy arrays prefer tolist. Datetime isinstance first. Reasonable order; micro-opt only.

## New findings / bugs

### IS-010 (NEW, Low) — HttpPublisher no auto internal-secret injection

**Severity:** Low (caller bears responsibility currently)
**Status:** Proposed (Phase 4/5 enhancement)

**Summary:** `HttpPublisher.__init__(endpoint, sender, headers)` passes headers through. Caller must remember to set `X-Internal-Service` + `X-Internal-Secret`. M02 AlertService adds them but M08 infrastructure doesn't enforce. Mirror issue to IS-002 (different file).

**Fix:** Add `internal_secret: str | None = None` param, auto-inject alongside `X-Internal-Service` if set.

**Est:** 10 min.

### IS-011 (NEW, Low) — HttpPublisher no retry logic

**Severity:** Low
**Status:** Proposed (Phase 5 enhancement)

**Summary:** HTTP publisher single-attempt per batch. Transient errors = message loss.

**Fix:** Mirror `AlertService._ALERT_PUSH_MAX_RETRIES` pattern — 3 attempts with 1/2/4s backoff. Or accept upstream caller handles retry (current assumption).

**Est:** 20 min.

## Positive findings

- **Injectable sender callback** (`sender: Callable[...]`) — trivial test double pattern. Reuse for future transport types.
- **PublishResult dataclass** — structured result > bare bool. Apply to other return shapes.
- **Optional dep pattern** (`try: import paho; except: mqtt = None`) — clean degradation. Used also in `etl_pipeline/artifact_writer.py` for pandas/pyarrow.
- **Duck-type check `getattr(result, "rc", 1)`** — defensive against paho API changes.
- **Router fallback pattern**: MQTT primary + HTTP fallback in `TransportRouter.publish`. Resilient dispatch.

## Recommended actions (Phase 4)

### P1
- [ ] **IS-010 fix**: Add `internal_secret` param to HttpPublisher. Auto-inject headers.

### P2
- [ ] **IS-011 fix**: Add retry with backoff to HttpPublisher (mirror AlertService pattern).
- [ ] Consider migrating urllib.request -> httpx.Client for connection pooling consistency.
- [ ] Add MQTT TLS config options (Phase 4 pre-deployment).
- [ ] Narrow `except Exception` in HttpPublisher to specific URLError types.
- [ ] Document MQTT QoS=0 choice in publisher docstring.

## Out of scope (defer)

- Backpressure mechanism for large batches.
- Dead-letter queue for failed messages.
- Transport-level encryption (mTLS) — deployment concern.
- Message ordering guarantees.

## Cross-references

- Framework: [00_audit_framework.md](../../00_audit_framework.md) v1
- Inventory: [M08 entry](../../module_inventory/05_iot_simulator.md#m08-transport--publisher)
- Reference for IS-010 fix: `pre_model_trigger/healthguard_client.py` (M07) — auto-injects headers
- Reference for IS-011 fix: `api_server/services/alert_service.py` (M02) — retry+backoff pattern
