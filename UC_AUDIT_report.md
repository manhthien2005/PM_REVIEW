# BÁO CÁO KIỂM TRA USE CASE — HealthGuard

> **Ngày**: 14/03/2026
> **Phiên bản**: 6.0
> **Tổng UC kiểm tra**: 29

---

## 1. TỔNG QUAN KIỂM TRA

| Metric                  | Kết quả     |
| ----------------------- | ----------- |
| Tổng UC                 | 29          |
| UC đạt chất lượng       | 29          |
| UC cần sửa              | 0           |
| HG-FUNC được phủ        | 11/11       |
| Tính nhất quán Actor    | 100% (Đã gỡ bỏ Caregiver/Patient) |
| Cột SQL được phủ bởi UC | Đã map hoàn toàn bảng liên kết |

---

## 2. BẢNG KIỂM TRA UC (Inventory) - Điểm Nhấn Refactor

Toàn bộ 29 UC đã được thanh tra và cập nhật hàng loạt để loại bỏ hoàn toàn sự phân mảnh Role cũ:

| Nhóm Module | Số lượng UC | Trạng thái Refactor (Role -> User) | Ghi chú cập nhật |
| ----------- | ----------- | ---------------------------------- | ---------------- |
| Auth        | 6           | ✅ Hoàn tất                        | UC002 đã xóa bước chọn đối tượng đăng ký, tự gán role `user`. |
| Monitoring  | 3           | ✅ Hoàn tất                        | Đã cập nhật Rule Phân quyền `BR-Auth-01` qua liên kết. |
| Emergency   | 4           | ✅ Hoàn tất                        | Đã chuyển cơ chế broadcast SOS sang query theo quyền `can_receive_alerts`. |
| Analysis    | 2           | ✅ Hoàn tất                        | Cập nhật BR phân quyền data. |
| Sleep       | 2           | ✅ Hoàn tất                        | Cập nhật BR phân quyền data. |
| Notification| 2           | ✅ Hoàn tất                        | Điều chỉnh Actor thành User/Admin. |
| Device      | 3           | ✅ Hoàn tất                        | Tách biệt vai trò User connect thiết bị. |
| Admin       | 7           | ✅ Hoàn tất                        | Tất cả UC quản trị đã bỏ filter theo patient/caregiver, chuyển sang kiến trúc Linked Profiles. |

---

## 3. PHÂN NHÓM THEO USE CASE (CẬP NHẬT KIẾN TRÚC MỚI)
- **Thiếu Sót Module Admin (ĐÃ FIX)**: Các Use Case Admin (UC022, UC024, UC028, UC029) trước đây vẫn còn tham chiếu đến khái niệm role `patient` (Bệnh nhân) và `caregiver` (Người chăm sóc). Qua quá trình File Audit, toàn bộ tài liệu đã được nâng cấp đồng nhất lên kiến trúc mới: dùng 1 role `user` duy nhất và quản lý quyền truy cập qua bảng `user_relationships` (Tài khoản liên kết/Người theo dõi sức khỏe). Các thay đổi này đã áp dụng triệt để vào ngày 14/03/2026.
- **Ngưng sử dụng (Deprecated UCs)**: Bám sát theo thiết kế trước, loại bỏ các UC liên quan tới tính năng không liên đới (XAI / System background job).
- **Core Priority UCs**: Mọi chức năng chính (Auth, Vitals Monitoring, Emergency, Risk Analysis) đã được quy chuẩn hóa.

### 3.2 Phân quyền (BR-Auth-01 Verification)

| Level      | UCs chứa Rule Authorization `user_relationships`                   | Tình trạng |
| ---------- | ------------------------------------------------------------------ | ---------- |
| DATA FETCH | UC006, UC007, UC008, UC016, UC020                                  | ✅         |
| SOS ACTION | UC010, UC014, UC015                                                | ✅         |

---

## 4. KIỂM TRA CHÉO (Cross-Check)

### 4.1 UC ↔ SQL Gaps (Post-Refactor)

| Table | Lỗi / Cột   | Rủi ro xử lý trong DB Schema | Status |
| ----- | ----------- | ---------------------------- | ------ |
| users | role        | Constraint cũ `patient/caregiver` đã được Plan sửa thành `user/admin` | ✅ Đã giao Task DB |
| user_relationships | caregiver_id | Tên cột dễ gây nhầm lẫn. Đã NOTE lại cho Đội BE giữ nguyên tên để tránh vỡ code cũ | ✅ SAFE |

### 4.2 Internal Consistency

| Check    | Source A          | Source B    | Match | Flag         |
| -------- | ----------------- | ----------- | ----- | ------------ |
| Actor Type | Bản thân các file UC | File 00_DANH_SACH_USE_CASE.md | ✅ MATCH | OK |
| Module count | Thư mục vật lý | MASTER_INDEX.md | ✅ MATCH | OK |

---

## 5. KHUYẾN NGHỊ ƯU TIÊN

| Priority | Issue   | Action Required |
| -------- | ------- | --------------- |
| P0       | Migration DB | Team SQL cần lên kịch bản migrate data chạy Update các Role cũ (`patient/caregiver`) thành `user` trước thời điểm Deploy. |
| P1       | Chỉnh sửa App | Team Mobile FE & BE cần phát triển ngay Module `GET /api/mobile/access-profiles` để nạp dữ liệu Profile Switcher. |
| P2       | Document SOS | Spec liên quan Push Notification (FCM/APNS) cần update thêm object `target_profile_id` chìm trong Payload để App Client biết hiển thị SOS cho ai. |

---

## 🔄 KHÁI QUÁT SỰ THAY ĐỔI
- **Lần trước**: Phiên bản 5.1 (08/03/2026) vẫn còn Actor phân chia theo Role "patient/caregiver".
- **Lần này**: Phiên bản 6.0 (14/03/2026) hệ thống đã đạt trạng thái thống nhất "Universal User" - "Linked Profiles".
- **Hành động**: Tất cả các file UC liên quan đã được Override và cập nhật Rule Phân Quyền. Master List đã ghi nhận Changelog. Kiến trúc sẵn sàng bàn giao cho Đội Dev.
