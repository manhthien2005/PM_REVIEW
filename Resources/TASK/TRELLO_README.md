# 📋 HƯỚNG DẪN SỬ DỤNG TRELLO CARDS

> **Mục đích**: File này hướng dẫn PM/BA cách sử dụng các file Trello cards template để setup board Trello cho dự án HealthGuard.

---

## 📁 CẤU TRÚC FILES

```
BA/
├── TRELLO_CARDS_TEMPLATE.md      # Template chung + hướng dẫn
├── TRELLO_SPRINT1.md             # Cards cho Sprint 1: Nền tảng & Auth
├── TRELLO_SPRINT2.md             # Cards cho Sprint 2: Monitoring Core
├── TRELLO_SPRINT3.md             # Cards cho Sprint 3: Emergency & Notification
├── TRELLO_SPRINT4.md             # Cards cho Sprint 4: Risk & AI + Admin + Sleep
└── TRELLO_README.md              # File này
```

---

## 🎯 TEAM STRUCTURE

**7 người**:
- **1 PM/BA** (kiêm Tester) - [PM/BA Name]
- **2 Dev Admin** (1 FE + 1 BE) - [Admin FE Dev], [Admin BE Dev]
- **2 Dev Mobile** (1 FE + 1 BE) - [Mobile FE Dev], [Mobile BE Dev]
- **1 Dev AI** - [AI Dev]
- **1 Tester** - [Tester Name]

---

## 📝 CÁCH SỬ DỤNG

### Bước 1: Setup Trello Board

1. Tạo board mới: **"Đồ Án 2 - HealthGuard"**
2. Tạo các **Lists**:
   - `BACKLOG`
   - `TO DO`
   - `IN PROGRESS`
   - `REVIEW`
   - `DONE`
3. Tạo các **Labels**:
   - **Module**: `Monitoring`, `Emergency`, `Auth`, `Admin`, `Device`, `Analysis`, `Sleep`, `Notification`, `Infra`
   - **Role**: `Backend`, `Frontend`, `Mobile`, `AI`, `Test`, `BA`
   - **Priority**: `High`, `Medium`, `Low`
   - **Sprint**: `Sprint 1`, `Sprint 2`, `Sprint 3`, `Sprint 4`

### Bước 2: Copy Cards vào Trello

1. Mở file `TRELLO_SPRINT1.md` (hoặc Sprint 2, 3, 4)
2. Với mỗi **CARD** trong file:
   - Tạo card mới trong Trello
   - Copy **TITLE** → Card title
   - Copy **DESCRIPTION** → Card description
   - Copy **LABELS** → Add labels tương ứng
   - Copy **CHECKLIST** → Add checklist items (mỗi role = 1 checklist section)
   - **Assign members** cho từng checklist item

### Bước 3: Customize cho Team

1. Thay thế generic names:
   - `[PM/BA Name]` → Tên thật của bạn
   - `[Admin FE Dev]` → Tên Admin Frontend Dev
   - `[Admin BE Dev]` → Tên Admin Backend Dev
   - `[Mobile FE Dev]` → Tên Mobile Frontend Dev
   - `[Mobile BE Dev]` → Tên Mobile Backend Dev
   - `[AI Dev]` → Tên AI Dev
   - `[Tester Name]` → Tên Tester

2. Điều chỉnh checklist nếu cần:
   - Thêm/bớt task con tùy theo team capacity
   - Thêm acceptance criteria cụ thể hơn

### Bước 4: Sprint Planning

1. **Sprint 1**: Copy tất cả cards từ `TRELLO_SPRINT1.md` vào `TO DO`
2. **Sprint 2**: Copy cards từ `TRELLO_SPRINT2.md` vào `BACKLOG`, sau đó move sang `TO DO` khi bắt đầu Sprint 2
3. Tương tự cho Sprint 3, 4

---

## 📊 TỔNG QUAN CARDS THEO SPRINT

### Sprint 1: Nền tảng & Auth (6 cards)
- [Infra] Setup Database & TimescaleDB
- [Infra] Setup Backend FastAPI Skeleton
- [Auth] UC001 - Login
- [Auth] UC002 - Register
- [Auth] UC003 - Forgot Password
- [Auth] UC004 - Change Password

**Estimated**: ~10-14 days

### Sprint 2: Monitoring Core (6 cards)
- [Device] UC040 - Connect Device
- [Device] UC042 - View Device Status
- [Infra] Data Ingestion Service (MQTT/HTTP)
- [Monitoring] UC006 - View Health Metrics
- [Monitoring] UC007 - View Health Metrics Detail
- [Monitoring] UC008 - View Health History

**Estimated**: ~9-14 days

### Sprint 3: Emergency & Notification (6 cards)
- [Notification] UC030 - Configure Emergency Contacts
- [Emergency] UC010 - Confirm After Fall Alert
- [Emergency] UC014 - Send Manual SOS
- [Emergency] UC015 - Receive SOS Notification
- [Emergency] UC011 - Confirm Safety Resolution
- [Notification] UC031 - Manage Notifications

**Estimated**: ~10-15 days

### Sprint 4: Risk & AI + Admin + Sleep (8 cards)
- [Analysis] UC016 - View Risk Report
- [Analysis] UC017 - View Risk Report Detail
- [Sleep] UC020 - Analyze Sleep
- [Sleep] UC021 - View Sleep Report
- [Admin] UC022 - Manage Users
- [Admin] UC025 - Manage Devices
- [Admin] UC024 - Configure System
- [Admin] UC026 - View System Logs

**Estimated**: ~13-19 days

---

## ✅ CHECKLIST TEMPLATE CHO MỖI CARD

Mỗi card có checklist cho các role:

- ✅ **PM/BA**: Review UC, verify business rules
- ✅ **Admin FE Dev**: UI/UX cho Admin Web Dashboard
- ✅ **Admin BE Dev**: Backend APIs, business logic
- ✅ **Mobile FE Dev**: UI/UX cho Mobile App (Flutter)
- ✅ **Mobile BE Dev**: Mobile backend integration, API calls
- ✅ **AI Dev**: AI models, data processing (nếu card có AI)
- ✅ **Tester**: Test cases, manual testing, bug tracking

---

## 🎯 ACCEPTANCE CRITERIA

Mỗi card có **Acceptance Criteria** rõ ràng. Card chỉ được move sang `DONE` khi:
- Tất cả checklist items đã tick
- Tất cả acceptance criteria đã pass
- Code review đã done (nếu có)
- Test cases đã pass

---

## 📌 LƯU Ý QUAN TRỌNG

1. **Dependencies**: Một số cards phụ thuộc nhau (VD: Card 1 → Card 2 → Card 3). Cần làm theo thứ tự.

2. **Priority**: 
   - **High**: Phải làm trong sprint
   - **Medium**: Nên làm nếu có thời gian
   - **Low**: Có thể bỏ qua hoặc làm sau

3. **Estimated Effort**: Là ước tính, có thể điều chỉnh theo thực tế team velocity.

4. **AI Cards**: Cards có AI (Fall Detection, Risk Scoring) cần thời gian training model hoặc dùng pre-trained model.

5. **External Services**: Một số cards cần setup external services:
   - FCM (Firebase Cloud Messaging) cho push notifications
   - SMS service (Twilio, AWS SNS) cho SOS
   - Email service (SendGrid, AWS SES) cho verification emails

---

## 🔄 WORKFLOW

1. **Sprint Planning**: Copy cards từ file Sprint tương ứng vào `TO DO`
2. **Daily Standup**: Review cards trong `IN PROGRESS`
3. **Development**: Move cards sang `IN PROGRESS` khi bắt đầu, tick checklist khi hoàn thành
4. **Code Review**: Move sang `REVIEW` khi code xong
5. **Testing**: Tester test và ghi nhận bugs
6. **Done**: Move sang `DONE` khi tất cả acceptance criteria pass

---

## 📞 HỖ TRỢ

Nếu có vấn đề hoặc cần điều chỉnh:
1. Review lại UC tương ứng trong `BA/UC/`
2. Review Technical Spec trong `BA/Technical_Specification/`
3. Điều chỉnh checklist/acceptance criteria cho phù hợp với team

---

**Cập nhật lần cuối**: [Ngày]  
**Version**: 1.0
