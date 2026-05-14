# ADR-013: IoT Simulator ghi DB truc tiep cho vitals tick (bypass BE)

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, iot-sim, health_system, cross-repo, performance, scope]

## Context

Phase 0.5 intent drift doc `ETL_TRANSPORT.md` (Q4, 2026-05-13) chot "IoT sim -> BE -> DB, direct DB = vi pham boundary contract". Nhung:

1. **Runtime evidence** (`grep transport_router.publish = 0 hit`): `TransportRouter` da duoc init trong `dependencies.py:675` nhung **khong co call site** trong runtime. Kien truc `IoT sim -> TransportRouter -> HTTP -> BE` chua bao gio active.
2. **Plan `IOT_SIM_DIRECT_DB_WRITE.md` (2026-04-13)** da phan tich + approve Option C: thay `transport_router.publish()` bang `session_scope()` + batch INSERT truc tiep vao bang `vitals` + `motion_data`. Plan co Impact Analysis §8 xac nhan blast radius = 1 method.
3. **Precedent da ton tai:** `_update_device_heartbeat()` (`dependencies.py:854-864`) da direct-DB write qua `SimAdminService.update_heartbeat()` -> pattern proven.
4. **Forces:**
   - Latency `avgLatencyMs: 2074ms` qua HTTP (per plan §1) - UX Dashboard xau.
   - IoT sim phai doi health_system BE chay moi push duoc vitals -> fragile.
   - Vitals tick la write-only telemetry (HR, SpO2, motion) - khong can BE business logic validation (khong trigger notification, khong score calculation).

5. **Constraints:**
   - IoT sim da co `DATABASE_URL` + SQLAlchemy engine + `session_scope` context manager (qua `api_server/db.py`).
   - Shared schema `healthguard` - health_system BE doc bang `vitals` cung format.
   - Alert / sleep / risk co business logic (notifications, scoring, ML) -> giu HTTP path.

**References:**
- `Iot_Simulator_clean/plans/IOT_SIM_DIRECT_DB_WRITE.md`
- `Iot_Simulator_clean/api_server/dependencies.py:670-675` (transport wire, unused)
- `Iot_Simulator_clean/api_server/dependencies.py:854-864` (heartbeat direct-DB precedent)
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/ETL_TRANSPORT.md` (Q4 - superseded by this ADR)
- `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/ETL_TRANSPORT_verify.md` (C3 issue, F-ET-02 backlog)

## Decision

**Chose:** Option B (hybrid) tu plan - **vitals tick + motion_data ghi DB truc tiep; alert / sleep / risk giu HTTP qua BE.**

**Why:**
1. **Latency fix dang dong tien.** Vitals tick = >90% traffic volume (moi 5s per device). 2074ms -> ~10ms DB write = 200x improvement. UX Dashboard + Verification table hien thi dung latency write thay vi network noise.
2. **Not a new pattern.** Heartbeat da direct-DB. Them 2 bang (`vitals`, `motion_data`) cung style khong expand blast radius thuc su.
3. **Vitals = write-only telemetry.** Khong can BE validation, notification, hay scoring. BE chi la thin proxy hien tai (route -> insert). Cat bo proxy = giam latency khong mat gi.
4. **Alert / sleep / risk giu HTTP vi CO business logic** - FCM push, score calculation, ML inference. Cat nhung path nay se mat feature, khong phai chi mat latency.
5. **Q4 cu dua tren gia dinh sai** - "qua BE validate" khong dung voi thuc te (BE telemetry ingest endpoint khong co business validation phuc tap, chi insert). Refactor Q4 decision reflect reality.

## Options considered

### Option A (rejected): Giu Q4 - Tat ca qua BE

**Description:** Implement `transport_router.publish()` call site cho vitals tick (hien dang missing). Giu nguyen architecture "IoT sim -> HTTP -> BE -> DB".

**Pros:**
- Consistent boundary contract: moi external service write DB qua BE.
- Business validation point tap trung neu sau nay them rules.

**Cons:**
- Latency 2074ms co huu - network + BE routing + serialization overhead.
- IoT sim phu thuoc BE runtime (circular-like: sim muon test BE nhung sim can BE chay truoc).
- Khong co validation thuc te tai BE cho vitals ingest -> overhead khong doi lai gi.
- Plan direct-DB bi scrap -> wasted analysis work.

**Why rejected:** Cost/benefit nguoc - pay latency (2s) de co boundary ma khong co validation thuc te. Plan da xac nhan viec enforce "boundary" cho vitals chi la ly thuyet.

### Option B (chosen): Hybrid - vitals direct-DB, alert/sleep/risk qua HTTP

**Description:** Implement plan Section 6 Phase 1:
- `_execute_pending_tick_publish()` thay `transport_router.publish(messages)` bang `session_scope()` + batch INSERT vao `vitals` + `motion_data`.
- Giu nguyen `_push_alert_to_backend()`, `_push_sleep_to_backend()`, `_trigger_risk_inference()`.
- `TransportRouter` + `HttpPublisher` + `MqttPublisher` giu lai **khong xoa** nhung mark deprecated (dead code now, cleanup rieng).

**Pros:**
- Latency ~200x faster (2074ms -> ~10ms).
- IoT sim independent cho vitals (van can BE cho alert/risk).
- Blast radius thuc su 1 method per plan §8.
- Alert/sleep/risk giu business logic qua BE.
- Pattern heartbeat da proven.

**Cons:**
- IoT sim gio co 2 write modes (DB direct cho vitals, HTTP cho alert/sleep/risk) - can document ro tai sao tach.
- Neu sau nay BE muon add validation cho vitals -> phai migrate lai.
- Schema coupling: IoT sim phai biet schema `vitals` + `motion_data` (hien da coupled qua SQLAlchemy models).
- `TransportRouter` thanh dead infrastructure neu khong cleanup.

**Effort:**
- S Decision + ADR: 1h (done by end of this turn).
- M Implementation: 4-6h (per plan §6 Phase 1+2).
- S Doc update (drift doc + topology): 30min.

### Option C (rejected): Full direct-DB (alert + sleep + risk cung DB)

**Description:** IoT sim bypass BE hoan toan - ghi DB cho vitals, motion, alert, sleep session, risk score.

**Pros:**
- IoT sim hoan toan doc lap.
- Maximum latency reduction.

**Cons:**
- Alert can FCM push logic (o BE) - neu bypass, mat notification.
- Sleep score calculation o BE - neu bypass, phai port logic sang sim.
- Risk inference can ML model call + SHAP - bypass = re-implement.
- Blast radius lon gap 5-10 lan vs Option B.

**Why rejected:** Bypass business logic = re-implement feature. YAGNI - vitals latency da giai quyet 90% van de.

---

## Consequences

### Positive

- Dashboard `avgLatencyMs` giam ~2000ms -> ~10ms. Verification table correct.
- IoT sim vitals tick khong can BE runtime -> testing/demo flexibility.
- Plan direct-DB unblocked, implement sau khi ADR accepted.
- Q4 drift doc revised theo reality (transport chua bao gio wire, khong phai "doi huong").

### Negative / Trade-offs accepted

- Em accept split ownership cua DB write (IoT sim direct + BE) - document ro trong drift doc + topology.
- `TransportRouter` + publishers tro thanh legacy dead code - cleanup task P2 rieng.
- Neu production can audit log cho vitals writes tu sim -> phai add audit trong sim (out of scope now).

### Follow-up actions required

- [ ] **Phase 4 task (code):** Implement plan §6 Phase 1 - inline SQL trong `_execute_pending_tick_publish()`. Effort M (~4-6h).
- [ ] **Phase 4 task (code):** Smoke test - vitals + motion_data xuat hien trong DB, dashboard latency giam.
- [ ] **Phase 4 task (code, P2):** Decide co cut `transport/` module hay khong. Neu yes: +3-4h cleanup + update tests.
- [ ] **Phase 0.5 doc:** Rewrite `ETL_TRANSPORT.md` drift doc - mark Q4 superseded by ADR-013, update E4/E6/E7 per reality.
- [ ] **Phase 0.5 doc:** Update `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - document IoT sim DB write path cho vitals.
- [ ] **Steering sync:** Update `.kiro/steering/11-cross-repo-topology.md` - document exception "IoT sim vitals -> DB direct" voi rationale link ADR-013.

## Reverse decision triggers

Conditions de reconsider:

- Neu BE can add validation/transformation cho vitals ingest (e.g., per-device calibration, cross-vital consistency check) -> migrate vitals back qua BE.
- Neu audit compliance yeu cau moi vital write phai pass qua authenticated/logged gateway (HIPAA-style) -> revert Option A.
- Neu team expand va co DBA muon enforce schema ownership -> reconsider split writes.

## Related

- **Plan:** `Iot_Simulator_clean/plans/IOT_SIM_DIRECT_DB_WRITE.md` - detailed impact analysis approved.
- **Supersedes:** Q4 decision trong `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/ETL_TRANSPORT.md` (2026-05-13 original).
- **Verify report:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/ETL_TRANSPORT_verify.md` (C3 finding triggered this ADR).
- **ADR:** ADR-004 (API prefix) - cross-reference but khong conflict (ADR-013 ve DB direct write, ADR-004 ve HTTP paths).
- **Bug:** XR-001 (topology steering drift) - separate, khong conflict.
- **Code:**
  - `Iot_Simulator_clean/api_server/dependencies.py:866-901` (_execute_pending_tick_publish - se change)
  - `Iot_Simulator_clean/api_server/dependencies.py:854-864` (heartbeat precedent - khong change)
  - `Iot_Simulator_clean/transport/*` (legacy after change - cleanup P2)

## Notes

### Why khong chon Option C (full direct-DB)

Plan `IOT_SIM_DIRECT_DB_WRITE.md` §9 da raise open questions cho alert/sleep/risk:
- Alert: BE co FCM trigger logic.
- Sleep: BE co AI scoring.
- Risk: BE co ML inference.

3 domains nay co BE business logic thuc su, khong phai thin proxy nhu vitals. Cat = mat feature.

### Vitals ingest endpoint hien tai co validation khong?

Grep `health_system/backend/app/api/routes/telemetry.py` (em da doc het) - endpoint `/mobile/telemetry/ingest` chi la pass-through insert, khong co pydantic validator nang ngoai schema shape check. BE ingest ~= IoT sim direct write. Option B khong mat feature gi.

### Audit log concern

Neu tuong lai can audit moi vital write tu sim (khong phai user production), co the add logging trong `_execute_pending_tick_publish()` inline - khong can phai qua BE. Add log handler trong sim layer.

### TransportRouter cleanup decision

ADR-013 chi confirm Option B direction. **Khong** mandate cut transport module - do la separate decision (tooling scope, P2 backlog). Ly do: neu tuong lai enable MQTT broker that (capstone+1), router pattern co ich. Keep code, mark comments ro "dead at runtime, reserved for MQTT future".
