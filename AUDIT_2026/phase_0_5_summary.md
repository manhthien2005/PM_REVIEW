# Phase 0.5 Summary — Business Spec Rebuild + Intent Capture

**Status:** Aggregate summary — wave 1-5 closure roll-up
**Phase:** Phase 0.5 (per `00_phase_0_5_charter.md`)
**Date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)

## Scope

Aggregate summary cho Phase 0.5 — close phase per charter Definition of Done. Roll-up 5 wave intent_drift output + UC delta + ADR proposals + Phase 4 backlog adjusted.

## Wave coverage

| Wave | Repo | Modules planned | Modules done | Status |
|---|---|---|---|---|
| Wave 1 | HealthGuard | 10 | 12 (extra: AI_MODELS, INTERNAL, VITAL_ALERT_ADMIN) | ✅ Complete |
| Wave 2 | healthguard-model-api | 3 | 1 (MODEL_API consolidated) | ✅ Complete |
| Wave 3 | Iot_Simulator_clean | 6 | 6 | ✅ Complete |
| Wave 4 | health_system BE | 8 | 5 (AUTH, DEVICE, INGESTION, NOTIFICATIONS, MONITORING) | ✅ Partial — 3 module deferred Phase 1+ |
| Wave 5 | health_system mobile | 10 | 5 (AI_XAI, PROFILE, RELATIONSHIPS, SETTINGS, SLEEP) | ✅ Partial — overlap với Wave 4 docs |

**Total intent_drift docs**: 29 file (HG 12 + MA 1 + IS 6 + HS 10).

**health_system intent_drift**: 10 file consolidated `tier1.5/intent_drift/health_system/` (AI_XAI, AUTH, DEVICE, INGESTION, MONITORING, NOTIFICATIONS, PROFILE, RELATIONSHIPS, SETTINGS, SLEEP).

## UC delta

### Drop / supersede
- **UC031 Manage Notifications**: 3/4 endpoints proposed DEAD từ FE perspective (acknowledge, severity filter BE-side, preferences). UC031 v2 reduce scope.
- **UC040 Connect Device pair-claim flow**: deprecated. UC040 v2 = pair-create only (per ADR-011).
- **UC041 Configure Device calibration offsets**: 3 field (heart_rate_offset, spo2_calibration, temperature_offset) drop. UC041 v2 (per ADR-012).
- **Server/device config split** (UC041 BR-041-01): drop. Settings table lookup pattern là implementation detail.

### Rewrite / refine
- **UC040 v2**: pair-create only flow + NULL user_id support cho admin provisioning + IoT sim auto-provision. ADR-010 governs schema.
- **UC041 v2**: drop calibration offsets, keep notify_high_hr/notify_low_spo2/notify_high_bp toggle.
- **UC042 v2**: BR-042-03 attention zone heuristic refine — grace period 1h cho new-paired device.
- **UC031 v2**: keep mark-all as read (D-NOT-C), drop acknowledge + severity filter BE + preferences.

### Keep unchanged
- UC001/009 Auth (HS) — Phase 0.5 confirm spec đúng với code.
- UC006/007 View Health Metrics — Phase 0.5 confirm.
- UC020 Risk inference — confirm với caveat ADR-015.

## ADR commits during Phase 0.5

| ADR ID | Title | Status | Driving drift |
|---|---|---|---|
| ADR-004 | Standardize API prefix `/api/v1/{domain}/*` | 🟢 Accepted | D-019 root_path hack |
| ADR-005 | Internal service-to-service authentication strategy | 🟢 Accepted | D-021 telemetry endpoints inconsistent guard |
| ADR-008 | Mobile BE không host system settings write — admin BE single source | 🟢 Accepted | SETTINGS.md scope |
| ADR-009 | Avatar storage Supabase (mobile) — intentional cross-repo split với R2 | 🟢 Accepted | PROFILE.md storage scope |
| ADR-010 | Devices schema canonical = PM_REVIEW (user_id nullable, ON DELETE SET NULL) | 🟢 Accepted | DEVICE.md HS-001 |
| ADR-011 | UC040 Connect Device = pair-create only (drop pair-claim) | 🟢 Accepted | DEVICE.md UC040 v2 |
| ADR-012 | Drop calibration offset fields | 🟢 Accepted | DEVICE.md HS-003 |
| ADR-013 | IoT Simulator direct-DB write cho vitals tick (bypass BE) | 🟢 Accepted | INGESTION.md scope |
| ADR-015 | Alert severity taxonomy — clarify 4 layers + fix BE enum drift | 🟢 Accepted | D1 + XR-002 |

### Proposed (not yet Accepted)
- **ADR-016 proposed**: UserRelationship default permission posture (HS-012 driver, BE-M04 audit Phase 1).

## Bugs flagged during Phase 0.5

| BugID | Severity | Module | Status |
|---|---|---|---|
| HS-001 | Critical | DEVICE | 🔴 Open (Phase 4 scheduled per ADR-010) |
| HS-002 | High | DEVICE | 🔴 Open |
| HS-003 | Medium | DEVICE | 🔴 Open (Phase 4 scheduled per ADR-012) |
| HS-004 | Critical | INGESTION (telemetry) | 🔴 Open (Phase 4 scheduled per ADR-005) |
| XR-001 | Medium | Cross-repo (5) | 🔴 Open |
| XR-002 | High | health_system BE | 🔴 Open (Phase 4 scheduled per ADR-015) |
| IS-002 | Critical | Iot_Simulator_clean | 🔴 Open (batch với HS-004) |
| HG-001 | Medium | HealthGuard | 🔴 Open (deferred Phase 4) |
| MA-* | — | healthguard-model-api | None flagged Phase 0.5 |

**Total Phase 0.5 bugs**: 8 (4 health_system + 1 cross-repo XR + 1 IoT sim + 1 HealthGuard + 0 model-api).

## D-series drift IDs (reference only Phase 1+)

5 D-series được mark "reference only" cho Phase 1+ audit:

| Drift ID | Source | Scope | Governing |
|---|---|---|---|
| D-012 | tier1/api_contract_v1.md | Telemetry endpoints inconsistent internal guard | HS-004 + ADR-005 |
| D-019 | tier1/topology_v2.md | API prefix `root_path` hack | ADR-004 |
| D-021 | tier1/topology_v2.md | `/sleep` + `/imu-window` + `/sleep-risk` no internal guard P0 | HS-004 + ADR-005 |
| D1 | tier1/db_canonical_diff.md | Severity vocab drift (alerts/sos_events CHECK + escalation matrix) | ADR-015 + XR-002 |
| D3 | NOTIFICATIONS.md Phase 0.5 | notification_reads truth source | NOTIFICATIONS.md reverify decision |

## Phase 4 backlog adjusted

Net Phase 4 effort estimate post-Phase 0.5 reverify:

| Module | Pre-Phase-0.5 estimate | Post-reverify | Saving |
|---|---|---|---|
| NOTIFICATIONS | ~5.5h (4 endpoint) | ~2.5h (1 endpoint mark-all + worker) | 3h |
| DEVICE | ~4h (calibration offsets active) | ~3h (drop offsets per ADR-012) + 15min FE attention zone fix | 0.5h |
| INGESTION | ~3h (auth fix + topology doc) | ~2h (HS-004 only, drop D-ING-01/02 overlap) | 1h |
| AUTH | ~6h (deep-dive review) | ~6h (no scope change) | 0 |
| MONITORING | ~3h | ~3h | 0 |

**Net saving**: ~4.5h scope reduce qua Phase 0.5 reverify.

## Phase 1 audit re-evaluation note

Phase 1 audit (BE-M01..M11 + MOB-M01..M12) chạy với Phase 0.5 reverify findings as input:
- **5 known D-series blacklist** (D-012, D-019, D-021, D1, D3) — reference only trong Phase 1 audit Cross-references, không re-flag.
- **8 Phase 0.5 bugs** (HS-001..HS-004, XR-001..XR-002, IS-002, HG-001) — pre-existing, reference only trong Phase 1 New bugs.
- **9 Accepted ADRs** — reference trong Phase 1 audit, không re-debate.

Phase 1 audit total bugs **net new**: 19 (HS-005 → HS-023). Cross-cutting với Phase 0.5 bugs: 0 duplicate, 0 conflict.

## Definition of Done — closure status

Per charter `00_phase_0_5_charter.md`:

- [x] 37 modules có new UC + intent_drift doc → **29 file** consolidated (some module merged across waves).
- [x] `phase_0_5_summary.md` aggregate (this file).
- [x] UC delta documented (drop / merge / rewrite / new) — section above.
- [x] Phase 4 backlog adjusted theo intent mới — section above.
- [x] New ADRs added (9 ADRs Accepted).
- [x] Phase 1 Track 1A re-evaluation — Phase 1 audit complete (BE 11 + Mobile 12 module health_system).

**Phase 0.5 status**: ✅ **CLOSED** với this aggregate summary.

## Trust hierarchy post-Phase-0.5

> 1. UC v2 (Phase 0.5 output) — HIGHEST trust
> 2. SRS technical sections (NFR, threshold, security) — trust nếu không bị Phase 0.5 override
> 3. Phase -1 specs (DB canonical, API contract, topology) — trust
> 4. Code — implementation, không phải intent
> 5. UC cũ pre-Phase-0.5 — DEPRECATED (chỉ archive)

## Cross-references

- Charter: [`00_phase_0_5_charter.md`](./00_phase_0_5_charter.md)
- Intent drift docs: [`tier1.5/intent_drift/`](./tier1.5/intent_drift/) (29 file)
- ADR INDEX: [`PM_REVIEW/ADR/INDEX.md`](../ADR/INDEX.md)
- BUGS INDEX: [`PM_REVIEW/BUGS/INDEX.md`](../BUGS/INDEX.md)
- Phase 1 audit health_system: [`tier2/health_system/_TRACK_SUMMARY.md`](./tier2/health_system/_TRACK_SUMMARY.md)
- Phase 2 verify health_system: [`tier1.5/verify/health_system/PHASE_2_VERIFY_REPORT.md`](./tier1.5/verify/health_system/PHASE_2_VERIFY_REPORT.md)

## Next phase readiness

Phase 0.5 closure → **Phase 4 ready** với:
- Phase 0.5 baseline complete (UC v2 + 9 ADRs + 8 pre-existing bugs).
- Phase 1 macro audit health_system complete (19 new bugs, Top 5 risks, cross-module patterns).
- Phase 2 verify health_system complete (0 false-positive, 1 cross-repo discovery refine HS-021 strategy).

**Phase 4 fix sequence** (per Phase 2 verify dependency graph):
1. P0 batch 1: HS-018 (XSS) + HS-020 (orphan) + HS-023 (scripts).
2. P0 batch 2 cross-repo: HS-021 + HS-006 staged rollout.
3. P0 batch 3 pydantic-settings migration: HS-005 + HS-006 + HS-007 + HS-015.
4. P1 batch: HS-009 canonical update + HS-010..HS-014 ORM sync + HS-019 + HS-022.
5. P2 batch: HS-016 + HS-017 defense-in-depth.
