CRITICAL INSTRUCTION: You MUST generate the final report in Vietnamese, exactly matching the markdown template below. Do not generate English text in the final report. The table headers, structure, and template wording must remain exactly as defined below in Vietnamese.

```markdown
# 📊 BÁO CÁO ĐÁNH GIÁ TỔNG QUAN

## Thông tin chung
- **Dự án**: [Admin / Mobile]
- **Phạm vi đánh giá**: [Toàn bộ / Module cụ thể]
- **Ngày đánh giá**: [ISO date]
- **Sprint hiện tại**: [Sprint N]

---

## 🏆 TỔNG ĐIỂM: XX/100

| Tiêu chí | Điểm | Ghi chú |
|----------|------|---------|
| Bám sát SRS | /20 | ... |
| Kiến trúc & Cấu trúc | /20 | ... |
| Tính nhất quán | /15 | ... |
| Tiến độ vs Trello | /20 | ... |
| Code Quality | /15 | ... |
| Bảo mật & Best Practices | /10 | ... |

---

## 📐 ARCHITECTURE ASSESSMENT
> Chi tiết tiêu chí #2

### Clean Architecture & Layers (/8)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| Separation of Concerns | ✅/❌ | ... |
| Dependency Direction | ✅/❌ | ... |
| Business logic tách framework | ✅/❌ | ... |
| DB queries không trong controller | ✅/❌ | ... |

### Folder Structure (/6)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| ... | ✅/❌ | ... |

### Design Patterns (/6)
| Kiểm tra | Đạt? | Ghi chú |
|----------|------|---------|
| ... | ✅/❌ | ... |

---

## ✅ ƯU ĐIỂM
1. [Liệt kê ưu điểm nổi bật]

## ❌ NHƯỢC ĐIỂM
1. [Liệt kê nhược điểm cần cải thiện]

## 🔧 ĐIỂM CẦN CẢI THIỆN
1. [Cải thiện cụ thể + mức độ ưu tiên: HIGH/MEDIUM/LOW]

## 🗑️ ĐIỂM CẦN LOẠI BỎ
1. [Code/pattern/dependency cần loại bỏ]

## ⚠️ SAI LỆCH VỚI TRELLO TASKS
> Phần này BẮT BUỘC phải có nếu phát hiện sai lệch

| Trello Card | Sprint | Mô tả sai lệch | Mức độ |
|-------------|--------|----------------|--------|
| [Card name] | [Sprint N] | [Mô tả] | 🔴/🟡/🟢 |

## 📋 KHUYẾN NGHỊ HÀNH ĐỘNG
1. [Action item + Owner + Deadline khuyến nghị]
```
