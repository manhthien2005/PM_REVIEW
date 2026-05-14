# Audit: MOB-M06 — family (LARGEST: invite + dashboard + linked contact)

**Module:** `health_system/lib/features/family/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim + Full on lib/features/family/<deep_link_routing_files>

## Scope

Feature family — LARGEST mobile module ~45 file ~4,500 LoC. Family member invite + dashboard + linked contact detail + medical info P-4 view.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Family invite flow OK. Permission boundary (member role). Defer per-screen detail. |
| Readability | 2/3 | 45 file phân chia OK theo data/domain/presentation/providers. |
| Architecture | 3/3 | Clean per-feature architecture. Family provider 2 instance. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Permission boundary check service-side. Trừ điểm: deep link route arg validation gap. |
| Performance | 3/3 | Async dashboard fetch. Provider state cache. |
| **Total** | **12/15** | Band: **🟡 Healthy**. |

## Findings

### Security (FullMode trên deep link routing)

- Family member invite flow — verify deep link param sanitization (family ID UUID, invite token signature check).
- Linked contact medical info P-4 — UC verify caregiver `can_view_medical_info` permission. Service-side audit log mandate.
- Resource ownership check — shared resource access enforce BE-side.

### Architecture

- Clean per-feature architecture.
- Family Dashboard Provider + Family Relationship Provider tách concern.
- LinkedContact detail consume schema (BE-M05).

### HS-014 schema duplicate cross-link

- HS-014 `FamilyProfileSnapshot` 2 lần định nghĩa BE-M05. Mobile parser tolerant với 2 shape. Phase 4 BE fix → mobile parser update.

## Positive findings

- Largest feature organized clean.
- 2 provider tách concern.
- Permission boundary integration BE.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P1

- [ ] Mobile parser update sau khi BE fix HS-014.

### P2

- [ ] Defer Phase 3: per-screen UI polish, per-role permission matrix test.

## Out of scope

- Service-side permission enforce — BE-M03.
- Audit log PHI access — BE-M02.
- Per-screen UI — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- BUGS INDEX (reference):
  - [HS-012](../../../BUGS/INDEX.md) — UserRelationship default permission flip (BE-M04).
  - [HS-014](../../../BUGS/INDEX.md) — FamilyProfileSnapshot duplicate (BE-M05).
  - [HS-018](../../../BUGS/INDEX.md) — XSS via deep_link_redirect (BE-M02).
  - [HS-022](../../../BUGS/INDEX.md) — relationship_service silent error swallow (BE-M03).
- ADR INDEX:
  - **ADR-016 proposed** — UserRelationship default permission posture.
- Intent drift (reference only):
  - RELATIONSHIPS.md (Phase 0.5).
- Related audit files:
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md).
  - [`BE_M03_services_audit.md`](./BE_M03_services_audit.md).
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md).
  - [`BE_M05_schemas_audit.md`](./BE_M05_schemas_audit.md).
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
