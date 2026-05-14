---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---

# Flutter Rules — health_system

Áp dụng khi đang làm việc với file `.dart`.

## Architecture

Clean Architecture per feature: `data/` → `domain/` → `presentation/`

## Key conventions

- **Riverpod 2.x** cho state management
- **GoRouter** cho navigation
- **dio** cho HTTP (centralized trong `lib/core/network/`)
- **Repository pattern** — screen không gọi http trực tiếp
- **Const constructors** mọi nơi có thể
- **Stateless > Stateful** (default)

## Anti-patterns (flag tự động)

- `setState()` sau `await` không check `mounted`
- `BuildContext` qua async gap
- `dispose()` thiếu cho controller/timer/subscription
- `print()` trong production code
- `dynamic` type ở public API
- Hardcode string/color — dùng theme + app_strings
- Touch target < 48dp (medical app accessibility)

## Commands

- `flutter pub get` sau sửa pubspec
- `flutter analyze` trước commit (zero warnings)
- `flutter test test/<feature>/` trước push
