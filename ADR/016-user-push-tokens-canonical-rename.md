# ADR-016: User push tokens — canonical rename `user_fcm_tokens` → `user_push_tokens`

**Status:** Accepted
**Date:** 2026-05-14
**Decision-maker:** ThienPDM (solo)
**Tags:** [database, schema, cross-repo, health_system, healthguard, canonical, push-notification]

## Context

Phase 1 BE-M04 audit phát hiện drift Critical (HS-009) giữa:
- **Canonical SQL** `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` SECTION 16 (line 832): `CREATE TABLE user_fcm_tokens (...)`.
- **Mobile BE ORM** `health_system/backend/app/models/push_token_model.py:13`: `__tablename__ = "user_push_tokens"`.
- **HealthGuard Prisma** `HealthGuard/backend/prisma/schema.prisma`: có CẢ HAI model `user_fcm_tokens` (line 474, ZOMBIE — không consumer) và `user_push_tokens` (line 522, ACTIVE — match production reality).

Hệ quả nếu deploy DB qua canonical hiện tại:
- Mobile BE FCM register/dispatch raise `ProgrammingError: relation "user_push_tokens" does not exist`.
- HealthGuard backend `user_fcm_tokens.findMany()` trả rỗng (table tồn tại nhưng không bao giờ ghi).

Production reality (verify qua HealthGuard backend code + mobile BE service):
- Bảng thực tế đang dùng = `user_push_tokens` (15+ query references trong `push_notification_service.py`, `notification_service.py`, `probe_test_data.py`).
- Field set production: `id, user_id, token (TEXT), platform CHECK IN (android/ios/web), device_id (nullable, FK devices ON DELETE SET NULL), is_active, last_sync_at, created_at, updated_at, UNIQUE(user_id, token)`.

Constraints:
- PM_REVIEW canonical SQL phải match production (không break mobile BE ORM).
- Tên `user_push_tokens` phù hợp hơn vì system support FCM (Android/Web) + APNs (iOS) + future channels — không nên brand-lock vào "fcm".
- Steering rule `25-docs-sql.md`: PM_REVIEW là canonical, nhưng khi lệch production → update canonical theo reality (Option B), không bắt production rebuild ngược lại.

## Decision

**Chose:** Option B — Rename canonical `user_fcm_tokens` → `user_push_tokens`, thêm 2 column `device_id` (nullable FK) + `last_sync_at` (TIMESTAMPTZ).

**Why:**

1. **Production đã dùng `user_push_tokens` từ lâu.** Mobile BE ORM + HealthGuard Prisma đều có model active. Đảo ngược canonical là phá production.
2. **Tên `user_push_tokens` đúng phạm vi hơn.** `user_fcm_tokens` brand-lock Firebase. System đã support APNs (`platform IN ('android', 'ios', 'web')`).
3. **2 column thêm vào (`device_id`, `last_sync_at`) đã có ở mobile BE ORM** — sync canonical theo production để eliminate drift, không thêm field mới ngoài production.

## Options considered

### Option A (rejected): Keep canonical `user_fcm_tokens`, force production rename ngược lại

**Description:** Giữ `user_fcm_tokens` trong canonical, yêu cầu mobile BE + HealthGuard rename ORM/Prisma thành `user_fcm_tokens`.

**Pros:**
- Canonical không thay đổi.

**Cons:**
- Phải sửa 15+ query references trong mobile BE.
- Phải sửa Prisma schema HealthGuard + chạy migration rename ngược.
- Tên `user_fcm_tokens` brand-lock Firebase, sai semantic khi support APNs.
- Lượng code change > 5 lần Option B mà không giải quyết vấn đề thực.

**Why rejected:** Anti-pattern. Canonical đáng lẽ phải lead production, nhưng khi production đã ổn định và canonical là cái drift → update canonical (cheap), không rebuild production (expensive + risky).

### Option B (chosen): Rename canonical `user_fcm_tokens` → `user_push_tokens`, thêm 2 column

**Description:** Update `init_full_setup.sql` SECTION 16 + source file `16_verify_bp_columns_and_fcm_tokens.sql` rename table thành `user_push_tokens`. Thêm column `device_id` (FK devices nullable) + `last_sync_at`. Migration script `20260514_user_push_tokens_canonical_align.sql` cho production DB chưa rename.

**Pros:**
- Match production reality 100% — eliminate Critical drift HS-009.
- Sequence với Session C BLOCK 8 (drop Prisma zombie model `user_fcm_tokens`) là clean.
- Tên `user_push_tokens` đúng phạm vi multi-channel.

**Cons:**
- Canonical thay đổi (acceptable — đó là intent của Phase 4).
- Migration script production phải chạy theo thứ tự sau Session C BLOCK 8.

**Effort:** S (~30min — canonical update + migration script + ADR).

### Option C (rejected): Keep cả 2 table song song

**Description:** Canonical giữ `user_fcm_tokens`, mobile BE giữ `user_push_tokens`, viết view bridge `user_fcm_tokens AS SELECT * FROM user_push_tokens`.

**Pros:**
- Backward-compat với code legacy đọc `user_fcm_tokens`.

**Cons:**
- 2 view name confuse maintainer.
- Performance overhead 0 nhưng cognitive overhead cao.
- Không fix root cause.

**Why rejected:** Workaround, không phải fix.

---

## Consequences

### Positive

- HS-009 Critical drift resolved.
- Canonical match production — no more deploy-time landmine.
- Tên table chuẩn hóa multi-channel push.
- Foundation cho Phase 5+ implement APNs + multi-device push routing (qua `device_id`).

### Negative / Trade-offs accepted

- Migration production phải sequence sau Session C BLOCK 8 (HG Prisma drop zombie). Em accept dependency lock này — risk acceptable vì Session C task đã planned trước.
- Source file `16_verify_bp_columns_and_fcm_tokens.sql` filename còn chứa "fcm" — không rename file vì breaking script index (08, 16, 17 sequence). Filename là legacy, content updated.

### Follow-up actions required

- [x] Update canonical `init_full_setup.sql` SECTION 16 — rename + 2 column.
- [x] Update source `16_verify_bp_columns_and_fcm_tokens.sql` (PART 2 + PART 3) — rename + 2 column + comments.
- [x] Tạo migration `20260514_user_push_tokens_canonical_align.sql`.
- [ ] Session C BLOCK 8 — drop Prisma zombie `user_fcm_tokens` model (HealthGuard).
- [ ] Apply migration production — chỉ sau Session C BLOCK 8 merge.
- [ ] Mobile BE ORM verify match canonical (push_token_model.py đã match — no change needed).

## Reverse decision triggers

- Nếu APNs/web push bị drop khỏi scope → có thể rename ngược về `user_fcm_tokens` (unlikely).
- Nếu phát sinh provider thứ 3 (Huawei HMS) cần partition table → revisit.

## Related

- UC: — (infra concern, no UC)
- ADR: complements ADR-010 (devices canonical), ADR-012 (drop dead fields)
- Bug: triggered by **HS-009** (Critical, BE-M04 audit)
- Code: `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql:832`, `PM_REVIEW/SQL SCRIPTS/16_verify_bp_columns_and_fcm_tokens.sql`, `health_system/backend/app/models/push_token_model.py:13`
- Spec: `PM_REVIEW/AUDIT_2026/tier2/health_system/BE_M04_models_audit.md`

## Notes

Sequence point cross-session: Session B BLOCK 1 (canonical update — code only) merge OK independent. Production migration apply phải đợi Session C BLOCK 8 (HG Prisma drop zombie).
