# Build Plans — Index

> Thư mục chứa các plan chi tiết để Agent implement. Mỗi plan độc lập, có thể đưa riêng cho Agent.

---

## EMERGENCY SOS Module

| File | Mục đích | Agent đọc khi |
|------|----------|---------------|
| [EMERGENCY_SOS_Flow_Plan.md](./EMERGENCY_SOS_Flow_Plan.md) | **Tổng quan** — Luồng, Decision Log, Multi-agent review | Cần hiểu toàn bộ context |
| [EMERGENCY_SOS_01_Navigation_Flow_Plan.md](./EMERGENCY_SOS_01_Navigation_Flow_Plan.md) | **Luồng màn hình** — Route, Navigator, link giữa màn | Implement navigation |
| [EMERGENCY_SOS_02_FE_Architecture_Plan.md](./EMERGENCY_SOS_02_FE_Architecture_Plan.md) | **UI/UX** — AppColors, AppTextStyles, mock data | Implement UI, styling |
| [EMERGENCY_SOS_03_Folder_Architecture_Plan.md](./EMERGENCY_SOS_03_Folder_Architecture_Plan.md) | **Cấu trúc thư mục** — File path, import | Tạo/sửa file |

### Thứ tự Agent nên đọc

1. **EMERGENCY_SOS_Flow_Plan.md** — Hiểu tổng quan
2. **EMERGENCY_SOS_03_Folder_Architecture_Plan.md** — Biết đặt file ở đâu
3. **EMERGENCY_SOS_01_Navigation_Flow_Plan.md** — Wire routes, Navigator
4. **EMERGENCY_SOS_02_FE_Architecture_Plan.md** — Style từng màn

### Mock Data (Gửi Dev Backend)

| File | Mục đích |
|------|----------|
| [EMERGENCY_SOS_Mock_Data_Spec.md](./EMERGENCY_SOS_Mock_Data_Spec.md) | Spec API mock cho SOS Received — schema, sample JSON, checklist |

---

## FAMILY Module

| File | Mục đích |
|------|----------|
| [FAMILY_UI_Refactor_Build_Plan.md](./FAMILY_UI_Refactor_Build_Plan.md) | Refactor Family Dashboard + Person Detail |
| [FAMILY_TabGiaDinh_Refactor_Spec.md](./FAMILY_TabGiaDinh_Refactor_Spec.md) | Spec tab Gia đình (Theo dõi | Liên hệ) |

---

## ANALYSIS Module

| File | Mục đích | Ưu tiên build |
|------|----------|---------------|
| [ANALYSIS_01_RiskReport_plan.md](./ANALYSIS_01_RiskReport_plan.md) | Màn overview sau khi bấm banner điểm sức khỏe | 1 |
| [ANALYSIS_02_RiskReportDetail_plan.md](./ANALYSIS_02_RiskReportDetail_plan.md) | Màn giải thích XAI, breakdown và recommendation | 2 |
| [ANALYSIS_03_RiskHistory_plan.md](./ANALYSIS_03_RiskHistory_plan.md) | Màn lịch sử điểm sức khỏe / risk score | 3 |

### Thứ tự Agent nên build

1. **ANALYSIS_01_RiskReport_plan.md** — khóa visual language + route entry từ banner
2. **ANALYSIS_02_RiskReportDetail_plan.md** — build XAI breakdown + drill-down sang màn đã có
3. **ANALYSIS_03_RiskHistory_plan.md** — build history sau cùng để reuse component và API contract

---

*Index v1.0 — 2026-03-19*
