# Hướng Dẫn Setup JIRA (Chuẩn Scrum) Cho Dự Án HealthGuard

Để chuyển đổi từ Trello sang Jira một cách mượt mà và tận dụng tối đa sức mạnh của mô hình Scrum, chúng ta cần thống nhất cách mapping (chuyển đổi) các khái niệm từ file Markdown sang các loại Issue (Thẻ) trong Jira.

---

## 1. Hệ Thống Phân Cấp (Issue Hierarchy)

*   **Epic:** Đại diện cho một tính năng lớn hoặc một Use Case hoàn chỉnh (Ví dụ: `UC001 - Login`, `Setup Infrastructure`). Epic mất nhiều Sprint để hoàn thành hoặc bao gồm nhiều Story.
*   **Story (User Story):** Một đơn vị công việc mang lại giá trị cho người dùng cuối, được phân chia theo nền tảng/vai trò (Ví dụ: `[Admin BE] API Login`, `[Mobile FE] Giao diện Login`). Điểm Story Point sẽ được gán ở cấp độ này.
*   **Sub-task:** Các bước kỹ thuật nhỏ gọn để hoàn thành một Story (Ví dụ: `Viết Unit Test`, `Thiết kế DB Table`). Sub-task thuộc về một Story cụ thể.
*   **Bug:** Thẻ ghi nhận lỗi hệ thống do đội QA/Tester báo cáo.

---

## 2. JIRA Templates (Mẫu Thẻ)

Dưới đây là các template mẫu mô phỏng lại cách bạn sẽ nhập dữ liệu từ `TRELLO_SPRINT1.md` vào Jira.

### Mẫu 1: EPIC (Hạng Mục Lớn)

**Issue Type:** `Epic`
**Epic Name:** `[Auth] UC001 - Login`
**Summary:** Người dùng đăng nhập bằng email/password, nhận JWT token.

**Description (Mô tả):**
```markdown
**Mục tiêu:**
Người dùng đăng nhập bằng email/password để truy cập hệ thống.
⚠️ Hệ thống phân tách rõ ràng:
- Admin login qua Node.js Backend.
- Patient/Caregiver (Mobile) login qua FastAPI Backend.

**Tài liệu đính kèm (Reference):**
- [Link tới BA/UC/Authentication/UC001_Login.md]
```

---

### Mẫu 2: STORY (Thẻ Công Việc Cụ Thể)

Đây là thẻ mà các Dev sẽ trực tiếp nhận (Assign) và code.

**Ví dụ 1: Backend Story**
**Issue Type:** `Story`
**Summary:** `[Admin BE] Implement API Login cho Web Dashboard`
**Epic Link:** Chọn Epic `[Auth] UC001 - Login`
**Assignee:** `[Tên Admin BE Dev]`
**Story Points:** `3` (Điểm Effort)
**Labels:** `Backend`, `Auth`
**Components:** `Admin-BE`

**Description (Mô tả chi tiết):**
```markdown
**Mục tiêu:**
Phát triển API Login `POST /api/auth/login` cho Admin Web Dashboard.

**Acceptance Criteria (Điều Kiện Hoàn Thành):**
*   [ ] Request nhận `{email, password}`.
*   [ ] Response trả về `{access_token, token_type, user: {id, email, role, full_name}}`.
*   [ ] Sử dụng bcrypt để hash password.
*   [ ] Generate JWT token: `iss="healthguard-admin"`, role: ADMIN, thời hạn (expiry) **8h**.
*   [ ] Cài đặt Rate limiting: 5 attempts/15 phút per IP.
*   [ ] Kiểm tra cờ `is_active` trong table `users`.
*   [ ] Update `last_login_at` vào database.
*   [ ] Ghi log đăng nhập vào table `audit_logs`.
*   [ ] Xử lý lỗi (Error handling): sai email/mật khẩu, tài khoản bị khoá.
```

*(Sau khi tạo thẻ này, Dev tự tạo các Sub-tasks như "Viết Unit Test cho Login", "Cấu hình Rate Limit middleware" nếu họ muốn chia nhỏ thêm).*

**Ví dụ 2: Frontend Story**
**Issue Type:** `Story`
**Summary:** `[Admin FE] Phát triển giao diện Login`
**Epic Link:** Chọn Epic `[Auth] UC001 - Login`
**Assignee:** `[Tên Admin FE Dev]`
**Story Points:** `2`
**Labels:** `Frontend`, `Auth`
**Components:** `Admin-FE`
**Linked Issues:** `is blocked by` -> Chọn Story `[Admin BE] Implement API Login` *(Cấu hình này báo cho FE biết phải chờ API xong)*

**Description:**
```markdown
**Mục tiêu:**
Thiết kế và code trang Login bằng React + TailwindCSS, tích hợp API từ Backend.

**Acceptance Criteria:**
*   [ ] Validate form (định dạng email, các trường bắt buộc).
*   [ ] Gọi API `POST /api/auth/login`.
*   [ ] Lưu trữ JWT token an toàn.
*   [ ] Chuyển hướng (Redirect) về Dashboard sau khi đăng nhập thành công.
*   [ ] Hiển thị thông báo lỗi (sai mật khẩu, tài khoản khoá).
*   [ ] Nút bật/tắt hiển thị mật khẩu (Show/hide password toggle).
*   [ ] Hiển thị trạng thái Loading khi đang gọi API.
```

---

### Mẫu 3: SUB-TASK (Nhiệm Vụ Kỹ Thuật Dành Cho QA/Tester)

Thông thường, QA có thể có một Story riêng hoặc các Sub-tasks nằm rải rác. Tuy nhiên, để linh hoạt, ta tạo một QA Story riêng trong Epic.

**Issue Type:** `Story`
**Summary:** `[QA] Kiểm thử chức năng Login (Web & Mobile)`
**Epic Link:** Seç Epic `[Auth] UC001 - Login`
**Assignee:** `[Tên Tester]`
**Labels:** `QA`, `Auth`

**Description:**
```markdown
**Mục tiêu:**
Kiểm tra luồng Login đảm bảo đúng logic và bảo mật.

**Test Cases (Trường Hợp Kiểm Thử):**
**1. Admin Login (Web):**
- [ ] Luồng chính: Đăng nhập đúng thông tin -> nhận JWT hạn 8h.
- [ ] Luồng phụ: Sai email/mật khẩu -> hiển thị lỗi.
- [ ] Rate limiting: Nhập sai 6 lần liên tiếp -> báo khoá IP.
**2. Mobile Login (App):**
- [ ] Luồng chính: Đăng nhập đúng -> nhận JWT hạn 30 ngày + refresh token.
- [ ] Luồng phụ: Sai email/mật khẩu.
**3. Phân quyền:**
- [ ] Bắt lỗi tài khoản Admin đăng nhập trên App Mobile (và ngược lại).
```

---

## 3. Cấu Hình Workflow Đề Xuất Cho Board (Cột Kanban)

Thay vì workflow mặc định quá đơn giản, bạn nên setup board gồm các cột sau (theo thứ tự trái qua phải):

1.  **BACKLOG / TO DO:** Thẻ vừa được lên kế hoạch trong Sprint hiện tại.
2.  **IN PROGRESS:** Dev đang code. *(Giới hạn WIP - Work In Progress: Mỗi người chỉ nên gánh tối đa 2 thẻ ở cột này cùng lúc).*
3.  **REVIEW (CODE REVIEW):** Dev code xong, tạo Pull Request và chờ người khác (Lead/Dev khác) review code.
4.  **READY FOR TEST:** Code đã merge vào nhánh `staging` và deploy. Chờ Tester vào kiểm tra.
5.  **IN TESTING:** Tester đang test (Thẻ assign cho Tester).
    *   *Nếu có bug:* Tester tạo MỚI 1 Jira Bug Card, link với Story này, và thả Bug Card về cột `TO DO`, assign lại cho Dev. Thẻ Story vẫn đứng im ở `IN TESTING`.
6.  **DONE:** Tester xác nhận [Passed], PM đóng thẻ. Cuối Sprint, Epic sẽ tự hoàn tất nếu tất cả Story bên trong về `DONE`.

---

## 4. Các Bước Thiết Lập Dự Án Mới Trên Jira (Dành Cho PM)

1.  **Create Project:** Chọn Template `Scrum` (Đừng chọn Kanban, vì bạn đang muốn chạy các Sprints theo số tuần).
2.  **Add Users:** Mời 7 thành viên vào dự án.
3.  **Create Components:** Đi tới *Project settings > Components*, tạo các mục: `Backend-Node`, `Backend-FastAPI`, `Frontend-React`, `Mobile-Flutter`, `AI-Models`, `Infra-DB`.
4.  **Tạo Epic:** Mở mục Epic Panel ở màn hình Backlog, tạo list danh sách các Epic (Card 1, Card 2A, Card 3...).
5.  **Tạo Backlog:** Copy dần checklist của từng Role vào làm Title của các Story dưới Epic đó.
6.  **Gán Sprint (Sprint Planning):** Chọn nhóm các thẻ bỏ vào hộp `Sprint 1`, thiết lập ngày bắt đầu/kết thúc (Vd: 2 tuần), gắn Story Points cho từng thẻ, sau đó nhấn **START SPRINT**.
