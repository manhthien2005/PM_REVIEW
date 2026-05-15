# ADR-022: IMU Window Persistence — TimescaleDB Hypertable with 7-day Retention

**Status:** 🟡 Proposed (Redesign 2026-05-15)
**Date:** 2026-05-15
**Decision-maker:** ThienPDM (solo)
**Tags:** [database, timescaledb, fall, audit, retention]
**Resolves:** OQ2

## Context

Hiện tại Mobile BE chỉ lưu derived `fall_events` row (event_type + confidence + sos_triggered). Raw IMU motion window (100 samples × 9 channels) **không persist** — bị mất sau khi model predict.

**Forces:**
- OQ2 chốt: lưu raw + TTL 7 ngày (Option D)
- Demo lợi thế: admin web có thể show motion chart cho operator review false-positive
- Future retrain: 7-day data sample đủ cho monthly retrain cycle
- Bounded growth: TTL + compression policy required
- TimescaleDB đã có trong stack (vitals hypertable)

**Constraints:**
- Storage: ~3.6KB/window raw → 100 user × 100 event/day = 360KB/day raw
- Performance: hypertable chunk_time_interval 1 day → indexes efficient
- Compression: TimescaleDB compress 10:1 typical → ~36KB/day compressed
- Retention 7 days → bounded ~250KB rolling (uncompressed) or ~25KB (compressed)

**References:**
- OQ2 Charter section 7
- Contract `fall_imu_window.md` section 6
- TimescaleDB docs: hypertable + compression + retention

## Decision

**Chose:** Option A — TimescaleDB hypertable `imu_windows` với 1-day chunk + 7-day retention + 1-day-old compression policy.

**Why:**
1. **OQ2 chốt** — Option D from Charter
2. **TimescaleDB native** — vitals đã dùng pattern này
3. **Bounded growth** — auto-drop sau 7 ngày, compress 10:1
4. **Demo asset** — admin web show motion chart cho false-positive review
5. **Future-friendly** — sample data có sẵn cho retrain (export thủ công nếu cần)

## Options considered

### Option A (CHOSEN): TimescaleDB hypertable, 7-day TTL, compress 1-day-old

**Description:**

```sql
CREATE TABLE imu_windows (
    time TIMESTAMPTZ NOT NULL,
    device_id BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    fall_event_id BIGINT REFERENCES fall_events(id) ON DELETE SET NULL,
    accel JSONB NOT NULL,         -- [{x,y,z}, ...] 100 samples
    gyro JSONB NOT NULL,
    orientation JSONB,
    sample_rate_hz INT NOT NULL DEFAULT 50,
    duration_seconds REAL NOT NULL DEFAULT 2.0,
    context JSONB,                 -- scenario_id, variant, activity_before
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (time, device_id)
);

SELECT create_hypertable('imu_windows', 'time', 
    chunk_time_interval => INTERVAL '1 day');

SELECT add_retention_policy('imu_windows', INTERVAL '7 days');

ALTER TABLE imu_windows SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('imu_windows', INTERVAL '1 day');

CREATE INDEX idx_imu_windows_device_time 
    ON imu_windows (device_id, time DESC);
CREATE INDEX idx_imu_windows_fall_event 
    ON imu_windows (fall_event_id) WHERE fall_event_id IS NOT NULL;

-- Add FK column to fall_events
ALTER TABLE fall_events ADD COLUMN IF NOT EXISTS imu_window_id BIGINT;
ALTER TABLE fall_events ADD CONSTRAINT fk_fall_events_imu_window 
    FOREIGN KEY (imu_window_id, time) 
    REFERENCES imu_windows (id, time) ON DELETE SET NULL;
```

**Pros:**
- Native TimescaleDB pattern (vitals tương tự)
- Auto-drop after 7 days
- Auto-compress chunks > 1 day → 10:1 ratio
- Indexed query efficient cho admin web
- FK to fall_events for join queries

**Cons:**
- New table → new migration script
- Slightly more storage than current zero-persist
- BE INSERT thêm 1 query per fall event

**Effort:** S (~2-3h):
- 30min: SQL migration script
- 1h: Mobile BE handler update (INSERT after IMU window receive)
- 30min: ORM model add (optional, có thể dùng raw SQL)
- 30min: Smoke test query/retention

### Option B (rejected): Store raw forever (no TTL)

**Description:** Save raw windows indefinitely cho retrain dataset.

**Pros:**
- Maximum retrain dataset
- Audit forever

**Cons:**
- Unbounded growth: 100 user × 100 event/day × 365 day × 3.6KB = 130GB/year raw
- Need cold storage strategy (S3 archive)
- Out of scope đồ án

**Why rejected:** Unbounded growth, premature optimization for đồ án.

### Option C (rejected): Store derived features only (200B/event)

**Description:** Extract mean/std/max/percentile, không lưu raw arrays.

**Pros:**
- 18× smaller storage
- Simpler schema

**Cons:**
- Cannot retrain model (lost raw)
- Cannot replay false-positive case
- Demo asset bị mất (no motion chart)

**Why rejected:** Loses key value cho debug + future retrain.

### Option D (rejected): Store in object storage (S3)

**Description:** Raw windows go to S3, DB chỉ lưu URL.

**Pros:**
- Cheap storage
- Scalable

**Cons:**
- Infrastructure add (S3 bucket setup)
- Out of scope local development
- Query complex (cross-system)

**Why rejected:** Over-engineer cho local dev environment.

## Consequences

### Positive
- OQ2 chốt option implemented
- Bounded growth
- Demo asset rich (motion chart)
- Audit trail 7 days
- Future retrain sample available

### Negative / Trade-offs accepted
- New table + migration
- BE INSERT overhead per fall event (~1ms)
- TimescaleDB compression slight CPU cost (background job)

### Follow-up actions required
- [ ] Phase 7 slice 1: Migration SQL file `20260515_imu_windows_hypertable.sql`
- [ ] Phase 7 slice 2: Mobile BE handler update INSERT imu_windows trong `/telemetry/imu-window`
- [ ] Phase 7 slice 3: Add FK `fall_events.imu_window_id`
- [ ] Phase 7 slice 4: Add SQLAlchemy model (optional)
- [ ] Phase 7 slice 5: Verify retention policy active (psql query)
- [ ] Optional: Admin web add motion chart viewer cho debug

## Reverse decision triggers

- Nếu storage volume vượt projection (vd model gen 1000 events/day/user) → tighten TTL 3 days hoặc downsample
- Nếu performance impact INSERT >10ms → consider batch INSERT
- Nếu compression không achieve 10:1 → revisit raw vs derived (Option C)

## Related

- **Companion:** ADR-019 (no direct model-api — fall flow goes via BE)
- Contract: `fall_imu_window.md` (section 6 DB schema target)
- Bug: N/A (new feature)
- Code: `health_system/backend/app/api/routes/telemetry.py:638` (handler to extend)
- DB: `health_system/SQL SCRIPTS/04_create_tables_timeseries.sql` (pattern reference — vitals hypertable)

## Notes

### Storage projection

| Scenario | Events/day/user | Users | Days | Raw size/event | Total raw | Compressed (10:1) |
|---|---|---|---|---|---|---|
| Conservative | 1 | 10 | 7 | 3.6KB | 252KB | 25KB |
| Realistic | 10 | 100 | 7 | 3.6KB | 25MB | 2.5MB |
| High-fall | 100 | 100 | 7 | 3.6KB | 252MB | 25MB |
| Stress (100Hz, 5s) | 100 | 100 | 7 | 9KB | 630MB | 63MB |

→ All scenarios bounded.

### Query patterns

```sql
-- Latest fall windows for a device
SELECT time, accel, gyro 
FROM imu_windows 
WHERE device_id = $1 
ORDER BY time DESC 
LIMIT 10;
-- Index used: idx_imu_windows_device_time

-- Join with fall_events
SELECT fe.confidence, iw.accel, iw.gyro
FROM fall_events fe
JOIN imu_windows iw ON fe.imu_window_id = iw.id
WHERE fe.user_id = $1
ORDER BY fe.created_at DESC;
-- Index used: idx_imu_windows_fall_event

-- Admin replay scenario
SELECT * FROM imu_windows
WHERE context->>'scenario_id' = 'fall_high_confidence'
AND time > NOW() - INTERVAL '7 days';
```

### Retention + compression behavior

- Day 0: row inserted, uncompressed
- Day 1: row >1 day old, background job compress chunk → 10:1 size
- Day 7: row >7 days old, retention policy drop chunk

Verify with:
```sql
SELECT * FROM timescaledb_information.compression_settings;
SELECT * FROM timescaledb_information.jobs WHERE proc_name LIKE '%compression%' OR proc_name LIKE '%retention%';
SELECT show_chunks('imu_windows');
```

### Future: cross-link to admin web motion viewer

Phase 7+ optional: admin web build component `<MotionWindowChart fallEventId={id} />` fetch `/api/v1/admin/imu-windows/{fall_event_id}` → display 3-axis line chart 100 samples × 9 channels. Useful cho operator review.
