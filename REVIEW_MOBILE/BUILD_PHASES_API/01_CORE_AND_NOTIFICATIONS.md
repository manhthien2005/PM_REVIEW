# Phase 1: Core System, Devices & Notifications

Phase này tập trung vào các tính năng sống còn của ứng dụng: quản lý thiết bị thật, giao diện tổng quan và hệ thống real-time thông báo.

## 1. Device Management (Kết nối & Cấu hình)

Hiện tại `DEVICE_Connect` và `DEVICE_Configure` đang mock/delay.

- **POST /devices/scan/pair**: API ghép nối thiết bị (BLE/Network).
- **PUT /devices/{id}/settings**: Lưu cấu hình ngưỡng cảnh báo, tần suất đo của thiết bị.
- **POST /devices/{id}/unpair**: Hủy kết nối thiết bị.

## 2. Home Dashboard

Hiện tại `HOME_Dashboard` (màn hình chính) đang dùng mock.

- **GET /dashboard/summary**: Lấy thông tin tổng quan mới nhất (Vitals hiện tại, thiết bị đang kết nối hiệu năng, cảnh báo chưa đọc).

## 3. Notifications & Real-time Alerts

Hiện tại thiếu toàn bộ màn hình Notification và module nhận Alert đến.

- **GET /notifications**: Lấy danh sách lịch sử thông báo (phân trang).
- **GET /notifications/{id}**: Lấy chi tiết một thông báo/cảnh báo cụ thể.
- **PUT /notifications/{id}/read**: Đánh dấu đã đọc.
- **WebSocket / FCM Integration (EMERGENCY_IncomingAlert)**: Lắng nghe cảnh báo SOS từ người thân hoặc cảnh báo chỉ số nguy hiểm từ server theo thời gian thực.

## 4. Settings General

- **GET /settings/general**: Lấy cấu hình hệ thống (ngôn ngữ, theme, định dạng đo lường).
- **PUT /settings/general**: Cập nhật cấu hình ứng dụng/tài khoản tổng quát.
