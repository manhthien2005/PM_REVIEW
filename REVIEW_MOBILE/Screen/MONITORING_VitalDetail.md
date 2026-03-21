# 📱 MONITORING — Chi tiết chỉ số sinh tồn

> **UC Ref**: UC006, UC007
> **Module**: MONITORING
> **Status**: ✅ Built (health_system)

## Purpose

Drill-down 1 chỉ số (HR, SpO₂, BP, Temp) với biểu đồ 24h. **Giải thích bằng tiếng người** bên cạnh số (VD: "82 BPM — Bình thường"). Đây là màn hình **contextual**: nhận `profileId` qua route (optional, null = self) — UC007: xem chỉ số của người được monitor.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [HOME_Dashboard](./HOME_Dashboard.md) | Bấm Card chỉ số | → This screen (profileId = null, self) |
| [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) | Bấm chỉ số trên Card | → This screen (profileId từ Card) |
| [MONITORING_HealthHistory](./MONITORING_HealthHistory.md) | Bấm event | → This screen |
| This screen | Chỉ số critical của self → SOS | → [EMERGENCY_ManualSOS](./EMERGENCY_ManualSOS.md) |
| This screen | Bấm "Xu hướng" | → [MONITORING_HealthHistory](./MONITORING_HealthHistory.md) |
| This screen | Back | → [HOME_Dashboard](./HOME_Dashboard.md) hoặc [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) |

---

## User Flow

1. Nhận `vitalType` (hr/spo2/bp/temp) và `profileId` (optional) từ route.
2. Hiển thị giá trị lớn + đơn vị + trạng thái (Bình thường / Cảnh báo / Nguy hiểm).
3. Biểu đồ 24h (line chart).
4. Giải thích: "82 BPM — Bình thường".
5. Chỉ số ngoài vùng hợp lệ → `"--"` + icon cảnh báo.
6. Nếu là self và chỉ số critical → hiển thị nút "Gọi SOS" / link ManualSOS.
7. Nếu là linked profile và chỉ số critical → hiển thị cảnh báo rõ ràng, nhưng **không** cho gửi `ManualSOS` thay người khác.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| Loading | Đang fetch vital detail | Skeleton / CircularProgressIndicator |
| Success | Có data | Giá trị + chart + giải thích |
| Empty | Không có data 24h | "Chưa có dữ liệu" + icon, vẫn hiển thị giá trị hiện tại nếu có |
| Invalid | Giá trị ngoài vùng (sensor lỗi) | `"--"` + icon cảnh báo cam "Không đo được" |
| Error | API fail, 403 (no permission) | SnackBar + "Thử lại" / Back |
| Critical | Chỉ số nguy hiểm | Nút "Gọi SOS" nổi bật |

---

## Edge Cases

- [ ] `profileId` null → fetch data self (HOME_Dashboard flow)
- [ ] `profileId` có giá trị → fetch data của linked profile; cần `can_view_vitals` (HOME_FamilyDashboard flow)
- [ ] 403 Forbidden (không có quyền xem profile) → message "Bạn không có quyền xem" → Back
- [ ] Chỉ số HR=0, sensor rời → hiển thị `"--"` + "Kiểm tra thiết bị"
- [ ] Không có data 24h (đồng hồ mới kết nối) → Empty state, vẫn hiển thị giá trị mới nhất nếu có
- [ ] Self + bấm "Gọi SOS" khi critical → navigate ManualSOS (có countdown, không gửi ngay)
- [ ] Linked profile + critical → chỉ hiển thị cảnh báo / CTA liên hệ phù hợp, không gửi SOS thay người khác

---

## Data Requirements

- **API endpoint**: `GET /api/mobile/vitals/:vitalType/detail` với query `?profile_id={profileId}` (omit = self)
- **Input**: Route args: `vitalType`, `profileId?` (contextual route arg, không dùng global profile switcher)
- **Output**: `{ current: { value, unit, status }, chartData: [{ timestamp, value }], educationText }`

---

## Sync Notes

- Khi HOME_Dashboard / HOME_FamilyDashboard thay đổi → link truyền đúng `vitalType` và `profileId`
- Khi MONITORING_HealthHistory thay đổi → bấm event truyền `vitalType`, `profileId`, `timestamp` (optional)
- Shared: `VitalDetailChart`, `VitalStatusBadge`, `EducationText` widget
- **Lưu ý**: health_system chưa nhận profileId — self-only; cần bổ sung khi support Family flow

---

## Design Context

- **Target audience (profileId = null)**: Người cao tuổi xem chỉ số của chính mình — cần giải thích rõ, font lớn.
- **Target audience (profileId có)**: Người theo dõi (caregiver/family) xem chỉ số người thân — cần header hiển thị tên người được xem.
- **Usage context**: Routine monitoring — drill-down từ Dashboard.
- **Key UX priority**: Clarity (số to, màu trạng thái rõ), Calm (không gây hoảng).
- **Specific constraints**: Biểu đồ cần legend; nút SOS min 48dp; Text Scaling 150% → chart scale.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | [build-plan/MONITORING_VitalDetail_plan.md](./build-plan/MONITORING_VitalDetail_plan.md) |
| BUILD | ✅ Done | health_system |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context (profileId/audience), Pipeline Status, Changelog |
| v2.1 | 2026-03-17 | AI | Cross-check sync: bỏ `target_profile_id`, làm rõ self/linked flow và giới hạn `ManualSOS` cho self |
| v2.2 | 2026-03-18 | AI | PLAN done: build-plan/MONITORING_VitalDetail_plan.md — gap analysis, reuse existing screen, phased implementation |

---

## Implementation Reference (health_system)

- `lib/features/health_monitoring/screens/vital_detail_screen.dart`
- Props: title, value, unit, status, chartData, chartColors, educationText, onSosTap
- Chưa nhận profileId — self-only hiện tại.
