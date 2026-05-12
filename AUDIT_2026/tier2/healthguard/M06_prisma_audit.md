# M06 — Prisma Schema Audit (HealthGuard backend)

**Track:** Phase 1 Track 1A
**Module:** Prisma schema (`backend/prisma/`)
**Files:** `schema.prisma` (577 LoC), migrations directory
**Effort spent:** ~30 min
**Auditor:** AI pair
**Date:** 2026-05-12

---

## Scope

23 models + 4 enums in single `schema.prisma`. Canonical truth for HealthGuard DB per Phase -1.A decision (until canonical SQL re-baselined).

**Models inventory:**

| Group | Models |
|---|---|
| **Identity** | `users`, `users_archive`, `password_reset_tokens`, `user_relationships`, `user_fcm_tokens`, `user_push_tokens` |
| **Device + telemetry** | `devices`, `vitals`, `motion_data`, `sleep_sessions` |
| **Events** | `fall_events`, `sos_events`, `alerts`, `notification_reads` |
| **Risk + AI** | `risk_scores`, `risk_explanations`, `risk_alert_responses`, `ai_models`, `ai_model_versions`, `ai_model_mlops_states` |
| **Ops** | `audit_logs`, `system_metrics`, `system_settings`, `emergency_contacts` |

**Enums:** `alert_severity` (low/medium/high/critical), `risk_level`, `sos_status`, `user_role`.

---

## Scoring

| Axis | Score | Notes |
|---|---|---|
| **Correctness** | 3 | Relations + FK strategies appropriate; soft delete consistent; UUID + Int dual-ID. |
| **Readability** | 3 | Auto-generated comments preserved; index naming convention consistent (`idx_<table>_<col>`). |
| **Architecture** | 2 | Some entity overlap (`user_fcm_tokens` vs `user_push_tokens` — duplication); composite PK on `audit_logs` (id, time) — TimescaleDB hint not declared. |
| **Security** | 2 | No row-level security policy; `token_hash` for password reset OK; no field-level encryption for PHI (heart rate, location). |
| **Performance** | 3 | Index coverage strong on all hot paths (alerts, audit_logs, vitals); BigInt for audit_logs id. |

**Total: 13/15 → 🟢 Mature**

---

## Strengths

### F1 🟢 Soft delete pattern consistent

Tables with `deleted_at` field: `users`, `devices`, `ai_models`, `ai_model_versions`. Allows recovery + audit trail. Middleware `authenticate.js` already filters `deleted_at: null`.

### F2 🟢 Dual-ID strategy

Most tables have both `id` (Int autoincrement) + `uuid` (default `gen_random_uuid()`).

**Use case:**
- `id` for FK joins (smaller, indexed faster)
- `uuid` for external API exposure (no enumeration attack)

Good defense-in-depth.

### F3 🟢 Strong index coverage

**Example: `alerts` (lines 13-43):**
```prisma
@@index([device_id, created_at(sort: Desc)], map: "idx_alerts_device")
@@index([alert_type, created_at(sort: Desc)], map: "idx_alerts_type")
@@index([user_id, created_at(sort: Desc)], map: "idx_alerts_user")
```

Composite indexes with `created_at DESC` — optimal for time-series query patterns ("most recent alerts for user X").

### F4 🟢 BigInt for high-volume tables

`audit_logs.id BigInt` (line 48) — anticipates billions of rows. Good foresight.

`risk_alert_responses.id BigInt` (line 505) — same pattern.

### F5 🟢 Composite PK for time-series

`audit_logs @@id([id, time])` (line 63) — partitioning-friendly. **Note:** This hints TimescaleDB hypertable but declaration is missing — verify with M06 ops/migrations review.

### F6 🟢 Cascading deletes consistent

`user_fcm_tokens`, `notification_reads`, `risk_alert_responses`, `user_push_tokens`, `ai_model_mlops_states` → `onDelete: Cascade`.

Prevents orphan rows when user/alert/model deleted.

---

## Findings

### F7 🟠 Duplicated push token tables

**Files:** `user_fcm_tokens` (lines 474-485) + `user_push_tokens` (lines 522-537)

**Differences:**
- `user_fcm_tokens` — Android-only by default (`platform default 'android'`), no device_id link
- `user_push_tokens` — platform required, optional `device_id` String

**Issue:** Two tables for same domain concept. Mobile app `health_system/lib/features/notifications/` likely writes to one; `HealthGuard/backend/services/notification.service.js` reads from another. Risk: tokens get lost.

**Verify in M04 services audit:** which table does HealthGuard read for notification dispatch?

**Fix (Phase 4):**
- Audit usage in both repos
- Decide canonical table → migrate other → drop legacy
- Document in ADR

**Severity:** P2 (architecture debt, not security)
**Effort:** 4-6h (cross-repo migration + ADR)

---

### F8 🟠 No row-level security (RLS)

**Issue:** All tables accessible by any authenticated request. Permission check is **only in middleware/service layer**. If a query bypasses middleware (e.g., dev script), no DB-level enforcement.

**Risk:** Defense-in-depth absent. If service code has bug → user A reads user B's vitals.

**Recommendation (Phase 4 hardening or defer):**
- Add Postgres RLS policies on `vitals`, `alerts`, `motion_data`, `risk_scores`
- Use `SET app.current_user_id = $1` in middleware
- Trade-off: complexity vs defense layer

**Decision:** Defer to Phase 4+ — would require ADR.

**Severity:** P3
**Effort:** 12-16h (policies + middleware + tests)

---

### F9 🟠 No field-level encryption for PHI

**Tables with sensitive data:**
- `vitals` — heart_rate, blood_pressure, spo2, etc. — at rest plaintext
- `sos_events` — latitude, longitude — at rest plaintext
- `users` — date_of_birth, phone, address?

**Compliance angle:** If publishing app to stores (Google Play Health), encryption-at-rest required for PHI per Google policy.

**Fix (Phase 4 or compliance push):**
- Use Postgres `pgcrypto` extension
- Encrypt sensitive columns with app-managed key
- Or full-DB encryption (Azure/AWS managed Postgres)

**Severity:** P3 (compliance-driven, not blocking dev)
**Effort:** 8-12h + key management ADR

---

### F10 🟡 `risk-calculation.service.js` zero-byte file

**File:** `backend/src/services/risk-calculation.service.js` (0 bytes)

Not Prisma scope but discovered during inventory.

**Likely:** Renamed to `risk-calculator.service.js` (10 KB present). Delete dead file.

**Fix (Phase 4):**
```bash
git rm backend/src/services/risk-calculation.service.js
```

**Severity:** P3
**Effort:** 2 min

---

### F11 🟡 Drift findings from Phase -1.A pending

Phase -1.A `db_canonical_diff.md` identified 6+ drifts between Prisma + canonical SQL + SQLAlchemy:
- Tables present in Prisma but missing in canonical SQL (`ai_model_mlops_states`)
- Column type variants between Prisma and SQLAlchemy
- `notification_reads.read_at` missing default

**Action:** Phase 4 Task — sync canonical SQL with current Prisma (Prisma = source of truth per Phase -1 decision).

**Severity:** P2 (already tracked in PM-001)
**Effort:** Phase 4 — 4h (script + verify + commit canonical SQL)

---

## Anti-pattern flags

- 🚩 **Two tables same concept** (F7 fcm_tokens vs push_tokens) — feature duplication
- 🚩 **No DB-level access control** (F8) — defense layer absent
- 🚩 **PHI plaintext** (F9) — compliance risk
- 🚩 **Zero-byte file** (F10) — cleanup hygiene

---

## Phase 3 deep-dive candidates

| Table | Reason | Priority |
|---|---|---|
| `alerts` + `notification_reads` | HG-001 bug fix point — read state design | High |
| `user_fcm_tokens` + `user_push_tokens` | F7 reconciliation | Medium |
| `audit_logs` partitioning | TimescaleDB hypertable verify | Medium |

---

## Phase 4 recommended fixes (priority order)

| # | Fix | Severity | Effort |
|---|---|---|---|
| 1 | F11 Sync canonical SQL with Prisma | P2 | 4h |
| 2 | F7 Reconcile push token tables | P2 | 4-6h |
| 3 | F10 Remove zero-byte service file | P3 | 2 min |
| 4 | F9 PHI encryption (compliance trigger) | P3 | 8-12h |
| 5 | F8 RLS policies | P3 | 12-16h |

**Critical for Phase 4 chain:** F11 (canonical SQL sync) is blocker for future migrations.

---

## Cross-references

- Phase -1.A `db_canonical_diff.md` — 6 drift findings; this audit confirms scope
- PM-001 (PM_REVIEW spec drift) — F11 tracked here
- HG-001 (alerts always unread) — `notification_reads` table schema = fix point (M04 services to verify)

---

## Verdict

**🟢 Mature.** Schema is well-indexed + soft-delete pattern + dual-ID strategy applied consistently. Findings are debt-track items (F7, F8, F9) not blocking. F11 canonical SQL sync = high-priority Phase 4 hygiene to maintain trust baseline rebuilt in Phase -1.A.
