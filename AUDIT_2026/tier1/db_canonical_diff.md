# Phase -1.A — DB Canonical Diff

**Date:** 2026-05-11
**Scope:** Compare DB schema across 4 sources of truth
**Method:** Manual extract from canonical SQL + Prisma + SQLAlchemy + raw SQL queries
**Linked:** [PM-001](../../BUGS/PM-001-pm-review-spec-drift.md), [Charter](../00_phase_minus_1_charter.md)

---

## TL;DR — Critical findings

| Finding | Severity | Affected | Action needed |
|---|---|---|---|
| 3 tables exist in Prisma + SQLAlchemy but NOT in canonical SQL | **HIGH** | `ai_model_mlops_states`, `user_push_tokens`, `notification_reads` | Update canonical SQL OR remove from Prisma |
| `alerts.severity` CHECK constraint **conflicts** giữa canonical vs SQLAlchemy | **HIGH** | `alerts.severity` | Pick 1 canonical truth |
| `user_relationships` Prisma có 3 cột extra không có ở canonical | **MEDIUM** | `status`, `primary_relationship_label`, `tags` | Update canonical SQL |
| `risk_scores.risk_level` CHECK skip giá trị `'high'` | **MEDIUM** | Canonical only allows `low/medium/critical` | Verify intent |
| Health backend SQLAlchemy thiếu nhiều bảng vs Prisma (10/24 covered) | **LOW** | `vitals`, `motion_data`, `sleep_sessions`, `system_settings`, ... | Likely intentional (read-only via raw SQL) |

**Verdict:** Canonical SQL bị **lag** so với Prisma + SQLAlchemy. Prisma + SQLAlchemy có 3 bảng newer. Canonical là **stalest** trong 3 sources.

**Recommendation:** Treat **Prisma schema** làm source of truth (most fresh, có FK relationships đầy đủ). Canonical SQL phải re-baseline bằng `prisma db pull` hoặc tay add 3 bảng missing.

---

## Sources scanned

| Source | Path | Scope | Last updated |
|---|---|---|---|
| Canonical SQL | `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` | 18 sections, 22 tables | 2026-04-28 |
| Prisma schema | `HealthGuard/backend/prisma/schema.prisma` | 24 models | code current |
| SQLAlchemy | `health_system/backend/app/models/*.py` | 12 models (`__tablename__` declared) | code current |
| Raw SQL (IoT) | `Iot_Simulator_clean/api_server/sim_admin_service.py` | Read `devices` + `users`, write `devices` | code current |

**Out of scope this phase:** Index-level diff, constraint detail beyond CHECK, trigger/function diff, hypertable policy diff.

---

## Master comparison matrix

Legend:
- ✓ = present
- ✗ = missing (drift)
- ⚠️ = present but with conflict (column/constraint diff)
- — = not expected (e.g., model-api stateless)

### Table presence matrix

| # | Table | Canonical SQL | Prisma | SQLAlchemy (HS BE) | IoT raw SQL | Drift |
|---|---|---|---|---|---|---|
| 1 | `users` | ✓ | ✓ | ✓ | read | aligned |
| 2 | `user_relationships` | ✓ | ⚠️ +3 cols | ✓ | — | **drift** |
| 3 | `emergency_contacts` | ✓ | ✓ | ✗ | — | aligned (HS BE doesn't use) |
| 4 | `devices` | ✓ | ✓ | ✓ | read+write | aligned |
| 5 | `vitals` | ✓ | ✓ | ✗ | — | aligned |
| 6 | `motion_data` | ✓ | ✓ | ✗ | — | aligned |
| 7 | `sleep_sessions` | ✓ | ✓ | ✗ | — | aligned |
| 8 | `fall_events` | ✓ | ✓ | ✓ | — | aligned |
| 9 | `sos_events` | ✓ | ✓ | ✓ | — | aligned |
| 10 | `alerts` | ✓ | ✓ | ⚠️ severity conflict | — | **drift** |
| 11 | `risk_scores` | ⚠️ CHECK gap | ✓ | ✓ | — | **drift** |
| 12 | `risk_explanations` | ✓ | ✓ | ✓ | — | aligned |
| 13 | `risk_alert_responses` | ✓ | ✓ | ✓ | — | aligned |
| 14 | `audit_logs` | ✓ | ✓ | ✓ | — | aligned |
| 15 | `system_metrics` | ✓ | ✓ | ✗ | — | aligned |
| 16 | `system_settings` | ✓ | ✓ | ✗ | — | aligned |
| 17 | `password_reset_tokens` | ✓ | ✓ | ✗ | — | aligned |
| 18 | `users_archive` | ✓ | ✓ | ✗ | — | aligned |
| 19 | `ai_models` | ✓ | ✓ | ✗ | — | aligned |
| 20 | `ai_model_versions` | ✓ | ✓ | ✗ | — | aligned |
| 21 | `user_fcm_tokens` | ✓ | ✓ | ✗ | — | aligned |
| 22 | `ai_model_mlops_states` | **✗** | ✓ | ✗ | — | **HIGH DRIFT** |
| 23 | `user_push_tokens` | **✗** | ✓ | ✓ | — | **HIGH DRIFT** |
| 24 | `notification_reads` | **✗** | ✓ | ✓ | — | **HIGH DRIFT** |

**Total tables (union):** 24
**Drift count:** 6 (3 missing + 3 conflict)

---

## High-severity drift detail

### Drift D-001: `ai_model_mlops_states` missing from canonical SQL

**Severity:** HIGH (FK from `ai_models.active_version_id` → exists in canonical, but related state table NOT)

**Prisma definition** (`HealthGuard/backend/prisma/schema.prisma:540-550`):
```prisma
model ai_model_mlops_states {
  id         Int       @id @default(autoincrement())
  model_id   Int       @unique
  payload    Json      @default("{}")
  created_at DateTime? @default(now()) @db.Timestamptz(6)
  updated_at DateTime? @default(now()) @db.Timestamptz(6)
  ai_models  ai_models @relation(fields: [model_id], references: [id], onDelete: Cascade, onUpdate: NoAction)

  @@index([model_id], map: "idx_ai_model_mlops_states_model_id")
  @@index([payload], map: "idx_ai_model_mlops_states_payload", type: Gin)
}
```

**Canonical SQL:** No CREATE TABLE.
**SQLAlchemy:** Not modeled.

**Impact:**
- Prisma migrate sẽ create table, nhưng new env init từ canonical SQL sẽ thiếu
- Anyone running raw `psql -f init_full_setup.sql` then app code → app crashes when querying ML ops state

**Fix suggestion:** Add SECTION 19 to canonical SQL with this CREATE TABLE.

---

### Drift D-002: `user_push_tokens` missing from canonical SQL

**Severity:** HIGH (used by FCM push notification flow, hot path)

**Prisma definition** (`schema.prisma:522-537`):
```prisma
model user_push_tokens {
  id           Int      @id @default(autoincrement())
  user_id      Int
  token        String   @unique @db.VarChar(512)
  platform     String   @db.VarChar(20)
  device_id    String?  @db.VarChar(128)
  is_active    Boolean
  created_at   DateTime @db.Timestamptz(6)
  updated_at   DateTime @db.Timestamptz(6)
  last_seen_at DateTime @db.Timestamptz(6)
  ...
}
```

**SQLAlchemy** (`health_system/backend/app/models/push_token_model.py`): present, `__tablename__ = "user_push_tokens"`.
**Canonical SQL:** No CREATE TABLE. Note: `user_fcm_tokens` exists (different table, also FCM-related) — likely older design that didn't get replaced cleanly.

**Note đáng nghi:** Có 2 bảng FCM token — `user_fcm_tokens` (canonical + Prisma) và `user_push_tokens` (Prisma + SQLAlchemy). **Có khả năng `user_fcm_tokens` deprecated nhưng chưa xóa.** Cần xác nhận với code đường dẫn nào đang được dùng thực tế (Phase -1.B sẽ surface khi map endpoint).

**Fix suggestion:** Phase -1.B clarify which is active. Add active table to canonical SQL.

---

### Drift D-003: `notification_reads` missing from canonical SQL

**Severity:** HIGH (alerts.read_at vs notification_reads — likely 2-way storage of read state)

**Prisma definition** (`schema.prisma:487-500`):
```prisma
model notification_reads {
  id         Int      @id @default(autoincrement())
  user_id    Int
  alert_id   Int
  read_at    DateTime @db.Timestamptz(6)
  created_at DateTime @db.Timestamptz(6)
  alerts     alerts   @relation(...)
  users      users    @relation(...)

  @@unique([user_id, alert_id], map: "uq_notification_reads_user_alert")
}
```

**SQLAlchemy** (`notification_read_model.py`): present.
**Canonical SQL:** Not present.

**Note đáng nghi:** Bảng `alerts` đã có `read_at` column (canonical SQL line 456). Vậy có 2 nơi lưu trạng thái read:
1. `alerts.read_at` (per-alert)
2. `notification_reads` (per-user × per-alert — multi-recipient notification?)

**Hypothesis:** alerts là 1-recipient (user_id), notification_reads là multi-recipient (vd, alert gửi đến caregiver, từng caregiver có read state riêng). Nếu vậy, `alerts.read_at` có thể stale (chỉ track recipient gốc).

**Cần verify:** Đâu là source of truth cho UI hiển thị "đã đọc"? Phase 1 macro audit hoặc Phase 3 deep-dive notifications module sẽ trả lời.

**Fix suggestion:** Add to canonical SQL. Phase 3 sẽ deep-dive notifications module để clarify dual-storage.

---

### Drift D-004: `alerts.severity` CHECK constraint conflict

**Severity:** HIGH (semantic drift — production data can be invalid theo 1 source nhưng valid theo source khác)

**Canonical SQL** (init_full_setup.sql line 450):
```sql
severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical'))
```
4 values: `low`, `medium`, `high`, `critical`.

**SQLAlchemy** (`sos_event_model.py:65`):
```python
CheckConstraint("severity IN ('normal', 'high', 'critical')", name="check_alert_severity"),
```
3 values: `normal`, `high`, `critical`.

**Conflict:**
- Canonical allows `low`, `medium` — SQLAlchemy doesn't
- SQLAlchemy allows `normal` — Canonical doesn't
- Production DB schema is whichever migration ran last → unclear

**Impact:**
- INSERT của health_system backend reject row với severity `low` hoặc `medium` (per SQLAlchemy CheckConstraint)
- Or INSERT raw từ HealthGuard (Prisma — không có CHECK ở Prisma layer) reject với severity `normal`

**Fix suggestion:**
- Pick 1 vocabulary
- Industry standard: `low/medium/high/critical` (4 levels). Drop `normal` (= `low`?).
- Update SQLAlchemy CheckConstraint + verify production DB constraint via `\d alerts` in psql.

---

### Drift D-005: `user_relationships` Prisma có 3 cột extra

**Severity:** MEDIUM (forward-only — Prisma có data fields canonical SQL không có. Insert qua Prisma OK nhưng dump/restore từ canonical SQL sẽ mất data.)

**Prisma extra columns** (`schema.prisma:264-279`):
```prisma
status                     String?   @default("pending") @db.VarChar(20)
primary_relationship_label String?   @db.VarChar(100)
tags                       Json?
```

**Canonical SQL** (line 110-134): does NOT have these.

**SQLAlchemy** (`relationship_model.py`): NEED VERIFY (em chưa đọc detail file). Likely matches Prisma since both are runtime ORM.

**Impact:**
- Re-init DB từ canonical → app code bị crash khi try query `status` column
- Prisma migrations chắc đã add cột này nhưng chưa propagate vào canonical SQL

**Fix suggestion:** Add ALTER TABLE statements to canonical SQL SECTION 19 (or higher).

---

### Drift D-006: `risk_scores.risk_level` CHECK skip 'high'

**Severity:** MEDIUM (data integrity — INSERT với `risk_level='high'` sẽ fail)

**Canonical SQL** (line 491):
```sql
risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'critical'))
```
**3 values only:** `low`, `medium`, `critical`. **Missing `high`!**

**Prisma:** Không có CHECK at Prisma layer (just VarChar(20)).
**SQLAlchemy** (`risk_score_model.py`): NEED VERIFY full file.

**Impact:**
- App code cố INSERT `risk_level='high'` → Postgres reject với CHECK violation
- 4-level risk_level enum (`risk_level` enum at line 559-564 — `low`, `medium`, `high`, `critical`) — match enum nhưng CHECK constraint không match

**Likely cause:** Typo or oversight when writing initial schema. Should be 4 values.

**Fix suggestion:** Update canonical SQL CHECK to include `'high'`. Verify production DB hiện tại.

---

## Aligned tables (no action needed for canonical)

Tables that exist consistently across canonical + Prisma (column-level diff khả năng nhỏ, không deep-dive Phase này):

```
users, devices, vitals, motion_data, sleep_sessions, fall_events,
sos_events, audit_logs, risk_explanations, risk_alert_responses,
system_metrics, system_settings, password_reset_tokens, users_archive,
ai_models, ai_model_versions, emergency_contacts, user_fcm_tokens
```

**Note:** "Aligned at table level" không có nghĩa là 100% column match. Index, default value, constraint detail có thể vẫn lệch. Phase -1 không deep-dive.

---

## SQLAlchemy coverage analysis

health_system backend chỉ có 12 SQLAlchemy models, while DB có 24 tables. Pattern observed:

**SQLAlchemy modeled (12):** users, devices, fall_events, alerts, sos_events, risk_scores, risk_explanations, risk_alert_responses, user_relationships, user_push_tokens, notification_reads, audit_logs

**SQLAlchemy NOT modeled (12):** vitals, motion_data, sleep_sessions, emergency_contacts, system_metrics, system_settings, password_reset_tokens, users_archive, ai_models, ai_model_versions, ai_model_mlops_states, user_fcm_tokens

**Pattern:** Tables modeled = tables health_system BE writes. Tables not modeled = tables read-only OR managed by another service (HealthGuard admin BE, IoT sim).

**Status:** Likely intentional — SQLAlchemy được dùng cho write-heavy paths của health_system. Verify in Phase -1.B / Phase 3 nếu deep-dive needed.

---

## IoT Simulator DB usage

`Iot_Simulator_clean/api_server/sim_admin_service.py` dùng raw SQL via SQLAlchemy `text()`:

**Tables read:**
- `users` (email lookup)
- `devices` (admin operations: list, link to user, deactivate, heartbeat update)

**Tables write:**
- `devices` (UPDATE: user_id, is_active, last_seen_at, battery_level, signal_strength)

**No own tables** — Reuses HealthGuard DB. Compliance with topology (IoT chia sẻ DB với HealthGuard BE).

---

## Recommendations (priority ordered)

### P0 — Blocking macro audit
- [ ] Add to canonical SQL: `ai_model_mlops_states`, `user_push_tokens`, `notification_reads` (3 sections mới hoặc embed vào sections existing)
- [ ] Resolve `alerts.severity` vocabulary conflict — chọn 1 trong 2 và sync 3 sources
- [ ] Update `user_relationships` canonical SQL với 3 cột extra
- [ ] Fix `risk_scores.risk_level` CHECK to include `'high'`

### P1 — Cleanup
- [ ] Verify `user_fcm_tokens` vs `user_push_tokens` — bảng nào thực sự dùng? Deprecate cái còn lại.
- [ ] Verify `alerts.read_at` vs `notification_reads.read_at` — clarify which is source of truth for UI
- [ ] Document `alerts.alert_type` 12-value vocabulary trong SRS (canonical đã có CHECK, Prisma không có — info loss tại Prisma layer OK vì DB enforce)

### P2 — Future hardening
- [ ] Add ADR cho schema change workflow: ai-driven → must update canonical SQL + Prisma migration cùng lúc
- [ ] Consider Prisma `db pull` workflow để regenerate canonical SQL từ live DB (treat live DB là truth)
- [ ] Add CI check: warn if Prisma migrate creates table không trong canonical SQL

---

## Decisions confirmed (ThienPDM 2026-05-11)

### D1. Severity vocabulary = `low/medium/high/critical` (4 levels)

**Rationale:**
- Match Canonical SQL CHECK + Prisma enum (2/3 high-authority sources)
- Match `RISK_LEVEL_LABELS` đã có 4 buckets trong admin web (`HealthConstants.js:5-11`)
- Consistent UX language giữa risk_level và severity
- 4 levels = natural medical alert taxonomy (info/notice/warning/critical)
- Less risky than 3-level rename (Option B): chỉ extend (add `low`+`medium`), không touch existing data

**Fix actions (Phase 4):**
- Backend `sos_event_model.py:65` → `CheckConstraint("severity IN ('low', 'medium', 'high', 'critical')")`
- Mobile `notification_severity.dart:14-22` → 4 distinct buckets, `'high'` separate from `'medium'`
- Admin `HealthConstants.js:29-32` → `SEVERITY_LABELS` extend từ 2 → 4 buckets
- Backend `alert_constants.py` → optional extend ESCALATION_MATRIX với `low`/`medium` rules khi product cần

### D2. `user_fcm_tokens` = deprecated zombie

**Verified:** 0 code references trong cả health_system + HealthGuard backends.

**Active table:** `user_push_tokens` (richer: device_id, last_seen_at).

**Fix action (Phase 4):** Migration `DROP TABLE user_fcm_tokens` + remove from canonical SQL + remove from Prisma schema.

### D3. `notification_reads` = active source of truth, `alerts.read_at` = dead column

**Verified:**
- `notification_reads (user_id, alert_id, read_at)` = active multi-recipient read tracking — used by `notification_service.py` (mobile flow)
- `alerts.read_at` = zombie column, NEVER written by mobile BE, admin BE has wrong assumption (see HG-001)

**Design intent confirmed:** Per-user read state cho linked caregivers. 1 alert có thể gửi đến patient + N caregivers, mỗi user có read state riêng.

**Fix actions:**
- Phase 4: Drop `alerts.read_at` column (after admin BE migration to use `notification_reads`)
- Bug logged: [HG-001](../../BUGS/HG-001-admin-web-alerts-always-unread.md) — admin web alerts always unread
- Document trong SRS: notification read model = `notification_reads` table

### D4. Re-baseline approach = defer Phase 4 (option C)

**Rationale:**
- Phase -1 goal = trust-able baseline, KHÔNG cần "perfect" baseline
- File `db_canonical_diff.md` này đủ context cho Phase 1 macro audit (treat Prisma là truth temporarily)
- Phase 4 refactor sẽ touch DB schema → sync canonical SQL tự nhiên
- Avoid scope creep trong Phase -1

---

## Phase -1.A Definition of Done

- [x] Master comparison matrix (24 tables × 4 sources)
- [x] 6 drift findings documented với severity + fix suggestion
- [x] Aligned tables identified
- [x] SQLAlchemy coverage analysis
- [x] IoT raw SQL usage mapped
- [x] Recommendations prioritized (P0/P1/P2)
- [x] Questions for ThienPDM listed
- [ ] ThienPDM review

**Next:** Phase -1.B — API Contract v1
