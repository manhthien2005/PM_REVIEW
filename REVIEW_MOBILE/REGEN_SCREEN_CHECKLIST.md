# 🔄 REGEN SCREEN CHECKLIST — Sinh lại toàn bộ Screen Specs theo chuẩn mới

> **Mục tiêu**: Regenerate toàn bộ 41 file màn hình trong `Screen/` theo đúng `screen_spec_template.md` v3.0
> **Skill trigger**: `@PM_REVIEW/SKILLS/mobile-agent/SKILL.md` mode **TASK**
> **Sub-command**: `TASK update [screen]` (từng file) hoặc `TASK generate [module]` (theo module)
> **Ngày tạo**: 2026-03-17
> **Standard ref**: `PM_REVIEW/SKILLS/mobile-agent/references/templates/screen_spec_template.md`

---

## 📋 Tại sao cần regenerate?

Phần lớn file màn hình hiện tại **thiếu** các sections bắt buộc theo chuẩn mới:

| Section bắt buộc | Trạng thái hiện tại |
| --- | --- |
| `## UI States` (Loading / Empty / Success / Error) | ❌ Thiếu ở hầu hết file |
| `## Edge Cases` | ❌ Thiếu ở hầu hết file |
| `## Data Requirements` (API endpoint, input, output) | ❌ Thiếu ở hầu hết file |
| `## Sync Notes` | ❌ Thiếu ở hầu hết file |
| `## Design Context` (audience, UX priority, constraints) | ❌ Thiếu ở hầu hết file |
| `## Pipeline Status` (TASK / PLAN / BUILD / REVIEW) | ❌ Thiếu ở hầu hết file |
| `## Changelog` | ❌ Thiếu ở hầu hết file |

---

## 🗺️ Inventory — Phân loại trạng thái hiện tại

| Ký hiệu | Nghĩa |
| --- | --- |
| 🔴 STUB | <500 bytes — chỉ có header + 1-2 dòng Purpose |
| 🟡 PARTIAL | 500-2000 bytes — có Purpose + Navigation + Flow nhưng thiếu UI States / Edge Cases / Design Context |
| 🟢 BETTER | >3000 bytes — gần đủ nhưng vẫn cần validate lại format |

---

## 📦 MODULE: AUTH (7 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 1 | `AUTH_Splash.md` | ~4KB | 🟢 BETTER | [x] |
| 2 | `AUTH_Login.md` | ~4KB | 🟢 BETTER | [x] |
| 3 | `AUTH_Register.md` | ~4KB | 🟢 BETTER | [x] |
| 4 | `AUTH_VerifyEmail.md` | ~4KB | 🟢 BETTER | [x] |
| 5 | `AUTH_ForgotPassword.md` | ~4KB | 🟢 BETTER | [x] |
| 6 | `AUTH_ResetPassword.md` | ~4KB | 🟢 BETTER | [x] |
| 7 | `AUTH_Onboarding.md` | ~3KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger AUTH batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK update AUTH_Splash
Đọc UC001-UC005, UC009 và screen_spec_template.md. Sinh lại đầy đủ file AUTH_Splash.md theo đúng template chuẩn mới: có đủ 7 sections (UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog). Giữ nguyên nội dung cũ nếu vẫn đúng.
```

> Lặp lại prompt trên cho từng file: AUTH_Login, AUTH_Register, AUTH_VerifyEmail, AUTH_ForgotPassword, AUTH_ResetPassword, AUTH_Onboarding

---

## 📦 MODULE: DEVICE (4 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 8 | `DEVICE_List.md` | ~4KB | 🟢 BETTER | [x] |
| 9 | `DEVICE_Connect.md` | ~4KB | 🟢 BETTER | [x] |
| 10 | `DEVICE_StatusDetail.md` | ~4KB | 🟢 BETTER | [x] |
| 11 | `DEVICE_Configure.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger DEVICE batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate DEVICE
Đọc UC040, UC041, UC042 và screen_spec_template.md. Sinh lại TẤT CẢ 4 file DEVICE (DEVICE_List, DEVICE_Connect, DEVICE_StatusDetail, DEVICE_Configure) theo đúng template chuẩn mới. Đảm bảo mỗi file có đủ: UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog.
```

---

## 📦 MODULE: HOME (2 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 12 | `HOME_Dashboard.md` | ~9KB | 🟢 BETTER | [x] |
| 13 | `HOME_FamilyDashboard.md` | ~9KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger HOME batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK update HOME_Dashboard
Đọc UC006-UC008, UC016, UC020 và screen_spec_template.md. Validate và bổ sung các sections còn thiếu theo template chuẩn mới: UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog. KHÔNG xoá nội dung cũ đúng.
```

> Lặp lại cho: HOME_FamilyDashboard

---

## 📦 MODULE: MONITORING (2 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 14 | `MONITORING_VitalDetail.md` | ~4KB | 🟢 BETTER | [x] |
| 15 | `MONITORING_HealthHistory.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger MONITORING batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate MONITORING
Đọc UC006, UC007, UC008 và screen_spec_template.md. Sinh lại đầy đủ 2 file MONITORING theo template chuẩn mới. Chú ý: MONITORING_VitalDetail nhận profileId (UC007 — xem chỉ số của người được monitor). Đảm bảo Design Context phản ánh đối tượng người dùng (cao tuổi hoặc người theo dõi).
```

---

## 📦 MODULE: EMERGENCY (6 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 16 | `EMERGENCY_FallAlert.md` | ~4KB | 🟢 BETTER | [x] |
| 17 | `EMERGENCY_ManualSOS.md` | ~4KB | 🟢 BETTER | [x] |
| 18 | `EMERGENCY_LocalSOSActive.md` | ~4KB | 🟢 BETTER | [x] |
| 19 | `EMERGENCY_IncomingSOSAlarm.md` | ~4KB | 🟢 BETTER | [x] |
| 20 | `EMERGENCY_SOSReceivedList.md` | ~4KB | 🟢 BETTER | [x] |
| 21 | `EMERGENCY_SOSReceivedDetail.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger EMERGENCY batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate EMERGENCY
Đọc UC010, UC011, UC014, UC015 và screen_spec_template.md. Sinh lại TẤT CẢ 6 file EMERGENCY theo template chuẩn mới. Chú ý ưu tiên UX: tốc độ phản hồi, màu đỏ emergency, font lớn, nút to ≥56dp, hold-to-confirm cho SOS. Edge Cases bắt buộc có: network loss, countdown = 0, app background.
```

---

## 📦 MODULE: PROFILE (8 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 22 | `PROFILE_Overview.md` | ~4KB | 🟢 BETTER | [x] |
| 23 | `PROFILE_EditProfile.md` | ~4KB | 🟢 BETTER | [x] |
| 24 | `PROFILE_MedicalInfo.md` | ~4KB | 🟢 BETTER | [x] |
| 25 | `PROFILE_ChangePassword.md` | ~4KB | 🟢 BETTER | [x] |
| 26 | `PROFILE_DeleteAccount.md` | ~4KB | 🟢 BETTER | [x] |
| 27 | `PROFILE_ContactList.md` | ~5KB | 🟢 BETTER | [x] |
| 28 | `PROFILE_AddContact.md` | ~5KB | 🟢 BETTER | [x] |
| 29 | `PROFILE_LinkedContactDetail.md` | ~6KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger PROFILE batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate PROFILE
Đọc UC005, UC030 và screen_spec_template.md. Sinh lại TẤT CẢ 8 file PROFILE theo template chuẩn mới. Chú ý kiến trúc mới: không dùng role patient/caregiver — chỉ dùng unified User role và Linked Profiles. PROFILE_ContactList / AddContact / LinkedContactDetail là màn quản lý Linked Profiles.
```

---

## 📦 MODULE: NOTIFICATION (5 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 30 | `NOTIFICATION_Center.md` | ~4KB | 🟢 BETTER | [x] |
| 31 | `NOTIFICATION_Detail.md` | ~4KB | 🟢 BETTER | [x] |
| 32 | `NOTIFICATION_Settings.md` | ~4KB | 🟢 BETTER | [x] |
| 33 | `NOTIFICATION_EmergencyContacts.md` | ~4KB | 🟢 BETTER | [x] |
| 34 | `NOTIFICATION_AddEditContact.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger NOTIFICATION batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate NOTIFICATION
Đọc UC030, UC031 và screen_spec_template.md. Sinh lại TẤT CẢ 5 file NOTIFICATION theo template chuẩn mới. Phần lớn là STUB cần tạo mới hoàn toàn. Đảm bảo phân biệt rõ: NOTIFICATION_Center (inbox), NOTIFICATION_Settings (tuỳ chỉnh cảnh báo), NOTIFICATION_EmergencyContacts (danh sách liên hệ khẩn — link sang PROFILE_ContactList).
```

---

## 📦 MODULE: ANALYSIS (3 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 35 | `ANALYSIS_RiskReport.md` | ~4KB | 🟢 BETTER | [x] |
| 36 | `ANALYSIS_RiskReportDetail.md` | ~4KB | 🟢 BETTER | [x] |
| 37 | `ANALYSIS_RiskHistory.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger ANALYSIS batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate ANALYSIS
Đọc UC016, UC017 và screen_spec_template.md. Sinh lại TẤT CẢ 3 file ANALYSIS theo template chuẩn mới. Chú ý: ANALYSIS_RiskHistory cần lazy load (infinite scroll), ANALYSIS_RiskReportDetail cần breakdown từng chỉ số đóng góp vào điểm rủi ro AI.
```

---

## 📦 MODULE: SLEEP (4 screens)

| # | File | Size | Tình trạng | Done? |
| --- | --- | --- | --- | --- |
| 38 | `SLEEP_Report.md` | ~4KB | 🟢 BETTER | [x] |
| 39 | `SLEEP_Detail.md` | ~4KB | 🟢 BETTER | [x] |
| 40 | `SLEEP_History.md` | ~4KB | 🟢 BETTER | [x] |
| 41 | `SLEEP_TrackingSettings.md` | ~4KB | 🟢 BETTER | [x] |

### ▶️ Prompt để trigger SLEEP batch:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK generate SLEEP
Đọc UC020, UC021 và screen_spec_template.md. Sinh lại TẤT CẢ 4 file SLEEP theo template chuẩn mới. Chú ý: dữ liệu sleep được xử lý ban đêm → cần UI State "No data tonight yet" cho ngày hiện tại trước 6:00 sáng. SLEEP_TrackingSettings cho phép user bật/tắt tracking và set giờ ngủ mục tiêu.
```

---

## 🚀 Bước cuối — Sync & Update README

Sau khi regenerate xong TẤT CẢ modules, chạy lệnh final sync:

```
@PM_REVIEW/SKILLS/mobile-agent/SKILL.md

mode TASK sync
Sau khi regenerate tất cả 41 file screen, chạy TASK sync để:
1. Kiểm tra cross-link toàn bộ (orphan, missing, broken links, one-way links)
2. Cập nhật README.md (Screen Index) với đầy đủ thông tin status mới
3. Xuất TASK Report cuối với tổng số screen đã cập nhật
```

---

## 📋 TASK Report cuối (2026-03-17)

| Hạng mục | Kết quả |
| --- | --- |
| **Tổng screen** | 41 |
| **Đã regenerate** | 41/41 ✅ |
| **Cross-link** | 0 broken, 0 orphan, 0 missing |
| **One-way links** | Một số (chấp nhận được — Back button thay reverse link) |
| **README.md** | ✅ Đã cập nhật status Done cho tất cả |
| **Điều chỉnh** | Xóa MONITORING_HealthMetrics khỏi index (file không tồn tại) |

---

## 📊 Tiến độ tổng thể

| Module | Tổng | Stub 🔴 | Partial 🟡 | Better 🟢 | Hoàn thành ✅ |
| --- | --- | --- | --- | --- | --- |
| AUTH | 7 | 0 | 0 | 7 | 7/7 |
| DEVICE | 4 | 0 | 0 | 4 | 4/4 |
| HOME | 2 | 0 | 0 | 2 | 2/2 |
| MONITORING | 2 | 0 | 0 | 2 | 2/2 |
| EMERGENCY | 6 | 0 | 0 | 6 | 6/6 |
| PROFILE | 8 | 0 | 0 | 8 | 8/8 |
| NOTIFICATION | 5 | 0 | 0 | 5 | 5/5 |
| ANALYSIS | 3 | 0 | 0 | 3 | 3/3 |
| SLEEP | 4 | 0 | 0 | 4 | 4/4 |
| **TOTAL** | **41** | **0** | **0** | **41** | **41/41** |

---

## ⚙️ Hướng dẫn thực hiện

### Thứ tự ưu tiên (theo dependency)

1. **Batch 1 — AUTH** (7 screens) — Không có dependency
2. **Batch 2 — DEVICE** (4 screens) — Không có dependency
3. **Batch 3 — HOME** (2 screens) — Cần AUTH + DEVICE xong trước (navigation links)
4. **Batch 4 — MONITORING** (2 screens) — Cần HOME xong
5. **Batch 5 — EMERGENCY** (6 screens) — Cần HOME + MONITORING xong
6. **Batch 6 — PROFILE** (8 screens) — Cần AUTH xong
7. **Batch 7 — NOTIFICATION** (5 screens) — Cần PROFILE xong
8. **Batch 8 — ANALYSIS** (3 screens) — Cần HOME xong
9. **Batch 9 — SLEEP** (4 screens) — Cần HOME xong
10. **Final — TASK sync** — Sau khi tất cả xong

### Quy tắc bắt buộc khi AI regenerate

- ✅ **GIỮ** nội dung cũ đúng (Purpose, Navigation Links, User Flow đã có)
- ✅ **BỔ SUNG** các sections còn thiếu (UI States, Edge Cases, Data Requirements, Sync Notes, Design Context, Pipeline Status, Changelog)
- ✅ **ĐỌC** UC tương ứng trước khi sinh nội dung
- ✅ **KIỂM TRA** Architecture Rule: không dùng `patient`/`caregiver` role — chỉ dùng `User` + `Linked Profiles`
- ❌ **KHÔNG** xoá nội dung cũ đúng
- ❌ **KHÔNG** bỏ qua Design Context (critical cho medical app với người cao tuổi)

---

*Checklist này được tạo tự động dựa trên phân tích 41 file screen trong `PM_REVIEW/REVIEW_MOBILE/Screen/`*
*Cập nhật tiến độ bằng cách check [x] các ô Done khi hoàn thành từng file/module*
