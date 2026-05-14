# Audit: MOB-M02 — core (network + routes + services + theme)

**Module:** `health_system/lib/core/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim

## Scope

Module core chứa shared primitives mobile: 8 sub-folder (constants, error, network, notifications, routes, services, theme, utils). SkimMode focus Architecture + Security + FullMode trên `network/api_client.dart` + `routes/app_router.dart`. ~3,000 LoC est.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | api_client.dart HTTP wrapper với refresh token rotation. Token attach Authorization header. Trừ điểm: dùng raw `http` thay vì `dio` (no interceptor pipeline); app_router.dart 33 case fat router. |
| Readability | 2/3 | app_router.dart 365 LoC chứa 33+ route case. Constants centralized. |
| Architecture | 2/3 | Clean api_client + session service injection. Central route registry tốt. Trừ điểm: route definition không có whitelist deep link; debug print route name. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Token via `flutter_secure_storage`. Trừ điểm: onGenerateRoute không validate route arg format; no certificate pinning. |
| Performance | 3/3 | Async HTTP non-blocking. Route construction lazy. |
| **Total** | **11/15** | Band: **🟡 Healthy**. |

## Findings

### Correctness

- `lib/core/network/api_client.dart:73-83` — Authorization header attach pattern. Token từ `_sessionService.readStoredSession()`. OK.
- `lib/core/routes/app_router.dart:83-365` — `onGenerateRoute` switch 33 case. Each case construct MaterialPageRoute với RouteSettings + arguments. Fat router pattern.
- `lib/core/routes/app_router.dart:94-100` — Native Flutter deep link push với query param handle inline. Comment giải thích edge case.

### Readability

- `lib/core/routes/app_router.dart:85` — `debugPrint("======== [AppRouter] onGenerateRoute: $routePath ========")` debug print pattern. Production leak risk. P2 guard `kDebugMode`.
- 33 case route registry — readable nhưng dài. Split candidate.

### Architecture

- **Raw `http` package vs Dio**: `api_client.dart` dùng `http`. Không có interceptor pipeline → token refresh, error mapping, logging dispersed. Dio recommend cho mobile production. P2.
- **Route registry centralization**: 365 LoC single source-of-truth. Pattern OK. Split candidate sang sub-router.
- **`onboarding_permission_service` consume `flutter_secure_storage`** — same store với token. Pragmatic.

### Security

- **Anti-pattern auto-flag scan**:
  - Token in localStorage / SharedPreferences? **NO** — `flutter_secure_storage` đúng convention.
  - Hardcoded secret? **NO**.
  - SSL verify disabled? **NO**.
  
  **Kết luận: 0 hit → Security=0 override KHÔNG áp dụng.**

- **Deep link route arg validation gap**: `onGenerateRoute` accept arg từ deep link → MaterialPageRoute construct với arg không validate format. Cross-link HS-018 BE-M02 — defense-in-depth recommended.

- **Certificate pinning missing**: `api_client.dart` không có cert pinning. Production man-in-the-middle risk nếu CA compromised. P2 forward-looking.

### Performance

- Async HTTP non-blocking.
- Route construction lazy.
- Token refresh logic retry pattern.

## Positive findings

- `lib/core/network/api_client.dart:73-83` — Token attach clean.
- `lib/core/routes/app_router.dart:94-100` — Native deep link query param handle.
- `lib/core/services/onboarding_permission_service.dart` — `flutter_secure_storage` consume same store với token.
- Constants + theme centralization.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P1

- [ ] **Migrate `http` → `dio`**: interceptor pipeline cho token refresh + error mapping + structured logging.
- [ ] **Deep link arg validation**: `onGenerateRoute` validate arg format trước construct MaterialPageRoute. Defense-in-depth với HS-018.
- [ ] **Certificate pinning**: forward-looking production deploy.

### P2

- [ ] **`debugPrint` guard `kDebugMode`** — `app_router.dart:85`.
- [ ] **Split `app_router.dart`** → sub-router per feature.
- [ ] **Defer Phase 3**: per-service method unit test, per-route transition animation, theme spec.

## Out of scope

- Per-feature provider audit — defer per-feature MOB module.
- `core/error/` exception hierarchy — defer Phase 3.
- `core/notifications/` consumer detail — MOB-M08.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-018](../../../BUGS/INDEX.md) — XSS via deep_link_redirect (BE-M02); cross-link mobile route arg validation.
- ADR INDEX:
  - [ADR-004](../../../ADR/INDEX.md) — API prefix standardization. `api_client.dart` consumer.
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md).
  - `MOB_M04_auth_audit.md` (Task 15 pending) — `_sessionService.readStoredSession()` consumer.
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Steering: `health_system/.kiro/steering/40-security-guardrails.md`.
