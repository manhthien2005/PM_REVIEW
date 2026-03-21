# Tổng hợp API cho các màn hình (Mobile App)

Dưới đây là danh sách tổng hợp chi tiết tất cả **41 màn hình** hiện có trong thư mục `Screen`. Trạng thái (DONE / Missing) phản ánh tiến độ thực hiện hoặc định nghĩa API trong tài liệu kỹ thuật.

### 1. Analysis (ANALYSIS)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **ANALYSIS_RiskHistory** | `GET /api/mobile/risk-report/history` | **DONE** |
| **ANALYSIS_RiskReport** | `GET /api/mobile/risk-report/latest` | **DONE** |
| **ANALYSIS_RiskReportDetail** | `GET /api/mobile/risk-report/:reportId`<br>`GET /api/mobile/risk-report/latest/detail` | **DONE** |

### 2. Authentication (AUTH)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **AUTH_ForgotPassword** | `POST /api/auth/forgot-password` | **DONE** |
| **AUTH_Login** | `POST /api/auth/login` | **DONE** |
| **AUTH_Onboarding** | _Không có API (UI-only hoặc Local)_ | **DONE** |
| **AUTH_Register** | `POST /api/auth/register` | **DONE** |
| **AUTH_ResetPassword** | `POST /api/auth/reset-password` | **DONE** |
| **AUTH_Splash** | _Không có API (UI-only hoặc Local)_ | **DONE** |
| **AUTH_VerifyEmail** | `POST /api/auth/resend-verification`<br>`POST /api/auth/verify-email` | **DONE** |

### 3. Devices (DEVICE)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **DEVICE_Configure** | `DELETE /api/mobile/devices/:deviceId`<br>`GET /api/mobile/devices/:deviceId/config`<br>`PATCH /api/mobile/devices/:deviceId` | **DONE** |
| **DEVICE_Connect** | `POST /api/mobile/devices`<br>`POST /api/mobile/devices/bind` | **DONE** |
| **DEVICE_List** | `GET /api/mobile/devices` | **DONE** |
| **DEVICE_StatusDetail** | `GET /api/mobile/devices/:deviceId` | **DONE** |

### 4. Emergency (EMERGENCY)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **EMERGENCY_FallAlert** | `POST /api/mobile/sos/cancel`<br>`POST /api/mobile/sos/send` | **DONE** |
| **EMERGENCY_IncomingSOSAlarm** | _Không có API_ | **DONE** |
| **EMERGENCY_LocalSOSActive** | `POST /api/mobile/sos/:sosId/resolve`<br>`POST /api/mobile/sos/send` | **DONE** |
| **EMERGENCY_ManualSOS** | `POST /api/mobile/sos/send` | **DONE** |
| **EMERGENCY_SOSReceivedDetail** | `GET /api/mobile/sos/:sosId`<br>`POST /api/mobile/sos/:sosId/resolve` | **DONE** |
| **EMERGENCY_SOSReceivedList** | `GET /api/mobile/sos/received` | **DONE** |

### 5. Home (HOME)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **HOME_Dashboard** | `GET /api/mobile/dashboard/self`<br>`WS /api/mobile/vitals/stream` | **DONE** |
| **HOME_FamilyDashboard** | `GET /api/mobile/access-profiles`<br>`GET /api/mobile/family-dashboard` | **DONE** |

### 6. Monitoring (MONITORING)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **MONITORING_HealthHistory** | `GET /api/mobile/health-history` | **DONE** |
| **MONITORING_VitalDetail** | `GET /api/mobile/vitals/:vitalType/detail` | **DONE** |

### 7. Notifications (NOTIFICATION)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **NOTIFICATION_AddEditContact** | `PATCH /api/mobile/emergency-contacts/:id`<br>`POST /api/mobile/emergency-contacts` | **DONE** |
| **NOTIFICATION_Center** | `GET /api/mobile/notifications` | **DONE** |
| **NOTIFICATION_Detail** | `GET /api/mobile/notifications/:id`<br>`PATCH /api/mobile/notifications/:id/read` | **DONE** |
| **NOTIFICATION_EmergencyContacts** | `GET /api/mobile/emergency-contacts` | **DONE** |
| **NOTIFICATION_Settings** | `GET /api/mobile/notification-settings`<br>`PATCH /api/mobile/notification-settings` | **DONE** |

### 8. Profile (PROFILE)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **PROFILE_AddContact** | `GET /api/mobile/user/my-code`<br>`POST /api/mobile/contacts/request` | **DONE** |
| **PROFILE_ChangePassword** | `POST /api/mobile/profile/change-password` | **DONE** |
| **PROFILE_ContactList** | `GET /api/mobile/contacts`<br>`GET /api/mobile/contacts/pending`<br>`POST /api/mobile/contacts/`<br>`POST /api/mobile/contacts/request` | **DONE** |
| **PROFILE_DeleteAccount** | `DELETE /api/mobile/profile`<br>`POST /api/mobile/profile/delete-account` | **DONE** |
| **PROFILE_EditProfile** | `GET /api/mobile/profile/self`<br>`PATCH /api/mobile/profile/self`<br>`POST /api/mobile/profile/avatar` | **DONE** |
| **PROFILE_LinkedContactDetail** | `DELETE /api/mobile/contacts/`<br>`GET /api/mobile/contacts/`<br>`PATCH /api/mobile/contacts/` | **DONE** |
| **PROFILE_MedicalInfo** | `GET /api/mobile/profile/medical-info`<br>`PATCH /api/mobile/profile/medical-info` | **DONE** |
| **PROFILE_Overview** | `GET /api/mobile/profile/self` | **DONE** |

### 9. Sleep (SLEEP)
| Màn hình | Các API endpoints | Trạng thái |
|----------|-------------------|------------|
| **SLEEP_Detail** | `GET /api/mobile/sleep/detail` | **DONE** |
| **SLEEP_History** | `GET /api/mobile/sleep/history` | **DONE** |
| **SLEEP_Report** | `GET /api/mobile/sleep/report` | **DONE** |
| **SLEEP_TrackingSettings** | `GET /api/mobile/sleep/settings`<br>`PATCH /api/mobile/sleep/settings` | **DONE** |

*(Ghi chú: Thống kê này bao gồm toàn bộ **41 màn hình** nằm trong thư mục `PM_REVIEW/REVIEW_MOBILE/Screen`. Các file không có API được đánh dấu rõ ràng. Hiện tại theo nội dung mô tả, các API đều ở trạng thái DONE).*
