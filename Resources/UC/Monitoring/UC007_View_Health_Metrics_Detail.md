# UC007 - XEM CHI TIẾT CHỈ SỐ SỨC KHỎE (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Main Flow step 5 range list sang 24h/7d/30d (match `_VITALS_TIMESERIES_RANGES` preset). Drop Alt 5.a "> 1 năm" + BR-007-03 "max 1 năm" vì code không expose custom range picker (3 preset max 30d). Drop Alt 6.a export CSV/PDF (D-MON-01, admin web đã có). Add BR-007-05 stats min/max/avg status chưa implement (Phase 5+).

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC007 |
| **Tên UC** | Xem chi tiết chỉ số sức khỏe |
| **Tác nhân chính** | User |
| **Mô tả** | Người dùng xem chi tiết một chỉ số sức khỏe (HR / SpO2 / BP / Temp / RR) với biểu đồ trend + safe range bar + education card. |
| **Trigger** | Chọn 1 chỉ số trên UC006 hoặc truy cập `VitalDetailScreen` qua routing. |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Thiết bị đã pair + có dữ liệu (trong 24h gần nhất mặc định). |
| **Hậu điều kiện** | Người dùng xem được value hiện tại + 24h trend + safe range bar + education text. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Từ UC006, tap vào 1 chỉ số (VD "Nhịp tim") hoặc mở trực tiếp Vital Detail Screen. |
| 2 | Hệ thống | Open `VitalDetailScreen` với `vitalType` param (hr/spo2/bp/temp/rr). Default range 24h. |
| 3 | Client | `VitalSignsProvider.startPolling()`: polling 5s cho latest vital + fetch timeseries 24h (idempotent, không re-fetch trên mỗi tick). |
| 4 | Hệ thống | Hiển thị:<br>- Hero card: value 84sp + status pill (BR-006-01 color)<br>- Safe range bar (5 zones, `VitalSafeRangeBar`)<br>- Line chart 24h (`MiniLineChart` từ `timeseries.data`)<br>- Education card (`VitalEducationCard` per vital type) |
| 5 | Người dùng | (Phase 4, D-MON-03) Thay đổi range: 24h / 7d / 30d. |
| 6 | Client | Gọi `/metrics/vitals/timeseries?range=<key>` với range mới. Update chart. |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Không có dữ liệu trong 24h

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Hệ thống (BE) | `/timeseries` trả `data: []` (defensive, không 500 nếu vitals hypertable empty). |
| 3.a.2 | Client | `VitalSignsProvider.chartData = []` thì render `EmptyChartPlaceholder("Chưa có dữ liệu xu hướng")`. |
| 3.a.3 | Client | Nếu latest vital cũng empty thì hero card hiển thị "--" + status unknown. |

### 4.a - Vital stale (>5 phút không ingest)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 4.a.1 | Hệ thống (BE) | `VITALS_STALE_AFTER` check. `VitalSignsResponse.is_stale = TRUE`. |
| 4.a.2 | Client | `_buildVitalValueCard` render stale banner "Thiết bị mất kết nối" (F-8 M-9 fix). |
| 4.a.3 | Client | Force `extractStatus = VitalStatus.unknown` để không mis-classify stale reading thành critical/normal. |

### 5.a - Critical status hiện SOS button

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Client | `vitalStatus == VitalStatus.critical` thì render `_buildCriticalAction` SOS CTA. |
| 5.a.2 | Người dùng | Tap SOS thì cascade sang UC030 SOS trigger flow. |

---

## Business Rules

- **BR-007-01:** Mặc định hiển thị 24 giờ gần nhất khi mở Vital Detail Screen. Match code `VitalSignsProvider.loadTimeseries(range: '24h')` default.
- **BR-007-02:** Sử dụng continuous aggregates TimescaleDB:
  - 24h range: `time_bucket('15 minutes')` runtime query trên `vitals` (chưa dùng CA riêng, raw query downsample inline, OK cho 24h window).
  - 7d range: `time_bucket('60 minutes')`.
  - 30d range: `time_bucket('360 minutes')` (6h).
  - Phase 5+ consider switch sang CA `vitals_5min` / `vitals_hourly` / `vitals_daily` nếu load cao.
- **BR-007-03 (DROPPED v2):** UC cũ nói "max 1 năm". Drop, code không expose custom range picker, chỉ có 3 preset max 30d. Nếu Phase 5+ add custom range, revisit.
- **BR-007-04:** Tôn trọng quyền truy cập caregiver. Enforce ở `get_target_profile_id` (tested in `test_monitoring_routes_http.py::test_caregiver_cannot_access_unauthorized_profile`).
- **BR-007-05 (stats min/max/avg, UC cũ step 4 Main Flow):** Phase 5+ scope. Code hiện không tính min/max/avg cho từng chỉ số trong detail screen. FE chỉ render line chart + current value + safe range bar. UC007 v2 drop step "Giá trị min/max/avg" khỏi Main Flow step 4.

## Business Rules - Phân quyền

- **BR-Auth-01:** User A chỉ xem dữ liệu User B nếu `can_view_vitals = TRUE`.

## Yêu cầu phi chức năng

- **Performance**:
  - Thời gian tải chart 24h < 1 giây (96 bucket, payload <10 KB).
  - Thời gian tải chart 30d < 2 giây (120 bucket).
  - Polling 5s KHÔNG re-fetch timeseries (idempotent) để không overload BE.
- **Usability**:
  - Safe range bar 5-zone màu sắc dễ hiểu cho người lớn tuổi.
  - Education card collapsible text giải thích y khoa tiếng Việt.
  - Touch target >=48dp (medical app accessibility).
  - Pinch-to-zoom chart là Phase 5+ (chart hiện chỉ hiển thị fixed range).
- **Security**: API JWT auth + BR-Auth-01 enforce.

---

## Dropped features (UC cũ drop trong v2)

- Alt 5.a "khoảng thời gian quá dài > 1 năm": Drop vì preset range max 30d, không cần validation edge case này.
- Alt 6.a "Xuất CSV/PDF": Drop (D-MON-01). Admin web HealthGuard đã có export CSV. Mobile = view-only.
- Main Flow step 4 "min/max/avg stats panel": Drop (xem BR-007-05). Phase 5+ scope.
- Main Flow step 4 "Số lần vượt ngưỡng cảnh báo": Drop. Phase 5+ scope.

---

## Implementation references

- Route BE: `health_system/backend/app/api/routes/monitoring.py` — `get_vitals_timeseries`
- Service BE: `health_system/backend/app/services/monitoring_service.py` — `get_vitals_timeseries`, `_VITALS_TIMESERIES_RANGES`
- FE screen: `health_system/lib/features/health_monitoring/screens/vital_detail_screen.dart`
- FE widgets: `VitalSafeRangeBar`, `MiniLineChart`, `VitalEducationCard`, `EmptyChartPlaceholder`
- FE provider: `health_system/lib/features/health_monitoring/providers/vital_signs_provider.dart`
- FE repo: `health_system/lib/features/health_monitoring/repositories/monitoring_repository.dart` — `getVitalsTimeseries(range: '24h')`
- Related UCs: UC006 (entry point), UC008 (longer history), UC030 (SOS trigger from critical)
