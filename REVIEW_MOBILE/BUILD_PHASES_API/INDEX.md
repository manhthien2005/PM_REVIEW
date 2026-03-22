# Danh Sách Các Phase Xây Dựng API

Dựa trên tình trạng hiện tại của hệ thống (những API đang dùng Mock, Local-Only, hoặc Missing), dưới đây là kế hoạch ưu tiên xây dựng các API và tích hợp vào App:

## [Phase 1: Core System, Devices & Notifications](./01_CORE_AND_NOTIFICATIONS.md)

Ưu tiên hoàn thiện luồng thiết bị (kết nối, cấu hình) vì đây là nguồn thu thập dữ liệu chính. Dashboard để hiển thị tình trạng tổng quan, và hệ thống thông báo/websockets đặc biệt quan trọng cho cảnh báo khẩn cấp (SOS/Incoming Alert).

## [Phase 2: Health, Monitoring & Analysis](./02_HEALTH_AND_ANALYSIS.md)

Sau khi thiết bị đã đẩy dữ liệu thật, ưu tiên hoàn thiện các API truy xuất chi tiết chỉ số sức khỏe (Vitals) và kết quả phân tích AI (Risk Reports).

## [Phase 3: Family & Relationship](./03_FAMILY_AND_SHARING.md)

Cuối cùng là module cộng đồng/gia đình, xử lý việc liên kết tài khoản, chia sẻ dữ liệu và theo dõi người thân. Module này phụ thuộc vào dữ liệu sức khỏe và cảnh báo đã hoàn thiện ở Phase 2.
