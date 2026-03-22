# Health System - Báo Cáo Tiến Độ Dự Án (UI & API Status)

Báo cáo này đối chiếu tiến độ thực tế giữa việc lên form Giao diện (Mobile Screens) và tình trạng tích hợp luồng dữ liệu API (Backend DB/SQL) dựa trên Source Code hiện hành.

---

## Giai đoạn 1 (Phase 1) — Shell & Auth (Cổng vào ứng dụng)

**Trạng thái chung:** ✅ Hoàn thành toàn bộ (Đã nối API thật)

### Chi tiết Màn hình & API

| Màn Hình                | Status UI | API Sử Dụng                                | Status API |
| :---------------------- | :-------: | :----------------------------------------- | :--------: |
| `AUTH_Splash`           |  ✅ DONE  | _(Không gọi API)_                          |     -      |
| `AUTH_Login`            |  ✅ DONE  | `POST /api/v1/mobile/auth/login`           |  ✅ DONE   |
| `AUTH_Register`         |  ✅ DONE  | `POST /api/v1/mobile/auth/register`        |  ✅ DONE   |
| `AUTH_VerifyEmail`      |  ✅ DONE  | `POST /api/v1/mobile/auth/verify-email`    |  ✅ DONE   |
| `AUTH_ForgotPassword`   |  ✅ DONE  | `POST /api/v1/mobile/auth/forgot-password` |  ✅ DONE   |
| `AUTH_ResetPassword`    |  ✅ DONE  | `POST /api/v1/mobile/auth/reset-password`  |  ✅ DONE   |
| `Bottom_Navigation_Bar` |  ✅ DONE  | _(Không gọi API)_                          |     -      |

### Mô tả chi tiết UI

- **`AUTH_Splash`**: Màn hình chờ vừa mở ứng dụng (Splash Screen). Tự động chạy logic kiểm tra bộ nhớ local xem có token hợp lệ không để rẽ nhánh.
- **`AUTH_Login`**: Giao diện đăng nhập tài khoản.
- **`AUTH_Register`**: Giao diện đăng ký tài khoản mới.
- **`AUTH_VerifyEmail`**: Giao diện nhập mã xác minh gồm 4-6 số gửi vào hòm mail.
- **`AUTH_ForgotPassword`**: Màn hình nhập Email yêu cầu gửi mã khôi phục mật khẩu.
- **`AUTH_ResetPassword`**: Màn hình nhập chuỗi OTP xác thực và điền mật khẩu mới.
- **`Bottom_Navigation_Bar`**: Thanh điều hướng dưới cùng của ứng dụng, quản lý chuyển trang.

### Mô tả chi tiết API

- **`AUTH_Splash`**: Không sử dụng API, chỉ check `flutter_secure_storage`.
- **`AUTH_Login`**: Gọi `POST .../auth/login` để xác thực máy chủ và nhận lưu trữ JWT.
- **`AUTH_Register`**: Gọi `POST .../auth/register` truyền dữ liệu người dùng yêu cầu tạo mới xuống CSDL.
- **`AUTH_VerifyEmail`**: Gọi `POST .../auth/verify-email` để kích hoạt cờ (flag) tài khoản.
- **`AUTH_ForgotPassword`**: Gọi `POST .../auth/forgot-password` kích hoạt luồng bắn email.
- **`AUTH_ResetPassword`**: Gọi `POST .../auth/reset-password` để cập nhật mật khẩu băm (hash) mới.
- **`Bottom_Navigation_Bar`**: Chỉ là khung tĩnh, không gọi backend.

---

## Giai đoạn 2 (Phase 2) — Thiết bị + Dashboard cơ bản

**Trạng thái chung:** ⚠️ Hoàn thành một phần (Dashboard đang dùng Mock Data)

### Chi tiết Màn hình & API

| Màn Hình              | Status UI | API Sử Dụng                           |     Status API     |
| :-------------------- | :-------: | :------------------------------------ | :----------------: |
| `HOME_Dashboard`      |  ✅ DONE  | `GET /api/v1/mobile/health/dashboard` | ⚠️ DONE (MockData) |
| `DEVICE_List`         |  ✅ DONE  | _(Native BLE Protocol)_               |      ✅ DONE       |
| `DEVICE_Connect`      |  ✅ DONE  | `POST /api/v1/mobile/devices/sync`    | ⚠️ DONE (MockData) |
| `DEVICE_StatusDetail` |  ✅ DONE  | `GET /api/v1/mobile/devices/status`   | ⚠️ DONE (MockData) |

### Mô tả chi tiết UI

- **`HOME_Dashboard`**: Trang chủ hiển thị tóm tắt tình trạng sinh tồn và phần cứng. UI đã hoàn thiện.
- **`DEVICE_List`**: Màn hình quét Bluetooth xung quanh, liệt kê thiết bị y tế.
- **`DEVICE_Connect`**: Màn hình cài đặt thông số và ghép đôi thiết bị.
- **`DEVICE_StatusDetail`**: Giao diện quản lý dung lượng pin và tính liên tục của kết nối.

### Mô tả chi tiết API

- **`HOME_Dashboard`**: Luồng dữ liệu `GET /health/dashboard` đang dùng Mock Data (`Future.delayed(1s)`), chưa map real DB.
- **`DEVICE_List`**: Giao tiếp qua sóng Bluetooth (Native), đã hoàn thiện bắt sóng thực.
- **`DEVICE_Connect`**: Có Code kết nối API `POST .../devices/sync` nhưng đang bị chốt chặn bởi config `DeviceMockConfig.useMockData` để dùng dữ liệu giả lập tĩnh.
- **`DEVICE_StatusDetail`**: Đang dùng Data giả định qua cấu hình `DeviceMockConfig.useMockData == true`.

---

## Giai đoạn 3 (Phase 3) — Theo dõi sức khoẻ bản thân (Core value P0)

**Trạng thái chung:** ⚠️ Dựng UI (Mock Data) nhưng chưa nối Backend cho Vitals, Thiếu hẳn Code AI

### Chi tiết Màn hình & API

| Màn Hình                    | Status UI | API Sử Dụng                                 |     Status API     |
| :-------------------------- | :-------: | :------------------------------------------ | :----------------: |
| `MONITORING_VitalDetail`    |  ✅ DONE  | `GET /api/.../health/vitals/timeseries`     | ⚠️ DONE (MockData) |
| `MONITORING_HealthHistory`  |  ✅ DONE  | `GET /api/v1/mobile/health/reports/summary` | ⚠️ DONE (MockData) |
| `SLEEP_Report`              |  ✅ DONE  | `GET /api/v1/mobile/health/sleep/latest`    | ⚠️ DONE (MockData) |
| `SLEEP_Detail`              |  ✅ DONE  | `GET /api/v1/mobile/health/sleep/latest`    | ⚠️ DONE (MockData) |
| `ANALYSIS_RiskReport`       |  ✅ DONE  | `GET /api/v1/mobile/ai/risk-analysis`       | ⚠️ DONE (MockData) |
| `ANALYSIS_RiskReportDetail` |  ✅ DONE  | `GET /api/v1/mobile/ai/risk-explanation`    | ⚠️ DONE (MockData) |

### Mô tả chi tiết UI

- **`MONITORING_VitalDetail`**: Biểu đồ động hiển thị chỉ số Nhịp tim và SpO2 theo móc thời gian quá khứ.
- **`MONITORING_HealthHistory`**: Danh sách các phiên đo chỉ số sinh tồn lưu lại ở dạng báo cáo.
- **`SLEEP_Report`**: Giao diện tóm tắt về thời gian nằm trên giường và điểm giấc ngủ.
- **`SLEEP_Detail`**: Phân bổ chu kỳ ngủ nông/sâu/thức thành biểu đồ thanh.
- **`ANALYSIS_RiskReport`**: Màn hình hiển thị tổng điểm sức khoẻ thông minh từ rủi ro AI, đã hoàn thiện UI component thiết kế đẹp mắt.
- **`ANALYSIS_RiskReportDetail`**: Màn hình giải thích chi tiết nguyên nhân rủi ro, đã chia component đầy đủ.

### Mô tả chi tiết API

- **`MONITORING_VitalDetail`**: Lẽ ra gọi `GET /vitals/timeseries` nhưng đang bị dev fake bằng `vital_detail_mock`.
- **`MONITORING_HealthHistory`**: Đang sử dụng Repo giả mạo, chưa chạy payload thực từ Summary Endpoint của hệ thống.
- **`SLEEP_Report`**: Đang dùng `_useMock = true` gọi vào `MockSleepRepository`, chưa ráp Backend thật.
- **`SLEEP_Detail`**: Đồng bộ biểu đồ biểu diễn qua fake data của Sleep provider.
- **`ANALYSIS_RiskReport`**: Đang dùng MockData từ provider `risk_report_provider.dart` với delay 800ms, tự động nhét model tĩnh thay vì gửi request thực.
- **`ANALYSIS_RiskReportDetail`**: Tương tự bản Report, giao diện nhận fake data từ model tĩnh local để render cây component.

---

## Giai đoạn 4 (Phase 4) — Khẩn cấp SOS (Safety critical)

**Trạng thái chung:** ⚠️ Hoàn thành một phần (Thiếu luồng nhận cảnh báo chủ động)

### Chi tiết Màn hình & API

| Màn Hình                    | Status UI  | API Sử Dụng                                    |     Status API     |
| :-------------------------- | :--------: | :--------------------------------------------- | :----------------: |
| `EMERGENCY_ManualSOS`       |  ✅ DONE   | `POST /api/v1/mobile/emergency/sos`            |      ✅ DONE       |
| `EMERGENCY_SOSReceivedList` |  ✅ DONE   | `GET /api/v1/mobile/emergency/alerts`          | ⚠️ DONE (MockData) |
| `EMERGENCY_SOSDetail`       |  ✅ DONE   | `GET /api/v1/mobile/emergency/alerts/{id}`     | ⚠️ DONE (MockData) |
| `EMERGENCY_IncomingAlert`   | ❌ MISSING | `POST /api/.../notifications/topics/subscribe` |     ❌ MISSING     |

### Mô tả chi tiết UI

- **`EMERGENCY_ManualSOS`**: Nút SOS khổng lồ, bấm vào để truyền cảnh báo SOS cưỡng chế.
- **`EMERGENCY_SOSReceivedList`**: Danh sách lịch sử những đợt tín hiệu SOS ứng dụng nhận được từ người thân bảo hộ.
- **`EMERGENCY_SOSDetail`**: Định vị vị trí cụ thể của cảnh báo cứu viện trên Google Maps và ghi chú thời gian.
- **`EMERGENCY_IncomingAlert`**: Màn hình Overlay cưỡng chế (vượt mặt khóa máy/pop-up hú còi) khi bị cảnh báo. _Chưa code._

### Mô tả chi tiết API

- **`EMERGENCY_ManualSOS`**: Gọi `POST /emergency/sos` nhét cả Toạ độ GPS lên Data. Chạy thông suốt.
- **`EMERGENCY_SOSReceivedList`**: Đang dùng List từ `EmergencyCaregiverMockRepository`, chưa nhận payload thật.
- **`EMERGENCY_SOSDetail`**: Tương tự bản List, tải mô phỏng Mock.
- **`EMERGENCY_IncomingAlert`**: Chưa gắn Service Subscribe topic của cổng WebSocket hay Firebase Messaging để lắng nghe sự kiện push trigger realtime.

---

## Giai đoạn 5 (Phase 5) — Quản lý nhiều hồ sơ (Relationship)

**Trạng thái chung:** ⚠️ Phần lớn UI đều chưa nối Backend (Gắn Mock Provider)

### Chi tiết Màn hình & API

| Màn Hình           | Status UI | API Sử Dụng                              |     Status API     |
| :----------------- | :-------: | :--------------------------------------- | :----------------: |
| `FAMILY_Dashboard` |  ✅ DONE  | `GET /api/v1/mobile/family/members`      | ⚠️ DONE (MockData) |
| `FAMILY_AddMember` |  ✅ DONE  | `POST /api/v1/mobile/family/invite`      | ⚠️ DONE (MockData) |
| `FAMILY_Settings`  |  ✅ DONE  | `POST /api/v1/mobile/family/permissions` | ⚠️ DONE (MockData) |

### Mô tả chi tiết UI

- **`FAMILY_Dashboard`**: Tab quản lý sức khoẻ dành riêng cho ông/bà, bố/mẹ dưới dạng User khác nhau.
- **`FAMILY_AddMember`**: Màn hình quét QR code kết bạn và gán tư cách thành viên.
- **`FAMILY_Settings`**: Bật/Tắt quyền riêng tư (không cho ai xem nhịp tim/vị trí của mình).

### Mô tả chi tiết API

- **`FAMILY_Dashboard`**: Vẫn còn đang load list từ `family_dashboard_mock_provider.dart`.
- **`FAMILY_AddMember`**: Tương tự, gọi logic thêm thành viên vào nhưng thực tế fake trạng thái thành công.
- **`FAMILY_Settings`**: Chỉnh trên ứng dụng nhưng văng ra thì thông số tự trả về mặc định do không có DB lưu trữ.

---

## Giai đoạn 6 (Phase 6) — Profile & Settings

**Trạng thái chung:** ✅ Hoàn thành toàn bộ

### Chi tiết Màn hình & API

| Màn Hình           | Status UI | API Sử Dụng                     | Status API |
| :----------------- | :-------: | :------------------------------ | :--------: |
| `PROFILE_View`     |  ✅ DONE  | `GET /api/v1/mobile/auth/me`    |  ✅ DONE   |
| `PROFILE_Edit`     |  ✅ DONE  | `PUT /api/v1/mobile/auth/me`    |  ✅ DONE   |
| `SETTINGS_General` |  ✅ DONE  | _(Local SharedPreferences)_     |  ✅ DONE   |
| `ACCOUNT_Delete`   |  ✅ DONE  | `DELETE /api/v1/mobile/profile` |  ✅ DONE   |

### Mô tả chi tiết UI

- **`PROFILE_View`**: Hiển thị tên tuổi ảnh đại diện người dùng hệ thống.
- **`PROFILE_Edit`**: Thao tác thay đổi Textfield Họ Tên, Cân Nặng.
- **`SETTINGS_General`**: Ngôn ngữ, Theme sáng tối, Đơn vị đo.
- **`ACCOUNT_Delete`**: Màn hình Xác nhận xoá Tài khoản với check box.

### Mô tả chi tiết API

- **`PROFILE_View`**: Load dữ liệu `auth/me` thực từ DB.
- **`PROFILE_Edit`**: PUT lưu lại dữ liệu.
- **`SETTINGS_General`**: Setting chỉ lưu thiết bị.
- **`ACCOUNT_Delete`**: Đã hoàn thiện gọi `DELETE /profile` (hoạt động theo chiến lược Soft Delete trên DB).

---

## Giai đoạn 7 (Phase 7) — Cảnh báo và Thông báo (Push Notification)

**Trạng thái chung:** ❌ Chưa triển khai logic

### Chi tiết Màn hình & API

| Màn Hình                     | Status UI  | API Sử Dụng                             | Status API |
| :--------------------------- | :--------: | :-------------------------------------- | :--------: |
| `NOTIFICATION_HistoryList`   | ❌ MISSING | `GET /api/v1/mobile/notifications`      | ❌ MISSING |
| `NOTIFICATION_DetailedAlert` | ❌ MISSING | `PUT /api/v1/mobile/notifications/read` | ❌ MISSING |

### Mô tả chi tiết UI

- **`NOTIFICATION_HistoryList`**: Màn hình Chuông thông báo tổng hợp sự kiện.
- **`NOTIFICATION_DetailedAlert`**: Đọc chi tiết nội dung sự kiện theo Push msg.

### Mô tả chi tiết API

- **`NOTIFICATION_HistoryList`**: Không nhận được API `GET /notifications`.
- **`NOTIFICATION_DetailedAlert`**: Khép lại logic chưa có Endpoint cập nhật state "Đã đọc".
