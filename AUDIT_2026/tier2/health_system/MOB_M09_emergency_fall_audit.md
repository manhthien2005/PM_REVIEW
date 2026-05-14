# Audit: MOB-M09 — emergency + fall (life-critical)

**Module:** `health_system/lib/features/emergency/` + `lib/features/fall/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim + Full on emergency/services/sos_realtime_alert_service.dart + fall handlers

## Scope

Feature emergency + fall — life-critical. SOS trigger + countdown + auto-call + fall detection + fall alert UI. ~17 + 8 = 25 file ~2,500 LoC.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Fail-safe SOS countdown. State machine Module FA-2 Option 3-Lite. Idempotency. |
| Readability | 2/3 | SOSRealtimeAlertService docstring. Critical alert redirect coupling complex. |
| Architecture | 2/3 | Singleton bind navigator key + critical alert redirect. Tight nhưng acceptable life-critical. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. GPS permission check. Trừ điểm: deep link route arg validation. |
| Performance | 3/3 | Async fall detection subscriber. Background location. |
| **Total** | **11/15** | Band: **🟡 Healthy**. |

## Findings

### Security (FullMode trên life-critical handlers)

- SOS countdown service — fail-safe verify Phase 4.
- Fall-detected idempotency — verify cross-grep BE-M03 Module FA-2 Option 3-Lite.
- Auto-call dialer — CALL_PHONE permission gate.
- GPS permission + accuracy validation.
- PII trong alert payload — service-side G-3 redaction cross-link.

### Architecture

- SOSRealtimeAlertService singleton lifecycle.
- Critical alert redirect coupling NotificationRuntimeService.
- Module FA-2 Option 3-Lite stand-up survey state machine.

### UC cross-reference

- Fall detection UC + emergency SOS UC trong PM_REVIEW/Resources/UC/.

## Positive findings

- Module FA-2 Option 3-Lite documented.
- SOS state machine đầy đủ.
- Critical alert redirect fail-safe pattern.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P1

- [ ] Fail-safe logic verify SOS countdown.
- [ ] Idempotency multi fall verify cross-grep BE.
- [ ] GPS permission gate + accuracy threshold validation.

### P2

- [ ] Defer Phase 3: per-UI animation, haptic feedback.

## Out of scope

- Service-side fan-out — BE-M03.
- Per-UI animation — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-018](../../../BUGS/INDEX.md).
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md), [ADR-015](../../../ADR/INDEX.md).
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md).
  - [`MOB_M08_notifications_audit.md`](./MOB_M08_notifications_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md) — emergency_service + fall_event_service.
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- UC: PM_REVIEW/Resources/UC/.
