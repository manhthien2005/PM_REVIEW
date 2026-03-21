# 🧭 Family / Contacts Implementation Order

## Recommended Order

### Phase 1 — `PROFILE_ContactList`

**Why first**
- Là hub điều hướng của toàn bộ module.
- Chứa pending + accepted contacts, là nguồn sự thật UI cho các màn còn lại.
- Giúp xác định rõ state model: `pending`, `accepted`, `permission-needed`, `empty`.

**Output**
- `PROFILE_ContactList_plan.md`
- Hero + pending section + grouped contact list
- Navigation hooks sang `AddContact` và `LinkedContactDetail`

---

### Phase 2 — `PROFILE_AddContact`

**Why second**
- Là entry point tạo dữ liệu mới cho ContactList.
- Sau khi ContactList ổn định, AddContact chỉ cần trả success callback về hub.
- Dễ test hơn khi đã có hub nhận kết quả.

**Output**
- `PROFILE_AddContact_plan.md`
- 2-mode flow: `Quét mã` / `Mã của tôi`
- Success return về ContactList

---

### Phase 3 — `PROFILE_LinkedContactDetail`

**Why third**
- Chỉ meaningful khi đã có accepted contacts.
- Phụ thuộc navigation từ `ContactList`.
- Cần state cập nhật quyền và side effects sau khi data model đã ổn định từ 2 phase đầu.

**Output**
- `PROFILE_LinkedContactDetail_plan.md`
- Permission center + label management + unlink flow

---

### Phase 4 — `HOME_FamilyDashboard`

**Why fourth**
- Là màn consume dữ liệu sau cùng.
- Phụ thuộc linked profiles + permission model đã hoàn thiện.
- Nếu build sớm hơn sẽ phải mock/đoán nhiều state quyền liên kết.

**Output**
- `HOME_FamilyDashboard_plan.md`
- Family hero + SOS priority + profile health cards

---

## Final Ordered List

1. `PROFILE_ContactList_plan.md`
2. `PROFILE_AddContact_plan.md`
3. `PROFILE_LinkedContactDetail_plan.md`
4. `HOME_FamilyDashboard_plan.md`

---

## Why This Order Is Best

- Đi từ **hub dữ liệu** → **tạo dữ liệu** → **cấu hình quyền** → **màn tiêu thụ dữ liệu**
- Giảm số lần phải sửa navigation/state model
- Giảm mock tạm và rework UI
- Hợp với logic user journey thật:
  - quản lý liên hệ,
  - thêm liên hệ,
  - chỉnh quyền,
  - theo dõi gia đình

---

## Parallelization Notes

Có thể tách như sau nếu nhiều người cùng làm:

- Dev A: `PROFILE_ContactList`
- Dev B: `PROFILE_AddContact`
- Sau khi A xong navigation/state contract:
  - Dev C: `PROFILE_LinkedContactDetail`
- Khi contract API quyền và linked profiles đã rõ:
  - Dev D: `HOME_FamilyDashboard`

Nhưng nếu chỉ có 1 người làm, vẫn nên theo đúng thứ tự 1 → 4 ở trên.
