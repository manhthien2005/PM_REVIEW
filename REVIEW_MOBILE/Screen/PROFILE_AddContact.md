# 📱 PROFILE — Thêm Liên hệ mới (Add Contact)

> **UC Ref**: UC005
> **Module**: PROFILE
> **Status**: 🔄 In Progress

## Purpose
Cho phép người dùng thêm liên hệ mới bằng cách quét QR Code (người trẻ thao tác) hoặc đưa mã QR khổng lồ tĩnh 6 số của mình lên để người khác quét (người già thụ động). Chỉnh lại flow: Gắn thẻ/nhãn dán ngay sau khi quét.

## Navigation Links (🔗 Related Screens)
| From Screen                           | Action            | To Screen                                               |
| ------------------------------------- | ----------------- | ------------------------------------------------------- |
| [PROFILE_ContactList](./PROFILE_ContactList.md) | Thêm (+) | → This screen                                           |
| This screen                           | Gửi lời mời xong  | → [PROFILE_ContactList](./PROFILE_ContactList.md) + Toast "Thành công" |
| This screen                           | Back              | → [PROFILE_ContactList](./PROFILE_ContactList.md)       |

## User Flow
1. Bấm [+] mở màn hình.
2. Màn hình chia 2 Tab Bar:
   - **Tab Quét Mã**: Mở Camera, quét QR người khác -> Popup hỏi "Người này là ai?" -> Chọn Nhãn -> Bấm Gửi lời mời.
   - **Tab Mã Của Tôi**: Hiện mã QR lớn + số PIN 6 số siêu to (để người già cho con cháu tự thao tác trên máy mình). Có nút Share (Zalo/SMS).
3. Đợi người kia Accept.

## UI States
| State   | Description | Display |
| ------- | ----------- | ------- |
| Perm_Denied | Chưa cấp quyền Camera | Cảnh báo yêu cầu quyền + Nút Cấp Quyền |
| Scanning | Đang View Camera | Fullscreen camera view vuông + Overlay frame mờ |
| Success_Scanned | Bắt được QR Code hợp lệ | Dừng camera, Popup BottomSheet hiện lên với Thông tin User vừa quét + Dropdown/Chips chọn Group Label -> Button: Send Request |
| Error_Scanned | Mã QR giả/Sai cấu trúc | Rung thiết bị + SnackBar màu cam cảnh báo |
| My_Code | Tab 2 đang xem mã | Mã QR lớn (200x200), mã số 6 chữ số cỡ 48sp, dòng chú thích "Mã có hiệu lực đến 23:59 hôm nay", button Share |

## Edge Cases
- [x] Quét trúng QR không phải của app HealthGuard.
- [x] Quét lại QR của chính mình (Check ID User hiện tại != ID QR code).
- [x] Sử dụng trong bóng tối (Nút bật Flashlight ở góc camera).
- [x] PIN hết hạn -> `POST /api/mobile/contacts/request` trả về `410 GONE` -> SnackBar "Mã QR đã hết hạn, yêu cầu người kia làm mới mã."

## Data Requirements
- API endpoint: 
  - `GET /api/mobile/user/my-code` (Generate/Lấy mã của mình)
  - `POST /api/mobile/contacts/request`
- Input: `{ "target_user_id": "...", "label": "FAMILY" }`
- Output: `{ "status": "pending_approval" }`

## Sync Notes

- **PIN 24h expiry**: PIN 6 số rotate mỗi 24 giờ (server-side). API `GET /api/mobile/user/my-code` trả về `{ code, pin_6, expires_at }`. Mã có hiệu lực đến 23:59 ngày hiện tại.
- Phụ thuộc hệ thống cấp quyền Flutter (`permission_handler`).
- Sử dụng package `mobile_scanner`, `qr_flutter`.
- **Architecture**: Linked Profiles — gửi lời mời kết nối; không dùng patient/caregiver.

---

## Design Context

- **Target audience**: User — thêm Linked Profile (QR cho người già thụ động, quét cho người trẻ chủ động).
- **Usage context**: Setup — kết nối người thân.
- **Key UX priority**: Clarity (mã 6 số to 48sp), Trust (PIN hết hạn rõ).
- **Specific constraints**: Mã QR lớn 200x200; nút Share; flashlight trong bóng tối.

---

## Pipeline Status

| Stage | Status | File |
| --- | --- | --- |
| TASK | ✅ Done | This file |
| PLAN | ✅ Done | `build-plan/PROFILE_AddContact_plan.md` |
| BUILD | 🔄 In Progress | — |
| REVIEW | ⬜ Not started | — |

### Companion Docs

- `build-plan/PROFILE_AddContact_plan.md`

---

## Changelog
| Version | Date       | Author  | Changes          |
| ------- | ---------- | ------- | ---------------- |
| v1.0    | 2026-03-16 | AI      | Initial creation |
| v2.0    | 2026-03-17 | AI      | Regen: Design Context, Pipeline Status, architecture (Linked Profiles) |
| v2.1    | 2026-03-18 | AI      | Added detailed build plan `build-plan/PROFILE_AddContact_plan.md`, chuẩn hoá 2-mode QR/PIN flow và đồng bộ style với `DEVICE_Connect` |
