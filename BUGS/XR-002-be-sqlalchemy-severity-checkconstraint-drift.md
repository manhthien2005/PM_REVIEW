# Bug XR-002: health_system BE SQLAlchemy severity CheckConstraint drift voi canonical SQL

**Status:** Open
**Repo(s):** health_system (+ affect canonical alignment per PM_REVIEW)
**Module:** backend/models
**Severity:** High (drift tiem an runtime bug, khong trigger chua vi IoT sim chi push "normal/warning/critical")
**Reporter:** Phase 0.5 verify pass (PRE_MODEL_TRIGGER_verify.md C1 finding + ADR-015)
**Created:** 2026-05-13
**Resolved:** _(pending)_

## Symptom

SQLAlchemy model `Alert` trong `health_system/backend/app/models/sos_event_model.py:65` co CheckConstraint:

```python
CheckConstraint("severity IN ('normal', 'high', 'critical')", name="check_alert_severity"),
```

Nhung canonical SQL + Postgres ENUM type define:

```sql
-- PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql:131
severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical'))

-- PM_REVIEW/SQL SCRIPTS/01_init_timescaledb.sql:25
CREATE TYPE alert_severity AS ENUM ('low', 'medium', 'high', 'critical');
```

**3 drift points:**
1. SQLAlchemy allows `normal` - canonical rejects.
2. SQLAlchemy rejects `low`, `medium` - canonical allows.
3. Same column, 2 constraint logic conflict.

## Repro steps

1. Insert alert voi `severity='low'` qua SQLAlchemy model API (FastAPI endpoint):
   ```python
   Alert(device_id=1, severity='low', title='Test', ...)
   ```
2. Model-level validation FAIL - CheckConstraint reject "low".

Alternative repro - DB-level test:
1. Bypass SQLAlchemy, insert direct SQL: `INSERT INTO alerts (..., severity) VALUES (..., 'normal')`.
2. Postgres CHECK constraint REJECT "normal".

**Expected:** Both model + DB accept same vocab `low/medium/high/critical`.
**Actual:** Model accepts `normal/high/critical`, DB accepts `low/medium/high/critical`. Intersection chi co `high/critical`.

**Repro rate:** 100% (static mismatch). Runtime bug chua trigger vi:
- IoT sim hien push `normal/warning/critical` qua `_map_alert_severity()` translation (telemetry.py:172).
- Translation output: `normal/high/critical` - match SQLAlchemy constraint, but "normal" FAIL DB canonical CHECK.
- **Hidden bug**: Khi any caller push `severity="normal"` direct, DB layer REJECT + transaction rollback.

## Environment

- health_system/backend HEAD 2026-05-13
- Canonical SQL `PM_REVIEW/SQL SCRIPTS/05_*.sql` unchanged.
- Production DB schema may deviate depending on migration history - check `SELECT DISTINCT severity FROM alerts`.

## Logs / Stack trace

Khong co log currently (bug chua trigger frequently). Expected error neu trigger:

```
IntegrityError: (psycopg2.errors.CheckViolation) new row for relation "alerts" 
violates check constraint "alerts_severity_check"
DETAIL: Failing row contains (..., normal, ...)
```

## Investigation

### Root cause

Historical drift: SQLAlchemy model was written to match IoT sim outbound vocab (`normal/warning/critical`) instead of canonical DB vocab. Translation layer `_map_alert_severity()` da co nhung handle partial (chi map "warning" -> "high").

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | SQLAlchemy model written before canonical SQL finalized | OK Likely - migration sequence suggests this |
| H2 | Translation layer intentional partial mapping | PARTIAL - mapping logic handles warning+critical+high, default "normal" (buggy) |

### Attempts

#### Attempt 1 - 2026-05-13 (pending)

**Hypothesis:** H1 + H2
**Approach:** Per ADR-015, fix 2 files:

**File 1:** `health_system/backend/app/models/sos_event_model.py:65`
```python
# Before:
CheckConstraint("severity IN ('normal', 'high', 'critical')", name="check_alert_severity"),

# After:
CheckConstraint("severity IN ('low', 'medium', 'high', 'critical')", name="check_alert_severity"),
```

**File 2:** `health_system/backend/app/api/routes/telemetry.py:172-180`
```python
# Add explicit mapping for "normal" input:
def _map_alert_severity(severity: str) -> str:
    normalized = (severity or "").strip().lower()
    if normalized == "normal":
        return "low"  # NEW: explicit mapping per ADR-015
    if normalized == "warning":
        return "high"
    if normalized == "critical":
        return "critical"
    if normalized == "high":
        return "high"
    return "low"  # CHANGED: was "normal"
```

**Pre-flight check:**
```sql
SELECT DISTINCT severity FROM alerts;
```
If result contains `'normal'`:
```sql
BEGIN;
UPDATE alerts SET severity='low' WHERE severity='normal';
COMMIT;
```

**Verification:**
- Unit test: insert Alert voi severity in {'low', 'medium', 'high', 'critical'} - all PASS.
- Unit test: insert voi 'normal' or 'invalid' - reject.
- Integration test: push vitals severity='normal' qua telemetry.ingest endpoint - verify DB row has severity='low'.
- Regression: existing alert flow (warning/critical) unchanged.

**Files touched:**
- `health_system/backend/app/models/sos_event_model.py:65`
- `health_system/backend/app/api/routes/telemetry.py:172-180`
- NEW test: `health_system/backend/tests/test_alert_severity_contract.py`

**Effort estimate:** 30min code + 30min test + 30min verify.

## Resolution

_(Pending Phase 4 code branch)_

**Fix commit:** _(pending fix/severity-checkconstraint-drift branch)_
**PR:** _(pending)_
**Approach:** Per ADR-015 Option X migration steps.
**Test added:** `tests/test_alert_severity_contract.py` (regression + contract).
**Verification:** DB-level + model-level accept `low/medium/high/critical` identical.
**Watch for regression:** Monitor error log `CheckViolation.*check_alert_severity` post-deploy.

## Related

- **ADR:** ADR-015 (Alert severity taxonomy 4-layer mapping).
- **Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/PRE_MODEL_TRIGGER_verify.md` (C1 finding triggered).
- **Code:**
  - `health_system/backend/app/models/sos_event_model.py:65` (drift source)
  - `health_system/backend/app/api/routes/telemetry.py:172-180` (translation layer)
  - `PM_REVIEW/SQL SCRIPTS/05_create_tables_events_alerts.sql:131` (canonical reference)

## Notes

### Why XR-NOT single-repo

Primarily touches `health_system/backend/`. Classified XR vi:
- Impact contract voi IoT sim outbound payload (cross-repo severity schema).
- Requires coordination voi canonical SQL source (PM_REVIEW).
- Phase 4 fix requires check production DB state.

### Existing DB row concern

Pre-flight query `SELECT DISTINCT severity FROM alerts` required. If `normal` rows exist:
- UPDATE to `low` first (minimize data loss interpretation).
- Then apply CheckConstraint fix.
- Cascade effect: FE admin web may filter `severity='normal'` - grep to confirm.

Code grep `severity='normal'` or `severity == "normal"` across 3 repos:
- `Iot_Simulator_clean/api_server/services/vitals_service.py:195` - internal only.
- `HealthGuard/backend/src/controllers/health.controller.js:144-146` - handle `warning|critical|high|medium` + default "Thấp" (Low). Missing "low" explicit match nhung fall-through ok.

Low breakage risk - proceed voi Phase 4 fix per ADR-015.
