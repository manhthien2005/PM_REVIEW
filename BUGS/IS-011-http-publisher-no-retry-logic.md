# Bug IS-011: HttpPublisher không có retry logic cho transient failure

**Status:** Open
**Repo(s):** Iot_Simulator_clean (transport)
**Module:** transport/http_publisher
**Severity:** Low
**Reporter:** ThienPDM (self) — surfaced trong Phase 1 Track 5 Pass C audit (M08)
**Created:** 2026-05-13
**Resolved:** _(dien khi resolve)_

## Symptom

`HttpPublisher.publish(messages)` thuc hien 1 attempt POST. Neu fail (network blip, backend restart, timeout), return `PublishResult(ok=False, error=...)` ngay. Messages bi mat trong transient window.

Drift voi `AlertService._push_alert_to_backend` (M02) = retry 3 lan voi exponential backoff (1/2/4s).

## Repro steps

1. Start IoT sim, HttpPublisher targets `http://localhost:8000/ingest`
2. Kill backend tam thoi giua 2 tick
3. Publisher attempts POST -> `ConnectionRefusedError`
4. `publish()` return `PublishResult(ok=False, error="Connection refused", ack_count=0)`
5. Upstream caller (dependencies.py tick loop) can handle or drop
6. Messages cua tick do bi mat (khong buffer, khong retry)

**Expected:** 3 attempts with backoff, backend restart within retry window -> success on attempt 2 or 3.

**Actual:** Single attempt, immediate give-up.

**Repro rate:** 100% cho transient network fail scenarios.

## Environment

- Repo: `Iot_Simulator_clean@develop`
- File: `Iot_Simulator_clean/transport/http_publisher.py` line 21-42

## Root cause

### File: `http_publisher.py:21-42`

```python
def publish(self, messages: list[dict[str, Any]]) -> PublishResult:
    payload = json_dumps({"messages": messages})
    try:
        if self._headers:
            status_code = self._sender(self.endpoint, payload, self._headers)
        else:
            status_code = self._sender(self.endpoint, payload)
    except Exception as exc:
        return PublishResult(
            ok=False,
            transport_mode=self.mode,
            target=self.endpoint,
            message_count=len(messages),
            error=str(exc),
        )
    # No retry loop — 1 attempt only
    ...
```

### Contrast: `alert_service.py:130-170` (correct retry pattern)

```python
_ALERT_PUSH_MAX_RETRIES = 3
_ALERT_PUSH_BACKOFF_BASE = 1  # seconds

for attempt in range(1, _ALERT_PUSH_MAX_RETRIES + 1):
    try:
        status_code = self._http_sender(endpoint, prepared.payload_json, _iot_headers)
        last_exc = None
        break
    except Exception as exc:
        last_exc = exc
        if attempt < _ALERT_PUSH_MAX_RETRIES:
            delay = _ALERT_PUSH_BACKOFF_BASE * (2 ** (attempt - 1))
            logger.warning("Alert push attempt %d/%d failed, retrying in %ds: %s", ...)
            time.sleep(delay)
```

## Impact

**Dev env:** Hiem transient fail. HttpPublisher chu yeu dung cho debug/devops dispatch. Low production surface.

**Future risk:**
- If production data flows through HttpPublisher (not just debug), transient backend restart = data loss
- Tick buffer not replayed — caller assumption may rely on deliver-at-least-once semantics

**Note:** Transport router already has MQTT primary + HTTP fallback in `TransportRouter.publish`. If MQTT fails -> HTTP retry IS the fallback. Adding retry INSIDE HttpPublisher may conflict with router's own fallback logic.

**Severity Low:** Router fallback exists; publisher-level retry is 2nd line of defense.

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Caller owns retry via `TransportRouter` fallback | Partially true — MQTT -> HTTP swap, but within HTTP path no retry |
| H2 | AlertService retry is because it's critical path, publisher is not | Reasonable but inconsistent |
| H3 | Retry would mask bugs (rapid repeat of same bad payload) | Consider — backoff + 3-attempt limit mitigates |

### Attempts

_(Chua attempt fix — surfaced Phase 1 Pass C audit 2026-05-13)_

## Resolution

_(Fill in when resolved — Phase 5 hygiene)_

**Fix approach (planned):**

### Option A: Add retry inside HttpPublisher

```python
_HTTP_PUBLISH_MAX_RETRIES = 3
_HTTP_PUBLISH_BACKOFF_BASE = 1

def publish(self, messages: list[dict[str, Any]]) -> PublishResult:
    payload = json_dumps({"messages": messages})
    last_exc: Exception | None = None
    status_code: int | None = None

    for attempt in range(1, _HTTP_PUBLISH_MAX_RETRIES + 1):
        try:
            if self._headers:
                status_code = self._sender(self.endpoint, payload, self._headers)
            else:
                status_code = self._sender(self.endpoint, payload)
            last_exc = None
            break
        except Exception as exc:
            last_exc = exc
            if attempt < _HTTP_PUBLISH_MAX_RETRIES:
                delay = _HTTP_PUBLISH_BACKOFF_BASE * (2 ** (attempt - 1))
                time.sleep(delay)

    if last_exc is not None:
        return PublishResult(ok=False, error=str(last_exc))

    ok = 200 <= status_code < 300
    return PublishResult(ok=ok, ack_count=len(messages) if ok else 0)
```

Pro: Consistent voi AlertService pattern.
Con: Retry inside publisher + router fallback = 2 levels. Configurable or document explicitly.

### Option B: Accept upstream caller handles retry

Document in HttpPublisher docstring: "single-attempt, caller responsible for retry". Keeps transport layer dumb.

Pro: No code change.
Con: Drift with AlertService; inconsistent.

**Em khuyen Option A** — unified pattern across sim. Adjust `TransportRouter` if needed to disable retry when using HTTP as MQTT fallback.

**Fix scope summary:** ~20 LoC change + 2 module-level consts. Est 25 min.

**Test added (planned):**
- `test_http_publisher.py::test_retries_on_transient_failure_then_succeeds`
- `test_http_publisher.py::test_gives_up_after_max_retries`
- `test_http_publisher.py::test_backoff_delay_increases_exponentially`

**Verification:**
1. Unit tests green
2. Simulate backend restart with controlled timing, verify 2nd attempt lands successfully
3. Measure wall-clock cua failed publish: should be ~7s total (1 + 2 + 4s backoff)

## Related

- **Parent audit:** [M08 transport audit](../AUDIT_2026/tier2/iot-simulator/M08_transport_audit.md)
- **Reference pattern:** [AlertService retry+backoff](../AUDIT_2026/tier2/iot-simulator/M02_services_audit.md) line 130-170
- **Related pattern:** `TransportRouter.publish` MQTT -> HTTP fallback (overlapping concern)

## Notes

- Low priority
- Consider coordinating with Option A caveat: avoid retry stampede when router already has fallback
- Adjustable config: `max_retries` + `backoff_base` as __init__ params for test flexibility
