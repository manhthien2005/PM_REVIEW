# ADR-<NNN>: <Short title>

**Status:** Proposed / Accepted / Superseded by ADR-<NNN> / Deprecated
**Date:** YYYY-MM-DD
**Decision-maker:** ThienPDM (solo)
**Tags:** [tag1, tag2, ...]

## Context

Mô tả bối cảnh:
- Vấn đề gì cần quyết định?
- Forces nào đang tác động (technical, time, skill, external)?
- Constraints không thể đổi?
- Reference UC/Spec nếu có: UC<XXX>, `<repo>/docs/specs/<file>.md`.

## Decision

**Chose:** <Option name>

**Why:** 1-3 đoạn — lý do thực sự, không chung chung. Quantify khi có thể.

❌ Bad: "Option A is better"
✅ Good: "Option A vì giảm 60% boilerplate (verified bằng prototype 2 file), trade-off là phải learn thêm Riverpod codegen — ROI tốt cho 50+ providers dự kiến"

## Options considered

### Option A (chosen): <name>

**Description:** <ngắn gọn>

**Pros:**
- ...

**Cons:**
- ...

**Effort:** S / M / L (cụ thể nếu có thể: ~Xh)

### Option B (rejected): <name>

**Description:** ...

**Pros:**
- ...

**Cons:**
- ...

**Why rejected:** <lý do cụ thể, không vague>

### Option C (rejected, if any): <name>

(repeat structure)

---

## Consequences

### Positive

- ...

### Negative / Trade-offs accepted

- ...
- _(Em accept rằng <X> sẽ phải làm thêm/sau, đổi lại <Y> immediate)_

### Follow-up actions required

- [ ] <action 1 — concrete>
- [ ] <action 2>
- [ ] <action 3>

## Reverse decision triggers

Conditions để reconsider quyết định này:

- Nếu <X> changes → reconsider (vd: "team grows beyond solo dev → reconsider workspace hosting").
- Nếu <Y> trở nên unacceptable (vd: "audit log size > 10GB → split table").
- Nếu <Z> emerges (vd: "Riverpod 3 ships breaking changes → re-evaluate state mgmt").

## Related

- UC: UC<XXX> (nếu có)
- ADR: supersedes ADR-<NNN> / superseded by ADR-<NNN>
- Bug: triggered by <BUG-ID> (nếu decision này phát sinh từ bug fix)
- Code: enforces in `<file>:<line range>`
- Spec: `<repo>/docs/specs/<file>.md`

## Notes

_(Free-form: alternatives đã suggest nhưng chưa explore; questions chưa answer; references đã đọc)_
