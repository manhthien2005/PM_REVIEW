---
inclusion: always
---

# Stack Conventions — Branching, Commits, Versioning

## Branch naming

**Format:** `<type>/<short-desc>` (kebab-case, ≤ 50 chars)

- `feat/<desc>` — feature mới
- `fix/<desc>` — bug fix
- `chore/<desc>` — infra, config
- `refactor/<desc>` — restructure không đổi behavior
- `docs/<desc>` — documentation only

## Commit message — Conventional Commits

**Format:** `<type>(<scope>): <subject tiếng Việt>`

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `style`, `perf`, `build`, `ci`

Ví dụ:
```
feat(fall): thêm full-screen alert khi phát hiện ngã
fix(sos): countdown reset khi user nhấn cancel
chore: dọn dẹp file rác AI tooling
```

Body (khi non-trivial): giải thích **WHY**, không phải WHAT.

## PR flow

1. Branch từ trunk → Code + test → Self-review → Push → PR
2. **Cấm push trực tiếp lên trunk.**

## Migration discipline

- **Prisma** (HealthGuard): `npx prisma migrate dev --name <desc>`
- **FastAPI/Python:** raw SQL scripts `PM_REVIEW/SQL SCRIPTS/YYYYMMDD_<desc>.sql`
- **Canonical schema:** `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` (sửa cuối cùng)

## Naming code

- **JS/Dart:** `camelCase` (var/function), `PascalCase` (class)
- **Python:** `snake_case` (var/function), `PascalCase` (class)
- **DB:** `snake_case` table + column, plural table name
