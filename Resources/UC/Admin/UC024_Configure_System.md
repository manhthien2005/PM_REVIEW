# UC024 - CẤU HÌNH HỆ THỐNG TOÀN CỤC

## 1. Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC024                                                                                                                                                                                                                                                    |
| **Tên UC**         | Cấu hình hệ thống toàn cục (Global System Settings)                                                                                                                                                                                                      |
| **Tác nhân chính** | Quản trị viên cấp cao (Super Admin)                                                                                                                                                                                                                      |
| **Mô tả**          | Cung cấp cho Admin quyền lực cao nhất để tinh chỉnh các hoạt động cốt lõi của hệ thống, bao gồm cấu hình độ nhạy AI (ngừa false alarm), cấu hình luồng thông báo Push Notification, đặt ngưỡng sinh tồn mặc định và đưa hệ thống vào trạng thái bảo trì. |
| **Trigger**        | Admin truy cập mục "Cấu hình hệ thống" trên màn hình điều khiển (Admin Dashboard).                                                                                                                                                                       |
| **Tiền điều kiện** | Admin đã đăng nhập và được gắn quyền `super_admin` hoặc có permission tương đương.                                                                                                                                                                       |
| **Hậu điều kiện**  | Cấu hình mới được ghi vào DB. Backend workers tự động reload cấu hình mới (ngay lập tức hoặc tính từ chu kỳ kế tiếp). Hệ thống ghi log kiểm toán (`audit_logs`) mọi thay đổi.                                                                            |

---

## 2. Các Nhóm Cấu Hình Thực Tế (Configuration Domains)

Thiết kế màn hình này đem lại tính thực tiễn cao cho sản phẩm để quản lý chi phí và độ ổn định thực tế, bao gồm 4 nhóm chính tương ứng với bảng `system_settings` dưới Database:

1. **AI & Fall Detection (Chống False Alarm)**
   - `confidence_threshold` (Ngưỡng tự tin AI - vd: 0.85): Nếu AI quá nhạy và báo sai nheieù, admin tăng con số này lên.
   - `auto_sos_countdown_sec` (Thời gian đếm ngược - mặc định: 30s): Cho phép user có thời gian bấm CANCEL trước khi hệ thống tự động gọi cấp cứu.
   - `enable_auto_sos` (Tự kích hoạt SOS): Kill-switch đóng/mở hoàn toàn khả năng tự tạo SOS (Dùng khi Call Center đang quá tải).

2. **Quản lý Kênh Liên lạc (Communication Channels)**
   - Hệ thống sử dụng hoàn toàn **Push Notification** qua ứng dụng di động để gửi cảnh báo nhằm tối ưu chi phí và đảm bảo tính tức thời.
   - Các cấu hình SMS/Voice Call đã được loại bỏ phân hệ này.

3. **Cấu hình Sinh tồn Mặc định (Clinical Defaults)**
   - SpO2 Min (92%), Nhịp tim Min/Max (50-120). Nếu bác sĩ/caregiver quên thiết lập ngưỡng cá nhân cho bệnh nhân, hệ thống sẽ sử dụng các **Global Default** này làm căn cứ chốt chặn.

4. **Bảo mật & Bảo trì (Security & Maintenance)**
   - `maintenance_mode` (Chế độ bảo trì): Kích hoạt sẽ hiển thị "Đang bảo trì" cho tất cả người dùng (app, web), ngoại trừ tài khoản có quyền Admin để test hệ thống.
   - `session_timeout_minutes`: Thời gian rảnh của phiên đăng nhập trước khi buộc văng ra (ví dụ: 60 phút).

---

## 3. Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                  |
| ---- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập menu "Cấu hình hệ thống".                                                                                                                                                                         |
| 2    | Hệ thống        | Query bảng `system_settings` và render UI form chia thành 4 tab: **AI**, **Notification**, **Sinh tồn**, và **Bảo trì**.                                                                                   |
| 3    | Admin           | Thay đổi một tham số. Ví dụ: Thay đổi `auto_sos_countdown_sec` từ 30 -> 20.                                                                                                                                |
| 4    | Admin           | Bấm "Lưu Thay Đổi".                                                                                                                                                                                        |
| 5    | Hệ thống        | Hiển thị hộp thoại xác nhận (Modal): "Bạn đang thay đổi cấu hình lõi của hệ thống. Nhập lại mật khẩu để tiếp tục."                                                                                         |
| 6    | Admin           | Nhập mật khẩu (Password confirmation) và xác nhận.                                                                                                                                                         |
| 7    | Hệ thống        | Validate mật khẩu và định dạng dữ liệu, sau đó lưu thay đổi vào DB dạng JSON.                                                                                                                              |
| 8    | Hệ thống        | Ghi bản ghi vào `audit_logs` chi tiết: `action: settings.changed`, bao gồm JSON `{old_value, new_value}`. Phát sự kiện (Event Bus/Redis) để các Background Workers cập nhật config vào bộ nhớ đệm (Cache). |
| 9    | Hệ thống        | Thông báo "Cập nhật thành công. Lệnh thay đổi sẽ mất khoảng 1-2 phút để LAN toả ra toàn bộ hệ thống".                                                                                                      |

---

## 4. Luồng thay thế (Alternative Flows)

### 4.a Xác nhận mật khẩu sai
| Bước  | Người thực hiện | Hành động                                                                               |
| ----- | --------------- | --------------------------------------------------------------------------------------- |
| 5.a.1 | Hệ thống        | Phát hiện mật khẩu admin nhập vào không hợp lệ.                                         |
| 5.a.2 | Hệ thống        | Hiển thị cảnh báo: "Mật khẩu xác nhận không đúng. Việc thay đổi bị huỷ bỏ". Đóng Modal. |
| 5.a.3 | Admin           | Bấm "Lưu Thay Đổi" lần nữa để kích hoạt lại luồng nhập mật khẩu (Trở về bước 5).        |

### 4.b Thay đổi cấu hình sai logic kinh doanh
| Bước  | Người thực hiện | Hành động                                                                        |
| ----- | --------------- | -------------------------------------------------------------------------------- |
| 3.b.1 | Admin           | Cố tình thiết lập SpO2 Min > 100% hoặc Nhịp tim Min > Nhịp tim Max, v.v..        |
| 7.b.1 | Hệ thống        | Bước kiểm tra (Validate) phát hiện lỗi logic phi lý này.                         |
| 7.b.2 | Hệ thống        | Tô đỏ Input box, thông báo "Thông số logic không hợp lệ. Vui lòng kiểm tra lại". |

---

## 5. Business Rules (Quy tắc nghiệp vụ)

- **BR-024-01 (Strict Auth):** Do tính chất thay đổi toàn cục rủi ro cao, không chỉ kiểm tra Access Token (JWT), quá trình lưu phải có **Re-authentication (Nhập lại mật khẩu)**.
- **BR-024-02 (Auditability):** Bất kì sự sai lệch nào ở form gửi đi so với trạng thái DB cũ đều phải bắn vào Hypertable `audit_logs` để truy vết (Phòng hờ admin phá hoại).
- **BR-024-03 (Cache Invalidation):** Sau khi lưu DB thành công, hệ thống phải phát một tín hiệu (vd qua Pub/Sub Redis) để đả thông các Worker đang xử lí SOS/Notification biết mà clear cache cấu hình cũ, tải cái mới về.

---

## 6. Yêu cầu phi chức năng (NFR)

- **Performance (Tốc độ):** Đọc cấu hình nhanh < 50ms (Được Cache ở Memory backend).
- **Reliability (Đáng tin cậy):** Nếu database lỗi giữa chừng, không lưu thành công phải rollback, chặn không cho Redis clear cache. 
- **Usability (Trực quan):** Phải giải thích chi tiết ý nghĩa của tham số cấu hình bằng Tooltip (Hover) bên cạnh từng Input field.
