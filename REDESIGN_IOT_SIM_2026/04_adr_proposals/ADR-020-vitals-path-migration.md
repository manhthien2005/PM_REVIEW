# ADR-020: Vitals Path Migration — DB Direct → HTTP

**Status:** � Approved (Redesign 2026-05-15) — SUPERSEDES ADR-013
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [iot-sim, architecture, vitals, refactor, supersedes-adr-013]
**Supersedes:** ADR-013 (IoT direct DB vitals)
**Resolves:** B1 (Vitals path), enables OQ5 (BE auto-trigger risk)

## Context

ADR-013 (Accepted earlier) chốt IoT sim write vitals DIRECT vào Postgres `vitals` table qua SQLAlchemy `session_scope()`, bypass HTTP layer. Rationale ADR-013 thời điểm đó:
- High tick rate (5s default, có thể 1s khi demo) → HTTP latency 50-200ms tạo overhead
- Sim chỉ là dev tool → không cần production-realistic HTTP

**Phase 1 inventory phát hiện CRITICAL CONTRADICTION:**
- OQ5 chốt BE auto-trigger risk inference sau `/telemetry/ingest` endpoint
- `calculate_device_risk` được gọi từ HTTP route handler (`routes/telemetry.py:325-333`)
- IoT sim DB direct → bypass HTTP → BE KHÔNG nhận trigger → risk inference **KHÔNG chạy**
- Mobile app sẽ KHÔNG thấy risk update realtime khi simulation chạy

**Forces:**
- B1 brainstorm chốt HTTP migration
- OQ5 (BE auto-trigger risk) ưu tiên cao hơn ADR-013 latency concern
- Production flow phải đại diện đúng smartwatch → phone → BE qua HTTP
- HS-024 fix yêu cầu BE validation gate — chỉ work nếu vitals đi qua route handler
- Demo dramatic impact: panel chấm thấy risk_level update mỗi tick → quan trọng cho đồ án

**Constraints:**
- ADR-013 đã accepted → reverse decision phải có rationale rõ + ADR mới
- IoT sim test suite có tests cho `_execute_pending_tick_publish` DB direct path → cần migrate
- HTTP latency 50-200ms per batch — acceptable cho 5s tick (4% overhead)

**References:**
- ADR-013 (original DB direct decision)
- Phase 1 inventory section 9.2 (vitals dual-path resolution)
- Brainstorm B1
- OQ5 BE auto-trigger
- Contract `vitals_ingest.md`

## Decision

**Chose:** Option A — Migrate IoT sim vitals từ DB direct sang HTTP `POST /api/v1/mobile/telemetry/ingest`.

**Why:**
1. **Resolve contradiction** với OQ5 — BE auto-trigger risk chỉ work nếu vitals qua HTTP route
2. **Production-realistic** — smartwatch BLE → phone → BE qua HTTP, never direct DB
3. **Enable HS-024 fix** — BE validation gate require route handler entry point
4. **Demo flow accurate** — panel chấm thấy realistic smartwatch flow
5. **Latency acceptable** — 50-200ms HTTP overhead < 5s tick interval = <4%
6. **`HttpPublisher` đã wired sẵn** trong `dependencies.py:670-674` (dead code currently) — chỉ cần invoke

## Options considered

### Option A (CHOSEN): HTTP migration, dispose DB direct

**Description:**
- Replace `_execute_pending_tick_publish` (line 1011-1056) DB direct INSERT logic
- Wire vào HTTP path: tick → `_tick_buffer` → batch flush qua `transport_router.http.publish()`
- HTTP endpoint: `POST /api/v1/mobile/telemetry/ingest` với `X-Internal-Service: iot-simulator`
- Schema validation strict ở BE (HS-024 fix)
- BE auto-trigger risk per device (OQ5)
- Dispose: `_execute_pending_tick_publish` direct DB INSERT code path

**Pros:**
- Resolve OQ5 contradiction
- Production-realistic
- Enable HS-024 validation at BE boundary
- HTTP audit log
- Smoke test E2E qua curl
- `HttpPublisher` infra đã sẵn (chỉ wire)

**Cons:**
- Breaking ADR-013 (reverse decision)
- +50-200ms HTTP latency per batch (acceptable)
- Update IoT sim test suite (mock mobile BE)
- Cần dual-mount transitional (1-2 deploy) nếu sợ rủi ro

**Effort:** M (~6-8h):
- 1h: Wire `transport_router.http.publish()` vào tick flow thay direct DB
- 2h: Update batch payload structure match `VitalIngestRequest` schema
- 2h: Update IoT sim unit tests (mock HTTP instead of psql)
- 1-2h: E2E smoke test simulator → BE → DB → mobile poll

### Option B (rejected): Keep DB direct + add Postgres LISTEN/NOTIFY

**Description:** Giữ DB direct INSERT, add BE worker LISTEN trên Postgres channel `vitals_inserted`, trigger risk async.

**Pros:**
- No breaking ADR-013
- Avoid HTTP latency

**Cons:**
- Add infra complexity (Postgres NOTIFY worker, Celery hoặc asyncio task)
- Production wearable không dùng pattern này
- Stack VSmartwatch chưa có infrastructure cho async worker
- Postgres NOTIFY có payload size limit 8000 bytes → batch ingest có thể exceed

**Why rejected:** Add complexity for marginal latency saving. Not production-realistic.

### Option C (rejected): Keep ADR-013, accept "no auto-risk for IoT sim"

**Description:** IoT sim vitals stays DB direct. Risk inference chỉ chạy khi user mobile tap "Tính lại".

**Pros:**
- Zero code change
- Zero risk

**Cons:**
- Demo mất sức mạnh — panel chấm KHÔNG thấy risk update realtime khi simulate
- IoT sim simulation không đại diện đúng smartwatch (production has auto-risk)
- Mâu thuẫn OQ5 directly

**Why rejected:** Defeats purpose of OQ5 + Charter section 2.1 M1 + M2 target.

### Option D (rejected): IoT sim trigger /risk/calculate manually after each batch

**Description:** Sau mỗi DB INSERT batch, IoT sim gọi `POST /risk/calculate` HTTP → BE chạy risk → return.

**Pros:**
- Keep ADR-013 DB direct
- Get auto-risk indirectly

**Cons:**
- Mâu thuẫn OQ5 (which dispose `_trigger_risk_inference`)
- Dual contract: vitals DB direct + risk HTTP → confusion
- Doesn't fix HS-024 (validation still at risk handler, not ingest)

**Why rejected:** Halfway hack — neither solves problem nor saves complexity.

## Consequences

### Positive
- B1 + OQ5 + HS-024 + HS-024 root cause all addressed
- Production-realistic flow
- Demo dramatic accurate
- HTTP audit log
- Smoke test trivial (`curl POST /telemetry/ingest`)
- `HttpPublisher` orphan dead code → active path

### Negative / Trade-offs accepted
- ADR-013 reversed (need ADR update)
- HTTP latency +50-200ms per batch
- Test suite refactor
- Need dual-mount window 1-2 deploy (or skip — solo dev redesign branch)

### Follow-up actions required
- [ ] Update ADR-013 status to "⚫ Superseded by ADR-020"
- [ ] Phase 7 slice 1: Wire `_tick_buffer` → `transport_router.http.publish()`
- [ ] Phase 7 slice 2: Update payload structure match `VitalIngestRequest`
- [ ] Phase 7 slice 3: Update IoT sim tests
- [ ] Phase 7 slice 4: Remove old `_execute_pending_tick_publish` DB direct code
- [ ] Phase 7 slice 5: E2E verify auto-risk trigger works
- [ ] Update INDEX.md ADR list

## Reverse decision triggers

- Nếu BE latency >500ms per batch consistently → consider Option B (LISTEN/NOTIFY) 
- Nếu BE health unstable + IoT sim demo block → temporary fallback DB direct với feature flag
- Nếu HTTP layer add unforeseen complexity → revisit ADR-013

## Related

- **Supersedes:** ADR-013 (IoT direct-DB vitals)
- **Companion:** ADR-018 (validation contract), ADR-019 (no direct model-api), ADR-021 (prefix)
- Contract: `vitals_ingest.md`
- Phase 1 inventory section 9.2
- Code: `Iot_Simulator_clean/api_server/dependencies.py:670-674` (HttpPublisher orphan), `:1011-1056` (DB direct dispose target)

## Notes

### Implementation pattern

```python
# Phase 7 dependencies.py update
def _execute_pending_tick_publish(self, pending_publish: PendingTickPublish | None) -> None:
    if pending_publish is None:
        return
    
    # NEW: HTTP path via transport_router
    payload = {
        "messages": [
            {
                "db_device_id": msg["db_device_id"],
                "emitted_at": msg["emitted_at"],
                "vitals": msg["vitals"],
            }
            for msg in pending_publish.messages
        ]
    }
    
    publish_started = monotonic()
    try:
        status_code = self._http_sender(
            self._telemetry_ingest_endpoint(self._health_backend_url),
            _json.dumps(payload),
            headers={"X-Internal-Service": "iot-simulator"},
        )
        ack_count = len(payload["messages"]) if 200 <= status_code < 300 else 0
    except Exception:
        logger.warning("HTTP publish failed", exc_info=True)
        ack_count = 0
    
    # REMOVE: db.execute(INSERT INTO vitals ...) direct path
    # ... existing publish_ok + last_publish_* tracking remains
```

### Migration strategy (no big-bang)

Phase 7 build incremental:
1. Add HTTP path alongside DB direct (dual-mount transitional)
2. Verify HTTP path works via flag `USE_HTTP_VITALS_PUBLISH=true`
3. Toggle flag → all vitals via HTTP
4. Monitor 1-2 days
5. Remove DB direct code path (Phase 7 cleanup slice)

### Backward compat

- IoT sim FE: no change (push interval/scenario logic untouched)
- BE endpoint `/telemetry/ingest`: existing, just stricter validation
- Mobile app: no change (still polls `/monitoring/vitals/timeseries`)
- Admin web: no change

### Performance benchmark target

- Tick interval 5s → batch ~1-5 vitals records → ~200B payload
- HTTP roundtrip target p95 < 300ms
- Vitals → mobile poll latency end-to-end < 5s (tick) + 200ms (HTTP) + 3s (poll) = ~8s ❌

Wait — for vitals-only polling, target latency là 5s tick interval bound. HTTP add 200ms = 5.2s. Acceptable.

For FCM alerts (fall/critical risk), latency target <2s. FCM async push, không liên quan vitals batch path.
