# Verification Report — `Iot_Simulator_clean / SIMULATOR_CORE`

**Verified:** 2026-05-13
**Source doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` (status Confirmed v2 post-fix)
**Verifier:** Phase 0.5 spec verification pass (deep cross-check code vs doc)
**Verdict (initial):** WARN — 3 HIGH + 4 MEDIUM + 3 LOW drift findings.
**Verdict (resolved 2026-05-13):** PASS v2 — ADR-014 accepted + drift doc v2 rewritten. HIGH all done, MEDIUM M1 resolved via ADR, M3 done, M4 scheduled Phase 4. LOW quick wins all done.

---

## TL;DR

- **C1-C7 behaviors**: Most correct. Minor: motion generator khong always produce output (returns `None` sometimes).
- **C6 "5 states"**: SAI. State machine thuc te KHONG phai 5 states nhu doc list. Actual enum = 7 activity_state values + 3 orthogonal state fields. Doc nham voi "DEVICE lifecycle states" tu mobile app context.
- **"mock_personas.py"**: Doc claim "Persona profiles preset" - nhung code comment noi "Not currently auto-imported" -> preset dead code.
- **Cross-repo inconsistency**: `sleep_ai_client.py` trong simulator_core van bug IS-001 (POST `/predict` thay vi `/api/v1/sleep/predict`). Doc SIMULATOR_CORE list module nay nhung khong reference IS-001.
- **Q1 Phase 4 enhancement ("named health profiles")**: Scope clash voi 3 existing concepts (MOCK_PERSONAS, PersonaConfig, SLEEP_VITALS_PROFILES).

---

## 1. Mapping: claim trong drift doc vs code reality

### 1.1 Module file claims

| Claim | Code location | Verdict |
|---|---|---|
| `session.py`: SimulatorSession - tick loop, device state machine | `session.py:52-90` (`SimulatorSession.tick()`) | OK Dung |
| `vitals_generator.py`: Generate HR/SpO2/BP/temp (persona + scenario + noise) | **`vitals_generator.py` la SHIM** (3 dong re-export). Logic thuc te o `generators.py:45-194` class `VitalsGenerator` | WARN Misleading - file ton tai nhung rong |
| `motion_generator.py`: 3-axis accelerometer + gyroscope arrays | **`motion_generator.py` la SHIM** (3 dong re-export). Logic thuc te o `generators.py:196-231` class `MotionGenerator` | WARN Misleading - same as above |
| `generators.py`: Composite generator orchestration | `generators.py:45, 196` - 2 classes (Vitals + Motion). KHONG co "composite orchestration" - chi la file chung chua 2 classes rieng. Orchestration o `session.py:61-89` | WARN Wording sai |
| `persona_engine.py` + `mock_personas.py`: Persona profiles (age/weight/gender -> baseline) | `persona_engine.py:10-16` `Persona` + `persona_engine.py:43-102` `PersonaEngine`. `mock_personas.py` la list 5 presets voi comment "Not currently auto-imported" (dead-ish code) | WARN mock_personas chua wired |
| `dataset_registry.py`: Load parquet artifacts, serve data by device binding | `dataset_registry.py:29` class `DatasetRegistry` + 30+ methods | OK Dung |
| `fall_ai_client.py`: HTTP client -> model-api `/api/v1/fall/predict` (correct path) | `fall_ai_client.py` FallAIClient.predict() - `f"{self.base_url}/api/v1/fall/predict"` | OK Dung + availability probe dung `/api/v1/fall/model-info` (verified) |
| `sleep_vitals_enricher.py`: Enrich sleep record voi vitals context | `sleep_vitals_enricher.py:94-152` `enrich_sleep_record()` + 4 scenario profiles (good/fragmented/apnea_mild/apnea_severe) | OK Dung |

**Module claim verdict: WARN 3/8 misleading hoac incomplete.**

### 1.2 Device state machine claim (C6 "5 states")

**Doc claim:** `provisioned -> streaming -> sleeping -> fall_countdown -> sos_active` (5 states)

**Actual code (`persona_engine.py:20-26`):**
```
@dataclass
class DeviceState:
    activity_state: str = "resting"
    fall_variant: str | None = None
    stress_state: str | None = None
    sleep_phase: str | None = None
    battery_level: int = 100
    is_online: bool = True
```

**Actual states reachable** (tu `transition_to` + `inject_event` + battery drain factors):

| State source | Values | Notes |
|---|---|---|
| `activity_state` default | `"resting"` | Default khi device tao |
| `activity_state` tu transitions | `"resting"`, `"walking"`, `"running"`, `"standing"`, `"fall"`, `"recovery"`, `"sleeping"` | 7 states |
| `_BATTERY_DRAIN_FACTORS` keys | `sleeping`, `resting`, `walking`, `running`, `standing`, `fall`, `recovery` | Confirm 7 |
| `fall_variant` (orthogonal) | `fall_generic`, `fall_brief`, `fall_from_bed`, `fall_1`, `fall_no_response`, etc. | Additional axis |
| `stress_state` (orthogonal) | `"stress"`, `"neutral"`, `None` | Additional axis |
| `sleep_phase` (orthogonal) | `"light"`, `"deep"`, `"rem"`, etc. | Additional axis |

**Verdict:** C6 claim sai.
- State machine KHONG phai 5 states linear. La activity_state (7 values) + 3 orthogonal state fields.
- `provisioned`, `streaming`, `fall_countdown`, `sos_active` KHONG PHAI states trong `DeviceState` - do la mobile app UI states (o `health_system/lib`), khong phai persona engine.
- Doc nham voi "device lifecycle tu mobile app perspective" - 2 concepts khac nhau:
  - Mobile app device state: provisioning, streaming, etc. (UI/UX flow)
  - Persona engine activity state: resting/walking/fall/etc. (physiological state generator)

### 1.3 "C3 Scenario modulation" behavior claim

**Doc claim:** "Scenario modulation: scenario inject -> vitals shift theo profile"

**Actual:** Scenario handling chia 2 layers:
- `persona_engine.inject_event(event_type, variant)` (`persona_engine.py:85-102`) - chi 9 event types: `fall_detected`, `sleep_start`, `sleep_end`, `sleep_phase_change`, `low_battery`, `device_offline`, `device_online`, `stress`, `neutral`.
- Scenario orchestration phuc tap hon o `api_server/services/session_service.py` + `scenarios/*` - KHONG trong simulator_core module.

**Verdict:** WARN C3 incomplete - "scenario modulation" chu yeu o layer TREN simulator_core. Core chi handle event-level state transitions.

### 1.4 "C7 Fall AI integration" claim

**Doc claim:** "Call `/api/v1/fall/predict` voi motion window"

**Actual (`fall_ai_client.py`):**
- `predict()` POST to `/api/v1/fall/predict` OK
- `check_availability()` probe `/api/v1/fall/model-info` OK
- Header KHONG co `X-Internal-Service: iot-simulator` (line: `headers={"Content-Type": "application/json"}`) - flagged in Phase -1.C as D-020 (medium severity, future security).

**Verdict:** WARN C7 dung endpoint, nhung thieu auth header (per topology D-020). Chua block runtime vi model-api chua enforce, nhung se break khi D-013 (internal secret enforce) ship.

### 1.5 Sleep AI client elephant in the room

**Doc KHONG mention** `sleep_ai_client.py` trong module list. Nhung `simulator_core/sleep_ai_client.py` la ton tai va la module co bug IS-001 (POST `/predict` 404).

**Verdict:** MEDIUM Scope gap - module co, doc miss. Them vao + flag IS-001 reference.

### 1.6 Phase 4 "Named Health Profiles" scope analysis

**Doc proposes (Q1 + Features moi):**
- 3-5 named profiles: `elderly_healthy`, `elderly_hypertension`, `elderly_cardiac_risk`, `elderly_diabetic`, `young_healthy`
- BE: 3-5 presets + API
- FE: profile selector + expected outcome display

**Existing code reality:**

| Existing concept | Location | Overlap voi "named profiles"? |
|---|---|---|
| `mock_personas.py` MOCK_PERSONAS (5 presets: young/middle/elderly/obese/underweight) | `simulator_core/mock_personas.py` | Partial - demographic-based, khong phai health-condition-based. Comment noi "Not currently auto-imported" |
| `PersonaConfig` pydantic schema (age, weight_kg, height_cm, gender, seed) | `api_server/schemas.py:41-46` | Foundation, nhung chua health-conditions |
| `SLEEP_VITALS_PROFILES` (good/fragmented/apnea_mild/apnea_severe) | `simulator_core/sleep_vitals_enricher.py:13-65` | 4 "sleep health" profiles da ton tai nhung chi cho sleep scenario |
| `_FALL_VARIANT_TO_PERSONA` mapping | `api_server/dependencies.py:297-307` | Unrelated (fall variant naming) |
| `_build_db_device_persona()` | `api_server/dependencies.py:322` | Tao persona tu DB device info (age tu dob) |

**Verdict:** Phase 4 enhancement "named health profiles" scope overlap voi 3 existing concepts:
1. MOCK_PERSONAS (5 demographic presets dead code)
2. PersonaConfig schema
3. SLEEP_VITALS_PROFILES (sleep-only health conditions)

Doc proposal khong clarify:
- Health profiles new = REPLACE MOCK_PERSONAS, hay ADD ON?
- Co wire SLEEP_VITALS_PROFILES into named profiles khong?
- "Scenario outcome adjust theo profile" - hien tai `_FALL_VARIANT_TO_PERSONA` chi map 1 chieu (variant -> persona hint); adjust outcome theo health = need new layer.

**Risk:** Implement Phase 4 theo Q1 hien tai se tao 3rd concept roi ra chu khong unify existing 3.

---

## 2. Issues enumerated (prioritized)

### CRITICAL - None

Khong co critical drift. Module nay less affected by runtime drift hon ETL_TRANSPORT.

### HIGH - Spec wrong / cross-repo coupling

**H1. C6 State machine claim sai (5 states linear vs reality 7 activity_state + 3 orthogonal axes)**
- **Evidence:** `persona_engine.py:20-26` DeviceState dataclass + grep `transition_to` patterns.
- **Impact:** Ai doc spec se confuse giua mobile app device UI state (provisioned/streaming/sos_active) va persona engine physiological state (resting/walking/fall/recovery). 2 concepts khac repo, khac domain.
- **Fix direction:** Split C6 thanh 2 claims:
  - C6a: Persona engine activity_state (7 values) + 3 orthogonal fields (fall_variant, stress_state, sleep_phase).
  - C6b: Mobile app device lifecycle states - clarify KHONG trong simulator_core scope, reference mobile DEVICE module.
- **Effort:** Doc 20min.

**H2. Module `sleep_ai_client.py` miss trong doc + IS-001 cross-reference**
- **Evidence:** `simulator_core/sleep_ai_client.py` ton tai 78 lines, POST `/predict` -> 404 (IS-001 critical bug).
- **Impact:** SIMULATOR_CORE module verify incomplete - miss 1 module.
- **Fix direction:** Add `sleep_ai_client.py` vao "Code state" section + reference IS-001 trong cross-references + note "ca fall_ai_client + sleep_ai_client deu thieu X-Internal-Service header per D-020".
- **Effort:** Doc 15min.

**H3. `vitals_generator.py` + `motion_generator.py` la shim (misleading doc)**
- **Evidence:** 2 file day 3 dong re-export. Logic thuc o `generators.py`.
- **Impact:** Ai doc spec bullet list se mo file rong. Confuse cho contributor moi.
- **Fix direction:** Update "Code state" section:
  - `generators.py`: Chua VitalsGenerator (line 45) + MotionGenerator (line 196) classes
  - `vitals_generator.py` / `motion_generator.py`: Re-export shims for convenience import
- **Effort:** Doc 10min.

### MEDIUM - Scope clarify / gap

**M1. Q1 Phase 4 "named health profiles" chua address 3 existing overlapping concepts**
- **Evidence:** Section 1.6 analysis.
- **Impact:** Implement theo current spec se fragment concepts, debt tich luy.
- **Fix direction:** Phase 4 task Q1 can design session:
  - Decide: merge MOCK_PERSONAS + new health profiles = 1 unified `HealthProfile` catalog, hay keep separate?
  - Decide: SLEEP_VITALS_PROFILES co fold vao HealthProfile (per-domain expansion), hay giu rieng?
  - Output: ADR cho "Profile taxonomy" truoc khi code.
- **Effort:** 1h design + ADR + revise Phase 4 tasks.

**M2. `mock_personas.py` "Not currently auto-imported" - dead code or intentional?**
- **Evidence:** File header comment: `# NOTE: These personas are available for manual use / future API integration. Not currently auto-imported.`
- **Impact:** Code smell - neu planned feature (M1 resolve), preset nay can become active; neu not, should delete per YAGNI.
- **Fix direction:** Tied to M1. Decide as part of profile taxonomy ADR.
- **Effort:** Included in M1.

**M3. C3 "Scenario modulation" misleading - actually happens OUTSIDE simulator_core**
- **Evidence:** `persona_engine.inject_event()` supports 9 event types. Scenario orchestration logic (apply/load/compose) o `api_server/services/session_service.py` + `api_server/routers/scenarios.py`.
- **Impact:** Scope boundary fuzzy - ai doc doc tuong simulator_core handle full scenario.
- **Fix direction:** Revise C3:
  - "Event-level state transitions (9 event types) qua `PersonaEngine.inject_event()`" - in scope.
  - "Full scenario orchestration (apply/compose/persist)" - out of scope, see SCENARIOS module.
- **Effort:** Doc 15min.

**M4. Fall AI client thieu `X-Internal-Service` header (D-020 cross-repo)**
- **Evidence:** `fall_ai_client.py` headers `Content-Type: application/json` only.
- **Impact:** Khi D-013 (model-api internal secret enforce) ship trong Phase 4, fall AI integration se break.
- **Fix direction:** Phase 4 task coupling - khi add `verify_internal_secret` to model-api, simultaneous add header to `fall_ai_client.py` + `sleep_ai_client.py`.
- **Effort:** 30min code + test (per Phase -1.C D-020 guidance).

### LOW - Wording

**L1. `generators.py` "Composite generator orchestration" wording**
- Thuc te la file chua 2 classes rieng. Orchestration o `session.py`. Replace "Composite orchestration" -> "Container for VitalsGenerator + MotionGenerator classes".
- Effort 5min.

**L2. `MotionGenerator.generate()` can return `None`**
- `generators.py:201-215` return `None` neu activity khong match dataset. Doc "C4 3-axis accel/gyro arrays" khong mention nullable output.
- Effort 5min.

**L3. `inject_event()` supports `low_battery`, `device_offline`, `device_online` - khong map UC**
- Scope note: event types nay cho test realism, khong link UC.
- Effort 5min note.

---

## 3. Fix backlog (prioritized) — status tracked

| ID | Issue | Priority | Effort | Status (2026-05-13) |
|---|---|---|---|---|
| F-SC-01 | Split C6 state machine claim (persona vs mobile device UI) (H1) | P1 | 20min | **DONE** — v2 Q3 + C6a/C6b rewritten |
| F-SC-02 | Add `sleep_ai_client.py` module + cross-ref IS-001 (H2) | P1 | 15min | **DONE** — v2 Code state + Cross-refs added |
| F-SC-03 | Fix shim file wording for vitals/motion_generator.py (H3) | P1 | 10min | **DONE** — v2 Code state rewritten |
| F-SC-04 | ADR "Profile taxonomy" resolve M1 truoc Phase 4 code (M1+M2) | P1 | 1h design + ADR | **DONE** — ADR-014 accepted (Option X) |
| F-SC-05 | Revise C3 scope boundary (scenario modulation) (M3) | P2 | 15min | **DONE** — v2 C3 revised with scope note |
| F-SC-06 | Add X-Internal-Service header to fall_ai + sleep_ai clients (M4) | P2 | 30min code | **SCHEDULED** — Phase 4 paired with D-013 |
| F-SC-07 | Fix wording C1-C7 minor (L1-L3) | P3 | 15min | **DONE** — v2 C4 null note, C6 split, L3 absorbed in C3 |

**Status summary:** 6/7 DONE, 1/7 SCHEDULED (F-SC-06 Phase 4 code coupling with D-013).

**Total effort spent today:** ~2h (verify report + ADR-014 + drift doc v2 + INDEX).
**Remaining (Phase 4 code branch):** Per ADR-014 follow-up (~15-20h total) + F-SC-06 30min.

---

## 4. Cross-repo impact

### Affected docs/specs
- `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` D-020, D-022 - related findings for fall/sleep AI clients. No update needed (already logged).
- `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md` - cross-link from SIMULATOR_CORE drift doc.
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SCENARIOS.md` - depends on SIMULATOR_CORE named profiles (per SCENARIOS Q5). Can re-align sau khi F-SC-04 resolve.

### Affected code repos
- `Iot_Simulator_clean/simulator_core/fall_ai_client.py` - M4 fix (coupling with model-api).
- `Iot_Simulator_clean/simulator_core/sleep_ai_client.py` - IS-001 + M4 coupling.
- `Iot_Simulator_clean/simulator_core/mock_personas.py` - M1/M2 decision (keep + wire, or delete).

### ADRs can tao
- **ADR-014: Profile taxonomy** (PersonaConfig vs MOCK_PERSONAS vs HealthProfile vs SLEEP_VITALS_PROFILES) - resolve M1. Block Phase 4 "named health profiles" implementation.

---

## 5. Next steps - em de xuat

1. **Ngay (doc only, ~1h25min):** Anh approve F-SC-01, 02, 03, 05, 07 -> em apply -> drift doc v2.
2. **Decision needed (F-SC-04):** Anh decide profile taxonomy truoc khi em draft ADR-014. Em recommend:
   - **Option X (em recommend):** Unify = 1 `HealthProfile` model (age + comorbidities + baseline shifts) replace MOCK_PERSONAS. Keep `SLEEP_VITALS_PROFILES` as sub-catalog (sleep-specific deltas per HealthProfile).
   - **Option Y:** Keep MOCK_PERSONAS (demographics only) + add `HealthProfile` (conditions only) = 2 orthogonal catalogs. Operator select both.
   - **Option Z:** Expand PersonaConfig pydantic schema (add `conditions: list[str]`, `baseline_overrides: dict`) -> no new concept, enrich existing.
3. **Phase 4 backlog update:** Sau M1 resolve, revise Q1 tasks voi scope dung.

**Em khong edit drift doc trong phase verify. Output verify nay la input cho anh decide; rewrite chi sau khi anh confirm huong M1.**

---

## Appendix - evidence index

- Core engine: `simulator_core/{session,persona_engine,generators,dataset_registry}.py`
- AI clients: `simulator_core/{fall_ai_client,sleep_ai_client}.py`
- Presets/config: `simulator_core/mock_personas.py`, `api_server/schemas.py` (PersonaConfig)
- Sleep enrichment: `simulator_core/sleep_vitals_enricher.py` + 4 profiles
- Scenario orchestration (out of simulator_core scope): `api_server/services/session_service.py`, `api_server/routers/scenarios.py`
- Related bugs: `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md`
- Related topology drift: `PM_REVIEW/AUDIT_2026/tier1/topology_v2.md` D-020, D-022
- Related drift doc: `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SCENARIOS.md` (dependency on named profiles)
