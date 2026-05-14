# ADR-014: IoT Simulator profile taxonomy - unified HealthProfile

**Status:** Accepted
**Date:** 2026-05-13
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, iot-sim, persona, scope, simulator-web, phase4-prereq]

## Context

Phase 0.5 verify pass cho module `SIMULATOR_CORE` (SIMULATOR_CORE_verify.md) phat hien 3 concepts "profile-like" cung ton tai nhung rieng re:

1. **`MOCK_PERSONAS`** (`simulator_core/mock_personas.py`): 5 demographic presets (young_healthy / middle_aged / elderly / obese / underweight). File header: `# NOTE: These personas are available for manual use / future API integration. Not currently auto-imported.` -> **Dead code**.
2. **`PersonaConfig`** (`api_server/schemas.py:41-46`): pydantic schema active - age / weight_kg / height_cm / gender / seed. **Foundation, nhung thieu health conditions.**
3. **`SLEEP_VITALS_PROFILES`** (`simulator_core/sleep_vitals_enricher.py:13-65`): 4 sleep-specific health conditions (good_sleep_night / fragmented_sleep / sleep_apnea_mild / sleep_apnea_severe). **Active, nhung scope chi sleep.**

Intent drift doc `SIMULATOR_CORE.md` Q1 propose Phase 4 enhancement "named health profiles" (3-5 preset: elderly_healthy / elderly_hypertension / elderly_cardiac_risk / elderly_diabetic / young_healthy) **ma khong clarify relationship voi 3 concepts tren** -> risk implement Phase 4 tao `HealthProfile` la **concept thu 4 roi ra** thay vi unify.

**Forces:**
- Operator can chon "patient profile" de simulate (elderly hypertensive vs young healthy) -> cung scenario, khac outcome magnitude.
- FE simulator-web can display "expected vitals ranges + outcome preview" truoc khi apply scenario (per SCENARIOS Q5 + SIMULATOR_CORE FE display requirement).
- AI testing can realistic data -> `PersonaConfig` va health conditions phai wire vao vitals generation.
- 4 sleep profiles hien tai hoat dong (`sleep_service._select_session_for_scenario`) - khong muon break.

**Constraints:**
- Capstone scope - 3-5 profiles la du, khong can clinical-grade comorbidity model.
- MOCK_PERSONAS tu "manual use / future" da 6+ thang khong wire - candidate for deletion per YAGNI.
- `PersonaConfig` pydantic schema da trong FE/BE contract (`schemas.py` + `deviceApi.ts`) - not breaking.

**References:**
- `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` (Q1 + Features moi)
- `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/SIMULATOR_CORE_verify.md` (M1/M2 findings triggered this ADR)
- `Iot_Simulator_clean/simulator_core/mock_personas.py` (dead code)
- `Iot_Simulator_clean/api_server/schemas.py:41-46` (PersonaConfig)
- `Iot_Simulator_clean/simulator_core/sleep_vitals_enricher.py:13-65` (SLEEP_VITALS_PROFILES)

## Decision

**Chose:** Option X - **Unified `HealthProfile` catalog replace MOCK_PERSONAS; SLEEP_VITALS_PROFILES fold vao HealthProfile.sleep_profile sub-catalog.**

**Why:**
1. **It concept nhat.** 3 overlapping roi re -> 1 catalog chinh + 1 sub-catalog per-domain. Developer future chi can hieu 1 model.
2. **MOCK_PERSONAS dead code xoa luon.** Khong vi pham Chesterton's Fence vi comment noi ro "manual use / future" va 6+ thang khong wire.
3. **SLEEP_VITALS_PROFILES fold tu nhien.** Sleep deltas la per-HealthProfile per-domain = structured hierarchy, khong mat granularity.
4. **PersonaConfig backward compat.** Giu pydantic schema, them field `health_profile: str | None` reference HealthProfile catalog. FE/BE contract khong break.
5. **Scope capstone-friendly.** 3-5 profiles + sleep overlay = du demo "personalized AI testing" ma khong over-engineer.

## Options considered

### Option X (chosen): Unified HealthProfile, replace MOCK_PERSONAS, fold SLEEP_VITALS_PROFILES

**Description:**

Dinh nghia `HealthProfile` catalog moi (`simulator_core/health_profiles.py` hoac similar):

```
class HealthProfile:
    label: str               # e.g., "elderly_hypertension"
    display_name: str        # "Ong Nguyen, 72t, tien su tang huyet ap"
    description: str         # FE display blurb
    demographics: dict       # age range, weight range, height range, typical gender
    baseline_shifts: dict    # { "hr": (+5, +10), "bp_sys": (+20, +30), ... }
    scenario_response: dict  # { "tachycardia": magnitude_multiplier_1.5, ... }
    sleep_profile: dict | None  # ref to SLEEP_VITALS_PROFILES entry (fold sub-catalog)
    conditions: list[str]    # tags: "hypertension", "cardiac_risk", etc.
```

Catalog: 3-5 profiles (per Q1): `young_healthy`, `elderly_healthy`, `elderly_hypertension`, `elderly_cardiac_risk`, `elderly_diabetic`.

**Migration:**
- `MOCK_PERSONAS`: Delete. Demographic info merge vao HealthProfile.demographics.
- `SLEEP_VITALS_PROFILES`: Keep file `sleep_vitals_enricher.py`, but change lookup from scenario_id -> HealthProfile.sleep_profile. Each HealthProfile reference 1 sleep entry.
- `PersonaConfig` pydantic schema: Add `health_profile: str | None = None` field -> reference HealthProfile.label.
- `_build_db_device_persona()`: Map DB device demographics -> auto-select closest HealthProfile (nearest-age match).

**BE API:**
- `GET /api/v1/sim/health-profiles` -> list all profiles (for FE selector).
- Device create/update: accept `health_profile` field trong `PersonaConfig`.

**FE simulator-web:**
- Profile selector dropdown (replace MOCK_PERSONAS picker neu co).
- Profile description card: show `demographics` + `baseline_shifts` ranges.
- Scenario preview: show `scenario_response[scenario_id]` magnitude.

**Pros:**
- 1 catalog thay 3 -> cognitive load thap.
- Sleep profiles tiep tuc hoat dong qua reference.
- PersonaConfig backward compat.
- FE display requirement (per SCENARIOS Q5) co data source.

**Cons:**
- Delete MOCK_PERSONAS = lose 5 demographic presets - phai migrate to HealthProfile demographics.
- Introduce new file + new schema - small boilerplate.
- `_build_db_device_persona()` auto-match logic can test coverage.

**Effort:**
- S Decision + ADR: 1h (this turn).
- M Backend implementation: 4-6h (schema + catalog + API endpoint + migration).
- M Frontend: 4-6h (profile selector + description card + preview).
- S Migration: 1-2h (map existing MOCK_PERSONAS -> HealthProfile demographics, delete file).
- S Test: 1-2h (API contract + HealthProfile.scenario_response matrix).

### Option Y (rejected): Keep MOCK_PERSONAS (demographics) + add HealthProfile (conditions) as 2 orthogonal catalogs

**Description:** MOCK_PERSONAS chi giu demographic (age/weight). HealthProfile moi chi define conditions (hypertension, cardiac, etc.). Operator chon ca 2: "elderly demographic + hypertension condition".

**Pros:**
- Flexible - combine demographics x conditions.
- No breaking change to MOCK_PERSONAS.

**Cons:**
- 2 catalogs overlap (elderly demographic + elderly_healthy HealthProfile = confusing).
- Combinatorial explosion - N x M cases to test.
- MOCK_PERSONAS dead code still dead - operator picking demographic separately = not a real use case observed.
- FE picker = 2 dropdowns = UX worse.

**Why rejected:** Over-engineer cho capstone. Operator dung thuc te la chon "patient template" (demographic + condition combined) chu khong tach. Option X = 1 picker = UX tot hon.

### Option Z (rejected): Expand PersonaConfig schema with conditions + baseline_overrides

**Description:** Giu PersonaConfig la source of truth. Add fields `conditions: list[str]`, `baseline_overrides: dict`, `scenario_multipliers: dict`. Khong co catalog rieng - moi device co full PersonaConfig.

**Pros:**
- No new concept file.
- Schema-driven, flexible.

**Cons:**
- No reusable catalog - every device need full config manual.
- FE picker = no preset list to pick from.
- Operator phai construct config moi lan - UX chua.
- SLEEP_VITALS_PROFILES catalog still separate (khong giai quyet M1).
- Schema phong to voi dynamic dict fields -> pydantic validation yeu.

**Why rejected:** Khong resolve catalog problem. Operator can presets de demo, khong muon construct config. Option X co catalog + schema reference = best of both.

---

## Consequences

### Positive

- 1 source of truth cho "patient template" concept.
- FE picker simple (1 dropdown voi HealthProfile.display_name + description).
- Sleep profiles fold gon, khong orphan.
- MOCK_PERSONAS dead code removed -> giam clutter.
- Phase 4 "named health profiles" task unblocked voi clear scope.

### Negative / Trade-offs accepted

- Delete MOCK_PERSONAS = lose direct demographic presets. Mitigation: demographics moved to HealthProfile.demographics + can infer tu DB device.
- Schema migration: add `health_profile: str | None` to PersonaConfig = FE/BE coordinated update (small).
- Sleep profile lookup changes from `scenario_id` -> `health_profile.sleep_profile` = refactor `sleep_service._select_session_for_scenario()`. Testable, small.
- Em accept hierarchy depth 2 (HealthProfile -> sleep_profile) thay vi flat tables - worth it vi per-domain deltas thuc te la 2-level.

### Follow-up actions required

- [ ] **Phase 4 task (BE):** Create `simulator_core/health_profiles.py` catalog module. Effort M (2-3h).
- [ ] **Phase 4 task (BE):** Add `health_profile` field to `PersonaConfig` pydantic schema. Effort S (30min).
- [ ] **Phase 4 task (BE):** API endpoint `GET /api/v1/sim/health-profiles`. Effort S (1h + test).
- [ ] **Phase 4 task (BE):** Refactor `sleep_service._select_session_for_scenario()` to use HealthProfile.sleep_profile lookup. Effort S (1-2h + test).
- [ ] **Phase 4 task (BE):** `_build_db_device_persona()` auto-match HealthProfile by demographics. Effort S (1h).
- [ ] **Phase 4 task (FE):** simulator-web profile selector + description card + scenario preview. Effort M (4-6h).
- [ ] **Phase 4 task (cleanup):** Delete `simulator_core/mock_personas.py`. Effort S (5min + grep ensure no import).
- [ ] **Phase 0.5 doc:** Revise `SIMULATOR_CORE.md` drift doc Q1 + Features moi theo decision. Effort S (30min).
- [ ] **Phase 0.5 doc:** Revise `SCENARIOS.md` drift doc Q5 "expected outcome preview" scope voi reference HealthProfile.scenario_response. Effort S (20min).

## Reverse decision triggers

Conditions de reconsider:

- Neu operator feedback bao "muon chon demographics va conditions rieng" (use case X em chua thay) -> reconsider Y.
- Neu clinical-grade comorbidity model needed (post-capstone feature) -> reconsider hierarchical Option beyond X.
- Neu sleep profiles phat trien mass sang cac domain khac (respiration, cardiac) va per-domain logic phuc tap -> may need split back, X hierarchy khong con scalable.

## Related

- **Triggered by:** `PM_REVIEW/AUDIT_2026/tier1.5/verify/iot_simulator_clean/SIMULATOR_CORE_verify.md` (M1/M2).
- **Supersedes intent:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SIMULATOR_CORE.md` Q1 + "Features moi - Named Health Profiles" section - se revise voi HealthProfile unified approach.
- **Cross-refs drift doc:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/iot_simulator_clean/SCENARIOS.md` Q5 "expected outcome preview" - HealthProfile.scenario_response la source cho preview data.
- **ADR:** No supersede. Cross-reference ADR-013 (IoT sim direct-DB) - unrelated but same repo.
- **Code touched (Phase 4):**
  - NEW: `Iot_Simulator_clean/simulator_core/health_profiles.py`
  - MODIFY: `Iot_Simulator_clean/api_server/schemas.py` (PersonaConfig add field)
  - MODIFY: `Iot_Simulator_clean/api_server/services/sleep_service.py` (sleep lookup)
  - MODIFY: `Iot_Simulator_clean/api_server/dependencies.py` (`_build_db_device_persona`)
  - MODIFY: `Iot_Simulator_clean/simulator-web/src/types/device.ts` + selector components
  - DELETE: `Iot_Simulator_clean/simulator_core/mock_personas.py`

## Notes

### HealthProfile catalog initial content (Phase 4 starter set)

Em propose 5 profiles (anh adjust neu can):

| label | display_name | demographics | key conditions | scenario_response example |
|---|---|---|---|---|
| `young_healthy` | "Young Healthy (25y)" | age 20-35, BMI 18-25 | none | tachycardia x0.8 (milder) |
| `elderly_healthy` | "Elderly Healthy (68y)" | age 65-75, BMI 18-27 | none | tachycardia x1.2 |
| `elderly_hypertension` | "Elderly Hypertensive (72y)" | age 65-80, BMI 20-30 | hypertension | tachycardia x1.5, bradycardia x1.3 |
| `elderly_cardiac_risk` | "Elderly Cardiac Risk (75y)" | age 70-85, BMI 20-30 | hypertension, arrhythmia | tachycardia x2.0, bradycardia x1.8 |
| `elderly_diabetic` | "Elderly Diabetic (70y)" | age 65-80, BMI 25-35 | diabetes, hypertension | hypoglycemia x1.5, tachycardia x1.3 |

Sleep profile mapping:
- `young_healthy`, `elderly_healthy` -> `good_sleep_night`
- `elderly_hypertension` -> `fragmented_sleep`
- `elderly_cardiac_risk`, `elderly_diabetic` -> `sleep_apnea_mild` hoac `sleep_apnea_severe` (Anh decide).

### Why sleep fold sub-catalog khong fold demographics

Demographics = continuous parameters (age, weight) - flat merge vao dict OK.
Sleep conditions = discrete categories (good / fragmented / apnea_mild / apnea_severe) - reference by key natural hon inline copy.

### What about FALL variants?

`_FALL_VARIANT_TO_PERSONA` mapping unrelated to HealthProfile. Variant = fall type (slip / bed / confirmed), khong phai patient template. Separate concept, dung rieng. ADR-014 khong touch variant mapping.

### What if future need comorbidity interactions?

Current `conditions: list[str]` la flat tags. Neu tuong lai can "diabetes + hypertension combined scenario" (interaction), co the add `condition_interactions: dict[tuple, multiplier]` field. YAGNI hien tai.

### Breaking change assessment

- FE `PersonaConfig` type: ADD optional field -> non-breaking.
- API `PersonaConfig` pydantic: ADD optional field -> non-breaking.
- `sleep_service._select_session_for_scenario()`: change lookup method -> contained within service, no API surface change.
- `MOCK_PERSONAS` delete: grep showed 0 import uses + comment confirmed manual/future-only -> safe delete.

No runtime breaking change expected. Migration path clean.
