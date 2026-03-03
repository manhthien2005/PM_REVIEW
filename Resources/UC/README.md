# 📘 USE CASE SPECIFICATION - HEALTHGUARD SYSTEM

> **Hệ thống**: HealthGuard - Giám sát và cảnh báo sức khỏe qua thiết bị IoT  
> **Phiên bản**: 2.0 (Refactored)  
> **Ngày cập nhật**: 05/02/2026

---

## 🗂️ CẤU TRÚC THƯ MỤC

```
UC/
├── 00_DANH_SACH_USE_CASE.md     # Danh sách tổng hợp tất cả UC
├── README.md                     # File hướng dẫn này
│
├── Authentication/               # UC về xác thực
│   ├── UC001_Login.md           ✅
│   └── UC002_Register.md        ✅
│
├── Monitoring/                   # UC về giám sát sức khỏe
│   └── UC006_View_Health_Metrics.md  ✅
│
├── Emergency/                    # UC về khẩn cấp
│   ├── UC010_Confirm_After_Fall_Alert.md  ✅
│   └── UC014_Send_Manual_SOS.md           ✅
│
├── Analysis/                     # UC về phân tích
│   └── UC016_View_Risk_Report.md  ✅
│
└── Admin/                        # UC về quản trị
    └── UC022_Manage_Users.md    ✅
```

---

## 📊 TÌNH TRẠNG

| Tổng UC | Đã hoàn thành | Còn thiếu | Đã xóa | Tiến độ |
|---------|--------------|-----------|--------|---------|
| 24 | 7 | 17 | 3 | 29% |

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
|------|----------------|-----------|
| 1 | Actor | ... |
| 2 | System | ... |

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

| UC | Tên | Độ ưu tiên | Trạng thái |
|----|-----|-----------|-----------|
| **UC001** | Login | ⭐⭐⭐⭐⭐ | ✅ Done |
| **UC002** | Register | ⭐⭐⭐⭐⭐ | ✅ Done |
| **UC006** | View Health Metrics | ⭐⭐⭐⭐⭐ | ✅ Done |
| **UC010** | Confirm After Fall Alert | ⭐⭐⭐⭐⭐ | ✅ Done |
| **UC014** | Send Manual SOS | ⭐⭐⭐⭐⭐ | ✅ Done |
| **UC016** | View Risk Report | ⭐⭐⭐⭐ | ✅ Done |
| **UC022** | Manage Users | ⭐⭐⭐ | ✅ Done |

---

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
└─────────────┘       └──────┬──────┘
                             │
                             │ [không phản hồi]
                             ▼
                      ┌─────────────┐
                      │   UC014     │
                      │  Send SOS   │
                      └─────────────┘
```

### Include relationships:
- UC006 **includes** UC007 (Xem chi tiết - chưa viết)
- UC016 **includes** UC017 (Xem báo cáo chi tiết - chưa viết)

### Extend relationships:
- UC010 **extends to** UC014 (nếu không phản hồi → gửi SOS)

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
- Chi tiết technical (API, database, JSON schema) → Xem `Technical_Specification/`
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
- ❌ Database schema, SQL query
- ❌ JSON payload, API endpoint
- ❌ Chi tiết thuật toán AI
- ❌ Implementation chi tiết (bcrypt, JWT, ...)

→ **Chuyển sang**: `Technical_Specification/`

---

## 📋 SO SÁNH VỚI TÀI LIỆU SRS

| Phần SRS | Use Cases tương ứng |
|----------|-------------------|
| **HG-FUNC-01, 02, 03** (Giám sát chỉ số) | UC006 - View Health Metrics |
| **HG-FUNC-04, 05, 06, 07** (Té ngã & SOS) | UC010, UC014 |
| **HG-FUNC-08, 09** (Rủi ro & XAI) | UC016 - View Risk Report |
| **Quản trị** | UC022 - Manage Users |

---

## 🔧 REFACTOR ĐÃ THỰC HIỆN

### Thay đổi cấu trúc:
✅ Tái tổ chức folder theo module  
✅ Đổi tên file sang tiếng Anh  
✅ Xóa UC không hợp lệ (UC005, UC018, UC023)

### Cải thiện nội dung:
✅ Giảm số bước luồng chính (trung bình từ 12 → 7 bước)  
✅ Loại bỏ chi tiết technical  
✅ Tách rõ Business Rules  
✅ Chuẩn hóa format bảng markdown  
✅ Sửa Actor (loại bỏ "Hệ thống" làm actor)

### Tích hợp XAI:
✅ Gộp UC018 (XAI) vào UC010 và UC016  
✅ Giải thích AI hiển thị ngay trong UC liên quan

---

## 📞 LIÊN HỆ & TÀI LIỆU THAM KHẢO

### Tài liệu liên quan:
- **SRS**: `BA/SOFTWARE REQUIREMENTS SPECIFICATION (SRS) v1.0 (1).md`
- **Technical Spec**: `BA/Technical_Specification/`
  - Data_Pipeline.md
  - AI_Models.md
  - API_Design.md

### Use Case Diagram:
- Xem file: `BA/Diagrams/UseCase_Diagram.puml` (nếu có)

---

**Cập nhật lần cuối**: 05/02/2026  
**Version**: 2.0  
**Status**: ✅ Refactor completed  
**Next**: Viết thêm 17 UC còn thiếu
