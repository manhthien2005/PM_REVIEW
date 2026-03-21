# Kế Hoạch Triển Khai Chi Tiết: Module Gia Đình (Refactor)

## Mục Tiêu
Cấu trúc lại toàn bộ tab `Gia đình` thành 2 tab con (`Theo dõi` và `Liên hệ`), tập trung vào UI/UX và Mock Data theo đúng document `FAMILY_TabGiaDinh_Refactor_Spec.md`. Không gọi API BE thực.

## Phase 1: Chuẩn bị Provider & Mock Data
*Vì chỉ làm Frontend, ta cần nguồn dữ liệu giả lập chuẩn xác cho các state khác nhau.*
- [ ] Tạo file `family_mock_data.dart` định nghĩa các model:
  - `ContactProfile`: ID, Avatar, Tên, Labels, Trạng thái (pending/accepted).
  - `ContactPermissions`: `can_view_vitals`, `can_receive_alerts`, `can_view_location`.
  - `HealthStatus`: `stable`, `attention`, `sos_active`, `offline`.
- [ ] Tạo file `family_provider.dart` (hoặc `contact_provider.dart` / `tracking_provider.dart`) expose các list contacts tương ứng:
  - List `pendingRequests`.
  - List `acceptedContacts` (dùng cho tab Liên hệ).
  - List `monitorableProfiles` (lọc từ accepted + `can_view_vitals == true` - dùng cho tab Theo dõi).
- [ ] Thêm các method mock: acceptRequest, togglePermission, updateLabel, removeContact.

## Phase 2: FAMILY_Shell (Khung điều hướng chính)
- [ ] Tạo `FamilyShellScreen` (`family_shell_screen.dart`).
- [ ] Vẽ App bar với title "Gia đình" và chung style `HealthGuard Calm`.
- [ ] Thêm Segmented Control / TabBar chuyển đổi giữa `Theo dõi` và `Liên hệ`.
- [ ] Setup logic đổi index tab.

## Phase 3: PROFILE_ContactList (Tab Liên hệ)
- [ ] Tạo màn `ContactListScreen` (nằm trong shell).
- [ ] Xây dựng **Hero summary**: Hiển thị tổng số liên hệ, số pending. Nút CTA "Thêm liên hệ mới".
- [ ] Xây dựng **Pending Section**: List các yêu cầu kết bạn đến, nút "Chấp nhận" / "Từ chối".
- [ ] Xây dựng **Accepted Section**: List các người đã liên kết, hiển thị rõ Tên, Nhãn, Tóm tắt quyền.
- [ ] Xử lý state rỗng (Empty State) mượt mà cho cả pending và accepted list.

## Phase 4: PROFILE_AddContact (Thêm liên hệ)
- [ ] Tạo màn `AddContactScreen`.
- [ ] Thêm Segmented Switch: `Quét mã` và `Mã của tôi`.
- [ ] Xây dựng UI mode `Quét mã`: Khung camera giả lập, text hướng dẫn quét QR người thân, bottom sheet "Xác nhận kết nối".
- [ ] Xây dựng UI mode `Mã của tôi`: Hình ảnh QR code lớn (dùng icon hoặc ảnh dummy), PIN code to rõ chữ, nút "Chia sẻ".

## Phase 5: PROFILE_LinkedContactDetail (Chi tiết cấu hình liên hệ)
- [ ] Tạo màn `LinkedContactDetailScreen`.
- [ ] Vẽ **Hero Card**: Tên, Avatar, Label hiện tại.
- [ ] Vẽ **Permission Cards**: 3 block toggle buttons (Xem chỉ số, Nhận cảnh báo, Xem vị trí). Có text giải thích rõ ràng.
- [ ] Vẽ **Label Management Card**: Đổi nhãn (VD: Vợ, Bố, Mẹ).
- [ ] Vẽ **Danger Zone**: Nút "Huỷ liên kết" chữ đỏ, popup xác nhận trước khi xóa.

## Phase 6: FAMILY_Tracking (Tab Theo dõi)
*(Màn hình này sẽ hiển thị các đối tượng đủ điều kiện theo dõi)*
- [ ] Sửa lại màn `HomeFamilyDashboard` cũ (thành `FamilyTrackingScreen`) hoặc refactor lại.
- [ ] Xây dựng **Hero Dashboard**: Text tổng quan "Đang theo dõi 3 người", hiển thị số người cần chú ý, số SOS.
- [ ] Xây dựng **Filter Chips**: `Tất cả`, `SOS`, `Cần chú ý`, `Ưu tiên`.
- [ ] Xây dựng **FamilyProfileHealthCard**: Card hiển thị avatar, tên, nhịp tim/huyết áp preview, và trạng thái màu sắc theo mức độ (đỏ - SOS, vàng - Chú ý, xanh - Ổn định).
- [ ] Xử lý **Permission-needed State**: Hiển thị card ảo báo "Bạn có 1 liên hệ chưa cấp quyền xem chỉ số", CTA "Đi tới Liên hệ".

## Phase 7: FAMILY_PersonDetail (Chi tiết theo dõi 1 người)
- [ ] Tạo màn `PersonDetailScreen`.
- [ ] Vẽ **Hero State Block**: Tên, nhãn, trạng thái (Ổn định/SOS/...), thời gian cập nhật gần nhất.
- [ ] Vẽ **Live Vitals Block**: Các card chỉ số sức khỏe mới nhất mượt mà, layout lưới 2x2.
- [ ] Vẽ **Alert History / Risk Summary Block**: Danh sách các cảnh báo nhịp tim/huyết áp gần đây của người đó.
- [ ] Xử lý logic Quick Action đi từ `Tracking` sang màn chi tiết cá nhân.
- [ ] Nếu có mock state SOS, hiện banner đỏ to trên đầu màn hình, CTA báo cấp cứu.
