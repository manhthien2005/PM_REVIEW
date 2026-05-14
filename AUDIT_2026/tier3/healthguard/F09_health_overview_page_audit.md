# Deep-dive: F09 — HealthOverviewPage.jsx (HG-001 + Q7 UI consumer + god-component)

**File:** `HealthGuard/frontend/src/pages/admin/HealthOverviewPage.jsx`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 3 (MLOps + Frontend god-components)

## Scope

Single page file `HealthOverviewPage.jsx` (~520 LoC):
- State management (~30 LoC): summary, alerts, alertsTotal, riskData, riskTotal, patientDetail, loading, paginationLoading, activeTab, page, limit, searchInput, severity, alertType, dateRange, customDateFrom, customDateTo, status, detailModal, toast.
- WebSocket handlers (~110 LoC): `handleNewAlert`, `handleRiskUpdate` — real-time event consumers.
- Fetch functions (~80 LoC): `fetchSummary`, `fetchAlertsWithoutSearch`, `fetchAlerts`, `fetchRiskDistribution`, `fetchPatientDetail`.
- Event handlers (~70 LoC): `handleViewDetail`, `handleManualSearch`, `handleCardClick`, `handleExportAlerts`, `handleExportRisk`, `handleRefresh`, `showToast`.
- Render JSX (~230 LoC): toast banner, header, summary bar, tabs, alerts filter form, ThresholdAlertsTable, RiskDistributionChart, PatientHealthDetailModal.

**Out of scope:** ThresholdAlertsTable internals (F12), RiskDistributionChart + PatientHealthDetailModal + HealthSummaryBar component logic (M11 Phase 1 macro), `useWebSocket` hook (M12 + Wave 4 future scope).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 1/3 | HG-001 UI hardcode `status: 'unread'` line 65 (consumer-side mirror BE bug). WebSocket handler duplicate Vietnamese parse logic với BE health.service.js (F01) — cùng coupling vấn đề. `useEffect` deps array đa số đúng nhưng có potential stale closure. |
| Readability | 1/3 | 520 LoC god-component. JSX render 230 LoC inline với inline filter form (~150 LoC). Console.log debug rải rác (lines 64, 109, 119, 144, 161). State 20+ variables không group. Nested ternary trong JSX. |
| Architecture | 1/3 | God-component nghiêm trọng: state + WebSocket + fetch + render trong 1 file. Filter form inline 150 LoC nên extract thành `ThresholdFilterBar.jsx` component. WebSocket event handler chứa 50 LoC business logic (formatAlertMetric duplicate F01) — không thuộc page layer. |
| Security | 2/3 | React JSX auto-escape user input. Service layer pass through API. Gap: console.log payload data có thể chứa user info. |
| Performance | 2/3 | `useCallback` apply đúng cho fetch + handlers (lines 158-181). Refetch storm tiềm năng khi user thay đổi filter rapid (no debounce explicit ở filter input). 4 useEffect chains. |
| **Total** | **7/15** | Band: **🟠 Needs-attention** (Total 7-9 = Needs-attention per framework v1) |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M10 findings (all confirmed + escalate):**

1. ✅ **God-component candidate** (M10 estimate ~600-900 LoC) — Phase 3 verify actual 520 LoC. Slightly under estimate nhưng vẫn god-component.
2. ✅ **HG-001 UI consumer** (M10 P3) — confirmed line 65 hardcode `status: 'unread'` trong `handleNewAlert`. Phase 3 escalate P0 cùng F01 vì FE side mirror BE bug — fix HG-001 phải sync BE + FE.
3. ✅ **HG-001 dependent trên BE fix** — confirmed page consume `healthService.getThresholdAlerts()` API → BE return `status='unread'` từ F01 hardcode → FE display same.

**Phase 3 new findings (beyond Phase 1 macro):**

4. ⚠️ **HG-001 FE side hardcode `status: 'unread'`** (line 65 trong WebSocket `handleNewAlert`):
   - WebSocket emit `health:new-alert` từ BE → FE receive raw alert → format trong handler.
   - Line 65: `status: 'unread'` hardcode bất kể alert thực tế đã read hay chưa.
   - Cùng root cause với F01 BE service: BE schema gap → FE mirror logic.
   - Phase 4 fix HG-001 cần sync: BE pivot `notification_reads` (F01) + FE handler đọc `payload.data.read_state` thay vì hardcode.
   - Priority P0 cùng cluster HG-001 fix.
5. ⚠️ **Vietnamese parse logic duplicate F01** (lines 79-105):
   - WebSocket handler parse `message.includes('SpO')`, `message.includes('Nhịp tim')`, `message.includes('Huyết áp')`, `message.includes('Nhiệt độ')` → set `metric/value/threshold`.
   - Same logic với F01 `health.service.js:241-305` (M04 + F01 P2 flag).
   - 2 sources of truth → dễ drift khi message template đổi.
   - Fix: BE phải emit `alert.data.metric` field enum trong WebSocket payload (depend F01 P2 fix), FE consume directly.
   - Priority P2 — coordinate với F01 P2 fix.
6. ⚠️ **God-component 520 LoC** — vượt steering React rule "Component < 200 LoC". Sub-component split candidates:
   - `ThresholdFilterBar.jsx` — lines 308-432 (~125 LoC inline filter form).
   - `useHealthOverviewData()` custom hook — extract fetch + state (lines 27-200).
   - `useWebSocketAlertHandler()` — extract WebSocket handlers + format logic (lines 51-160).
   - Page main remain ~150 LoC (compose components).
   - Priority P2 (Phase 5+ refactor).
7. ⚠️ **Debug console.log** rải rác:
   - Line 64: `console.log` log full payload (sensitive data potential).
   - Line 109: `console.log('Fetching risk distribution...')`.
   - Line 119: `console.log('Risk distribution response:', res)`.
   - Line 144: `console.log('Setting up WebSocket event listeners')`.
   - Line 161: `console.log('Cleaning up WebSocket event listeners')`.
   - Production log spam + emoji rule violation + alert payload có thể chứa user info.
   - Priority P2 — gate `if (import.meta.env.DEV)` hoặc remove.
8. ⚠️ **Stale closure tiềm năng** (`fetchAlerts:165-180`):
   - useCallback deps `[page, limit, searchInput, severity, alertType, dateRange, customDateFrom, customDateTo, status]` (9 deps).
   - Mỗi state change → re-create function reference → child component re-render.
   - Nếu deps array thiếu → stale closure → fetch dùng giá trị cũ.
   - Verify exhaustive-deps lint không có warning. Priority P3.
9. ⚠️ **`useEffect` chain phức tạp** (4 effects):
   - Effect 1 (line 168): cleanup timers on unmount.
   - Effect 2 (line 168 wrong line — actual line 142): WebSocket subscribe + cleanup.
   - Effect 3 (line 195): tab query parameter sync.
   - Effect 4 (line 280): initial data load.
   - Effect 5 (line 290): tab-specific data reload.
   - Effect 6 (line 297): filter auto-fetch.
   - 6 useEffect total. Risk: hidden ordering dependencies, race conditions.
   - Priority P3 — extract custom hook để consolidate.
10. ⚠️ **Refetch storm tiềm năng** (lines 297-302):
    - `useEffect` deps trên `[severity, alertType, dateRange, customDateFrom, customDateTo, status, ...]` → mỗi change → fetch.
    - Filter UI có debounce ở searchInput (timer 400ms ở line 39 setSearchTimer) nhưng không debounce ở severity/alertType select.
    - Admin click multiple filter rapid → N fetch calls.
    - Acceptable với rate limit BE (60/min) nhưng lãng phí bandwidth.
    - Priority P3 — Phase 5+ batch filter changes hoặc TanStack Query dedupe.
11. ⚠️ **`handleCardClick` setTimeout race** (line 268, 256-263):
    - `setTimeout(() => fetchAlertsWithoutSearch(), 100)` sau setState multiple — workaround state batching.
    - Brittle pattern: nếu state update chậm > 100ms → fetch dùng giá trị cũ.
    - React 18+ automatic batching → setState đồng bộ trong handler → fetch sau setState.
    - Fix: dùng `flushSync` hoặc trigger fetch trong useEffect dependent on state change.
    - Priority P3.

### Correctness (1/3)

- ✓ **State initial values** (lines 16-37) — đúng (null/empty array/string default).
- ✓ **`useCallback` apply** (lines 51, 109, 144, 158, 181, 217, 237) — fetch + handlers stable refs.
- ✓ **Cleanup timers on unmount** (lines 41-50) — searchTimer + toastTimer cleanup.
- ✓ **WebSocket cleanup** (lines 156-162) — `off(...)` mỗi event handler.
- ⚠️ **P0 — HG-001 UI hardcode `status: 'unread'`** (line 65) — duplicate F01 BE bug.
- ⚠️ **P2 — Vietnamese parse logic duplicate F01** (lines 79-105) — coupling.
- ⚠️ **P3 — Stale closure tiềm năng** trong useCallback deps.
- ⚠️ **P3 — `setTimeout` race trong handleCardClick** — brittle workaround.

### Readability (1/3)

- ⚠️ **P1 — God-component 520 LoC** — vượt rule "< 200 LoC". JSX render 230 LoC + inline filter form 125 LoC.
- ⚠️ **P2 — 5 console.log debug** — rải rác, emoji rule violation.
- ⚠️ **P2 — Filter form inline 125 LoC JSX** (lines 308-432) — 5 inputs (search, severity, alertType, dateRange, customDateFrom/To) + clear button + total count display. Should extract `ThresholdFilterBar.jsx`.
- ⚠️ **P2 — Nested ternary trong JSX** (line 467 `alert.severity === 'critical' ? 'Nguy hiểm' : alert.severity === 'high' ? 'Cao' : alert.severity === 'medium' ? 'Trung bình' : 'Thấp'`). Extract `getSeverityLabel(severity)` helper. Priority P2.
- ⚠️ **P3 — State 20+ variables** — không group. Có thể `useReducer` cho complex state.
- ✓ Method naming clear (`fetchAlertsWithoutSearch`, `handleCardClick`, `handleManualSearch`).
- ✓ Vietnamese comment explain ý đồ inline.

### Architecture (1/3)

- ⚠️ **P1 — God-component 520 LoC** (duplicate Readability P1) — extract sub-components + custom hooks.
- ⚠️ **P2 — Business logic trong page** (WebSocket handler 50 LoC parse Vietnamese template):
  - `handleNewAlert` (lines 51-110) chứa 50 LoC format alert metric — không thuộc page layer.
  - Fix: extract `formatAlertMetric(alert)` helper hoặc move sang BE WebSocket payload.
  - Priority P2.
- ⚠️ **P2 — Direct service import** (lines 8 import `healthService`) — tight coupling. Phase 5+ wrap trong custom hook (`useHealthOverview()`) cho separation.
- ⚠️ **P3 — 6 useEffect chains** — risk hidden ordering. Consolidate qua custom hook.
- ✓ Component composed từ `HealthSummaryBar`, `ThresholdAlertsTable`, `RiskDistributionChart`, `PatientHealthDetailModal` — separation đúng layer (sub-components).
- ✓ Service layer delegate (line 8 `healthService`) — không hit fetch trực tiếp.

### Security (2/3)

- ✓ React JSX auto-escape user input (`{alert.userName}`, `{alert.message}`).
- ✓ Không `dangerouslySetInnerHTML` trong file.
- ✓ Service layer (`healthService.getPatientHealthDetail`) handle audit log BE side (F01).
- ⚠️ **P2 — Console.log alert payload** (line 64): log toàn bộ payload — payload có `users.full_name`, `users.email`, `vitals` data có thể chứa sensitive info. Production log leak.
  - Fix: gate `if (import.meta.env.DEV)` hoặc strip sensitive fields trước log.
  - Priority P2.
- ⚠️ **P2 — Console.log risk response** (line 119): `console.log('Risk distribution response:', res)` — risk data của all patients.
  - Fix: same gate.
  - Priority P2.
- ✓ Không expose token trong code.
- ✓ Page wrap bởi `ProtectedRoute` (App.jsx parent) — auth gate enforced.

### Performance (2/3)

- ✓ **`useCallback`** đúng pattern cho fetch + handlers stable refs.
- ✓ **`useMemo`** không dùng nhưng filter logic tại BE side, FE không heavy compute.
- ✓ **Pagination** (page state + onPageChange callback) — không load all rows.
- ⚠️ **P2 — Refetch storm filter changes** (lines 297-302) — no debounce filter select. Acceptable BE rate limit nhưng UX waste.
- ⚠️ **P2 — `fetchAlertsWithoutSearch` vs `fetchAlerts` duplicate** (lines 109-160) — 2 functions same logic chỉ khác `search` param. Refactor 1 function với `searchOverride` parameter.
- ⚠️ **P3 — 6 useEffect chains** — multiple re-render cycles trên state change. Consolidate qua custom hook giảm re-render.
- ⚠️ **P3 — `setTimeout` race trong handleCardClick** — brittle, không phải perf issue chính.

## Recommended actions (Phase 4)

### P0 — HG-001 FE side fix (cùng cluster F01)

- [ ] **P0** — Fix `handleNewAlert` line 65: read `status` từ payload thay vì hardcode `'unread'` (~15 min, depend F01 BE fix emit `read_state` field).

### P2 — architecture + readability

- [ ] **P2** — Extract `ThresholdFilterBar.jsx` từ filter form inline (lines 308-432) (~2h).
- [ ] **P2** — Extract `getSeverityLabel(severity)` helper từ nested ternary (~10 min).
- [ ] **P2** — Refactor `formatAlertMetric` cùng F01 BE — emit `alert.data.metric` enum field, FE consume directly (~1h FE side, depend BE fix).
- [ ] **P2** — Replace `console.log` debug bằng `if (import.meta.env.DEV)` gate hoặc remove (~10 min).
- [ ] **P2** — Merge `fetchAlertsWithoutSearch` + `fetchAlerts` thành 1 function với `searchOverride` parameter (~30 min).
- [ ] **P2 (Phase 5+)** — Extract `useHealthOverview()` custom hook consolidate state + fetch + WebSocket (~4h refactor).

### P3 — defensive + cleanup

- [ ] **P3** — Verify exhaustive-deps lint warning cho `useCallback` deps (~5 min).
- [ ] **P3** — Remove `setTimeout` race trong handleCardClick — dùng useEffect dependent on state (~30 min).
- [ ] **P3** — Consolidate 6 useEffect chains → 2-3 effects qua custom hook (~2h).
- [ ] **P3** — Replace 20+ state variables → useReducer (~2h refactor).

## Out of scope (defer)

- ThresholdAlertsTable component internals — F12 deep-dive scope.
- `useWebSocket` hook implementation — Wave 4 + M12 Phase 1 cover.
- Service layer (`healthService`) — F01 BE deep-dive cover.
- Style + animation — Phase 3 cosmetic out of scope.
- Accessibility (ARIA, keyboard nav) — Phase 5+.
- E2E test cho filter combination — Phase 5+ Cypress/Playwright.

## Cross-references

- Phase 1 M10 audit: [tier2/healthguard/M10_frontend_pages_audit.md](../../tier2/healthguard/M10_frontend_pages_audit.md) — god-component candidate flagged.
- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — BE health.service.js consumer.
- F01 `health.service.js` deep-dive — BE source of HG-001 + Q7 + Vietnamese parse duplicate.
- F12 `ThresholdAlertsTable.jsx` deep-dive — UI consumer của alert data.
- HG-001 bug: [BUGS/HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — root cause BE service.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/HEALTH.md](../../tier1.5/intent_drift/healthguard/HEALTH.md) — D-HEA-04 alert acknowledge defer Phase 5+.
- Steering React rule: `.kiro/steering/24-react-vite.md` — Component < 200 LoC.
- Precedent format: [tier3/healthguard-model-api/F2_health_service_audit.md](../healthguard-model-api/F2_health_service_audit.md) — tier3 service deep-dive (compare BE/FE pattern).

---

**Verdict:** God-component với HG-001 + Q7 UI mirror — 7/15 Needs-attention band. P0 fix HG-001 FE side cùng commit BE F01 (~15 min). P2 architectural refactor (~6h tổng) → 11/15 Healthy post-fix. Phase 5+ split component sang sub-components + custom hooks là next major refactor.
