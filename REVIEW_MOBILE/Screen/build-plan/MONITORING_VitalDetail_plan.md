# 📐 UI Plan: Chi tiết chỉ số sinh tồn (Vital Detail)

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [MONITORING_VitalDetail.md](../MONITORING_VitalDetail.md)  
> **Existing Code**: `health_system/lib/features/health_monitoring/screens/vital_detail_screen.dart`

---

## 1. Description

- **SRS Ref**: UC006, UC007
- **User Role**: User (self) / User xem linked profile (caregiver/family)
- **Purpose**: Drill-down 1 chỉ số (HR, SpO₂, BP, Temp) với biểu đồ 24h, giải thích bằng tiếng người (VD: "82 BPM — Bình thường"). Màn hình contextual: nhận `profileId` qua route (optional, null = self).

**Existing screen**: `VitalDetailScreen` đã có layout giá trị lớn + chart + education + SOS. Tận dụng và cải thiện theo task.

---

## 2. User Flow

1. User mở màn hình từ HOME_Dashboard (bấm Card) hoặc HOME_FamilyDashboard (bấm chỉ số) hoặc MONITORING_HealthHistory (bấm event).
2. Route truyền `vitalType` (hr/spo2/bp/temp) và `profileId` (optional).
3. Screen fetch `GET /api/mobile/vitals/:vitalType/detail?profile_id={profileId}`.
4. Hiển thị giá trị lớn + đơn vị + trạng thái (Bình thường / Cảnh báo / Nguy hiểm).
5. Biểu đồ 24h — hoặc Empty state nếu không có data.
6. Giải thích: "82 BPM — Bình thường".
7. Invalid (sensor lỗi) → `"--"` + icon cảnh báo cam.
8. Self + critical → nút "Gọi SOS". Linked + critical → chỉ cảnh báo, không SOS.
9. Bấm "Xu hướng" → MONITORING_HealthHistory.
10. Back → HOME_Dashboard hoặc HOME_FamilyDashboard.

---

## 3. UI States

| State | Description | Display |
|-------|-------------|---------|
| Loading | Đang fetch vital detail | Skeleton shimmer (card + chart placeholder) |
| Success | Có data | Giá trị + chart + giải thích |
| Empty | Không có data 24h | "Chưa có dữ liệu" + icon, vẫn hiển thị giá trị hiện tại nếu có |
| Invalid | Giá trị ngoài vùng (sensor lỗi) | `"--"` + icon cảnh báo cam "Không đo được" |
| Error | API fail, 403 (no permission) | SnackBar + "Thử lại" / Back |
| Critical | Chỉ số nguy hiểm | Nút "Gọi SOS" nổi bật (chỉ khi self) |

---

## 4. Widget Tree (proposed)

```
Scaffold
├── AppBar
│   ├── leading: BackButton
│   ├── title: Text(vitalTypeLabel)  // "Nhịp tim", "SpO₂", ...
│   └── subtitle (nếu profileId): Text(linkedProfileName)
├── Body: BlocBuilder / Consumer
│   ├── [Loading] → VitalDetailSkeleton
│   ├── [Error]   → ErrorView(message, onRetry)
│   └── [Success/Empty/Invalid/Critical] → SingleChildScrollView
│       ├── VitalValueCard (value, unit, status) — hoặc InvalidCard ("--", icon)
│       ├── Section "Biến động 24h qua"
│       │   ├── [Empty] → EmptyChartPlaceholder("Chưa có dữ liệu")
│       │   └── [Has data] → MiniLineChart (existing)
│       ├── EducationTextCard (existing)
│       ├── Link "Xem xu hướng" → TextButton
│       ├── [Self + Critical] → SOSButton (existing, min 64dp)
│       └── [Linked + Critical] → WarningBanner (không có SOS)
```

---

## 4.5. Visual Design Spec

### Colors

| Role | Token / Value | Usage in this screen |
|------|---------------|----------------------|
| Primary BG | `AppColors.bgPrimary` | Scaffold background |
| Card | `AppColors.bgSurface` | Card container |
| Normal | `AppColors.success` | Status badge, value khi Bình thường |
| Warning | `AppColors.warning` | Status badge khi Cảnh báo, Invalid icon |
| Critical | `AppColors.critical` | Status badge khi Nguy hiểm |
| SOS button | `AppColors.emergency` | Nút Gọi SOS |
| Text primary | `AppColors.textPrimary` | Section title |
| Text secondary | `AppColors.textSecondary` | Đơn vị, caption |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Giá trị chính | 84sp | Bold | semantic (success/warning/critical) |
| Đơn vị | 28sp | Medium | textSecondary |
| Status badge | 18sp | Bold | semantic |
| Section title | 18sp | Bold | textPrimary |
| Education text | 16sp | Regular | textPrimary (tăng từ 15sp) |
| SOS button | 20sp | Bold | white on emergency |

### Spacing

- Screen padding: 20dp horizontal
- Card gap: 24dp
- Section gap: 24dp
- SOS button min height: 64dp (spec: 48dp minimum, 64dp for critical CTA)

---

## 4.6. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
|---------|----------------------|----------|
| Screen enter | Slide from right (default) | 300ms |
| Value change | AnimatedVitalValue (fade+slide) | 500ms |
| Loading → Success | Skeleton → content crossfade | 200ms |
| SOS button press | Scale 0.95 + haptic | 150ms |

---

## 4.7. Accessibility Checklist

- [x] Min font 16sp (body), 14sp (caption) — education 16sp
- [x] Min touch target 48dp × 48dp — SOS button 64dp
- [x] Contrast ratio ≥ 4.5:1 (text), ≥ 3:1 (icons)
- [x] TalkBack: SOS button có `Semantics(button: true, label: 'Gọi bác sĩ hoặc người thân ngay lập tức')`
- [x] No information by color alone — status có text "Bình thường/Cảnh báo/Nguy hiểm"
- [x] Elderly UX: SOS ở bottom 40% màn hình

---

## 4.8. Design Rationale

| Decision | Reason |
|----------|--------|
| Giá trị 84sp | Elderly-friendly, đọc khi screen xa |
| SOS button 64dp | Trembling hands, WCAG 2.5.5 |
| Self-only SOS | Không gửi SOS thay người khác (UC007) |
| Linked profile + critical | Chỉ cảnh báo, CTA liên hệ — không SOS |
| Invalid → "--" + icon cam | Sensor lỗi rõ ràng, không gây hoảng |
| Reuse VitalDetailScreen | Đã có layout đúng ~70%, refactor thêm |

---

## 5. Edge Cases Handled

- [x] `profileId` null → fetch self data
- [x] `profileId` có → fetch linked profile; cần `can_view_vitals`
- [x] 403 Forbidden → message "Bạn không có quyền xem" + Back
- [x] HR=0, sensor rời → Invalid: `"--"` + "Kiểm tra thiết bị"
- [x] Không có data 24h → Empty state + giá trị mới nhất nếu có
- [x] Self + "Gọi SOS" → navigate ManualSOS (countdown)
- [x] Linked profile + critical → chỉ cảnh báo, không SOS

---

## 6. Dependencies

### Shared widgets needed

- `VitalDetailSkeleton` — NEW (Loading)
- `EmptyChartPlaceholder` — NEW hoặc extend MiniLineChart
- `InvalidVitalCard` — NEW (`"--"` + icon)
- `ErrorView` — NEW nếu chưa có
- Reuse: `VitalDetailScreen` (refactor), `AnimatedVitalValue`, `MiniLineChart`, `VitalStatus`

### API endpoints

- `GET /api/mobile/vitals/:vitalType/detail?profile_id={profileId}`
- Response: `{ current: { value, unit, status }, chartData: [{ timestamp, value }], educationText }`

### Route args

- `vitalType`: String (hr | spo2 | bp | temp)
- `profileId`: String? (null = self)

---

## 7. Confidence Score

- **Plan Confidence: 88%**
- **Reasoning**: Màn hình hiện có cover ~70% yêu cầu. Gap: profileId, UI states, route. Plan tận dụng và refactor.
- **Uncertainties**: API schema `status: invalid` chưa confirm; HealthHistory route args cần sync.

---

## 8. Implementation Phases (tận dụng màn hình hiện có)

| Phase | Action |
|-------|--------|
| 1 | Refactor VitalDetailScreen: AppColors, `isSelf`, `showInvalidState`, link "Xu hướng", AppBar subtitle |
| 2 | VitalDetailContainer + use case + API; Loading, Error, 403 |
| 3 | Empty, Invalid states; wire navigation |
| 4 | Sync HOME_Dashboard, FamilyDashboard, HealthHistory |
