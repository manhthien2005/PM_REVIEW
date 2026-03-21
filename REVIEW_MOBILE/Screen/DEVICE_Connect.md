# 📱 DEVICE — Kết nối thiết bị mới

> **UC Ref**: UC040
> **Module**: DEVICE
> **Status**: ⬜ Spec only (health_system đang dùng dialog kỹ thuật tạm thời)

## Purpose

Ghép cặp thiết bị IoT với **chính tài khoản của người dùng** bằng cách **quét QR hoặc nhập mã thiết bị / serial**. Màn hình này phải thật đơn giản cho người lớn tuổi, đồng thời vẫn hỗ trợ trường hợp có người thân biết công nghệ đứng cạnh hỗ trợ thao tác.

> **Quan trọng**:
> - Đây là luồng **self-only**.
> - Không cho phép người dùng ở tab Gia đình tự bind thiết bị thay cho linked profile từ xa.
> - `health_system` hiện có dialog nhập nhiều trường kỹ thuật; đó là giải pháp tạm, **không phải UX đích**.

---

## Navigation Links (🔗 Màn hình Liên quan)

| Từ màn hình | Thao tác | Đến màn hình |
| --- | --- | --- |
| [DEVICE_List](./DEVICE_List.md) | Bấm CTA/FAB "Thêm thiết bị" | → This screen |
| [HOME_Dashboard](./HOME_Dashboard.md) | No-device state → CTA "Kết nối thiết bị" | → This screen |
| This screen | Kết nối thành công | → [DEVICE_List](./DEVICE_List.md) |
| This screen | Hủy / Back | → [DEVICE_List](./DEVICE_List.md) |

---

## User Flow

1. User mở màn **Kết nối thiết bị mới**.
2. Hệ thống hiển thị 2 cách rõ ràng:
   - **Quét QR trên hộp / thiết bị**
   - **Nhập mã thiết bị thủ công**
3. Nếu user chọn quét QR:
   - Xin quyền camera.
   - Mở khung scan với hướng dẫn lớn, dễ hiểu.
4. Nếu user chọn nhập tay:
   - Hiển thị 1 ô nhập mã/serial duy nhất, có ví dụ minh hoạ.
5. Hệ thống verify mã thiết bị:
   - Thiết bị có tồn tại?
   - Có đang bị khoá?
   - Có đang thuộc user khác?
6. Nếu hợp lệ:
   - Hiển thị màn confirm ngắn: tên thiết bị nhận diện được, loại thiết bị, nút **"Kết nối ngay"**.
7. Kết nối thành công:
   - Toast/snackbar + điều hướng về `DEVICE_List`, item mới xuất hiện ở đầu danh sách.
8. Nếu thất bại:
   - Giải thích ngắn gọn bằng ngôn ngữ đời thường và cho phép thử lại/chuyển sang cách còn lại.

---

## UI States

| State | Description | Display |
| --- | --- | --- |
| MethodSelect | Chưa chọn cách kết nối | 2 card lớn: Quét QR / Nhập mã |
| CameraPermission | Chưa có quyền camera | Explainer + nút "Cho phép camera" + fallback nhập mã |
| Scanning | Đang quét QR | Camera preview + khung scan + hướng dẫn chữ lớn |
| ManualEntry | Nhập mã tay | 1 ô nhập chính + ví dụ + nút verify |
| Verifying | Đang kiểm tra mã thiết bị | Progress state, disable thao tác |
| Confirm | Đã nhận diện được thiết bị | Tên thiết bị + loại + nút "Kết nối ngay" |
| Success | Bind thành công | Checkmark + tự điều hướng về List |
| DeviceInvalid | Mã sai / thiết bị không tồn tại / bị khoá | Message rõ + thử lại |
| DeviceOwned | Thiết bị đang thuộc user khác | Message rõ + hướng hỗ trợ / chuyển quyền nếu policy cho phép |
| Error | Lỗi mạng / server | Inline error + Retry |

---

## Edge Cases

- [x] User từ 60+ tuổi không quen QR → luôn có fallback nhập mã thủ công.
- [x] Camera permission bị từ chối → không chặn luồng, chuyển ngay sang nhập mã.
- [x] QR quét mãi không ăn → có nút "Nhập mã thay thế".
- [x] Mã sai 1 ký tự → hiển thị lỗi dễ hiểu, không dump lỗi kỹ thuật.
- [x] Thiết bị bị khoá / không hợp lệ → thông báo "Thiết bị không hợp lệ hoặc đã bị khoá. Vui lòng liên hệ hỗ trợ."
- [x] Thiết bị đang thuộc tài khoản khác → hướng dẫn rõ quy trình chuyển quyền nếu hệ thống cho phép.
- [x] Mất mạng giữa lúc verify → giữ lại mã vừa nhập, không bắt user nhập lại.
- [x] User bấm back khi đã nhập mã nhưng chưa bind → confirm nhẹ "Bạn chưa kết nối thiết bị, thoát chứ?"
- [x] Nếu app bị mở trong linked/family context → chặn và giải thích "Thiết bị chỉ có thể được kết nối cho tài khoản của chính bạn".

---

## Data Requirements

- **API contract cần chốt trước khi build**:
  - Theo UC040: nên có endpoint kiểu `POST /api/mobile/devices/bind` hoặc `.../register` với `deviceCode` / `serial` / `qrToken`.
  - `health_system` hiện đang dùng `POST /api/mobile/devices` với form kỹ thuật nhiều trường, không đúng UX đích.
- **Input canonical**:
  - `deviceCode` hoặc `serialNumber` hoặc `qrToken`
  - Optional: `displayName` nếu muốn cho phép đặt tên sau khi nhận diện
- **Output**:
  - `device: { id, name, type, isOnline, ... }`
  - lỗi nghiệp vụ: `DEVICE_INVALID`, `DEVICE_LOCKED`, `DEVICE_ALREADY_ASSIGNED`

---

## Sync Notes

- Sau khi connect thành công → `DEVICE_List` phải refresh hoặc optimistic insert item mới.
- Nếu user vào từ `HOME_Dashboard` no-device state → sau success điều hướng về `DEVICE_List`, không cần quay lại dashboard trước.
- Shared components nên có: `ConnectionMethodCard`, `QrScanFrame`, `ManualCodeField`, `DeviceOwnershipErrorCard`.
- Nếu backend vẫn chưa có QR flow, có thể giữ dialog manual làm **fallback tạm thời**, nhưng plan build chuẩn vẫn phải ưu tiên QR/manual-code-first.

---

## Design Context

- **Target audience**: Người lớn tuổi tự kết nối thiết bị của mình; người thân biết công nghệ có thể hỗ trợ trực tiếp khi ở cạnh.
- **Usage context**: One-time setup hoặc thay thiết bị mới.
- **Key UX priority**: Clarity > Confidence > Speed.
- **Specific constraints**:
  - 1 bước = 1 quyết định rõ ràng.
  - Không bắt nhập nhiều field kỹ thuật ngay từ đầu.
  - Touch target >= 48dp.
  - Text hướng dẫn phải rất ngắn, tiếng Việt đời thường.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `./build-plan/DEVICE_Connect_plan.md` |
| BUILD | ⬜ Not started | — |
| REVIEW | ⬜ Not started | — |

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-17 | AI | Initial creation |
| v2.0 | 2026-03-17 | AI | Regen: full template với UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog |
| v2.1 | 2026-03-18 | AI | Chuyển spec từ BLE/technical form sang QR/manual code theo UC040, thêm self-only guard và luồng hỗ trợ người lớn tuổi |
| v2.2 | 2026-03-18 | AI | Liên kết PLAN đã tạo: `build-plan/DEVICE_Connect_plan.md` |

---

## Implementation Reference (health_system)

- Chưa có màn riêng.
- Hiện tại `DeviceScreen._showAddDeviceDialog()` dùng dialog nhập:
  - tên thiết bị,
  - loại,
  - model,
  - firmware,
  - MAC,
  - serial,
  - MQTT Client ID.
- Đây là fallback kỹ thuật / admin-assisted, cần được thay bằng flow QR/manual code đơn giản hơn khi build chuẩn.
