# UC021 - XEM BÁO CÁO GIẤC NGỦ (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** Minor update — add BR-021-04 explicit threshold TỐT/TRUNG BÌNH/KÉM (match `monitoring_service._calculate_sleep_metrics` thresholds 70/50), add BR-021-05 reference incomplete session badge (paired với UC020 BR-020-05). Core flow không đổi vì code đã aligned.

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC021                                                                                                                   |
| **Tên UC**         | Xem báo cáo giấc ngủ                                                                                                    |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc                                                                                               |
| **Mô tả**          | Người dùng xem báo cáo chất lượng giấc ngủ theo đêm hoặc theo khoảng ngày từ `sleep_sessions` (UC020 output).          |
| **Trigger**        | User mở tab "Giấc ngủ" (`SleepReportScreen`), hoặc chọn đêm cụ thể (`SleepDetailScreen`), hoặc mở history.             |
| **Tiền điều kiện** | Ít nhất một phiên giấc ngủ hợp lệ trong `sleep_sessions` cho `target_profile_id`.                                       |
| **Hậu điều kiện**  | Người dùng hiểu chất lượng giấc ngủ đêm qua + xu hướng 7 ngày.                                                          |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                         |
| ---- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Người dùng      | Mở tab "Giấc ngủ" trên app.                                                                                                                                                                                       |
| 2    | Client          | `GET /mobile/metrics/sleep/latest?target_profile_id=<id>` + `GET /mobile/metrics/sleep/history?from_date=...&to_date=...&target_profile_id=<id>` song song (Future.wait).                                         |
| 3    | Hệ thống (BE)   | Auth guard: JWT user + `get_target_profile_id()` resolve. Nếu target_profile_id != current_user.id thì check `user_relationships.can_view_vitals = TRUE` (BR-021-03).                                             |
| 4    | Hệ thống (BE)   | Query `sleep_sessions` filter `user_id + sleep_date` range. Compute `sleep_minutes / awake_minutes / efficiency_ratio / quality_label` per row (xem BR-021-04).                                                   |
| 5    | Client          | Render `SleepReportScreen`:<br>- Hero card: quality_score 0-100 + quality_label (TỐT/TRUNG BÌNH/KÉM) + sleep_minutes<br>- Timeline phases (light/deep/rem)<br>- 7-day trend chart<br>- History list                |
| 6    | Người dùng      | Chọn 1 đêm cụ thể để mở `SleepDetailScreen`.                                                                                                                                                                      |
| 7    | Client          | `getSessionByDate(date)` gọi lại `sleep/history` với `from_date = to_date = date`, hoặc dùng cache từ history list (provider TTL 1 min).                                                                           |
| 8    | Client          | Render detail: wave chart từ `phases`, start/end time, wake_count, phases breakdown.                                                                                                                              |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Chưa có session nào

| Bước  | Người thực hiện | Hành động                                                                                                                                         |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.a.1 | Hệ thống (BE)   | `/sleep/latest` returns null (204 hoặc response_model với `None` union).                                                                           |
| 2.a.2 | Client          | `SleepProvider` set state `empty` hoặc `noDataYet` (nếu ngày hôm nay trước 6h sáng).                                                              |
| 2.a.3 | Client          | Render empty state: "Chưa có dữ liệu giấc ngủ" + CTA mở UC040 (pair device) hoặc hướng dẫn đeo thiết bị khi ngủ.                                  |

### 3.a - Forbidden (target user B không grant can_view_vitals)

| Bước  | Người thực hiện | Hành động                                                                   |
| ----- | --------------- | --------------------------------------------------------------------------- |
| 3.a.1 | Hệ thống (BE)   | Query `user_relationships` where `patient_id=B AND caregiver_id=A AND can_view_vitals=TRUE` trả empty. |
| 3.a.2 | Hệ thống (BE)   | Return 403 Forbidden.                                                        |
| 3.a.3 | Client          | Render error state với message "Bạn chưa được cấp quyền xem dữ liệu này".   |

### 3.b - Filter khoảng thời gian khác

| Bước  | Người thực hiện | Hành động                                                                       |
| ----- | --------------- | ------------------------------------------------------------------------------ |
| 3.b.1 | Người dùng      | Chọn range 7/30/90 ngày trên FE.                                                |
| 3.b.2 | Client          | Gọi lại `/sleep/history` với `from_date` shifted theo range.                    |
| 3.b.3 | Client          | Update 7-day trend chart theo data mới.                                         |

### 5.a - Session incomplete (linked với UC020 BR-020-05)

| Bước  | Người thực hiện | Hành động                                                                                                         |
| ----- | --------------- | ----------------------------------------------------------------------------------------------------------------- |
| 5.a.1 | Client          | Row có `is_complete = FALSE` (Phase 4).                                                                           |
| 5.a.2 | Client          | Render badge "Không hoàn chỉnh" trên session card + tooltip: "Phiên ngủ < 2h hoặc device mất kết nối giữa chừng". |

---

## Business Rules

- **BR-021-01**: Điểm chất lượng giấc ngủ = `sleep_score` từ `sleep_sessions` (device-calculated, 0-100 scale high=better). KHÔNG phải ML inference — ML thuộc UC028 Analysis (xem UC020 BR-020-04).
- **BR-021-02**: Màn hình báo cáo hiển thị "Tóm tắt cho người không rành kỹ thuật" với nhãn TỐT / TRUNG BÌNH / KÉM (Vietnamese). Client map từ English label backend trả về (`GOOD` sang `Tốt`, `AVERAGE` sang `Trung bình`, `POOR` sang `Kém`).
- **BR-021-03**: Caregiver chỉ xem report của patient nếu `user_relationships.can_view_vitals = TRUE` (shared với UC015 Family Dashboard permission model). Auth enforce ở BE endpoint.
- **BR-021-04** (explicit threshold cho BR-021-02): Backend `MonitoringService._calculate_sleep_metrics` map quality_score sang quality_label theo 3 tier:
  - `>= 70` sang `GOOD` (Tốt)
  - `50..69` sang `AVERAGE` (Trung bình)
  - `< 50` sang `POOR` (Kém)
  
  Thresholds hardcode cho đồ án 2 scope, Phase 5+ có thể configurable qua `system_settings` nếu có compliance requirement.
- **BR-021-05** (depend UC020 BR-020-05, implement Phase 4): Nếu session có `is_complete = FALSE`, FE hiển thị badge "Không hoàn chỉnh" trên session card + detail. Quality score vẫn compute nhưng user/caregiver nên đánh giá với context data không đầy đủ.

---

## Yêu cầu phi chức năng

- **Usability**:
  - Biểu đồ trực quan, font lớn cho người lớn tuổi.
  - State machine FE rõ: `initial / loading / success / empty / error / noDataYet`.
- **Performance**:
  - `/sleep/latest` + `/sleep/history` song song (Future.wait client-side).
  - 7-day history < 2s cho user có đầy đủ data.
  - Cache TTL 1 phút trong `SleepProvider`.
- **Privacy**:
  - `can_view_vitals` check enforce ở BE, không chỉ UI hide.
  - Caregiver access logged qua `audit_logs` (Phase 4+, out of UC021 v2 scope).

---

## Implementation references

- Route: `health_system/backend/app/api/routes/monitoring.py` (`get_latest_sleep_session`, `get_sleep_history`)
- Service: `health_system/backend/app/services/monitoring_service.py` (`_calculate_sleep_metrics`, `_normalize_sleep_date`)
- Schema: `health_system/backend/app/schemas/monitoring.py` (`SleepSessionResponse`, `SleepHistoryResponse`)
- FE provider: `health_system/lib/features/sleep_analysis/providers/sleep_provider.dart`
- FE repository: `health_system/lib/features/sleep_analysis/repositories/sleep_repository.dart`
- FE model: `health_system/lib/features/sleep_analysis/models/sleep_session.dart` (`SleepSession`, `SleepPhasesDTO`, quality label map Vietnamese)
- FE screens: `sleep_report_screen.dart`, `sleep_detail_screen.dart`, `sleep_history_screen.dart`
- Related UCs: UC020 (producer), UC028 (sleep ML risk report separate channel), UC015 (family permission model)
