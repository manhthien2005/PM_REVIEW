# 📋 Cross-Check Report — health_system vs Screen Spec

> **Ngày**: 2026-03-17  
> **Nguồn**: BUILD_PHASES + Screen Index + quét health_system/lib  
> **Quy ước**: `✅ Spec+Code` = khớp | `⚠️ Khác spec` = có code nhưng khác tài liệu | `⬜ Missing` = chưa có code

---

## 🎯 Build Sequence cập nhật sau Cross-Check Sync

| # | Work item | Phase | Trạng thái | Ưu tiên |
|---|-----------|:-----:|------------|---------|
| **1** | **DEVICE_StatusDetail** | 2 | ⚠️ **Khác spec** | Cao nhất — Spec: full screen + pin % + nút Cấu hình; Code: Bottom sheet, thiếu pin % và link Configure |
| **2** | **DEVICE_Connect** | 2 | ⚠️ **Khác spec** | Cao — Spec: BLE scan → Pair; Code: Dialog form thủ công (name, MAC, MQTT...) |
| **3** | **ANALYSIS_RiskReport (self flow)** | 3 | ⬜ **Missing** | Cao — core value từ `HOME_Dashboard`, nên build trước linked flow |
| **4** | **ANALYSIS_RiskReportDetail** | 3 | ⬜ **Missing** | Cao — XAI là cặp màn bắt buộc của Risk |
| **5** | **HOME_FamilyDashboard risk integration** | 5 | ⚠️ **Khác spec** | Cao — card người thân cần `risk_summary` + drill-down `RiskReport(profileId)` |

---

## 📊 Bảng Cross-Check đầy đủ (41 màn hình)

### Phase 1 — Shell & Auth

| Spec | health_system | Status |
|------|---------------|--------|
| AUTH_Splash | AuthPagesScreen + StartScreen | ✅ Spec+Code |
| AUTH_Login | LoginScreen | ✅ Spec+Code |
| AUTH_Register | RegisterScreen | ✅ Spec+Code |
| AUTH_VerifyEmail | EmailVerificationScreen | ✅ Spec+Code |
| AUTH_ForgotPassword | ForgotPasswordScreen | ✅ Spec+Code |
| AUTH_ResetPassword | ResetOtpVerificationScreen + ResetPasswordScreen | ✅ Spec+Code |
| Bottom Nav | MainScreen (5 tabs) | ⚠️ **Khác spec** — Spec: 4 tab (Sức khoẻ, Gia đình, Thiết bị, Hồ sơ); Code: 5 tab (Sức khỏe, Giấc ngủ, Khẩn cấp, Gia đình, Cá nhân). Device = route `/device`, không phải tab |

---

### Phase 2 — Device + Dashboard

| Spec | health_system | Status |
|------|---------------|--------|
| HOME_Dashboard | HealthMonitoringScreen (tab 1) | ✅ Spec+Code |
| DEVICE_List | DeviceScreen | ✅ Spec+Code |
| DEVICE_Connect | Dialog "Đăng ký thiết bị" (form thủ công) | ⚠️ **Khác spec** — Spec: BLE scan → Chọn → Pair; Code: Dialog nhập name, type, model, MAC, serial, MQTT |
| DEVICE_StatusDetail | Bottom sheet (thông tin trên card) | ⚠️ **Khác spec** — Spec: Full screen + pin % + nút Cấu hình; Code: ModalBottomSheet, thiếu pin %, thiếu link Configure |

---

### Phase 3 — Health Core

| Spec | health_system | Status |
|------|---------------|--------|
| MONITORING_VitalDetail | VitalDetailScreen | ✅ Spec+Code |
| MONITORING_HealthHistory | HealthReportScreen | ✅ Spec+Code |
| SLEEP_Report | SleepScreen | ✅ Spec+Code |
| SLEEP_Detail | SleepTimelineBar inline trong SleepScreen | 🔄 **Partial** — Spec: Màn riêng drill-down timeline; Code: Inline widget, chưa có màn chi tiết |
| ANALYSIS_RiskReport | — | ⬜ **Missing** |
| ANALYSIS_RiskReportDetail | — | ⬜ **Missing** |

---

### Phase 4 — Emergency SOS

| Spec | health_system | Status |
|------|---------------|--------|
| EMERGENCY_ManualSOS | ManualSOSScreen (countdown 5s → gửi SOS) | ⚠️ **Khác spec** — Spec: Sau gửi → LocalSOSActive; Code: SnackBar + pop, không navigate LocalSOSActive |
| EMERGENCY_LocalSOSActive | — | ⬜ **Missing** — Màn "SOS đang phát" với countdown, contact emergency |
| EMERGENCY_FallAlert | — | ⬜ **Missing** |
| EMERGENCY_IncomingSOSAlarm | — | ⬜ **Missing** — FCM P0 full-screen khi nhận SOS |
| EMERGENCY_SOSReceivedList | EmergencySOSReceivedListScreen | ✅ Spec+Code |
| EMERGENCY_SOSReceivedDetail | EmergencySOSDetailScreen | ✅ Spec+Code |

---

### Phase 5 — Family

| Spec | health_system | Status |
|------|---------------|--------|
| HOME_FamilyDashboard | FamilyManagementScreen (tab Gia đình) | ⚠️ **Khác spec** — Spec mới yêu cầu card có `risk_summary` + mở `RiskReport(profileId)`; code hiện chưa phản ánh flow này |
| PROFILE_ContactList | FamilyManagementScreen tab Danh bạ | ✅ Spec+Code |
| PROFILE_AddContact | UserSearchTab (route search-user) | ✅ Spec+Code |
| PROFILE_LinkedContactDetail | UserDetailScreen | ✅ Spec+Code |

---

### Phase 6 — Profile

| Spec | health_system | Status |
|------|---------------|--------|
| PROFILE_Overview | ProfileScreen | ✅ Spec+Code |
| PROFILE_EditProfile | EditProfileScreen | ✅ Spec+Code |
| PROFILE_MedicalInfo | — | ⬜ **Missing** |
| PROFILE_ChangePassword | ChangePasswordScreen | ✅ Spec+Code |
| PROFILE_DeleteAccount | Dialog trong ProfileScreen | ⚠️ **Khác spec** — Spec: 3-step flow (confirm → nhập password → final); Code: 1 dialog đơn giản |

---

### Phase 7 — Notifications & Config

| Spec | health_system | Status |
|------|---------------|--------|
| NOTIFICATION_Center | — | ⬜ **Missing** |
| NOTIFICATION_Detail | — | ⬜ **Missing** |
| NOTIFICATION_EmergencyContacts | — | ⬜ **Missing** |
| NOTIFICATION_AddEditContact | — | ⬜ **Missing** |
| NOTIFICATION_Settings | — | ⬜ **Missing** |
| SLEEP_History | — | ⬜ **Missing** |
| SLEEP_TrackingSettings | — | ⬜ **Missing** |
| ANALYSIS_RiskHistory | — | ⬜ **Missing** |
| DEVICE_Configure | — | ⬜ **Missing** |
| AUTH_Onboarding | — | ⬜ **Missing** |

---

## 🧭 Build Guidance cập nhật

### Recommended order để build hợp lý

1. **Pass A — Self foundation:** Phase 1 → Phase 2 → Phase 3 self flow (`HOME_Dashboard` → Vital / Sleep / Risk).
2. **Pass B — Family foundation:** Phase 5 contacts + permissions + FamilyDashboard card structure.
3. **Pass C — Linked integration:** quay lại gắn `RiskReport(profileId)` và verify `VitalDetail(profileId)`, `SleepReport(profileId)`, `RiskReport(profileId)` từ FamilyDashboard.
4. **Pass D — Safety:** Phase 4 Emergency để đồng bộ với self + linked monitoring.
5. **Pass E — Polish:** Phase 6 → Phase 7.

### Vì sao phải build như vậy?

- `Risk` hiện là core feature, nhưng **linked risk flow không test được đúng** nếu chưa có FamilyDashboard card và `can_view_vitals`.
- `profileId` đã được chuẩn hóa là contextual route arg; vì vậy Phase 3 phải code theo pattern này ngay từ đầu, dù Pass A mới build self flow.
- Phase 7 (History, Notification, Settings) chỉ hợp lý khi self flow và linked flow đều đã rõ.

---

## 🧭 Proposed Fix Direction

### 1. DEVICE_Connect
- **Vấn đề hiện tại**: Code đang dùng dialog form thủ công ngay từ đầu, buộc user nhập `name`, `MAC`, `serial`, `MQTT`, làm lệch mục tiêu UX "đơn giản mặc định cho người già".
- **Hướng sửa đề xuất**:
  - Refactor từ dialog sang **màn riêng** `DEVICE_Connect`.
  - Luồng mặc định: `Intro -> kiểm tra permission/Bluetooth -> scan BLE -> chọn thiết bị -> pairing -> success`.
  - Hạ form thủ công xuống **secondary path** `Nhập mã thiết bị thủ công`, chỉ dành cho ca nâng cao hoặc fallback khi scan không hoạt động.
  - Với bối cảnh simulator hiện tại, có thể dùng **mock BLE demo / hybrid demo** cho discovery, còn data ingestion vẫn giữ `MQTT/HTTP`.
- **Mục tiêu UX**:
  - Người già hiểu công nghệ có thể hoàn thành connect flow mà không cần đọc thông tin kỹ thuật.
  - Người dùng chuyên sâu vẫn có đường vào manual mode khi thật sự cần.
- **Plan tham chiếu**: `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/DEVICE_Connect_plan.md`

### 2. DEVICE_StatusDetail
- **Vấn đề hiện tại**: Tap card chỉ mở bottom sheet ngắn, thiếu `pin %` nổi bật và không có CTA `Cấu hình`; thông tin routine và metadata kỹ thuật bị trộn lẫn.
- **Hướng sửa đề xuất**:
  - Tách thành **full screen** `DEVICE_StatusDetail` thay cho `ModalBottomSheet`.
  - Vùng ưu tiên đầu phải hiển thị rõ:
    - tên thiết bị
    - loại thiết bị
    - pin %
    - online/offline
    - last sync
  - Thêm CTA rõ ràng `Cấu hình thiết bị` để điều hướng sang `DEVICE_Configure`.
  - Đẩy `firmware`, `serial`, `MAC`, `MQTT` xuống section `Thông tin kỹ thuật` ở nửa dưới màn để giảm cognitive load.
  - Sau khi quay về từ `DEVICE_Configure`, màn detail cần **refetch**; nếu unpair/delete thì back về `DEVICE_List`.
- **Mục tiêu UX**:
  - User phổ thông có một điểm kiểm tra tình trạng thiết bị ổn định, dễ đọc, không gây rối.
  - User chuyên sâu vẫn xem được thông tin kỹ thuật và đi tiếp sang cấu hình nâng cao.
- **Plan tham chiếu**: `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/DEVICE_StatusDetail_plan.md`

### 3. Risk flow theo Hybrid Architecture
- **Vấn đề hiện tại**: `ANALYSIS_RiskReport` và `RiskReportDetail` chưa có code; đồng thời `HOME_FamilyDashboard` trong code chưa có `risk_summary` để mở linked risk flow.
- **Hướng sửa đề xuất**:
  - Build `ANALYSIS_RiskReport` trước cho **self flow** từ `HOME_Dashboard`.
  - Build `ANALYSIS_RiskReportDetail` ngay sau đó để hoàn tất cặp overview + XAI.
  - Khi sang Phase 5 integration, bổ sung `risk_summary` vào payload `family-dashboard`.
  - Trên Family card, thêm vùng tap riêng cho `Risk summary` → mở `ANALYSIS_RiskReport(profileId)`.
- **Mục tiêu UX**:
  - Self: User thấy ngay giá trị cốt lõi của app trên dashboard cá nhân.
  - Linked: Caregiver xem risk của người thân mà không cần profile switcher.

---

## 📈 Tổng kết

| Loại | Ghi chú |
|------|--------|
| ✅ Spec+Code | Nhiều màn core self flow đã có, đủ để tiếp tục build theo phase |
| ⚠️ Khác spec | Tập trung ở Bottom Nav, DEVICE_Connect, DEVICE_StatusDetail, ManualSOS flow, DeleteAccount, và **HOME_FamilyDashboard risk integration** |
| 🔄 Partial | `SLEEP_Detail` đang là inline widget, chưa tách màn |
| ⬜ Missing | Chủ yếu là Risk, Emergency còn thiếu, Notifications & Config |

---

## 🔧 Khuyến nghị ưu tiên

1. **DEVICE_StatusDetail** — Tách Bottom sheet thành full screen, thêm pin %, nút Cấu hình
2. **DEVICE_Connect** — Refactor: Dialog → màn BLE (hoặc chấp nhận Dialog nếu product quyết định)
3. **ANALYSIS_RiskReport + ANALYSIS_RiskReportDetail** — Implement self flow trước (Phase 3 core)
4. **HOME_FamilyDashboard risk integration** — thêm `risk_summary` + mở `RiskReport(profileId)`
5. **EMERGENCY_LocalSOSActive** — ManualSOS sau khi gửi cần navigate đây thay vì pop
6. **EMERGENCY_FallAlert**, **EMERGENCY_IncomingSOSAlarm** — Safety critical
