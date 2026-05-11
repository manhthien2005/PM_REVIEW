# ADR-002: Centralize bug log + ADR trong PM_REVIEW

**Status:** 🟢 Accepted
**Date:** 2026-05-11
**Decision-maker:** ThienPDM (solo)
**Tags:** [workspace, anti-loop, cross-session, bug-tracking]

## Context

Phase 4 audit phát hiện workflow hiện tại thiếu **anti-loop mechanism** — AI session không nhớ attempts của session trước, dẫn đến đề xuất lại approach đã fail ("vòng lặp chết"). Cần:

1. **Bug fix-attempt log** — track mọi attempt + reason fail.
2. **Decision log (ADR-lite)** — track architectural decisions cross-session.

Anh có thể work parallel trên nhiều module/repo khác nhau (không xung đột scope). Yêu cầu: các session đọc được thay đổi của nhau.

Forces:
- Solo dev, AI sessions là main "team review" của anh.
- Cross-session continuity critical (same bug có thể span 3-5 sessions trong tuần).
- Multi-repo parallel work — bug có thể cross-repo.

## Decision

**Chose:** Option A — Centralized trong PM_REVIEW/BUGS/ và PM_REVIEW/ADR/.

**Why:**
- Cross-session continuity yêu cầu single source of truth — session A (HealthGuard) và session B (health_system) đọc cùng 1 file.
- ID convention `<REPO-PREFIX>-<NUM>` đủ rõ để biết bug thuộc repo nào, không cần tách folder.
- INDEX.md là GPS — search 1 nơi tìm thấy tất cả.
- ADR là project-wide concept, không belong 1 repo.

## Options considered

### Option A (chosen): Centralized in PM_REVIEW

**Description:**
- Bugs: `PM_REVIEW/BUGS/<REPO-PREFIX>-<NUM>.md` + `PM_REVIEW/BUGS/INDEX.md`
- ADR: `PM_REVIEW/ADR/<NNN>-<title>.md` + `PM_REVIEW/ADR/INDEX.md`

**Pros:**
- Single source — session bất kỳ đọc được full project history
- Cross-repo bug log centrally accessible
- ADR project-wide, không thuộc 1 repo
- INDEX search nhanh
- Match Option A của ADR-001 (PM_REVIEW là meta repo)

**Cons:**
- Không trực quan trong code repo (vd HealthGuard dev không thấy bug log trong HealthGuard/docs/)
- Cross-repo bug phải log 1 chỗ (nhưng đó là điểm mạnh)

**Effort:** ~1h (tạo INDEX, template, 2 initial ADR)

### Option B (rejected): Per-repo trong docs/

**Description:**
- `<repo>/docs/bugs/<id>.md` cho bug riêng stack
- `<repo>/docs/adr/<num>.md` cho decision riêng repo

**Pros:**
- Trực quan với OSS convention
- Bug context gần code

**Cons:**
- Cross-repo bug phải log 2 chỗ → drift
- Session A (work in HealthGuard) không tự thấy bug trong health_system
- ADR project-wide không tự nhiên thuộc 1 repo nào

**Why rejected:** Anh's workflow là multi-module parallel — per-repo log fragments memory, conflict yêu cầu "session làm việc đọc được thay đổi của nhau".

### Option C (rejected): Hybrid (per-repo + central PM_REVIEW)

**Description:**
- Per-repo bug log cho bug riêng stack
- PM_REVIEW central cho cross-repo bug + ADR

**Pros:**
- Best of both worlds (in theory)

**Cons:**
- Anh phải nhớ "bug này thuộc category nào" mỗi lần log
- AI session phải check 2 chỗ
- Drift khi bug 1-repo phát hiện thực ra cross-repo

**Why rejected:** Cognitive overhead cho solo dev. Centralized đơn giản hơn, ID prefix đủ rõ.

## Consequences

### Positive
- Cross-session continuity — single source for bug history + decisions.
- AI rule `60-context-continuity.md` reference 1 nơi → AI đọc đúng cho mọi session.
- ADR INDEX search by tag → tìm decision nhanh.
- Bug log INDEX search by repo + status → triage rõ.

### Negative / Trade-offs accepted
- PM_REVIEW git size tăng (acceptable, < 1MB cho 100 bugs).
- Khi work in 1 repo, dev phải mở PM_REVIEW workspace để đọc bug log (mitigated bằng absolute path search trong skill `bug-log`).

### Follow-up actions required
- [x] Tạo `PM_REVIEW/BUGS/INDEX.md` + `_TEMPLATE.md` (done)
- [x] Tạo `PM_REVIEW/ADR/INDEX.md` + `_TEMPLATE.md` (done)
- [x] Skill `bug-log/SKILL.md` (done)
- [x] Skill `decision-log/SKILL.md` (done)
- [x] Rule `60-context-continuity.md` (done)
- [x] Workflow `/debug`, `/fix-issue`, `/build` integrate anti-loop check (done in M2)
- [ ] Workflow `/stuck` (M4)
- [ ] Sync template → 5 repos (M6)

## Reverse decision triggers

Reconsider khi:
- Bug count > 500 → có thể split per-repo cho perf.
- Có team member khác (không còn solo) → có thể per-repo cho ownership clarity.
- ADR INDEX > 100 entries → có thể split by domain (security/, mobile/, backend/).

## Related

- ADR: ADR-001 (workspace tooling host — set precedent for centralizing in PM_REVIEW)
- Skill: `bug-log`, `decision-log`
- Rule: `60-context-continuity.md`
- Workflow: `/debug`, `/fix-issue`, `/stuck` (M4)
- Phase: Phase 4 M3 (anti-loop infrastructure)

## Notes

Anh's exact wording (2026-05-11):
> "Anh có thể làm việc trên nhiều module khác nhau (nếu chúng không ảnh hưởng đến nhau, có phạm vi tác động rõ ràng). Vậy nên để tối ưu hoá thời gian và năng lực làm việc nhất, em hãy chọn cách tối uưu cho vấn đề này, đảm bảo ta có thể làm tốt và các session làm việc đọc được các thay đổi của nhau."

→ Lý do chính chọn centralized: yêu cầu cross-session continuity rõ ràng.
