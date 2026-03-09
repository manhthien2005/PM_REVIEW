# BÁO CÁO CẬP NHẬT DATABASE HỖ TRỢ UC024 (CẤU HÌNH HỆ THỐNG)

**Ngày cập nhật:** 09/03/2026
**Mô-đun:** Admin / System Configuration
**Issue / Trigger:** Đáp ứng yêu cầu mở rộng quyền lực kiểm soát thực tế cho Admin trong UC024.

---

## 1. Vấn Đề Hiện Tại Của Cơ Sở Dữ Liệu Cũ
Trước đó, hệ thống (theo như file `README.md` của DB và thiết kế các bảng `01` đến `12`) chưa có bất kỳ nơi nào để lưu trữ **Global System Settings** (cấu hình toàn cục).
- Bảng `devices` chỉ lưu tham số riêng lẻ cho từng thiết bị (`calibration_data`).
- Bảng `07_create_tables_system.sql` chỉ thuần tuý lưu Audit Logs và Metrics hiệu suất.

Việc thiếu vắng thiết kế này khiến UC024 ("Cấu hình hệ thống") không có Backend Database hỗ trợ phía sau. Các ý tưởng về thay đổi AI, giới hạn SMS hay cấu hình Sinh tồn mặc định không thể thực thi.

## 2. Giải Pháp: Bổ Sung Bảng Mới `system_settings`
Để giải quyết triệt để rào cản này và bám sát tiêu chí **"Thực Tế & Hiệu Quả"** cho sản phẩm, file script SQL thứ 13 đã được bổ sung:
👉 **File:** `13_create_system_settings.sql`

### 2.1 Cấu Trúc Bảng Linh Hoạt Với JSONB
```sql
CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_group VARCHAR(50) NOT NULL, 
    setting_value JSONB NOT NULL,
    description TEXT,
    is_editable BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by INT REFERENCES users(id) ON DELETE SET NULL    
);
```

- **Lợi ích thực tế:** Sử dụng `setting_value` với kiểu dữ liệu `JSONB` là "chìa khoá vàng". Admin có thể nhóm nhiều tham số liên quan vào cùng một file JSON. Khi sản phẩm cần mở rộng 5-10 cấu hình mới trong tương lai, Developer **không bao giờ phải chạy lệnh `ALTER TABLE`** để rạch thêm cột. 

### 2.2 Các Tham Số (Configurations) Mặc Định Được Bơm Sẵn
Script SQL đi kèm cụm lệnh `INSERT` để khởi tạo sẵn 4 quyền lực thực dụng nhất cho nhà quản trị:

| Setting Key                 | Group          | Ứng Dụng Thực Tế                                                                                                                                                                              | Value (JSON)                                                   |
| :-------------------------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------- |
| `fall_detection_ai`         | ai_model       | **Chống False Alarm:** Nắm quyền quyết định ngưỡng tin cậy của AI. Nếu model báo sai nhiều, Admin tăng `confidence_threshold`. Kiểm soát đếm ngược SOS.                                       | `{"confidence_threshold": 0.85, "auto_sos_countdown_sec": 30}` |
| `notification_gateways`     | infrastructure | **Kiểm soát & Ngắt Cước Phí:** SMS API (như Twilio) tốn tiền mặt. Admin có quyền ngắt (Kill-switch) kênh SMS, Call hoặc đặt giới hạn X tin/ngày/user để tránh lặp lặp spam bào mòn ngân sách. | `{"sms_enabled": true, "max_sms_per_user_daily": 5, ...}`      |
| `vitals_default_thresholds` | clinical       | **An Toàn Bệnh Nhân:** Áp dụng ngưỡng mặc định SpO2 và Nhịp Tim nếu bác sĩ quên thiết lập.                                                                                                    | `{"spo2_min": 92, "hr_min": 50, "hr_max": 120}`                |
| `system_security`           | security       | **Deploy / Maintenance:** Chốt chặn không cho user đăng nhập hoặc thao tác khi Server cần bảo trì nâng cấp, ngoại trừ Admin.                                                                  | `{"maintenance_mode": false, "session_timeout_minutes": 60}`   |

## 3. Tác Động Giao Thoa Giữa DB Mới và UC024

Sự xuất hiện của bảng `system_settings` đã đem lại linh hồn cho Use Case **UC024**. Toàn bộ tài liệu UC024 được viết lại tập trung xoay quanh 4 luồng dữ liệu trên.

**Các bổ sung Non-Functional đi kèm:**
- Luồng `Audit Logs` (BR-024-02): Mọi thao tác đổi settings từ web admin do user click lưu đều trigger việc ghi dấu (Bảng `audit_logs`).
- Luồng `Cache Invalidation` (BR-024-03): Các worker xử lý cảnh báo (gửi SMS, gọi AI) trước kia tải file `.env` tĩnh, bây giờ sẽ fetch DB `system_settings` định kỳ hoặc qua sự kiện Redis Invalidation khi Admin bấm Save.

---
**Kết Luận:** Nâng cấp SQL mang tính "Future-Proof" (Hướng tương lai). 4 nhóm settings là đủ và dư sức bao phủ mọi thao tác sinh sát (Kill-switch) của Admin đối với hệ thống Backend.
