# 📐 UI Plan: Health Monitoring Screen (Refactoring & UX Polish)

## 0. Kết quả Assessment (Đánh giá UI/UX hiện tại)
Dựa trên phương pháp **Multi-agent Brainstorming**, dưới đây là những điểm chưa ổn và vi phạm chuẩn UI/UX cho người già / y tế, cùng với hướng khắc phục:

### 🔴 Lỗi Nghiêm Trọng (Critical - Accessibility)
1. **Kích thước chữ quá nhỏ (Font Size Violation)**:
   - Quy chuẩn của `mobile-agent` cho app y tế / theo dõi người già: Nhỏ nhất là **16sp (body)** và **14sp (caption)**.
   - Hiện trạng: `vital_card.dart` dùng size 13 (tiêu đề), size 10 (status)! `blood_pressure_card.dart` dùng size 14, size 11. Các thông số này cực kỳ khó đọc với người lớn tuổi.
   - *Plan*: Nâng toàn bộ base font size lên tối thiểu 14sp cho các nhãn phụ (caption) và 16sp cho các nhãn chính (body).

2. **Cấu trúc Grid tĩnh (Rigid Grid Layout)**:
   - Hiện trạng: `health_monitoring_screen.dart` dùng `GridView.count` với `childAspectRatio: 1.0`.
   - Vấn đề: Thao tác này sẽ **gây vỡ Layout (Overflow)** ngay lập tức khi user bật tính năng Text Scaling (phóng to chữ) trong cài đặt điện thoại, vì chiều cao bị giới hạn tĩnh theo chiều ngang.
   - *Plan*: Chuyển sang dùng `SliverGridDelegateWithMaxCrossAxisExtent` hoặc `mainAxisExtent` linh hoạt để block tự giãn theo nội dung, hoặc chuyển hoàn toàn sang UI dạng danh sách Card lớn hơn nếu màn hình nhỏ.

### 🟡 Lỗi Trunh Bình (Medium - Usability & Contrast)
1. **Tràn chữ số liệu (Overflow on extreme values)**:
   - Các chỉ số như Nhịp tim (VD: 120 BPM) hoặc Huyết áp (140/90) nếu font size được phóng to có thể tràn khỏi giới hạn viền.
   - *Plan*: Bổ sung `FittedBox` bọc quanh `AnimatedVitalValue` để auto-scale nhỏ lại nếu số quá to, đảm bảo không bao giờ bị overflow.

2. **Độ tương phản của Badge trạng thái (Contrast Ratio)**:
   - Hiện tại sử dụng màu nền với `alpha: 0.15` cho text. Độ tương phản thấp ở điều kiện ngoài trời.
   - *Plan*: Tăng alpha hoặc dùng màu solid cho các badge trạng thái (Bình thường / Cảnh báo / Nguy hiểm) để dể đọc hơn.

---

## 1. Description
- **SRS Ref**: Health Monitoring (Dashboard)
- **User Role**: User (Profile: Monitored Person / App User) 
- **Purpose**: Hiển thị bảng điều khiển các chỉ số sinh tồn của người đeo đồng hồ.
- **Goal của Plan**: Khắc phục các khiếm khuyết về Accessibility, tối ưu hóa kích thước touch target, hỗ trợ Text Scaling cho người cao tuổi.

## 2. User Flow
(User flow hiện tại đã ổn - giữ nguyên trạng loading, error, success, empty state. Chỉ tập trung vào UI/UX Refactoring ở Success State).

## 2. User Flow & Navigation (Kiến trúc Navigation mới)
Sau khi áp dụng Multi-agent Brainstorming, luồng trải nghiệm (UX) được cấu trúc lại như sau:

Quy tắc cốt lõi: **Tách biệt Micro-view (Cho người bệnh xem nhanh) và Macro-view (Cho Bác sĩ/Người nhà phân tích).**

### 2.1. Micro-view: Tính năng Card Drill-down (Chi tiết từng chỉ số)
- **Mục đích:** Để người dùng (đặc biệt là người lớn tuổi) phản xạ tự nhiên: "Thấy Tim -> Bấm vào để xem Tim". Tránh việc bị dội thông tin.
- **Action:** Click vào `VitalCard` (Nhịp tim, Nhiệt độ...) hoặc `BloodPressureCard`.
- **UI Màn hình Detail (Ví dụ: `VitalDetailScreen`):**
  1. **Nổi bật hiện tại:** Hiển thị con số đo gần nhất TO QUÁ KHỔ (ví dụ: 85 BPM) ngay giữa màn hình, kèm text trạng thái (Bình thường/Nguy hiểm).
  2. **Biểu đồ chuyên biệt (Mini chart):** 1 biểu đồ đường (Line graph) hiển thị biến động của DUY NHẤT chỉ số đó trong 24h qua. Dễ nhìn, không rối mắt.
  3. **Kiến thức y khoa (Education Text):** Một thẻ nhỏ giải thích: *"Nhịp tim bình thường của người già lúc nghỉ ngơi là từ 60-100 BPM..."* giúp người nhà yên tâm.
  4. **Nút Cấp cứu (Contextual SOS):** Nếu chỉ số đang ở mức `Critical` (Nguy hiểm), hiển thị ngay một nút to màu đỏ: "Gọi Bác Sĩ / Người Thân" ở dưới cùng.

### 2.2. Macro-view: Nút "Báo cáo & Nhật ký sức khoẻ" (Consolidated Report)
- **Mục đích:** Gộp 2 nút `History` và `Stats` (đang có sự trùng lặp) thành 1 nút duy nhất. Dành cho Bác sĩ hoặc Người giám sát muốn kiểm tra toàn diện.
- **Action:** Click vào nút (hoặc banner) "Báo cáo & Nhật ký" ở dưới cùng `HealthMonitoringScreen`.
- **UI Màn hình Report (`HealthReportScreen`):**
  - Màn hình này sử dụng **Tab Bar** hoặc **Toggle Switch** để chuyển đổi 2 chế độ:
  - **Chế độ 1: Timeline (Nhật ký sự kiện):** 
    - Hiển thị danh sách dọc theo thời gian (Chronological). 
    - Ví dụ: 
      - `[08:00 AM] Nhịp tim: 82 BPM, Huyết áp: 120/80` (Màu xanh)
      - `[10:30 AM] Nhịp tim: 110 BPM (Cảnh báo)` (Highlight màu cam)
      - `[11:00 AM] Mất kết nối cảm biến` (Text màu xám)
    - Giúp tracking bối cảnh và xem thiết bị có gặp lỗi không.
  - **Chế độ 2: Biểu đồ tương quan (Trends/Stats):**
    - Cho phép chọn thời gian (Hôm nay, 7 ngày qua, 1 tháng qua).
    - Biểu đồ đa biến (Multi-line chart) kết hợp lồng ghép Nhịp tim & Huyết áp trên cùng 1 đồ thị để bác sĩ tìm ra quy luật (Correlation).
    - Có phần thống kê trung bình: "Nhịp tim trung bình tuần: 78 BPM".

## 3. UI States Khắc Phục (Success State - Màn hình chính)
| Component | Thay đổi UI/UX |
|---|---|
| `VitalCard` | Nâng font tiêu đề lên 16sp. Status lên 14sp. Bọc giá trị bằng `FittedBox`. Tối ưu màu sắc để đạt chuẩn WCAG AA. Thêm `Ripple Effect` và truyền hàm `onTap` mở Navigation sang màn hình Detail. |
| `BloodPressureCard` | Nâng font nhãn phụ lên 14sp, tối ưu khoảng cách. Thay đổi layout text để support Text Scaling. Truyền hàm `onTap` sang màn hình Detail Huyết Áp. |
| `QuickActionsPanel` | (Bị Dọn Dẹp). Thay thế bằng 1 Component mới: `HealthReportBanner`. |
| **[MỚI]** `HealthReportBanner` | Một Card rộng (Width 100%), thiết kế nổi bật (có thể dùng gradient nhẹ hoặc icon Calendar/Chart), text to: *"Báo cáo & Nhật ký sức khoẻ"*. Min height 72dp để dễ bấm. |
| `HealthMonitoringScreen` | Cập nhật `GridView` bỏ `childAspectRatio: 1.0`, thay bằng `mainAxisExtent: 160` (hoặc tính năng tự co giãn). Thêm phần Navigation Routing. |

## 4. Widget Tree (Proposed Updates for Dashboard)
- `Scaffold`
  - `CustomScrollView`
    - `SliverAppBar` (Giữ nguyên)
    - `SliverPadding`
      - `SliverGrid` (Hiển thị 4 VitalCards - Auto-size height)
      - `SliverList`
        - `BloodPressureCard`
        - `SizedBox(height: 16)`
        - **`HealthReportBanner`** (Nút chức năng mới, thay thế QuickActions)

## 5. Edge Cases Handled (Bổ sung mới)
- [x] **Người già mắt kém bật phóng to chữ 150-200% trong OS**: Layout sẽ mở rộng theo chiều dọc thay vì vỡ màn hình nhờ bỏ fixed aspect ratio + dùng FittedBox.
- [x] **Ánh sáng mạnh (Ngoài trời)**: Thay đổi contrast của các tag cảnh báo trong VitalCard rõ ràng hơn.
- [x] **Số liệu bất thường cực lớn (ví dụ HR = 180)**: UI tự động scale font số nhỏ lại nhờ `FittedBox` chứ không báo lỗi vàng đen overflow.

## 6. Dependencies & Backend Validation
Việc chuyển đổi sang kiến trúc Navigation mới (Drilldown + Consolidated Report) ĐẢM BẢO KHẢ THI nhờ cấu trúc Database đã thiết kế ở backend (`04_create_tables_timeseries.sql` và `05_create_tables_events_alerts.sql`):
- **Micro-view (Drilldowns):** Có sẵn các Materialized Views của TimescaleDB như `vitals_5min` và `vitals_hourly` để vẽ biểu đồ chi tiết 1 chỉ số cực nhanh mà không query raw data.
- **Macro-view (Timeline Nhật ký):** Được hỗ trợ bởi bảng `alerts` (chứa các log như `vital_abnormal`, `device_offline`, `sos_triggered`) và `fall_events`, rất chuẩn xác để build Timeline.
- **Macro-view (Thống kê xu hướng):** Dùng `vitals_daily` (chứa sẵn `avg_hr`, `avg_bp_sys`...) để vẽ biểu đồ tương quan đa biến dài hạn (7-30 ngày).
- **Phụ thuộc Frontend:**
  - Cần tạo mới / update: `vital_detail_screen.dart` (Micro-view), `health_report_screen.dart` (Macro-view).
  - Có thể cần thư viện vẽ biểu đồ (`fl_chart` hoặc tương tự) cho đồ thị. Không thêm package nếu không thực sự cần.
