---
name: project-overview-assessment
description: "High-level assessment for the HealthGuard project. Triggers on keywords: project structure, project overview, tong quan, review architecture, assess structure. Uses MASTER_INDEX to optimize context."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-04"
---

# 🔍 Skill: Project Overview Assessment (TongQuan)

## Purpose

Evaluate the **holistic structure and progress** of the HealthGuard project to ensure it aligns with the SRS, follows industry-standard architecture, and stays on track with JIRA sprint tasks (Epics/Stories).

## When to Use This Skill

Automatically activates when the user wants to:
- Evaluate the overall project or a specific large section
- Verify if the existing codebase structure reflects the SRS correctly
- Review progress against JIRA sprints (Epics & Stories)
- Report the project status to stakeholders

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to optimize token limits and prevent getting lost in context.

### Tier 1: Navigation (ALWAYS read first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** — The overall GPS map of the project.
2. Determine the assessment scope (Admin / Mobile / or both).

### Tier 2: Prepare Integrated Skills
3. **CRITICAL:** Before evaluating, read the internal bundled skills under `skills/` to inherit their high-level structural rules:
   - `skills/architect-review/SKILL.md`
   - `skills/software-architecture/SKILL.md`
   - `skills/backend-architect/SKILL.md`
   - `skills/architecture-patterns/SKILL.md`

### Tier 3: Structure (Read based on scope)
4. **Read the corresponding `Project_Structure.md`** (Admin or Mobile).

### Tier 4: Summaries (Read ONLY relevant summaries)
5. **Read related summary files** from the `summaries/` folder.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS document — use the summary files instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read the full JIRA CSV — use `PM_REVIEW/Resources/TASK/JIRA/README.md` (JIRA Index) to quickly locate Epics/Stories, then read only relevant rows from the CSV.
- ❌ **DO NOT** read the entire source code — only scan the folder structure for overviews.

## Evaluation Process (Progressive Deepening)

**Step 1:** Complete the Context Loading Protocol.
**Step 2:** Source Code Scan (Surface Level). Browse folder structure without reading file contents, comparing against `Project_Structure.md`.
**Step 3:** Evaluate against 6 Criteria: SRS Compliance, Architecture, Consistency, Progress vs JIRA, Code Quality, Security. **READ `references/evaluation-criteria.md` for specific check details.**
**Step 4:** Cross-check with JIRA Stories from the JIRA Index.

## 📁 Output File Protocol (MANDATORY)

### File Naming Convention
The review file MUST follow this naming pattern:
```
TONGQUAN_{DỰ_ÁN}_review.md
```
- **DỰ_ÁN**: Tên dự án, UPPERCASE (ví dụ: `ADMIN`, `MOBILE`)
- Nếu đánh giá cả hai dự án → tạo 2 file riêng biệt hoặc `TONGQUAN_ALL_review.md`

### Output Location
- Admin project → `PM_REVIEW/REVIEW_ADMIN/TONGQUAN_ADMIN_review.md`
- Mobile project → `PM_REVIEW/REVIEW_MOBILE/TONGQUAN_MOBILE_review.md`

### Examples
| User yêu cầu                     | File output                               |
| -------------------------------- | ----------------------------------------- |
| "Đánh giá tổng quan dự án Admin" | `REVIEW_ADMIN/TONGQUAN_ADMIN_review.md`   |
| "Đánh giá tổng quan Mobile"      | `REVIEW_MOBILE/TONGQUAN_MOBILE_review.md` |

## 🔄 Re-review Protocol (Khi review lần 2+)

> [!IMPORTANT]
> Trước khi bắt đầu review, AI PHẢI kiểm tra xem đã có file review cũ hay chưa. Nếu có → thực hiện so sánh.

### Bước 1: Tìm file review cũ
1. Xác định tên file theo **Output File Protocol** ở trên.
2. Kiểm tra file đó có tồn tại tại `REVIEW_ADMIN/` hoặc `REVIEW_MOBILE/` hay không.

### Bước 2: Đọc file review cũ (nếu tồn tại)
3. Đọc file review cũ và trích xuất:
   - **Điểm cũ**: Tổng điểm + điểm từng tiêu chí.
   - **Nhược điểm cũ**: Danh sách tất cả nhược điểm.
   - **Khuyến nghị cũ**: Danh sách khuyến nghị hành động.
   - **Ngày đánh giá cũ**: Từ phần "Thông tin chung".
   - **Lần đánh giá cũ**: Từ phần "Thông tin chung" (nếu có).

### Bước 3: Thực hiện review mới bình thường
4. Thực hiện review theo Evaluation Process ở trên (Step 1–4).

### Bước 4: So sánh & đánh giá thay đổi
5. So sánh kết quả mới với dữ liệu trích xuất từ file cũ:
   - Điểm tăng/giảm từng tiêu chí.
   - Nhược điểm nào đã được **khắc phục** (có trong cũ, không còn trong mới).
   - Nhược điểm nào **vẫn tồn tại** (có trong cả cũ và mới).
   - Nhược điểm nào **mới phát sinh** (không có trong cũ, xuất hiện trong mới).

### Bước 5: Ghi đè file cũ
6. **GHI ĐÈ** file review cũ bằng báo cáo mới hoàn chỉnh, bao gồm section "🔄 SO SÁNH VỚI LẦN ĐÁNH GIÁ TRƯỚC" (theo template `references/report-template.md`).
7. Tăng số **Lần đánh giá** lên 1.

### ⚠️ Lưu ý
- Nếu **KHÔNG tìm thấy file cũ** → đây là lần review đầu tiên → KHÔNG thêm section so sánh, set `Lần đánh giá: 1`.
- Nếu **CÓ file cũ** → BẮT BUỘC phải thêm section so sánh, tăng `Lần đánh giá`.

## Output Formatting

**MANDATORY:** You must use the Vietnamese markdown reporting template located at `references/report-template.md`. You must not deviate from this template.

## Reference Documents

| Name             | Path                                                | When to read                                   |
| ---------------- | --------------------------------------------------- | ---------------------------------------------- |
| **MASTER INDEX** | `PM_REVIEW/MASTER_INDEX.md`                         | **ALWAYS**                                     |
| Admin Structure  | `PM_REVIEW/REVIEW_ADMIN/Project_Structure.md`       | When reviewing Admin                           |
| Mobile Structure | `PM_REVIEW/REVIEW_MOBILE/Project_Structure.md`      | When reviewing Mobile                          |
| Admin Summaries  | `PM_REVIEW/REVIEW_ADMIN/summaries/*.md`             | Based on module                                |
| Mobile Summaries | `PM_REVIEW/REVIEW_MOBILE/summaries/*.md`            | Based on module                                |
| DB Summary       | `PM_REVIEW/SQL SCRIPTS/README.md`                   | When reviewing database design                 |
| Use Cases (UC)   | `PM_REVIEW/Resources/UC/**/*.md`                    | When explicit detail is missing from summaries |
| **JIRA Index**   | `PM_REVIEW/Resources/TASK/JIRA/README.md`           | **ALWAYS** — Quick lookup for Epics/Stories    |
| JIRA Full CSV    | `PM_REVIEW/Resources/TASK/JIRA/JIRA_IMPORT_ALL.csv` | Only when need full Story details              |
