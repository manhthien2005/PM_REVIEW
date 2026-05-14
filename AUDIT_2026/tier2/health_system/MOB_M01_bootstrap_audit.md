# Audit: MOB-M01 — bootstrap (Flutter app entry + initialization)

**Module:** `health_system/lib/{app, main}.dart`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim

## Scope

Module bootstrap chứa entry point Flutter app: `main.dart` (binding init + dotenv load + Firebase init + Supabase init + runApp) + `app.dart` (HealthSystemApp Stateful root + ProviderScope multi-provider + deep link handler + auth bootstrap gate). Scope SkimMode = Architecture + Security focus, defer per-screen detail. ~250 LoC total.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | 4-step init defensive (try/except mỗi step + log debug). Deep link handler 2 flow OK. Trừ điểm: dotenv load `bool.fromEnvironment('dart.vm.product')` thay `kReleaseMode`; deep link not handle action=invite_caregiver flow; defer per-screen. |
| Readability | 2/3 | Comment Vietnamese + English mix. `==== MAIN STARTED ====` debug print pattern dev-friendly nhưng cần guard production. ProviderScope 12 provider rõ trong MultiProvider block. |
| Architecture | 2/3 | MultiProvider root pattern đúng cho ChangeNotifierProvider. AuthBootstrapGate FutureBuilder sequence correct. Trừ điểm: `_navigatorKey` global state qua `_sosRealtimeAlertService.bindNavigatorKey()` — singleton coupling. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. dotenv consume `.env.dev`/`.env.prod` đúng convention. Trừ điểm: `debugPrint` ra production có thể leak debug info trong release build (cần `kReleaseMode` guard). |
| Performance | 3/3 | Async init không block UI thread. `runApp` sau bind init. ProviderScope lazy-create providers. |
| **Total** | **11/15** | Band: **🟡 Healthy** — không Security=0 override. |

## Findings

### Correctness

- `lib/main.dart:18-21` — dotenv load với `bool.fromEnvironment('dart.vm.product')`. Flutter recommend `kReleaseMode` từ `package:flutter/foundation.dart`. P2.
- `lib/app.dart:152-194` — Deep link handler 2 flow (verify-email + reset-password). Acceptable.
- `lib/main.dart:23-49` — 4 try/except blocks cho dotenv/Firebase/Supabase init. Init failure không crash app. Defensive design.
- `lib/app.dart:99-127` — Deep link initial URI handle với `_lastHandledUri` guard tránh re-handle race condition. Good.

### Readability

- `lib/main.dart:8` — `debugPrint("==== MAIN STARTED ====")` — production output trong release. P2 guard `kDebugMode`.
- `lib/main.dart:13` — Comment Vietnamese trong source. Steering convention English. P2.
- `lib/app.dart:200-220` — MultiProvider 12 entry rõ ràng. Comment "Phase 8 / slice 4a" cross-reference plan.

### Architecture

- **MultiProvider root pattern**: 12 ChangeNotifierProvider + `NotificationRuntimeAuthBridge` wrapper. Pattern provider DI đúng Flutter idiomatic. OK.
- **Singleton coupling**:
  - `SOSRealtimeAlertService.instance` — singleton accessed via static.
  - `_navigatorKey` GlobalKey passed vào singleton via `bindNavigatorKey()`.
  
  Mix singleton vs provider DI. Singleton OK cho global state nhưng test override khó. P2.

- **AuthBootstrapGate FutureBuilder**: pattern correct cho async session resolve trước route. OK.

- **Deep link handler trong State**: logic giấu trong `_HealthSystemAppState`. Cần extract sang `DeepLinkService` cho test isolation. P2.

### Security

- **Anti-pattern auto-flag scan**: 0 hit. Security=0 override KHÔNG áp dụng.
  - Token in localStorage / SharedPreferences? **NO** — verify cross-grep: `flutter_secure_storage` được dùng đúng (token_storage_service.dart).
  - Hardcoded secret? **NO** — dotenv consume.

- `lib/main.dart:23` — dotenv consume env file. Steering compliance. OK.
- `lib/main.dart:33` — Firebase init không pass option (default config từ google-services.json). Steering forbid commit `google-services.json` — verify `.gitignore` Phase 4 P1.
- `lib/main.dart:39-47` — Supabase init guard `if (env not empty)`. Defensive.
- `debugPrint` trong production release build có thể leak debug context. P2 guard.
- `lib/app.dart:152-194` — Deep link handler accept query param từ external app. Mobile-side accept any string + pass thẳng vào navigator route argument → service-side validate (BE-M02 HS-018 reference).

### Performance

- Async init non-blocking. UI thread không block.
- `WidgetsBinding.instance.addPostFrameCallback` defer đến post-frame.
- ChangeNotifierProvider lazy-create.
- `flutter_native_splash` remove sau post-frame callback.

## Positive findings

- `lib/main.dart:8-55` — defensive try/except 4 init step. Init failure không crash app.
- `lib/main.dart:33-37` — Firebase background message handler register đúng pattern.
- `lib/app.dart:99-127` — Deep link `_lastHandledUri` guard chống re-handle race condition.
- `lib/app.dart:200-220` — MultiProvider clean với 12 ChangeNotifierProvider.
- `lib/app.dart:159-178` — `AuthBootstrapGate` FutureBuilder pattern.
- `flutter_secure_storage` consume đúng cho token storage (cross-link MOB-M04).
- `flutter_dotenv` consume `.env.dev`/`.env.prod` đúng steering convention.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P0

- [ ] Không có action P0.

### P1

- [ ] **Verify `.gitignore` block `google-services.json` + `GoogleService-Info.plist` + `.env.prod`/`.env.dev` actual files** (chỉ commit `.env.example`).

### P2

- [ ] **`bool.fromEnvironment('dart.vm.product')` → `kReleaseMode`** từ `package:flutter/foundation.dart`.
- [ ] **`debugPrint` guard `kDebugMode`** — release build không leak debug context.
- [ ] **Vietnamese comment trong source** — chuyển sang English kỹ thuật (steering convention).
- [ ] **Extract `DeepLinkService` từ `_HealthSystemAppState`** — test isolation.
- [ ] **Singleton vs Provider DI**: `SOSRealtimeAlertService.instance` migrate sang Provider/Riverpod.
- [ ] **Defer Phase 3**: per-screen splash flow, localization setup detail, MaterialApp theme audit.

## Out of scope

- Per-feature provider audit — defer Phase 3 hoặc per-feature MOB module.
- `core/routes/app_router.dart` route definition — MOB-M02 core scope.
- `flutter_native_splash` config — UX scope.
- `firebase_messaging` background handler implementation — MOB-M08 notifications scope.
- `Supabase.initialize` consumer detail — MOB-M12 scope.
- Defer Phase 3: per-screen widget audit, animation flow.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-018](../../../BUGS/INDEX.md) — XSS via deep_link_redirect (BE-M02); cross-link mobile deep link consumer.
- ADR INDEX:
  - [ADR-009](../../../ADR/INDEX.md) — Avatar storage Supabase. Bootstrap Supabase init consumer.
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md) — HS-018 deep_link_redirect XSS.
  - `MOB_M02_core_audit.md` (Task 13 pending).
  - `MOB_M04_auth_audit.md` (Task 15 pending) — token_storage_service.
  - `MOB_M08_notifications_audit.md` (Task 17 pending).
  - `MOB_M09_emergency_fall_audit.md` (Task 18 pending) — SOSRealtimeAlertService.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Steering: `health_system/.kiro/steering/40-security-guardrails.md`.
