# 📋 JIRA INDEX — HealthGuard Project

> **Mục đích:** File này là **điểm truy cập nhanh (index)** để AI và team tra cứu Epic/Story mà KHÔNG cần đọc toàn bộ file CSV.  
> **Cập nhật:** 04/03/2026 | **Phiên bản:** 1.0

---

## 📊 Tổng quan

| Metric            | Giá trị               |
| :---------------- | :-------------------- |
| Tổng Epics        | 16                    |
| Tổng Stories      | 61                    |
| Tổng Story Points | ~125 SP               |
| Sprints           | 4 (mỗi Sprint 2 tuần) |
| UC Coverage       | 24/24 (100%)          |

---

## 🗺️ DANH SÁCH EPIC (Tra cứu nhanh)

> **Cách dùng cho AI:** Tìm Epic theo module/keyword → ghi nhận Epic Name → dùng Epic Name lọc trong `JIRA_IMPORT_ALL.csv` để lấy chi tiết Stories.

### Sprint 1: Nền tảng & Xác thực

| #    | Epic Name (CSV) | Module | UCs          | Stories | SP   | Priority  |
| :--- | :-------------- | :----- | :----------- | :------ | :--- | :-------- |
| 1    | `EP01-Database` | Infra  | —            | 4       | 6    | 🔴 Highest |
| 2    | `EP02-AdminBE`  | Infra  | —            | 2       | 3    | 🔴 Highest |
| 3    | `EP03-MobileBE` | Infra  | —            | 2       | 3    | 🔴 Highest |
| 4    | `EP04-Login`    | Auth   | UC001        | 5       | 11   | 🔴 Highest |
| 5    | `EP05-Register` | Auth   | UC002        | 5       | 9    | 🟠 High    |
| 12   | `EP12-Password` | Auth   | UC003, UC004 | 5       | 10   | 🟡 Medium  |

### Sprint 2: Thiết bị & Giám sát

| #    | Epic Name (CSV)   | Module     | UCs                 | Stories | SP   | Priority |
| :--- | :---------------- | :--------- | :------------------ | :------ | :--- | :------- |
| 6    | `EP06-Ingestion`  | Infra      | —                   | 3       | 6    | 🟠 High   |
| 7    | `EP07-Device`     | Device     | UC040, UC041, UC042 | 6       | 12   | 🟠 High   |
| 8    | `EP08-Monitoring` | Monitoring | UC006, UC007, UC008 | 3       | 8    | 🟠 High   |

### Sprint 3: Khẩn cấp & Thông báo

| #    | Epic Name (CSV)     | Module       | UCs                 | Stories | SP   | Priority |
| :--- | :------------------ | :----------- | :------------------ | :------ | :--- | :------- |
| 9    | `EP09-FallDetect`   | Emergency    | UC010               | 4       | 10   | 🟠 High   |
| 10   | `EP10-SOS`          | Emergency    | UC014, UC015, UC011 | 3       | 7    | 🟠 High   |
| 11   | `EP11-Notification` | Notification | UC030, UC031        | 3       | 6    | 🟡 Medium |

### Sprint 4: Phân tích & Quản trị

| #    | Epic Name (CSV)    | Module   | UCs          | Stories | SP   | Priority |
| :--- | :----------------- | :------- | :----------- | :------ | :--- | :------- |
| 13   | `EP13-RiskScore`   | Analysis | UC016, UC017 | 4       | 11   | 🟡 Medium |
| 14   | `EP14-Sleep`       | Sleep    | UC020, UC021 | 4       | 8    | 🟡 Medium |
| 15   | `EP15-AdminManage` | Admin    | UC022, UC025 | 5       | 12   | 🟡 Medium |
| 16   | `EP16-AdminConfig` | Admin    | UC024, UC026 | 3       | 5    | 🟢 Low    |

---

## 👥 PHÂN BỔ THEO ROLE

| Role          | Tổng Stories | Sprints hoạt động |
| :------------ | :----------- | :---------------- |
| Admin BE Dev  | 8            | Sprint 1, 4       |
| Admin FE Dev  | 6            | Sprint 1, 4       |
| Mobile BE Dev | 15           | Sprint 1, 2, 3, 4 |
| Mobile FE Dev | 11           | Sprint 1, 2, 3, 4 |
| AI Dev        | 5            | Sprint 1, 2, 3, 4 |
| Tester (QA)   | 16           | Tất cả            |

---

## 🔗 UC → EPIC MAPPING (Reverse Lookup)

> **Cách dùng:** Khi biết UC cần review → tra bảng này → tìm Epic Name → lọc CSV.

| UC    | Tên UC                       | Epic Name           |
| :---- | :--------------------------- | :------------------ |
| UC001 | Login                        | `EP04-Login`        |
| UC002 | Register                     | `EP05-Register`     |
| UC003 | Forgot Password              | `EP12-Password`     |
| UC004 | Change Password              | `EP12-Password`     |
| UC006 | View Health Metrics          | `EP08-Monitoring`   |
| UC007 | View Health Metrics Detail   | `EP08-Monitoring`   |
| UC008 | View Health History          | `EP08-Monitoring`   |
| UC010 | Confirm After Fall Alert     | `EP09-FallDetect`   |
| UC011 | Confirm Safety Resolution    | `EP10-SOS`          |
| UC014 | Send Manual SOS              | `EP10-SOS`          |
| UC015 | Receive SOS Notification     | `EP10-SOS`          |
| UC016 | View Risk Report             | `EP13-RiskScore`    |
| UC017 | View Risk Report Detail      | `EP13-RiskScore`    |
| UC020 | Analyze Sleep                | `EP14-Sleep`        |
| UC021 | View Sleep Report            | `EP14-Sleep`        |
| UC022 | Manage Users                 | `EP15-AdminManage`  |
| UC024 | Configure System             | `EP16-AdminConfig`  |
| UC025 | Manage Devices               | `EP15-AdminManage`  |
| UC026 | View System Logs             | `EP16-AdminConfig`  |
| UC030 | Configure Emergency Contacts | `EP11-Notification` |
| UC031 | Manage Notifications         | `EP11-Notification` |
| UC040 | Connect Device               | `EP07-Device`       |
| UC041 | Configure Device             | `EP07-Device`       |
| UC042 | View Device Status           | `EP07-Device`       |

---

## 📂 CẤU TRÚC THƯ MỤC JIRA

```
TASK/JIRA/
├── README.md                ← File này (Index cho AI tra cứu nhanh)
├── JIRA_IMPORT_ALL.csv      ← CSV chứa 16 Epics + 61 Stories (dùng để import vào Jira)
├── HUONG_DAN_IMPORT.md      ← Hướng dẫn import CSV vào Jira Cloud
└── EPIC_01_Infra_Database/  ← Folder mẫu cho Epic 01 (có thể tạo thêm cho các Epic khác)
    ├── _EPIC.md
    ├── STORY_01_Admin_BE_Setup_DB.md
    ├── STORY_02_Mobile_BE_Connect_DB.md
    ├── STORY_03_AI_Review_Schema.md
    └── STORY_04_QA_Verify_DB.md
```

---

## 🤖 HƯỚNG DẪN CHO AI AGENT

### Khi cần tra cứu task cho một module:
1. Đọc file **README.md này** (JIRA Index).
2. Tìm Epic Name theo module hoặc UC cần review trong bảng trên.
3. Mở `JIRA_IMPORT_ALL.csv` → lọc cột `Epic Link` = Epic Name tìm được.
4. Đọc chỉ các Stories thuộc Epic đó (không đọc toàn bộ CSV).

### Khi cần tra cứu task cho một UC cụ thể:
1. Tìm UC trong bảng **UC → EPIC MAPPING** ở trên.
2. Ghi nhận Epic Name.
3. Lọc CSV theo Epic Name đó.
