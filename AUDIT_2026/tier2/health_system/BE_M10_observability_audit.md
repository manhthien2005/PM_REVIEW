# Audit: BE-M10 — observability (Phase 7 stage timing)

**Module:** `health_system/backend/app/observability/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module observability chứa stage timing primitives Phase 7 cho risk pipeline. Scope audit = 2 file (`__init__.py` + `timing.py`). ~120 LoC. Focus: log format, log level per env, PHI masking, correlation ID propagation, metric cardinality. Phạm vi loại trừ: middleware wiring (BE-M01), service consumer (BE-M03), tracing infrastructure.

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `__init__.py` | ~22 | Re-export StageTimer + record_timing + Phase 7 plan documentation | Module docstring captures 4 canonical stage names. |
| `timing.py` | ~98 | StageTimer context manager + record_timing log emit + test hook | Dual-purpose: prod log + test listener subscribe. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | StageTimer fire unconditionally kể cả exception. record_timing defensive listener iteration. Test subscribe/unsubscribe idempotent. |
| Readability | 3/3 | Module docstring best-in-class. Class docstring with usage example. Comment captures design tradeoff (no metrics runtime dependency). |
| Architecture | 2/3 | Clean prod-test boundary. Trừ điểm: 1 file primitive — không cover full observability stack (tracing, structured logger config, correlation ID, log filter PHI mask). Scope rất nhỏ. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Trừ điểm: PHI logging risk medium — `**fields` accept arbitrary kwargs, consumer có thể vô tình pass PHI value. Không có log filter mask. |
| Performance | 3/3 | StageTimer wall-clock O(1). Listener iteration tuple snapshot. record_timing structured log payload nhỏ. Không I/O blocking. |
| **Total** | **13/15** | Band: **🟢 Mature** — primitive observability minimal nhưng correct + tested. |

## Findings

### Correctness

- `backend/app/observability/timing.py:63-83` — StageTimer context manager fire unconditionally on `__exit__` including exception propagation. Comment giải thích "elapsed_ms still reflects how long the failing call took, exactly what you want for outage timing dashboards". Best-in-class defensive timing.

- `backend/app/observability/timing.py:42-52` — record_timing defensive listener iteration với `tuple(_TEST_LISTENERS)` snapshot tránh mutation race. Try/except với justification comment "never let listener bugs break callers".

- `backend/app/observability/timing.py:85-95` — subscribe/unsubscribe_for_tests idempotent (ValueError swallow). Test fixture safety.

- `backend/app/observability/timing.py:38-40` — record_timing payload format. Round 3 decimal millisecond precision. Log line `risk.timing {dict}` parseable bởi log aggregator.

### Readability

- `backend/app/observability/__init__.py:1-15` — module docstring giải thích Phase 7 + 4 canonical stage name + WHY structured log thay vì metrics runtime ("avoid metrics dependency until Phase 7+ infrastructure"). Reader hiểu design tradeoff trong 30s.
- `backend/app/observability/timing.py:1-23` — module docstring với 2 surface (function + class) + test hook explanation. Best-in-class.
- `backend/app/observability/timing.py:25-29` — TIMING_LOG_PREFIX comment "Channel used by every emitted log line — lets the aggregator filter timing events". Reader hiểu log channel intent.
- `backend/app/observability/timing.py:31-34` — _TEST_LISTENERS comment "Test-only sink. Production code never reads this". Boundary clear.
- `backend/app/observability/timing.py:38-58` — record_timing docstring chi tiết: stage convention + elapsed_ms semantics + extra fields purpose.
- `backend/app/observability/timing.py:65-83` — StageTimer docstring với usage example block + edge case "fires unconditionally on `__exit__` including exception propagation".

### Architecture

- **Clean separation prod path vs test path**: production code chỉ thấy `logger.info(...)`. Test code subscribe `_TEST_LISTENERS` callback. Boundary explicit.
- **No metrics runtime dependency**: comment giải thích explicit. Forward-looking + minimal initial scope.
- **Single file 98 LoC primitive**: scope minimal. Không cover full observability stack:
  - Missing: structured logger config (JSON formatter, correlation ID per-request).
  - Missing: tracing instrumentation (OpenTelemetry).
  - Missing: log filter for PHI mask.
  - Missing: log level per env.
  
  Hiện scope chỉ Phase 7 stage timing → acceptable. BE-M01 P1 recommendation đã capture cross-link.

- **No correlation ID**: stage timing không có `request_id` field default → multiple concurrent request log chồng chất, khó trace. Phase 4 P1 add `request_id` từ contextvar.

### Security

- **Anti-pattern auto-flag scan**: 0 hit. Security=0 override KHÔNG áp dụng.

- **PHI logging risk medium**: `record_timing(stage, elapsed_ms, **fields)` accept arbitrary `**fields` kwargs. Service consumer có thể vô tình pass PHI:
  ```python
  # Service code (hypothetical bad example):
  record_timing("inference", 245.5, heart_rate=120, spo2=92, user_id=42)
  ```
  → log line chứa raw vital values. Steering `40-security-guardrails.md` mandate "Không log password/token/health vitals raw".
  
  Hiện service consumer (BE-M03) chưa pass PHI. Verify cross-grep cần Phase 4 P1. Defense-in-depth: validate `**fields` keys against whitelist (no vital values).
  
  Cross-cutting concern. Không re-flag bug ID (BE-M03 P1 PHI logging filter cover).

- `backend/app/observability/timing.py:42-52` — listener exception swallow `# noqa: BLE001` justified ("never let listener bugs break callers"). Defensive design.

- Log level `logger.info` cho production OK.

### Performance

- `time.monotonic()` C-extension fast path. O(1).
- `tuple(_TEST_LISTENERS)` snapshot O(N) listeners — production list rỗng. Negligible.
- `payload = {"stage": ..., **fields}` dict construction O(K) keys.
- `logger.info("%s %s", PREFIX, payload)` lazy format — payload chỉ render khi log level enable.
- Không I/O blocking.

## Positive findings

- `backend/app/observability/timing.py:65-83` — StageTimer fire unconditionally including exception. Best-in-class defensive timing.
- `backend/app/observability/timing.py:42-52` — defensive listener iteration với tuple snapshot + try/except. Listener bug không break caller.
- `backend/app/observability/timing.py:85-95` — subscribe/unsubscribe idempotent design.
- `backend/app/observability/__init__.py:1-15` — module docstring captures Phase 7 plan + design tradeoff.
- `backend/app/observability/timing.py:1-23` — module docstring với 2 surface explanation.
- `TIMING_LOG_PREFIX = "risk.timing"` channel naming convention — log aggregator filter friendly.
- Production-test boundary explicit qua naming.
- Forward-looking design — cho phép Phase 7+ wrap metrics runtime.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P0

- [ ] Không có action P0.

### P1

- [ ] **Correlation ID propagation**: thêm `request_id` từ contextvar (set by request middleware BE-M01) vào record_timing default fields.
- [ ] **PHI logging filter**: validate `**fields` keys against whitelist hoặc add log filter mask. Cross-cutting với BE-M03 P1.

### P2

- [ ] **Structured logger config**: `app/observability/logger_config.py` với JSON formatter + log level per env.
- [ ] **Stage name enum**: thay free-form `stage: str` bằng `Literal[StageEnum]`.
- [ ] **Log level downgrade**: per-stage timing → DEBUG nếu volume cao.
- [ ] **Tracing infrastructure**: OpenTelemetry integration. Phase 7+.

## Out of scope

- Middleware wiring — BE-M01.
- Service consumer của StageTimer — BE-M03.
- Tracing infrastructure — Phase 7+.
- Log aggregator config — DevOps scope.
- Defer Phase 3: per-stage histogram dashboard config, alert threshold tuning.

## Cross-references

- BUGS INDEX (new):
  - Không phát hiện bug mới.
- BUGS INDEX (reference):
  - HS-022 — `relationship_service` silent error swallow (BE-M03); cùng pattern logger.exception missing.
- ADR INDEX:
  - Không khớp ADR cho observability scope hiện tại.
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md) — P1 "Wire BE-M10 observability".
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md) — `model_api_client` consumer.
  - [`BE_M07_adapters_audit.md`](./BE_M07_adapters_audit.md) — adapter consumer.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/40-security-guardrails.md` (PHI mask rule).
