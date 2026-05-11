# Module Inventory — health_system mobile (Flutter)

**Repo:** `health_system/`
**Stack:** Flutter 3.11 + Riverpod 2.x + GoRouter + http package
**Role:** Mobile app cho elderly/caregiver user — vitals view, SOS, fall alerts, family monitoring
**Path:** `health_system/lib/`
**Total LoC scope:** ~25,000+ (mobile = largest LoC in workspace)
**Phase 1 track suggestion:** Track 3 (parallel)

---

## Overview

Mobile app dùng **clean architecture per feature** với 12 features độc lập. Riverpod state mgmt, GoRouter navigation, http package cho REST API calls.

**Critical user flows:**
- Login → JWT bearer → vitals fetch → display
- SOS trigger → backend POST → push notification fanout
- Fall detection alert → full-screen overlay → user response (dismiss/help/timeout)
- Family monitoring (caregiver view linked patients)

**Known concerns từ Phase -1:**
- Mobile expects `/api/v1/mobile/*` base URL (ADR-004 standardize affects this)
- Severity vocabulary mapping (D1 decision): mobile currently bucket `high→medium` — UX gap, fix Phase 4
- `notification_severity.dart` mapping (D1 fix point)

---

## Modules

### M01: `lib/app.dart` + `main.dart` — Bootstrap

**Path:** `health_system/lib/`
**LoC:** ~300
**Effort:** S (~1h)
**Priority:** P1
**Dependencies:** core/, all features

**Audit focus:**
- Architecture: ProviderScope, theme setup, route config
- Security: dotenv load, no debug log in production
- Performance: const constructors

### M02: `lib/core/` — Cross-cutting

**Path:** `health_system/lib/core/`
**Files:** 14 items (network, routes, theme, services, etc.)
**LoC:** ~3,000
**Effort:** L (~10h)
**Priority:** P0 (foundational)
**Dependencies:** —

**Sub-modules:**
- `core/network/` — API client (analyzed Phase -1.C)
- `core/routes/` — GoRouter config + deep link handler
- `core/network/risk_contract_version.dart` — middleware-aware
- `core/services/` — FCM, secure storage, notification runtime

**Audit focus:**
- Security: token storage (must `flutter_secure_storage` NOT shared_preferences), TLS pinning
- Architecture: ApiClient singleton pattern, refresh token rotation
- Correctness: 401 retry logic (already exists), deep link routing
- Performance: HTTP client reuse, connection pool

### M03: `lib/shared/` — Shared widgets + theme

**Path:** `health_system/lib/shared/`
**Files:** 15 items
**LoC:** ~2,000
**Effort:** M (~5h)
**Priority:** P1
**Dependencies:** —

**Audit focus:**
- Readability: widget naming, organization
- Architecture: reusability (DRY check)
- Accessibility: min font 16sp, min touch 48dp (medical app — elderly UX)

### M04: `features/auth/` — Login + register flow

**Path:** `health_system/lib/features/auth/`
**Files:** 22 items
**LoC:** ~2,500
**Effort:** M (~6h)
**Priority:** P0 (security + UX critical)
**Dependencies:** core/network, core/services

**Audit focus:**
- Security: password input, biometric optional, session persistence
- Correctness: 8 backend auth endpoints flow (register → verify → login → refresh → reset)
- Architecture: clean arch (data/domain/presentation)

### M05: `features/device/` — Device pairing + management

**Path:** `health_system/lib/features/device/`
**Files:** 35 items (one of largest features)
**LoC:** ~3,500
**Effort:** L (~8h)
**Priority:** P0 (mandatory for vitals flow)
**Dependencies:** core/network, BLE plugins

**Audit focus:**
- Correctness: BLE scan/pair flow, permission handling
- Security: device serial validation, no spoof
- Performance: connection state mgmt

### M06: `features/family/` — Caregiver/patient linking

**Path:** `health_system/lib/features/family/`
**Files:** 45 items (LARGEST feature)
**LoC:** ~4,500
**Effort:** L (~12h)
**Priority:** P0 (multi-recipient flow — notification_reads design D3)
**Dependencies:** core/network

**Audit focus:**
- Architecture: family graph data model, sync state
- Correctness: invitation accept/reject flow
- Security: privacy controls (can_view_vitals, can_view_location flags)

### M07: `features/health_monitoring/` — Vitals view

**Path:** `health_system/lib/features/health_monitoring/`
**Files:** 23 items
**LoC:** ~3,000
**Effort:** L (~8h)
**Priority:** P0 (primary value)
**Dependencies:** core/network, charting lib

**Audit focus:**
- Performance: real-time chart rendering, list virtualization
- Correctness: vitals data freshness, offline handling
- Readability: dashboard widget composition

### M08: `features/notifications/` — Notification list + detail

**Path:** `health_system/lib/features/notifications/`
**Files:** 18 items
**LoC:** ~2,500
**Effort:** M (~6h)
**Priority:** P0 (D1 severity vocab fix point + D3 read state)
**Dependencies:** core/services FCM

**Audit focus:**
- Correctness: D1 fix — bucket `high` separately from `medium` (severity mapping)
- Architecture: notification source-of-truth from `notification_reads` (D3)
- Security: deep link from notification handling

### M09: `features/emergency/` + `features/fall/`

**Path:** `health_system/lib/features/{emergency, fall}/`
**Files:** emergency 17 + fall 8 = 25 items
**LoC:** ~2,500
**Effort:** L (~8h)
**Priority:** P0 (life-critical — SOS + fall alert flow)
**Dependencies:** core/services (full-screen intent), location plugin

**Audit focus:**
- Correctness: SOS trigger flow (fall detect → countdown → dismiss/timeout → push)
- Security: location permission, emergency contact dispatch
- UX: 56dp emergency button (elderly), high contrast, audio cue
- Performance: alert overlay rendering speed

### M10: `features/analysis/` — Health risk analysis

**Path:** `health_system/lib/features/analysis/`
**Files:** 34 items
**LoC:** ~3,500
**Effort:** L (~8h)
**Priority:** P1 (insight feature, not life-critical)
**Dependencies:** core/network risk endpoints

**Audit focus:**
- Correctness: risk_score display, XAI explanation rendering
- Readability: chart components, recommendation display
- Performance: heavy data viz optimization

### M11: `features/sleep_analysis/`

**Path:** `health_system/lib/features/sleep_analysis/`
**Files:** 18 items
**LoC:** ~2,000
**Effort:** M (~5h)
**Priority:** P1
**Dependencies:** core/network sleep endpoints

**Audit focus:**
- Correctness: sleep phase visualization
- Performance: history list virtualization

### M12: `features/home/` + `features/profile/` + `features/onboarding/`

**Path:** `health_system/lib/features/{home, profile, onboarding}/`
**Files:** home 14 + profile 11 + onboarding 1
**LoC:** ~2,000
**Effort:** M (~5h)
**Priority:** P1
**Dependencies:** —

**Audit focus:**
- Architecture: home dashboard composition
- UX: onboarding flow completeness
- Profile: medical info input validation

---

## Phase 1 macro audit plan

**Track 3 sequential** (em một mình, mobile too large for parallel within track):

| Order | Module | Effort | Why |
|---|---|---|---|
| 1 | M01 (Bootstrap) | 1h | Init context |
| 2 | M02 (Core) | 10h | Foundation — network/security |
| 3 | M03 (Shared) | 5h | Reusable widgets |
| 4 | M04 (Auth) | 6h | Login flow |
| 5 | M05 (Device) | 8h | Pairing flow |
| 6 | M08 (Notifications) | 6h | D1+D3 fix point |
| 7 | M09 (Emergency+Fall) | 8h | Life-critical |
| 8 | M07 (Health monitoring) | 8h | Primary feature |
| 9 | M06 (Family) | 12h | Multi-recipient complexity |
| 10 | M10 (Analysis) | 8h | Insight |
| 11 | M11 (Sleep) | 5h | |
| 12 | M12 (Home/profile/onboarding) | 5h | |

**Track 3 total:** ~82h (largest track)

⚠️ Mobile track effort 82h là pessimistic. Em đề xuất Phase 1 macro audit cho mobile **skim mode** (focus architecture + security per feature, defer detailed per-screen review tới Phase 3).

**Realistic Track 3:** ~40-50h skim mode.

---

## Phase 3 deep-dive candidates

- [ ] `core/network/api_client.dart` — verify ADR-004 base URL after refactor
- [ ] `core/network/risk_contract_version.dart` — middleware contract version
- [ ] `core/services/notification_runtime_service.dart` — FCM foreground
- [ ] `core/services/notification_open_router.dart` — deep link routing
- [ ] `features/notifications/utils/notification_severity.dart` — D1 severity bucket fix
- [ ] `features/emergency/screens/*` — SOS trigger flow correctness
- [ ] `features/fall/widgets/fall_overlay_screen.dart` — full-screen alert
- [ ] `features/auth/services/auth_session_service.dart` — token persistence

---

## Out of scope

- Native iOS/Android code (em focus Dart)
- pubspec.yaml deps upgrade
- Integration tests (defer, separate)
- App store metadata
- Push notification platform setup (FCM console)
- E2E flow tests
