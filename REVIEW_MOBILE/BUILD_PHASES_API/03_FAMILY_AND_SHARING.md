# Phase 3: Family & Sharing

Phase này hiện tại đang Mock 100%. Đây là chức năng mạng xã hội/kết nối thu nhỏ, phụ thuộc vào dữ liệu Vitals và Analytics đã có.

## 1. Family Dashboard

- **GET /family/dashboard**: Danh sách nhanh trạng thái sức khỏe tóm tắt của tất cả thành viên trong nhóm gia đình.

## 2. Contact Management

- **GET /family/contacts**: Lấy danh sách những người liên hệ (caregivers / dependents).
- **POST /family/contacts/request**: Gửi lời mời liên kết theo dõi sức khỏe đến một user khác qua QR/SĐT.
- **PUT /family/contacts/request/accept**: Chấp nhận yêu cầu theo dõi.
- **DELETE /family/contacts/{id}/unlink**: Gỡ bỏ liên kết người theo dõi.

## 3. Member Detail & Settings

- **GET /family/contacts/{id}/detail**: Lấy chi tiết hồ sơ sức khỏe hiện tại của một thành viên (nếu được cấp quyền).
- **PUT /family/contacts/{id}/permissions**: (LinkedContact Settings) Thay đổi quyền được xem (ví dụ: chỉ cho xem SOS, không cho xem Vitals chi tiết).
