# Health System - Báo Cáo Tiến Độ Tích Hợp API

Thư mục này theo dõi tiến độ và thứ tự ưu tiên xây dựng các API còn thiếu hoặc chưa được tích hợp thực tế (đang dùng Mock/Local-only) trong Mobile App.

## Tổng Quan Số Lượng & Danh Sách API

Dựa trên quá trình rà soát, hiện tại hệ thống còn **~22 endpoints và 1 kết nối WebSocket** cần được xây dựng phần backend và gắn vào Mobile App.

### [Phase 1: Core System, Devices & Notifications](./01_CORE_AND_NOTIFICATIONS.md) (9 APIs + 1 WS)

- [ ] `POST /devices/scan/pair` : Ghép nối thiết bị - `🧪 MOCK-ONLY`
- [ ] `PUT /devices/{id}/settings` : Lưu cấu hình thiết bị - `🧪 MOCK-ONLY`
- [ ] `POST /devices/{id}/unpair` : Hủy kết nối của một thiết bị - `🧪 MOCK-ONLY`
- [ ] `GET /dashboard/summary` : Widget tổng quan ở màn hình Home - `🧪 MOCK-ONLY`
- [ ] `GET /notifications` : Lấy danh sách lịch sử thông báo - `❌ MISSING`
- [ ] `GET /notifications/{id}` : Xem chi tiết nội dung của thông báo - `❌ MISSING`
- [ ] `PUT /notifications/{id}/read` : Đánh dấu thông báo đã đọc - `❌ MISSING`
- [ ] `WS / Fcm` (Incoming Alert) : Kết nối realtime nhận cảnh báo khẩn cấp/SOS - `❌ MISSING`
- [ ] `GET /settings/general` : Cấu hình chung của ứng dụng - `❌ MISSING`
- [ ] `PUT /settings/general` : Lưu thay đổi thiết lập ứng dụng - `❌ MISSING`

### [Phase 2: Health, Monitoring & Analysis](./02_HEALTH_AND_ANALYSIS.md) (6 APIs)

- [ ] `GET /metrics/vitals/{type}` : Dữ liệu chuỗi thời gian (timeseries) cho biểu đồ sinh hiệu - `🧪 MOCK-ONLY`
- [ ] `GET /metrics/health-report` : Báo cáo thống kê sức khỏe tổng quan - `🧪 MOCK-ONLY`
- [ ] `PUT /metrics/sleep/settings` : Cập nhật mục tiêu giấc ngủ cá nhân - `🧩 LOCAL-ONLY`
- [ ] `GET /analysis/risk-reports` : Danh sách lịch sử báo cáo cảnh báo AI - `🧪 MOCK-ONLY`
- [ ] `GET /analysis/risk-reports/{id}` : Xem chi tiết phân tích rủi ro/lời khuyên AI - `🧪 MOCK-ONLY`
- [ ] `GET /analysis/risk-history` : Biểu đồ thay đổi rủi ro theo các tuần - `🧪 MOCK-ONLY`

### [Phase 3: Family & Sharing](./03_FAMILY_AND_SHARING.md) (7 APIs)

- [ ] `GET /family/dashboard` : Trạng thái sức khỏe người thân đang liên kết - `🧪 MOCK-ONLY`
- [ ] `GET /family/contacts` : Danh sách người đang được theo dõi / người theo dõi - `🧪 MOCK-ONLY`
- [ ] `POST /family/contacts/request` : Gửi yêu cầu theo dõi người mới - `🧪 MOCK-ONLY`
- [ ] `PUT /family/contacts/request/accept` : Chấp nhận yêu cầu theo dõi - `🧪 MOCK-ONLY`
- [ ] `DELETE /family/contacts/{id}/unlink` : Xóa liên kết tài khoản - `🧪 MOCK-ONLY`
- [ ] `GET /family/contacts/{id}/detail` : Xem bản sao dữ liệu sức khỏe của người thân - `🧪 MOCK-ONLY`
- [ ] `PUT /family/contacts/{id}/permissions` : Điều chỉnh quyền riêng tư dữ liệu cho từng người - `🧪 MOCK-ONLY`

---

## Change Log

> Quy ước: Mỗi khi có API nào được tích hợp thật vào Mobile App, hãy cập nhật lại số lượng ở trên và thêm một dòng vào bảng dưới đây.

| Ngày Cập Nhật | Phiên Bản | Người Cập Nhật | Nội Dung Thay Đổi                                                               |
| :------------ | :-------: | :------------- | :------------------------------------------------------------------------------ |
| 2026-03-22    |   v1.0    | Codex          | Khởi tạo tài liệu thống kê số lượng API; Phân rã tiến độ thành 3 Phase ưu tiên. |
