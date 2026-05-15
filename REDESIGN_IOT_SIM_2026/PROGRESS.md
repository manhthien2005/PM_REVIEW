# Phase 7 Build — Progress Tracker

> **Mục đích:** Track 20 vertical slices của redesign IoT Simulator 2026. Update sau mỗi slice complete + commit.

**Session start:** 2026-05-15
**Executor:** Cascade (pair programmer)
**Driver:** ThienPDM
**Estimated total effort:** ~74h (8 weeks @ ~9h/week per Charter)
**Status:** 🟡 In Progress — S0 ✅, S1 ✅ (code), S1.8 deferred to S19. Starting S2.

---

## Baseline snapshot (S0)

### Repo trunk state at session start

| Repo | Trunk | HEAD commit | Status |
|---|---|---|---|
| `Iot_Simulator_clean` | `develop` | `03bcbb6` Merge SessionRunner UX redesign | ✅ Clean |
| `health_system` | `develop` | `6ebcf44` fix(family): align FamilyProfileSnapshot HS-014 | ⚠️ Stashed `pre-redesign-p7-bootstrap-2026-05-15` (auth_repository.dart + flutter plugin gen + temp_toggle.txt) |
| `healthguard-model-api` | `master` | `179f012` fix(schema): XR-003 step 2 synthetic flag + confidence reduction | ✅ Clean |
| `HealthGuard` | `develop` | `7227316` Merge PR #88 swagger fix | ✅ Clean |
| `PM_REVIEW` | `main` | `5fe4b7a` Merge redesign documentation phase | ✅ Clean — currently on `chore/redesign-p7-bootstrap` |

### Pre-existing work relevant to Phase 7

- **healthguard-model-api XR-003 step 1 + 2 đã có** (commits `33da3c5`, `179f012`):
  - `VitalSignsRecord.Field(ge=, le=)` cho 14 fields ✅
  - `is_synthetic_default: bool` + `defaults_applied: list[str]` ✅
  - Service apply confidence × 0.5 if synthetic ✅
- **S2 còn gap** (sẽ xử lý ở S2 turn):
  - `effective_confidence` separate field (vs current overloaded `confidence`)
  - `data_quality_warning` field
  - Structured 422 error response `{error: {code, message, details}}`

### Stop conditions reminder

Em sẽ STOP và hỏi anh khi:
- S12, S13 cần real Android device (full-screen takeover, 2-mobile fanout)
- S20 E2E smoke cần all services running + 2 mobile emulators
- Cần secret/credential mới
- Edge case không có trong ADR/contract
- Test fail 3 lần liên tiếp cùng approach
- Token budget gần hết

---

## Slice tracker

Status: ⏳ Pending | 🟡 In progress | ✅ Done | ❌ Blocked

| ID | Title | Status | Branch | Commit | Test result | Notes |
|---|---|---|---|---|---|---|
| **S0** | Bootstrap — verify baseline | ✅ Done | `chore/redesign-p7-bootstrap` (PM_REVIEW) | _to be filled_ | n/a (verify only) | health_system stashed; model-api XR-003 partial done; baseline = current HEAD per merged PRs |
| **S1** | ADR-021 endpoint prefix migration (5 repos) | ✅ Done (code only) | `feat/redesign-s1-prefix-migration` (health_system + Iot_Simulator_clean) | `47913bb` (HS) + `8f9c4df` (IoT) | 6/6 + 5/5 smoke pass, baseline routing OK | S1.1-S1.7 done; **S1.8 steering sync 5 repos DEFERRED to S19** (infra path requires chore branch, batch with PM_REVIEW docs sync) |
| **S2** | Model-API Field constraints + structured error (ADR-018 p1) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | **Partial DONE** — chỉ cần add `effective_confidence`, `data_quality_warning`, structured 422 |
| **S3** | Mobile BE risk validation refactor (ADR-018 p2) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | HS-024 critical fix path |
| **S4** | DB risk_scores synthetic columns migration (ADR-018 p3) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Additive migration only |
| **S5** | Telemetry ingest strict schema (ADR-018 p4) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Breaking change for IoT sim fixtures |
| **S6** | IoT sim HTTP vitals publisher (ADR-020 p1) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Vitals critical path |
| **S7** | BE auto-trigger risk + dispose IoT risk path (OQ5) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | |
| **S8** | imu_windows hypertable (ADR-022) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | TimescaleDB hypertable + retention |
| **S9** | Wire MobileTelemetryClient — fall (ADR-019) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Fall flow critical for demo |
| **S10** | Wire SleepRiskDispatcher — sleep (ADR-019) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | |
| **S11** | Mobile risk parser + warning banner (ADR-018 p5) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Additive UI |
| **S12** | Mobile FCM hybrid takeover (ADR-023 p1, OQ3) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | **Requires real Android device** |
| **S13** | Mobile FCM fanout linked profile (ADR-023 p2, OQ4) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | **Requires 2 mobile devices** |
| **S14** | BE WebSocket flow events (ADR-024 p1) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | |
| **S15** | FE sequence diagram live (ADR-024 p2) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Mermaid render |
| **S16** | FE multi-device coordinator (B3, OQ4) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | |
| **S17** | FE demo mode toggle (B3) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | |
| **S18** | Dispose dead code | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Cleanup orphan |
| **S19** | PM_REVIEW docs sync (BUGS + ADR INDEX) | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | Mark HS-024, XR-001, XR-003 Resolved |
| **S20** | E2E smoke + verify | ⏳ Pending | _tbd_ | _tbd_ | _tbd_ | **Requires all services + 2 mobile devices** |

---

## Phase summary

### Phase 7.0 — Foundation
- S0 ✅

### Phase 7.A — Prefix + Steering
- S1 ✅ code, S1.8 deferred

### Phase 7.B — Validation Layer
- S2, S3, S4, S5 ⏳

### Phase 7.C — Vitals Migration
- S6, S7 ⏳

### Phase 7.D — Fall + Sleep Refactor
- S8, S9, S10 ⏳

### Phase 7.E — Mobile UX
- S11, S12, S13 ⏳

### Phase 7.F — Simulator-web UX
- S14, S15, S16, S17 ⏳

### Phase 7.G — Cleanup + Polish
- S18, S19, S20 ⏳

---

## Blockers log

### Deferred tasks (not blocking)

- **S1.8 — Steering docs sync (5 repos)**: `.windsurf/rules/11-cross-repo-topology.md` cần update reality:
  - Current drift: `/api/mobile/*` (wrong) → should be `/api/v1/mobile/*`
  - Current drift: `/api/internal/*` (legacy) → should be `/api/v1/mobile/telemetry/*`
  - Current drift: `/api/admin/*` (wrong) → should be `/api/v1/admin/*`
  - Effort: ~15min update PM_REVIEW master + sync to 4 other repos via tooling
  - Batched with S19 PM_REVIEW docs sync
  - Risk if not done: only doc inconsistency, code is correct

---

## Bug closure tracker (target post Phase 7)

| Bug | Status now | Target |
|---|---|---|
| HS-024 | 🔴 Open | ✅ Resolved (after S3) |
| XR-001 | 🔴 Open | 🟡 Code fixed (S1), steering sync pending S19 |
| XR-003 | 🔴 Open | ✅ Resolved (after S2) |

---

## ADR status tracker (target post Phase 7)

| ADR | Status now | Target |
|---|---|---|
| ADR-013 | 🟢 Accepted | 🔵 Superseded by ADR-020 (after S6) |
| ADR-018 | _not registered in INDEX_ | 🟢 Accepted (after S2-S5) |
| ADR-019 | _not registered_ | 🟢 Accepted (after S9, S10) |
| ADR-020 | _not registered_ | 🟢 Accepted (after S6, S7) |
| ADR-021 | _not registered_ | 🟢 Accepted (after S1) |
| ADR-022 | _not registered_ | 🟢 Accepted (after S8) |
| ADR-023 | _not registered_ | 🟢 Accepted (after S12, S13) |
| ADR-024 | _not registered_ | 🟢 Accepted (after S14, S15) |

INDEX update batched ở S19.

---

## Conventions reminder

- Branch: `feat/redesign-s<N>-<desc>` (code) | `chore/redesign-s<N>-<desc>` (docs/migration)
- Commit: `<type>(<scope>): <mô tả tiếng Việt không dấu>`
- Merge no-ff vào trunk per repo, push trunk
- Update PROGRESS row after each slice

---

## Changelog

| Date | Action |
|---|---|
| 2026-05-15 | Session start, PROGRESS.md initialized |
| 2026-05-15 | S0 Bootstrap ✅ Done — baseline snapshot 5 repos, health_system stashed, chore branch created |
| 2026-05-16 | S1 ✅ Done (code S1.1-S1.7) — ADR-021 prefix /api/v1/mobile + /api/v1/sim merged to develop trunks (health_system 47913bb, Iot_Simulator_clean 8f9c4df). Smoke 11/11 pass. S1.8 steering sync deferred to S19. |
