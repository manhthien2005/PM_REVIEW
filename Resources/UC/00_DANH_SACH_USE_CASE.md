# DANH SÁCH USE CASE - HỆ THỐNG HEALTHGUARD

> **Phiên bản**: 2.0 (Refactored)  
> **Ngày cập nhật**: 05/02/2026  
> **Trạng thái**: ✅ Hoàn tất refactor

---

## 📁 CẤU TRÚC THƯ MỤC

```
UC/
├── Authentication/
│   ├── UC001_Login.md
│   └── UC002_Register.md
├── Monitoring/
│   └── UC006_View_Health_Metrics.md
├── Emergency/
│   ├── UC010_Confirm_After_Fall_Alert.md
│   └── UC014_Send_Manual_SOS.md
├── Analysis/
│   └── UC016_View_Risk_Report.md
└── Admin/
    └── UC022_Manage_Users.md
```

---

## ✅ USE CASE ĐÃ HOÀN THÀNH (7 UC)

### 1. Authentication (Xác thực)

| Mã UC | Tên Use Case | Actor | File |
|-------|-------------|-------|------|
| **UC001** | Đăng nhập vào hệ thống | Bệnh nhân, Người chăm sóc, Admin | `Authentication/UC001_Login.md` |
| **UC002** | Đăng ký tài khoản mới | Bệnh nhân, Người chăm sóc | `Authentication/UC002_Register.md` |

### 2. Monitoring (Giám sát sức khỏe)

| Mã UC | Tên Use Case | Actor | File |
|-------|-------------|-------|------|
| **UC006** | Xem chỉ số sức khỏe real-time | Bệnh nhân, Người chăm sóc | `Monitoring/UC006_View_Health_Metrics.md` |

### 3. Emergency (Khẩn cấp)

| Mã UC | Tên Use Case | Actor | File |
|-------|-------------|-------|------|
| **UC010** | Xác nhận an toàn sau cảnh báo té ngã | Bệnh nhân | `Emergency/UC010_Confirm_After_Fall_Alert.md` |
| **UC014** | Gửi SOS thủ công | Bệnh nhân | `Emergency/UC014_Send_Manual_SOS.md` |

### 4. Analysis (Phân tích)

| Mã UC | Tên Use Case | Actor | File |
|-------|-------------|-------|------|
| **UC016** | Xem báo cáo đánh giá rủi ro | Bệnh nhân, Người chăm sóc | `Analysis/UC016_View_Risk_Report.md` |

### 5. Admin (Quản trị)

| Mã UC | Tên Use Case | Actor | File |
|-------|-------------|-------|------|
| **UC022** | Quản lý người dùng | Quản trị viên | `Admin/UC022_Manage_Users.md` |

---

## ❌ ĐÃ XÓA - KHÔNG PHẢI USE CASE

| Mã cũ | Tên cũ | Lý do xóa |
|-------|--------|-----------|
| ~~UC005~~ | Thu thập dữ liệu sinh tồn | System background process, không có user interaction |
| ~~UC018~~ | Cung cấp giải thích AI (XAI) | Không phải UC độc lập, đã tích hợp vào UC010 và UC016 |
| ~~UC023~~ | Xem Dashboard tổng hợp | Chỉ là view data, không có interaction thực sự |

---

## 📝 USE CASE CẦN BỔ SUNG (17 UC)

### Authentication (2 UC còn thiếu)
- [ ] UC003 - Quản lý hồ sơ cá nhân
- [ ] UC004 - Đổi mật khẩu

### Monitoring (2 UC còn thiếu)
- [ ] UC007 - Xem chi tiết chỉ số sức khỏe
- [ ] UC008 - Xem lịch sử chỉ số sức khỏe

### Emergency (2 UC còn thiếu)
- [ ] UC011 - Xác nhận an toàn (nếu tách riêng từ UC010)
- [ ] UC015 - Nhận và xử lý thông báo khẩn cấp (Actor: Người chăm sóc)

### Analysis (1 UC còn thiếu)
- [ ] UC017 - Xem báo cáo chi tiết đánh giá rủi ro

### Sleep Analysis (2 UC mới)
- [ ] UC020 - Phân tích giấc ngủ
- [ ] UC021 - Xem báo cáo giấc ngủ

### Admin (3 UC còn thiếu)
- [ ] UC024 - Cấu hình hệ thống
- [ ] UC025 - Quản lý thiết bị IoT
- [ ] UC026 - Xem nhật ký hệ thống

### Notification (2 UC mới)
- [ ] UC030 - Cấu hình Emergency Contacts
- [ ] UC031 - Quản lý thông báo

### Device (3 UC mới)
- [ ] UC040 - Kết nối thiết bị IoT
- [ ] UC041 - Cấu hình thiết bị
- [ ] UC042 - Xem trạng thái thiết bị

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
```

---

## 📊 THỐNG KÊ

| Metric | Số lượng |
|--------|----------|
| **Tổng UC đã hoàn thành** | 7 |
| **UC đã xóa** | 3 |
| **UC còn thiếu** | 17 |
| **Tổng UC dự kiến** | 24 |
| **Tiến độ** | 29% (7/24) |

---

## 🎯 ƯU TIÊN PHÁT TRIỂN

### Phase 1 - Core Features ⭐⭐⭐⭐⭐
- ✅ UC001 - Login
- ✅ UC002 - Register
- ✅ UC006 - View Health Metrics
- ✅ UC010 - Confirm After Fall Alert
- ✅ UC014 - Send Manual SOS

### Phase 2 - Advanced Features ⭐⭐⭐⭐
- ✅ UC016 - View Risk Report
- [ ] UC007 - Xem chi tiết chỉ số
- [ ] UC015 - Nhận SOS (Người chăm sóc)

### Phase 3 - Admin & Management ⭐⭐⭐
- ✅ UC022 - Manage Users
- [ ] UC024 - Cấu hình hệ thống
- [ ] UC030 - Cấu hình Emergency Contacts

### Phase 4 - Extended Features ⭐⭐
- [ ] UC020, UC021 - Sleep Analysis
- [ ] UC040-042 - Device Management

---

## 📝 CẢI TIẾN SO VỚI PHIÊN BẢN CŨ

### ✅ Đã thực hiện:

1. **Tái cấu trúc folder**: Tổ chức theo module (Authentication, Monitoring, Emergency, Analysis, Admin)
2. **Chuẩn hóa tên file**: Đổi từ tiếng Việt sang tiếng Anh (VD: `UC001_Dang_nhap.md` → `UC001_Login.md`)
3. **Loại bỏ UC không hợp lệ**: Xóa UC005, UC018, UC023
4. **Đơn giản hóa nội dung**: 
   - Giảm số bước trong luồng chính (VD: UC002 từ 16 bước → 7 bước)
   - Loại bỏ chi tiết technical (bcrypt, JWT, database query, JSON schema)
   - Tách rõ Business Rules và Technical Implementation
5. **Sửa Actor**: Loại bỏ "Hệ thống" và "Hệ thống AI" khỏi Actor list
6. **Cải thiện format**: Dùng bảng markdown chuẩn, đánh số flow đúng UML

### 🎯 Nguyên tắc mới:

- **Use Case** = User goal + User interaction (không phải system function)
- **Actor** = External entity (người hoặc hệ thống bên ngoài)
- **Luồng chính** ≤ 7-10 bước (ngắn gọn, dễ hiểu)
- **Technical details** → Chuyển sang Technical Specification
- **XAI** → Tích hợp vào UC liên quan, không tách riêng

---

**Người thực hiện refactor**: Senior BA & Software Engineer  
**Review by**: [Chưa review]  
**Approved by**: [Chờ phê duyệt]
