# UC008 - XEM LỊCH SỬ CHỈ SỐ SỨC KHỎE (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Minor update từ v1 "no change". Drop Alt 6.a "custom from/to" (code không expose custom range picker). BR-008-04 retention explicit 1 năm theo `09_create_policies.sql`. BR-008-05 note scope UC008 trong code hiện tại chỉ map với `/analysis/risk-history` (risk trend) hơn là raw vitals trend, clarify scope boundary UC007 vs UC008.

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC008 |
| **Tên UC** | Xem lịch sử chỉ số sức khỏe |
| **Tác nhân chính** | User |
| **Mô tả** | Người dùng xem lại xu hướng tổng hợp + lịch sử risk scores qua các ngày/tuần/tháng để phát hiện pattern dài hạn. Phân biệt với UC007: UC007 drill-down chi tiết 1 chỉ số trong 24h/7d/30d (vitals_timeseries), UC008 focus dài hạn risk + sleep history. |
| **Trigger** | Người dùng mở tab "Lịch sử" / "Phân tích rủi ro" / Sleep History. |
| **Tiền điều kiện** | Ít nhất 1 ngày dữ liệu risk_scores hoặc sleep_sessions đã tồn tại. |
| **Hậu điều kiện** | User xem được biểu đồ xu hướng + thống kê theo khoảng thời gian đã chọn. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập màn "Lịch sử sức khỏe" (risk + sleep). |
| 2 | Hệ thống | Hiển thị bộ lọc preset range: 7d / 30d / 90d (`RISK_HISTORY_RANGE_DAYS`). Optional filter `risk_type`: all / general / sleep / fall (Phase 4A-full slice 3b). |
| 3 | Người dùng | Chọn range + risk_type. |
| 4 | Client | Gọi `/analysis/risk-history?range=<key>&page=1&limit=20[&risk_type=<type>]`. |
| 5 | Hệ thống | BE query `risk_scores` với filter + pagination. Build summary (avg/highest/lowest/delta) + items list. |
| 6 | Client | Render:<br>- Summary stats card<br>- Line/bar chart risk trend<br>- List chi tiết (risk_score, risk_level, display_status, reason_preview, analyzed_at)<br>- Pagination "Xem thêm" |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Chưa đủ dữ liệu (<24h usage)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống (BE) | `/risk-history` trả `items: []` + `summary` với average=0/highest=0/lowest=0. |
| 2.a.2 | Client | Render "Chưa đủ dữ liệu lịch sử. Vui lòng sử dụng thiết bị ít nhất 24 giờ." |

### 5.a - Tap 1 risk report trên timeline

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người dùng | Tap 1 item trong history list (VD risk report ngày hôm qua). |
| 5.a.2 | Client | Gọi `/analysis/risk-reports/{id}` (UC028 detail view). |
| 5.a.3 | Hệ thống | Render detail screen với SHAP breakdown + AI explanation + recommendations (cross-UC sang UC028). |

---

## Business Rules

- **BR-008-01:** Mặc định range `7d` (match `get_risk_history` default `range_key="7d"`).
- **BR-008-02:** Preset range cố định: 7d / 30d / 90d.
  - `RISK_HISTORY_RANGE_DAYS = {"7d": 7, "30d": 30, "90d": 90}` (code canonical).
  - Khác UC cũ nói "7 ngày, 30 ngày, 3 tháng, tùy chọn from/to": Drop custom from/to (xem Alt 6.a DROPPED). 3 tháng = 90 ngày match.
- **BR-008-03 (DROPPED v2 Alt 6.a):** UC cũ có Alt 6.a "Lọc khoảng thời gian custom (ngày bắt đầu/kết thúc)". Drop vì:
  - `get_risk_history` chỉ accept 3 preset range, không parse `from_date`/`to_date`.
  - Scope mobile view-only, custom range là Phase 5+.
- **BR-008-04 (retention):** Data retention theo `09_create_policies.sql`:
  - `vitals`: 1 năm (compression after 7 days).
  - `motion_data`: 3 tháng.
  - `risk_scores`: keep long-term (không retention policy hiện tại).
  - `audit_logs`: 2 năm.
  - Query range >1 năm trả data có thể bị truncated/empty.
- **BR-008-05 (scope clarification v2):** UC008 trong code hiện map với `/analysis/risk-history` (risk scores timeline). Không có endpoint riêng cho "vitals aggregated history" kiểu daily average heart rate, đó là cascade UC007 (dùng `/metrics/vitals/timeseries?range=30d` với bucket 6h). Sleep history map với `/metrics/sleep/history` (UC021). UC008 v2 chủ yếu focus risk trend + sleep history dashboard.

## Business Rules - Phân quyền

- **BR-Auth-01:** Caregiver chỉ xem lịch sử của patient nếu `can_view_vitals = TRUE` trong `user_relationships`.

## Yêu cầu phi chức năng

- **Performance**:
  - Load `/risk-history` 30d < 3 giây với pagination 20 items.
  - Summary stats precomputed trong query.
- **Usability**:
  - Chart dùng màu sắc consistent với UC006 (low=xanh, medium=vàng, high=cam, critical=đỏ).
  - Hỗ trợ xoay ngang (landscape) cho chart full-width.
- **Security**: BE auth + BR-Auth-01 enforce.

---

## Dropped features (UC cũ drop trong v2)

- Alt 6.a "Lọc khoảng tùy chỉnh from/to": Drop. Code chỉ có 3 preset. Phase 5+ nếu có demand.
- Main Flow step 2 "tùy chọn from/to": Drop cùng Alt 6.a.

---

## Implementation references

- Route BE: `health_system/backend/app/api/routes/monitoring.py` — `get_risk_history`
- Service BE: `health_system/backend/app/services/monitoring_service.py` — `get_risk_history`, `RISK_HISTORY_RANGE_DAYS`
- FE screen: `health_system/lib/features/analysis/screens/risk_history_screen.dart` (nếu đã có trong AUDIT_2026 module inventory, Phase 0.5 cross-ref)
- DB retention: `PM_REVIEW/SQL SCRIPTS/09_create_policies.sql`
- Related UCs: UC006 (live view), UC007 (short-range drill-down), UC021 (sleep history companion), UC028 (risk report detail)
