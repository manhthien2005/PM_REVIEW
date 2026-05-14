# UC006 - XEM CHỈ SỐ SỨC KHỎE (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Step 3 "1 giờ" sang "24 giờ" (match code `VitalSignsProvider` render 24h trend chart). Alt 5.b liệt kê 24h/7d/30d (drop 1h/6h không có trong `_VITALS_TIMESERIES_RANGES`). NFR "chu kỳ 1 phút" sang "1 giây" (match vitals hypertable spec + IoT sim tick). BR-006-01 note FE thresholds source hardcode trong `vital_signs.dart` model, Phase 5+ centralize qua SettingsService.

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC006 |
| **Tên UC** | Xem chỉ số sức khỏe theo thời gian thực |
| **Tác nhân chính** | User (bệnh nhân, người chăm sóc) |
| **Mô tả** | Người dùng xem các chỉ số sức khỏe hiện tại (HR, SpO2, BP, Temp, RR) và nhận cảnh báo khi có bất thường. |
| **Trigger** | Người dùng mở app hoặc truy cập Dashboard hoặc Vital Detail Screen. |
| **Tiền điều kiện** | - Người dùng đã đăng nhập.<br>- Thiết bị IoT đã pair (UC040) và đang gửi vitals ingest. |
| **Hậu điều kiện** | Người dùng nhìn thấy trạng thái sức khỏe hiện tại + lịch sử 24h. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Truy cập màn hình "Sức khỏe" hoặc Vital Detail Screen. |
| 2 | Hệ thống | Hiển thị các chỉ số hiện tại:<br>- Nhịp tim (BPM)<br>- SpO₂ (%)<br>- Huyết áp (mmHg)<br>- Nhiệt độ (°C)<br>- Nhịp thở (lần/phút)<br>Với màu sắc: Xanh (OK), Vàng (Cảnh báo), Đỏ (Nguy hiểm) — thresholds ở BR-006-01. |
| 3 | Hệ thống | Hiển thị biểu đồ xu hướng 24 giờ gần nhất (bucket 15 phút, ~96 điểm, endpoint `/metrics/vitals/timeseries?range=24h`). |
| 4 | Hệ thống | Polling 5s (FE `VitalSignsProvider`) gọi `/metrics/vital-signs/latest`. Cập nhật giá trị + status pill. |
| 5 | Hệ thống | Nếu backend set `is_stale = TRUE` (>5 phút không nhận ingest), FE render "Thiết bị mất kết nối" + value "--" + status "Không rõ". Xem NFR stale handling. |
| 6 | Hệ thống | Gửi push notification nếu phát hiện chỉ số bất thường, xem UC008 Alert Thresholds + `risk_alert_service`. |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Thiết bị offline / stale (>5 phút không ingest)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống (BE) | `VITALS_STALE_AFTER = timedelta(minutes=5)`. Nếu `now - latest.time > 5 phút` thì response `is_stale=TRUE`. |
| 2.a.2 | Client | `VitalSignsProvider.isStale = TRUE` thì value "--", status `VitalStatus.unknown`. Banner "Thiết bị mất kết nối". |
| 2.a.3 | Hệ thống | Hiển thị dữ liệu cuối cùng với timestamp để user biết sample cuối khi nào. |

### 5.a - Xem chi tiết chỉ số

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.a.1 | Người dùng | Tap vào tile chỉ số hoặc mở Vital Detail Screen cho 1 vital (hr/spo2/bp/temp/rr). |
| 5.a.2 | Hệ thống | Mở `VitalDetailScreen` (UC007). Cascade flow sang UC007. |

### 5.b - Thay đổi khoảng thời gian biểu đồ

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 5.b.1 | Người dùng | Chọn khoảng: 24h / 7d / 30d (Phase 4 wire range tabs, D-MON-03). |
| 5.b.2 | Client | Gọi lại `/metrics/vitals/timeseries?range=<key>`. BE trả 96/168/120 bucket tương ứng. |

Note: UC cũ liệt kê "1h, 6h, 24h, 7 ngày". 1h/6h bị drop vì `_VITALS_TIMESERIES_RANGES` chỉ có 3 preset. Custom from/to range picker là Phase 5+ scope.

---

## Business Rules

- **BR-006-01 (alert thresholds, FE hardcode source):**

| Chỉ số | Bình thường (Xanh) | Cảnh báo (Vàng) | Nguy hiểm (Đỏ) |
|--------|-------------------|----------------|----------------|
| **Nhịp tim** | 60-100 BPM | 50-59 hoặc 101-120 | <50 hoặc >120 |
| **SpO₂** | ≥95% | 92-94% | <92% |
| **Huyết áp tâm thu** | 90-120 mmHg | 121-139 hoặc 70-89 | ≥140 hoặc <70 |
| **Huyết áp tâm trương** | 60-80 mmHg | 81-89 hoặc 50-59 | ≥90 hoặc <50 |
| **Nhiệt độ** | 36.1-37.2°C | 37.3-37.7 hoặc 35.5-36.0 | ≥37.8 hoặc <35.5 |
| **Nhịp thở** | 12-20 lần/phút | 8-11 hoặc 21-24 | <8 hoặc >24 |

  Thresholds hiện hardcode trong FE `lib/features/health_monitoring/models/vital_signs.dart` (`getHeartRateStatus`, `getSpo2Status`, `getTemperatureStatus`, `classifyBloodPressureStatus`, `getRespiratoryRateStatus`). Không có endpoint mobile BE serve thresholds cho FE. Alert evaluation phía BE (`risk_alert_service`) dùng thresholds khác (chưa verify trùng khít với bảng này, Phase 0.5 scope limit).

  Phase 5+ parking: Centralize thresholds qua `SettingsService` (`system_settings` table đã có cho admin), expose endpoint `GET /mobile/settings/vitals-thresholds`. Đồ án 2 accept FE hardcode.

- **BR-006-02:** SpO₂ < 92% gửi cảnh báo ngay lập tức (real-time alert pipeline, xem UC008).
- **BR-006-03:** Nhiệt độ ≥ 37.8°C cảnh báo sốt.
- **BR-006-04:** Nhịp tim bất thường kéo dài > 5 phút gửi thông báo (risk alert service aggregate).
- **BR-006-05 (stale detection):** Backend `VITALS_STALE_AFTER = 5 phút`. FE render "--" + `VitalStatus.unknown` khi stale. Không hiển thị giá trị cũ làm user lầm tưởng còn live.

## Business Rules - Phân quyền (Authorization)

- **BR-Auth-01:** User A chỉ xem dữ liệu User B nếu `user_relationships.can_view_vitals = TRUE` (hoặc xem chính mình). Enforce ở `get_target_profile_id` dependency trong `monitoring.py`.

## Yêu cầu phi chức năng

- **Performance**:
  - Độ trễ hiển thị giá trị mới < 5 giây (SRS HG-FUNC-02). FE polling 5s, BE stale check 5 phút.
  - Chu kỳ thiết bị gửi: 1 giây (update v2 — match vitals hypertable comment "Frequency: 1 record/second/device" + IoT sim tick 1s). UC cũ nói "1 phút" là sai factual, continuous aggregates 5min/hourly/daily exists để handle volume 1s.
- **Usability**:
  - Responsive mobile.
  - Font lớn (84sp hero value), tương phản cao cho người cao tuổi.
  - Dark mode (app theme).
- **Security**: Chỉ hiển thị dữ liệu user được ủy quyền (BR-Auth-01).

---

## Implementation references

- Route BE: `health_system/backend/app/api/routes/monitoring.py` — `get_latest_vital_signs`, `get_vitals_timeseries`
- Service BE: `health_system/backend/app/services/monitoring_service.py` — `VITALS_STALE_AFTER`, `_VITALS_TIMESERIES_RANGES`
- FE provider: `health_system/lib/features/health_monitoring/providers/vital_signs_provider.dart` — 5s polling + `isStale` + `chartData`
- FE screen: `health_system/lib/features/health_monitoring/screens/vital_detail_screen.dart`
- FE model: `health_system/lib/features/health_monitoring/models/vital_signs.dart` — BR-006-01 thresholds hardcode
- Related UCs: UC007 (detail drill-down), UC008 (history longer range), UC040 (device pair precondition)
