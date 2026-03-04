---
name: detailed-feature-review
description: "Detailed evaluation of a specific feature in the project. Triggers on keywords: review code, evaluate feature, check implementation, danh giá chi tiết, detailed review. Integrates architecture standards + progressive deepening."
risk: safe
source: custom
date_added: "2026-03-03"
date_updated: "2026-03-04"
---

# 🔬 Skill: Detailed Feature Review (DanhGiaChiTiet)

## Purpose

Conduct a **detailed evaluation** of a specific system feature — analyzing the actual code against industry architecture standards, verifying SRS compliance, checking implementation quality, and cross-referencing JIRA Epics/Stories.

## When to Use This Skill

Automatically activates when the user wants to:
- Review code quality for a specific module
- Verify if a feature complies with the SRS
- Check acceptance criteria execution from a JIRA Story
- Evaluate specific implementation details (e.g., Auth, Monitoring, Emergency)

## ⚡ Context Loading Protocol (MANDATORY)

> [!IMPORTANT]
> The Agent MUST strictly follow this 3-tier loading protocol to optimize token limits and ensure accuracy.

### Tier 1: Navigate (ALWAYS first)
1. **Read `PM_REVIEW/MASTER_INDEX.md`** → Find the corresponding module row.
2. Note down: Sprint, UC refs, summary file path.

### Tier 2: Load Context (Read ONE summary)
3. **Read the corresponding summary file** (e.g.: `summaries/AUTH_summary.md`).
4. **DO NOT read the full SRS, DO NOT read the full JIRA CSV.** Instead, read `PM_REVIEW/Resources/TASK/JIRA/README.md` (JIRA Index) to quickly locate the relevant Epic/Stories.

### Tier 3: Prepare Integrated Skills
5. **CRITICAL:** Before evaluating, read the internal bundled skills under `skills/` to inherit their constraints:
   - `skills/architect-review/SKILL.md`
   - `skills/software-architecture/SKILL.md`
   - `skills/backend-architect/SKILL.md`
   - `skills/architecture-patterns/SKILL.md`
   - `skills/architecture-decision-records/SKILL.md`

### Tier 4: Deep Dive (Progressive — code only)
6. **Scan**: List files in the related folder → verify files exist.
7. **Surface**: Read file outlines (function names, class names, LOC).
8. **Deep**: Read detailed contents ONLY for the files requiring evaluation.

### ⛔ WHAT NOT TO DO
- ❌ **DO NOT** read the full SRS → use the summary instead. If more detail is needed, read the specific Use Case (UC) file in `PM_REVIEW/Resources/UC/`.
- ❌ **DO NOT** read the full JIRA CSV → use `JIRA/README.md` index to find the relevant Epic, then read only the matching Stories in the CSV.
- ❌ **DO NOT** read files unrelated to the module currently under review.
- ❌ **DO NOT** read all source code at once → read file by file selectively.

## Evaluation Process

**Step 1:** Complete the Context Loading Protocol.
**Step 2:** Code Analysis (8 Criteria). **READ `references/evaluation-criteria.md` for the detailed point breakdown and checks.**
**Step 3:** Use JIRA Stories (from JIRA Index → CSV) to cross-check acceptance criteria.
**Step 4:** SRS/Use Case Verification from the summary.

## 📁 Output File Protocol (MANDATORY)

### File Naming Convention
The review file MUST follow this naming pattern:
```
{CHỨC_NĂNG}_{MODULE}_review.md
```
- **CHỨC_NĂNG**: Tên chức năng user yêu cầu review, UPPERCASE, dấu cách → `_` (ví dụ: `AUTH_LOGIN`, `DEVICE_CONNECT`)
- **MODULE**: Tên module từ MASTER_INDEX, UPPERCASE (ví dụ: `AUTH`, `DEVICE`, `MONITORING`)
- Nếu chức năng trùng tên module (review toàn bộ module) → chỉ cần `{MODULE}_review.md`

### Output Location
- Admin project → `PM_REVIEW/REVIEW_ADMIN/{tên_file}`
- Mobile project → `PM_REVIEW/REVIEW_MOBILE/{tên_file}`

### Examples
| User yêu cầu                                             | File output                              |
| -------------------------------------------------------- | ---------------------------------------- |
| "Review chức năng Login, module AUTH, dự án Admin"       | `REVIEW_ADMIN/AUTH_LOGIN_review.md`      |
| "Review module AUTH, dự án Admin"                        | `REVIEW_ADMIN/AUTH_review.md`            |
| "Review chức năng Device Connect, module DEVICE, Mobile" | `REVIEW_MOBILE/DEVICE_CONNECT_review.md` |

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

## After Review: Update MASTER_INDEX
When the review process concludes, you must modify the corresponding module row in `MASTER_INDEX.md`:
- Set `Review Status` → ✅ Done (or accordingly)
- Set `Score` → XX/100
- Set `Last Review` → [Current date]
