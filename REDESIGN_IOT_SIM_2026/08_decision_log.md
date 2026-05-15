# Phase 8 — Decision Log

> **Goal:** Consolidated index của tất cả decisions, open questions, brainstorm chốt trong redesign. Cập nhật xuyên suốt từ Phase 0 đến Phase 7.

**Date:** 2026-05-15
**Author:** Cascade
**Reviewer:** ThienPDM (approved 2026-05-15)
**Status:** ✅ v1.0 — All documentation phases complete

---

## 1. Charter Open Questions — RESOLVED

| OQ | Question | Decision | ADR ref |
|---|---|---|---|
| **OQ1** | Endpoint prefix final | `/api/v1/mobile/*` everywhere (execute ADR-004) | ADR-021 |
| **OQ2** | IMU raw window persistence | TimescaleDB hypertable + 7-day TTL + compression | ADR-022 |
| **OQ3** | Fall takeover UI | Hybrid: full-screen wake cho critical, notification thường cho non-critical | ADR-023 |
| **OQ4** | Linked profile demo | 2 mobile device song song (elderly + family) | ADR-023 |
| **OQ5** | Risk inference trigger | BE auto-trigger sau ingest, IoT sim không trigger | ADR-019, ADR-020 |

---

## 2. Phase 2 Brainstorm — RESOLVED

| Brainstorm | Question | Decision | ADR ref |
|---|---|---|---|
| **B1** | Vitals path: DB direct hay HTTP | HTTP migration (reverse ADR-013) | ADR-020 |
| **B2** | Fall + Sleep flow pattern | Pattern Unified IoT → BE → model-api (no direct call) | ADR-019 |
| **B3** | Simulator-web UX scope | Mid scope: chips + sequence diagram live + multi-device + demo mode | ADR-024 |

---

## 3. Persona + Scope đã chốt

| Aspect | Decision |
|---|---|
| **IoT sim persona** | Anh + giáo viên hướng dẫn + panel chấm đồ án (demo-friendly UX) |
| **Mobile end-user persona** | Cả 2: elderly user + family caregiver (linked profile) |
| **Streaming target** | FCM critical + REST polling mobile + WebSocket admin/sim |
| **IoT sim mode** | 1 mode duy nhất (demo mode, no production-like/stress test) |
| **Deadline** | 1-2 tháng |
| **Repo trong scope** | IoT_Simulator_clean, health_system, healthguard-model-api, PM_REVIEW (full); HealthGuard (limited WebSocket consumer) |

---

## 4. ADRs đã propose (Phase 4)

| ADR | Title | Status | Resolves |
|---|---|---|---|
| ADR-018 | Health Input Validation Contract | 🟢 Approved | HS-024 + XR-003 |
| ADR-019 | IoT Sim No Direct Model-API | 🟢 Approved | B2, OQ2, OQ5 |
| ADR-020 | Vitals Path Migration (Supersedes ADR-013) | 🟢 Approved | B1, OQ5 |
| ADR-021 | Endpoint Prefix Execution (Executes ADR-004) | 🟢 Approved | OQ1, XR-001 |
| ADR-022 | IMU Window Persistence | 🟢 Approved | OQ2 |
| ADR-023 | Mobile Streaming Pattern | 🟢 Approved | OQ3, OQ4 |
| ADR-024 | Simulator-web Flow WebSocket | 🟢 Approved | B3 |

**Status change post Phase 7:**
- ADR-013 → ⚫ Superseded by ADR-020
- ADR-004 → ✅ Executed by ADR-021 (decision intact, action complete)

---

## 5. Bug closures (post Phase 7 expectations)

| Bug ID | Title | Resolved by | Status |
|---|---|---|---|
| HS-024 | Risk inference silent default fill | ADR-018 + Phase 7 S3/S4 | ⏳ Open → ✅ Resolved post P7 |
| XR-001 | Topology steering endpoint prefix drift | ADR-021 + Phase 7 S1 | ⏳ Open → ✅ Resolved post P7 |
| XR-003 | Model API input validation contract | ADR-018 + Phase 7 S2 | ⏳ Open → ✅ Resolved post P7 |

---

## 6. Roadmap commit summary

| Phase | Effort | Slices |
|---|---|---|
| P0 Charter | 1 session | n/a (planning) |
| P1 Inventory | 2 sessions | n/a (verify) |
| P2 Target topology | 2 sessions | n/a |
| P3 Data contracts | 3 sessions | n/a |
| P4 ADRs | 2 sessions | n/a |
| P5 Gap + Roadmap | 1 session | 20 slices defined |
| P6 Test plan | 1 session | n/a |
| **P7 Build (next)** | ~74h estimated | **20 vertical slices over 8 weeks** |

---

## 7. Documentation artifacts

| Phase | File | Status |
|---|---|---|
| P0 | `00_charter.md` | ✅ v1.0 approved |
| P1 | `01_current_state.md` | ✅ v1.0 complete |
| P2 | `02_target_topology.md` | ✅ v1.0 approved |
| P3 | `03_data_contracts/README.md` + 5 contract files | ✅ v1.0 approved |
| P4 | `04_adr_proposals/README.md` + 7 ADR files | ✅ v1.0 approved |
| P5 | `05_gap_analysis.md` + `06_migration_roadmap.md` | ✅ v1.0 approved |
| P6 | `07_test_plan.md` | ✅ v1.0 approved |
| P8 | `08_decision_log.md` (this file) | ✅ v1.0 |

---

## 8. Key non-goals confirmed

Em **KHÔNG** làm trong redesign này:
- ❌ Stress test mode (100+ device song song)
- ❌ Production deployment infra (k8s/helm)
- ❌ Wearable hardware BLE
- ❌ Admin web HealthGuard UX redesign
- ❌ Mobile receiver mirror trên simulator-web
- ❌ Model retraining
- ❌ Database schema major changes (chỉ additive: imu_windows + risk_scores columns)

---

## 9. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Cross-repo coordination Phase 7 | Medium | High | Slice-per-PR, smoke test E2E |
| FCM unreliable emulator | Medium | High | Real device runbook, 2 Android phones final demo |
| Model-api breaking change | Low | Critical | Backward compat Optional fields |
| Refactor IoT sim test suite | High | Medium | TDD discipline, fix incremental |
| Endpoint prefix migration cutover | High | High | Phase 7 S1 với dual-mount transitional 1 deploy |
| Demo mode 1Hz overload BE | Low | Low | Configurable, manual toggle |

---

## 10. Reverse decision triggers (consolidated)

| Decision | Reverse trigger | Plan B |
|---|---|---|
| ADR-020 HTTP migration | BE latency p95 >500ms consistently | Reactivate DB direct với feature flag |
| ADR-019 no direct model-api | BE health unstable | Direct AI client fallback with circuit breaker |
| ADR-021 prefix migration | Production proxy strip `/api/v1` | Restore dual-mount |
| ADR-018 fail-closed | UX critique fail-closed | Downgrade to Option B degrade-with-flag |
| ADR-022 IMU 7-day TTL | Storage volume exceed projection | Tighten TTL to 3 days, downsample |
| ADR-023 hybrid takeover | Android 14+ permission UX fail | Fallback notification-only cho old Android |
| OQ4 2-device demo | FCM fanout fail >2 phones | Single-device demo with mock family panel |
| B3 Mid scope simulator-web | Effort >5 days actual | Cut multi-device coord, keep sequence diagram only |

---

## 11. Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v1.0 | 2026-05-15 | Cascade | Initial decision log post documentation phase complete |

---

## 12. Approval chain

| Phase | Role | Approver | Date |
|---|---|---|---|
| P0 Charter v1.0 | Driver | ThienPDM | 2026-05-15 |
| P1 Inventory v1.0 | Driver | ThienPDM | 2026-05-15 |
| P2 Target topology v1.0 | Driver | ThienPDM | 2026-05-15 |
| P3 Data contracts v1.0 | Driver | ThienPDM | 2026-05-15 |
| P4 ADRs v1.0 (7 ADRs) | Driver | ThienPDM | 2026-05-15 |
| P5 Gap + Roadmap v1.0 | Driver | ThienPDM | 2026-05-15 |
| P6 Test plan v1.0 | Driver | ThienPDM | 2026-05-15 |
| **Documentation Phase TOTAL** | **Driver** | **ThienPDM** | **2026-05-15 ✅ APPROVED** |
