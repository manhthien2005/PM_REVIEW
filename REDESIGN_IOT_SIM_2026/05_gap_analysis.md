# Phase 5 — Gap Analysis

> **Goal:** Compare current state (Phase 1 inventory) với target state (Phase 2 topology + Phase 3 contracts + Phase 4 ADRs). Identify mọi gap với severity + effort estimate. Đây là input cho `06_migration_roadmap.md`.

**Phase:** P5 — Gap Analysis
**Date:** 2026-05-15
**Author:** Cascade
**Reviewer:** ThienPDM (pending)
**Status:** 🟡 v0.1
**Inputs:** Charter v1.0, Inventory v1.0, Target Topology v0.1, 5 Data Contracts v0.1, 7 ADRs v0.1

---

## 1. Methodology

Mỗi gap được scored theo:

- **Severity:** Critical (block redesign success) / High (significant impact) / Medium (improvement) / Low (nice-to-have)
- **Effort:** S (<2h), M (2-8h), L (8-24h), XL (>24h)
- **Risk:** High (breaks production) / Medium (cross-repo coordination) / Low (isolated)
- **Repo:** IoT sim, Mobile BE, Mobile FE, Model-API, PM_REVIEW, Cross-repo

---

## 2. Gap matrix per repo

### 2.1 IoT Simulator (`Iot_Simulator_clean/`)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| IS-G01 | Endpoint prefix | `/api/sim/*` | `/api/v1/sim/*` | High | S (1h) | Low | ADR-021 |
| IS-G02 | Outbound telemetry prefix | `/mobile/*` (no v1) | `/api/v1/mobile/*` | High | S (0.5h) | Low | ADR-021 |
| IS-G03 | Vitals path | DB direct INSERT | HTTP POST `/telemetry/ingest` | Critical | M (3-4h) | Medium | ADR-020 |
| IS-G04 | Fall AI client | `FallAIClient` direct `:8001` | Wire `MobileTelemetryClient` orphan | Critical | M (2-3h) | Medium | ADR-019 |
| IS-G05 | Sleep AI client | `SleepAIClient` direct `:8001` | Wire `SleepRiskDispatcher` orphan | Critical | M (2-3h) | Medium | ADR-019 |
| IS-G06 | Risk trigger code | `_trigger_risk_inference` method exists | DISPOSE (BE auto-trigger via OQ5) | High | S (0.5h) | Low | OQ5 |
| IS-G07 | Risk endpoint helper | `_risk_calculate_endpoint` exists | DISPOSE | Medium | S (0.5h) | Low | OQ5 |
| IS-G08 | HttpPublisher | Wired không invoke (dead code) | INVOKE through transport_router | High | M (1-2h) | Low | ADR-020 |
| IS-G09 | Direct AI client unit tests | Test `FallAIClient.predict()` direct | Update mock layer Mobile BE | Medium | M (1-2h) | Low | ADR-019 |
| IS-G10 | Simulator-web FE Session Runner page | Basic chips + tick output | Mid scope: sequence diagram + multi-device + demo mode | High | L (8-10h) | Low | ADR-024 |
| IS-G11 | Simulator-web FE multi-device panel | Single device card | Linked profile coordinator (elderly + family) | High | M (3-4h) | Low | B3, OQ4 |
| IS-G12 | Simulator-web FE WebSocket | Only `/ws/logs` | Add `/ws/flow` consumer | High | M (2-3h) | Low | ADR-024 |
| IS-G13 | BE WebSocket flow events | None | Add `/ws/flow/{session_id}` + publish hooks | High | M (3-4h) | Low | ADR-024 |
| IS-G14 | Demo mode toggle | None | Switch polling 3s ↔ 1s, tick 5s ↔ 1s | Medium | S (1-2h) | Low | B3 |
| IS-G15 | Steering doc 11-cross-repo-topology | Claim `/api/internal/*` (wrong) | Sync `/api/v1/mobile/*` | Low | S (0.5h) | Low | ADR-021 |

**IoT sim total effort:** ~30-40h

### 2.2 Mobile BE (`health_system/backend/`)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| MB-G01 | FastAPI mount | `root_path="/api/v1"` + router prefix `/mobile` | Drop root_path, router prefix `/api/v1/mobile` | High | S (0.5h) | Medium | ADR-021 |
| MB-G02 | Risk inference `_build_inference_payload` | Silent default fill 4 critical fields | Reject NULL critical fields → `InsufficientVitalsError` | Critical | M (3-4h) | High | ADR-018 |
| MB-G03 | Risk service `_fetch_latest_vitals` | Reject chỉ khi cả HR+SpO2 NULL | Reject nếu BẤT KỲ critical field NULL | Critical | M (2h) | High | ADR-018 |
| MB-G04 | Model API adapter `to_record` | Layer 2 fill default lần nữa, drift HRV 50 vs 40 | Synchronize default values với Layer 1 | Critical | M (1-2h) | Medium | ADR-018 |
| MB-G05 | Risk response schema | Không có `is_synthetic_default`, `defaults_applied`, `effective_confidence` | Add 4 new fields | High | M (2-3h) | Medium | ADR-018 |
| MB-G06 | DB schema `risk_scores` | Thiếu 4 column synthetic tracking | Migration: add 4 columns | High | S (1h) | Medium | ADR-018 |
| MB-G07 | Telemetry ingest endpoint | Pydantic `extra="allow"`, no Field constraints | `extra="forbid"` + `Field(ge=, le=)` | Critical | M (2-3h) | High | ADR-018 |
| MB-G08 | Telemetry ingest error format | Plain string errors list | Structured `IngestError` schema | Medium | S (1-2h) | Low | Contracts |
| MB-G09 | IMU window endpoint persistence | Chỉ INSERT fall_events | INSERT imu_windows hypertable + fall_events with FK | High | M (2-3h) | Medium | ADR-022 |
| MB-G10 | DB schema `imu_windows` | Không tồn tại | TimescaleDB hypertable + retention + compress | High | S (1h) | Low | ADR-022 |
| MB-G11 | FCM payload structure | Mixed notification + data | Data-only with full vocabulary | High | M (3-4h) | Medium | ADR-023, Contract |
| MB-G12 | FCM fanout patient vs caregiver discrimination | `send_fall_critical_alert` không phân biệt fullScreenIntent | Per-recipient payload với `is_recipient_patient` flag | High | M (2-3h) | Medium | ADR-023, OQ4 |
| MB-G13 | Idempotency dedup | Không có | Header `Idempotency-Key` + 5-min window | Low | M (2-3h) | Low | Contracts |
| MB-G14 | Endpoint `/telemetry/sleep` deprecated | Active | Mark deprecated, mobile clients KHÔNG gọi (use sleep-risk) | Low | S (0.5h) | Low | ADR-019 |

**Mobile BE total effort:** ~25-35h

### 2.3 Model-API (`healthguard-model-api/`)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| MA-G01 | `VitalsRecord` Field constraints | Không có `ge`/`le` | `Field(ge=20, le=250)` cho HR, etc | Critical | S (1h) | Low | ADR-018 |
| MA-G02 | `VitalsRecord` synthetic flag | Không có | Optional `is_synthetic_default`, `defaults_applied` | High | S (1h) | Low | ADR-018 |
| MA-G03 | Response `effective_confidence` | Không có | Compute `confidence × 0.5 if synthetic` | High | S (1-2h) | Low | ADR-018 |
| MA-G04 | Response `data_quality_warning` | Không có | Optional string warning | Medium | S (0.5h) | Low | ADR-018 |
| MA-G05 | Error response | Generic 422 message | Structured `{error: {code, message, details}}` | High | M (2-3h) | Low | Contracts |
| MA-G06 | Test cases new fields | Chưa cover | Add test for synthetic flag + range validation | Medium | M (2-3h) | Low | Contracts §8 |

**Model-API total effort:** ~10-15h

### 2.4 Mobile FE (`health_system/lib/`)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| MF-G01 | API client baseUrl | `http://10.0.2.2:8000/api/v1/mobile` | NO CHANGE (already correct) | - | - | - | ADR-021 |
| MF-G02 | Risk Report parser | Không parse `is_synthetic_default`, `defaults_applied` | Parse 4 new fields | High | M (2-3h) | Medium | ADR-018 |
| MF-G03 | Risk Report Detail UI | Không show warning banner | Render orange warning banner khi `is_synthetic_default` | High | M (2-3h) | Low | ADR-018 |
| MF-G04 | Vitals chart polling | Existing | Verify .autoDispose pattern + 2-3s interval | Medium | S (1h) | Low | ADR-023 |
| MF-G05 | FCM handler critical fall | Existing handler | Update full-screen takeover logic per ADR-023 | High | M (3-4h) | Medium | ADR-023, OQ3 |
| MF-G06 | AndroidManifest | Missing `USE_FULL_SCREEN_INTENT`, `showWhenLocked` | Add permissions + Activity attrs | High | S (1h) | Low | ADR-023, OQ3 |
| MF-G07 | iOS APNS critical alert | Default config | Update for `interruption-level: critical` | Medium | S (1h) | Low | ADR-023 |
| MF-G08 | Demo mode polling override | Không có | Env flag `DEMO_MODE=true` → 1s polling | Medium | S (1h) | Low | ADR-023, B3 |
| MF-G09 | Linked profile demo wiring | Existing family features | Verify FCM token register cho 2 user + test fanout | High | M (2-3h) | Medium | OQ4 |
| MF-G10 | SOSConfirmScreen takeover trigger | Existing | Verify FCM data-only payload routing logic | High | M (2h) | Low | ADR-023, OQ3 |
| MF-G11 | Notification channel registration (Android) | Existing | Add `fall_critical_channel` with bypass DND | High | S (1-2h) | Low | ADR-023 |

**Mobile FE total effort:** ~15-22h

### 2.5 PM_REVIEW (docs)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| PM-G01 | ADR INDEX.md | Không có ADR-018 đến ADR-024 | Register 7 new ADRs | Low | S (0.5h) | Low | ADR-021 |
| PM-G02 | BUGS INDEX.md | HS-024, XR-001, XR-003 status Open | Mark Resolved sau Phase 7 | Low | S (0.5h) | Low | - |
| PM-G03 | Steering 11-cross-repo-topology.md | 5 repo copies, claim `/api/internal/*` | Sync `/api/v1/mobile/*` | Low | S (0.5h) | Low | ADR-021 |
| PM-G04 | UC016 BR-016-02 | `≥24h vitals required` not enforced in code | Cross-link to ADR-018 in UC | Low | S (0.5h) | Low | ADR-018 |
| PM-G05 | Topology v2 D-019 | Open drift | Mark Resolved | Low | S (0.5h) | Low | ADR-021 |
| PM-G06 | ADR-013 status | Accepted | Update to Superseded (link ADR-020) | Low | S (0.5h) | Low | ADR-020 |
| PM-G07 | API contract v1 catalog | Has old prefix info | Update with new prefix | Low | S (1h) | Low | ADR-021 |

**PM_REVIEW total effort:** ~4-5h

### 2.6 HealthGuard admin web (limited scope)

| # | Gap | Current | Target | Severity | Effort | Risk | ADR ref |
|---|---|---|---|---|---|---|---|
| HG-G01 | WebSocket realtime consumer | Có infra | Verify integration với new flow | Low | S (1h) | Low | ADR-023 |
| HG-G02 | Alerts display | Existing | Display `is_synthetic_default` flag (optional polish) | Low | M (2h) | Low | ADR-018 |
| HG-G03 | Risk score display | Existing | Display `effective_confidence` (optional polish) | Low | M (2h) | Low | ADR-018 |

**HealthGuard total effort:** ~5h (optional)

---

## 3. Aggregated effort summary

| Repo | Critical | High | Medium | Low | Total |
|---|---|---|---|---|---|
| IoT Simulator | 3 (M) | 7 (S+M+L) | 4 (S+M) | 1 (S) | 30-40h |
| Mobile BE | 4 (M) | 7 (S+M) | 2 (S+M) | 1 (S) | 25-35h |
| Model-API | 1 (S) | 3 (S) | 2 (M+S) | 0 | 10-15h |
| Mobile FE | 0 | 7 (S+M) | 4 (S) | 0 | 15-22h |
| PM_REVIEW | 0 | 0 | 0 | 7 (S) | 4-5h |
| HealthGuard (optional) | 0 | 0 | 0 | 3 (S+M) | 5h |
| **Grand Total** | **8** | **24** | **12** | **12** | **~89-122h** |

**Translated to working days:** ~12-17 day-equivalent (assuming 7h/day solo dev pace)
**Match Charter timeline:** 1-2 tháng (4-8 weeks) ✅ realistic

---

## 4. Critical gap priority

8 gaps marked Critical phải fix dứt điểm trong Phase 7:

1. **IS-G03** Vitals DB direct → HTTP migration (ADR-020)
2. **IS-G04** FallAIClient direct dispose (ADR-019)
3. **IS-G05** SleepAIClient direct dispose (ADR-019)
4. **MB-G02** Risk inference silent default fill (ADR-018, HS-024)
5. **MB-G03** Fetch vitals per-field NULL check (ADR-018, HS-024)
6. **MB-G04** Adapter default drift HRV 40 vs 50 (ADR-018)
7. **MB-G07** Telemetry ingest schema strict + range (ADR-018, contracts)
8. **MA-G01** Model-API Field constraints (ADR-018, XR-003)

**8 Critical → Phase 7 P0 (must)** = ~22-30h core work

---

## 5. Risk + mitigation matrix

| Risk category | Examples | Mitigation |
|---|---|---|
| **Cross-repo coordination** | ADR-021 prefix migration touches IoT sim + Mobile BE + steering | Phase 7 deploy đồng thời tất cả repo (single PR set), smoke test E2E sau cùng |
| **HTTP latency overhead** | IS-G03 add ~50-200ms per tick | Acceptable (4% overhead at 5s tick); demo mode 1s still OK |
| **Breaking IoT sim test suite** | IS-G09 + IS-G03 changes | Test refactor Phase 7 slice, mock Mobile BE instead of model-api |
| **FCM emulator unreliability** | OQ4 + ADR-023 demo | Real device runbook required, 2 Android phones cho final demo |
| **DB migration in production** | MB-G06, MB-G10 schema changes | Migrations are additive (ADD COLUMN), no rollback risk |
| **Mobile UX breaking** | MF-G02 + MF-G03 require new fields | Backward compat: Optional fields default to false/null, UI conditional |
| **Risk reverse decisions** | ADR-020 supersedes ADR-013 | Reverse triggers documented per ADR; rollback plan = revert PR |

---

## 6. Out-of-scope items (acknowledged, deferred)

| Item | Why deferred | Future plan |
|---|---|---|
| Production deployment infra (k8s/helm) | Charter section 2.3 non-goal | Post-đồ án |
| Stress test mode 100+ device | OQ chốt single demo mode (YAGNI) | If product evolve to production |
| Wearable hardware BLE | Out-of-scope đồ án (IoT sim đại diện) | Future product version |
| Admin web UX redesign | Charter section 3.4 limited scope | Separate redesign initiative |
| Model retraining | Out-of-scope (model treated as black box) | Separate ML pipeline initiative |
| Mobile receiver mirror trên simulator-web (Option C của B3) | YAGNI redundant với 2 phone thật | Post-đồ án nếu có thời gian |

---

## 7. Acceptance criteria Phase 5

- [x] Gap matrix per repo (5 repos + HealthGuard limited)
- [x] Severity + Effort + Risk per gap
- [x] ADR reference per gap
- [x] Aggregated effort summary với day-equivalent
- [x] Critical gap priority list (8 items)
- [x] Risk + mitigation matrix
- [x] Out-of-scope acknowledged

---

## 8. Output for Phase 6 + Phase 7

**To `06_migration_roadmap.md`:**
- Map 56 gaps thành vertical slices
- Define DAG dependency
- Estimate per-slice effort ≤ 2 days

**To `07_test_plan.md`:**
- Test pyramid per layer (unit + integration + E2E)
- Contract test per ADR

**To Phase 7 build:**
- 8 Critical gaps là P0 (must complete)
- 24 High gaps P1
- 12 Medium + 12 Low cherry-pick based on time

---

## 9. Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-15 | Cascade | Initial gap matrix 56 items across 6 repos, ~89-122h effort |
