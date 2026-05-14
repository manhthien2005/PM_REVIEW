# ADR-015: Alert severity taxonomy - clarify 4 layers + fix BE enum drift

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, severity, cross-repo, health_system, iot-sim, healthguard, database, schema]

## Context

Phase 0.5 verify pass cho `PRE_MODEL_TRIGGER` (C1 finding) phat hien doc Q4 claim "prob < 0.3 normal, 0.3-0.7 warning, > 0.7 critical per ADR D1 (low/medium/high/critical)" la SAI. Khi verify sau, em phat hien 5 vocabularies khac nhau cho severity/risk/alert trong codebase, va BE co enum drift giua DB schema va SQLAlchemy model.

### Severity vocabularies phat hien (cross-repo grep)

| Layer | Vocabulary | Location | Use case |
|---|---|---|---|
| IoT sim orchestrator internal | `NORMAL / WATCH / SEND_TO_RISK_MODEL / URGENT` | `Iot_Simulator_clean/pre_model_trigger/response_handler.py:21-26` | Action decision engine |
| IoT sim outbound alert payload | `normal / warning / critical / offline` | `Iot_Simulator_clean/api_server/schemas.py:27` `AlertSeverityValue` | Push-to-BE contract |
| health_system BE ingest endpoint | `_map_alert_severity(severity)` returns `normal / high / critical` | `health_system/backend/app/api/routes/telemetry.py:172-180` | Translation layer |
| health_system BE DB `alerts.severity` (canonical SQL) | `low / medium / high / critical` (CHECK constraint + Postgres ENUM type `alert_severity`) | `PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql:131`, `01_init_timescaledb.sql:25` | Persisted alert severity |
| health_system BE SQLAlchemy model CheckConstraint | `normal / high / critical` (3 values) | `health_system/backend/app/models/sos_event_model.py:65` | **DRIFT** - khac canonical SQL |
| Admin BE Prisma schema | `low / medium / high / critical` (enum `alert_severity`) | `HealthGuard/backend/prisma/schema.prisma:552-557` | Matches canonical |
| Risk level (ADR D1 canonical) | `LOW / MEDIUM / HIGH / CRITICAL` | Phase -1 spec + `risks.risk_level` column | Risk scoring output |

### Forces

- Severity la cross-repo contract point - IoT sim -> BE -> admin FE -> mobile FE all consume.
- BE SQLAlchemy model drift voi canonical SQL = runtime bug tiem an. Khi IoT sim push `severity="low"` (valid theo canonical), BE model CheckConstraint reject do constraint chi accept `normal/high/critical`.
- `_map_alert_severity()` translation layer chi handle 3 input cases (warning/critical/high), default = "normal". Input `severity="medium"` tu IoT sim -> BE -> "normal" (downgraded silently). Tuong tu "low" -> "normal" (ok coincidental).
- ADR D1 nham lan scope: canonical SQL cho `alerts.severity` la `low/medium/high/critical` (4 levels), `risks.risk_level` la `LOW/MEDIUM/HIGH/CRITICAL` (uppercase) - ADR D1 phase_minus_1_summary gop 2 concepts thanh 1 statement.

### Constraints

- Canonical SQL `PM_REVIEW/SQL SCRIPTS/*.sql` la source of truth per steering rule.
- Production DB da deploy voi enum `alert_severity AS ENUM ('low', 'medium', 'high', 'critical')`.
- Mobile BE SQLAlchemy model la drift duplicate - can fix trong Phase 4 (docs task).

### References

- `Iot_Simulator_clean/pre_model_trigger/response_handler.py:21-26`
- `Iot_Simulator_clean/api_server/schemas.py:27`
- `Iot_Simulator_clean/api_server/dependencies.py:1655-1675` (`_decide_alert_severity()`)
- `health_system/backend/app/api/routes/telemetry.py:172-195` (translation layer)
- `health_system/backend/app/models/sos_event_model.py:65` (**DRIFT source**)
- `PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql:131` (canonical)
- `HealthGuard/backend/prisma/schema.prisma:552-557`
- `PM_REVIEW/AUDIT_2026/phase_minus_1_summary.md` (ADR D1)
- `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/PRE_MODEL_TRIGGER_verify.md` (C1 triggered this ADR)

## Decision

**Chose:** Option X - **Clarify 4-layer mapping + fix BE SQLAlchemy drift.**

### Canonical severity taxonomy

```
Layer 1: IoT sim orchestrator (decision)  = NORMAL / WATCH / SEND_TO_RISK_MODEL / URGENT
Layer 2: IoT sim outbound alert (contract) = normal / warning / critical  (drop "offline" unused)
Layer 3: BE ingest _map_alert_severity()   = input -> normal / medium / high / critical
Layer 4: BE DB alerts.severity (canonical) = low / medium / high / critical
```

### Mapping contract (Layer 2 -> Layer 3 -> Layer 4)

| IoT sim outbound | BE translation | BE DB persist |
|---|---|---|
| `normal` | `normal` -> passthrough | `low` (relabel low severity trong DB) |
| `warning` | `high` (existing logic) | `high` |
| `critical` | `critical` (existing logic) | `critical` |
| (missing) | default `normal` -> `low` | `low` |

### Risk level (separate concept)

`risks.risk_level` = `LOW/MEDIUM/HIGH/CRITICAL` (uppercase, 4 levels). **Khong map 1-1 sang alert severity**. Khi risk_level HIGH/CRITICAL, co the tao alert voi severity tuong ung - se document mapping rieng neu needed.

### Why

1. **Layer 1 internal KHONG expose ra ngoai.** Rename/unify khong value-add.
2. **Layer 2 outbound la contract IoT sim.** `normal/warning/critical` de trace. Drop `offline` unused.
3. **Layer 3 BE translation** layer da ton tai va la point mapping chuan - clean up logic de handle "normal" -> "low" (khong phai default "normal").
4. **Layer 4 DB canonical** la source of truth. BE SQLAlchemy model DRIFT phai FIX (per XR-002 bug).

## Options considered

### Option X (chosen): 4-layer mapping + fix BE SQLAlchemy drift

**Migration steps:**
1. Fix `health_system/backend/app/models/sos_event_model.py:65` CheckConstraint: `'low', 'medium', 'high', 'critical'` (match canonical).
2. Fix `_map_alert_severity()` trong `telemetry.py` for "normal" input -> "low" output (avoid truncation).
3. Document 4-layer mapping trong doc nay + cross-ref drift doc PRE_MODEL_TRIGGER v2.
4. IoT sim `schemas.py` `AlertSeverityValue` keep `normal/warning/critical/offline` - runtime OK, `offline` reserved.
5. Log XR-002 bug cho BE SQLAlchemy drift (1-line CheckConstraint fix).

**Pros:**
- Fix BE model drift (hidden bug).
- Clarify mapping taxonomy - khong confuse ADR D1 scope.
- Minimal code change - 2 lines fix.

**Cons:**
- Keep 4-layer vocabulary - still complex. Justified boi moi layer co purpose khac (decision / contract / translation / persist).

**Effort:**
- S Decision + ADR: 1h (this turn).
- S Code fix: 30min (2 line changes + test regression).
- S Doc update: 20min.

### Option Y (rejected): Unify all 4 layers to single vocabulary

**Description:** Change all 4 layers to `low/medium/high/critical` (canonical).

**Pros:**
- Single vocab everywhere.
- Simpler cognitive load.

**Cons:**
- Touch 10+ files across 3 repos.
- Break IoT sim orchestrator decision enum (`NORMAL/WATCH/SEND_TO_RISK_MODEL/URGENT` la action decision, khong fit low/medium/high/critical semantics).
- `_map_alert_severity()` translation layer worth keeping - different concerns per layer.
- Risk regression trong existing tests.

**Why rejected:** Unify khong cost-effective. Moi layer co purpose khac (internal decision vs persisted severity). Translation layer la OK architecture pattern.

### Option Z (rejected): Do nothing, document as-is

**Description:** Keep current state, just add doc noting vocab differences per layer.

**Pros:**
- Zero code change.

**Cons:**
- BE SQLAlchemy drift (`normal/high/critical` vs canonical `low/medium/high/critical`) = bug. Will surface when operator inject alert voi severity `low` or `medium` -> BE 500.
- Silent downgrade from "medium" -> "normal" via translation layer default.

**Why rejected:** Drift = real bug, khong chi document issue. Fix required.

---

## Consequences

### Positive

- BE SQLAlchemy CheckConstraint match canonical SQL (drift resolved).
- Translation layer clear semantic (normal->low, not default pass).
- 4-layer mapping documented, future contributor understand.
- Phase 0.5 Q4 PRE_MODEL_TRIGGER can revise correctly.

### Negative / Trade-offs accepted

- Still 4 vocabularies. Accept vi each layer co distinct concern.
- Translation layer change behavior: severity "normal" bay gio persist "low" thay vi "normal" (old). Runtime impact: existing DB rows voi "normal" stay, new rows persist "low" - check canonical CHECK constraint accept "low" (OK).
- Code touch minimal (2 files).

### Follow-up actions required

- [ ] **Phase 4 task (BE):** Fix `health_system/backend/app/models/sos_event_model.py:65` CheckConstraint. Effort S (15min + test). Note: Existing DB rows may have "normal" value (not in new constraint) - check DB state + migration if needed.
- [ ] **Phase 4 task (BE):** Fix `health_system/backend/app/api/routes/telemetry.py:_map_alert_severity()` "normal" input -> "low" output. Effort S (15min + test).
- [ ] **Phase 0.5 doc:** Revise `PRE_MODEL_TRIGGER.md` drift doc Q4 per ADR-015 mapping. Effort S (20min).
- [ ] **Bug log:** XR-002 BE SQLAlchemy severity drift. Effort S (20min).

## Reverse decision triggers

- Neu client app can low severity (low vs normal distinction matters for UX) -> reconsider translation "normal -> low".
- Neu operator request risk_level + alert_severity merge vao 1 field -> reconsider full taxonomy redesign.
- Neu BE add new severity value (emergency?) -> update canonical SQL + migrate.

## Related

- **Triggered by:** PRE_MODEL_TRIGGER verify C1 finding.
- **Phase -1 ADR D1** (phase_minus_1_summary.md): Clarified - ADR D1 addresses risk_level canonical vocab (`LOW/MEDIUM/HIGH/CRITICAL`), NOT alert severity. Two different concepts.
- **Bug:** XR-002 (to be filed post-ADR) - BE SQLAlchemy severity CheckConstraint drift.
- **Code touched (Phase 4):**
  - MODIFY: `health_system/backend/app/models/sos_event_model.py:65`
  - MODIFY: `health_system/backend/app/api/routes/telemetry.py:172-180`
  - DOC: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/PRE_MODEL_TRIGGER.md` Q4

## Notes

### Why `normal` -> `low` mapping

BE DB canonical constraint accept `low/medium/high/critical`. IoT sim outbound "normal" is the default/pass-through severity. Map "normal" -> "low" vi:
- "low" la minimal severity trong canonical vocab.
- Preserve semantic: both mean "da record nhung khong urgent".
- Tranh mismatch CHECK constraint (reject "normal" o DB layer sau Phase 4 fix).

### Layer 1 `SEND_TO_RISK_MODEL` semantics

Khong phai severity level per se - la routing decision. Stays internal. When orchestrator emit action voi `SEND_TO_RISK_MODEL`, actual alert severity assigned boi `_decide_alert_severity()` (`dependencies.py:1656`) based on AI verdict + fall variant policy.

### BE existing data migration concern

Neu DB da co rows voi `severity='normal'`, fix CheckConstraint se fail existing data. Phase 4 task phai:
1. Grep existing rows `SELECT DISTINCT severity FROM alerts`.
2. Neu co `normal` rows: UPDATE alerts SET severity='low' WHERE severity='normal'; THEN apply constraint fix.
3. Neu 0 rows voi `normal`: direct constraint fix OK.
