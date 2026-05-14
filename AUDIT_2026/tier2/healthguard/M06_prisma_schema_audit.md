# Audit: M06 — Prisma schema (ORM mapping)

**Module:** `HealthGuard/backend/prisma/schema.prisma` (single file, 577 LoC)
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 1A (HealthGuard backend)

## Scope

Single file `schema.prisma` chứa:
- 24 model declarations (alerts, audit_logs, devices, emergency_contacts, fall_events, motion_data, risk_explanations, risk_scores, sos_events, system_metrics, system_settings, user_relationships, users, password_reset_tokens, vitals, users_archive, sleep_sessions, ai_models, ai_model_versions, user_fcm_tokens, notification_reads, risk_alert_responses, user_push_tokens, ai_model_mlops_states)
- 4 enum declarations (`alert_severity`, `risk_level`, `sos_status`, `user_role`)
- Datasource + generator config

**Out of scope:** migration history (prisma/migrations/ — no folder exists in this repo, schema managed via `db pull`), canonical SQL diff (covered by Phase -1 tier1/db_canonical_diff.md), runtime query patterns (M04 services).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | FK relations declared, indexes on query hot paths. Drift: `alert_severity` enum declared nhưng `alerts.severity` vẫn String VARCHAR; `risk_level` enum có `'high'` bị D-HEA-07 loại bỏ (3 levels after Phase 4). |
| Readability | 2/3 | Prisma auto-generated comments (`/// This table contains check constraints...`) lặp lại 22 lần gây noise. Nhưng model field naming consistent snake_case. |
| Architecture | 2/3 | 3 time-series bảng (vitals/motion_data/system_metrics) chưa có `@@map` tới TimescaleDB hypertable (Prisma không quản). `users_archive` dead-ish (orphan). `user_fcm_tokens` zombie (drift -1 D2, 0 refs code). |
| Security | 2/3 | Credential column named `password_hash` (hashed, no plaintext column). `audit_logs.ip_address` Inet type. `user_push_tokens.token` Unique. Không dùng Prisma row-level security (rely on app-layer). Composite PK trên `audit_logs` + `motion_data` + `vitals` + `system_metrics` prevent duplicate writes. |
| Performance | 2/3 | Index coverage tốt (30+ indexes trên FK + time DESC). Nhưng `ai_model_mlops_states.payload` JSONB có GIN index — pattern OK; `system_metrics.tags` cũng GIN. 1 issue: `@@index([deleted_at])` trên `ai_models` + `ai_model_versions` — filter `deleted_at IS NULL` chiếm majority rows → low selectivity index. |
| **Total** | **10/15** | Band: **🟡 Healthy** |

## Findings

### Correctness (2/3)

- ✓ `alerts` (lines 13-42) — FK `user_id` NOT NULL với `onDelete: Cascade`, `device_id` nullable với NoAction. Matches canonical semantics.
- ✓ `audit_logs` (lines 46-67) — composite PK `(id, time)` → TimescaleDB hypertable candidate, indexes time DESC + (user_id, time) + (action, time).
- ✓ `devices` (lines 70-97) — nullable `user_id` với NoAction → device có thể unassigned (drift DEVICES D-DEV-10 ratify); `deleted_at` soft delete.
- ✓ `fall_events` + `sos_events` — FK `device_id` Cascade khi delete device → events gone theo device; `fall_event_id` nullable trên sos_events → SOS manual không gắn fall.
- ✓ `vitals` + `motion_data` (lines 485-500 + 158-172) — composite PK `(device_id, time)` → TimescaleDB-compatible.
- ✓ `password_reset_tokens` (lines 460-470) — `token_hash` VARCHAR(255), `expires_at` NOT NULL, `used_at` nullable → 1-time-use flag pattern.
- ✓ 4 enums declared (`alert_severity`, `risk_level`, `sos_status`, `user_role`, lines 543-570) mapped đúng semantic.
- ⚠️ **P1 — Enum declaration không enforce** (`alerts.severity`, `sos_events.status`, `risk_scores.risk_level`, `users.role`): 4 enum khai báo ở cuối file (lines 543-575) NHƯNG các column dùng `String @db.VarChar` thay vì enum type reference. → Prisma không enforce enum tại app layer; TypeScript client không có type safety; chỉ DB CHECK constraint (nếu có) enforce. Drift -1.A D1 đã chốt 4 levels + canonical SQL CHECK; Phase 4 D-HEA-07 đổi `risk_level` 4→3 levels (drop 'high') sẽ cần update cả enum declaration + CHECK. Priority P1 — sync lại enum usage khi Phase 4 run.
  - File: `HealthGuard/backend/prisma/schema.prisma:543-570`
- ⚠️ **P1 — `risk_level` enum chứa `'high'` (line 557)** — D-HEA-07 quyết định Phase 4 drop 'high' khỏi admin BE + schema. Schema hiện tại chưa phản ánh quyết định → Phase 4 sync: remove `high` từ enum + DB CHECK + index `08_create_indexes.sql:104`. Priority P1 per drift.
- ⚠️ **P2 — 3 fields dư columns trên `user_relationships`** (lines 329-332: `status`, `primary_relationship_label`, `tags`): admin BE service không dùng, `status` default `'pending'` tạo inconsistency (admin create → DB ghi pending). Drift REL D-REL-05 quyết định Phase 4 service fix `status='active'` + document Phase 5+. Schema giữ nguyên. Priority P2 per drift.
- ⚠️ **P2 — `alerts.sent_via String[]` default `["push"]`** (line 30) — default array literal OK nhưng thiếu CHECK constraint cho element value (no list-of-allowed-channels). Nếu downstream code push `"sms"` → DB accept. Rely on app-layer validation. Priority P3.
- ⚠️ `sos_events.status` `@default("active")` (line 230) — VARCHAR(20) không enforce `sos_status` enum (lines 563-568). Priority P1 cùng group với `risk_level`.

### Readability (2/3)

- ✓ Field naming consistent `snake_case` (DB convention) — không trộn `camelCase`.
- ✓ Type annotations rõ (`@db.Decimal(5, 2)`, `@db.Inet`, `@db.Timestamptz(6)`, `@db.Uuid`) — reader biết chính xác column type.
- ✓ Index names explicit (`map: "idx_alerts_user"`, v.v.) → grep theo index name tìm được query pattern intended.
- ✓ Relation fields named rõ (`users_sos_events_resolved_by_user_idTousers`, `users_user_relationships_caregiver_idTousers`) — Prisma auto-generate từ FK tên, verbose nhưng unambiguous cho schema có 2 FK cùng target table.
- ⚠️ **P3 — 22 bản comment lặp lại `/// This table contains check constraints and requires additional setup for migrations...`** — Prisma generator auto-inject khi pull từ DB có CHECK constraint. Noise làm file khó scan. Giải pháp: chuyển sang manual-managed schema (drop `db pull`) hoặc xoá comment qua post-process script. Priority P3.
- ⚠️ **P3 — Không có 1 dòng module-level comment** — reader mở file không biết intent (schema-first vs DB-first, ai owner, có migrate không). Thêm 5-10 dòng header nên tham khảo canonical SQL. Priority P3.
- ⚠️ `user_relationships` field names verbose (`users_user_relationships_caregiver_idTousers`, lines 336-337) — Prisma quy ước tự sinh, reader phải parse `{base_table}_{fk_name}_{referenced_table}`. Nếu khai báo alias ngắn hơn sẽ readable hơn nhưng chi phí = manual maintenance. Priority P3.

### Architecture (2/3)

- ✓ FK Cascade strategy hợp lý: user-owned data (`alerts`, `devices`, `risk_scores`, `sleep_sessions`, `sos_events user_id`, `password_reset_tokens`, `notification_reads`, `emergency_contacts`, `user_fcm_tokens`, `user_push_tokens`) → Cascade khi user deleted. Shared resources (audit_logs, user_relationships) → NoAction giữ lịch sử.
- ✓ Soft delete pattern (`deleted_at DateTime?`) áp dụng cho `users`, `devices`, `ai_models`, `ai_model_versions`, `user_relationships` — consistent.
- ✓ `audit_logs` composite PK `(id, time)` + time DESC index → TimescaleDB-friendly, partition-by-time candidate.
- ✓ 4 enums declared riêng thay vì inline union → Prisma client type-safe (nếu fields dùng enum type).
- ⚠️ **P1 — 3 TimescaleDB hypertables không declare trong Prisma** (`vitals`, `motion_data`, `system_metrics`): Prisma không hiểu hypertable/continuous aggregates → `vitals_5min`, `vitals_hourly`, `vitals_daily` (canonical SQL `04_create_tables_timeseries.sql`) **không có trong schema**. Hệ quả: Prisma Client không gen type cho CA; admin BE `health.service.js` nếu muốn dùng CA per drift HEALTH D-HEA-01 → phải dùng `prisma.$queryRaw` untyped. Priority P1 (drift-linked).
  - **Action:** per drift/HEALTH.md D-HEA-01 — Phase 4 refactor service use CA: dùng `$queryRaw` với tên view hardcoded, hoặc khai 3 CA làm `view` trong schema.prisma (Prisma không support view trực tiếp, cần `unsupported type` workaround). Effort bổ sung vs drift D-HEA-01 estimate ~1h.
  - File: `HealthGuard/backend/prisma/schema.prisma` (missing model declarations)
- ⚠️ **P2 — `users_archive` orphan table** (lines 507-519): không có FK tới bất kỳ bảng nào, không có service code reference (verify Phase 3). Có thể là artifact cho D-USERS-XX delete-with-archive flow, nhưng nếu unused → dead. Priority P2 — cleanup hoặc document usage.
- ⚠️ **P2 — `user_fcm_tokens` zombie** (lines 400-416): Phase -1 D2 đã flag 0 references, drift decision = deprecated zombie, `user_push_tokens` replaced. Phase 4 task: `prisma migrate dev --name drop_user_fcm_tokens` + schema remove. Priority P2 per drift.
- ⚠️ **P2 — `alerts.read_at` zombie** (line 28): drift -1.A D3 nói `notification_reads` là truth, `alerts.read_at` dead không được mobile BE write. HG-001 root cause trong admin code giả định schema không có `read_at`. Phase 4 cleanup: drop column + admin code pivot sang `notification_reads`. Priority P2 per drift + HG-001 (xem M04 audit).
- ⚠️ **P3 — `ai_model_versions.artifact_sha256` VARCHAR(64)** (line 378): SHA-256 hex = 64 char OK. Nhưng thiếu CHECK regex `^[a-f0-9]{64}$` ở DB layer — app-layer validation chịu trách nhiệm. Rely trust.

### Security (2/3)

- ✓ `users.password_hash` VARCHAR(255) → bcrypt digest typical length ~60 char. Không có column lưu raw credential nào trong schema → pattern R1 reference AUTH.
- ✓ `audit_logs.ip_address @db.Inet` → type-safe, no IP as free-form string.
- ✓ `user_push_tokens.token` `@unique` — prevent duplicate token registrations.
- ✓ `password_reset_tokens.token_hash` VARCHAR(255) — hashed (not raw token), `expires_at` NOT NULL, `used_at` nullable → 1-time-use enforced at app layer.
- ✓ `users.token_version` Int default 1 → pattern R1 reference (token invalidation).
- ✓ `users.failed_login_attempts`, `locked_until`, `verification_code`, `reset_code` — account security state tracked.
- ✓ Composite PK trên time-series tables (`vitals`, `motion_data`, `system_metrics`, `audit_logs`) prevent duplicate inserts at same timestamp.
- ⚠️ **P2 — `users.verification_code` VARCHAR(6) raw-stored** (line 430) + `reset_code` VARCHAR(6) (line 432) — OTP codes stored as plaintext column. Ngắn (6 chars) nên rainbow-table attack tính khả thi nếu DB leak + `expires_at` short window mitigate nhưng không eliminate. Comparison vs `password_reset_tokens.token_hash` đã digest → inconsistent security stance. Priority P2 — hash verification/reset codes khi Phase 4. (Drift AUTH chưa cover topic này → em flag mới, không escalate bug riêng mà để Phase 3 deep-dive.)
  - File: `HealthGuard/backend/prisma/schema.prisma:430-433`
- ⚠️ **P3 — Không dùng Prisma Row-Level Security** — mọi ACL enforce ở app layer (middleware + service). Chấp nhận được nhưng nếu 1 service bug bypass check → DB không có safety net. Priority P3 (Phase 5+ PHI hardening).
- ⚠️ `risk_alert_responses.notification_id @unique` (line 504) — mỗi alert response exactly once. Tốt cho dedup. Không phải issue.

### Performance (2/3)

- ✓ **Index coverage tốt** — 30+ indexes cover FK + time DESC cho hot queries:
  - `(user_id, created_at DESC)` trên `alerts`, `audit_logs`, `risk_scores`, `sleep_sessions`
  - `(device_id, time DESC)` trên `vitals`, `motion_data`
  - `(action, time DESC)`, `(resource_type, resource_id, time DESC)` trên `audit_logs`
  - `(metric_name, time DESC)` trên `system_metrics`
- ✓ **GIN indexes trên JSONB** — `ai_model_mlops_states.payload` (line 540), `system_metrics.tags` (line 267) → đúng cho JSONB contains/path queries.
- ✓ Composite PK time-series (`vitals`, `motion_data`, `system_metrics`) → cluster by `(device_id, time)` hoặc `(metric_name, time)` cho scan efficiency.
- ⚠️ **P2 — Low-selectivity index `@@index([deleted_at])`** trên `ai_models` line 363 + `ai_model_versions` line 383: `deleted_at IS NULL` chiếm >90% rows thường (active records) → index không giúp filter. Useful chỉ khi query `WHERE deleted_at IS NOT NULL` để list archived, rare. Priority P2 — cân nhắc bỏ index hoặc đổi sang partial index `WHERE deleted_at IS NOT NULL` (Prisma không support partial index trực tiếp, cần raw migration SQL).
  - File: `HealthGuard/backend/prisma/schema.prisma:363, 383`
- ⚠️ **P3 — 2 indexes trùng trên `ai_model_versions`**: `@@index([model_id])` (line 386) + `@@unique([model_id, version])` line 385. Unique tạo B-tree có cover model_id lookup → standalone `@@index([model_id])` redundant. Priority P3 — micro optimization.
  - File: `HealthGuard/backend/prisma/schema.prisma:385-386`
- ⚠️ **P3 — `notification_reads` có 3 indexes + 1 composite unique** (lines 424-426): `(user_id, alert_id)` unique + `(alert_id)` + `(id)` + `(user_id)` — unique đã cover user_id lookup. `@@index([id])` redundant với PK. Priority P3.
  - File: `HealthGuard/backend/prisma/schema.prisma:424-426`
- ⚠️ Prisma không quản hypertable compression policies (`09_create_policies.sql` retention + CA refresh) — admin/ops concern, không phải schema concern. Priority N/A.

## Recommended actions (Phase 4)

- [ ] **P1** — Per drift/HEALTH.md D-HEA-07: Sync `risk_level` enum (line 557) drop `'high'` + DB CHECK migration + index update (coordinate với admin BE service fix) (~30 min schema side).
- [ ] **P1** — Per drift/HEALTH.md D-HEA-01: Handle TimescaleDB CA trong Prisma — dùng `$queryRaw` cho `vitals_5min/hourly/daily` hoặc khai báo view workaround (~1h).
- [ ] **P1** — Map cột `severity`, `status`, `risk_level`, `role` sang enum types đã declare (lines 543-575) thay vì VARCHAR free-form — Prisma client type-safe (~30 min + regen client).
- [ ] **P2** — Per Phase -1 D2: Drop `user_fcm_tokens` model + DB migration (~15 min schema + ~15 min migration file).
- [ ] **P2** — Per Phase -1 D3 + HG-001 pivot: Drop `alerts.read_at` column (đồng bộ với admin BE service pivot sang `notification_reads`) (~15 min schema after service fix).
- [ ] **P2** — Per drift/RELATIONSHIP.md D-REL-05: Giữ 3 dư columns trên `user_relationships` (status/primary_relationship_label/tags) + chỉ fix service code (Phase 4 action trên M04, không schema change).
- [ ] **P2** — Hash `users.verification_code` + `reset_code` trước khi store (~1h app-layer + schema rename column type digest format).
- [ ] **P2** — Audit `users_archive` — nếu dead code → drop; nếu planned → document.
- [ ] **P2** — Review low-selectivity indexes `@@index([deleted_at])` trên `ai_models` + `ai_model_versions` — đổi partial index hoặc drop (~30 min raw migration).
- [ ] **P3** — Drop redundant indexes: `ai_model_versions.@@index([model_id])` + `notification_reads.@@index([id])` + `@@index([user_id])` duplicate với unique.
- [ ] **P3** — Add module-level comment header vào `schema.prisma` (managed bằng `db pull` hay manual, ai owner, link canonical SQL).
- [ ] **P3** — Add CHECK constraint cho `alerts.sent_via String[]` element value (`push/sms/email`) — cần raw migration SQL.

## Out of scope (defer Phase 3 deep-dive)

- Full canonical SQL diff — covered by Phase -1 tier1/db_canonical_diff.md.
- Migration history review — no `prisma/migrations/` folder (schema managed via `db pull` từ DB sau SQL canonical apply). Phase 4 cần decide: migrate sang managed migrations hay keep `db pull` workflow.
- TimescaleDB compression + retention policies — ops concern, not schema.
- Partition strategy cho `audit_logs` / `system_metrics` — Phase 5+ scale concern.
- Prisma Client regeneration cost when schema changes — CI/CD concern.

## Cross-references

- Phase -1 findings: [phase_minus_1_summary.md](../../phase_minus_1_summary.md) — D1 (severity vocab), D2 (`user_fcm_tokens` zombie), D3 (`alerts.read_at` zombie), canonical SQL missing 3 tables.
- Phase -1 tier1: [db_canonical_diff.md](../../tier1/db_canonical_diff.md) — 24 tables × 4 sources comparison.
- Phase 0.5 drift: [drift/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-01 CA usage, D-HEA-07 risk_level 3 levels.
- Phase 0.5 drift: [drift/RELATIONSHIP.md](../../tier1.5/intent_drift/healthguard/RELATIONSHIP.md) — D-REL-05 schema dư columns keep + service fix.
- Phase 0.5 drift: [drift/AUTH.md](../../tier1.5/intent_drift/healthguard/AUTH.md) — pattern R1 (token_version), password_hash reference.
- Phase 0.5 drift: [drift/DEVICES.md](../../tier1.5/intent_drift/healthguard/DEVICES.md) — D-DEV-12 add `is_locked` field separation Phase 4 (schema change candidate).
- HG-001 bug: [HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — `alerts.read_at` column zombie root cause.
- ADR-010: [010-devices-schema-canonical.md](../../../ADR/010-devices-schema-canonical.md) — devices.user_id nullable + SET NULL canonical.
- ADR-015: [015-alert-severity-taxonomy.md](../../../ADR/015-alert-severity-taxonomy.md) — 4 layers severity + BE enum drift fix.
- Module inventory: M06 in [01_healthguard.md](../../module_inventory/01_healthguard.md).
- Precedent format: [healthguard-model-api/M03_schemas_audit.md](../healthguard-model-api/M03_schemas_audit.md) — schema audit approach, range validators.
