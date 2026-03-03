# DANH SÁCH USE CASE - HỆ THỐNG HEALTHGUARD

> **Phiên bản**: 4.0  
> **Ngày cập nhật**: 03/03/2026  
> **Trạng thái**: ✅ Hoàn tất 26/26 UC

---

## 📁 CẤU TRÚC THƯ MỤC

```
UC/
├── 00_DANH_SACH_USE_CASE.md
├── README.md
├── Authentication/
│   ├── UC001_Login.md
│   ├── UC002_Register.md
│   ├── UC003_ForgotPassword.md
│   ├── UC004_ChangePassword.md
│   ├── UC005_Manage_Profile.md
│   └── UC009_Logout.md
├── Monitoring/
│   ├── UC006_View_Health_Metrics.md
│   ├── UC007_View_Health_Metrics_Detail.md
│   └── UC008_View_Health_History.md
├── Emergency/
│   ├── UC010_Confirm_After_Fall_Alert.md
│   ├── UC011_Confirm_Safety_Resolution.md
│   ├── UC014_Send_Manual_SOS.md
│   └── UC015_Receive_SOS_Notification.md
├── Analysis/
│   ├── UC016_View_Risk_Report.md
│   └── UC017_View_Risk_Report_Detail.md
├── Admin/
│   ├── UC022_Manage_Users.md
│   ├── UC024_Configure_System.md
│   ├── UC025_Manage_Devices.md
│   └── UC026_View_System_Logs.md
├── Sleep/
│   ├── UC020_Analyze_Sleep.md
│   └── UC021_View_Sleep_Report.md
├── Notification/
│   ├── UC030_Configure_Emergency_Contacts.md
│   └── UC031_Manage_Notifications.md
└── Device/
    ├── UC040_Connect_Device.md
    ├── UC041_Configure_Device.md
    └── UC042_View_Device_Status.md
```

---

## ✅ DANH SÁCH USE CASE (26 UC)

### 1. Authentication (Xác thực) — 6 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC001** | Đăng nhập vào hệ thống | Bệnh nhân, Người chăm sóc, Admin | Mobile + Admin Web | `Authentication/UC001_Login.md` |
| **UC002** | Đăng ký tài khoản mới | Bệnh nhân, Người chăm sóc | Mobile | `Authentication/UC002_Register.md` |
| **UC003** | Khôi phục mật khẩu khi quên | Bệnh nhân, Người chăm sóc | Mobile | `Authentication/UC003_ForgotPassword.md` |
| **UC004** | Thay đổi mật khẩu | Bệnh nhân, Người chăm sóc | Mobile | `Authentication/UC004_ChangePassword.md` |
| **UC005** | Quản lý hồ sơ cá nhân | Bệnh nhân, Người chăm sóc | Mobile | `Authentication/UC005_Manage_Profile.md` |
| **UC009** | Đăng xuất khỏi hệ thống | Bệnh nhân, Người chăm sóc, Admin | Mobile + Admin Web | `Authentication/UC009_Logout.md` |

### 2. Monitoring (Giám sát sức khỏe) — 3 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC006** | Xem chỉ số sức khỏe real-time | Bệnh nhân, Người chăm sóc | Mobile | `Monitoring/UC006_View_Health_Metrics.md` |
| **UC007** | Xem chi tiết chỉ số sức khỏe | Bệnh nhân, Người chăm sóc | Mobile | `Monitoring/UC007_View_Health_Metrics_Detail.md` |
| **UC008** | Xem lịch sử chỉ số sức khỏe | Bệnh nhân, Người chăm sóc | Mobile | `Monitoring/UC008_View_Health_History.md` |

### 3. Emergency (Khẩn cấp) — 4 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC010** | Xác nhận an toàn sau cảnh báo té ngã | Bệnh nhân | Mobile | `Emergency/UC010_Confirm_After_Fall_Alert.md` |
| **UC011** | Xác nhận an toàn & kết thúc sự cố | Bệnh nhân, Người chăm sóc | Mobile | `Emergency/UC011_Confirm_Safety_Resolution.md` |
| **UC014** | Gửi SOS khẩn cấp thủ công | Bệnh nhân | Mobile | `Emergency/UC014_Send_Manual_SOS.md` |
| **UC015** | Nhận và xử lý thông báo SOS | Người chăm sóc | Mobile | `Emergency/UC015_Receive_SOS_Notification.md` |

### 4. Analysis (Phân tích) — 2 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC016** | Xem báo cáo đánh giá rủi ro | Bệnh nhân, Người chăm sóc | Mobile | `Analysis/UC016_View_Risk_Report.md` |
| **UC017** | Xem chi tiết báo cáo rủi ro | Bệnh nhân, Người chăm sóc | Mobile | `Analysis/UC017_View_Risk_Report_Detail.md` |

### 5. Sleep (Giấc ngủ) — 2 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC020** | Phân tích giấc ngủ | Bệnh nhân | Mobile | `Sleep/UC020_Analyze_Sleep.md` |
| **UC021** | Xem báo cáo giấc ngủ | Bệnh nhân, Người chăm sóc | Mobile | `Sleep/UC021_View_Sleep_Report.md` |

### 6. Admin (Quản trị) — 4 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC022** | Quản lý người dùng | Quản trị viên | Admin Web | `Admin/UC022_Manage_Users.md` |
| **UC024** | Cấu hình hệ thống | Quản trị viên | Admin Web | `Admin/UC024_Configure_System.md` |
| **UC025** | Quản lý thiết bị IoT (Admin) | Quản trị viên | Admin Web | `Admin/UC025_Manage_Devices.md` |
| **UC026** | Xem nhật ký hệ thống | Quản trị viên | Admin Web | `Admin/UC026_View_System_Logs.md` |

### 7. Notification (Thông báo) — 2 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC030** | Cấu hình Emergency Contacts | Bệnh nhân | Mobile | `Notification/UC030_Configure_Emergency_Contacts.md` |
| **UC031** | Quản lý thông báo | Bệnh nhân, Người chăm sóc | Mobile | `Notification/UC031_Manage_Notifications.md` |

### 8. Device (Thiết bị) — 3 UC

| Mã UC | Tên Use Case | Actor | Platform | File |
|-------|-------------|-------|----------|------|
| **UC040** | Kết nối thiết bị IoT (User pair) | Bệnh nhân | Mobile | `Device/UC040_Connect_Device.md` |
| **UC041** | Cấu hình thiết bị IoT | Bệnh nhân | Mobile | `Device/UC041_Configure_Device.md` |
| **UC042** | Xem trạng thái thiết bị | Bệnh nhân, Người chăm sóc | Mobile | `Device/UC042_View_Device_Status.md` |

---

## ❌ ĐÃ XÓA - KHÔNG PHẢI USE CASE

| Mã cũ | Tên cũ | Lý do xóa |
|-------|--------|-----------| 
| ~~UC005~~ | Thu thập dữ liệu sinh tồn | System background process, không có user interaction |
| ~~UC018~~ | Cung cấp giải thích AI (XAI) | Không phải UC độc lập, đã tích hợp vào UC010 và UC016 |
| ~~UC023~~ | Xem Dashboard tổng hợp | Chỉ là view data, không có interaction thực sự |

---

## 📌 UC CÒN THIẾU (Cần bổ sung trong tương lai)

> ✅ Không còn UC nào thiếu. Tất cả UC đã được bổ sung đầy đủ (v4.0 — 03/03/2026).

> **Ghi chú lịch sử**: UC003 ban đầu được lên kế hoạch cho "Quản lý hồ sơ cá nhân" nhưng trong quá trình phát triển đã được dùng cho "Quên mật khẩu" (Forgot Password). UC quản lý hồ sơ cá nhân đã được bổ sung với ID UC005.

---

## 🗺️ PLATFORM MAPPING

### Mobile App (Bệnh nhân + Người chăm sóc) → Mobile Backend (FastAPI)

| Module | UCs |
|--------|-----|
| Authentication | UC001, UC002, UC003, UC004, UC005, UC009 |
| Monitoring | UC006, UC007, UC008 |
| Emergency | UC010, UC011, UC014, UC015 |
| Analysis | UC016, UC017 |
| Sleep | UC020, UC021 |
| Notification | UC030, UC031 |
| Device | UC040, UC041, UC042 |
| **Tổng** | **22 UC** |

### Admin Web (Quản trị viên) → Admin Backend (Node.js)

| Module | UCs |
|--------|-----|
| Authentication | UC001 (Admin login), UC009 (Admin logout) |
| Admin | UC022, UC024, UC025, UC026 |
| **Tổng** | **6 UC** |

> **Lưu ý**: UC001 phục vụ cả 2 platform nhưng logic xác thực khác nhau (Admin BE dùng JWT secret riêng, expiry 8h; Mobile BE dùng JWT secret riêng, access token 30 ngày + refresh token 90 ngày).

---

## 🔗 MỐI QUAN HỆ GIỮA CÁC UC

### Include:
- UC006 (View Health Metrics) **includes** UC007 (Xem chi tiết)
- UC016 (View Risk Report) **includes** UC017 (Xem chi tiết)

### Extend:
- UC010 (Confirm After Fall Alert) **extends to** UC014 (Send SOS) nếu không phản hồi

### Trigger chains:
```
Fall Detection (AI Service) 
  → UC010 (Confirm) 
    → [không phản hồi] 
      → UC014 (Send SOS) 
        → UC015 (Nhận SOS)
          → UC011 (Xác nhận an toàn)
```

### Phân biệt UC025 vs UC040:
- **UC025** (Admin): Admin gán/bỏ gán/khóa thiết bị trên Dashboard → quản trị tập trung
- **UC040** (User): Bệnh nhân tự pair thiết bị bằng mã/QR trên Mobile App → self-service

---

## 📊 THỐNG KÊ

| Metric | Số lượng |
|--------|----------|
| **Tổng UC đã hoàn thành** | 26 |
| **UC đã xóa** | 3 |
| **UC còn thiếu** | 0 |
| **Tổng UC dự kiến** | 26 |
| **Tiến độ** | 100% (26/26) |

---

## 🎯 ƯU TIÊN PHÁT TRIỂN

### Phase 1 — Core Features ⭐⭐⭐⭐⭐
- ✅ UC001 - Login
- ✅ UC002 - Register
- ✅ UC009 - Logout
- ✅ UC006 - View Health Metrics
- ✅ UC010 - Confirm After Fall Alert
- ✅ UC014 - Send Manual SOS

### Phase 2 — Advanced Features ⭐⭐⭐⭐
- ✅ UC016 - View Risk Report
- ✅ UC007 - Xem chi tiết chỉ số
- ✅ UC015 - Nhận SOS (Người chăm sóc)
- ✅ UC011 - Xác nhận an toàn
- ✅ UC003 - Quên mật khẩu
- ✅ UC004 - Đổi mật khẩu
- ✅ UC005 - Quản lý hồ sơ cá nhân

### Phase 3 — Admin & Management ⭐⭐⭐
- ✅ UC022 - Manage Users
- ✅ UC024 - Cấu hình hệ thống
- ✅ UC030 - Cấu hình Emergency Contacts
- ✅ UC025 - Quản lý thiết bị (Admin)
- ✅ UC026 - Xem nhật ký hệ thống

### Phase 4 — Extended Features ⭐⭐
- ✅ UC020, UC021 - Sleep Analysis
- ✅ UC040, UC041, UC042 - Device Management (User)
- ✅ UC008 - Xem lịch sử chỉ số
- ✅ UC017 - Chi tiết rủi ro
- ✅ UC031 - Quản lý thông báo

---

**Người thực hiện refactor**: Senior BA & Software Engineer  
**Review by**: SRS_AGENT (AI Review - 03/03/2026)  
**Approved by**: [Chờ phê duyệt]
