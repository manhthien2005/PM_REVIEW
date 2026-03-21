# 🧩 HOME_Dashboard — Wireframe Markdown

> **Screen**: `HOME_Dashboard`
> **Purpose**: Low-fi wireframe để dev và designer nhìn nhanh bố cục, ưu tiên thông tin và các state chính
> **Companion docs**:
> - `HOME_Dashboard.md`
> - `HOME_Dashboard_plan.md`
> - `HOME_Dashboard_flutter_widget_tree.md`

---

## 1. Wireframe mục tiêu

### Normal State

```text
┌─────────────────────────────────────────────┐
│ SafeArea Top                                │
├─────────────────────────────────────────────┤
│ [Avatar] Chào Minh Thiện        [🔔 • ]     │
│ Cập nhật sức khoẻ mới nhất lúc 08:42        │
├─────────────────────────────────────────────┤
│ Hôm nay bạn đang ổn                         │
│ [Ổn định] Các chỉ số hiện trong ngưỡng an toàn │
│ [Xem lịch sử chỉ số →]                      │
├─────────────────────────────────────────────┤
│ [⌚ Đồng hồ đang kết nối]    [Pin 82%]       │
├─────────────────────────────────────────────┤
│ Chỉ số hôm nay                              │
│ ┌───────────────┐ ┌───────────────┐         │
│ │ ❤️ Nhịp tim   │ │ 💧 SpO₂       │         │
│ │ 82 BPM        │ │ 97%           │         │
│ │ Bình thường   │ │ Tốt           │         │
│ └───────────────┘ └───────────────┘         │
│ ┌───────────────┐ ┌───────────────┐         │
│ │ 🩸 Huyết áp    │ │ 🌡️ Nhiệt độ    │         │
│ │ 120/80        │ │ 36.5°C        │         │
│ │ Theo dõi      │ │ Tốt           │         │
│ └───────────────┘ └───────────────┘         │
├─────────────────────────────────────────────┤
│ 😴 Giấc ngủ đêm qua                         │
│ 7h20 ngủ • Chất lượng tốt                   │
│ Nhịp tim khi ngủ: 58 BPM                    │
│                           [Xem chi tiết →]  │
├─────────────────────────────────────────────┤
│ 🤖 Điểm rủi ro AI                           │
│ [32/100] Thấp                               │
│ Không có nguy cơ đáng lo ngại               │
│                           [Xem báo cáo →]   │
├─────────────────────────────────────────────┤
│ [ 🆘 GỬI TÍN HIỆU KHẨN CẤP SOS ]            │
├─────────────────────────────────────────────┤
│ [Tôi*] [Gia đình] [Thiết bị] [Hồ sơ]        │
│ SafeArea Bottom                             │
└─────────────────────────────────────────────┘
```

### Ý đồ

- Hero card là điểm nhìn đầu tiên.
- Strip thiết bị trả lời câu hỏi "dữ liệu có đang đáng tin không?".
- Vitals là khối lớn nhất vì đây là thông tin thao tác thường xuyên nhất.
- Sleep và Risk là 2 insight cards ngang vai, không cạnh tranh với hero.
- SOS luôn thấy ở cuối viewport, tách biệt khỏi nội dung.

---

## 2. Wireframe theo state

### 2.1 Loading

```text
┌─────────────────────────────────────────────┐
│ [avatar skeleton]   [icon skeleton]         │
│ [text skeleton]                              │
├─────────────────────────────────────────────┤
│ [hero skeleton 2 lines]                     │
├─────────────────────────────────────────────┤
│ [status strip skeleton]                     │
├─────────────────────────────────────────────┤
│ [2x2 card skeleton grid]                    │
├─────────────────────────────────────────────┤
│ [sleep card skeleton]                       │
├─────────────────────────────────────────────┤
│ [risk card skeleton]                        │
├─────────────────────────────────────────────┤
│ [sos bar fixed]                             │
├─────────────────────────────────────────────┤
│ [bottom nav visible, active tab stable]     │
└─────────────────────────────────────────────┘
```

### Rule

- `Bottom Navigation` và `EmergencyStickyBar` không đổi vị trí khi loading.
- Không để layout nhảy khi dữ liệu về.

### 2.2 Success_Warning

```text
┌─────────────────────────────────────────────┐
│ Chào Minh Thiện                  [🔔]       │
│ Cập nhật lúc 08:42                           │
├─────────────────────────────────────────────┤
│ Hôm nay cần chú ý                           │
│ [Cần theo dõi] Một vài chỉ số cần theo dõi  │
├─────────────────────────────────────────────┤
│ ⚠️ Một số chỉ số cần chú ý                   │
├─────────────────────────────────────────────┤
│ Card HR bình thường | Card SpO₂ viền cam    │
│ Card BP viền cam    | Card Temp bình thường │
├─────────────────────────────────────────────┤
│ Sleep card                                    │
├─────────────────────────────────────────────┤
│ Risk card                                      │
├─────────────────────────────────────────────┤
│ SOS bar                                         │
└─────────────────────────────────────────────┘
```

### Rule

- Chỉ những card bất thường mới đổi accent.
- Không biến toàn màn thành vàng/cam.

### 2.3 Success_Critical

```text
┌─────────────────────────────────────────────┐
│ Chào Minh Thiện                  [🔔]       │
│ Cập nhật lúc 08:42                           │
├─────────────────────────────────────────────┤
│ Hôm nay cần xử lý sớm                       │
│ [Nguy cơ cao] Có chỉ số bất thường           │
│ [Gọi trợ giúp ngay]                          │
├─────────────────────────────────────────────┤
│ Card critical nền đỏ nhạt                    │
│ Card còn lại giữ trung tính                  │
├─────────────────────────────────────────────┤
│ Sleep / Risk vẫn hiển thị, không biến mất    │
├─────────────────────────────────────────────┤
│ [ 🆘 GỬI TÍN HIỆU KHẨN CẤP SOS ]            │
└─────────────────────────────────────────────┘
```

### Rule

- Cảnh báo phải rõ hơn warning.
- Không dùng nền đỏ đậm toàn màn vì dễ gây hoảng.

### 2.4 No_Device

```text
┌─────────────────────────────────────────────┐
│ Chào Minh Thiện                  [🔔]       │
├─────────────────────────────────────────────┤
│ Chưa có dữ liệu sức khoẻ trực tiếp          │
│ [Kết nối đồng hồ để bắt đầu theo dõi]       │
│ [Kết nối thiết bị]                           │
├─────────────────────────────────────────────┤
│ [⌚ Chưa kết nối đồng hồ]                    │
├─────────────────────────────────────────────┤
│ Card onboarding / card hướng dẫn nhẹ         │
│ Không render số giả `0` hoặc `--` khô cứng   │
├─────────────────────────────────────────────┤
│ Sleep / Risk có thể ẩn hoặc chuyển empty     │
├─────────────────────────────────────────────┤
│ SOS bar                                      │
└─────────────────────────────────────────────┘
```

### 2.5 Offline / Device_Offline

```text
┌─────────────────────────────────────────────┐
│ Chào Minh Thiện                  [🔔]       │
├─────────────────────────────────────────────┤
│ Đang offline — hiển thị dữ liệu đã lưu      │
├─────────────────────────────────────────────┤
│ [⌚ Đồng hồ offline] [Dữ liệu lúc 08:10]     │
├─────────────────────────────────────────────┤
│ Các vital card vẫn hiện cache + timestamp    │
├─────────────────────────────────────────────┤
│ Sleep / Risk dùng snapshot cuối              │
├─────────────────────────────────────────────┤
│ SOS bar                                      │
└─────────────────────────────────────────────┘
```

### 2.6 Error

```text
┌─────────────────────────────────────────────┐
│ Chào Minh Thiện                  [🔔]       │
├─────────────────────────────────────────────┤
│ Không thể tải dữ liệu sức khoẻ lúc này      │
│ [Thử lại]                                    │
├─────────────────────────────────────────────┤
│ Nếu có cache: tiếp tục hiện content cũ       │
│ Nếu không có cache: empty error state         │
├─────────────────────────────────────────────┤
│ SOS bar                                      │
└─────────────────────────────────────────────┘
```

---

## 3. Bottom Navigation Wireframe

### Default

```text
┌─────────────────────────────────────────────┐
│  [ pill active ]                            │
│  🏠 Tôi   👨‍👩‍👧 Gia đình   ⌚ Thiết bị   👤 Hồ sơ │
│  Tôi*      Gia đình      Thiết bị      Hồ sơ │
└─────────────────────────────────────────────┘
```

### Với badge cảnh báo

```text
┌─────────────────────────────────────────────┐
│  🏠 Tôi   👨‍👩‍👧• Gia đình   ⌚• Thiết bị   👤 Hồ sơ │
│  Tôi*      Gia đình        Thiết bị      Hồ sơ │
└─────────────────────────────────────────────┘
```

### Rules

- Label luôn hiển thị, kể cả inactive.
- Indicator active là pill nhẹ, không cần animation nhảy mạnh.
- Badge chỉ là dấu chấm nhỏ hoặc chấm đỏ có semantics, không phình to như notification badge web.

---

## 4. Responsive Notes

### Text scaling 150-200%

```text
┌─────────────────────────────────────────────┐
│ Header                                      │
├─────────────────────────────────────────────┤
│ Hero                                        │
├─────────────────────────────────────────────┤
│ Status strip                                │
├─────────────────────────────────────────────┤
│ ❤️ Nhịp tim                                 │
│ 82 BPM                                      │
│ Bình thường                                 │
├─────────────────────────────────────────────┤
│ 💧 SpO₂                                     │
│ 97%                                         │
│ Tốt                                         │
├─────────────────────────────────────────────┤
│ ... các card thành list dọc ...             │
└─────────────────────────────────────────────┘
```

### Rule

- `LiveVitalsSection` bỏ grid khi text scale lớn.
- `Bottom Navigation` giữ 4 tab, ưu tiên spacing linh hoạt thay vì cắt label.

---

## 5. Checklist đọc wireframe

- [ ] Hero có phải điểm nhìn đầu tiên không?
- [ ] User có hiểu được trạng thái trong 3-5 giây không?
- [ ] Strip kết nối có đủ nổi để người dùng hiểu dữ liệu còn mới hay không?
- [ ] SOS có đủ dễ chạm nhưng không phá mood của dashboard không?
- [ ] Bottom nav có đủ rõ để dùng làm shared shell cho các tab khác không?
