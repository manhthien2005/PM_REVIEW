# 📐 UI Plan: EMERGENCY_ManualSOS — Phát SOS Thủ công

## 1. Description

- **SRS Ref**: UC014
- **User Role**: Bệnh nhân / Người dùng (muốn gửi tín hiệu khẩn cấp cho những người theo dõi mình).
- **Purpose**: Cho phép người dùng chủ động kích hoạt báo động khẩn cấp (SOS) một cách nhanh chóng nhưng phải an toàn để tránh bấm nhầm. Hệ thống sau đó sẽ gửi cảnh báo đến tất cả các tài khoản đang có liên kết giám sát với trạng thái "accepted".

## 2. User Flow

1. User bấm vào nút bấm **SOS** bự màu đỏ ở trang chủ (HOME_Dashboard) hoặc phần **Cảnh báo/Khẩn cấp**.
2. Màn hình đếm ngược (Manual SOS) hiện lên với số giây lớn đếm lùi `5... 4... 3...` và thông báo "Đang chuẩn bị gửi tín hiệu khẩn cấp".
3. Lúc này có 2 hành động để User can thiệp:
   - **Gửi ngay**: User gạt thanh trượt (Slide to trigger) hoặc bấm giữ (Hold 3s) nút "GỬI RÕ RÀNG" để bỏ qua đếm lùi và gửi tín hiệu ngay lập tức.
   - **Huỷ báo động**: User đổi ý hoặc ấn nhầm, bấm vào nút "Hủy bỏ" (Màu xám) trong khi đang đếm ngược.
4. Trình tự ngầm (Background):
   - Lấy vị trí GPS hiện tại (Latitude, Longitude).
   - Gọi API `POST /api/mobile/sos/send`. Server tự fetch ra những người có quan hệ với User này để bắn Notification / SMS.
5. Khi API success (hoặc hết đếm ngược), điều hướng tự động sang màn hình **EMERGENCY_LocalSOSActive** để hiển thị chế độ Emergency Mode (Với nút "Tôi đã an toàn").

## 3. UI States

| State               | Description           | Display                                                    |
| ------------------- | --------------------- | ---------------------------------------------------------- |
| **Countdown**       | Đợi chờ 5s đi đếm lùi | Số giây cực lớn ở giữa, biểu tượng cảnh báo rung nhẹ       |
| **Hold Confirm**    | Đang giữ nút gửi      | Vòng tròn Progress lấp đầy chạy 3s                         |
| **Cancelled**       | Bấm huỷ khẩn cấp      | Màn hình out về trang Dashboard cũ                         |
| **Sending/Loading** | Đang call API SOS     | Vòng xoay Loading + "Đang báo động..."                     |
| **Network Loss**    | Mất mạng khi gửi      | Banner vàng "Đang thử kết nối...". Bộ đệm Local cache SOS. |

## 4. Widget Tree (proposed)

- `Scaffold` (Màu Đỏ đô khẩn cấp)
  - `SafeArea`
    - `Column`
      - `AppBar` (Transparent, có nút X để Hủy)
      - `Spacer`
      - `Icon(Icons.warning, size: 80)` (Animated Pulse/Rung)
      - `Text("Sẽ gửi SOS trong:")`
      - `CountdownText` (Custom widget đếm 5 -> 0, size lớn)
      - `Spacer`
      - `SlideAction` (Thanh trượt: "Trượt để GỬI NGAY")
      - `TextButton("Hủy báo động")` (Bản to, chạm dễ)
      - `SizedBox(bottom padding)`

## 4.5. Visual Design Spec

### Colors

| Role          | Token / Value         | Usage in this screen                                 |
| ------------- | --------------------- | ---------------------------------------------------- |
| Background    | `Colors.red.shade900` | Scaffold nền — Báo động nguy hiểm                    |
| Cảnh báo icon | `Colors.white`        | Trắng trên nền Đỏ                                    |
| Hủy nút       | `Colors.white24`      | Nền trắng mờ để tách biệt với báo động               |
| Chữ/Text      | `Colors.white`        | Mọi text đều màu trắng cho tỉ lệ tương phản cao nhất |

### Typography

| Element          | Size  | Weight | Color                        |
| ---------------- | ----- | ------ | ---------------------------- |
| "Sẽ gửi SOS..."  | 24sp  | Bold   | white                        |
| Số giây (5)      | 120sp | Black  | white                        |
| Nút Hủy          | 18sp  | Medium | white                        |
| Dòng thanh trượt | 16sp  | Bold   | red (chìm trong thanh trắng) |

### Spacing

- Căn giữa toàn màn hình `mainAxisAlignment: MainAxisAlignment.center`
- Nút bấm, thanh trượt cách 2 lề `24dp` (để tránh rớt viền)
- Nút bấm tối thiểu cao `64dp` (to hơn quy chuẩn vì người dùng đang hoảng hốt)

## 4.6. Interaction & Animation Spec

| Trigger            | Animation / Behavior                                        | Duration     |
| ------------------ | ----------------------------------------------------------- | ------------ |
| Khởi động màn hình | Nền chuyển dần sang đỏ (Fade in), cảnh báo chóp tắt (Pulse) | 300ms        |
| Bộ đếm Tick        | Chữ số Pop phóng to lên rối thu về (Scale) mỗi giây         | 1000ms       |
| Trượt Slider       | Khóa gạt trượt từ trái sang phải mượt mà                    | Tuỳ tay User |
| Gọi API SOS        | Nhoè màn hình bằng màu đỏ đen đậm, hiện loading xoay        | Liên tục     |

## 4.7. Accessibility Checklist

- [x] Text to: Số đếm ngược đặt kích thước khổng lồ `120sp` để nhìn tự động hiểu ngay.
- [x] Nút điều khiển bự: Nút "Hủy" cùng Slider trigger rất khổ lớn (chiều cao 64dp).
- [x] Tương phản vượt chuẩn `4.5:1` do xài chữ Trắng (`#FFFFFF`) trên Đỏ Đậm (`#B71C1C`).
- [x] Semantic Lables dãn nhãn cho TalkBack, hỗ trợ đọc: "Còn 3 giây, 2 giây để hủy..."

## 4.8. Design Rationale

| Decision                                         | Reason                                                                                     |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| Màu nền đỏ rực `red.shade900`                    | Gây sốc và cảnh tỉnh ngay lập tức khi vô tình ấn nhầm, khẩn cấp khi đúng mục đích.         |
| Time chờ `5` giây                                | Vừa đủ để phản ứng nếu ấn nhầm SOS trên tab bar, nhưng cũng đủ nhanh để cấp cứu kịp thời.  |
| Sử dụng _Slide/Trượt_ thay vì Nút Bấm "Gửi ngay" | Slide-to-confirm là hình thức chống thao tác nhầm vô thức (accidental taps) hiệu quả nhất. |

## 5. Edge Cases Handled

- [x] **Trường hợp Offline / Mất mạng:** App vẫn tự động ghi log `Manual SOS triggered`, lưu vào cache SQL cục bộ, hiển thị Banner "Đang chờ kết nối gửi tín hiệu" và auto-retry 30s/lần khi mạng quay lại.
- [x] **Hết giờ đếm ngược:** Sẽ tự trigger API Call mà không chờ vuốt slider.
- [x] **Background App lúc đếm giờ:** Lỡ gập app vô tình, khi bật lên nếu thời gian quá 5s tự trigger SOS luôn (ưu tiên sinh mạng). Nếu vào lại mà còn thời gian, tiếp tục đếm.

## 6. Dependencies

- Package: `slide_to_act` hoặc tự custom Widget `Dismissible` cho thanh trượt "Trượt để gửi ngay".
- API: `POST /api/v1/mobile/emergency/sos`
- Hardware: Lệnh `Geolocator` để bắt vĩ độ/kinh độ trước khi gửi API.

## 7. Confidence Score

- **Plan Confidence: 95%**
- Thiết kế bao quát đầy đủ logic chặn "nhấn nhầm" và cả tính bức thiết của quy trình khẩn cấp. Phù hợp 100% với luồng BE được cập nhật là phát cho mọi Target relationship.
