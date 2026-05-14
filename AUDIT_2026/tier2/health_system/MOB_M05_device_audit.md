# Audit: MOB-M05 — device (BLE pairing + state + firmware/battery)

**Module:** `health_system/lib/features/device/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim

## Scope

Feature device chứa BLE pairing flow + device list/configure + firmware/battery polling. ~35 file ~3,500 LoC. SkimMode focus Architecture + Security.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Device state machine rõ. Defer per-UC detail. |
| Readability | 2/3 | Provider docstring partial. |
| Architecture | 3/3 | Clean architecture per feature. Device provider isolated. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. BLE permission gate Android 12+. Trừ điểm: MAC address handling (PII?) cần encryption verify. |
| Performance | 3/3 | Async BLE operation non-blocking. |
| **Total** | **12/15** | Band: **🟡 Healthy**. |

## Findings

### Security

- BLE permission gate Android 12+ runtime permission — verify `permission_handler` package consume Phase 4.
- MAC address handling: ORM column plaintext (BE-M04). Cross-cutting PHI encryption ADR.
- HS-001 (devices schema drift), HS-003 (calibration offsets dead) cross-link.
- HS-002 (cross-user MAC bypass) — service-side BE fix.

### Architecture

- Clean architecture per feature.
- Device provider isolated.
- Defer Phase 3: per-UC widget flow test, device disconnect UX.

## Positive findings

- Clean per-feature architecture.
- BLE permission gate compliant.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P2

- [ ] MAC address encryption ADR cross-link BE-M04 P2.
- [ ] Defer Phase 3: per-UC widget flow test.

## Out of scope

- Per-screen widget test — Phase 3.
- BLE library config detail — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-001](../../../BUGS/HS-001-devices-schema-drift-canonical.md).
  - [HS-002](../../../BUGS/HS-002-device-unique-mac-cross-user-bypass.md).
  - [HS-003](../../../BUGS/HS-003-calibration-offsets-never-consumed.md).
- ADR INDEX:
  - [ADR-010](../../../ADR/INDEX.md), [ADR-011](../../../ADR/INDEX.md), [ADR-012](../../../ADR/INDEX.md).
- Intent drift (reference only):
  - DEVICE.md (Phase 0.5).
- Related audit files:
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
