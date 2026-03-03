# UC042 - XEM TRẠNG THÁI THIẾT BỊ

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC042 |
| **Tên UC** | Xem trạng thái thiết bị |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem trạng thái hiện tại của thiết bị (online/offline, pin, tín hiệu, lần cuối gửi dữ liệu). |
| **Trigger** | Người dùng mở màn "Thiết bị" hoặc xem chi tiết thiết bị trên app. |
| **Tiền điều kiện** | Thiết bị đã được kết nối với tài khoản (UC040). |
| **Hậu điều kiện** | Người dùng nắm được trạng thái thiết bị để xử lý khi thiết bị offline/hết pin. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Mở màn "Thiết bị" trên app. |
| 2 | Hệ thống | Truy vấn bảng `devices` cho user hiện tại. |
| 3 | Hệ thống | Hiển thị danh sách thiết bị với thông tin: Tên, Loại, Pin (%), Trạng thái kết nối (online/offline), Lần cuối gửi dữ liệu (`last_seen_at`). |
| 4 | Người dùng | Chọn 1 thiết bị để xem chi tiết. |
| 5 | Hệ thống | Hiển thị chi tiết: mức pin, RSSI (`signal_strength`), trạng thái active, thời điểm `last_sync_at`, cảnh báo nếu thiết bị offline quá lâu. |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Không có thiết bị nào gán

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống | Không tìm thấy thiết bị nào cho user. |
| 3.a.2 | Hệ thống | Hiển thị "Bạn chưa kết nối thiết bị nào" và gợi ý chạy UC040. |

### 5.a - Thiết bị offline quá lâu

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Nếu `NOW() - last_seen_at > X` (VD: 30 phút). |
| 5.a.2 | Hệ thống | Hiển thị cảnh báo "Thiết bị đã mất kết nối quá lâu. Vui lòng kiểm tra pin/kết nối." |

---

## Business Rules

- **BR-042-01**: Trạng thái online/offline được quyết định dựa trên `last_seen_at` và một ngưỡng thời gian cấu hình (VD: 2 phút). 
- **BR-042-02**: Nếu `battery_level < 20`, hiển thị cảnh báo "Pin yếu" (có thể map sang alert `low_battery`). 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Trang thái được thể hiện bằng icon/màu sắc dễ hiểu (xanh = online, xám = offline, đỏ = lỗi). 
- **Performance**: 
  - Thời gian tải danh sách thiết bị < 1 giây cho user có ít thiết bị (1–5). 

