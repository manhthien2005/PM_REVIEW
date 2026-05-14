# UC020 - PHÂN TÍCH GIẤC NGỦ

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC020 |
| **Tên UC** | Phân tích giấc ngủ |
| **Tác nhân chính** | User |
| **Mô tả** | Hệ thống phân tích dữ liệu trong thời gian ngủ (được cấu hình) để ước tính chất lượng giấc ngủ và các chỉ số liên quan. |
| **Trigger** | - Người dùng bật chế độ "Theo dõi giấc ngủ" trên app.<br>- Hoặc hệ thống tự động nhận diện khung giờ ngủ đã cấu hình (VD: 22:00–06:00). |
| **Tiền điều kiện** | - Người dùng đeo thiết bị trong lúc ngủ.<br>- Thiết bị thu thập đủ dữ liệu (nhịp tim, chuyển động). |
| **Hậu điều kiện** | - Hệ thống ghi lại một phiên "giấc ngủ" với các chỉ số tổng hợp để dùng cho UC021. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Bật "Theo dõi giấc ngủ" hoặc xác nhận giờ đi ngủ trên app. |
| 2 | Hệ thống | Ghi nhận thời điểm bắt đầu ngủ dự kiến và gắn cờ cho dữ liệu time-series trong khung thời gian này. |
| 3 | Hệ thống | Thu thập liên tục dữ liệu `vitals` và `motion_data` trong suốt thời gian ngủ. |
| 4 | Hệ thống (Batch/Background) | Sau khi hết khung giờ ngủ (hoặc người dùng xác nhận "Thức dậy"), hệ thống chạy job phân tích: tính tổng thời gian ngủ, thời gian tỉnh, số lần thức giữa đêm, nhịp tim trung bình, v.v. |
| 5 | Hệ thống | Lưu kết quả vào bảng phân tích giấc ngủ (theo thiết kế DB/AI – có thể là bảng mới hoặc một phần của `risk_scores`). |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Thiết bị bị tháo giữa chừng

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống | Phát hiện không có dữ liệu trong một khoảng dài bất thường (VD: > 30 phút). |
| 3.a.2 | Hệ thống | Đánh dấu phiên giấc ngủ là "Không hoàn chỉnh" và hiển thị cảnh báo trong UC021. |

### 4.a - Người dùng ngủ ngoài khung giờ mặc định

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống | Nhận thấy nhiều khoảng thời gian bất động + nhịp tim giảm trong ban ngày. |
| 4.a.2 | Hệ thống | Gợi ý người dùng xác nhận đó có phải là "giấc ngủ trưa" để phân tích riêng. |

---

## Business Rules

- **BR-020-01**: Một ngày có thể có nhiều phiên giấc ngủ (VD: ngủ đêm + ngủ trưa). 
- **BR-020-02**: Phiên giấc ngủ phải có tối thiểu X phút dữ liệu liên tục (VD: 2 giờ) mới được tính là hợp lệ. 
- **BR-020-03**: Các chỉ số phân tích chính: tổng thời gian ngủ, thời gian nằm nhưng không ngủ, số lần tỉnh giấc, nhịp tim trung bình và thấp nhất trong lúc ngủ. 

---


## Business Rules - Phân quyền (Authorization)
- **BR-Auth-01**: User A chỉ được phép truy vấn/xem dữ liệu y tế của User B nếu ID của cả hai tồn tại trong bảng `user_relationships` và có cờ `can_view_vitals = true` (hoặc User A xem dữ liệu của chính mình).

## Yêu cầu phi chức năng

- **Performance**: 
  - Job phân tích có thể chạy batch sau khi người dùng thức dậy; không yêu cầu real-time. 
- **Usability**: 
  - Giao diện bật/tắt chế độ theo dõi giấc ngủ đơn giản, dễ hiểu. 
- **Privacy**: 
  - Dữ liệu giấc ngủ được đối xử tương đương dữ liệu y tế nhạy cảm; không chia sẻ ra ngoài nếu không có sự đồng ý. 

