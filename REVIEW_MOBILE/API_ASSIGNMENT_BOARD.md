# Phân Công Nhiệm Vụ Phát Triển API - Health System

Bảng dưới đây liệt kê chi tiết các màn hình và những API tương ứng cần được gọi. Bảng đã được cập nhật ĐỒNG BỘ hoàn toàn với `BUILD_STATUS_REPORT.md`.

---

## BẢNG TỔNG HỢP PHÂN CÔNG API

| Màn Hình                           | API Cần Đấu Nối                                    |       Status       | Người Phụ Trách |
| :--------------------------------- | :------------------------------------------------- | :----------------: | :-------------- |
| **P1 - AUTH_Login**                | `POST /api/v1/mobile/auth/login`                   |      ✅ DONE       | `[@Minh6625]`   |
| **P1 - AUTH_Register**             | `POST /api/v1/mobile/auth/register`                |      ✅ DONE       | `[@Minh6625]`   |
| **P1 - AUTH_VerifyEmail**          | `POST /api/v1/mobile/auth/verify-email`            |      ✅ DONE       | `[@Minh6625]`   |
| **P1 - AUTH_ForgotPassword**       | `POST /api/v1/mobile/auth/forgot-password`         |      ✅ DONE       | `[@Minh6625]`   |
| **P1 - AUTH_ResetPassword**        | `POST /api/v1/mobile/auth/reset-password`          |      ✅ DONE       | `[@Minh6625]`   |
|                                    |                                                    |                    |                 |
| **P2 - HOME_Dashboard**            | `GET /api/v1/mobile/health/dashboard`              | ⚠️ DONE (MockData) | `[@Manh12347]`  |
| **P2 - DEVICE_List**               | _(Native BLE Protocol)_                            |      ✅ DONE       | `[@Name]`       |
| **P2 - DEVICE_Connect**            | `POST /api/v1/mobile/devices/sync`                 | ⚠️ DONE (MockData) | `[@Name]`       |
| **P2 - DEVICE_StatusDetail**       | `GET /api/v1/mobile/devices/status`                | ⚠️ DONE (MockData) | `[@Name]`       |
|                                    |                                                    |                    |                 |
| **P3 - MONITORING_VitalDetail**    | `GET /api/.../health/vitals/timeseries`            | ⚠️ DONE (MockData) | `[@Manh12347]`  |
| **P3 - MONITORING_HealthHistory**  | `GET /api/v1/mobile/health/reports/summary`        | ⚠️ DONE (MockData) | `[@Name]`       |
| **P3 - SLEEP_Report & Detail**     | `GET /api/v1/mobile/health/sleep/latest`           | ⚠️ DONE (MockData) | `[@Manh12347]`  |
| **P3 - ANALYSIS_RiskReport**       | `GET /api/v1/mobile/ai/risk-analysis`              | ⚠️ DONE (MockData) | `[@Name]`       |
| **P3 - ANALYSIS_RiskReportDetail** | `GET /api/v1/mobile/ai/risk-explanation`           | ⚠️ DONE (MockData) | `[@Name]`       |
|                                    |                                                    |                    |                 |
| **P4 - EMERGENCY_ManualSOS**       | `POST /api/v1/mobile/emergency/sos`                |      ✅ DONE       | `[@Minh6625]`   |
| **P4 - EMERGENCY_SOSReceivedList** | `GET /api/v1/mobile/emergency/alerts`              | ⚠️ DONE (MockData) | `[@Minh6625]`   |
| **P4 - EMERGENCY_SOSDetail**       | `GET /api/v1/mobile/emergency/alerts/{id}`         | ⚠️ DONE (MockData) | `[@Minh6625]`   |
| **P4 - EMERGENCY_IncomingAlert**   | `POST /api/.../notifications/topics/subscribe`     |     ❌ MISSING     | `[@Minh6625]`   |
|                                    |                                                    |                    |                 |
| **P5 - FAMILY_Dashboard**          | `GET /api/v1/mobile/family/members`                | ⚠️ DONE (MockData) | `[@Name]`       |
| **P5 - FAMILY_AddMember**          | `POST /api/v1/mobile/family/invite`                | ⚠️ DONE (MockData) | `[@Name]`       |
| **P5 - FAMILY_Settings**           | `POST /api/v1/mobile/family/permissions`           | ⚠️ DONE (MockData) | `[@Name]`       |
|                                    |                                                    |                    |                 |
| **P6 - PROFILE_View**              | `GET /api/v1/mobile/auth/me`                       |      ✅ DONE       | `[@Manh12347]`  |
| **P6 - PROFILE_Edit**              | `PUT /api/v1/mobile/auth/me`                       |      ✅ DONE       | `[@Manh12347]`  |
| **P6 - SETTINGS_General**          | _(Local SharedPreferences)_                        |      ✅ DONE       | `[@Manh12347]`  |
| **P6 - ACCOUNT_Delete**            | `DELETE /api/v1/mobile/profile`                    |      ✅ DONE       | `[@Manh12347]`  |
|                                    |                                                    |                    |                 |
| **P7 - NOTIFICATION_HistoryList**  | `GET /api/v1/mobile/notifications`                 |     ❌ MISSING     | `[@Name]`       |
| **P7 - NOTIFICATION_DetailedAlert**| `PUT /api/v1/mobile/notifications/read`            |     ❌ MISSING     | `[@Name]`       |

---

## Hướng Dẫn Sử Dụng Bảng Chấm Công

1. Cột **Màn Hình**: Giúp bạn biết nút bấm gọi API này nằm ở giao diện nào trên App.
2. Cột **API Cần Đấu Nối**: Mục tiêu endpoint kỹ thuật phải hoàn thành, lấy chuẩn theo `BUILD_STATUS_REPORT.md`.
3. Cột **Status**: 
   - `✅ DONE`: Đã hoạt động mượt mà với API thật.
   - `⚠️ DONE (MockData)`: Giao diện đã xong nhưng đang dùng Data tĩnh/Fake/Delay => **Cần ưu tiên tháo Mock làm thật**.
   - `❌ MISSING`: Chưa code màn hình và chưa có Endpoint.
4. Cột **Người Phụ Trách**: Thay thế `[@Name]` bằng tên của người chịu trách nhiệm đấu vào (Ví dụ: `@Minh6625`).
