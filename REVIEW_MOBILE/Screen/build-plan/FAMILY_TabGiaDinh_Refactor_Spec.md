# FAMILY Tab Refactor Spec

> **Module**: `Gia đình`
> **Type**: Refactor Spec
> **Status**: Proposed
> **Goal**: Chuẩn hoá lại toàn bộ tab `Gia đình` theo mô hình mới để hỗ trợ người già, người thân chăm sóc, và bác sĩ theo dõi nhiều đối tượng một cách rõ ràng, an toàn, đồng bộ style với phần `Home` và `Device`.

---

## 1. Core Decision

Tab `Gia đình` phải được refactor thành **một module thống nhất** với **2 tab con**:

1. `Theo dõi`
2. `Liên hệ`

### Decision chốt

- `Theo dõi` là không gian giám sát hằng ngày.
- `Liên hệ` là không gian quản lý quan hệ, quyền, nhãn, và kết nối.
- **Không tạo thêm business state riêng** kiểu `được thêm vào Theo dõi`.
- Một người xuất hiện trong `Theo dõi` khi và chỉ khi:
  - đã là `linked contact` hợp lệ
  - và user hiện tại có quyền `can_view_vitals = true`
- Nếu cần “ưu tiên” ai đó, chỉ dùng lớp hiển thị như:
  - `Ưu tiên`
  - `SOS`
  - `Cần chú ý`
  - `Tất cả`
- `Ưu tiên` là **presentation preference**, không phải access state.

---

## 2. Product Intent

### Module này tồn tại để trả lời 2 nhu cầu khác nhau nhưng liên quan chặt chẽ:

1. **Tôi đang chăm sóc / theo dõi ai?**
2. **Tôi đang có quan hệ và quyền gì với họ?**

### Vì sao phải tách `Theo dõi` và `Liên hệ`

- `Theo dõi` là read-heavy, tốc độ đọc trạng thái là ưu tiên số 1.
- `Liên hệ` là write-heavy, liên quan quyền và thao tác nhạy cảm.
- Nếu trộn 2 thứ này vào một màn, cognitive load sẽ tăng mạnh.
- Với bác sĩ và caregiver, module phải scale cho nhiều người, không chỉ 1-2 người thân.

---

## 3. Information Architecture

## 3.1. Cấu trúc cấp cao

```text
Bottom Nav
└─ Gia đình
   ├─ Theo dõi
   │  ├─ Summary / Hero
   │  ├─ Danh sách người đang monitor được
   │  └─ Chi tiết theo dõi từng người
   └─ Liên hệ
      ├─ Pending requests
      ├─ Accepted contacts
      ├─ Add contact
      └─ Linked contact detail / permissions
```

## 3.2. Các màn hình cần có

### A. `FAMILY_Shell`

Vai trò:
- là shell chính của tab `Gia đình`
- chứa segmented control `Theo dõi / Liên hệ`
- giữ context điều hướng nhất quán trong module

### B. `FAMILY_Tracking`

Vai trò:
- màn chính của tab con `Theo dõi`
- hiển thị danh sách những người user đang **được phép** theo dõi

### C. `PROFILE_ContactList`

Vai trò:
- màn chính của tab con `Liên hệ`
- quản lý pending, accepted contacts, labels, permission entrypoints

### D. `PROFILE_AddContact`

Vai trò:
- thêm liên hệ mới
- 2 mode:
  - `Quét mã`
  - `Mã của tôi`

### E. `PROFILE_LinkedContactDetail`

Vai trò:
- quản lý quyền chia sẻ và nhãn cho một liên hệ cụ thể

### F. `FAMILY_PersonDetail`

Vai trò:
- chi tiết theo dõi của một người cụ thể trong `Theo dõi`
- đây là màn cần bổ sung rõ vào spec refactor mới

---

## 4. Rule Hiển Thị `Theo dõi` / `Liên hệ`

## 4.1. `Liên hệ` hiển thị gì

`Liên hệ` hiển thị toàn bộ graph quan hệ:

- `pending_incoming`
- `pending_outgoing`
- `accepted`
- `accepted` nhưng chưa được cấp quyền xem chỉ số
- `accepted` chỉ nhận SOS
- `accepted` có đầy đủ quyền

### `Liên hệ` là source of truth cho:

- ai đang kết nối với ai
- nhãn là gì
- quyền đang cấp là gì
- unlink / accept / reject

## 4.2. `Theo dõi` hiển thị gì

`Theo dõi` chỉ hiển thị:

- những người đã `accepted`
- và user hiện tại có `can_view_vitals = true`

### `Theo dõi` không hiển thị:

- pending requests
- accepted nhưng chưa có `can_view_vitals`
- đối tượng chỉ có quyền `can_receive_alerts`

## 4.3. Nếu có liên hệ nhưng chưa ai monitor được

Không được để user thấy màn trống mơ hồ.

Phải có state kiểu:

- `Anh đã có 3 liên hệ`
- `Hiện chưa ai bật chia sẻ chỉ số sức khỏe cho anh`
- CTA:
  - `Đi tới Liên hệ`
  - hoặc `Quản lý quyền chia sẻ`

## 4.4. Nếu có quá nhiều người

Không thêm state “followed manually”.

Chỉ thêm lớp hiển thị:

- `Tất cả`
- `SOS`
- `Cần chú ý`
- `Ưu tiên`

### Rule:

- `Ưu tiên` là display preference
- không ảnh hưởng quyền
- không ảnh hưởng eligibility

---

## 5. State Model Chuẩn

## 5.1. Relationship State

Áp dụng cho `Liên hệ`:

- `pending_incoming`
- `pending_outgoing`
- `accepted`
- `unlinked`

## 5.2. Permission State

Áp dụng cho `LinkedContactDetail`:

- `can_view_vitals`
- `can_receive_alerts`
- `can_view_location`

## 5.3. Monitoring Visibility State

Áp dụng cho `Theo dõi`:

- `monitorable`
- `linked_but_not_monitorable`
- `pending`

### Mapping

- `monitorable` = `accepted + can_view_vitals = true`
- `linked_but_not_monitorable` = `accepted + can_view_vitals = false`
- `pending` = chưa accepted

## 5.4. Health State

Áp dụng cho từng người trong `Theo dõi`:

- `sos_active`
- `attention`
- `stable`
- `offline`
- `stale_data`

## 5.5. Nguyên tắc cứng

Không được thêm state:

- `is_manually_followed`
- `is_added_to_tracking`

vì state này thừa và gây rối mental model.

---

## 6. User Flow Chuẩn

## 6.1. Flow cấp module

1. User bấm tab `Gia đình` ở bottom nav.
2. App mở `FAMILY_Shell`.
3. Tab con mặc định là `Theo dõi`.

## 6.2. Flow `Theo dõi`

1. Load aggregated family dashboard.
2. Hero đầu màn hiển thị:
   - tổng số người đang monitor được
   - số người cần chú ý
   - số SOS active
3. Hiển thị danh sách theo thứ tự:
   - `SOS`
   - `Cần chú ý`
   - `Ổn định`
4. User bấm vào một người:
   - mở `FAMILY_PersonDetail`
5. Từ đây user drill-down tiếp:
   - `VitalDetail(profileId)`
   - `SleepReport(profileId)`
   - `RiskReport(profileId)`

## 6.3. Flow `Liên hệ`

1. User switch sang `Liên hệ`.
2. App hiển thị:
   - pending requests
   - accepted contacts grouped theo nhãn
3. User accept request:
   - mở `PermissionSetupBottomSheet`
4. `Cài sau` vẫn phải áp dụng default an toàn:
   - `can_view_vitals = OFF`
   - `can_receive_alerts = ON`
   - `can_view_location = ON`
5. User bấm vào contact:
   - mở `PROFILE_LinkedContactDetail`

## 6.4. Flow `Add Contact`

1. Từ `Liên hệ`, bấm `Thêm liên hệ`.
2. Mở `PROFILE_AddContact`.
3. Chọn một trong hai:
   - `Quét mã`
   - `Mã của tôi`
4. Xác nhận / gửi request.
5. Quay về `Liên hệ`.

## 6.5. Flow `Linked Contact Detail`

1. Mở chi tiết liên hệ.
2. Xem:
   - avatar
   - tên
   - nhãn
   - 3 quyền
3. User có thể:
   - bật/tắt quyền
   - đổi nhãn
   - huỷ liên kết

## 6.6. Flow `FAMILY_PersonDetail`

1. User vào từ `Theo dõi`.
2. Mở chi tiết theo dõi của một người.
3. Thấy:
   - trạng thái tổng quát
   - last updated
   - chỉ số hiện tại
   - risk summary
   - health alert history
   - quick action vào detail screens
4. Nếu đang có SOS active:
   - CTA sang `EMERGENCY_SOSReceivedDetail`

---

## 7. Trên Mỗi Màn Cần Có Gì

## 7.1. `FAMILY_Shell`

Phải có:

- App bar title: `Gia đình`
- Segmented control:
  - `Theo dõi`
  - `Liên hệ`
- Badge tổng hợp:
  - pending count ở `Liên hệ`
  - alert indicator ở `Theo dõi`

## 7.2. `FAMILY_Tracking`

Phải có:

- `FamilyHealthHeroCard`
- `FamilySOSPriorityBanner`
- `FamilyAttentionSummaryBanner`
- Filter chips:
  - `Tất cả`
  - `SOS`
  - `Cần chú ý`
  - `Ưu tiên`
- `FamilyProfileHealthCard`
- empty state
- permission-needed state
- CTA sang `Liên hệ`

## 7.3. `PROFILE_ContactList`

Phải có:

- Hero summary:
  - tổng số liên hệ
  - số pending
  - CTA thêm liên hệ
- pending section
- accepted section grouped theo nhãn
- mỗi contact card hiển thị:
  - avatar
  - tên
  - nhãn
  - summary quyền
  - trạng thái
  - CTA vào detail

## 7.4. `PROFILE_AddContact`

Phải có:

- Intro card
- segmented switch:
  - `Quét mã`
  - `Mã của tôi`
- mode `Quét mã`:
  - permission state
  - scanner viewport
  - flashlight
  - confirm sheet
- mode `Mã của tôi`:
  - QR lớn
  - PIN lớn
  - expiry
  - share button

## 7.5. `PROFILE_LinkedContactDetail`

Phải có:

- Hero card
- Context explanation:
  - `Anh đang cấu hình quyền anh chia sẻ cho người này`
- 3 permission cards
- label management card
- unlink danger zone

## 7.6. `FAMILY_PersonDetail`

Phải có:

- Hero state block:
  - tên
  - nhãn
  - trạng thái hiện tại
  - last updated
- live/latest vitals block
- risk summary block
- sleep summary block
- health alert history block
- CTA:
  - `Xem chi tiết chỉ số`
  - `Xem báo cáo giấc ngủ`
  - `Xem báo cáo rủi ro`
- nếu có SOS:
  - `Xem tình huống khẩn cấp`

---

## 8. Alert History Đặt Ở Đâu

## 8.1. `SOS history`

Đặt ở:

- `EMERGENCY_SOSReceivedList`

Không đặt full ở `Liên hệ`.
Không đặt full ở `Theo dõi`.

### Trong `Theo dõi` chỉ nên có:

- `SOS active`
- recent emergency shortcut
- CTA `Xem tất cả SOS`

## 8.2. `Health alert history`

Đặt ở:

- `FAMILY_PersonDetail`

Bao gồm:

- cảnh báo chỉ số bất thường
- alert theo risk
- trạng thái cần chú ý gần đây

## 8.3. `Notification Center`

Nếu sau này build:

- dùng làm inbox toàn app
- không phải màn chính cho theo dõi sức khỏe nhiều người

---

## 9. Prompt Guardrails Để Giữ Đồng Bộ Công Nghệ Và Style

Phần này dùng để “ép prompt” khi tiếp tục tạo plan/build/review cho module này.

## 9.1. Product / UX Guardrails

- Luôn giữ mental model:
  - `Theo dõi = monitoring`
  - `Liên hệ = relationship management`
- Không tạo state `manually followed`
- Không để user phải suy luận phức tạp về quyền
- Ngôn ngữ phải đời thường, không kỹ thuật
- Trạng thái `đã linked nhưng chưa monitor được` phải cực rõ

## 9.2. Architecture Guardrails

- `can_view_vitals` là business gate duy nhất để xuất hiện trong `Theo dõi`
- `Liên hệ` là source of truth của labels và permissions
- `Theo dõi` chỉ consume read model, không tự sở hữu quyền
- Không trộn `contactId`, `relationshipId`, `profileId`
- Tách rõ:
  - route shell
  - contact management
  - tracking read model
  - person detail read model

## 9.3. Visual Guardrails

Phải đồng bộ với visual family của app hiện tại:

- `HOME_Dashboard`
- `DEVICE_List`
- `DEVICE_Configure`
- `DEVICE_StatusDetail`

### Theme direction

Sử dụng `HealthGuard Calm`:

- nền sáng
- card trắng sạch
- hero elevated dịu
- semantic color tiết chế
- typography lớn, dễ đọc

### Token gợi ý

| Token | Value | Usage |
| --- | --- | --- |
| `bg.primary` | `#F4F7FB` | Nền app |
| `bg.surface` | `#FFFFFF` | Card |
| `bg.elevated` | `#EEF4FF` | Hero |
| `text.primary` | `#12304A` | Nội dung chính |
| `text.secondary` | `#5B7288` | Metadata |
| `brand.primary` | `#2F80ED` | CTA chính/phụ |
| `success` | `#2E9B6F` | Bình thường |
| `warning` | `#F2A93B` | Cần chú ý |
| `critical` | `#D95C5C` | Khẩn / SOS |

### Typography

- Display compact: `28-30sp`
- Section title: `20sp`
- Card title: `18sp`
- Body: `16-17sp`
- Caption: `14sp`

### Accessibility

- body >= `16sp`
- touch target >= `48dp`
- text scaling `150-200%` vẫn usable
- không dùng chỉ màu để phân biệt trạng thái

## 9.4. Prompt Template Gợi Ý

```text
Refactor module Gia đình theo mô hình mới:
- Tab Gia đình có 2 tab con: Theo dõi và Liên hệ
- Theo dõi là monitoring workspace, chỉ hiển thị các linked profiles có can_view_vitals = true
- Liên hệ là source of truth cho pending, accepted, labels, permissions, unlink
- Không tạo business state riêng kiểu manually followed
- Nếu linked nhưng chưa monitor được, phải hiển thị rõ là permission issue chứ không phải lỗi
- Giữ visual style đồng bộ với HOME_Dashboard, DEVICE_List, DEVICE_Configure theo hệ HealthGuard Calm
- Ưu tiên readability cho elderly/caregiver/doctor
- Font lớn, spacing thoáng, hierarchy rõ, trạng thái SOS/attention rất rõ nhưng không gây hoảng
- Tách rõ contactId, relationshipId, profileId
- Output phải giữ kiến trúc, wording, component naming nhất quán với app hiện tại
```

---

## 10. Thứ Tự Sửa Các File Plan Hiện Có

## 10.1. Sửa trước

1. `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/HOME_FamilyDashboard_plan.md`

Lý do:
- đây là file chịu tác động lớn nhất
- hiện đang là monitoring-only screen
- cần đổi thành `Theo dõi` tab con bên trong `Gia đình`
- cần thêm rule mới về eligibility

2. `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/PROFILE_ContactList_plan.md`

Lý do:
- cần xác lập rõ `Liên hệ` là tab con thứ hai trong cùng shell
- phải liên kết chặt với `Theo dõi`

3. `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/PROFILE_LinkedContactDetail_plan.md`

Lý do:
- cần viết rõ hơn vai trò source of truth cho permission/label
- phải gắn chặt hơn với điều kiện xuất hiện trong `Theo dõi`

4. `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/PROFILE_AddContact_plan.md`

Lý do:
- ít thay đổi nhất
- chủ yếu update entry context và return flow về `Liên hệ`

## 10.2. Tạo mới thêm

Nên tạo thêm 2 file plan/spec:

1. `PM_REVIEW/REVIEW_MOBILE/Screen/FAMILY_PersonDetail.md`
2. `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/FAMILY_PersonDetail_plan.md`

vì đây là màn còn thiếu nhưng cực kỳ quan trọng cho mô hình mới.

## 10.3. Cập nhật spec gốc

Nên cập nhật thêm:

- `PM_REVIEW/REVIEW_MOBILE/Screen/HOME_FamilyDashboard.md`
- `PM_REVIEW/REVIEW_MOBILE/Screen/PROFILE_ContactList.md`
- `PM_REVIEW/REVIEW_MOBILE/Screen/PROFILE_LinkedContactDetail.md`
- `PM_REVIEW/REVIEW_MOBILE/Screen/PROFILE_AddContact.md`

để toàn bộ task/spec khớp với refactor direction mới.

---

## 11. Build Order Gợi Ý

1. `FAMILY_Shell`
2. `PROFILE_ContactList`
3. `PROFILE_AddContact`
4. `PROFILE_LinkedContactDetail`
5. `FAMILY_Tracking`
6. `FAMILY_PersonDetail`
7. reconnect `EMERGENCY` shortcut + risk/sleep/vitals drill-down

---

## 12. Final Summary

### Mô hình cuối cùng cần chốt

- `Gia đình` là module chính
- bên trong có:
  - `Theo dõi`
  - `Liên hệ`
- `Liên hệ` quản lý quan hệ và quyền
- `Theo dõi` là ảnh chiếu read-only của tất cả người mà user được phép xem chỉ số
- không thêm state dư kiểu “được theo dõi thủ công”
- `alert history` sức khỏe nằm ở `FAMILY_PersonDetail`
- `SOS history` nằm ở `EMERGENCY_SOSReceivedList`

### Mục tiêu UX cuối

Người dùng phải luôn hiểu được:

- tôi đang theo dõi ai
- tôi đang có quan hệ với ai
- tại sao có người chưa xuất hiện trong `Theo dõi`
- tôi vào đâu để chỉnh quyền
- tôi vào đâu để xem sâu chỉ số và đánh giá của từng người

---

## Changelog

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| v1.0 | 2026-03-18 | AI | Initial refactor spec for `Gia đình` tab using the new `Theo dõi / Liên hệ` model |
