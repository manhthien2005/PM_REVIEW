# ADR-017: UserRelationship default permission flip True (caregiver vitals + alerts)

**Status:** Accepted
**Date:** 2026-05-14
**Decision-maker:** ThienPDM (solo)
**Tags:** [database, schema, health_system, mobile, uc, privacy]

## Context

Phase 1 BE-M04 audit phát hiện default permission drift (HS-012):
- **Canonical SQL** `init_full_setup.sql:121-123`: `can_view_vitals BOOLEAN DEFAULT true`, `can_receive_alerts BOOLEAN DEFAULT true`, `can_view_location BOOLEAN DEFAULT false`.
- **Mobile BE ORM** `relationship_model.py:25-29`: 3 cột nói trên đều `default=False` (Python-side default).

Hệ quả: caregiver mới được link qua UC040 sẽ KHÔNG nhận vitals + alerts mặc định — patient phải tự bật từng quyền. Đối với app y tế mục đích chính là caregiver theo dõi người cao tuổi, default opt-out này phá UX expectation:
- Patient pair caregiver xong → caregiver dashboard rỗng → "đang lỗi gì?".
- Khi vital bất thường, caregiver không nhận push → mất ý nghĩa link relationship.

Trade-off privacy vs utility:
- Vitals + alerts là core value proposition của relationship link. Default off = link không có giá trị.
- Location là phạm vi nhạy cảm hơn (tracking real-time GPS) → giữ default off.
- Medical info (P-4 thêm `can_view_medical_info`) cũng giữ default off vì là PHI sensitive (blood type, medication, allergies).

UC040 acceptance criteria không nói rõ default state, nhưng spec Phase 0.5 update UC040 v2 (BR-040-04) khẳng định "khi pair thành công, caregiver có quyền xem vitals + nhận alert mặc định; quyền chi tiết user có thể edit ở settings sau".

## Decision

**Chose:** Flip `can_view_vitals` + `can_receive_alerts` default từ `False` → `True` trong cả ORM và canonical SQL. `can_view_location` + `can_view_medical_info` giữ `False` (opt-in).

**Why:**

1. **Match canonical SQL (existing source of truth).** Canonical đã có `DEFAULT true`. ORM lệch là drift, không có ADR justify.
2. **UC040 utility yêu cầu access mặc định.** Caregiver phải nhìn được vitals + alert ngay sau pair thành công, không cần bước manual configure.
3. **Privacy granularity.** Vitals + alerts là minimum cần cho monitoring; location + medical info nhạy cảm hơn → giữ opt-in.

## Options considered

### Option A (chosen): Default True cho 2 quyền core (vitals + alerts), giữ False cho 2 quyền nhạy cảm (location + medical_info)

**Description:** Flip ORM `default=True` cho `can_view_vitals` + `can_receive_alerts` để match canonical. Migration `20260514_relationship_default_permission.sql` ALTER COLUMN SET DEFAULT TRUE cho production DB.

**Pros:**
- Match canonical + UX expectation.
- Privacy split rõ: monitoring core vs sensitive data.

**Cons:**
- Em accept rằng rows existing trước migration sẽ giữ giá trị cũ (False explicit). Migration KHÔNG backfill — chỉ change default cho rows mới insert sau này. Caregiver đã link trước Phase 4 phải toggle thủ công nếu muốn enable.

**Effort:** S (~30min - ORM flip + migration + ADR + 4 regression test).

### Option B (rejected): Giữ default False cho cả 4, sửa canonical theo ORM

**Description:** Update canonical `init_full_setup.sql` đổi DEFAULT của 2 cột từ true → false để match ORM.

**Pros:**
- Privacy paranoid mặc định (deny-by-default).

**Cons:**
- Phá UC040 utility — caregiver dashboard rỗng sau pair, UX hỏng.
- Cần rebuild flow UI: thêm step "configure permissions" sau pair → tăng friction lớn.
- Solo dev đồ án 2 không đủ time implement granular permission UI properly.

**Why rejected:** Trade-off sai. UC040 mục tiêu là "share access nhanh" không phải "deny-by-default".

### Option C (rejected): Default True cho cả 4 quyền

**Description:** Flip toàn bộ 4 cột thành DEFAULT true.

**Pros:**
- Đơn giản, đối xứng.

**Cons:**
- Location + medical_info là PHI nhạy cảm, default opt-in vi phạm best practice privacy.
- HS-012 bug file đặc biệt note `can_view_location` + `can_view_medical_info` nên giữ False.

**Why rejected:** Vi phạm privacy posture cho data nhạy cảm.

---

## Consequences

### Positive

- HS-012 Medium drift resolved.
- UC040 caregiver pair flow → ngay lập tức nhận monitoring access.
- Privacy split granular: 2 quyền core opt-out vs 2 quyền sensitive opt-in.

### Negative / Trade-offs accepted

- Rows existing trước migration giữ giá trị cũ - không backfill. Caregiver đã link trước Phase 4 cần toggle thủ công.
- Khi Phase 5+ implement granular permission settings UI, cần document migration backfill này để user audit lại.

### Follow-up actions required

- [x] ORM flip `default=True` cho 2 quyền (BLOCK 3 commit).
- [x] Migration script `20260514_relationship_default_permission.sql`.
- [ ] Apply migration production sau khi merge.
- [ ] Phase 5+: implement granular settings UI cho user toggle 4 permissions per linked contact.

## Reverse decision triggers

- Nếu user/clinician feedback "caregiver thấy data tôi không muốn share" → revisit Option B / Option C variant.
- Nếu compliance audit (HIPAA-like) yêu cầu default-deny → flip ngược + add UC040 step "permission configure".

## Related

- UC: UC040 v2 (BR-040-04 default access vitals + alerts)
- ADR: complements ADR-010 (devices canonical), ADR-016 (push tokens canonical)
- Bug: triggered by **HS-012** (Medium, BE-M04 audit)
- Code: `health_system/backend/app/models/relationship_model.py`, `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:121-123`, migration `20260514_relationship_default_permission.sql`
- Spec: `PM_REVIEW/AUDIT_2026/tier2/health_system/BE_M04_models_audit.md`

## Notes

Migration phải chạy SAU khi mobile BE deploy ORM `default=True` mới, tránh inconsistency window: rows insert sau migration nhưng trước deploy sẽ có DB default True nhưng app default False (Python-side wins).
