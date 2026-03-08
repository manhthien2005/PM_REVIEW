# UC028 - GIÁM SÁT SỨC KHỎE & ĐÁNH GIÁ RỦI RO (ADMIN)

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                                                                                                                            |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC028                                                                                                                                                                                                                                                                                                                               |
| **Tên UC**         | Giám sát sức khỏe & đánh giá rủi ro                                                                                                                                                                                                                                                                                                 |
| **Tác nhân chính** | Quản trị viên                                                                                                                                                                                                                                                                                                                       |
| **Mô tả**          | Quản trị viên giám sát tổng quan dữ liệu sức khỏe và kết quả đánh giá rủi ro (Risk Scores) toàn bộ bệnh nhân: cảnh báo ngưỡng vitals, phân bố risk levels, bệnh nhân bất thường, và xu hướng hệ thống. **Lưu ý**: UC này dành cho Admin giám sát ở tầm hệ thống; việc user xem vitals/risk cá nhân xem tại UC006/UC007/UC016/UC017. |
| **Trigger**        | Admin truy cập mục "Giám sát sức khỏe" trên Admin Dashboard.                                                                                                                                                                                                                                                                        |
| **Tiền điều kiện** | Admin đã đăng nhập với quyền ADMIN.                                                                                                                                                                                                                                                                                                 |
| **Hậu điều kiện**  | Admin nắm được tình hình sức khỏe và mức rủi ro tổng thể của tất cả bệnh nhân.                                                                                                                                                                                                                                                      |

---

## Luồng chính (Main Flow) — Xem tổng quan sức khỏe & risk

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                                 |
| ---- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập "Giám sát sức khỏe".                                                                                                                                                                                             |
| 2    | Hệ thống        | Hiển thị **Summary Cards**:<br>- Tổng bệnh nhân đang được giám sát<br>- Bệnh nhân có vitals bất thường (vi phạm ngưỡng)<br>- Bệnh nhân Risk HIGH/CRITICAL<br>- Cảnh báo vitals hôm nay                                    |
| 3    | Hệ thống        | Hiển thị **Tab 1 — Cảnh báo Ngưỡng** (bảng, 24h gần nhất):<br>- Bệnh nhân, Chỉ số vi phạm (HR/SpO₂/BP/Temp), Giá trị, Ngưỡng, Thời gian, Mức độ                                                                           |
| 4    | Hệ thống        | Hiển thị **Tab 2 — Phân bố Risk** (biểu đồ + bảng):<br>- Donut chart: LOW / MEDIUM / HIGH / CRITICAL (count + %)<br>- Bảng bệnh nhân Risk Cao (HIGH + CRITICAL, sắp xếp giảm dần)<br>- Xu hướng risk 30 ngày (line chart) |
| 5    | Hệ thống        | Hiển thị biểu đồ **Xu hướng vitals** toàn hệ thống:<br>- SpO₂ trung bình (daily trend)<br>- HR trung bình (daily trend)<br>- Số lượng vi phạm ngưỡng theo ngày                                                            |
| 6    | Admin           | Xem tổng quan và lọc/tìm kiếm theo nhu cầu.                                                                                                                                                                               |

---

## Luồng thay thế (Alternative Flows)

### 6.a — Xem chi tiết sức khỏe một bệnh nhân

| Bước  | Người thực hiện | Hành động                                                                                                                                                                                                                                                                                                        |
| ----- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6.a.1 | Admin           | Click vào một bệnh nhân trong bảng cảnh báo hoặc bảng risk cao.                                                                                                                                                                                                                                                  |
| 6.a.2 | Hệ thống        | Hiển thị trang chi tiết sức khỏe bệnh nhân:<br>- **Vitals hiện tại**: HR, SpO₂, BP, Temp<br>- **Risk Score**: Giá trị, Level, Thời điểm đánh giá<br>- **Biểu đồ 24h** (từ `vitals_5min`)<br>- **Biểu đồ 7 ngày** (từ `vitals_daily`)<br>- **Risk trend 30 ngày** của bệnh nhân<br>- **Lịch sử cảnh báo** gần đây |
| 6.a.3 | Admin           | Xem chi tiết và quyết định hành động (liên hệ caregiver, khóa tài khoản, v.v.).                                                                                                                                                                                                                                  |

### 6.b — Lọc theo chỉ số bất thường

| Bước  | Người thực hiện | Hành động                                                                                                                       |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 6.b.1 | Admin           | Chọn bộ lọc: Loại chỉ số (HR/SpO₂/BP/Temp), Mức độ (Warning/Critical), Khoảng thời gian, Risk Level (LOW/MEDIUM/HIGH/CRITICAL). |
| 6.b.2 | Hệ thống        | Lọc lại bảng cảnh báo và biểu đồ theo điều kiện đã chọn.                                                                        |

### 6.c — Xuất danh sách cảnh báo

| Bước  | Người thực hiện | Hành động                                                          |
| ----- | --------------- | ------------------------------------------------------------------ |
| 6.c.1 | Admin           | Click "Xuất CSV" trên bảng cảnh báo hoặc bảng risk.                |
| 6.c.2 | Hệ thống        | Tạo file CSV chứa dữ liệu theo bộ lọc hiện tại và cho phép tải về. |

---

## Business Rules

- **BR-028-01**: Dữ liệu vitals tổng quan **BẮT BUỘC** lấy từ Continuous Aggregates (`vitals_5min`, `vitals_hourly`, `vitals_daily`), KHÔNG ĐƯỢC query trực tiếp bảng `vitals`.
- **BR-028-02**: Ngưỡng cảnh báo sử dụng giá trị từ cấu hình hệ thống (UC024): SpO₂ < 92%, HR > 100 hoặc < 60, BP > 140 hoặc < 90, Temp > 37.8°C.
- **BR-028-03**: Admin chỉ xem dữ liệu tổng hợp và thống kê, KHÔNG can thiệp vào dữ liệu y tế (read-only).
- **BR-028-04**: Mọi lượt xem chi tiết sức khỏe bệnh nhân phải ghi vào `audit_logs` với action `admin.view_patient_health`.
- **BR-028-05**: Bệnh nhân "offline" được xác định khi device `last_seen_at` > 60 phút so với hiện tại.
- **BR-028-06**: Risk score lấy từ bảng `risk_scores`. Phân loại theo SRS: LOW (0-33), MEDIUM (34-66), HIGH (67-84), CRITICAL (85-100).
- **BR-028-07**: "Xu hướng" risk (↑↓→) tính bằng so sánh score lần đánh giá gần nhất với lần trước đó.

---

## Yêu cầu phi chức năng

- **Performance**:
  - Bảng cảnh báo load < 2 giây với phân trang (20 items/page).
  - Biểu đồ xu hướng sử dụng `vitals_daily` aggregate, load < 1 giây.
- **Security**:
  - Chỉ ADMIN role truy cập.
  - Dữ liệu y tế chi tiết chỉ hiển thị khi Admin drill-down vào bệnh nhân cụ thể, có ghi audit log.
- **Usability**:
  - Color coding nhất quán: Xanh lá (LOW/Normal), Vàng (MEDIUM/Warning), Cam (HIGH), Đỏ (CRITICAL).
  - Biểu đồ interactive với tooltip khi hover.
  - Hỗ trợ search nhanh bệnh nhân theo tên/email.
  - Tab navigation giữa Cảnh báo Ngưỡng và Phân bố Risk.
