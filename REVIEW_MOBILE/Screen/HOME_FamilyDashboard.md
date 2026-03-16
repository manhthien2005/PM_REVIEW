# 📱 HOME — Bảng theo dõi Gia đình (Family Dashboard)

> **UC Ref**: UC006, UC015, UC030
> **Module**: HOME
> **Status**: ⬜ Draft

## Purpose
Tab thứ 2 của thanh điều hướng chính (Bottom Navigation Bar). Hiển thị **cái nhìn tổng quan bird's-eye view** về tình trạng sức khoẻ của tất cả người thân được liên kết mà user đang có quyền xem (`can_view_vitals = true`). Khác với "Sức khoẻ của tôi" (chỉ xem bản thân), tab này là **trung tâm giám sát đa người** — dành cho vai trò người chăm sóc hoặc thành viên gia đình lo lắng về người thân.

---

## Navigation Links (🔗 Màn hình Liên quan)
| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| `HOME_Dashboard` (Tab "Sức khoẻ của tôi") | Bấm tab "Gia đình" ở Bottom Nav | → This screen |
| This screen | Bấm vào Card của người thân → Chỉ số | → [MONITORING_VitalDetail](./MONITORING_VitalDetail.md) (kèm `profileId`) |
| This screen | Bấm vào Card của người thân → Giấc ngủ | → [SLEEP_Report](./SLEEP_Report.md) (kèm `profileId`) |
| This screen | Bấm SOS Badge đỏ trên Card | → [EMERGENCY_SOSReceivedDetail](./EMERGENCY_SOSReceivedDetail.md) |
| This screen | Bấm "Thêm người thân" (Empty State) | → [PROFILE_ContactList](./PROFILE_ContactList.md) |
| This screen | Bấm nút "Quản lý quyền theo dõi" | → [PROFILE_ContactList](./PROFILE_ContactList.md) |

---

## User Flow
1. User bấm vào tab **"Gia đình"** ở Bottom Navigation Bar.
2. App gọi `GET /api/mobile/family-dashboard` — trả về danh sách các Profile liên kết có `can_view_vitals = true`, kèm snapshot chỉ số sinh tồn mới nhất.
3. Mỗi người thân hiển thị dưới dạng **Card dọc** (Full-width) theo thứ tự tuỳ chỉnh:
   - Ảnh đại diện + Tên hiển thị + Nhãn dán (VD: "Bố", "Mẹ", "Ông nội").
   - 3-4 chỉ số sức khoẻ quan trọng nhất (Nhịp tim, SpO₂, Huyết áp, Nhiệt độ) — số to, rõ ràng.
   - Thời điểm cập nhật lần cuối ("Vừa xong", "3 phút trước").
   - **Badge SOS đỏ** nổi góc phải nếu người này đang có SOS active.
4. App tự động **polling mỗi 30 giây** để làm mới chỉ số. Không dùng WebSocket liên tục (tiết kiệm pin).
5. Khi có SOS mới của người thân → FCM đẩy về, App cập nhật badge trực tiếp mà không cần đợi polling.
6. User bấm vào bất kỳ chỉ số nào trên Card → Drill-down sang màn `VitalDetail` của người đó với `profileId` được truyền qua.
7. User bấm SOS Badge → Mở thẳng `SOSReceivedDetail` (War Room) của sự kiện khẩn cấp đang diễn ra.

---

## UI States
| Trạng thái | Điều kiện | Hiển thị |
| --- | --- | --- |
| **Loading** | Đang tải lần đầu | Skeleton loading placeholder cho từng Card. |
| **Success_Normal** | Có người thân, không có SOS | Danh sách Card xanh/xám. Thông tin chỉ số cập nhật. |
| **Success_SOS_Active** | Có người thân đang cấp cứu | Card của người đó đổi nền đỏ nhấp nháy nhẹ. Badge SOS đỏ nổi bật ở góc. Nút "XEM NGAY" to hiện lên phía trên danh sách. |
| **Empty** | User chưa có người thân liên kết nào có `can_view_vitals = true` | Minh hoạ (Illustration) nhỏ + text "Chưa có ai để theo dõi" + Nút lớn "Liên kết người thân ngay". |
| **Perm_Denied** | Có người liên kết nhưng chưa bật quyền `can_view_vitals` | Card hiển thị nhưng chỉ số bị che "`---`" + Badge khoá nhỏ. Tap → Popup hướng dẫn nhờ người thân bật quyền. |
| **Error** | Lỗi mạng khi load | Snackbar lỗi + Nút "Thử lại". Dữ liệu cũ (nếu có cache) vẫn hiển thị với dòng chữ nhỏ "Dữ liệu lần cuối lúc HH:mm". |
| **Offline** | Mất kết nối internet | Banner vàng "Đang offline — Hiển thị dữ liệu đã lưu từ HH:mm". |

---

## Layout Card (Từng người thân)
```
┌─────────────────────────────────────────┐
│ 🔴 [SOS Badge]     [Avatar] Bố - Nguyễn Văn A  │
│ ─────────────────────────────────────── │
│  ❤️ Nhịp tim    💧 SpO₂    🩸 Huyết áp  │
│    82 BPM        97%       120/80        │
│    Bình thường   Tốt       Theo dõi      │
│ ─────────────────────────────────────── │
│  🌡️ Nhiệt độ    😴 Giấc ngủ hôm qua     │
│    36.5°C        6h12m - Trung bình      │
│ ─────────────────────────────────────── │
│  🕐 Cập nhật: 2 phút trước   [Xem chi tiết →] │
└─────────────────────────────────────────┘
```

---

## Edge Cases
- [x] **Không có kết nối WebSocket liên tục** → Dùng polling 30s để bảo vệ pin thiết bị. FCM đảm nhận thông báo khẩn cấp real-time.
- [x] **Nhiều người thân cùng SOS cùng lúc** → Hiển thị tất cả Card SOS lên đầu danh sách (ưu tiên). Banner "⚠️ 2 người đang cần trợ giúp" ở top screen.
- [x] **Người thân tắt quyền xem trong khi app đang mở** → Lần polling tiếp theo sẽ cập nhật Card sang trạng thái `Perm_Denied`. Không hiển thị lỗi đột ngột.
- [x] **Người già bật Text Scaling 150%** → Card dùng `wrap` layout thay vì hàng cố định, chỉ số tự xuống dòng thay vì tràn.
- [x] **Chỉ số sinh tồn ngoài vùng giá trị hợp lệ (VD: HR=0, bộ cảm biến rời ra)** → Hiển thị `"--"` + icon cảnh báo nhỏ cam "Không đo được — Kiểm tra thiết bị".
- [x] **User vào tab khi chưa có người thân nào (mới đăng ký)** → Empty State với hướng dẫn rõ ràng 2 bước: Bấm "Liên kết" → QR code.

---

## Data Requirements
- **API Endpoint:**
  - `GET /api/mobile/family-dashboard` → Trả về `[{ profile_id, display_name, avatar_url, label, latest_vitals: { hr, spo2, bp_sys, bp_dia, temp }, sleep_summary: { duration_min, quality }, last_updated, active_sos_id? }]`
  - `GET /api/mobile/access-profiles` → Dùng để biết danh sách cần hiển thị (reuse từ Profile logic cũ).
- **Polling:** 30 giây/lần khi tab đang active. Dừng polling khi tab ẩn (AppLifecycleState.paused).
- **FCM Topic:** `user_{userId}_sos_alerts` → Nhận badge SOS mà không cần chờ polling.

---

## Sync Notes
- **Không dùng Global Profile Switcher** ở màn này. Mỗi Card đại diện một người, không có khái niệm "đang xem hồ sơ của ai".
- Khi drill-down sang `VitalDetail` hoặc `SleepReport`, truyền `profileId` qua Route argument. Màn đó tự render dữ liệu của đúng người.
- Shared widgets dùng chung: `FamilyProfileCard`, `SOSActiveBadge`, `VitalMiniChip`, `OfflineBanner`.
- Thứ tự sắp xếp Card: SOS active → Trạng thái cần theo dõi → Bình thường. Cho phép user kéo thả để đổi thứ tự ưu tiên.
- Nếu `active_sos_id` có giá trị → Nút "XEM NGAY" trỏ thẳng đến `EMERGENCY_SOSReceivedDetail` với `sosId` đó.

---

## Design Context

- **Target audience**: User theo dõi người thân (người chăm sóc, thành viên gia đình) — có quyền `can_view_vitals` với linked profiles.
- **Usage context**: Routine monitoring — bird's-eye view đa người.
- **Key UX priority**: Clarity (card rõ từng người), Speed (polling 30s + FCM SOS real-time), Calm (SOS badge không gây hoảng).
- **Specific constraints**: Polling thay WebSocket để tiết kiệm pin; SOS badge đỏ nổi bật; drill-down truyền `profileId`; Text Scaling 150% → layout wrap.

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
| v1.0    | 2026-03-16 | AI     | Initial creation — Hybrid Architecture (tách khỏi Profile Switcher) |
| v2.0    | 2026-03-17 | AI     | Regen: bổ sung Design Context, Pipeline Status theo template chuẩn mới |
