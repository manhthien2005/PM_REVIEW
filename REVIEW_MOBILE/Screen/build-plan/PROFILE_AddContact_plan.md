# 📐 UI Plan: PROFILE_AddContact Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [PROFILE_AddContact.md](../PROFILE_AddContact.md)  
> **Visual Parent**: `DEVICE_Connect`, `HOME_Dashboard`  
> **Refactor Goal**: Tạo flow thêm liên hệ mới vừa **dễ thao tác cho người trẻ**, vừa **thân thiện với người lớn tuổi** bằng mô hình `Scan code / My code`.

---

## 1. Description

- **SRS Ref**: UC005
- **User Role**: User (self)
- **Purpose**: Gửi yêu cầu liên kết bằng QR/PIN theo hướng:
  - người trẻ chủ động quét,
  - người lớn tuổi chỉ cần mở mã của mình cho người khác quét.

### 1.1. Problem Statement

Màn thêm liên hệ rất dễ bị làm thành màn kỹ thuật. Với nhóm user lớn tuổi:
- nếu camera/scan là flow duy nhất, UX sẽ khó,
- nếu code/PIN không đủ lớn và đủ rõ, người già sẽ không dùng được,
- nếu chưa giải thích QR/PIN dùng để làm gì, user sẽ thiếu tin tưởng.

### 1.2. Design Goal

- **2 mode rất rõ**
- **Scan dễ cho người trẻ**
- **My Code đủ to cho người già**
- **giống triết lý `DEVICE_Connect`: onboarding dịu, không kỹ thuật**

---

## 2. User Flow

### 2.1. Entry Flow

1. User từ `PROFILE_ContactList` bấm `Thêm liên hệ`.
2. App mở screen có segmented tab:
   - `Quét mã`
   - `Mã của tôi`

### 2.2. Scan Flow

1. User chọn tab `Quét mã`.
2. Nếu chưa có quyền camera:
   - hiển thị explanation card + CTA cấp quyền.
3. Khi camera mở:
   - hiển thị scanner frame rõ.
4. Quét thành công:
   - dừng camera,
   - mở `ScannedUserConfirmSheet`.
5. User chọn label.
6. Bấm `Gửi lời mời`.
7. Toast success và quay lại `PROFILE_ContactList`.

### 2.3. My Code Flow

1. User chọn tab `Mã của tôi`.
2. Hiển thị:
   - QR code lớn,
   - PIN 6 số rất to,
   - thời gian hết hạn,
   - nút `Chia sẻ`.
3. User chỉ cần đưa màn cho người còn lại quét hoặc chia sẻ mã.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Tôi đang ở chế độ nào: quét hay đưa mã?
2. Nếu quét: camera đã sẵn sàng chưa?
3. Nếu mã của tôi: QR và PIN ở đâu?
4. Mã này còn hiệu lực tới khi nào?

### Điều phải tránh

- Không để 2 tab có trọng số bằng nhau nhưng nội dung quá khó đọc
- Không hiển thị quá nhiều text kỹ thuật
- Không làm QR/PIN nhỏ như một phụ kiện

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| Initial | Vừa vào màn | Segmented mode switch + intro text |
| Perm_Denied | Chưa cấp camera | Permission explanation card + CTA |
| Scanning | Camera active | Scanner frame + flashlight + help text |
| Success_Scanned | Quét hợp lệ | Confirm bottom sheet |
| Error_Scanned | QR sai / hết hạn / là mã của mình | Warning snackbar + keep scanning |
| My_Code | Hiển thị mã của tôi | QR lớn + PIN lớn + expiry + share |
| Loading_MyCode | Đang fetch mã | Skeleton / placeholder |
| Error | Không lấy được mã của tôi | Retry block |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar(title: "Thêm liên hệ")
└─ Body
   └─ Column
      ├─ AddContactIntroCard
      ├─ ModeSegmentedControl
      └─ Expanded
         ├─ [Scan] ScanModeView
         │  ├─ CameraPermissionCard (optional)
         │  ├─ QRScannerViewport
         │  ├─ ScannerHelpText
         │  └─ FlashlightButton
         └─ [My Code] MyCodeView
            ├─ MyCodeHeroCard
            ├─ QRCodeDisplay
            ├─ PinCodeDisplay
            ├─ ExpiryInfoRow
            └─ ShareCodeButton
```

### 5.1. New / Refined Widgets

- `AddContactIntroCard` — NEW
- `ModeSegmentedControl` — NEW
- `QRScannerViewport` — REFRESH
- `ScannedUserConfirmSheet` — NEW
- `MyCodeHeroCard` — NEW
- `PinCodeDisplay` — NEW
- `ShareCodeButton` — REFRESH

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ Thêm liên hệ                               │
├────────────────────────────────────────────┤
│  Kết nối người thân bằng mã QR hoặc PIN    │
│  [ Quét mã ] [ Mã của tôi ]                │
├────────────────────────────────────────────┤
│ [Scan mode]                                │
│ ┌────────────────────────────────────────┐ │
│ │              Camera View               │ │
│ │          [ QR focus frame ]            │ │
│ └────────────────────────────────────────┘ │
│  Đưa mã QR vào giữa khung để quét         │
│  [Bật đèn]                                 │
├────────────────────────────────────────────┤
│ [My code mode]                             │
│              [ QR LỚN ]                    │
│                482 931                     │
│     Có hiệu lực đến 23:59 hôm nay          │
│            [ Chia sẻ mã ]                  │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

- bình tĩnh như `DEVICE_Connect`,
- không nặng kỹ thuật,
- rõ “2 cách thêm liên hệ”,
- tab `Mã của tôi` phải đủ “dễ đưa cho người khác xem”.

### 7.2. Colors

| Token | Value | Usage |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | App background |
| `bg.surface` | `#FFFFFF` | Main card |
| `bg.elevated` | `#EEF4FF` | Intro / my code hero |
| `brand.primary` | `#2F80ED` | Active mode / CTA |
| `text.primary` | `#12304A` | Main text |
| `text.secondary` | `#5B7288` | Supporting |
| `warning` | `#F2A93B` | Invalid / expired |

### 7.3. Typography

- Screen title: `22sp`
- Intro title: `20sp`
- Body: `16sp`
- PIN display: `40-48sp`
- Expiry caption: `14sp`

### 7.4. Spacing

- Outer padding: `16dp`
- Segmented control gap: `12dp`
- QR block padding: `20dp`
- Button height: `52-56dp`

---

## 8. Interaction & Behavior

| Trigger | Behavior | Duration |
| --- | --- | --- |
| Switch tab | Crossfade / slide | 180ms |
| Scan success | Freeze frame + show bottom sheet | 220ms |
| Invalid QR | Snack warning + continue scan | 120ms |
| Tap share | Open native share sheet | system |

---

## 9. Confirm Sheet Spec (`ScannedUserConfirmSheet`)

### Content

- Avatar / initials
- Full name
- Email/identifier phụ
- Label chips:
  - `Gia đình`
  - `Bác sĩ`
  - `Bạn bè`
  - `Khác`
- Buttons:
  - `Quét lại`
  - `Gửi lời mời`

### Rules

- không auto-submit ngay sau scan
- luôn cho user xác nhận đúng người
- label selection là required nhưng default có thể là `Gia đình`

---

## 10. Accessibility Checklist

- [x] PIN đủ lớn cho người già
- [x] Segmented control target >= 48dp
- [x] Permission-denied state giải thích bằng text, không chỉ icon
- [x] Flashlight button đủ lớn
- [x] Text scaling 150-200% vẫn đọc được

---

## 11. Design Rationale

| Decision | Reason |
| --- | --- |
| Chia 2 mode rõ ràng | Hợp với 2 kiểu user khác nhau |
| `My Code` có QR + PIN | QR cho người trẻ, PIN cho trường hợp camera/share thủ công |
| Confirm sheet sau scan | Tăng trust, tránh gửi nhầm |
| Intro card ngắn | Giảm cảm giác kỹ thuật, giúp user hiểu mình đang làm gì |

---

## 12. Edge Cases Handled

- [x] Camera permission denied
- [x] Quét QR không thuộc app
- [x] Quét chính mã của mình
- [x] PIN hết hạn
- [x] Môi trường tối -> flashlight
- [x] Không lấy được `my-code`

---

## 13. Dependencies

### 13.1. API / State

- `GET /api/mobile/user/my-code`
- `POST /api/mobile/contacts/request`

### 13.2. Packages

- `mobile_scanner`
- `qr_flutter`
- `permission_handler`
- native share package nếu cần

### 13.3. Navigation

- Return success to `PROFILE_ContactList`

---

## 14. Recommended File Structure

- `lib/features/family/screens/add_contact_screen.dart`
- `lib/features/family/widgets/add_contact_intro_card.dart`
- `lib/features/family/widgets/mode_segmented_control.dart`
- `lib/features/family/widgets/scanned_user_confirm_sheet.dart`
- `lib/features/family/widgets/my_code_hero_card.dart`
- `lib/features/family/widgets/pin_code_display.dart`

---

## 15. Dev Implementation Sequence

1. Build screen shell + segmented control
2. Build `My Code` tab first
3. Build permission-denied / loading / error states
4. Build scan viewport and flashlight action
5. Build `ScannedUserConfirmSheet`
6. Wire request API and success return

---

## 16. Acceptance Criteria

- [ ] User hiểu ngay 2 cách thêm liên hệ
- [ ] `Mã của tôi` đủ rõ cho người lớn tuổi dùng
- [ ] Scan flow không tự gửi nhầm request
- [ ] Màn cùng style với `DEVICE_Connect` và `HOME_Dashboard`
- [ ] Expiry / invalid code được hiển thị rõ

---

## 17. Out of Scope

- Deep share integrations theo từng app cụ thể
- Contact list refresh behavior ngoài success callback

---

## 18. Confidence Score

- **Plan Confidence: 95%**
- **Reasoning**: Luồng nghiệp vụ gọn, trọng tâm nằm ở cách trình bày 2 mode sao cho dễ hiểu cho 2 kiểu user.
