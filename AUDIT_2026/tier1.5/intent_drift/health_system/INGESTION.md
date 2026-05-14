# Intent Drift Review — `health_system / INGESTION` (v2)

**Status:** ✅ Confirmed Phase 0.5 v2 (2026-05-13) — drop 2 overlap decisions, add self-correction reference
**Repo:** `health_system/backend` (mobile FastAPI BE)
**Module:** INGESTION (Data pipeline: IoT sim sang mobile BE DB)
**Related UCs (old):** No dedicated UC, implicit precondition of UC006 (View Health Metrics)
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13

---

## 🎯 Mục tiêu v2

Rewrite doc v1 sau khi verify phát hiện:
- D-ING-01 (auth gap) overlap hoàn toàn với **HS-004** (commit session SLEEP trước).
- D-ING-02 (topology doc drift) overlap với **XR-001** (đã có, scope rộng hơn 1 row IoT sim).
- Self-correction: Claim trong DEVICE.md v2 về `last_sync_at` dead là SAI — telemetry.py line 287-291 CÓ update path.

v2 drop D-ING-01 + D-ING-02 tránh duplicate effort. Keep D-ING-03 + D-ING-04 doc-only. Self-correct 3 file từ session DEVICE.

---

## 📚 UC context (memory aid)

Không có UC riêng cho ingestion. Relevant UCs:
- **UC006 View Health Metrics:** Precondition "Thiết bị IoT đang kết nối và gửi dữ liệu". Chu kỳ 1 phút. Latency <5s.
- **UC007 View Detail:** Uses aggregated data (5min/hourly/daily continuous aggregates).
- **UC008 Alert Thresholds:** Triggered by vitals out of range during ingest.

---

## 🔧 Code state — verified

### Routes (`telemetry.py`) — 5 ingest endpoints

```
POST /mobile/telemetry/ingest       Batch vitals sang vitals hypertable       [require_internal_service] ✓
POST /mobile/telemetry/alert        Alert + fall detection sang alerts/fall_events [require_internal_service] ✓
POST /mobile/telemetry/imu-window   IMU sang model-api fall predict sang fall_events [NO AUTH GUARD, HS-004] ⚠️
POST /mobile/telemetry/sleep        Sleep session sang sleep_sessions             [NO AUTH GUARD, HS-004] ⚠️
POST /mobile/telemetry/sleep-risk   Sleep sang model-api sang risk_scores            [NO AUTH GUARD, HS-004] ⚠️
```

### Vitals ingest (`POST /telemetry/ingest`) — verified

Request: `VitalIngestRequest` với `messages: list[VitalIngestItem]`. Mỗi item có `db_device_id`, `emitted_at`, `vitals` (HR, SpO2, temp, HRV, RR, BP sys/dia, signal_quality, motion_artifact).

Logic (line 201-320):
1. `INSERT INTO vitals ON CONFLICT (device_id, time) DO NOTHING` (dedup).
2. `UPDATE devices SET last_sync_at = NOW() WHERE id = ANY(:device_ids) AND deleted_at IS NULL` (line 287-295) với pushed_device_ids list.
3. For each device: `calculate_device_risk(allow_cached=True, dispatch_alerts=True)` inline, try/except nuốt exception vào `errors` array.

Auth: `require_internal_service` — checks `X-Internal-Service: iot-simulator` + optional `X-Internal-Secret` (`INTERNAL_SERVICE_SECRET` env).

### Alert ingest (`POST /telemetry/alert`) — verified

Fall detected path:
1. Create `FallEvent` row (confidence, location, model_version, features).
2. Gate confidence `>= _fall_confidence_threshold()` (env `FALL_CONFIDENCE_THRESHOLD`, default 0.7).
3. If pass: `EmergencyService.trigger_sos(trigger_type='auto', ...)`.
4. If fail: create soft `Alert` row với `alert_type='fall_detection', severity='high'`, title "chờ xác minh".
5. Post-fall risk snapshot: `calculate_device_risk(allow_cached=False, dispatch_alerts=False)`.
6. Patient-facing push: `PushNotificationService.send_fall_critical_alert` (background task).

Vitals out of range path:
- Create Alert row với mapped severity (`warning` sang `high`, `critical` sang `critical`) + mapped type.
- Dispatch risk alerts qua `dispatch_risk_alerts()` nếu applicable.

Sleep context path:
- Nếu metadata `sleep_context=true` thì load `SettingsService.get_vitals_sleep_thresholds()` (AASM thresholds) và log.

Auth: `require_internal_service` ✓.

### IMU window ingest (`POST /telemetry/imu-window`) — verified

Phase 4B-thin. Request: `ImuWindowRequest` (db_device_id, sampling_rate, window_size, data list[SensorSample] min 20).

Logic:
1. Forward sang `get_model_api_client().predict_fall(model_payload)`.
2. On success: `FallPersistenceAdapter.persist()` write 1 `fall_events` row.
3. On `None` (breaker open / 5xx / transport error): return `status="model_unavailable"`, NO row written.

Auth: ⚠️ NO `require_internal_service` — bug HS-004.

### Sleep risk ingest (`POST /telemetry/sleep-risk`) — verified

Phase 4A-thin. Request: `SleepRiskRequest` (db_device_id, db_user_id, record: SleepRecord verbatim model-api shape).

Logic:
1. Forward `get_model_api_client().predict_sleep(record_dict)`.
2. On success: `SleepRiskAdapter.from_response()` build `NormalizedExplanation` với score inversion (`risk_score = 100 - predicted_sleep_score`).
3. `RiskPersistenceAdapter.persist(risk_type='sleep')` write `risk_scores` row.
4. On `None`: return `status="model_unavailable"`.

Auth: ⚠️ NO `require_internal_service` — bug HS-004.

### IoT Simulator contract — verified

| Endpoint                                         | IoT Sim Client                                                       | Auth Headers                                               |
| ------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| `/mobile/telemetry/ingest`                       | `HttpPublisher` (transport layer), `dependencies.py:670-675`         | `X-Internal-Service: iot-simulator`                        |
| `/mobile/telemetry/alert`                        | `alert_service.py:160`, `dependencies.py:1217`                       | `X-Internal-Service: iot-simulator` + optional `X-Internal-Secret` |
| `/api/v1/mobile/telemetry/imu-window`            | `pre_model_trigger/mobile_telemetry_client.py:183`                   | `X-Internal-Service: iot-simulator` + `X-Internal-Secret` |
| `/api/v1/mobile/telemetry/sleep-risk`            | `pre_model_trigger/mobile_telemetry_client.py:183`                   | `X-Internal-Service: iot-simulator` + `X-Internal-Secret` |

Note: IoT sim DOES send correct auth headers. Gap là BE không check 3 endpoints (`imu-window`, `sleep`, `sleep-risk`) — HS-004.

### DB schema — verified

**`vitals` hypertable (TimescaleDB):**
- PK: (device_id, time).
- Columns: heart_rate, spo2, temperature, blood_pressure_sys/dia, hrv, respiratory_rate, signal_quality, motion_artifact.
- 7-day chunks, 1 record/second/device theoretical max.

**`motion_data` hypertable (TimescaleDB):**
- PK: (device_id, time).
- Columns: accel_x/y/z, gyro_x/y/z, magnitude, sampling_rate.
- 1-day chunks, 50-100 records/second/device theoretical.
- NO write path trong HTTP ingest code.
- ADR-013 plan (`Iot_Simulator_clean/plans/IOT_SIM_DIRECT_DB_WRITE.md` §6) schedule IoT sim direct-DB INSERT vào motion_data — chưa implement runtime.

**Continuous aggregates:**
- `vitals_5min` (real-time dashboard).
- `vitals_hourly` (1-week history).
- `vitals_daily` (long-term trends).

### Direct-DB write path (ADR-013)

`Iot_Simulator_clean/api_server/dependencies.py:1046-1050`:
```python
"UPDATE devices SET last_sync_at = NOW(), updated_at = NOW() WHERE id = :device_id AND deleted_at IS NULL"
```

ADR-013 direction: vitals tick payload KHÔNG qua HTTP `/telemetry/ingest` nữa, mà direct-DB INSERT qua `session_scope()`. Alert/sleep/risk vẫn qua HTTP. Plan documented, chưa fully implemented (grep `transport_router.publish` trả 0 hits runtime).

---

## 🟡 Drift findings v2

### A. Claim đúng từ v1 (confirm)

1. ✅ 5 endpoint list, 2 có auth, 3 không có.
2. ✅ Vitals ON CONFLICT DO NOTHING dedup.
3. ✅ `last_sync_at` update path trong ingest (line 287-295).
4. ✅ Fall confidence threshold 0.7 + gate logic.
5. ✅ SOS trigger + soft alert paths.
6. ✅ Post-fall risk snapshot.
7. ✅ Sleep context threshold awareness.
8. ✅ IoT sim sends correct auth headers.
9. ✅ `motion_data` table exists nhưng HTTP ingest code không write (ADR-013 plan).

### B. Claim OVERLAP với bug đã track (v2 drop decision, reference instead)

#### B.1 D-ING-01 Q1 "Auth gap 3 endpoints" = HS-004

v1 claim Phase 4 task `fix(security): add require_internal_service to imu-window + sleep + sleep-risk` effort ~15min.

Thực tế: HS-004 (commit session SLEEP 2026-05-13) đã cover chính xác 3 endpoint này + bundle IoT sim header verify. Effort HS-004 estimate ~30min (code + IoT sim).

Fix v2: Drop D-ING-01 decision, reference HS-004.

#### B.2 D-ING-02 Q2 "Topology doc drift `/api/internal/*`" = XR-001

v1 claim Phase 4 task `docs: update 11-cross-repo-topology.md IoT sim paths` effort ~5min.

Thực tế: XR-001 (bug đã có 2026-05-13) cover đúng drift này + scope rộng hơn: review all 5 row trong "Boundary contracts" table của steering. Không chỉ 1 row IoT sim mà còn row Mobile sang Backend (thiếu `/v1`), Admin Web sang Admin BE (thiếu `/v1`).

Fix v2: Drop D-ING-02 decision, reference XR-001.

### C. Decisions v2 keep (doc-only, không overlap bug)

#### C.1 D-ING-03 `motion_data` unused table

Keep. Decision B3 — document reserved Phase 5+ + reference ADR-013 plan. Doc-only.

#### C.2 D-ING-04 Inline risk eval

Keep. Decision B4 — acceptable cho đồ án 2 scope (<100 devices). Doc-only.

Note cho Phase 4 (parking): inline risk eval loop qua device_ids trong `/ingest` là blocking flow. Với 100 device cùng push vitals peak case, response có thể >5s. UC006 violation. Defer sang UC006 v2 session để document NFR latency + background task plan Phase 5+.

### D. Self-correction cross-module

#### D.1 `last_sync_at` dead column claim SAI trong DEVICE.md v2 + HS-003

Em claim trước đó trong session DEVICE:
- DEVICE.md v2 section C.5: "last_sync_at dead column"
- UC042 v2 BR-042-03: "last_sync_at hiện KHÔNG được update bởi code nào"
- HS-003 sub-task 3: "Option A drop column hoặc Option B populate"

Thực tế: `telemetry.py:287-295` CÓ update `last_sync_at = NOW()` sau vitals ingest. IoT sim `dependencies.py:1046-1050` cũng có update path direct-DB (ADR-013).

Root cause em claim sai: session DEVICE em grep với `includePattern: **/health_system/backend/**/*.py`, vẫn match telemetry.py nhưng có thể em miss line do partial scan. Session INGESTION em grep workspace-wide thấy đầy đủ.

Fix v2 (commit cùng lúc session này):
- **DEVICE.md v2 C.5**: rewrite "dead column" sang "FE heuristic edge case".
- **UC042 v2 BR-042-03**: remove claim "không được update".
- **HS-003 sub-task 3**: downgrade severity Medium sang Low, fix approach chỉ FE-only heuristic patch.

---

## 🎯 Anh's decisions Phase 0.5 v2

Anh chọn "theo em default" (2026-05-13):

| ID                   | Item                                  | Decision                                                            | Output artifact                  |
| -------------------- | ------------------------------------- | ------------------------------------------------------------------- | -------------------------------- |
| ~~D-ING-01~~         | ~~Auth gap 3 endpoints~~              | DROP, overlap HS-004                                                | Reference HS-004                 |
| ~~D-ING-02~~         | ~~Topology doc drift~~                | DROP, overlap XR-001                                                | Reference XR-001                 |
| D-ING-03             | `motion_data` unused                  | Keep table, document reserved Phase 5+ (ADR-013 plan)               | UC006 NFR note (optional)        |
| D-ING-04             | Inline risk eval                      | Keep inline, UC006 note acceptable <100 devices                     | UC006 NFR note (optional)        |
| **E3 self-correct**  | `last_sync_at` dead claim             | Fix DEVICE.md v2 + UC042 v2 + HS-003                                | 3 file update, same session      |
| **E4 parking**       | Blocking inline risk eval latency     | Defer sang UC006 v2 session (Monitoring module)                     | UC006 parking note               |

### Phase 4 total (revised INGESTION scope)

| Task                                                          | Track via         | Effort           |
| ------------------------------------------------------------- | ----------------- | ---------------- |
| Auth guard 3 endpoints                                        | **HS-004**        | ~30min (bundled) |
| Topology doc sync                                             | **XR-001**        | ~30min (5 rows)  |
| motion_data document                                          | D-ING-03 doc      | ~5min            |
| Inline risk eval UC006 NFR note                               | D-ING-04 doc      | ~5min            |
| Self-correct 3 file cho last_sync_at                          | E3                | ~15min           |

Estimated Phase 4 code effort (INGESTION only): 0h — all bugs tracked elsewhere.
Estimated Phase 0.5 self-correction effort (now): ~15min.

---

## 🆕 Industry standard add-ons — anh's selection

Tất cả DROP (giữ nguyên v1):

- ❌ Message queue (Redis/RabbitMQ) — Phase 5+ scale
- ❌ Data validation pipeline (schema registry) — Phase 5+
- ❌ Backpressure / rate limiting on ingest — Phase 5+
- ❌ Raw IMU persistence to `motion_data` — ADR-013 scope, Phase 4+ IoT sim scope

---

## 📊 Drift summary v2

### Code impact (Phase 4 backlog)

| Finding                          | Track via        | Severity    | Effort                       |
| -------------------------------- | ---------------- | ----------- | ---------------------------- |
| Auth gap (v1 D-ING-01 dropped)   | **HS-004**       | 🔴 Critical | ~30min (in HS-004)           |
| Topology doc (v1 D-ING-02 dropped)| **XR-001**       | 🟡 Medium   | ~30min (in XR-001)           |
| motion_data unused (D-ING-03)    | D-ING-03 doc     | 🟢 Doc      | ~5min                        |
| Inline risk eval (D-ING-04)      | D-ING-04 doc, UC006 NFR parking | 🟢 Doc | ~5min                        |
| `last_sync_at` self-correct      | E3               | 🟢 Doc fix  | ~15min                       |

INGESTION không có task code riêng Phase 4 — all bugs tracked via HS-004 + XR-001.

### Cross-repo coordination

- **Iot_Simulator_clean:** No change (handled in HS-004 IoT sim scope + ADR-013 ongoing).
- **health_system mobile BE:** Phase 4 HS-004 fix 3 endpoints.
- **PM_REVIEW steering:** Phase 4 XR-001 fix topology table.
- **DB:** No change.

---

## 📝 Anh's decisions log v2

### Active decisions

| ID         | Item                             | Decision                             | Rationale                                                      |
| ---------- | -------------------------------- | ------------------------------------ | -------------------------------------------------------------- |
| D-ING-03   | `motion_data` reserved           | Keep table, doc Phase 5+ / ADR-013   | Harmless; Phase 5+ raw IMU use case valid; ADR-013 plan tracks |
| D-ING-04   | Inline risk eval                 | Keep inline, parking UC006 v2        | <5s met cho <100 devices; non-blocking on failure; UC006 NFR   |
| ~~D-ING-01~~ | ~~Auth gap~~                   | DROP, reference HS-004               | Overlap bug track                                              |
| ~~D-ING-02~~ | ~~Topology doc~~               | DROP, reference XR-001               | Overlap bug track                                              |
| E3         | `last_sync_at` self-correct      | Fix DEVICE.md v2 + UC042 + HS-003    | False claim propagation prevent                                |
| E4         | Blocking flow latency            | Parking UC006 v2 session             | Scope INGESTION không cover NFR latency                        |

### Add-ons dropped

| Add-on                       | Decision |
| ---------------------------- | -------- |
| Message queue                | ❌ Drop |
| Schema validation pipeline   | ❌ Drop |
| Backpressure/rate limiting   | ❌ Drop |
| Raw IMU persistence          | ❌ Drop (ADR-013 scope IoT sim) |

---

## Cross-references

### Code paths (mobile BE — no new Phase 4 task from INGESTION)

- `health_system/backend/app/api/routes/telemetry.py:287-295` — `last_sync_at = NOW()` update path VERIFIED (contradicts DEVICE.md v2 C.5 claim).
- `health_system/backend/app/api/routes/telemetry.py:551+` — 3 endpoints no auth (tracked HS-004, not D-ING-01).

### Code paths (IoT sim — no change)

- `Iot_Simulator_clean/transport/http_publisher.py` — sends headers ✓
- `Iot_Simulator_clean/pre_model_trigger/mobile_telemetry_client.py:183` — sends headers ✓
- `Iot_Simulator_clean/api_server/dependencies.py:1046-1050` — direct-DB `last_sync_at` update (ADR-013 path).

### DB schema

- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` section 04 — vitals + motion_data hypertables + continuous aggregates.
- `motion_data` — reserved Phase 5+ (D-ING-03).

### Steering docs

- `.kiro/steering/11-cross-repo-topology.md` — Phase 4 update paths tracked trong XR-001.

### Related bugs

- **HS-004** — telemetry endpoints no auth Critical (covers D-ING-01).
- **XR-001** — topology steering prefix drift Medium (covers D-ING-02).

### Related UCs

- UC006 View Health Metrics — precondition (ingestion). Phase 0.5 session sau sẽ address NFR latency (E4 parking).
- UC007 View Detail — uses continuous aggregates.
- UC008 Alert Thresholds — triggered by alert ingest.

### Related ADRs

- **ADR-005** (Internal service-to-service auth) — pattern HS-004 miss apply.
- **ADR-013** (IoT sim direct-DB vitals) — motion_data + vitals tick plan.
- Không tạo ADR riêng INGESTION — no architectural change.

---

## Changelog

| Version | Date       | Note                                                                                                                       |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------- |
| v1      | 2026-05-13 sáng | Initial 4 Q drift review (D-ING-01 to D-ING-04)                                                                       |
| v2      | 2026-05-13 chiều | Deep verify: drop D-ING-01/02 overlap HS-004/XR-001, add E3 self-correction `last_sync_at`, parking E4 UC006 latency |
