# Phase 3 — Data Contracts

> **Goal:** Define rõ schema, validation, error codes của 5 endpoint trong target topology. Mỗi contract là source of truth cho IoT sim (producer) + Mobile BE (consumer) + Mobile app (downstream consumer).

**Phase:** P3 — Data Contracts
**Date:** 2026-05-15
**Author:** Cascade
**Reviewer:** ThienPDM (pending)
**Status:** 🟡 v0.1 (5 contracts drafted)
**Charter:** `../00_charter.md` v1.0
**Target topology:** `../02_target_topology.md` v0.1

---

## Files trong folder này

| File | Endpoint | Producer | Consumer | Critical bug fixed |
|---|---|---|---|---|
| [`vitals_ingest.md`](./vitals_ingest.md) | `POST /api/v1/mobile/telemetry/ingest` | IoT sim | Mobile BE | XR-001 (prefix), HS-024 (validation) |
| [`fall_imu_window.md`](./fall_imu_window.md) | `POST /api/v1/mobile/telemetry/imu-window` | IoT sim | Mobile BE | XR-001, ADR-019 |
| [`sleep_session.md`](./sleep_session.md) | `POST /api/v1/mobile/telemetry/sleep-risk` | IoT sim | Mobile BE | XR-001, ADR-019 |
| [`alert_push.md`](./alert_push.md) | `POST /api/v1/mobile/telemetry/alert` + FCM payload | IoT sim + Mobile BE | Mobile BE + Mobile app | OQ3 hybrid takeover |
| [`risk_trigger.md`](./risk_trigger.md) | Internal flow (BE auto-trigger after ingest) | Mobile BE | Model API + Mobile app | HS-024, XR-003, OQ5 |

---

## Common contract conventions

### Authentication

| Surface | Header | Value |
|---|---|---|
| IoT sim → Mobile BE | `X-Internal-Service` | `iot-simulator` |
| Mobile BE → Model API | `X-Internal-Secret` | Shared secret từ env `INTERNAL_SECRET` |
| Mobile app → Mobile BE | `Authorization` | `Bearer <JWT>` |

### Error response format (standardized cho redesign)

```json
{
  "error": {
    "code": "INSUFFICIENT_VITALS",
    "message": "Vitals batch incomplete: required fields missing",
    "details": {
      "missing_fields": ["heart_rate", "spo2"],
      "device_id": 123
    }
  },
  "request_id": "uuid-v4"
}
```

**Error codes vocabulary:**

| Code | HTTP | Meaning |
|---|---|---|
| `INVALID_PAYLOAD` | 400 | Schema validation failed (missing required, wrong type) |
| `OUT_OF_RANGE` | 422 | Value outside acceptable range (e.g., HR > 250) |
| `INSUFFICIENT_VITALS` | 422 | Critical vitals NULL (HR + SpO2 both missing) |
| `UNAUTHORIZED` | 401 | Missing/invalid auth header |
| `FORBIDDEN` | 403 | Auth OK but role/scope insufficient |
| `NOT_FOUND` | 404 | Resource not exist |
| `CONFLICT` | 409 | Idempotency conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `MODEL_UNAVAILABLE` | 503 | Model API down or circuit breaker open |
| `INTERNAL_ERROR` | 500 | Unexpected server error (sanitized) |

### Versioning

- Endpoint version trong URL: `/api/v1/*` (ADR-004)
- Schema version trong header (optional): `X-Schema-Version: 2026-05-15`
- Risk contract version: `X-Risk-Contract-Version` (đã có trong code, giữ nguyên)

### Idempotency

- IoT sim retry mechanism phải gửi `Idempotency-Key: <uuid>` header
- Mobile BE deduplicate trong 5 phút window
- Vitals INSERT đã có `ON CONFLICT (device_id, time) DO NOTHING` — DB-level idempotency

---

## Phase 3 acceptance criteria

- [x] 5 contract files với schema đầy đủ
- [x] Field constraints (type + range + nullable)
- [x] Error code structured + HTTP status mapping
- [x] Example payload (valid + invalid)
- [x] Producer/consumer references (file:line)
- [x] Backward compatibility note
- [x] Common conventions (auth, error format, versioning)

---

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-15 | Cascade | Initial draft 5 contracts |
