# 📋 TEMPLATE TRELLO CARDS - HỆ THỐNG HEALTHGUARD

> **Mục đích**: File này chứa template và danh sách đầy đủ các Trello cards để PM/BA copy vào board Trello, assign đúng người, đúng phần việc.

> **Team**: 7 người
> - 1 PM/BA (kiêm Tester)
> - 2 Dev Admin (1 FE + 1 BE)
> - 2 Dev Mobile (1 FE + 1 BE)
> - 1 Dev AI
> - 1 Tester

---

## 📌 CÁCH SỬ DỤNG TEMPLATE

### 1. **Copy card vào Trello**
- Mỗi section dưới đây = 1 card Trello
- Copy Title, Description, Labels, Checklist vào card tương ứng

### 2. **Assign members**
- Thay `[Admin FE Dev]`, `[Mobile BE Dev]`, v.v. bằng tên thật của team member
- Hoặc dùng generic names nếu chưa có tên cụ thể

### 3. **Labels trong Trello**
Tạo các labels sau trong board:
- **Module**: `Monitoring`, `Emergency`, `Auth`, `Admin`, `Device`, `Analysis`, `Sleep`, `Notification`, `Infra`
- **Role**: `Backend`, `Frontend`, `Mobile`, `AI`, `Test`, `BA`
- **Priority**: `High`, `Medium`, `Low`
- **Sprint**: `Sprint 1`, `Sprint 2`, `Sprint 3`, `Sprint 4`

### 4. **Checklist trong card**
- Mỗi role có checklist riêng
- Tick khi hoàn thành
- Comment nếu có vấn đề

---

## 🎯 TEMPLATE CHUNG CHO 1 CARD

```
TITLE: [Module] UCXXX - Tên Use Case

DESCRIPTION:
---
UC: BA/UC/[Module]/UCXXX_[Name].md
Mục tiêu: [Tóm tắt ngắn mục tiêu UC]
Liên quan: [UC khác nếu có]

LABELS:
- Module: [Monitoring/Emergency/Auth/...]
- Role: [Backend/Frontend/Mobile/AI/Test]
- Priority: [High/Medium/Low]
- Sprint: [Sprint X]

CHECKLIST:

✅ PM/BA ([PM/BA Name])
- [ ] Review UC đã final, không đổi trong sprint
- [ ] Cập nhật mapping UC → API trong API_Design.md (nếu có)
- [ ] Review acceptance criteria với team

✅ Admin FE Dev ([Admin FE Dev])
- [ ] [Task cụ thể cho Admin FE]
- [ ] [Task cụ thể cho Admin FE]

✅ Admin BE Dev ([Admin BE Dev])
- [ ] [Task cụ thể cho Admin BE]
- [ ] [Task cụ thể cho Admin BE]

✅ Mobile FE Dev ([Mobile FE Dev])
- [ ] [Task cụ thể cho Mobile FE]
- [ ] [Task cụ thể cho Mobile FE]

✅ Mobile BE Dev ([Mobile BE Dev])
- [ ] [Task cụ thể cho Mobile BE]
- [ ] [Task cụ thể cho Mobile BE]

✅ AI Dev ([AI Dev])
- [ ] [Task cụ thể cho AI]
- [ ] [Task cụ thể cho AI]

✅ Tester ([Tester Name])
- [ ] Viết test cases dựa trên Main/Alt Flows của UC
- [ ] Test manual trên [Mobile/Web/API]
- [ ] Ghi nhận bug, tạo bug card riêng nếu có

ACCEPTANCE CRITERIA:
- [ ] [Criteria 1]
- [ ] [Criteria 2]
- [ ] [Criteria 3]

NOTES:
- [Ghi chú đặc biệt nếu có]
```

---

## 📅 DANH SÁCH CARDS THEO SPRINT

Xem các file riêng:
- `TRELLO_SPRINT1.md` - Sprint 1: Nền tảng & Auth
- `TRELLO_SPRINT2.md` - Sprint 2: Monitoring Core
- `TRELLO_SPRINT3.md` - Sprint 3: Emergency & Notification
- `TRELLO_SPRINT4.md` - Sprint 4: Risk & AI + Admin + Sleep

---

**Cập nhật lần cuối**: [Ngày]
**Version**: 1.0
