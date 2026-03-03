CRITICAL INSTRUCTION: You MUST generate the final report in Vietnamese, exactly matching the markdown template below. Do not generate English text in the final report. The table headers, structure, and template wording must remain exactly as defined below in Vietnamese.

```markdown
# 🔬 BÁO CÁO ĐÁNH GIÁ CHI TIẾT

## Thông tin chung
- **Chức năng**: [Tên]
- **Module**: [AUTH/DEVICE/MONITORING/EMERGENCY/NOTIFICATION/ANALYSIS/SLEEP/ADMIN/INFRA]
- **Dự án**: [Admin / Mobile / Cả hai]
- **Sprint**: [Sprint N]
- **Trello Card**: [Card name + số]
- **UC Reference**: [UC0XX]
- **Ngày đánh giá**: [ISO date]

---

## 🏆 TỔNG ĐIỂM: XX/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Chức năng đúng yêu cầu | /15 | ... |
| API Design | /10 | ... |
| Architecture & Patterns | /15 | ... |
| Validation & Error Handling | /12 | ... |
| Security | /12 | ... |
| Code Quality | /12 | ... |
| Testing | /12 | ... |
| Documentation | /12 | ... |

---

## 📐 ARCHITECTURE DEEP DIVE

### Clean Architecture Layers (/5)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Route → Controller → Service → Repo separation | ✅/❌ | ... |
| ... | | |

### Design Patterns (/5)
| Pattern | Có? | Đánh giá |
|---------|-----|---------|
| Middleware | ✅/❌ | ... |
| ... | | |

---

## 📂 FILES ĐÁNH GIÁ
| File | Layer | LOC | Đánh giá tóm tắt |
|------|-------|-----|-------------------|
| `path/to/file` | [Controller/Service/Repo] | [N] | [Tóm tắt] |

---

## 📋 TRELLO TASK TRACKING

### Card: [Tên card] (Sprint X)

#### [Role Name]
| # | Checklist Item | Trạng thái | Ghi chú |
|---|---------------|------------|---------|
| 1 | [Item] | ✅/⚠️/❌/🔄 | [Chi tiết] |

#### Acceptance Criteria
| # | Criteria | Trạng thái | Ghi chú |
|---|---------|------------|---------|
| 1 | [Criteria] | ✅/❌ | [Chi tiết] |

---

## 📊 SRS COMPLIANCE

### Main Flow
| Bước | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|
| 1 | [Mô tả] | [Thực tế] | ✅/❌ |

### Alternative Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|

### Exception Flows
| Flow | SRS Yêu cầu | Implementation | Match? |
|------|-------------|---------------|--------|

---

## ✅ ƯU ĐIỂM
1. [Ưu điểm + file/line reference]

## ❌ NHƯỢC ĐIỂM
1. [Nhược điểm + lý do + file/line reference]

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. **[HIGH]** [Mô tả] → Cách sửa: [suggestion]
2. **[MEDIUM]** [Mô tả] → Cách sửa: [suggestion]
3. **[LOW]** [Mô tả] → Cách sửa: [suggestion]

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. [Code/pattern cần loại bỏ + lý do]

## ⚠️ SAI LỆCH VỚI TRELLO / SRS
| Source | Mô tả sai lệch | Mức độ | Đề xuất |
|--------|----------------|--------|---------|
| Trello Card X | [Mô tả] | 🔴/🟡/🟢 | [Đề xuất] |

## 💡 CODE SNIPPETS ĐÁNG CHÚ Ý

### ✅ Code tốt:
\```[language]
// file: path/to/file, line X-Y
[code snippet]
\```

### ❌ Code cần sửa:
\```[language]
// HIỆN TẠI:
[current code]
// NÊN SỬA THÀNH:
[suggested code]
\```

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
| # | Action | Owner | Priority | Sprint |
|---|--------|-------|----------|--------|
| 1 | [Mô tả] | [Role] | HIGH/MED/LOW | [Sprint N] |
```
