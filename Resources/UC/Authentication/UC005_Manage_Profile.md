# UC005 - QUẢN LÝ HỒ SƠ CÁ NHÂN

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC005                                                                                                                                                                                                                   |
| **Tên UC**         | Quản lý hồ sơ cá nhân                                                                                                                                                                                                   |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc                                                                                                                                                                                               |
| **Mô tả**          | Người dùng xem và cập nhật thông tin cá nhân (họ tên, SĐT, ngày sinh, ảnh đại diện) và thông tin y tế (tiền sử bệnh lý, nhóm máu, chiều cao, cân nặng, thuốc đang dùng, dị ứng) — dữ liệu y tế dùng cho AI Risk Scoring |
| **Trigger**        | Người dùng chọn "Hồ sơ cá nhân" trong Cài đặt                                                                                                                                                                           |
| **Tiền điều kiện** | Người dùng đã đăng nhập                                                                                                                                                                                                 |
| **Hậu điều kiện**  | - Thông tin cá nhân và y tế được cập nhật<br>- Nếu cập nhật thông tin y tế → AI Risk Score có thể thay đổi ở lần đánh giá tiếp theo                                                                                     |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                                      |
| ---- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1    | Người dùng      | Truy cập "Cài đặt" → "Hồ sơ cá nhân"                                                                                                                                           |
| 2    | Hệ thống        | Hiển thị thông tin hiện tại: ảnh đại diện, họ tên, email (readonly), SĐT, ngày sinh, giới tính, thông tin y tế (tiền sử bệnh lý, nhóm máu, chiều cao, cân nặng, thuốc, dị ứng) |
| 3    | Người dùng      | Chỉnh sửa thông tin muốn thay đổi                                                                                                                                              |
| 4    | Người dùng      | Nhấn "Lưu thay đổi"                                                                                                                                                            |
| 5    | Hệ thống        | Validate dữ liệu (SĐT hợp lệ, ngày sinh trong quá khứ, chiều cao/cân nặng hợp lệ)                                                                                              |
| 6    | Hệ thống        | Cập nhật thông tin cá nhân và dữ liệu y tế (nếu có thay đổi)                                                                                                                   |
| 7    | Hệ thống        | Hiển thị "Cập nhật hồ sơ thành công"                                                                                                                                           |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Cập nhật ảnh đại diện
| Bước  | Người thực hiện | Hành động                                      |
| ----- | --------------- | ---------------------------------------------- |
| 3.a.1 | Người dùng      | Chạm vào ảnh đại diện                          |
| 3.a.2 | Hệ thống        | Hiển thị tùy chọn: Chụp ảnh / Chọn từ thư viện |
| 3.a.3 | Người dùng      | Chọn ảnh                                       |
| 3.a.4 | Hệ thống        | Crop và upload ảnh, hiển thị preview           |

### 3.b - Cập nhật tiền sử bệnh lý
| Bước  | Người thực hiện | Hành động                                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------- |
| 3.b.1 | Người dùng      | Chọn tab "Tiền sử bệnh lý"                                                             |
| 3.b.2 | Hệ thống        | Hiển thị checklist: Cao huyết áp, Tim mạch, Tiểu đường, Đột quỵ, Khác (ghi chú tự do)  |
| 3.b.3 | Người dùng      | Tick/untick hoặc nhập ghi chú                                                          |
| 3.b.4 | Hệ thống        | Lưu và thông báo "Việc cập nhật tiền sử bệnh sẽ ảnh hưởng đến kết quả đánh giá rủi ro" |

### 3.c - Cập nhật thông tin y tế chi tiết
| Bước  | Người thực hiện | Hành động                                                                                                                    |
| ----- | --------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 3.c.1 | Người dùng      | Chọn tab "Thông tin y tế"                                                                                                    |
| 3.c.2 | Hệ thống        | Hiển thị form: Nhóm máu (dropdown), Chiều cao (cm), Cân nặng (kg), Thuốc đang dùng (danh sách text), Dị ứng (danh sách text) |
| 3.c.3 | Người dùng      | Nhập/cập nhật thông tin                                                                                                      |
| 3.c.4 | Hệ thống        | Validate (chiều cao 50-250cm, cân nặng 2-500kg) và lưu                                                                       |
| 3.c.5 | Hệ thống        | Thông báo "Thông tin y tế đã được cập nhật"                                                                                  |

### 3.d - Yêu cầu xóa tài khoản (App Store / GDPR Compliance)
| Bước  | Người thực hiện | Hành động                                                                                                                    |
| ----- | --------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 3.d.1 | Người dùng      | Cuộn xuống cuối trang Hồ sơ, chọn "Xóa tài khoản vĩnh viễn"                                                                  |
| 3.d.2 | Hệ thống        | Hiển thị popup Cảnh báo đỏ: "Hành động này không thể hoàn tác. Dữ liệu y tế sẽ bị xóa/ẩn danh sau 30 ngày." Yêu cầu nhập MK. |
| 3.d.3 | Người dùng      | Nhập mật khẩu xác nhận và Tích chọn "Tôi hiểu hậu quả". Nhấn "Xác nhận xóa".                                                 |
| 3.d.4 | Hệ thống        | Đánh dấu tài khoản `deleted_at = NOW()`, đưa thông tin vào `users_archive`. Đăng xuất người dùng.                            |

### 5.a - Validation thất bại
| Bước  | Người thực hiện | Hành động                                                                          |
| ----- | --------------- | ---------------------------------------------------------------------------------- |
| 5.a.1 | Hệ thống        | Phát hiện SĐT không hợp lệ, thiếu trường bắt buộc, hoặc giá trị y tế ngoài phạm vi |
| 5.a.2 | Hệ thống        | Highlight trường lỗi và hiển thị message cụ thể                                    |

---

## Business Rules

- **BR-005-01**: Email không được sửa (readonly) — dùng làm identifier duy nhất
- **BR-005-02**: Tiền sử bệnh lý và thông tin y tế ảnh hưởng trực tiếp đến AI Risk Scoring (UC016)
- **BR-005-03**: Ảnh đại diện tối đa 5MB, định dạng JPG/PNG
- **BR-005-04**: Mọi thay đổi profile được ghi audit log
- **BR-005-05**: SĐT phải 10-11 số, bắt đầu bằng 0
- **BR-005-06**: Nhóm máu chỉ chấp nhận giá trị: A+, A-, B+, B-, AB+, AB-, O+, O-
- **BR-005-07**: Chiều cao (50-250 cm) và cân nặng (2-500 kg) phải là số dương hợp lệ
- **BR-005-08**: Thuốc đang dùng và dị ứng lưu dạng danh sách, cho phép thêm/xóa từng mục
- **BR-005-09**: Khi "Xóa tài khoản" được kích hoạt, hệ thống sẽ soft delete (`deleted_at`), đưa data tĩnh vào `users_archive`. Worker hệ thống sẽ tự động quét và thu dọn dữ liệu time-series (vitals, motion) liên quan sau chính xác 30 ngày (Data Retention Period).

---

## Data Requirements

### Input Data:
| Trường          | Kiểu       | Bắt buộc | Validation                     | Editable   |
| --------------- | ---------- | -------- | ------------------------------ | ---------- |
| Email           | String     | Có       | —                              | ❌ Readonly |
| Họ tên          | String     | Có       | 1-100 ký tự                    | ✅          |
| Số điện thoại   | String     | Có       | 10-11 số, bắt đầu bằng 0       | ✅          |
| Ngày sinh       | Date       | Có       | Trong quá khứ                  | ✅          |
| Giới tính       | Enum       | Không    | Nam / Nữ / Khác                | ✅          |
| Ảnh đại diện    | File       | Không    | JPG/PNG, ≤ 5MB                 | ✅          |
| Tiền sử bệnh    | JSON/Array | Không    | Checklist + ghi chú tự do      | ✅          |
| Nhóm máu        | Enum       | Không    | A+/A-/B+/B-/AB+/AB-/O+/O-      | ✅          |
| Chiều cao       | Number     | Không    | 50-250 cm                      | ✅          |
| Cân nặng        | Number     | Không    | 2-500 kg                       | ✅          |
| Thuốc đang dùng | Array/Text | Không    | Danh sách, mỗi mục ≤ 200 ký tự | ✅          |
| Dị ứng          | Array/Text | Không    | Danh sách, mỗi mục ≤ 200 ký tự | ✅          |

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
