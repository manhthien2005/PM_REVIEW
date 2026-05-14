# Deep-dive: F02 — risk-calculator.service.js (Q7 INSERT FAIL root cause)

**File:** `HealthGuard/backend/src/services/risk-calculator.service.js`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 1 (HG-001 + Q7 cluster)

## Scope

Single file `risk-calculator.service.js` (~240 LoC):
- `calculateRiskScore(userId)` — main method, ~190 LoC. Lấy vitals 30 phút, tính trung bình, score 4 axes (SpO2 / HR / BP / temperature), classify level, insert `risk_scores` + `risk_explanations`.
- `_avg(arr)` — helper mean ignoring null.
- `calculateAllRiskScores()` — batch loop qua users role=user active, gọi `calculateRiskScore` từng user.

**Out of scope:** Invoker `riskScoreJob` (covered M07 Phase 1), consumer side `health.service.js getSummary` filter logic (covered F01 deep-dive).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 0/3 | Q7 CRITICAL bug: line 163 set `riskLevel = 'high'` cho score 67-84 → DB CHECK violation `risk_level IN ('low','medium','critical')` → INSERT FAIL silently. File header comment line 24-28 declare 4 levels (LOW/MEDIUM/HIGH/CRITICAL) — contradict DB canonical + Mobile BE truth. |
| Readability | 3/3 | File ≤250 LoC, section comments Vietnamese rõ (SpO2 / HR / BP / temperature). Weight table comment inline (35/30/20/15) — reader biết priority ngay. |
| Architecture | 2/3 | Single service single responsibility (calculate risk score). Fallback chain `activeDevice` → `recentVitals 30 min` → `latest vitals` — defensive. Nhưng feature extraction + scoring + DB write + explanation generation ghép trong 1 function ~190 LoC → god-method. |
| Security | 3/3 | Prisma parameterized queries. Không leak sensitive data. Fallback threshold safe values. No eval/exec. Không hit anti-pattern auto-flag. |
| Performance | 2/3 | Batch loop sequential (`for ... await`) trong `calculateAllRiskScores` → N users × 4 DB queries mỗi user. Với 100 users → ~400 queries serial. Priority P2 Phase 5+. |
| **Total** | **10/15** | Band: **🟡 Healthy với ⚠️ Critical Correctness deficit** (framework v1 không auto-Critical cho Correctness=0, chỉ Security=0. Em label manual vì Q7 production impact nghiêm trọng.) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M04 findings (all confirmed):**

1. ✅ **Q7 risk_level enum mismatch** (drift D-HEA-07) — confirmed line 163 `else if (riskScore >= 67) riskLevel = 'high';`. Phase 3 deep-dive pinpoint exact line + add Impact: every user với vitals abnormal score 67-84 → risk_scores INSERT FAIL → admin dashboard thiếu user ở "high risk" filter → operational blind spot.
2. ✅ **File header comment sai** (lines 24-28) — declare 4 levels với threshold OLD (67-84 high, 85-100 critical). Cần sync xuống 3 levels (67-100 critical) per Mobile BE truth.
3. ✅ **File không có test** — M08 đã flag, Phase 4 add test `__tests__/services/risk-calculator.service.test.js` là must-have cho fix verification.

**Phase 3 new findings (beyond Phase 1 macro):**

4. ⚠️ **Silent failure cho entire batch** — `calculateAllRiskScores:228-242` wrap `calculateRiskScore` trong try/catch per-user, log error message, tiếp tục next user. Nếu Q7 INSERT FAIL với 50% users → 50% dashboard blind, KHÔNG có aggregate alert admin. Priority P1.
5. ⚠️ **Threshold duplicate** (`DEFAULT_VITALS_DAY` lines 8-19 vs `system_settings` DB) — 2 source of truth cho threshold. Nếu DB fail → fallback silent. Priority P2.
6. ⚠️ **Score capped ở 100** (`Math.min(100, riskScore)` line 157) — nếu user có tất cả 4 axis abnormal critical → `35+30+20+15 = 100` đúng. Edge case score = 100 → `riskLevel = 'critical'` đúng. Không có bug ở đây.
7. ⚠️ **`explanation_text` chứa Vietnamese template** (line 202) — template hardcode trong service layer. Nếu đổi label/format → sửa 1 chỗ OK, nhưng coupling với language. Priority P3.

### Correctness (0/3) — Critical Correctness deficit

**⚠️ P0 CRITICAL — Q7 INSERT FAIL** (line 159-164):

- **DB canonical** (`06_create_tables_ai_analytics.sql:30`): `CHECK (risk_level IN ('low','medium','critical'))` — 3 values chỉ.
- **Mobile BE** (`risk_inference_service.py:64-72`): LOW 0-33, MEDIUM 34-66, **CRITICAL 67-100** (2 levels hợp nhất từ admin's 67-84 + 85-100).
- **Admin BE này** (line 159-164): 4 levels với threshold LEGACY.
- Flow cho user với score 67-84:
  1. Line 163 set `riskLevel = 'high'`.
  2. Line 166-176 gọi `prisma.risk_scores.create({ data: { risk_level: 'high', ... } })`.
  3. PostgreSQL CHECK constraint reject → Prisma throw `PrismaClientKnownRequestError` (code P2010 or similar).
  4. Caller `calculateAllRiskScores` (line 232-234) catch → `console.error` → next user.
  5. **Silent failure**: `risk_scores` row KHÔNG insert → admin dashboard filter `risk_level IN ('high','critical')` thiếu user này → missing from "high risk" list.
- **Impact severity:**
  - Safety-critical: elderly patient với vitals abnormal score 67-84 → admin nghĩ "low/medium" (missing row) → không escalate kịp.
  - HG cron chạy mỗi 5 phút (M07 `risk-score-job.js:15`) → silent fail compound.
  - Log `.error` console-only, không gửi admin alert → operational invisibility.
- **Fix required:**
  - Line 163: merge 'high' branch vào 'critical' (drop 'high' entirely).
  - Line 161: thay `if (riskScore >= 85) riskLevel = 'critical';` → `if (riskScore >= 67) riskLevel = 'critical';`.
  - Line header comment 24-28: sync 3 levels.
- **Test required:**
  - Boundary test: score 66 → medium, score 67 → critical, score 100 → critical.
  - Regression test: mock vitals abnormal → verify `risk_scores` INSERT success (no DB exception).

**⚠️ P0 — File header comment outdated** (lines 24-28):

- Current: "LOW 0-33 / MEDIUM 34-66 / HIGH 67-84 / CRITICAL 85-100" (4 levels).
- Fix: "LOW 0-33 / MEDIUM 34-66 / CRITICAL 67-100" (3 levels).
- Priority P0 cùng commit với code fix line 163.

**⚠️ P1 — Silent failure không alert aggregate** (`calculateAllRiskScores:232-234`):

- Catch per-user, continue loop. Nếu 30% users fail → admin KHÔNG biết.
- Return `results` array chỉ chứa success users → caller `risk-score-job.js:45` không có visibility số fail.
- **Fix proposal:**
  - Track `failedUsers` array song song với `results`.
  - Return `{ results, failedUsers }`.
  - Caller (job) emit WebSocket alert nếu `failedUsers.length > 0` → admin aware.
- Priority P1.

### Readability (3/3)

- ✓ Section comments chia 4 axes rõ (`// --- SpO₂ ---`, `// --- Nhịp tim ---`, v.v.).
- ✓ Weight inline ở mỗi section (`trọng số cao nhất: 35 điểm`).
- ✓ Variable naming tự explain (`avg.spo2`, `features.spo2_abnormal`, `abnormalFeatures`).
- ✓ File ≤250 LoC, method `calculateRiskScore` dài nhưng segmented rõ.
- ⚠️ **P3 — Emoji trong code** (`calculateAllRiskScores:223, 229, 234, 237`): 4 emoji literal trong console.log — cross-cutting rule anti-pattern.

### Architecture (2/3)

- ✓ Single service single responsibility (calculate score + persist).
- ✓ Fallback chain (activeDevice → 30-min vitals → latest vitals) defensive.
- ✓ Helper `_avg` extracted.
- ⚠️ **P2 — `calculateRiskScore` god-method** (~190 LoC): feature extraction (lines 75-82) + 4 scoring blocks (lines 85-152) + risk level classification (lines 159-164) + DB write (lines 166-176) + explanation generation (lines 179-210) ghép 1 function. Test khó. Priority P2 — extract:
  - `_extractAverages(recentVitals)` — lines 75-82.
  - `_scoreVitals(avg, config)` — lines 85-152, return `{ riskScore, features }`.
  - `_classifyLevel(riskScore)` — lines 159-164.
  - `_buildExplanation(features, riskLevel, riskScore, abnormalFeatures)` — lines 179-210.
- ⚠️ **P2 — Threshold 2 sources** (`DEFAULT_VITALS_DAY` literal + `system_settings` DB) — spread logic. Nếu admin update DB threshold → fallback literal không sync. Priority P2 — single source, load once at startup (depend Drift CONFIG D-CFG-03 cache layer).

### Security (3/3)

- ✓ Prisma `findFirst`, `findMany`, `create` — parameterized queries.
- ✓ Không log sensitive data raw. `console.log` chỉ log risk score + level + user name (full_name acceptable cho admin internal audit).
- ✓ Không hit anti-pattern auto-flag.
- ✓ Input `userId` từ internal caller (`calculateAllRiskScores` loop users qua Prisma select) → không user-controlled.

### Performance (2/3)

- ✓ Prisma `orderBy + take` cho vitals query → bounded.
- ✓ `_avg` helper O(n) với n ≤ 20 (take: 20).
- ⚠️ **P2 — Batch loop sequential** (`calculateAllRiskScores:227-240`): `for (const patient of patients) { await calculateRiskScore(patient.id); }` → N users × ~4 DB queries serial. Với 100 users → ~400 queries sequential.
  - Alternative: `Promise.all(patients.map(p => calculateRiskScore(p.id)))` → parallel, nhưng burst DB connection pool.
  - Middle: chunk 10 users parallel với `p-limit` hoặc Prisma connection pool default.
  - Priority P2 Phase 5+.
- ⚠️ **P3 — 2 DB read trong `calculateRiskScore`** (active device + recent vitals) — sequential, có thể Promise.all nếu activeDevice không dependent với vitals query filter. Hiện tại vitals filter dùng `device_id: activeDevice.id` → sequential required. OK.

## Recommended actions (Phase 4)

- [ ] **P0 CRITICAL** — Fix Q7 line 159-164: merge 'high' branch → 'critical'. Sync line 24-28 comment. Test boundary 66/67/100 (~30 min).
- [ ] **P0** — Add `risk-calculator.service.test.js` cover: (a) level boundary (low/medium/critical transitions), (b) fallback chain (no device / no vitals / stale vitals), (c) DB write success + CHECK constraint compliance (~1h).
- [ ] **P1** — Track `failedUsers` separately + return `{ results, failedUsers }`. Caller emit admin alert nếu `failedUsers.length > 0` (~1h).
- [ ] **P2** — Extract 4 sub-methods (_extractAverages, _scoreVitals, _classifyLevel, _buildExplanation) từ `calculateRiskScore` (~2h refactor).
- [ ] **P2** — Single source of truth cho threshold (remove `DEFAULT_VITALS_DAY`, trust `system_settings` + cache layer per D-CFG-03) (~1h).
- [ ] **P2 (Phase 5+)** — Batch `calculateAllRiskScores` parallel với `p-limit(5)` hoặc chunk worker (~1h).
- [ ] **P3** — Replace emoji trong console.log bằng text prefix `[OK]`, `[FAIL]`, `[INFO]` (~5 min).

## Out of scope (defer)

- Risk score algorithm tuning (weights 35/30/20/15) — UC028 business decision, không phải Phase 3 correctness scope.
- Cohort analysis (demographic-specific thresholds) — Phase 5+ research feature.
- ML-based risk scoring replacement — ADR-006 mock scope, Phase 5+ real integration.
- Performance load test với 10,000 users — Phase 5+ ops audit.

## Cross-references

- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — Q7 + duplicate naming flag.
- Phase 1 M08 audit: [tier2/healthguard/M08_tests_audit.md](../../tier2/healthguard/M08_tests_audit.md) — no test coverage flag, Phase 4 add.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-07 3 levels decision.
- F01 `health.service.js` deep-dive: sister file chứa consumer-side filter bug (line 46 `IN ('high','critical')`).
- F03 `risk-calculation.service.js` deep-dive: dead empty file, confirmed không overlap.
- Cross-repo truth: `health_system/backend/app/services/risk_inference_service.py:64-72` — 3 levels source of truth.
- Canonical DB: `PM_REVIEW/SQL SCRIPTS/06_create_tables_ai_analytics.sql:30` CHECK constraint.
- Caller: `HealthGuard/backend/src/jobs/risk-score-job.js:45` — cron mỗi 5 phút, silent fail invisible.
- Precedent format: [tier3/healthguard-model-api/F1_fall_service_audit.md](../healthguard-model-api/F1_fall_service_audit.md) — tier3 deep-dive format.

---

**Verdict:** Q7 CRITICAL bug → Phase 4 P0 must fix ngay trong commit đầu. Combine fix với F01 consumer filter (line 46) + DB backfill migration + UC028 BR-028-06 update + tests (M08 + F02 new test file). Total cross-file fix estimate: 2.5h (per drift D-HEA-07 plan) + 1h test = ~3.5h cohesive.
