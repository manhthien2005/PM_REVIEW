# Ví dụ Thực Tế: Phân Tích UC003 (Quên Mật Khẩu) Thành JIRA Epic & Thẻ Làm Việc

Dựa trên tài liệu Đặc tả `UC003_ForgotPassword.md`, dưới đây là cách phân rã (Breakdown) Use Case này thành cấu trúc Jira chuẩn Scrum kèm mô phỏng quy trình làm việc (Workflow).

---

## 🏗️ 1. Khởi Tạo EPIC (Hạng Mục Sinh Lời)

Đầu tiên, PM/BA tạo một **Epic** làm "cái rổ" chứa tất cả các công việc liên quan đến tính năng Quên Mật Khẩu.

*   **Issue Type:** `Epic`
*   **Epic Name:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** Người dùng yêu cầu đặt lại mật khẩu thông qua email khi quên.
*   **Description:**
    ```markdown
    **Mục tiêu:**
    Cho phép Patient/Caregiver và Admin có thể tự reset password thông qua luồng gửi email chứa token.

    **Business Rules cốt lõi:**
    - BR-001: Link reset có hiệu lực 15 phút.
    - BR-002: Token reset chỉ dùng 1 lần.
    - BR-005: Chống Enumeration Attack (Luôn báo gửi email thành công dù email không tồn tại).
    - BR-006: Rate limit (3 lần/15 phút).

    **Documents:** [Link file UC003_ForgotPassword.md]
    ```

---

## 📝 2. Chẻ Nhỏ Thành Các USER STORIES (Thẻ Việc Cho Dev)

Từ Epic trên, chúng ta xẻ nhỏ ra thành **5 Thẻ (Story)** độc lập. Mỗi thẻ chỉ do 1 người chịu trách nhiệm (Assignee).

### 💳 Story 1: Backend cho Admin (Node.js)
*   **Issue Type:** `Story`
*   **Epic Link:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** `[Admin BE] API Forgot & Reset Password`
*   **Assignee:** `[Admin BE Dev]` | **Story Points:** `3`
*   **Description (Dựa trên Data Requirements & BR của UC):**
    ```markdown
    **Mục tiêu:** Viết 2 API cho Admin Web: `POST /api/auth/forgot-password` và `POST /api/auth/reset-password`.
    **Acceptance Criteria:**
    *   [ ] Validate email format từ request.
    *   [ ] Kiểm tra Rate limit (3 requests / 15 phút).
    *   [ ] Dù email có hay không trong DB, API luôn trả về HTTP 200 (Success) để chống quét email (BR-005).
    *   [ ] Đẩy Token JWT (thời hạn 15 phút - BR-001) vào email (dùng SendGrid/SMTP).
    *   [ ] API Reset: Nhận token, cập nhật DB, vô hiệu hoá token (BR-002).
    *   [ ] Mật khẩu mới >= 8 ký tự, phải khác mật khẩu cũ (BR-003, BR-004).
    ```

### 💳 Story 2: Backend cho Mobile (FastAPI)
*   **Issue Type:** `Story`
*   **Epic Link:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** `[Mobile BE] API Forgot & Reset Password`
*   **Assignee:** `[Mobile BE Dev]` | **Story Points:** `3`
*   *(Description tương tự Story 1, nhưng viết bằng Python/FastAPI và trả về Deep Link cho Mobile ví dụ `app://healthguard/reset?token=...`)*

### 💳 Story 3: Frontend Web Admin (ReactJS)
*   **Issue Type:** `Story`
*   **Epic Link:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** `[Admin FE] UI - Màn hình Quên và Đổi Mật Khẩu`
*   **Assignee:** `[Admin FE Dev]` | **Story Points:** `2`
*   **Linked Issues:** `is blocked by` `[Admin BE] API Forgot & Reset Password`
*   **Description:**
    ```markdown
    **Mục tiêu:** Làm UI cho pha yêu cầu email và pha nhập mật khẩu mới.
    **Acceptance Criteria:**
    *   [ ] UI Form nhập email: Gọi API Forgot. Show thông báo "Đã gửi email..." dù thành công hay lỗi.
    *   [ ] UI Form Reset: Đọc tham số `?token=...` từ URL.
    *   [ ] Validate ô "Mật khẩu mới" (>=8 ký tự) và ô "Xác nhận mật khẩu" phải khớp.
    ```

### 💳 Story 4: Mobile App (Flutter)
*   **Issue Type:** `Story`
*   **Epic Link:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** `[Mobile FE] App - Màn hình Quên và Đổi Mật Khẩu`
*   **Assignee:** `[Mobile FE Dev]` | **Story Points:** `2`
*   **Linked Issues:** `is blocked by` `[Mobile BE] API Forgot & Reset Password`
*   *(Description làm form UI tương tự Story 3, tích hợp xử lý Deep Link mở app từ email)*

### 💳 Story 5: QA/Tester
*   **Issue Type:** `Story`
*   **Epic Link:** `[Auth] UC003 - Quên Mật Khẩu`
*   **Summary:** `[QA] Test Cả Luồng Chính/Phụ của UC003`
*   **Assignee:** `[Tester]`
*   **Description (Dựa trên Luồng thay thế của UC):**
    ```markdown
    - [ ] Test Luồng chính: Gửi -> Nhận Email -> Reset -> Login thành công.
    - [ ] Test 5.a: Nhập email sai (không có trong DB) -> Vẫn báo gửi thành công.
    - [ ] Test 9.a: Để im email quá 15 phút mới click link -> Báo lỗi hết hạn.
    - [ ] Test 10.a: Nhập pass mới giống pass cũ -> Báo lỗi.
    - [ ] Test Rate limit: Nhấn nút gửi 4 lần liên tục lúc quên pass -> Bị chặn.
    ```

---

## 🔄 3. Mô Phỏng Workflow Làm Việc Thực Tế (Ngày qua Ngày)

Đây là cách dòng chảy công việc sẽ diễn ra mượt mà trong thực tế mà Trello không làm được:

**Thứ 2 (Planning):**
*   PM/BA gom cả 5 Thẻ trên nhét vào **Sprint 1**, gán 10 Điểm (Story Points) dự tính, bấm Start Sprint.

**Thứ 3:**
*   Dev BE (Admin BE & Mobile BE) kéo Thẻ 1 và Thẻ 2 sang cột `IN PROGRESS` và bắt tay vào code.
*   Dev FE đang rảnh. Dev FE bấm vào Thẻ 3, thấy dòng chữ đỏ rực cảnh báo `Blocked by Thẻ 1 (Admin BE)`. Dev FE biết mình chưa thể làm trang này, bèn quay sang làm Epic Login (UC001) trước. Không có lời phàn nàn nào.

**Thứ 4:**
*   Dev Admin BE xong API Forgot Password. Push code. Kéo Thẻ 1 sang `REVIEW`, nhờ sếp review code. Sếp OK, code tự Merge, Thẻ 1 được hệ thống tự chuyển sang `READY FOR TEST` (hoặc `DONE`).
*   Ngay lúc này, Jira tự bắn thông báo (hoặc chuông Slack) cho Admin FE: *"Rào cản đã được gỡ"*. Dev FE lập tức kéo Thẻ 3 sang `IN PROGRESS` để bắt đầu ghép API.

**Thứ 5:**
*   FE làm xong, kéo thẻ sang `READY FOR TEST`. Tester cũng kéo Thẻ 5 (QA) sang `IN TESTING` và bắt đầu vào Web test.
*   Tester test tới bước nhập pass cũ, phát hiện bug (Nhập pass mới Y CHANG pass cũ mà hệ thống vẫn chịu).

**Xử Lý Bug Bằng Jira:**
*   Thay vì chat Telegram la hét, Tester lập tức bấm "Create Bug" trực tiếp trên Jira:
    *   **Bug Name:** `Lỗi UC003: Backend cho phép sửa pass mới trùng pass cũ`.
    *   **Link tới:** Thẻ 1 `[Admin BE] API Forgot`.
*   Tester quăng Bug này vào cột `TO DO` của Dev BE.
*   Dev BE nhận thẻ Bug, sửa lỗi trong 30 phút, đẩy lại sang `READY FOR TEST`.
*   Tester test lại -> Pass -> Kéo Bug sang `DONE`, kéo Thẻ 5 (QA) sang `DONE`.

**Thứ 6:**
*   Mở Jira lên, PM cười mỉm. Thanh Progress Bar của Epic `[Auth] UC003` chuyển sang màu xanh lá báo **100% Hoàn Thành**. Epic tự động khoá (Closed). Done!
