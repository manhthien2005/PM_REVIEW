# Bug IS-010: HttpPublisher không tự inject X-Internal-Service header (caller-owned)

**Status:** Open
**Repo(s):** Iot_Simulator_clean (transport)
**Module:** transport/http_publisher
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M08)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`transport.HttpPublisher.__init__(endpoint, sender, headers)` nhan `headers: dict[str, str] | None = None`. Caller phai tu build dict `{"X-Internal-Service": "iot-simulator", "X-Internal-Secret": <env>}` moi khi khoi tao publisher. Khong co safety net neu caller quen.

Inconsistent voi reference pattern trong `pre_model_trigger/healthguard_client.py` + `mobile_telemetry_client.py`: 2 client do tu inject headers tu `internal_secret` param.

## Repro steps

1. Tao `HttpPublisher("http://backend/endpoint")` khong pass `headers`
2. Publisher goi `_default_sender(endpoint, payload)` voi `headers=None`
3. Merged headers = `{"Content-Type": "application/json"}` — missing auth
4. Backend nhan unauthenticated POST

**Expected:** Neu `internal_secret` duoc config o ENV, publisher tu inject headers ma khong can caller remember.

**Actual:** Caller must remember. Silent if forgot.

**Repro rate:** 100% deterministic khi caller khong pass headers.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/transport/http_publisher.py` line 14-32

## Root cause

### File: `http_publisher.py:14-32`

```python
class HttpPublisher(Publisher):
    mode = "http"

    def __init__(
        self,
        endpoint: str,
        *,
        sender: Callable[[str, str], int] | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        self.endpoint = endpoint
        self._sender = sender or self._default_sender
        self._headers: dict[str, str] = headers or {}
```

Constructor doesn't accept `internal_secret` or equivalent. Caller owns all auth concerns.

### Contrast: `pre_model_trigger/healthguard_client.py:94-99`

```python
headers: dict[str, str] = {
    "Content-Type": "application/json",
    "X-Internal-Service": "iot-simulator",
}
if self._internal_secret:
    headers["X-Internal-Secret"] = self._internal_secret
```

Client owns header injection, caller passes `internal_secret` once at init.

## Impact

**Current dev usage:** No known incidents. Callers in `api_server/dependencies.py` likely pass headers explicitly. Em chua grep verify.

**Future risk:**
- New caller forgets header -> unauthenticated POST silently
- Backend-side enforcement (HS-004 Phase 4) rejects -> HTTP 403 -> publisher returns PublishResult(ok=False) -> upstream caller may swallow
- Test doubles skip auth concerns -> production flow untested

**Severity Low:** Current callers work. Pattern fragile for future.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | HttpPublisher was written before ADR-005 internal-secret strategy | Likely — pre-May 2026 initial design |
| H2 | Caller always remembers to pass headers | Assumed but not verified — grep dependencies.py needed |
| H3 | Pattern inconsistency is intentional (transport layer "dumb pipe") | Reject — M07 clients use same transport role and inject |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 5 hygiene)_

**Fix approach (planned):**

```python
class HttpPublisher(Publisher):
    mode = "http"

    def __init__(
        self,
        endpoint: str,
        *,
        sender: Callable[[str, str], int] | None = None,
        headers: dict[str, str] | None = None,
        internal_secret: str | None = None,   # <-- ADD
    ) -> None:
        self.endpoint = endpoint
        self._sender = sender or self._default_sender
        merged: dict[str, str] = {"X-Internal-Service": "iot-simulator"}
        if internal_secret:
            merged["X-Internal-Secret"] = internal_secret
        if headers:
            merged.update(headers)
        self._headers = merged
```

Update caller in `dependencies.py` to pass `internal_secret=settings.INTERNAL_SERVICE_SECRET`.

**Fix scope summary:** ~8 LoC change trong 2 file. Est 15 min.

**Test added (planned):**
- `test_http_publisher.py::test_auto_injects_x_internal_service_header`
- `test_http_publisher.py::test_injects_internal_secret_when_provided`
- `test_http_publisher.py::test_caller_headers_can_override_defaults`

**Verification:**
1. Unit tests green
2. Grep caller usage — confirm all HttpPublisher instantiation pass `internal_secret` or inherit default
3. Manual: send test POST, inspect headers

## Related

- **Parent audit:** [M08 transport audit](../AUDIT_2026/tier2/iot-simulator/M08_transport_audit.md)
- **Reference pattern:** [M07 healthguard_client](../AUDIT_2026/tier2/iot-simulator/M07_pre_model_trigger_audit.md) line 94-99
- **Related bug (same root):** [IS-002](./IS-002-sleep-service-missing-internal-auth-headers.md)
- **ADR:** [ADR-005 internal-service-secret-strategy](../ADR/005-internal-service-secret-strategy.md)

## Notes

- Low priority (no known production incident)
- Batch voi IS-002 trong unified "internal auth header consistency" PR
- Transport layer should be "secure by default"; current design delegates to caller
