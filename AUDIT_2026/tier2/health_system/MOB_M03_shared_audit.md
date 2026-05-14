# Audit: MOB-M03 — shared (widgets + models + presentation)

**Module:** `health_system/lib/shared/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 3 — health_system mobile
**Depth mode:** Skim

## Scope

Module shared chứa cross-feature widget + model + presentation utilities. 3 sub-folder: `models/`, `presentation/`, `widgets/`. ~2,000 LoC est. SkimMode focus Architecture + Security.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Shared widget reusable. Model class minimal logic. Defer per-widget detail. |
| Readability | 3/3 | Folder structure clear (widgets/models/presentation separation). |
| Architecture | 2/3 | No circular dep into features/. Generic widget thiếu Flutter golden test fixture. |
| Security | 3/3 | Shared layer không touching auth/PHI/network. Không hit anti-pattern. |
| Performance | 3/3 | Stateless widget pattern, `const` constructor potential. |
| **Total** | **13/15** | Band: **🟢 Mature** — minimal scope, clean separation. |

## Findings

### Architecture

- Shared layer compliance steering "feature A không import feature B internals" — shared chỉ depend `core/`, không feature.
- Widget composition pattern Flutter idiomatic.

### Security

- Không touch auth/PHI/network → no anti-pattern surface.
- Input sanitization N/A — Flutter render text safe by default.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P2

- [ ] **Golden test fixture** cho shared widget visual regression.
- [ ] **`const` constructor** audit cho stateless widget — perf optimization.
- [ ] **Defer Phase 3**: widget snapshot test, per-util unit test.

## Out of scope

- Per-widget visual regression — Phase 3.
- Per-util unit test coverage — Phase 3.

## Cross-references

- BUGS INDEX (new): Không phát hiện bug mới.
- ADR INDEX: Không khớp ADR.
- Intent drift: Không khớp drift ID.
- Related audit files:
  - [`MOB_M01_bootstrap_audit.md`](./MOB_M01_bootstrap_audit.md) — `AppLoadingScreen` từ `shared/widgets/` consumer.
- Preflight: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework: [`00_audit_framework.md`](../../00_audit_framework.md) v1
