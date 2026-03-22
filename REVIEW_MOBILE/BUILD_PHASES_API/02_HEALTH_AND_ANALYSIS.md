# Phase 2: Health, Monitoring & Analysis

Phase này xử lý những dữ liệu Time-series và các báo cáo AI/phân tích rủi ro dựa trên dữ liệu thiêt bị đã thu thập được ở Phase 1.

## 1. Vitals & Monitoring

Hiện tại `MONITORING_VitalDetail` và `HealthHistory` đang dùng dữ liệu mock.

- **GET /metrics/vitals/{type}**: Lấy chi tiết lịch sử một loại biểu đồ (nhịp tim, SpO2, huyết áp...) theo biểu đồ thời gian.
- **GET /metrics/health-report**: Trả về tham số báo cáo sức khỏe (có thể xuất dạng PDF hoặc raw data để hiển thị lịch sử).

## 2. Sleep Settings

Thiết lập dữ liệu giấc ngủ hiện tại là `LOCAL-ONLY`.

- **PUT /metrics/sleep/settings**: Cập nhật mục tiêu giấc ngủ (giờ ngủ mong muốn, nhắc nhở).
  _(Sleep history và Detail hiện đã LIVE-READY)_

## 3. UI/AI Analysis (Risk Reports)

Danh mục phân tích của AI đang được mock toàn bộ.

- **GET /analysis/risk-reports**: Lấy danh sách các báo cáo phân tích rủi ro gần đây.
- **GET /analysis/risk-reports/{id}**: Chi tiết nhận định rủi ro tổng hợp (có đưa ra lời khuyên từ AI bác sĩ).
- **GET /analysis/risk-history**: Thống kê lịch sử thay đổi của điểm rủi ro qua các tuần/tháng.
