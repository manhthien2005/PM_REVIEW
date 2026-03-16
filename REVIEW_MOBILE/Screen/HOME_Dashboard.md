# 📱 HOME — Sức khoẻ của tôi (My Health Dashboard)

> **UC Ref**: UC006, UC007, UC008, UC016, UC020
> **Module**: HOME
> **Status**: ⬜ Draft

## Purpose
Tab đầu tiên và mặc định của ứng dụng (Bottom Navigation Bar). Hiển thị **toàn bộ sức khoẻ của chính bản thân người dùng** — chỉ số sinh tồn thời gian thực, báo cáo giấc ngủ đêm qua, điểm rủi ro AI, và lối tắt vào các chức năng nhanh như SOS hay thiết bị. Màn hình này **KHÔNG** hiển thị dữ liệu của người khác — đó là nhiệm vụ của tab `HOME_FamilyDashboard`.

> **Lưu ý kiến trúc**: Màn hình này thay thế hoàn toàn khái niệm cũ "Profile Switcher Context". Người dùng KHÔNG còn chuyển đổi ngữ cảnh Profile ở màn này nữa. Dữ liệu luôn là của chính bản thân họ.

---

## Navigation Links (🔗 Màn hình Liên quan)
| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| `AUTH_Login` / `AUTH_Splash` | Đăng nhập thành công | → This screen (Tab mặc định) |
| This screen | Bấm tab "Gia đình" ở Bottom Nav | → [HOME_FamilyDashboard](./HOME_FamilyDashboard.md) |
| This screen | Bấm vào Card chỉ số sinh tồn | → [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) |
| This screen | Bấm "Xem lịch sử chỉ số" | → [MONITORING_HealthHistory](./MONITORING_HealthHistory.md) |
| This screen | Bấm vào Banner Giấc ngủ | → [SLEEP_Report](./SLEEP_Report.md) |
| This screen | Bấm vào Banner Điểm rủi ro AI | → [ANALYSIS_RiskReport](./ANALYSIS_RiskReport.md) |
| This screen | Bấm nút SOS khẩn cấp (Emergency FAB) | → [EMERGENCY_ManualSOS](./EMERGENCY_ManualSOS.md) |
| This screen | Bấm tab Thiết bị ở Bottom Nav | → [DEVICE_List](./DEVICE_List.md) |
| This screen | Bấm tab Hồ sơ ở Bottom Nav | → [PROFILE_Overview](./PROFILE_Overview.md) |
| *System Event* | SOS active khi mở lại app | → [EMERGENCY_LocalSOSActive](./EMERGENCY_LocalSOSActive.md) |

---

## User Flow
1. Sau khi đăng nhập (hoặc mở lại app), ứng dụng load thẳng vào tab **"Sức khoẻ của tôi"**.
2. App gọi `GET /api/mobile/dashboard/self` — trả về snapshot chỉ số sinh tồn mới nhất của user.
3. Dashboard hiển thị theo bố cục dọc:
   - **Phần trên (Live Vitals):** Grid 2x2 các card chỉ số: Nhịp tim, SpO₂, Huyết áp, Nhiệt độ. Số to, màu theo trạng thái (Xanh bình thường / Cam theo dõi / Đỏ nguy hiểm). Cập nhật real-time qua WebSocket khi đồng hồ đang đeo (hoặc polling 60s nếu offline).
   - **Phần giữa (Giấc ngủ đêm qua):** Banner tóm tắt giấc ngủ: Tổng thời gian + Chất lượng + Nhịp tim khi ngủ. Bấm vào → `SLEEP_Report`.
   - **Phần dưới (Điểm rủi ro AI):** Banner điểm rủi ro tổng hợp (0-100). Bấm vào → `ANALYSIS_RiskReport`.
4. Nút **SOS Khẩn cấp** (FAB đỏ nổi bật hoặc nút cố định đáy màn hình) luôn hiển thị — bấm → `ManualSOS`.
5. **App Resume Logic**: Khi app được mở lại từ background:
   - Nếu user có `active_sos_event` đang diễn ra → Điều hướng thẳng sang `EMERGENCY_LocalSOSActive`.
   - Nếu không → Ở lại Dashboard bình thường.

---

## UI States
| Trạng thái | Điều kiện | Hiển thị |
| --- | --- | --- |
| **Loading** | Lần đầu tải sau đăng nhập | Skeleton animation trên tất cả Cards. |
| **Success_Normal** | Tất cả chỉ số bình thường | Cards màu xanh/xám. Không có cảnh báo. |
| **Success_Warning** | Một hoặc nhiều chỉ số cần theo dõi | Card đó chuyển viền cam, icon cảnh báo nhỏ. Banner top screen "⚠️ Một số chỉ số cần chú ý". |
| **Success_Critical** | Chỉ số đang ở mức nguy hiểm | Card chuyển nền đỏ nhạt. Nút "Gọi trợ giúp ngay" to xuất hiện. |
| **No_Device** | Chưa kết nối đồng hồ | Banner nhắc "Kết nối đồng hồ để đo chỉ số" + Nút "Kết nối thiết bị". Không có data trong Grid. |
| **Device_Offline** | Đồng hồ đang mất kết nối | Badge nhỏ "Đồng hồ offline" trên mỗi Card. Hiển thị data lần cuối với dấu thời gian. |
| **Error** | Lỗi API | Snackbar lỗi + Nút "Thử lại". |
| **Offline** | Điện thoại mất mạng | Banner vàng offline. Hiển thị cache. |

---

## Layout Gợi ý
```
┌──────────────────────────────────────────┐
│  [Avatar] Xin chào, Minh Thiện!   [🔔]   │   ← App Bar
│  Thứ Hai, 16/03/2026                      │
├──────────────────────────────────────────┤
│  ❤️ 82 BPM   💧 97%   🩸 120/80  🌡️ 36.5°  │   ← Grid Live Vitals
│  Bình thường  Tốt     Theo dõi  Tốt       │
├──────────────────────────────────────────┤
│  😴 Giấc ngủ tối qua: 7h20 — Tốt          │   ← Sleep Banner
│  Nhịp tim khi ngủ: 58 BPM (Thư giãn)     │
├──────────────────────────────────────────┤
│  🤖 Điểm rủi ro AI: 32/100 — Thấp         │   ← Risk Banner
│  "Không có nguy cơ đáng lo ngại"          │
├──────────────────────────────────────────┤
│  [ 🆘 GỬI TÍN HIỆU KHẨN CẤP SOS ]        │   ← Emergency Button (Luôn hiển thị)
└──────────────────────────────────────────┘
         [Tôi] [Gia đình] [Thiết bị] [Hồ sơ]   ← Bottom Nav
```

---

## Edge Cases
- [x] **Thiết bị không có đồng hồ** → State `No_Device` với hướng dẫn kết nối thiết bị. Không crash, không hiển thị "`--`" trống không.
- [x] **Mở app đúng lúc đang có SOS active** → App Resume Logic kiểm tra sự kiện SOS và redirect đúng màn hình. Dashboard không bao giờ hiển thị trong trường hợp này.
- [x] **Chỉ số từ AI Fall Detection về đột ngột** → Màn hình `EMERGENCY_FallAlert` có Z-Index P0, đè lên Dashboard mà không cần rời tab.
- [x] **Người già vào app lần đầu (chưa đo lần nào)** → Hiển thị Empty State nhẹ nhàng cho từng Card: "Đang đợi dữ liệu từ đồng hồ..." thay vì hiển thị "`0`" hoặc "`--`".
- [x] **Text Scaling 150-200%** → Grid chuyển từ 2x2 sang danh sách dọc (responsive breakpoint). Không dùng fixed aspect ratio.
- [x] **Nút SOS bị bấm nhầm** → Chuyển sang `ManualSOS` (có countdown 5s + Slide-to-cancel). Dashboard KHÔNG gửi SOS trực tiếp.

---

## Data Requirements
- **API Endpoint:**
  - `GET /api/mobile/dashboard/self` → `{ vitals: { hr, spo2, bp_sys, bp_dia, temp, last_updated }, sleep_summary: { duration_min, quality, avg_hr_sleep }, risk_score: { score, level, summary }, device_status: { connected, battery_percent } }`
  - `WS /api/mobile/vitals/stream` → WebSocket stream chỉ số real-time (chỉ kết nối khi tab đang active, màn hình mở).
- **Cache:** Local cache chỉ số cuối cùng cho trạng thái Offline.

---

## Sync Notes
- **KHÔNG còn Profile Switcher** ở màn hình này. Header chỉ hiển thị tên user và nút Thông báo.
- **Tách biệt hoàn toàn** với `HOME_FamilyDashboard`: Dữ liệu bản thân ↔ Dữ liệu người thân không bao giờ trộn lẫn trên cùng một màn hình.
- WebSocket chỉ kết nối cho **Self Profile** ở màn này. `HOME_FamilyDashboard` dùng polling 30s để bảo vệ pin.
- Màn hình này **không** nhận SOS notification của người khác. SOS của người thân chỉ xuất hiện ở `HOME_FamilyDashboard` và FCM pop-up toàn màn hình `EMERGENCY_IncomingSOSAlarm`.
- Shared widgets dùng chung: `LiveVitalCard`, `SleepSummaryBanner`, `RiskScoreBanner`, `EmergencySOSButton`, `DeviceStatusBadge`.

---

## Design Context

- **Target audience**: User xem sức khoẻ của chính mình (người cao tuổi hoặc người tự theo dõi).
- **Usage context**: Routine — màn mặc định mỗi khi mở app.
- **Key UX priority**: Clarity (số to, màu rõ), Calm (không gây hoảng), Speed (WebSocket real-time).
- **Specific constraints**: Người già — font lớn, nút SOS min 56dp; Text Scaling 150-200% → layout responsive; nút SOS có Slide-to-cancel tránh bấm nhầm.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ⬜ Not started | — |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog
| Version | Date       | Author | Changes          |
| ------- | ---------- | ------ | ---------------- |
| v1.0    | 2026-03-16 | AI     | Initial creation — Hybrid Architecture (Self-only, bỏ Profile Switcher) |
| v2.0    | 2026-03-17 | AI     | Regen: bổ sung Design Context, Pipeline Status theo template chuẩn mới |
