# Verification Report - `Iot_Simulator_clean / SCENARIOS`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SCENARIOS.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** PASS (good doc) - 3 MEDIUM + 2 LOW findings.
**Verdict (resolved 2026-05-13):** PASS v2 - Anh approved F-SC-01 through F-SC-05. All 5 doc fixes DONE. No code changes, no ADR needed. Phase 4 backlog stable (Q5 FE preview depends on ADR-014).

---

## TL;DR

- **Scenario count OK:** BUILT_IN_SCENARIOS list contains exactly 13 scenarios (5 vitals + 3 fall + 3 sleep + 2 risk) - doc accurate.
- **Fall variant count OK:** `_FALL_VARIANT_POLICIES` dict has exactly 6 entries (false_fall / slip_recovery / fall_brief / fall_from_bed / confirmed / fall_no_response) - doc accurate.
- **Backfill max OK:** `backfill_sleep_history` route accepts `days_behind` 1-90 via pydantic schema validation. Background task pattern confirmed.
- **NEW M1: Side-effect routing scope narrower than doc claim.** `_SCENARIO_RISK_INJECTS` dict covers only 3 scenarios (hypoxia_critical, high_risk_cardiac, medium_risk_general). Doc S7 "scenario -> auto risk inject" implies generic mechanism; reality = 3 hardcoded mappings.
- **NEW M2: Boundary cross-reference inaccurate.** Doc claims "scenarios push alerts to HealthGuard BE via transport layer". Reality per ADR-013: transport layer unused at runtime. Alert push goes via `alert_service.py` HTTP direct. Scenarios themselves don't push alerts - they trigger BE side-effects that may emit alerts downstream.
- **L1 push-date 365 days not mentioned:** `push_sleep_for_date` route has separate 365-day max limit (distinct from backfill 90-day max), not documented in Q3.
- **L2 Q5 dependency on SIMULATOR_CORE named profiles:** Per ADR-014, "named profiles" was superseded by unified `HealthProfile` catalog. Q5 "scenario x profile" should reference ADR-014 HealthProfile.scenario_response as data source.

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 Scenario count + categories

**Doc claim:** 13 scenarios, 4 categories. Vitals (5) + Fall (3) + Sleep (3) + Risk (2).

**Code reality** (`api_server/routers/scenarios.py:66-321`):

| Category | Doc count | Actual IDs | Code count |
|---|---|---|---|
| Vitals | 5 | normal_rest, tachycardia_warning, hypoxia_critical, hypertension_moderate, normal_walking | 5 OK |
| Fall | 3 | fall_high_confidence, fall_false_alarm, fall_no_response | 3 OK |
| Sleep | 3 | good_sleep_night, fragmented_sleep, elderly_normal | 3 OK |
| Risk | 2 | high_risk_cardiac, medium_risk_general | 2 OK |
| **Total** | **13** | - | **13 OK** |

**Verdict:** OK All scenario counts + categories exact.

### 1.2 Scenario metadata schema

**Doc claim:** Each scenario has id, name, category, description, expectedOutcome, severity, keySignals, followUp.

**Code reality** (`scenarios.py:50-65` ScenarioOption pydantic):

| Field | Type | Verified |
|---|---|---|
| `id` | str | OK |
| `name` | str | OK |
| `category` | ScenarioCategory (Literal) | OK (4 values: vitals/fall/sleep/risk) |
| `description` | str | OK |
| `expectedOutcome` | str | OK |
| `severity` | ScenarioSeverity (Literal) | OK (normal/warning/critical) |
| `keySignals` | list[KeySignal] | OK |
| `followUp` | list[ScenarioFollowUp] | OK |

**Verdict:** OK Schema exact match.

### 1.3 Fall variant policy (6 variants)

**Doc claim:** 6 variants: false_fall, slip_recovery, fall_brief, fall_from_bed, confirmed, fall_no_response.

**Code reality** (`dependencies.py:218-287` `_FALL_VARIANT_POLICIES`):

| Variant | Countdown | Auto-resolve | Cancel allowed | Device state | Alert | Severity | Confidence |
|---|---|---|---|---|---|---|---|
| `false_fall` | 0 | No | No | streaming | No | normal | 0.10 |
| `slip_recovery` | 0 | No | No | streaming | No | normal | 0.20 |
| `fall_brief` | 10s | Yes | Yes | fall_countdown | Yes | warning | 0.65 |
| `fall_from_bed` | 30s | No | Yes | fall_countdown | Yes | critical | 0.85 |
| `confirmed` | 30s | No | Yes | fall_countdown | Yes | critical | 0.95 |
| `fall_no_response` | 30s | No | No | fall_countdown | Yes | critical | 0.99 |

Plus `_FALL_VARIANT_DEFAULT_POLICY` = `confirmed` (for unknown variants like `fall_1`, `fall_generic` legacy).

**Verdict:** OK 6 variants exact match, granularity clear (test 6 branches per doc Q2).

### 1.4 Sleep backfill (Q3 90 days)

**Doc claim:** Backfill max 90 days, BackgroundTask pattern.

**Code reality** (`scenarios.py:405-438` `backfill_sleep_history`):
- Accepts `BackfillSleepRequest` with `days_behind` field.
- Uses `background_tasks.add_task(_run_backfill, ...)` - FastAPI BackgroundTasks.
- Returns immediately with `pushed=0, total_days=days_behind, errors=["Backfill accepted"]`.
- Comment: "CRITICAL #3 fix: heavy loop up to 90 iterations of DB + AI + HTTP runs in background".

**Verdict:** OK BackgroundTask pattern + 90 days context accurate.

**LOW concern L1:** `push_sleep_for_date` route has SEPARATE validation: `if (today - request.target_date).days > 365`. 365 days max, not 90. Doc mixes 2 endpoints (backfill + push-date) in Q3 but only mentions 90. Push-date is 365.

### 1.5 Side-effect routing (S7 "scenario -> auto risk inject")

**Doc claim:** Side-effect routing table: scenario -> auto risk inject.

**Code reality** (`scenarios.py:305-315` `_SCENARIO_RISK_INJECTS`):

```
_SCENARIO_RISK_INJECTS: dict[str, dict[str, object]] = {
    "hypoxia_critical": {"risk_type": "general", "risk_level": "HIGH", "score": 0.78},
    "high_risk_cardiac": {"risk_type": "cardiac", "risk_level": "CRITICAL", "score": 0.90},
    "medium_risk_general": {"risk_type": "general", "risk_level": "MEDIUM", "score": 0.58},
}
```

**Scope:** 3 scenarios trong 13 (hypoxia_critical + 2 risk scenarios). 10 scenarios KHONG co auto risk inject.

**Fall side-effects** via `runtime.set_device_scenario()` (via fall variant policy table) - separate mechanism.
**Sleep side-effects** via `followUp` metadata + `runtime.set_device_scenario()` - separate mechanism.

**Verdict:** WARN Doc S7 misleading - implies all scenarios have "auto risk inject". Reality = 3 scenarios. Other side-effects (fall countdown, sleep phase) go through DIFFERENT routing mechanisms.

### 1.6 Apply scenario atomicity (S2)

**Doc claim:** Apply = atomic BE-driven (FE khong fire follow-on calls).

**Code reality** (`scenarios.py:326-362` `apply_scenario`):
- Module B.2 comment: "this endpoint is now the single source of truth for the apply pipeline. Fall and sleep side-effects are already injected by `runtime.set_device_scenario()`; the risk-inject side-effects are looked up from `_SCENARIO_RISK_INJECTS` and dispatched here. The FE no longer fires its own follow-on `events/fall` / `events/risk-inject` POSTs after a scenario apply."
- Flow: `runtime.set_device_scenario()` -> `_SCENARIO_RISK_INJECTS.get()` -> if exists, `runtime.inject_risk_score()`.
- 404 on either step returns cleanly.

**Verdict:** OK S2 claim verified. Atomic BE-driven pipeline.

### 1.7 Scenario -> HealthGuard BE alert claim

**Doc claim (Cross-references):** "Boundary: scenarios push alerts to HealthGuard BE via transport layer"

**Code reality:**
- Transport layer (`TransportRouter`) = dead code per ADR-013 (0 call sites trong runtime).
- Alert push from IoT sim -> health_system BE (not HealthGuard BE) via `alert_service._push_alert_to_backend()` + `httpx`.
- Scenarios themselves DON'T push alerts. They trigger BE side-effects (fall event / risk inject) that MAY emit alerts downstream.

**Verdict:** FAIL Cross-reference wording sai 3 goc:
1. "HealthGuard BE" sai - alert push sang `health_system` BE (mobile BE port 8000), khong phai HealthGuard admin BE (port 5000).
2. "Transport layer" sai - per ADR-013, transport module unused.
3. "Scenarios push alerts" sai - scenarios only trigger BE, alert emission downstream.

---

## 2. Issues enumerated (prioritized)

### CRITICAL - none
### HIGH - none

### MEDIUM - Doc accuracy / scope clarity

**M1. S7 "side-effect routing" scope narrower than claim**
- **Evidence:** Section 1.5. `_SCENARIO_RISK_INJECTS` covers 3 scenarios, doc wording implies generic mechanism.
- **Impact:** Reader tuong all scenarios auto risk inject. Actual = 3. Risk misunderstanding Phase 4 debugging.
- **Fix direction:** Revise S7:
  - "Side-effect routing: 3 scenarios (hypoxia_critical, high_risk_cardiac, medium_risk_general) auto risk inject via `_SCENARIO_RISK_INJECTS` table. Other scenarios trigger fall/sleep side-effects via `runtime.set_device_scenario()` separately."
- **Effort:** Doc 15min.

**M2. Cross-reference "HealthGuard BE via transport layer" wrong**
- **Evidence:** Section 1.7.
- **Impact:** Reader tuong scenarios -> HealthGuard admin BE qua transport. Reality = scenarios -> BE side-effects -> downstream alert push via direct httpx to health_system BE.
- **Fix direction:** Revise Cross-references:
  - Remove "Boundary: scenarios push alerts to HealthGuard BE via transport layer".
  - Add: "Scenario apply triggers BE side-effects (fall event / risk inject / sleep phase). Downstream alerts (if any) emit via `alert_service.py` direct httpx to health_system BE `/mobile/telemetry/alert`. Transport layer per ADR-013 is not involved."
- **Effort:** Doc 10min.

**M3. Q5 dependency link to SIMULATOR_CORE should reference ADR-014**
- **Evidence:** Doc Q5 "Link voi SIMULATOR_CORE named profiles enhancement". Post-verify, named profiles superseded by unified HealthProfile per ADR-014.
- **Impact:** Phase 4 task implementation order = ADR-014 HealthProfile first, then Q5 FE preview can consume HealthProfile.scenario_response.
- **Fix direction:** Update Q5 + Cross-references to reference ADR-014 HealthProfile.scenario_response explicitly.
- **Effort:** Doc 10min.

### LOW - Wording

**L1. Push-date 365 days not documented**
- **Evidence:** Section 1.4. `push_sleep_for_date` route has `days > 365` validation check.
- **Fix direction:** Expand Q3 or add S5 note: "Sleep push single: 1 day, synchronous. Cap 365 days old (separate from backfill 90-day max)."
- **Effort:** 5min doc.

**L2. PRE_MODEL_TRIGGER cross-reference could note shadow mode behavior**
- **Evidence:** Doc Cross-ref says "PRE_MODEL_TRIGGER: auto-detect can trigger same AI calls as manual scenario". Per PRE_MODEL_TRIGGER verify, default mode = shadow (actions log only). Active mode deferred.
- **Fix direction:** Add note: "PRE_MODEL_TRIGGER auto-detect runs in shadow mode by default (per F-PT-03). Manual scenario apply remains primary trigger path."
- **Effort:** 5min doc.

---

## 3. Fix backlog (prioritized) — status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-SC-01 | Revise S7 scope (M1) - 3 scenarios actual vs generic wording | P2 | 15min | **DONE** — v2 S7 + Code state updated |
| F-SC-02 | Fix cross-reference wording (M2) - HealthGuard BE vs health_system BE + transport dead | P2 | 10min | **DONE** — v2 Cross-references section rewritten |
| F-SC-03 | Link Q5 to ADR-014 HealthProfile.scenario_response (M3) | P2 | 10min | **DONE** — v2 Q5 + S8 + Cross-references linked |
| F-SC-04 | Document push-date 365 days cap (L1) | P3 | 5min | **DONE** — v2 Q3 expanded + S5 noted |
| F-SC-05 | PRE_MODEL_TRIGGER shadow mode note (L2) | P3 | 5min | **DONE** — v2 Cross-references PRE_MODEL_TRIGGER note |

**Status summary:** 5/5 DONE.

**Total effort spent today:** ~50min (verify report + drift doc v2 rewrite).
**Remaining (Phase 4 code branch):** Only Q5 FE preview (~3-4h) depends on ADR-014 HealthProfile implementation.

---

## 4. Cross-repo impact

### Affected docs/specs
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` - Q5 scenario preview refs ADR-014 HealthProfile. Already cross-linked in SIMULATOR_CORE v2.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/PRE_MODEL_TRIGGER.md` - Cross-ref mode shadow noted in PT v2.
- `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` - no update needed (already notes `/mobile/telemetry/alert`).

### Affected code repos
None. Module is verified stable. No code changes needed.

### ADRs needed
None. Module boundaries clear, decisions already covered by ADR-013 (transport) + ADR-014 (HealthProfile).

---

## 5. Next steps - em de xuat

1. **Anh approve em apply:** F-SC-01 through F-SC-05 doc fixes (~45min total).
2. **No decisions needed** - all refinements are factual corrections/clarifications.
3. **Phase 4 backlog stable:** Q5 FE preview still depends on ADR-014 HealthProfile implementation.

**Em khong edit drift doc trong phase verify. Output verify nay la input cho anh decide.**

---

## Appendix - evidence index

- Scenarios manifest: `api_server/routers/scenarios.py:66-303` (13 ScenarioOption entries)
- Schema: `api_server/routers/scenarios.py:50-65` (ScenarioOption pydantic)
- Fall variant policies: `api_server/dependencies.py:218-287` (6 entries in `_FALL_VARIANT_POLICIES`)
- Fall variant default: `dependencies.py:289` (`_FALL_VARIANT_DEFAULT_POLICY = confirmed`)
- Side-effect routing: `api_server/routers/scenarios.py:305-315` (`_SCENARIO_RISK_INJECTS` 3 entries)
- Apply scenario route: `scenarios.py:326-362`
- Backfill route: `scenarios.py:405-438` (BackgroundTask pattern)
- Push-date route: `scenarios.py:440-466` (365-day cap)
- Runtime integration: `dependencies.py:1509-1524` (`_resolve_fall_variant_policy`)
