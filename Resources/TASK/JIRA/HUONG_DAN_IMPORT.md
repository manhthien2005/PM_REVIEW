# 📥 Hướng Dẫn Import CSV Vào JIRA

## File CSV
- **Tên file:** `JIRA_IMPORT_ALL.csv`
- **Nội dung:** 16 Epics + 58 Stories

## Thống kê tổng quan

| Sprint   | Số Epic                   | Số Story       | Tổng Story Points |
| :------- | :------------------------ | :------------- | :---------------- |
| Sprint 1 | 6 Epics (EP01-EP05, EP12) | 29 Stories     | 52 SP             |
| Sprint 2 | 3 Epics (EP06-EP08)       | 9 Stories      | 20 SP             |
| Sprint 3 | 3 Epics (EP09-EP11)       | 10 Stories     | 23 SP             |
| Sprint 4 | 4 Epics (EP13-EP16)       | 18 Stories     | 33 SP             |
| **Tổng** | **16 Epics**              | **58 Stories** | **128 SP**        |

## Phân bổ Story theo Role

| Role          | Số Story | Tổng Story Points |
| :------------ | :------- | :---------------- |
| Admin BE Dev  | 12       | 26 SP             |
| Admin FE Dev  | 8        | 17 SP             |
| Mobile BE Dev | 16       | 38 SP             |
| Mobile FE Dev | 10       | 23 SP             |
| AI Dev        | 6        | 14 SP             |
| Tester (QA)   | 16       | 24 SP             |

## Các bước Import vào Jira Cloud

### Bước 1: Tạo Project
1. Vào **Jira** > **Create Project**
2. Chọn template: **Scrum**
3. Đặt tên: `HealthGuard` (Project Key gợi ý: `HG`)

### Bước 2: Tạo Components
Vào **Project Settings** > **Components**, tạo:
- `Admin-BE`
- `Admin-FE`
- `Mobile-BE`
- `Mobile-FE`
- `AI-Models`
- `QA`
- `Infra-DB`

### Bước 3: Import CSV
1. Vào **Project Settings** > **Import** (hoặc **System** > **Import Issues** > **CSV**)
2. Upload file `JIRA_IMPORT_ALL.csv`
3. **Map các cột** như sau:

| Cột CSV      | Jira Field                               |
| :----------- | :--------------------------------------- |
| Summary      | Summary                                  |
| Issue Type   | Issue Type                               |
| Epic Name    | Epic Name                                |
| Epic Link    | Epic Link                                |
| Priority     | Priority                                 |
| Assignee     | Assignee (hoặc bỏ qua, gán sau)          |
| Component    | Component/s                              |
| Labels       | Labels                                   |
| Story Points | Story Points (hoặc Story point estimate) |
| Sprint       | Sprint                                   |
| Description  | Description                              |

4. Bấm **Begin Import**

### Bước 4: Sau khi Import
1. Vào **Backlog** view, kiểm tra các Epic đã được tạo
2. Kiểm tra Stories đã link đúng Epic
3. Tạo Sprint 1 > kéo các Stories có label `Sprint-1` vào
4. **Gán Assignee** thực tế cho từng Story (thay thế tên role bằng tên thật)
5. Bấm **Start Sprint**

## ⚠️ Lưu ý quan trọng

1. **Assignee:** Trong CSV mình để tên Role (VD: "Admin BE Dev"). Sau khi import, bạn cần đổi thành tên thật của thành viên.
2. **Epic Link:** Nếu Jira không tự link được, bạn vào từng Story > sửa trường "Epic Link" chọn Epic tương ứng.
3. **Encoding:** Mở file CSV bằng Notepad++ hoặc VS Code để kiểm tra encoding là UTF-8 trước khi import.
4. **Dấu tiếng Việt:** File CSV đã dùng không dấu để tránh lỗi encoding khi import. Sau khi import lên Jira, bạn có thể sửa lại tiếng Việt có dấu nếu muốn.
