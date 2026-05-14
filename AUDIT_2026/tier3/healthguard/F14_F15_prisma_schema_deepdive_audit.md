# Deep-dive: F14 + F15 — Prisma schema (Continuous Aggregates view declaration + low-selectivity index)

**File:** `HealthGuard/backend/prisma/schema.prisma`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 4 (FE API layer + Prisma)

## Scope

2 Phase 3 deep-dive topics trong `schema.prisma`:

**F14:** TimescaleDB Continuous Aggregates declaration workaround — 3 CA views (`vitals_5min`, `vitals_hourly`, `vitals_daily`) cần Prisma representation để D-HEA-01 service refactor (F01) consume qua type-safe ORM thay vì `$queryRaw`.

**F15:** Low-selectivity `@@index([deleted_at])` trên `ai_models` line 363 + `ai_model_versions` line 383 — drop hoặc partial migration.

**Out of scope:** Full schema audit (M06 Phase 1 cover), migration history (`prisma/migrations/` no folder, schema managed via `db pull`), other indexes (M06 cover redundant index findings).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | F14: Prisma không hỗ trợ TimescaleDB Continuous Aggregates trực tiếp → workaround unsupported type hoặc raw SQL. F15: low-selectivity index không impact correctness, chỉ wasted storage. |
| Readability | 2/3 | F14: workaround pattern (declare view as model với `@@map` + `@@ignore`) dễ hiểu nhưng manual maintenance cao. F15: 2 indexes literal, dễ identify để drop. |
| Architecture | 2/3 | F14: cần Prisma Client extension hoặc dual-source pattern (Prisma model cho writes, raw SQL cho CA reads). F15: redundant index removal cleanup. |
| Security | 3/3 | F14: CA views chỉ read aggregated, không expose raw user data hơn. F15: index không liên quan security. |
| Performance | 2/3 | F14: nếu service consume CA → 100x faster vs raw vitals (F01 D-HEA-01 fix). F15: low-selectivity index `WHERE deleted_at IS NULL` chiếm >90% rows → index không filter, wasted B-tree storage + insert/update overhead. |
| **Total** | **11/15** | Band: **🟡 Healthy** (combined F14 + F15) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M06 findings (all confirmed):**

1. ✅ **3 TimescaleDB hypertables không declare trong Prisma** (M06 P1) — confirmed `vitals`, `motion_data`, `system_metrics` declared là regular tables, KHÔNG có view declaration cho `vitals_5min`/`hourly`/`daily` Continuous Aggregates.
2. ✅ **Low-selectivity `@@index([deleted_at])`** (M06 P2) — confirmed lines 363 (`ai_models`) + 383 (`ai_model_versions`).

**Phase 3 new findings (beyond Phase 1 macro):**

### F14 — Continuous Aggregates view declaration

3. ⚠️ **Prisma không hỗ trợ TimescaleDB CA trực tiếp**:
   - TimescaleDB CA = materialized view với refresh policy (canonical SQL `09_create_policies.sql:72-92`).
   - Prisma schema language không có `view` keyword (Prisma 6.19.2 vẫn `unsupported`).
   - Workaround options:
     - Option A: raw SQL `prisma.$queryRaw` — string-based, no type safety.
     - Option B: Declare view as Prisma model với `@@map("vitals_5min")` + `@@ignore` flag (mark view không Prisma migrate). Type-safe via generated client.
     - Option C: Generate types từ DB introspect runtime, manual sync schema.prisma.
   - Recommended: Option B — closest to typed ORM pattern, vẫn cần manual sync schema khi CA schema đổi.
   - Priority P1 — depend F01 D-HEA-01 service refactor.
4. ⚠️ **CA refresh policies không control ở Prisma level**:
   - Refresh policies (5min/1h/1d) trong canonical SQL `09_create_policies.sql:72-92`.
   - Prisma không gen migration cho `add_continuous_aggregate_policy(...)`.
   - Phase 5+ migration sang Prisma managed → cần raw migration SQL parallel.
   - Priority P3.
5. ⚠️ **CA view declaration field types**:
   - Cần khai báo Prisma model field types khớp với CA SELECT clause.
   - Vd `vitals_5min` có columns: bucket TIMESTAMPTZ, device_id INT, avg_heart_rate FLOAT, avg_spo2 FLOAT, count BIGINT, etc.
   - Nếu canonical SQL CA schema đổi → schema.prisma không tự sync → drift silent.
   - Fix: post-fix add CI lint check schema.prisma vs canonical SQL CA schema match.
   - Priority P3 — Phase 5+ CI integration.
6. ⚠️ **Service consumer pattern cần refactor F01**:
   - F01 hiện tại dùng `prisma.vitals.groupBy({ by: ['time'] })` (D-HEA-01 bug).
   - Sau F14 fix: `prisma.vitals_5min.findMany({ where: ... })` type-safe.
   - Effort F01 P1 ~3h depend trên F14 declare CA model.
   - Priority P1 cùng cluster F01 D-HEA-01.

### F15 — Low-selectivity `@@index([deleted_at])`

7. ⚠️ **`@@index([deleted_at])` trên `ai_models` + `ai_model_versions`** (lines 363, 383):
   - Filter `WHERE deleted_at IS NULL` chiếm majority rows (>90% active records).
   - PostgreSQL không dùng index nếu predicate match >5-10% rows (cost-based optimizer chọn seq scan).
   - Index waste: storage + insert/update overhead × N rows.
   - Useful chỉ khi query `WHERE deleted_at IS NOT NULL` để list archived (rare).
   - Priority P2.
8. ⚠️ **Partial index alternative**:
   - PostgreSQL hỗ trợ `CREATE INDEX ... WHERE deleted_at IS NOT NULL` — index chỉ deleted rows (~5% data).
   - Useful cho admin "view trash" feature nếu có.
   - Prisma schema language không hỗ trợ partial index trực tiếp → cần raw migration SQL.
   - Priority P3 — Phase 4 raw SQL migration.
9. ⚠️ **3 model khác có `deleted_at` không có index**:
   - `users.deleted_at`, `devices.deleted_at`, `user_relationships.deleted_at` — soft delete fields.
   - Không có `@@index([deleted_at])` (M06 không flag).
   - OK vì pattern: query active records (`WHERE deleted_at IS NULL`) dùng composite index `(user_id, created_at)` etc.
   - F15 chỉ flag `ai_models` + `ai_model_versions` vì 2 model này có standalone deleted_at index.
   - Priority N/A — accept consistent pattern.

### Correctness (2/3)

- ✓ M06 finding correctness preserve — F14/F15 không introduce new correctness bugs.
- ✓ Prisma schema valid syntax (auto-generated từ `db pull`, validated bởi Prisma generator).
- ⚠️ **F14 P1** — Prisma không gen type cho CA → admin BE health.service.js (F01) phải dùng raw SQL untyped.
- ⚠️ **F15 P2** — wasted storage + insert/update overhead, không impact correctness.

### Readability (2/3)

- ✓ Schema syntax declarative, easy scan.
- ✓ M06 noted 22x auto-generated comments noise — same applies F14/F15.
- ⚠️ **F14 P2** — view declaration workaround pattern manual + verbose.
- ⚠️ **F15 P3** — 2 indexes literal dễ identify, drop dễ.

### Architecture (2/3)

- ✓ Schema đúng intent: ORM mapping cho relational tables.
- ⚠️ **F14 P2** — Dual-source pattern: Prisma model cho `vitals` writes (insert telemetry) + Prisma view declaration cho `vitals_*` CA reads (admin dashboard analytics). Architectural complexity nhưng cần thiết.
- ⚠️ **F15 P3** — index removal trivial cleanup.

### Security (3/3)

- ✓ CA views chỉ read aggregated (avg, count, min/max) — không expose raw individual user data.
- ✓ `@@index([deleted_at])` không liên quan security.
- ✓ Soft delete pattern (`deleted_at IS NULL` filter) consistent.

### Performance (2/3)

- ✓ M06 indexes coverage tốt cho FK + time DESC.
- ⚠️ **F14 P1 (high impact)** — Service refactor consume CA → query 30d × 100 devices × 86400 rows/day = 2.6 tỷ rows tiềm năng → CA aggregate to ~3000 rows (30d × 100 devices × 1 row/day). 100-1000x speedup.
- ⚠️ **F15 P2 (low-medium impact)** — index waste storage ~10-20% extra cho 2 model. Insert/update overhead minor.

## Recommended actions (Phase 4)

### F14 — P1 cùng cluster F01 D-HEA-01 fix

- [ ] **P1** — Declare 3 CA views là Prisma model với `@@map("vitals_5min")` + `@@ignore` flag (verify Prisma 6.19.2 `@@ignore` behavior — possibly cần manual `prisma generate` sau `db pull`). Field types khớp với CA SELECT clause: bucket Timestamptz, device_id Int, avg_heart_rate Float?, avg_spo2 Float?, count BigInt. Tương tự cho `vitals_hourly`, `vitals_daily`. Priority P1 ~1h depend F01 D-HEA-01 service refactor.

### F15 — P2 + P3 raw migration SQL

- [ ] **P2** — Drop `@@index([deleted_at])` trên `ai_models` + `ai_model_versions` qua raw migration SQL: DROP INDEX IF EXISTS `ai_models_deleted_at_idx` + `ai_model_versions_deleted_at_idx`. ~5 min.
- [ ] **P3 (Phase 5+ if needed)** — Add partial index nếu có "view trash" admin feature: CREATE INDEX ... WHERE deleted_at IS NOT NULL. Defer until feature request.

### Cross-cutting Prisma cleanup

- [ ] **P3** — Post-fix CI lint check schema.prisma vs canonical SQL CA schema match (~2h Phase 5+ CI integration).
- [ ] **P3** — Document Prisma view declaration workaround trong README (~30 min).

## Out of scope (defer)

- Full TimescaleDB hypertable management qua Prisma — Phase 5+ feature.
- Continuous Aggregates refresh policy management qua Prisma — Phase 5+ raw migration.
- Schema migration history rebuild (`prisma migrate dev` from current state) — Phase 4/5+ decision.
- Other low-selectivity indexes (`is_active`, `is_verified`) — verify Phase 5+.
- Schema documentation generation (Prisma ERD) — Phase 5+ tool integration.

## Cross-references

- Phase 1 M06 audit: [tier2/healthguard/M06_prisma_schema_audit.md](../../tier2/healthguard/M06_prisma_schema_audit.md) — root flags F14/F15.
- F01 `health.service.js` deep-dive — D-HEA-01 service refactor depend F14.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-01 CA usage decision.
- Canonical SQL: `PM_REVIEW/SQL SCRIPTS/04_create_tables_timeseries.sql:106-173` — CA schema source.
- Canonical SQL: `PM_REVIEW/SQL SCRIPTS/09_create_policies.sql:72-92` — CA refresh policies.
- ADR-010: [ADR/010-devices-schema-canonical.md](../../../ADR/010-devices-schema-canonical.md) — schema canonical decision.
- Steering SQL: `.kiro/steering/25-docs-sql.md` — `init_full_setup.sql` canonical schema rule.
- Precedent format: [tier3/healthguard-model-api/F6_health_sleep_schemas_audit.md](../healthguard-model-api/F6_health_sleep_schemas_audit.md) — tier3 schema deep-dive format.

---

**Verdict:** F14 + F15 combined — 11/15 Healthy band. F14 P1 high-impact: Prisma view declaration workaround unblock F01 D-HEA-01 100-1000x perf speedup (~1h schema work + ~3h F01 service refactor). F15 P2 low-impact: drop 2 redundant indexes (~5 min raw SQL). Sau Phase 4 → 13/15 Mature. F14 prerequisites cho F01 service refactor — sequence tight: F14 first, F01 second.
