# Deep-dive: F12 — ThresholdAlertsTable.jsx (HG-001 UI consumer + label mapping)

**File:** `HealthGuard/frontend/src/components/health/ThresholdAlertsTable.jsx`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Wave:** Phase 3 Wave 3 (MLOps + Frontend god-components)

## Scope

Single component file `ThresholdAlertsTable.jsx` (~250 LoC):
- Component prop interface: alerts, loading, onViewDetail, onExport, page, total, limit, onPageChange — controlled component.
- Header: title + Export CSV button.
- Table 9 columns: Bệnh nhân (avatar + name + email), Loại (alert_type badge), Chỉ số (metric), Giá trị (value), Ngưỡng (threshold), Mức độ (severity badge), Trạng thái (status badge), Thời gian (Vietnam timezone), Thao tác (View detail).
- Inline helpers: getAlertTypeColor, getAlertTypeName, getStatusColor, getStatusName — 7 alert_type + 4 status branch.
- Empty state + loading state + sticky last column.
- AlertsPagination consumed cuối table.

**Out of scope:** AlertsPagination component (M11 Phase 1), HealthConstants (SEVERITY_COLORS, METRIC_UNITS), dateUtils helpers (formatVietnamTime, formatVietnamDate — Phase 5+).

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Controlled component pattern đúng. 9 columns render đúng. Empty state + loading state OK. Gap: 4 helper functions inline trong component body re-create mỗi render (perf), `key={idx}` row key không stable. |
| Readability | 2/3 | JSX 250 LoC scannable nhờ table structure. Vietnamese comment cho intent inline. Nhưng 4 inline helper functions duplicate logic cho mapping label/color — extract sang HealthConstants. |
| Architecture | 2/3 | Controlled component đúng pattern (props-driven). Sticky cuối column với z-index. Gap: 4 inline helpers business logic không thuộc presentational component — should extract sang `utils/alertLabels.js` hoặc HealthConstants. Component 250 LoC vượt rule "<200 LoC". |
| Security | 3/3 | React JSX auto-escape. formatVietnamTime + formatVietnamDate consume Date objects from API. Không `dangerouslySetInnerHTML`. |
| Performance | 2/3 | Helper functions inline re-create mỗi render. `key={idx}` không stable nếu data reorder. Sticky column với box-shadow + backdrop-blur — moderate render cost. |
| **Total** | **11/15** | Band: **🟡 Healthy** |

## Findings

### Confirm / revise Phase 1 findings

**Phase 1 M11 findings (all confirmed):**

1. ✅ **Controlled component pattern** (M11 P3 health/ folder) — confirmed: props-driven, không có state local.
2. ✅ **HG-001 UI consumer** — confirmed line 198 render `getStatusName(alert.status)` mà alert.status hardcode `'unread'` từ BE F01 + F09 chain.

**Phase 3 new findings (beyond Phase 1 macro):**

3. ⚠️ **4 inline helper functions duplicate** (lines 59-159):
   - getAlertTypeColor — 7 alert_type → CSS classes.
   - getAlertTypeName — 7 alert_type → Vietnamese label.
   - getStatusColor — 4 status → CSS classes.
   - getStatusName — 4 status → Vietnamese label.
   - Inside `alerts.map(...)` — re-create mỗi render × N rows.
   - Should extract sang `components/health/HealthConstants.js` (đã có SEVERITY_COLORS) hoặc `utils/alertLabels.js`.
   - Priority P2.
4. ⚠️ **Severity nested ternary** (lines 211-214):
   - `alert.severity === 'critical' ? 'Nguy hiểm' : alert.severity === 'high' ? 'Cao' : alert.severity === 'medium' ? 'Trung bình' : 'Thấp'`.
   - Cùng pattern với F09 line 467 — duplicate.
   - Extract `getSeverityLabel` helper sang HealthConstants.
   - Priority P2 — coordinate F09.
5. ⚠️ **`key={idx}` row key** (line 161):
   - `alerts.map((alert, idx) => <tr key={idx}>...)`.
   - Steering React rule: "Missing `key` or `key={index}` for reorderable list" — anti-pattern.
   - Nếu data reorder (sort by time DESC change → ASC) → React không track row identity → re-render full.
   - Fix: `<tr key={alert.id}>`.
   - Priority P2.
6. ⚠️ **`getAlertTypeName` map cứng cho 7 types** (lines 80-99):
   - Hardcoded mapping 7 alert_type → Vietnamese label.
   - Nếu BE thêm alert_type mới (vd `medication_missed`) → FE hiển thị 'Khác' default.
   - Drift potential: BE → FE label out-of-sync.
   - Fix: BE emit `alert_type_label` field hoặc enum constant cross-shared.
   - Priority P3 — Phase 5+ contract.
7. ⚠️ **Sticky cuối column performance** (line 220-221):
   - `sticky right-0 bg-white/90 backdrop-blur-sm z-10 ... shadow-[-4px_0_12px_-4px_rgba(0,0,0,0.05)]`.
   - 3 expensive CSS: `backdrop-blur-sm`, `box-shadow` arbitrary value, `position: sticky`.
   - Mỗi row × table render — moderate GPU cost.
   - Acceptable cho 20 rows pagination, nhưng test với scroll list dài Phase 5+.
   - Priority P3.
8. ⚠️ **`min-w-[1200px]` hardcode** (line 28):
   - Table min-width 1200px → mobile/tablet horizontal scroll.
   - Acceptable cho admin desktop, nhưng UX kém trên tablet.
   - Drift DASHBOARD chưa flag responsive concern.
   - Priority P3 — Phase 5+ responsive design.
9. ⚠️ **Avatar charAt(0).toUpperCase()** (line 168):
   - `{alert.userName.charAt(0).toUpperCase()}` — nếu userName null/undefined → TypeError.
   - Defensive check thiếu.
   - Fix: `{alert.userName?.charAt(0).toUpperCase() || '?'}`.
   - Priority P3.
10. ⚠️ **Empty state UX** (lines 49-58):
    - Khi `alerts.length === 0` → render "Không có cảnh báo / Tất cả chỉ số sức khỏe đều bình thường".
    - Tốt UX. Note positive finding.
11. ⚠️ **`SEVERITY_COLORS[alert.severity]`** (line 209) — consume HealthConstants. Pattern nhất quán cho severity nhưng không cho alert_type/status (inline helpers). Inconsistent.

### Correctness (2/3)

- ✓ **Controlled component** — props-driven, không state local.
- ✓ **9 columns render đúng** — match BE response shape.
- ✓ **Loading state** (lines 36-44) — Loader2 spin.
- ✓ **Empty state** (lines 45-58) — UX message + icon.
- ✓ **Pagination delegate** — `<AlertsPagination page limit total onPageChange />` (line 245).
- ⚠️ **P2 — `key={idx}` không stable** (line 161) — anti-pattern per steering.
- ⚠️ **P3 — `userName.charAt(0)` không null-safe** (line 168).

### Readability (2/3)

- ✓ Table structure scannable — header + body + pagination.
- ✓ Vietnamese comment intent inline (line 59 `// Định nghĩa màu sắc cho loại cảnh báo`).
- ✓ Variable naming clear (getAlertTypeColor, getStatusName).
- ⚠️ **P2 — Component 250 LoC** vượt rule "< 200 LoC". 4 inline helpers chiếm 100 LoC (lines 59-159). Extract → component remain ~150 LoC.
- ⚠️ **P2 — 4 inline helpers duplicate logic** — extract sang HealthConstants.
- ⚠️ **P2 — Severity nested ternary duplicate F09**.
- ⚠️ **P3 — `min-w-[1200px]` magic number inline**.

### Architecture (2/3)

- ✓ **Controlled component** đúng pattern.
- ✓ **Sub-component composition** — AlertsPagination delegate.
- ⚠️ **P2 — Inline business logic** (4 helpers) — không thuộc presentational layer. Move sang `utils/alertLabels.js` hoặc HealthConstants.
- ⚠️ **P2 — 250 LoC vượt rule**.
- ⚠️ **P3 — Inconsistent constants source** — SEVERITY_COLORS từ HealthConstants, alert_type/status helpers inline.
- ⚠️ **P3 — Avatar component không extract** (lines 167-172) — inline `<div>` với gradient + first letter. Pattern dùng nhiều places, extract `<UserAvatar name={userName} size="sm" />`.

### Security (3/3)

- ✓ React JSX auto-escape (`{alert.userName}`, `{alert.userEmail}`, `{alert.message}`, `{alert.value}`, `{alert.threshold}`).
- ✓ Không `dangerouslySetInnerHTML` — verify steering React rule compliance.
- ✓ formatVietnamTime, formatVietnamDate consume Date objects từ API. Helper sanitize input.
- ✓ Không `eval`, không `Function()` constructor.
- ✓ Component pure — không side effect, không emit event ngoài callback prop.

### Performance (2/3)

- ✓ Pagination — không render all rows.
- ✓ Table với 9 cells × 20 rows = 180 cells render — acceptable.
- ⚠️ **P2 — 4 inline helpers re-create mỗi render** — getAlertTypeColor, getAlertTypeName, getStatusColor, getStatusName declared trong `alerts.map(...)` body. JS engine memoize literal nhưng function declaration cost. Move outside component (top file constant) → 1 declaration cho all renders.
- ⚠️ **P2 — `key={idx}` re-render full** trên reorder.
- ⚠️ **P3 — Sticky column với backdrop-blur + box-shadow arbitrary value** — moderate GPU cost với scroll.
- ⚠️ **P3 — No `React.memo`** trên ThresholdAlertsTable — parent re-render → all rows re-render dù props unchanged.

## Recommended actions (Phase 4)

### P2 — readability + perf

- [ ] **P2** — Extract 4 helpers (getAlertTypeColor, getAlertTypeName, getStatusColor, getStatusName) sang `components/health/HealthConstants.js` hoặc `utils/alertLabels.js` (~30 min).
- [ ] **P2** — Extract `getSeverityLabel` helper từ nested ternary line 211-214 (coordinate F09 same fix) (~10 min).
- [ ] **P2** — Fix `key={alert.id}` thay `key={idx}` (~5 min).
- [ ] **P2** — Wrap component với `React.memo` để tránh unnecessary re-render (~10 min).

### P3 — defensive + cleanup

- [ ] **P3** — Add null-safe avatar `alert.userName?.charAt(0).toUpperCase() || '?'` (~5 min).
- [ ] **P3** — Extract `<UserAvatar />` component reusable (~30 min, found dùng nhiều places).
- [ ] **P3** — Verify GPU cost sticky column với larger pagination Phase 5+.
- [ ] **P3** — Replace `min-w-[1200px]` hardcode với responsive breakpoint logic Phase 5+.
- [ ] **P3 (Phase 5+)** — BE emit `alert_type_label` + `severity_label` enum field thay vì FE hardcode mapping.

## Out of scope (defer)

- AlertsPagination component internals — M11 Phase 1 macro.
- HealthConstants SEVERITY_COLORS + METRIC_UNITS — M11 Phase 1 macro.
- dateUtils helpers (formatVietnamTime, formatVietnamDate) — Phase 5+ scope.
- Sticky column accessibility (screen reader nav) — Phase 5+.
- Mobile responsive design — Phase 5+ feature.
- Sort + click column header — Phase 5+ feature.

## Cross-references

- Phase 1 M11 audit: [tier2/healthguard/M11_frontend_components_audit.md](../../tier2/healthguard/M11_frontend_components_audit.md) — health/ folder consumer flag.
- F01 `health.service.js` deep-dive — BE source emit alert.status hardcode (HG-001).
- F09 `HealthOverviewPage.jsx` deep-dive — page consumer của F12, severity nested ternary duplicate.
- HG-001 bug: [BUGS/HG-001-admin-web-alerts-always-unread.md](../../../BUGS/HG-001-admin-web-alerts-always-unread.md) — root cause BE service.
- Steering React rule: `.kiro/steering/24-react-vite.md` — Component < 200 LoC, `key={index}` anti-pattern.
- Precedent format: [tier3/healthguard-model-api/F5_prediction_contract_audit.md](../healthguard-model-api/F5_prediction_contract_audit.md) — tier3 deep-dive format.

---

**Verdict:** Presentational table component reasonable architecture — 11/15 Healthy band. Main gaps: 4 inline helpers business logic (P2 extract), `key={idx}` anti-pattern (P2 fix), 250 LoC vượt rule (P2 extract helpers giải quyết). Sau Phase 4 P2 → 13/15 Mature. HG-001 fix ở BE F01 + FE F09 sẽ propagate qua F12 mà không cần code change ở table.
