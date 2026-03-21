# 📐 UI Plan: DEVICE_Connect Refactor

> **Mode**: PLAN (mobile-agent skill)  
> **Process**: Gather Context → Silent Multi-Agent Brainstorming → Output  
> **Screen Spec**: [DEVICE_Connect.md](../DEVICE_Connect.md)  
> **Existing Code**: `health_system/lib/features/device/screens/device_screen.dart` (đang dùng dialog nhập kỹ thuật)  
> **Refactor Goal**: Đồng bộ `DEVICE_Connect` với visual language mới của `DEVICE_List` và `HOME_Dashboard`: sạch, yên tâm, product-grade, không mang cảm giác form utility.

---

## 1. Description

- **SRS Ref**: UC040
- **User Role**: User (self only)
- **Purpose**: Tạo lại luồng kết nối thiết bị theo trải nghiệm đời thực: đơn giản với người lớn tuổi, đủ tin cậy cho người hỗ trợ kỹ thuật, và thống nhất với toàn bộ family UI của module DEVICE.

### 1.1. Problem Statement

Flow hiện tại bị lệch vì:
- entry point là dialog nhập nhiều field kỹ thuật,
- không có cảm giác “guided setup” như một sản phẩm consumer,
- chưa cùng ngôn ngữ thị giác với `HOME_Dashboard` và `DEVICE_List`,
- user mới dễ sợ và lùi bước ngay từ đầu.

### 1.2. Design Goal

Refactor theo các nguyên tắc:
- **Guided onboarding**, không phải technical setup form
- **One clear decision per step**
- **Calm Clinical visual language**
- **Manual fallback** có tồn tại nhưng không chiếm spotlight

---

## 2. User Flow

### 2.1. Primary Flow

1. User bấm CTA `Kết nối thiết bị mới` từ `DEVICE_List`.
2. App mở `DEVICE_Connect` với 2 lựa chọn rất rõ:
   - `Quét QR thiết bị`
   - `Nhập mã thiết bị`
3. User chọn 1 phương thức.
4. App hướng dẫn đúng theo step đang làm.
5. App verify mã / QR.
6. App hiển thị thiết bị đã nhận diện được.
7. User bấm `Kết nối ngay`.
8. Success -> back về `DEVICE_List` và refresh hero/list.

### 2.2. Fallback Flow

1. Nếu camera fail hoặc user không biết quét:
   - luôn có đường sang `Nhập mã thiết bị`.
2. Nếu verify lỗi:
   - cho retry ngay tại step hiện tại,
   - hoặc đổi phương thức không mất context.

### 2.3. Error / Recovery Flow

1. Invalid device -> cảnh báo dễ hiểu.
2. Device owned -> error state có hướng dẫn hỗ trợ.
3. Network error -> giữ dữ liệu vừa nhập, không bắt nhập lại.

---

## 3. Information Hierarchy

### Thứ tự đọc mong muốn

1. Tôi đang ở bước nào?
2. Tôi cần làm gì tiếp theo?
3. Thiết bị nào đã được nhận diện?
4. Nếu lỗi thì lỗi là gì và cách thử lại?

### Điều phải tránh

- Không hiển thị nhiều field kỹ thuật ngay từ đầu
- Không để nhiều CTA ngang trọng lượng nhau
- Không làm UI giống “form đăng ký admin”

---

## 4. UI States

| State | Description | Display |
| --- | --- | --- |
| MethodSelect | Chọn cách kết nối | Hero intro + 2 method cards |
| CameraPermission | Chưa có quyền camera | Permission explainer + primary CTA |
| Scanning | Đang quét QR | Scan frame + helper text + fallback |
| ManualEntry | Nhập mã | Large input + helper card + verify CTA |
| Verifying | Đang kiểm tra | Loading card, chặn double submit |
| Confirm | Đã nhận diện thiết bị | Device identity card + connect CTA |
| Success | Kết nối thành công | Success hero + auto return |
| DeviceInvalid | Mã sai / thiết bị bị khoá | Warning card |
| DeviceOwned | Thiết bị đang thuộc người khác | Error card mạnh hơn |
| Error | Mất mạng / server fail | Retry with preserved data |

---

## 5. Widget Tree (proposed)

```text
Scaffold
├─ AppBar
│  ├─ BackButton
│  └─ Title("Kết nối thiết bị")
└─ Body: SafeArea
   └─ AnimatedSwitcher
      ├─ ConnectIntroHero
      ├─ MethodSelectSection
      │  ├─ ConnectionMethodCard(QR)
      │  └─ ConnectionMethodCard(Manual)
      ├─ CameraPermissionCard
      ├─ DeviceQrScanStep
      ├─ DeviceManualCodeStep
      ├─ DeviceVerifyLoadingCard
      ├─ DeviceIdentityConfirmCard
      ├─ DeviceConnectSuccessCard
      └─ DeviceConnectErrorCard
```

### 5.1. New / Refined Widgets

- `ConnectIntroHero` — NEW
- `ConnectionMethodCard` — refine
- `DeviceQrScanStep` — NEW
- `DeviceManualCodeStep` — NEW
- `DeviceIdentityConfirmCard` — refine
- `DeviceConnectSuccessCard` — NEW
- `DeviceConnectErrorCard` — refine

---

## 6. Layout Proposal

```text
┌────────────────────────────────────────────┐
│ ← Kết nối thiết bị                         │
├────────────────────────────────────────────┤
│  Kết nối đồng hồ của bạn                   │
│  Chỉ cần quét mã hoặc nhập mã thiết bị.    │
├────────────────────────────────────────────┤
│  [ Quét QR thiết bị ]                      │
│  Nhanh hơn, ít phải nhập tay               │
│                                            │
│  [ Nhập mã thiết bị ]                      │
│  Dùng khi không quét được mã               │
├────────────────────────────────────────────┤
│  (Step state bên dưới tuỳ flow)            │
└────────────────────────────────────────────┘
```

---

## 7. Visual Design Spec

### 7.1. Visual Direction

Màn này phải giống “guided setup” của một app sức khoẻ:
- sạch,
- nhẹ,
- yên tâm,
- mỗi bước rõ ràng,
- không gây sợ như màn cấu hình kỹ thuật.

### 7.2. Colors

| Role | Token / Value | Usage in this screen |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Background |
| `bg.surface` | `#FFFFFF` | Cards / step blocks |
| `brand.primary` | `#0F766E` | Main CTA |
| `brand.soft` | `#E6FFFB` | Intro / scan helper areas |
| `success` | `#0F9D7A` | Success |
| `warning` | `#F2A93B` | Invalid / permission warning |
| `critical` | `#D97706` | Device owned / stronger blocking error |
| `text.primary` | `#12304A` | Main text |
| `text.secondary` | `#5B7288` | Helper text |

### 7.3. Typography

| Element | Size | Weight | Color |
| --- | --- | --- | --- |
| Page title | 22sp | 700 | `text.primary` |
| Hero title | 24sp | 700 | `text.primary` |
| Method card title | 18sp | 700 | `text.primary` |
| Body text | 16sp | 400 | `text.secondary` |
| Input text | 18sp | 600 | `text.primary` |
| CTA label | 17-18sp | 700 | white |

### 7.4. Spacing

- Screen padding: `20dp`
- Card gap: `16dp`
- Step gap: `20dp`
- CTA min height: `56dp`

---

## 8. Interaction & Animation Spec

| Trigger | Animation / Behavior | Duration |
| --- | --- | --- |
| Step change | Crossfade + light slide | 200ms |
| QR success | Glow + light haptic | 140ms |
| Success card enter | Scale in + fade | 220ms |
| Error card appear | Slide up | 180ms |

---

## 9. Accessibility Checklist

- [x] Body >= 16sp
- [x] CTA >= 56dp
- [x] Có fallback nhập mã khi camera fail
- [x] Không dùng màu làm thông tin duy nhất
- [x] Copy đời thường, không jargon
- [x] Text scaling 150-200% không vỡ step layout
- [x] Screen reader đọc được step hiện tại

---

## 10. Design Rationale

| Decision | Reason |
| --- | --- |
| Intro hero nhẹ ở đầu màn | Tạo cảm giác onboarding, không ném user vào form ngay |
| 2 method cards rõ ràng | User hiểu có lựa chọn, không bị kẹt |
| Device identity confirm riêng | Tăng sự tin tưởng trước khi bind |
| Manual flow là fallback | Progressive disclosure, tránh overload |
| Cùng palette với `DEVICE_List` | Nhất quán toàn module |

---

## 11. Edge Cases Handled

- [x] Camera permission bị từ chối
- [x] QR không đọc được
- [x] User không biết quét QR
- [x] Device invalid / locked
- [x] Device thuộc user khác
- [x] Mất mạng giữa verify
- [x] Back khi đang có dữ liệu nhập dở
- [x] Mở sai linked/family context

---

## 12. Dependencies

### 12.1. Shared Widgets Needed

- `ConnectIntroHero` — NEW
- `ConnectionMethodCard` — refine
- `DeviceQrScanStep` — NEW
- `DeviceManualCodeStep` — NEW
- `DeviceIdentityConfirmCard` — NEW/refine
- `DeviceConnectSuccessCard` — NEW
- `DeviceConnectErrorCard` — refine

### 12.2. API / Platform

- QR scan package / native camera scanning
- verify/bind device contract
- error mapping:
  - invalid
  - locked
  - already assigned
  - network fail

### 12.3. Route / State

- Route mới: `device/connect`
- `DeviceConnectProvider` riêng

---

## 13. Recommended File Structure

- `lib/features/device/screens/device_connect_screen.dart`
- `lib/features/device/providers/device_connect_provider.dart`
- `lib/features/device/widgets/device_connect/connect_intro_hero.dart`
- `lib/features/device/widgets/device_connect/connection_method_card.dart`
- `lib/features/device/widgets/device_connect/device_qr_scan_step.dart`
- `lib/features/device/widgets/device_connect/device_manual_code_step.dart`
- `lib/features/device/widgets/device_connect/device_identity_confirm_card.dart`
- `lib/features/device/widgets/device_connect/device_connect_error_card.dart`

---

## 14. Dev Implementation Sequence

1. Tách route và provider riêng cho `DEVICE_Connect`
2. Build intro hero + method selection
3. Build manual-code flow hoàn chỉnh trước
4. Thêm QR scan + permission flow
5. Build confirm / success / error states
6. Nối API verify/bind
7. Hook callback refresh về `DEVICE_List`
8. Polish accessibility + visual sync với module

---

## 15. Acceptance Criteria

- [ ] Entry point không còn là technical dialog
- [ ] UI cùng visual family với `DEVICE_List` và `HOME_Dashboard`
- [ ] User phổ thông hiểu ngay cách kết nối
- [ ] Manual fallback tồn tại nhưng không lấn át flow chính
- [ ] Success quay về list mượt và update state đúng
- [ ] Error states dễ hiểu, không raw technical

---

## 16. Out of Scope

- Refactor `DEVICE_StatusDetail`
- Refactor `DEVICE_Configure`
- BLE true end-to-end hardware integration
- Pair cho linked/family profile

---

## 17. Confidence Score

- **Plan Confidence: 96%**
- **Reasoning**: Vấn đề UX của màn này rất rõ, hướng refactor ít phụ thuộc layout legacy và dễ đồng bộ với visual system mới.
- **Uncertainties**:
  - verify/bind API cuối cùng của backend
  - thư viện scan QR chuẩn của project
