# Audit: MOB-M12 — home + profile + onboarding

**Module:** `health_system/lib/features/{home, profile, onboarding}/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim + Full on lib/features/profile/<profile_screen>

## Scope

Feature home + profile + onboarding combined. 14 + 11 + 1 = 26 file ~2,000 LoC. Profile PHI display sensitive — FullMode trên profile screen.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Home dashboard display flow OK. Profile R/W flow consume `validate_age` shared. Onboarding wizard skip logic. |
| Readability | 2/3 | Provider docstring partial. |
| Architecture | 3/3 | Clean per-feature architecture. ProfileProvider + HomeDashboardProvider tách concern. |
| Security | 2/3 | KHÔNG hit anti-pattern. Profile PHI display — verify masking + clear on logout. UC P-4 caregiver view audit log mandate. |
| Performance | 3/3 | Async dashboard fetch. Provider state cache. |
| **Total** | **12/15** | Band: **🟡 Healthy**. |

## Findings

### Security (FullMode trên profile PHI display)

- Profile PHI display: medications, allergies, medical_conditions, blood_type, height_cm, weight_kg, date_of_birth. Verify mobile-side masking + clear on logout.
- UC P-4: caregiver xem profile patient → audit log mandate.
- Edit flow validation tại boundary — schema BE-M05 consume.
- Avatar upload Supabase (ADR-009) — verify URL signing + access control.

### Architecture

- Clean per-feature architecture.
- ProfileProvider + HomeDashboardProvider tách concern.
- Onboarding wizard separate flow.

## Positive findings

- `validate_age` shared utility consume từ utils.
- Avatar storage Supabase per ADR-009.
- Clean per-feature separation.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P1

- [ ] Profile PHI access audit log integration verify (cross-link BE-M03 P1).

### P2

- [ ] Local cache encryption verify cho profile PHI display.
- [ ] Defer Phase 3: per-onboarding-step widget test.

## Out of scope

- Service-side audit log — BE-M02 + BE-M03.
- Avatar upload Supabase config detail — Phase 3.
- Per-screen widget test — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-017](../../../BUGS/INDEX.md) — PatientInfo.date_of_birth str (BE-M05).
- ADR INDEX:
  - [ADR-009](../../../ADR/INDEX.md) — Avatar storage Supabase.
- Intent drift (reference only):
  - PROFILE.md (Phase 0.5).
  - SETTINGS.md (Phase 0.5).
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md).
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md).
  - [`BE_M05_schemas_audit.md`](./BE_M05_schemas_audit.md).
  - [`BE_M09_utils_audit.md`](./BE_M09_utils_audit.md).
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- UC: PM_REVIEW/Resources/UC/.
