# Charter — Redesign IoT Simulator + Streaming Pipeline 2026

> **Goal:** Refactor toàn bộ IoT simulator (FE + BE), endpoint contract IoT ↔ Mobile BE ↔ model-api, và Mobile FE/BE consumer theo pattern production wearable chuẩn — match Apple HealthKit / Google Fit / FCM / WebSocket pattern. Loại bỏ drift hiện có (XR-001, HS-024, XR-003) bằng redesign-first thay vì patch-first.

**Created:** 2026-05-15
**Branch:** `chore/redesign-iot-sim-2026` (PM_REVIEW)
**Driver:** ThienPDM
**Executor:** Cascade (Cascade-anh-pair)
**Linked bugs:**
- [HS-024](../BUGS/HS-024-risk-inference-silent-default-fill.md) — risk silent default fill
- [XR-001](../BUGS/XR-001-topology-steering-endpoint-prefix-drift.md) — endpoint prefix drift
- [XR-003](../BUGS/XR-003-model-api-input-validation-contract.md) — contract validation gap
**Linked ADRs (existing):** ADR-004 (api prefix), ADR-013 (IoT direct DB), ADR-015 (severity vocab)
**Status:** ✅ Approved v1.0 — sẵn sàng Phase 1

---

## 1. Background — Vì sao redesign

### 1.1 Triệu chứng quan sát được

Trong audit 2026-05-13/14 + deep-dive session 2026-05-15, em phát hiện:

1. **IoT simulator bypass kiến trúc production** — sim gọi trực tiếp `model-api :8001/api/v1/{fall,sleep}/predict` thay vì đi qua `mobile BE :8000`. Production smartwatch không có path này → simulation không đại diện đúng flow thật.
2. **Vitals dual-path không rõ** — `_execute_pending_tick_publish` direct DB INSERT (ADR-013) song song với `HttpPublisher` wired tới `/mobile/telemetry/ingest`. Một path active, một orphan, hoặc cả hai cùng chạy gây duplicate.
3. **Health risk silent default fill** — mobile BE fill default cho NULL vital fields (HR=75, SpO2=98, BP=120/80) không thông báo cho mobile app → risk score giả mạo (HS-024).
4. **Model-api thiếu input validation** — `VitalsRecord` không có `Field(ge=..., le=...)` → out-of-range data pass validation, confidence cao trên junk data (XR-003).
5. **Endpoint prefix drift** — steering claim `/api/internal/*` cho IoT sim, code dùng `/mobile/*` (XR-001). Slice 2b `MobileTelemetryClient._IMU_WINDOW_PATH = "/api/v1/mobile/..."` orphan, có nguy cơ 404.
6. **Mobile app không phản ánh được data source** — không có cách nào biết data đến từ smartwatch thật vs IoT sim → khi panel chấm demo, không tách bạch được.

### 1.2 Root cause systemic

Tất cả 6 triệu chứng đều phản ánh **1 root cause:** **thiếu contract layer hợp đồng formalize** giữa 5 repo. Mỗi repo viết theo intent riêng, không có spec cross-repo binding → drift xuất hiện theo thời gian.

→ **Redesign-first thay vì patch-first.** Patch từng bug HS-024 / XR-003 chỉ vá triệu chứng. Cần redesign contract + topology.

---

## 2. Mục tiêu redesign

### 2.1 Mục tiêu chính (must)

| # | Mục tiêu | Đo lường |
|---|---|---|
| **M1** | IoT sim outbound flow match production wearable pattern | 100% endpoint IoT→BE có spec + test contract; bỏ direct call IoT→model-api |
| **M2** | Vitals/risk/fall/sleep streaming end-to-end với latency budget rõ ràng | Vitals chart latency p95 ≤ 5s; SOS/fall alert p95 ≤ 3s; risk score cooldown 30-60s |
| **M3** | Mobile UX rõ ràng cho 2 persona (elderly + family) | Vitals card readable cho elderly (font ≥ 18pt); risk detail readable cho family (top features + explanation) |
| **M4** | IoT sim FE narrative cho panel chấm đồ án | Sequence diagram chạy live; status chips từng bước (vitals row inserted → alert pushed → FCM sent); zero technical jargon ngoài label |
| **M5** | Loại bỏ HS-024 + XR-003 + XR-001 dứt điểm | 3 bug đổi status `✅ Resolved` với regression test |
| **M6** | Documentation đầy đủ — không vibe code | 8 artifact deliverables (Charter + 7 phase docs) approved by ThienPDM trước khi code |

### 2.2 Mục tiêu phụ (nice-to-have, optional)

- **N1** — Demo polling 1Hz mode để vitals chart cực mượt khi chấm đồ án
- **N2** — Export sequence diagram video từ simulator-web cho thuyết minh
- **N3** — Performance dashboard cho IoT sim BE (request rate, latency p50/p95)

### 2.3 Non-goals (KHÔNG làm trong redesign này)

- ❌ Stress test mode cho IoT sim (100+ device song song) — YAGNI cho đồ án
- ❌ Production deployment infrastructure (k8s, helm chart, CI/CD pipeline)
- ❌ Wearable hardware thật BLE integration — IoT sim đã đại diện
- ❌ Admin web HealthGuard UX redesign — chỉ bổ sung WebSocket consumer nếu cần
- ❌ Database schema thay đổi lớn — chỉ thêm column nếu thực sự cần (tracked via ADR)
- ❌ AI model retraining hoặc đổi feature engineering — model-api treated as black box (chỉ fix input validation)

---

## 3. Scope đã chốt — sau khi clarify với anh

### 3.1 Persona

| Persona | Where | Mục tiêu UX |
|---|---|---|
| **ThienPDM (anh) + giáo viên hướng dẫn + panel chấm** | simulator-web | Demo-friendly: narrative, sequence diagram live, status chips. Hiểu được flow trong 5 phút giải thích |
| **Elderly user** | Mobile app (self-view) | Đơn giản, chữ to, cảnh báo ngắn gọn tiếng Việt. Không lộ technical jargon (HRV, SHAP, model_version) |
| **Family caregiver** | Mobile app (linked profile view) | Detailed: risk explanation, history, top features. Tiếng Việt formal |

### 3.2 Streaming pattern (đã chốt sau research production)

| Layer | Transport | Latency target | Justification |
|---|---|---|---|
| **IoT sim → mobile BE** (vitals) | REST batch HTTP, 5s tick (configurable) | 5s | Match smartwatch BLE → phone batch |
| **IoT sim → mobile BE** (alert/fall) | REST immediate | <1s | Critical event không batch |
| **Mobile BE → mobile app** (vitals chart) | REST polling 2-3s khi user mở Health screen, autoDispose khi exit | 2-3s | Apple Health pattern, battery-safe |
| **Mobile BE → mobile app** (alert/SOS) | **FCM push immediate** | <2s | Production-standard, OS-friendly |
| **Mobile BE → mobile app** (risk score) | REST poll 30s + on-demand button | 30-60s | Match production cooldown |
| **Mobile BE → admin web HealthGuard** | WebSocket | <500ms | Operator dashboard, browser persistent |
| **IoT sim BE → simulator-web FE** | WebSocket (đã có) | <500ms | Demo dashboard |
| **Mobile BE → model-api** | REST sync HTTP | ~200-500ms | Single inference call, no streaming |

### 3.3 IoT sim mode — single demo mode

- 1 mode duy nhất: **demo mode**
- Speed configurable (1x, 5x, 10x) qua FE
- Tick interval cố định 5s base, scaled by speed
- KHÔNG có production-like mode (30s tick) hoặc stress test mode (1Hz × 100 device) — YAGNI

### 3.4 Repo trong scope

| Repo | Trong scope? | Cho phép sửa gì |
|---|---|---|
| `Iot_Simulator_clean` | ✅ Yes | FE simulator-web + BE api_server + simulator_core (full refactor) |
| `health_system` (mobile + BE) | ✅ Yes | Mobile app screens/widgets + backend telemetry/risk routes + adapters/services |
| `healthguard-model-api` | ✅ Yes (limited) | Schema validation (Field constraints), error code structure, optional `is_synthetic_default` flag — KHÔNG retrain model |
| `HealthGuard` (admin web) | ⚠️ Partial | Chỉ thêm WebSocket consumer cho realtime nếu cần demo. KHÔNG redesign UI |
| `PM_REVIEW` | ✅ Yes | Tất cả docs cho redesign này |

---

## 4. Roadmap — 7 phase trong 1-2 tháng

```
P0 (current) → P1 → P2 → P3 → P4 → P5 → P6 → P7
Charter      Inv  Tgt  DataC  ADR  Gap  Test  Build
```

| Phase | Tên | Deliverable | Effort ước | Acceptance |
|---|---|---|---|---|
| **P0** | Charter (current) | `00_charter.md` v1.0 approved | 1 session | ThienPDM ký + chốt scope |
| **P1** | Current State Inventory | `01_current_state.md` (full grep): 13 scenarios + N endpoint thực tế + dead code | 1-2 session | Mọi endpoint có ✅/❌/orphan label, mọi client có path verified |
| **P2** | Target Topology | `02_target_topology.md` + sequence diagram (Mermaid) cho 6 luồng | 2-3 session | Brainstorm 2-3 approach (skill `brainstorming`), anh chọn 1 |
| **P3** | Data Contracts | `03_data_contracts/{vitals_ingest,fall_imu,sleep_session,alert_push,risk_trigger}.md` (5 file) | 3-4 session | Mỗi spec có schema + range + error code + example payload |
| **P4** | ADRs | `04_adr_proposals/{ADR-018,019,020,021,...}.md` (4-6 ADR) | 1-2 session/ADR | Mỗi ADR ≥ 2 options, có consequence analysis |
| **P5** | Gap Analysis + Roadmap | `05_gap_analysis.md` + `06_migration_roadmap.md` (vertical slices DAG) | 1 session | Slice DAG có dependency rõ, mỗi slice ≤ 2 ngày effort |
| **P6** | Test Plan | `07_test_plan.md` (test pyramid per slice) | 1 session | Contract test định nghĩa rõ trước implementation |
| **P7** | Build (vertical slices) | Code theo skill `tdd` + `/build` workflow, 1 PR / slice | Bulk effort | Mỗi slice: red → green → refactor → commit; CI green |

**Quy tắc chuyển phase:**
- Phase N+1 chỉ bắt đầu khi Phase N có file artifact + ThienPDM approve
- Không skip phase
- Charter có thể cập nhật cả lúc đang chạy phase sau (versioned: v1.0 → v1.1 → ...)

---

## 5. Acceptance criteria (cho toàn bộ redesign khi xong)

### 5.1 Code criteria
- [ ] IoT sim KHÔNG còn direct call `:8001/api/v1/{fall,sleep}/predict`
- [ ] Mobile BE expose `is_synthetic_default` flag trong response risk + alert
- [ ] Model-api `VitalsRecord` có `Field(ge=, le=)` cho mọi vital field
- [ ] Steering `11-cross-repo-topology.md` reflect đúng endpoint reality (5 repo synced)
- [ ] Endpoint prefix consistent: `/api/v1/mobile/*` (production target per ADR-004) hoặc `/mobile/*` (current local) — chốt 1, sync mọi repo

### 5.2 UX criteria
- [ ] Mobile elderly view: Health Monitoring screen polling 2-3s, animation smooth
- [ ] Mobile family view: Risk Report Detail show top features + Vietnamese explanation
- [ ] Mobile alert critical: FCM push <2s từ IoT sim emit → SOSConfirmScreen takeover
- [ ] Simulator-web: sequence diagram live (Mermaid render hoặc custom flow viz) + status chips từng bước
- [ ] Demo end-to-end: panel chấm hiểu được flow trong 5 phút thuyết minh

### 5.3 Bug closure
- [ ] HS-024 → ✅ Resolved (regression test included)
- [ ] XR-001 → ✅ Resolved (5 steering files synced)
- [ ] XR-003 → ✅ Resolved (model-api validation + flag)

### 5.4 Documentation criteria
- [ ] 8 artifact files (Charter + 7 phase docs) committed
- [ ] 4-6 ADR new committed
- [ ] BUG INDEX.md updated
- [ ] Mỗi PR có link tới slice trong `06_migration_roadmap.md`

---

## 6. Risks + Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Scope creep** — anh thêm feature mới vào giữa phase | Medium | High | Charter version control; feature mới → ticket mới (not in this redesign) |
| **FCM không reliable trên emulator** — demo bị hỏng | Medium | High | Real device runbook đã có (`docs/testing/notifications-real-device-runbook.md`); test trên Android device thật trước demo |
| **Model-api breaking change làm crash mobile BE production** | Low | Critical | Backward compat: `is_synthetic_default` Optional, default `False`. Old client không bị break |
| **Refactor IoT sim làm vỡ existing test suite** | High | Medium | TDD discipline (skill `tdd`): viết test trước, fix dần |
| **Endpoint prefix migration `/mobile/*` → `/api/v1/mobile/*`** | High | High | Phase 7 cuối cùng; mobile + IoT sim + admin migrate đồng thời 1 PR cross-repo |
| **Multi-repo coordination phức tạp** | High | Medium | `/cross-repo-feature` workflow; producer-first DAG; mỗi PR cross-repo có 1 driver repo |
| **Demo mode polling 1Hz làm BE quá tải** | Low | Low | Configurable, default 2-3s; demo mode chỉ bật manual |

---

## 7. Open questions — RESOLVED (2026-05-15)

### OQ1 — Endpoint prefix final

**Resolution:** Execute ADR-004 — standardize `/api/v1/mobile/*` cho 5 backend service.

**Implications:**
- Mobile app baseUrl `http://10.0.2.2:8000/api/v1/mobile` (giữ nguyên, đã đúng)
- FastAPI mount: drop `root_path="/api/v1"`, change `api_router = APIRouter(prefix="/api/v1/mobile")`
- IoT sim đổi 4 file:
  - `Iot_Simulator_clean/api_server/dependencies.py` 3 method `_telemetry_*_endpoint` + `_risk_calculate_endpoint`
  - `Iot_Simulator_clean/api_server/backend_admin_client.py:45`
  - `Iot_Simulator_clean/api_server/services/sleep_service.py:581,638`
- Steering `11-cross-repo-topology.md` 5 repo sync về `/api/v1/mobile/*`
- Drop FastAPI `root_path` hack
- Resolve XR-001 + D-019

**Action ownership:** Phase 4 ADR-021 (execution-of-accepted-ADR, không tạo decision mới).

### OQ2 — IMU raw window persistence

**Resolution:** Option D — Lưu raw window vào TimescaleDB hypertable + retention policy 7 ngày + compression policy 10:1.

**Implications:**
- Tạo table `imu_windows` (timestamptz time, device_id, fall_event_id FK, accel/gyro/orientation arrays)
- TimescaleDB hypertable: `create_hypertable('imu_windows', 'time', chunk_time_interval=>'1 day')`
- Retention: `add_retention_policy('imu_windows', interval '7 days')`
- Compression: `add_compression_policy('imu_windows', interval '1 day')`
- BE persist trong `/telemetry/imu-window` endpoint (slice 2b wire vào)
- Bounded growth: ~1.3GB/năm worst case (100 user × 100 event/day × 7 day × 10x compression)

**Demo lợi thế:** Admin web có thể show motion chart cho operator review false-positive.

**Action ownership:** Phase 3 contract `fall_imu_window.md` định nghĩa schema + Phase 4 ADR-019 (no direct model-api call).

### OQ3 — Fall takeover UI

**Resolution:** Option C Hybrid — critical = full-screen wake screen + ring; non-critical = notification thường.

**Implications:**
- Mobile (Android): `USE_FULL_SCREEN_INTENT` permission, `AndroidNotificationDetails(fullScreenIntent: true)` cho FCM message với `severity=critical`
- AndroidManifest: `<activity android:showWhenLocked="true" android:turnScreenOn="true" />` cho SOSConfirmActivity
- Onboarding step: request `USE_FULL_SCREEN_INTENT` permission từ Android 14+
- iOS: dùng `UNNotificationSound.defaultCritical` + banner critical (Apple Critical Alert entitlement skip cho đồ án)
- Severity discrimination:
  - `severity=critical` (`fall_high_confidence`, `fall_no_response`): full-screen takeover
  - `severity=high` (`fall_false_alarm` confidence 0.65): notification thường, no takeover

**Risk flagged:**
- Real Android device required cho demo (emulator hành vi khác)
- Anh phải có 2 phone Android cho demo OQ4

**Action ownership:** Phase 2 target topology + Phase 3 contract `alert_push.md` định nghĩa FCM payload structure.

### OQ4 — Linked profile demo (elderly + family)

**Resolution:** Option A — 2 mobile device chạy song song, mỗi device login 1 user khác.

**Implications:**
- Setup demo:
  - Device 1 (Android phone hoặc emulator): login `elderly@test.com`, bind smartwatch sim qua admin
  - Device 2 (Android phone hoặc emulator thứ 2): login `family@test.com`, linked với elderly qua `UserRelationship`
- BE infra ĐÃ CÓ (em verify code):
  - `PushNotificationService.send_fall_critical_alert` — fan out FCM tới user + caregivers
  - `PushNotificationService.send_fall_followup_concern` — caregiver-only soft push
  - `EmergencyRepository.get_alert_recipient_user_ids(db, patient_user_id)` — fetch linked caregivers
- Phase 1 inventory verify: FCM token register cả 2 user, fanout logic chạy đúng
- Phase 3 contract `alert_push.md` định nghĩa structure FCM payload phân biệt elderly vs family receiver

**Demo flow target:**
1. Anh trigger `fall_high_confidence` trên simulator-web
2. Phone 1 (elderly): full-screen SOS takeover + ring + countdown 30s
3. Phone 2 (family): notification banner "Bố/mẹ bạn vừa té ngã — tap để xem" + tap mở RiskReportDetailScreen
4. Cả 2 phone update đồng bộ

**Action ownership:** Phase 1 (verify FCM fanout) + Phase 3 (alert_push contract) + Phase 7 (build).

### OQ5 — Risk inference trigger source of truth

**Resolution:** Option B — BE auto-trigger sau `/telemetry/ingest`. IoT sim KHÔNG trigger risk inference nữa.

**Implications:**
- Bỏ method `_trigger_risk_inference` + `_risk_calculate_endpoint` từ IoT sim `dependencies.py`
- Bỏ orchestrator wire R3 fix `_trigger_risk_inference` call
- Endpoint `/api/v1/mobile/risk/calculate` (internal `X-Internal-Service`) **dispose** (em verify Phase 1, có consumer nào khác không)
- Endpoint `/api/v1/mobile/risk/recalculate` (user-facing) **GIỮ** cho mobile app on-demand "Tính lại" button
- BE flow: `/telemetry/ingest` → `calculate_device_risk(allow_cached=True, dispatch_alerts=True)` → cooldown `RISK_COOLDOWN_SECONDS=60` ngăn spam model-api

**Trade-off accepted:**
- IoT sim không control timing risk inference (nhường cho BE) — match production: smartwatch chỉ push raw
- BE auto-trigger 100 device × ingest 12/phút = 1200 calls/phút → cooldown drop 99% → 100 model-api call/phút → OK

**Action ownership:** Phase 4 ADR-019 (no direct model-api + no IoT trigger) + Phase 7 cleanup code IoT sim.

---

## 8. Linked artifacts (sẽ tạo dần)

```
PM_REVIEW/REDESIGN_IOT_SIM_2026/
├── 00_charter.md                         ← BẠN ĐANG ĐỌC (v1.0 approved)
├── 01_current_state.md                   ← Phase 1 (pending)
├── 02_target_topology.md                 ← Phase 2 (pending)
├── 03_data_contracts/
│   ├── vitals_ingest.md                  ← Phase 3
│   ├── fall_imu_window.md
│   ├── sleep_session.md
│   ├── alert_push.md
│   └── risk_trigger.md
├── 04_adr_proposals/
│   ├── ADR-018-health-validation-contract.md
│   ├── ADR-019-iot-sim-no-direct-modelapi.md
│   ├── ADR-020-vitals-single-path.md
│   └── ADR-021-endpoint-prefix-canonical.md
├── 05_gap_analysis.md                    ← Phase 5
├── 06_migration_roadmap.md
├── 07_test_plan.md                       ← Phase 6
└── 08_decision_log.md                    ← cập nhật xuyên suốt
```

---

## 9. Approval block

| Role | Name | Status | Date | Note |
|---|---|---|---|---|
| **Driver** | ThienPDM | ✅ Approved | 2026-05-15 | Đã chốt 5 Open Questions + scope mở rộng (IoT sim FE/BE + Mobile FE/BE + model-api validation) |
| **Executor** | Cascade | ✅ Drafted v1.0 | 2026-05-15 | Sẵn sàng sang Phase 1: Current State Inventory |

**Khi anh approve:**
- Đổi status driver thành ✅
- Bump version Charter `v0.1 → v1.0` 
- Em commit Charter + bắt đầu Phase 1 (`01_current_state.md`)

**Khi anh muốn đổi scope:**
- Em update Charter version (v1.0 → v1.1 với changelog dưới đây)
- Re-approve required nếu thay đổi major (persona, streaming pattern, scope repo)

---

## 10. Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-15 | Cascade | Initial draft sau brainstorm 5 câu với ThienPDM |
| v1.0 | 2026-05-15 | Cascade | Resolve 5 Open Questions (OQ1-OQ5) + ThienPDM approve. Sang Phase 1. |
