# 📘 USE CASE SPECIFICATION - HEALTHGUARD SYSTEM

> **Hệ thống**: HealthGuard - Giám sát và cảnh báo sức khỏe qua thiết bị IoT  
> **Phiên bản**: 4.0  
> **Ngày cập nhật**: 05/03/2026

---

## 🗂️ CẤU TRÚC THƯ MỤC

```
UC/
├── 00_DANH_SACH_USE_CASE.md     # Danh sách tổng hợp tất cả UC
├── README.md                     # File hướng dẫn này
│
├── Authentication/               # UC về xác thực
│   ├── UC001_Login.md
│   ├── UC002_Register.md
│   ├── UC003_ForgotPassword.md
│   ├── UC004_ChangePassword.md
│   ├── UC005_Manage_Profile.md
│   └── UC009_Logout.md
│
├── Monitoring/                   # UC về giám sát sức khỏe
│   ├── UC006_View_Health_Metrics.md
│   ├── UC007_View_Health_Metrics_Detail.md
│   └── UC008_View_Health_History.md
│
├── Emergency/                    # UC về khẩn cấp
│   ├── UC010_Confirm_After_Fall_Alert.md
│   ├── UC011_Confirm_Safety_Resolution.md
│   ├── UC014_Send_Manual_SOS.md
│   └── UC015_Receive_SOS_Notification.md
│
├── Analysis/                     # UC về phân tích rủi ro
│   ├── UC016_View_Risk_Report.md
│   └── UC017_View_Risk_Report_Detail.md
│
├── Admin/                        # UC quản trị (Admin Web)
│   ├── UC022_Manage_Users.md
│   ├── UC024_Configure_System.md
│   ├── UC025_Manage_Devices.md
│   └── UC026_View_System_Logs.md
│
├── Sleep/                        # UC phân tích giấc ngủ
│   ├── UC020_Analyze_Sleep.md
│   └── UC021_View_Sleep_Report.md
│
├── Notification/                 # UC thông báo & liên hệ khẩn cấp
│   ├── UC030_Configure_Emergency_Contacts.md
│   └── UC031_Manage_Notifications.md
│
└── Device/                       # UC quản lý thiết bị (User)
    ├── UC040_Connect_Device.md
    ├── UC041_Configure_Device.md
    └── UC042_View_Device_Status.md
```

---

## 📊 TÌNH TRẠNG

| Tổng UC | Đã hoàn thành | Còn thiếu | Đã xóa | Tiến độ |
| ------- | ------------- | --------- | ------ | ------- |
| 26      | 26            | 0         | 3      | 100%    |

---

## 📖 CÁCH ĐỌC USE CASE

Mỗi file UC sử dụng format chuẩn UML (Fully Dressed Format):

### 1. **Bảng đặc tả Use Case**
- Mã UC, Tên UC, Actor, Mô tả
- Trigger (sự kiện kích hoạt)
- Tiền điều kiện, Hậu điều kiện

### 2. **Luồng chính (Main Flow)**
Mô tả các bước khi mọi thứ diễn ra bình thường (Happy Path)

| Bước | Người thực hiện | Hành động |
| ---- | --------------- | --------- |
| 1    | Actor           | ...       |
| 2    | System          | ...       |

### 3. **Luồng thay thế (Alternative Flows)**
Các trường hợp ngoại lệ, lỗi, hoặc luồng khác:
- Đánh số theo bước gốc: 3.a, 3.b, ...
- Mỗi luồng có heading riêng

### 4. **Business Rules**
Quy tắc nghiệp vụ không thay đổi

### 5. **Yêu cầu phi chức năng**
Performance, Security, Usability, etc.

---

## 🎯 USE CASE QUAN TRỌNG NHẤT

### **Core Features** (Phải implement):

| UC        | Tên                      | Platform       | Trạng thái |
| --------- | ------------------------ | -------------- | ---------- |
| **UC001** | Login                    | Mobile + Admin | ✅ Done     |
| **UC002** | Register                 | Mobile         | ✅ Done     |
| **UC006** | View Health Metrics      | Mobile         | ✅ Done     |
| **UC010** | Confirm After Fall Alert | Mobile         | ✅ Done     |
| **UC014** | Send Manual SOS          | Mobile         | ✅ Done     |
| **UC016** | View Risk Report         | Mobile         | ✅ Done     |
| **UC022** | Manage Users             | Admin Web      | ✅ Done     |

---

## 🗺️ PLATFORM MAPPING

### Mobile App (Bệnh nhân + Người chăm sóc) → Mobile Backend (FastAPI)

| Module         | UCs                                      |
| -------------- | ---------------------------------------- |
| Authentication | UC001, UC002, UC003, UC004, UC005, UC009 |
| Monitoring     | UC006, UC007, UC008                      |
| Emergency      | UC010, UC011, UC014, UC015               |
| Analysis       | UC016, UC017                             |
| Sleep          | UC020, UC021                             |
| Notification   | UC030, UC031                             |
| Device         | UC040, UC041, UC042                      |
| **Tổng**       | **22 UC**                                |

### Admin Web (Quản trị viên) → Admin Backend (Node.js)

| Module         | UCs                                       |
| -------------- | ----------------------------------------- |
| Authentication | UC001 (Admin login), UC009 (Admin logout) |
| Admin          | UC022, UC024, UC025, UC026                |
| **Tổng**       | **6 UC**                                  |

> **Lưu ý**: UC001 phục vụ cả 2 platform nhưng logic xác thực khác nhau (Admin: JWT 8h, Mobile: access 30d + refresh 90d rotation).

## 🔗 MỐI QUAN HỆ GIỮA CÁC UC

### Dependencies Flow:

```
┌─────────────┐
│   UC001     │  Đăng nhập
│   Login     │
└──────┬──────┘
       │
       ▼
┌─────────────┐       ┌─────────────┐
│   UC006     │       │   UC010     │
│ View Health │◄──────┤ Fall Alert  │
│  Metrics    │       │  Confirm    │
└──────┬──────┘       └──────┬──────┘
       │                     │
       ▼                     │ [không phản hồi]
┌─────────────┐              ▼
│   UC007     │       ┌─────────────┐
│ Detail View │       │   UC014     │
└─────────────┘       │  Send SOS   │
       │              └──────┬──────┘
       ▼                     │
┌─────────────┐              ▼
│   UC008     │       ┌─────────────┐
│  History    │       │   UC015     │
└─────────────┘       │ Receive SOS │
                      └──────┬──────┘
                             │
                             ▼
                      ┌─────────────┐
                      │   UC011     │
                      │ Confirm Safe│
                      └─────────────┘
```

### Include relationships:
- UC006 **includes** UC007 (Xem chi tiết chỉ số)
- UC016 **includes** UC017 (Xem chi tiết báo cáo rủi ro)

### Extend relationships:
- UC010 **extends to** UC014 (nếu không phản hồi → gửi SOS)

### Phân biệt UC025 vs UC040:
- **UC025** (Admin Web): Admin gán/bỏ gán/khóa thiết bị → quản trị tập trung
- **UC040** (Mobile): Bệnh nhân tự pair thiết bị bằng mã/QR → self-service

---

## 🚀 HƯỚNG DẪN SỬ DỤNG

### 1. **Cho Developer**

Khi implement feature:
1. Đọc UC tương ứng để hiểu business requirement
2. Implement Main Flow trước
3. Sau đó implement Alternative Flows
4. Đảm bảo tuân thủ Business Rules
5. Check NFRs (Non-Functional Requirements)

**Lưu ý**: 
- Chi tiết technical (API, database, JSON schema) → Xem Technical Specification
- UC chỉ mô tả **WHAT** (làm gì), không mô tả **HOW** (làm thế nào)

### 2. **Cho Tester**

Test cases dựa trên:
- Main Flow → Happy path test
- Alternative Flows → Exception test cases
- Business Rules → Rule-based testing
- NFRs → Performance/Security testing

### 3. **Cho BA/PM**

Khi viết thêm UC mới:
1. Copy template từ UC001 hoặc UC006
2. Đảm bảo:
   - Tên UC theo format: `Động từ + Tân ngữ`
   - Actor là external entity (không phải "Hệ thống")
   - Main Flow ≤ 7-10 bước
   - Loại bỏ technical details
3. Đặt file vào folder phù hợp
4. Cập nhật `00_DANH_SACH_USE_CASE.md`

---

## ❌ NHỮNG GÌ KHÔNG NÊN CÓ TRONG UC

### Không phải Use Case:
- ❌ System background processes (VD: "Thu thập dữ liệu")
- ❌ UI components (VD: "Hiển thị button")
- ❌ Technical functions (VD: "Gọi API X")
- ❌ View-only screens không có interaction

### Không nên trong UC:
- ❌ Mã nguồn, pseudocode
- ❌ Database schema, SQL query, tên bảng DB
- ❌ JSON payload, API endpoint
- ❌ Chi tiết thuật toán AI
- ❌ Implementation chi tiết (bcrypt, JWT, ...)

→ **Chuyển sang**: Technical Specification

---

## 📋 SO SÁNH VỚI TÀI LIỆU SRS

| Phần SRS                                  | Use Cases tương ứng        |
| ----------------------------------------- | -------------------------- |
| **HG-FUNC-01, 02, 03** (Giám sát chỉ số)  | UC006, UC007, UC008        |
| **HG-FUNC-04, 05, 06, 07** (Té ngã & SOS) | UC010, UC011, UC014, UC015 |
| **HG-FUNC-08, 09** (Rủi ro & XAI)         | UC016, UC017               |
| **Xác thực**                              | UC001, UC002, UC003, UC004 |
| **Quản trị**                              | UC022, UC024, UC025, UC026 |
| **Giấc ngủ**                              | UC020, UC021               |
| **Thông báo**                             | UC030, UC031               |
| **Thiết bị**                              | UC040, UC041, UC042        |

---

**Cập nhật lần cuối**: 05/03/2026  
**Version**: 4.0  
**Status**: ✅ 26/26 UC hoàn thành  
**Next**: Không còn UC thiếu
