---
inclusion: manual
---

# Skill: Flutter Mobile Patterns (health_system)

## Architecture — Clean Architecture per feature

```
lib/features/<feature>/
├── data/
│   ├── models/         # JSON (de)serialization
│   └── repositories/   # data source impl
├── domain/
│   ├── entities/       # pure dart domain models
│   └── repositories/   # abstract interfaces
└── presentation/
    ├── providers/      # Riverpod state
    ├── screens/        # page widgets
    └── widgets/        # local reusable
```

## State management — Riverpod 2.x

- `Provider` → immutable computed
- `StateProvider` → simple primitive
- `StateNotifierProvider` → complex state + business logic
- `FutureProvider` / `StreamProvider` → async data
- Async safety: check `mounted` trước setState/Navigator sau await

## Widget rules

- Stateless > Stateful (default)
- Const constructors everywhere
- Extract widget khi `build()` > 100 dòng
- Không nested ternary trong build

## Navigation — GoRouter

- Router config: `lib/core/routes/app_router.dart`
- Không push routes trực tiếp — dùng route name + params
- Deep link / FCM: qua `notification_open_router.dart`

## Network — dio + Repository pattern

- HTTP client centralized: `lib/core/network/`
- Screen không gọi http trực tiếp → qua repository
- Error handling: `Either<Failure, T>` hoặc Result type

## FCM

- Foreground: `notification_runtime_service.dart`
- Background: `FirebaseMessagingService` + `onBackgroundMessage`
- Fall alert: full-screen intent (Android) + critical alert (iOS)
- Don't navigate từ background handler — store deep link, navigate on resume

## Accessibility (medical app)

- Min font: 16sp body, 14sp caption
- Min touch target: 48dp (56dp emergency/elderly UI)
- Min contrast: 4.5:1 (WCAG AA)
- TalkBack/VoiceOver semantic labels
- Bottom 40% screen cho main actions (thumb zone)
