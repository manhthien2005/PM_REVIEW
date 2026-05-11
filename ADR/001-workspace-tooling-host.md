# ADR-001: Host `.windsurf-template/` trong PM_REVIEW

**Status:** 🟢 Accepted
**Date:** 2026-05-11
**Decision-maker:** ThienPDM (solo)
**Tags:** [workspace, tooling]

## Context

Phase 3 workspace overhaul tạo ra `.windsurf-template/` chứa rules + skills + workflows + hooks dùng chung cho 5 repos VSmartwatch. Câu hỏi: lưu template ở đâu?

Forces:
- Anh là solo dev, không có infra repo riêng.
- Mất máy → mất template = mất 1-2 ngày Phase 3 work.
- Template phải dễ edit + dễ sync.
- Anh có thể work parallel trên nhiều repo trong các session khác nhau.

Constraints:
- Không tạo team workflow phức tạp (anh là solo).
- Không thêm dependency/repo mới khi không cần.
- Sync script phải portable (không hardcode path).

## Decision

**Chose:** Option A — Host trong PM_REVIEW repo dưới `tooling/.windsurf-template/`.

**Why:**
- PM_REVIEW vốn là "meta" repo của project (chứa SRS, UC, JIRA backlog, custom skills) — host workspace tooling logical.
- Version-controlled qua git → mất máy không mất template, có thể clone lại.
- Sync script dùng `$PSScriptRoot` → portable, không hardcode path tuyệt đối.
- Không tạo repo thứ 6, không phức tạp hóa multi-workspace setup của anh.

## Options considered

### Option A (chosen): Trong PM_REVIEW/tooling/

**Description:** Move `.windsurf-template/` từ `d:\DoAn2\VSmartwatch\` (loose folder) vào `PM_REVIEW/tooling/.windsurf-template/`.

**Pros:**
- Version-controlled (git)
- Cùng nơi với SKILLS gốc + docs + JIRA → đồng bộ
- Không tạo repo mới
- Sync script portable với `$PSScriptRoot`

**Cons:**
- PM_REVIEW git tree lớn hơn (~150 file thêm — chấp nhận được)
- Skill source duplicate với deployed `.windsurf/skills/` (mỗi sync regenerate)

**Effort:** ~30 phút (move + update sync.ps1 + update README)

### Option B (rejected): Repo riêng `vsmartwatch-workspace-tooling`

**Description:** Tạo repo thứ 6 chỉ chứa template + sync script.

**Pros:**
- Clean separation tooling vs project content
- Có thể share với external team trong tương lai

**Cons:**
- Tạo workspace thứ 6 anh phải nhớ
- Anh là solo dev → over-engineering
- Cross-reference giữa tooling repo và project context (PM_REVIEW) phức tạp

**Why rejected:** Solo dev không cần level tách biệt này.

### Option C (rejected): Loose folder + manual zip backup

**Description:** Giữ nguyên ở `d:\DoAn2\VSmartwatch\.windsurf-template/`, anh tự zip + onedrive định kỳ.

**Pros:**
- Đơn giản nhất, không động git

**Cons:**
- Mất nếu quên backup
- Không có history khi sửa template
- Không AI session/agent đọc được

**Why rejected:** Risk loss > simplicity benefit.

## Consequences

### Positive
- Template sống cùng project — sync flow rõ ràng.
- Sync script portable, anh chạy từ bất kỳ workspace nào với absolute path.
- Git history cho mọi template change.

### Negative / Trade-offs accepted
- PM_REVIEW git size +5MB (acceptable).
- Mỗi sync overwrite `.windsurf/` của repos → cần discipline: edit template TRƯỚC, sync SAU; KHÔNG edit `.windsurf/` trực tiếp.

### Follow-up actions required
- [x] Create `PM_REVIEW/tooling/.windsurf-template/` (done 2026-05-11)
- [x] Update `sync.ps1` to use `$PSScriptRoot` (done)
- [x] Update README to document new location (done)
- [x] Commit + push to PM_REVIEW (done — commit `600a312`)
- [ ] (future) When anh có team → reconsider repo separation

## Reverse decision triggers

Reconsider khi:
- Anh tuyển dev khác vào project → có thể tách thành infra repo cho clean ownership.
- PM_REVIEW git size > 100MB → split tooling out.
- Template content drift quá xa khỏi project content → cleaner separation needed.

## Related

- Code: `PM_REVIEW/tooling/.windsurf-template/sync.ps1`
- Commit: PM_REVIEW@600a312
- Workflow Phase: Phase 3 (workspace overhaul)
- ADR: led to ADR-002 (bug log + ADR location follow-up decision)

## Notes

Em đã consider Option C trong session ban đầu, anh chọn Option A. Quyết định pragmatic — solo dev không cần tách biệt cấp enterprise.
