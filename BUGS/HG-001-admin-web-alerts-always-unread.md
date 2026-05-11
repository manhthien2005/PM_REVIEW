# Bug HG-001: Admin web hiển thị tất cả alerts là 'unread' do code wrong assumption

**Status:** 🔴 Open
**Repo(s):** HealthGuard (admin web backend)
**Module:** health.service (alerts list endpoint)
**Severity:** Medium
**Reporter:** ThienPDM (self) — surfaced trong Phase -1.A audit
**Created:** 2026-05-11
**Resolved:** _(điền khi resolve)_

## Symptom

Admin web frontend khi list alerts của user → tất cả alerts hiển thị status `'unread'` (không phân biệt alert đã được user đọc hay chưa). Kết quả: admin không thể filter "đã đọc" / "chưa đọc", dashboard count "unread alerts" sai.

## Repro steps

1. Login admin dashboard
2. Mở trang Alerts của 1 user có alerts mix (đã đọc + chưa đọc qua mobile app)
3. Xem column "Status" hoặc filter "Read state"

**Expected:** Hiển thị `read` cho alerts user đã đọc qua mobile (có row trong `notification_reads`), `unread` cho alerts chưa.
**Actual:** Tất cả hiển thị `'unread'`.

**Repro rate:** 100% (deterministic — code path always returns 'unread')

## Environment

- Repo: `HealthGuard/backend@develop` (current)
- File: `HealthGuard/backend/src/services/health.service.js:177-360`

## Root cause (đã identify)

### File: `HealthGuard/backend/src/services/health.service.js`

**Lines 177-181** — comment thừa nhận giả định sai:
```javascript
if (severity) {
  whereClause.severity = severity;
}

// NOTE: Status filter disabled - schema không có read_at, acknowledged_at, expires_at
// Nếu cần tính năng này, phải thêm fields vào schema và migration
```

**Lines 353-358** — hardcode tất cả là `unread`:
```javascript
// Xác định trạng thái - TẠM THỜI set tất cả là 'unread' vì schema không có read_at
let alertStatus = 'unread';

return {
  ...
  status: alertStatus,
  ...
}
```

### Schema reality (verified Phase -1.A)

- `alerts.read_at` cột TỒN TẠI trong canonical SQL (line 456 init_full_setup.sql) + Prisma schema (line 27)
- Tuy nhiên `alerts.read_at` không được mobile backend write — health_system backend dùng `notification_reads (user_id, alert_id, read_at)` thay
- Admin code đọc canonical SQL cũ (không có `read_at`) → comment "schema không có" → hardcode unread

### Why bug exists

- Schema migration thêm `alerts.read_at` đã được apply nhưng admin team không update code
- Mobile backend chuyển sang `notification_reads` mà admin team chưa pivot
- Symptom: 2 nơi lưu read state, admin code không đọc nơi nào

## Investigation

### Hypothesis log

| # | Hypothesis | Status |
|---|---|---|
| H1 | Admin code chỉ cần đọc `notification_reads` table thay vì hardcode | ⏸️ Not yet implemented |
| H2 | Per-user read state có nhiều records (1 alert × N caregivers) → admin cần aggregate logic | ⏸️ Need design decision |

### Attempts

_(Chưa attempt fix — bug surfaced trong Phase -1.A audit, defer Phase 4 refactor)_

## Resolution

_(Fill in when resolved — Phase 4 target)_

**Fix approach (planned):**

1. **Option A — Source from `notification_reads`** (recommended):
   - JOIN `alerts a LEFT JOIN notification_reads nr ON nr.alert_id = a.id`
   - Status logic:
     - Nếu admin xem alert của user X: check `notification_reads WHERE user_id=X AND alert_id=A`
     - Hoặc aggregate: alert "read by anyone" vs "fully unread"
   - Cần design decision: admin view = recipient-specific hay system-wide?

2. **Option B — Use `alerts.read_at`** (legacy):
   - Đọc `alerts.read_at` (tồn tại nhưng không được mobile BE write)
   - Sẽ đọc `null` cho mọi alert → bug không fix
   - **Reject** option này

**Test added (planned):** `HealthGuard/backend/src/__tests__/services/health.service.test.js` — `describe('getAlerts', () => { it('returns read=true for alerts user marked read on mobile') })`

**Verification:** Manual repro:
1. User mark 1 alert as read trên mobile app (POST `/notifications/{id}/read`)
2. Admin dashboard list alerts của user → verify `status='read'` cho alert đó

## Related

- **Phase -1.A finding:** `@/d:/DoAn2/VSmartwatch/PM_REVIEW/AUDIT_2026/tier1/db_canonical_diff.md` § Drift D-003 + Bonus finding
- **Linked bug:** [PM-001](./PM-001-pm-review-spec-drift.md) — systemic drift (parent context)
- **UC:** UC028 — Health Overview (admin web alerts dashboard)
- **Blocked by:** Phase 4 (refactor execution) — không fix sớm hơn vì cần design decision về aggregate logic

## Notes

- Bug **không** ảnh hưởng mobile UX (mobile dùng `notification_reads` đúng)
- Bug **không** block production deploy (admin still functional, chỉ thiếu read filter)
- Severity = Medium vì có workaround (admin scan manually) + không break business flow
- **Fix Phase 4** cùng với deprecation of `alerts.read_at` column (zombie field)
