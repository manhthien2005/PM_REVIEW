---
inclusion: always
---

# Testing Discipline

Solo dev không có QA team. Test là bảo hiểm sinh tồn khi refactor.

## Iron law

- **Tests trước/cùng implement** cho feature mới.
- **Bug fix luôn có regression test.**
- **Không claim done** trước khi verify (chạy test, đọc output).
- **Không weaken/disable test** khi nó fail — root-cause trước.

## Test pyramid per stack

### Flutter (`health_system/test/`)
- Unit: business logic, models, repositories, providers
- Widget: UI behavior (state changes, gestures)
- Integration: `integration_test/` (real device)
- Run: `flutter test test/<feature>/`

### FastAPI (`tests/`)
- Unit: services, validators
- Contract: API endpoint shape (TestClient)
- Integration: with test DB
- Run: `pytest tests/<file>::<test_func>`

### Express + Prisma (`HealthGuard/backend/src/__tests__/`)
- Unit: services, validators
- Integration: API route → service → mock Prisma
- Run: `npm test -- <file>`

### React + Vite (`HealthGuard/frontend/`)
- Unit: hooks, utilities
- Component: render + fire event + assert
- Run: `npm test -- <component>`

## Rules

- Test ở **boundary** (API surface, repository return), không test internal implementation.
- **No production data trong test.** Factory/builder pattern.
- **Deterministic.** Mock time/network/random.
- **Flaky test = banned.** Find root cause (race condition, missing await, shared state).
- Coverage target: **60–70%** cho code mới. Don't chase 100%.
