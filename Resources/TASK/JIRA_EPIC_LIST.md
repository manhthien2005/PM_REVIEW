# Danh Sách Epics JIRA (Dự Án HealthGuard)

Dưới đây là danh sách các Epic được tổng hợp từ kế hoạch của 4 Sprints. Các thẻ này được gom nhóm từ các thẻ Use Case/Chức năng riêng lẻ và được sắp xếp theo **thứ tự ưu tiên thực thi dọn đường (Dependencies + Priority)** để đảm bảo mạch làm việc của team không bị block.

---

### 📋 DANH SÁCH EPICS ƯU TIÊN

| STT    | Tên Epic trên Jira                                                    | Nguồn tham chiếu (Base Task) | Priority      | Component / Role Chính | Ghi chú (Lý do ưu tiên)                                                                          |
| :----- | :-------------------------------------------------------------------- | :--------------------------- | :------------ | :--------------------- | :----------------------------------------------------------------------------------------------- |
| **1**  | **[Infra] Thiết lập Database & Timescale DB**                         | Sprint 1 (Card 1)            | 🔴 **Highest** | Infra / BE             | Phải làm đầu tiên để có schema chuẩn, mọi thứ đều phụ thuộc vào DB.                              |
| **2**  | **[Infra] Khởi tạo Admin Backend (Node.js)**                          | Sprint 1 (Card 2A)           | 🔴 **Highest** | Admin BE               | Setup khung xương server cho Admin FE làm việc.                                                  |
| **3**  | **[Infra] Khởi tạo Mobile Backend (FastAPI)**                         | Sprint 1 (Card 2B)           | 🔴 **Highest** | Mobile BE              | Setup khung xương server cho Flutter App và AI Ingestion.                                        |
| **4**  | **[Auth] Tính năng Đăng nhập & Authentication (Tất cả Roles)**        | Sprint 1 (Card 3)            | 🔴 **Highest** | Cả Team                | Cần JWT Token để gọi API cho toàn bộ các chức năng về sau.                                       |
| **5**  | **[Auth] Đăng ký & Quản lý Tài khoản ban đầu**                        | Sprint 1 (Card 4)            | 🟠 **High**    | Cả Team                | Cần dữ liệu user thực để test.                                                                   |
| **6**  | **[Infra] Data Ingestion & MQTT Service**                             | Sprint 2 (Card 3)            | 🟠 **High**    | Mobile BE, AI          | Timestream, kết nối đồng hồ giả lập để đổ data vào DB rỗng. Rất quan trọng cho Sprint 2.         |
| **7**  | **[Device] Kết nối & Quản lý trạng thái Thiết bị IoT**                | Sprint 2 (Card 1, 2)         | 🟠 **High**    | Mobile BE/FE           | Logic phân luồng thiết bị của ai, trạng thái pin/sóng. Đi liền với Ingestion.                    |
| **8**  | **[Monitoring] Bảng điều khiển Chỉ số sinh tồn (Realtime & Lịch sử)** | Sprint 2 (Card 4, 5, 6)      | 🟠 **High**    | Mobile BE/FE           | Core feature của App: Hiện HR, SpO2, BP ra màn hình. Data lấy từ Epic #6.                        |
| **9**  | **[Emergency] Tính năng Cảnh báo Té ngã (Fall Detection)**            | Sprint 3 (Card 2)            | 🟠 **High**    | Mobile BE/FE, AI       | Core feature của sự an toàn. Tích hợp AI Trigger, quy trình 30 giây xác nhận.                    |
| **10** | **[Emergency] Gửi và Nhận SOS Thủ công**                              | Sprint 3 (Card 3, 4, 5)      | 🟠 **High**    | Mobile BE/FE           | Bấm nút khẩn cấp, Flow xác nhận và xử lý (Resolve) cảnh báo.                                     |
| **11** | **[Notification] Cấu hình Liên hệ khẩn cấp & Thông báo**              | Sprint 3 (Card 1, 6)         | 🟡 **Medium**  | Mobile BE/FE           | Dựa trên luồng SOS (Epic #10) để phân luồng gửi SMS, gọi điện, Push Notify.                      |
| **12** | **[Auth] Phục hồi & Thay đổi Mật khẩu**                               | Sprint 1 (Card 5, 6)         | 🟡 **Medium**  | Cả Team                | Tính năng phụ trợ (Auxiliary) cho flow đăng nhập, có thể làm sau khi Core chạy được.             |
| **13** | **[Analysis] Chấm điểm Rủi ro (Risk Scoring Model)**                  | Sprint 4 (Card 1, 2)         | 🟡 **Medium**  | Mobile BE, AI          | Phụ thuộc vào AI model đã train xong, và hệ thống đã thu thập đủ Data (24h vitals).              |
| **14** | **[Sleep] Phân tích và Báo cáo Giấc ngủ**                             | Sprint 4 (Card 3, 4)         | 🟡 **Medium**  | Mobile BE, AI          | Tính năng nâng cao, xử lý theo ca/Cronjob hàng ngày.                                             |
| **15** | **[Admin] Quản lý Người dùng & Thiết bị toàn hệ thống**               | Sprint 4 (Card 5, 6)         | 🟡 **Medium**  | Admin BE/FE            | Xây dựng UI dashboard quản lý toàn bộ User từ DB (Làm ở Sprint 4 do rảnh rỗi chờ các team khác). |
| **16** | **[Admin] Cấu hình Hệ thống & Export Logs**                           | Sprint 4 (Card 7, 8)         | 🟢 **Low**     | Admin BE/FE            | Tính năng quản trị phía sau, không ảnh hưởng lớn đến nghiệp vụ End-user.                         |

---

### 💡 Hướng dẫn cho PM khi tạo Card trên JIRA

1. Tạo 16 Epics này trước tiên trong mục **Backlog** của Jira (Nhớ chọn Issue Type là `Epic`).
2. Mở file `TRELLO_SPRINT1-4.md`. Đi tới từng mục `Card 1`, `Card 2`... và copy dòng **CHECKLIST** sang thành các Thẻ **Story** hoặc **Sub-task** (như đã hướng dẫn ở file `JIRA_SETUP_GUIDE.md`).
3. Gắn các Thẻ Story đó vào Epic tương ứng trong danh sách trên.
4. Lên plan Sprints: Thay vì cố ép theo nội dung tĩnh của `TRELLO_SPRINT1.md`, bây giờ bạn có thể **kéo thả từng Story** của các Epic từ cao xuống thấp nhét vào các Sprints (thường khoảng 20-30 điểm Story Point / 1 Sprint tuỳ theo năng lực thực tế của Team BE và FE trong tuần đó).
