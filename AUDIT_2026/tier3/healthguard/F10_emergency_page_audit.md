# Deep-dive: F10 — EmergencyPage.jsx (real-time WS + emergency response flow)

**File:** `HealthGuard/frontend/src/pages/admin/EmergencyPage.jsx`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 3 (MLOps + Frontend god-components)

## Scope

Single page file `EmergencyPage.jsx` (~510 LoC):
- State + tabs: activeTab (active/history/watch), summary, fallCountdownList, events, total, page, filters, searchInput, loading, isDisconnected.
- WebSocket: useEffect subscribe `emergency:new-event` + `emergency:status-update` với debounce 400ms + burst toast logic.
- Auto-refresh: 15-second interval cho tab `active` + `watch` (UC029 Reliability BR-029-01).
- Fetch logic: `refreshEmergencyData(silent)` — Promise.all summary + tab-specific.
- Event handlers: handleSearchChange, handleFilterChange, handleClearFilters, handleCardClick, exportFilters, handleExportCSV/JSON, handleViewDetails, handleOpenStatusPrompt, handleConfirmStatus, handleLogContact, showToast.
- Render JSX: toast banner, disconnected warning, header, summary bar, tabs (3), toolbar, conditional content (watch panel hoặc table+pagination), modals (detail + status prompt).

**Out of scope:** EmergencyToolbar/Table/Pagination/SummaryBar/FallCountdownPanel/DetailModal/StatusPrompt component internals (M11 Phase 1 macro), `useWebSocket` hook (M12 + Wave 4), `emergencyService` API layer (M12 Phase 1).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | UC029 Reliability auto-refresh 15s + WebSocket burst debounce 400ms — defensive against race. `refreshGenRef` generation pattern protect stale fetch. WebSocket cleanup đúng. Gap: `handleConfirmStatus` close modal trước fetch refresh → FE state có thể stale 1 frame. |
| Readability | 2/3 | UC029 reference comments inline (BR-029-01). Vietnamese inline literal cho tab description. JSX 200 LoC vẫn scannable nhờ tab-based structure. State 10 variables — fewer hơn F09. |
| Architecture | 2/3 | Component composition tốt: 7 sub-components extracted (Toolbar/Table/Pagination/SummaryBar/FallCountdownPanel/DetailModal/StatusPrompt). WebSocket debounce pattern reusable. Gap: 510 LoC vẫn vượt rule "< 200 LoC". `refreshEmergencyData` 60 LoC monolithic. |
| Security | 2/3 | React JSX auto-escape. Service layer delegate. Không console.log debug (good!). Gap: admin notes input chưa validate length/sanitize FE side trước gửi BE. |
| Performance | 3/3 | WebSocket debounce 400ms tránh refresh storm khi BE emit burst. `refreshGenRef` generation cancel stale. `useMemo` cho `filteredWatchItems` (line 78). 15s polling acceptable cho real-time UC029 scope. |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M10 findings (all confirmed):**

1. ✅ **Page consume `services/*Service.js` pattern** — confirmed line 3 import `emergencyService`.
2. ✅ **WebSocket integration** (M10 P3) — confirmed lines 109-141 sử dụng `useWebSocket` hook + emergency events subscription.
3. ✅ **Auto-refresh 15s pattern** (UC029 BR-029-01) — confirmed lines 145-156.

**Phase 3 new findings (beyond Phase 1 macro):**

4. ⚠️ **WebSocket burst debounce pattern reusable** (lines 109-141):
   - `wsDebounceRef` + `wsBurstHasNewRef` + `setTimeout(400)` consolidate burst events.
   - Pattern hay — nên extract thành `useWebSocketBurstHandler(events, debounceMs)` custom hook reuse.
   - Tương tự HealthOverviewPage (F09) chưa có pattern này → có thể adopt.
   - Priority P3 (Phase 5+) — refactor share hook.
5. ⚠️ **`refreshGenRef` race protection** (lines 89-105):
   - Pattern: increment `refreshGenRef.current` mỗi call; check `gen !== refreshGenRef.current` trong async result → stale fetch ignore.
   - Tốt practice, nhưng spread khắp file (5 chỗ check). Extract thành utility (`useFetchWithStaleProtection`).
   - Priority P3 (Phase 5+).
6. ⚠️ **`handleConfirmStatus` close modal trước fetch refresh** (lines 296-339):
   - Flow: gọi BE update → success → setEvents inline update → setStatusPrompt close → refreshEmergencyData(true).
   - `setEvents(prev => prev.filter(...))` (line 330) optimistic update.
   - Nhưng `refreshEmergencyData(true)` async → 1-3 second race window FE thấy state cũ.
   - Acceptable UX nhưng không atomic.
   - Priority P3 — Phase 5+ wait refresh complete trước modal close.
7. ⚠️ **`exportFilters` helper** (lines 277-283) — small helper extract đúng pattern. Reusable.
8. ⚠️ **`handleCardClick` switch-case 4 branches** (lines 250-272):
   - 4 filterType: 'SOS', 'Fall', 'resolved', 'all'.
   - Logic phức tạp với date range computation inline (lines 252-258 `todayStr`, `sevenDaysStr`).
   - Extract `useEmergencyFilters()` hook hoặc `getFilterPreset(type)` helper.
   - Priority P3 — Phase 5+.
9. ⚠️ **`isDisconnected` state không sync với `isConnected` từ useWebSocket** (lines 32, 107):
   - `isDisconnected` set từ try/catch trong `refreshEmergencyData` (line 105).
   - `isConnected` từ `useWebSocket` hook (line 107) — separate state.
   - Nếu fetch fail nhưng WebSocket OK → `isDisconnected=true` nhưng `isConnected=true` → inconsistent UX.
   - Fix: combine `isDisconnected = !isConnected || fetchFailed` để consistent.
   - Priority P3.
10. ⚠️ **No console.log debug** (good practice) — F10 cleaner hơn F09. Note positive finding.
11. ⚠️ **`searchTimer` debounce 400ms** (lines 240-246) — đúng pattern. Comparable với F09.
12. ⚠️ **`activeTab === 'watch'` exception logic** (lines 78-89, 105):
    - Tab `watch` không fetch events table (chỉ `fallCountdownList`).
    - Tab `watch` không apply filter search (filter client-side via `filteredWatchItems` useMemo).
    - 3 chỗ branch logic cho `'watch'` tab.
    - Chấp nhận được nhưng pattern complex. Extract `useEmergencyWatchTab()` hoặc `WatchTabContent.jsx`.
    - Priority P3 — Phase 5+.

### Correctness (2/3)

- ✓ **`refreshGenRef` generation pattern** (lines 89-105) — protect stale fetch khi user click rapid.
- ✓ **WebSocket cleanup** (lines 137-141) — `off(...)` event handlers + clearTimeout debounce.
- ✓ **Auto-refresh interval cleanup** (line 154) — `clearInterval` on unmount.
- ✓ **Pagination loading state** — separate từ initial loading, không full-screen spinner mỗi page change.
- ✓ **Toast cleanup** (lines 67-71) — `clearTimeout(toastTimer.current)` trước set new toast.
- ✓ **WebSocket burst debounce 400ms** — defense against BE emit storm.
- ⚠️ **P3 — `handleConfirmStatus` non-atomic** — modal close trước fetch refresh.
- ⚠️ **P3 — `isDisconnected` inconsistent với `isConnected`**.

### Readability (2/3)

- ✓ **UC029 BR reference comments** inline (line 144 `BR-029-01: Auto-refresh every 15s`).
- ✓ **Vietnamese description per tab** (lines 408-413) — UX clear cho admin.
- ✓ **State naming clear** (`activeTab`, `fallCountdownList`, `detailModal`, `statusPrompt`).
- ✓ **Section comment** (line 115 `Trong cửa sổ debounce: ...`) — explain intent.
- ⚠️ **P2 — File 510 LoC** — vượt rule "< 200 LoC". Sub-component extract candidates:
  - `WatchTabContent.jsx` — fall countdown panel + search filter (lines 466-472).
  - `useEmergencyData()` custom hook — refreshEmergencyData + state (lines 80-141).
  - Page main remain ~250 LoC compose.
- ⚠️ **P2 — `handleConfirmStatus` 50 LoC** (lines 296-345) — complex branching: customEventId vs detailModal eventId, optimistic update, refresh detail, refresh table. Extract sub-functions.
- ⚠️ **P3 — `getFilterPreset(type)` extract** từ handleCardClick switch-case.

### Architecture (2/3)

- ✓ **Component composition** đúng — 7 sub-components extracted.
- ✓ **Custom hook usage** — `useWebSocket` đúng pattern.
- ✓ **`useMemo` cho `filteredWatchItems`** (line 78) — client-side filter, đúng performance pattern.
- ⚠️ **P2 — File 510 LoC** vượt rule. Extract sub-components.
- ⚠️ **P2 — `refreshEmergencyData` 60 LoC monolithic** (lines 80-108):
  - Logic dispatch theo activeTab (active/history/watch).
  - Promise.all summary + tab-specific fetch.
  - Extract `useTabFetch(activeTab, page, filters)` custom hook.
  - Priority P2.
- ⚠️ **P3 — `searchTimer` ref pattern** — local state với ref. Acceptable but could move to custom hook (`useDebouncedSearch`).

### Security (2/3)

- ✓ React JSX auto-escape (`{toast.message}`, `{summary.pendingFallDetails.countdown}`).
- ✓ Không `dangerouslySetInnerHTML`.
- ✓ Service layer delegate (line 3 `emergencyService`).
- ✓ Page wrap bởi `ProtectedRoute`.
- ✓ **Không console.log** trong file (clean compared F09).
- ⚠️ **P3 — Admin notes validation** (lines 296-345 `handleConfirmStatus`):
  - `notes` param từ user input trong `EmergencyStatusPrompt` modal → gửi BE.
  - FE không validate length/sanitize trước gửi.
  - BE validation chịu trách nhiệm (xem M03 emergency.controller.js validate rules) — nhưng FE-side defensive nên check.
  - Priority P3 — add `notes.trim().length > 0 && notes.length < 1000` check.

### Performance (3/3)

- ✓ **WebSocket debounce 400ms** (lines 113-122) — consolidate burst.
- ✓ **`refreshGenRef` generation** — cancel stale fetch.
- ✓ **`useMemo` cho `filteredWatchItems`** — client-side filter optimal.
- ✓ **Auto-refresh interval clearInterval cleanup** — không leak.
- ✓ **Pagination loading separate** — không full-screen spinner mỗi page.
- ✓ **Conditional fetch** (line 89 `secondRequest = activeTab === ...`) — chỉ fetch tab cần thiết.

## Recommended actions (Phase 4)

### P2 — architecture cleanup

- [ ] **P2** — Extract `useEmergencyData()` custom hook consolidate `refreshEmergencyData` + state (~3h refactor).
- [ ] **P2** — Extract `WatchTabContent.jsx` sub-component (~1h).
- [ ] **P2** — Extract `getFilterPreset(type)` helper từ `handleCardClick` (~30 min).
- [ ] **P2** — Refactor `handleConfirmStatus` 50 LoC complex flow → sub-functions (~1h).

### P3 — cleanup + defensive

- [ ] **P3 (Phase 5+)** — Extract `useWebSocketBurstHandler(events, debounceMs)` custom hook reusable (F09 + F10 share).
- [ ] **P3 (Phase 5+)** — Extract `useFetchWithStaleProtection()` utility (`refreshGenRef` pattern).
- [ ] **P3** — Consolidate `isDisconnected` với `isConnected` từ useWebSocket (~10 min).
- [ ] **P3** — Add admin notes validate length/trim trước gửi BE (~10 min).
- [ ] **P3 (Phase 5+)** — Make `handleConfirmStatus` atomic — wait refresh trước modal close.

## Out of scope (defer)

- EmergencyToolbar/Table/Pagination/SummaryBar/FallCountdownPanel/DetailModal/StatusPrompt internals — F12 ThresholdAlertsTable similar UI pattern.
- `useWebSocket` hook — Wave 4 future scope.
- `emergencyService` API layer — M12 cover.
- E2E test cho real-time WS event flow — Phase 5+ Cypress/Playwright.
- Style + animation — Phase 3 cosmetic out of scope.
- Accessibility (ARIA, keyboard nav, screen reader cho countdown) — Phase 5+.
- UC029 SOS auto-trigger logic — covered M04 + emergency.service Phase 1.

## Cross-references

- Phase 1 M10 audit: [tier2/healthguard/M10_frontend_pages_audit.md](../../tier2/healthguard/M10_frontend_pages_audit.md) — page composition flagged.
- Phase 1 M04 audit: [tier2/healthguard/M04_services_audit.md](../../tier2/healthguard/M04_services_audit.md) — `emergency.service.js` BE source.
- Phase 0.5 drift: [tier1.5/intent_drift/healthguard/EMERGENCY.md](../../tier1.5/intent_drift/healthguard/EMERGENCY.md) — UC029 v2 decisions (status workflow, contact log, watch tab).
- F07 `websocket.service.js` deep-dive — emit `emergency:new-event` + `emergency:status-update` source.
- F09 `HealthOverviewPage.jsx` deep-dive — sister page comparison (god-component pattern, WebSocket integration).
- Steering React rule: `.kiro/steering/24-react-vite.md` — Component < 200 LoC.
- Precedent format: [tier3/healthguard-model-api/F2_health_service_audit.md](../healthguard-model-api/F2_health_service_audit.md) — tier3 deep-dive format.

---

**Verdict:** EmergencyPage performant nhờ WebSocket debounce + generation pattern — 11/15 Healthy band. Best practices examples: `refreshGenRef` stale protection + WebSocket burst debounce + `useMemo` cho filteredWatchItems. Main gap: 510 LoC god-component (Phase 5+ split). No P0/P1 critical findings — page chỉ cần P2 architectural cleanup. Better state hơn F09 HealthOverviewPage.
