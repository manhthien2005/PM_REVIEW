---
inclusion: fileMatch
fileMatchPattern: "**/*.{sql,md}"
---

# Docs + SQL Rules — PM_REVIEW

Áp dụng khi đang làm việc với file SQL hoặc Markdown trong PM_REVIEW.

## SQL conventions

- **Canonical schema:** `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql`
- **Migration scripts:** `YYYYMMDD_<desc>.sql`
- **Table naming:** `snake_case`, plural (`users`, `fall_events`)
- **Column naming:** `snake_case`
- **Always include:** `created_at`, `updated_at` timestamps
- **Soft delete:** `deleted_at` nullable timestamp (where applicable)

## Documentation conventions

- **UC format:** follow template in `PM_REVIEW/Resources/UC/`
- **Vietnamese** cho doc nội bộ, technical terms giữ English
- **MASTER_INDEX.md** phải được update khi thêm UC/SRS mới
- **SRS_INDEX.md** phải sync với actual SRS files

## When changing SQL schema

1. Update canonical `init_full_setup.sql`
2. Write migration script
3. Update Prisma schema (HealthGuard)
4. Update FastAPI models (health_system/backend)
5. Test both backends
