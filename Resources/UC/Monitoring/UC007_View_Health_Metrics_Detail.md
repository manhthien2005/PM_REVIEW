# UC007 - XEM CHI TIẾT CHỈ SỐ SỨC KHỎE

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC007 |
| **Tên UC** | Xem chi tiết chỉ số sức khỏe |
| **Tác nhân chính** | User |
| **Mô tả** | Người dùng xem chi tiết một chỉ số sức khỏe (nhịp tim, SpO₂, huyết áp, nhiệt độ) với thống kê và biểu đồ theo khoảng thời gian linh hoạt. |
| **Trigger** | Người dùng chọn 1 chỉ số cụ thể trên màn hình UC006 hoặc truy cập màn hình “Chi tiết chỉ số”. |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Đã có thiết bị gán với tài khoản và có dữ liệu trong khoảng thời gian chọn. |
| **Hậu điều kiện** | - Người dùng xem được thống kê chi tiết cho chỉ số đã chọn.<br>- (Tuỳ chọn) Người dùng có thể xuất dữ liệu hoặc thay đổi khoảng thời gian xem. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Từ màn hình UC006, chọn 1 chỉ số (VD: Nhịp tim) hoặc chọn "Xem chi tiết". |
| 2 | Hệ thống | Hiển thị màn hình "Chi tiết Nhịp tim" với khoảng thời gian mặc định (24 giờ gần nhất). |
| 3 | Hệ thống | Truy vấn dữ liệu đã được tổng hợp tương ứng với khoảng thời gian (dữ liệu 5 phút, theo giờ, theo ngày). |
| 4 | Hệ thống | Hiển thị:<br>- Biểu đồ đường (line chart)<br>- Giá trị min/max/avg<br>- Số lần vượt ngưỡng cảnh báo trong khoảng thời gian đó. |
| 5 | Người dùng | Thay đổi khoảng thời gian (1h, 24h, 7 ngày, 30 ngày, tuỳ chỉnh from/to). |
| 6 | Hệ thống | Nạp lại dữ liệu và cập nhật biểu đồ + thống kê theo khoảng thời gian mới. |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Không có dữ liệu trong khoảng thời gian chọn

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống | Phát hiện không có bản ghi nào trong khoảng thời gian được chọn. |
| 3.a.2 | Hệ thống | Hiển thị thông báo "Chưa có dữ liệu trong khoảng thời gian này" và gợi ý khoảng gần nhất có dữ liệu. |

### 5.a - Khoảng thời gian quá dài (ảnh hưởng hiệu năng)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người dùng | Chọn khoảng thời gian quá dài (VD: > 1 năm). |
| 5.a.2 | Hệ thống | Hiển thị cảnh báo "Khoảng thời gian quá dài, vui lòng thu hẹp phạm vi để hiển thị nhanh hơn". |
| 5.a.3 | Hệ thống | Gợi ý các mốc: 1 tháng, 3 tháng, 6 tháng. |

### 6.a - Xuất dữ liệu

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 6.a.1 | Người dùng | Chọn "Xuất dữ liệu" (CSV/PDF). |
| 6.a.2 | Hệ thống | Tạo file theo khoảng thời gian hiện tại. |
| 6.a.3 | Hệ thống | Cho phép tải file CSV hoặc chia sẻ PDF (qua email/zalo,...). |

---

## Business Rules

- **BR-007-01**: Mặc định hiển thị 24 giờ gần nhất khi vào màn hình chi tiết lần đầu.
- **BR-007-02**: Sử dụng dữ liệu từ các bảng tổng hợp (theo 5 phút, theo giờ, theo ngày) để tối ưu hiệu năng.
- **BR-007-03**: Chỉ cho phép chọn khoảng thời gian tối đa 1 năm trong 1 lần truy vấn.
- **BR-007-04**: Tôn trọng quyền truy cập của caregiver (chỉ xem bệnh nhân mà họ được gán quyền giám sát). 

---


## Business Rules - Phân quyền (Authorization)
- **BR-Auth-01**: User A chỉ được phép truy vấn/xem dữ liệu y tế của User B nếu ID của cả hai tồn tại trong bảng `user_relationships` và có cờ `can_view_vitals = true` (hoặc User A xem dữ liệu của chính mình).

## Yêu cầu phi chức năng

- **Performance**: 
  - Thời gian tải biểu đồ chi tiết < 2 giây cho 30 ngày dữ liệu.
- **Usability**: 
  - Biểu đồ có chú thích rõ ràng, có thể chạm vào điểm dữ liệu để xem giá trị chính xác.
  - Hỗ trợ zoom/pan trên biểu đồ (trên mobile dùng pinch-to-zoom).
- **Security**: 
  - Các API lấy dữ liệu chi tiết phải xác thực JWT và kiểm tra quyền truy cập.

