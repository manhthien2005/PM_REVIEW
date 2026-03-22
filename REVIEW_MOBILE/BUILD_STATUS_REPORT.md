# Health System - Báo Cáo Tiến Độ Theo Source Hiện Tại

Báo cáo này phản ánh **source Flutter `health_system` hiện tại trong workspace**. Chỉ giữ lại những flow, route, provider và endpoint thực sự có trong code; các endpoint/spec cũ không còn được ghi là "đã có" nếu source chưa gọi.

## Cách đọc trạng thái

- `✅ ROUTED`: Có route hoặc flow mở màn hình rõ ràng trong app.
- `✅ SCREEN (push)`: Có màn hình thật, nhưng đang được mở bằng `MaterialPageRoute` thay vì named route.
- `✅ IN SHELL`: Nằm trong tab/shell hiện có của app.
- `🔶 SCREEN ONLY`: Có file màn hình nhưng chưa thấy route/navigation chính thức trong app.
- `📝 NATIVE`: Xử lý ở native/plugin, không có Flutter screen riêng.
- `✅ LIVE`: Source đang gọi API thật.
- `⚠️ LIVE-READY`: Source đã có code API thật, nhưng runtime hiện tại vẫn đang mock/local theo config hoặc dependency injection.
- `🧪 MOCK-ONLY`: Mới có mock/local provider, chưa có API call thật trong source.
- `🧩 LOCAL-ONLY`: Chỉ có state local/UI, chưa có persistence/backend.
- `❌ NONE`: Chưa thấy implementation tương ứng trong source.

---

## Phase 1 — Entry & Auth

| Flow / Màn hình          |            UI / Route             |   Data / API    | Ghi chú theo source                                                            |
| :----------------------- | :-------------------------------: | :-------------: | :----------------------------------------------------------------------------- |
| `AUTH_NativeSplash`      |            `📝 NATIVE`            | `🧩 LOCAL-ONLY` | App dùng `flutter_native_splash`; không có Flutter screen `AUTH_Splash` riêng. |
| `AUTH_Start / AuthPages` |      `✅ ROUTED` (`/start`)       |    `❌ NONE`    | `AuthPagesScreen` + `StartScreen` là entry UI/pageview, không gọi API.         |
| `AUTH_Login`             |      `✅ ROUTED` (`/login`)       |    `✅ LIVE`    | Gọi `POST /auth/login`.                                                        |
| `AUTH_Register`          |     `✅ ROUTED` (`/register`)     |    `✅ LIVE`    | Gọi `POST /auth/register`.                                                     |
| `AUTH_VerifyEmail`       |   `✅ ROUTED` (`/verify-email`)   |    `✅ LIVE`    | Gọi `POST /auth/verify-email`.                                                 |
| `AUTH_ForgotPassword`    | `✅ ROUTED` (`/forgot-password`)  |    `✅ LIVE`    | Gọi `POST /auth/forgot-password`.                                              |
| `AUTH_VerifyResetOtp`    | `✅ ROUTED` (`/verify-reset-otp`) |    `✅ LIVE`    | Gọi `POST /auth/verify-reset-otp`.                                             |
| `AUTH_ResetPassword`     |  `✅ ROUTED` (`/reset-password`)  |    `✅ LIVE`    | Gọi `POST /auth/reset-password`.                                               |

---

## Phase 2 — Home & Device

| Flow / Màn hình       |         UI / Route         |   Data / API    | Ghi chú theo source                                                                                               |
| :-------------------- | :------------------------: | :-------------: | :---------------------------------------------------------------------------------------------------------------- |
| `HOME_Dashboard`      | `✅ ROUTED` (`/dashboard`) | `🧪 MOCK-ONLY`  | Dùng `HomeDashboardViewModel` mock local; chưa có repository/provider gọi API dashboard thật.                     |
| `DEVICE_List`         |  `✅ ROUTED` (`/device`)   | `⚠️ LIVE-READY` | `DeviceProvider` đã có `GET/POST/PATCH/DELETE /devices...`, nhưng mặc định `DeviceMockConfig.useMockData = true`. |
| `DEVICE_Connect`      |     `✅ SCREEN (push)`     | `🧪 MOCK-ONLY`  | `DeviceConnectProvider` đang simulate scan/verify/pair; chưa có API call thật trong provider.                     |
| `DEVICE_StatusDetail` |     `✅ SCREEN (push)`     | `⚠️ LIVE-READY` | Có live path `GET /devices/{id}`, nhưng mặc định vẫn chạy mock snapshot.                                          |
| `DEVICE_Configure`    |     `✅ SCREEN (push)`     | `🧪 MOCK-ONLY`  | Màn cấu hình đã có UI; `saveChanges()` và `unpairDevice()` mới chỉ `Future.delayed`.                              |

---

## Phase 3 — Monitoring, Sleep, Analysis

| Flow / Màn hình             |             UI / Route              |   Data / API    | Ghi chú theo source                                                                                           |
| :-------------------------- | :---------------------------------: | :-------------: | :------------------------------------------------------------------------------------------------------------ |
| `MONITORING_VitalDetail`    |    `✅ ROUTED` (`/vital-detail`)    | `🧪 MOCK-ONLY`  | Dùng `VitalDetailMockProvider`; chưa có live repository/timeseries endpoint trong source.                     |
| `MONITORING_HealthHistory`  |          `🔶 SCREEN ONLY`           | `🧪 MOCK-ONLY`  | `HealthReportScreen` tồn tại nhưng chưa thấy route/navigation chính thức; dữ liệu đang hardcode local.        |
| `SLEEP_Report`              |    `✅ ROUTED` (`/sleep-report`)    | `⚠️ LIVE-READY` | `SleepProvider` đang khóa `_useMock = true`; `SleepRepositoryImpl` đã có `/sleep/latest` và `/sleep/history`. |
| `SLEEP_Detail`              |    `✅ ROUTED` (`/sleep-detail`)    | `⚠️ LIVE-READY` | Dùng chung `SleepProvider`; nguồn dữ liệu thực vẫn bị chặn bởi `_useMock = true`.                             |
| `SLEEP_History`             |   `✅ ROUTED` (`/sleep-history`)    | `⚠️ LIVE-READY` | Màn hình có thật và đang dùng chung provider/repository của sleep.                                            |
| `SLEEP_Settings`            |   `✅ ROUTED` (`/sleep-settings`)   | `🧩 LOCAL-ONLY` | Chỉ có state nội bộ cho switch/time picker; chưa có persistence/backend.                                      |
| `ANALYSIS_RiskReport`       |    `✅ ROUTED` (`/risk-report`)     | `🧪 MOCK-ONLY`  | `RiskReportProvider` trả entity mock, chưa có API call thật.                                                  |
| `ANALYSIS_RiskReportDetail` | `✅ ROUTED` (`/risk-report-detail`) | `🧪 MOCK-ONLY`  | Dùng chung `RiskReportProvider`, dữ liệu hardcoded.                                                           |
| `ANALYSIS_RiskHistory`      |    `✅ ROUTED` (`/risk-history`)    | `🧪 MOCK-ONLY`  | `RiskHistoryProvider` sinh summary/list mock, chưa gọi backend.                                               |

---

## Phase 4 — Emergency

| Flow / Màn hình             |              UI / Route               |   Data / API    | Ghi chú theo source                                                                                                   |
| :-------------------------- | :-----------------------------------: | :-------------: | :-------------------------------------------------------------------------------------------------------------------- |
| `EMERGENCY_ManualSOS`       |      `✅ ROUTED` (`/manual-sos`)      |    `✅ LIVE`    | `ManualSOSScreen` gọi `POST /emergency/sos/trigger`, có lấy GPS nếu khả dụng.                                         |
| `EMERGENCY_SOSConfirm`      |     `✅ ROUTED` (`/sos-confirm`)      |    `❌ NONE`    | Màn xác nhận sau khi gửi SOS, không gọi API.                                                                          |
| `EMERGENCY_SOSReceivedList` |             `✅ IN SHELL`             | `⚠️ LIVE-READY` | App đang inject `EmergencyCaregiverMockRepository`; real repo đã có `GET /emergency/caregiver/sos-alerts?status=...`. |
| `EMERGENCY_SOSDetail`       | `✅ ROUTED` (`/emergency/sos/detail`) | `⚠️ LIVE-READY` | Runtime hiện tại dùng mock repo; real repo đã có `GET /emergency/sos/{id}`.                                           |
| `EMERGENCY_SOSResolve`      |          `✅ IN DETAIL FLOW`          | `⚠️ LIVE-READY` | Flow resolve đã có trong provider; real repo đã có `POST /emergency/sos/{id}/resolve`.                                |
| `EMERGENCY_IncomingAlert`   |           `🔶 SCREEN ONLY`            |    `❌ NONE`    | Có `WarningScreen`, `FamilySOSFullScreenOverlay` và polling placeholder; chưa có FCM/WebSocket/topic subscribe thật.  |

---

## Phase 5 — Family & Relationship

| Flow / Màn hình                         |               UI / Route               |   Data / API   | Ghi chú theo source                                                             |
| :-------------------------------------- | :------------------------------------: | :------------: | :------------------------------------------------------------------------------ |
| `FAMILY_Shell`                          |   `✅ ROUTED` (`/family-management`)   | `🧪 MOCK-ONLY` | Shell 3 tab: Theo dõi / Liên hệ / SOS.                                          |
| `FAMILY_Dashboard`                      |   `✅ ROUTED` (`/family-dashboard`)    | `🧪 MOCK-ONLY` | Dùng `SharedFamilyMockProvider.generateDashboardSnapshots()`.                   |
| `FAMILY_ContactList`                    |             `✅ IN SHELL`              | `🧪 MOCK-ONLY` | Dùng shared mock provider, không có API thật.                                   |
| `FAMILY_AddMember`                      |      `✅ ROUTED` (`/add-contact`)      | `🧪 MOCK-ONLY` | Thêm liên hệ qua `SharedFamilyMockProvider.sendRequest()`, scan/share đều mock. |
| `FAMILY_LinkedContactDetail / Settings` | `✅ ROUTED` (`/linked-contact-detail`) | `🧪 MOCK-ONLY` | Quyền chia sẻ, tags, unlink đều qua `LinkedContactDetailMockProvider`.          |
| `FAMILY_PersonDetail`                   |     `✅ ROUTED` (`/person-detail`)     | `🧪 MOCK-ONLY` | Chi tiết người thân đang dựng từ snapshot mock.                                 |

---

## Phase 6 — Profile & Security

| Flow / Màn hình          |            UI / Route            | Data / API | Ghi chú theo source                                                        |
| :----------------------- | :------------------------------: | :--------: | :------------------------------------------------------------------------- |
| `PROFILE_View`           |     `✅ ROUTED` (`/profile`)     | `✅ LIVE`  | `ProfileProvider.fetchProfile()` gọi `GET /profile`.                       |
| `PROFILE_Edit`           |  `✅ ROUTED` (`/edit-profile`)   | `✅ LIVE`  | `ProfileProvider.updateProfile()` gọi `PUT /profile`.                      |
| `PROFILE_MedicalInfo`    |  `✅ ROUTED` (`/medical-info`)   | `✅ LIVE`  | Dùng chung `PUT /profile`.                                                 |
| `PROFILE_ChangePassword` | `✅ ROUTED` (`/change-password`) | `✅ LIVE`  | Gọi `POST /auth/change-password`.                                          |
| `ACCOUNT_Delete`         | `✅ ROUTED` (`/delete-account`)  | `✅ LIVE`  | `ProfileProvider.deleteAccount()` gọi `DELETE /profile`.                   |
| `SETTINGS_General`       |           `❌ MISSING`           | `❌ NONE`  | Không thấy screen/service `SharedPreferences` riêng trong source hiện tại. |

---

## Phase 7 — Notifications

| Flow / Màn hình              |              UI / Route              | Data / API | Ghi chú theo source                                |
| :--------------------------- | :----------------------------------: | :--------: | :------------------------------------------------- |
| `NOTIFICATION_HistoryList`   |             `❌ MISSING`             | `❌ NONE`  | Không thấy màn hình/router/provider riêng.         |
| `NOTIFICATION_DetailedAlert` |             `❌ MISSING`             | `❌ NONE`  | Không thấy màn hình/router/provider riêng.         |
| `Notification CTA trên Home` | `✅ ROUTED` (button trong dashboard) | `❌ NONE`  | Nút thông báo hiện có nhưng callback vẫn để trống. |

---

## Tóm tắt nhanh

- Đã có API thật và đúng source: `auth/login`, `auth/register`, `auth/verify-email`, `auth/forgot-password`, `auth/verify-reset-otp`, `auth/reset-password`, `auth/change-password`, `profile`, `emergency/sos/trigger`.
- Đã có code live nhưng runtime hiện tại vẫn mock/local: `device`, `sleep`, `emergency caregiver`.
- Mới dừng ở mock/local: `home dashboard`, `vital detail`, toàn bộ `analysis`, toàn bộ `family`.
- Bị thiếu trong source hiện tại: `settings general`, `notification history`, `notification detail`.

---

## Changelog

> Quy ước bắt buộc: Mỗi lần cập nhật file này, người sửa **phải thêm một dòng mới** vào changelog bên dưới.

| Ngày       | Người cập nhật | Nội dung thay đổi                                                                                                                                                                                                                                                                                                     |
| :--------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-03-22 | Codex          | Viết lại toàn bộ báo cáo theo source `health_system` hiện tại; sửa endpoint sai, cập nhật đúng trạng thái mock/live, và bổ sung các flow bị thiếu như `risk_history`, `sleep_history`, `device_configure`, `linked_contact_detail`, `person_detail`, `medical_info`, `change-password`, `sos_confirm`, `sos_resolve`. |
