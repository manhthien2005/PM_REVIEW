# Intent Drift Review — `health_system / PROFILE`

**Status:** ✅ Confirmed Phase 0.5 reverify (Q1-Q4 cũ adjusted với findings code thực tế; Q5 mới về crop tool; 4 add-ons drop)
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE)
**Module:** PROFILE (User self-manage hồ sơ cá nhân + thông tin y tế)
**Related UCs (old):** UC005 Manage Profile
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-12
**Date revised:** 2026-05-12 (Phase 0.5 reverify — Q1+Q2 assumptions corrected; Q5 added)
**Question count:** 5 (Q1-Q4 revised + Q5 new crop tool)

---

## 🔄 Phase 0.5 Reverify — Adjustments to Q1-Q4 cũ

> **Override scope:** Q1-Q4 cũ đúng **direction** nhưng sai 2 **assumption foundational**. Q5 mới thêm sau khi verify UC005 spec gap. PROFILE module ACTIVE (FE consume đầy đủ), KHÔNG drop được như SETTINGS.
>
> **3 corrections:**
>
> 1. **Q1 storage assumption SAI:** intent doc cũ ghi "R2/S3" → mobile FE thực tế dùng **Supabase Storage** (`avatar_storage_service.dart` 131 dòng full impl + `main.dart:36-42` `Supabase.initialize()`). Pattern Q1 Option A vẫn đúng (FE upload, BE accept URL); chỉ sai provider.
> 2. **Q2 archive table assumption SAI:** intent doc cũ "skip table sunk cost" → bảng `users_archive` **THỰC TẾ TỒN TẠI** trong canonical (`12_create_users_archive.sql` + `init_full_setup.sql:707-721`). Code BE chưa dùng → implementation gap, không phải design gap.
> 3. **Q5 mới:** UC005 Alt 3.a.4 + NFR Usability spec "Crop và upload ảnh" + "Avatar crop tool tích hợp" → FE chưa có `image_cropper` package. Spec gap cần đóng sổ.
>
> **Decisions revised (Phase 0.5):**
> - Q1 → A1: Keep Supabase mobile-only + tạo ADR-009 document quyết định
> - Q2 → A2: Implement đúng UC005 BR-005-09 (insert archive + APScheduler worker hard-delete vitals/motion sau 30 ngày). App Store / Google Play yêu cầu mandatory account deletion từ 2022.
> - Q3 keep — add validator length ≤ 200
> - Q4 → A4: Add validator NHƯNG whitelist Supabase domain (không R2)
> - Q5 → B5: Remove crop requirement khỏi UC005 (anh decision đồ án 2 scope reduce)
>
> **Detailed reasoning + verify evidence:** xem section "Em verified Phase 0.5" + "Anh's revised decisions" dưới đây. Q1-Q4 cũ giữ làm audit trail (status: REVISED/SUPERSEDED).

---

## 🎯 Mục tiêu

Capture intent cho PROFILE module mobile BE + FE. UC005 cũ làm memory aid. Phase 0.5 reverify phát hiện 3 drift quan trọng với assumptions Q1-Q4 cũ. Output = UC005 v2 (Q5 crop removal) + ADR-009 storage + decisions log revised + Phase 4 backlog updated.

---

## 📚 UC005 cũ summary (memory aid)

- **Actor:** Bệnh nhân, Người chăm sóc
- **Main:** View/update profile + thông tin y tế (ảnh hưởng AI Risk UC016)
- **Alt 3.a:** Update avatar (Chụp ảnh / Chọn từ thư viện)
- **Alt 3.b:** Medical history checklist (Cao huyết áp, Tim mạch, Tiểu đường, Đột quỵ, Khác)
- **Alt 3.c:** Medical info (blood type, height, weight, medications, allergies)
- **Alt 3.d:** Delete account (GDPR/App Store compliance)
- **BR-005-01:** Email readonly
- **BR-005-03:** Avatar ≤ 5MB JPG/PNG
- **BR-005-04:** Audit log mọi thay đổi
- **BR-005-05:** SĐT 10-11 số, bắt đầu bằng 0
- **BR-005-06:** Blood type enum (8 values)
- **BR-005-07:** Height 50-250cm, weight 2-500kg
- **BR-005-08:** Medications/allergies danh sách, mỗi mục ≤ 200 ký tự
- **BR-005-09:** Soft delete + `users_archive` + 30-day retention worker

---

## 🔧 Code state — verified

### Routes (`profile.py`) — 3 endpoints

```
prefix=(none), tags=[mobile-profile]

GET    /profile        Get current user profile
PUT    /profile        Update profile (audit log với IP + UA)
DELETE /profile        Delete account (require password + audit log)
```

### Pydantic schema (`schemas/profile.py`) — verified

**✅ Aligned với UC005:**
- `ProfileResponse`: email readonly (không có trong UpdateRequest) ✓ BR-005-01
- `ProfileUpdateRequest`:
  - `phone` validator: 10-11 số, bắt đầu bằng 0 ✓ BR-005-05
  - `blood_type` enum 8 values ✓ BR-005-06
  - `height_cm` 50-250, `weight_kg` 2-500 ✓ BR-005-07
  - `gender` VI→EN translation ✓ (UC says "Nam/Nữ/Khác")
  - `medical_conditions` enum: `hypertension, heart_disease, diabetes, stroke, other` ✓ BR-005-03 Alt 3.b
  - `full_name` Vietnamese regex ✓
  - `date_of_birth` age validator ✓
- `DeleteAccountRequest`: password required ✓ Alt 3.d.3

### Service (`profile_service.py`) — verified

**✅ Aligned:**
- `verify_password` check trong `delete_account` (line 89) ✓ Alt 3.d.3
- `AuditLogRepository.log_action` cho `profile.update` + `profile.delete_account` ✓ BR-005-04
- Audit log details: `fields_updated` list ✓ trace nice
- `deleted_at = NOW()` soft delete ✓ BR-005-09 (partial)

### 🟡 Drift findings (Phase 0.5 reverify)

1. **Avatar storage = Supabase, KHÔNG phải R2/S3 (Q1 cũ sai assumption):**
   - Mobile FE: `avatar_storage_service.dart:1-131` full impl Supabase
   - `main.dart:36-42` gọi `Supabase.initialize()` với `SUPABASE_URL` + `SUPABASE_ANON_KEY` env
   - Bucket: `avatars` (default) hoặc env `SUPABASE_AVATAR_BUCKET`
   - Path: `<userId>/<timestamp>.<ext>` với cleanup old avatars
   - Cache-busting `?v=<timestamp>` trong public URL
   - **Cross-repo:** admin web (HealthGuard) dùng R2 cho AI artifacts (ADR-007). Mobile Supabase, admin R2 → intentional split (use case khác: avatar ~5MB vs AI model ~100MB+).
   - **Mobile BE:** 0 match `supabase` — BE chỉ accept URL string, không xử lý upload
   - BR-005-03 Avatar ≤ 5MB JPG/PNG validation **delegated to FE** (image_picker config) + Supabase bucket policy
   - → Pattern Q1 Option A đúng; ADR mới document Supabase choice

2. **BR-005-09 `users_archive` table TỒN TẠI (Q2 cũ sai assumption):**
   - **Table có trong canonical:** `12_create_users_archive.sql:1-34` + `init_full_setup.sql:707-721`
   - Schema: `id, original_id, uuid, email, user_data JSON, archived_at, archived_by`
   - **Code BE KHÔNG insert vào table:** `profile_service.py:94-96` chỉ `deleted_at + is_active = false`
   - 0 match `users_archive` trong `health_system/backend` — implementation gap, không design gap

3. **BR-005-09 30-day retention worker MISSING:**
   - 0 match `apscheduler|account_deletion_cleanup` trong `health_system/backend`
   - Không có folder `app/jobs/` hoặc tương đương
   - GDPR/App Store compliance gap (mandatory cho mobile app store deploy từ 2022)

4. **BR-005-08 medications/allergies length validation MISSING:**
   - Code `schemas/profile.py:65-66`: `medications: list[str] | None` + `allergies: list[str] | None` — không validate length per item
   - UC005 Data Requirements table line 103-104 confirm "≤ 200 ký tự" (text Business Rules chỉ nói "danh sách thêm/xóa" — spec inconsistency UC text vs Data Req table)

5. **🔴 Avatar crop tool MISSING (Q5 mới):**
   - UC005 Alt 3.a.4: "Crop và upload ảnh, hiển thị preview"
   - UC005 NFR Usability: "Avatar crop tool tích hợp"
   - 0 match `image_cropper|ImageCropper|crop_tool` trong mobile FE
   - `_pickAndUploadAvatar()` chỉ pick → upload, không crop
   - → Spec gap cần decision: implement crop hay reduce UC scope

### ✅ Code state đúng spec (verified)

- BR-005-01 Email readonly: `ProfileResponse` có email, `ProfileUpdateRequest` không có → enforced schema-level ✓
- BR-005-04 Audit log với IP+UA: `update_profile` + `delete_account` đều có `ip_address` + `user_agent` + `AuditLogRepository.log_action` ✓
- BR-005-05 SDT validator 10-11 số bắt đầu 0 ✓
- BR-005-06 Blood type enum 8 values ✓
- BR-005-07 Height 50-250cm, weight 2-500kg ✓ (note: weight `lt=500` strict mắc hỗn đồng bộ với DB CHECK)
- Alt 3.d.3 Re-auth password: `verify_password(payload.password, user.password_hash)` line 89 ✓
- BR-005-02 Medical conditions enum 5 values: `MEDICAL_CONDITION_KEYS` validator ✓

### 🔍 Mobile FE consumer — ACTIVE (khác SETTINGS dead)

- `lib/features/profile/screens/profile_screen.dart` — GET profile + display avatar
- `lib/features/profile/screens/edit_profile_screen.dart` — PUT profile + Supabase upload
- `lib/features/profile/screens/medical_info_screen.dart` — PUT medical fields
- `lib/features/profile/providers/profile_provider.dart` — proxy GET/PUT
- `lib/features/family/widgets/*` — RemoteAvatar consume `avatarUrl` cross-feature

→ **DROP NOT applicable**. Phải fix forward.

---

## 💬 Anh react block (history — Q1-Q4 REVISED bởi Phase 0.5 reverify)

> 4 câu cũ — module có UC chi tiết nhưng 3 GDPR/compliance gaps.
> **Status:** ⚠️ Q1+Q2 có assumption SAI → REVISED với reasoning mới. Q3+Q4 keep direction nhưng adjust details. Q5 mới thêm.

---

### Q1: ⚠️ REVISED — Avatar upload — endpoint missing + storage strategy

**Drift:**
- UC Alt 3.a nói "Chụp ảnh / Chọn từ thư viện" + crop tool → flow upload file
- Code: `avatar_url: str | None` accept URL only (FE-side upload)
- BR-005-03 Avatar ≤ 5MB JPG/PNG validation **không có ở BE**

**Em recommend:**
- **Option A — Keep current pattern (FE upload, BE accept URL):** Document trong UC v2 rằng FE upload sang Cloudflare R2 / S3 trước, BE chỉ persist URL. BE validate URL pattern (must be storage domain whitelist).
- **Option B — Add BE upload endpoint `POST /profile/avatar`:** Multipart form-data, BE validate size + format + upload vào R2, return URL. Effort ~2h + R2 service consistency với HealthGuard.

**Em prefer:** **Option A** — mobile pattern phổ biến (FE upload trực tiếp + presigned URL), giảm BE load. BE thêm URL whitelist validation (~30min).

**Anh decision (REVISED):**
- ✅ **Em recommend (Option A — FE upload, BE accept URL + whitelist)** ← anh CHỌN sáng 2026-05-12
- ⚠️ **Phase 0.5 reverify (chiều 2026-05-12):** Đúng direction; provider thực tế là **Supabase Storage** không phải R2/S3. Anh chốt **A1 — Keep Supabase mobile-only** + tạo ADR-009 document.
- ☐ Option B (BE upload endpoint, full control + size validation)
- ☐ Skip avatar feature (đồ án 2 không cần)
- ☐ Khác: ___

---

### Q2: ⚠️ REVISED — BR-005-09 GDPR compliance — `users_archive` + 30-day worker

**Drift critical:**
- UC nói: Soft delete → copy vào `users_archive` → 30 ngày sau worker xóa vitals/motion data
- Code: CHỈ `deleted_at = NOW()`, KHÔNG có users_archive + KHÔNG có worker

**Implications:**
- GDPR "right to be forgotten" compliance gap
- App Store/Google Play yêu cầu account deletion → 30-day data retention chuẩn industry

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| **A. Implement full (Phase 4)** | GDPR + App Store compliant; UC chuẩn | Effort ~4-6h (schema + worker + tests) |
| **B. Defer Phase 5+** | Phase 4 focus user-facing fixes | Compliance debt; risky cho production deploy |
| **C. Minimal (no archive table, worker only):** | Easier; data tự xóa sau 30 ngày | Mất "archive" historical reference |

**Em recommend:**
- **Option C — Minimal** (~2h Phase 4):
  - Skip `users_archive` table (sunk cost cho đồ án 2)
  - Add worker `app/jobs/account_deletion_cleanup.py` với APScheduler chạy daily
  - Worker scan `users.deleted_at < NOW() - 30 days` → hard delete vitals/motion data của user
  - Audit log `system.user_data_purged` per user
- Effort ~2h + UC v2 update

**Anh decision (REVISED):**
- ✅ **Em recommend (Option C — minimal worker, no archive table)** ← anh CHỌN sáng 2026-05-12 (assumption: table không tồn tại)
- ⚠️ **Phase 0.5 reverify:** Table `users_archive` **THỰC TẾ TỒN TẠI** trong canonical → "skip sunk cost" reasoning sai. Anh chốt **A2 — Implement đúng UC005 BR-005-09**: insert archive khi delete + APScheduler worker hard-delete vitals/motion sau 30 ngày. App Store / Google Play yêu cầu mandatory account deletion từ 2022.
- ☐ Option A original (full users_archive + worker, ~4-6h) — gần giống A2
- ☐ Option B (defer Phase 5+, accept compliance debt)
- ☐ Khác: ___

---

### Q3: ✅ KEEP — BR-005-08 medications/allergies length validation

**Drift:**
- UC: mỗi item trong medications/allergies ≤ 200 ký tự
- Code: `list[str] | None` không validate length per item

**Em recommend:**
- **Add `field_validator`** trong Pydantic:
  ```python
  @field_validator('medications', 'allergies')
  def validate_item_length(cls, value):
      if value is None: return None
      for item in value:
          if len(item) > 200:
              raise ValueError(f"Mỗi mục ≤ 200 ký tự")
      return value
  ```
- Effort ~10min

**Anh decision (KEEP):**
- ✅ **Em recommend (add per-item length validator)** ← anh CHỌN, Phase 0.5 reverify confirm — spec UC005 Data Requirements table line 103-104 explicit "≤ 200 ký tự"

---

### Q4: ⚠️ REVISED — Avatar URL field validation (URL format + storage scope)

**Issue (depend Q1):**
- Nếu Q1 chọn Option A (FE upload): BE cần whitelist storage domain để chống abuse (FE pass URL malicious)
- Currently: `avatar_url: str | None` accept any string

**Em recommend (Q1 Option A path):**
- **Add validator:**
  ```python
  ALLOWED_AVATAR_DOMAINS = {'r2.cloudflarestorage.com', 'pub-xxx.r2.dev'}  # env config
  
  @field_validator('avatar_url')
  def validate_avatar_url(cls, value):
      if value is None: return None
      # validate URL format + domain whitelist
  ```
- Effort ~15min

**Anh decision (REVISED):**
- ✅ **Em recommend (add URL + domain whitelist validator)** ← anh CHỌN sáng 2026-05-12 (depend Q1 Option A)
- ⚠️ **Phase 0.5 reverify:** Validator concept vẫn đúng; whitelist domain phải **Supabase** không R2. **A4 — Add Supabase whitelist validator** Phase 4.
- ☐ Skip (trust FE, đồ án 2)
- ☐ Khác: ___

---

### Q5: 🆕 NEW — Avatar crop tool (UC005 spec gap)

**Drift discovered Phase 0.5:**
- UC005 Alt 3.a.4: "Crop và upload ảnh, hiển thị preview"
- UC005 NFR Usability: "Avatar crop tool tích hợp"
- 0 match `image_cropper|ImageCropper|crop_tool` trong mobile FE
- `_pickAndUploadAvatar()` chỉ pick → upload, không crop

**Trade-off:**

| Approach | Pros | Cons |
|---|---|---|
| **A5. Add `image_cropper` package** | Match UC005 spec; standard mobile UX | Effort ~45min FE; thay đổi upload flow |
| **B5. Remove crop requirement khỏi UC005** | Reduce scope đồ án 2; FE flow hiện tại đủ dùng | Spec downgrade; UI editing thiếu so với industry standard |
| **C5. Defer Phase 5+** | Plan task riêng | Doc dríft vẫn tồn tại Phase 4-5 |

**Em recommend:** **B5** — đồ án 2 reduce scope, crop nice-to-have không block functional flow. Update UC005 remove "Crop và" trong Alt 3.a.4 + remove "Avatar crop tool tích hợp" trong NFR.

**Anh decision:**
- ✅ **Em recommend (B5 — Remove crop requirement khỏi UC005)** ← anh CHỌN: "Crop anh thấy không cần thiết"
- ☐ A5 (Add `image_cropper` package, ~45min)
- ☐ C5 (Defer Phase 5+)
- ☐ Khác: ___

---

## 🎯 Anh's revised decisions Phase 0.5 — reverify 2026-05-12 (chiều)

### Decisions revised

| ID | Item | Decision Phase 0.5 | Effort Phase 4 |
|---|---|---|---|
| **D-PRO-A** | Avatar storage | **A1 — Keep Supabase mobile-only** + tạo ADR-009 document quyết định | ~20min ADR (Phase 0.5 đã làm) |
| **D-PRO-B** | GDPR retention | **A2 — Implement đúng UC005 BR-005-09** (insert `users_archive` + APScheduler worker hard-delete vitals/motion sau 30 ngày) | ~3-4h Phase 4 |
| **D-PRO-C** | medications/allergies length | **Keep — add Pydantic validator ≤ 200 ký tự** | ~10min Phase 4 |
| **D-PRO-D** | avatar_url whitelist | **A4 — Add Pydantic validator whitelist Supabase domain** (không R2) | ~15min Phase 4 |
| **D-PRO-E** | Avatar crop tool (Q5 mới) | **B5 — Remove crop requirement khỏi UC005** (anh decision đồ án 2 scope reduce) | ~10min Phase 0.5 (UC update) |

### Lý do override Q1-Q4 cũ

1. **Q1 cũ ghi R2/S3** → verify code thực tế là Supabase. Pattern Option A vẫn đúng, chỉ sai provider → ADR-009 document intentional split (mobile Supabase, admin R2 cho AI).
2. **Q2 cũ "skip sunk cost"** → verify table `users_archive` tồn tại → implementation gap không design gap. App Store / Google Play (mandatory từ 2022) yêu cầu account deletion full → implement đúng UC005 BR-005-09 để unblock production deploy future.
3. **Q3 keep** — spec UC005 Data Requirements rows 103-104 confirm "≤ 200 ký tự".
4. **Q4 cũ R2 whitelist** → update Supabase whitelist (consistent với A1).
5. **Q5 mới** — UC005 spec crop tool chưa impl, anh chốt reduce scope → update UC005 remove crop.

### Out-of-scope flag (em không lan scope)

- **Cross-repo storage consolidation** (Supabase ↔ R2) — ADR-009 document split intentional, không migrate. Future revisit nếu use case overlap.
- **Mobile FE BR-005-03 Avatar ≤ 5MB JPG/PNG validation** — delegated FE (image_picker config) + Supabase bucket policy. Em flag em chưa verify image_picker config thực tế có enforce 5MB chưa — audit Phase 2.
- **`weight_kg < 500` strict consistency check** với DB CHECK — em đã verify Pydantic match `lt=500`, nếu DB CHECK khác phải fix — audit Phase 2.
- **`gender` VI↔EN translation edge case** với `null` fallback — em đã verify, không issue.

---

## 🆕 Industry standard add-ons — anh's selection

**Tất cả DROP** để tránh nở scope:

- ❌ **Profile snapshot history** — Phase 5+ compliance enhancement
- ❌ **Avatar thumbnail generation** — FE upload pattern (Q1 Option A), BE không xử lý image
- ❌ **Medical info export PDF** — Phase 5+ feature
- ❌ **Email verification on update** — Phase 5+ security

---

## 🆕 Features mới em recommend

**Không có** — UC005 đã chi tiết, Q1-Q5 đã cover gaps.

---

## ❌ Features em recommend DROP

- **Avatar crop tool** (Q5 → B5): Remove khỏi UC005 Alt 3.a.4 + NFR Usability — anh decision đồ án 2 scope reduce.
- **3 endpoints `/profile` GET/PUT/DELETE:** KHÔNG drop — active feature mobile FE consume đầy đủ (khác SETTINGS dead API).

---

## 📊 Drift summary — Phase 0.5 reverify

### UC delta

| UC cũ | Status | UC mới |
|---|---|---|
| UC005 Manage Profile | **Update v2 (Phase 0.5)** | Alt 3.a.4 remove "Crop và" + NFR remove "Avatar crop tool tích hợp" (Q5 → B5). Other BRs unchanged. |

### Code impact (Phase 4 backlog — revised Phase 0.5)

| Phase 0.5 finding | Decision | Phase 4 task | Severity | Effort |
|---|---|---|---|---|
| Avatar storage = Supabase (Q1 → A1) | ADR-009 + Q4 Supabase whitelist | Doc-only Phase 0.5 (ADR) + Q4 Phase 4 task | 🟢 Doc | ~20min ADR (Phase 0.5) |
| GDPR retention `users_archive` impl (Q2 → A2) | Insert archive + APScheduler worker | `feat: profile_service.delete_account insert users_archive` + `feat: jobs/account_deletion_cleanup.py APScheduler hard-delete vitals/motion sau 30 ngày` | � Compliance | ~3-4h Phase 4 |
| medications/allergies length (Q3 keep) | Add Pydantic validator ≤ 200 | `feat: Pydantic field_validator validate_item_length` | 🟢 Low | ~10min Phase 4 |
| Avatar URL Supabase whitelist (Q4 → A4) | Add Pydantic validator | `feat: Pydantic validator avatar_url Supabase domain whitelist` | 🟢 Low | ~15min Phase 4 |
| Avatar crop tool removal (Q5 → B5) | Update UC005 spec | `docs(uc): UC005 Alt 3.a.4 + NFR remove crop requirement` | 🟢 Doc | ~10min Phase 0.5 (UC update) |

**Estimated Phase 0.5 effort (now):** ~30min (ADR-009 + UC005 update + intent doc đang làm)
**Estimated Phase 4 effort:** ~3.5-4.5h (Q2 dominant + Q3+Q4 small)

### Cross-repo coordination required

- **HealthGuard admin BE:** ✅ No change — R2 cho AI artifacts (ADR-007), không overlap PROFILE
- **health_system mobile BE:** Phase 4 implement Q2 worker + Q3+Q4 validators
- **Mobile FE:** ✅ No code change — đã setup Supabase đúng pattern
- **DB:** Phase 4 verify `users_archive` schema match UC005 spec (column `user_data JSON` đủ store full snapshot)
- **UC005 spec:** Phase 0.5 update remove crop (em đang làm)

---

## 📝 Anh's decisions log

### Active decisions — Phase 0.5 reverify (chiều 2026-05-12)

| ID | Item | Decision | Rationale |
|---|---|---|---|
| **D-PRO-A** | Avatar storage strategy | **A1 — Keep Supabase mobile-only** + ADR-009 document | Verified mobile FE đã setup Supabase đúng pattern; cross-repo split intentional (mobile Supabase / admin R2 cho AI) vì use case khác (avatar ~5MB vs AI model ~100MB+); migrate cost cao không ROI đồ án 2 |
| **D-PRO-B** | GDPR retention | **A2 — Implement đúng UC005 BR-005-09** | Table `users_archive` tồn tại trong canonical, chỉ thiếu impl; App Store / Google Play mandatory từ 2022; effort ~3-4h reasonable; unblock production deploy future |
| **D-PRO-C** | medications/allergies length | **Add Pydantic validator ≤ 200 ký tự** | UC005 Data Requirements table line 103-104 explicit; defense-in-depth |
| **D-PRO-D** | avatar_url whitelist | **A4 — Add Pydantic validator Supabase domain whitelist** | Defense-in-depth (BE accept URL từ client = vector tránh FE manipulated); Supabase domain (không R2) consistent với D-PRO-A |
| **D-PRO-E** | Avatar crop tool (Q5 mới) | **B5 — Remove crop requirement khỏi UC005** | Anh decision "Crop không cần thiết" đồ án 2; functional flow upload đủ dùng không block; Phase 5+ revisit nếu user feedback |

### Superseded decisions — Q1-Q4 cũ (giữ làm audit trail)

| ID | Item | Decision cũ | Status |
|---|---|---|---|
| ~~D-PRO-01~~ | Avatar upload strategy | ~~Option A FE upload + BE whitelist (R2/S3)~~ | ⚠️ **REVISED bởi D-PRO-A** — provider thực tế là Supabase, không R2/S3 |
| ~~D-PRO-02~~ | GDPR retention worker | ~~Option C minimal (skip archive table)~~ | ⚠️ **SUPERSEDED bởi D-PRO-B** — table tồn tại không "sunk cost" |
| D-PRO-03 | medications/allergies length | Add per-item validator ≤ 200 ký tự | ✅ **KEEP** — rất khớp với D-PRO-C |
| ~~D-PRO-04~~ | avatar_url whitelist (R2 domain) | ~~Add R2 domain whitelist validator~~ | ⚠️ **REVISED bởi D-PRO-D** — whitelist Supabase, không R2 |

### Add-ons selection

| Add-on | Decision |
|---|---|
| Profile snapshot history | ❌ Drop (Phase 5+ compliance) |
| Avatar thumbnail generation | ❌ Drop (Q1 Option A, BE không xử lý image) |
| Medical info export PDF | ❌ Drop (Phase 5+) |
| Email verification on update | ❌ Drop (Phase 5+ security) |

**All 4 add-ons dropped** — anh ưu tiên không nở scope.

---

## Cross-references

### UC + Specs

- `PM_REVIEW/Resources/UC/Authentication/UC005_Manage_Profile.md` — **UPDATE Phase 0.5** (Q5 → B5 remove crop requirement)
- UC016 (Risk Report) consume medical info (BR-005-02) — no change
- UC002 (Register) initial profile data — no change

### Code paths (mobile BE — Phase 4 actions)

- `health_system/backend/app/api/routes/profile.py` — no change (3 endpoints active)
- `health_system/backend/app/services/profile_service.py:94-96` — **Phase 4: insert `users_archive` khi `delete_account`** (D-PRO-B)
- `health_system/backend/app/schemas/profile.py:55, 65-66` — **Phase 4: add validators** (D-PRO-C, D-PRO-D)
- `health_system/backend/app/jobs/account_deletion_cleanup.py` — **CREATE Phase 4** APScheduler worker (D-PRO-B)

### Code paths (mobile FE — no change)

- `health_system/lib/core/services/avatar_storage_service.dart` — already Supabase, no change
- `health_system/lib/main.dart:36-42` — already `Supabase.initialize()`, no change
- `health_system/lib/features/profile/screens/edit_profile_screen.dart` — already pick+upload, no change
- `health_system/lib/features/profile/providers/profile_provider.dart` — already PUT proxy, no change

### DB schema

- `PM_REVIEW/SQL SCRIPTS/12_create_users_archive.sql` — table existing, no change
- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:707-721` — table seed, no change
- DB tables: `users` (`deleted_at`, `is_active`), `users_archive` (Phase 4 active), `audit_logs` (existing)

### Related ADR

- **`PM_REVIEW/ADR/009-avatar-storage-supabase-mobile-only.md`** → **CREATE Phase 0.5** (D-PRO-A)
- `PM_REVIEW/ADR/007-r2-artifact-vs-model-api-serving-disconnect.md` — admin AI R2 (cross-repo context)
- `PM_REVIEW/ADR/008-mobile-be-no-system-settings-write.md` — mobile BE pattern reference
