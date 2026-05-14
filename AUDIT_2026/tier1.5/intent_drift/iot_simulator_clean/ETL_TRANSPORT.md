# Intent Drift Review - Iot_Simulator_clean / ETL_TRANSPORT

**Status:** Confirmed v2 (2026-05-13) - Q4 SUPERSEDED by ADR-013; Transport section rewritten to reflect runtime reality
**Repo:** `Iot_Simulator_clean`
**Module:** ETL_TRANSPORT
**Related UCs (old):** N/A (internal tooling - no UC existed)
**Phase 1 audit ref:** N/A (not audited yet)
**Date prepared:** 2026-05-13
**Date confirmed (v1):** 2026-05-13
**Date revised (v2):** 2026-05-13 (post verify pass)
**Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/ETL_TRANSPORT_verify.md`

---

## Rev history

- **v1 (2026-05-13 morning):** Q1-Q6 chot, status Confirmed.
- **v2 (2026-05-13 afternoon):** Verify pass phat hien 3 CRITICAL + 3 HIGH drift giua doc va code:
  - C1 `TransportRouter.publish()` = 0 runtime call sites -> E4/E6 claims sai.
  - C2 Endpoint cross-reference `/api/internal/telemetry` sai (reality: `/mobile/telemetry/ingest`).
  - C3 Q4 "qua BE" xung dot voi plan `IOT_SIM_DIRECT_DB_WRITE.md` - **Resolved by ADR-013 (hybrid direct-DB cho vitals tick).**
  - H1-H3: E6/E7 wording sai ve latency layer va fallback direction.
- Transport section rewritten theo runtime reality + ADR-013.

---

## Muc tieu doc nay

Capture intent cho ETL pipeline + Transport layer cua IoT Simulator.
Day la internal tooling (khong user-facing), khong co UC cu. Output = new intent doc + Phase 4 task list.

---

## Memory aid - UC cu summary

Khong co UC cu cho module nay. IoT Simulator la internal testing tool.

---

## Code state - what currently exists

**ETL Pipeline (`etl_pipeline/`):**
- `normalize.py`: `NormalizedArtifactPipeline` - orchestrate 8 adapters normalize thanh parquet/jsonl artifacts. CLI entrypoint `python -m etl_pipeline.normalize --output-dir ...`.
- `artifact_writer.py`: `ArtifactWriter` - parquet primary (neu co pandas+pyarrow), jsonl fallback.
- `window_builder.py`: `build_motion_windows()` - fixed-length windows (default `target_length=100, stride=25`) grouped by subject/dataset/activity/fall_variant.

**Dataset Adapters (`dataset_adapters/`):** 8 adapters (verified tu `__init__.py`):
- BIDMC (PPG/SpO2/respiration), PAMAP2 (activity/motion), PIFV3 (multi-modal synthetic),
- PPGDaLiA (HR), SleepEdf (hypnogram), UPFall (fall events), VitalDB (BP/SpO2), WESAD (stress)
- Base adapter `DatasetAdapter` + shared types (`SleepPhase`, `SleepSessionRecord`, `SimpleDataFrame`)

**Transport layer (`transport/`):** 
- `Publisher` (abstract) + `PublishResult` dataclass (`ok`, `transport_mode`, `target`, `message_count`, `ack_count`, `error`).
- `HttpPublisher`: POST JSON with optional headers. Mode `http`.
- `MqttPublisher`: paho-mqtt topic routing `{topic_prefix}/{device_id}`. Mode `mqtt`. Supports `client` callback override for testing.
- `TransportRouter`: routes `mode="mqtt"` -> MQTT primary + HTTP fallback on failure; `mode="http"` -> HTTP only, no fallback.

**Transport wiring (at runtime startup):**
- `api_server/dependencies.py:670-675` init `TransportRouter(mqtt, http)` with:
  - MQTT `client=lambda topic, payload: True` (mock, no broker).
  - HTTP endpoint `/mobile/telemetry/ingest` on `HEALTH_BACKEND_URL`, header `X-Internal-Service: iot-simulator`.
- **`grep transport_router.publish` = 0 hits trong runtime code paths.** Router init nhung chua duoc goi. Reserved for future MQTT enable (post-capstone).

**Actual runtime telemetry paths (what really runs):**
- Vitals tick + motion (>90% volume): currently `transport_router.publish` call site MISSING - per ADR-013 se implement inline DB INSERT qua `session_scope()`.
- Alert push: `alert_service.py` direct `httpx` POST -> `/mobile/telemetry/alert`.
- Sleep push: `sleep_service.py` shared `httpx.Client` POST -> `/mobile/telemetry/sleep`.
- Risk inference: `dependencies.py:1214-1220` direct `httpx` POST -> `/mobile/risk/calculate`.
- Heartbeat: `SimAdminService.update_heartbeat()` direct DB write qua `session_scope` (precedent cho ADR-013).

**Artifacts output (from `NormalizedArtifactPipeline.run()`):**
- `motion_windows` (100 samples/window, 6-axis accel/gyro + accel_mag) - always written.
- `vitals_stream` (HR, SpO2, BP, temp) - always written.
- `event_catalog` (fall events with pre/post vitals) - always written.
- `stress_stream` (WESAD stress states) - **conditional** (only if rows > 0).
- `respiration_stream` (BIDMC) - **conditional**.
- `sleep_sessions` (Sleep-EDF hypnogram) - conditional via `normalize_sleep()` helper.
- `normalize_summary.json` metadata always written.

---

## Anh's decisions (Q1-Q6 + revised Q4)

### Q1: ETL scope - offline hay runtime?
**Decision:** ETL offline, runtime read artifacts. (UNCHANGED v1 -> v2)
**Rationale:** ETL normalize datasets nang (phut). Tach offline = boot nhanh, artifacts san tren disk.

### Q2: Dataset coverage - 8 datasets du chua?
**Decision:** Keep 8, khong them khong bot. (UNCHANGED)
**Rationale:** 8 datasets cover du domain signals (HR/SpO2, motion/fall, sleep, stress, respiration). Capstone scope du.

### Q3: Transport priority - MQTT hay HTTP?
**Decision (revised v2):** Hien tai **khong co transport layer active o runtime**. Runtime dung direct `httpx` cho alert/sleep/risk + direct DB cho heartbeat + (per ADR-013) direct DB cho vitals tick. TransportRouter + publishers giu lai nhu legacy abstraction cho future MQTT enable (post-capstone).
**Rationale:** Grep 0 call site confirm `TransportRouter.publish` chua bao gio duoc goi. Active paths di theo 4 duong rieng re + heartbeat/vitals DB direct.

### Q4: Transport target? (**SUPERSEDED by ADR-013**)
**Decision v1 (2026-05-13 morning):** Qua BE (IoT sim -> health_system BE -> DB).
**Decision v2 (2026-05-13 afternoon, per ADR-013):** **Hybrid.** Vitals tick + motion_data ghi DB **truc tiep** qua `session_scope()`. Alert / sleep / risk giu HTTP qua BE (co business logic).
**Rationale:** Xem ADR-013 full context. Tom tat: (i) TransportRouter qua BE chua bao gio active; (ii) Heartbeat precedent da direct DB; (iii) BE ingest endpoint khong co business validation; (iv) Latency 2074ms -> ~10ms (200x).

### Q5: Delivery guarantee?
**Decision:** At-most-once, log result (ok/fail, ack count, latency). (UNCHANGED)
**Note:** Latency tracked o caller layer (`session.last_publish_latency_ms`), khong trong `PublishResult`. Publisher chi track ok/ack_count/error.
**Rationale:** Simulator data = gia lap. Mat 1-2 message khong anh huong. Retry them complexity khong can thiet cho testing tool.

### Q6: Motion window size?
**Decision:** Keep 100 samples, stride 25. (UNCHANGED)
**Rationale:** Fall AI model trained tren input shape 100. Doi window size = model predict sai. Stride 25 = 75% overlap, du granularity.

---

## Features moi

Khong co.

---

## Features DROP

Khong co. Giu nguyen code transport (MQTT + HTTP publishers + Router) nhu legacy. Cleanup module deferred P2 backlog.

---

## Confirmed Intent Statement (v2)

> ETL Pipeline normalize 8 medical research datasets (offline CLI) thanh parquet artifacts (hoac jsonl fallback) ma IoT Simulator runtime doc duoc. 
> 
> Transport layer (`transport/*` module) hien la **legacy abstraction khong active tai runtime** (router + publishers init nhung 0 call site) - giu lai reserved cho future MQTT enable post-capstone.
> 
> Runtime telemetry di **5 duong song song**:
> 1. Vitals tick + motion_data -> **direct DB INSERT** qua `session_scope()` (per ADR-013).
> 2. Alert push -> HTTP POST `/mobile/telemetry/alert` qua `httpx`.
> 3. Sleep push -> HTTP POST `/mobile/telemetry/sleep` qua shared `httpx.Client`.
> 4. Risk inference -> HTTP POST `/mobile/risk/calculate` qua `httpx`.
> 5. Heartbeat -> direct DB write qua `SimAdminService.update_heartbeat()`.
> 
> Header `X-Internal-Service: iot-simulator` apply cho tat ca HTTP calls.

---

## Confirmed Behaviors (v2)

| ID | Behavior | Status | Evidence |
|---|---|---|---|
| E1 | Dataset normalization: 8 adapters -> unified schema | Confirmed | `dataset_adapters/__init__.py` (8 exports) + `normalize.py` imports |
| E2 | Artifact persistence: normalized data -> parquet (primary) / jsonl (fallback) | Confirmed | `artifact_writer.py:27-39` |
| E3 | Motion window building: raw IMU -> 100-sample windows, stride 25 | Confirmed | `window_builder.py:43-44` defaults |
| E4 | Telemetry transport = 5 paths (NOT via TransportRouter) | Confirmed v2 | Grep `transport_router.publish` = 0; actual paths trong "Code state" section |
| E5 | MQTT publisher: paho-mqtt topic routing | Deferred | Code exists `mqtt_publisher.py`, not wired runtime. Reserved post-capstone. |
| E6 | Transport routing logic (when enabled): mqtt primary + http fallback; http mode = single-shot no fallback | Confirmed v2 | `router.py:32-41` code verified. Logic asymmetric (1-way fallback). |
| E7 | Delivery tracking: publisher returns `PublishResult` (ok/ack_count/error); latency tracked at caller layer (`session.last_publish_latency_ms`) | Confirmed v2 | `base_publisher.py:8-16` + `dependencies.py` caller pattern |
| E8 | Direct DB write cho vitals tick + motion (per ADR-013) | Confirmed v2 | ADR-013; implementation in Phase 4 backlog |
| E9 | HTTP paths su dung `X-Internal-Service: iot-simulator` header | Confirmed | `dependencies.py:674`, `alert_service.py:160`, `sleep_service.py` patterns |

---

## Impact on Phase 4 fix plan (v2)

| Phase 4 task | Priority | Effort | Status |
|---|---|---|---|
| Implement ADR-013 inline DB INSERT cho `_execute_pending_tick_publish()` | P0 | 4-6h | **Unblocked by ADR-013** |
| Smoke test: vitals + motion_data xuat hien trong DB, dashboard latency giam | P0 | 1-2h | Paired voi implement |
| Fix XR-001 topology steering drift (5 copies + template) | P1 | 1-2h | Separate chore/ branch |
| Add pydantic validation for outgoing HTTP messages (if transport ever activated) | P2 | 1-2h | Deferred |
| Decide cut `transport/` module hay keep as legacy | P2 | 3-4h | Deferred post-capstone |
| MQTT real implementation (broker + BE consumer) | P3 | 8-12h | Deferred post-capstone |

---

## Cross-references

- **Phase -1 topology:** `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - Path 6, Path 7, D-019 (ground truth cho endpoint paths).
- **Transport contract:** `X-Internal-Service: iot-simulator` header.
- **Fall AI model input:** 100-sample motion windows (`window_builder.py`).
- **Actual runtime endpoints (reality, current):**
  - `/mobile/telemetry/ingest` (defined `dependencies.py:913` for TransportRouter http config; **superseded by direct DB write per ADR-013**)
  - `/mobile/telemetry/alert` (`alert_service.py`)
  - `/mobile/telemetry/sleep` (`sleep_service.py:582`)
  - `/mobile/risk/calculate` (`dependencies.py:1214`)
- **Target state endpoints (per ADR-004):** `/api/v1/mobile/*` (Phase 4 standardization).
- **ADRs:**
  - **ADR-004** (API prefix standardization) - target state.
  - **ADR-005** (Internal service secret) - auth header.
  - **ADR-013** (IoT sim direct-DB vitals) - supersedes Q4 v1.
- **Bugs:**
  - **XR-001** (topology steering drift) - filed 2026-05-13, affects 5 repo steering files.
  - **IS-001** (sleep AI client wrong path) - separate scope, not ETL_TRANSPORT.

---

## Verify audit trail

| Date | Action | By |
|---|---|---|
| 2026-05-13 morning | v1 Q1-Q6 confirmed | Anh + em |
| 2026-05-13 afternoon | Verify pass - 3 CRITICAL + 3 HIGH drift | Em |
| 2026-05-13 afternoon | ADR-013 accepted (Q4 revised) | Anh |
| 2026-05-13 afternoon | XR-001 filed | Em |
| 2026-05-13 afternoon | v2 rewrite confirmed | Em (doc) |
