# 📊 Báo cáo tiến độ — health_system vs Spec

> Updated: 2026-03-17
> So sánh implementation thực tế (health_system) với spec trong `Screen/` và `BUILD_PHASES/`.

---

## Tổng quan

| Metric | Số lượng |
| --- | --- |
| Spec files tồn tại | **41/43** |
| Screens đã build (health_system) | **~22** |
| Spec chưa có file | 2 (MONITORING_HealthMetrics nếu tách riêng) |
| Khác biệt Spec vs Implementation | Xem bảng dưới |

---

## Phase 1 — Shell & Auth ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| AUTH_Splash | AuthPagesScreen + StartScreen | `AUTH_Splash.md` | ✅ Spec + Code |
| AUTH_Login | LoginScreen | `AUTH_Login.md` | ✅ Spec + Code |
| AUTH_Register | RegisterScreen | `AUTH_Register.md` | ✅ Spec + Code |
| AUTH_VerifyEmail | EmailVerificationScreen | `AUTH_VerifyEmail.md` | ✅ Spec + Code |
| AUTH_ForgotPassword | ForgotPasswordScreen | `AUTH_ForgotPassword.md` | ✅ Spec + Code |
| AUTH_ResetPassword | ResetPasswordScreen | `AUTH_ResetPassword.md` | ✅ Spec + Code |
| Bottom Nav | MainScreen (5 tabs) | Phase1_Auth.md | ⚠️ **Khác spec** (5 vs 4 tab) |

---

## Phase 2 — Device + Dashboard ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| HOME_Dashboard | HealthMonitoringScreen (tab 1) | `HOME_Dashboard.md` | ✅ Spec + Code |
| DEVICE_List | DeviceScreen | `DEVICE_List.md` | ✅ Spec + Code |
| DEVICE_Connect | Dialog "Đăng ký thiết bị" (form thủ công) | `DEVICE_Connect.md` | ⚠️ Khác: Dialog thay BLE |
| DEVICE_StatusDetail | Thông tin trên card | `DEVICE_StatusDetail.md` | ⬜ Spec only |

---

## Phase 3 — Health Core ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| MONITORING_VitalDetail | VitalDetailScreen | `MONITORING_VitalDetail.md` | ✅ Spec + Code |
| MONITORING_HealthHistory | HealthReportScreen | `MONITORING_HealthHistory.md` | ✅ Spec + Code |
| SLEEP_Report | SleepScreen | `SLEEP_Report.md` | ✅ Spec + Code |
| SLEEP_Detail | SleepTimelineBar inline | `SLEEP_Detail.md` | 🔄 Partial |
| ANALYSIS_RiskReport | — | `ANALYSIS_RiskReport.md` | ⬜ Spec only |
| ANALYSIS_RiskReportDetail | — | `ANALYSIS_RiskReportDetail.md` | ⬜ Spec only |

---

## Phase 4 — Emergency SOS ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| EMERGENCY_ManualSOS | — | `EMERGENCY_ManualSOS.md` | ⬜ Spec only |
| EMERGENCY_LocalSOSActive | — | `EMERGENCY_LocalSOSActive.md` | ⬜ Spec only |
| EMERGENCY_FallAlert | — | `EMERGENCY_FallAlert.md` | ⬜ Spec only |
| EMERGENCY_IncomingSOSAlarm | — | `EMERGENCY_IncomingSOSAlarm.md` | ⬜ Spec only |
| EMERGENCY_SOSReceivedList | EmergencySOSReceivedListScreen | `EMERGENCY_SOSReceivedList.md` | ✅ Spec + Code |
| EMERGENCY_SOSReceivedDetail | EmergencySOSDetailScreen | `EMERGENCY_SOSReceivedDetail.md` | ✅ Spec + Code |

---

## Phase 5 — Family ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| HOME_FamilyDashboard | FamilyManagementScreen (tab Người thân) | `HOME_FamilyDashboard.md` | ✅ Spec + Code |
| PROFILE_ContactList | FamilyManagementScreen tab 2 | `PROFILE_ContactList.md` | ✅ Spec + Code |
| PROFILE_AddContact | UserSearchTab (tab Tìm kiếm) | `PROFILE_AddContact.md` | ✅ Spec + Code |
| PROFILE_LinkedContactDetail | UserDetailScreen | `PROFILE_LinkedContactDetail.md` | ✅ Spec + Code |

---

## Phase 6 — Profile ✅

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| PROFILE_Overview | ProfileScreen | `PROFILE_Overview.md` | ✅ Spec + Code |
| PROFILE_EditProfile | EditProfileScreen | `PROFILE_EditProfile.md` | ✅ Spec + Code |
| PROFILE_MedicalInfo | — | `PROFILE_MedicalInfo.md` | ⬜ Spec only |
| PROFILE_ChangePassword | ChangePasswordScreen | `PROFILE_ChangePassword.md` | ✅ Spec + Code |
| PROFILE_DeleteAccount | Dialog trong ProfileScreen | `PROFILE_DeleteAccount.md` | ⚠️ 1 dialog, chưa 3-step |

---

## Phase 7 — Notifications & Config ✅ (Spec)

| Spec | health_system | File | Status |
| --- | --- | --- | --- |
| NOTIFICATION_Center | — | `NOTIFICATION_Center.md` | ⬜ Spec only |
| NOTIFICATION_Detail | — | `NOTIFICATION_Detail.md` | ⬜ Spec only |
| NOTIFICATION_EmergencyContacts | — | `NOTIFICATION_EmergencyContacts.md` | ⬜ Spec only |
| NOTIFICATION_AddEditContact | — | `NOTIFICATION_AddEditContact.md` | ⬜ Spec only |
| NOTIFICATION_Settings | — | `NOTIFICATION_Settings.md` | ⬜ Spec only |
| SLEEP_History | — | `SLEEP_History.md` | ⬜ Spec only |
| SLEEP_TrackingSettings | — | `SLEEP_TrackingSettings.md` | ⬜ Spec only |
| ANALYSIS_RiskHistory | — | `ANALYSIS_RiskHistory.md` | ⬜ Spec only |
| DEVICE_Configure | — | `DEVICE_Configure.md` | ⬜ Spec only |
| AUTH_Onboarding | — | `AUTH_Onboarding.md` | ⬜ Spec only |

---

## Khác biệt chính: Bottom Nav

| Spec (Phase1) | health_system MainScreen |
| --- | --- |
| 4 tab: Sức khoẻ, Gia đình, Thiết bị, Hồ sơ | 5 tab: Sức khỏe, Giấc ngủ, Khẩn cấp, Gia đình, Cá nhân |
| Device = tab | Device = route `/device` |

---

## Changelog (2026-03-17)

- **Phase 2–7**: Tạo đầy đủ spec files cho tất cả màn hình còn thiếu.
- **Tổng cộng**: 41 spec files (trừ README).
- **Cross-links**: Các spec đã link 2 chiều theo phase requirements.
