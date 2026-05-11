# Bug PM-001: PM_REVIEW source-of-truth bị stale, không phản ánh implementation hiện tại

**Status:** 🟡 In progress (systemic — track ongoing, not single-fix)
**Repo(s):** PM_REVIEW (impacts: HealthGuard, health_system, Iot_Simulator_clean, healthguard-model-api)
**Module:** Resources/UC, Resources/SRS, SQL SCRIPTS, Resources/TASK/JIRA, REPORT
**Severity:** High (block audit-driven refactor)
**Reporter:** ThienPDM (self)
**Created:** 2026-05-11
**Resolved:** _(open — staged remediation qua Phase -1 → Phase 4)_

## Symptom

PM_REVIEW (canonical doc hub) bị **drift nặng** so với code thực tế ở 4 runtime repos. Cụ thể:

- Một số UC trong `Resources/UC/` không còn match với feature đang chạy trong code
- DB canonical SQL (`SQL SCRIPTS/init_full_setup.sql`) chưa verify đầy đủ với Prisma schema (HealthGuard) + SQLAlchemy models (health_system backend)
- Topology.md viết theo hiểu biết, chưa cross-check với HTTP client / DB query thực tế trong code
- Báo cáo (`REPORT/chuong_*.md`) chứa kiến trúc/CSDL/API design có thể đã bị code đẩy xa
- JIRA Sprint 1-5 backlog có Stories đã đóng nhưng UC/SRS không được update tương ứng

**Hệ quả:**
- Khi audit code so với spec → ra **false positives** (code đúng, spec sai → bị flag là "missing UC")
- ThienPDM đang gặp **vòng lặp fix bug vô tận**: mỗi fix dựa vào hiểu biết spot-check code, không có baseline tin cậy → fix surface, không chạm root cause
- Một vài module ThienPDM "không biết nó đang hoạt động ra sao" — knowledge gap do spec drift đã quá lâu
- Architectural debt accumulate vì không có "đúng/sai" reference để align refactor

## Repro steps

1. Mở 1 UC bất kỳ trong `Resources/UC/`
2. Map UC đó vào module/screen tương ứng trong code
3. So sánh: actor, main flow, business rule, data field
4. **Expected:** UC khớp với code behavior (allow ±5% diff cho minor wording)
5. **Actual:** Diff nhiều hơn 30%, có UC không tồn tại trong code, có feature trong code không có UC

**Repro rate:** Em chưa quantify chính xác — Phase -1 sẽ measure cụ thể % drift.

## Environment

- PM_REVIEW commit: 25b7938 (post-merge audit-driven hardening)
- Runtime repos commit: post chore/workspace-fixes merge (2026-05-11)
- Spec last meaningful update: rải rác Q1 2026 (~3 tháng trước)
- Code velocity: 5 sprints implemented sau khi spec viết

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Drift là **systemic** (không phải 1-2 UC outdated, mà toàn bộ hub) | 🔄 Phase -1 verify |
| H2 | Drift gây ra "vòng lặp bug" do ThienPDM fix dựa stale assumption | 🔄 Phase 1+ confirm |
| H3 | Một số UC chưa bao giờ implement (orphan UC) | 🔄 Phase -1.B (API contract) sẽ surface |
| H4 | Một số feature đang chạy không có UC (orphan feature) | 🔄 Phase -1.B sẽ surface |
| H5 | DB canonical đã được update gần đây (file 10-12 created 11/05/2026) nhưng Prisma/SQLAlchemy có thể không sync | 🔄 Phase -1.A confirm |

### Approach (multi-phase remediation)

Đây không phải bug "fix-once". Approach: **selective rebuild** Tier 1 ngay (Phase -1), Tier 2 incremental qua audit phases.

#### Phase -1 (in progress) — Tier 1 baseline

Goal: rebuild trust-critical specs trước khi macro audit.

- **Phase -1.A — DB canonical diff** — Canonical SQL vs Prisma vs SQLAlchemy matrix
- **Phase -1.B — API contract v1** — Extract từ 5 services + cross-check producer/consumer
- **Phase -1.C — Topology v2** — Verify call graph against actual HTTP/Socket usage

Output: `PM_REVIEW/AUDIT_2026/tier1/`

#### Phase 0 → 4 — Incremental Tier 2 rebuild

UC, SRS, JIRA backlog sẽ được update tự nhiên qua từng Phase 3 deep-dive (mỗi module deep-dive ends với "rebuild UC từ actual behavior") + Phase 4 refactor execution.

Cuối Phase 4: PM_REVIEW đã được rebuild "lazy" mà không cần làm 1 cú lớn.

### Attempts

#### Attempt 1 — 2026-05-11 (Phase -1 kickoff)

**Hypothesis:** H1, H5
**Approach:** Selective rebuild Tier 1 (em viết Phase -1 charter, scope 3 sub-phase A/B/C)
**Files touched:**
- `PM_REVIEW/AUDIT_2026/00_phase_minus_1_charter.md` (this commit)
- `PM_REVIEW/BUGS/PM-001-pm-review-spec-drift.md` (this file)
- `PM_REVIEW/BUGS/INDEX.md` (add PM-001 entry)

**Verification (chưa chạy):**
- Phase -1.A done → output `tier1/db_canonical_diff.md`
- Phase -1.B done → output `tier1/api_contract_v1.md`
- Phase -1.C done → output `tier1/topology_v2.md`

**Result:** ⏳ In progress — Phase -1 đang execute

---

## Resolution

_(Open. Bug PM-001 này sẽ resolve khi:_
1. _Phase -1 done → Tier 1 baseline trust-able_
2. _Phase 4 hoàn thành → toàn bộ UC/SRS đã rebuild incremental, match code_
3. _Anh schedule periodic spec-sync để drift không tích lũy nữa_

_Trong thời gian đó, status giữ 🟡 In progress, không close vội.)_

## Related

- ADR: pending — sau Phase -1 sẽ tạo ADR-005 "spec-as-code workflow" để tránh drift lặp lại
- Workflow: `/sync-spec` (đã exist trong workflows) — phải be enforced sau mỗi UC change
- Skill: `UC_AUDIT`, `doc-gen`, `mobile-agent` — tools cho rebuild
- JIRA: Sprint-6 (planned) sẽ có refactor stories với spec-update component

## Notes

- Bug này là **systemic indicator**, không phải defect. Track trong BUGS/ vì nó block downstream audit work.
- Severity High vì block toàn bộ refactor planning. Sau Phase -1 có thể downgrade Medium nếu Tier 1 đủ trust.
- ThienPDM nhận diện được trước khi em propose, đó là good signal — solo dev awareness của technical debt.
- Không nên panic "rebuild full" — Option B (selective) đã được approve. Tránh gold-plating spec ở phase này.
