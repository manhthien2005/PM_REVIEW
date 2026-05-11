---
trigger: glob
globs: **/*.md
---

# Docs + SQL Rules — PM_REVIEW

Áp dụng cho `PM_REVIEW/` — repo chứa SRS, UC, JIRA backlog, SQL canonical, custom skills.

## Repo purpose

PM_REVIEW là **source of truth** cho:
- **SRS** (Software Requirements Specification)
- **UC** (Use Cases, 26 files trong `Resources/UC/{Module}/`)
- **SQL canonical schema** (`SQL SCRIPTS/`)
- **JIRA backlog** (`Resources/TASK/JIRA/Sprint-{N}/`)
- **Review reports** (`REVIEW_ADMIN/`, `REVIEW_MOBILE/`)
- **Custom skills** anh đã viết — đã migrate vào `.windsurf-template/shared/skills/`

## Khi anh request "tạo task", "review code", "audit UC", v.v.

Invoke skill tương ứng — đã có sẵn trong `.windsurf/skills/`:

| User intent | Skill |
|---|---|
| "review code module X" | `detailed-feature-review` |
| "đánh giá tổng quan" | `TongQuan` |
| "audit UC" | `UC_AUDIT` |
| "sinh test case" | `TEST_CASE_GEN` |
| "lên plan sprint" | `task-manager` |
| "check backlog progress" | `backlog-auditor` |
| "viết SRS/SDD" | `doc-gen` |
| "review screen Flutter" | `mobile-agent` (mode REVIEW) |
| "check project sync" | `CHECK` |

## File naming conventions

- **UC:** `UC{XXX}.md` (3 chữ số) trong module folder. UC001 = Login.
- **Review report:** `{FEATURE}_{MODULE}_review.md` trong `REVIEW_ADMIN/` hoặc `REVIEW_MOBILE/`.
- **Test case:** `{FUNCTION}_testcases.md` trong `TESTING/{MODULE}/`.
- **SQL:** `{NN}_{name}.sql` với prefix số thứ tự execution order.
- **JIRA Sprint:** `Sprint-{N}/_SPRINT.md`, `Sprint-{N}/{EpicCode}-{Name}/_EPIC.md`, `STORIES.md`.

## Vietnamese language convention

- **Section headers tiếng Việt** cho reports/UCs/specs (stakeholder đọc).
- **Skill instructions tiếng Anh** (AI parse tốt hơn).
- **Template (UC, _SPRINT, _EPIC, STORIES):** giữ exact format hiện có. Không improvise.

## SQL discipline

### Khi cần update schema

1. **Identify change** — column add/remove/rename.
2. **Update canonical** `SQL SCRIPTS/init_full_setup.sql` cuối cùng.
3. **Migration script** đặt tên `YYYYMMDD_<desc>.sql` trong `SQL SCRIPTS/migrations/`.
4. **Update cross-repo:**
   - HealthGuard: `prisma migrate dev`
   - health_system backend: SQLAlchemy model hoặc raw query
5. **Update SRS** nếu schema change ảnh hưởng to UC.

### SQL conventions

- `snake_case` cho table + column.
- Plural table name (`users`, `fall_events`).
- Foreign key suffix `_id`: `user_id`, `device_id`.
- Timestamp 2 cột: `created_at`, `updated_at`.
- Soft delete (nếu dùng): `deleted_at NULL`.
- Audit log table: ref `Audit_Log_Specification.md`.

## UC discipline

Mỗi UC phải có (xem skill `UC_AUDIT` để detail):

- Spec table header (UC ID, Name, Actor, Goal, Priority)
- Main Flow (≤ 10 steps)
- Alternative Flows (numbered, link to main flow step)
- Business Rules (BR-XXX)
- NFR (Performance, Security, Usability)
- Data Fields (referenced trong flow)

## Cross-references

Khi reference giữa các files, dùng relative path:
- `[UC001](../UC/Authentication/UC001.md)`
- `[EP04-Login](../TASK/JIRA/Sprint-1/EP04-Login/_EPIC.md)`

Update bi-directional khi tạo link mới.

## Anti-patterns flag tự động

- UC chưa có Alt Flow nhưng đã có Story trong JIRA → likely missing edge case
- SQL `SELECT *` trong canonical script
- Migration file edit sau khi đã commit
- UC reference table mà table không tồn tại trong SQL
- JIRA Story reference UC mà UC không tồn tại
- Vietnamese trong instruction skill (giảm AI parse accuracy)

## Khi anh request thay đổi PM_REVIEW

- **Mọi update** → cập nhật `MASTER_INDEX.md` tương ứng.
- **Skill output report** → overwrite cùng filename (không tạo file mới với date suffix).
- **Cross-link consistency** → khi thêm UC mới, update `00_DANH_SACH_USE_CASE.md` + JIRA README.
