# Phase 0.5 — Business Spec Rebuild + Intent Capture (Charter)

**Status:** In progress (started 2026-05-12)
**Trigger:** Anh nhận ra PM_REVIEW (UC + SRS) cũ, không trust được làm Source of Truth cho "intent".
**Goal:** Rebuild business specs (UCs + SRS) **đồng thời** capture true intent từ anh-now.
**Approach chosen:** Option C — Hybrid (UCs cũ làm memory aid, anh react quick, output = new UC + confirmed intent)

---

## Lý do tồn tại

### Vấn đề khám phá

```
Phase -1: Tech specs rebuilt ✅ (DB canonical, API contract, topology)
Phase 0.5 ORIGINAL DESIGN: pull UCs cũ làm "intended"
                              ↑
                  ❌ UC cũ outdated → "intended" cũng outdated
                     → drift check ra cũng vô nghĩa
```

### Insight

Em đang miss **layer quan trọng nhất:**

| Layer | Status |
|---|---|
| Technical specs (DB, API, topology) | ✅ Rebuilt Phase -1 |
| Code quality (rubric) | ✅ Phase 1 ongoing |
| Module inventory | ✅ Phase 0 |
| **Business intent (UC, SRS, features)** | ❌ **Never rebuilt** ← Phase 0.5 fix |

---

## Approach — Option C Hybrid

### Per module flow

```
┌─────────────────────────────────────────────────┐
│ 1. Em prep (offline, ~30-45 min/module)         │
│    - Đọc UC cũ → summary 5-10 dòng              │
│    - Đọc Phase 1 audit → code state summary    │
│    - Em recommend default (anh chỉ cần OK/no)   │
│                                                  │
│ 2. Anh react (~10-15 min/module)                │
│    - UC cũ: keep / update / drop / rewrite      │
│    - Code: align hay diverge?                   │
│    - Em recommendations: ✅ / ❌ / khác           │
│                                                  │
│ 3. Em finalize (offline, ~15-30 min/module)     │
│    - Write NEW UC file (overwrite cũ)           │
│    - Write intent_drift doc (decisions log)     │
│    - Adjust Phase 4 fix plan                    │
└─────────────────────────────────────────────────┘
```

### Anti-patterns avoid

- ❌ Bắt anh đọc UC cũ full → em present summary 5-10 dòng
- ❌ Question rộng "anh muốn module X như nào?" → focused "AC-3 lockout 5x — keep?"
- ❌ Em im lặng → mọi question em đã đề xuất default sẵn
- ❌ Touch code → Phase 0.5 = doc-only

---

## Output structure

### Per module

**File 1: New UC** (overwrite cũ)
```
PM_REVIEW/Resources/UC/<Module>/UC0XX_<Name>.md
```
Format: giữ pattern UC cũ nhưng nội dung anh-now confirmed.

**File 2: Intent drift doc** (audit trail)
```
PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/<repo>/<MODULE>.md
```
Capture:
- UC cũ vs UC mới diff
- Anh's decisions inline với rationale
- Phase 4 fix impact

### Aggregate

```
PM_REVIEW/AUDIT_2026/phase_0_5_summary.md
```
- UC delta table (29 UCs → new count)
- New ADRs nếu Phase 0.5 expose architectural decisions
- Phase 4 backlog adjusted

---

## Process — sequence

### Wave 1: HealthGuard (10 modules)
**Why first:** Track 1A audit fresh + 9 UCs clearest

- AUTH (UC001, UC009)
- ADMIN_USERS (UC022)
- DEVICES (UC025)
- CONFIG (UC024)
- LOGS (UC026)
- DASHBOARD (UC027)
- HEALTH (UC028) ← chứa HG-001
- EMERGENCY (UC029)
- RELATIONSHIP (no UC — Phase 0.5 decide có UC hay không)
- INFRA (no UC — defer)

### Wave 2: model-api (3 features)
- Fall prediction
- Sleep analysis
- Health risk

### Wave 3: IoT sim (6 modules)
- Routers + scenarios
- Sleep AI client (IS-001)
- ETL + Transport

### Wave 4: health_system BE (8 services)
- Auth, Ingestion, Monitoring, AI/XAI, Notification, Sleep, Device, Profile

### Wave 5: health_system mobile (10 modules)
- AUTH, HOME, DEVICE, INFRA, MONITORING, EMERGENCY, NOTIFICATION, ANALYSIS, SLEEP, PROFILE

---

## Effort estimate

| Wave | Modules | Em prep | Anh dialogue | Em finalize | Total |
|---|---|---|---|---|---|
| 1 HealthGuard | 10 | 5-7h | 2-2.5h | 3-4h | **10-13h** |
| 2 model-api | 3 | 1.5-2h | 0.5-0.7h | 1h | **3-4h** |
| 3 IoT sim | 6 | 3-4h | 1-1.5h | 1.5-2h | **5.5-7.5h** |
| 4 health_system BE | 8 | 4-6h | 1.3-2h | 2-3h | **7-11h** |
| 5 health_system mobile | 10 | 5-7h | 2-2.5h | 3-4h | **10-13h** |
| **Total** | **37** | **18-26h** | **7-9h** | **10-14h** | **35-48h** |

**Sessions estimate:** ~10-12 sessions (3-4h each).

---

## Definition of Done

Phase 0.5 done khi:
- [ ] 37 modules có new UC + intent_drift doc
- [ ] `phase_0_5_summary.md` aggregate
- [ ] UC delta documented (drop / merge / rewrite / new)
- [ ] Phase 4 backlog adjusted theo intent mới
- [ ] New ADRs nếu cần (vd: "FCM-only vs WebSocket+FCM" decision)
- [ ] Phase 1 Track 1A re-evaluation note: findings nào cần re-frame theo UC mới

---

## Out of scope

- ❌ NFR rewrite (security/perf threshold) — đã có trong SRS, keep
- ❌ DB schema change — Phase -1 đã chốt
- ❌ Tech stack change — anh không muốn đổi stack
- ❌ Sprint planning / JIRA update — Phase 5 (post-fix)
- ❌ Code edit — Phase 0.5 = doc-only

---

## Cross-references

- Phase 0 framework — 5-axis rubric vẫn dùng cho Phase 1
- Phase 1 Track 1A `_TRACK_SUMMARY.md` — code state input cho HealthGuard wave
- UC cũ `Resources/UC/` — memory aid, anh decide có overwrite không
- ADR-004 (API prefix), HG-001 (bug log) — references để align

---

## Lưu ý quan trọng

> **Trust hierarchy mới sau Phase 0.5:**
> 1. UC mới (Phase 0.5 output) — HIGHEST trust
> 2. SRS technical sections (NFR, threshold, security) — trust nếu không bị Phase 0.5 override
> 3. Phase -1 specs (DB canonical, API contract, topology) — trust
> 4. Code — implementation, không phải intent
> 5. UC cũ pre-Phase-0.5 — DEPRECATED (chỉ archive)
