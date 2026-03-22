# Phân Công Nhiệm Vụ Phát Triển API - Health System (Theo Source Hiện Tại)

File này được cập nhật lại theo **source Flutter `health_system` hiện tại**.

- Không còn ghi các endpoint spec cũ nếu source chưa thực sự gọi.
- Không liệt kê `AUTH_Splash` như một Flutter screen riêng vì app đang dùng native splash.
- Cột `Người phụ trách` giữ nguyên giá trị cũ nếu bảng cũ đã có; các mục mới hoặc chưa xác định dùng `TBD`.

## Chú thích trạng thái

- `✅ LIVE`: Source đang gọi API thật.
- `⚠️ LIVE-READY`: Source đã có code API thật, nhưng runtime hiện tại vẫn đang mock/local theo config hoặc dependency injection.
- `🧪 MOCK-ONLY`: Mới có mock/local provider hoặc dữ liệu hardcode; chưa có API call thật trong source.
- `🧩 LOCAL-ONLY`: Chỉ có local state/UI, chưa có persistence/backend.
- `🔶 PARTIAL`: Có một phần flow/UI, nhưng chưa đủ để coi là hoàn chỉnh.
- `❌ MISSING`: Chưa thấy implementation tương ứng trong source.

---

## Bảng tổng hợp phân công API / dữ liệu

| Flow / Màn hình                         | API / Nguồn dữ liệu trong source                                                                                       | Trạng thái thực tế | Việc còn lại để hoàn thiện                                                               | Người phụ trách |
| :-------------------------------------- | :--------------------------------------------------------------------------------------------------------------------- | :----------------: | :--------------------------------------------------------------------------------------- | :-------------- |
| `AUTH_Login`                            | `POST /auth/login`                                                                                                     | `✅ LIVE`           | Giữ nguyên, chỉ cần regression test khi backend đổi contract.                            | `@Minh6625`     |
| `AUTH_Register`                         | `POST /auth/register`                                                                                                  | `✅ LIVE`           | Giữ nguyên, chỉ cần regression test khi backend đổi contract.                            | `@Minh6625`     |
| `AUTH_VerifyEmail`                      | `POST /auth/verify-email`                                                                                              | `✅ LIVE`           | Giữ nguyên, kiểm tra lại flow deep link / verify code.                                   | `@Minh6625`     |
| `AUTH_ForgotPassword`                   | `POST /auth/forgot-password`                                                                                           | `✅ LIVE`           | Giữ nguyên.                                                                              | `@Minh6625`     |
| `AUTH_VerifyResetOtp`                   | `POST /auth/verify-reset-otp`                                                                                          | `✅ LIVE`           | Giữ nguyên, bổ sung test end-to-end reset flow.                                          | `TBD`           |
| `AUTH_ResetPassword`                    | `POST /auth/reset-password`                                                                                            | `✅ LIVE`           | Giữ nguyên.                                                                              | `@Minh6625`     |
| `HOME_Dashboard`                        | Chưa có API call trong source; đang dùng `HomeDashboardViewModel` mock local                                           | `🧪 MOCK-ONLY`      | Tạo repository/provider thật cho dashboard, map dữ liệu home từ backend.                 | `@Manh12347`    |
| `DEVICE_List`                           | `GET /devices`, `POST /devices`, `PATCH /devices/{id}`, `DELETE /devices/{id}`; mặc định đang bật mock                 | `⚠️ LIVE-READY`    | Tắt `DeviceMockConfig`, test contract list/add/update/delete với backend thật.           | `TBD`           |
| `DEVICE_Connect`                        | Không có API call thật trong `DeviceConnectProvider`; verify/pair đang simulate                                        | `🧪 MOCK-ONLY`      | Chốt contract verify/pair hoặc BLE-native bridge thật, bỏ scan/pair mock.                | `TBD`           |
| `DEVICE_StatusDetail`                   | `GET /devices/{id}`; mặc định đang bật mock snapshot                                                                   | `⚠️ LIVE-READY`    | Tắt mock và test detail state online/offline/battery với payload thật.                   | `TBD`           |
| `DEVICE_Configure`                      | Chưa có API call; `saveChanges()` và `unpairDevice()` mới là delay giả                                                 | `🧪 MOCK-ONLY`      | Thiết kế API cấu hình/unpair thật hoặc map vào contract hiện có.                         | `TBD`           |
| `MONITORING_VitalDetail`                | `VitalDetailMockProvider`                                                                                              | `🧪 MOCK-ONLY`      | Tạo live repository cho timeseries vitals và nối vào màn chi tiết.                       | `@Manh12347`    |
| `MONITORING_HealthHistory`              | `HealthReportScreen` hardcode local, chưa thấy route chính thức                                                        | `🔶 PARTIAL`        | Quyết định giữ hay bỏ screen này; nếu giữ thì cần route + repository thật.               | `TBD`           |
| `SLEEP_Report`                          | `SleepProvider` đang `_useMock = true`; live repo đã có `/sleep/latest`, `/sleep/history`                              | `⚠️ LIVE-READY`    | Tắt mock config, kiểm tra contract và trạng thái empty/error với backend thật.           | `@Manh12347`    |
| `SLEEP_Detail`                          | Dùng chung `SleepProvider` / `SleepRepositoryImpl`                                                                     | `⚠️ LIVE-READY`    | Cùng task với sleep report; test select date / linked profile.                           | `@Manh12347`    |
| `SLEEP_History`                         | Dùng chung `SleepProvider` / `SleepRepositoryImpl`                                                                     | `⚠️ LIVE-READY`    | Hoàn thiện chung với flow sleep; bổ sung test lịch sử và chọn session.                   | `TBD`           |
| `SLEEP_Settings`                        | State local trong `SleepSettingsScreen`                                                                                | `🧩 LOCAL-ONLY`     | Quyết định lưu local hay backend; hiện chưa có persistence.                              | `TBD`           |
| `ANALYSIS_RiskReport`                   | `RiskReportProvider` trả dữ liệu mock local                                                                            | `🧪 MOCK-ONLY`      | Tạo analysis repository và gọi API thật cho latest report.                               | `TBD`           |
| `ANALYSIS_RiskReportDetail`             | `RiskReportProvider.fetchReportDetail()` trả dữ liệu mock local                                                        | `🧪 MOCK-ONLY`      | Tạo API/detail contract thật cho xAI breakdown.                                          | `TBD`           |
| `ANALYSIS_RiskHistory`                  | `RiskHistoryProvider` sinh summary/list mock                                                                           | `🧪 MOCK-ONLY`      | Tạo API/history contract thật và phân trang/range filter.                                | `TBD`           |
| `EMERGENCY_ManualSOS`                   | `POST /emergency/sos/trigger`                                                                                          | `✅ LIVE`           | Giữ nguyên, test thêm GPS/no-GPS/network-error với backend thật.                         | `@Minh6625`     |
| `EMERGENCY_SOSConfirm`                  | Không có API; màn xác nhận local sau khi gửi SOS                                                                       | `🧩 LOCAL-ONLY`     | Chỉ cần polish UI/UX nếu cần.                                                            | `TBD`           |
| `EMERGENCY_SOSReceivedList`             | Runtime đang dùng `EmergencyCaregiverMockRepository`; real repo đã có `GET /emergency/caregiver/sos-alerts?status=...` | `⚠️ LIVE-READY`    | Đổi dependency injection sang repo thật và test list/filter/search.                      | `@Minh6625`     |
| `EMERGENCY_SOSDetail`                   | Runtime đang dùng mock repo; real repo đã có `GET /emergency/sos/{id}`                                                 | `⚠️ LIVE-READY`    | Đổi sang repo thật và test map/location/fall timeline.                                   | `@Minh6625`     |
| `EMERGENCY_SOSResolve`                  | Runtime đang dùng mock repo; real repo đã có `POST /emergency/sos/{id}/resolve`                                        | `⚠️ LIVE-READY`    | Bật repo thật, test resolve flow và refresh detail/list.                                 | `TBD`           |
| `EMERGENCY_IncomingAlert`               | Mới có `WarningScreen`, `FamilySOSFullScreenOverlay`, polling placeholder; chưa có push subscription thật              | `🔶 PARTIAL`        | Implement FCM/WebSocket/topic subscribe và cơ chế mở incoming alert thật.                | `@Minh6625`     |
| `FAMILY_Dashboard`                      | `SharedFamilyMockProvider.generateDashboardSnapshots()`                                                                | `🧪 MOCK-ONLY`      | Tạo family repository thật và thay mock snapshots.                                       | `TBD`           |
| `FAMILY_ContactList`                    | `SharedFamilyMockProvider`                                                                                             | `🧪 MOCK-ONLY`      | Tạo API danh sách liên hệ/relationship thật.                                             | `TBD`           |
| `FAMILY_AddMember`                      | `SharedFamilyMockProvider.sendRequest()`                                                                               | `🧪 MOCK-ONLY`      | Chốt flow invite/scan/share thật với backend.                                            | `TBD`           |
| `FAMILY_LinkedContactDetail / Settings` | `LinkedContactDetailMockProvider`                                                                                      | `🧪 MOCK-ONLY`      | Tạo API permission/tags/unlink thật; đây là phần source tương ứng với `FAMILY_Settings`. | `TBD`           |
| `FAMILY_PersonDetail`                   | Snapshot mock từ `SharedFamilyMockProvider`                                                                            | `🧪 MOCK-ONLY`      | Map sang data thật cho linked profile detail.                                            | `TBD`           |
| `PROFILE_View`                          | `GET /profile`                                                                                                         | `✅ LIVE`           | Giữ nguyên; endpoint cũ `/auth/me` trong tài liệu cũ là sai.                             | `@Manh12347`    |
| `PROFILE_Edit`                          | `PUT /profile`                                                                                                         | `✅ LIVE`           | Giữ nguyên.                                                                              | `@Manh12347`    |
| `PROFILE_MedicalInfo`                   | `PUT /profile`                                                                                                         | `✅ LIVE`           | Giữ nguyên; đang dùng chung contract update profile.                                     | `TBD`           |
| `PROFILE_ChangePassword`                | `POST /auth/change-password`                                                                                           | `✅ LIVE`           | Giữ nguyên.                                                                              | `TBD`           |
| `ACCOUNT_Delete`                        | `DELETE /profile`                                                                                                      | `✅ LIVE`           | Giữ nguyên.                                                                              | `@Manh12347`    |
| `SETTINGS_General`                      | Không thấy screen/service riêng trong source                                                                           | `❌ MISSING`        | Nếu còn scope, cần tạo screen + persistence local hoặc backend.                          | `@Manh12347`    |
| `NOTIFICATION_HistoryList`              | Không thấy screen/router/provider riêng                                                                                | `❌ MISSING`        | Cần tạo đầy đủ flow notifications nếu còn scope.                                         | `TBD`           |
| `NOTIFICATION_DetailedAlert`            | Không thấy screen/router/provider riêng                                                                                | `❌ MISSING`        | Cần tạo chi tiết alert + mark-as-read nếu còn scope.                                     | `TBD`           |

---

## Ghi chú quan trọng

1. Các endpoint spec cũ như `/health/dashboard`, `/devices/sync`, `/devices/status`, `/health/reports/summary`, `/ai/risk-analysis`, `/auth/me`, `/family/members`, `/notifications` **không xuất hiện trong source Flutter hiện tại**.
2. Các endpoint thực sự có trong source hiện tại gồm:
   - `/auth/login`
   - `/auth/register`
   - `/auth/verify-email`
   - `/auth/forgot-password`
   - `/auth/verify-reset-otp`
   - `/auth/reset-password`
   - `/auth/change-password`
   - `/devices`
   - `/sleep/latest`
   - `/sleep/history`
   - `/profile`
   - `/emergency/sos/trigger`
   - `/emergency/caregiver/sos-alerts`
   - `/emergency/sos/{id}`
   - `/emergency/sos/{id}/resolve`
3. Nếu cần đồng bộ tiếp với backend/spec tổng, nên update spec theo source hoặc quyết định rõ hướng nào là "nguồn sự thật" trước khi phân công dev tiếp.

---

## Changelog

> Quy ước bắt buộc: Mỗi lần cập nhật file này, người sửa **phải thêm một dòng mới** vào changelog bên dưới.

| Ngày       | Người cập nhật | Nội dung thay đổi                                                                                                                                                                           |
| :--------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-03-22 | Codex          | Viết lại bảng phân công theo source `health_system` hiện tại; thay endpoint/spec cũ bằng contract thực tế, chỉnh lại trạng thái thực thi, và thêm các flow/source item trước đây bị bỏ sót. |
