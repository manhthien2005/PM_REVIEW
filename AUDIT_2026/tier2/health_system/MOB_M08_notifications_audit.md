# Audit: MOB-M08 — notifications (FCM + foreground/background + in-app list)

**Module:** `health_system/lib/features/notifications/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim + Full on lib/features/notifications/services/notification_runtime_service.dart

## Scope

Feature notifications chứa FCM init + foreground/background handler + topic subscribe + in-app notification list + push token register. ~18 file ~2,500 LoC. Security-sensitive — FCM payload handler được FullMode audit. D1 + D3 reference points.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | FCM init + background handler đúng pattern. Notification list mark-read flow. D3 read state consume đúng. |
| Readability | 2/3 | NotificationRuntimeService docstring có. Provider state mixed concern. |
| Architecture | 2/3 | NotificationRuntimeService instantiated trong bootstrap singleton-like. AuthBridge wrapper pattern. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. FCM payload handler verify type-safe (cross-link MOB-M02 deep link). Trừ điểm: deep link nav từ notification → consume app_router không validate. |
| Performance | 3/3 | Async FCM init non-blocking. Notification list pagination. |
| **Total** | **11/15** | Band: **🟡 Healthy**. |

## Findings

### Security (FullMode trên FCM payload handler)

- FCM payload handler — verify type-safe casting.
- Deep link navigation từ notification click → consume `app_router` (MOB-M02). Cross-link HS-018 + MOB-M02 P1.
- Topic subscribe — verify scope per user.

### D-series reference (không re-flag)

- **D1 — severity vocab drift**: governed ADR-015. Reference only.
- **D3 — notification read state truth source**: governed Phase 0.5 NOTIFICATIONS.md reverify. Reference only.

### Architecture

- NotificationRuntimeService instantiated trong `_HealthSystemAppState` → singleton lifecycle.
- Critical alert redirect coupling với `SOSRealtimeAlertService` (MOB-M09).

## Positive findings

- FCM background handler register đúng pattern.
- Deep link integration với app_router.
- D3 reverify decision implementation correct.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P1

- [ ] FCM payload type-safe cast verify defense-in-depth.

### P2

- [ ] Defer Phase 3: per-notification-type widget, channel config per Android version.

## Out of scope

- D1 severity vocab — governed ADR-015.
- D3 notification read state — governed Phase 0.5.
- Per-screen widget test — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-018](../../../BUGS/INDEX.md) — XSS via deep_link_redirect (BE-M02).
- ADR INDEX:
  - [ADR-015](../../../ADR/INDEX.md) — Severity taxonomy.
- Intent drift (reference only — không re-flag):
  - **D1** — severity vocab drift. Governed ADR-015.
  - **D3** — notification read state truth source. Governed Phase 0.5.
  - NOTIFICATIONS.md (Phase 0.5 reverify decisions).
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md).
  - [`MOB_M02_core_audit.md`](./MOB_M02_core_audit.md).
  - [`MOB_M09_emergency_fall_audit.md`](./MOB_M09_emergency_fall_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md) — notification_service, push_notification_service.
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
