# ADR-009: Avatar storage = Supabase (mobile) — intentional cross-repo split với R2 (admin AI)

**Status:** Accepted
**Date:** 2026-05-12
**Decision-maker:** ThienPDM (solo)
**Tags:** [architecture, mobile-frontend, health_system, healthguard, cross-repo, storage, scope]

## Context

Hệ thống VSmartwatch có 2 use case storage cho file binary:

1. **Mobile avatar (UC005 PROFILE):** Mobile user chụp/chọn ảnh đại diện, upload qua app Flutter, hiển thị trên profile + family screens.
   - Size: ~5MB max (BR-005-03 JPG/PNG)
   - Frequency: Low write (1-2 lần/user lifetime), high read (mỗi screen render)
   - Latency yêu cầu: < 5 giây upload, instant CDN read
   - Auth: User-scoped (`<userId>/<timestamp>.<ext>` path)

2. **AI model artifacts (UC AI_MODELS):** Admin upload AI model `.pt`/`.pkl`/`.onnx` files cho retrain workflow.
   - Size: ~100-500MB per model version
   - Frequency: Low write (mỗi version mới), low read (chỉ khi load runtime)
   - Latency yêu cầu: Không strict
   - Auth: Admin-only, signed URL pattern (ADR-007)

Phase 0.5 audit (`AUDIT_2026/tier1.5/intent_drift/health_system/PROFILE.md`) reveal:

- **Mobile FE đã setup Supabase Storage** (verified `lib/core/services/avatar_storage_service.dart` 131 lines + `main.dart:36-42` `Supabase.initialize()`)
- **Admin BE đã setup R2** (Cloudflare R2, ADR-007 chosen)
- **0 ADR document quyết định Supabase mobile** — implementation đã có nhưng decision chưa capture

Q1 cũ trong intent doc PROFILE assume "R2/S3" generic → audit phát hiện thực tế là Supabase + cross-repo inconsistency cần document.

### Forces

- **Solo dev, đồ án 2 scope** — không có capacity migrate dual storage backends.
- **Karpathy surgical** — implementation đã tồn tại working, không refactor "for consistency" alone.
- **Use case khác nhau** — avatar (5MB user content) vs AI model (500MB admin artifact) có requirements khác (auth, latency, CDN, lifecycle).
- **Cost** — Supabase free tier đủ avatar (1GB+ với compression); R2 free tier đủ AI artifacts (10GB).
- **Existing code:** Mobile FE Supabase implementation đã working đúng pattern Q1 Option A (FE upload → BE accept URL).

### Constraints

- KHÔNG migrate Supabase → R2 (cost effort cao, ROI thấp đồ án 2).
- KHÔNG migrate R2 → Supabase (conflict ADR-007 chosen R2 cho AI artifacts; Supabase storage class limit pricing tier).
- Bridge giữa 2 backends qua URL string trong DB (`users.avatar_url` field) — single source of truth.

## Decision

**Chose:** Option A — Keep intentional split: **Mobile FE = Supabase Storage** cho user avatar, **Admin BE = Cloudflare R2** cho AI artifacts. Document cross-repo decision trong ADR này.

**Why:** Implementation existing both sides đã working. Use case khác nhau (avatar consumer-facing latency-sensitive vs AI artifact admin batch). Migrate cost cao, ROI thấp đồ án 2. Document split intentional thay vì migrate sang single backend "for consistency".

## Options considered

### Option A (chosen): Keep split — Supabase mobile + R2 admin AI

**Description:**

- **Mobile FE (`health_system/lib`):**
  - `AvatarStorageService` upload trực tiếp Supabase qua `supabase_flutter` package
  - Bucket `avatars` (default) hoặc env `SUPABASE_AVATAR_BUCKET`
  - Path: `<userId>/<timestamp>.<ext>` với cleanup old avatars
  - Cache-busting `?v=<timestamp>` query param
  - Public URL pattern: `https://<project-ref>.supabase.co/storage/v1/object/public/<bucket>/<path>?v=<ts>`
- **Mobile BE (`health_system/backend`):**
  - Accept `avatar_url: str | None` trong `ProfileUpdateRequest`
  - Phase 4: Add Pydantic validator whitelist Supabase domain (D-PRO-D)
  - KHÔNG xử lý upload, KHÔNG có Supabase SDK
- **Admin BE (`HealthGuard/backend`):**
  - R2 cho AI model artifacts (ADR-007)
  - KHÔNG đụng avatar
- **DB (shared `users.avatar_url`):**
  - Field varchar string, single source of truth
  - Mobile BE write/read; admin BE chỉ read (cho user mgmt screen)

**Pros:**
- Working code không phải refactor — Karpathy surgical
- Use case fit: Supabase free tier có CDN + RLS rules dễ setup cho user-uploaded content; R2 cost effective cho large blob admin
- Independent scaling: avatar load (high read) không ảnh hưởng AI artifact load (batch)
- Mobile FE Supabase pattern đã có cleanup old avatars + cache-busting (mature)

**Cons:**
- Cross-repo learning burden: developer phải hiểu 2 storage backends
- Backup/migration strategy phải maintain 2 procedures
- Vendor lock-in spread (Supabase + Cloudflare R2)
- Bucket policy maintenance ở 2 chỗ (Supabase RLS + R2 access control)

**Effort:** ~20min (chỉ document ADR + Phase 4 add validator)

### Option B (rejected): Consolidate sang R2 (mobile + admin)

**Description:**
- Migrate mobile FE từ Supabase → R2
- Add R2 client cho `avatar_storage_service.dart`
- Setup R2 bucket cho avatars + presigned URL flow
- Update mobile BE validator whitelist R2 domain
- Migrate existing avatar files từ Supabase bucket → R2 bucket
- Drop `supabase_flutter` dependency

**Pros:**
- Single storage backend cross-repo
- Single backup/migration procedure
- Consolidate vendor lock-in (chỉ Cloudflare)
- Reduce dependency tree mobile FE

**Cons:**
- **Effort cao:** ~3-4h migrate code + setup R2 mobile + migrate data
- R2 không có built-in RLS như Supabase → phải implement signed URL flow ở BE
- R2 mobile SDK ít mature hơn `supabase_flutter` (Cloudflare focus server-side)
- Existing avatar URLs trong DB phải migrate (data migration risk)
- ROI thấp: working code + 0 user complaint

**Why rejected:** Effort/cost cao cho refactor không có user-facing value. Vendor consolidation là nice-to-have, không must-have đồ án 2. Phase 5+ revisit nếu Cloudflare adds RLS-equivalent feature hoặc nếu cost/ops complexity tăng.

### Option C (rejected): Consolidate sang Supabase (mobile + admin)

**Description:**
- Move admin AI artifacts từ R2 → Supabase Storage
- Reverse ADR-007 (R2 chosen for AI artifacts)
- Setup Supabase bucket cho large blob
- Update admin BE upload code

**Pros:**
- Single storage backend cross-repo
- Supabase free tier có thể đủ (depend on AI artifact size growth)

**Cons:**
- **Conflict ADR-007** (chose R2 for AI artifacts)
- Supabase storage pricing tier-based — large blob (500MB+) push lên paid tier nhanh
- Admin BE phải refactor R2 client + signed URL flow → Supabase
- Effort ~6-8h refactor + supersede ADR-007
- Reverse decision vừa make → red flag governance

**Why rejected:** Conflict ADR-007 + Supabase không phù hợp large blob (AI model 100-500MB) cost-wise. Effort overkill.

### Option D (rejected): Use BE upload endpoint (`POST /profile/avatar`)

**Description:**
- Mobile FE pass file qua multipart form-data về mobile BE
- Mobile BE validate size + format
- Mobile BE upload file vào Supabase / R2
- Return URL về client

**Pros:**
- Centralized validation (5MB JPG/PNG enforced server-side)
- Auth check tại BE trước khi upload
- Hide storage backend từ FE (BE swap dễ tương lai)

**Cons:**
- Effort ~2h refactor mobile BE + add file handling
- BE load tăng (file pass-through)
- Latency tăng (FE → BE → Storage round-trip thay vì FE → Storage direct)
- Existing FE flow (Supabase direct) hoạt động tốt → refactor không có user value
- Supabase RLS có thể enforce auth + size hash check tốt như BE-side

**Why rejected:** Existing direct upload pattern là industry standard mobile + giảm BE load. Phase 4 add Pydantic validator domain whitelist (D-PRO-D) đủ defensive cho BE accept URL pattern.

---

## Consequences

### Positive

- **Karpathy surgical:** Working code không phải refactor — capture decision intentional
- **Cost effective:** Free tier Supabase đủ avatar (mobile users < 1000 đồ án 2); R2 đủ AI artifacts → $0/month base case
- **Use case fit:** Supabase RLS + CDN tự nhiên cho user content; R2 cost effective cho admin blob
- **Independent scaling:** Avatar request load không ảnh hưởng AI artifact bandwidth
- **Existing maturity:** Mobile FE Supabase code có cleanup + cache-busting (battle-tested pattern)

### Negative / Trade-offs accepted

- **2 vendor lock-in (Supabase + Cloudflare R2):** Em accept vì single vendor lock-in cũng risky; spread rủi ro across 2 vendors free tier OK đồ án 2
- **2 bucket policy procedures (Supabase RLS + R2 access control):** Em accept và document trong runbook khi deploy production
- **Cross-repo cognitive load:** Developer phải hiểu 2 storage backends — em accept và document trong README + ADR này
- **No avatar migration story khi vendor change:** Em accept Phase 5+ revisit nếu Supabase free tier policy thay đổi
- **BE delegated 5MB JPG/PNG validation cho FE + Supabase bucket policy** (BR-005-03): Em accept và Phase 4 audit verify (image_picker config + Supabase bucket file size limit)

### Follow-up actions required

- [ ] **Phase 4: mobile BE add Pydantic validator** `avatar_url` whitelist Supabase domain (D-PRO-D, ~15min)
- [ ] **Phase 4: verify Supabase bucket policy** enforce 5MB max + JPG/PNG/WebP MIME types (BR-005-03 server-side defense)
- [ ] **Phase 4: verify mobile FE `image_picker` config** có `imageQuality` + `maxWidth/maxHeight` để client-side reduce file size trước upload (~10min audit)
- [ ] **Phase 5+: Setup Supabase RLS rules** restrict bucket write theo `<userId>/<*>` path pattern (defense-in-depth)
- [ ] **Phase 5+: Backup procedure document** cho Supabase avatar bucket (separate từ R2 backup)
- [ ] **Phase 5+: Avatar lifecycle rule** Supabase auto-delete files của users đã `deleted_at + 30 days` (consistent với D-PRO-B GDPR retention worker)

## Reverse decision triggers

Conditions để reconsider quyết định này:

- **Supabase free tier policy changes** (vd cap 1GB → 500MB) → cost ROI revisit, có thể migrate sang R2 (Option B)
- **Cloudflare R2 adds RLS-equivalent feature** + Supabase storage costs leo → Option B feasibility tăng
- **AI model artifact size shrink** (vd quantization compress → ~50MB) → Supabase storage tier feasible cho admin → Option C revisit
- **Vendor outage incident** Supabase impact mobile users critical → migrate hoặc multi-region setup
- **Data sovereignty / compliance requirement** (vd Vietnam data residency law) → cả 2 vendors có thể không đáp ứng → revisit storage strategy entirely
- **Production scale beyond 10K users** → cost analysis 2 vendors có thể justify consolidation hoặc self-hosted MinIO

## Related

- **UC:** UC005 Manage Profile (mobile avatar upload)
- **ADR:**
  - Cross-references **ADR-007** (R2 chosen for AI artifacts) — both ADRs together form complete cross-repo storage decision
  - Cross-references **ADR-008** (mobile BE settings drop) — both Phase 0.5 reverify decisions
- **Bug:** Triggered by Phase 0.5 audit findings cho PROFILE intent doc (Q1 cũ assumption R2/S3 mismatch verify code)
- **Code:**
  - **Mobile FE Supabase impl:** `health_system/lib/core/services/avatar_storage_service.dart` (131 lines)
  - **Mobile FE Supabase init:** `health_system/lib/main.dart:36-42`
  - **Mobile BE accept URL:** `health_system/backend/app/schemas/profile.py:55` (Phase 4 add validator)
  - **Mobile BE service:** `health_system/backend/app/services/profile_service.py:54` (no change needed)
  - **Admin BE R2 (cross-repo context):** `HealthGuard/backend/src/services/aiModels.service.js` (R2 client per ADR-007)
- **Spec:** `PM_REVIEW/AUDIT_2026/tier1.5/intent_drift/health_system/PROFILE.md` (Phase 0.5 D-PRO-A decision capture)
- **Env config:**
  - Mobile FE: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_AVATAR_BUCKET` trong `.env.dev` / `.env.prod`
  - Mobile BE: `ALLOWED_AVATAR_HOSTS` (Phase 4 add cho D-PRO-D validator)

## Notes

- **Why không document Supabase ADR ngay khi setup ban đầu?** Anh setup Supabase mobile trước Phase 0.5 audit framework — decision implicit trong code. Phase 0.5 reverify mục đích chính là capture decisions implicit này thành ADR formal.
- **Why split avatar (5MB consumer) vs AI artifact (500MB admin) là intentional good?** Different storage class fit different use case. Supabase Storage = consumer-facing CDN với RLS (good cho avatar). R2 = enterprise blob storage (good cho large admin file). Coupling 2 use case vào 1 backend ép trade-off một bên.
- **Why không phải security risk vendor split?** 2 vendors free tier có cùng baseline security (encryption at rest + HTTPS in transit). Vendor split có thể là defense-in-depth (compromise 1 vendor không leak cả mobile + admin data).
- **Cross-repo coord:** Khi user delete account (D-PRO-B GDPR worker Phase 4) — worker phải gọi Supabase Storage API delete user folder + cleanup avatar files. Em flag follow-up action: worker logic phải have `supabase_admin_client` server-side hoặc dùng Supabase Edge Function trigger.
- **Backward compat:** Avatar URLs hiện tại trong DB là Supabase pattern. Bất kỳ migration tương lai phải convert URLs hoặc dual-read fallback. Em flag prevent surprise breaking change.
