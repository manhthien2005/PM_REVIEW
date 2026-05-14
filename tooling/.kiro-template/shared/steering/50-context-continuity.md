---
inclusion: always
---

# Context Continuity — Cross-Session Memory

Em phải đọc context từ session trước để tránh:
- Đề xuất lại approach đã thử fail.
- Hỏi lại quyết định đã chốt.
- Re-implement feature đã có ở repo khác.

## 2 nguồn ngữ cảnh BẮT BUỘC

### 1. Bug Log — `PM_REVIEW/BUGS/`

- **Khi đọc:** Bắt đầu debug/fix-issue, khi anh nói "still broken"/"tried that", khi attempt ≥ 2.
- **Khi update:** Sau mỗi attempt (failed or successful), khi bug resolved.
- **Iron rule:** KHÔNG đề xuất approach đã mark `failed`. Variations chỉ OK khi address documented failure reason.

### 2. Decision Log (ADR) — `PM_REVIEW/ADR/`

- **Khi đọc:** Bắt đầu spec/refactor/cross-repo feature, khi anh hỏi "tại sao chọn X".
- **Khi tạo mới:** Choosing approach A over B, adopting new lib, changing convention, defining cross-repo contract.

## Bug ID format

`<REPO-PREFIX>-<NUM>` (3-digit zero-padded)

| Prefix | Repo |
|---|---|
| HG | HealthGuard |
| HS | health_system |
| IS | Iot_Simulator_clean |
| MA | healthguard-model-api |
| XR | Cross-repo |

## ADR ID format

`<NNN>-<short-kebab-title>` — sequential, system-wide.

## INDEX files

- `PM_REVIEW/BUGS/INDEX.md` — open bugs by status, repo, severity.
- `PM_REVIEW/ADR/INDEX.md` — decisions chronological + by tag.
- Em PHẢI update INDEX khi tạo/resolve bug hoặc tạo/supersede ADR.

## Anti-patterns

- Đề xuất approach đã `failed` trong bug log → STOP, đọc lại lý do.
- Re-debate decision đã có ADR `Accepted` → STOP, reference ADR.
- Skip update INDEX → STOP, update.
