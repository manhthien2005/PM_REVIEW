# UC005 - QUẢN LÝ HỒ SƠ CÁ NHÂN

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC005 |
| **Tên UC** | Quản lý hồ sơ cá nhân |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem và cập nhật thông tin cá nhân, bao gồm họ tên, SĐT, ngày sinh, ảnh đại diện, và tiền sử bệnh lý (dùng cho AI Risk Scoring) |
| **Trigger** | Người dùng chọn "Hồ sơ cá nhân" trong Cài đặt |
| **Tiền điều kiện** | Người dùng đã đăng nhập |
| **Hậu điều kiện** | - Thông tin cá nhân được cập nhật trong DB<br>- Nếu cập nhật tiền sử bệnh lý → AI Risk Score có thể thay đổi ở lần đánh giá tiếp theo |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập "Cài đặt" → "Hồ sơ cá nhân" |
| 2 | Hệ thống | Hiển thị thông tin hiện tại: ảnh đại diện, họ tên, email (readonly), SĐT, ngày sinh, giới tính, tiền sử bệnh lý |
| 3 | Người dùng | Chỉnh sửa thông tin muốn thay đổi |
| 4 | Người dùng | Nhấn "Lưu thay đổi" |
| 5 | Hệ thống | Validate dữ liệu (SĐT hợp lệ, ngày sinh trong quá khứ) |
| 6 | Hệ thống | Cập nhật thông tin trong bảng `users` + `medical_history` (nếu có) |
| 7 | Hệ thống | Hiển thị "Cập nhật hồ sơ thành công" |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Cập nhật ảnh đại diện
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Người dùng | Chạm vào ảnh đại diện |
| 3.a.2 | Hệ thống | Hiển thị tùy chọn: Chụp ảnh / Chọn từ thư viện |
| 3.a.3 | Người dùng | Chọn ảnh |
| 3.a.4 | Hệ thống | Crop và upload ảnh, hiển thị preview |

### 3.b - Cập nhật tiền sử bệnh lý
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.b.1 | Người dùng | Chọn tab "Tiền sử bệnh lý" |
| 3.b.2 | Hệ thống | Hiển thị checklist: Cao huyết áp, Tim mạch, Tiểu đường, Đột quỵ, Khác (ghi chú tự do) |
| 3.b.3 | Người dùng | Tick/untick hoặc nhập ghi chú |
| 3.b.4 | Hệ thống | Lưu và thông báo "Việc cập nhật tiền sử bệnh sẽ ảnh hưởng đến kết quả đánh giá rủi ro" |

### 5.a - Validation thất bại
| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Hệ thống | Phát hiện SĐT không hợp lệ hoặc thiếu trường bắt buộc |
| 5.a.2 | Hệ thống | Highlight trường lỗi và hiển thị message cụ thể |

---

## Business Rules

- **BR-005-01**: Email không được sửa (readonly) — dùng làm identifier duy nhất
- **BR-005-02**: Tiền sử bệnh lý ảnh hưởng trực tiếp đến AI Risk Scoring (UC016)
- **BR-005-03**: Ảnh đại diện tối đa 5MB, định dạng JPG/PNG
- **BR-005-04**: Mọi thay đổi profile được ghi audit log
- **BR-005-05**: SĐT phải 10-11 số, bắt đầu bằng 0

---

## Data Requirements

### Input Data:
| Trường | Kiểu | Bắt buộc | Validation | Editable |
|--------|------|----------|------------|----------|
| Email | String | Có | — | ❌ Readonly |
| Họ tên | String | Có | 1-100 ký tự | ✅ |
| Số điện thoại | String | Có | 10-11 số, bắt đầu bằng 0 | ✅ |
| Ngày sinh | Date | Có | Trong quá khứ | ✅ |
| Giới tính | Enum | Không | Nam / Nữ / Khác | ✅ |
| Ảnh đại diện | File | Không | JPG/PNG, ≤ 5MB | ✅ |
| Tiền sử bệnh | JSON/Array | Không | Checklist + ghi chú tự do | ✅ |

---

## Yêu cầu phi chức năng

- **Privacy**: Tuân thủ các nguyên tắc bảo vệ dữ liệu cá nhân (tương đương HIPAA ở mức độ học thuật) — dữ liệu bệnh lý nhạy cảm
- **Usability**: 
  - Form đơn giản, font lớn, phù hợp người cao tuổi
  - Avatar crop tool tích hợp
- **Performance**: Cập nhật profile < 2 giây, upload ảnh < 5 giây
- **Security**: Chỉ user chủ tài khoản mới sửa được profile của mình

---

## Mối quan hệ với UC khác

- **Input cho UC016 (Risk Report)**: Tiền sử bệnh lý → AI Risk Scoring
- **Extends UC002 (Register)**: Thông tin từ đăng ký có thể được bổ sung/sửa tại đây
- **Khác UC004 (Change Password)**: Đổi mật khẩu tách riêng, không nằm trong profile
