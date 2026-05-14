# Intent Drift Review — `health_system / MONITORING` (v2)

**Status:** ✅ Confirmed Phase 0.5 v2 (2026-05-13) — deep verification rewrite, 2 claim fix + 2 drift add
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE)
**Module:** MONITORING (Real-time vitals + health report + risk analysis + history)
**Related UCs:** UC006 v2 View Health Metrics, UC007 v2 View Detail, UC008 v2 View History
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13

---

## 🎯 Mục tiêu v2

Rewrite v1 (3 Q) sau khi deep-verify:
- Claim v1 đúng phần lớn nhưng miss 2 drift factual: UC NFR "chu kỳ 1 phút" sai (thực tế 1 giây), UC007 BR-007-03 "max 1 năm" không implement được.
- Code comment drift giữa `_VITALS_TIMESERIES_RANGES` docstring ("coerced to 24h") và logic thực tế (3 range đều functional).
- UC cũ expose custom from/to range, code chỉ có 3 preset, cần drop.

v2 update UC006/007/008 rewrite cohesive, thêm D-MON-04/05/06/07/08 bundle doc fix.

---

## 📚 UC cũ summary (deprecated post-v2)

### UC006 v1 — Xem chỉ số sức khỏe real-time
- Main step 3 "1h trend", Main step 4 "chu kỳ 1 phút".
- Alt 5.b "1h/6h/24h/7d".
- BR thresholds table HR/SpO2/BP/Temp.

### UC007 v1 — Xem chi tiết
- Main step 4 "min/max/avg + violation count", Alt 6.a "export CSV/PDF".
- BR-007-03 "max 1 năm".

### UC008 v1 — Xem lịch sử
- Alt 6.a "custom from/to range picker".
- BR-008-02 "aggregate theo ngày cho >30d".

---

## 🔧 Code state — verified deep

### Routes (`monitoring.py`) — 9 endpoints

```
GET /metrics/vital-signs/latest         JWT + get_target_profile_id + can_view_vitals
GET /metrics/vitals/timeseries          Same + range query param (24h/7d/30d)
GET /metrics/sleep/latest               Same (covered in SLEEP module)
GET /metrics/sleep/history              Same (covered in SLEEP module)
GET /metrics/health-report              Same
GET /analysis/risk-reports              Same + limit
GET /analysis/risk-reports/{id}         Same + audience query (patient/clinician)
GET /analysis/risk-history              Same + range + page + limit + risk_type filter
```

v1 đếm 7 endpoint là chưa chính xác (thực tế 9 khi count /sleep/* và /risk-reports/{id}). v1 đã note "sleep covered in SLEEP module" nên không hẳn sai.

### Service (`monitoring_service.py`) — verified canonical

Constants:
```python
VITALS_STALE_AFTER = timedelta(minutes=5)
RISK_HISTORY_RANGE_DAYS = {"7d": 7, "30d": 30, "90d": 90}
_VITALS_TIMESERIES_RANGES = {
    "24h": (24, 15),
    "7d":  (24*7, 60),
    "30d": (24*30, 360),
}
```

Logic:
- `get_latest_vital_signs`: query max(time) vitals row, compute `is_stale` vs 5 phút threshold. Raises `ValueError` if no data (404 ở route).
- `get_vitals_timeseries`: `normalized_range = range_key if in _VITALS_TIMESERIES_RANGES else "24h"`. Functional cho cả 3 range — comment drift.
- `get_health_report`: 24h AVG + latest risk + health score.
- `get_risk_reports`: LATERAL JOIN + normalize scoring + 7d trend compact.
- `get_risk_report_detail` + `get_risk_report_clinician_detail`: Phase 5 audience gate.
- `get_risk_history`: pagination + `risk_type` filter + summary stats.

### Mobile FE (`health_system/lib/features/health_monitoring/`) — verified rich UX

- `VitalDetailScreen`:
  - 84sp hero value + status pill.
  - `VitalSafeRangeBar` 5-zone.
  - `MiniLineChart` 24h trend (line `provider.chartData` từ timeseries).
  - `VitalEducationCard` per vital type (Vietnamese text).
  - `_buildCriticalAction` SOS button nếu `status == critical`.
  - Stale banner "Thiết bị mất kết nối" nếu `provider.isStale`.
- `HealthReportScreen`: health score hero + 24h avg grid + risk insight.
- `VitalSignsProvider`: 5s polling + `isStale` getter + `chartData` compute từ timeseries envelope.
- `MonitoringRepository.getVitalsTimeseries(range: '24h')` — default 24h, docstring note "7d/30d reserved cho future range tab".

Thresholds hardcode ở `models/vital_signs.dart`:
- `getHeartRateStatus`, `getSpo2Status`, `getTemperatureStatus`, `classifyBloodPressureStatus`, `getRespiratoryRateStatus`.

---

## 🚨 Drift findings v2 (verified)

### A. Claim đúng từ v1 (confirm, 10/10)

1. ✅ Endpoint list (7 monitoring + 2 sleep).
2. ✅ `time_bucket()` 3 ranges functional.
3. ✅ Range config `{"24h":(24,15), "7d":(168,60), "30d":(720,360)}`.
4. ✅ Polling 5s FE + `isStale` 5 phút.
5. ✅ `VITALS_STALE_AFTER = 5 phút`.
6. ✅ UC006 thresholds HR/SpO2/BP/Temp.
7. ✅ Clinician audience gate.
8. ✅ Continuous aggregates DB.
9. ✅ FE chart 24h + education.
10. ✅ Repository default 24h.

### B. Claim SAI nhỏ (v2 fix)

#### B.1 Comment drift `_VITALS_TIMESERIES_RANGES`

Code comment line 741-742:
> "Only "24h" is wired into the mobile UI today; "7d" / "30d" are reserved for future ticket scope and currently coerced to 24h."

Thực tế line 779-783:
```python
normalized_range = range_key if range_key in _VITALS_TIMESERIES_RANGES else "24h"
```

`_VITALS_TIMESERIES_RANGES` chứa cả 3 key. Nên `range_key="7d"` truyền vào thì `normalized_range="7d"`, KHÔNG coerce về 24h. Schema `VitalsTimeseriesResponse` docstring (line 42-50) cũng claim "coerced to 24h" sai.

Drift: FE nếu muốn 7d/30d thì gửi `range=7d` sẽ nhận 168 bucket đúng, không coerce. Nhưng docstring misleading dev.

Fix v2 (D-MON-04 new): Phase 4 bundle D-MON-03 fix 2 comment misleading (service + schema docstring). +5min.

#### B.2 Thresholds source — FE hardcode vs `system_settings`

UC006 BR thresholds hardcode trong FE `vital_signs.dart` model. Không có endpoint mobile BE serve thresholds cho FE. Alert evaluation phía BE (`risk_alert_service`) có thể dùng thresholds khác (chưa verify, Phase 0.5 scope limit không deep dive vào risk_alert_service).

Admin system_settings có threshold config nhưng mobile FE không consume qua endpoint.

Drift: UC006 v2 add BR-006-01 explicit note FE hardcode. Phase 5+ parking centralize.

Không tạo bug riêng vì đồ án 2 accept hardcode, nhưng UC v2 đã document rõ ràng.

### C. Drift MISS v1 (v2 add)

#### C.1 🟠 HIGH: UC NFR "chu kỳ 1 phút" vs code actual 1 giây

UC006 v1 NFR: "chu kỳ 1 phút" (match SRS HG-FUNC-01 claim).

Thực tế:
- `vitals` hypertable DDL comment: "Frequency: 1 record/second/device" (`04_create_tables_timeseries.sql` line 12).
- IoT sim `SimulatorSession` tick default 1s.
- Continuous aggregates 5min/hourly/daily exists để handle volume 1s.

10x discrepancy. UC006 NFR sai factual.

Fix v2: UC006 v2 update NFR "chu kỳ 1 giây" + explain CA aggregation.

#### C.2 🟡 MEDIUM: UC007 BR-007-03 "max 1 năm" không enforce

UC007 v1 BR-007-03: "Chỉ cho phép chọn khoảng thời gian tối đa 1 năm trong 1 lần truy vấn."

Thực tế: `_VITALS_TIMESERIES_RANGES` chỉ có 3 preset max 30d. Không có custom range picker. BR-007-03 vô nghĩa vì không có context apply.

Fix v2: UC007 v2 drop BR-007-03. Alt 5.a ">1 năm" cũng drop.

#### C.3 🟡 MEDIUM: UC008 Alt 6.a "custom from/to" không implement

UC008 v1 Alt 6.a: "Lọc khoảng tùy chỉnh from/to". Code `get_risk_history` chỉ accept 3 preset range. `get_sleep_history` accept from_date/to_date nhưng limit max 90 (tương đương 90d preset).

Fix v2: UC008 v2 drop Alt 6.a.

---

## 🎯 Anh's decisions Phase 0.5 v2

Anh chọn "theo em default" (2026-05-13):

| ID | Item | Decision | Phase 4 effort |
|---|---|---|---|
| D-MON-01 (v1 carry) | Mobile export CSV/PDF | Drop UC007 Alt 6.a | 0h (doc) |
| D-MON-02 (v1 carry) | UC006 "1h" sang "24h" | Update UC006 step 3 | 0h (doc) |
| D-MON-03 (v1 carry) | FE range tabs 24h/7d/30d | Wire FE SegmentedButton | ~2h |
| **D-MON-04 new** | BE comment drift | Fix `_VITALS_TIMESERIES_RANGES` comment + schema docstring | ~5min (bundle D-MON-03) |
| **D-MON-05 new** | UC006 chu kỳ 1s (not 1 phút) | UC006 v2 NFR update | 0h (doc) |
| **D-MON-06 new** | Thresholds FE hardcode note | UC006 BR-006-01 explicit note | 0h (doc) |
| **D-MON-07 new** | UC007 drop BR-007-03 | UC007 v2 drop | 0h (doc) |
| **D-MON-08 new** | UC008 drop Alt 6.a | UC008 v2 drop | 0h (doc) |

### Phase 4 total revised

| Task | Effort |
|---|---|
| D-MON-03: FE range tabs | **~2h** |
| D-MON-04: BE comment fix (bundle) | ~5min |
| Doc updates UC006/007/008 | ~25min (Phase 0.5 now) |

Estimated Phase 4 code effort: ~2h05min (D-MON-03 + D-MON-04 bundled).

---

## 📊 UC delta v2

| UC cũ | Status v2 | v2 changes |
|---|---|---|
| UC006 View Metrics | **Overwrite** | Step 3 "1h" sang "24h". Alt 5.b list 24h/7d/30d (drop 1h/6h). NFR chu kỳ "1 phút" sang "1 giây". BR-006-01 note FE hardcode. BR-006-05 add stale detection. |
| UC007 View Detail | **Overwrite** | Step 5 list 24h/7d/30d. Drop Alt 5.a "> 1 năm" + BR-007-03. Drop Alt 6.a export. Drop step 4 "min/max/avg + violation count". BR-007-05 stats Phase 5+. |
| UC008 View History | **Minor update** | Drop Alt 6.a custom range. BR-008-02 preset 7d/30d/90d canonical. BR-008-04 retention explicit. BR-008-05 scope clarify UC007 vs UC008. |

---

## 🆕 Industry standard add-ons — anh's selection

Tất cả DROP (giữ v1):

- ❌ Min/max/avg stats panel — Phase 5+ (UC007 step 4 drop)
- ❌ Threshold violation count — Phase 5+ (UC007 step 4 drop)
- ❌ Custom date range picker — Phase 5+ (UC008 Alt 6.a drop)
- ❌ Multi-vital overlay chart — Phase 5+

---

## 📝 Anh's decisions log v2

| ID | Item | Decision | Rationale |
|---|---|---|---|
| D-MON-01 | Mobile export | Drop UC007 Alt 6.a | Admin web đã có; mobile view-only |
| D-MON-02 | Chart range text | Update UC006 step 3 24h | Match code behavior |
| D-MON-03 | FE range tabs | Wire 24h/7d/30d Phase 4 | BE đã implement, chỉ cần FE UI |
| **D-MON-04** | BE comment drift | Fix misleading "coerce to 24h" | Code thực tế không coerce khi key valid |
| **D-MON-05** | UC006 chu kỳ 1s | Update NFR | Match vitals hypertable + IoT sim tick |
| **D-MON-06** | Thresholds FE hardcode | Document BR-006-01 | Đồ án 2 accept; Phase 5+ centralize |
| **D-MON-07** | UC007 BR-007-03 "max 1 năm" | Drop | Code không có custom range |
| **D-MON-08** | UC008 Alt 6.a custom range | Drop | Code không support; Phase 5+ |

### Add-ons dropped

| Add-on | Decision |
|---|---|
| Min/max/avg stats | ❌ Drop Phase 5+ |
| Violation count | ❌ Drop Phase 5+ |
| Custom date range | ❌ Drop Phase 5+ |
| Multi-vital overlay | ❌ Drop Phase 5+ |

---

## Cross-references

### UC v2 (committed Phase 0.5)

- `PM_REVIEW/Resources/UC/Monitoring/UC006_View_Health_Metrics.md` — v2 overwrite
- `PM_REVIEW/Resources/UC/Monitoring/UC007_View_Health_Metrics_Detail.md` — v2 overwrite
- `PM_REVIEW/Resources/UC/Monitoring/UC008_View_Health_History.md` — v2 minor update

### Code paths (Phase 4)

**health_system BE (D-MON-04):**
- `health_system/backend/app/services/monitoring_service.py` line 741-742 — fix comment "coerced to 24h" misleading
- `health_system/backend/app/schemas/monitoring.py` line 42-50 — fix `VitalsTimeseriesResponse` docstring

**Mobile FE (D-MON-03):**
- `health_system/lib/features/health_monitoring/screens/vital_detail_screen.dart` — add SegmentedButton row
- `health_system/lib/features/health_monitoring/providers/vital_signs_provider.dart` — add `_currentRange` state + `setRange(String)` method
- `health_system/lib/features/health_monitoring/repositories/monitoring_repository.dart` — `getVitalsTimeseries` đã có `range` param

### DB schema

- `PM_REVIEW/SQL SCRIPTS/04_create_tables_timeseries.sql` — vitals + motion_data + CAs
- `PM_REVIEW/SQL SCRIPTS/09_create_policies.sql` — retention 1 năm vitals

### Related bugs / ADR

- Không tạo bug/ADR mới — tất cả fix là doc alignment + code comment cleanup, no architectural change.
- Related ADR-013 (IoT sim direct-DB) — confirms vitals tick 1s.

---

## Changelog

| Version | Date | Note |
|---|---|---|
| v1 | 2026-05-13 sáng | Initial 3 Q drift review (D-MON-01/02/03) |
| v2 | 2026-05-13 chiều | Deep verify: add D-MON-04 (comment drift) + D-MON-05/06/07/08 (UC text fixes). Overwrite UC006/007/008. |
