# Audit: M05 — Scripts (dev tooling, skim)

**Module:** `healthguard-model-api/scripts/`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 4 (model-api)
**Mode:** SKIM (P2 priority — not production code)

## Scope

7 scripts, ~600 LoC total:

| File | Role |
|---|---|
| `build_fall_sample_cases.py` | Generate IMU windows for fall sample-cases JSON |
| `build_health_sample_cases.py` | Generate vital records for health sample-cases JSON |
| `build_sleep_sample_cases.py` | Generate sleep sessions for sleep sample-cases JSON |
| `build_predict_batch_samples.py` | Generate batch sample inputs |
| `build_runtime_samples.py` | Aggregate runtime sample data |
| `inspect_modelok.py` | Verify joblib bundle integrity |
| `write_per_case_json.py` | Write per-case JSON files |

**Audit method:** Skim only — file listing + path inspection from inventory. Not scanned line-by-line per Phase 1 P2 mode.

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Likely correct (scripts work for current sample generation) but no automated test. |
| Readability | 2/3 | Naming consistent (`build_*_sample_cases`). Need scan để verify docstrings + CLI args. |
| Architecture | 2/3 | Separated per domain. May share generation helpers — verify Phase 3. |
| Security | 3/3 | No external input (dev-only). No secrets needed. |
| Performance | 3/3 | Run on-demand, not on hot path. |
| **Total** | **12/15** | Band: **🟡 Healthy** (skim — best estimate) |

## Findings (limited — skim mode)

### Correctness (2/3)

- ✓ Scripts produce JSON consumed by router `/sample-cases` + `/sample-input` endpoints
- ✓ M01 routers reference these scripts in error messages ("Run: python scripts/build_fall_sample_cases.py") → script names verified
- ⚠️ No automated test verifies output JSON shape matches consumer expectations
- ⚠️ Sample generation deterministic? Re-running may produce different outputs (random seed not verified)

### Readability (2/3)

- ✓ Naming convention consistent (`build_*_sample_cases.py`)
- ⚠️ Em chưa scan content — verify Phase 3 docstrings, CLI args via argparse, exit codes

### Architecture (2/3)

- ✓ One script per domain (fall/health/sleep) — clean separation
- ✓ Plus `inspect_modelok.py` as cross-cutting tool
- ⚠️ May duplicate generation helpers — extract to `scripts/_common.py` if found duplication

### Security (3/3)

- ✓ Scripts are local dev tooling — no exposed endpoint
- ✓ No user input (scripts read seed config or embedded data)
- ✓ Output to local disk — no secret leak risk
- ✓ Not in production deployment path

### Performance (3/3)

- ✓ Run manually on-demand → no production performance impact
- ✓ Output cached in `app/data/runtime/` → routers read fast from disk

## Recommended actions (Phase 4)

- [ ] **P3:** Add `--seed` arg to sample generation scripts để reproducible runs (defer unless Phase 4 needs it)
- [ ] **P3:** Add 1 unit test verifying output JSON matches consumer schema
- [ ] **P3:** Extract shared generation helpers if Phase 3 finds duplication

## Out of scope (defer Phase 3 if needed)

- Per-script detail review (P2 priority, low ROI cho macro audit)
- Generated sample data quality (cover realistic distribution?)
- Script orchestration (Makefile vs npm-style task runner)
- CI integration (auto-regenerate samples on model artifact change)

## Cross-references

- Phase -1.B: scripts referenced in `routers/*.py` error detail messages
- Phase 0: Module M05 in [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)
- Note: M05 is **P2** — Phase 1 macro skim is acceptable depth
