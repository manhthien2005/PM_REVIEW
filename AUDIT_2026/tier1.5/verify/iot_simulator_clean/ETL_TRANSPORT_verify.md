# Verification Report — `Iot_Simulator_clean / ETL_TRANSPORT`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/ETL_TRANSPORT.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** FAIL — Major drift giua doc va runtime.
**Verdict (resolved 2026-05-13):** PASS v2 — ADR-013 + XR-001 + drift doc v2 + topology Path 9 close out CRITICAL + HIGH findings. MEDIUM/LOW items go to Phase 4 backlog.

---

## TL;DR

- **ETL section**: Mostly dung voi code. Minor gaps (parquet fallback, windowing stats).
- **Transport section**: **SAI nghiem trong**. Drift doc mo ta kien truc `IoT sim -> TransportRouter -> HTTP -> BE` la "primary production", nhung:
  1. `TransportRouter.publish()` **khong duoc goi o bat ky runtime path nao** (grep 0 hit). Transport layer la dead code sau khi `IOT_SIM_DIRECT_DB_WRITE.md` plan da revise.
  2. Telemetry runtime thuc te di 4 duong rieng re (alert / sleep / risk / vitals) - **khong** di qua `TransportRouter`.
  3. Cross-reference endpoint `/api/internal/telemetry` SAI - thuc te la `/mobile/telemetry/ingest`.
- **Intent drift**: Q4 decision ("Qua BE") xung dot voi `plans/IOT_SIM_DIRECT_DB_WRITE.md` dang quyet dinh **bypass BE, write DB truc tiep** cho vitals tick.

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 ETL Pipeline claims

| Claim | Code location | Verdict |
|---|---|---|
| `NormalizedArtifactPipeline` normalize 8 medical datasets | `etl_pipeline/normalize.py:70` + imports tu `dataset_adapters/__init__.py` (BIDMC, PAMAP2, PIFV3, PPG_DaLiA, SleepEdf, UPFall, VitalDB, WESAD = **8 OK**) | OK Dung |
| `artifact_writer.py`: write artifacts to disk (JSON/parquet) | `etl_pipeline/artifact_writer.py:27-39` - parquet neu co pandas+pyarrow, fallback jsonl | WARN Doc noi "parquet" nhung code co jsonl fallback |
| `window_builder.py`: 100 samples, stride 25 | `etl_pipeline/window_builder.py:43` - defaults `target_length=100, stride=25` | OK Dung |
| Offline CLI entrypoint | `normalize.py:504-523` (`_build_cli_parser`, `main`, `__main__`) | OK Dung |
| 6 artifact streams | `normalize.py:103-111` run() output | OK Dung - nhung `respiration_stream`/`stress_stream` la **conditional** (chi ghi neu co rows) |

**ETL verdict: Mostly correct. Minor issue: parquet fallback to jsonl + conditional artifacts.**

### 1.2 Transport claims

| Claim (drift doc) | Code location | Verdict |
|---|---|---|
| `TransportRouter`: route messages - mode="mqtt" (primary) hoac mode="http" | `transport/router.py:26-41` + `api_server/dependencies.py:670-675` | WARN Router code dung, nhung runtime init luon dung mode default = "mqtt" o test |
| `http_publisher.py`: POST to health_system BE, header `X-Internal-Service: iot-simulator` | `transport/http_publisher.py:11-55` + `api_server/dependencies.py:674` | OK Header & class correct |
| Hien tai runtime init MQTT voi mock callback (`client=lambda topic, payload: True`) | `api_server/dependencies.py:670` | OK Dung - confirmed mock, khong ket noi broker that |
| **E4** "HTTP publish: POST to BE with `X-Internal-Service` header - Confirmed (primary)" | **CRITICAL**: grep `transport_router.publish` = **0 match** trong toan repo. Router wired nhung **khong call site** | FAIL SAI - HTTP publisher qua TransportRouter KHONG phai primary runtime path. La dead code. |
| **E6** "Transport routing: configurable mode, auto-fallback on failure" | `router.py:32-34` - `mode=="http"` path **KHONG fallback**, chi `mode=="mqtt"` moi fallback to http | HALF Half-true. Fallback chi hoat dong 1 chieu (mqtt->http). Doc wording misleading. |
| **E7** "Delivery tracking: log ok/fail, ack count, latency per publish" | `PublishResult` dataclass co `ok`, `ack_count` - **KHONG co `latency_ms` field** | FAIL SAI - latency tracking khong trong PublishResult. Latency duoc tracked o `session.last_publish_latency_ms` trong caller layer (`_execute_pending_tick_publish`), khong phai publisher. |
| Cross-reference: "Boundary: IoT sim -> health_system BE `/api/internal/telemetry`" | `dependencies.py:913` - endpoint thuc te `/mobile/telemetry/ingest` | FAIL SAI endpoint |
| "Q4 Decision: Qua BE (IoT sim -> health_system BE -> DB)" | `plans/IOT_SIM_DIRECT_DB_WRITE.md` (2026-04-13) - quyet dinh revised Option C inline SQL DB write, **bypass BE** cho vitals/motion tick | FAIL Decision stale - Q4 decision 2026-05-13 (doc) khong reflect plan 2026-04-13 |

**Transport verdict: Major drift. 4/7 claims fail or misleading.**

### 1.3 Actual runtime telemetry paths (what really happens)

Grep bang chung tu `api_server/`:

| Data type | Actual path | File |
|---|---|---|
| Vitals tick (HR/SpO2/BP/motion) | `_execute_pending_tick_publish()` -> planned **inline DB INSERT** (plan Section 6 revised) | `dependencies.py:866-901` per plan |
| Alert push | Direct `httpx` call trong `alert_service.py` -> `/mobile/telemetry/alert` | `alert_service.py:165` `self._http_sender(endpoint, ...)` |
| Sleep push | Direct `httpx.Client` trong `sleep_service.py` -> `/mobile/telemetry/sleep` | `sleep_service.py:582-585, 641-643` |
| Risk inference | `_trigger_risk_inference()` -> direct httpx -> `/mobile/risk/calculate` | `dependencies.py:1214-1220` |
| Heartbeat | Direct DB write qua `SimAdminService.update_heartbeat()` (session_scope) | `dependencies.py:854-864` (per plan §2.5) |
| **ETL -> telemetry via TransportRouter** | **0 call sites** | - |

**Ket luan**: `TransportRouter` + `HttpPublisher` + `MqttPublisher` la **infrastructure du thua** hien tai. Duoc init trong `__init__` nhung khong ai goi. Day co the la (a) legacy tu design truoc khi tach ra cac service rieng, hoac (b) planned cho future nhung chua wire.

---

## 2. Issues enumerated (prioritized)

### CRITICAL — Block release / wrong behavior claim

**C1. TransportRouter runtime path la ao tuong**
- **Evidence**: `grep -r "transport_router.publish" --include="*.py"` = 0 hits; plan `IOT_SIM_DIRECT_DB_WRITE.md` Section 6 Phase 1 chu dong remove call site.
- **Impact**: Doc bao "HTTP primary, production-ready E2E" -> ai doc spec nay se expect runtime dung TransportRouter. Actual architecture la 4 path roi + plan di direct DB.
- **Fix direction**: 
  - Viet lai Confirmed Intent Statement + E4/E6 de reflect "Transport layer = legacy abstraction, unused at runtime. Actual paths: 4 direct httpx calls + planned direct DB write for vitals tick."
  - Hoac decide cut `transport/` module neu confirmed YAGNI (giam maintenance surface).
- **Effort**: Doc rewrite 1-2h; code cleanup (neu cut transport) 3-4h + test update.

**C2. Cross-repo endpoint path sai**
- **Evidence**: Doc cross-reference `/api/internal/telemetry`; code dung `/mobile/telemetry/ingest` (no /api prefix, no /internal).
- **Impact**: Mobile BE routers da thay doi ten endpoint nhung IoT sim doc chua sync. Ai doc topology se confuse.
- **Cross-repo check**: Verify `health_system/backend/app/api/routes/telemetry.py` route prefix. Steering `11-cross-repo-topology.md` cung bao `/api/internal/*` cho IoT->BE - **topology steering cung sai**.
- **Fix direction**: 
  - Update drift doc cross-reference sang `/mobile/telemetry/{ingest,alert,sleep}` + `/mobile/risk/calculate`.
  - Raise cross-repo inconsistency: topology steering `11-cross-repo-topology.md` claim `/api/internal/*` nhung reality la `/mobile/*` - can chot contract + rewrite mot trong hai.
- **Effort**: Doc 30min; topology decision 1h; propagate sang steering ~30min.

**C3. Q4 "Qua BE" quyet dinh xung dot voi plan direct-DB**
- **Evidence**: 
  - Drift doc Q4 (2026-05-13): "Qua BE (IoT sim -> health_system BE -> DB). Direct DB = bypass validation + vi pham boundary contract."
  - Plan (2026-04-13) Section 6 Phase 1: "Thay `transport_router.publish(messages)` bang `session_scope()` + batch INSERT" cho vitals tick, "pattern da proven boi `_update_device_heartbeat()`" (da direct DB).
- **Impact**: Anh da confirm Q4 = "qua BE" nhung code/plan dang di direct DB. Neu implement theo plan -> vi pham Q4 decision. Neu giu Q4 -> plan bi block.
- **Fix direction**: **Anh can quyet lai** - mot trong hai:
  - (a) **Revise Q4**: accept direct DB cho vitals tick (per plan analysis: latency 2s->10ms). Document as ADR moi. Update doc rationale.
  - (b) **Block plan**: giu Q4 "qua BE", plan direct-DB bi scrap. Tim giai phap khac cho latency (batch push / async).
  - Em recommend (a) vi (i) heartbeat da direct DB proven, (ii) latency impact lon, (iii) vitals tick la write-only khong can BE validation nang. Log audit qua BE du cho alert/risk.
- **Effort**: Decision + ADR 1h; neu chon (a) implement plan 4-6h; update doc 30min.

### HIGH — Spec gap, wrong behavior

**H1. E7 delivery tracking claim sai vi tri**
- **Evidence**: `PublishResult` dataclass khong co `latency_ms`. Latency tracked o `session.last_publish_latency_ms` (caller-side).
- **Impact**: Ai doc E7 tuong publisher tu log latency. Neu replace publisher implementation se mat tracking.
- **Fix direction**: Split E7: "(a) Publisher tracks ok/ack_count qua `PublishResult`; (b) Caller tracks latency qua `session.last_publish_latency_ms` (measured around publish call)".
- **Effort**: Doc 15min.

**H2. E6 auto-fallback semantics incomplete**
- **Evidence**: `router.py` chi fallback mqtt->http, khong fallback http->mqtt.
- **Impact**: Neu runtime goi mode="http" va fail, khong co retry/fallback. Doc goi y "auto-fallback" universal.
- **Fix direction**: E6 nen viet: "Transport routing: mode=mqtt primary + HTTP fallback on MQTT failure. Mode=http = single-shot, no fallback."
- **Effort**: Doc 15min.

**H3. Q3 rationale "HTTP da hoat dong E2E" khong dung qua TransportRouter**
- **Evidence**: E2E flow dung direct httpx (alert/sleep/risk) + tuong lai direct DB (vitals). TransportRouter HTTP path untested trong runtime.
- **Impact**: Rationale support cho Q3 dua tren premise sai.
- **Fix direction**: Revise Q3 rationale: "HTTP direct (4 paths rieng re qua `httpx`) da hoat dong E2E. TransportRouter HTTP = legacy, chua wire vao runtime."
- **Effort**: Doc 20min.

### MEDIUM — Missing / unclear

**M1. IS-001 bug khong duoc mention**
- **Evidence**: Phase 0.5 charter Wave 3 mention "IS-001" (Sleep AI client) cho IoT sim. Drift doc khong reference.
- **Impact**: ETL_TRANSPORT neu khong lien quan thi OK skip. Nhung can confirm scope boundary.
- **Fix direction**: Add explicit note "IS-001 = Sleep AI client scope, thuoc SCENARIOS/SLEEP module, khong thuoc ETL_TRANSPORT." hoac verify neu co lien quan.
- **Effort**: 10min check + note.

**M2. Parquet fallback to jsonl khong document**
- **Evidence**: `artifact_writer.py:33-39` - fallback jsonl neu thieu pandas/pyarrow.
- **Impact**: Minor. Ai deploy thieu deps se confuse vi artifacts o jsonl.
- **Fix direction**: Doc code state: "Artifacts: parquet (primary, requires pandas+pyarrow) / jsonl (fallback)".
- **Effort**: Doc 5min.

**M3. Conditional artifacts (stress/respiration) khong noi bat**
- **Evidence**: `normalize.py:108-111` - `stress_stream` va `respiration_stream` chi ghi neu rows > 0. 
- **Impact**: Minor. Ai expect 6 artifacts luon co se thay thieu.
- **Fix direction**: Doc E1/E2: "6 artifact streams, trong do stress/respiration conditional."
- **Effort**: Doc 5min.

**M4. Input validation contract missing**
- **Evidence**: 
  - `MqttPublisher.publish` - neu `message.get("device_id")` = None thi topic = `devices/sim/unknown` (line 55, 79).
  - `HttpPublisher` - khong validate messages truoc khi serialize.
  - No pydantic schema cho outgoing message format.
- **Impact**: Silent data pollution. `device_id=unknown` messages se di qua nhung BE se fail downstream.
- **Fix direction**: Define `TelemetryMessage` pydantic model (device_id required, vitals/motion optional). Validate truoc publish.
- **Effort**: 1-2h implement + test.

### LOW — Wording / style

**L1. "MQTT deferred (code giu, khong implement that)" -> can ro deferred la post-capstone hay never**
- Per Q3 rationale ro la post-capstone. Doc OK nhung "Phase 4 backlog = P3" la tot -> keep.

**L2. Missing test mention cho `test_transport_router.py`**
- Test co 3 cases (mqtt success, mqtt fail + http fallback, http direct). Drift doc khong reference.
- Add to "Confirmed Behaviors" table nhu evidence cho E4/E6.

---

## 3. Fix backlog (prioritized) — status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-ET-01 | Rewrite drift doc Transport section (C1) - reflect actual runtime paths | P0 | 2h | **DONE** — ETL_TRANSPORT.md v2 rewritten |
| F-ET-02 | Resolve Q4 conflict with direct-DB plan (C3) - chot ADR | P0 | 1h decision + 30min doc | **DONE** — ADR-013 accepted |
| F-ET-03 | Fix cross-reference endpoint (C2) - `/mobile/telemetry/ingest` | P0 | 30min | **DONE** — v2 cross-references updated |
| F-ET-04 | Raise cross-repo topology inconsistency (C2) - steering `11-cross-repo-topology.md` claim `/api/internal/*` sai | P1 | 1h | **LOGGED** — XR-001 filed; fix pending chore/ branch |
| F-ET-05 | Implement direct-DB plan neu chot (a) | P1 | 4-6h | **UNBLOCKED** — Phase 4 backlog, ADR-013 accepted |
| F-ET-06 | Consider cutting `transport/` module neu confirmed dead | P2 | 3-4h | Deferred post-capstone (per ADR-013 Notes) |
| F-ET-07 | Add pydantic validation for outgoing messages (M4) | P2 | 1-2h | Deferred — low priority since transport layer dead |
| F-ET-08 | Fix E6/E7 wording (H1, H2) | P2 | 30min | **DONE** — v2 E6/E7 rewritten with precise semantics |
| F-ET-09 | Revise Q3 rationale (H3) | P2 | 20min | **DONE** — v2 Q3 rationale updated |
| F-ET-10 | Document parquet/jsonl fallback + conditional artifacts (M2, M3) | P3 | 15min | **DONE** — v2 Code state section updated |

**Status summary:** 7/10 DONE, 1/10 LOGGED (XR-001), 1/10 UNBLOCKED (Phase 4), 2/10 deferred post-capstone.

**Total effort spent today:** ~3h (doc rewrite + ADR-013 + XR-001 + topology Path 9 + index updates).
**Remaining (Phase 4 code branch):** 4-6h direct-DB implement + 1-2h smoke test + 1-2h XR-001 steering sync.

---

## 4. Cross-repo impact

### Affected docs/specs
- `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - verify `/api/internal/*` claim vs reality
- `.kiro/steering/11-cross-repo-topology.md` (all 5 repo copies) - same issue
- `PM_REVIEW/Resources/UC/` - khong impact UC (ETL/Transport la internal tooling)

### Affected code repos
- `health_system/backend/app/api/routes/telemetry.py` - endpoint contract (confirm prefix)
- `Iot_Simulator_clean/api_server/dependencies.py` - plan-driven changes
- `Iot_Simulator_clean/transport/` - potential cleanup neu cut

### ADRs can tao
- **ADR-XXX: IoT Simulator direct-DB write cho vitals tick** (decision cho F-ET-02)
- **ADR-XXX: Cross-repo telemetry endpoint prefix** (resolve `/mobile/*` vs `/api/internal/*`)

---

## 5. Next steps - em de xuat

1. **Ngay (5 phut)**: Anh xac nhan uu tien - fix doc truoc (F-ET-01, 03, 08-10) hay resolve decision conflict truoc (F-ET-02)?
2. **Truoc khi implement code**: Anh decide C3 (Q4 vs direct-DB plan).
3. **Sau decision**: Em rewrite drift doc -> reflect confirmed state -> mark status `Confirmed v2`.
4. **Song song**: Raise cross-repo topology issue (C2) - co the em tao bug `XR-NNN` + ADR draft de anh review.

**Em khong edit doc trong phase verify. Output verify nay la input cho anh decide; rewrite chi sau khi anh confirm.**

---

## Appendix — evidence index

- Transport: `transport/{base_publisher,mqtt_publisher,http_publisher,router}.py`
- Runtime wiring: `api_server/dependencies.py:668-675, 908-940`
- Runtime call sites (actual paths): `api_server/services/{alert_service,sleep_service}.py`, `api_server/dependencies.py:1214-1220`
- ETL: `etl_pipeline/{normalize,artifact_writer,window_builder}.py`
- Adapters: `dataset_adapters/__init__.py` (8 adapters confirmed)
- Plan: `plans/IOT_SIM_DIRECT_DB_WRITE.md` (critical context)
- Tests: `tests/test_transport_router.py`, `tests/test_mqtt_publisher_integration.py`
