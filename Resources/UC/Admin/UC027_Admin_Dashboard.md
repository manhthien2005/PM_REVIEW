# UC027 - DASHBOARD TỔNG QUAN HỆ THỐNG

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                                                                                                                                               |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC027                                                                                                                                                                                                                                                                  |
| **Tên UC**         | Dashboard tổng quan hệ thống                                                                                                                                                                                                                                           |
| **Tác nhân chính** | Quản trị viên                                                                                                                                                                                                                                                          |
| **Mô tả**          | Quản trị viên xem tổng hợp các chỉ số KPI và trạng thái hoạt động toàn hệ thống, bao gồm: thống kê user, thiết bị, cảnh báo, sự cố, và xu hướng sức khỏe. Dashboard là điểm vào chính của Admin Web, cung cấp cái nhìn bird's-eye và cho phép drill-down vào chi tiết. |
| **Trigger**        | Quản trị viên đăng nhập thành công hoặc click "Dashboard" trên thanh điều hướng.                                                                                                                                                                                       |
| **Tiền điều kiện** | Admin đã đăng nhập với quyền ADMIN.                                                                                                                                                                                                                                    |
| **Hậu điều kiện**  | Admin xem được tổng hợp KPI real-time của toàn hệ thống.                                                                                                                                                                                                               |

---

## Luồng chính (Main Flow) — Xem Dashboard

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                                           |
| ---- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Admin           | Truy cập Dashboard (trang chính sau đăng nhập).                                                                                                                                                                                     |
| 2    | Hệ thống        | Truy vấn và hiển thị các **KPI Cards** tổng hợp:<br>- Tổng Users (Active/Locked)<br>- Tổng Devices (Online/Offline)<br>- Alerts hôm nay (count + severity)<br>- SOS events active (chưa resolved)<br>- Bệnh nhân risk HIGH/CRITICAL |
| 3    | Hệ thống        | Hiển thị **biểu đồ xu hướng** (7 ngày gần nhất):<br>- Số lượng alerts theo ngày (bar chart)<br>- Phân bố risk levels (pie chart)<br>- Devices online trend (line chart)                                                             |
| 4    | Hệ thống        | Hiển thị bảng **Sự cố gần đây** (5 sự cố mới nhất):<br>- Loại (Fall/SOS/Vital Alert), Bệnh nhân, Thời gian, Trạng thái                                                                                                              |
| 5    | Hệ thống        | Hiển thị bảng **Bệnh nhân cần chú ý** (top 5 risk cao nhất):<br>- Tên, Risk Score hiện tại, Risk Level, Lần đánh giá gần nhất                                                                                                       |
| 6    | Admin           | Xem tổng quan và quyết định hành động tiếp theo.                                                                                                                                                                                    |

---

## Luồng thay thế (Alternative Flows)

### 6.a — Drill-down vào chi tiết

| Bước  | Người thực hiện | Hành động                                                                |
| ----- | --------------- | ------------------------------------------------------------------------ |
| 6.a.1 | Admin           | Click vào một KPI Card hoặc một hàng trong bảng sự cố/bệnh nhân.         |
| 6.a.2 | Hệ thống        | Điều hướng đến trang chi tiết tương ứng (UC022/UC025/UC028/UC029/UC032). |

### 6.b — Thay đổi khoảng thời gian biểu đồ

| Bước  | Người thực hiện | Hành động                                                     |
| ----- | --------------- | ------------------------------------------------------------- |
| 6.b.1 | Admin           | Chọn khoảng thời gian: Hôm nay / 7 ngày / 30 ngày / Tùy chọn. |
| 6.b.2 | Hệ thống        | Tải lại dữ liệu biểu đồ theo khoảng thời gian mới.            |

### 6.c — Refresh dữ liệu thủ công

| Bước  | Người thực hiện | Hành động                                      |
| ----- | --------------- | ---------------------------------------------- |
| 6.c.1 | Admin           | Click nút "Refresh" hoặc biểu tượng reload.    |
| 6.c.2 | Hệ thống        | Truy vấn lại tất cả KPI và cập nhật Dashboard. |

---

## Business Rules

- **BR-027-01**: Dashboard auto-refresh mỗi 60 giây (configurable trong UC024).
- **BR-027-02**: KPI Cards sử dụng dữ liệu aggregated, KHÔNG query raw tables (`vitals`, `motion_data`).
- **BR-027-03**: "Sự cố gần đây" chỉ hiện sự cố trong 24h gần nhất, sắp xếp theo thời gian giảm dần.
- **BR-027-04**: "Bệnh nhân cần chú ý" chỉ hiện bệnh nhân có risk_level = HIGH hoặc CRITICAL.
- **BR-027-05**: Mọi lượt truy cập Dashboard được ghi vào `audit_logs` với action `admin.view_dashboard`.

---

## Yêu cầu phi chức năng

- **Performance**:
  - Dashboard load lần đầu < 2 giây.
  - KPI queries sử dụng Continuous Aggregates (`vitals_daily`, `vitals_hourly`).
  - Hỗ trợ caching KPI data (TTL 30 giây).
- **Security**:
  - Chỉ ADMIN role truy cập được.
  - Không hiển thị thông tin y tế chi tiết (chỉ thống kê tổng hợp).
- **Usability**:
  - Responsive layout cho màn hình desktop (1280px+).
  - Biểu đồ interactive (hover tooltip, click drill-down).
  - Color coding cho severity levels (Green/Yellow/Orange/Red).
