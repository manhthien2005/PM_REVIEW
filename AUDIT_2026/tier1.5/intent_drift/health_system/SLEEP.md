# Intent Drift Review — `health_system / SLEEP` (v2)

**Status:** ✅ Confirmed Phase 0.5 v2 (2026-05-13) — deep verification rewrite, fix 2 claim sai + add 3 drift
**Repo:** `health_system/backend` (mobile FastAPI BE) + `health_system/lib` (mobile FE)
**Module:** SLEEP (Sleep analysis + reporting)
**Related UCs:** UC020 v2 Phân tích giấc ngủ, UC021 v2 Xem báo cáo giấc ngủ
**Phase 1 audit ref:** N/A (health_system Track 2 pending)
**Date prepared:** 2026-05-13

---

## 🎯 Mục tiêu v2

Rewrite doc v1 (2026-05-13 sáng) sau khi deep-dive phát hiện:
- 2 claim sai: Q5 "canonical missing sleep_sessions" hoàn toàn sai (canonical đã có đầy đủ), claim auth cho `/telemetry/sleep` misleading (endpoint thực tế KHÔNG có auth).
- 3 drift MISS: HS-004 (telemetry endpoints no auth, Critical), BR-020-02 min 2h validation không enforce (bundle vào D-SLP-03), UC021 quality_label thresholds hardcode không document trong spec.

v2 = source-of-truth cho Phase 4 backlog SLEEP module.

---

## 📚 UC cũ summary (deprecated post-v2)

### UC020 v1 — Phân tích giấc ngủ (DEPRECATED)
- Main flow server-side batch analyze vitals/motion sau khi user thức.
- Alt 3.a incomplete session, Alt 4.a nap detection.
- BR-020-01 nhiều session/day, BR-020-02 min 2h, BR-020-03 chỉ số analyze.
- BR-Auth-01 can_view_vitals.

### UC021 v1 — Xem báo cáo giấc ngủ (DEPRECATED)
- Main flow report + 7-day chart + timeline.
- Alt 2.a no data, Alt 3.a range filter.
- BR-021-01 score 0-100, BR-021-02 TỐT/TRUNG BÌNH/KÉM, BR-021-03 caregiver perm.

---

## 🔧 Code state — verified deep

### Routes — 4 endpoints

**Ingest (telemetry.py):**
```
POST /mobile/telemetry/sleep              NO AUTH (HS-004 bug), device-side pre-computed session upsert
POST /mobile/telemetry/sleep-risk         NO AUTH (HS-004 bug), ML sleep inference sang risk_scores row
POST /mobile/telemetry/imu-window         NO AUTH (HS-004 bug), IMU raw sang fall model sang fall_events row (scope FALL)
```

**Read (monitoring.py):**
```
GET /mobile/metrics/sleep/latest          JWT user + target_profile_id + can_view_vitals check ✓
GET /mobile/metrics/sleep/history         Same auth ✓
```

### DB schema `sleep_sessions` — canonical ĐÚNG

`PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` section 04 + 18:
- `CREATE TABLE IF NOT EXISTS sleep_sessions` (line 357-371): id, user_id FK, device_id FK, start_time, end_time, sleep_score, phases JSONB, wake_count.
- `ALTER TABLE ... ADD COLUMN IF NOT EXISTS sleep_date DATE` (section 18).
- `CREATE UNIQUE INDEX uq_sleep_user_device_date ON sleep_sessions (user_id, device_id, sleep_date)` (section 18).
- `CREATE INDEX idx_sleep_sessions_user_time ON sleep_sessions(user_id, start_time DESC)`.

v1 claim "canonical missing" là SAI. D-SLP-05 invalid, drop.

### Ingest service (`telemetry.py` `ingest_sleep_session`)

- `SleepIngestRequest`: db_device_id, user_id, date, score, efficiency, duration_minutes, phases, start_time, end_time.
- Upsert: `INSERT ... ON CONFLICT (user_id, device_id, sleep_date) DO UPDATE SET ...`.
- Score clamp `min(100, max(0, payload.score))`.
- `wake_count = phases.get("awake", 30) // 30`.
- Defensive `has_updated_at` check (handle DB schema chưa có `updated_at` column, legacy path).
- No validation `duration_minutes >= 120` (BR-020-02 không enforce, bug B.2).
- No auth guard (HS-004).

### Sleep risk adapter (`sleep_risk_adapter.py`)

- `_SLEEP_RISK_LEVEL_MAP`: normal/low sang low, warning/medium/moderate/high sang medium, critical sang critical.
- `from_response()` inverts: `risk_score = 100 - predicted_sleep_score`.
- Prediction label fallback chain: `predicted_sleep_label`, `prediction.prediction_label`, `risk_level`.
- Explanation text Vietnamese fallback.
- `_default_recommendations()` per level (Vietnamese).
- Confidence proxy: `prediction.prediction_score / 100`.

### Monitoring service read path (`_calculate_sleep_metrics`)

- Quality label thresholds hardcode:
  - `>= 70` sang `GOOD`
  - `>= 50` sang `AVERAGE`
  - else sang `POOR`
- Efficiency ratio: `sleep_minutes / in_bed_minutes`.
- Sleep minutes: `total_minutes - phases.awake` hoặc `duration_minutes` fallback.

### Mobile FE (`health_system/lib/features/sleep_analysis/`) — ACTIVE

- 4 screens: `sleep_report_screen`, `sleep_detail_screen`, `sleep_history_screen`, `sleep_settings_screen` (disabled shell, IgnorePointer + Opacity 0.5).
- `SleepProvider`: state machine `initial/loading/success/empty/error/noDataYet`, cache TTL 1 min, patient context.
- `SleepRepositoryImpl`: `getLatestSleep`, `getSleepHistory`, `getSessionByDate` (handle 404 sang null/empty).
- `SleepSession.fromJson`: parse phases DTO, quality label map Vietnamese (`GOOD sang Tốt`, `AVERAGE sang Trung bình`, `POOR sang Kém`).

### Cross-repo

- `Iot_Simulator_clean/api_server/services/sleep_service.py`: produce sleep sessions, call `sleep_ai_client` (bug IS-001), post to BE `/telemetry/sleep` (HS-004).
- `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:53`: IS-001 bug (wrong path `/predict` vs `/api/v1/sleep/predict`).
- `healthguard-model-api/app/routers/sleep.py`: `/api/v1/sleep/predict` + `/api/v1/sleep/model-info` — correct.

---

## 🚨 Drift findings v2 (verified)

### A. Claim đúng từ v1 (confirm)

1. ✅ 4 endpoint (2 ingest + 2 read).
2. ✅ DB schema `sleep_sessions` với unique constraint (user_id, device_id, sleep_date).
3. ✅ Ingest upsert ON CONFLICT DO UPDATE.
4. ✅ wake_count derivation.
5. ✅ Score clamp 0-100.
6. ✅ Sleep risk adapter inversion (100 - predicted_sleep_score).
7. ✅ Risk level mapping.
8. ✅ Default recommendations Vietnamese.
9. ✅ SleepSettingsScreen disabled shell.

### B. Claim SAI từ v1 (đã sửa v2)

#### B.1 🚨 Q5 / D-SLP-05 "canonical missing sleep_sessions" — SAI HOÀN TOÀN

v1 claim canonical `init_full_setup.sql` thiếu `sleep_sessions`. Thực tế:
- Section 04 line 357-371: `CREATE TABLE IF NOT EXISTS sleep_sessions (...)` đầy đủ.
- Section 18 line 899-907: ALTER TABLE add `sleep_date` column + UNIQUE INDEX.

Canonical ĐÚNG, không thiếu gì. Phase 4 task `fix(sql): add sleep_sessions to init_full_setup.sql` là fake work.

Fix v2: Drop D-SLP-05 hoàn toàn. Remove khỏi Phase 4 backlog.

#### B.2 🚨 Claim endpoint `/telemetry/sleep` có auth "IoT sim → DB upsert" — MISLEADING

v1 liệt kê endpoint như internal flow có auth. Thực tế `telemetry.py:551` `@router.post("/sleep", response_model=IngestResponse)` KHÔNG có `Depends(require_internal_service)`. So với `/ingest` + `/alert` trong cùng file có auth.

3 endpoint dưới đây đều NO AUTH:
- `/mobile/telemetry/sleep`
- `/mobile/telemetry/sleep-risk`
- `/mobile/telemetry/imu-window`

Fix v2: Bug HS-004 Critical, Phase 4 add `Depends(require_internal_service)` + IoT sim header verify.

### C. Drift MISS hoàn toàn trong v1 (v2 add)

#### C.1 🚨 CRITICAL: Telemetry sleep endpoints no auth

Covered B.2. Bug HS-004 track.

#### C.2 🟠 HIGH: BR-020-02 min 2h validation không enforce

UC020 cũ BR-020-02 yêu cầu `duration_minutes >= 120`. Grep code trả 0 match. Ingest accept bất kỳ duration nào.

Hệ quả: User ngủ 30 phút cũng tạo session "hợp lệ" với score, UI misleading.

Fix v2: Bundle vào D-SLP-03 (`is_complete` flag). Sub-task: Phase 4 add boundary validation — nếu `duration_minutes < 120` thì `is_complete = FALSE` (không reject, vẫn lưu để debug).

#### C.3 🟡 MEDIUM: Quality label thresholds hardcode không document trong UC021

`monitoring_service._calculate_sleep_metrics` dùng thresholds 70/50/else cho GOOD/AVERAGE/POOR. UC021 v1 không explicit thresholds này.

Fix v2: UC021 v2 add BR-021-04 document explicit thresholds match code. Cosmetic, doc-only.

---

## 🎯 Anh's decisions Phase 0.5 v2

Anh chọn "theo em default" (2026-05-13):

| ID     | Item                                           | Decision                                                                          | Phase 4 effort   |
| ------ | ---------------------------------------------- | --------------------------------------------------------------------------------- | ---------------- |
| D-SLP-01 (v1 carry) | Settings screen disabled                      | Keep disabled shell, UC note automatic                                           | 0h (doc)         |
| D-SLP-02 (v1 carry) | Nap detection                                  | Drop UC020 Alt 4.a                                                                | 0h (doc)         |
| D-SLP-03 (v1 expand)| Incomplete marking + min 2h validation         | Phase 4: add `is_complete BOOLEAN DEFAULT TRUE` column + validate `duration_minutes >= 120` set FALSE. Bundle 2 sub-task (before chỉ có sub-task 1) | **~1h**          |
| D-SLP-04 (v1 carry) | IS-001 sleep AI path                           | Fix IoT sim (scope IoT sim repo)                                                  | ~15min (IoT sim) |
| ~~D-SLP-05~~        | ~~Canonical SQL~~                              | ~~Update init_full_setup.sql~~ DROP — sai factual, canonical đã OK                | 0h (deleted)     |
| **E1 new** | Drop D-SLP-05                                        | Canonical đã có sleep_sessions, không cần Phase 4 work                           | -                |
| **E2 new** | HS-004 telemetry auth                               | Phase 4 add `require_internal_service` cho 3 endpoint + IoT sim header            | **~30min**       |
| **E3 new** | BR-020-02 min 2h validation                         | Bundle vào D-SLP-03 (cùng implementation)                                        | included D-SLP-03 |
| **E4 new** | UC020 BR-020-04 cross-UC boundary                   | UC020 v2 add BR-020-04 reference sleep ML sang UC028                              | 0h (doc)         |

### New Phase 4 total (revised)

| Task                                                      | Effort          |
| --------------------------------------------------------- | --------------- |
| D-SLP-03 + E3: `is_complete` + min 2h validation          | **~1h**         |
| D-SLP-04: Fix IS-001 (IoT sim)                            | ~15min (IoT sim) |
| E2: HS-004 telemetry auth (3 endpoints + IoT sim header)  | **~30min**      |

**Estimated Phase 4 total SLEEP module: ~1h30min** (health_system) + ~15min (IoT sim) + ~15min (IoT sim sleep client header).

Down từ v1 claim ~1h15min vì drop D-SLP-05 fake work nhưng add HS-004. Net thêm ~15min.

---

## 📊 UC delta v2

| UC cũ                 | Status v2    | v2 changes                                                                                                                                                                                                                                                              |
| --------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UC020 Phân tích       | **Overwrite** | Main Flow = device pre-compute + BE upsert (match code, drop server-side batch analyze). Drop Alt 4.a (nap). Keep Alt 3.a + implement Phase 4. Add BR-020-04 cross-UC ML boundary. Add BR-020-05 `is_complete` column. Add BR-Auth-01 HS-004 reference.                 |
| UC021 Xem báo cáo     | **Minor update** | Add BR-021-04 explicit thresholds 70/50. Add BR-021-05 incomplete badge. Core flow + BR-021-01/02/03 không đổi.                                                                                                                                                       |

---

## 🆕 Industry standard add-ons — anh's selection v2

Tất cả DROP (giữ nguyên v1):

- ❌ Sleep score trend prediction — Phase 5+
- ❌ Smart alarm — Phase 5+
- ❌ Sleep hygiene tips — Phase 5+
- ❌ Circadian rhythm analysis — Phase 5+

---

## 📝 Decisions log consolidated

### Active decisions v2

| ID       | Item                             | Decision                                          | Output artifact                                    |
| -------- | -------------------------------- | ------------------------------------------------- | -------------------------------------------------- |
| D-SLP-01 | Settings screen                  | Keep disabled shell                               | UC020 v2 Usability section                         |
| D-SLP-02 | Nap detection                    | Drop UC020 Alt 4.a                                | UC020 v2 BR-020-01                                 |
| D-SLP-03 | Incomplete session + min 2h val  | Phase 4: is_complete + boundary check (bundled)  | UC020 v2 BR-020-05 + UC021 v2 BR-021-05 (FE badge) |
| D-SLP-04 | IS-001 sleep AI path             | Fix IoT sim (scope IoT sim repo)                  | IS-001 bug file                                    |
| ~~D-SLP-05~~ | ~~Canonical SQL~~                    | DROP, sai factual                                 | -                                                  |
| **E2**   | HS-004 telemetry auth            | Phase 4 add require_internal_service              | HS-004 bug, UC020 v2 BR-Auth-01                    |
| **E4**   | Cross-UC boundary sleep ML       | Doc-only UC020 v2 BR-020-04                       | UC020 v2                                           |

### Add-ons dropped

| Add-on                       | Decision |
| ---------------------------- | -------- |
| Sleep score trend prediction | ❌ Drop |
| Smart alarm                  | ❌ Drop |
| Sleep hygiene tips           | ❌ Drop |
| Circadian rhythm analysis    | ❌ Drop |

---

## Cross-references

### UC v2 (committed Phase 0.5)

- `PM_REVIEW/Resources/UC/Sleep/UC020_Analyze_Sleep.md` — v2 overwrite
- `PM_REVIEW/Resources/UC/Sleep/UC021_View_Sleep_Report.md` — v2 minor update

### Bug mới (committed Phase 0.5)

- `PM_REVIEW/BUGS/HS-004-telemetry-sleep-endpoints-no-auth.md` — Critical

### Bug related (existing)

- `PM_REVIEW/BUGS/IS-001-sleep-ai-client-wrong-path.md` — Phase 4 fix (IoT sim scope)

### Code paths (Phase 4 backlog)

**health_system BE:**
- `health_system/backend/app/api/routes/telemetry.py:551` (`ingest_sleep_session`) — add `Depends(require_internal_service)` (HS-004) + `duration_minutes >= 120` validation + `is_complete` logic (D-SLP-03)
- `health_system/backend/app/api/routes/telemetry.py` line ~440 (`ingest_imu_window`) — add auth (HS-004)
- `health_system/backend/app/api/routes/telemetry.py` line ~500 (`ingest_sleep_risk`) — add auth (HS-004)

**DB migration scripts mới (Phase 4):**
- `PM_REVIEW/SQL SCRIPTS/20260513_sleep_sessions_is_complete.sql` — add `is_complete BOOLEAN DEFAULT TRUE` column (D-SLP-03)
- Không cần migration cho HS-004 (code-level fix only)
- Không cần migration cho D-SLP-05 (đã drop)

**Mobile FE (Phase 4):**
- `health_system/lib/features/sleep_analysis/models/sleep_session.dart` — add `isComplete` field parse
- `health_system/lib/features/sleep_analysis/screens/sleep_report_screen.dart` — render "Không hoàn chỉnh" badge
- `health_system/lib/features/sleep_analysis/screens/sleep_history_screen.dart` — badge trên session card

**Cross-repo (Phase 4):**
- `Iot_Simulator_clean/simulator_core/sleep_ai_client.py:53` — fix path IS-001
- `Iot_Simulator_clean/api_server/services/sleep_service.py` — add `X-Internal-Service` header cho POST `/telemetry/sleep` (HS-004)
- IMU + sleep-risk client trong IoT sim — add header tương tự nếu đang miss

### ADR references

- **ADR-005** (Internal service-to-service auth strategy) — pattern HS-004 miss apply.

### DB schema canonical

- `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` section 04 + 18 — sleep_sessions + UNIQUE constraint, đã có đầy đủ.

---

## Changelog

| Version | Date       | Note                                                                                                                       |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------- |
| v1      | 2026-05-13 sáng | Initial 5 Q drift review (D-SLP-01 to D-SLP-05)                                                                        |
| v2      | 2026-05-13 chiều | Deep verification: drop D-SLP-05 (fake), add HS-004 Critical, bundle min 2h vào D-SLP-03, UC020/021 rewrite          |
