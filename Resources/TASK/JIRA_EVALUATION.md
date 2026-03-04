# Đánh Giá Phương Pháp Giao Task Hiện Tại (Trello)

 Dựa trên các tài liệu `TRELLO_README.md`, `TRELLO_SPRINT1.md` cùng các nguyên tắc trong **Product Manager Toolkit** và **Brainstorming**, dưới đây là bản đánh giá chi tiết về quy trình giao task hiện tại của dự án HealthGuard.

---

## 1. Cách giao task chi tiết này có hợp lý không? Có làm rối dev không?

**Trả lời nhanh:** Từng chi tiết (Description, Acceptance Criteria) là **rất xuất sắc và cần thiết**, nhưng **cách chuyển thể lên thẻ Trello (Card) sẽ làm RỐI MÙ dev và PM**.

**Tại sao lại rối?**
- **Xung đột trạng thái (Status Conflict trên Kanban board):** Một card đại diện cho toàn bộ Use Case (ví dụ: UC001 - Login) chứa checklist cho cả BE, FE và Tester. 
  - *Ví dụ:* Khi Backend đang code, card nằm ở cột `IN PROGRESS`. Khi BE làm xong và báo Frontend ghép API, card đó nên nằm ở cột nào? Nếu BE cần `REVIEW` nhưng FE lại mới bắt đầu `IN PROGRESS`, thì việc di chuyển thẻ sẽ bị mâu thuẫn.
- **Quá tải nhận thức (Cognitive Overload):** Một dev (ví dụ: Mobile FE) mở thẻ lên sẽ phải "bơi" qua hàng loạt thông tin không liên quan đến mình như setup DB, Admin BE, Admin FE, v.v., dẫn đến việc dễ bỏ sót task của chính mình.
- **Trách nhiệm bị pha loãng (Diluted Ownership):** Khi assign 4-5 người vào cùng 1 thẻ, không ai thực sự làm "chủ" thẻ đó (Card Owner). Tâm lý chung là "chắc người kia đang làm", làm giảm tính cam kết.

---

## 2. Ưu và Nhược điểm của file markdown hiện tại

### ✅ Ưu điểm (Nên giữ lại)
- **Tính toàn vẹn (Feature Completeness):** Đứng ở góc độ PM/BA, các file Sprint của bạn giống như một tài liệu **PRD (Product Requirements Document)** cỡ nhỏ rất tuyệt vời. Nó đảm bảo 1 Use Case được mô tả xuyên suốt từ DB lên tới UI.
- **Acceptance Criteria rõ ràng:** Điều kiện "Done" cực kỳ rành mạch, bảo vệ chất lượng phần mềm.
- **Bao quát được Dependencies:** Thể hiện rõ khối lượng công việc khổng lồ của toàn bộ module trong một bức tranh chung.

### ❌ Nhược điểm (Cần cải thiện)
- **Sai nguyên tắc thẻ Agile/Kanban:** Một thẻ Kanban sinh ra để theo dõi 1 đơn vị công việc độc lập có thể hoàn thành trong khoảng thời gian ngắn bởi 1 người hoặc 1 cặp pair-programming. Gom cả Use Case vào 1 thẻ là đang nhầm lẫn giữa **Epic (Hạng mục lớn)** và **Task (Công việc)**.
- **Khó ước tính (Estimation):** Không thể đánh giá Effort (như trong mô hình RICE) hay tính toán Velocity riêng biệt cho team BE hay FE nếu chúng dính chặt vào chung 1 thẻ.

---

## 3. Đề xuất: Cách tốt hơn và dễ quản lý hơn

Để tối ưu hóa cả 2 tiêu chí là **Dễ kiểm soát tiến độ, người làm** và **Tracking công việc**, bạn nên chuyển từ mô hình "1 Thẻ = 1 Use Case (nhiều roles)" sang mô hình **"Epic & Task Cards"**.

### Giải pháp: Tách Thẻ (Card Splitting)

Bản thân file `TRELLO_SPRINT1.md` của bạn nên đóng vai trò là thư mục gốc (Epic). Thay vì copy toàn bộ nội dung Card 3 (`UC001 - Login`) vào 1 thẻ Trello duy nhất, PM hãy chia nhỏ nó ra:

1. **[Tùy chọn] Tạo Epic Card:** `[EPIC] UC001 - Login`. Để thẻ này ở list đầu tiên. Chứa mô tả chung và Acceptance Criteria tổng.
2. **Tạo Task Cards chuyên biệt:** (Mỗi thẻ chỉ assign cho 1 người/1 nhóm chuyên môn)
   - 💳 **Thẻ 1:** `[Admin BE] API Login` -> Copy checklist của Admin BE vào đây. Assign cho Admin BE.
   - 💳 **Thẻ 2:** `[Mobile BE] API Login` -> Copy checklist Mobile BE. Assign Mobile BE.
   - 💳 **Thẻ 3:** `[Admin FE] UI Login` -> Note thêm dependency: *Cần thẻ 1 xong API*. Assign Admin FE.
   - 💳 **Thẻ 4:** `[Mobile FE] UI Login` -> Note dependency: *Cần thẻ 2*. Assign Mobile FE.
   - 💳 **Thẻ 5:** `[QA] Test UC001 Admin & Mobile` -> Chứa Acceptance Criteria. Assign Tester.

### Đánh giá đề xuất theo tiêu chí của bạn

| Tiêu chí | Đánh giá mô hình đề xuất (Epic & Tasks) |
| :--- | :--- |
| **Dễ kiểm soát tiến độ** | **Rất Dễ.** Nhìn vào bảng Kanban, PM thấy ngay `[Admin BE] API Login` đang ở cột DONE, nhưng `[Admin FE] UI Login` vẫn kẹt ở TO DO. -> PM biết ngay điểm nghẽn (bottleneck) đang ở đâu để xử lý. |
| **Dễ kiểm soát người làm** | **Tuyệt đối.** Mô hình `1 Thẻ = 1 Assignee`. Dev BE không thể vịn cớ "FE chưa làm nên em chưa kéo thẻ sang Done". Việc ai người nấy tự chịu trách nhiệm kéo thẻ của mình. |
| **Tracking công việc tổng thể**| Dev chỉ nhìn thấy checklist của mình -> Làm việc focus nhanh hơn. PM/Tester có thể dùng thẻ Epic gốc hoặc hệ thống Trello Label (vd label `UC001`) để filter xem Use Case này đã hoàn tất được bao nhiêu phần trăm. |

### Bước đi tiếp theo (Action Item)
Bạn không cần phải sửa nội dung các file `TRELLO_SPRINT*.md` hiện tại vì chúng đã rất tốt để làm tài liệu tham khảo/PRD. Bạn chỉ cần sửa **Bước 2 trong `TRELLO_README.md`** thành hướng dẫn **"Tách các role của mỗi Card trong file Markdown thành các Task Cards độc lập trên Trello"** là quy trình sẽ mượt mà ngay lập tức.
