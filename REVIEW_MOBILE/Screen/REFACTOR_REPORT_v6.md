# BÁO CÁO CẬP NHẬT GIAO DIỆN MOBILE & TASK MÀN HÌNH (Version 6.0)

> **Ngày**: 14/03/2026
> **Mục tiêu**: Điều chỉnh lại các Task, luồng màn hình Mobile để phù hợp với sự thay đổi trong `UC_AUDIT_report.md` (chuyển đổi từ Role "Patient/Caregiver" sang "Universal User & Linked Profiles").

---

## 1. Cập nhật Mobile Agent Skill (`SKILL.md`)

- **Thay đổi Keyword:**
  - Thay thế "elderly patients, caregivers" thành "elderly users, linked family members/monitoring users" trong định nghĩa Audience của UI/UX Designer.
  - Thay thế User Role trong **Example 1: SOS Screen Design** từ `Patient` thành `User (Profile: Monitored Person)`.
  - Thay thế các hành động của `Patient` thành `User` trong User Flow.
- **Thêm Rule Kiến Trúc (Architecture Rule):** 
  - Tại Bước 3 (Mode TASK), đã thêm một Rule bắt buộc: *"Ensure all screens strictly adopt the unified 'User' role and 'Linked Profiles' (Profile Switcher) mechanism. Do not use deprecated 'patient'/'caregiver' functional roles."*
- **Số lượng Screens dự kiến:** Cập nhật lại Master Count từ 22 lên 41 (theo các Module mới nhất).

---

## 2. Refactor Master Screen Index (`PM_REVIEW/REVIEW_MOBILE/Screen/README.md`)

Master Index đã được tái thiết kế hoàn toàn để phản ánh luồng **Profile-Driven Navigation** mới:

- **Loại bỏ Phân chia Role cứng nhắc**: Xóa bỏ khái niệm màn hình chỉ dành cho "Patient" hay "Caregiver". Mọi User đều có thể truy cập các tính năng, nhưng **dữ liệu hiển thị phụ thuộc vào Context của Profile đang được chọn** (thông qua Quyền hạn `can_view_vitals`, `can_receive_alerts` trong `user_relationships`).
- **Hợp nhất Dashboard**:
  - Khai tử `HOME_PatientDashboard.md` và `HOME_CaregiverDashboard.md`.
  - Hợp nhất thành một màn hình chung duy nhất: `HOME_Dashboard.md` (Main Dashboard).
- **Profile Switcher Component**: Bổ sung `Profile Switcher Dropdown` (Component #41) như trái tim điều hướng toàn cục, đặt trên Header. Component này chịu trách nhiệm set `TargetProfileId` cho toàn bộ ứng dụng cập nhật State.
- **Tính toán lại số lượng màn hình**: Giảm từ 42 xuống 41 màn hình sau khi hợp nhất Dashboard. Dashboard đã được cập nhật thành **Contextual** (Linh hoạt thay đổi hiển thị thay vì có 2 màn hình vật lý khác nhau).

---

## 3. Xác minh dựa trên Kế hoạch `PLAN_MOBILE.md`

Các hành động trên hoàn toàn khớp với kế hoạch Mobile Frontend do Dev đề xuất:
- **Xóa bỏ Chọn Role lúc Đăng Ký**: Mọi người đều là Root User. Luồng Auth_Register (Màn hình #3) đã được note lại là General, thay vì bắt buộc chọn Role.
- **Global Context TargetProfileId**: Toàn bộ hệ thống UI đều được trỏ về Data State chứa giá trị đang active của Khách hàng, không phân tích tĩnh trên mã nguồn nữa chữ "Caregiver" hay "Patient" như trước.

---

## 4. Hành động tiếp theo cho Mobile Team

Dựa trên kết quả cập nhật, Mobile FE & BE cần chú trọng 2 điểm lớn nhất khi implement Screen Specs:

1. Thiết kế **Profile Switcher / Context Switcher Component** ưu tiên trước để kiểm thử được việc lấy Data chéo theo TargetProfileID từ API `/api/mobile/access-profiles`.
2. Áp dụng các Rule của `mobile-agent` đã ghim trong Model để sinh ra (generate) các đặc tả màn hình (`.md`) ở Mode `TASK` mà không vi phạm chuẩn "Profile Linked" mới.
