# Audit: MOB-M04 — auth (login/register/verify/reset/biometric)

**Module:** `health_system/lib/features/auth/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim + Full on lib/features/auth/services/token_storage_service.dart

## Scope

Feature auth chứa login/register/verify-email/forgot-password/reset-password/change-password/biometric flow + token persistence. ~22 file ~2,500 LoC. Security-sensitive — token storage được FullMode audit.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Token persistence flow đúng (`flutter_secure_storage`). Auth provider state machine rõ. Defer per-screen detail. |
| Readability | 2/3 | Token storage service docstring tốt. Auth provider mixed concern (state + repository). |
| Architecture | 3/3 | Clean architecture per feature: data/domain/presentation/providers/services. Token storage isolated. |
| Security | 3/3 | **Token storage FlutterSecureStorage** — đúng convention steering. KHÔNG hit anti-pattern auto-flag (no SharedPreferences cho token). |
| Performance | 3/3 | Async storage non-blocking. Provider lazy-create. |
| **Total** | **13/15** | Band: **🟢 Mature**. |

## Findings

### Security (FullMode trên token_storage_service.dart)

- `lib/features/auth/services/token_storage_service.dart:5-15` — `FlutterSecureStorage` instance đúng convention. Token KHÔNG persist vào SharedPreferences (which would hit anti-pattern auto-flag).
  
  **Verify cross-grep**: `grep "SharedPreferences" lib/features/auth/` → 0 hit. **PASS anti-pattern scan**.

- Token model `auth_response_model.dart` consume — JSON serialize/deserialize. OK.
- JWT `iss=healthguard-mobile` verify per topology contract — server-side issue. Mobile-side không verify JWT signature.
- Refresh token rotation pattern cross-link với `core/network/api_client.dart` (MOB-M02).

### Architecture

- Clean architecture per feature: data/domain/presentation/providers/services. Pattern Flutter idiomatic.
- Token storage service isolated → test isolation OK.
- Auth provider state machine: bootstrap → unauthenticated/authenticated.

### Correctness

- Login + register flow: form validation tại boundary → AuthService consume → token persist. Defer per-screen widget test Phase 3.

## Positive findings

- `token_storage_service.dart` consume `FlutterSecureStorage` đúng convention.
- Clean architecture per feature.
- Token isolated trong dedicated service.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P2

- [ ] **Defer Phase 3**: per-screen widget test, biometric fallback UX.
- [ ] **Refresh token rotation P2**: cross-link MOB-M02 P1 dio migration.

## Out of scope

- Refresh token rotation logic — MOB-M02.
- Per-screen widget test — Phase 3.
- Biometric authentication flow — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-007](../../../BUGS/INDEX.md) — JWT TTL drift (BE-M09).
  - [HS-016](../../../BUGS/INDEX.md) — Password policy inconsistent (BE-M05).
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md) — Internal service auth (server-side).
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md).
  - [`MOB_M02_core_audit.md`](./MOB_M02_core_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md).
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Steering: `health_system/.kiro/steering/40-security-guardrails.md`.
