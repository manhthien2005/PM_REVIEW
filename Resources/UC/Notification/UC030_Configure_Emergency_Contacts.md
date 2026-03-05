# UC030 - CẤU HÌNH NGƯỜI LIÊN HỆ KHẨN CẤP (EMERGENCY CONTACTS)

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                           |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC030                                                                                                                              |
| **Tên UC**         | Cấu hình Emergency Contacts                                                                                                        |
| **Tác nhân chính** | Bệnh nhân                                                                                                                          |
| **Mô tả**          | Bệnh nhân cấu hình danh sách người liên hệ khẩn cấp (người chăm sóc, người thân, bác sĩ) để hệ thống sử dụng khi gửi cảnh báo/SOS. |
| **Trigger**        | Người dùng truy cập phần "Người liên hệ khẩn cấp" trong cài đặt tài khoản.                                                         |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Tài khoản đã được xác minh (email/phone).                                                          |
| **Hậu điều kiện**  | Danh sách liên hệ khẩn cấp và mối quan hệ giám sát được cập nhật.                                                                  |

---

## Luồng chính (Main Flow) - Thêm mới Emergency Contact

| Bước | Người thực hiện | Hành động                                                                                                                                                                  |
| ---- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Bệnh nhân       | Vào "Cài đặt" → "Người liên hệ khẩn cấp".                                                                                                                                  |
| 2    | Hệ thống        | Hiển thị danh sách liên hệ hiện tại (nếu có) và nút "Thêm liên hệ mới".                                                                                                    |
| 3    | Bệnh nhân       | Chọn "Thêm liên hệ mới".                                                                                                                                                   |
| 4    | Hệ thống        | Hiển thị form: Họ tên, Số điện thoại, Quan hệ (vợ/chồng, con, bác sĩ...), Ưu tiên, Kênh nhận (SMS/Call/Push nếu là user trong hệ thống), Cho phép xem vị trí GPS (bật/tắt) |
| 5    | Bệnh nhân       | Nhập thông tin và nhấn "Lưu".                                                                                                                                              |
| 6    | Hệ thống        | Validate dữ liệu (số điện thoại hợp lệ, priority > 0, không trùng với contact hiện có).                                                                                    |
| 7    | Hệ thống        | Lưu liên hệ khẩn cấp và thiết lập quan hệ giám sát (nếu người liên hệ là user trong hệ thống).                                                                             |
| 8    | Hệ thống        | Hiển thị "Thêm liên hệ khẩn cấp thành công".                                                                                                                               |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Chỉnh sửa/Xóa liên hệ khẩn cấp

| Bước  | Người thực hiện | Hành động                                                                  |
| ----- | --------------- | -------------------------------------------------------------------------- |
| 2.a.1 | Bệnh nhân       | Chọn 1 contact trong danh sách.                                            |
| 2.a.2 | Hệ thống        | Hiển thị tuỳ chọn "Sửa" hoặc "Xoá".                                        |
| 2.a.3 | Bệnh nhân       | Chọn "Sửa", cập nhật thông tin và lưu lại **hoặc** chọn "Xoá" và xác nhận. |
| 2.a.4 | Hệ thống        | Cập nhật hoặc xoá bản ghi tương ứng trong DB.                              |

### 6.a - Nhập trùng số điện thoại

| Bước  | Người thực hiện | Hành động                                                             |
| ----- | --------------- | --------------------------------------------------------------------- |
| 6.a.1 | Hệ thống        | Phát hiện số điện thoại đã tồn tại trong danh sách liên hệ.           |
| 6.a.2 | Hệ thống        | Hiển thị "Số điện thoại này đã nằm trong danh sách liên hệ khẩn cấp". |

---

## Business Rules

- **BR-030-01**: Một user có thể có nhiều liên hệ khẩn cấp, nhưng priority phải là số nguyên dương; giá trị nhỏ hơn nghĩa là ưu tiên cao hơn. 
- **BR-030-02**: Khi gửi SOS, hệ thống sử dụng priority để quyết định thứ tự gọi/gửi SMS. 
- **BR-030-03**: Cho phép cấu hình kênh nhận thông báo (SMS/Call/Email/Push) tuỳ từng contact. 
- **BR-030-04**: Cho phép cấu hình quyền xem vị trí GPS cho từng người liên hệ (bật/tắt). 

---

## Yêu cầu phi chức năng

- **Usability**: 
  - Giao diện đơn giản, giải thích rõ vai trò của Emergency Contacts cho người dùng lớn tuổi. 
- **Security & Privacy**: 
  - Dữ liệu liên hệ khẩn cấp được bảo vệ như dữ liệu cá nhân, chỉ dùng cho mục đích khẩn cấp. 

