# Phase 4 — ADR Proposals

> **Goal:** Document architecture decisions chính thức của redesign 2026. Mỗi ADR follow IEEE-1016 lite pattern với Context + Options + Decision + Consequences + Reverse triggers.

**Phase:** P4 — ADRs
**Date:** 2026-05-15
**Author:** Cascade
**Reviewer:** ThienPDM (pending)
**Status:** 🟡 v0.1 (7 ADRs drafted)
**Charter:** `../00_charter.md` v1.0

---

## ADRs trong redesign này

| ADR | Title | Status | Resolves |
|---|---|---|---|
| [ADR-018](./ADR-018-health-input-validation-contract.md) | Health Input Validation Contract — Fail-Closed with Synthetic Flag | 🟡 Proposed | HS-024, XR-003 |
| [ADR-019](./ADR-019-iot-sim-no-direct-modelapi.md) | IoT Simulator No Direct Model-API Call | 🟡 Proposed | B2, OQ2, OQ5 |
| [ADR-020](./ADR-020-vitals-path-migration.md) | Vitals Path Migration — DB Direct → HTTP (SUPERSEDES ADR-013) | 🟡 Proposed | B1, OQ5 |
| [ADR-021](./ADR-021-endpoint-prefix-execution.md) | Endpoint Prefix Execution (EXECUTES ADR-004) | 🟡 Proposed | OQ1, XR-001 |
| [ADR-022](./ADR-022-imu-window-persistence.md) | IMU Window Persistence — TimescaleDB Hypertable | 🟡 Proposed | OQ2 |
| [ADR-023](./ADR-023-mobile-streaming-pattern.md) | Mobile Streaming Pattern — FCM Push + REST Polling | 🟡 Proposed | OQ3, OQ4, Charter section 3.2 |
| [ADR-024](./ADR-024-simulator-web-flow-websocket.md) | Simulator-web Flow Event WebSocket — Live Sequence Diagram | 🟡 Proposed | B3 |

---

## ADR dependency graph

```
                ADR-021 (prefix execution)
                    │
        ┌───────────┴───────────┐
        │                       │
    ADR-018                ADR-019
   (validation)        (no direct MA)
        │                       │
        │                       ├──── ADR-022 (IMU persistence)
        │                       │
        └──── ADR-020 ──────────┤
              (vitals HTTP)     │
                                │
                          ADR-023 (mobile streaming)
                                │
                          ADR-024 (sim WS flow)
```

**Execution order Phase 7:**
1. ADR-021 (prefix execution) — foundation, all other ADRs depend on consistent prefix
2. ADR-018 (validation contract) + ADR-020 (vitals HTTP) — parallel
3. ADR-019 (no direct MA) + ADR-022 (IMU persistence) — parallel
4. ADR-023 (mobile streaming) — consumer side
5. ADR-024 (sim WS flow) — demo polish

---

## Status legend

- 🟡 **Proposed** — Drafted, chờ ThienPDM review
- 🟢 **Accepted** — Approved by ThienPDM
- 🔴 **Rejected** — Sau review không proceed
- ⚫ **Superseded** — Replaced bởi ADR sau

---

## How to update ADR

1. Increment status: 🟡 → 🟢 sau ThienPDM approve
2. Add row to changelog
3. If superseded later: ⚫ + link to superseding ADR
4. Update `PM_REVIEW/ADR/INDEX.md` global ADR registry sau Phase 7 merge

---

## Cross-references

- Charter: `../00_charter.md`
- Inventory: `../01_current_state.md`
- Target topology: `../02_target_topology.md`
- Data contracts: `../03_data_contracts/`

---

## Phase 4 acceptance criteria

- [x] 7 ADRs draft đầy đủ
- [x] Mỗi ADR ≥ 2 options considered + rationale rejection
- [x] Consequences (positive + negative + follow-up) per ADR
- [x] Reverse decision triggers per ADR
- [x] Related links (bugs, contracts, code citations)
- [x] Dependency graph documented
- [x] Execution order Phase 7

---

## Changelog

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-15 | Cascade | Initial 7 ADRs drafted |
